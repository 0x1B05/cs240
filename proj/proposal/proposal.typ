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
      department: [School of Information Science and Technology],
      organization: [ShanghaiTech University],
      location: [Shanghai, China],
      email: "liujq2025@shanghaitech.edu.cn",
    ),
    (
      name: "TODO: Team Member 2",
      department: [School of Information Science and Technology],
      organization: [ShanghaiTech University],
      location: [Shanghai, China],
      email: "TODO",
    ),
    (
      name: "TODO: Team Member 3",
      department: [School of Information Science and Technology],
      organization: [ShanghaiTech University],
      location: [Shanghai, China],
      email: "TODO",
    ),
    (
      name: "Zhixin Xiao - 2025234366",
      department: [School of Information Science and Technology],
      organization: [ShanghaiTech University],
      location: [Shanghai, China],
      email: "xiaozhx2025@shanghaitech.edu.cn",
    ),
    (
      name: "TODO: Team Member 5",
      department: [School of Information Science and Technology],
      organization: [ShanghaiTech University],
      location: [Shanghai, China],
      email: "TODO",
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

Large language models rely on retrieval-augmented generation (RAG) to answer questions using external knowledge @lewis2020rag. A standard RAG pipeline retrieves a list of candidate passages and then sends the top-ranked passages to the model. However, the context window is a limited resource: every passage has a token cost, and selecting many similar passages wastes budget that could cover missing evidence. This is especially important for multi-hop questions, where the answer may require several distinct pieces of evidence.

We choose the course topic "LLM context selection" and focus on the following algorithmic question: how can classical coverage and approximation algorithms help select a compact, diverse, and query-relevant context set for RAG? This matches the course requirement because it connects a modern LLM-system problem to knapsack constraints, maximum coverage, greedy approximation, and submodular optimization.

= Problem Formalization

For each query $q$, a retriever returns a candidate set $C = {d_1, d_2, ..., d_n}$. Each candidate passage $d_i$ has a token cost $c_i$, and the context window gives a total budget $B$. The output is a subset $S subset.eq C$ satisfying

$ sum_(d_i in S) c_i <= B. $

The objective is to maximize a query-aware set function:

$ max_(S subset.eq C) F_q(S) = L_q(S) + lambda R_q(S), quad "s.t." sum_(d_i in S) c_i <= B. $

Following Lin and Bilmes @lin2011submodular, $L_q(S)$ will measure coverage over candidate information units, and $R_q(S)$ will reward diversity across clusters or aspects. For example, using pairwise similarity weights $w_(i,j)$ and relevance scores $r_i(q)$, the coverage term can reward selected passages that represent many candidates, while the diversity term can apply a concave reward such as $sqrt(sum_(d_i in S inter P_k) r_i(q))$ within each cluster $P_k$. This creates diminishing returns: after one passage covers an aspect, additional similar passages add less value. The budget constraint makes the problem a knapsack-style variant of maximum coverage.

= Related Work and Method Selection

Our main paper is Lin and Bilmes's submodular summarization framework @lin2011submodular. They define a class of monotone submodular objectives combining coverage and diversity, then optimize them under summary-length constraints with greedy algorithms. We will reproduce the core method-level results: coverage-only, diversity-only, and combined objectives optimized by budgeted greedy selection. Instead of reproducing every original summarization benchmark, we adapt the same optimization framework to RAG context selection.

Carbonell and Goldstein introduced maximal marginal relevance (MMR), a classical reranking method that trades off relevance against redundancy @carbonell1998mmr. MMR is a natural baseline for context selection because it also discourages repeatedly selecting near-duplicate passages. Khuller, Moss, and Naor studied the budgeted maximum coverage problem @khuller1999budgeted, which provides the theoretical background for selecting high-value sets under costs. Together, these papers make the project an algorithmic study rather than only an LLM application demo.

= Algorithm and Technical Plan

We will implement a budgeted greedy algorithm. Starting with $S = emptyset$, each step adds the feasible passage with the largest marginal gain per token:

$ d^* = arg max_(d_i in C - S, c_i + sum_(d_j in S) c_j <= B) (F_q(S union {d_i}) - F_q(S)) / c_i. $

The algorithm stops when no remaining passage fits the budget. A direct implementation costs roughly $O(n^2)$ per query if marginal gains are recomputed against all candidates; we will measure this cost and may add lazy greedy evaluation as an optional optimization. We will also implement simpler baselines: top-ranked retrieval until the budget is full, relevance-only selection by relevance-to-cost ratio, random feasible selection, and MMR. For small synthetic or sampled instances, we may enumerate all feasible subsets to compare greedy results with the optimal solution.

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
  | Team Member 2 | Submodular objectives, greedy algorithm, and lazy-greedy extension. |
  | Team Member 3 | Retrieval candidates, MultiHop-RAG preprocessing, token costs, and similarities. |
  | Team Member 4 | Baselines, evidence metrics, and small brute-force optimal checks. |
  | Team Member 5 | Experiments, scalability analysis, figures/tables, report, and presentation. |
]
