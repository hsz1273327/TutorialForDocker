# Docker的安装与配置

Docker是开源软件,目前支持在x86-64指令集和arm指令集下安装和使用.Docker完全依赖Linux的特性,因此理论上只能在Linux系统下安装使用,但借助虚拟机技术我们也可以在windows和mac os下通过Docker Desktop安装使用.

## 在linux下安装Docker

在linux上安装可以确定好自己的系统发行版本,然后参考[官网的指南](https://docs.docker.com/install/linux/docker-ce/centos/)安装.如果是个新机器一般也可以直接使用如下一组命令

1. 下载安装脚本(第一次安装)

    ```shell
    curl -sSL https://get.docker.com | sh
    ```

2. 配置自启动

    将docker注册到开机自启动

    ```shell
    sudo usermod -aG docker pi

    sudo systemctl enable docker

    sudo systemctl start docker
    ```

3. 将用户添加进docker组

    ```shell
    sudo gpasswd -a ${USER} docker
    ```

    之后重启服务器或者重启docker服务即可

    ```shell
    sudo service docker restart
    ```

## 利用Docker Desktop在Windows和Mac OS上安装Docker

[Docker Desktop](https://hub.docker.com/?overlay=onboarding)是一个一站式的Docker环境,它已经帮我们把相关的坑都踩完了,因此在Windows和Mac OS上我们只需要直接下载对应平台后安装即可

需要注意的是:

+ windows必须是win10, 如果你是win10 home版本,那么你只能设置使用wsl2作为docker的执行后端;其他版本则可以使用hyper-v作为docker的执行后端
+ mac os目前的m1芯片版本并没有被支持,也就是说只有Intel版本的mac可以使用.mac版本的docker desktop使用的后端是HyperKit.

## 配置Docker

Docker在Linux下的配置一般在`/etc/docker/daemon.json`,在Docker Desktop中可以在`设置->Docker Engine`中找到.它是一个json文件.其可选值可以参考如下:

```json
{
  "authorization-plugins": [],
  "data-root": "",
  "dns": [],
  "dns-opts": [],
  "dns-search": [],
  "exec-opts": [],
  "exec-root": "",
  "experimental": false,
  "features": {},
  "storage-driver": "",
  "storage-opts": [],
  "labels": [],
  "live-restore": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file":"5",
    "labels": "somelabel",
    "env": "os,customer"
  },
  "mtu": 0,
  "pidfile": "",
  "cluster-store": "",
  "cluster-store-opts": {},
  "cluster-advertise": "",
  "max-concurrent-downloads": 3,
  "max-concurrent-uploads": 5,
  "default-shm-size": "64M",
  "shutdown-timeout": 15,
  "debug": true,
  "hosts": [],
  "log-level": "",
  "tls": true,
  "tlsverify": true,
  "tlscacert": "",
  "tlscert": "",
  "tlskey": "",
  "swarm-default-advertise-addr": "",
  "api-cors-header": "",
  "selinux-enabled": false,
  "userns-remap": "",
  "group": "",
  "cgroup-parent": "",
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "init": false,
  "init-path": "/usr/libexec/docker-init",
  "ipv6": false,
  "iptables": false,
  "ip-forward": false,
  "ip-masq": false,
  "userland-proxy": false,
  "userland-proxy-path": "/usr/libexec/docker-proxy",
  "ip": "0.0.0.0",
  "bridge": "",
  "bip": "",
  "fixed-cidr": "",
  "fixed-cidr-v6": "",
  "default-gateway": "",
  "default-gateway-v6": "",
  "icc": false,
  "raw-logs": false,
  "allow-nondistributable-artifacts": [],
  "registry-mirrors": [],
  "seccomp-profile": "",
  "insecure-registries": [],
  "no-new-privileges": false,
  "default-runtime": "runc",
  "oom-score-adjust": -500,
  "node-generic-resources": ["NVIDIA-GPU=UUID1", "NVIDIA-GPU=UUID2"],
  "runtimes": {
    "cc-runtime": {
      "path": "/usr/bin/cc-runtime"
    },
    "custom": {
      "path": "/usr/local/bin/my-runc-replacement",
      "runtimeArgs": [
        "--debug"
      ]
    }
  },
  "default-address-pools":[
    {"base":"172.80.0.0/16","size":24},
    {"base":"172.90.0.0/16","size":24}
  ]
}
```

一般来说除非有需要我们并不需要去修改它.但作为在墙内的用户,建议设置下docker hub的镜像库(`registry-mirrors`)

```json
{
    "registry-mirrors":[
        "https://registry.docker-cn.com",
        "https://hub-mirror.c.163.com",
        "https://docker.mirrors.ustc.edu.cn/"
    ]
}
```

## helloworld

按照传统,我们的第一个例子是一个helloworld,我们来演示下docker的最简单使用流程.例子在[python_docker_example](https://github.com/hszofficial/python_docker_example),这个例子所在的仓库也是我们后续文章使用的仓库,这个例子在[helloworld分支](https://github.com/hsz1273327/TutorialForDocker/tree/helloworld).我们用flask构造一个helloworld服务,借助它来直观的感受下docker的使用流程.

首先确认好你有docker环境.然后我们创建如下文件:

+ `requirements.txt`文件用于记录程序的依赖

    ```txt
    sanic==20.6.3
    ```

+ `pip.conf`文件,用于pip翻墙(非必须)

    ```conf
    [global]
    index-url = https://pypi.tuna.tsinghua.edu.cn/simple
    ```

+ `app.py`文件用于构造flask的hellowoeld程序

    项目的功能非常简单--访问`/`后返回一个`helloworld`文本,代码如下

    ```python
    from sanic.response import json

    app = Sanic("hello_example")

    @app.route("/")
    async def test(request):
    return json({"hello": "world"})

    if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
    ```

+ `Dockerfile`文件用于声明如何构造镜像

    先不细究dockerfile语法,下面是示例:

    ```dockerfile
    FROM python:3.8
    ADD requirements.txt /code/requirements.txt
    ADD pip.conf /etc/pip.conf
    WORKDIR /code
    RUN pip install --upgrade pip
    RUN pip install -r requirements.txt
    ADD app.py /code/app.py
    CMD [ "python" ,"app.py"]
    ```

+ `build_image.sh/build_image.ps1`文件(可选)用于方便执行构造镜像的操作.

    ```bash
    docker build -t python_docker_example:helloworld .
    ```

    执行这个命令会构造一个标签为`python_docker_example:helloworld`的镜像

+ `run_container.sh/run_container.ps1`文件(可先)用于方便执行使用镜像运行容器

    ```bash
    docker run -d -p 5000:5000 python_docker_example:helloworld
    ```

    执行这个命令会使用上面构造的标签为`python_docker_example:helloworld`的镜像构造一个容器来运行我们的程序.
    我们将其设置为后台运行,并且将宿主机的5000端口与容器的5000端口映射.我们就可以通过访问本地的5000端口来访问程序了

## 启动网络API

**注意:启动网络API是不安全的,请尽量不要启用,如果要启用请一定配置[tls证书](https://blog.hszofficial.site/introduce/2020/12/03/TLS%E4%B8%8E%E9%80%9A%E4%BF%A1%E5%AE%89%E5%85%A8/).**

Docker最简单的远程调用方式是启动网络api,我们知道`docker`和`dockerd`是客户端/服务器结构的,默认情况下他们使用本地的`unix socket`(`unix:///var/run/docker.sock`)通信.我们可以修改配置让它通过tcp协议通信从而让外网访问

```json
{
"hosts": [
        "tcp://0.0.0.0:2376",
        "unix:///var/run/docker.sock"
    ]
}
```

这样宿主机tcp协议的2376端口就会监听来自外部的请求了

### 使用网络api

使用网络api的方式有三种:

+ 使用docker客户端访问

    `docker`命令可以通过

    ```bash
    docker -H <tcp://host:2376> \
      --tls \
      --tlscacert=xxxx \ # 默认路径为`~/.docker/ca.pem`
      --tlscert=xxxx \ # 默认路径为`~/.docker/cert.pem` 
      --tlskey=xxxx \ # 默认路径为`~/.docker/key.pem` 
      <cmds ....>
    ```

    的方式直接操作远程.如果你不想每次都输入`-H`参数,那么你可以在客户端机器加上下面的环境变量`export DOCKER_HOST="tcp://192.168.0.83:2376"`

+ 直接通过http/https方式请求
    启动网络api后的docker可以通过http接口从外部控制本地docker,其接口文档可以看<https://docs.docker.com/engine/api/v1.40/>这里就不再细讲了

+ 使用不同编程语言的客户端工具,比如[docker-py](https://github.com/docker/docker-py),比如[moby](https://github.com/moby/moby).

这块的例子可以看[官方示例](https://docs.docker.com/engine/api/sdk/examples/)