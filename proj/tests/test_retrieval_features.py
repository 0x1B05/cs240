from pathlib import Path

import pytest

from proj.src.data import DataValidationError, load_dataset
from proj.src.features import build_features
from proj.src.retrieval import retrieve_top_n


def test_retrieve_top_n_returns_stable_candidates():
    dataset = load_dataset(Path("proj/data/fixtures"))
    candidates = retrieve_top_n(dataset, top_n=3)

    assert set(candidates) == {"q1", "q2", "q3"}
    assert len(candidates["q1"]) == 3
    assert candidates["q1"][0].rank == 1
    assert candidates["q1"][0].token_cost > 0


def test_retrieve_rejects_nonpositive_top_n():
    dataset = load_dataset(Path("proj/data/fixtures"))

    with pytest.raises(DataValidationError, match="top_n"):
        retrieve_top_n(dataset, top_n=0)


def test_build_features_shapes_are_consistent():
    dataset = load_dataset(Path("proj/data/fixtures"))
    query = dataset.queries[0]
    candidates = retrieve_top_n(dataset, top_n=4)[query.query_id]

    features = build_features(query.query, candidates)

    assert len(features.doc_ids) == 4
    assert len(features.costs) == 4
    assert len(features.relevance) == 4
    assert len(features.similarity) == 4
    assert features.similarity[0][1] == features.similarity[1][0]
