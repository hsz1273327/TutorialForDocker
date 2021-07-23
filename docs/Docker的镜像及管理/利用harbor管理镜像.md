# 利用harbor管理镜像

harbor是一个企业级自建镜像仓库方案,除了仓库,还额外集成了用户权限管理,镜像签名,镜像安全扫描以及对p2p分发的支持,对k8s的支持方面也支持作为`Helm Charts`仓库.

首先强调:虽然看着功能相当强大,但通常没什么必要自建仓库,官方的docker hub已经足够满足一般个人用户的需要.

但如果你是企业用户,自建镜像仓库就是个必选项了,毕竟本地镜像仓库相对更加稳定安全可靠.

本文将介绍harbor的部署和使用.

## 安装harbor

自建镜像仓库首选[harbor](https://github.com/goharbor/harbor).

harbor的部署完全依赖docker,官方有两种部署方式:

1. 单节点部署
2. 集群化高可用部署

个人更加建议单节点部署而不是集群化高可用部署,因为

1. 作为一个镜像仓库它并不是业务的主体,不该占用过多的资源.
2. 镜像的推拉操作相对比较低频,用不着太多资源

本文也将只介绍单节点部署的

部署harbor的的基本需求是:

+ x86/64平台(亲测arm平台部署不起来)
+ linux系统
+ 2核cpu+
+ 4G内存+
+ 40G硬盘+
+ docker(版本不能太低)
+ docker-compose(版本不能太低)
+ ssl(版本不能太低)
+ 可用的PostgreSQL数据库(可选)

安装的步骤如下:

1. 下载[安装包](https://github.com/goharbor/harbor/releases/tag/v2.1.1)建议下载offline版本的安装包.下载完后解压到要安装的机器上.
2. 配置ssl认证和私钥(可选)
3. 在自己的PostgreSQL数据库中创建需要的库和用户(可选)
4. 配置harbor,根据模板文件`harbor.yml.temp`编辑配置文件`harbor.yml`
5. 执行安装脚本`install.sh`

### 配置harbor的安装

harbor的安装是组件化的,我们可以先把配置都配好然后根据需要选择是否要特定的功能.harbor的功能包括:

+ 基本的镜像仓库和用户权限管理
+ 镜像漏洞扫面(--with-clair/--with-trivy)
+ 镜像签名校验(--with-notary)
+ Helm Charts仓库(--with-chartmuseum)

我们只需要在配置文件中按需填写配置,然后在安装时我们只需要执行`./install.sh --xxxx`就可以重置安装harbor了.

#### 配置和安装

```yaml
## 无论如何都要配的

# 你的harbor对外的域名,不要使用`localhost`,`0.0.0.0`或者`127.0.0.1`,如果有域名就用域名,没有就用宿主机的ip地址
hostname: reg.mydomain.com

# 默认初始admin用户的初始密码
harbor_admin_password: Harbor12345

## log相关
log:
  # options are debug, info, warning, error, fatal
  level: info
  # configs for logs in local storage
  local:
    # Log files are rotated log_rotate_count times before being removed. If count is 0, old versions are removed rather than rotated.
    rotate_count: 50
    # Log files are rotated only if they grow bigger than log_rotate_size bytes. If size is followed by k, the size is assumed to be in kilobytes.
    # If the M is used, the size is in megabytes, and if G is used, the size is in gigabytes. So size 100, size 100k, size 100M and size 100G
    # are all valid.
    rotate_size: 200M
    # The directory on your host that store log
    location: /var/log/harbor

## 任务调度服务配置
jobservice:
  # 最大执行者数量
  max_job_workers: 10

## 提醒相关设置
notification:
  # Maximum retry count for webhook job
  webhook_job_max_retry: 10

## 通讯协议和安全相关

# http 协议相关的配置,生产环境不要用http协议,应该全部使用https协议,注释掉就禁用了
http:
  # http协议开放的端口,如果`https`协议有配置,则这个端口会重新定向给https的端口
  port: 80

# https 协议相关的配置,生产环境无论内网外网都应该使用https协议,注释掉就禁用了
https:
  # https协议的端口,默认 443
  port: 443
  # https协议使用的签名和私钥
  certificate: /your/certificate/path
  private_key: /your/private/key/path

# 在harbor各个组件间通信时使用tls加密,可以注释掉禁用,建议注释掉
# internal_tls:
#   enabled: true
#   # tls的证书和私钥位置所在的文件夹
#   dir: /etc/harbor/tls/internal


# 当使用外部代理时使用,指名外部代理使用的域名,不建议设置
# external_url: https://reg.mydomain.com:8433

# 配置全局代理,不建议设置
proxy:
  http_proxy:
  https_proxy:
  no_proxy:
  components:
    - core
    - jobservice
    - clair
    - trivy


## 数据存储
# 数据存放位置,主要是指的镜像存放的位置,默认使用本地硬盘存储,也可以配置如azure, gcs, s3, swift, oss作为数据存储后端,不使用本地硬盘存储可以注释掉
data_volume: /data

# 使用存储服务的配置,建议注释掉
storage_service:
  # 存储服务的证书位置
  ca_bundle:

  # 存储的后端,默认为filesystem, 可选的包括 filesystem, azure, gcs, s3, swift, oss.
  # 具体设置可以看[docker的相关配置](https://docs.docker.com/registry/configuration/)
  filesystem:
    maxthreads: 100
  # set disable to true when you want to disable registry redirect
  redirect:
    disabled: false


# Harbor 的数据库设置,如果不用外部数据harbor会根据这个设置启动一个postgresql作为数据库.
# 建议关闭和其他比如代码仓库,jekins等一起公用一个数据库实例统一管理,减少维护成本
database:
  password: root123
  max_idle_conns: 50
  max_open_conns: 1000

# 使用外部数据库,建议使用
external_database:
  # harbor基础服务的数据库配置
  harbor:
    host: harbor_db_host
    port: harbor_db_port
    db_name: harbor_db_name
    username: harbor_db_username
    password: harbor_db_password
    ssl_mode: disable
    max_idle_conns: 2
    max_open_conns: 0
  # 镜像漏洞检测服务相关的数据库配置
  # 如果使用--with-clair开启镜像漏洞检测且使用外部数据库就需要配置
  clair:
    host: clair_db_host
    port: clair_db_port
    db_name: clair_db_name
    username: clair_db_username
    password: clair_db_password
    ssl_mode: disable
  # 镜像签名的签名服务相关的数据库配置
  # 如果使用--with-notary开启镜像签名且使用外部数据库就需要配置
  notary_signer:
    host: notary_signer_db_host
    port: notary_signer_db_port
    db_name: notary_signer_db_name
    username: notary_signer_db_username
    password: notary_signer_db_password
    ssl_mode: disable
  # 镜像签名服务相关的数据库配置
  # 如果使用--with-notary开启镜像签名且使用外部数据库就需要配置
  notary_server:
    host: notary_server_db_host
    port: notary_server_db_port
    db_name: notary_server_db_name
    username: notary_server_db_username
    password: notary_server_db_password
    ssl_mode: disable


# 如果使用外部redis则需要配置这个,建议和其他运维工具共用redis降低维护成本
external_redis:
  # support redis, redis+sentinel
  # host for redis: <host_redis>:<port_redis>
  # host for redis+sentinel:
  #  <host_sentinel1>:<port_sentinel1>,<host_sentinel2>:<port_sentinel2>,<host_sentinel3>:<port_sentinel3>
  host: redis:6379
  password:
  # sentinel_master_set must be set to support redis+sentinel
  #sentinel_master_set:
  # db_index 0 is for core, it's unchangeable
  registry_db_index: 1
  jobservice_db_index: 2
  chartmuseum_db_index: 3
  clair_db_index: 4
  trivy_db_index: 5
  idle_timeout_seconds: 30

## 具体功能性服务的设置

# 配置 Clair 
clair:
  # 多少小时更新一次clair的漏洞数据库
  updaters_interval: 12

# 配置Trivy
# Trivy DB contains vulnerability information from NVD, Red Hat, and many other upstream vulnerability databases.
# It is downloaded by Trivy from the GitHub release page https://github.com/aquasecurity/trivy-db/releases and cached
# in the local file system. In addition, the database contains the update timestamp so Trivy can detect whether it
# should download a newer version from the Internet or use the cached one. Currently, the database is updated every
# 12 hours and published as a new release to GitHub.
trivy:
  # ignoreUnfixed The flag to display only fixed vulnerabilities
  ignore_unfixed: false
  # skipUpdate The flag to enable or disable Trivy DB downloads from GitHub
  #
  # You might want to enable this flag in test or CI/CD environments to avoid GitHub rate limiting issues.
  # If the flag is enabled you have to download the `trivy-offline.tar.gz` archive manually, extract `trivy.db` and
  # `metadata.json` files and mount them in the `/home/scanner/.cache/trivy/db` path.
  skip_update: false
  #
  # insecure The flag to skip verifying registry certificate
  insecure: false
  # github_token The GitHub access token to download Trivy DB
  #
  # Anonymous downloads from GitHub are subject to the limit of 60 requests per hour. Normally such rate limit is enough
  # for production operations. If, for any reason, it's not enough, you could increase the rate limit to 5000
  # requests per hour by specifying the GitHub access token. For more details on GitHub rate limiting please consult
  # https://developer.github.com/v3/#rate-limiting
  #
  # You can create a GitHub token by following the instructions in
  # https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line
  #
  # github_token: xxx

# 配置 chartmuseum
chart:
  # Change the value of absolute_url to enabled can enable absolute url in chart
  absolute_url: disable
```

个人对安装时的建议是:

+ 将harbor部署在内网而非外网
+ 一般使用只需要使用`./install.sh --with-clair`开启漏洞检查就足以应付.
+ 不介意多个外部依赖的可以使用`./install.sh --with-clair --with-trivy`做个双重保护,个人觉得没必要.
+ 如果要部署到外网,应该开启镜像签名`./install.sh --with-clair --with-notary`
+ 如果要用k8s,应该开启`--with-chartmuseum`如果只是单机docker环境或者swarm环境则不建议开启.

需要注意安装的时候可能会报错找不到路径`common/config`,这时候手动创建就好了.

## 使用harbor

对于客户端来说harbor的使用和dockerhub主要区别在于tag的命名:

+ dockerhub:`<dockerhub用户名>/镜像名`
+ harbor:`<harbor域名>/<项目名>/镜像名`

可以看出区别是两个方面:

1. harbor不能缺省服务器域名
2. harbor不以用户名作为命名空间,而是以项目名作为命名空间.

而对于仓库来说,我们就多了一项对镜像仓库的管理任务.

镜像仓库管理主要有如下几个部分:

1. 用户权限管理
2. 镜像管理
3. 仓库管理

而我们也可以在`系统管理->配置管理->邮箱`中设置邮箱用于提醒.

harbor中的实例有如下几个:

1. 用户,harbo系统中在册的用户,只有用户才可以使用仓库中的镜像
2. 制品,仓库中物品的最小单位,拉取镜像实际拉取的内容,它可以是一个有标签的镜像,一个manifest列表(在列表中会有一个文件夹的图标)
3. 镜像,指同名镜像,制品的集合,一般用tag区分版本
4. 项目,由复数镜像组成的集合,通常只是一个命名空间
5. 仓库,由复数项目组成的集合,一个harbor实例通常就是一个仓库
6. 标签,用于标识镜像的标签,主要是方便搜索管理

### 用户权限管理

首先harbor有完整的用户体系,支持`管理员-一般成员`模型的二级权限管理,管理员基本上什么都可以干,而一般成员则会处处受限.用户的访问权限可以细化到项目,这样可以避免无关人员修改镜像造成损失.

我们可以为项目设置成员,这样非成员的用户访问这个仓库就会受限(具体如何受限要看仓库的属性).我们可以设置非管理员无法创建项目来避免项目变得无序不可维护.

下面是项目权限管理的矩阵图

| 成员类型 | 项目类型 | 是否为项目成员 | pull权限 | push权限 | 编辑镜像文档 |
| -------- | -------- | -------------- | -------- | -------- | ------------ |
| 一般     | 公开     | 是             | T        | T        | T            |
| 一般     | 非公开   | 是             | F        | T        | T            |
| 一般     | 公开     | 否             | T        | F        | F            |
| 一般     | 非公开   | 否             | F        | F        | F            |
| 管理员   | 公开     | 是             | T        | T        | T            |
| 管理员   | 非公开   | 是             | T        | T        | T            |
| 管理员   | 公开     | 否             | T        | T        | T            |
| 管理员   | 非公开   | 否             | T        | F        | T            |

我们还可以在项目中为用户设定不同的角色来更加细化的控制权限.目前角色分为:

+ 项目管理员
+ 开发者
+ 维护人员
+ 访客
+ 受限访客

### 镜像管理

harbor的本职工作就是镜像管理,镜像管理大致分为如下几个方面:

1. 为镜像提供说明和分类便于选择使用
2. 为镜像提供全声明周期管理,用于回收资源
3. 为镜像提供认证确保安全
4. 为镜像提供快速的分发渠道

#### 镜像的说明分类管理

harbor用于说明和分类的工具可以总结为:

1. 项目划分,项目划分本身可以作为分类
2. 镜像描述,在`项目->镜像->描述信息`中可以定义整个镜像的描述信息.一般用于介绍使用范围,列出依赖.
3. 标签,harbor提供标签功能(`系统管理->标签`)可以在管理页中定义好全局标签,或者在`项目->特定项目->标签`中定义项目特有标签,然后单独为特定镜像的制品打上标签用于快速识别
4. tags,镜像的tag本身就是有含义的内容,通常我们会将执行平台信息放置在其中.

#### 为镜像提供全生命周期管理

镜像除了会被创建,也应该会被删除,删除后的空间回收是镜像生命周期管理的主要工作.

harbor提供了手动回收和自动定时回收两种方式,这两种方式都在`系统管理->垃圾清理`中,手动清理就是点击`立即清理`,自动清理就是在`当前定时任务`中选择指定的执行时间.

#### 镜像安全性检查

如果部署时使用了`--with-trivy`标识,那么harbor就会附带镜像安全检测功能.我们使用的[trivy](https://github.com/aquasecurity/trivy)是一个镜像漏洞静态分析工具.它通过对容器的layer进行扫描,发现漏洞并进行预警.

需要注意我们要使用它的话需要进行如下配置:

```yml
trivy:
  # ignoreUnfixed The flag to display only fixed vulnerabilities
  ignore_unfixed: false
  # skipUpdate The flag to enable or disable Trivy DB downloads from GitHub
  #
  # You might want to enable this flag in test or CI/CD environments to avoid GitHub rate limiting issues.
  # If the flag is enabled you have to download the `trivy-offline.tar.gz` archive manually, extract `trivy.db` and
  # `metadata.json` files and mount them in the `/home/scanner/.cache/trivy/db` path.
  skip_update: false
  #
  # insecure The flag to skip verifying registry certificate
  insecure: false
  # github_token The GitHub access token to download Trivy DB
  #
  # Anonymous downloads from GitHub are subject to the limit of 60 requests per hour. Normally such rate limit is enough
  # for production operations. If, for any reason, it's not enough, you could increase the rate limit to 5000
  # requests per hour by specifying the GitHub access token. For more details on GitHub rate limiting please consult
  # https://developer.github.com/v3/#rate-limiting
  #
  # You can create a GitHub token by following the instructions in
  # https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line
  #
  github_token: xxxx
```

其中`github_token`是你github上的用户token,可以参考[这篇文章配置获得](https://docs.github.com/cn/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token)

我们可以手动的扫描特定制品,也可以设置定时任务对全仓库的镜像进行扫描,也可以在push完成后立刻对镜像扫描.

+ 指定制品扫描:`项目->特定项目->Artifacts->选择特定制品->扫描`
+ 手动全部扫描:`系统管理->审查服务->漏洞->开始扫描`
+ 设置push后立刻扫描:`项目->特定项目->配置管理->自动扫描镜像`
+ 设置定时扫描:`系统管理->审查服务->漏洞->定时扫描所有`

查出镜像有安全漏洞也不用焦虑,毕竟docker hub上的镜像80%都是由漏洞的,只要不是严重的漏洞其实也都还好.如果想要彻底避免漏洞基本只有如下几个方式

1. 使用静态语言编写的纯静态可执行文件
2. 最终镜像中不要包含任何不必要的可执行文件和共享库

这对于多数情况,尤其是以python等解释型语言为主要编程语言的用户来说几乎是不可能达到的.因为很多漏洞都是由于一些构成操作系统的很基础的库造成的,比如glibc,openssl等.因此我们可以将要求适当放宽--在配置的`部署安全`项中设置`阻止危害级别`为`危急`或者直接放开,毕竟阻止部署可能会影响CD部分的成功率.

如果发现有漏洞,一般来说我们只能等待发现漏洞的库有新版本,好在harbor的安全性检查除了检查漏洞也会检查是否可以修复,当发现可以修复后只要更新有问题的包或者更新基镜像的操作系统即可.

#### 镜像认证

如果部署时使用了`--with-notary`,那么harbor就会多开出一个端口(默认`4443`)用于提供Notary的签名服务.
Notary的目标是保证server和client之间的交互使用可信任的连接,从而确保镜像的完整性和可信度,用于解决互联网的内容发布的安全性问题.其原理还是数字签名技术,通过设置签名服务器在客户端来为build的镜像创建签名,当push时这个签名也会被带到镜像仓库;而从镜像仓库pull镜像时则会校验这个签名.

需要注意由于windows上文件夹名不能存在`:`符号,所以如果你的镜像仓库有端口号,那么就无法在window上做认证.

> 对于客户端来说,我们需要设置如下几个步骤

1. 设置根证书
    镜像认证基于tls,它需要我们信任发放证书的第三方也就是信任根证书.在`~/.docker/tls/你的harbor域名/`目录中放入根证书

2. 设置环境变量
    我们需要设置两个环境变量来激活这一功能:

    + `DOCKER_CONTENT_TRUST=1`:表示开启Docker内容信任模式,这个模式下push/pull操作的目标必须是有签名的.
    + `DOCKER_CONTENT_TRUST_SERVER=xxxxx`:指定认证服务器,harbor中默认就是`4443`端口,注意其格式为`https://xxxx:xxx`

    当设置了这两个参数后我们push镜像时就必须指定tag了,使用`-a`推送全部不会进行签名操作.如果我们在指定了这两个环境变量后希望不进行签名,那么可以在`push`子命令中加入标识`--disable-content-trust`

3. 我们可以设置notary为如下值方便管理本地的可信仓库(可选)

    + windows:`set-alias notary "notary --server https://<远程notray服务器地址> --trustDir ~/.docker/trust --tlscacert <dtr-ca.pem>"`
    + 其他:`alias notary="notary --server https://<dtr-url> --trustDir ~/.docker/trust --tlscacert <dtr-ca.pem>"`

> 对于harbor管理来说我们可以设置:

`项目->具体项目->配置管理->部署安全->内容信任`来管理是否仅允许拉取通过认证的镜像.这边建议不要开启,而是更多的在人员管理上做文章

我们也可以很方便的在制品列表中看到镜像是都通过认证.

#### 镜像分布式分发

镜像管理另一个大问题是镜像分发,

[Dragonfly](https://github.com/dragonflyoss/Dragonfly),是阿里开源的基于p2p的分发工具.其执行原理是:

1. 当执行`docker pull`操作时,客户端镜像会通过`df-daemon`使用代理的方式拦截请求并将请求转发给`supernode`节点.`supernode`节点的地址已经在客户端镜像中的`/etc/dragonfly.conf`文件中配置好了.

2.`df-daemon`启动的时候带了`registry`参数,并且通过`df-get`传给服务端`supernode`.`supernode`解析参数到对应的镜像仓库获取镜像并以`block`的形式返回给客户端.如果再次拉取镜像时,`supernode`就会检测哪一个客户端存在和镜像文件对应的`block`,如果存在直接从该client下载,如果不存在就到镜像仓库拉取镜像.

它的最大特点是结构简单,虽然是p2p的实现,但实际上还是一个中心化分发的思路,它解决的实际上是镜像分发环节中对镜像仓库的依赖问题,可以看到只要与`supernode`相连的的客户端中只要有一个已经有了就可以内部消化.这也变相一部分的解决了镜像走外网拉取的问题,可以减少外网流量.

我们需要配置的就3步:

+ 一个超级节点
+ 在需要使用这个功能的节点上配置客户端
+ 修改客户端节点上的docker配置

Dragonfly目前(release版本号1.0.6)官方只提供了`amd64`版本的镜像,通常超级节点会独立于集群,可能就是和harbor部署在一起,那一般它也是一个amd64的机器,所以超级节点只提供amd64的版本问题不大,但节点环境就复杂多了,比如我家里的有armv7版本的节点(32位PiOs)也有arm64的节点(64位ubuntu for pi).

好在它是个go语言的程序,我们可以很轻易的在各个平台编译,我在[这个fork](https://github.com/Basic-Components/Dragonfly/tree/build-multiplateform)上构造了amd64,arm64,armv7三个版本的1.0.6版本的客户端镜像,托管在[docker hub](https://registry.hub.docker.com/repository/docker/hsz1273327/dragonfly-client/tags?page=1&ordering=last_updated)上.测试可以使用.目前看官方也已经加入了对arm64平台的支持,相信下一个版本就会有了.

##### 配置Dragonfly的超级节点

以下是超级节点的配置文件(镜像中位置`/etc/dragonfly/supernode.yml`)

```yml
# This file is the template of supernode configuration file.
# You can configure your supernode by change the parameter according your requirement.
---
base:
  # ListenPort is the port supernode server listens on.
  # default: 8002
  listenPort: 8002

  # DownloadPort is the port for download files from supernode.
  # And you should start a file server firstly which listens on the download port.
  # default: 8001
  downloadPort: 8001

  # HomeDir is working directory of supernode.
  # default: /home/admin/supernode
  homeDir: /home/admin/supernode

  # the core pool size of ScheduledExecutorService.
  # When a request to start a download task, supernode will construct a thread concurrent pool
  # to download pieces of source file and write to specified storage.
  # Note: source file downloading is into pieces via range attribute set in HTTP header.
  # default: 10
  schedulerCorePoolSize: 10

  # PeerUpLimit is the upload limit of a peer. When dfget starts to play a role of peer,
  # it can only stand PeerUpLimit upload tasks from other peers.
  # default: 5
  peerUpLimit: 5

  # PeerDownLimit is the download limit of a peer. When a peer starts to download a file/image,
  # it will download file/image in the form of pieces. PeerDownLimit mean that a peer can only
  # stand starting PeerDownLimit concurrent downloading tasks.
  # default: 4
  peerDownLimit: 4

  # When dfget node starts to play a role of peer, it will provide services for other peers
  # to pull pieces. If it runs into an issue when providing services for a peer, its self failure
  # increases by 1. When the failure limit reaches EliminationLimit, the peer will isolate itself
  # as a unhealthy state. Then this dfget will be no longer called by other peers.
  # default: 5
  eliminationLimit: 5

  # FailureCountLimit is the failure count limit set in supernode for dfget client.
  # When a dfget client takes part in the peer network constructed by supernode,
  # supernode will command the peer to start distribution task.
  # When dfget client fails to finish distribution task, the failure count of client
  # increases by 1. When failure count of client reaches to FailureCountLimit(default 5),
  # dfget client will be moved to blacklist of supernode to stop playing as a peer.
  # default: 5
  failureCountLimit: 5

  # SystemReservedBandwidth is the network bandwidth reserved for system software.
  # default: 20 MB, in format of G(B)/g/M(B)/m/K(B)/k/B, pure number will also be parsed as Byte.
  systemReservedBandwidth: 20M

  # MaxBandwidth is the network bandwidth that supernode can use.
  # default: 200 MB, in format of G(B)/g/M(B)/m/K(B)/k/B, pure number will also be parsed as Byte.
  maxBandwidth: 200M

  # Whether to enable profiler
  # default: false
  enableProfiler: false

  # Whether to open DEBUG level
  # default: false
  debug: false

  # FailAccessInterval is the interval time after failed to access the URL.
  # If a task failed to be downloaded from the source, it will not be retried in the time since the last failure.
  # default: 3m
  failAccessInterval: 3m

  # gc related

  # GCInitialDelay is the delay time from the start to the first GC execution.
  # default: 6s
  gcInitialDelay: 6s

  # GCMetaInterval is the interval time to execute GC meta.
  # default: 2m0s
  gcMetaInterval: 2m

  # TaskExpireTime when a task is not accessed within the taskExpireTime,
  # and it will be treated to be expired.
  # default: 3m0s
  taskExpireTime: 3m

  # PeerGCDelay is the delay time to execute the GC after the peer has reported the offline.
  # default: 3m0s
  peerGCDelay: 3m

  # GCDiskInterval is the interval time to execute GC disk.
  # default: 15s
  gcDiskInterval: 15s

  # YoungGCThreshold if the available disk space is more than YoungGCThreshold
  # and there is no need to GC disk.
  # default: 100GB
  youngGCThreshold: 100G

  #  FullGCThreshold if the available disk space is less than FullGCThreshold
  #  and the supernode should gc all task files which are not being used.
  #  default: 5GB
  fullGCThreshold: 5G

  # IntervalThreshold is the threshold of the interval at which the task file is accessed.
  # default: 2h0m0s
  IntervalThreshold: 2h
```

我们根据需求修改其中的配置,然后通过如下docker-compose文件部署到amd64的机器上:

```yml
version: "2.4"

x-log: &default-log
  options:
    max-size: "10m"
    max-file: "3"

services:
  supernode:
    # build:
    #   context: .
    #   dockerfile: Dockerfile.supernode
    image: dragonflyoss/supernode:1.0.6
    logging:
      <<: *default-log
    cpus: 0.8
    mem_limit: 100m
    memswap_limit: 200m
    restart: on-failure
    ports:
      - "8001:8001"
      - "8002:8002"
    volumes:
      - "你的数据文件夹用于存储镜像:/home/admin/supernode"
      - "你的超级节点配置文件位置:/etc/dragonfly/supernode.yml"
    command: ["--download-port=8001"]
```

部署好后我们假设其地址为`mysupernodehost`

##### 配置客户端

客户端配置相对会麻烦些.大致可以分为3步:

1. 为客户端写配置文件

    dragonfly的客户端需要在所有要用它的机器上部署,其配置文件大致应该是这样:

    + harbor使用了http

        ```yml
        registry_mirror:
          remote: https://index.docker.io
          insecure: false
          certs: []
        dfget_flags: ["--node","<mysupernodehost>=1","-f","Expires&Signature"]
        proxies:
          # 代理所有经过它代理的拉取镜像的http请求
          - regx: blobs/sha256.*
        hijack_https:
          hosts:
            - regx: <myharbor_host>
              certs: []
              insecure: true
        ```

    + harbor使用了https

        ```yml
        registry_mirror:
          remote: https://index.docker.io
          insecure: false
          certs: []
        dfget_flags: ["--node","<mysupernodehost>:8002=1","-f","Expires&Signature"]
        proxies:
          # 代理所有经过它代理的拉取镜像的http请求
          - regx: blobs/sha256.*
        hijack_https:
          # 创建df使用的私钥-证书对,可以在
          cert: /keys/df.crt
          key: /keys/df.key
          hosts:
            - regx: <myharbor>:9443
        ```

        + 创建`df.key`

            ```bash
            openssl genrsa -des3 -passout pass:<随机4个以上字符的字符串> -out df.pass.key 2048
            openssl rsa -passin pass:<上面的字符串> -in df.pass.key -out df.key
            rm df.pass.key
            ```

        + 创建`df.crt`

            ```bash
            openssl req -new -key df.key -out df.csr
            openssl x509 -req -sha256 -days 365 -in df.csr -signkey df.key -out df.crt
            rm df.csr
            ```

        注意这个在windows上无法创建,创建好后可以利用swarm的`secrets`将其保存好(`dfdaemon-df_key`和`dfdaemon-df_crt`).之后还要将harbor设置为`insecure-registries`

        ```json
        {
          "insecure-registries": ["mysupernodehost:9443"]
        }
        ```

    + harbor使用了自签名的https

        除了上面`harbor使用了https`的步骤外还需要将自签名的根证书放入配置

        ```yml
        registry_mirror:
          remote: https://index.docker.io
          insecure: false
          certs: []
        dfget_flags: ["--node","<mysupernodehost></mysupernodehost>:8002=1","-f","Expires&Signature"]
        proxies:
          # 代理所有经过它代理的拉取镜像的http请求
          - regx: blobs/sha256.*
        hijack_https:
          # 创建df使用的私钥-证书对
          cert: /keys/df.crt
          key: /keys/df.key
          hosts:
            - regx: <myharbor></myharbor>:9443
              #如果你的harbor是自己签名的需要将根证书放在这里
              certs: ["ca.crt"]
        ```

2. 部署客户端

> docker standalone部署

```yml
version: "2.4"

x-log: &default-log
  options:
    max-size: "10m"
    max-file: "3"

services:
  dfclient:
    image: hsz1273327/dragonfly-client:1.0.6
    logging:
      <<: *default-log
    cpus: 0.8
    mem_limit: 100m
    memswap_limit: 200m
    restart: on-failure
    ports:
      - "65001:65001"
    volumes:
      - "你的节点数据文件夹位置:/root/.small-dragonfly"
      - "你的节点配置位置:/etc/dragonfly/dfdaemon.yml"
      - "你的key文件夹:/keys"
```

/home/hsz/workspace/docker_deploy

> swarm部署

我们可以利用`mode: global`在其中每台机器上部署,使用`config`来统一客户端配置(`dfdaemon-config`),使用

然后使用下面的方式部署客户端到整个集群

```yml
version: "3.7"

x-log: &default-log
  options:
    max-size: "10m"
    max-file: "3"

services:
  dfclient:
    image: hsz1273327/dragonfly-client:1.0.6
    logging:
      <<: *default-log
    ports:
      - "65001:65001"
    volumes:
      - "df-client-data:/root/.small-dragonfly"
    configs:
      - source: dfdaemon-config
        target: /etc/dragonfly/dfdaemon.yml
    secrets:
      - source: dfdaemon-df_key
        target: /keys/df.key
      - source: dfdaemon-df_crt
        target: /keys/df.crt

    deploy:
      mode: global
      resources:
        limits:
          cpus: '0.5'
          memory: 200M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 100s

volumes:
  df-client-data:

configs:
  dfdaemon-config:
    external: true

secrets:
  dfdaemon-df_key:
    external: true
  dfdaemon-df_crt:
    external: true

```

1. 为每台机器设置http代理

    + `/etc/systemd/system/docker.service.d/http-proxy.conf`

    ```conf
    [Service]
    Environment="HTTP_PROXY=http://127.0.0.1:65001"
    Environment="HTTPS_PROXY=http://127.0.0.1:65001"
    Environment="NO_PROXY=localhost,127.0.0.1"
    ```

    + 修改docker配置 无论那种方式都需要将harbor的host加入docker的配置项`insecure-registries`中

    + 之后重启docker

    ```bash
    sudo systemctl daemon-reload 
    sudo systemctl restart docker
    ```

   这样之后我们就可以利用`dragonfly`通过p2p方式分发harbor中的镜像了

##### 配置harbor

在harbor中我们可以为`dragonfly`预热镜像,在`系统管理->分布式分发`中可以设置`dragonfly`的`supernode`,然后我们可以在项目下的`p2p预热`中设置预热规则.可以通过过滤器设置哪些镜像会被预热,然后可以设置定时预热或者事件触发预热.

过滤器支持`双星语法`,其规则如下:

| 特殊字符     | 含义                                                                                                                              |
| ------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| `*`          | 匹配任何非路径分隔符序列                                                                                                          |
| `**`         | 匹配任何字符序列，包括路径分隔符                                                                                                  |
| `?`          | 匹配任何单个非路径分隔符字符                                                                                                      |
| `[class]`    | 匹配一类非路径分隔符的单个字符,支持的有`[abc]`特定单个在集合中的字符,`[a-z]`特定单个在范围中的字符,`[^class]`特定不在范围中的字符 |
| `{alt1,...}` | 如果逗号分隔的替代项之一匹配,则匹配一个字符序列                                                                                   |

### 仓库管理

harbor除了自己可以作为镜像仓库外也可以用于与外部的仓库同步.我们需要在`系统管理->仓库管理`中定义好自己的目标仓库,并提供登录信息.然后再在`系统管理->复制管理`中定义规则.

harbor不仅支持其他harbor仓库和dockerhub,也支持比如华为云在内的其他许多仓库实现.而规则可以是从本仓库复制到目标仓库也可以是从目标仓库复制到本仓库.这以特性可以解决多地部署的镜像同步问题.
