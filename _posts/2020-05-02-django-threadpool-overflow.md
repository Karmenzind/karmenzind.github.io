---
title: "解决Django ORM使用ThreadPoolExecutor时数据库连接溢出的问题"
categories:
    - Blog
tags:
    - memcached
    - python
---


团队内有多个Web项目使用Django框架，在处理一些日常事务时，为了加速API返回，会用到concurrent模块的线程池ThreadPoolExecutor，将不需要立刻知晓结果的逻辑以任务的形式提交（submit）到线程池。在使用过程中遇到一个较为棘手的问题：线程池会创建新的数据库连接，而Django服务并不会主动回收它们。而一般的接口请求结束时，Django都会调用`close_old_connections`方法来结束不需要的连接。

这对于需要频繁访问数据库的业务而言，会埋下巨大的隐患：限制连接不断增长，最终耗尽可用资源，使服务宕机。本案例旨在解决线程池连接回收这一问题。

## 问题分析

这里通过简要的代码来复现这个过程：

```python3
def compute(job):
    result = FooModel.objects.filter(...).aggregate(...)
    return BarModel.objects.create(result)

def process(dataset):
    thread_pool = ThreadPoolExecutor(max_workers=20)
    futures = []

    for job in dataset:
        futures += [thread_pool.submit(compute, job)]

    results = list(r.result() for r in wait(futures)[0])
    return results

for i in range(0, 100):
    process(['foo', 'bar', 'qux'])
```

如上所示，将`process`函数循环调用一百次，每一次会创建新的线程池，并将三个任务提交到线程池中，每个人物的内容为一次聚合查询与数据插入。

上述代码在Django交互环境中运行结束后，PostgreSQL的活动表`pg_stat_activity`查询结果如下：

```
mypostgresdb=# select count(*) from pg_stat_activity;
 count 
-------
   182
(1 row)
```

而奇怪的是，此时通过Django自身并无法感知到这些连接的存在：

```
>>> from django.db import connections
>>> print(len(connections.all()))
>>> 2
```

同时通过线程模块可以看到，所有的worker线程都已经关闭：

```
>>> import threading
>>> threading.enumerate()
[<_MainThread(MainThread, started 140660203321088)>]
```

从上述结果可以分析得出，ThreadPoolExecutor自身并不会创建/管理数据库连接，真正去维护这些连接的是线程任务。所以要从根本上解决这个问题，就需要在每个线程中去完成连接回收这个过程。

## 解决方案

基于上述的分析结果，我对ThreadPoolExecutor进行了封装，在每次执行任务时，确保连接被关闭。具体代码如下：

```python3
from functools import wraps
from concurrent.futures import ThreadPoolExecutor
from django.db import connection

class DjangoConnectionThreadPoolExecutor(ThreadPoolExecutor):
    def close_django_db_connection(self):
        connection.close()

    def generate_thread_closing_wrapper(self, fn):
        wraps(fn)
        def new_func(*args, **kwargs):
            try:
                res = fn(*args, **kwargs)
            except:
                self.close_django_db_connection()
                raise e
            else:
                self.close_django_db_connection()
                return res
        return new_func

    def submit(*args, **kwargs):
        if len(args) >= 2:
            self, fn, *args = args
            fn = self.generate_thread_closing_wrapper(fn=fn)
        elif not args:
            raise TypeError("descriptor 'submit' of 'ThreadPoolExecutor' object "
                        "needs an argument")
        elif 'fn' in kwargs:
            fn = self.generate_thread_closing_wrapper(fn=kwargs.pop('fn'))
            self, *args = args

        return super(self.__class__, self).submit(fn, *args, **kwargs)
```

如上所示，当函数通过submit或者map被提交到线程池中后，借助封装逻辑，确保任务完成时在线程内调用close_django_db_connection，以此来控制Django数据库连接溢出。因为map方法内部调用的也是submit，所以此处只需要覆盖submit方法即可。其中，submit方法的参数过滤、解构逻辑，模仿了[thread模块的实现方法](https://github.com/python/cpython/blob/3.7/Lib/concurrent/futures/thread.py)。

有了这样一层封装之后，针对之前用到线程池的代码，修改一下线程池初始化过程就可以无缝切换，如下所示：

```python3
with DjangoConnectionThreadPoolExecutor(max_workers=15) as executor:
    results = list(executor.map(func, args_list))
```

其余所有代码都不需要修改，同时也能够保证所有垃圾线程得以回收。

## 总结

在使用以上方案之后，之前线程溢出的问题得到了完美解决，而且因为采用了封装的方式，保证了原有代码的最小程度修改。

在使用非框架内置的功能时，一定要明确诸如线程、数据库连接回收等方面的副作用，避免引起不可控后果。同时要了解一些必要的框架细节，这样在做一些必要的封装时，能够有据可循。
