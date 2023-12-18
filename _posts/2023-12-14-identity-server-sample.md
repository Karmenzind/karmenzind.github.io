---
title: "IdentityServer Sample"
categories:
    - Blog
tags:
    - auth
    - .net
img_path: "/assets/posts/2023-12-14-identity-server-sample"
---

[IdentityServer](https://github.com/DuendeSoftware/IdentityServer)下面简称IS，当前活跃版本是v6，即将正式发布v7。

v6支持.NET 6/7，在2024年11月会终止维护（跟随.NET 6寿终正寝），v7只支持.NET 8。目前v7还是prerelease（迄今出了3个[Preview版本](https://github.com/DuendeSoftware/IdentityServer/releases/tag/7.0.0-preview.1)），但RTM版本在2024年1月就会发布，所以很快就能用上。

看了下[release notes](https://github.com/DuendeSoftware/IdentityServer/releases)还是有很多突破性的改进，可惜以我有限的框架认知并不能get到它突在何处。这里就直接从v7开始试用。

## 机制

Duende文档中实现的几个样例所采用的交互机制是标准的OAuth2.0和OpenID Connect协议流程，除了第一个Sample是OAuth2.0客户端凭证式授权较为简单，其余均是几个标准角色：客户端、IdentityServer（OIDC Provider）、远程API服务。基本流程为：

1. 应用注册
2. 用户访问
3. 重定向到服务器
4. 用户认证
5. 用户同意授权
6. 应用程序接受授权代码
7. 令牌请求
8. 令牌相应
9. 访问资源
10. 管理令牌（存储、刷新等）

具体的交互机制，[Big Picture](https://docs.duendesoftware.com/identityserver/v7/overview/big_picture/)和[Terminology](https://docs.duendesoftware.com/identityserver/v7/overview/terminology/)中的几张图其实已经足够清晰，可以结合OAuth2.0协议内容中的图一起理解。

## Samples

IS提供了大量的现成[模板](https://github.com/DuendeSoftware/IdentityServer.Templates)和样例（加上后几种的变形，大概有十个），这里先从[Quickstarts部分](https://github.com/DuendeSoftware/Samples/tree/main/IdentityServer/v7/Quickstarts)逐个尝试。基本上csproj中指定的.NET版本都是6，需要改成8。

这里测试用的系统是Archlinux，.NET和ASP.NET版本8.0.0。涉及到的IS的版本主要为7.0.0-preview.3版本。

这些Sample都是基于v6版本的IS实现，第4个Sample中因为Entity框架部分底层方法的变更，.NET 7和8都需要调整很多调用，所以Server暂时用.NET 6和运行，其他组件无影响。

## 1. 凭证式


先尝试的Client Credentials这个sample，顾名思义它是OAuth2.0中的第四种授权方式，也就是在Client这个层级上请求的通用Token，而不是与用户绑定。

它提供了一个非常基础的Identity服务，简单定义了API的作用域和Client信息。其中Client代码可看到只用了clientid/secret做认证。

```csharp
    // no interactive user, use the clientid/secret for authentication
    AllowedGrantTypes = GrantTypes.ClientCredentials,
```

### Identity Server部分

> 这个csproj中默认指定的IS版本是6.2.1，但在.NET 8.0运行并未发现异常，猜测是用到的功能过于简单，没有涉及Breaking Change中的内容。
>
>  改成7.0.0-preview3再试试。

启动服务后，测试Discovery Endpoint（OIDC的规范定义，OAuth2.0里面没这个内容）接口的调用结果：

<details><summary> 【太长了，折叠一下】 </summary>
<pre><code><font size="4">
话说这个Blog主题居然渲染不了折叠之后的内容，毛病真的很多，是时候换个新的了

```javascript
// 20231215153736
// https://localhost:5001/.well-known/openid-configuration

{
  "issuer": "https://localhost:5001",
  "jwks_uri": "https://localhost:5001/.well-known/openid-configuration/jwks",
  "authorization_endpoint": "https://localhost:5001/connect/authorize",
  "token_endpoint": "https://localhost:5001/connect/token",
  "userinfo_endpoint": "https://localhost:5001/connect/userinfo",
  "end_session_endpoint": "https://localhost:5001/connect/endsession",
  "check_session_iframe": "https://localhost:5001/connect/checksession",
  "revocation_endpoint": "https://localhost:5001/connect/revocation",
  "introspection_endpoint": "https://localhost:5001/connect/introspect",
  "device_authorization_endpoint": "https://localhost:5001/connect/deviceauthorization",
  "backchannel_authentication_endpoint": "https://localhost:5001/connect/ciba",
  "frontchannel_logout_supported": true,
  "frontchannel_logout_session_supported": true,
  "backchannel_logout_supported": true,
  "backchannel_logout_session_supported": true,
  "scopes_supported": [
    "api1",
    "offline_access"
  ],
  "claims_supported": [

  ],
  "grant_types_supported": [
    "authorization_code",
    "client_credentials",
    "refresh_token",
    "implicit",
    "urn:ietf:params:oauth:grant-type:device_code",
    "urn:openid:params:grant-type:ciba"
  ],
  "response_types_supported": [
    "code",
    "token",
    "id_token",
    "id_token token",
    "code id_token",
    "code token",
    "code id_token token"
  ],
  "response_modes_supported": [
    "form_post",
    "query",
    "fragment"
  ],
  "token_endpoint_auth_methods_supported": [
    "client_secret_basic",
    "client_secret_post"
  ],
  "id_token_signing_alg_values_supported": [
    "RS256"
  ],
  "subject_types_supported": [
    "public"
  ],
  "code_challenge_methods_supported": [
    "plain",
    "S256"
  ],
  "request_parameter_supported": true,
  "request_object_signing_alg_values_supported": [
    "RS256",
    "RS384",
    "RS512",
    "PS256",
    "PS384",
    "PS512",
    "ES256",
    "ES384",
    "ES512",
    "HS256",
    "HS384",
    "HS512"
  ],
  "authorization_response_iss_parameter_supported": true,
  "backchannel_token_delivery_modes_supported": [
    "poll"
  ],
  "backchannel_user_code_parameter_supported": true
}
```
</font></code></pre></details>

这里是相对完整的IODC Provider配置，供Client使用。看了下包含令牌、认证、用户信息端点位置和算法，还有Scope信息，基本就是这个流程涉及到的所有概念和成分都在这里。

> 此处有个关于key management的tip，暂不理解用途，先记录：On first startup, IdentityServer will use its automatic key management feature to create a signing key and store it in the src/IdentityServer/keys directory. To avoid accidentally disclosing cryptographic secrets, the entire keys directory should be excluded from source control. It will be recreated if it is not present.


### API Project

接下来就是接口服务，也就是提供resources的部分，是IdentityServer要secure的对象。Sample能找到一个用ASP.NET Core写的简单的API服务。
里面只定义了一个接口

```csharp
[Route("identity")]
[Authorize]
public class IdentityController : ControllerBase
{
    [HttpGet]
    public IActionResult Get()
    {
        return new JsonResult(from c in User.Claims select new { c.Type, c.Value });
    }
}
```

> C#这种通过给class加Attribute来定义接口和鉴权的方式，还挺像Python的装饰器

然后主程序中直接用ASP.NET Core框架提供的现成包（Microsoft.AspNetCore.Authentication.JwtBearer）来接入上面的服务。不得不说这语言真是跟JAVA一样啰嗦。

```csharp
builder.Services.AddAuthentication("Bearer")
    .AddJwtBearer(options =>
    {
        options.Authority = "https://localhost:5001";
        options.TokenValidationParameters.ValidateAudience = false;
    });
builder.Services.AddAuthorization(options =>
    options.AddPolicy("ApiScope", policy =>
    {
        policy.RequireAuthenticatedUser();
        policy.RequireClaim("scope", "api1");
    })
);
```

这里用的是C#典型的Dependency Injection（DI）模式。说到DI，微软的文档讲得很绕，ChatGPT两段话给讲明白了。

> 这里出现了关于Audience Validation的详细讨论，不解，暂记录 https://docs.duendesoftware.com/identityserver/v7/apis/aspnetcore/jwt/#adding-audience-validation

启动后直接访问上面的`identity`接口是401，意味着此时没有凭证。那么接下来就是作为桥梁功能的Client。

### Client

这里用到[IdentityModel](https://github.com/IdentityModel/IdentityModel)，其实就是将原本可以用HTTP完成的token请求过程和相关的协议交互封装做成的库。

这个库会自动根据Discovery Endpoint进行自发现和进一步的交互，只需要配置IS服务访问，也就是上面的5001端口服务。

Sample中提供的Client项目的OutputType是Exe，差不多是个脚本，里面大致进行了三步：

1. 获取discovery endpoint
2. 请求Token
3. 拿Token去请求API中的/identity接口

然后运行报错了：

```bash
Error connecting to https://localhost:5001/.well-known/openid-configuration. The SSL connection could not be established, see inner exception..
```

是发生在第一步的接口请求：

```csharp
// discover endpoints from metadata
var client = new HttpClient();
var disco = await client.GetDiscoveryDocumentAsync("https://localhost:5001");
if (disco.IsError)
{
    Console.WriteLine(disco.Error);
    return;
}
```

检查disco.Exception.InnerException.Message内容是：

```
The remote certificate is invalid because of errors in the certificate chain: UntrustedRoot
```

似曾相识，本地SSL证书问题，搜了下[dotnet的解决方式](https://stackoverflow.com/questions/52939211/the-ssl-connection-could-not-be-established)是，通过`dotnet dev-certs`来生成和信任证书。

但Linux并不支持自动信任.NET的开发证书：

```
Trusting the HTTPS development certificate was requested. Trusting the certificate on Linux distributions automatically is not supported. For instructions on how to manually trust the certificate on your Linux distribution, go to https://aka.ms/dev-certs-trust
```

[微软文档](https://aka.ms/dev-certs-trust)提供的解决方案并不适用于Archlinux，把证书放进Arch特有的anchors路径下再更新trust并没有什么用，即使这个方式对之前其他的证书问题是有效果的。

看上去似乎是两个命令能解决的问题，然后这个问题卡在这里差不多五个小时，尝试了Arch Forum上几个古老的帖子、Stack和Reddit上诸多答案，最终只有[这个看上去不太靠谱的Repo](https://github.com/BorisWilhelms/create-dotnet-devcert)生效了，可能因为它比别人多了几个nss库的处理。我真的要吐了。我已经忘记我原本是要干什么了。

哦我原本在运行这个Client，现在它三个步骤成功了，请求得到的Token：

```json
{"access_token":"eyJhbGciOiJSUzI1NiIsImtpZCI6IjkxRkQzOTQ3MzdDNEI0MTBCMzg5NDY5MEI4OTY2Qzk3IiwidHlwIjoiYXQrand0In0.eyJpc3MiOiJodHRwczovL2xvY2FsaG9zdDo1MDAxIiwibmJmIjoxNzAyODI4NzI1LCJpYXQiOjE3MDI4Mjg3MjUsImV4cCI6MTcwMjgzMjMyNSwic2NvcGUiOlsiYXBpMSJdLCJjbGllbnRfaWQiOiJjbGllbnQiLCJqdGkiOiJDQzUxODRFMTc5MEQ1MzgwMzQzODJEODk0MDc1ODc2NiJ9.js9Uu4hXiwArp-8g_00qKRABeQgg3IpRdfSBQcDswv2VbSfvbLpV2b8cWAH0qnNxqfmnBZZTtYItoVI1XxTX7DXIlzbJL6s3-YXujSc75xVAxwdXabJFKsTfdA5QByQ895b9ZiOsRU89LGUlQakbRto-Uv8ylByeZJb5bvfUnLnRyfIqchFgn7gzroiQAV5Aqt2phIu9LZo3i-JI63QYeJjzeGxuOs4ppLciACbgiJRroHXYW494oXK3t04t0Ptg5QXiCAY5yVi7szf9BYJGVsnWaCaZmMILgPXQqFPH3XGlXsUAZp5iiaDTPNXczLJug17z0ldkclLjq410aA9aWw","expires_in":3600,"token_type":"Bearer","scope":"api1"}
```

根据文档建议，拿这个Token去jwt.ms尝试Decode一下（当然也可以直接自己解码），可以直接得到前两段的信息：

![](jwt_ms.png)


用Token去请求API服务的接口获得了完整的identity信息：

```json
[
  {
    "type": "iss",
    "value": "https://localhost:5001"
  },
  {
    "type": "nbf",
    "value": "1702828725"
  },
  {
    "type": "iat",
    "value": "1702828725"
  },
  {
    "type": "exp",
    "value": "1702832325"
  },
  {
    "type": "scope",
    "value": "api1"
  },
  {
    "type": "client_id",
    "value": "client"
  },
  {
    "type": "jti",
    "value": "CC5184E1790D538034382D8940758766"
  }
]
```


## 2. 增加OIDC支持交互

接下来尝试[第二个Sample](https://docs.duendesoftware.com/identityserver/v7/quickstarts/2_interactive/)，在之前服务基础上增加用户认证（基于OIDC协议）。

这个Sample用ASP.NET Razer Pages造了一个UI页面。

这次在Server、API、Client三个角色的基础上增加了Web Client。

首先是Server的改造，要加入用户支持所以要开启OIDC。

### 加入OIDC的Server

IS内置对OIDC的支持，只是需要开发者提供UI，Pages下面是每个页面源码，cshtml这种混合方式和之前用过的某些模板语言还真挺像。

![](pages_code.png)

`ConfigureServices`中明显比第一个Sample多了许多内容，看了下主要是三个部分：
- UI支持，通过注册RazerPages和静态页面
- OIDC配置，定义了IdentityResources、ApiScope和Clients，还加入了一些测试用户（TestUser.cs中能找到两个虚拟账户Alice和Bob的信息）
- 加入认证方法，这里用的Google认证

注册OIDC Client的机制和第一个Sample里面的OAuth有点类似，多了登入、登出时候的重定向：

```csharp
    // where to redirect after login
    RedirectUris = { "https://localhost:5002/signin-oidc" },
    // where to redirect after logout
    PostLogoutRedirectUris = { "https://localhost:5002/signout-callback-oidc" },
```

启动后就是一个完整的页面，乍一看还以为是文档，但其实是几个路由。

![](5001_home.png)

现在因为只有一个Server，每个路由点进去都会被重定向到登陆：

![](login.png)

显然后续会通过图中这几种方式测试登陆。

### OIDC Client

> csproj中缺失了`System.IdentityModel.Tokens.Jwt`的依赖，这还帮他们发现个Bug，后续提个Issue。

> 这里用的IdentityModel是[azure的库](https://github.com/AzureAD/azure-activedirectory-identitymodel-extensions-for-dotnet)，与IS无关

接下来是用于登陆的Web Client，在Program中配置Authority与:5001的Server绑定。`DefaultChallengeScheme`设置为`oidc`强制用户登录，`DefaultScheme`设为`Cookies`，也就是认证信息将会被存储的方式。

此处就是OIDC的起点，将用户重定向到IS服务。用户登陆之后再重定向回来，在这里创建Cookies。后续的请求都会带上这些cookie。

> 后续待阅：Razor Pages的认证惯例 https://learn.microsoft.com/en-us/aspnet/core/security/authorization/razor-pages-authorization?view=aspnetcore-6.0

从Index.cshtml的内容大致能看出这个页面会把Claims和Cookies的内容（通过`HttpContext.AuthenticateAsync()`获取的结果）逐项展示出来。

现在启动Web Client，和5002端口绑定，用浏览器打开https://localhost:5002之后直接跳转到了5001，链接中还附带了跳回5002的重定向信息。

![](5002_open.png)

此时它已经与IS服务完成了握手。

尝试登陆Alice的账号，跳转回了5002，页面显示出完整的Alice身份信息和Cookies属性。

![](alice.png)

从F12控制台中也能看到`https://localhost:5002/`接口请求头的Cookie中所用的正是这些信息。

### Google登陆

直接选择Google登陆，不出所料报错了：

![](google_try.png)

用人家的账号登陆，当然得报备才行。此处需要在Google Cloud平台注册个app，获得授权凭据：

![](google.png)

需要在配置中加入授权重定向URI：

![](google_app.png)

此处安全起见，.NET有[专门的方式](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/social/google-logins?view=aspnetcore-6.0)存储ClientID和Secret

```
dotnet user-secrets set "Authentication:Google:ClientId" "<client-id>"
dotnet user-secrets set "Authentication:Google:ClientSecret" "<client-secret>"
```

此时再重新启动Server，尝试Google登陆，出现了用户认证页面：

![](google_ok.png)

还挺神奇，居然能用这个不存在的东西来登陆。然而此时开始了无限加载：

![](google_wait.png)

查了下发现是重定向的接口需要一段时间才能生效，等待几个小时后重试：

![](google_after.png)

终于成功，此时amr的值已经变成了external，识别为外部认证机制。（虽然有梯子，但登陆过程几乎有一大半几率失败，需要重试多次，猜测Google并没有分配多少资源给测试版本的免费App）

后续试试把Google Cloud APP中允许的用户接口开放出来看看能被允许获取到什么。

## 3. OIDC基础上访问API

其实应该算是Sample 2的后半部分，2中只进行了Identity资源的获取（profile和openid），接下来是把这些用在API资源的调用上。包含两个Token

- Identity Token
- Access Token

此处IS服务端增加了两处改变：在scope中增加了api1，供用户访问；在服务设置中增加`AllowOfflineAccess=true`，作用是能够支持刷新token。

Web Client也需要对这两项做相应的修改，在oidc的options中增加`options.SaveTokens = true;`，将Token信息存储下来。

### 携带Token访问Api

在CallApi.cshtml和CallApi.cshtml.cs中能看到代码在请求:6001/之前增加了获取Token的步骤：

```csharp
    var accessToken = await HttpContext.GetTokenAsync("access_token");
    var client = new HttpClient();
    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
    var content = await client.GetStringAsync("https://localhost:6001/identity");
```

此时用bob账户登陆:5002，访问`/CallApi`，就能看到在第一个Sample中通过Client程序直接调用的接口在页面上呈现出来：

![](callapi.png)

从这里出发，就需要考虑token缓存、存储、失效刷新，这些都是以前在实际项目中做过的内容。

> 这里Duende推荐直接用ASP.NET Core的官方库IdentityModel来进行lifetime management，后续了解 https://identitymodel.readthedocs.io/en/latest/aspnetcore/overview.html

## 4. 引入ORM

> 这里Server用v7出了问题，从'System.Collections.Generic.IList`1<Microsoft.EntityFrameworkCore.Metadata.Conventions.IModelFinalizingConvention> Microsoft.EntityFrameworkCore.Metadata.Conventions.ConventionSet.get_ModelFinalizingConventions()'开始往外追溯，很多地方要改，换成.NET 7+v6也不行，所以推测是.NET本身的变化造成不兼容，但应该仅限于ORM配置部分，与IS本身功能无涉

前面的Sample中，无论用户信息还是Token存取都是发生在内存中，用完即弃，实际使用的时候当然需要存储。所以引入存储是接下来要考虑的，这里用到的是Entity Framework，也就是.NET官方ORM。而Identity.Server也内置了对EntityFramework的支持。

似乎到了熟悉的领域，这里直接用Sqlite（我最近写的词典工具也直接用了Sqlite，最新版本的Sqlite已经拥有了非常瞩目的性能，真是小而美的典范）。接下来是常见的模式，定义Context、Connection、Migration、Schema，

> 这里引申了在版本更迭、Schema变更时候的migration管理讨论，后续阅读 https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/?tabs=dotnet-core-cli

这一节的QuickStart篇幅着重在讲初始化数据，在HostingExtensions.cs中将Client、IdentityResources、ApiScope的信息都入库，同样在Pipeline中也加入Database的逻辑。其他部分的内容基本没变。

### 数据表

但初始化数据后看了一下，确实没想到有这么多内容：


![](tables.png)

挺像Django初始化之后生成的大量的和用户权限相关的表。虽然目前只有少数的表有内容：

![](table_data.png)

其中信息最多的应该还是`Clients`这个表：

![](table_clients.png)

尝试登陆了一下之后，发现PersistedGrants中有新的数据产生，正是当前的Session：

![](table_session.png)

此时基于IdentityServer的系列流程的相关数据都已经实现了持久化。

## 5. 构造Javascript应用

此处有两种模式：有后端的JS应用和无后端的JS应用。推荐有后端（即服务于前端的后端，Backend For Frontent，BFF）的风格，更安全也更符合现代的开发规范，这种方式中由后端实现所有与Token服务器的安全协议交互。

### 引入BFF

Duende提供了名为BFF的库来辅助这一实现，在这里后端负责所有认证交互和管理，而用户侧（client-side）的JavaScript服务则直接使用传统的cookie认证与Server进行认证。

[这个Sample](https://docs.duendesoftware.com/identityserver/v7/quickstarts/js_clients/js_with_backend/V)类似第三个Sample的流程，但其中前端部分增加了JavaScript应用。

代码中增加了JavaScriptClient，是基于Duende.BFF实现，整体机制还是类似于前面的WebClient，只是把Razor Pages完成的功能交由BFF去实现。简单的静态文件整体作用一览无余：

![](index_js.png)

而JS文件中则是调用了几个`/bff`开头的接口，可见是直接与BFF框架功能交互。

在Program.cs中依旧是类似Web Client的一系列初始化，只不过重定向的部分换成了这个服务本身的链接。

### 运行情况

运行之后是简单的页面：

![](js_page.png)

这简陋的页面不禁让人怀疑作者搞了这么多示例代码之后已经累得不想再写一个JS版本的登陆页面，毕竟IS服务用Razor Pages做的UI还有模有样的。

然后就是与前面相同的OIDC协议交互，点击Login后跳转到5001端口的登陆页面，继续用bob登入，跳转回到JS页面，获得与前面类似的Client信息，但是其中部分字段已经变成了bff：

![](js_bob.png)

Remote API即调用Api服务的`/identity`接口，也是直接展示到下方。点击Logout之后能够成功跳转到5001的登出页面。

### 其他

暂时记录这么多Sample的测试情况，文档还另外提供了无Backend版本的demo，也就是将协议交互的内容也写到JS代码中，没什么实际使用意义，毕竟现在前后端分离已经是默认基准。

文档还提供了Blazor WASM版本的前端，也就是把这节JavaScript和Duende.BFF做的事情用Blazor WASM库再实现一次，简单运行了下发现区别不大，这里不再赘述。

## 结尾

这些尝试只是简单入门，后续诸多复杂课题尚未开始，包括用户管理系统接入、状态管理、多要素认证等等。首先需要克服的还是还是语言，C#没有最初以为的门槛那么高，但繁琐程度不容小觑。这几天跟着OIDC流程几乎把所有语法细节都打了个照面，但也仅仅是看一眼的程度，要适应还是得上手写大量的代码。

以及，涉及OIDC和OAuth 2.0的元素以前做业务的时候居然接触过不少，甚至还写过挺多代码，但当时只是片面地知道这里是个授权方法、那里要拿个Bearer Token，却从来没有想过从全局上去了解这个机制。难以想象这种盲目。
