# 单机条件下host网络示例

docker单机环境部署的例子.

新增`build`下`extra_hosts`解决github域名污染问题

使用步骤:

**注意这个例子只能在linux下执行**

> 启动与关闭:

1. 执行`docker-compose up --build -d`构造镜像并执行编排好的服务stack.这样执行`docker logs tutorialfordocker_hellodocker_1`就可以看到服务的log了
2. 执行`docker-compose down`关闭删除服务stack.,如果要删除镜像,加上参数`--rmi`
