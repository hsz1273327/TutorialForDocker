# 使用Portainer管理Docker环境

[Portainer](https://github.com/portainer/portainer)是一个专注于Docker环境管理的可视化开源工具.目前它支持管理的环境有:

+ 本地环境
+ 远程单机环境
+ Swarm环境
+ kubernetes环境

对kubernetes环境的支持是今年3月Portainer 2.0版本新增的特性.因此可能目前支持并不完善.但Portainer社区相当活跃,相信很快就会成熟.

需要注意,Portainer使用`docker-compose`部署容器使用的是自己fork的[libcompose](https://github.com/portainer/libcompose)实现的.也就是说它和docker官方的实现并不是同步的.
比如对GPU的支持目前Portainer还没有.如果有这种需求可能还是得手工去manager节点操作.

Portainer除了提供页面外也提供API供外部调用.由于是使用会过期的jwt作为权限令牌的所以相对也是比较安全的.

## 安装

portainer支持docker本地安装,docker swarm集群安装,以及k8s集群安装,具体的安装方式可以查看[官方安装文档](https://documentation.portainer.io/v2.0/deploy/linux/).
个人推荐docker本地模式安装,并且最好是放在一台相对稳定且与用于部署线上服务的机器隔离的机器上,并使用端点(Endpoint)来管理集群.

本地docker部署的方法是:

+ http

    ```bash
    docker volume create portainer_data
    docker run -d -p 8000:8000 -p 9000:9000 \
        --name=portainer --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce
    ```

+ https

    ```bash
    docker volume create portainer_data
    docker run -d -p 8000:8000 -p 9000:9000 \
    --name=portainer --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    -v ~/local-certs:/certs \
    portainer/portainer-ce --ssl --sslcert /certs/portainer.crt --sslkey /certs/portainer.key
    ```

安装完成后我们进入其中(默认9000端口)会看到如下页面

![进入portainer](../IMGS/portainer-main.PNG)

其中`Home`就是当前页面

`SETTINGS`下面则是这个portainer下的管理设置.其中

+ `Users`用于管理可以登录这个portainer的用户,我们不止可以在其中注册用户也可以设置用户组用于分群管理,不过用户权限设置是portainer企业版的功能,社区版没有.
+ `Endpoints`用于添加和管理端点,所谓端点就是我们维护的docker执行环境.我们可以在其中添加单机docker,docker swarm集群或者k8s集群用于管理.同时可以为集群打上标签或者分群管理.根据安装的方式不同,我们会默认将宿主环境添加到其中作为第一个端点(默认命名为`primary`)
+ `Registries`用于保存使用的镜像仓库信息,默认情况下我们只能拉取docker hub上的镜像,如果要使用私有镜像仓库,我们需要将其连同登录信息注册到这里
+ `Settings`则是其他一些设置,主要是认证信息等,一般默认就行.如果我们要使用edge agent模式添加端点,建议将`Enable edge compute features`打开

而其他的侧边栏则是当前使用的Endpoint的管理选项.由于我已经将宿主机代表的端点改名为`local`,所以侧边的标题就成了local.其中的各个标签作用我们在后面单独按情况介绍

## 添加端点

我们用portainer主要是添加3类端点:

+ 远程单机环境Docker

    这种端点必须开通要连接的宿主机上docker自带的api加入端点.建议加上tls确保安全性.

    这种选择路径`Endpoints->Docker`,然后填上远程docker环境的自带api路径即可

+ agent模式

    这种模式支持添加swarm集群或者k8s集群,它需要先在集群上以global方式部署镜像`portainer/agent`,而且容器需要映射宿主机的`/var/run/docker.sock`和`/var/lib/docker/volumes`

+ edge agent模式

    这种模式主要是为边缘计算设计的,它和agent模式的主要区别是edge agent模式管理的单机或者集群并不需要portainer的宿主机可以访问到,只要部署为`edge agent`的机器可以访问到portainer即可.因此一般用这种模式管理其他内网内的集群.比如我们在成都分公司有一个swarm集群,南京分公司有一个swarm集群,深圳分公司也有一个swarm集群,这些集群都部署在公司内网且这些内网并没有相互大打通,那么如果我们希望在北京总部统一管理这些swarm集群就可以使用edge agent模式.
    edge agent模式目前支持单机docker环境和swarm环境

## 使用

portainer的使用主要看管理的是什么docker环境以及用的哪种方式部署,其中可以分为如下情况

| 情况编号 | 部署方式       | docker执行环境                  |
| -------- | -------------- | ------------------------------- |
| 1        | 远程单机/local | docker standalone               |
| 2        | agent          | docker swarm                    |
<!-- | 3        | edge agent     | docker standalone和docker swarm |
| 4        | agent          | k8s                             | -->

下面我们来详细介绍这几种情况的使用

### 情况1

在远程单机或者本地单机的情况下portainer的管理页面包括:

+ `Dashboard`用于描述当前端点的概况,我们可以一目了然的看到当宿主机的cpu和内存情况,以及服务的部署情况等
+ `App Template`用于保存和维护docker standalone和docker swarm下的docker-compose.yml模板.
+ `Stacks`用于维护部署中的`stack`.
+ `Container`用于维护部署中的容器
+ `Images`用于维护当前宿主机上存在的镜像
+ `Networks`用于维护当前docker中创建的network
+ `Volumes`用于维护当前docker挂载的存储资源,通常nfs设置也在这边
+ `Events`用于查看当前docker发出的event
+ `Host`用于查看当前宿主机详细情况

在远程单机或者本地单机的情况下部署分为`stack`和`contaners`两级.在单机情况下确实`service`一级逻辑十分简单,所以portainer省略了这一级,这两级都可以用于部署容器,但一般还是在`stack`一级部署容器会更容易管理些.

![stack管理页面](../IMGS/portainer-standalone-stack.PNG)

`stack`中的docker-compose内容在`Editor`子页面,使用的是v2版本的docker-compose来部署(新版本似乎支持v3了但我个人依然不推荐),我们可以更改后点击`Update the stack`来更新这个stack.需要注意stack的更新并不会重新拉取镜像,只有在`Images`中重新拉取了镜像后remove掉执行中的容器后重新部署才会更新镜像.

而如果你希望将这个stack的部署的内容也部署到其他端点,可以使用这个页面中显示的`Stack duplication / migration`下面的选项实现.

在页面底部是这个stack下的容器的列表,我们可以选中要操作的容器直接在这个页面下操作,也可以直接点击容器中的四个小按钮进行一些常用操作

+ `文件图标`: 查看容器log
+ `感叹号图标`: 查看容器状态
+ `图表图标`: 观察容器资源占用
+ `命令行图标`: 连接容器命令行

### 情况2

使用agent部署docker swarm的情况

<!-- 
### 情况3 -->

