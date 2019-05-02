---
title: "廉价Magicbook R5 装 Manjaro之后的一堆声卡问题"
categories:
    - Blog
tags:
    - laptop
    - linux

---



买回来第一时间装了ArchLinux，然而之前没有笔记本装Linux经验，看到Wiki上一堆Laptop优化策略后倍感恶心，日常996完全没有时间折腾，换Manjaro。

## 问题一：<del>外放完全没有声音</del>

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

## 问题二：D面喇叭没有声音

这样就比较致命了，外放声音格外空灵，完全没有Win10的豪华家庭影院效果。

## Reference:

- [Arch Linux on MateBook X Pro](https://aymanbagabas.com/2018/07/23/archlinux-on-matebook-x-pro.html)
- https://forums.freebsd.org/threads/getting-sound-to-automatically-switch-to-laptop-headphone-jack-x1-carbon-6th-gen-thinkpad-realtek-alc285.66052/
- hdajackretask:
    - https://askubuntu.com/questions/1027332/how-to-identify-correct-pin-assignment-for-hdajackretask
