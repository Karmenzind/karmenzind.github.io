---
title: "IdentityServer Notes"
categories:
    - Blog
tags:
    - auth
    - .net
---


它本质是个中间件

## Concepts

- Authorization
- Authentication

## JWT

`<header>.<payload>.<signature>`组成的base64编码，前两个解析之后是用户和算法信息，sig是加密字符串

签名算法：HS256/RS256/RS256，分别为HMAC、RSA、ECDSA + SHA-256，其中HS256是对称密钥，另外两个是非对称

OIDC中的Access Token一般都是JWT

Kubernetes的Bearer Token也是（并不必须）是JWT，我之前为了监控K8S集群帮客户折腾了那么久Token，几乎把他们所有的安全条例都破了一遍，居然没去了解过这玩意儿本身。

## Authentication

- SAML2p (most widely used and deployed)
- WS-Federation
- OpenID Connect (the future)

## OIDC相关

OpenID Connect在OAuth2.0基础上引入部分额外特性，主要区别含：

- ID Token
- Userinfo 可以理解为在标准OAuth2.0认证通过之后调用的一个info接口
- 标准化认证流程，OAuth2.0没有定义认证标准
- 默认HTTPS

前公司某H开头的系统用的就是OIDC，当时为了简化任务流程还写过一个作弊脚本每天抓他们的Token。



## 





## Reference


- RFC6749 OAuth2.0 https://datatracker.ietf.org/doc/html/rfc6749
- https://www.youtube.com/watch?v=02Yh3sxzAYI
- ruanyifeng的oauth讲解
  - https://www.ruanyifeng.com/blog/2014/05/oauth_2_0.html 
  - 后来的版本更易读一些 https://www.ruanyifeng.com/blog/2019/04/oauth-grant-types.html
- https://zhuanlan.zhihu.com/p/105644659
