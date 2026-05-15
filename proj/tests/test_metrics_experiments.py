import json
from pathlib import Path

import pytest

from proj.src.data import DataValidationError, Selection, load_dataset
from proj.src.experiments import run_smoke
from proj.src.features import build_features
from proj.src.metrics import evaluate_selection
from proj.src.retrieval import retrieve_top_n


def test_evidence_metrics_for_full_hit():
    dataset = load_dataset(Path("proj/data/fixtures"))
    query = dataset.queries[2]
    candidates = retrieve_top_n(dataset, top_n=5)[query.query_id]
    features = build_features(query.query, candidates)
    selected = tuple(doc_id for doc_id in query.evidence_ids if doc_id in features.doc_ids)
    selection = Selection(query_id=query.query_id, method="test", selected_doc_ids=selected, total_cost=1)

    metrics = evaluate_selection(query, features, selection, budget=10)

    assert metrics.evidence_recall == 1.0
    assert metrics.evidence_precision == 1.0
    assert metrics.evidence_f1 == 1.0


def test_metrics_reject_unknown_selected_doc():
    dataset = load_dataset(Path("proj/data/fixtures"))
    query = dataset.queries[0]
    candidates = retrieve_top_n(dataset, top_n=5)[query.query_id]
    features = build_features(query.query, candidates)
    selection = Selection(query_id=query.query_id, method="bad", selected_doc_ids=("missing",), total_cost=1)

    with pytest.raises(DataValidationError, match="outside"):
        evaluate_selection(query, features, selection, budget=10)


def test_run_smoke_writes_metrics(tmp_path):
    output_dir = tmp_path / "smoke"

    metrics = run_smoke(Path("proj/data/fixtures"), output_dir, budget=18, top_n=5)

    assert "submodular_combined" in metrics["aggregate"]
    assert (output_dir / "metrics.json").exists()
    assert (output_dir / "summary.md").exists()
    loaded = json.loads((output_dir / "metrics.json").read_text(encoding="utf-8"))
    assert loaded["config"]["budget"] == 18
