from pathlib import Path

import pytest

from proj.src.data import Candidate, DataValidationError, Dataset, Document, Query, load_dataset
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


def test_retrieve_top_n_is_independent_of_unrelated_queries():
    corpus = (
        Document(doc_id="d-alpha", text="alpha alpha alpha beta"),
        Document(doc_id="d-beta", text="alpha beta beta beta"),
        Document(doc_id="d-noise", text="gamma delta epsilon"),
    )
    target = Query(query_id="q-target", query="alpha beta", answer="", evidence_ids=("d-alpha",))
    unrelated = Query(query_id="q-unrelated", query="beta beta beta beta", answer="", evidence_ids=("d-beta",))
    one_query = Dataset(queries=(target,), corpus=corpus)
    two_queries = Dataset(queries=(target, unrelated), corpus=corpus)

    single = retrieve_top_n(one_query, top_n=3)["q-target"]
    batched = retrieve_top_n(two_queries, top_n=3)["q-target"]

    assert [(item.doc_id, item.score) for item in batched] == [(item.doc_id, item.score) for item in single]


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


def test_build_features_similarity_is_independent_of_query_text():
    candidates = [
        Candidate(query_id="q", doc_id="d1", rank=1, score=1.0, text="alpha alpha beta", token_cost=3),
        Candidate(query_id="q", doc_id="d2", rank=2, score=0.9, text="alpha beta beta", token_cost=3),
        Candidate(query_id="q", doc_id="d3", rank=3, score=0.1, text="gamma delta", token_cost=2),
    ]

    first = build_features("alpha beta", candidates)
    second = build_features("gamma gamma gamma", candidates)

    assert first.similarity == second.similarity


def test_build_features_can_use_stable_reference_texts_across_candidate_prefixes():
    candidates = [
        Candidate(query_id="q", doc_id="d1", rank=1, score=1.0, text="alpha alpha rare", token_cost=3),
        Candidate(query_id="q", doc_id="d2", rank=2, score=0.9, text="alpha beta", token_cost=2),
        Candidate(query_id="q", doc_id="d3", rank=3, score=0.8, text="unrelated unrelated", token_cost=2),
    ]
    reference_texts = [candidate.text for candidate in candidates]

    prefix = build_features("alpha", candidates[:2], reference_texts=reference_texts)
    full = build_features("alpha", candidates, reference_texts=reference_texts)

    assert prefix.relevance == full.relevance[:2]
    assert prefix.similarity[0] == full.similarity[0][:2]
    assert prefix.similarity[1] == full.similarity[1][:2]
