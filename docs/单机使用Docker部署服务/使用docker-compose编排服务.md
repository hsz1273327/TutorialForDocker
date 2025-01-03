# 使用docker-compose本地部署

作为通用的容器部署编排工具,[docker-compose](https://github.com/docker/compose)已经是docker生态下的标准工具了.虽然docker也有直接使用`docker run`命令部署容器的方式,但从便利性和可维护性角度看已经完全没有必要介绍了.

在古早版本中docker-compose区分v2,v3版本,两版语法不兼容适用范围也不一样,现如今这两个版本都已经废弃并合并.非常优秀的一点是当前版本兼容之前的两个版本,我们几乎不需要修改迁移.

## docker-compose的安装

`docker-compose`本质上是一个python脚本程序,这个程序是`docker desktop`自带的.因此如果是window或者mac用户并不需要关心这个问题.而在linux下官方推荐的安装方式是使用如下命令

```bash
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

同样的卸载也是简单的删除

```bash
sudo rm /usr/local/bin/docker-compose
```

由于有墙,国内下载上面的链接会相当慢,可以先[翻墙下载好最新版本](https://github.com/docker/compose/releases),然后用如下命令复制到要部署的机器:

```bash
# 本地复制到待部署机
scp <docker-compose文件在本地的位置> <待部署机用户名>@<待部署机host或ip>:~/docker-compose
# 在待部署机上部署compose
ssh <待部署机用户名>@<待部署机host或ip>
sudo cp docker-compose /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```
<!-- 
```bash
sudo curl -L "https://get.daocloud.io/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
``` 
注意:这种方式**只适用于`x86/64`架构的机器**,如果是在`arm`架构上部署我们必须使用`pip`安装,在使用`pip`安装前我们先要安装一个依赖`libffi-dev`,没有它`docker-compose`的安装会编译报错.

如果使用`pip`安装,则卸载也需要使用`pip`. -->

## docker-compose语法

`docker-compose`本质上是一种配置文件,它遵循[yaml语法](https://yaml.org/).发展到现在已经有4个大版本了.目前`v1`,`v2`,`v3`都已经不再更新维护,被统一称为`Compose V1`.在`compose 1.27.0` 版本后的实现统一被成为`Compose V2`.`v2`,`v3`版本相互不兼容,而`Compose V2`兼容合并了`v2`,`v3`的语法.

目前看主流使用的是`Compose V2`而`v2`和`v3`两个版本也有不少遗留,他们分别有如下特点

+ `v2`版本,对`docker run`命令的映射,对硬件的支持更好,所以一般单机部署都是使用的它;

+ `v3`版本,主要多出了`deploly`字段用于更加细化的定义`swarm`集群部署上的行为,因此`swarm`集群上部署服务都会用它.

+ `Compose V2`,语法是`v2`和`v3`的合并,在单机或`swarm`集群部署上都可以使用.也可以认为`v2`和`v3`分别是在不同场景下`Compose V2`的方言.

本章节介绍单机使用Docker.因此我会以`v2.4`版本为基础介绍`docker-compose`语法,下一章节介绍Swarm集群时我们会引入`v3`版本语法.本文只是一个引子,介绍基本语法和使用,一些部署和资源上的设置我们将在后面单独介绍.

一个典型的`docker-compose`配置文件使用[yaml格式](https://baike.baidu.com/item/YAML/1067697?fr=aladdin)定义.一个服务栈会与一个`docker-compose.yml`文件一一对应,服务栈会根据与其对应的`docker-compose.yml`配置其中的服务,网络,挂在卷等信息.一个典型的`docker-compose`配置文件如下:

```yml
version: "2.4"
services:
  webapp:
    build: ./dir
```

可以看到基本结构有3层,当然复杂的可能也有4层5层.

第一层包括`version`,`services`等,这一层一般是声明使用的语法版本,定义的服务,网络等内容以及一些通用设置;第二层通常就是具体各项的定义了,比如上面例子中`webapp`就是一个具体的服务的定义;第三层则是具体到各个项的配置,比如上面例子上`build`就是定义`webapp`这个服务的镜像编译行为.

其中`version`仅仅是声明,`docker-compose`并不会根据申明的语法去进行不同版本的匹配,而是直接使用最新的语法规范进行解析.

docker-compose的语法详细的还是因该去看[官方文档](https://docs.docker.com/compose/compose-file/).

## 部署服务的基本工作流

单机模式下使用`docker-compose`部署服务的基本工作流是

1. 定义一个`docker-compose.yml`文件用于描述服务的编排.
2. 使用命令`docker-compose up`部署服务.

## 使用`docker-compose.yml`编排服务

在`docker-compose`编排声明中最核心的是`services`字段,也就是服务配置的声明层.它可以允许配置多个不同的服务的基本信息和部署行为.`services`下的每一个key对应的是一个服务的名字,同一个服务栈下不可以有重名的服务.

在单机模式下每个`service`对应一个容器.

本文的例子在[example-standalone-deploy](https://github.com/hsz1273327/TutorialForDocker/tree/example-standalone-deploy)

这个例子我们沿用之前`hellodocker`项目的代码依然是做一个http服务器.对这个镜像的扩展我们会贯穿整个单机部分,借助其不断的扩展来演示单机环境下的对docker的各种需求.本例中我们介绍如果使用`docker-compose`编排部署一个服务栈.

这次我们为其添加对环境变量的读取支持:

```python
REDIS_URL = os.getenv("HELLO_DOCKER_REDIS_URL") or "redis://host.docker.internal?db=0"
HOST = os.getenv("HELLO_DOCKER_HOST") or "0.0.0.0"
if port := os.getenv("HELLO_DOCKER_PORT"):
    PORT = int(port)
else:
    PORT = 5000

...

client = StrictRedis.from_url(REDIS_URL, decode_responses=True)
```

以及两个接口用于读取和设置redis中key`foo`的值,以此来确定组件间的依赖关系.

```python
@app.get("/foo")
async def getfoo(_: Request) -> HTTPResponse:
    value = await client.get('foo')
    return json({"result": value})


@app.get("/set_foo")
async def setfoo(request: Request) -> HTTPResponse:
    value = request.args.get("value", "")
    await client.set('foo', value)
    return json({"result": "ok"})
```

### 指定service使用的镜像

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
+ `extra_hosts`:指定build镜像过程中构造的临时容器的dns解析,值为键值对形式
+ `network`:指定build镜像过程中构造的临时容器使用的网络类型
+ `target`:指定dockerfile中的特定stage编译

当然还有其他的配置项,但不常用,需要的话可以去文档里查

如果一个`service`下既有`image`又有`build`,那么会在编译创建完镜像后将`image`中指定的名字赋值给编译成的镜像.

如果要使用的`dockerfile`没有什么参数,命名就叫`Dockerfile`(忽略大小写)那么可以使用简写形式:

```yml
...
build: ./dir
...
```

### 使用`environment`设置容器中的环境变量

我们可以利用`environment`字段设置容器中的环境变量,

```yaml
services:
  ...
  hellodocker:
    ...
    environment:
      HELLO_DOCKER_REDIS_URL: redis://db-redis?db=0
      HELLO_DOCKER_HOST: 0.0.0.0
      HELLO_DOCKER_PORT: 3000
    ...
```

在容器中环境变量的来源有两个:

1. 构造镜像时使用`ENV`字段引入的环境变量
2. 执行镜像时使用`docker run`命令的`-e`或者在`docker-compse`中的`environment`字段中定义的环境变量.

第二种会覆盖第一种.

通常来说docker鼓励从环境变量中读取数据作为启动配置这种方式.

### 设置容器中程序的启动命令

在指定好镜像后,如果镜像本身已经定义了`CMD`或者`ENTERYPOINT`那么容器就已经可以启动了.但很多时候我们需要指定部署的一些行为.
如果我们不想用镜像中指定的启动方式,我们可以在字段`command`中定义容器中程序的启动行为.其形式如下:

```yml
command: python app.py
```

或者

```yml
command: ["python" ,"app.py"]
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

### 为service打标签

我们可以利用`labels`为服务打标签:

```yaml
services:
  ...
  hellodocker:
    ...
    labels:
      - "hsz.hsz.image=hellodocker"
      - "hsz.hsz.desc=hello docker with get/set foo in redis"
    ...
```

docker体系下标签都是键值对形式的,用`labels`字段就可以将标签添加进service的元数据中.
因此我们使用命令`docker ps --filter "label=hsz.hsz.image=hellodocker"`就可以将这个服务过滤出来.

同样的第三方扩展也就可以利用这一特性查找服务.比如用[cAdvisor](https://github.com/google/cadvisor)做监控,用[log-pilot](https://github.com/AliyunContainerService/log-pilot)做log收集等.

### 设置服务的健康检查

一些情况下我们需要重写镜像中的健康检查以符合我们执行时设定过的参数.比如本例中由于我们修改了端口,之前在dockerfile中定义好的健康检查肯定无法使用了.这时候我们就可以在compse file中定义`healthcheck`字段来覆盖镜像中定义的健康检查项目.

```yml
services:
  ...
  hellodocker:
    ...
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/ping"]
      interval: 1m30s
      timeout: 10s
      retries: 3
      start_period: 40s
    ...
```

`test`字段定义检查的命令,注意命令必须是固定的格式,这个格式由列表的第一个元素确定:

+ 如果`test`后面的值为字符串,则这个字符串就是要执行的命令,如`"curl -f http://localhost:3000/ping || exit 1"`
+ 如果`test`后面的值为列表且以元素`"CMD"`开头,则如上面例子
+ 如果`test`后面的值为列表且以元素`"CMD-SHELL"`开头,则只有两个元素,如:`["CMD-SHELL", "curl -f http://localhost:3000/ping || exit 1"]`

其他字段就和dockerfile中定义的类似了.

如果我们使用的镜像有设定健康检查但我们希望容器不要进行健康检查,那么可以将其强制设为关闭

```yml
services:
  ...
  hellodocker:
    ...
    healthcheck:
      disable: true
    ...
```

#### 设置容器的资源限制

docker相比起直接部署的一个优势就在于可以限制使用的资源.在开发的时候可以限制好资源开发,避免出现资源占用过高后不得不拔电源重启的情况.

docker的资源限制相关的配置在`v2`版本的compose语法中在如下字段中:

| 字段               | 说明                                                                       | 数据类型                         |
| ------------------ | -------------------------------------------------------------------------- | -------------------------------- |
| `cpu_count`        | 使用几个核                                                                 | int                              |
| `cpu_percent`      | 使用cpu的多少百分比的资源(0,100)                                           | int                              |
| `cpus`             | 总共使用多少cpu资源                                                        | float                            |
| `cpu_shares`       | cpu的共享权重                                                              | int                              |
| `cpu_quota`        | 限制CPU的CFS配额,必须不小于1ms,即>= 1000                                   | int                              |
| `cpu_period`       | 限制CPU的CFS的周期范围从100ms~1s                                           | str,单位一般时ms                 |
| `cpuset`           | 允许使用的CPU集合                                                          | str,取值为`0-3`或者`0,1`这种形式 |
| `mem_limit`        | 内存限制,最小4m                                                            | str,单位可以是b,k,m,g            |
| `memswap_limit`    | 内存+交换区大小总限制                                                      | str,单位可以是b,k,m,g            |
| `mem_swappiness`   | 置容器的虚拟内存控制行为,值为`0~100`之间的整数                             | int                              |
| `mem_reservation`  | 内存的软性限制                                                             | str,单位可以是b,k,m,g            |
| `oom_kill_disable` | 当oom时不会杀死当前进程                                                    | bool                             |
| `oom_score_adj`    | 系统内存不够时,容器被杀死的优先级.负值更教不可能被杀死而正值更有可能被杀死 | int                              |

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

#### 设置容器的重启策略

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

### 设定服务下的容器数量

服务下的容器数量默认是1,我们可以通过`scale`字段告诉docker对应的服务下应该起多少个容器

```yaml
services:
  ...
  hellodocker:
    ...
    scale: 2
    ...
```

如果启动后需要修改容器数量,也可以使用`docker-compose up --scale [服务名=需要的数量]`来修改.

## 重复的配置部分使用锚点单独声明

YAML格式允许使用锚点预先定义好内容,然后再在别处引用锚点用于复用配置.这一点也可以用在`docker-compose`上用来降低配置的代码量.

例子中我们展示了批量配置docker的log行为的方法:

```yaml
...
x-log: &default-log
    options:
      max-size: "10m"
      max-file: "3"

services:
  db-redis:
    ...
    logging:
      <<: *default-log
    ...

  hellodocker:
    ...
    logging:
      <<: *default-log
    ...

```

我们只需要写一次log设置,就可以在每个service中引用.我想也是因为yaml格式这项语法`docker-compose`才会选它而不是json来作为配置文件格式.

### 编排服务间的依赖顺序

上面的例子中我们起了两个服务,这两个服务实际上是有依赖关系的--`webapp`依赖`redis`.但上面的配置中实际上是忽视这种依赖关系的.
实际上为了确保可用,应该先启动`redis`,`redis`ready了再启动`webapp`,同时如果要删除这个task应该先删除`webapp`再删除`db-redis`,这种依赖关系我们可以使用字段`depends_on`来进行约束.

其语法如:

```yml
services:
  ...
  hellodocker:
    ...
    depends_on:
      - db-redis
    ...
```

我们还可以进一步设置`depends_on`的条件.支持的条件有两个:`service_started`(服务启动完成,默认)和`service_healthy`(服务健康检测通过)

```yml
services:
  ...
  hellodocker:
    ...
    depends_on:
      db-redis:
        condition: service_started
    ...
```

一般来说程序是有启动时间的,`service_healthy`相对会比`service_started`更加准确一些,但如果服务没有定义健康检查或者健康检查因为设置不合理而长期未通过,那么可能就会等待相当长的时间.因此另一种方式是借助脚本比如[wait-for-it](https://github.com/vishnubob/wait-for-it)在容器中检验端口是否已经可以访问.

+ `dockerfile`

  ```dockerfile
  ...
  RUN wget https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh -O /code/wait-for-it.sh
  RUN chmod +x /code/wait-for-it.sh
  ...
  ```

+ `docker-compose.yml`

  ```yml
  services:
    ...
    hellodocker:
      ...
      command: ["./wait-for-it.sh", "db-redis:6379", "--", "python", "app.py"]
      ...
  ```

上面各个部分设置好后,我们可以得到如下的compose file:

```yml
version: "2.4"

x-log: &default-log
  options:
    max-size: "10m"
    max-file: "3"

services:
  db-redis:
    image: redis
    logging:
      <<: *default-log

  hellodocker:
    build:
      context: ./server
      dockerfile: Dockerfile
    image: hsz1273327/hellodocker:0.0.1
    environment:
      HELLO_DOCKER_REDIS_URL: redis://db-redis?db=0
      HELLO_DOCKER_HOST: 0.0.0.0
      HELLO_DOCKER_PORT: 3000
    labels:
      - "hsz.hsz.image=hellodocker"
      - "hsz.hsz.desc=hello docker with get/set foo in redis"
    command: ["python" ,"app.py"]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/ping"]
      interval: 1m30s
      timeout: 10s
      retries: 3
      start_period: 40s
    cpus: 0.8
    mem_limit: 100m
    memswap_limit: 200m
    restart: on-failure
    scale: 2
    depends_on:
      - db-redis
    logging:
      <<: *default-log

```

## 使用`docker-compose`命令行工具部署服务栈

接下来我们要部署这个配置,很简单,就是使用命令`docker-compose up`即可.

[docker-compose](https://github.com/docker/compose)是一个python的命令行工具,专门用于解析`docker-compose.yml`文件然后根据其中的配置编排部署容器.
他的详细命令介绍可以看[官方文档](https://docs.docker.com/compose/reference/overview/)

比较常用的命令是:

| 命令                  | 功能说明                                                          | 可选参数                                      |
| --------------------- | ----------------------------------------------------------------- | --------------------------------------------- |
| `docker-compose up`   | 启动`docker-compose.yml`对应的服务栈                              | `-d`用于后台执行,`--build`用于重新编译镜像,`` |
| `docker-compose down` | 停掉`docker-compose.yml`对应的服务栈中的所有容器,并删除整个服务栈 | `--rmi`同时删除其中用到的镜像                 |

`docker-compose`会找到当前文件夹下的`docker-compose.yml`文件,解析并部署容器,服务栈的名字就是当前的文件夹名.

而同一个服务栈下的服务会有一个与服务栈名相同的共同前缀.而同一服务下的容器则会有一个以服务名为前缀的名字,后缀则是一个数字.比如我们的服务栈名为`A`,那么其下的服务`B`的完整名字为`A_B`,比如我们在`B`下启动了2个容器,则服务`B`下的容器名字则是`A_B_1`和`A_B_2`

知道这一规则这样我们就可以一目了然的知道容器的归属了.

如果需要指定`docker-compose.yml`文件,比如一个项目会部署在多个环境,不同的环境使用不同的`docker-compose.yml`文件,那可以通过`-f`指定配置文件.同时我们也可以使用`-p`为服务栈指定名字,如果不指定则默认为执行命令时的文件夹名.

不过要注意,这个`-f`和`-p`是`docker-compose`的参数,不是`docker-compose up`的参数,因此需要在`up`之前写好

## 管理服务栈

单机条件下管理容器可以分为:

+ 使用`docker-compose`命令粗颗粒度的批量管理服务栈中的服务和容器.

| 命令                                       | 常用额外参数                                                                            | 说明                                      |
| ------------------------------------------ | --------------------------------------------------------------------------------------- | ----------------------------------------- |
| `docker-compose up`                        | `-d`后台执行</br>`--build`强制重build镜像</br>`--force-recreate`强制重新创建服务栈</br> | 如果服务栈未创建则创建,创建了则更新后重启 |
| `docker-compose up --scale  <service=num>` | ---                                                                                     | 扩展服务下的容器个数.                     |
| `docker-compose images`                    | ---                                                                                     | 列出用到的镜像                            |
| `docker-compose  ps`                       | ---                                                                                     | 查看服务栈下的容器列表                    |
| `docker-compose top`                       | ---                                                                                     | 批量查看服务栈下容器运行状况信息          |
| `docker-compose  port`                     | ---                                                                                     | 列出服务栈中指定服务开放的端口            |
| `docker-compose  logs`                     | ---                                                                                     | 查看服务栈中的log输出                     |
| `docker-compose  pause`                    | ---                                                                                     | 暂停服务栈中的服务                        |
| `docker-compose  restart`                  | ---                                                                                     | 重启服务栈下的容器                        |
| `docker-compose rm`                        | ---                                                                                     | 删除停止了的容器                          |
| `docker-compose start`                     | ---                                                                                     | 批量启动容器                              |
| `docker-compose stop`                      | ---                                                                                     | 批量停止容器                              |

+ 使用细颗粒度的管理特定容器两种.相关的操作主要使用`docker`命令.大致可以总结为如下:

| 命令                                               | 常用额外参数                                                                                                                                                                | 说明                                        |
| -------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| `docker run [options]{imagesname}[:tag]`           | `--restart={flag}`:设定镜像重启等级</br>`--name {name}`:为镜像取个名</br>`-d`:守护进程启动 </br>`-it`:即交互模式,启动shell允许输入</br>`-p`:设定host和端口</br>`-v`:设定宿主机挂载卷</br>`-rm`:容器退出后自动删除容器| 由镜像创建容器                              |
| `docker ps [option]`                               | 查看当前运行的镜像列表</br>`-a`:全部镜像</br>`-l`:最近启动的镜像                                                                                                            | 查看定义了的容器                            |
| `docker inspect {name\|cid}`                        | ---                                                                                                                                                                         | 查看单个容器属性                            |
| `docker exec [option] {name\|cid} COMMAND [ARG...]` | `-i`:保持`stdin`打开</br>`-t`:分配一个tty</br>                                                                                                                              | 在运行中的指定容器中执行命令                |
| `docker logs [option] {name\|cid}`                  | `--tail {n}`:查看末尾的n行                                                                                                                                                  | 查看容器的log信息                           |
| `docker stats`                                     | ---                                                                                                                                                                         | 查看所有执行中的容器的状态,包括资源占用情况 |
| `docker start {name\|cid}`                          | ---                                                                                                                                                                         | 启动容器                                    |
| `docker restart {name\|cid}`                        | ---                                                                                                                                                                         | 重启镜像                                    |
| `docker attach {name\|cid}`                         | ---                                                                                                                                                                         | 附着到正在运行中的容器上实现会话            |
| `docker stop {name\|cid}`                           | ---                                                                                                                                                                         | 停止镜像                                    |

除此之外我们也可以使用第三方工具[ctop](https://github.com/bcicen/ctop)来更方便的查看运行中的容器状态.它可以监控容器的资源占用.直接执行`ctop`就可以得到更加可读的当前执行中容器的状态了.

+ 删除已经停止的镜像

容器停止后不会自己消失,我们需要手动指定删除--`docker rm {name\|cid}`.如果要批量删除我们可以使用`docker container prune -f`命令
