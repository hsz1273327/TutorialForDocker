# Docker的镜像

Docker的镜像比较类似于虚拟机中的镜像,它是系统状态的序列化保存.所有镜像都是通过一个64位十六进制字符串(内部是一个256bit的值)来标识的. 为简化使用,前12个字符可以组成一个短ID可以在命令行中使用.短ID还是有一定的碰撞机率,所以服务器总是返回长ID.

## Docker镜像的原理

docker的镜像是底层由引导文件系统(bootfs),上层由文件系统叠加而成的,的一种虚拟化文件系统.

它的结构如图:

![docker镜像的结构](../IMGS/docker-filesystems-multilayer.png)

正如图上所画,其实镜像的最顶层就是容器(可写容器),而镜像是一层一层叠加上去的,最下面的镜像就是基础镜像,我们用的ubuntu,其实只是ubuntu的最小安装而已,然后叠一层vim再叠一层啥的.

### 写时复制

当docker第一次启动容器时,时间上读写层是空的,当文件系统发生变化时这些变化都会应用到这一层,它会从只读层将要改的文件复制到读写层,然后所有修改都在读写层而不会影响只读层而只读层的文件将在使用时代替读写层的对应文件.这种机制便是写时复制,利用这一机制我们可以快速构建镜像并运行包含我们自己应用的容器.

## OCI中的`image spec`

Docker的镜像满足OCI中的`image spec`,因此即便我们不使用docker的docker的镜像,只要runtime满足OCI中的接口定义那就可以使用docker构造的镜像.

比如k8s现在已经完全弃用docker服务了,但因为其使用的运行时还是满足OCI中定义的接口,因此k8s依然可以使用docker构造的镜像.

OCI容器镜像主要包括几块内容：

+ 文件系统:以`layer`保存的文件系统,每个`layer`保存了和上层之间变化的部分,`layer`应该保存哪些文件,怎么表示增加,修改和删除的文件等.
+ `config`文件:保存了文件系统的层级信息(每个层级的hash值,以及历史信息),以及容器运行时需要的一些信息(比如环境变量,工作目录,命令参数,mount列表等),指定了镜像在某个特定平台和系统的配置.比较接近我们使用`docker inspect <image_id>`看到的内容.
+ `manifest`文件:镜像的`config`文件索引,有哪些`layer`，额外的`annotation`信息,`manifest`文件中保存了很多和当前平台有关的信息.
+ `index`文件:可选的文件,指向不同平台的`manifest文件`,这个文件能保证一个镜像可以跨平台使用,每个平台拥有不同的`manifest`文件,使用index作为索引.

## 构建镜像的基本工作流

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
FROM [--platform=xxxx] <baseimg>:<tag>
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

+ `FROM`:指定基镜像
+ `MAINTAIER`:指定作者信息
+ `RUN`:默认用`/bin/sh -c`来执行后面的命令
+ `EXPOSE`:指定向外公开的端口

### Dockerfile支持的指令汇总

| 指令          | 说明                                                                                                                  |
| ------------- | --------------------------------------------------------------------------------------------------------------------- |
| `FROM`        | 选择基镜像                                                                                                            |
| `MAINTAINER`  | 设定作者和作者有邮箱                                                                                                  |
| `WORKDIR`     | 设定一个工作目录,类似cd的作用                                                                                         |
| `ENV`         | 设定环境变量                                                                                                          |
| `USER`        | 以什么用户身份运行                                                                                                    |
| `ADD`         | 将构建环境下的文件和目录复制到镜像中                                                                                  |
| `COPY`        | 类似ADD,但不会做文件提取和解压,注意`COPY`的目标都是目录而非文件                                                       |
| `RUN`         | 运行bash命令                                                                                                          |
| `EXPOSE`      | 设定外露端口                                                                                                          |
| `CMD`         | 类似RUN,指定容器启动时运行的命令                                                                                      |
| `ENTRYPOINT`  | 类似CMD,但不会被`docker run`命令覆盖                                                                                  |
| `VOLUME`      | 为添加卷增加挂载点                                                                                                    |
| `ARG`         | 声明编译构造镜像时使用的参数,其形式为`ARG <name>[=<default value>]`,在编译时使用`--build-arg <key>=<value>`来传入参数 |
| `ONBUILD`     | 触发器,当一个镜像被用作其他镜像的基础镜像的时候会触发运行                                                             |
| `LABEL`       | 用于为构建好的镜像标识一些元信息,编译出镜像后可以使用`docker image inspect --format='' 镜像id`来查看                  |
| `STOPSIGNAL`  | 允许用户自定义应用在收到`docker stop`所发送的信号                                                                     |
| `HEALTHCHECK` | 设定健康检测规则.                                                                                                     |

### ADD与COPY

上面的汇总中可以看到两个功能非常相近的指令:`ADD`和`COPY`,我们可以理解为`ADD`是扩展版的`COPY`下面是不同情况下行为的矩阵

| 示例                                       | 源路径(本地) | 目标路径(容器) | `ADD`指令的行为                                                                                                                           | `COPY`指令的行为               |
| ------------------------------------------ | ------------ | -------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ |
| `[CMD] test1.txt test1`                    | 文件         | 不存在的文件   | 将源路径指定的文件复制到目标路径                                                                                                          | 同`ADD`                        |
| `[CMD] test1.txt test1`                    | 文件         | 已存在的文件   | 将源路径指定的文件复制到目标路径并覆盖原有文件内容                                                                                        | 同`ADD`                        |
| `[CMD] test1.txt test1`                    | 文件         | 已存在的目录   | 将源路径指定的文件复制到目标路径指定的目录中(不推荐这样写避免混淆)                                                                        | 同`ADD`                        |
| `[CMD] test1.txt test1/`                   | 文件         | 不存在的目录   | `/`表明目标路径为目录,创建目标路径为目录,并将源路径指定的文件复制到目标路径指定的目录中                                                   | 同`ADD`                        |
| `[CMD] test1.txt test1/`                   | 文件         | 已存在的目录   | `/`表明目标路径为目录,将源路径指定的文件复制到目标路径指定的目录中                                                                        | 同`ADD`                        |
| `[CMD] test1 test1`                        | 目录         | 已存在的目录   | 将源路径指定的目录中的所有文件包括其路径关系复制到目标路径指定的目录中,</br>如果文件已经存在的则覆盖,不存在的则复制(不推荐这样写避免混淆) | 同`ADD`                        |
| `[CMD] test1 test1/`                       | 目录         | 已存在的目录   | 将源路径指定的目录中的所有文件包括其路径关系复制到目标路径指定的目录中,</br>如果文件已经存在的则覆盖,不存在的则复制                       | 同`ADD`                        |
| `[CMD] test1/ test1/`                      | 目录         | 已存在的目录   | 将源路径指定的目录中的所有文件包括其路径关系复制到目标路径指定的目录中,</br>如果文件已经存在的则覆盖,不存在的则复制                       | 同`ADD`                        |
| `[CMD] test1 test1/`                       | 目录         | 不存在的目录   | 创建目标路径,并将源路径指定的目录中的所有文件包括其路径关系复制到目标路径指定的目录中,</br>如果文件已经存在的则覆盖,不存在的则复制        | 同`ADD`                        |
| `[CMD] test1/ test1/`                      | 目录         | 不存在的目录   | 创建目标路径,并将源路径指定的目录中的所有文件包括其路径关系复制到目标路径指定的目录中,</br>如果文件已经存在的则覆盖,不存在的则复制        | 同`ADD`                        |
| `[CMD] test1/* test1/`                     | 目录通配符   | 已存在的目录   | 对符合源路径指定的下一层所有文件和文件夹执行`CMD`操作复制到目标路径指定的目录中(不推荐这样写,容易造成路径混乱)                            | 同`ADD`                        |
| `[CMD] test1/* test1/`                     | 目录通配符   | 不存在的目录   | 创建目标路径,并对符合源路径指定的下一层所有文件和文件夹执行`CMD`操作复制到目标路径指定的目录中(不推荐这样写,容易造成路径混乱)             | 同`ADD`                        |
| `[CMD] test1.tar.xz test1`                 | 压缩归档文件 | 已存在的目录   | 将源路径下的压缩归档文件解压后放入目标文件夹下                                                                                            | 将压缩归档文件当作一般文件处理 |
| `[CMD] test1.tar.xz test1/`                | 压缩归档文件 | 已存在的目录   | 将源路径下的压缩归档文件解压后放入目标文件夹下                                                                                            | 将压缩归档文件当作一般文件处理 |
| `[CMD] test1.tar.xz test1/`                | 压缩归档文件 | 不存在的目录   | 创建目标路径,并将源路径下的压缩归档文件解压后放入目标文件夹下                                                                             | 将压缩归档文件当作一般文件处理 |
| `[CMD] https://myhost/test1.tar.xz test1`  | url路径      | 不存在的文件   | 将url指定的文件下载为指定路径的文件(不会解压)                                                                                             | 不支持                         |
| `[CMD] https://myhost/test1.tar.xz test1`  | url路径      | 已存在的文件   | 将url指定的文件下载为指定路径的文件将原文件替换掉(不会解压)                                                                               | 不支持                         |
| `[CMD] https://myhost/test1.tar.xz test1`  | url路径      | 已存在的目录   | 将url指定的文件下载到指定路径(不推荐这样写避免混淆)(不会解压)                                                                             | 不支持                         |
| `[CMD] https://myhost/test1.tar.xz test1/` | url路径      | 已存在的目录   | 将url指定的文件下载到指定路(不会解压)径                                                                                                   | 不支持                         |
| `[CMD] https://myhost/test1.tar.xz test1/` | url路径      | 不存在的目录   | 创建目标路径,并将url指定的文件下载到指定路(不会解压)径                                                                                    | 不支持                         |

建议:

1. 只有在充分理解`ADD`行为的情况下才用它,否则老老实实用`COPY`
2. 通配符本质上是一种批处理的快捷方式,只有充分理解目标路径为通配符时使用这种方式,否则老老实实指定目录或者文件

### 镜像的健康检测

上面的列表中有写到`HEALTHCHECK`指令,这个指令有一些特殊,它是一个规定在镜像被部署为容器后会执行的参数,他有两种形式:

+ `HEALTHCHECK NODE`,其含义为不继承父镜像的HEALTHCHECK.

+ `HEALTHCHECK [options] CMD command`其含义为镜像设置默认健康减查,其执行减查的指令就是`CMD command`的内容,`options`部分则用于设定执行行为的触发机制,`options`可选的参数包括:
    + `interval=DURATION`从容器运行起来开始计时`interval`的时间后进行第一次健康检查,随后每次间隔`interval`进行一次健康检查.
    + `start-period=DURATION`,默认为`0s`如果指定这个参数则必须大于`0s`,`start-period`用于设置容器启动需要的启动时间,在这个时间段内如果检查失败不会记录失败次数;如果在启动时间内成功执行了健康检查则容器将被视为已经启动,此后如果在启动时间内再次出现检查失败则会记录失败次数.
    + `timeout`:设定执行`command`需要时间.比如`curl`一个地址,如果超过`timeout`秒则认为超时是错误的状态,此时每次健康检查的时间是`timeout+interval`
    + `retries`:连续检查`retries`次,如果结果都是失败状态则认为这个容器是unhealth的.

对于许多服务或程序一个常见的需求就是健康检测了,我们通常写一个服务都会给一个`ping-pong`接口用于检测心跳防止服务起着但是已经不再可用.不用docker的话通常我们是在外部定义一个定时任务隔段时间请求一次来确保可用.而如果是docker的话就可以设置健康检查脚本了(前提是镜像中有对应的工具支持).当然了更加推荐的是在构建镜像时定义健康检查.

> 例1: [为我们的helloworld项目提供健康检测功能](https://github.com/hsz1273327/TutorialForDocker/tree/checkimage-build_healthycheck)

+ `dockerfile`

```yml
FROM python:3.8
ADD requirements.txt /code/requirements.txt
ADD pip.conf /etc/pip.conf
WORKDIR /code
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
ADD app.py /code/app.py
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD [ "curl","-f","http://localhost:5000/ping" ]
CMD [ "python" ,"app.py"]
```

使用`docker ps`如果在容器的`STATUS`信息中看到有`health`字样,表明健康检查被激活了.

### CMD和ENTRYPOINT

这两个命令都是用于定义镜像启动为容器时的默认行为的也就是说是用来定义容器执行行为的指令.通常现在的镜像都会至少指定其中一个,如果一个都没有指定,那么直接构造容器时会报错直接退出.而一般镜像都是在其中指定一个.

既然涉及到容器执行,那么就需要了解下docker下容器的执行方式了.

> exec模式和shell模式

docker容器的执行方式有两种

+ `exec模式`这个模式相当于在命令行中直接执行命令,它的进程号会为`1`,这也就意味着docker要关闭容器时可以优雅的关闭不容易造成僵尸进程.通常也比较推荐这种方式.
+ `shell模式`这个模式相当于执行`/bin/sh -c <你的命令>`,因此它的`1`号进程实际上是bash进程,这样就有可能造成僵尸进程.

下面是CMD和ENTRYPOINT关键字中不同模式的写法:

| 命令形式                                        | 模式        |
| ----------------------------------------------- | ----------- |
| `CMD ["executable","param1","param2"]`          | `exec模式`  |
| `CMD command param1 param2`                     | `shell模式` |
| `ENTRYPOINT ["executable", "param1", "param2"]` | `exec模式`  |
| `ENTRYPOINT command param1 param2`              | `shell模式` |

总结下就是后面的参数是**字符串列表**的就是`exec模式`,直接是命令的则是`shell模式`

> `ENTRYPOINT`和`CMD`的执行优先级

而优先级上来说,`ENTRYPOINT`优先于`CMD`,也就是说如果有`ENTRYPOINT`定义则看它是那种模式,如果是`shell模式`,那么就不会再去执行`CMD`中的指令了;如果是`exec模式`,则`ENTRYPOINT`中定义的内容会和`CMD`组合成一条指令来执行

下面是各种情况的矩阵表

| ---                | 未定义`ENTRYPOINT`         | `shell模式`的`ENTRYPOINT`                                         | `exec模式`的`ENTRYPOINT`                               |
| ------------------ | -------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------ |
| 未定义`CMD`        | 报错退出                   | `/bin/sh -c <ENTRYPOINT中的命令>`                                 | `<ENTRYPOINT中的命令>`                                 |
| `shell模式`的`CMD` | `/bin/sh -c <CMD中的命令>` | `/bin/sh -c <ENTRYPOINT中的命令>`+回车+`/bin/sh -c <CMD中的命令>` | `<ENTRYPOINT中的命令>`+回车+`/bin/sh -c <CMD中的命令>` |
| `exec模式`的`CMD`  | `<CMD中的命令>`            | `/bin/sh -c <ENTRYPOINT中的命令>`+回车+`<CMD中的命令>`            | `<ENTRYPOINT中的命令>`+`<CMD中的命令>`                 |

因此也可以看出如果两个都定义,那比较合适的用法是在`exec模式`的`ENTRYPOINT`中指定执行程序,`exec模式`的`CMD`中指定默认的执行参数,而在部署容器时则通过声明`command`字段来覆盖镜像中的`CMD`部分达到灵活执行的目的.注意`command`字段同样也要用**字符串列表**的形式声明参数.

## 构建镜像

在定义好`Dockerfile`后就是正式的构建镜像步骤了,这里用到的是`docker build <dockerfile所在的文件夹路径>`命令.

通常我们会用到的参数有:

+ `-f`指定`Dockerfile`,比如我们要为不同的平台构造镜像,他们除了基础镜像不一样其他都一样,那么我们就需要用到这个参数.我们可以为每个平台写一个`dockerfile_<平台名>`为名的`Dockerfile`,然后编译的时候根据需要指定即可.

+ `-t`为镜像指定一个标签.

一个最常见的写法如下:

```bash
docker build -t hsz1273327/myimage:latest .
```

它的含义是在当前目录下找`Dockerfile`文件构建一个标签为`hsz1273327/myimage:latest`的镜像.

镜像的构建实际是使用的`docker`

### 镜像的标签

我们上面说了镜像的标签,docker体系下镜像标签不光是一个简单标签,它是有规范的.

符合规范的标签大致可以分为如下几种形式:

+ `dockerhub账号/镜像名:版本`
+ `私有镜像仓库地址/仓库二级目录名/镜像名:版本`

没错,镜像的标签是和镜像分发有关的.需要额外注意的是`版本`,docker镜像中`latest`有特殊地位,它的含义是最新的稳定版本.因此如果拉取镜像时不指定版本那么docker会自动拉取`latest`版本的镜像.

### 跨指令集编译镜像

如果我们的基镜像是arm版而我们的编译环境为x86-64,那很遗憾我们无法成功编译镜像.但实际上也不是没有办法,我们可以设置开启[buildx](https://docs.docker.com/buildx/working-with-buildx/)特性.注意buildx是一项实验特性(在`docker 19.03`之前都没有),目前并不稳定.但可以用.

本例在[example-image-build-buildx](https://github.com/hsz1273327/TutorialForDocker/tree/example-image-build-buildx)

#### 激活跨平台镜像编译功能

我们需要在docker设置中开启这一特性:

+ `daemon.json`

    ```json
    {
    "experimental": true
    }
    ```

然后我们需要创建一个编译器:

```bash
docker buildx create --use --name mybuilder
```

创建过程中会去拉取镜像`buildkit`,在创建完成后我们可以通过`docker buildx inspect mybuilder --bootstrap`查看这个编译器的状态

```bash
Name:   mybuilder
Driver: docker-container

Nodes:
Name:      mybuilder0
Endpoint:  npipe:////./pipe/docker_engine
Status:    running
Platforms: linux/amd64, linux/arm64, linux/riscv64, linux/ppc64le, linux/s390x, linux/386, linux/arm/v7, linux/arm/v6
```

一般来说我们会用到的平台也就是`linux/amd64`(一般pc),`linux/arm64`(树莓派4的硬件,需要更新系统未arm64位),`linux/arm/v7`(树莓派3,4的默认系统).

#### dockerfile中的跨平台设置

Docker Hub支持多平台使用相同的tag(multi-arch images/multi-manifest特性),harbor也支持这一特性.基于这一特性,我们可以通过指定平台,导入相同名命的基镜像构造多平台的镜像.这只需要在dockerfile的`FROM`字段中加入`--platform`参数

```dockerfile
FROM --platform=$TARGETPLATFORM python:3.9
...

```

dockerfile中支持的与跨平台相关的上下文变量有:

| 变量             | 说明                                         | 取值范围                                     |
| ---------------- | -------------------------------------------- | -------------------------------------------- |
| `TARGETPLATFORM` | 构建镜像的目标平台                           | `linux/amd64`,`linux/arm/v7`,`linux/amd64`等 |
| `TARGETOS`       | 目标平台OS类型                               | `linux`,`windows`等                          |
| `TARGETARCH`     | 目标平台架构类型                             | `amd64`,`arm`,`arm64`等                      |
| `TARGETVARIANT`  | 目标平台架构类型的子类型,主要时arm架构的变种 | `v7`,`v6`等                                  |
| `BUILDPLATFORM`  | 构建镜像主机平台                             | `linux/amd64`等                              |
| `BUILDOS`        | 构建镜像主机平台的OS类型                     | `linux`,`windows`等                          |
| `BUILDARCH`      | 构建镜像主机平台的架构类型                   | `amd64`,`arm`,`arm64`等                      |
| `BUILDVARIANT`   | 构建镜像主机平台的架构类型的子类型           | `v7`,`v6`等                                  |

#### 跨平台编译镜像

如果我们的编译器不是`running`状态可以使用`docker buildx use {编译器名}`来指定激活编译器.

在确保我们的编译器是`running`状态时我们可以执行镜像的编译操作:

```bash
docker buildx build --load --platform={指定平台} -t {tag} . 
```

`docker buildx build`命令类似`docker build`,指定flag`--load`会将编译好的镜像打包到本地.

注意`-t`中的tag要标明平台,即`xxxx:arm64-0.0.0`这种形式,以防止镜像覆盖.

需要注意`docker buildx build`命令可能会在拉取镜像的时候报`TLS handshake timeout`错误,可以通过设置docker的配置增大对大文件的支持来缓解:

```json
{
  "mtu": 1300
}
```

这是因为本质上我们的编译过程是在docker容器中执行的,宿主机网络的mtu一般是1500,而容器中一般会比这个值略小(1450的样子),我们只有将`mtu`参数设置的至少和容器中的一致tls才不容易出错.1300也是一个经验值.

## 本地镜像管理

本地的镜像管理可以汇总为如下表格:

| 说明                     | 命令                                                              |
| ------------------------ | ----------------------------------------------------------------- |
| 查看本地镜像             | `docker images`                                                   |
| 搜索`docker hub`中的镜像 | `docker search {imagesname}`                                      |
| 为已有的镜像打标签       | `docker tag {iid} {tag}`                                          |
| 删除镜像                 | `docker rmi {iid}`                                                |
| 强制删除镜像             | `docker rmi -f {iid}`                                             |
| 查看镜像属性             | `docker inspect {iid}`                                            |
| 批量删除无标签镜像       | `docker rmi (docker images --filter dangling=true -q --no-trunc)` |
| 批量删除所有镜像         | `docker rmi (docker images -q)`                                   |
| 导出镜像                 | `docker save {iid} > {name}.tar`                                  |
| 导入镜像                 | `docker load < {name}.tar`                                        |