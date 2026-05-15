from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
import re
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


def load_dataset(data_dir: Path) -> Dataset:
    query_rows = read_jsonl(data_dir / "queries.jsonl")
    corpus_rows = read_jsonl(data_dir / "corpus.jsonl")
    corpus = tuple(_parse_document(row) for row in corpus_rows)
    queries = tuple(_parse_query(row) for row in query_rows)
    validate_dataset(Dataset(queries=queries, corpus=corpus))
    return Dataset(queries=queries, corpus=corpus)


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
