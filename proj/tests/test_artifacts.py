import pytest

from proj.src.artifacts import ArtifactValidationError, generate_artifacts
from proj.src.experiments import ExperimentConfig, run_experiment


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


def test_generate_artifacts_rejects_incompatible_metric_schema(tmp_path):
    run_dir = tmp_path / "run"
    run_dir.mkdir()
    (run_dir / "aggregate_metrics.csv").write_text("method_label,evidence_f1_mean\nbad,0.0\n", encoding="utf-8")
    (run_dir / "optimal_checks.csv").write_text("status\nexecuted\n", encoding="utf-8")

    with pytest.raises(ArtifactValidationError, match="missing required columns"):
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
