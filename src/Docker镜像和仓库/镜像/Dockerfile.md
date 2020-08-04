# Dockerfile

所谓Dockerfile其实是指名为Dockerfile的定义文件,它用来定义镜像的构建过程,类似专门做镜像的makefile.它的语法大约如下:

```Dockerfile
动作(指令) + shell命令
```
其中动作为Dockerfile的关键字,为大写,而后面的shell指令就是一般在shell中使用的指令

而以`#`开头的语句都是注释

它的操作其实可以理解成逐行执行动作后commit当前的容器.这种方式的好处是如果有哪条指令出错了也不用从头开始.

Dockerfile的通用格式是:

```Dockerfile
# Version: x.x.x
FROM <baseimg>:<tag>
MAINTAINER <author> "<email>"
RUN <cmd>
.
.
.
EXPOSE <port>
```

其中:
+ FROM :指定基镜像
+ MAINTAIER :指定作者信息
+ RUN :默认用`/bin/sh -c`来执行后面的命令
+ EXPOSE :指定向外公开的端口

> 基于centos镜像用Dockerfile创建一个Nginx静态服务镜像

我们从头开始创建一个新的镜像,基镜像是daocloud的centos镜像,墙外的小朋友们可以用官方的那是最好的.

Dockerfile:

```Dockerfile
# Version: 0.0.1
FROM daocloud.io/centos:latest
MAINTAINER hsz "hsz1273327@gmail.com"
RUN yum update
ADD nginx.repo /etc/yum.repos.d/nginx.repo
RUN yum install -y nginx
RUN echo "done!" > /usr/share/nginx/html/index.html
EXPOSE 80
```
nginx.repo:
```
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/7/$basearch/
gpgcheck=0
enabled=1
```
上面我们用了ADD这个额外的命令来将宿主机上的文件添加到镜像的指定位置.

## 用Dockerfile构建镜像

这个用到`build`命令它的用法是这样:

到有Dockerfile的文件夹下使用

```shell
docker build -t=<toImage Name> <path>"
```

或者如果有基于dockerfile的项目在github或者git仓库上,也可以在本地没有dockerfile的情况下在这条命令后面path替换成git仓库中项目下Dockerfile所在位置


## 启动我们的静态服务

```shell
docker run -d -p 80 --name static_web hsz/static_web:v1 \
nginx -g "daemon off;"
```
这条命令意思是:

+ -d :分离模式,适合运行守护进程这种长时间运行的服务
+ -p : 指定公开给外部网络(宿主机)的端口号

    docker可以用两种方式在主机上分配端口:

    + 宿主机上随机选择一个49000~49900的端口来映射到80端口
    + 指定一个具体端口连接到80端口

    这条命令是第一种情况,使用`docker ps`来查看端口情况

```shell
CONTAINER ID        IMAGE                                        COMMAND                  CREATED             STATUS              PORTS                     NAMES
a8c4b60ca5bc        hsz/static_web:v2                            "nginx -g 'daemon off"   7 minutes ago       Up 7 minutes        0.0.0.0:32770->80/tcp     static_web
```
可见容器的80端口被映射到了宿主机的32770端口
如果想要指定到宿主机的某个端口,那么-p后面的参数需要写成`8080:80`这样,这样就绑定到了宿主机的8080端口
更进一步,我们可以写成`-p 127.0.0.1:8080:80`,这样就绑定了ip了

更加简单的方式是使用`-P`参数,这个参数将会把容器用EXPOSE 公开的端口绑定到宿主机随机端口

需要注意的是mac下因为宿主机是虚拟机,所以访问并不能用localhost:<port>的形式,而是必须使用进入时候虚拟机的ip地址.

## Dockerfile指令汇总

指令|说明
---|---
FROM|选择基镜像
MAINTAINER|设定作者和作者有邮箱
RUN|运行bash命令
EXPOSE|设定外露端口
CMD|类似RUN,指定容器启动时运行的命令
ENTRYPOINT|类似CMD,但不会被docker run命令覆盖
WORKDIR|设定一个工作目录,类似cd的作用
ENV|设定环境变量
USER|以什么用户身份运行
VOLUME|添加卷
ADD|将构建环境下的文件和目录复制到镜像中
COPY|类似ADD,但不会做文件提取和解压
ONBUILD|触发器,当一个镜像被用作其他镜像的基础镜像的时候会触发运行


## 挂载卷(VOLUME)

所谓的挂载卷是指将宿主机的指定目录映射为镜像中的指定位置,这样即便镜像停止了数据也不会丢失,是非常实用的技巧.
这个在后面的构建测试环境和构建服务的部分会详细讨论

## 删除镜像

有时候我希望删除一些镜像,这时候可以使用

```shell
docker rmi <img>
```
