---
title: "错误使用物化视图造成的负优化案例"
categories:
    - Blog
tags:
    - database
    - postgresql
---


部门项目使用PostgreSQL数据库和Django Web框架，核心功能涉及设备管理，定时对每台设备进行巡检。最初设计时为了优化性能考虑，引入了物化视图（Materialized View），对聚合查询结果进行缓存，但因为使用不当反而产生了负优化。本文将对这一案例进行具体介绍。

## 问题介绍

业务对每台设备进行周期性的巡检，每次的结果存入下表：

```
postgres@10:scenedb> \d inspectionresult;
+-------------+--------------------------+----------------------------------------------------------------+
| Column      | Type                     | Modifiers                                                      |
|-------------+--------------------------+----------------------------------------------------------------|
| id          | integer                  |  not null default nextval('inspectionresult_id_seq'::regclass) |
| asset_id    | integer                  |  not null                                                      |
| ok          | boolean                  |  not null                                                      |
| detail      | jsonb                    |  not null                                                      |
| create_time | timestamp with time zone |  not null                                                      |
| frameshot   | character varying(100)   |                                                                |
+-------------+--------------------------+----------------------------------------------------------------+
Indexes:
    "inspectionresult_pkey" PRIMARY KEY, btree (id)
    "inspectionresult_asset_id_5437e88f" btree (asset_id)
```

其中，`detail`字段为JSON，保存巡检结果细节。系统中需要展示每台设备的最后一次结果，单次查询如下：

```sql
SELECT DISTINCT ON (asset_id)
    asset_id,
    ok,
    detail,
    frameshot
FROM inspectionresult
ORDER BY asset_id, id DESC;
```

上面的DISTINCT ON相当于MySQL的`ORDER BY asset_id, id GROUP BY asset_id`。考虑到频繁进行这一聚合查询浪费性能，所以基于上表做了个物化视图，对查询结果进行缓存：

```sql
CREATE MATERIALIZED VIEW IF NOT EXISTS lastinspectionresult AS
    SELECT DISTINCT ON (asset_id)
        asset_id,
        ok,
        detail,
        frameshot
    FROM inspectionresult
    ORDER BY asset_id, id DESC;
CREATE UNIQUE INDEX IF NOT EXISTS lir_asset_id
ON lastinspectionresult (asset_id);
 
```

有新的结果产生时，就通过如下REFRESH语句触发更新，为了业务考虑，此处加入了`CONCURRENTLY`参数，使更新操作与其他查询可以并行进行，而不是锁定视图。然而这也意味着：在更新视图的过程中，会耗费更多的引擎资源，而且耗时更久，这在基表的行数较大时更为明显。

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY lastinspectionresult;
```

物化视图有个不容忽视的关键特性是，无法对视图进行局部更新，只能一次性的刷新整个视图。几个月前，基表的数量已经达到了千万级别，而要巡检的设备有一千多个，几乎每秒都有新的巡检结果产生，意味着要不断进行视图更新。

在摒弃物化视图之前，生产环境上的视图刷新操作至少需要30秒才能完成，业务繁忙时甚至需要100~150秒。即使把更新频率控制在一分钟一次，通过pt_stat_activity视图能够看到，后台始终在对视图进行刷新，数据库所在容器有大约20%的CPU被占用进行这一操作，是很不必要的性能浪费，而且也不能及时的更新。每次更新的结果，最多被使用几十秒，就被下一次结果代替，这也没有充分利用到物化视图的数据缓存价值。

## 解决方案


最后的解决方案很简单：将物化视图改为实体表，以asset_id作为主键，有新结果产生的时候直接更新该条数据。如下所示：


```
+----------------------+--------------------------+------------------------------------------------------+
| Column               | Type                     | Modifiers                                            |
|----------------------+--------------------------+------------------------------------------------------|
| asset_id             | integer                  |  not null                                            |
| inspection_detail    | jsonb                    |  not null                                            |
| inspection_frameshot | character varying(128)   |  not null                                            |
| inspection_ok        | boolean                  |  not null                                            |
| inspection_time      | timestamp with time zone |                                                      |
+----------------------+--------------------------+------------------------------------------------------+
Indexes:
    "device_pkey" PRIMARY KEY, btree (id)
    "device_asset_id_6408c816" btree (asset_id)
```

因为是实体表，可以利用Django的信号（signal）系统绑定事件触发更新，使得更新逻辑更为简单明晰，且只需要寥寥数行：

```python
@receiver(post_save, sender=InspectionResult)
def signal_post_save_inspectionresult(sender, instance, **kwargs):
    updator = dict(
        inspection_ok=instance.ok,
        inspection_time=instance.create_time,
        inspection_detail=instance.detail,
    )
    if instance.frameshot:
        updator['inspection_frameshot'] = instance.frameshot
    r = Device.objects.filter(asset_id=instance.asset_id, deleted=False).update(**updator)
```

但由于基于视图的代码逻辑繁多，花了数天时间去小心地重构旧代码，反复进行测试，这进一步印证了前期错误的设计会给后期维护带来多少困扰。

## 反思

本文的使用场景已经背离了物化视图的特性。物化视图只有在较低的刷新频率（通常用于报表业务，几个小时或一天刷新一次）时才会带来较高的性能收益。而像本文的使用，则只能带来负优化。而且因为Django的内置ORM不支持PostgreSQL的物化视图，需要额外针对视图实现诸多逻辑代码，使得开发、维护工作更为复杂。

最初决定使用物化视图时，很大程度上是因为PostgreSQL不同于MySQL的新鲜特性使我充满好奇、跃跃欲试，却没有具体了解它的特性和适用场景，希望在日后的开发工作中能谨记这一教训。

