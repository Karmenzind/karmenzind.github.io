---
title: "数据库问题记录：持久化连接、PG并行查询等"
categories:
    - Blog
tags:
    - django
    - mysql
    - postgresql
---


## 持久化连接

### 应用端（Django）参数

CONN_MAX_AGE参数默认为0，针对每一条连接都会重新创建一次TCP连接，对密集访问数据库的场景增加无谓开销。

Persistent connections相关文档描述：https://docs.djangoproject.com/en/2.2/ref/databases/#persistent-connections

Connections management中：

> If your database terminates idle connections after some time, you should set CONN_MAX_AGE to a lower value, so that Django doesn’t attempt to use a connection that has been terminated by the database server. 

猜测这里是指：如果数据库端实际上已经判定连接超时并断开连接时，应用端是无法感知这一行为的，依然会在CONN_MAX_AGE范围内尝试去复用连接。此时会报错超时重连或者重新创建连接。网上有许多“MySQL 8小时问题”，说的就是这样的情况。

Caveats中：

 > If you enable persistent connections, this setup is no longer repeated every request. If you modify parameters such as the connection’s isolation level or time zone, you should either restore Django’s defaults at the end of each request, force an appropriate value at the beginning of each request, or disable persistent connections.
 
猜测这里是指持久化连接存在过程中数据库端参数被更改的情况。

### 数据库端参数

- MySQL: `wait_timeout` `interactive_timeout`
- PostgreSQL: `statement_timeout`

后续补全。

## 表级并行查询

后续补全。


其他：

- keep-alive
