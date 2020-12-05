
#### 在docker Swarm环境下配置证书和私钥

通常我们在docker中配置ssl不会直接将文件放入镜像,这样挺奇怪的,而是会将其放入docker swarm的`secrets`中.

在Docker中,Secret是一种BLOB(二进制大对象)数据,像密码,SSH私钥,SSL证书或那些不应该未加密就直接存储在Dockerfile或应用程序代码中的数据就应该放在其中.在Docker 1.13及更高版本中我们可以使用`Docker Secrets`集中管理这些数据并将其安全地传输给需要访问的容器.一个给定的Secret只能被那些已被授予明确访问权限的服务正在运行的情况下使用.

不想在镜像或代码中管理的任何敏感数据我们都可以使用Secret来管理,比如:

+ 用户名和密码
+ TLS certificates and keys
+ SSH keys
+ 数据库名
+ 内部服务器信息
+ 通用的字符串或二进制内容 (最大可达 500 Kb)

##### secrets的操作

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

##### 在配置中使用secret

secret可以当做就是一个文件,它的路径默认在`/run/secrets/[secret]`上所以只要拿这个地址放在配置中相应的位置即可.

顺道一提,docker同样提供了`configs`用于管理配置文件,但nginx的配置文件比较特殊不建议使用这个管理,因为nginx换个配置文件做的事情就完全不一样了和代码其实是差不多的不是传统意义上的配置.
`config`无法做到版本管理,所以建议还是讲它的配置文件放入镜像,拿label管理好版本.