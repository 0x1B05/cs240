from pathlib import Path

import pytest

from proj.src.data import DataValidationError, load_dataset
from proj.src.features import FeatureSet, build_features
from proj.src.objectives import Objective, combined_objective, coverage_objective, diversity_objective
from proj.src.retrieval import retrieve_top_n
from proj.src.selectors import budgeted_greedy, exhaustive_optimal, mmr, relevance_ratio, seeded_random, top_ranked


def test_objectives_empty_and_combined_value():
    features = _fixture_features()
    coverage = coverage_objective(features)
    diversity = diversity_objective(features)
    combined = combined_objective(features, lambda_value=2.0)

    assert coverage.value(()) == 0.0
    assert diversity.value(()) == 0.0
    assert combined.value((0, 1)) == coverage.value((0, 1)) + 2.0 * diversity.value((0, 1))


def test_diversity_marginal_gain_has_diminishing_returns():
    features = FeatureSet(
        query_id="q",
        doc_ids=("a", "b", "c"),
        costs=(1, 1, 1),
        relevance=(1.0, 1.0, 1.0),
        similarity=((1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0)),
    )
    objective = diversity_objective(features)

    first_gain = objective.marginal_gain((), 0)
    later_gain = objective.marginal_gain((1, 2), 0)

    assert first_gain > later_gain


def test_negative_lambda_rejected():
    features = _fixture_features()

    with pytest.raises(DataValidationError, match="lambda"):
        combined_objective(features, lambda_value=-1.0)


def test_budgeted_greedy_respects_budget():
    features = _fixture_features()
    objective = combined_objective(features)
    result = budgeted_greedy(features, objective, budget=18)

    assert result.total_cost <= 18
    assert result.indices
    assert result.objective_value is not None


def test_budgeted_greedy_compares_against_best_feasible_singleton():
    features = FeatureSet(
        query_id="q",
        doc_ids=("cheap", "expensive"),
        costs=(4, 10),
        relevance=(0.0, 0.0),
        similarity=((1.0, 0.0), (0.0, 1.0)),
    )
    objective = WeightedSingletonObjective((5.0, 11.0))

    result = budgeted_greedy(features, objective, budget=10)

    assert result.indices == (1,)
    assert result.total_cost == 10
    assert result.objective_value == 11.0


def test_baselines_are_budget_feasible_and_seeded_random_is_stable():
    features = _fixture_features()
    budget = 15

    results = [
        top_ranked(features, budget),
        relevance_ratio(features, budget),
        seeded_random(features, budget, seed=7),
        mmr(features, budget),
    ]

    assert all(result.total_cost <= budget for result in results)
    assert seeded_random(features, budget, seed=7) == seeded_random(features, budget, seed=7)


def test_mmr_stops_when_best_remaining_score_is_nonpositive():
    features = FeatureSet(
        query_id="q",
        doc_ids=("a", "b", "c"),
        costs=(1, 1, 1),
        relevance=(1.0, 1.0, 1.0),
        similarity=((1.0, 1.0, 1.0), (1.0, 1.0, 1.0), (1.0, 1.0, 1.0)),
    )

    result = mmr(features, budget=3, lambda_value=0.0)

    assert len(result.indices) == 1
    assert result.total_cost == 1


def test_random_requires_seed_and_exhaustive_threshold():
    features = _fixture_features()

    with pytest.raises(DataValidationError, match="seed"):
        seeded_random(features, budget=10, seed=None)
    with pytest.raises(DataValidationError, match="refuses"):
        exhaustive_optimal(features, combined_objective(features), budget=10, max_items=2)


def _fixture_features():
    dataset = load_dataset(Path("proj/data/fixtures"))
    query = dataset.queries[1]
    candidates = retrieve_top_n(dataset, top_n=5)[query.query_id]
    return build_features(query.query, candidates)


class WeightedSingletonObjective(Objective):
    def __init__(self, values: tuple[float, ...]):
        self.values = values

    def value(self, selected):
        return sum(self.values[index] for index in set(selected))

    def marginal_gain(self, selected, item: int) -> float:
        return 0.0 if item in set(selected) else self.values[item]
