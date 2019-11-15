---
title: "Python+Memcached实现伪mapping存储"
categories:
    - Blog
tags:
    - python
---


```python3
class MapCacheProxy:
    """
    伪装成Map，实现一些Dict的基础方法
    实际上每个key都是独立存储
    """

    def __init__(self, name):
        self._pref = "_localmap_" + name

    def mk(self, key):
        """make key"""
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

Now the question is, how to implement a `.clear()` method?

