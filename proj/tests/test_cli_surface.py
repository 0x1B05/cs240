import json
import os
from pathlib import Path
import subprocess
import sys

from proj.src.cli import main
from proj.src.experiments import ExperimentConfig, run_experiment


def test_cli_help_lists_full_experiment_surface(capsys):
    exit_code = main(["--help"])
    captured = capsys.readouterr()

    assert exit_code == 0
    for command in [
        "prepare-data",
        "generate-candidates",
        "select-evaluate",
        "run-experiment",
        "generate-artifacts",
        "run-smoke",
    ]:
        assert command in captured.out


def test_cli_run_smoke_default_data_dir_is_independent_of_cwd(tmp_path):
    output_dir = tmp_path / "smoke"
    result = subprocess.run(
        [
            sys.executable,
            "-m",
            "proj.src",
            "run-smoke",
            "--output-dir",
            str(output_dir),
        ],
        check=False,
        capture_output=True,
        cwd=tmp_path,
        env={**os.environ, "PYTHONPATH": str(Path(__file__).resolve().parents[2])},
        text=True,
    )

    assert result.returncode == 0
    assert (output_dir / "metrics.json").exists()


def test_cli_prepare_data_writes_processed_cache(tmp_path, capsys):
    raw_dir = tmp_path / "raw"
    raw_dir.mkdir()
    raw_path = raw_dir / "raw.jsonl"
    raw_path.write_text(
        json.dumps(
            {
                "id": "q1",
                "question": "Where is the Louvre?",
                "answer": "Paris",
                "evidence_ids": ["d1"],
                "contexts": [{"id": "d1", "text": "The Louvre is in Paris."}],
            }
        )
        + "\n",
        encoding="utf-8",
    )
    output_dir = tmp_path / "processed"

    exit_code = main(
        [
            "prepare-data",
            "--raw-queries",
            str(raw_path),
            "--schema",
            "embedded",
            "--output-dir",
            str(output_dir),
            "--seed",
            "13",
        ]
    )
    captured = capsys.readouterr()

    assert exit_code == 0
    assert "wrote processed cache" in captured.out
    assert (output_dir / "queries.jsonl").exists()
    assert (output_dir / "corpus.jsonl").exists()
    assert (output_dir / "manifest.json").exists()


def test_cli_missing_input_path_fails(tmp_path, capsys):
    exit_code = main(
        [
            "prepare-data",
            "--raw-queries",
            str(tmp_path / "missing.jsonl"),
            "--schema",
            "embedded",
            "--output-dir",
            str(tmp_path / "processed"),
        ]
    )
    captured = capsys.readouterr()

    assert exit_code == 2
    assert "missing input file" in captured.err


def test_package_entry_point_propagates_failure_exit_code(tmp_path):
    result = subprocess.run(
        [
            sys.executable,
            "-m",
            "proj.src",
            "prepare-data",
            "--raw-queries",
            str(tmp_path / "missing.jsonl"),
            "--schema",
            "embedded",
            "--output-dir",
            str(tmp_path / "processed"),
        ],
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode == 2
    assert "missing input file" in result.stderr


def test_cli_generate_candidates_writes_top_n_column(tmp_path, capsys):
    output_path = tmp_path / "candidates.jsonl"

    exit_code = main(
        [
            "generate-candidates",
            "--data-dir",
            "proj/data/fixtures",
            "--output-path",
            str(output_path),
            "--top-n",
            "3",
        ]
    )
    captured = capsys.readouterr()

    assert exit_code == 0
    assert "wrote" in captured.out
    first = json.loads(output_path.read_text(encoding="utf-8").splitlines()[0])
    assert first["top_n"] == 3


def test_cli_generate_candidates_rejects_directory_output_path(tmp_path, capsys):
    output_path = tmp_path / "candidate-dir"
    output_path.mkdir()

    exit_code = main(
        [
            "generate-candidates",
            "--data-dir",
            "proj/data/fixtures",
            "--output-path",
            str(output_path),
            "--top-n",
            "3",
        ]
    )
    captured = capsys.readouterr()

    assert exit_code == 2
    assert "output path is not a file" in captured.err


def test_cli_select_evaluate_consumes_candidate_file(tmp_path, capsys):
    candidates_dir = tmp_path / "candidates"
    candidates_dir.mkdir()
    candidates_path = candidates_dir / "candidates.jsonl"
    output_dir = tmp_path / "selected"
    assert (
        main(
            [
                "generate-candidates",
                "--data-dir",
                "proj/data/fixtures",
                "--output-path",
                str(candidates_path),
                "--top-n",
                "3",
            ]
        )
        == 0
    )

    exit_code = main(
        [
            "select-evaluate",
            "--data-dir",
            "proj/data/fixtures",
            "--candidates-path",
            str(candidates_path),
            "--output-dir",
            str(output_dir),
            "--budget",
            "18",
            "--seed",
            "13",
        ]
    )
    captured = capsys.readouterr()

    assert exit_code == 0
    assert "selection/evaluation" in captured.out
    assert (output_dir / "per_query_metrics.jsonl").exists()


def test_cli_select_evaluate_generates_artifact_compatible_grid(tmp_path, capsys):
    candidates_dir = tmp_path / "candidates"
    candidates_dir.mkdir()
    candidates_path = candidates_dir / "candidates.jsonl"
    selected_dir = tmp_path / "selected"
    artifact_dir = tmp_path / "artifacts"
    assert (
        main(
            [
                "generate-candidates",
                "--data-dir",
                "proj/data/fixtures",
                "--output-path",
                str(candidates_path),
                "--top-n",
                "5",
            ]
        )
        == 0
    )
    capsys.readouterr()

    exit_code = main(
        [
            "select-evaluate",
            "--data-dir",
            "proj/data/fixtures",
            "--candidates-path",
            str(candidates_path),
            "--output-dir",
            str(selected_dir),
            "--budget",
            "18",
            "--seed",
            "13",
            "--selectors",
            "top_ranked,relevance_ratio,random_seeded,mmr,budgeted_greedy",
            "--objectives",
            "coverage,diversity,combined",
            "--combined-lambdas",
            "1.0",
            "--optimal-max-items",
            "5",
        ]
    )
    selected = capsys.readouterr()

    assert exit_code == 0
    assert "selection/evaluation" in selected.out

    exit_code = main(
        [
            "generate-artifacts",
            "--run-dir",
            str(selected_dir),
            "--output-dir",
            str(artifact_dir),
        ]
    )
    artifacts = capsys.readouterr()

    assert exit_code == 0
    assert "report artifacts" in artifacts.out
    assert (artifact_dir / "comparison_table.md").exists()


def test_cli_select_evaluate_default_grid_supports_artifacts(tmp_path, capsys):
    candidates_path = tmp_path / "candidates.jsonl"
    selected_dir = tmp_path / "selected"
    artifact_dir = tmp_path / "artifacts"
    assert (
        main(
            [
                "generate-candidates",
                "--data-dir",
                "proj/data/fixtures",
                "--output-path",
                str(candidates_path),
                "--top-n",
                "5",
            ]
        )
        == 0
    )
    capsys.readouterr()

    exit_code = main(
        [
            "select-evaluate",
            "--data-dir",
            "proj/data/fixtures",
            "--candidates-path",
            str(candidates_path),
            "--output-dir",
            str(selected_dir),
            "--budget",
            "18",
            "--seed",
            "13",
            "--optimal-max-items",
            "5",
        ]
    )
    selected = capsys.readouterr()

    assert exit_code == 0
    assert "selection/evaluation" in selected.out

    exit_code = main(
        [
            "generate-artifacts",
            "--run-dir",
            str(selected_dir),
            "--output-dir",
            str(artifact_dir),
        ]
    )
    artifacts = capsys.readouterr()

    assert exit_code == 0
    assert "report artifacts" in artifacts.out
    assert (artifact_dir / "comparison_table.md").exists()


def test_cli_generate_artifacts_rejects_file_output_dir(tmp_path, capsys):
    run_dir = tmp_path / "run"
    output_path = tmp_path / "artifacts.md"
    output_path.write_text("collision\n", encoding="utf-8")
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

    exit_code = main(
        [
            "generate-artifacts",
            "--run-dir",
            str(run_dir),
            "--output-dir",
            str(output_path),
        ]
    )
    captured = capsys.readouterr()

    assert exit_code == 2
    assert "output path is not a directory" in captured.err
    assert output_path.read_text(encoding="utf-8") == "collision\n"
