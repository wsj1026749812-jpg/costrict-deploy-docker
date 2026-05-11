# Casdoor基本配置文档

此文档是从0配置casdoor,本教程大部分配置在安装后已经配置成功了，如果需要添加用户，可以见 **添加用户**

<span style="color: red; font-weight: bold;">再次提醒，本教程是从0开始配置casdoor的示例,目前，casdoor已经内置了costrict相关的组织和用户,你只需要往costrict组织中添加用户即可</span>(组织和用户名称可能由于版本变更变化,只要你看到组织有两个，built-in组织是管理组不用管，另一个组织就是costrict用户的组织)

## 配置页面

### 配置页面访问

访问 http://{COSTRICT_BACKEND}:{PORT_CASDOOR}, 进入管理端登陆页面

```commandline
默认账号： admin
默认密码： 123
```

然后进入到管理页面

## 添加组织

添加的这个组织将会存放所有costrict用户,组织的名称并不重要，可自定义

![image-20260120095700101](./casdoor-img/config-images/1-add_org-1.png)

![image-20260120095741985](./casdoor-img/config-images/1-add_org-2.png)

## 添加应用

这将是CoStrict登录用到的应用,应用名称并不重要，可自定义.
![image-20260120095801365](./casdoor-img/config-images/2-add_app-1.png)


![image-20260120102644577](./casdoor-img/config-images/2-add_app-2.png)


> 客户端ID和客户端密钥对应部署目录`configure.sh`  `OIDC_CLIENT_ID` `OIDC_CLIENT_SECRET`两个变量(注意,这两个id和oidc配置中的需要一致,请看部署目录oidc-auth相关配置),如：

```
9e2fc5d4fbcd52ef4f6f
ab5d8ba28b0e6c0d6e971247cdc1deb269c9eea3
```

> 其中 组织是前面新建的组织

![image-20260120101039642](./casdoor-img/config-images/2-add_app-3.png)



重定向url,请修改ip和port,可部署目录`configure.sh` 文件中的 `COSTRICT_BACKEND_BASEURL` 的ip端口一致(注意，根据情况选择使用http/https,完整按照本教程，则是使用http 不要用变量，是真实的ip端口)

一键部署已经默认设置了通配符，为保证安全，可以修改此处

```
http://ip:port/oidc-auth/api/v1/plugin/login/callback
http://ip:port/oidc-auth/api/v1/manager/bind/account/callback
http://ip:port/oidc-auth/api/v1/manager/login/callback
```

![image-20260120100515628](./casdoor-img/config-images/2-add_app-4.png)

> 最后，保存当前应用

## 添加用户

进入组织的用户，然后点击添加

![image-20260120102919337](./casdoor-img/config-images/3-add_user-1.png)

添加demo用户，点击保存&退出。

![image-20260120103025347](./casdoor-img/config-images/3-add_user-2.png)

添加后可以修改密码：
![image-20260120103919026](./casdoor-img/config-images/4-update_user-1.png)

![image-20260120103933033](./casdoor-img/config-images/4-update_user-2.png)


如果你需要批量导入用户，请查看官方教程：[从XLSX文件导入用户](https://www.casdoor.org/zh/docs/user/overview/#%E4%BB%8Exlsx%E6%96%87%E4%BB%B6%E5%AF%BC%E5%85%A5%E7%94%A8%E6%88%B7)

> 配置结束，之后就可以使用demo用户登录costrict了(注意是登录costrict不是casdoor)

## 对接第三方认证系统

![](./casdoor-img/config-images/5-provider-add.png)

请根据实际情况配置，其中 客户端ID, 客户端密钥: 和组织中设置的一样即可。