# docker-compose

作为通用的容器部署编排工具,`docker-compose`已经是docker生态下的标准工具了.虽然docker也有直接使用`docker run`命令部署服务的方式,但从便利性和可维护性角度看已经完全没有必要介绍了.

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

一个典型的`docker-compose`配置文件使用[yaml格式](https://baike.baidu.com/item/YAML/1067697?fr=aladdin)定义.通常一个项目下会有一个`docker-compose.yml`文件,它就是这个项目的部署配置文件.一个典型的`docker-compose`配置文件如下:

```yml
version: "3.8"
services:
  webapp:
    build: ./dir
```
可以看到基本结构也是3层,当然复杂的可能也有4层.

第一层包括`version`,`services`等,这一层一般是声明使用的语法版本,定义的服务,网络等内容;第二层通常就是具体各项的定义了,比如上面例子中`webapp`就是一个具体的服务的定义;第三层则是具体到各个项的配置,比如上面例子上`build`就是定义`webapp`这个服务的镜像编译行为.

docker-compose的语法详细的还是因该去看[官方文档](https://docs.docker.com/compose/compose-file/).下面介绍的是在单机环境下常用的配置项.

## docker-compose语法版本

`version`字段用于声明`docker-compose`解析的语法版本,目前看主要是两种即`v2`版本和`v3`版本.这两个版本大同小异,但侧重点不同--`v2`版本主要偏向于单机部署,`v3`版本主要偏向于`swarm`集群部署.目前的趋势是`v3`版本用的人越来越多,`v2`版本用的人越来越少,但`v2`版本却有许多功能`v3`版本不支持或者不原生支持.`v2`版本的最高版本号是`2.4`,且已经不再更新.

本文以`v2.4`版本为基础介绍`docker-compose`语法.

## 服务配置

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

### 指定部署行为

在指定好镜像后,如果镜像本身已经定义了`CMD`或者`ENTERYPOINT`那么容器就已经可以启动了.但很多时候我们需要指定部署的一些行为.
不考虑利用外部资源的情况下主要包括:

+ 资源限制
+ 重启策略
+ 传入参数
+ 启动服务
+ 服务标签
+ log收集

#### 资源限制

docker相比起直接部署的一个优势就在于可以限制使用的资源.在开发的时候可以限制好资源开发,避免出现资源占用过高后不得不拔电源重启的情况.

docker的资源限制相关的配置在`v2`版本的compose语法中在如下字段中:

字段|说明|数据类型
---|---|---
`cpu_count`|使用几个核|int
`cpu_percent`|使用cpu的多少百分比的资源(0,100)|int
`cpus`|总共使用多少cpu资源|float
`cpu_shares`|cpu的共享权重|int
`cpu_quota`|限制CPU的CFS配额,必须不小于1ms,即>= 1000|int
`cpu_period`|限制CPU的CFS的周期范围从100ms~1s|str,单位一般时ms
`cpuset`|允许使用的CPU集合|str,取值为`0-3`或者`0,1`这种形式
`mem_limit`|内存限制,最小4m|str,单位可以是b,k,m,g
`memswap_limit`|内存+交换区大小总限制|str,单位可以是b,k,m,g
`mem_swappiness`|置容器的虚拟内存控制行为,值为`0~100`之间的整数|int
`mem_reservation`|内存的软性限制|str,单位可以是b,k,m,g
`oom_kill_disable`|当oom时不会杀死当前进程|bool
`oom_score_adj`|系统内存不够时,容器被杀死的优先级.负值更教不可能被杀死而正值更有可能被杀死|int

```yml
...
cpu_percent: 50
cpus: 0.5
cpu_shares: 73
cpu_quota: 50000
cpu_period: 20ms
cpuset: 0,1
...
```

如果服务或容器尝试使用的内存超过系统可用的内存,则可能会遇到内存不足异常(俗称oom),docker内核会杀掉容器进程或者Docker守护程序.为防止这种情况发生,应该确保应用程序在具有足够内存的主机上运行.

docker一般推荐一个容器只起一个进程,这样在杀死进程的时候可以避免僵尸进程.

#### 重启策略

docker的另一个优势就是可以自动重启,这对于一些需要开机自启动的程序相当友好.

docker的重启策略相关的配置在在`v2`版本的compose语法中通过`restart`字段规定.其形式如下:

```yml
...
restart: on-failure
...
```

其中取值范围可以有4种:

+ `on-failure`只在启动失败时重启
+ `any`,在任何情况下重启(默认值)
+ `none`,在任何情况下都不重启
+ `unless-stopped`除了正常停止以外都会重启

### 传入参数

在docker下一般推荐使用环境变量来传入参数,我们可以使用字段`environment`来指定要传入参数的键值对.其形式如下:


```yml
environment:
    ENV: development
    SHOW: 'true'
    SESSION_SECRET: 'a secret'
```

或者

```yml
environment:
  - ENV=development
  - SHOW=true
  - SESSION_SECRET='a secret'
```

需要注意`environment`字段相当于在容器中设置环境变量,这个操作是在创建容器时执行的,它无法影响镜像的编译过程.


### 启动服务

如果我们不想用镜像中指定的启动方式,我们可以在字段`command`中定义容器中程序的启动行为.其形式如下:

```yml
command: python3 manage.py runserver 0.0.0.0:8000
```

或者

```yml
command: ["python3","manage.py","runserver","0.0.0.0:8000"]
```

如果要执行多行,则可以这样写:

```yml
command:
    - sh
    - -c 
    - |
        cmd1
        cmd2
        cmd3
```

### 服务标签

服务标签并不会影响服务的运行,它是一个关于该服务的元数据,一些框架会使用服务的标签做一些文章.其形式为:

```yml

labels:
  com.example.description: "Accounting webapp"
  com.example.department: "Finance"
  com.example.label-with-empty-value: ""
```

### log收集.

docker中容器打出的log都会被docker收集,关于log收集一块的配置在关键字`logging`部分定义,其形式如下:

```yml
logging:
  driver: "json-file"
  options:
    max-size: "200k"
    max-file: "10"
```

通常我们都是使用的如上面的配置方式,它规定了该服务的log的形式时jsonfile,同时单log文件大小最大为200k,最多会存在10个log文件.

关于docker下的log收集时另一个话题,我们会在介绍完`swarm`后专门介绍.

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

## 存储配置

上面的例子我们部署nginx只是让它跑起来而已,我们知道nginx是一个静态http服务器,那如果我们希望它可以部署我们的静态页面,那就需要它可以访问我们宿主机上的文件系统.

在`docker-compose.yml`中可以通过挂载文件系统来让容器和宿主机互通文件.

### 存储映射宿主机上的文件系统

最简单的办法是直接映射宿主机上的文件系统,这个我们可以直接在`services`中定义映射,其形式为:

```yml
...
services:
  http_static:
    ...
    volumes:
      - "本地路径:容器中路径"
    ...
...
```

需要注意,在window下默认是无法挂载宿主机磁盘的,要支持这个功能需要进入`docker desktop`的设置中修改设置,设置路径为`Settings->Docker Engine`,在其中的json格式的配置中修改`"experimental"`项为`true`即可.

>例2: [为nginx挂载本地文件系统获取静态html文件](https://github.com/hsz1273327/TutorialForDocker/tree/example-nginx-volumes)

我们在项目目录下新建一个文件夹`static`,其中放上一个html文件

+ `index.html`

```html
<h1>hello</h1>
```

然后修改`docker-compose.yml`文件,为其加上挂载文件系统的配置.
+ `docker-compose.yml`

```yml
version: "2.4"
services:
  http_static:
    ...
    volumes: 
      - "./static:/usr/share/nginx/html"
    ...
```

## 网络配置

上面的例子中我们部署了一个nginx,nginx是一个静态http服务器和网络代理中间件,如果按上面的方式部署我们肯定是无法使用它的,因为很明显容器既无法让外部访问到,也无法访问外部的环境.

docker中网络配置是专门的一块.本文是介绍单机上docker部署的,因此这部分也只介绍单机条件下的网络配置.

单机条件下可用的网络驱动有两种:`host`也就是完全映射宿主机的网络,`bridge`也就是桥接网络.

### host网络

单机下最方便的就是使用`host`网络,它会像在本地开发一样的和宿主机共享网络端口,其配置方法就是在`service`中使用`network_mode`声明使用`host`网络:

```yml
network_mode: "host"
```

当然这种方式也是相当危险的,它无异于将本机的所有端口暴露给了容器,如果是不熟悉来源的容器建议不要使用这种方式.
需要注意由于docker desktop的实现问题,在windows和mac下这个方式并不会起任何效果,也就是说只在linux下会生效.由于多数人还是在windows/mac下做开发,因此这种方式其实实用性不高.

### bridge网络

`bridge`网络相对就安全许多.`bridge`网络是单机模式下的默认网络驱动,它无法直接访问宿主机的端口,而要让容器外部访问到容器内的端口也需要使用`ports`字段声明,其形式为:

```yml
ports:
  - 3000:3000
```

其中冒号左侧的是映射到宿主机的端口,右侧的则是要映射的容器中的端口.

> 例3: [将nginx中的80端口映射到宿主机的8080端口](https://github.com/hsz1273327/TutorialForDocker/tree/example-nginx-ports)

```yml
version: "2.4"
services:
  http_static:
    ...
    ports: 
      - "8080:80"
    ...
```

相对应的另一种需求是我们希望容器可以访问宿主机上的服务.

+ 如果是windows或者mac平台使用的`docker desktop运行的docker服务`,那么可以在容器种使用`host.docker.internal`作为hostname代表宿主机.
+ 如果是linux下直接安装的docker,则可以直接使用本机的内网ip作为hostname在容器种使用.

> 例4: [使用`bridge`网络部署sanic应用,并连接本地的redis(windows或mac下)](https://github.com/hsz1273327/TutorialForDocker/tree/helloworld-with-redis)

这里例子我们要起两个服务,一个是sanic的http服务(helloworld例子的扩展),一个是redis.我们的sanic需要访问redis的`foo`这个key,为其设置值和取值.

+ `app.py`

  ```python
  from sanic.response import json
  from sanic import Sanic
  from aredis import StrictRedis
  import os
  redis_url = os.environ.get(f"REDIS_URL") or "redis://localhost:6379"
  app = Sanic("hello_example")
  client = StrictRedis.from_url(redis_url,decode_responses=True)

  @app.get("/")
  async def test(request):
      return json({"hello": "world"})

  @app.get("/set_foo/<value:string>")
  async def set(request,value):
      await client.set('foo', value)
      return json({"result": "ok"})

  @app.get("/get_foo")
  async def get(request):
      res = await client.get('foo')
      return json({"result":res})

  if __name__ == "__main__":
      print(f"redis_url: {redis_url}")
      app.run(host="0.0.0.0", port=5000)
  ```

+ `docker-compose.yml`

  ```yml
  version: "2.4"
  services:
    redis: 
      image: redis:latest
      ports:
        - "5379:6379"
    webapp:
      build: ./
      logging:
        driver: "json-file"
        options:
          max-size: "200k"
          max-file: "10"
      ports:
        - "5000:5000"
      environment: 
        REDIS_URL: "redis://host.docker.internal:5379"
      cpus: 1.0
      mem_limit: 30m
      restart: on-failure
  ```

我们在`app.py`的代码中通过获取环境变量`REDIS_URL`来这是连接的redis的路径.在`docker-compose.yml`中我们则是通过`environment`字段来设置环境变量`REDIS_URL`的值.

我们使用`host.docker.internal`指代宿主机的hostname,这样就可以访问到redis了.

### 服务间的依赖顺序

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

### 使用bridge网络联通服务

实际上我们只要访问`webapp`,并不关心它是存在哪个redis里,更加不会没事取访问它依赖的那个redis.类似的情况很多,况且暴露越多的端口也越危险.

`bridge`网络无法访问宿主机的端口,因此常见的用法是将依赖的服务放到同一个stack,在同一个stack下会默认创建一个网络,同一个stack中的service都可以使用service的名字作为hostname相互访问.

> 例6: [上例stack中的redis不再暴露给外网]()

```yml
version: "2.4"
services:
  redis: 
    image: redis:latest
  webapp:
    ...
    environment: 
      REDIS_URL: "redis://redis:6379"
    ...
```
我们只需要将redis暴露的端口去掉,并且使用`redis`作为redis连接的hostname.