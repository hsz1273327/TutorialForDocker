# 使用docker-compose本地部署

作为通用的容器部署编排工具,[docker-compose](https://github.com/docker/compose)已经是docker生态下的标准工具了.虽然docker也有直接使用`docker run`命令部署服务的方式,但从便利性和可维护性角度看已经完全没有必要介绍了.

## docker-compose的安装

`docker-compose`本质上是一个python脚本程序,这个程序是`docker desktop`自带的.因此如果是window或者mac用户并不需要关心这个问题.而在linux下官方推荐的安装方式是使用如下命令

```bash
sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

同样的卸载也是简单的删除

```bash
sudo rm /usr/local/bin/docker-compose
```

注意:这种方式**只适用于`x86/64`架构的机器**,如果是在`arm`架构上部署我们必须使用`pip`安装,在使用`pip`安装前我们先要安装一个依赖`libffi-dev`,没有它`docker-compose`的安装会编译报错.

如果使用`pip`安装,则卸载也需要使用`pip`.

## docker-compose语法

`docker-compose`本质上是一种配置文件,它遵循[yaml语法](https://yaml.org/).发展到现在已经有互不兼容的3个大版本了.目前`v1`,`v2`都已经不再更新维护,还在更新的就是`v3`版本了.

目前看主流使用的是`v2`和`v3`两个版本,这两个版本的关键字和结构有较大重合,但至少暂时`v3`还无法替代`v2`版本.

+ `v2`版本虽然已经不再更新,但由于是对`docker run`命令的映射,对硬件的支持更好,所以一般单机部署都是使用的它;

+ `v3`版本主要多出了`deploly`字段用于更加细化的定义`swarm`集群部署上的行为,因此`swarm`集群上部署服务都会用它.

本章节介绍单机使用Docker.因此我会以`v2.4`版本为基础介绍`docker-compose`语法,下一章节介绍Swarm集群时我们会引入`v3`版本.本文只是一个引子,介绍基本语法和使用,一些部署和资源上的设置我们将在后面单独介绍.

一个典型的`docker-compose`配置文件使用[yaml格式](https://baike.baidu.com/item/YAML/1067697?fr=aladdin)定义.通常一个项目下会有一个`docker-compose.yml`文件,它就是这个项目的部署配置文件.一个典型的`docker-compose`配置文件如下:

```yml
version: "2.4"
services:
  webapp:
    build: ./dir
```

可以看到基本结构有3层,当然复杂的可能也有4层5层.

第一层包括`version`,`services`等,这一层一般是声明使用的语法版本,定义的服务,网络等内容以及一些通用设置;第二层通常就是具体各项的定义了,比如上面例子中`webapp`就是一个具体的服务的定义;第三层则是具体到各个项的配置,比如上面例子上`build`就是定义`webapp`这个服务的镜像编译行为.

docker-compose的语法详细的还是因该去看[官方文档](https://docs.docker.com/compose/compose-file/).

## 部署服务的基本工作流

单机模式下使用`docker-compose`部署服务的基本工作流是

1. 定义一个`docker-compose.yml`文件用于描述服务的编排.
2. 使用命令`docker-compose up`部署服务.

## 使用`docker-compose.yml`编排服务

`services`是服务配置的声明层,它可以允许配置多个不同的服务,这里也是`docker-compose`的主要配置部分.`services`下的每一个key对应的是一个服务的名字,同一个stack下不可以有重名的服务.

### 指定镜像

指定镜像一般有两种方式:

1. 使用现有的镜像

2. 使用项目下的代码构建临时镜像

#### 使用`image`指定镜像

如果是使用现有的镜像部署那么就需要用`image`申明使用的镜像.

其格式为`image: 镜像名`或者`image: 镜像名:版本标签`或`image: 镜像id`.如果指定为镜像名则默认拉取版本标签为`latest`的镜像.需要注意如果本地并没有指定的镜像那么docer会去镜像仓库拉取.

#### `build`

如果是在开发调试阶段,那每次都多一步编译创建镜像有点太过麻烦,这种时候就可以使用`build`命令在部署的时候指定编译创建镜像.其主要形式如下:

```yml
...
build:
  context: ./dir
  dockerfile: Dockerfile-alternate
  args:
    buildno: 1
...
```

`build`下面可以设置编译的配置,主要的设置项有:

+ `context`: 指定`docker build`操作执行所在的文件夹.
+ `dockerfile`: 指定`docker build`操作使用的`Dockerfile`
+ `args`: 指定`Dockerfile`执行时的参数

当然还有其他的配置项,但不常用,需要的话可以去文档里查

如果一个`service`下既有`image`又有`build`,那么会在编译创建完镜像后将`image`中指定的名字赋值给编译成的镜像.

如果要使用的`dockerfile`没有什么参数,命名就叫`Dockerfile`(忽略大小写)那么可以使用简写形式:

```yml
...
build: ./dir
...
```

## 重复的配置部分单独声明



### 编排服务间的依赖顺序

上面的例子中我们起了两个服务,这两个服务实际上是有依赖关系的--`webapp`依赖`redis`.但上面的配置中实际上是忽视这种依赖关系的.
实际上为了确保可用,应该先启动`redis`,`redis`ready了再启动`webapp`,同时如果要删除这个task应该先删除`webapp`再删除`redis`,这种依赖关系我们可以使用字段`depends_on`来进行约束.

其语法如:

```yml
depends_on:
  - a
  - b
  ...
```

> 例5:[修改例4,约束依赖关系](https://github.com/hsz1273327/TutorialForDocker/tree/helloworld-with-redis-depends_on)

```yml
version: "2.4"
  ...
    webapp:
     ...
     depends_on:
      - redis
```

## 使用`docker-compose`命令行工具部署stack

上面的部分我们已经介绍了单机部署的基本配置,后续的网络配置,编排配置,存储配置,包括swarm集群配置都是在这部分之上的扩展,接下来我们完整应用下上面的内容来实战下容器部署.

> 例子1: [部署nginx](https://github.com/hsz1273327/TutorialForDocker/tree/example-nginx)

+ `docker-compose.yml`

  ```yml
  version: "2.4"
  services:
    http_static:
      image: nginx:latest
      logging:
        driver: "json-file"
        options:
          max-size: "200k"
          max-file: "10"
      cpus: 1.0
      mem_limit: 30m
      restart: on-failure
  ```

接下来我们要部署这个配置,很简单,就是使用命令`docker-compose up`即可.

[docker-compose](https://github.com/docker/compose)是一个python的命令行工具,专门用于解析`docker-compose.yml`文件然后根据其中的配置编排部署容器.
他的详细命令介绍可以看[官方文档](https://docs.docker.com/compose/reference/overview/)

比较常用的命令是:

命令|功能说明|可选参数
---|---|---
`docker-compose up`|启动`docker-compose.yml`对应的stack|`-d`用于后台执行,`--build`用于重新编译镜像
`docker-compose down`|停掉`docker-compose.yml`对应的stack中的所有容器,并删除整个stack|`--rmi`同时删除其中用到的镜像

`docker-compose`会找到当前文件夹下的`docker-compose.yml`文件,解析并部署容器,stack的名字就是当前的文件夹名.

如果需要指定`docker-compose.yml`文件,比如一个项目会部署在多个环境,不同的环境使用不同的`docker-compose.yml`文件,那可以通过`-f`指定配置文件.


