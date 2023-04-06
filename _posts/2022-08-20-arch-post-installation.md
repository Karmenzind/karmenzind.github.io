---
title: "2022年8月的Archlinux安装"
categories:
    - Blog
tags:
    - archlinux
---

我几年前就写过完整流程的Archlinux安装脚本，一键执行十分钟内搞定所有工作。然而最近自己给新工作机装系统时还是选择了看着wiki一步一步敲命令，前后居然花了两个多小时，津津有味地把几年前烂熟于心的文档都读了一遍，大概nothing is happier than following the manual。

这次发现了一些新细节，记下备用。

大致按照执行时间顺序。

## Pacman

```confini
# Misc options
Color
ILoveCandy
ParallelDownloads
```

## Swap文件

文件确实比分区要灵活得多。

### For cache dir

Enable and start `paccache.timer`.

## Cronie


```crontab
@hourly ntpdate xx.x.x.x
@daily pacman -Fy
@weekly 
```

