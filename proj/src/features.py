from __future__ import annotations

from dataclasses import dataclass
import math

from .data import Candidate, DataValidationError
from .textmath import cosine, tfidf_transform


@dataclass(frozen=True)
class FeatureSet:
    query_id: str
    doc_ids: tuple[str, ...]
    costs: tuple[int, ...]
    relevance: tuple[float, ...]
    similarity: tuple[tuple[float, ...], ...]


def build_features(query_text: str, candidates: list[Candidate]) -> FeatureSet:
    if not candidates:
        raise DataValidationError("candidate list must not be empty")
    query_ids = {candidate.query_id for candidate in candidates}
    if len(query_ids) != 1:
        raise DataValidationError("candidate list contains multiple query ids")

    doc_texts = [candidate.text for candidate in candidates]
    query_vector = tfidf_transform([query_text], reference_texts=doc_texts)[0]
    doc_vectors = tfidf_transform(doc_texts, reference_texts=doc_texts)

    relevance = tuple(max(0.0, cosine(query_vector, vector)) for vector in doc_vectors)
    similarity_rows: list[tuple[float, ...]] = []
    for left in doc_vectors:
        row = tuple(max(0.0, cosine(left, right)) for right in doc_vectors)
        similarity_rows.append(row)

    features = FeatureSet(
        query_id=candidates[0].query_id,
        doc_ids=tuple(candidate.doc_id for candidate in candidates),
        costs=tuple(candidate.token_cost for candidate in candidates),
        relevance=relevance,
        similarity=tuple(similarity_rows),
    )
    validate_features(features)
    return features


def validate_features(features: FeatureSet) -> None:
    size = len(features.doc_ids)
    if size == 0:
        raise DataValidationError("features must contain at least one document")
    if len(features.costs) != size or len(features.relevance) != size or len(features.similarity) != size:
        raise DataValidationError("feature dimensions do not match document ids")
    for cost in features.costs:
        if cost <= 0:
            raise DataValidationError("feature costs must be positive")
    for score in features.relevance:
        _validate_nonnegative_finite(score, "relevance")
    for row in features.similarity:
        if len(row) != size:
            raise DataValidationError("similarity matrix must be square")
        for score in row:
            _validate_nonnegative_finite(score, "similarity")
    for i in range(size):
        for j in range(size):
            if abs(features.similarity[i][j] - features.similarity[j][i]) > 1e-9:
                raise DataValidationError("similarity matrix must be symmetric")


def _validate_nonnegative_finite(value: float, label: str) -> None:
    if math.isnan(value) or math.isinf(value) or value < 0:
        raise DataValidationError(f"{label} values must be nonnegative and finite")
