#set page(width: 48in, height: 36in, margin: 0.42in)
#set text(font: "TeX Gyre Termes", size: 28pt)
#set par(justify: false, leading: 0.58em)
#set list(indent: 0.52em, body-indent: 0.62em, spacing: 0.18em)

#let blue = rgb("#1f4e79")
#let teal = rgb("#0f766e")
#let orange = rgb("#b45309")
#let slate = rgb("#334155")
#let light = rgb("#f8fafc")
#let line = rgb("#cbd5e1")

#let panel(title, body) = block(
  width: 100%,
  fill: light,
  stroke: 1.2pt + line,
  inset: 20pt,
  breakable: false,
)[
  #text(size: 36pt, weight: "bold", fill: blue)[#title]
  #v(8pt)
  #body
]

#let keybox(label, value, note, color: blue) = block(
  fill: rgb("#ffffff"),
  stroke: 1pt + line,
  inset: 15pt,
  width: 100%,
)[
  #text(size: 25pt, weight: "bold", fill: slate)[#label]
  #v(3pt)
  #text(size: 43pt, weight: "bold", fill: color)[#value]
  #v(3pt)
  #text(size: 23pt, fill: slate)[#note]
]

#let tight_image(path, h) = align(center)[
  #image(path, width: 100%, height: h, fit: "contain")
]

#align(center)[
  #text(
    size: 57pt,
    weight: "bold",
    fill: blue,
  )[Budgeted Submodular Context Selection for RAG]
  #v(5pt)
  #text(
    size: 34pt,
    fill: slate,
  )[CS240 Algorithm Design and Analysis Final Project]
  #v(3pt)
  #text(size: 28pt)[Junqi Liu, Xu Zhu, Yuxuan Fu, Zhixin Xiao, Ledu Zhang]
  #v(3pt)
  #text(size: 25pt, fill: slate)[Repo: https://github.com/0x1B05/cs240]
]

#v(0.18in)

#grid(
  columns: (1fr, 1.16fr, 1fr),
  gutter: 0.32in,
  [
    #panel([Problem], [
      RAG retrieves many documents, but only a few fit in the model context. Rank-only packing ignores token cost and repeated evidence.

      #v(6pt)
      *Optimization view:* choose documents $S subset.eq C$ under a token budget:

      #align(center)[$ max F_q(S) quad "s.t." quad sum_(d_i in S)c_i <= B $]

      This is a knapsack-constrained monotone submodular maximization problem.
    ])

    #v(0.18in)

    #panel([Submodular Objective], [
      Each document has relevance $r_i$, token cost $c_i$, and pairwise similarity $w_(i,j)$.

      #align(center)[$ L_q(S)=sum_i r_i max_(j in S) w_(i,j) $]
      #align(center)[$ R_q(S)=sqrt(sum_(i in S) r_i) $]
      #align(center)[$ F_q(S)=L_q(S)+lambda R_q(S) $]

      Coverage rewards representing the candidate pool. The concave diversity term gives diminishing returns. Their nonnegative sum is monotone submodular.
    ])

    #v(0.18in)

    #panel([Algorithms], [
      *Direct greedy:* repeatedly add the feasible document with largest marginal gain per token.

      #v(4pt)
      *Lazy greedy:* store cached marginal-gain densities in a priority queue. Submodularity makes old gains upper bounds, so many candidates avoid recomputation.

      #v(6pt)
      Baselines: top-ranked, relevance/token, seeded random, and corrected MMR.
    ])

    #v(0.18in)

    #panel([Theory], [
      *Coverage:* each selected document increases representative similarity maxima; marginal gains shrink as current maxima grow.

      #v(4pt)
      *Diversity:* $sqrt(sum_(i in S) r_i)$ is concave over modular relevance mass.

      #v(4pt)
      Therefore $F_q(S)=L_q(S)+lambda R_q(S)$ is monotone submodular for $lambda>=0$, under a knapsack budget.
    ])

    #v(0.18in)

    #panel([Adaptation], [
      Lin--Bilmes summarization becomes RAG context packing: summary units become retrieved documents, summary length becomes context-token budget, and quality is measured by gold-evidence recall, precision, and $F_1$.

      #v(4pt)
      *Evaluation:* selected document IDs are matched against MultiHop-RAG gold evidence lists.

      #v(4pt)
      *Reproducibility:* fixed seed 13, saved candidate caches, and generated artifacts make the run repeatable.
    ])
  ],
  [
    #panel([Pipeline], [
      #tight_image(
        "figures/multihop_q200_docbudget_s13_2/method_overview.png",
        5.55in,
      )
    ])

    #v(0.18in)

    #panel([Budget Sensitivity], [
      #tight_image(
        "figures/multihop_q200_docbudget_s13_2/budget_sensitivity.png",
        6.15in,
      )
      #v(4pt)
      Recall rises as the budget admits more articles. At $B=3200$, relevance/token reaches recall 0.393 and $F_1$ 0.400; submodular diversity reaches recall 0.391 and $F_1$ 0.397.
    ])

    #v(0.18in)

    #panel([Precision--Recall Trade-off], [
      #tight_image(
        "figures/multihop_q200_docbudget_s13_2/precision_recall_tradeoff.png",
        8.05in,
      )
    ])
  ],
  [
    #panel([Experimental Setup], [
      *Dataset:* 200-query MultiHop-RAG slice, seed 13.

      #v(5pt)
      *Candidates:* top $N in {10,20,40}$ TF-IDF retrieved documents.

      #v(5pt)
      *Budgets:* $B in {1600,3200,6400}$ simple word tokens.

      #v(5pt)
      *Metrics:* recall, precision, $F_1$, redundancy, budget use, runtime proxy.

      #v(5pt)
      *Validation:* exhaustive checks on small top-10 instances.
    ])

    #v(0.18in)

    #panel([Main Findings], [
      *Cost awareness:* relevance/token is a strong baseline.

      #v(5pt)
      *Recall:* combined selection with $lambda=2$ reaches recall 0.524 at $B=6400$.

      #v(5pt)
      *Precision:* top-ranked has stronger $F_1$ at high budget because it selects fewer distractors.

      #v(5pt)
      *Efficiency:* lazy greedy keeps the same objective while reducing marginal-gain evaluations.
    ])

    #v(0.18in)

    #panel([Scalability and Optimality], [
      #tight_image(
        "figures/multihop_q200_docbudget_s13_2/scalability_optimality.png",
        5.25in,
      )
      #v(4pt)
      At $N=40, B=6400$, direct combined greedy uses 8464 runtime-proxy units; lazy combined greedy uses 93.6. Greedy/exact ratios cluster near 1.0 on executed checks.
    ])

    #v(0.18in)

    #panel([Key Numbers], [
      #grid(
        columns: (1fr, 1fr),
        gutter: 0.15in,
        keybox([Recall], [0.524], [$lambda=2$, $B=6400$], color: teal),
        keybox([Runtime], [90x], [fewer evals at $N=40$], color: orange),
      )
      #v(8pt)
      #keybox(
        [Greedy/Optimal],
        [0.99],
        [mean ratio on exhaustive checks],
        color: blue,
      )
      #v(8pt)
      #text(size: 29pt, weight: "bold", fill: blue)[Takeaway]
      #v(4pt)
      Submodular selection makes the recall--precision trade-off explicit; lazy greedy keeps the same objective practical.
    ])
  ],
)
