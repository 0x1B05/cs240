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
