# 开发一个koa的简单应用

接着我们使用koa构建一个简单的动态web应用

首先依然是构建镜像用的Dockerfile:

这个项目其实要拆解成2个部分:

+ node.js镜像

Dockerfile:
```Dockerfile
# Version: 0.0.1
FROM centos:latest
MAINTAINER hsz "hsz1273327@gmail.com"
RUN yum update
ADD node-v4.4.5-linux-x64.tar.xz node4
RUN mkdir -p /opt/webapp
EXPOSE 3001
ENV PATH $PATH:/node4/node-v4.4.5-linux-x64/bin
WORKDIR /opt/webapp
CMD ["npm","run","app-dev"]
```

构建镜像:

`docker build -t=hsz/node_web:nodeapp .`

构建容器:
`docker run -d -p 3001 --name nodeapp -v $PWD/app:/opt/webapp hsz/node_web:nodeapp`

部署的代码就放在目录的app文件夹下,并挂载在容器的/opt/webapp目录下,该项目代码在在示例代码中,
因为使用了nodemon,所以我们可以修改内容,报错后app会自己重启.

+ redis镜像

上一个版本中我们只是单纯的使用了node渲染模板而已,这显然不是真正可以实用的webapp,接着让我们为它加入对数据库的支持.
在改写上面的代码之前,我们先新建一个redis服务器的镜像

Dockerfile:
```Dockerfile
# Version: 0.0.1
FROM centos:latest
MAINTAINER hsz "hsz1273327@gmail.com"
RUN yum update
ADD node-v4.4.5-linux-x64.tar.xz node4
RUN mkdir -p /opt/webapp
EXPOSE 3001
ENV PATH $PATH:/node4/node-v4.4.5-linux-x64/bin
WORKDIR /opt/webapp
CMD ["npm","run","app-dev"]
```
