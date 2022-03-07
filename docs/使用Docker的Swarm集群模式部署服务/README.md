# 使用Docker的Swarm集群模式部署服务

Docker自带一个集群模式`Swarm`,它的定位是轻量级的集群管理工具.最大的特点是轻量:

+ 集成在docker中
+ 接口风格和单机版高度一致
+ 使用的工具和单机版高度重合
+ 只提供最基本的集群化工具
+ 部署简单
+ 启动快速

原生Swarm集群大致分为如下几个部分:

+ 集群节点管理
+ 集群化部署管理
+ 集群网络管理
+ 集群数据管理

前面的单机部署中我们已经接触过`docker-compose`,它的基本用法我们已经了解了.swarm模式下使用的`docker-compse`是`v3`版本,这个版本目前还在迭代,目前最新版本是`v3.9`也就是`Compose specification`版本,`v3`版本基本兼容`v2`,只是有一些比如`runtime`这些在`v3`版本中被删除了而已.

swarm部分的文章主要是结合compose`v2`到`v3`的变化介绍docker swarm相比单机版本docker的变化.

本系列以[3.8](https://docs.docker.com/compose/compose-file/compose-file-v3/)版本为基础介绍变化和使用注意点.

本部分是容器化集群的分支之一,与k8s部分几乎平行,可以视需要选择是否学习.