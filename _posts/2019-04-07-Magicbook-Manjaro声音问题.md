---
title: "Magicbook R5安装Manjaro的效果和问题"
categories:
    - Blog
tags:
    - laptop
    - linux
---



3499六期免息的Magicbook R5集显版，买回来第一时间干掉Win10换ArchLinux。

然而之前没有笔记本Linux的经验，看到ArchWiki上一堆Laptop优化策略后有点恶心，日常996完全没有时间折腾（台式机换M.2已经半年多，使用次数屈指可数，wiki上SSD tips一条都没有尝试过）。

花了一小时尝试搞定背光控制之后，换Manjaro i3。目前：

- 无驱动问题

- F键屏幕亮度、键盘光、声音可控

- 借助i3全家桶自带xfce的power management
  - 开机键控制可用
  - suspend、hibernate目测可用
  - 自带一些低电量模式目测可用

产生的问题：

- [x] 默认声卡配置错误，导致外放完全没有声音

- [ ] D面喇叭没有声音

- [ ] 低电量时自动锁屏后系统假死

- [ ] 插电时接口处发热

  

## 问题一： <del>默认声卡配置错误，导致外放完全没有声音</del>

Fixed by:

1. create a `~/.asoundrc`
2. put in these things

```
pcm.!default {
    type hw
    card Generic_1
}
ctl.!default {
    type hw
    card Generic_1
}
```

`speaker-test`终于能听到白噪音，然而：

## 问题二：D面喇叭没有声音

D面就是键盘那一面。这问题就比较致命了，外放声音格外空灵，完全没有Win10的豪华家庭影院效果，还怎么听disco。

暂时无解。

已参考：

- [Arch Linux on MateBook X Pro](https://aymanbagabas.com/2018/07/23/archlinux-on-matebook-x-pro.html)
- https://forums.freebsd.org/threads/getting-sound-to-automatically-switch-to-laptop-headphone-jack-x1-carbon-6th-gen-thinkpad-realtek-alc285.66052/
- hdajackretask:
    - https://askubuntu.com/questions/1027332/how-to-identify-correct-pin-assignment-for-hdajackretask
- 花粉俱乐部，关键词：ubuntu 声卡

## 问题三：锁屏后假死

暂时无解。