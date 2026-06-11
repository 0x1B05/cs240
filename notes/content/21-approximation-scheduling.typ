#import "@preview/theorion:0.4.1": *
#import "@preview/tablem:0.3.0": three-line-table

#let OPT = math.op("OPT")
#let cost = math.op("cost")

= 第二十一章 Approximation Algorithms 与 Scheduling

#tip-box(title: "这一章的主线")[
  对 NP-hard 或 NP-complete 问题，精确最优解通常不可期待。Approximation algorithms 的目标是用多项式时间得到可证明接近最优的解。
]

== 为什么需要近似算法

前面许多算法都是 exact algorithms：输入一个实例，输出最优解。
但很多实践中重要的问题是 NP-complete 或 NP-hard，我们不知道多项式时间最优算法。

近似算法接受“不是最优”，但要求有可证明的质量保证：

- 对最大化问题，算法值不能太小；
- 对最小化问题，算法值不能太大；
- approximation ratio 越接近 1 越好。

== Approximation Ratio

#definition[
  对最大化问题，若算法 $A$ 总能输出值至少为最优值的 $1/alpha$，即

  $ A(I) >= OPT(I) / alpha, $

  则称 $A$ 是一个 $alpha$-approximation algorithm。
]

#definition[
  对最小化问题，若算法 $A$ 总能输出值至多为最优值的 $alpha$ 倍，即

  $ A(I) <= alpha OPT(I), $

  则称 $A$ 是一个 $alpha$-approximation algorithm。
]

这里 $alpha >= 1$。$alpha=1$ 就是精确算法；$alpha$ 越小越好。

== Set Cover

#definition[
  *Set Cover*：给定 universe $X$ 和一组集合 $cal(F)$，每个集合 $S in cal(F)$ 有 cost $cost(S)$，且所有集合的并为 $X$。
  目标是选出子集 $cal(G) subset.eq cal(F)$，使它们覆盖 $X$，并最小化总 cost。
]

Minimum set cover 是 NP-complete。课程中给出一个 $ln n$ 级别的贪心近似算法，其中 $n=|X|$。

== Set Cover 的贪心算法

贪心原则是：每次选“覆盖一个新元素最便宜”的集合。

维护：

- $U$：尚未覆盖的元素集合；
- $C$：已经选择的集合族。

算法如下：

1. 初始化 $U=X$，$C=emptyset$；
2. 当 $U != emptyset$ 时，选择使

   $ cost(S) / |S inter U| $

   最小的集合 $S$；
3. 把 $S$ 加入 $C$；
4. 从 $U$ 中删除 $S$ 覆盖的元素；
5. 输出 $C$。

这个算法一定输出 set cover，因为循环直到所有元素都被覆盖。

== Set Cover 的近似分析

设最优解代价为 $V=OPT$。分析用 charging argument：当一个集合被选中时，把它的 cost 平均分摊到它新覆盖的元素上。

关键观察是：如果当前还有 $k$ 个元素未覆盖，那么最优解仍然可以覆盖这 $k$ 个元素，总代价为 $V$。
因此在最优解的集合中，至少存在一个集合，它覆盖每个当前未覆盖元素的平均成本不超过 $V/k$。

贪心选择的是平均成本最低的集合，所以当还剩 $k$ 个元素时，被覆盖的每个新元素 charge 至多 $V/k$。

按元素被覆盖的顺序看：

- 第 1 个被覆盖的元素 charge 至多 $V/n$；
- 第 2 个至多 $V/(n-1)$；
- ...
- 最后一个至多 $V$。

总成本至多

$ V (1/n + 1/(n-1) + ... + 1) = V H_n <= V(1+ln n). $

因此贪心 set cover 是 $H_n$-approximation，也就是 $O(ln n)$-approximation。

== Makespan Scheduling

在并行计算中，有 $n$ 个 independent jobs 和 $m$ 台相同速度 processors。
每个 job $j$ 有处理时间 $p_j$，任意 job 可以放到任意 processor 上。

#definition[
  一个 schedule 的 *makespan* 是最后一台 processor 完成所有任务的时间。
  目标是最小化 makespan。
]

这个问题的 decision version 在 NP 中，并且可以从 SUBSET-SUM 归约得到 NP-complete。

归约直觉如下。给定 SUBSET-SUM 实例 $(S,t)$，令 $s=sum_(x in S) x$，构造 jobs：

$ J = S union {s - 2t}, $

并只使用 2 台 processors。若存在 $S' subset.eq S$ 使 $sum_(x in S') x=t$，则把 $S'$ 和 job $s-2t$ 放在一台机器上，负载为 $s-t$；剩余 $S-S'$ 放另一台机器上，负载也是 $s-t$。

反过来，如果 makespan 为 $s-t$，则包含 job $s-2t$ 的那台机器上其它 jobs 总和必须是 $t$，于是得到 SUBSET-SUM 的解。

== Graham's List Scheduling

由于 makespan scheduling 是 NP-complete，我们考虑近似算法。

List scheduling 是一个在线贪心算法：

1. jobs 按给定顺序到达；
2. 只要某台 processor 空闲，就把列表中的下一个 job 分给它；
3. 不需要预先知道所有 jobs。

这个算法简单，但有可证明保证。

#theorem(title: "List scheduling 是 2-approximation")[
  若 list scheduling 输出 makespan $M$，最优 makespan 为 $M^*$，则

  $ M <= 2M^*. $
]

证明抓住最后完成的 job $X$。设它开始时间为 $T$，处理时间为 $t$，则

$ M = T + t. $

首先，任何 schedule 都必须处理 $X$，所以

$ M^* >= t. $

其次，在 list scheduling 中，$X$ 开始之前没有 processor 空闲：只要有空闲 processor，就会立刻分配下一个 job。
所以在时间区间 `[0,T]` 内，$m$ 台机器一直在工作，总工作量至少为 $m T$。
任何最优 schedule 每单位时间最多处理 $m$ 单位工作，因此

$ M^* >= T. $

于是

$ M^* >= max(T,t), $

而

$ M = T+t <= 2 max(T,t) <= 2M^*. $

== List Scheduling 的紧例

List scheduling 的最坏情况来自“大 job 被排在最后”。

设有 $m^2$ 个长度为 1 的 jobs，另有一个长度为 $m$ 的 job。若输入顺序是：

`1, 1, ..., 1, m`

则 list scheduling 会先把短 job 平均铺满机器，最后长 job 可能使某台机器负载达到接近 $2m$。
而最优调度可以把长 job 与较少短 job 搭配，makespan 约为 $m+1$。

比值

$ 2m / (m+1) $

趋近于 2，说明 2-approximation 的分析在量级上是 tight 的。

== LPT Scheduling

LPT 表示 *Longest Processing Time first*。它和 list scheduling 一样把 job 分给空闲机器，但先按处理时间从大到小排序。

直觉是：长 job 最危险，如果拖到最后才放，可能造成很大 imbalance；先放长 job，可以让短 job 后面用来填缝。

例如 jobs 为 `2,3,3,4,5,6,8`，3 台 processors。
LPT 排序后为：

`8,6,5,4,3,3,2`

再按 list scheduling 分配，可得到 makespan 11，而随意顺序的 list scheduling 例子可能得到 13。

== LPT 的 4/3 近似直觉

#theorem(title: "LPT 的近似保证")[
  若最优 makespan 为 $M^*$，LPT 输出 makespan $M$，则

  $ M <= (4/3) M^*. $
]

证明思路仍看最后完成的 job $X$。设它开始于 $T$，大小为 $t$。
可以假设 $X$ 是最后一个开始的 job；否则删去更晚开始但不决定 makespan 的 job，不会让 makespan 增大。

因为 LPT 按非增顺序排序，最后开始的 job 一定是最小 job。

和 list scheduling 一样，在 $T$ 前没有机器空闲，因此

$ T <= M^*. $

所以

$ M = T+t <= M^* + t. $

分两种情况：

1. 若 $t <= M^* / 3$，则

   $ M <= M^* + M^* / 3 = (4/3)M^*. $

2. 若 $t > M^* / 3$，因为 $X$ 是最小 job，所有 job 都大于 $M^* / 3$。最优 schedule 中每台机器最多放两个 job，否则三件 job 总长超过 $M^*$。这时 LPT 的结构与最优匹配方式一致，因此不会比最优差。

课程 slides 给出的结论是 LPT 有 $4/3$ approximation ratio。

== LS 与 LPT 的取舍

LPT 的 approximation ratio 更好，但它是 offline algorithm：必须先知道所有 jobs，才能排序。

List scheduling 的 approximation ratio 较弱，但它是 online algorithm：jobs 来一个就能处理一个，不需要知道未来输入。

在真实并行系统中，jobs 往往在线到达，所以 LS 仍然非常有用。

== 本章小结

#figure(
  caption: [本章近似算法对比],
  three-line-table[
    | 问题 | 算法 | 近似比 | 关键证明思路 |
    |:---|:---|:---|:---|
    | Set Cover | per-unit-cost greedy | $H_n <= 1+ln n$ | charging argument |
    | Makespan Scheduling | List Scheduling | 2 | 最后完成 job：$M=T+t$，且 $M^*>=T,t$ |
    | Makespan Scheduling | LPT | $4/3$ | 长任务先排，最后任务是最小任务 |
  ],
)

#tip-box(title: "证明 approximation ratio 的套路")[
  先找算法输出值和 `OPT` 的共同下界或上界。Scheduling 里常用“总工作量”和“最大单个 job”作为 `OPT` 的下界；Set Cover 里常用最优解的平均成本给贪心步骤定价。
]
