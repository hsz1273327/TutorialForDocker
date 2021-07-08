# Swarm集群数据管理

集群化部署就会涉及到数据共享的问题.Swarm本身并没有提供额外的通用的数据管理工具,但提供了两个专用工具用于节点间共享数据.

+ `secrets`用于保存和共享密钥
+ `configs`用于保存配置

而其他更加通用的数据我们则需要借助单机环境下就有的`volume`通过nfs来实现.而如果使用`bind`模式或者普通`volume`则只是映射使用宿主机的硬盘资源而已.而且即便是使用nfs也是需要在每台部署的宿主机上都创建,因此在swarm模式下`volume`更多的在stack中定义而非在外部定义以方便管理销毁.

## 使用Swarm集群管理密钥

通常我们在docker中配置ssl不会直接将文件放入镜像,这样挺奇怪的,而是会将其放入docker swarm的`secrets`中.

在Docker中,Secret是一种BLOB(二进制大对象)数据,像密码,SSH私钥,SSL证书或那些不应该未加密就直接存储在Dockerfile或应用程序代码中的数据就应该放在其中.在Docker 1.13及更高版本中我们可以使用`Docker Secrets`集中管理这些数据并将其安全地传输给需要访问的容器.一个给定的Secret只能被那些已被授予明确访问权限的服务正在运行的情况下使用.

不想在镜像或代码中管理的任何敏感数据我们都可以使用Secret来管理,比如:

+ 用户名和密码
+ TLS certificates and keys
+ SSH keys
+ 数据库名
+ 内部服务器信息
+ 通用的字符串或二进制内容 (最大可达 500 Kb)

一般来说`Secret`都是现在外部定义好,然后再在部署时引用的.

如果你使用Portainer管理swarm集群的话更加建议使用其中的`Secrets`页面进行管理配置.

### secrets的操作

+ 创建Secret,通常我们都是通过文件创建secret对象的.

```shell
docker secret create [参数] SECRET [file|-]
```

参数:

| 简写 | 参数       | 默认值 | 描述        |
| ---- | ---------- | ------ | ----------- |
| `-d` | `--driver` | ---    | Secret 驱动 |
| `-l` | `--label`  | ---    | 配置标签    |

例子:

```shell
docker secret create mysecret ./secret.json
```

+ 删除一条secret

```shell
docker secret rm SECRET
```

+ 查看secret列表

```shell
docker secret ls [参数]
```

参数:

| 简写 | 参数       | 默认值 | 描述           |
| ---- | ---------- | ------ | -------------- |
| `-f` | `--filter` | ---    | 按条件过滤输出 |
| ---  | `--format` | ---    | GO模板转化     |
| `-q` | `--quiet`  | ---    | 仅展示ID       |

+ 查看某一条secret

```shell
docker secret inspect [参数] SECRET [SECRET...]
```

参数:

| 简写 | 参数       | 默认值 | 描述                   |
| ---- | ---------- | ------ | ---------------------- |
| `-f` | `--format` | ---    | GO模板转化             |
| ---  | `--pretty` | ---    | 以人性化的格式打印信息 |

### 在配置中使用secret

secret可以当做就是一个文件,它的路径默认在`/run/secrets/[secret]`上所以只要拿这个地址放在配置中相应的位置即可.如果需要为secret在容器中换个名字,可以在compose中通过定义`service`中的`secrets`来引用,当然了要用先要在外部声明

```yaml
version: "3.8"
services:
  redis:
    ...
    secrets:
      - source: my_secret
        target: <name in container>
secrets:
  my_secret:
    external: true
    
```

## 使用Swarm集群管理配置

docker同样提供了`configs`用于管理配置文件,它和`secrets`非常相似,各种操作只要把`secret`改成`config`就行.下面是一个使用的例子:

```yaml
version: "3.8"
...
services:
  fluentd-bit:
    ...
    configs:
      - source: fluent-bit-conf
        target: /fluent-bit/etc/fluent-bit.conf
      - source: docker_parser-conf
        target: /fluent-bit/etc/docker_parser.conf

configs:
  fluent-bit-conf:
    external: true
  docker_parser-conf:
    external: true
```

和`secrets`不同之处只在于`configs`的`target`可以指定容器中的路径