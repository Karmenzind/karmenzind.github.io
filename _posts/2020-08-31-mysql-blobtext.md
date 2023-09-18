---
title: "MySQL中BLOB/TEXT字段索引的错误使用"
categories:
    - Blog
tags:
    - database
    - mysql
---


因为历史原因，某服务的一张业务数据表的主键类型设置为了`VARCHAR(255)`，最近遇到一些特殊情况，这个长度需要扩增。尝试变更字段类型为`TEXT`时，遇到了如下报错：

```
> ALTER TABLE message MODIFY COLUMN message_id TEXT;
You're about to run a destructive command.
Do you want to proceed? (y/n): y
Your call!
(1170, "BLOB/TEXT column 'message_id' used in key specification without a key length")
```


当对BLOB或TEXT类型的字段建立索引时，引擎实际上只能选择前N个字符建立索引，而VARCHAR类型的字段则没有这一限制。这一限制同样也存在于BLOB/TEXT的子类字段，例如TINYBLOB、MEDIUMBLOB、LONGBLOB、TINYTEXT、MEDIUMTEXT以及LONGTEXT等。所以当尝试将`message_id`字段直接转化为TEXT字段的时候，实际上就是在没有指定前N这一长度的情况下，直接针对全字段直接建立索引。在这种情况下，由于该字段是动态变化的，MySQL并不能保证它的唯一性（uniqueness）。所以如果要使用BLOB/TEXT类型作为索引，就必须指定N值，MySQL据此确定键的长度。

在转化之前，VARCHAR类型字段上已经定义了唯一性约束（unique constraint）和主键约束，所以直接执行ALTER INDEX语句转化就会失败。

解决这一问题最简单的方法是继续使用VARCHAR字段，于是我尝试直接扩展`message_id`这一字段的长度，即`VARCHAR(512)`，但没想到再次触礁，又出现了上述的1170错误。

这令人很困惑，因为该报错显然是BLOB/TEXT字段特有的。在对VARCHAR类型字段进行进一步了解后找到了原因：VARCHAR类型字段默认只能存储256个字符，默认最大限制为255，当定义为512的时候，引擎会强制将该字段转化为SMALLTEXT类型，于是再次导致了1170错误。

上述尝试证实了继续使用VARCHAR是不可取的，于是最终采取的解决措施如下，即创建一个新表（语句省略了其他字段），然后为`message_id`加上UNIQUE KEY：

```sql
CREATE TABLE new_message (
    message_id TEXT,
    UNIQUE KEY idx_message_id (message_id (255))
);
```

`message_id`无法再作为主键，如果尝试运行如下语句，依然会遇到1170错误：

```sql
CREATE TABLE new_message (
    message_id TEXT PRIMARY KEY,
    UNIQUE KEY idx_message_id (message_id (255))
);
```

如果希望将message_id继续作为主键，可行的解决方法是，计算该字段的`SHA1`或`MD5`值，然后创建固定字段的VARCHAR类型字段作为主键。

虽然通过修改字段类型解决了当下的问题，但创建一个长度255的索引必定会带来不小的数据库开销，而这一开销将在数据量增大时越发明显。这一点让我意识到，优秀的前期设计非常重要，如果当初为了一时方便草率处理数据库字段设计，就会带来许多意想不到的尴尬问题。
