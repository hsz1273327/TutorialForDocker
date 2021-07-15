# 单机条件下挂载usb摄像头

docker单机环境部署的例子.

使用步骤:

**注意这个例子需要机器上有安装usb摄像头**

> 启动与关闭:

1. 执行`docker-compose up -d`构造镜像并执行编排好的服务stack.这样执行`docker logs tutorialfordocker_hello-video_1`就可以看到服务的log了,log中可以看到`video0`
2. 执行`docker-compose down`关闭删除服务stack.,如果要删除镜像,加上参数`--rmi`
