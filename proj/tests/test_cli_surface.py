import json

from proj.src.cli import main


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


def test_cli_prepare_data_writes_processed_cache(tmp_path, capsys):
    raw_path = tmp_path / "raw.jsonl"
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


def test_cli_select_evaluate_consumes_candidate_file(tmp_path, capsys):
    candidates_path = tmp_path / "candidates.jsonl"
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
