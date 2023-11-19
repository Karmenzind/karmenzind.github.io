---
title: "Archlinux补遗"
categories:
    - Blog
tags:
    - archlinux
---

几年前写过完整流程的[Archlinux安装脚本](https://github.com/Karmenzind/arch-installation-scripts)，一键执行十分钟内搞定所有工作。然而最近自己给新工作机装系统时还是选择了看着wiki一步一步敲命令，前后居然花了两个多小时，津津有味地把几年前烂熟于心的文档都读了一遍，大概nothing is happier than following the manual。

这次发现了一些新细节，主要还是属于General Recommondations的范围，记下备用，基本都是比较之后选择的最佳实践。

大致按照执行时间顺序。

## Pacman

```confini
# Misc options
Color
CheckSpace
ILoveCandy  # 居然还有这种东西
VerbosePkgLists
ParallelDownloads = 20
```

今年两度将SigLevel改成了Trustall，不知道是不是国内的网络问题，总是在签名的更新过程中出现各种各样令人困惑的问题，偷懒屏蔽SigLevel几次后，如今已经彻底不介意安全问题

> archlinuxcn源大概可以抛弃了

### mirrorlist

use reflector (ships with service)

```confini
# /etc/xdg/reflector/reflector.conf
--save /etc/pacman.d/mirrorlist
--country France,Germany
--protocol https
--latest 5
```

### For cache dir

Enable and start `paccache.timer`.

## Swap文件

文件确实比分区要灵活得多。


## Cronie

```crontab
# 双启动总会造成时间偏移，尽管我极少打开Windows
@daily ntpdate ntp.ntsc.ac.cn
@reboot ntpdate xx.x.x.x
@hourly ntpdate xx.x.x.x
# -Fy是archwiki不推荐的事情，但我看不出有什么坏处
@daily pacman -Fy
@hourly find /var/log/Xorg.*.log.* -mtime +7 -exec rm -fv {} \;
@daily find /var/log/journal/*/*.journal -mtime +15 -exec rm -fv {} \;
```

## 磁盘相关

用udiskie控制自动挂载。自动化确实方便。

## 回收站

TODO


## 其他：笔记本相关

> 2023-9 设备限制，无奈把笔记本搞了下，效果还行

- libinput设置中给touchpad开启`Option "NaturalScrolling" "true"`，能够模拟类似平板的滑动习惯
- 更改alsa设置之后莫名其妙解决了困扰多年的多音响发声问题，声卡是我永远搞不明白的东西

### Bootloader

- 目前只有refind作为boot loader的出错几率和被覆盖几率最小，原因不明，对华为设备充满厌恶，完全不想明白
- refind loader被覆盖可能原因：在refind页面选择“exit”（目前从Win正常退出未发现覆盖情况）
- 解决措施：Bootable Flash启动，进Arch Chroot环境，直接refind-install
