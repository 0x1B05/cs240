#import "@local/notes:0.1.0": *

= 第十章 NP 完全性

#tip-block(title: "这一章解决的问题")[
  上一章讲了归约是什么。这一章开始用归约做复杂性证明：
  如果一个问题被证明为 NP-complete，就说明它不是“暂时没想出算法”那么简单。
]

== Cook reduction 与 Karp transformation

先区分两个名字。它们很像，但写证明时常见的是后者。

#definition[
  *Polynomial reduction*（Cook reduction）允许你在多项式时间预处理中，多次调用目标问题 $Y$ 的 oracle。
]

#definition[
  *Polynomial transformation*（Karp reduction）要求你对任意输入 $x$，在多项式时间内构造一个新输入 $y$，使得 $x$ 是 yes 实例当且仅当 $y$ 是 yes 实例。
]

Karp 归约可以看成更“瘦身”的版本：

- 只调用一次 oracle；
- 而且这次调用放在最后一步；
- 本质上就是把一个问题实例直接翻译成另一个问题实例。

复杂性教材里大多数具体归约，其实都是 Karp 归约。课程里为了叙述方便，仍统一记作 `<=_p`。

== 什么叫 NP-complete

#definition[
  若问题 $Y$ 满足：

  - `Y in NP`；
  - 对任意 `X in NP` 都有 `X <=_p Y`；

  则称 $Y$ 为 *NP-complete*。
]

这个定义有两层意思：$Y$ 自己能被快速验证，同时 `NP` 里的任何问题都能翻译成它。
所以它代表的是 `NP` 中最难的一批判定问题。

#theorem(title: "NP-complete 与 P=NP 的等价性")[
  若 $Y$ 是 NP-complete，则 $Y$ 可在多项式时间内求解，当且仅当 `P = NP`。
]

这条定理解释了为什么大家会认真对待 NP-complete 证明。

- 如果你把某问题证明成 NP-complete，就等于说：
  除非 `P = NP`，否则别期待它有一般情形下的多项式时间算法。
- 反过来，只要任何一个 NP-complete 问题有多项式时间算法，所有 `NP` 问题都会有。

== 第一个 NP-complete 问题：Circuit-SAT

先按历史顺序看：

- 先定义 `NP`；
- 再必须找到一个“天然”的、确实是 NP-complete 的问题；
- 有了这个起点，后面的问题才能像多米诺骨牌一样连续展开。

这个起点就是：

#definition[
  *CIRCUIT-SAT*：给定一个由 AND、OR、NOT 门组成的组合逻辑电路，问是否存在输入，使得输出为 1。
]

Cook-Levin 定理说明它是 NP-complete。证明可以先按下面的直觉理解：

- `NP` 中任意问题都有多项式时间 certifier $C(s, t)$；
- 对固定输入长度，这个 certifier 的计算过程可以被一个多项式大小的电路模拟；
- 把实例 $s$ 硬编码进电路，把证书 $t$ 留作自由输入；
- 于是“是否存在证书使 certifier 接受”，就变成“这个电路是否可满足”。

#remark(title: "Cook-Levin 做了什么")[
  Cook-Levin 不是只证明了“一个电路问题很难”。
  它证明的是：*所有可快速验证的问题，本质上都能写成一个布尔计算是否有可行输入。*
  这是 `NP` 被统一刻画的关键。
]

== 如何建立一个新问题是 NP-complete

以后证明一个问题 NP-complete，基本就是这三步：

1. 先证明目标问题 `Y in NP`；
2. 选择一个已经知道 NP-complete 的问题 `X`；
3. 证明 `X <=_p Y`。

#important-block(title: "为什么只需要找一个已知 NP-complete 问题来归约")[
  因为若 `X` 已经是 NP-complete，那么 `NP` 中任意问题 `W` 都有 `W <=_p X`。
  再接上 `X <=_p Y`，就由传递性得到 `W <=_p Y`。
  所以 `Y` 自动继承了“对所有 NP 问题都至少一样难”这一性质。
]

这也是为什么你经常会看到证明模板写成：

- “显然 `Y in NP`。”
- “下面证明 `3-SAT <=_p Y`。”

== NP-hard 与 NP-complete 的区别

#definition[
  若对任意 `X in NP` 都有 `X <=_p Y`，则称 $Y$ 为 *NP-hard*。
]

与之相比，NP-complete 还额外要求 `Y in NP`。

所以：

`NP-complete = NP intersection NP-hard`

这一区别不能混。因为有些问题虽然至少和所有 `NP` 问题一样难，但它们本身未必是 decision problem，
甚至未必属于 `NP`。例如某些优化问题、搜索问题、甚至更难的不可判定问题，都可能只是 NP-hard。

== 3-SAT 为什么也是 NP-complete

接着把注意力从 circuit 拉回到更离散的 `3-SAT`。

#theorem(title: "3-SAT 是 NP-complete")[
  `3-SAT in NP`，并且 `CIRCUIT-SAT <=_p 3-SAT`。
]

这个证明值得认真读一遍，因为它展示了如何把“局部计算规则”翻译成 clause。

做法是：

- 对电路中的每个 gate/output/wire 赋予一个布尔变量；
- 再为每个门加入局部约束，确保这个变量组合必须符合门的真值表；
- 最后再额外加入子句，强制输出结点为真，以及强制那些硬编码输入取给定值。

例如：

- 若某节点表示 `$x_2 = ¬x_3$`，就加入若干 clause 保证两者互为取反；
- 若某节点 $x_1 = x_4 or x_5$，就加入 clause 保证 $x_1$ 与两个输入满足 OR 的关系；
- AND 门同理。

于是得到的 3-CNF 公式满足：

- 若原电路可满足，则把每个节点按真实计算结果赋值，就能满足这些 clause；
- 若公式可满足，则这些变量必须表现得像一个自洽的门电路计算，且最终输出为真。

#tip-block(title: "你不需要死记每个门对应哪几条子句")[
  要掌握的是这个模板：

  - 一个局部门关系；
  - 被翻译成常数条 clause；
  - 所有局部约束合在一起，就逼出了全局一致的计算。
]

== 为什么 3-SAT 成了“默认起点”

一旦 3-SAT 被证明成 NP-complete，它就有两个巨大的教学优势：

- 公式结构简单，便于携带真假约束；
- 很多图论/组合问题都能自然地把“变量选择”和“子句满足”编码进去。

这也是为什么后面连续几讲里，大量归约都从 3-SAT 出发：

- 到独立集；
- 到 Hamiltonian cycle；
- 到 3-color；
- 到 3D-matching；
- 到 subset-sum。

从这里开始，3-SAT 就成了后面很多归约的默认起点。

== 六大类 NP-complete 问题

这些经典问题可以粗略分成几类：

- packing：如 set packing、independent set；
- covering：如 set cover、vertex cover；
- constraint satisfaction：如 SAT、3-SAT；
- sequencing：如 Hamiltonian cycle、TSP；
- partitioning：如 3D-matching、3-color；
- numerical：如 subset sum、knapsack。

这张分类表的用处是帮你识别一个新问题更像哪种结构：

- 一个新问题是“选不冲突对象”吗？那可能接近 packing；
- 是“用少量对象覆盖所有需求”吗？那可能接近 covering；
- 是“给变量赋值满足一堆条件”吗？那通常靠 SAT；
- 是“排一个全局顺序或回路”吗？那往往靠 sequencing；
- 是“把元素分到几组里互不冲突”吗？那常靠 partitioning；
- 是“整数能否凑出某个值”吗？那是 numerical。

== NP-completeness 的意义不只是“证明很难”

NP-complete 的影响远超算法课本本身。
它能给科学研究提供一种 *负面指导*：

- 如果你已经把某自然问题证明成 NP-complete，
- 那就不应再盲目寻找一般情形下的精确多项式算法；
- 更合理的方向通常是：
  特殊情形、近似算法、参数化算法、启发式、或指数时间但更优的 exact algorithm。

#warning-block(title: "复杂性分类是一种研究方向选择器")[
  证明一个问题 NP-complete，不等于“这个问题没价值”。
  恰恰相反，它告诉你：别再朝错误的方向浪费十年。
]

== 本章小结

#figure(
  caption: [建立 NP-complete 的标准流程],
  three-line-table[
    | 步骤 | 要做什么 | 典型陷阱 |
    |:---|:---|:---|
    | 证明 `Y in NP` | 给出短证书与多项式时间 verifier | 只说“看起来容易验证”却不具体 |
    | 选择来源问题 `X` | 选一个已知 NP-complete 问题 | 选了一个难度关系不清的问题 |
    | 证明 `X <=_p Y` | 构造实例翻译并证明 iff | 把归约方向写反 |
  ],
)

#tip-block(title: "读完这一章先检查这些")[
  - 区分 Cook reduction 与 Karp transformation；
  - 解释 NP-complete 为什么和 `P = NP` 绑在一起；
  - 说清 Cook-Levin 定理在直觉上做了什么；
  - 理解为什么 3-SAT 成了后续归约的统一起点；
  - 正确区分 NP-hard 与 NP-complete。
]
