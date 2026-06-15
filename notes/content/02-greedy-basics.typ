#import "@local/notes:0.1.0": *

= 第二章 贪心算法基础

#tip-block(title: "贪心最容易错的地方")[
  贪心算法不是“看起来顺手就行”。真正困难的部分几乎总是 *证明*：为什么这一步局部最优，不会把未来逼入死路？
]

== 贪心算法的基本思想

Lecture 2 给出的定义非常直接：
- 每一步都做当前看来最好的选择；
- 把这个选择加入当前部分解；
- 不回头修改过去的决策。

这类算法的优点是简单、快、实现直观；缺点是并不总是对。于是做题时要先问自己两件事：
1. 我选的“局部标准”到底是什么？
2. 这个标准能不能被证明会导向全局最优？

== 区间调度：为什么最早结束最对

#definition[
  *Interval Scheduling* 问题：给定若干作业，每个作业有开始时间 $s_j$ 和结束时间 $f_j$。
  两个作业不重叠则称为兼容。目标是选出最多个两两兼容的作业。
]

一个自然模板是：

- 按某种顺序扫描作业；
- 若当前作业与已选集合兼容，就把它加入答案。

问题在于，“某种顺序”不能乱选。下面这些规则都很诱人，但都有反例：
- 最早开始；
- 区间长度最短；
- 与别的作业冲突最少。

这些规则都能被反例击穿。真正正确的是：

#theorem(title: "区间调度的贪心规则")[
  对所有作业按结束时间从小到大排序，并依次选择当前仍兼容的作业，得到的解是最优的。
]

为什么“最早结束”好？直觉上，因为它为后面的作业留下了最大的剩余空间。这个直觉要变成证明，通常用 *exchange argument*：
- 把贪心解记为 $i_1, i_2, dots$。
- 把某个最优解记为 $j_1, j_2, dots$。
- 找到它们第一个不同的位置。
- 因为贪心选的是当前结束最早的作业，所以 $i_(r+1)$ 一定不会比 $j_(r+1)$ 结束得更晚。
- 因此把最优解中的 $j_(r+1)$ 换成 $i_(r+1)$，可行性不变，解的大小也不变。

这说明：即使最优解一开始没选贪心选的那个作业，我们也总能把它“修”成选了该作业的另一组最优解。

#important-block(title: "这类证明的常见模板")[
  交换论证的核心不是“贪心看起来合理”，而是：
  若某个最优解没有按贪心规则选，我们总能把它改造成按贪心规则选、且质量不变的另一个最优解。
]

复杂度方面，主要成本来自排序，因此总时间为 $O(n log n)$。

== 最小化最大迟到：为什么要按截止时间排

#definition[
  *Minimizing Lateness* 问题：单机按顺序处理全部作业。作业 $j$ 需要处理时间 $t_j$，
  截止时间为 $d_j$。若完成时间为 $f_j$，则迟到定义为
  $l_j = max(0, f_j - d_j)$。目标是最小化最大迟到
  $L = max_j l_j$。
]

又会出现几个看起来合理的规则：

- 先做处理时间最短的；
- 先做 slack 最小的，其中 slack 是 $d_j - t_j$；
- 先做截止时间最早的。

前两个都有反例，正确答案是 *Earliest Deadline First*：

#theorem(title: "最小化最大迟到的贪心规则")[
  按截止时间从早到晚安排所有作业，可以最小化最大迟到。
]

这一题的证明重点不在“空间留得更多”，而在 *逆序对*。

#definition[
  若两个作业满足 $d_i <= d_j$，但在一个调度中却让 $j$ 排在 $i$ 前面，
  则称 $(j, i)$ 构成一个 inversion。
]

证明结构是：

- 先说明存在一个最优调度没有空闲时间。
- 若某个无空闲调度里存在 inversion，则一定存在一对相邻的 inversion。
- 交换这对相邻反序作业，不会让最大迟到变得更大。
- 因而从任意最优解出发，可以不断消除 inversion，最后得到按截止时间排序的调度。

```
  Consider an adjacent inversion j,i with d_i <= d_j.
  Let S be the start time of j.
  Before exchange:
  C_i = S + t_j + t_i.
  After exchange:
  C'_j = S + t_i + t_j = C_i.
  Since d_i <= d_j, we have C'_j - d_j <= C_i - d_i.
  Also job i finishes earlier after the swap, so its lateness cannot increase.
  All other jobs are unaffected.
  Therefore swapping an adjacent inversion does not increase maximum lateness.
  Repeating this removes all inversions and yields the EDF schedule.
  Thus EDF is optimal.
```

这是一种非常经典的“局部交换不变差”证明。

#remark(title: "和区间调度的区别")[
  两题都属于贪心，但证明味道不同。
  区间调度更像“把最优解对齐到贪心解”；
  最小迟到更像“把坏结构逐步消掉，直到剩下贪心结构”。
]

== 贪心证明的三种常见套路

Lecture 2 末尾总结了三类证明策略：

#figure(
  caption: [贪心证明的三种常见套路],
  three-line-table[
    | 方法 | 核心问题 | 典型场景 |
    |:---|:---|:---|
    | Stays Ahead | 每一步后，贪心是否都“不比别人差” | 缓存、某些调度问题 |
    | Exchange Argument | 最优解能否逐步改造成贪心解 | 区间调度、最小迟到 |
    | Structural Bound | 是否存在所有解都绕不过去的结构性上界 | MST、切割类问题 |
  ],
)

做题时如果你不知道怎么证明，可以先问：这题更像比较前缀状态、替换一个选择，还是利用全局结构上界？

== 最小生成树：贪心规则为什么成立

#definition[
  *最小生成树*（MST）问题：给定连通无向带权图，选出一棵包含全部顶点的树， 使得边权和最小。
]

这一部分用了三个经典贪心算法：

- Kruskal：边按权重从小到大看，不成环就加。
- Prim：从一个起点出发，每次向外扩展最便宜的边。
- Reverse-Delete：边按权重从大到小删，不断开就删。

这三个算法都对，背后靠的是两条结构性质。

#theorem(title: "MST 的 cut property")[
  对任意一个点集划分 $S$，若边 $e$ 是所有跨越该 cut 的边中最轻的一条，则某棵 MST 一定包含 $e$。
]

#theorem(title: "MST 的 cycle property")[
  对任意一个环，若边 $f$ 是该环中最重的一条，则某棵 MST 一定不包含 $f$。
]

cut property 解释了 Kruskal 和 Prim 为什么安全：你挑的那条最轻跨 cut 边，不会犯错。cycle property 则解释了 Reverse-Delete：环里最重的边不值得保留。

#tip-block(title: "如何记住 cut property")[
  当图被分成两边时，任何生成树都必须至少用一条边把两边接起来。
  既然总得接，那最轻的那条边天然具有“优先保留”的资格。
]

还有一个小而重要的事实：一个 cycle 和一个 cutset 的交集边数一定是偶数。它本身不是你最常用的考试结论，但能帮助理解 cut 与 cycle 两种结构为何常常成对出现。

== 最大间距聚类：MST 的另一个视角

#definition[
  *k-clustering with maximum spacing*：把对象划分成 $k$ 个非空类，希望不同类之间最近点对的距离尽可能大。这个最近跨类距离叫做 spacing。
]

Lecture 3 给出的贪心算法非常像 Kruskal：
- 一开始每个点自己是一个簇；
- 每次合并当前距离最近、且属于不同簇的两部分；
- 一直做到只剩下 $k$ 个簇。

关键观察是：这其实就是 *Kruskal 跑到还剩 $k$ 个连通分量时停下*。等价地说：

#theorem(title: "最大间距聚类与 MST")[
  先求一棵最小生成树，再删去其中最重的 $k-1$ 条边，得到的正是最大间距的 $k$ 聚类。
]

这个结论很漂亮，因为它把一个看起来像“聚类”的问题，转成了一个已经很熟悉的图结构问题。

#remark(title: "为什么删最大的边")[
  MST 倾向于用尽量便宜的边把所有点接起来。若想切成 $k$ 份，最自然的做法就是把连接不同大块的“最贵边”剪掉。被剪掉的最小那条边，正好成为最后的 spacing。
]

== 离线缓存最优策略：Farthest-in-Future

#definition[
  *缓存问题*：缓存容量为 $k$，请求序列为 $d_1, d_2, dots, d_m$。
  若请求对象已在缓存中，称为 hit；否则是 miss，需要把对象调入缓存，若缓存已满则还要驱逐一个对象。目标是让 miss 次数最少。
]

这里讨论的是 *offline caching*，也就是你事先知道整个请求序列。此时最优策略是：

#theorem(title: "Farthest-in-Future")[
  当发生 miss 且必须驱逐时，驱逐那个“下一次被访问时间最晚”的对象，
  得到的离线缓存策略是最优的。
]

这个算法又叫 clairvoyant algorithm，因为它像“知道未来”。

证明思路并不短，但主线很清楚：
- 先把任意调度规整成 reduced schedule，也就是“只有在对象被请求且当前不在缓存时，才把它放进缓存”。
- 然后做归纳：假设某个最优 reduced schedule 已经在前 $j$ 次请求上和 FF 一致。
- 证明总能把它改成另一个同样最优的 reduced schedule，使其在前 $j+1$ 次请求上也和 FF 一致。

这其实是一种更强版本的交换论证。

#important-block(title: "online 和 offline 的边界")[
  FF 之所以最优，不是因为现实系统真能知道未来，而是因为它给出了 offline 的理论最优基线。
  后面分析在线缓存算法时，常常拿它做比较对象。
]

顺带比较两种在线策略：

- LRU 有良好的竞争比结论；
- LIFO 可以非常差。

这说明“局部直觉”在在线场景下比在离线场景更危险。
