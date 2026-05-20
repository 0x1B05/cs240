#import "@preview/charged-ieee:0.1.4": ieee
#import "@preview/tablem:0.3.0": tablem, three-line-table

#show: ieee.with(
  title: [Budgeted Submodular Context Selection for Retrieval-Augmented Generation],
  abstract: [
    Retrieval-augmented generation (RAG) systems usually retrieve a ranked list of candidate passages and place the top candidates into a language model's context window. This simple strategy ignores the token budget and often selects redundant passages. We propose to study RAG context selection as a budgeted submodular maximization problem: given retrieved candidates and a context budget, select a subset that maximizes query-relevant coverage while reducing redundancy. Our project will reproduce the core greedy optimization framework of Lin and Bilmes for submodular document summarization, adapt it to RAG context selection, and compare it with top-ranked retrieval, relevance-only selection, and maximal marginal relevance.
  ],
  authors: (
    (
      name: "Junqi Liu - 2025234339",
      email: "liujq2025@shanghaitech.edu.cn",
    ),
    (
      name: "Yuxuan Fu - 2025234266",
      email: "fuyx2025@shanghaitech.edu.cn",
    ),
    (
      name: "Ledu Zhang - 2025234374",
      email: "zhangld2025@shanghaitech.edu.cn",
    ),
    (
      name: "Zhixin Xiao - 2025234366",
      email: "xiaozhx2025@shanghaitech.edu.cn",
    ),
    (
      name: "Xu Zhu - 2025234378",
      email: "zhuxu2025@shanghaitech.edu.cn",
    ),
  ),
  index-terms: (
    "Submodular maximization",
    "budgeted maximum coverage",
    "knapsack constraint",
    "retrieval-augmented generation",
    "context selection",
  ),
  bibliography: bibliography("refs.bib"),
)

= Topic and Motivation

Large language models rely on retrieval-augmented generation (RAG) to answer questions using external knowledge @lewis2020rag. A standard RAG pipeline retrieves a list of candidate passages and sends the top-ranked passages to the model. However, the context window is a limited resource: every passage has a token cost, and selecting many similar passages wastes budget that could cover missing evidence. Recent RAG studies address this issue through context compression @cheng2024xrag @louis2025pisco, budget-aware routing @qureshi2026budgetaware, and multi-hop retrieval strategies @ji2025mind @shi2026rtrag.

This is especially important for multi-hop questions, where the answer may require several distinct pieces of evidence. If the context budget is spent on redundant passages, the model may miss one hop of the reasoning chain even when the retriever has found useful candidates.

We choose the course topic "LLM context selection" and ask how classical coverage and approximation algorithms can select a compact, diverse, and query-relevant context set for RAG. This connects a modern LLM-system problem to knapsack constraints, maximum coverage, greedy approximation, and submodular optimization.

= Problem Formalization

For each query $q$, a retriever returns a candidate set $C = {d_1, d_2, ..., d_n}$. Each candidate passage $d_i$ has a token cost $c_i$, and the context window gives a total budget $B$. The output is a subset $S subset.eq C$ satisfying

$ sum_(d_i in S) c_i <= B. $

The objective is to maximize a query-aware set function:

$ max_(S subset.eq C) F_q(S) = L_q(S) + lambda R_q(S), quad "s.t." sum_(d_i in S) c_i <= B. $

Following Lin and Bilmes @lin2011submodular, $L_q(S)$ will measure coverage over candidate information units, and $R_q(S)$ will reward diversity across clusters or aspects. Using pairwise similarity weights $w_(i,j)$ and relevance scores $r_i(q)$, the coverage term can reward selected passages that represent many candidates, while the diversity term can apply a concave reward such as $sqrt(sum_(d_i in S inter P_k) r_i(q))$ within each cluster $P_k$. This creates diminishing returns: after one passage covers an aspect, additional similar passages add less value. The budget constraint makes the problem a knapsack-style variant of maximum coverage.

= Related Work and Method Selection

Our main paper is Lin and Bilmes's submodular summarization framework @lin2011submodular. They define monotone submodular objectives combining coverage and diversity, then optimize them under summary-length constraints with greedy algorithms. We will reproduce the method-level comparison between coverage-only, diversity-only, and combined objectives, but adapt the framework to RAG context selection instead of the original summarization benchmarks.

Recent work makes this adaptation relevant to modern RAG systems. xRAG compresses retrieved documents by reusing dense retrieval embeddings as retrieval-modality features @cheng2024xrag. PISCO studies a lightweight compression method for RAG question answering @louis2025pisco. These methods reduce context cost by changing the representation of retrieved text. Our project instead keeps passages as explicit text units and studies which units should be selected under a token budget.

The most closely related recent paper is Budget-Aware Routing for Long Clinical Text @qureshi2026budgetaware. It formulates long-document context construction as a knapsack-constrained subset selection problem and proposes a monotone submodular objective balancing relevance, coverage, and diversity. Their application is long clinical text, while ours is multi-hop RAG evidence selection.

Recent multi-hop RAG papers also motivate our application scenario. MIND uses memory-aware filtering and uncertainty-guided retrieval for multi-hop question answering @ji2025mind. RT-RAG decomposes complex questions into reasoning trees and collects evidence through structured bottom-up retrieval @shi2026rtrag. These systems show why we evaluate whether selected passages preserve complementary evidence on MultiHop-RAG @tang2024multihoprag.

Carbonell and Goldstein introduced maximal marginal relevance (MMR), a classical reranking method that trades off relevance against redundancy @carbonell1998mmr. MMR is a natural baseline because it also discourages near-duplicate passages. Khuller, Moss, and Naor studied budgeted maximum coverage @khuller1999budgeted, which provides the theoretical background for selecting high-value sets under costs.

= Algorithm and Technical Plan

We will implement a budgeted greedy algorithm. Starting with $S = emptyset$, each step adds the feasible passage with the largest marginal gain per token:

$ d^* = arg max_(d_i in C - S, c_i + sum_(d_j in S) c_j <= B) (F_q(S union {d_i}) - F_q(S)) / c_i. $

The algorithm stops when no remaining passage fits the budget. A direct implementation costs roughly $O(n^2)$ per query if marginal gains are recomputed against all candidates; we will measure this cost and may add lazy greedy evaluation as an optional optimization. We will compare against top-ranked retrieval until the budget is full, relevance-only selection by relevance-to-cost ratio, random feasible selection, and MMR. For small sampled instances, we may enumerate feasible subsets to compare greedy results with the optimum.

The planned dataset is MultiHop-RAG @tang2024multihoprag because it provides multi-hop queries, answers, evidence lists, and a corpus. We will use BM25 or provided retrieval candidates to generate a top-$N$ candidate set for each query, compute passage costs using token counts, and compute similarities using TF-IDF cosine similarity or sentence embeddings depending on implementation time. The main evaluation will focus on evidence coverage: whether the selected context contains the gold evidence needed by the query.

= Project Scope and Expected Results

The required project scope is:

+ Implement the Lin-Bilmes-style coverage, diversity, and combined submodular objectives for context selection.
+ Implement the budgeted greedy algorithm and the top-ranked, relevance-only, random, and MMR baselines.
+ Reproduce the method-level comparison between coverage-only, diversity-only, and combined submodular objectives under a fixed budget.
+ Evaluate on MultiHop-RAG with several token budgets and candidate-set sizes.
+ Report evidence recall/F1, redundancy, token-budget utilization, and running time.
+ Analyze the complexity and scalability of the algorithms as the number of candidates grows.

Possible extensions include lazy greedy acceleration, dense embedding similarity, testing on HotpotQA/BEIR, and a small downstream answer-quality experiment using a fixed LLM. These extensions are optional; the core deliverable is the reproduction and adaptation of the classical submodular optimization method.

= Team Information and Division

#three-line-table[
  | *Member* | *Planned contribution* |
  | :------ | :--------------------- |
  | Junqi Liu | Formalization, theory, and connection to budgeted maximum coverage. |
  | Zhixin Xiao | Submodular objectives, greedy algorithm, and lazy-greedy extension. |
  | Yuxuan Fu | Retrieval candidates, MultiHop-RAG preprocessing, token costs, and similarities. |
  | Ledu Zhang | Baselines, evidence metrics, and small brute-force optimal checks. |
  | Xu Zhu | Experiments, scalability analysis, figures/tables, report, and presentation. |
]
