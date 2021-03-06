---
title: "微服务笔记"
categories:
    - Blog
tags:
    - microservice
---

给PPT准备的草稿

内容：微服务基础概念、设计方式、集成方式

## 问题

日常软件开发中经常出现的问题：

- 功能越来越多
- 服务越来越大，代码库不断膨胀
- 模块相互依赖，密不可分
- 随处可见的重复实现

## 概念和定义分析

**协同工作**的**小**而**自治**的服务。--《微服务设计》

- 单块系统
- 单一职责原则
- 面向服务的架构（Service-Oriented Architecture）

### 关键词：小

专注于做好一件事。严守**单一职责原则**，保证**内聚性**。

> 把因相同原因而变化的东西聚合到一起，而把因不同原因而变化的东西分离开来。-- 《Single Responsibility Principle》

从时间、空间等因素衡量与决定“小”。

- ~~代码量？~~
- 依赖项
- 根据业务边界来划定服务边界
- “可以在两周内重构”
- 能够和团队结构相匹配

小，但是不要过于小。过小的微服务，会同时带来优越的独立性和泛滥的维护成本，这时候“小”就变成了“大”。

### 关键词：自治

独立的实体，可以独立部署在PAAS，也可以作为一个操作系统进程存在。

- 通过网络调用与其他服务通信

- 独立进行修改，部署不引起消费方变动

  在这个过程中要思考内部功能的暴露和隐藏，暴露越多，耦合越多

  黄金法则：能否修改一个服务、对其进行部署，而不影响其他服务？

### 关键词：协同工作

后续。

## 好处

- 技术异构性：可以在不同服务中使用最适合该服务的技术。反之，如果在场景过多的服务中尝试统一技术，会大大增加开发难度，而且无法兼顾每种场景、功能的需要。
- 弹性：降低级联故障。
- 扩展：对比单块服务，只需要扩展需要扩展的部分。
- 简化部署：只部署需要部署的部分，即使出故障，排错、回滚成本都很低。
- 匹配组织结构
- 可组合
- 可替代性

## 如何建模

### 什么是好服务？

**松耦合**

彼此之前保持极高的自主性，“藕断丝连”。

> 在组织的运行过程中各自保持一种独立自主、 低度联结的工作状态或组合方式 ,以致整个大学组织就像一个拥有各种知识群体的控股公司。

**高内聚**

相关行为聚在一起。

### 限界上下文

领域驱动设计（领域、子域、限界上下文），对现实世界的领域进行建模。“一个由显式边界限定的特定职责”。每个限界上下文（bounded context）中包含两个部分，一部分不需要与外部通信，另一部分需要。

下图展示了一个共享的隐藏模型： (TODO)


图中是某组织的财务部门与仓库，可以视为两个限界上下文。其中stock item是两个上下文之间的共享模型。stock item会对不同的上下文暴露不同的信息，同时，不同的行为（比如退货），对于不同的上下文也有不同的含义。（类比：执行任务、管理资源）

关键词：隐藏

边界内部相关性较高，得到高内聚。隐藏细节、暴露必要的部分，得到松耦合。各个上下文直接，由边界组合、接壤。

边界划分的准确性和时机很重要，犯错会造成非常大的修复成本。

## 集成

### 如何寻找合适的集成

- 集成技术？
- 破坏性修改
- 技术无关性
- 易于消费者使用
- 隐藏

### 如何集成

#### 数据库集成

(TODO)

各个服务可以直接访问数据库，可以互相修改。非常快速、简单（看起来）。

1. 内部细节对外部系统完全暴露，而且在关系上将其绑定。对所有的服务而言，数据结构都是平等的。
2. 消费者与技术选型绑定
3. 具体行为（比如：某个逻辑负责修改资源，如何置放它？所有的消费者都能直接操作数据库，都可能会有修改资源的逻辑。内聚性会被完全干掉。）（类比：接口请求）

#### 同步和异步

同步：发起远程调用，调用方会阻塞自己，等待流程结束（类比：创建虚拟机）

异步：调用方不需要等待操作，也不关心结果

两种通信模式影响着写作风格：请求/响应、基于事件。

- 请求/响应：发起请求、等待相应，或者注册一个回调。
- 基于事件：发布事件，期待（expect）其他协作者收到消息、自行处理，不告诉他们应该做什么。这种系统天生异步，不存在一个大脑来负责核心逻辑，而是职责平均分布；天生耦合性低，对于发布者而言，发出事件的一刻，任务就已经结束了，增加订阅者的时候，也不会影响发布者。

####编排与协同

编排：依赖某个大脑指挥、驱动整个流程。

协同：告知系统各部分各自的职责，把细节留给他们自己。

（问题：Post service失败了怎么办？） 

#### 远程过程调用

进行本地调用，然后结果是由某个远程服务器产生的，然后：

？？？

缺点：

1. 技术耦合，例如Java RMI和JVM
2. 与本地调用的区别：过度隐藏、网络可靠性
3. ...

#### REST

（Resource）Representational State Transfer

最重要的是资源的概念，对外显示方式、对内存储方式可能完全不同。

并没有规定具体的协议，但HTTP天然适合（动词、URI）。

### 实现基于事件的异步协作方式

#### 技术选型

考虑两个方面：事件发布机制和消费者接收事件机制

- RabbitMQ
- HTTP传播，比如ATOM。发布者向资源聚合（feed）发布服务，由消费者来轮询。

#### 服务复杂性

看起来耦合性非常低，伸缩性很好。但是复杂性也不能忽略：

- 发布订阅操作
- 消费者崩溃
- 中间件崩溃（比如：消息拥塞、出错处理重试等）（实现“消息医院”，用于集中失败的消息，来统一管理）

## 隐患

所有分布式系统都需要面对的复杂性。

部署、测试、监控。

