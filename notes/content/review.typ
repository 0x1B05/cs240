#import "@preview/theorion:0.6.0": *
#import cosmos.fancy: *
#show: show-theorion

#let reducesto = math.attach($<=$, br: $p$)

= P/NP

#definition("Reduction")[
  *Reduction*: Problem $X reducesto Y$ if arbitrary instances of problem X can be solved using:
  - Polynomial number of standard computational steps, plus
  - Polynomial number of calls to oracle that solves problem Y
]

它的含义是：如果我会解 $Y$；那我也就会解 $X$。因此，归约方向必须这样：$X reducesto Y$ 表示“$Y$ 至少和 $X$ 一样难”。

#example[
  X 一元一次方程, Y 一元二次方程. $X reducesto Y$, 如果我会解一元二次方程, 那么就一定可以解一元一次方程.
]

- *Independent Set*：是否存在大小至少为 $k$ 的点集, 图里面选点，但*不能选到一条边的两个端点*。
- *Vertex Cover*：是否存在大小至多为 $k$ 的点集, 对图里的每一条边 (u, v)，你选出来的点集 C 里面，必须包含 u 或者 v，也可以两个都包含。
  - 对任意图 $G = (V, E)$，集合 $S$ 是Independent Set，当且仅当 $V - S$ 是vertex cover。
- *Set Cover*：给定全集 $U$、若干子集 $S_1, S_2, dots, S_m subset.eq U$ 以及整数 $k$，问是否能选出不超过 $k$ 个集合，使它们的并集恰好覆盖 $U$。

归约的三种常见方式
#example(title: "Simple Equivalence, 简单等价")[
  Claim. Vertex-cover ≡p Independent-set
  pf:
  - =>
    - Let S be any independent set
    - Consider an arbitrary edge (u, v)
    - S independent→u ∉S or v ∉S→u ∊V– S or v ∊V- S
    - Thus,V– Scovers(u, v)
  - <=
    - Let V - S be any vertex cover
    - Consider two nodes u ∊Sand v ∊S
    - Observe that (u, v) ∉Esince V– S is avertex cover
    - Thus, no two nodes in S are joined by an edge →Sindependent
]

#example(title: "从特殊情形归约到一般情形")[
  Claim. Vertex-cover $reducesto$ Set-cover
  Pf.
  Given avertex-cover instance G=(V,E),k, we construct a set cover instance (U, S) whose size equals to the size of the vertex cover instance
  Construction.
  Create Set-cover instance: k=k, U=E, Sv={e ∊E:e incident to v}
  Set-cover of size≤k iff vertex cover of size≤k
]

- *Literal*：一个布尔变量 $x$ 或其否定 $not x$。
- *Clause*：若干个文字的 *析取*（逻辑“或”，记作 $or$）。$(x_1 or not x_2 or x_3)$
- *CNF*：一个命题公式是若干个子句的 *合取*（逻辑“与”，记作 $and$）。$(x_1 or not x_2) and (x_2 or x_3 or not x_4) and (not x_1 or x_4)$。
- *SAT (Boolean Satisfiability Problem)*：给定一个 CNF 公式，问是否存在一组对布尔变量的赋值（True / False），使得整个公式为真？举例公式 $(x_1 or x_2) and (not x_1 or not x_2)$ 是可满足的。例如取 $x_1 = "True"$, $x_2 = "False"$ 即可。SAT 是第一个被证明的 *NP-完全* 问题（Cook-Levin 定理）。
  - *3-SAT*：SAT 的一种特例，要求每个子句 *恰好包含 3 个不同的文字*。举例$(x_1 or not x_2 or x_3) and (not x_1 or x_2 or x_4)$。3-SAT 同样属于 NP-完全问题，并且常被用作其他 NP-完全问题的归约起点。

#example(title: "gadget 编码逻辑约束")[
  3-SAT $reducesto$ Independent-set

  Pf. Given an instance $Phi$ of 3-SAT, we construct an instance (G, k) of independent-set that has an independent set of size k iff $Phi$ is satisfiable
  - Construction
  - G contain 3 vertices for each clause, one for each literal
  - Connect 3 literals in a clause in a triangle
  - Connect literal to each of its negations

  Claim.G contains independent set of size k = |$Phi$| iff $Phi$is satisfiable
  - Pf. →Let S be independent set of size k
  - S must contain exactly one vertex in each triangle
  - Set these literals to true and any other variables in a consistent way
  - Truth assignment is consistent and all clauses are satisfied
  - Pf. Given satisfying assignment, select one true literal from each triangle. This is an independent set of size k
]

3-SAT $reducesto$ Independent Set $reducesto$ Vertex Cover $reducesto$ Set Cover。

- 若 X $reducesto$ Y 且 $Y$ 可在多项式时间内解决，则 $X$ 也可在多项式时间内解决。
- 若 X $reducesto$ Y 且已知 $X$ 不可能多项式时间解决，那么 $Y$ 也不可能。

self-reducibility 想说：

如果有一个能回答判定版的 oracle，那么我可以用它反复询问，最后恢复出优化版的最优解。(很多优化问题都可以 self-reduce 到 decision version, 不是全部)

#example[
  G 是否存在大小 ≤ k 的 vertex cover？
  Oracle(G,k) = yes iff G has a vertex cover of size ≤ k
  可以对k二分找到最小的 yes, 最小的k

  接着逐个尝试顶点，判断某个最优解能不能包含它

  最小 vertex cover 是什么？输出不只是 yes/no，而是要真的给出一组点，比如：{v2, v5, v9}
]

- P(polynomial)：有多项式时间算法的问题
- NP(nondeterministic polynomial): 多项式时间可验证的问题
  - *COMPOSITES*：给定 N，问 N 是不是合数, 证书是一个非平凡因子
  - *SAT*：是否有赋值让公式为true, 证书是一组布尔变量赋值；
  - *HAM-CYCLE*：是否有经过每点一次的环, 证书是一个顶点排列，表示 Hamiltonian cycle 的访问顺序。

$P subset.eq "NP"$, 多项式时间可解决那么多项式时间一定可验证, 反之不然.

- $P subset.eq "NP"$：若一个问题本来就能直接多项式时间求解，那么把证书取成空串即可；
- $"NP" subset.eq "EXP"$：若一个问题有多项式长度证书，就可以暴力枚举所有可能证书，虽然数量是指数级，但终究还能在指数时间内完成。

我们是否有 `P = NP`？即一个答案若容易验证；是否也一定容易找到？

Cook reduction 可以这样：

```
解 X(x):
    问 Y(y1)
    如果回答 yes:
        问 Y(y2)
    否则:
        问 Y(y3)
    ...
    最后输出 yes/no
```

Karp reduction 只能这样：

```
解 X(x):
    构造 y = f(x)
    问 Y(y)
    输出同样的 yes/no
```

== NP-complete/hard

NP-complete: 问题 $Y$ 满足 $Y in "NP"$；对任意 $X in "NP"$ 都有 $X reducesto Y$ ($Y$ 自己能被快速验证，同时 `NP` 里的任何问题都能翻译成它。)
NP-hard: 问题 $Y$ 满足 对任意 $X in "NP"$ 都有 $X reducesto Y$ (`NP` 里的任何问题都能翻译成$Y$ 。)

若 $Y$ 是 NP-complete，则 $Y$ 可在多项式时间内求解，当且仅当 `P = NP`。

$"NP-complete" = "NP" inter "NP-hard"$


=== CIRCUIT-SAT

给定一个由 AND、OR、NOT 门组成的组合逻辑电路，问是否存在输入，使得输出为 1。




