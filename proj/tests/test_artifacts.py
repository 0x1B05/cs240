import csv

import pytest

from proj.src.artifacts import ArtifactValidationError, REQUIRED_AGGREGATE_COLUMNS, generate_artifacts
from proj.src.experiments import ExperimentConfig, run_experiment


def _write_csv(path, fieldnames, rows):
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def _aggregate_row(method_label, selector, objective):
    return {
        "method_label": method_label,
        "selector": selector,
        "objective": objective,
        "lambda_value": "1.0",
        "budget": "18",
        "top_n": "5",
        "queries": "1",
        "evidence_recall_mean": "0.5",
        "evidence_recall_std": "0.0",
        "evidence_f1_mean": "0.5",
        "evidence_f1_std": "0.0",
        "redundancy_mean": "0.0",
        "budget_utilization_mean": "0.8",
        "runtime_units_mean": "10",
    }


def _optimal_row(selector, objective, lambda_value, budget, top_n):
    return {
        "query_id": "q1",
        "selector": selector,
        "objective": objective,
        "lambda_value": lambda_value,
        "budget": str(budget),
        "top_n": str(top_n),
        "status": "executed" if selector == "budgeted_greedy" else "skipped",
        "reason": "" if selector == "budgeted_greedy" else "nondeterministic_or_baseline_selector",
        "greedy_value": "1.0",
        "optimal_value": "1.0" if selector == "budgeted_greedy" else "",
        "greedy_cost": "1",
        "optimal_cost": "1" if selector == "budgeted_greedy" else "",
        "approx_ratio": "1.0" if selector == "budgeted_greedy" else "",
    }


def _write_minimal_artifact_inputs(run_dir, optimal_rows):
    run_dir.mkdir()
    aggregate_rows = [
        _aggregate_row("top_ranked", "top_ranked", "none"),
        _aggregate_row("relevance_ratio", "relevance_ratio", "none"),
        _aggregate_row("random_seeded", "random_seeded", "none"),
        _aggregate_row("mmr", "mmr", "none"),
        _aggregate_row("submodular_coverage", "budgeted_greedy", "coverage"),
        _aggregate_row("submodular_diversity", "budgeted_greedy", "diversity"),
        _aggregate_row("submodular_combined", "budgeted_greedy", "combined"),
    ]
    _write_csv(run_dir / "aggregate_metrics.csv", list(aggregate_rows[0]), aggregate_rows)
    _write_csv(run_dir / "optimal_checks.csv", list(optimal_rows[0]), optimal_rows)


def test_generate_artifacts_creates_report_tables(tmp_path):
    run_dir = tmp_path / "run"
    artifact_dir = tmp_path / "artifacts"
    run_experiment(
        ExperimentConfig(
            data_dir="proj/data/fixtures",
            output_dir=str(run_dir),
            budgets=(18,),
            candidate_sizes=(5,),
            selectors=("top_ranked", "relevance_ratio", "random_seeded", "mmr", "budgeted_greedy"),
            objectives=("coverage", "diversity", "combined"),
            seed=13,
            optimal_max_items=5,
        )
    )

    outputs = generate_artifacts(run_dir, artifact_dir)

    expected = {
        "comparison_table.md",
        "metric_by_budget.md",
        "runtime_by_candidate_size.md",
        "optimal_checks.md",
    }
    assert expected.issubset({path.name for path in outputs})
    assert "submodular_combined" in (artifact_dir / "comparison_table.md").read_text(encoding="utf-8")
    assert "runtime_units_mean" in (artifact_dir / "runtime_by_candidate_size.md").read_text(encoding="utf-8")


def test_generate_artifacts_accepts_multi_lambda_combined_labels(tmp_path):
    run_dir = tmp_path / "run"
    artifact_dir = tmp_path / "artifacts"
    run_experiment(
        ExperimentConfig(
            data_dir="proj/data/fixtures",
            output_dir=str(run_dir),
            budgets=(18,),
            candidate_sizes=(5,),
            selectors=("top_ranked", "relevance_ratio", "random_seeded", "mmr", "budgeted_greedy"),
            objectives=("coverage", "diversity", "combined"),
            combined_lambdas=(0.5, 1.0),
            seed=13,
            optimal_max_items=5,
        )
    )

    generate_artifacts(run_dir, artifact_dir)

    comparison = (artifact_dir / "comparison_table.md").read_text(encoding="utf-8")
    assert "submodular_combined_lambda_0.5" in comparison
    assert "submodular_combined_lambda_1" in comparison


def test_generate_artifacts_preserves_optimal_check_config_identity(tmp_path):
    run_dir = tmp_path / "run"
    artifact_dir = tmp_path / "artifacts"
    _write_minimal_artifact_inputs(
        run_dir,
        [
            _optimal_row("top_ranked", "none", "1.0", 18, 5),
            _optimal_row("relevance_ratio", "none", "1.0", 18, 5),
            _optimal_row("budgeted_greedy", "combined", "0.5", 18, 5),
            _optimal_row("budgeted_greedy", "combined", "1.0", 18, 5),
        ],
    )

    generate_artifacts(run_dir, artifact_dir)

    optimal = (artifact_dir / "optimal_checks.md").read_text(encoding="utf-8")
    assert "| Query | Selector | Objective | Lambda | Budget | Top N | Status | Greedy | Optimal | Approx Ratio |" in optimal
    assert "| q1 | top_ranked | none | 1.0 | 18 | 5 | skipped | 1.000 |  |  |" in optimal
    assert "| q1 | relevance_ratio | none | 1.0 | 18 | 5 | skipped | 1.000 |  |  |" in optimal
    assert "| q1 | budgeted_greedy | combined | 0.5 | 18 | 5 | executed | 1.000 | 1.000 | 1.000 |" in optimal
    assert "| q1 | budgeted_greedy | combined | 1.0 | 18 | 5 | executed | 1.000 | 1.000 | 1.000 |" in optimal


def test_generate_artifacts_sorts_optimal_checks_by_numeric_budget_and_top_n(tmp_path):
    run_dir = tmp_path / "run"
    artifact_dir = tmp_path / "artifacts"
    _write_minimal_artifact_inputs(
        run_dir,
        [
            _optimal_row("budgeted_greedy", "combined", "1.0", 160, 2),
            _optimal_row("budgeted_greedy", "combined", "1.0", 80, 10),
            _optimal_row("budgeted_greedy", "combined", "1.0", 320, 2),
            _optimal_row("budgeted_greedy", "combined", "1.0", 80, 2),
        ],
    )

    generate_artifacts(run_dir, artifact_dir)

    optimal = (artifact_dir / "optimal_checks.md").read_text(encoding="utf-8")
    row_80_2 = optimal.index("| 80 | 2 |")
    row_80_10 = optimal.index("| 80 | 10 |")
    row_160_2 = optimal.index("| 160 | 2 |")
    row_320_2 = optimal.index("| 320 | 2 |")
    assert row_80_2 < row_80_10 < row_160_2 < row_320_2


def test_generate_artifacts_rejects_file_output_dir(tmp_path):
    run_dir = tmp_path / "run"
    artifact_path = tmp_path / "artifacts.md"
    artifact_path.write_text("collision\n", encoding="utf-8")
    _write_minimal_artifact_inputs(run_dir, [_optimal_row("budgeted_greedy", "combined", "1.0", 18, 5)])

    with pytest.raises(ArtifactValidationError, match="output path is not a directory"):
        generate_artifacts(run_dir, artifact_path)

    assert artifact_path.read_text(encoding="utf-8") == "collision\n"


def test_generate_artifacts_rejects_symlink_output_dir(tmp_path):
    run_dir = tmp_path / "run"
    target_dir = tmp_path / "outside-target"
    target_dir.mkdir()
    target_file = target_dir / "keep.txt"
    target_file.write_text("outside\n", encoding="utf-8")
    artifact_dir = tmp_path / "artifacts-link"
    artifact_dir.symlink_to(target_dir, target_is_directory=True)
    _write_minimal_artifact_inputs(run_dir, [_optimal_row("budgeted_greedy", "combined", "1.0", 18, 5)])

    with pytest.raises(ArtifactValidationError, match="output path is a symlink"):
        generate_artifacts(run_dir, artifact_dir)

    assert target_file.read_text(encoding="utf-8") == "outside\n"
    assert not (target_dir / "comparison_table.md").exists()


def test_generate_artifacts_rejects_symlink_output_parent(tmp_path):
    run_dir = tmp_path / "run"
    target_dir = tmp_path / "outside-target"
    target_dir.mkdir()
    output_parent = tmp_path / "artifacts-parent-link"
    output_parent.symlink_to(target_dir, target_is_directory=True)
    _write_minimal_artifact_inputs(run_dir, [_optimal_row("budgeted_greedy", "combined", "1.0", 18, 5)])

    with pytest.raises(ArtifactValidationError, match="output parent path is a symlink"):
        generate_artifacts(run_dir, output_parent / "artifacts")

    assert not (target_dir / "artifacts" / "comparison_table.md").exists()


def test_generate_artifacts_rejects_incompatible_metric_schema(tmp_path):
    run_dir = tmp_path / "run"
    run_dir.mkdir()
    (run_dir / "aggregate_metrics.csv").write_text("method_label,evidence_f1_mean\nbad,0.0\n", encoding="utf-8")
    (run_dir / "optimal_checks.csv").write_text("status\nexecuted\n", encoding="utf-8")

    with pytest.raises(ArtifactValidationError, match="missing required columns"):
        generate_artifacts(run_dir, tmp_path / "artifacts")


def test_generate_artifacts_rejects_directory_metric_input(tmp_path):
    run_dir = tmp_path / "run"
    run_dir.mkdir()
    (run_dir / "aggregate_metrics.csv").mkdir()
    (run_dir / "optimal_checks.csv").write_text("status\nexecuted\n", encoding="utf-8")

    with pytest.raises(ArtifactValidationError, match="artifact input is not a file"):
        generate_artifacts(run_dir, tmp_path / "artifacts")


def test_generate_artifacts_rejects_empty_numeric_cells(tmp_path):
    run_dir = tmp_path / "run"
    rows = [
        _aggregate_row("top_ranked", "top_ranked", "none"),
        _aggregate_row("relevance_ratio", "relevance_ratio", "none"),
        _aggregate_row("random_seeded", "random_seeded", "none"),
        _aggregate_row("mmr", "mmr", "none"),
        _aggregate_row("submodular_coverage", "budgeted_greedy", "coverage"),
        _aggregate_row("submodular_diversity", "budgeted_greedy", "diversity"),
        _aggregate_row("submodular_combined", "budgeted_greedy", "combined"),
    ]
    rows[0]["budget"] = None
    _write_minimal_artifact_inputs(run_dir, [_optimal_row("budgeted_greedy", "combined", "1.0", 18, 5)])
    _write_csv(run_dir / "aggregate_metrics.csv", list(REQUIRED_AGGREGATE_COLUMNS), rows)

    with pytest.raises(ArtifactValidationError, match="non-numeric aggregate column: budget"):
        generate_artifacts(run_dir, tmp_path / "artifacts")


def test_generate_artifacts_rejects_truncated_numeric_cells(tmp_path):
    run_dir = tmp_path / "run"
    run_dir.mkdir()
    columns = [
        "method_label",
        "selector",
        "objective",
        "lambda_value",
        "top_n",
        "queries",
        "evidence_recall_mean",
        "evidence_recall_std",
        "evidence_f1_mean",
        "evidence_f1_std",
        "redundancy_mean",
        "budget_utilization_mean",
        "runtime_units_mean",
        "budget",
    ]
    values = ["top_ranked", "top_ranked", "none", "1.0", "5", "1", "0.5", "0.0", "0.5", "0.0", "0.0", "0.8", "10"]
    (run_dir / "aggregate_metrics.csv").write_text(",".join(columns) + "\n" + ",".join(values) + "\n", encoding="utf-8")
    _write_csv(run_dir / "optimal_checks.csv", list(_optimal_row("budgeted_greedy", "combined", "1.0", 18, 5)), [_optimal_row("budgeted_greedy", "combined", "1.0", 18, 5)])

    with pytest.raises(ArtifactValidationError, match="non-numeric aggregate column: budget"):
        generate_artifacts(run_dir, tmp_path / "artifacts")


def test_generate_artifacts_rejects_missing_required_methods(tmp_path):
    run_dir = tmp_path / "run"
    artifact_dir = tmp_path / "artifacts"
    run_experiment(
        ExperimentConfig(
            data_dir="proj/data/fixtures",
            output_dir=str(run_dir),
            budgets=(18,),
            candidate_sizes=(5,),
            selectors=("top_ranked",),
            objectives=("combined",),
            seed=13,
            optimal_max_items=5,
        )
    )

    with pytest.raises(ArtifactValidationError, match="required methods"):
        generate_artifacts(run_dir, artifact_dir)


def test_generate_artifacts_rejects_missing_submodular_objective_rows(tmp_path):
    run_dir = tmp_path / "run"
    artifact_dir = tmp_path / "artifacts"
    run_experiment(
        ExperimentConfig(
            data_dir="proj/data/fixtures",
            output_dir=str(run_dir),
            budgets=(18,),
            candidate_sizes=(5,),
            selectors=("top_ranked", "relevance_ratio", "random_seeded", "mmr", "budgeted_greedy"),
            objectives=("combined",),
            seed=13,
            optimal_max_items=5,
        )
    )

    with pytest.raises(ArtifactValidationError, match="submodular objectives"):
        generate_artifacts(run_dir, artifact_dir)
