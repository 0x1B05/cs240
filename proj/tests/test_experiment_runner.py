import json
from pathlib import Path

import pytest

import proj.src.experiments as experiments_module
from proj.src.artifacts import generate_artifacts
from proj.src.data import DataValidationError, load_dataset, read_jsonl
from proj.src.experiments import (
    ExperimentConfig,
    generate_candidates,
    parse_name_grid,
    parse_grid,
    run_experiment,
    run_smoke,
    select_evaluate,
)


def test_parse_grid_rejects_empty_nonpositive_and_duplicates():
    assert parse_grid("4,8", item_type=int, label="budgets") == (4, 8)
    assert parse_grid("0,1", item_type=float, label="combined_lambdas", allow_zero=True) == (0.0, 1.0)

    with pytest.raises(DataValidationError, match="budgets"):
        parse_grid("", item_type=int, label="budgets")
    with pytest.raises(DataValidationError, match="positive"):
        parse_grid("0,8", item_type=int, label="budgets")
    with pytest.raises(DataValidationError, match="duplicate"):
        parse_grid("8,8", item_type=int, label="budgets")
    with pytest.raises(DataValidationError, match="finite"):
        parse_grid("nan", item_type=float, label="combined_lambdas")
    with pytest.raises(DataValidationError, match="finite"):
        parse_grid("inf", item_type=float, label="combined_lambdas")


def test_parse_name_grid_rejects_empty_entries():
    assert parse_name_grid("top_ranked,mmr", allowed=("top_ranked", "mmr"), label="selectors") == ("top_ranked", "mmr")

    with pytest.raises(DataValidationError, match="empty value"):
        parse_name_grid("top_ranked,,mmr", allowed=("top_ranked", "mmr"), label="selectors")
    with pytest.raises(DataValidationError, match="empty value"):
        parse_name_grid("coverage,", allowed=("coverage", "combined"), label="objectives")


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


def test_run_experiment_allows_zero_combined_lambda(tmp_path):
    output_dir = tmp_path / "lambda-zero-run"

    run_experiment(
        ExperimentConfig(
            data_dir="proj/data/fixtures",
            output_dir=str(output_dir),
            budgets=(18,),
            candidate_sizes=(3,),
            selectors=("budgeted_greedy",),
            objectives=("combined",),
            combined_lambdas=(0.0,),
            seed=13,
            optimal_max_items=3,
        )
    )

    assert (output_dir / "aggregate_metrics.csv").exists()


def test_run_experiment_rejects_empty_combined_lambdas_before_writing(tmp_path):
    output_dir = tmp_path / "empty-lambda-run"

    with pytest.raises(DataValidationError, match="combined_lambdas"):
        run_experiment(
            ExperimentConfig(
                data_dir="proj/data/fixtures",
                output_dir=str(output_dir),
                budgets=(18,),
                candidate_sizes=(3,),
                selectors=("budgeted_greedy",),
                objectives=("combined",),
                combined_lambdas=(),
                seed=13,
                optimal_max_items=3,
            )
        )

    assert not output_dir.exists()


def test_run_experiment_allows_empty_lambdas_without_combined_objective(tmp_path):
    output_dir = tmp_path / "coverage-only-run"

    run_experiment(
        ExperimentConfig(
            data_dir="proj/data/fixtures",
            output_dir=str(output_dir),
            budgets=(18,),
            candidate_sizes=(3,),
            selectors=("budgeted_greedy",),
            objectives=("coverage",),
            combined_lambdas=(),
            seed=13,
            optimal_max_items=3,
        )
    )

    labels = {row["method_label"] for row in read_jsonl(output_dir / "selections.jsonl")}

    assert labels == {"submodular_coverage"}


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


def test_run_experiment_rejects_file_output_path(tmp_path):
    output_path = tmp_path / "not-a-directory"
    output_path.write_text("collision\n", encoding="utf-8")

    with pytest.raises(DataValidationError, match="output path is not a directory"):
        run_experiment(ExperimentConfig(data_dir="proj/data/fixtures", output_dir=str(output_path)))


def test_run_smoke_refuses_existing_nonempty_output_dir(tmp_path):
    output_dir = tmp_path / "smoke-run"
    output_dir.mkdir()
    marker = output_dir / "keep.txt"
    marker.write_text("do not delete\n", encoding="utf-8")

    with pytest.raises(DataValidationError, match="overwrite"):
        run_smoke(Path("proj/data/fixtures"), output_dir)

    assert marker.read_text(encoding="utf-8") == "do not delete\n"


def test_run_experiment_rejects_symlinked_output_dir_without_overwrite(tmp_path):
    target_dir = tmp_path / "outside-target"
    target_dir.mkdir()
    target_file = target_dir / "keep.txt"
    target_file.write_text("outside\n", encoding="utf-8")
    output_dir = tmp_path / "run-link"
    output_dir.symlink_to(target_dir, target_is_directory=True)

    with pytest.raises(DataValidationError, match="output path is a symlink"):
        run_experiment(
            ExperimentConfig(
                data_dir="proj/data/fixtures",
                output_dir=str(output_dir),
                budgets=(12,),
                candidate_sizes=(3,),
                selectors=("top_ranked",),
                objectives=("combined",),
                seed=13,
                optimal_max_items=3,
                overwrite=False,
            )
        )

    assert target_file.read_text(encoding="utf-8") == "outside\n"
    assert not (target_dir / "config.json").exists()


def test_run_experiment_rejects_symlinked_output_parent(tmp_path):
    target_dir = tmp_path / "outside-target"
    target_dir.mkdir()
    output_parent = tmp_path / "run-parent-link"
    output_parent.symlink_to(target_dir, target_is_directory=True)

    with pytest.raises(DataValidationError, match="output parent path is a symlink"):
        run_experiment(
            ExperimentConfig(
                data_dir="proj/data/fixtures",
                output_dir=str(output_parent / "run"),
                budgets=(12,),
                candidate_sizes=(3,),
                selectors=("top_ranked",),
                objectives=("combined",),
                seed=13,
                optimal_max_items=3,
                overwrite=False,
            )
        )

    assert not (target_dir / "run" / "config.json").exists()


def test_run_experiment_overwrite_unlinks_symlink_without_following_target(tmp_path):
    target_dir = tmp_path / "outside-target"
    target_dir.mkdir()
    target_file = target_dir / "keep.txt"
    target_file.write_text("outside\n", encoding="utf-8")
    output_dir = tmp_path / "run"
    output_dir.mkdir()
    (output_dir / "stale.txt").write_text("stale\n", encoding="utf-8")
    (output_dir / "linked").symlink_to(target_dir, target_is_directory=True)

    run_experiment(
        ExperimentConfig(
            data_dir="proj/data/fixtures",
            output_dir=str(output_dir),
            budgets=(12,),
            candidate_sizes=(3,),
            selectors=("top_ranked",),
            objectives=("combined",),
            seed=13,
            optimal_max_items=3,
            overwrite=True,
        )
    )

    assert target_file.read_text(encoding="utf-8") == "outside\n"
    assert not (output_dir / "linked").exists()


def test_run_experiment_overwrite_replaces_symlinked_output_dir(tmp_path):
    target_dir = tmp_path / "outside-target"
    target_dir.mkdir()
    target_file = target_dir / "keep.txt"
    target_file.write_text("outside\n", encoding="utf-8")
    output_dir = tmp_path / "run-link"
    output_dir.symlink_to(target_dir, target_is_directory=True)

    run_experiment(
        ExperimentConfig(
            data_dir="proj/data/fixtures",
            output_dir=str(output_dir),
            budgets=(12,),
            candidate_sizes=(3,),
            selectors=("top_ranked",),
            objectives=("combined",),
            seed=13,
            optimal_max_items=3,
            overwrite=True,
        )
    )

    assert target_file.read_text(encoding="utf-8") == "outside\n"
    assert output_dir.is_dir()
    assert not output_dir.is_symlink()
    assert (output_dir / "config.json").exists()


def test_run_experiment_rejects_symlink_output_inside_data_dir_with_overwrite(tmp_path):
    data_dir = tmp_path / "fixture-copy"
    _copy_fixture_dataset(data_dir)
    target_dir = tmp_path / "outside-target"
    target_dir.mkdir()
    target_file = target_dir / "keep.txt"
    target_file.write_text("outside\n", encoding="utf-8")
    output_dir = data_dir / "run-link"
    output_dir.symlink_to(target_dir, target_is_directory=True)

    with pytest.raises(DataValidationError, match="output directory must not contain experiment inputs"):
        run_experiment(
            ExperimentConfig(
                data_dir=str(data_dir),
                output_dir=str(output_dir),
                budgets=(12,),
                candidate_sizes=(3,),
                selectors=("top_ranked",),
                objectives=("combined",),
                seed=13,
                optimal_max_items=3,
                overwrite=True,
            )
        )

    assert target_file.read_text(encoding="utf-8") == "outside\n"
    assert output_dir.is_symlink()
    assert not (target_dir / "config.json").exists()


def test_run_experiment_rejects_overwrite_of_data_dir(tmp_path):
    output_dir = tmp_path / "fixture-copy"
    _copy_fixture_dataset(output_dir)

    with pytest.raises(DataValidationError, match="output directory must not contain experiment inputs"):
        run_experiment(ExperimentConfig(data_dir=str(output_dir), output_dir=str(output_dir), overwrite=True))

    assert (output_dir / "queries.jsonl").exists()
    assert (output_dir / "corpus.jsonl").exists()


def test_run_experiment_rejects_output_nested_under_data_dir(tmp_path):
    data_dir = tmp_path / "fixture-copy"
    _copy_fixture_dataset(data_dir)
    output_dir = data_dir / "nested-output"

    with pytest.raises(DataValidationError, match="output directory must not contain experiment inputs"):
        run_experiment(ExperimentConfig(data_dir=str(data_dir), output_dir=str(output_dir)))

    assert not output_dir.exists()


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


def test_run_experiment_builds_features_against_full_corpus_reference(tmp_path, monkeypatch):
    expected_reference = tuple(doc.text for doc in load_dataset(Path("proj/data/fixtures")).corpus)
    seen_references = []
    original_build_features = experiments_module.build_features

    def recording_build_features(query_text, candidates, *, reference_texts=None):
        seen_references.append(tuple(reference_texts) if reference_texts is not None else None)
        return original_build_features(query_text, candidates, reference_texts=reference_texts)

    monkeypatch.setattr(experiments_module, "build_features", recording_build_features)
    output_dir = tmp_path / "main-run"
    run_experiment(
        ExperimentConfig(
            data_dir="proj/data/fixtures",
            output_dir=str(output_dir),
            budgets=(12,),
            candidate_sizes=(3, 5),
            selectors=("top_ranked",),
            objectives=("combined",),
            seed=13,
            optimal_max_items=3,
        )
    )

    assert seen_references
    assert set(seen_references) == {expected_reference}


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


def test_select_evaluate_consumes_sampled_run_candidate_file(tmp_path):
    sampled_run = tmp_path / "sampled-run"
    selected = tmp_path / "selected"
    run_experiment(
        ExperimentConfig(
            data_dir="proj/data/processed/fixture-multihop",
            output_dir=str(sampled_run),
            budgets=(12,),
            candidate_sizes=(3,),
            selectors=("top_ranked",),
            objectives=("combined",),
            sample_size=2,
            sample_seed=1,
            seed=13,
            optimal_max_items=3,
        )
    )

    summary = select_evaluate(
        data_dir=Path("proj/data/processed/fixture-multihop"),
        candidates_path=sampled_run / "candidates.jsonl",
        output_dir=selected,
        budget=12,
        seed=13,
        selectors=("top_ranked",),
        objectives=("combined",),
        optimal_max_items=3,
        overwrite=False,
    )

    expected_query_ids = {row["query_id"] for row in read_jsonl(sampled_run / "sample_manifest.jsonl")}

    assert summary["queries"] == 2
    assert {row["query_id"] for row in read_jsonl(selected / "per_query_metrics.jsonl")} == expected_query_ids
    assert json.loads((selected / "config.json").read_text(encoding="utf-8"))["query_ids"] == sorted(expected_query_ids)


def test_select_evaluate_consumes_staged_subset_candidate_file(tmp_path):
    sampled_run = tmp_path / "sampled-run"
    first_selected = tmp_path / "first-selected"
    second_selected = tmp_path / "second-selected"
    run_experiment(
        ExperimentConfig(
            data_dir="proj/data/processed/fixture-multihop",
            output_dir=str(sampled_run),
            budgets=(12,),
            candidate_sizes=(3,),
            selectors=("top_ranked",),
            objectives=("combined",),
            sample_size=2,
            sample_seed=1,
            seed=13,
            optimal_max_items=3,
        )
    )
    select_evaluate(
        data_dir=Path("proj/data/processed/fixture-multihop"),
        candidates_path=sampled_run / "candidates.jsonl",
        output_dir=first_selected,
        budget=12,
        seed=13,
        selectors=("top_ranked",),
        objectives=("combined",),
        optimal_max_items=3,
        overwrite=False,
    )

    summary = select_evaluate(
        data_dir=Path("proj/data/processed/fixture-multihop"),
        candidates_path=first_selected / "candidates.jsonl",
        output_dir=second_selected,
        budget=12,
        seed=13,
        selectors=("top_ranked",),
        objectives=("combined",),
        optimal_max_items=3,
        overwrite=False,
    )

    expected_query_ids = {row["query_id"] for row in read_jsonl(first_selected / "sample_manifest.jsonl")}

    assert summary["queries"] == 2
    assert {row["query_id"] for row in read_jsonl(second_selected / "per_query_metrics.jsonl")} == expected_query_ids


def test_select_evaluate_rejects_partial_candidate_file_without_sample_manifest(tmp_path):
    candidates_dir = tmp_path / "candidates"
    candidates_dir.mkdir()
    candidates_path = candidates_dir / "candidates.jsonl"
    generate_candidates(Path("proj/data/fixtures"), candidates_path, top_n=3)
    rows = [row for row in read_jsonl(candidates_path) if row["query_id"] != "q3"]
    candidates_path.write_text("\n".join(json.dumps(row, sort_keys=True) for row in rows) + "\n", encoding="utf-8")

    with pytest.raises(DataValidationError, match="candidate file missing queries"):
        select_evaluate(
            data_dir=Path("proj/data/fixtures"),
            candidates_path=candidates_path,
            output_dir=tmp_path / "selected",
            budget=18,
            seed=13,
            overwrite=False,
        )


def test_select_evaluate_ignores_malformed_adjacent_sample_metadata_for_full_candidates(tmp_path):
    candidates_dir = tmp_path / "candidates"
    candidates_dir.mkdir()
    candidates_path = candidates_dir / "candidates.jsonl"
    generate_candidates(Path("proj/data/fixtures"), candidates_path, top_n=3)
    (candidates_dir / "sample_manifest.jsonl").write_text(
        "\n".join(json.dumps({"query_id": query_id}) for query_id in ["q1", "q2"]) + "\n",
        encoding="utf-8",
    )
    (candidates_dir / "config.json").write_text(
        json.dumps({"candidate_sizes": [3], "candidates_fingerprint": "stale", "query_ids": "q1,q2"}),
        encoding="utf-8",
    )

    summary = select_evaluate(
        data_dir=Path("proj/data/fixtures"),
        candidates_path=candidates_path,
        output_dir=tmp_path / "selected",
        budget=18,
        seed=13,
        selectors=("top_ranked",),
        objectives=("combined",),
        overwrite=False,
    )

    assert summary["queries"] == 3


def test_select_evaluate_ignores_invalid_adjacent_sample_manifest_for_full_candidates(tmp_path):
    candidates_dir = tmp_path / "candidates"
    candidates_dir.mkdir()
    candidates_path = candidates_dir / "candidates.jsonl"
    generate_candidates(Path("proj/data/fixtures"), candidates_path, top_n=3)
    (candidates_dir / "sample_manifest.jsonl").write_text("not-json\n", encoding="utf-8")
    (candidates_dir / "config.json").write_text(
        json.dumps({"candidate_sizes": [3], "candidates_fingerprint": "stale", "query_ids": ["q1", "q2"]}),
        encoding="utf-8",
    )

    summary = select_evaluate(
        data_dir=Path("proj/data/fixtures"),
        candidates_path=candidates_path,
        output_dir=tmp_path / "selected",
        budget=18,
        seed=13,
        selectors=("top_ranked",),
        objectives=("combined",),
        overwrite=False,
    )

    assert summary["queries"] == 3


def test_select_evaluate_rejects_partial_candidate_file_with_stale_sample_manifest(tmp_path):
    candidates_dir = tmp_path / "candidates"
    candidates_dir.mkdir()
    candidates_path = candidates_dir / "candidates.jsonl"
    generate_candidates(Path("proj/data/fixtures"), candidates_path, top_n=3)
    rows = [row for row in read_jsonl(candidates_path) if row["query_id"] != "q3"]
    candidates_path.write_text("\n".join(json.dumps(row, sort_keys=True) for row in rows) + "\n", encoding="utf-8")
    (candidates_dir / "sample_manifest.jsonl").write_text(
        "\n".join(json.dumps({"query_id": query_id}) for query_id in ["q1", "q2"]) + "\n",
        encoding="utf-8",
    )

    with pytest.raises(DataValidationError, match="candidate file missing queries"):
        select_evaluate(
            data_dir=Path("proj/data/fixtures"),
            candidates_path=candidates_path,
            output_dir=tmp_path / "selected",
            budget=18,
            seed=13,
            overwrite=False,
        )


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
    candidates_dir = tmp_path / "candidates"
    candidates_dir.mkdir()
    candidates_path = candidates_dir / "candidates.jsonl"
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


def test_select_evaluate_defaults_generate_report_artifacts(tmp_path):
    candidates_dir = tmp_path / "candidates"
    candidates_dir.mkdir()
    candidates_path = candidates_dir / "candidates.jsonl"
    output_dir = tmp_path / "selected"
    artifact_dir = tmp_path / "artifacts"
    generate_candidates(Path("proj/data/fixtures"), candidates_path, top_n=5)

    select_evaluate(
        data_dir=Path("proj/data/fixtures"),
        candidates_path=candidates_path,
        output_dir=output_dir,
        budget=18,
        seed=13,
        optimal_max_items=5,
        overwrite=False,
    )

    outputs = generate_artifacts(output_dir, artifact_dir)

    assert artifact_dir / "comparison_table.md" in outputs


def test_select_evaluate_rejects_overwrite_of_candidate_directory(tmp_path):
    candidates_dir = tmp_path / "staged"
    candidates_dir.mkdir()
    candidates_path = candidates_dir / "candidates.jsonl"
    generate_candidates(Path("proj/data/fixtures"), candidates_path, top_n=3)

    with pytest.raises(DataValidationError, match="output directory must not contain experiment inputs"):
        select_evaluate(
            data_dir=Path("proj/data/fixtures"),
            candidates_path=candidates_path,
            output_dir=candidates_dir,
            budget=18,
            seed=13,
            overwrite=True,
        )

    assert candidates_path.exists()


def test_select_evaluate_allows_output_beside_candidate_file(tmp_path):
    candidates_dir = tmp_path / "staged"
    candidates_dir.mkdir()
    candidates_path = candidates_dir / "candidates.jsonl"
    generate_candidates(Path("proj/data/fixtures"), candidates_path, top_n=3)
    output_dir = candidates_dir / "outputs"

    summary = select_evaluate(
        data_dir=Path("proj/data/fixtures"),
        candidates_path=candidates_path,
        output_dir=output_dir,
        budget=18,
        seed=13,
        overwrite=False,
    )

    assert summary["queries"] == 3
    assert candidates_path.exists()
    assert (output_dir / "per_query_metrics.jsonl").exists()


def test_select_evaluate_rejects_symlinked_output_parent(tmp_path):
    candidates_dir = tmp_path / "staged"
    candidates_dir.mkdir()
    candidates_path = candidates_dir / "candidates.jsonl"
    generate_candidates(Path("proj/data/fixtures"), candidates_path, top_n=3)
    target_dir = tmp_path / "outside-target"
    target_dir.mkdir()
    output_parent = tmp_path / "selected-parent-link"
    output_parent.symlink_to(target_dir, target_is_directory=True)

    with pytest.raises(DataValidationError, match="output parent path is a symlink"):
        select_evaluate(
            data_dir=Path("proj/data/fixtures"),
            candidates_path=candidates_path,
            output_dir=output_parent / "selected",
            budget=18,
            seed=13,
            overwrite=False,
        )

    assert not (target_dir / "selected" / "config.json").exists()


def test_generate_candidates_rejects_output_inside_data_dir(tmp_path):
    data_dir = tmp_path / "fixture-copy"
    _copy_fixture_dataset(data_dir)
    queries_path = data_dir / "queries.jsonl"
    original_queries = queries_path.read_text(encoding="utf-8")

    with pytest.raises(DataValidationError, match="output path must not overwrite dataset inputs"):
        generate_candidates(data_dir, queries_path, top_n=3)

    assert queries_path.read_text(encoding="utf-8") == original_queries


def test_generate_candidates_rejects_directory_output_path(tmp_path):
    output_path = tmp_path / "candidate-dir"
    output_path.mkdir()

    with pytest.raises(DataValidationError, match="output path is not a file"):
        generate_candidates(Path("proj/data/fixtures"), output_path, top_n=3)


def test_generate_candidates_rejects_symlink_output_path(tmp_path):
    target_file = tmp_path / "outside.jsonl"
    target_file.write_text("outside\n", encoding="utf-8")
    output_path = tmp_path / "candidates-link.jsonl"
    output_path.symlink_to(target_file)

    with pytest.raises(DataValidationError, match="output path is a symlink"):
        generate_candidates(Path("proj/data/fixtures"), output_path, top_n=3)

    assert target_file.read_text(encoding="utf-8") == "outside\n"


def test_generate_candidates_rejects_symlink_output_parent(tmp_path):
    target_dir = tmp_path / "outside-target"
    target_dir.mkdir()
    output_parent = tmp_path / "candidate-link-dir"
    output_parent.symlink_to(target_dir, target_is_directory=True)

    with pytest.raises(DataValidationError, match="output parent path is a symlink"):
        generate_candidates(Path("proj/data/fixtures"), output_parent / "candidates.jsonl", top_n=3)

    assert not (target_dir / "candidates.jsonl").exists()


def test_generate_candidates_rejects_nested_symlink_output_parent(tmp_path):
    target_dir = tmp_path / "outside-target"
    target_dir.mkdir()
    (target_dir / "nested").mkdir()
    output_parent = tmp_path / "candidate-link-dir"
    output_parent.symlink_to(target_dir, target_is_directory=True)

    with pytest.raises(DataValidationError, match="output parent path is a symlink"):
        generate_candidates(Path("proj/data/fixtures"), output_parent / "nested" / "candidates.jsonl", top_n=3)

    assert not (target_dir / "nested" / "candidates.jsonl").exists()


def test_run_experiment_labels_multiple_combined_lambdas(tmp_path):
    output_dir = tmp_path / "lambda-run"
    run_experiment(
        ExperimentConfig(
            data_dir="proj/data/fixtures",
            output_dir=str(output_dir),
            budgets=(18,),
            candidate_sizes=(3,),
            selectors=("budgeted_greedy",),
            objectives=("combined",),
            combined_lambdas=(0.5, 1.0),
            seed=13,
            optimal_max_items=3,
        )
    )

    labels = {row["method_label"] for row in read_jsonl(output_dir / "selections.jsonl")}

    assert labels == {"submodular_combined_lambda_0.5", "submodular_combined_lambda_1"}


def _copy_fixture_dataset(output_dir: Path) -> None:
    output_dir.mkdir()
    for filename in ("queries.jsonl", "corpus.jsonl"):
        source = Path("proj/data/fixtures") / filename
        (output_dir / filename).write_text(source.read_text(encoding="utf-8"), encoding="utf-8")


def test_select_evaluate_rejects_malformed_candidate_file(tmp_path):
    candidates_dir = tmp_path / "candidates"
    candidates_dir.mkdir()
    candidates_path = candidates_dir / "bad-candidates.jsonl"
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
    candidates_dir = tmp_path / "candidates"
    candidates_dir.mkdir()
    candidates_path = candidates_dir / "candidates.jsonl"
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


def test_select_evaluate_uses_safe_default_optimal_threshold(tmp_path):
    candidates_dir = tmp_path / "candidates"
    candidates_dir.mkdir()
    candidates_path = candidates_dir / "candidates.jsonl"
    output_dir = tmp_path / "selected"
    generate_candidates(Path("proj/data/fixtures"), candidates_path, top_n=20)

    select_evaluate(
        data_dir=Path("proj/data/fixtures"),
        candidates_path=candidates_path,
        output_dir=output_dir,
        budget=18,
        seed=13,
        overwrite=False,
    )

    config = json.loads((output_dir / "config.json").read_text(encoding="utf-8"))

    assert config["optimal_max_items"] == 16


def test_select_evaluate_rejects_float_candidate_integer_fields(tmp_path):
    candidates_dir = tmp_path / "candidates"
    candidates_dir.mkdir()
    candidates_path = candidates_dir / "candidates.jsonl"
    generate_candidates(Path("proj/data/fixtures"), candidates_path, top_n=3)
    rows = read_jsonl(candidates_path)
    rows[0]["rank"] = 1.5
    candidates_path.write_text("\n".join(json.dumps(row, sort_keys=True) for row in rows) + "\n", encoding="utf-8")

    with pytest.raises(DataValidationError, match="positive integer"):
        select_evaluate(
            data_dir=Path("proj/data/fixtures"),
            candidates_path=candidates_path,
            output_dir=tmp_path / "selected",
            budget=18,
            seed=13,
            overwrite=False,
        )


def test_select_evaluate_rejects_truncated_candidate_blocks(tmp_path):
    candidates_dir = tmp_path / "candidates"
    candidates_dir.mkdir()
    candidates_path = candidates_dir / "candidates.jsonl"
    generate_candidates(Path("proj/data/fixtures"), candidates_path, top_n=3)
    rows = read_jsonl(candidates_path)
    rows = [row for row in rows if not (row["query_id"] == "q1" and row["rank"] == 3)]
    candidates_path.write_text("\n".join(json.dumps(row, sort_keys=True) for row in rows) + "\n", encoding="utf-8")

    with pytest.raises(DataValidationError, match="fewer than top_n"):
        select_evaluate(
            data_dir=Path("proj/data/fixtures"),
            candidates_path=candidates_path,
            output_dir=tmp_path / "selected",
            budget=18,
            seed=13,
            overwrite=False,
        )


def test_select_evaluate_rejects_partial_candidate_file_with_stale_sample_config(tmp_path):
    candidates_dir = tmp_path / "candidates"
    candidates_dir.mkdir()
    candidates_path = candidates_dir / "candidates.jsonl"
    generate_candidates(Path("proj/data/fixtures"), candidates_path, top_n=3)
    source_rows = read_jsonl(candidates_path)
    rows = [row for row in source_rows if row["query_id"] != "q3"]
    candidates_path.write_text("\n".join(json.dumps(row, sort_keys=True) for row in rows) + "\n", encoding="utf-8")
    (candidates_dir / "sample_manifest.jsonl").write_text(
        "\n".join(json.dumps({"query_id": query_id}) for query_id in ["q1", "q2"]) + "\n",
        encoding="utf-8",
    )
    (candidates_dir / "config.json").write_text(
        json.dumps(
            {
                "candidate_sizes": [3],
                "candidates_fingerprint": "stale",
                "query_ids": ["q1", "q2"],
                "sample_size": 2,
            },
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )

    with pytest.raises(DataValidationError, match="candidate file missing queries"):
        select_evaluate(
            data_dir=Path("proj/data/fixtures"),
            candidates_path=candidates_path,
            output_dir=tmp_path / "selected",
            budget=18,
            seed=13,
            overwrite=False,
        )
