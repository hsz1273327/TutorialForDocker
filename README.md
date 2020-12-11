# 单机容器编排

docker单机环境部署的例子.

使用步骤:

1. 执行`docker-compose up --build -d`构造镜像并执行编排好的服务stack.这样执行`docker logs tutorialfordocker_hellodocker_1`就可以看到服务的log了
2. 执行`docker-compose down`关闭删除服务stack.,如果要删除镜像,加上参数`--rmi`
