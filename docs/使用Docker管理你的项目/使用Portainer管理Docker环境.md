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

情况编号|部署方式|docker执行环境
---|---|---
1|远程单机/local|docker
2|agent|docker swarm
3|edge agent|docker和docker swarm
4|agent|k8s

下面我们来详细介绍这几种情况的使用

### 情况1

在远程单机或者本地单机的情况下部署分为`stack`和`contaners`两级.在单机情况下确实`service`一级逻辑十分简单,所以portainer省略了这一级,这两级都可以用于部署容器,但一般还是在`stack`一级部署容器会更容易管理些.

`stack`页面使用的是v2版本的docker-compose来部署.但需要注意stack的更新并不会重新拉取镜像,只有在`images`中重新拉取了镜像后remove掉执行中的容器后重新部署才会更新镜像.

这种模式下我们可以管的东西最少:

1. 可以在`Host`页面查看宿主机资源,
2. 可以在`Networks`页面查看和管理网络资源
3. 可以在`Volumes`页面可以查看和管理挂载的存储资源,通常nfs设置也在这边


### 情况2

<!-- 
### 情况3 -->

