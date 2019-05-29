---
title: "Pytest文档阅读笔记"
categories:
    - Blog
tags:
    - python
    - unittest
    - django
---

Pytest文档地址：<https://docs.pytest.org/en/latest/contents.html>

## 兼容性

refer: 

[Using pytest with an existing test suite]: https://docs.pytest.org/en/latest/existingtestsuite.html#using-pytest-with-an-existing-test-suite

## Fixture

```python
@pytest.fixture(...)
def sql_cli():
    ... # 省略
    return SQLClient(...)
```


### Teardown

A better way:

```python
@pytest.fixture(scope=...)
def sql_cli():
    ... # 省略
    c = SQLClient(...)
    yield c
    # 出scope时执行
    c.close() 

# or more pythonic

@pytest.fixture(scope=...)
def sql_cli():
    with SQLClient(...) as c:
    	yield c
```

> e.g. 通过任何方式直接调用接口的方式都不推荐，可能造成脏数据无法清理，使用内置Client更好

### Scope

fixture的作用范围（function, class, module or session），基于fixture的产生成本来设置。

scope等级更高（session>module）的fixture会被更早初始化。（[doc](<https://docs.pytest.org/en/latest/fixture.html#higher-scoped-fixtures-are-instantiated-first>)）

> pytest会自动优化初始化过程，初始化和释放顺序见：[Automatic grouping of tests by fixture instances](<https://docs.pytest.org/en/latest/fixture.html#automatic-grouping-of-tests-by-fixture-instances>)

### 参数化

```python
@pytest.fixture(scope=..., params=[1, 2])
def foo(request):
    return request.param
```

所有基于这个fixture的测试函数都会运行两次。

还可以用mark结合参数化fixture：[marks with parametrized fixtures](<https://docs.pytest.org/en/latest/fixture.html#using-marks-with-parametrized-fixtures>)

### 一些内置Fixture

**request**
request-context请求上下文([doc](https://docs.pytest.org/en/latest/fixture.html#request-context))，可以用来introspect详细的上下文信息，比如`params,scope,fixturename`。

### 存疑

[Using fixtures from classes, modules or projects](<https://docs.pytest.org/en/latest/fixture.html#using-fixtures-from-classes-modules-or-projects>)

