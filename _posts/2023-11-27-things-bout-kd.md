---
title: "词典数据的压缩方式比较"
categories:
    - Blog
tags:
    - golang
---


（没写完，待探究的细节过多，待续）

最近在重构WudaoDict，从作者这里还真学到一些东西，比如词典数据的压缩方式。他的本地数据文件是这样的：

```
-rw-r--r-- 1 k k 1.7M Nov 19  2018 en.ind
-rw-r--r-- 1 k k 1.2M Nov 19  2018 zh.ind
-rw-r--r-- 1 k k  44M Nov 19  2018 en.z
-rw-r--r-- 1 k k  37M Nov 19  2018 zh.z
```

两个z文件是大约两万个词条用zlib压缩后的二进制拼接，ind则记录了将近两万个中英文词条的索引（文件偏移量），每次查词时实时根据索引去给z文件切块，然后读文件、zlib解压再decode。

粗看很不以为然，但我自己试了几种方式，却无法达到更好的压缩效果，看到release日志中特地提到压缩空间的改进，想必作者当初也费了一番功夫探究。

我最开始没有考虑过空间的问题，设想的方案是直接存JSON文件或sqlite，结果今天晚上我的IP突然被youdao给禁了，我不得不开始考虑构建本地词库。我用他的这两个z文件数据模拟了几种最粗糙的存储方式，

| 介质     | 方式                         | 大小 |
|----------|------------------------------|------|
| sqlite3  | 解码，拆分字段后存入         | 71M  |
| sqlite3  | 解码，作为单独长字符串字段   | 72M  |
| sqlite3  | 不解码，作为单独长字符串字段 | 72M  |
| 文本文件 | 解码，存入单文件             | 61M  |


| 介质    | 方式           | 大小 |
|---------|----------------|------|
| sqlite3 | 扩充字段的JSON | 204M |


## 变更压缩方式

| 序列化方式   | 版本/参数 | 方式                 | 大小 |
|--------------|-----------|----------------------|------|
| pickle       |           | dump对象->Bytes      | 120M |
| cbor         | cbor2     | dump对象->Bytes      | 120M |
| msgpack      |           | dump对象->Bytes      | 102M |
| gzip         |           | 压缩JSON->Bytes      | 63M  |
| zlib         | level 9   | 压缩JSON->Bytes      | 61M  |
| msgpack+zlib | level 9   | dump对象后压缩>Bytes | 58M  |

初步猜测是数据增加了大量的标点符号，而zlib的压缩方式

## 暂定

加入codec之后编译binary大小增加1M，且数据结构要重写一个MsgPack版本


## Reference
- https://medium.com/@u.praneel.nihar/improving-read-write-store-performance-by-changing-file-formats-serialization-protocols-bfdb13114004
- http://zderadicka.eu/comparison-of-json-like-serializations-json-vs-ubjson-vs-messagepack-vs-cbor/
- https://devforum.roblox.com/t/string-compression-zlibdeflate/755687
