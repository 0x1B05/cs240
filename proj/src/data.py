from __future__ import annotations

from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import random
import re
import shutil
from typing import Iterable


TOKEN_RE = re.compile(r"[A-Za-z0-9]+")


class DataValidationError(ValueError):
    """Raised when experiment input data is malformed."""


@dataclass(frozen=True)
class Document:
    doc_id: str
    text: str


@dataclass(frozen=True)
class Query:
    query_id: str
    query: str
    answer: str
    evidence_ids: tuple[str, ...]


@dataclass(frozen=True)
class Dataset:
    queries: tuple[Query, ...]
    corpus: tuple[Document, ...]


@dataclass(frozen=True)
class Candidate:
    query_id: str
    doc_id: str
    rank: int
    score: float
    text: str
    token_cost: int


@dataclass(frozen=True)
class Selection:
    query_id: str
    method: str
    selected_doc_ids: tuple[str, ...]
    total_cost: int
    objective_value: float | None = None


def tokenize(text: str) -> list[str]:
    return [match.group(0).lower() for match in TOKEN_RE.finditer(text)]


def token_cost(text: str) -> int:
    return len(tokenize(text))


def read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        raise DataValidationError(f"missing input file: {path}")
    rows: list[dict] = []
    with path.open("r", encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, 1):
            stripped = line.strip()
            if not stripped:
                continue
            try:
                row = json.loads(stripped)
            except json.JSONDecodeError as exc:
                raise DataValidationError(f"invalid JSONL at {path}:{line_number}") from exc
            if not isinstance(row, dict):
                raise DataValidationError(f"JSONL row must be an object at {path}:{line_number}")
            rows.append(row)
    if not rows:
        raise DataValidationError(f"empty input file: {path}")
    return rows


def write_jsonl(path: Path, rows: Iterable[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, sort_keys=True) + "\n")


def prepare_multihop_cache(
    *,
    raw_queries: Path,
    raw_corpus: Path | None,
    output_dir: Path,
    schema: str,
    sample_size: int | None,
    seed: int,
    overwrite: bool,
) -> dict:
    """Normalize local MultiHop-RAG-style records into the canonical cache.

    Downstream code intentionally keeps one contract: `queries.jsonl` and
    `corpus.jsonl`. This prep step is the only place that handles raw schema
    aliases and embedded context pools.
    """

    schema = _resolve_schema(schema, raw_corpus)
    if sample_size is not None and sample_size <= 0:
        raise DataValidationError("sample_size must be positive")
    if output_dir.is_symlink() and not overwrite:
        raise DataValidationError(f"output path is a symlink: {output_dir}")
    if output_dir.exists() and not output_dir.is_dir():
        raise DataValidationError(f"output path is not a directory: {output_dir}")
    if output_dir.exists() and any(output_dir.iterdir()) and not overwrite:
        raise DataValidationError(f"output directory exists; pass overwrite to replace it: {output_dir}")
    _validate_output_does_not_contain_inputs(output_dir, raw_queries, raw_corpus)

    if schema == "split":
        query_rows, corpus_rows = _prepare_split_rows(raw_queries, raw_corpus)
    elif schema == "embedded":
        query_rows, corpus_rows = _prepare_embedded_rows(raw_queries)
    else:
        raise DataValidationError(f"unsupported schema: {schema}")

    full_dataset = Dataset(
        queries=tuple(_parse_query(row) for row in query_rows),
        corpus=tuple(_parse_document(row) for row in corpus_rows),
    )
    validate_dataset(full_dataset)
    query_rows, corpus_rows = _sample_prepared_rows(query_rows, corpus_rows, sample_size, seed, schema)
    validate_dataset(
        Dataset(
            queries=tuple(_parse_query(row) for row in query_rows),
            corpus=tuple(_parse_document(row) for row in corpus_rows),
        )
    )

    if output_dir.exists() and overwrite:
        if output_dir.is_symlink():
            output_dir.unlink()
        else:
            shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    write_jsonl(output_dir / "queries.jsonl", query_rows)
    write_jsonl(output_dir / "corpus.jsonl", corpus_rows)
    manifest = {
        "schema": schema,
        "raw_queries": str(raw_queries),
        "raw_corpus": str(raw_corpus) if raw_corpus else None,
        "sample_size": sample_size,
        "seed": seed,
        "queries": len(query_rows),
        "corpus": len(corpus_rows),
        "query_ids": [row["query_id"] for row in query_rows],
    }
    (output_dir / "manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return manifest


def _validate_output_does_not_contain_inputs(output_dir: Path, raw_queries: Path, raw_corpus: Path | None) -> None:
    try:
        resolved_output = output_dir.resolve(strict=False)
        lexical_output = output_dir.absolute()
    except OSError as exc:
        raise DataValidationError(f"cannot resolve output directory: {output_dir}") from exc
    raw_paths = [raw_queries, *(path for path in (raw_corpus,) if path is not None)]
    for raw_path in raw_paths:
        try:
            resolved_raw = raw_path.resolve(strict=False)
            lexical_raw = raw_path.absolute()
        except OSError as exc:
            raise DataValidationError(f"cannot resolve raw input file: {raw_path}") from exc
        if _paths_overlap(resolved_output, resolved_raw) or _paths_overlap(lexical_output, lexical_raw):
            raise DataValidationError(f"output directory must not contain raw input files: {output_dir}")


def _paths_overlap(first: Path, second: Path) -> bool:
    return first == second or first in second.parents or second in first.parents


def load_dataset(data_dir: Path) -> Dataset:
    query_rows = read_jsonl(data_dir / "queries.jsonl")
    corpus_rows = read_jsonl(data_dir / "corpus.jsonl")
    corpus = tuple(_parse_document(row) for row in corpus_rows)
    queries = tuple(_parse_query(row) for row in query_rows)
    validate_dataset(Dataset(queries=queries, corpus=corpus))
    return Dataset(queries=queries, corpus=corpus)


def _resolve_schema(schema: str, raw_corpus: Path | None) -> str:
    if schema not in {"auto", "split", "embedded"}:
        raise DataValidationError("schema must be one of: auto, split, embedded")
    if schema == "auto":
        return "split" if raw_corpus is not None else "embedded"
    if schema == "split" and raw_corpus is None:
        raise DataValidationError("split schema requires raw_corpus")
    if schema == "embedded" and raw_corpus is not None:
        raise DataValidationError("embedded schema does not accept raw_corpus")
    return schema


def _prepare_split_rows(raw_queries: Path, raw_corpus: Path | None) -> tuple[list[dict], list[dict]]:
    if raw_corpus is None:
        raise DataValidationError("split schema requires raw_corpus")
    corpus_by_id: dict[str, dict] = {}
    text_to_doc_id: dict[str, str] = {}
    text_to_doc_ids: dict[str, list[str]] = {}
    for row in _read_records(raw_corpus):
        document = _normalize_doc_like(row, allow_hash_id=False)
        _add_document(corpus_by_id, text_to_doc_id, document, text_to_doc_ids)

    query_rows: list[dict] = []
    for row in _read_records(raw_queries):
        query_id = _first_text(row, ("query_id", "id"))
        query_text = _first_text(row, ("query", "question"))
        evidence_ids = _normalize_evidence_ids(row, corpus_by_id, text_to_doc_id, text_to_doc_ids=text_to_doc_ids, allow_materialize=False)
        query_rows.append(
            {
                "answer": str(row.get("answer", "")),
                "evidence_ids": evidence_ids,
                "query": _normalize_text(query_text),
                "query_id": query_id,
            }
        )
    return _sort_queries(query_rows), _sort_corpus(corpus_by_id.values())


def _prepare_embedded_rows(raw_queries: Path) -> tuple[list[dict], list[dict]]:
    prepared_queries: list[dict] = []
    corpus_by_id: dict[str, dict] = {}
    text_to_doc_id: dict[str, str] = {}
    text_to_doc_ids: dict[str, list[str]] = {}
    raw_rows = _read_records(raw_queries)
    local_doc_ids_by_row: list[set[str]] = []
    local_id_to_doc_id_by_row: list[dict[str, str]] = []
    local_text_to_doc_id_by_row: list[dict[str, str]] = []
    local_text_to_doc_ids_by_row: list[dict[str, list[str]]] = []
    embedded_texts_by_id: dict[str, set[str]] = {}
    for row in raw_rows:
        for doc_like in _embedded_docs(row):
            document = _normalize_doc_like(doc_like, allow_hash_id=True)
            embedded_texts_by_id.setdefault(document["doc_id"], set()).add(document["text"])
    conflicting_local_ids = {doc_id for doc_id, texts in embedded_texts_by_id.items() if len(texts) > 1}

    for row in raw_rows:
        query_id = _first_text(row, ("query_id", "id"))
        local_doc_ids: set[str] = set()
        local_id_to_doc_id: dict[str, str] = {}
        local_text_to_doc_id: dict[str, str] = {}
        local_text_to_doc_ids: dict[str, list[str]] = {}
        for doc_like in _embedded_docs(row):
            document = _normalize_doc_like(doc_like, allow_hash_id=True)
            original_doc_id = document["doc_id"]
            if original_doc_id in conflicting_local_ids:
                document = {**document, "doc_id": _embedded_doc_id(query_id, original_doc_id)}
            _add_document(corpus_by_id, text_to_doc_id, document, text_to_doc_ids)
            local_id_to_doc_id[original_doc_id] = document["doc_id"]
            local_doc_ids.add(document["doc_id"])
            local_text_to_doc_id.setdefault(document["text"], document["doc_id"])
            local_ids = local_text_to_doc_ids.setdefault(document["text"], [])
            if document["doc_id"] not in local_ids:
                local_ids.append(document["doc_id"])
        local_doc_ids_by_row.append(local_doc_ids)
        local_id_to_doc_id_by_row.append(local_id_to_doc_id)
        local_text_to_doc_id_by_row.append(local_text_to_doc_id)
        local_text_to_doc_ids_by_row.append(local_text_to_doc_ids)

    for index, row in enumerate(raw_rows):
        query_id = _first_text(row, ("query_id", "id"))
        query_text = _first_text(row, ("query", "question"))
        local_doc_ids = local_doc_ids_by_row[index]
        evidence_ids = _normalize_evidence_ids(
            row,
            corpus_by_id,
            text_to_doc_id,
            local_id_to_doc_id=local_id_to_doc_id_by_row[index],
            local_text_to_doc_id=local_text_to_doc_id_by_row[index],
            local_text_to_doc_ids=local_text_to_doc_ids_by_row[index],
            text_to_doc_ids=text_to_doc_ids,
            allow_materialize=True,
        )
        local_doc_ids.update(evidence_ids)
        prepared_queries.append(
            {
                "answer": str(row.get("answer", "")),
                "evidence_ids": evidence_ids,
                "query": _normalize_text(query_text),
                "query_id": query_id,
                "_reachable_doc_ids": sorted(local_doc_ids),
            }
        )

    return _sort_queries(prepared_queries), _sort_corpus(corpus_by_id.values())


def _sample_prepared_rows(
    query_rows: list[dict],
    corpus_rows: list[dict],
    sample_size: int | None,
    seed: int,
    schema: str,
) -> tuple[list[dict], list[dict]]:
    if sample_size is None or sample_size >= len(query_rows):
        return _strip_internal_query_fields(_sort_queries(query_rows)), _sort_corpus(corpus_rows)
    sorted_queries = _sort_queries(query_rows)
    sampled = random.Random(seed).sample(sorted_queries, sample_size)
    sampled = _sort_queries(sampled)
    if schema == "split":
        return sampled, _sort_corpus(corpus_rows)

    needed = {doc_id for row in sampled for doc_id in row.get("evidence_ids", [])}
    for row in sampled:
        needed.update(row.get("_reachable_doc_ids", []))
    filtered_corpus = [row for row in corpus_rows if row["doc_id"] in needed]
    return _strip_internal_query_fields(sampled), _sort_corpus(filtered_corpus)


def _read_records(path: Path) -> list[dict]:
    if not path.exists():
        raise DataValidationError(f"missing input file: {path}")
    if not path.is_file():
        raise DataValidationError(f"input path is not a file: {path}")
    text = path.read_text(encoding="utf-8").strip()
    if not text:
        raise DataValidationError(f"empty input file: {path}")
    if path.suffix == ".json":
        try:
            payload = json.loads(text)
        except json.JSONDecodeError as exc:
            raise DataValidationError(f"invalid JSON file: {path}") from exc
        if isinstance(payload, dict):
            for key in ("data", "records", "queries"):
                if isinstance(payload.get(key), list):
                    payload = payload[key]
                    break
        if not isinstance(payload, list):
            raise DataValidationError(f"JSON file must contain a list of records: {path}")
        rows = payload
    else:
        rows = read_jsonl(path)
    for index, row in enumerate(rows, 1):
        if not isinstance(row, dict):
            raise DataValidationError(f"record must be an object at {path}:{index}")
    return rows


def _embedded_docs(row: dict) -> list[dict]:
    for key in ("candidates", "contexts", "documents"):
        value = row.get(key)
        if value is None:
            continue
        if not isinstance(value, list) or not value:
            raise DataValidationError(f"{key} must be a nonempty list")
        docs: list[dict] = []
        for item in value:
            if isinstance(item, dict):
                docs.append(item)
            elif isinstance(item, str):
                docs.append({"text": item})
            else:
                raise DataValidationError(f"{key} entries must be objects or strings")
        return docs
    raise DataValidationError("embedded schema requires candidates, contexts, or documents")


def _normalize_evidence_ids(
    row: dict,
    corpus_by_id: dict[str, dict],
    text_to_doc_id: dict[str, str],
    *,
    local_id_to_doc_id: dict[str, str] | None = None,
    local_text_to_doc_id: dict[str, str] | None = None,
    local_text_to_doc_ids: dict[str, list[str]] | None = None,
    text_to_doc_ids: dict[str, list[str]] | None = None,
    allow_materialize: bool,
) -> list[str]:
    evidence_key = "evidence_ids" if "evidence_ids" in row else "evidence_list"
    raw = row.get(evidence_key)
    if not isinstance(raw, list) or not raw:
        query_id = row.get("query_id", row.get("id", "<unknown>"))
        raise DataValidationError(f"query {query_id} must include nonempty evidence_ids")

    evidence_ids: list[str] = []
    for item in raw:
        if isinstance(item, dict):
            if _has_any_text(item, ("doc_id", "id")):
                evidence_id = _first_text(item, ("doc_id", "id"))
                if _has_any_text(item, ("text", "passage", "contents")):
                    document = _normalize_doc_like(item, allow_hash_id=True)
                    if local_id_to_doc_id and document["doc_id"] in local_id_to_doc_id:
                        document = {**document, "doc_id": local_id_to_doc_id[document["doc_id"]]}
                    if not allow_materialize:
                        existing = corpus_by_id.get(document["doc_id"])
                        if existing is None or existing["text"] != document["text"]:
                            raise DataValidationError(f"missing evidence in corpus: {document['doc_id']}")
                    _add_document(corpus_by_id, text_to_doc_id, document, text_to_doc_ids)
                    evidence_ids.append(document["doc_id"])
                elif local_id_to_doc_id and evidence_id in local_id_to_doc_id:
                    evidence_ids.append(local_id_to_doc_id[evidence_id])
                elif evidence_id in corpus_by_id:
                    evidence_ids.append(evidence_id)
                else:
                    raise DataValidationError(f"missing evidence in corpus: {evidence_id}")
            elif _has_any_text(item, ("text", "passage", "contents")):
                text = _normalize_text(_first_text(item, ("text", "passage", "contents")))
                doc_id = _resolve_text_evidence_id(text, text_to_doc_id, local_text_to_doc_id, local_text_to_doc_ids, text_to_doc_ids)
                if doc_id is None:
                    if not allow_materialize:
                        raise DataValidationError(f"missing evidence in corpus: {text}")
                    document = {"doc_id": _hash_doc_id(text), "text": text}
                    _add_document(corpus_by_id, text_to_doc_id, document, text_to_doc_ids)
                    doc_id = document["doc_id"]
                evidence_ids.append(doc_id)
            else:
                raise DataValidationError("evidence object must include an id or text")
        elif isinstance(item, str) and item.strip():
            value = item.strip()
            normalized = _normalize_text(value)
            if local_id_to_doc_id and value in local_id_to_doc_id:
                evidence_ids.append(local_id_to_doc_id[value])
            elif value in corpus_by_id:
                evidence_ids.append(value)
            else:
                doc_id = _resolve_text_evidence_id(normalized, text_to_doc_id, local_text_to_doc_id, local_text_to_doc_ids, text_to_doc_ids)
                if doc_id is not None:
                    evidence_ids.append(doc_id)
                elif evidence_key == "evidence_list" and _looks_like_evidence_id(value):
                    raise DataValidationError(f"missing evidence in corpus: {value}")
                elif allow_materialize and (evidence_key == "evidence_list" or " " in normalized):
                    document = {"doc_id": _hash_doc_id(normalized), "text": normalized}
                    _add_document(corpus_by_id, text_to_doc_id, document, text_to_doc_ids)
                    evidence_ids.append(document["doc_id"])
                elif evidence_key == "evidence_list" or " " in normalized:
                    raise DataValidationError(f"missing evidence in corpus: {normalized}")
                else:
                    evidence_ids.append(value)
        else:
            raise DataValidationError("evidence entries must be nonempty strings or objects")
    if len(evidence_ids) != len(set(evidence_ids)):
        evidence_ids = list(dict.fromkeys(evidence_ids))
    return evidence_ids


def _embedded_doc_id(query_id: str, doc_id: str) -> str:
    return f"{query_id}::{doc_id}"


def _looks_like_evidence_id(value: str) -> bool:
    if " " in value.strip():
        return False
    if any(character.isupper() for character in value):
        return False
    return bool(re.fullmatch(r"[a-z][a-z0-9]*[-_][a-z0-9_-]+", value)) or bool(
        re.fullmatch(r"[a-z]*\d[a-z0-9_-]*", value)
    )


def _resolve_text_evidence_id(
    text: str,
    text_to_doc_id: dict[str, str],
    local_text_to_doc_id: dict[str, str] | None,
    local_text_to_doc_ids: dict[str, list[str]] | None,
    text_to_doc_ids: dict[str, list[str]] | None,
) -> str | None:
    local_matches = local_text_to_doc_ids.get(text, []) if local_text_to_doc_ids is not None else []
    if len(local_matches) > 1:
        raise DataValidationError(f"ambiguous evidence text in corpus: {text}")
    if len(local_matches) == 1:
        return local_matches[0]
    if local_text_to_doc_id and text in local_text_to_doc_id:
        return local_text_to_doc_id[text]
    matches = text_to_doc_ids.get(text, []) if text_to_doc_ids is not None else []
    if len(matches) > 1:
        raise DataValidationError(f"ambiguous evidence text in corpus: {text}")
    if len(matches) == 1:
        return matches[0]
    return text_to_doc_id.get(text)


def _normalize_doc_like(row: dict, *, allow_hash_id: bool) -> dict:
    text = _normalize_text(_first_text(row, ("text", "passage", "contents")))
    if token_cost(text) <= 0:
        raise DataValidationError("document text has nonpositive token cost")
    try:
        doc_id = _first_text(row, ("doc_id", "id"))
    except DataValidationError:
        if not allow_hash_id:
            raise
        doc_id = _hash_doc_id(text)
    return {"doc_id": doc_id, "text": text}


def _add_document(
    corpus_by_id: dict[str, dict],
    text_to_doc_id: dict[str, str],
    document: dict,
    text_to_doc_ids: dict[str, list[str]] | None = None,
) -> None:
    doc_id = document["doc_id"]
    existing = corpus_by_id.get(doc_id)
    if existing is not None and existing["text"] != document["text"]:
        raise DataValidationError(f"duplicate doc_id with conflicting text: {doc_id}")
    corpus_by_id[doc_id] = document
    text_to_doc_id.setdefault(document["text"], doc_id)
    if text_to_doc_ids is not None:
        doc_ids = text_to_doc_ids.setdefault(document["text"], [])
        if doc_id not in doc_ids:
            doc_ids.append(doc_id)


def _sort_queries(rows: Iterable[dict]) -> list[dict]:
    return sorted(rows, key=lambda row: row["query_id"])


def _strip_internal_query_fields(rows: Iterable[dict]) -> list[dict]:
    return [{key: value for key, value in row.items() if not key.startswith("_")} for row in rows]


def _sort_corpus(rows: Iterable[dict]) -> list[dict]:
    return sorted(rows, key=lambda row: row["doc_id"])


def _first_text(row: dict, keys: tuple[str, ...]) -> str:
    for key in keys:
        value = row.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
    raise DataValidationError(f"missing or empty required field: {'|'.join(keys)}")


def _has_any_text(row: dict, keys: tuple[str, ...]) -> bool:
    return any(isinstance(row.get(key), str) and row[key].strip() for key in keys)


def _hash_doc_id(text: str) -> str:
    return "doc_" + hashlib.sha1(text.encode("utf-8")).hexdigest()[:12]


def _parse_document(row: dict) -> Document:
    doc_id = _required_text(row, "doc_id")
    text = _required_text(row, "text")
    if token_cost(text) <= 0:
        raise DataValidationError(f"document {doc_id} has nonpositive token cost")
    return Document(doc_id=doc_id, text=_normalize_text(text))


def _parse_query(row: dict) -> Query:
    query_id = _required_text(row, "query_id")
    query = _required_text(row, "query")
    answer = str(row.get("answer", ""))
    evidence_raw = row.get("evidence_ids", row.get("evidence_list"))
    if not isinstance(evidence_raw, list) or not evidence_raw:
        raise DataValidationError(f"query {query_id} must include nonempty evidence_ids")
    evidence_ids = tuple(str(item).strip() for item in evidence_raw)
    if any(not item for item in evidence_ids):
        raise DataValidationError(f"query {query_id} includes an empty evidence id")
    return Query(query_id=query_id, query=_normalize_text(query), answer=answer, evidence_ids=evidence_ids)


def validate_dataset(dataset: Dataset) -> None:
    if not dataset.corpus:
        raise DataValidationError("corpus must not be empty")
    if not dataset.queries:
        raise DataValidationError("queries must not be empty")

    doc_ids = [doc.doc_id for doc in dataset.corpus]
    if len(doc_ids) != len(set(doc_ids)):
        raise DataValidationError("corpus contains duplicate document ids")

    query_ids = [query.query_id for query in dataset.queries]
    if len(query_ids) != len(set(query_ids)):
        raise DataValidationError("queries contain duplicate query ids")

    doc_id_set = set(doc_ids)
    for query in dataset.queries:
        missing = [doc_id for doc_id in query.evidence_ids if doc_id not in doc_id_set]
        if missing:
            raise DataValidationError(f"query {query.query_id} references missing evidence ids: {missing}")


def candidates_to_rows(candidates: dict[str, list[Candidate]]) -> list[dict]:
    rows: list[dict] = []
    for query_id in sorted(candidates):
        for candidate in candidates[query_id]:
            rows.append(
                {
                    "query_id": candidate.query_id,
                    "doc_id": candidate.doc_id,
                    "rank": candidate.rank,
                    "score": candidate.score,
                    "text": candidate.text,
                    "token_cost": candidate.token_cost,
                }
            )
    return rows


def selections_to_rows(selections: Iterable[Selection]) -> list[dict]:
    return [
        {
            "query_id": selection.query_id,
            "method": selection.method,
            "selected_doc_ids": list(selection.selected_doc_ids),
            "total_cost": selection.total_cost,
            "objective_value": selection.objective_value,
        }
        for selection in selections
    ]


def _required_text(row: dict, key: str) -> str:
    value = row.get(key)
    if not isinstance(value, str) or not value.strip():
        raise DataValidationError(f"missing or empty required field: {key}")
    return value.strip()


def _normalize_text(text: str) -> str:
    return " ".join(text.split())
