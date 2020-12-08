# 单机使用docker部署服务

docker并不一定非要自己构建镜像,很多时候docker生态是作为一种高效的分发工具而存在的.由于使用docker可以保证环境一致,这在本地开发调试中尤其常用.

## docker容器部署的逻辑结构.

docker容器部署的逻辑结构有3层,即

1. `container`容器,用于实际部署镜像执行任务
2. `service`服务,是一组执行相同镜像相同配置部署的容器的集合,`service`中每个容器都是等价的,通常是用作负载均衡的.
3. `stack`堆,用于描述一组互不相同的`service`的集合

这个模型基本上已经可以将常见的业务形态都包含进去了

## docker的执行环境

docker的runtime就是docker执行容器的运行时,它必须满足一定的规范,我们安装好docker后已经有了一个默认的runtime,通常情况下这个runtime已经够用,但在`docker 19.03`之前如果我们想使用gpu,那么我们必须使用`nvidia-docker`这个docker的实现,而在之后docker已经原生支持gpu了,我们可以声明`nvidia-container-runtime`的位置来直接支持使用gpu.本文以`docker 19.03`以后的版本为准,因此就不介绍`nvidia-docker`了.

docker的runtime都是基于`linux`内核的,因此在windows上或者macos上执行docker实际都是使用的虚拟机.这都是通过集成环境`docker desktop`实现的安装.


## 本地使用docker的工作流

单机部署docker容器的工作流大致是这样:

1. 从镜像仓库拉取需要的镜像[可选]
2. 写`docker-compose.yml`描述部署的配置
3. 执行`docker-compose`指令部署容器.

