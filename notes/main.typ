#import "@local/notes:0.1.0": *
#import "@preview/theorion:0.4.1": *
#import "@preview/tablem:0.3.0": three-line-table

#show: notes.with(
  title: [CS240 算法设计与分析课程讲义],
  short_title: "CS240 Notes",
  abstract: [
    本讲义根据课程 `Algorithm Design and Analysis` 的 Lecture 0 到 Lecture 16
    整理而成。内容按主题组织：导论、贪心、分治、动态规划、网络流，以及复杂性理论与特殊情形处理。每一章重点解释算法为什么成立、状态和贪心规则如何设计、证明时应抓住什么结构，以及不同算法范式之间的联系。后半部分整理归约、`P/NP/co-NP`、NP-complete、PSPACE、FPT，以及 NP-hard 问题的特殊结构处理方法。
  ],
  date: datetime(year: 2026, month: 4, day: 26),
  authors: (
    (
      name: "0x1B05",
      link: "https://github.com/0x1B05",
    ),
  ),
  bibliography-file: none,
  paper_size: "a4",
  font: (
    "Tex Gyre Termes",
    "Noto Serif CJK SC",
  ),
  code_font: "FiraCode Nerd Font Mono",
  toc: true,
)

#set text(lang: "zh")

#include "content/01-intro-tractability.typ"
#include "content/02-greedy-basics.typ"
#include "content/03-divide-conquer.typ"
#include "content/04-dynamic-programming.typ"
#include "content/05-flow-basics.typ"
#include "content/06-maxflow-mincut.typ"
#include "content/07-flow-applications-1.typ"
#include "content/08-flow-applications-2.typ"
#include "content/09-reductions-p-np.typ"
#include "content/10-np-completeness.typ"
#include "content/11-co-np-and-hamiltonian.typ"
#include "content/12-tsp-coloring.typ"
#include "content/13-3dm-subset-sum.typ"
#include "content/14-pspace.typ"
#include "content/15-fpt-special-cases.typ"
