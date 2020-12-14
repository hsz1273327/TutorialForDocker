# 单机容器编排

docker单机环境部署的例子.

使用步骤:

分别修改`docker-compose.yml`中`services->hellodocker->environment->HELLO_DOCKER_REDIS_URL`的值为:

+ `redis://db-redis?db=0`查看与其他服务连接
+ `redis://host.docker.internal:16379?db=0`windows/mac下查看与宿主机连接
+ `redis://{宿主机ip}:16379?db=0`linux下查看与宿主机连接

启动与关闭:

1. 执行`docker-compose up --build -d`构造镜像并执行编排好的服务stack.这样执行`docker logs tutorialfordocker_hellodocker_1`就可以看到服务的log了
2. 执行`docker-compose down`关闭删除服务stack.,如果要删除镜像,加上参数`--rmi`
