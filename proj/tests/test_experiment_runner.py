import json

import pytest

from proj.src.data import DataValidationError, read_jsonl
from proj.src.experiments import (
    ExperimentConfig,
    parse_grid,
    run_experiment,
)


def test_parse_grid_rejects_empty_nonpositive_and_duplicates():
    assert parse_grid("4,8", item_type=int, label="budgets") == (4, 8)

    with pytest.raises(DataValidationError, match="budgets"):
        parse_grid("", item_type=int, label="budgets")
    with pytest.raises(DataValidationError, match="positive"):
        parse_grid("0,8", item_type=int, label="budgets")
    with pytest.raises(DataValidationError, match="duplicate"):
        parse_grid("8,8", item_type=int, label="budgets")


def test_run_experiment_writes_required_outputs(tmp_path):
    output_dir = tmp_path / "main-run"
    config = ExperimentConfig(
        data_dir="proj/data/fixtures",
        output_dir=str(output_dir),
        dataset_name="fixture",
        split="test",
        budgets=(12, 18),
        candidate_sizes=(3, 5),
        selectors=("top_ranked", "relevance_ratio", "random_seeded", "mmr", "budgeted_greedy"),
        objectives=("combined",),
        combined_lambdas=(1.0,),
        mmr_lambda=0.7,
        seed=13,
        optimal_max_items=4,
        overwrite=False,
    )

    summary = run_experiment(config)

    assert summary["queries"] == 3
    for filename in [
        "config.json",
        "run.log",
        "candidates.jsonl",
        "selections.jsonl",
        "per_query_metrics.jsonl",
        "aggregate_metrics.csv",
        "aggregate_metrics.md",
        "optimal_checks.csv",
        "summary.md",
    ]:
        assert (output_dir / filename).exists()

    selections = read_jsonl(output_dir / "selections.jsonl")
    metrics = read_jsonl(output_dir / "per_query_metrics.jsonl")
    assert selections[0].keys() >= {
        "query_id",
        "method_label",
        "selector",
        "budget",
        "top_n",
        "selected_doc_ids",
        "total_cost",
        "objective_value",
        "runtime_units",
    }
    assert metrics[0].keys() >= {
        "query_id",
        "method_label",
        "budget",
        "top_n",
        "evidence_recall",
        "evidence_f1",
        "redundancy",
        "budget_utilization",
        "runtime_units",
    }
    assert "submodular_combined" in {row["method_label"] for row in metrics}
    assert "evidence_f1_mean" in (output_dir / "aggregate_metrics.csv").read_text(encoding="utf-8")


def test_run_experiment_refuses_overwrite(tmp_path):
    output_dir = tmp_path / "main-run"
    output_dir.mkdir()
    (output_dir / "config.json").write_text("{}\n", encoding="utf-8")
    config = ExperimentConfig(data_dir="proj/data/fixtures", output_dir=str(output_dir))

    with pytest.raises(DataValidationError, match="overwrite"):
        run_experiment(config)


def test_run_experiment_reproducible_selection_and_metric_files(tmp_path):
    first = tmp_path / "first"
    second = tmp_path / "second"
    base = dict(
        data_dir="proj/data/fixtures",
        dataset_name="fixture",
        split="test",
        budgets=(18,),
        candidate_sizes=(5,),
        selectors=("top_ranked", "relevance_ratio", "random_seeded", "mmr", "budgeted_greedy"),
        objectives=("combined",),
        seed=17,
        optimal_max_items=5,
    )

    run_experiment(ExperimentConfig(output_dir=str(first), **base))
    run_experiment(ExperimentConfig(output_dir=str(second), **base))

    for filename in ["candidates.jsonl", "selections.jsonl", "per_query_metrics.jsonl", "aggregate_metrics.csv", "optimal_checks.csv"]:
        assert (first / filename).read_text(encoding="utf-8") == (second / filename).read_text(encoding="utf-8")


def test_run_experiment_reports_executed_and_skipped_optimal_checks(tmp_path):
    output_dir = tmp_path / "main-run"
    run_experiment(
        ExperimentConfig(
            data_dir="proj/data/fixtures",
            output_dir=str(output_dir),
            budgets=(18,),
            candidate_sizes=(3, 5),
            selectors=("budgeted_greedy",),
            objectives=("combined",),
            seed=13,
            optimal_max_items=3,
        )
    )

    text = (output_dir / "optimal_checks.csv").read_text(encoding="utf-8")
    assert "executed" in text
    assert "too_many_items" in text
