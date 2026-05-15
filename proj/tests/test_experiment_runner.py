import json
from pathlib import Path

import pytest

from proj.src.data import DataValidationError, read_jsonl
from proj.src.experiments import (
    ExperimentConfig,
    generate_candidates,
    parse_grid,
    run_experiment,
    select_evaluate,
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


def test_runtime_units_reflect_selector_work(tmp_path):
    output_dir = tmp_path / "runtime-run"
    run_experiment(
        ExperimentConfig(
            data_dir="proj/data/fixtures",
            output_dir=str(output_dir),
            budgets=(18,),
            candidate_sizes=(5,),
            selectors=("top_ranked", "mmr", "budgeted_greedy"),
            objectives=("combined",),
            seed=13,
            optimal_max_items=5,
        )
    )

    by_method = {}
    for row in read_jsonl(output_dir / "per_query_metrics.jsonl"):
        if row["query_id"] == "q1":
            by_method[row["method_label"]] = row["runtime_units"]

    assert by_method["top_ranked"] < by_method["mmr"] < by_method["submodular_combined"]


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


def test_run_experiment_sample_size_controls_query_subset(tmp_path):
    first = tmp_path / "sample-one"
    second = tmp_path / "sample-two"
    base = dict(
        data_dir="proj/data/processed/fixture-multihop",
        budgets=(12,),
        candidate_sizes=(3,),
        selectors=("top_ranked",),
        objectives=("combined",),
        seed=13,
        optimal_max_items=3,
    )

    run_experiment(ExperimentConfig(output_dir=str(first), sample_size=1, sample_seed=1, **base))
    run_experiment(ExperimentConfig(output_dir=str(second), sample_size=2, sample_seed=1, **base))

    first_manifest = read_jsonl(first / "sample_manifest.jsonl")
    second_manifest = read_jsonl(second / "sample_manifest.jsonl")
    first_metrics = read_jsonl(first / "per_query_metrics.jsonl")
    second_metrics = read_jsonl(second / "per_query_metrics.jsonl")
    first_config = json.loads((first / "config.json").read_text(encoding="utf-8"))

    assert len(first_manifest) == 1
    assert len(second_manifest) == 2
    assert len(first_metrics) == 1
    assert len(second_metrics) == 2
    assert first_config["query_ids"] == [row["query_id"] for row in first_manifest]
    assert {row["query_id"] for row in first_metrics} == {row["query_id"] for row in first_manifest}


def test_random_seeded_baseline_is_salted_by_query_id(tmp_path):
    output_dir = tmp_path / "random-run"
    run_experiment(
        ExperimentConfig(
            data_dir="proj/data/fixtures",
            output_dir=str(output_dir),
            budgets=(30,),
            candidate_sizes=(5,),
            selectors=("random_seeded",),
            objectives=("combined",),
            seed=13,
            optimal_max_items=5,
        )
    )

    random_rows = [row for row in read_jsonl(output_dir / "selections.jsonl") if row["method_label"] == "random_seeded"]
    candidate_rank = {
        (row["query_id"], row["doc_id"]): row["rank"]
        for row in read_jsonl(output_dir / "candidates.jsonl")
        if row["top_n"] == 5
    }
    selected_ranks_by_query = {
        row["query_id"]: tuple(candidate_rank[(row["query_id"], doc_id)] for doc_id in row["selected_doc_ids"])
        for row in random_rows
    }

    assert len(set(selected_ranks_by_query.values())) > 1


def test_select_evaluate_consumes_saved_candidate_file(tmp_path):
    candidates_path = tmp_path / "candidates.jsonl"
    output_dir = tmp_path / "selected"
    generate_candidates(Path("proj/data/fixtures"), candidates_path, top_n=3)

    summary = select_evaluate(
        data_dir=Path("proj/data/fixtures"),
        candidates_path=candidates_path,
        output_dir=output_dir,
        budget=18,
        seed=13,
        overwrite=False,
    )

    assert summary["queries"] == 3
    assert {row["top_n"] for row in read_jsonl(output_dir / "candidates.jsonl")} == {3}
    assert (output_dir / "per_query_metrics.jsonl").exists()


def test_select_evaluate_rejects_malformed_candidate_file(tmp_path):
    candidates_path = tmp_path / "bad-candidates.jsonl"
    candidates_path.write_text(
        json.dumps({"query_id": "q1", "doc_id": "d1", "rank": 1, "score": 1.0, "text": "bad missing fields"}) + "\n",
        encoding="utf-8",
    )

    with pytest.raises(DataValidationError, match="missing required candidate columns"):
        select_evaluate(
            data_dir=Path("proj/data/fixtures"),
            candidates_path=candidates_path,
            output_dir=tmp_path / "selected",
            budget=18,
            seed=13,
            overwrite=False,
        )


def test_select_evaluate_rejects_candidate_payload_that_differs_from_corpus(tmp_path):
    candidates_path = tmp_path / "candidates.jsonl"
    generate_candidates(Path("proj/data/fixtures"), candidates_path, top_n=3)
    rows = read_jsonl(candidates_path)
    rows[0]["text"] = "stale candidate text for a known doc id"
    rows[1]["token_cost"] = rows[1]["token_cost"] + 100
    candidates_path.write_text("\n".join(json.dumps(row, sort_keys=True) for row in rows) + "\n", encoding="utf-8")

    with pytest.raises(DataValidationError, match="canonical corpus"):
        select_evaluate(
            data_dir=Path("proj/data/fixtures"),
            candidates_path=candidates_path,
            output_dir=tmp_path / "selected",
            budget=18,
            seed=13,
            overwrite=False,
        )
