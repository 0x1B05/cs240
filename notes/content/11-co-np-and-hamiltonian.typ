#import "@preview/theorion:0.4.1": *
#import "@preview/tablem:0.3.0": three-line-table

= 第十一章 co-NP、好刻画与 Hamiltonian 问题

#tip-box(title: "这一章要纠正一个直觉")[
  很多人第一次学 `NP` 时，会下意识觉得：
  “yes 实例有短证明，那 no 实例应该也差不多吧？”
  这一讲要讲清楚：这件事一点也不显然。
]

== NP 的不对称性

`NP` 的定义只关心 yes 实例：

- 如果答案是 yes，是否存在一个短证书；
- 并且我们能在多项式时间内检查它。

这天然带来一种不对称。

以 SAT 为例：

- 公式可满足时，给出一组赋值就能快速验证；
- 公式不可满足时，你该拿什么作为“证据”？

Hamiltonian cycle 也是一样：

- 若图有 Hamiltonian cycle，直接把这个环写出来即可；
- 若图没有，你很难用一张短纸条把“任何可能环都不行”说明白。

这就是 `NP` 的不对称性。

== co-NP：短“反证据”存在的问题

#definition[
  给定 decision problem $X$，其补问题记作 `bar(X)`，即把 yes/no 答案完全反转。
  所有补问题属于 `NP` 的那些问题，组成的类叫 `co-NP`。
]

因此，`co-NP` 的直觉是：

- yes 实例不一定容易证；
- 但 no 实例有短的 disqualifier。

典型例子包括：

- `TAUTOLOGY`；
- `NO-HAM-CYCLE`；
- `PRIMES`。

其中几个概念一定要分清：

- `SAT`：存在赋值使公式为真；
- `UNSAT`：不存在赋值使公式为真；
- `TAUTOLOGY`：所有赋值都使公式为真。

并且：

`phi` 是 `UNSAT` 当且仅当 `¬phi` 是 `TAUTOLOGY`。

#warning-box(title: "UNSAT 不是 SAT，只是把答案写成 no")[
  `UNSAT` 是 SAT 的补问题，不是“同一个问题里回答 no”这么简单。
  当我们说一个问题属于 `co-NP`，讨论的是“这个补问题的 yes 实例是否有短证书”。
]

== NP 是否等于 co-NP

课程给出的核心开放问题是：

#theorem(title: "NP vs co-NP")[
  我们是否有 `NP = co-NP`？
]

如果相等，就意味着：

- yes 实例有短证书；
- 当且仅当 no 实例也有短证书。

目前主流共识是“不相等”，但没人能证明。一个常用推论是：

#theorem(title: "若 NP != co-NP，则 P != NP")[
  如果 `NP != co-NP`，那么 `P != NP`。
]

理由并不复杂：

- `P` 在取补下是封闭的；
- 若 `P = NP`，那 `NP` 也会在取补下封闭；
- 于是得到 `NP = co-NP`。

这就是逆否命题。

== Good characterization：yes 和 no 都有短证据

Edmonds 提出的 *good characterization* 指的是问题同时属于 `NP` 与 `co-NP`。

#definition[
  若某个问题同时属于 `NP` 与 `co-NP`，
  则它的 yes 实例有短 certificate，no 实例也有短 disqualifier。
]

这类问题有特殊魅力，因为它们往往说明：

- 这个问题不像典型的 NP-complete 问题那样只有一边容易证；
- 它可能隐藏着更深的结构。

二分图完美匹配是一个很好的例子：

- 若存在完美匹配，可以把匹配本身作为证书；
- 若不存在，可以给出一组顶点 $S$，满足 `|N(S)| < |S|`，这正是 Hall 条件的违例证据。

这就是一个非常典型的“好刻画”。

#important-box(title: "好刻画为什么重要")[
  一个问题一旦被放进 `NP intersection co-NP`，
  你就知道它不像 SAT 那样只有 yes 端好证。
  这常常预示着问题可能进一步落入 `P`，或者至少拥有更强的结构定理。
]

== Factoring：在 `NP intersection co-NP`，但未必在 `P`

这里重点讨论因数分解相关问题。

#definition[
  *FACTOR*：给定整数 $x, y$，问 $x$ 是否存在一个小于 $y$ 的非平凡因子。
]

这里有两个结论：

- `FACTOR` 与 `FACTORIZE` 多项式等价；
- `FACTOR` 属于 `NP intersection co-NP`。

为什么？

- yes 证书：直接给出一个小于 $y$ 的因子；
- no 证据：给出 $x$ 的完整素因子分解，并附上各因子确实为素数的证明，
  从而说明所有非平凡因子都至少为 $y$。

这告诉你一件很重要的事：

- 在 `NP intersection co-NP` 里，不代表一定在 `P`；
- 只是说明这个问题不像典型 NP-complete 问题那样“两边证据极不对称”。

顺带记住：

- `PRIMES in P` 已由 AKS 算法证明；
- `FACTOR in P` 仍未知；
- 现代 RSA 正是建立在“生成大素数容易，而分解大合数似乎很难”的差异上。

== Hamiltonian cycle：序列型 NP-complete 的代表

从这里开始，课程又切回了另一类经典困难问题：*sequencing problems*。

#definition[
  *HAM-CYCLE*：给定无向图 $G = (V, E)$，问是否存在一个经过每个顶点恰好一次的简单环。
]

它与 SAT/独立集不同，不是在“选哪些元素”，而是在“能否排出一个覆盖全图的顺序/回路”。
这类问题往往比 packing/covering 更难有局部结构可利用。

== 有向 Hamiltonian cycle 与无向 Hamiltonian cycle

先看有向版本和无向版本的关系：

#theorem(title: "DIR-HAM-CYCLE <=_p HAM-CYCLE")[
  有向 Hamiltonian cycle 可多项式归约到无向 Hamiltonian cycle。
]

证明思路是把原图中每个顶点拆成一个小 gadget，使无向图里的 Hamiltonian tour 被迫按照某种固定次序穿过它，
从而编码出“进入”和“离开”的方向。

这个构造把每个原顶点扩展成 3 个颜色节点的链式结构。
这里不用记颜色本身，记它的作用就够了：

- 无向图本来没有方向信息；
- 于是必须用 gadget 强制一条 Hamiltonian cycle 穿过该顶点时，只能按两种镜像顺序之一访问；
- 这样才能把“顺着有向边走”这件事埋进无向图结构里。

== 从 3-SAT 到 Directed Hamiltonian Cycle

这是一个图比较多的 gadget 归约。第一次学时不必死背每一条边，先抓整体结构。

构造通常包含两层意思：

1. 变量选择：
   对每个变量 $x_i$，构造两条可走路径。
   从左到右穿过该变量 gadget 表示 `x_i = true`，
   从右到左穿过则表示 `x_i = false`。
2. 子句满足：
   对每个子句 $C_j$，额外放一个 clause node。
   只有当某个 literal 所在变量路径是以“正确方向”经过时，
   这个 clause node 才能被顺利 splice 进整条 tour。

于是得到的图满足：

- 若公式可满足，就能根据赋值选择每个变量 gadget 的行走方向，
  并把每个 clause node 嵌进至少一个为真的 literal 对应通道中；
- 若图存在 Hamiltonian cycle，则它在变量 gadget 中的穿越方向必然诱导出一个布尔赋值，
  并且每个 clause node 都必须借助某个“被满足的通道”被访问。

#tip-box(title: "如何读懂这种 Hamiltonian gadget")[
  只盯着单条边几乎一定会迷路。
  正确读法是：

  - 哪一部分在编码“二选一”的变量赋值；
  - 哪一部分在强制“每个 clause 至少有一个入口可用”；
  - 为什么 Hamiltonian 的“每点恰访一次”天然适合表达这种全局一致性。
]

== 本章小结

#figure(
  caption: [co-NP 与 Hamiltonian 问题的三条线],
  three-line-table[
    | 主题 | 要问的问题 | 记忆点 |
    |:---|:---|:---|
    | `co-NP` | no 实例能否高效证明 | `NP` 只管 yes，`co-NP` 讨论补问题 |
    | `NP intersection co-NP` | 两边是否都有短证据 | good characterization 往往意味着深结构 |
    | Hamiltonian 归约 | 如何把逻辑约束变成“一笔走完” | 变量方向 + 子句嵌入 |
  ],
)

#tip-box(title: "读完这一章先检查这些")[
  - 为什么 `NP` 的定义天然不对称；
  - `SAT`、`UNSAT`、`TAUTOLOGY` 三者是什么关系；
  - 好刻画为什么值得关注；
  - 为什么 factoring 的地位和典型 NP-complete 问题不同；
  - `3-SAT <=_p DIR-HAM-CYCLE` 的 gadget 到底在强制什么。
]
