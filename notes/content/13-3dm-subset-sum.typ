#import "@local/notes:0.1.0": *

= 第十三章 3D 匹配与子集和

#tip-block(title: "这一章怎么读")[
  这一章继续做 NP-complete 归约。重点不是背每个 gadget，
  而是看清楚“匹配约束”和“数字位数”怎么承载逻辑条件。
]

== 3-Dimensional Matching：匹配不只存在于二分图

#definition[
  *3D-MATCHING*：给定三个互不相交的集合 $X, Y, Z$，它们大小都为 $n$，
  以及一个三元组集合 $T subset.eq X times Y times Z$。
  问是否存在 $n$ 个三元组组成的子集，使得 $X union Y union Z$ 中每个元素都恰好出现一次。
]

你可以把它看成二分图完美匹配的三维版本：

- 二分匹配里，一条边同时占用左右各一个元素；
- 3D matching 里，一个 triple 同时占用三侧各一个元素。

这种“一个选择同时消耗三种资源”的结构，会比普通匹配困难得多。

== 从 3-SAT 到 3D-MATCHING 的总体结构

`3-SAT <=_p 3D-MATCHING` 的构造元素很多，逐个硬记很痛苦。先按三个部件理解：

1. 变量 gadget：
  对每个变量 $x_i$，构造一串 core/tip 元素。
  在任何 perfect 3D matching 中，你必须在两组互斥 triple 中整组选择其一：
  一组代表 `x_i = true`，另一组代表 `x_i = false`。
2. 子句 gadget：
  对每个子句 $C_j$，构造少量额外元素和三条候选 triple，
  分别连接到该子句三个 literal 对应的某个 tip。
  这样 clause gadget 想被覆盖，就必须借助某个“当前被允许使用”的 literal tip。
3. cleanup gadget：
  因为变量 gadget 里总会剩下大量没被 clause 用掉的 tip，
  还要再加一些清扫 triple，把这些剩余 tip 刚好填满。

这样设计后：

- 若公式可满足，就按赋值选择每个变量 gadget 的 true/false triple，
  再为每个 clause 选一个为真 literal 的 clause triple，
  最后用 cleanup gadget 收尾；
- 若存在完美 3D matching，则变量 gadget 中的整组选择必然诱导出一个一致赋值，
  而每个 clause gadget 被覆盖又保证了至少有一个 literal 为真。

#important-block(title: "3D matching gadget 的本质")[
  它利用了 perfect matching 的“每个元素恰好被用一次”这一刚性约束，
  把布尔变量的二选一和子句的至少一真都编码了进去。
]

== SUBSET-SUM：一个数值问题为何会 NP-complete

#definition[
  *SUBSET-SUM*：给定自然数 $w_1, dots, w_n$ 以及目标值 $W$，
  问是否存在一个子集，其元素和恰好等于 $W$。
]

这个问题表面上很像小学加法，但它的困难并不在 arithmetic 本身，而在于：

- 你要在指数多个子集里作组合选择；
- 还要让这些选择同时满足很多隐含约束。

这里有一个容易丢分的复杂性细节：

#warning-block(title: "数值问题一定要注意输入编码长度")[
  对整数问题，输入大小按 *二进制长度* 计算。
  因此一个依赖于数值大小 `W` 的算法，不一定是关于输入长度 `log W` 的多项式时间算法。
]

这也是为什么 knapsack/subset-sum 会出现“有动态规划，但仍然 NP-complete”的现象。

== 从 3-SAT 到 SUBSET-SUM：把逻辑约束写进十进制列

这部分最有意思的地方，是把布尔逻辑编码进十进制数字的每一位。

构造思路如下：

- 对每个变量 $x_i$，造两组数：一组表示选 `x_i`，另一组表示选 `¬x_i`；
- 对每个 clause，再造若干 dummy 数；
- 目标和 $W$ 的每一位都经过精心设计。

关键是让不同列承担不同语义：

- 变量列：强制每个变量恰好从 `x_i` 与 `¬x_i` 中选一个；
- 子句列：要求每个 clause 至少贡献一次“被满足”的记号；
- dummy 数只负责把子句列补足到目标值，但无法单独伪造变量一致性。

于是：

- 若公式可满足，就按真值选择对应 literal 的数，再补上合适 dummy 数，可凑出目标和；
- 若某子集恰好凑到目标和，则变量列会强制它对每个变量作出一致选择，
  而子句列又会强制每个 clause 至少选中了一个真 literal。

#remark(title: "为什么这种编码不会因为进位而乱掉")[
  构造时会控制每一列总和足够小，使不同列彼此独立，不发生意外进位。
  也正因为如此，subset-sum 归约里“每一位代表一个约束”才说得通。
]

== 从 3D-MATCHING 到 SUBSET-SUM

还可以从 3D matching 归约到 subset-sum：

`3D-MATCHING <=_p SUBSET-SUM`

思路是把每个 triple 编成一个大整数：

- 若 triple 使用了 $x_i$、$y_j$、$z_k$；
- 就在对应的三列上写 1；
- 其余列写 0；
- 再选择合适的进制，避免列之间进位干扰。

目标值则写成所有列都恰好为 1 的数。于是：

- 选出若干个数使总和等于目标值；
- 就等价于选出若干个 triple，使每个元素被恰好覆盖一次。

这条归约很有启发性，因为它告诉你：

- subset-sum 不是“只有 SAT 才能归约过去”；
- 它本身就足以承载匹配型约束、覆盖型约束以及布尔约束。

== 一张简化的“困难问题谱系图”

到这里，NP-complete 这一段已经给了你一张很有用的 hard problems 地图。

#figure(
  caption: [课程后半段常见 NP-complete 问题谱系],
  three-line-table[
    | 类别 | 代表问题 | 典型结构 |
    |:---|:---|:---|
    | 约束满足 | SAT, 3-SAT | 给变量赋值满足所有局部条件 |
    | 打包/覆盖 | Independent Set, Vertex Cover, Set Cover | 选对象并满足冲突/覆盖关系 |
    | 序列/遍历 | HAM-CYCLE, TSP, LONGEST-PATH | 形成全局顺序或回路 |
    | 划分/匹配 | 3-COLOR, 3D-MATCHING | 把元素放进互斥类别或三元组合 |
    | 数值问题 | SUBSET-SUM, KNAPSACK | 用整数编码组合约束 |
  ],
)

== 面对 NP-complete，正确的问题不再是“能不能暴力”

学到这里时，如果你是自学，我建议把 takeaway 说得更直接一点：

- 当你怀疑一个问题是 NP-complete 时，不要继续执着于找一般情形下的精确多项式算法；
- 更应该问：
  这个问题有没有特殊结构？
  能否近似？
  参数小时能否固定参数 tractable？
  现实数据上是否可以做启发式？

#tip-block(title: "复杂性理论给的是选择路线的能力")[
  学会 NP-completeness 以后，你拿到一个新问题时，
  不只会问“怎么解”，还会问“该往哪类解法里找”。
  这正是它在算法课程里的最大价值。
]
