---
title: "Archlinux补遗"
categories:
    - Blog
tags:
    - archlinux
---

几年前写过完整流程的[Archlinux安装脚本](https://github.com/Karmenzind/arch-installation-scripts)，一键执行十分钟内搞定所有工作。然而最近自己给新工作机装系统时还是选择了看着wiki一步一步敲命令，前后居然花了两个多小时，津津有味地把几年前烂熟于心的文档都读了一遍，大概nothing is happier than following the manual。

这次发现了一些新细节，记下备用。大致按照执行时间顺序。

## Pacman

```confini
# Misc options
Color
ILoveCandy
ParallelDownloads
```

### For cache dir

Enable and start `paccache.timer`.

## Swap文件

文件确实比分区要灵活得多。


## Cronie


```crontab
@hourly ntpdate xx.x.x.x
@daily pacman -Fy
@weekly 
```

## 磁盘相关

用udiskie控制自动挂载

## 回收站

TODO


## 其他：Magicbook笔记本相关

> 2023-9 设备限制，无奈把笔记本搞了下，效果还行

- 目前只有refind作为boot loader的出错几率和被覆盖几率最小，原因不明，对华为设备充满厌恶，完全不想明白
- libinput设置中给touchpad开启`Option "NaturalScrolling" "true"`，能够模拟类似平板的滑动习惯
