#import "@preview/theorion:0.6.0": *
#import cosmos.fancy: *
#show: show-theorion

#let reducesto = math.attach($<=$, br: $p$)

= Final Review

== P/NP

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

=== NP-complete/hard

NP-complete: 问题 $Y$ 满足 $Y in "NP"$；对任意 $X in "NP"$ 都有 $X reducesto Y$ ($Y$ 自己能被快速验证，同时 `NP` 里的任何问题都能翻译成它。)
NP-hard: 问题 $Y$ 满足 对任意 $X in "NP"$ 都有 $X reducesto Y$ (`NP` 里的任何问题都能翻译成$Y$ 。)

若 $Y$ 是 NP-complete，则 $Y$ 可在多项式时间内求解，当且仅当 `P = NP`。

$"NP-complete" = "NP" inter "NP-hard"$

==== CIRCUIT-SAT

给定一个由 AND、OR、NOT 门组成的组合逻辑电路，问是否存在输入，使得输出为 1。
- `NP` 中任意问题都有多项式时间 certifier $C(s, t)$；
- 对固定输入长度，这个 certifier 的计算过程可以被一个多项式大小的电路模拟；
- 把实例 $s$ 硬编码进电路，把证书 $t$ 留作自由输入；
- 于是“是否存在证书使 certifier 接受”，就变成“这个电路是否可满足”。

它证明的是：*所有可快速验证的问题，本质上都能写成一个布尔计算是否有可行输入。*

证明一个问题 NP-complete，基本就是这三步：

1. 先证明目标问题 `Y in NP`；
2. 选择一个已经知道 NP-complete 的问题 `X`；
3. 证明 $X reducesto Y$。

==== 六大类 NP-complete 问题

这些经典问题可以粗略分成几类：

- packing：如 set packing、independent set；
- covering：如 set cover、vertex cover；
- constraint satisfaction：如 SAT、3-SAT；
- sequencing：如 Hamiltonian cycle、TSP；
- partitioning：如 3D-matching、3-color；
- numerical：如 subset sum、knapsack。

== Local Search

== 摊还分析

=== 栈(aggregate analysis)

现在考虑一共做 n 个操作，每个操作可能是：PUSH, POP,MULTIPOP

如果只看每个操作的 worst-case：PUSH: O(1);POP: O(1);MULTIPOP: O(n)

然后粗暴地说：最多 n 个操作, 每个操作最坏 O(n), 所以总成本 O(n^2). 正确，但不紧。

每个元素被 PUSH 进栈之后，最多只能被 POP 一次。但无论如何，一个元素一旦被弹出，就不在栈里了，不可能再被弹第二次。

总 POP 次数 <= 总 PUSH 次数

而整个操作序列一共有 n 个操作，因此：总 POP 次数 <= 总 PUSH 次数 <= n

所以总成本： <= n + n = 2n

因此： 总成本 = O(n)

==== 摊还成本是什么

如果一串 n 个操作总成本是：O(n)

那么平均到每个操作上就是：O(n) / n = O(1)

所以说：每个操作的 amortized cost 是 O(1)

MULTIPOP(S, 1000) 可能实际弹出 1000 个元素，实际成本是：1000, 但这些成本可以摊到之前那 1000 次 PUSH 上。

==== 证明方式

考虑任意长度为 n 的操作序列。直接证明整个序列的总成本是 O(n)。因此每个操作的摊还成本是 O(1)。

=== binary counter increment

想象一个二进制数，从全 0 开始：0000

每次执行： INCREMENT 就是把这个二进制数加 1。

把成本定义为：翻转一个 bit 的成本是 1. 所以一次 INCREMENT 的成本就是这次翻转了多少个 bits。

单次最坏情况

比如：011111, 加 1 后变成： 100000 这里总共翻转 6 位。

如果计数器有 k 位，那么单次 INCREMENT 最坏可能翻转：Theta(k)

如果前 n 次 increment 至多用到 log n 位，那么单次最坏是：O(log n), 于是粗暴分析：n 次操作 \* 每次 O(log n) = O(n log n)

实际上

最低位每次都变：0,1,0,1,0,1,...

所以前 n 次中，第 0 位翻转次数最多：n

第 1 位每 2 次翻转一次。它的变化周期是： 0,0,1,1,0,0,1,1,...

所以前 n 次中，第 1 位最多翻转： floor(n/2)
第 2 位每 4 次翻转一次： floor(n/4)
第 3 位每 8 次翻转一次： floor(n/8)

一般地： 第 i 位每 2^i 次 increment 翻转一次, 所以前 n 次里，第 i 位最多翻转：floor(n / 2^i)

总成本 = 所有 bit 的总翻转次数 = n + n/2 + n/4 + n/8 + ... = 2n

=== Accounting method

对栈操作可以这样收费：`PUSH` 收 2；`POP` 收 0；`MULTIPOP` 收 0。

每次 push 一个对象时：1 个单位支付这次 push 的真实成本；1 个单位作为信用放在这个对象上。

以后这个对象被普通 `POP` 或 `MULTIPOP` 弹出时，就用它身上的信用支付弹出成本。由于一个对象至多被弹出一次，信用不会不够。

binary counter 当某一位从 0 变成 1 时，收 2；1 个单位支付本次翻转；1 个单位存到这个 1 位上；当它以后从 1 变成 0 时，用存好的信用支付。

每次 increment 最多把一个 0 变成 1，因此收 2 足够覆盖所有未来清零。

=== Potential method：把信用写成势能

势能法用一个函数 `Phi(D)` 描述数据结构状态 $D$ 中存了多少“未来可用的信用”。

摊还成本 = 真实成本 + 势能变化

$hat(c_i) = c_i + Phi(D_i) - Phi(D_(i-1))$

模板
```
  For operation A:
  actual cost = ...
  Delta Phi = ...
  amortized cost = actual cost + Delta Phi = ...

  For operation B:
  suppose it does t units of expensive work.
  actual cost = ...
  Delta Phi = ...
  amortized cost = actual cost + Delta Phi = ...

  重点是昂贵操作那一项, 希望看到这种结构：
  actual cost = O(t)
  Delta Phi = -Omega(t)
```

==== Dynamic Table：扩容为什么仍是常数摊还

==== Fibonacci Heap：把整理工作延后

== 随机算法

- *Las Vegas algorithm* 总是输出正确答案，但运行时间是随机变量。分析目标是期望运行时间。
- *Monte Carlo algorithm* 运行时间通常固定或有确定上界，但可能输出错误答案。分析目标是错误概率。

=== 几何分布

几何分布经常出现在 Las Vegas 算法里。

$Pr[R = k] = (1 - p)^(k - 1) * p$

$E[R] = 1 / p$: $E = p * 1 + (1 - p) * (1 + E)$

$(1 - p)^t <= e^(-p t)$:  $Pr[R > t] = (1 - p)^t <= e^(-p t)$

如果每次成功概率是 $p$，重复 $t$ 次。全部失败概率是： $(1 - p)^t$ 如果我们想让失败概率不超过 $delta$，需要大概： $t >= ln(1/delta) / p$

```
  while true:
      随机尝试一次
      if 找到正确答案:
          return answer
```

如果每次成功概率是 p，那么尝试次数是几何分布。

=== Contention Resolution

有 n 个 processes。每一轮，每个 process 独立地以概率 p = 1/n 尝试 transmit。如果两个或更多 process 同时 transmit，就会冲突，大家都失败。

所以对一个固定 process，比如 process i，它某一轮成功的概率是：
$Pr["success"] = p(1-p)^(n-1) = (1/n)(1-1/n)^(n-1)$, between $1/(e n)$ and $1/(2n)$. $Theta(1/n)$, 即单个 process 每一轮成功概率大概是 1/n。

对一个固定 process 来说，每轮成功概率至少是： $1/(e n)$ 所以每轮失败概率至多是： $1 - 1/(e n)$. 失败 t 轮的概率: $P <= (1 - 1/(e n))^t$

如果把 R = 某个固定 process 第一次成功需要的轮数, 那么 R 可以看成近似几何分布，成功概率大概是： $1/n$. 所以它的期望成功时间大概是： $Theta(n)$

$(1 - x)^t <= e^(-x t)$, $x = 1/(e n)$
所以： $(1 - 1/(e n))^t <= e^(-t/(e n))$, 取 $t = e n * c ln(n)$

$e^(-t/(e n)) = e^(-(e n * c ln n)/(e n)) = e^(-c ln n) = n^(-c)$

所以对一个固定 process： $Pr["这个 process 在 t 轮后还没成功"] <= n^(-c)$ 运行 $O(n log n)$ 轮后，一个固定 process 失败的概率非常小。

Union Bound: $Pr(E_1 union E_2 union ... union E_n) <= Pr(E_1) + Pr(E_2) + ... + Pr(E_n)$

一共有 $n$ 个 processes，每个失败概率最多 $n^(-c)$，所以：

Union Bound over n processes:$Pr["至少一个失败"] <= n * n^(-c) = n^(1-c)$

如果取 $c = 2$，那么： $Pr["至少一个失败"] <= 1/n$, 所以运行 $O(n log n)$ 轮后，所有 processes 都至少成功一次的概率至少是 $1 - 1/n$。

=== Random Load Balancing

有 m 个 jobs, 有 n 台 machines。每个 job 独立、均匀随机地选择一台 machine。也就是说，对每个 job： $Pr["job 被分到 machine i"] = 1/n$

问题是每台机器最后拿到多少 jobs？最大负载会不会特别大？

先固定一台机器，比如 machine i。 定义：
$X_i = "machine i 得到的 job 数量"$

对每个 job j，定义：

$Y_(i j) = 1, "如果 job j 被分到 machine i"$

$Y_(i j) = 0, "否则"$

那么 machine i 的总负载就是： $X_i = Y_(i 1) + Y_(i 2) + ... + Y_(i m) = sum_{j=1}^m Y_(i j)$

$E[X_i] = E[Y_(i 1) + Y_(i 2) + ... + Y_(i m)] = E[Y_(i 1)] + E[Y_(i 2)] + ... + E[Y_(i m)] = m * (1/n) = m/n$

Chernoff for one machine, union bound for max load across all machines.

Chernoff upper bound 是： $Pr[X_i >= (1 + d) * mu] <= exp(-mu * d^2 / 3)$

我们通常把单个对象的失败概率压到 $1/n^c$， 例如 $1/n^3$。然后n 个对象 union bound 后仍然很小。

所以如果我们想让右边小于等于：$1/n^3$
那就希望： $e^(-(mu * d^2) / 3) <= 1/n^3 = e^(-3 ln n)$
所以只要： $mu * d^2 / 3 >= 3 ln n$
所以这一步本质是： 选择 $d$ 足够大，使得 $mu * d^2$ 至少是 $9 ln(n)$。

Markov: $Pr[X>=a] <= E[X]/a$
Chebyshev:
$sigma = sqrt("Var"[X])$, $a = k * sigma$, $Pr[ |X - E[X]| >= k * sigma ] <= 1 / k^2$, 偏离期望至少 k 个标准差的概率 <= $1/k^2$
Chernoff Bound: $Pr[X >= (1 + d) * mu] <= e^(-(mu d^2) / 3)$, $mu = E[X], d = delta$，$delta$表示超过期望的比例

