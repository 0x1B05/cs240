from __future__ import annotations

from dataclasses import dataclass
import random

from .data import DataValidationError
from .features import FeatureSet
from .objectives import Objective


@dataclass(frozen=True)
class SelectionResult:
    indices: tuple[int, ...]
    total_cost: int
    objective_value: float | None = None


def budgeted_greedy(features: FeatureSet, objective: Objective, budget: int) -> SelectionResult:
    _validate_budget(budget)
    selected: list[int] = []
    remaining = set(range(len(features.doc_ids)))
    total_cost = 0

    while remaining:
        feasible = [item for item in remaining if total_cost + features.costs[item] <= budget]
        if not feasible:
            break
        best = max(
            feasible,
            key=lambda item: (
                objective.marginal_gain(selected, item) / features.costs[item],
                objective.marginal_gain(selected, item),
                -features.costs[item],
                features.doc_ids[item],
            ),
        )
        gain = objective.marginal_gain(selected, best)
        if gain <= 0:
            break
        selected.append(best)
        total_cost += features.costs[best]
        remaining.remove(best)

    return SelectionResult(tuple(selected), total_cost, objective.value(selected))


def top_ranked(features: FeatureSet, budget: int) -> SelectionResult:
    _validate_budget(budget)
    return _select_in_order(features, range(len(features.doc_ids)), budget)


def relevance_ratio(features: FeatureSet, budget: int) -> SelectionResult:
    _validate_budget(budget)
    order = sorted(
        range(len(features.doc_ids)),
        key=lambda item: (-(features.relevance[item] / features.costs[item]), features.doc_ids[item]),
    )
    return _select_in_order(features, order, budget)


def seeded_random(features: FeatureSet, budget: int, seed: int | None) -> SelectionResult:
    _validate_budget(budget)
    if seed is None:
        raise DataValidationError("random baseline requires an explicit seed")
    order = list(range(len(features.doc_ids)))
    random.Random(seed).shuffle(order)
    return _select_in_order(features, order, budget)


def mmr(features: FeatureSet, budget: int, lambda_value: float = 0.7) -> SelectionResult:
    _validate_budget(budget)
    if not 0.0 <= lambda_value <= 1.0:
        raise DataValidationError("MMR lambda must be in [0, 1]")

    selected: list[int] = []
    remaining = set(range(len(features.doc_ids)))
    total_cost = 0
    while remaining:
        feasible = [item for item in remaining if total_cost + features.costs[item] <= budget]
        if not feasible:
            break

        def score(item: int) -> tuple[float, str]:
            redundancy = max((features.similarity[item][chosen] for chosen in selected), default=0.0)
            mmr_score = lambda_value * features.relevance[item] - (1.0 - lambda_value) * redundancy
            return (mmr_score / features.costs[item], features.doc_ids[item])

        best = max(feasible, key=score)
        selected.append(best)
        total_cost += features.costs[best]
        remaining.remove(best)
    return SelectionResult(tuple(selected), total_cost)


def exhaustive_optimal(features: FeatureSet, objective: Objective, budget: int, max_items: int = 20) -> SelectionResult:
    _validate_budget(budget)
    size = len(features.doc_ids)
    if size > max_items:
        raise DataValidationError(f"exhaustive search refuses {size} items; max_items={max_items}")

    best_indices: tuple[int, ...] = ()
    best_value = 0.0
    best_cost = 0
    for mask in range(1 << size):
        indices = tuple(item for item in range(size) if mask & (1 << item))
        total_cost = sum(features.costs[item] for item in indices)
        if total_cost > budget:
            continue
        value = objective.value(indices)
        if value > best_value or (value == best_value and (total_cost, indices) < (best_cost, best_indices)):
            best_indices = indices
            best_value = value
            best_cost = total_cost
    return SelectionResult(best_indices, best_cost, best_value)


def _select_in_order(features: FeatureSet, order, budget: int) -> SelectionResult:
    selected: list[int] = []
    total_cost = 0
    for item in order:
        if total_cost + features.costs[item] <= budget:
            selected.append(item)
            total_cost += features.costs[item]
    return SelectionResult(tuple(selected), total_cost)


def _validate_budget(budget: int) -> None:
    if budget <= 0:
        raise DataValidationError("budget must be positive")
