#import "@local/notes:0.1.0": *

#let Pr = math.op("Pr")
#let Var = math.op("Var")

= 第二十章 Fingerprinting、Chernoff Bounds 与随机负载均衡

#tip-block(title: "这一章的主线")[
  前面随机算法多用期望分析。本章往前走一步：fingerprinting 用很少通信换取小概率错误，Chernoff bounds 则说明独立随机变量之和不仅“期望好”，而且大概率不会偏离太远。
]

== String Equality 与 Fingerprinting

设 Alice 和 Bob 各自有一个数据库副本。直接传输整个数据库可以检查是否一致，但如果数据库很大，通信代价就是主要瓶颈。
把数据库看成字符串后，问题变成：两个人想判断两个字符串是否相等，但不想传完整字符串。

Fingerprinting 的想法是：每个人本地计算一个很小的摘要值。

- 如果摘要不同，则原字符串一定不同；
- 如果摘要相同，则原字符串很可能相同，但允许有很小概率出错；
- 只传摘要可以把通信从字符串长度降到对数级别。

这是一类 Monte Carlo 思想：运行和通信很便宜，但有单侧错误。

== 模素数 fingerprint

令 Alice 和 Bob 的字符串分别是 bit sequence：

`(a_1, ..., a_n)` 和 `(b_1, ..., b_n)`。

把它们看成 $n$ bit 整数：

$ a = sum_(i=1)^n a_i 2^(i-1), quad b = sum_(i=1)^n b_i 2^(i-1). $

随机选择一个素数 $p$，定义 fingerprint：

$ F(a) = a mod p. $

Alice 把 $F(a)$ 传给 Bob，Bob 计算自己的 $F(b)=b mod p$ 并比较。
因为 $F(a)<p$，传输 fingerprint 只需要 $O(log p)$ bits。

#definition[
  在这里，“positive” 表示检测到 $a != b$。如果 $F(a) != F(b)$，则必然有 $a != b$，所以没有 false positive。可能出错的是 false negative：$a != b$，但 $F(a)=F(b)$。
]

为什么 false negative 会发生？若

$ F(a)=F(b), $

则

$ a mod p = b mod p, $

也就是 $p$ 整除 $a-b$。因此当 $a != b$ 时，算法出错的条件是随机选到的素数 $p$ 恰好是 $a-b$ 的一个素因子。

== 错误概率分析

用到两个数论事实。

#lemma[
  任意正整数 $t$ 的不同素因子个数至多为 $log_2 t$。
]

证明很直接：每个素因子至少为 2。如果有超过 $log_2 t$ 个不同素因子，它们的乘积就会超过 $t$，矛盾。

在 fingerprinting 中，$a$ 和 $b$ 都是 $n$ bit 整数，因此

$ |a-b| < 2^n. $

所以 $a-b$ 的不同素因子数少于 $n$。

再用 prime number theorem：小于 $t$ 的素数个数约为 $t / ln t$。令

$ t = n^2 ln n. $

则小于 $t$ 的素数个数大约是

$ t / ln t = (n^2 ln n) / (2 ln n + ln ln n) = Theta(n^2). $

从这些素数中随机选 $p$。若 $a != b$，会导致 false negative 的坏素数少于 $n$ 个，而候选素数有 $Theta(n^2)$ 个，所以

$ Pr["false negative"] <= O(1/n). $

另一方面，

$ log p <= log t = O(log n). $

因此只传 $O(log n)$ bits，就能把错误概率压到 $O(1/n)$。如果要求完全无错，在最坏情况下仍需要传整个数据库，也就是 $O(n)$ bits。

== 如何随机生成素数

Prime number theorem 还说明随机找素数是可行的。小于 $t$ 的随机数是素数的概率约为 $1 / ln t$，所以期望尝试 $O(ln t)$ 次能遇到一个素数。

实际判断素数时可以使用 Miller--Rabin primality test：

- 若数字是素数，它总能通过测试；
- 若数字是合数，它有小概率被误判为素数；
- 独立重复测试可以把误判概率指数级降低。

这里有两层随机性：随机选候选数，以及 primality test 本身的随机性。分析 fingerprinting 时通常假设最终得到的是随机素数。

== 从期望到 tail bound

期望只能说明“平均会怎样”，不能直接说明一次运行偏离期望的概率。

例如抛 100 次公平硬币，期望正面数是 50。我们还想问：

- 至少 60 个正面的概率是多少？
- 至少 80 个正面的概率是多少？
- 全部 100 个正面的概率是多少？

这类问题需要 tail bound。

== Markov 与 Chebyshev

#theorem(title: "Markov inequality")[
  若 $X$ 是非负随机变量，则对任意 $a>0$，

  $ Pr[X >= a] <= E[X] / a. $
]

Markov inequality 很通用，但通常较弱。例如 $X$ 是 100 次抛硬币的正面数，$E[X]=50$，则

$ Pr[X >= 60] <= 50/60 = 5/6. $

这个界显然不紧。

#theorem(title: "Chebyshev inequality")[
  对任意随机变量 $X$ 和任意 $a>0$，

  $ Pr[abs(X-E[X]) >= a] <= Var[X] / a^2. $
]

Chebyshev 可以由 Markov 应用于 $(X-E[X])^2$ 得到。
对 100 次公平抛硬币，$Var[X]=100/4=25$，因此

$ Pr[abs(X-50) >= 10] <= 25/100 = 1/4. $

因为分布关于 50 对称，可得 $Pr[X >= 60] <= 1/8$，比 Markov 强很多。

== Chernoff Bounds

Chernoff bounds 处理的是独立随机变量之和。设 $X_1, ..., X_n$ 独立，通常取值在 `{0,1}`，令

$ X = sum_i X_i, quad mu = E[X] = sum_i E[X_i]. $

那么 $X$ 偏离 $mu$ 的概率会随 $mu$ 和偏离比例指数下降。

#theorem(title: "Chernoff bounds 的常用形式")[
  对 $0 <= delta <= 1$，

  $ Pr[X >= (1+delta)mu] <= e^(-mu delta^2 / 3), $

  $ Pr[X <= (1-delta)mu] <= e^(-mu delta^2 / 2). $

  对 $delta > 1$，

  $ Pr[X >= (1+delta)mu] <= e^(-mu delta ln delta / 3). $
]

更精细的上尾形式是：

$ Pr[X >= (1+delta)mu] <= (e^delta / (1+delta)^(1+delta))^mu. $

当变量取值为 `{-1,1}` 且均匀独立时，若 $X=sum_i X_i$，则

$ Pr[X >= delta] = Pr[X <= -delta] <= e^(-delta^2/(2n)). $

直觉上，独立阶段越多，总和越接近期望；偏离比例固定时，失败概率是指数小的。

== Chernoff 在随机算法中的作用

很多随机算法的分析结构都是：

1. 算法分成许多独立或近似独立的阶段；
2. 每个阶段的期望成本容易算；
3. 总成本是这些阶段的和；
4. 用 Chernoff 说明总成本大概率不会比期望大太多。

和只给期望复杂度相比，Chernoff 给的是 high probability guarantee。

== Randomized Load Balancing

设有 $n$ 台机器，在线到达 $m$ 个等大小 jobs。目标是让每台机器分到的 job 数尽量接近，从而让所有 job 尽快完成。

Round-robin 可以做到均衡，但需要中心控制器，可能成为瓶颈。随机负载均衡的算法非常简单：

#definition[
  每个新 job 到来时，独立均匀随机选择一台机器，把 job 分配给它。
]

对固定机器 $i$，令 $X_i$ 表示它得到的 job 数。再令 $Y_(i,j)$ 是 indicator random variable：
如果第 $j$ 个 job 被分配给机器 $i$，则 $Y_(i,j)=1$；否则 $Y_(i,j)=0$。

则

$ X_i = sum_(j=1)^m Y_(i,j), quad E[Y_(i,j)] = 1/n, quad E[X_i] = m/n. $

因为不同 jobs 独立选择机器，$X_i$ 是独立 indicator 之和，可以使用 Chernoff bound。

例如对固定机器 $i$，

$ Pr[X_i >= (1+delta)m/n] <= e^(-(m/n) delta^2 / 3) quad (0<=delta<=1). $

若要控制所有机器的最大负载 $X=max_i X_i$，再使用 union bound：

$ Pr[exists i, X_i >= (1+delta)m/n] <= n e^(-(m/n) delta^2 / 3). $

这说明只要平均负载 $m/n$ 足够大，所有机器的负载都会以高概率集中在平均值附近。

== 本章小结

#figure(
  caption: [从 fingerprinting 到 Chernoff 的随机化工具链],
  three-line-table[
    | 工具 | 目标 | 保证 |
    |:---|:---|:---|
    | Fingerprinting | 用小通信检查字符串相等 | $O(log n)$ 通信，$O(1/n)$ 错误概率 |
    | Markov | 任意非负随机变量的上尾界 | 通用但弱 |
    | Chebyshev | 用方差控制偏离 | 比 Markov 强，需要方差信息 |
    | Chernoff | 独立随机变量和的集中性 | 指数级 tail bound |
    | Union bound | 从单个对象扩展到所有对象 | 概率求和即可 |
  ],
)

#tip-block(title: "考试和作业里怎么用")[
  看到“独立随机选择很多次，然后问总数是否偏离期望”，优先想到 Chernoff。
  看到“要让所有机器、所有点、所有阶段都同时好”，通常先对固定对象做 Chernoff，再用 union bound。
]
