from __future__ import annotations

from math import sqrt
from typing import Iterable, Protocol

from .data import DataValidationError
from .features import FeatureSet, validate_features


class Objective(Protocol):
    def value(self, selected: Iterable[int]) -> float: ...

    def marginal_gain(self, selected: Iterable[int], item: int) -> float: ...


class SubmodularObjective:
    def __init__(self, features: FeatureSet, coverage_weight: float = 1.0, diversity_weight: float = 1.0):
        validate_features(features)
        if coverage_weight < 0 or diversity_weight < 0:
            raise DataValidationError("objective weights must be nonnegative")
        self.features = features
        self.coverage_weight = coverage_weight
        self.diversity_weight = diversity_weight

    def value(self, selected: Iterable[int]) -> float:
        selected_set = _normalize_selection(selected, len(self.features.doc_ids))
        if not selected_set:
            return 0.0
        return self.coverage_weight * self.coverage(selected_set) + self.diversity_weight * self.diversity(selected_set)

    def marginal_gain(self, selected: Iterable[int], item: int) -> float:
        selected_set = _normalize_selection(selected, len(self.features.doc_ids))
        _validate_item(item, len(self.features.doc_ids))
        if item in selected_set:
            return 0.0
        return self.value((*selected_set, item)) - self.value(selected_set)

    def coverage(self, selected: Iterable[int]) -> float:
        selected_set = _normalize_selection(selected, len(self.features.doc_ids))
        total = 0.0
        for representative in range(len(self.features.doc_ids)):
            total += max(self.features.similarity[representative][item] for item in selected_set)
        return total

    def diversity(self, selected: Iterable[int]) -> float:
        selected_set = _normalize_selection(selected, len(self.features.doc_ids))
        # Concave reward over total relevance gives diminishing returns without adding a clustering dependency.
        return sqrt(sum(self.features.relevance[item] for item in selected_set))


def coverage_objective(features: FeatureSet) -> SubmodularObjective:
    return SubmodularObjective(features, coverage_weight=1.0, diversity_weight=0.0)


def diversity_objective(features: FeatureSet) -> SubmodularObjective:
    return SubmodularObjective(features, coverage_weight=0.0, diversity_weight=1.0)


def combined_objective(features: FeatureSet, lambda_value: float = 1.0) -> SubmodularObjective:
    if lambda_value < 0:
        raise DataValidationError("lambda_value must be nonnegative")
    return SubmodularObjective(features, coverage_weight=1.0, diversity_weight=lambda_value)


def _normalize_selection(selected: Iterable[int], size: int) -> tuple[int, ...]:
    normalized = tuple(dict.fromkeys(selected))
    for item in normalized:
        _validate_item(item, size)
    return normalized


def _validate_item(item: int, size: int) -> None:
    if item < 0 or item >= size:
        raise DataValidationError(f"item index out of range: {item}")
