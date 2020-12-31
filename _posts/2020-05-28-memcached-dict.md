---
title: "使用Python在Memcached实现模拟MutableMapping存储"
categories:
    - Blog
tags:
    - memcached
    - python
---


Memcached 是一种易于使用的高性能内存数据存储。它提供了一项成熟的可扩展开源解决方案，能够实现亚毫秒级响应时间并用作缓存或会话存储。Memcached 非常热门，可为 Web、移动应用程序、游戏、广告技术和电子商务领域的实时应用程序提供支持。

但是Memcached仅仅支持键/值对的存储，针对一些比较复杂的格式需要进行额外的处理，例如：存储Python字典，需要先转化为JSON字符串；存储Python对象，需要借助Pickle进行序列化。这样就会产生一些问题，例如体积较大的字典，序列/反序列化过程较为费时，而且通常只需要存取其中一个键，造成不必要的性能和网络浪费。

本文提出一种方法，借助鸭子类型思想，将Python映射（Mapping）拆开，分别将键值对的单独存储在Memcached中，但同时提供通用的Mapping接口进行访问、管理，以此来模拟一部分字典功能。

## 鸭子类型介绍

所谓的鸭子类型是指：一个对象有效的语义，不是由继承自特定的类或实现特定的接口，而是由"当前方法和属性的集合"决定。

这个概念的名字来源于由James Whitcomb Riley提出的鸭子测试，“鸭子测试”可以这样表述：当看到一只鸟走起来像鸭子、游泳起来像鸭子、叫起来也像鸭子，那么这只鸟就可以被称为鸭子。

在鸭子类型中，关注的不是对象的类型本身，而是它是如何使用的。在不使用鸭子类型的语言中，我们可以编写一个函数，它接受一个类型为"鸭子"的对象，并调用它的"走"和"叫"方法。
在使用鸭子类型的语言中，这样的一个函数可以接受一个任意类型的对象，并调用它的"走"和"叫"方法。(如果这些需要被调用的方法不存在，那么将引发一个运行时错误。任何拥有这样的正确的"走"和"叫"方法的对象都可被函数接受的这种行为引出了以上表述，这种决定类型的方式因此得名。)
注意：鸭子类型通常得益于"不"测试方法和函数中参数的类型，而是依赖文档、清晰的代码和测试来确保正确使用。

在Python中，鸭子类型在Python中被广泛使用。最典型例子就是类似file的类。这些类可以实现file的一些或全部方法，并可以用于file通常使用的地方。

例如:
- GzipFile实现了一个用于访问gzip压缩的数据的类似file的对象。
- cStringIO允许把一个Python字符串视作一个文件。
- 套接字（socket）也和文件共同拥有许多相同的方法。

而本案例中，正是要实现这样一种鸭子类型。

## 程序概念介绍

### MutableMapping

MutableMapping意思是可变映射，是一种Python抽象容器类型。基础类型dict即是MutableMapping的一种实现。

根据[Python 3官方模块abc的文档介绍](https://docs.python.org/3/library/collections.abc.html#collections-abstract-base-classes)，要实现一个MutableMapping（可变映射），需要多种抽象方法和Mixin方法，此处选取与dict（字典）特性关联密切的几种进行介绍：

- `__contains__` 用于判断是否包含属性，如：`'xxx' in mapping`
- `__getitem__` 用于获取属性，如：`mapping['xxx']`
- `.get` 调用`__getitem__`
- `__setitem__` 用于给属性赋值，如：`mapping['xxx'] = 'yyy'`
- `__delitem__` 用于删除属性，如：`del mapping['xxx']`
- `.pop` 调用`__delitem__`，提供不存在时的默认值，无默认值则报错

### Memcached Client

本案例应用在Django项目中，所以直接使用了内置的cache缓存框架（需要安装pylibmc，[具体见文档](https://docs.djangoproject.com/en/2.2/topics/cache/#memcached)）。存取数据的API较为简单，如下：

```python
>>> from django.core.cache import cache
>>> key = 'xxx'
>>> # 判断key在cache中
>>> key in cache
False
>>> # 存入key的值为1，设置60秒超时
>>> cache.set(key, 1, 60)
>>> # 读取key
>>> cache.get(key)
1
>>> # 从cache中删除key
>>> cache.delete(key)
```

## 具体实现方法

```python
from django.core.cache import cache


class MapCacheProxy:
    """
    伪装成Map，实现一些Dict的基础方法
    实际上每个key都是独立存储
    """

    def __init__(self, name):
        """
        :name: 此处的name用于生成在缓存系统中的键
        """
        self._pref = "_localmap_" + name

    def mk(self, key):
        """用于生成缓存键"""
        return self._pref+str(key)

    def get(self, key):
        return self.__getitem__(key)

    def __getitem__(self, key):
        return cache.get(self.mk(key))

    def __setitem__(self, key, value):
        cache.set(self.mk(key), value)

    def __contains__(self, key):
        return self.mk(key) in cache

    def pop(self, key, default):
        k = self.mk(key)
        if k in cache:
            v = cache.get(k)
            cache.delete(k)
            return v
        return default
```

上面的代码即Mapping的存储实现。在实际使用时，只需要初始化一个实例，就可以像使用dict的部分功能一样来使用这个代理类。如下：

```python

# 普通的mapping
a = MapCacheProxy('ckeysmapbyid')

# 嵌套在字典中
b = {
    "name": MapCacheProxy("catemapbyname"),
    "id": MapCacheProxy("catemapbyid"),
}

# 可以进行的操作如下：
a['xxx'] = 1
a.get('xxx')
del a['xxx']
a.pop('xxx')
```

此时，执行`a['xxx'] = 1`或`b['name']['xxx'] = 1`，实际上已经将值存储在了memcached中，而`a.get('xxx')或a['xxx']`，即从memcached中获取这个值。同时，cache系统有内置的超时时间，这样就可以比较好的利用缓存的优势。

现在这个方法还存在如下缺点，但由于当前需求较为简单，暂没有进一步研究：

1. 没有实现迭代器需要的功能（`__iter__`，`__len__`等）和一些建立在能知晓容器内部所有键基础上的方法（`__clear__`、`__popitem__`等），尝试解决无果。目前设想的方案是：通过另一个键来存储数组，记录Mapping中所有的键，但这样会增加设计和实现的复杂度。
2. 初始化方法`__init__`与dict不一样，不支持直接传值的方式，这个实现较为简单
3. 没有提供其他的dict功能方法，如`update`、`setdefault`等，这些实现也较为简单

## 总结

本案例提供了使用Python在Memcached实现模拟MutableMapping存储的思路，能够同时利用Mapping数据类型的优势和Memcached的缓存优势。同时还有一些问题尚未解决，期待在以后的工作中能进一步研究。
