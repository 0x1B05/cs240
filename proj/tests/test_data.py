from pathlib import Path

import pytest

from proj.src.data import DataValidationError, Dataset, Document, Query, load_dataset, read_jsonl


def test_load_fixture_dataset_is_stable():
    dataset = load_dataset(Path("proj/data/fixtures"))

    assert [query.query_id for query in dataset.queries] == ["q1", "q2", "q3"]
    assert dataset.queries[0].evidence_ids == ("d1", "d2")
    assert dataset.corpus[0].doc_id == "d1"


def test_read_jsonl_rejects_directory_input(tmp_path):
    jsonl_path = tmp_path / "queries.jsonl"
    jsonl_path.mkdir()

    with pytest.raises(DataValidationError, match="input path is not a file"):
        read_jsonl(jsonl_path)


def test_missing_evidence_id_is_rejected():
    dataset = Dataset(
        queries=(Query(query_id="q", query="query", answer="", evidence_ids=("missing",)),),
        corpus=(Document(doc_id="d", text="document text"),),
    )

    with pytest.raises(DataValidationError, match="missing evidence"):
        from proj.src.data import validate_dataset

        validate_dataset(dataset)
