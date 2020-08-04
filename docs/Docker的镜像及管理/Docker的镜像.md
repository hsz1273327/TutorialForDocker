# Docker的镜像


## Docker镜像的原理

docker的镜像是底层由引导文件系统(bootfs),上层由文件系统叠加而成的,的一种虚拟化文件系统.

它的结构如图:

![docker镜像的结构](imgs/docker-filesystems-multilayer.png)

正如图上所画,其实镜像的最顶层就是容器(可写容器),而镜像是一层一层叠加上去的,最下面的镜像就是基础镜像,我们用的ubuntu,其实只是ubuntu的最小安装而已,然后叠一层vim再叠一层啥的.

### 写时复制

当docker第一次启动容器时,时间上读写层是空的,当文件系统发生变化时这些变化都会应用到这一层,它会从只读层将要改的文件复制到读写层,然后所有修改都在读写层而不会影响只读层而只读层的文件将在使用时代替读写层的对应文件.这种机制便是写时复制,利用这一机制我们可以快速构建镜像并运行包含我们自己应用的容器.



## 构建镜像

一般我们构建镜像都是基于一个基镜像的,我们的那ubuntu作为基镜像,那么在其之上我们怎么构建镜像呢?有两种方式:

+ `commit`命令
+ `build`命令+`Dockerfile`文件

官方的推荐用法是使用`Dockerfile`,本文也只会介绍这种方法,`commit`命令这种方式我在工作中从未见过有人使用.

### Dockerfile的基本形式

所谓`Dockerfile`其实是指名为`Dockerfile`的定义文件,它用来描述镜像的构建过程,类似专门做镜像的makefile.它的语法大约如下:

```Dockerfile
动作(指令) + shell命令
```
其中动作为`Dockerfile`的关键字,为大写,而后面的shell指令就是一般在shell中使用的指令

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
.
.
.
```

其中:
+ FROM :指定基镜像
+ MAINTAIER :指定作者信息
+ RUN :默认用`/bin/sh -c`来执行后面的命令
+ EXPOSE :指定向外公开的端口


### Dockerfile支持的指令汇总

指令|说明
---|---
`FROM`|选择基镜像
`MAINTAINER`|设定作者和作者有邮箱
`WORKDIR`|设定一个工作目录,类似cd的作用
`ENV`|设定环境变量
`USER`|以什么用户身份运行
`ADD`|将构建环境下的文件和目录复制到镜像中
`COPY`|类似ADD,但不会做文件提取和解压
`RUN`|运行bash命令
`EXPOSE`|设定外露端口
`CMD`|类似RUN,指定容器启动时运行的命令
`ENTRYPOINT`|类似CMD,但不会被`docker run`命令覆盖
`VOLUME`|为添加卷增加挂载点
`ARG`|声明编译构造镜像时使用的参数,其形式为`ARG <name>[=<default value>]`,在编译时使用`--build-arg <key>=<value>`来传入参数
`ONBUILD`|触发器,当一个镜像被用作其他镜像的基础镜像的时候会触发运行
`LABEL`|用于为构建好的镜像标识一些元信息,编译出镜像后可以使用`docker image inspect --format='' 镜像id`来查看
`STOPSIGNAL`|允许用户自定义应用在收到`docker stop`所发送的信号
`HEALTHCHECK`|设定健康检测规则


### 为镜像指定标签

### 将镜像上传至镜像仓库

## 镜像管理

### 查找镜像

### 查看镜像属性

### 删除镜像

有时候我希望删除一些镜像,这时候可以使用

```shell
docker rmi <img>
```
#### 批量删除无用标签镜像