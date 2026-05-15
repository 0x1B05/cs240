from __future__ import annotations

from collections import Counter
from math import log, sqrt

from .data import tokenize


def tfidf_vectors(texts: list[str]) -> list[dict[str, float]]:
    docs = [tokenize(text) for text in texts]
    n_docs = len(docs)
    if n_docs == 0:
        return []

    doc_freq: Counter[str] = Counter()
    for tokens in docs:
        doc_freq.update(set(tokens))

    vectors: list[dict[str, float]] = []
    for tokens in docs:
        counts = Counter(tokens)
        total = sum(counts.values()) or 1
        vector: dict[str, float] = {}
        for term, count in counts.items():
            tf = count / total
            idf = log((1 + n_docs) / (1 + doc_freq[term])) + 1.0
            vector[term] = tf * idf
        vectors.append(vector)
    return vectors


def cosine(left: dict[str, float], right: dict[str, float]) -> float:
    if not left or not right:
        return 0.0
    if len(left) > len(right):
        left, right = right, left
    dot = sum(value * right.get(term, 0.0) for term, value in left.items())
    if dot <= 0:
        return 0.0
    left_norm = sqrt(sum(value * value for value in left.values()))
    right_norm = sqrt(sum(value * value for value in right.values()))
    if left_norm == 0 or right_norm == 0:
        return 0.0
    return dot / (left_norm * right_norm)
