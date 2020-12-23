# 单机条件下网络性能比较

docker单机环境部署的例子.

本项目顺便构建了`iperf3:3.7`版本在arm64,armv7和amd64平台上的[镜像]()

使用步骤:

**注意这个例子只能在linux下执行**

> 启动与关闭:

1. 执行`docker-compose up --build -d`构造镜像并执行编排好的服务stack.这样执行`docker logs tutorialfordocker_hellodocker_1`就可以看到服务的log了
2. 执行`docker-compose down`关闭删除服务stack.,如果要删除镜像,加上参数`--rmi`
