from __future__ import annotations

from .data import Candidate, Dataset, DataValidationError, token_cost
from .textmath import cosine, tfidf_transform


def retrieve_top_n(dataset: Dataset, top_n: int) -> dict[str, list[Candidate]]:
    if top_n <= 0:
        raise DataValidationError("top_n must be positive")

    doc_texts = [doc.text for doc in dataset.corpus]
    query_texts = [query.query for query in dataset.queries]
    query_vectors = tfidf_transform(query_texts, reference_texts=doc_texts)
    doc_vectors = tfidf_transform(doc_texts, reference_texts=doc_texts)

    results: dict[str, list[Candidate]] = {}
    for query, query_vector in zip(dataset.queries, query_vectors, strict=True):
        scored: list[tuple[float, str, int]] = []
        for index, (doc, doc_vector) in enumerate(zip(dataset.corpus, doc_vectors, strict=True)):
            score = cosine(query_vector, doc_vector)
            scored.append((score, doc.doc_id, index))
        scored.sort(key=lambda item: (-item[0], item[1]))

        candidates: list[Candidate] = []
        for rank, (score, _doc_id, index) in enumerate(scored[:top_n], 1):
            doc = dataset.corpus[index]
            candidates.append(
                Candidate(
                    query_id=query.query_id,
                    doc_id=doc.doc_id,
                    rank=rank,
                    score=score,
                    text=doc.text,
                    token_cost=token_cost(doc.text),
                )
            )
        results[query.query_id] = candidates
    return results
