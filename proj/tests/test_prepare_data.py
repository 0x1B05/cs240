import json
from pathlib import Path

import pytest

from proj.src.data import DataValidationError, load_dataset, prepare_multihop_cache, read_jsonl


def test_prepare_embedded_multihop_cache_is_deterministic(tmp_path):
    raw_path = tmp_path / "raw.jsonl"
    raw_path.write_text(
        "\n".join(
            [
                json.dumps(
                    {
                        "id": "raw-b",
                        "question": "  Which city hosts the Louvre? ",
                        "answer": "Paris",
                        "evidence_list": [{"text": "The Louvre is a museum in Paris."}],
                        "contexts": [
                            {"id": "ctx-b", "text": "The Louvre is a museum in Paris."},
                            {"id": "ctx-c", "text": "Berlin has Museum Island."},
                        ],
                    }
                ),
                json.dumps(
                    {
                        "id": "raw-a",
                        "query": "Where is the Prado Museum?",
                        "answer": "Madrid",
                        "evidence_ids": ["ctx-a"],
                        "candidates": [{"doc_id": "ctx-a", "contents": "The Prado Museum is in Madrid."}],
                    }
                ),
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    output_dir = tmp_path / "processed"

    first_manifest = prepare_multihop_cache(
        raw_queries=raw_path,
        raw_corpus=None,
        output_dir=output_dir,
        schema="embedded",
        sample_size=None,
        seed=13,
        overwrite=False,
    )
    first_queries = (output_dir / "queries.jsonl").read_text(encoding="utf-8")
    first_corpus = (output_dir / "corpus.jsonl").read_text(encoding="utf-8")

    prepare_multihop_cache(
        raw_queries=raw_path,
        raw_corpus=None,
        output_dir=output_dir,
        schema="embedded",
        sample_size=None,
        seed=13,
        overwrite=True,
    )

    assert first_manifest["queries"] == 2
    assert first_manifest["schema"] == "embedded"
    assert first_queries == (output_dir / "queries.jsonl").read_text(encoding="utf-8")
    assert first_corpus == (output_dir / "corpus.jsonl").read_text(encoding="utf-8")
    assert [row["query_id"] for row in read_jsonl(output_dir / "queries.jsonl")] == ["raw-a", "raw-b"]
    assert load_dataset(output_dir).queries[1].query == "Which city hosts the Louvre?"


@pytest.mark.parametrize("overwrite", [False, True])
def test_prepare_embedded_rejects_file_output_path(tmp_path, overwrite):
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
    output_path = tmp_path / "processed"
    output_path.write_text("collision\n", encoding="utf-8")

    with pytest.raises(DataValidationError, match="output path is not a directory"):
        prepare_multihop_cache(
            raw_queries=raw_path,
            raw_corpus=None,
            output_dir=output_path,
            schema="embedded",
            sample_size=None,
            seed=13,
            overwrite=overwrite,
        )


def test_prepare_embedded_accepts_id_only_evidence_objects(tmp_path):
    raw_path = tmp_path / "raw.jsonl"
    raw_path.write_text(
        json.dumps(
            {
                "id": "q1",
                "question": "Where is the Louvre?",
                "answer": "Paris",
                "evidence_list": [{"id": "d1"}],
                "contexts": [{"id": "d1", "text": "The Louvre is in Paris."}],
            }
        )
        + "\n",
        encoding="utf-8",
    )

    prepare_multihop_cache(
        raw_queries=raw_path,
        raw_corpus=None,
        output_dir=tmp_path / "processed",
        schema="embedded",
        sample_size=None,
        seed=13,
        overwrite=False,
    )

    assert read_jsonl(tmp_path / "processed" / "queries.jsonl")[0]["evidence_ids"] == ["d1"]


def test_prepare_embedded_resolves_one_token_text_evidence(tmp_path):
    raw_path = tmp_path / "raw.jsonl"
    raw_path.write_text(
        json.dumps(
            {
                "id": "q1",
                "question": "Which planet?",
                "answer": "Mercury",
                "evidence_list": ["Mercury"],
                "contexts": [{"id": "d1", "text": "Closest planet"}],
            }
        )
        + "\n",
        encoding="utf-8",
    )

    prepare_multihop_cache(
        raw_queries=raw_path,
        raw_corpus=None,
        output_dir=tmp_path / "processed",
        schema="embedded",
        sample_size=None,
        seed=13,
        overwrite=False,
    )

    query = read_jsonl(tmp_path / "processed" / "queries.jsonl")[0]
    corpus_text_by_id = {row["doc_id"]: row["text"] for row in read_jsonl(tmp_path / "processed" / "corpus.jsonl")}
    materialized_id = next(doc_id for doc_id, text in corpus_text_by_id.items() if text == "Mercury")

    assert query["evidence_ids"] == [materialized_id]


def test_prepare_embedded_rejects_ambiguous_global_text_only_evidence(tmp_path):
    raw_path = tmp_path / "raw.jsonl"
    duplicate_text = "shared supporting passage"
    raw_path.write_text(
        "\n".join(
            [
                json.dumps(
                    {
                        "id": "q1",
                        "question": "first",
                        "answer": "a1",
                        "evidence_ids": ["d1"],
                        "contexts": [{"id": "d1", "text": duplicate_text}],
                    }
                ),
                json.dumps(
                    {
                        "id": "q2",
                        "question": "second",
                        "answer": "a2",
                        "evidence_ids": ["d2"],
                        "contexts": [{"id": "d2", "text": duplicate_text}],
                    }
                ),
                json.dumps(
                    {
                        "id": "q3",
                        "question": "third",
                        "answer": "a3",
                        "evidence_list": [duplicate_text],
                        "contexts": [{"id": "d3", "text": "local distractor passage"}],
                    }
                ),
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    with pytest.raises(DataValidationError, match="ambiguous evidence text"):
        prepare_multihop_cache(
            raw_queries=raw_path,
            raw_corpus=None,
            output_dir=tmp_path / "processed",
            schema="embedded",
            sample_size=None,
            seed=13,
            overwrite=False,
        )


def test_prepare_embedded_rejects_ambiguous_materialized_text_only_evidence(tmp_path):
    raw_path = tmp_path / "raw.jsonl"
    duplicate_text = "shared materialized evidence"
    raw_path.write_text(
        "\n".join(
            [
                json.dumps(
                    {
                        "id": "q1",
                        "question": "first",
                        "answer": "a1",
                        "evidence_list": [{"id": "e1", "text": duplicate_text}],
                        "contexts": [{"id": "d1", "text": "first local context"}],
                    }
                ),
                json.dumps(
                    {
                        "id": "q2",
                        "question": "second",
                        "answer": "a2",
                        "evidence_list": [{"id": "e2", "text": duplicate_text}],
                        "contexts": [{"id": "d2", "text": "second local context"}],
                    }
                ),
                json.dumps(
                    {
                        "id": "q3",
                        "question": "third",
                        "answer": "a3",
                        "evidence_list": [duplicate_text],
                        "contexts": [{"id": "d3", "text": "third local context"}],
                    }
                ),
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    with pytest.raises(DataValidationError, match="ambiguous evidence text"):
        prepare_multihop_cache(
            raw_queries=raw_path,
            raw_corpus=None,
            output_dir=tmp_path / "processed",
            schema="embedded",
            sample_size=None,
            seed=13,
            overwrite=False,
        )


def test_prepare_split_multihop_cache_samples_queries_and_keeps_corpus(tmp_path):
    raw_queries = tmp_path / "queries.jsonl"
    raw_corpus = tmp_path / "corpus.jsonl"
    raw_queries.write_text(
        "\n".join(
            [
                json.dumps({"id": "q1", "question": "first", "answer": "a1", "evidence_ids": ["d1"]}),
                json.dumps({"id": "q2", "question": "second", "answer": "a2", "evidence_ids": ["d2"]}),
                json.dumps({"id": "q3", "question": "third", "answer": "a3", "evidence_ids": ["d3"]}),
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    raw_corpus.write_text(
        "\n".join(
            [
                json.dumps({"id": "d1", "passage": "first evidence"}),
                json.dumps({"id": "d2", "passage": "second evidence"}),
                json.dumps({"id": "d3", "passage": "third evidence"}),
                json.dumps({"id": "d4", "passage": "extra distractor"}),
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    output_dir = tmp_path / "processed"

    manifest = prepare_multihop_cache(
        raw_queries=raw_queries,
        raw_corpus=raw_corpus,
        output_dir=output_dir,
        schema="split",
        sample_size=2,
        seed=7,
        overwrite=False,
    )

    assert manifest["queries"] == 2
    assert manifest["corpus"] == 4
    assert manifest["sample_size"] == 2
    assert len(read_jsonl(output_dir / "queries.jsonl")) == 2
    assert len(read_jsonl(output_dir / "corpus.jsonl")) == 4


def test_prepare_split_accepts_id_only_evidence_objects(tmp_path):
    raw_queries = tmp_path / "queries.jsonl"
    raw_corpus = tmp_path / "corpus.jsonl"
    raw_queries.write_text(
        json.dumps({"id": "q1", "question": "first", "answer": "a1", "evidence_list": [{"id": "d1"}]}) + "\n",
        encoding="utf-8",
    )
    raw_corpus.write_text(json.dumps({"id": "d1", "passage": "first evidence"}) + "\n", encoding="utf-8")

    prepare_multihop_cache(
        raw_queries=raw_queries,
        raw_corpus=raw_corpus,
        output_dir=tmp_path / "processed",
        schema="split",
        sample_size=None,
        seed=13,
        overwrite=False,
    )

    assert read_jsonl(tmp_path / "processed" / "queries.jsonl")[0]["evidence_ids"] == ["d1"]


def test_prepare_split_multihop_cache_rejects_evidence_text_missing_from_corpus(tmp_path):
    raw_queries = tmp_path / "queries.jsonl"
    raw_corpus = tmp_path / "corpus.jsonl"
    raw_queries.write_text(
        json.dumps(
            {
                "id": "q1",
                "question": "first",
                "answer": "a1",
                "evidence_list": [{"text": "not present in corpus"}],
            }
        )
        + "\n",
        encoding="utf-8",
    )
    raw_corpus.write_text(json.dumps({"id": "d1", "passage": "first evidence"}) + "\n", encoding="utf-8")

    with pytest.raises(DataValidationError, match="missing evidence"):
        prepare_multihop_cache(
            raw_queries=raw_queries,
            raw_corpus=raw_corpus,
            output_dir=tmp_path / "processed",
            schema="split",
            sample_size=None,
            seed=13,
            overwrite=False,
        )


def test_prepare_split_rejects_ambiguous_text_only_evidence(tmp_path):
    raw_queries = tmp_path / "queries.jsonl"
    raw_corpus = tmp_path / "corpus.jsonl"
    duplicate_text = "duplicate supporting passage"
    raw_queries.write_text(
        json.dumps({"id": "q1", "question": "first", "answer": "a1", "evidence_list": [duplicate_text]}) + "\n",
        encoding="utf-8",
    )
    raw_corpus.write_text(
        "\n".join(
            [
                json.dumps({"id": "d1", "passage": duplicate_text}),
                json.dumps({"id": "d2", "passage": duplicate_text}),
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    with pytest.raises(DataValidationError, match="ambiguous evidence text"):
        prepare_multihop_cache(
            raw_queries=raw_queries,
            raw_corpus=raw_corpus,
            output_dir=tmp_path / "processed",
            schema="split",
            sample_size=None,
            seed=13,
            overwrite=False,
        )


def test_prepare_embedded_sample_keeps_candidate_pool_for_sampled_queries(tmp_path):
    raw_path = tmp_path / "raw.jsonl"
    raw_path.write_text(
        "\n".join(
            [
                json.dumps(
                    {
                        "id": "q1",
                        "question": "first query",
                        "answer": "a1",
                        "evidence_ids": ["d1"],
                        "contexts": [
                            {"id": "d1", "text": "first evidence"},
                            {"id": "d2", "text": "first distractor"},
                        ],
                    }
                ),
                json.dumps(
                    {
                        "id": "q2",
                        "question": "second query",
                        "answer": "a2",
                        "evidence_ids": ["d3"],
                        "contexts": [
                            {"id": "d3", "text": "second evidence"},
                            {"id": "d4", "text": "second distractor"},
                        ],
                    }
                ),
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    prepare_multihop_cache(
        raw_queries=raw_path,
        raw_corpus=None,
        output_dir=tmp_path / "processed",
        schema="embedded",
        sample_size=1,
        seed=3,
        overwrite=False,
    )

    query = read_jsonl(tmp_path / "processed" / "queries.jsonl")[0]
    corpus_ids = {row["doc_id"] for row in read_jsonl(tmp_path / "processed" / "corpus.jsonl")}
    if query["query_id"] == "q1":
        assert corpus_ids == {"d1", "d2"}
    else:
        assert corpus_ids == {"d3", "d4"}


def test_prepare_text_only_evidence_prefers_current_embedded_context(tmp_path):
    raw_path = tmp_path / "raw.jsonl"
    shared_text = "Shared evidence text appears in both local contexts."
    raw_path.write_text(
        "\n".join(
            [
                json.dumps(
                    {
                        "id": "q1",
                        "question": "first query",
                        "answer": "a1",
                        "evidence_list": [{"text": shared_text}],
                        "contexts": [{"id": "q1-local", "text": shared_text}],
                    }
                ),
                json.dumps(
                    {
                        "id": "q2",
                        "question": "second query",
                        "answer": "a2",
                        "evidence_list": [{"text": shared_text}],
                        "contexts": [{"id": "q2-local", "text": shared_text}],
                    }
                ),
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    prepare_multihop_cache(
        raw_queries=raw_path,
        raw_corpus=None,
        output_dir=tmp_path / "processed",
        schema="embedded",
        sample_size=None,
        seed=13,
        overwrite=False,
    )

    evidence_by_query = {row["query_id"]: row["evidence_ids"] for row in read_jsonl(tmp_path / "processed" / "queries.jsonl")}

    assert evidence_by_query == {"q1": ["q1-local"], "q2": ["q2-local"]}


def test_prepare_multihop_cache_rejects_missing_evidence(tmp_path):
    raw_path = tmp_path / "raw.jsonl"
    raw_path.write_text(
        json.dumps(
            {
                "id": "q1",
                "question": "Where?",
                "answer": "Nowhere",
                "evidence_ids": ["missing"],
                "contexts": [{"id": "d1", "text": "A document."}],
            }
        )
        + "\n",
        encoding="utf-8",
    )

    with pytest.raises(DataValidationError, match="missing evidence"):
        prepare_multihop_cache(
            raw_queries=raw_path,
            raw_corpus=None,
            output_dir=tmp_path / "processed",
            schema="embedded",
            sample_size=None,
            seed=13,
            overwrite=False,
        )


def test_prepare_multihop_cache_refuses_overwrite(tmp_path):
    raw_path = tmp_path / "raw.jsonl"
    raw_path.write_text(
        json.dumps(
            {
                "id": "q1",
                "question": "Where?",
                "answer": "Somewhere",
                "evidence_ids": ["d1"],
                "contexts": [{"id": "d1", "text": "A valid evidence document."}],
            }
        )
        + "\n",
        encoding="utf-8",
    )
    output_dir = tmp_path / "processed"
    output_dir.mkdir()
    (output_dir / "queries.jsonl").write_text("{}\n", encoding="utf-8")

    with pytest.raises(DataValidationError, match="overwrite"):
        prepare_multihop_cache(
            raw_queries=raw_path,
            raw_corpus=None,
            output_dir=output_dir,
            schema="embedded",
            sample_size=None,
            seed=13,
            overwrite=False,
        )


def test_prepare_multihop_cache_rejects_overwrite_of_raw_input_directory(tmp_path):
    raw_dir = tmp_path / "raw"
    raw_dir.mkdir()
    raw_path = raw_dir / "raw.jsonl"
    raw_path.write_text(
        json.dumps(
            {
                "id": "q1",
                "question": "Where?",
                "answer": "Somewhere",
                "evidence_ids": ["d1"],
                "contexts": [{"id": "d1", "text": "A valid evidence document."}],
            }
        )
        + "\n",
        encoding="utf-8",
    )

    with pytest.raises(DataValidationError, match="output directory must not contain raw input files"):
        prepare_multihop_cache(
            raw_queries=raw_path,
            raw_corpus=None,
            output_dir=raw_dir,
            schema="embedded",
            sample_size=None,
            seed=13,
            overwrite=True,
        )

    assert raw_path.exists()


def test_prepare_split_cache_rejects_overwrite_of_raw_input_parent(tmp_path):
    raw_dir = tmp_path / "raw"
    raw_dir.mkdir()
    raw_queries = raw_dir / "queries.jsonl"
    raw_corpus = raw_dir / "corpus.jsonl"
    raw_queries.write_text(
        json.dumps({"id": "q1", "question": "first", "answer": "a1", "evidence_ids": ["d1"]}) + "\n",
        encoding="utf-8",
    )
    raw_corpus.write_text(json.dumps({"id": "d1", "passage": "first evidence"}) + "\n", encoding="utf-8")

    with pytest.raises(DataValidationError, match="output directory must not contain raw input files"):
        prepare_multihop_cache(
            raw_queries=raw_queries,
            raw_corpus=raw_corpus,
            output_dir=tmp_path,
            schema="split",
            sample_size=None,
            seed=13,
            overwrite=True,
        )

    assert raw_queries.exists()
    assert raw_corpus.exists()
