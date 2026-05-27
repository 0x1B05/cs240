#import "@preview/charged-ieee:0.1.4": ieee
#import "@preview/tablem:0.3.0": tablem, three-line-table

#show: ieee.with(
  title: [Budgeted Submodular Context Selection for Retrieval-Augmented Generation],
  abstract: [
    Retrieval-augmented generation (RAG) systems retrieve external documents, but only a limited subset can be placed in the language model context. We formulate this context selection step as a knapsack-constrained monotone submodular maximization problem. The proposed adaptation transfers Lin and Bilmes's coverage-diversity framework for summarization to RAG evidence selection, where each document has a token cost and the objective rewards query-relevant, nonredundant coverage. On a 200-query MultiHop-RAG slice, we compare budgeted greedy submodular selection with top-ranked retrieval, relevance-per-token, seeded random, and MMR baselines. The study highlights the algorithmic connection between RAG context packing, budgeted maximum coverage, and greedy approximation, and it evaluates both evidence recovery and greedy-vs-optimal behavior on small instances.
  ],
  authors: (
    (
      name: "Junqi Liu - 2025234339",
      email: "liujq2025@shanghaitech.edu.cn",
    ),
    (
      name: "Team Member 2",
      email: "member2@shanghaitech.edu.cn",
    ),
    (
      name: "Team Member 3",
      email: "member3@shanghaitech.edu.cn",
    ),
    (
      name: "Zhixin Xiao - 2025234366",
      email: "xiaozhx2025@shanghaitech.edu.cn",
    ),
    (
      name: "Team Member 5",
      email: "member5@shanghaitech.edu.cn",
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

= Introduction

RAG systems use retrieval to expose external knowledge to a language model, but the retrieved list still has to be packed into a finite context window. Sending passages by retrieval rank alone ignores token costs and often repeats near-duplicate evidence. This work studies the packing step as a classical optimization problem: select a subset of passages under a knapsack-style token budget while maximizing a coverage/diversity objective.

The central question is whether Lin-Bilmes-style monotone submodular objectives can improve evidence coverage and reduce redundancy compared with rank-only or reranking baselines. The study is deliberately independent of live LLM calls, which makes the algorithmic behavior of the selector reproducible and easier to analyze.

The algorithmic relevance is direct. The finite context window induces a knapsack constraint, evidence coverage is a maximum-coverage objective, redundancy control is naturally modeled by diminishing returns, and the selector is optimized by a greedy approximation algorithm. Thus, modern RAG context selection provides a concrete setting for studying budgeted maximum coverage and monotone submodular maximization.

This work makes three contributions. First, it gives a formal reduction from RAG context packing to budgeted monotone submodular maximization. Second, it adapts the Lin-Bilmes coverage/diversity objective family from summarization to evidence selection with explicit token costs. Third, it evaluates the resulting greedy selector against rank-based, cost-normalized, random, and MMR baselines, including exhaustive optimal checks on small instances.

= Related Work

*Retrieval-augmented generation.* RAG augments a language model with external documents retrieved at inference time @lewis2020rag. A common pipeline first retrieves a ranked list and then places the highest-ranked items into the prompt. This pipeline makes retrieval explicit but leaves context packing under-specified: the model context is finite, retrieved items have unequal token costs, and multi-hop questions may require several distinct evidence documents. MultiHop-RAG provides a suitable evaluation setting because it includes multi-hop questions, answers, a document corpus, and gold evidence lists @tang2024multihoprag.

*Submodular summarization.* Lin and Bilmes propose a family of monotone submodular objectives for document summarization, combining coverage and diversity under a length constraint @lin2011submodular. Their formulation is a natural starting point for context selection because both summarization and RAG context packing require selecting a small subset that represents a larger information pool. This work reproduces the method-level comparison between coverage-only, diversity-only, and combined objectives, while replacing summary sentences with retrieved RAG contexts and replacing summary quality with evidence recovery.

*Diversity-based reranking.* Carbonell and Goldstein introduce maximal marginal relevance (MMR), which trades off query relevance against redundancy with respect to already selected items @carbonell1998mmr. MMR is a strong baseline for context selection because it directly discourages near-duplicate evidence. However, MMR optimizes a local reranking score, whereas the submodular formulation optimizes a global set function under an explicit budget.

*Budgeted maximum coverage.* The budgeted maximum coverage problem studies how to select valuable sets under costs @khuller1999budgeted. It provides the theoretical background for the present formulation: the context window is a knapsack constraint, and evidence coverage is a coverage objective with diminishing returns. This connection makes the study algorithmic rather than only an LLM application experiment.

= Adaptation and Contributions

The reproduction target is method-level rather than benchmark-identical. The central object reproduced from Lin and Bilmes is the coverage/diversity submodular optimization framework under a length budget, not a particular summarization benchmark. The adaptation introduces four changes. First, the budget is an LLM context-token proxy, so every candidate has an explicit token cost and selection is driven by marginal gain per token. Second, MultiHop-RAG evidence lists make it possible to evaluate selected contexts by evidence recall, precision, and $F_1$ instead of human summary scores. Third, the submodular methods are compared against top-ranked retrieval, relevance-per-token, seeded random, and MMR baselines. Finally, small candidate sets are checked by exhaustive search, so the greedy solution is compared with the exact optimum whenever feasible.

= Problem Formulation

For a query $q$, a retriever returns candidate passages $C = {d_1, ..., d_n}$. Passage $d_i$ has positive token cost $c_i$, and the context budget is $B$. The context selector outputs $S subset.eq C$:

$ max_(S subset.eq C) F_q(S) quad "subject to" quad sum_(d_i in S)c_i <= B. $

Each candidate has a nonnegative query relevance score $r_i$ and each pair has a nonnegative similarity $w_(i,j)$. In the experiments both are derived from TF-IDF cosine similarity. The coverage objective is

$ L_q(S) = sum_(i=1)^n r_i max_(j in S) w_(i,j), $

which rewards selected documents that represent many relevant candidates. The diversity objective is

$ R_q(S)=sqrt(sum_(i in S) r_i), $

which gives diminishing returns as more relevant mass is selected. The combined objective is

$ F_q(S)=L_q(S)+lambda R_q(S), quad lambda >= 0. $

The evaluated objective variants are:

+ Coverage-only: selected passages represent the candidate pool through maximum pairwise similarity.
+ Diversity-only: selected relevance mass receives a concave square-root reward.
+ Combined: coverage plus $lambda$ times diversity.

#place(
  top,
  float: true,
  scope: "parent",
  figure(
    image("figures/multihop_q200_docbudget_s13/method_overview.png", width: 94%),
    caption: [Overview of the context-selection pipeline. A retriever supplies candidates, feature extraction computes relevance, token cost, and pairwise similarity, budgeted greedy selection chooses a feasible context set, and the selected set is evaluated against MultiHop-RAG gold evidence.],
  ),
)

= Algorithm

The selector uses a density-based greedy rule. At each step, it considers only candidates that still fit within the remaining budget and adds the item with the largest marginal objective gain per token. After the iterative phase, the selected set is compared with the best feasible singleton; this safeguard is standard in budgeted coverage settings because a single expensive item can dominate a sequence of cheap marginal choices.

#block(stroke: 0.6pt + black, inset: 5pt, breakable: false)[
  *Algorithm 1: Budgeted Greedy Context Selection* \
  *Input:* candidates $C$, costs $c_i$, budget $B$, objective $F$. \
  *Initialize:* $S <- emptyset$. \
  1. While some $x in C without S$ satisfies $sum_(i in S)c_i + c_x <= B$, compute
  $rho_x = (F(S union {x}) - F(S)) / c_x$ for every feasible $x$. \
  2. Add $x^* = arg max_x rho_x$ to $S$. \
  3. Return the better of $S$ and the best feasible singleton.
]

The baselines cover several common alternatives. Top-ranked selection fills the context in retrieval order. Relevance/token selection sorts by $r_i/c_i$, adding a direct knapsack heuristic. Seeded random selection estimates a weak nonsemantic baseline. MMR greedily balances relevance and novelty using the maximum similarity to already selected items. These baselines separate the effects of ranking, token cost normalization, local redundancy control, and global submodular coverage.

= Theoretical Analysis

*Proposition 1.* The coverage objective used in the selector is monotone submodular.

Let the candidate set be $C={1,...,n}$. Each item $i$ has cost $c_i>0$, query relevance $r_i>=0$, and pairwise similarity $w_(i,j)>=0$. The coverage objective is

$ L(S) = sum_(i=1)^n r_i max_(j in S) w_(i,j), $

with $L(emptyset)=0$. For any $A subset.eq B subset.eq C$ and $x in C without B$, define $m_i(S)=max_(j in S) w_(i,j)$. Since $A subset.eq B$, $m_i(A) <= m_i(B)$ for every representative $i$. The marginal contribution of adding $x$ to set $S$ is

$ Delta_x^L(S) = sum_(i=1)^n r_i (max(m_i(S), w_(i,x)) - m_i(S)). $

For each $i$, the scalar term $max(m, w_(i,x))-m$ is nonincreasing in $m$. Because $m_i(A)<=m_i(B)$ and $r_i>=0$, we get $Delta_x^L(A) >= Delta_x^L(B)$. Thus $L$ has diminishing returns and is submodular. It is also monotone because adding an item can only increase each maximum.

*Proposition 2.* The diversity and combined objectives are monotone submodular.

The diversity objective is

$ R(S)=sqrt(sum_(i in S) r_i). $

The inner sum is a nonnegative modular function, and $sqrt(x)$ is nondecreasing and concave on $x>=0$. Therefore the marginal gain $sqrt(a+r_x)-sqrt(a)$ decreases as the accumulated relevance mass $a$ grows, so $R$ is also monotone submodular. The combined objective

$ F(S)=L(S)+lambda R(S), quad lambda>=0, $

is a nonnegative linear combination of monotone submodular functions, and is therefore monotone submodular.

The budget constraint $sum_(i in S)c_i<=B$ makes the problem a knapsack-constrained monotone submodular maximization problem, generalizing budgeted maximum coverage. The greedy selector maintains feasibility by considering only items satisfying $c_x + sum_(i in S)c_i <= B$, and chooses the feasible item with the largest marginal gain per cost, $Delta_x^F(S)/c_x$. We do not claim a stronger theorem than the implemented algorithm supports; instead, for small candidate sets we compute the exact optimum by exhaustive search and report $F(S_"greedy")/F(S^*)$ as an empirical approximation check.

#figure(
  kind: table,
  three-line-table[
    | *Method* | *Per-query time* |
    | :------ | :--------------- |
    | Top-ranked | $O(n)$ |
    | Relevance/token | $O(n log n)$ |
    | MMR | $O(n^2)$ |
    | Direct greedy | $O(n^3)$ worst case |
    | Exhaustive optimum | $O(2^n n)$ |
  ],
  caption: [Asymptotic per-query complexity of the selectors.],
)

The asymptotic ordering reflects the amount of set interaction each method uses. Top-ranked selection only scans the retrieval order; relevance/token adds sorting; MMR repeatedly checks redundancy against selected items; direct greedy recomputes a submodular marginal gain over the candidate representatives.

= Experimental Setup

The evaluation is fully offline. A deterministic TF-IDF retriever first produces a ranked candidate set for each query. Each selector then chooses a feasible subset under a token budget, and all methods are evaluated against the gold evidence document IDs supplied by MultiHop-RAG. This isolates the algorithmic context-selection problem from the variability and cost of live LLM calls.

#figure(
  kind: table,
  three-line-table[
    | *Component* | *Setting* |
    | :-------- | :------ |
    | Dataset | MultiHop-RAG, filtered to questions with nonempty evidence lists. |
    | Sample | 200 queries selected with seed 13. |
    | Candidate sizes | $N in {10,20,40}$. |
    | Budgets | $B in {1600,3200,6400}$ simple word tokens. |
    | Retrieval features | TF-IDF query relevance and pairwise cosine similarity. |
    | Baselines | Top-ranked, relevance/token, seeded random, and MMR. |
    | Proposed methods | Budgeted greedy with coverage, diversity, and combined objectives. |
    | Optimal check | Exhaustive search on small candidate sets, used only for validation. |
  ],
  caption: [Main experimental configuration.],
)

The official MultiHop-RAG corpus contains full news articles rather than short passages. Consequently, the budgets are document-level context budgets: they model selecting one to several articles instead of a handful of short chunks. Very small budgets make this real-data selection problem degenerate by admitting no article at all, so they are not used in the main evaluation.

We report evidence precision, recall, and $F_1$ by comparing selected document IDs with the gold evidence set for each query. Redundancy is the mean pairwise similarity among selected items, budget utilization is selected cost divided by $B$, and the runtime proxy counts deterministic inner-loop work rather than wall-clock time. For the proposed greedy selectors, the exhaustive small-instance check reports $F(S_"greedy")/F(S^*)$ when the optimum is computationally feasible.

= Results

== RQ1: Effect of the Token Budget

#figure(
  image("figures/multihop_q200_docbudget_s13/budget_sensitivity.png", width: 100%),
  caption: [Budget sensitivity on the 200-query MultiHop-RAG slice with top-10 candidates. Recall generally increases with larger budgets, while $F_1$ reflects the trade-off between recovering additional gold evidence and selecting extra non-evidence documents.],
)

Figure 2 shows that the token budget has a strong effect on recall. Moving from $B=1600$ to $B=3200$ roughly doubles the number of articles that can fit for many queries, and recall rises for all nonrandom methods. At $B=1600$, relevance/token obtains recall 0.230 and $F_1$ 0.322, while top-ranked obtains recall 0.166 and $F_1$ 0.229. At $B=3200$, relevance/token reaches recall 0.393 and $F_1$ 0.400, while submodular diversity reaches recall 0.391 and $F_1$ 0.397. The small gap suggests that simple cost normalization is a strong baseline when the retriever ranks evidence early.

At $B=6400$, recall continues to increase, but $F_1$ does not improve monotonically for every method. The reason is that larger budgets permit the selector to include more documents, which can recover missing evidence while also lowering precision. This behavior is expected in an evidence-coverage objective: the value of additional context depends on whether the evaluation rewards broad recall, strict precision, or a balance of both.

#figure(
  kind: table,
  three-line-table[
    | *Budget* | *Method* | *Recall* | *Precision* | *$F_1$* |
    | :------: | :------- | :------: | :---------: | :----: |
    | 3200 | Top-ranked | 0.320 | 0.450 | 0.360 |
    | 3200 | Relevance/token | 0.393 | 0.439 | 0.400 |
    | 3200 | Submodular diversity | 0.391 | 0.433 | 0.397 |
    | 6400 | Top-ranked | 0.492 | 0.374 | 0.407 |
    | 6400 | Submodular combined | 0.508 | 0.283 | 0.354 |
  ],
  caption: [Representative evidence-selection results for top-10 candidates.],
)

== RQ2: Precision--Recall Trade-off

#figure(
  image("figures/multihop_q200_docbudget_s13/precision_recall_tradeoff.png", width: 100%),
  caption: [Precision--recall trade-off as the budget increases from 1600 to 3200 to 6400 for top-10 candidates. Methods that aggressively fill the budget tend to move rightward in recall but downward in precision.],
)

Figure 3 makes the precision--recall trade-off explicit. At budget 6400 with top-10 candidates, top-ranked has the strongest summarized $F_1$ value, 0.407. The combined submodular objective reaches higher recall, 0.508, but lower $F_1$, 0.354, because it selects additional context that covers more evidence while also admitting more irrelevant articles. Relevance/token and submodular diversity also reach recall 0.528 at this budget, but their precision drops to 0.291.

The result should not be interpreted as a failure of submodularity. It shows that the current objective is tuned toward coverage of the candidate pool rather than strict gold-evidence precision. In a downstream RAG system, this behavior may be useful when missing one evidence article is more harmful than including an extra distractor. If strict precision is preferred, the objective can be adjusted by increasing cost penalties, reweighting relevance, or adding a learned evidence-likelihood term.

== RQ3: Scalability and Greedy Validation

#figure(
  image("figures/multihop_q200_docbudget_s13/scalability_optimality.png", width: 100%),
  caption: [Scalability and greedy validation. Panel (a) reports deterministic runtime proxy units as candidate size grows. Panel (b) compares greedy values with exhaustive optima on small instances where exact search is feasible.],
)

Figure 4 shows that the empirical runtime behavior matches the theoretical complexity analysis. Top-ranked and relevance/token remain cheap as $N$ grows, MMR increases because it repeatedly checks redundancy, and direct submodular greedy is the most expensive because each marginal-gain evaluation recomputes coverage over representatives. This cost is the main practical limitation of the direct implementation and motivates standard lazy-greedy acceleration as future work.

The greedy-vs-optimal panel provides a direct empirical check rather than relying only on the greedy heuristic. Across executed small-instance checks, the mean approximation ratios are 0.991 for coverage, 0.990 for diversity, and 0.990 for the combined objective; the medians are exactly 1.0 for all three objectives. The worst observed ratios are 0.874, 0.825, and 0.855 respectively. These numbers do not replace the classical approximation theory for budgeted submodular maximization, but they verify that the implemented selector is usually very close to the exhaustive optimum on the tested instances.

= Discussion and Limitations

Top-ranked selection is simple and often strong when the retriever ranks all gold evidence early, but it has no mechanism for token cost or redundancy. Relevance-ratio adds a knapsack-aware cost normalization. MMR adds a redundancy penalty but optimizes a local reranking score rather than a global coverage objective. The submodular methods explicitly value coverage over the candidate pool and expose the connection to budgeted maximum coverage.

The main deviation from Lin and Bilmes is the application domain. Their items are summarization units; our items are retrieved passages for a query. Their summary length budget becomes an LLM context-token budget, and our primary metric is evidence coverage instead of human summary quality. The method-level reproduction remains the same: compare coverage-only, diversity-only, and combined objectives under greedy budgeted selection.

There are two limitations. First, the retrieval stage is deliberately simple: TF-IDF is sufficient for a controlled algorithmic comparison, but a production RAG system would typically use dense retrieval or hybrid retrieval. Second, the current evaluation measures evidence selection quality rather than final generated-answer quality. This is appropriate for isolating the course-relevant optimization problem, but the next step would be to feed the selected contexts to an LLM and measure answer accuracy under the same budgets.

= Reproducibility

The experiments are deterministic: candidate generation, sampling, random baselines, and tie-breaking are all seeded. Raw data and saved candidate files are schema-validated before evaluation. Detailed preprocessing and execution notes are provided separately, while the report body focuses on the formulation, algorithm, and empirical findings.

= Conclusion

This work frames RAG context selection as a knapsack-constrained monotone submodular maximization problem. The resulting method-level reproduction preserves the central idea of Lin and Bilmes--coverage and diversity under a length budget--while adapting it to evidence selection for RAG. The results show that simple baselines remain strong, but submodular selection provides a principled way to trade precision for broader evidence coverage and gives a direct connection to maximum coverage, submodularity, greedy approximation, and knapsack constraints.
