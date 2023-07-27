# Swarm集群节点管理

Swarm的结构是典型的主从结构.主节点被称作`manager`,从节点被称作`worker`.

+ `manager`节点会负责管理集群上服务的分配和调度的同时也可以部署服务容器,它们通过`raft`算法选举出一个`leader`用于真正管理集群,而剩下的只是有资格在这个`leader`故障时成为候选者.manager节点也可以被部署容器.`manager`节点需要固定使用静态ip

+ `worker`节点仅用过于部署容器.`worker`节点不需要固定使用静态ip

通常一个集群中的`manager`节点不应该小于3个大于7个,且数量应该为单数.而且由于每个`manager`节点都有可能成为`leader`,因此应该确保所有`manager`节点的性能都足以承担调度工作.好在swarm的调度效率很高,通常并不需要多高的配置就足以应付很大集群的调度工作.

与Swarm集群的节点管理相关的命令有:

| 命令           | 说明                                  |
| -------------- | ------------------------------------- |
| `docker swarm` | 集群管理工具,用于创建,加入,离开集群等 |
| `docker node`  | 集群的节点管理工具                    |

## 初始化集群

操作位置为**任意你希望作为Manager节点的机器**,命令如下:

```bash
sudo docker swarn init
```

## 集群添加节点

添加节点到集群需要先从要**加入的集群的manager节点**中获取加入集群的token,根据不同的角色可以得到不同的token,

+ 获取作为manager节点的token

    ```bash
    sudo docker swarm join-token manager
    ```

+ 获取作为worker节点的token

    ```bash
    sudo docker swarm join-token worker
    ```

然后在**要加入集群的节点**上执行如下命令即可:

```bash
sudo docker swarm join --token <token> <manager节点的host>:2377
```

需要注意要给集群添加节点需要如下端口可以相互访问:

| 端口   | 协议     | 开放位置 | 说明                            |
| ------ | -------- | -------- | ------------------------------- |
| `2376` | tcp      | all      | docker客户端与dockerd间交互     |
| `2377` | tcp      | manager  | swarm节点间交互                 |
| `7946` | tcp和udp | all      | 用于网络服务发现                |
| `4789` | udp      | all      | overlay网络覆盖流量             |
| `50`   | tcp和udp | all      | 如果overlay网络使用了加密则需要 |

## 查看集群上的节点状态

操作位置为**任意Manager节点**,命令如下:

```bash
sudo docker node ls
```

其结果就是打印出各个节点的状态,包括如下几个维度:

+ `ID`,节点的唯一标识
+ `HOSTNAME`,节点的hostname
+ `STATUS`,节点状态,表示节点本身的状态,其值不受命令控制,只和节点机器的状态有关.其枚举值包括:
    + `Ready`,节点准备就绪
    + `Down`,节点不可用
+ `AVAILABILITY`,节点可用性,它表示该节点是否可以被调度.`AVAILABILITY`是可以通过设置改变的节点状态.
    + `Active`表示调度器可以在其中部署任务
    + `Pause`表示调度器无法在其中部署任务,但已经部署的任务依然在运行
    + `Drain`表示调度器无法在其中部署任务,而且其中原本部署的任务已经被遣散.
+ `MANAGER STATUS`,节点作为manager节点的状态,如果节点不是manager节点则不会有值,其值有如下枚举
    + `Leader`表示该节点为`Leader`节点,它将主导集群资源分配调用
    + `Reachable` 表示该节点是参与Raft共识仲裁的manager节点,如果`Leader`不可用则该节点有资格被选举为新的`Leader`.(也就是后备`Leader`)
    + `Unavailable` 表示该节点是无法与manager节点通信的manager节点

## 更改节点角色

+ worker节点提升为manager节点

    操作位置为**任意Manager节点**,命令如下:

    ```bash
    sudo docker node promote <nodeid>
    ```

+ manager节点降级为worker节点

    操作位置为**任意Manager节点**,命令如下:

    ```bash
    sudo docker node demote <nodeid>
    ```

## 遣散节点上的服务

在一些情况下(比如要做一些让节点不稳定的操作或者要让节点离开集群)我们会需要先遣散节点上的服务.这只需要**在任意manager节点**改变节点状态即可:

```bash
sudo docker node update --availability drain <NODE-ID>
```

类似的,我们也可以让已经处于遣散状态的节点回到可部署状态:

```bash
sudo docker node update --availability active <NODE-ID>
```

## 集群删除节点

集群删除节点的操作有两步

1. 要删除的节点先离开集群

    操作位置为**要离开的节点**,命令如下:

    ```bash
    sudo docker swarm leave
    ```

    注意这条命令**对manager节点无效**,因此需要先将manager节点降级未worker节点

2. 在管理节点上删除节点

    操作位置为**任意Manager节点**,命令如下:

    ```bash
    sudo docker node rm <nodeid>
    ```

## 节点更新docker

swarm集群只要还有一个主节点正常运行,其他节点即便重启也可以很快重新连入集群,因此更新每个节点上的docker只需要保证同一时间至少有一个主节点运行即可.

## 节点信息

swarm节点有如下固定的属性信息:

| 属性                  | 说明                                                  | 例子                                          |
| --------------------- | ----------------------------------------------------- | --------------------------------------------- |
| `node.id`             | 节点id                                                | `node.id==2ivku8v2gvtg4`                      |
| `node.hostname`       | 节点hostname                                          | `node.hostname=node-2`                        |
| `node.role`           | 节点角色                                              | `node.role==manager`                          |
| `node.platform.os`    | 节点操作系统                                          | `node.platform.os==windows`                   |
| `node.platform.arch`  | 节点指令集                                            | `node.platform.arch==x86_64`                  |
| `engine.labels.<key>` | docker引擎维护的标签信息,在配置文件的`labels`字段维护 | `engine.labels.operatingsystem==ubuntu 14.04` |

除了上面这些信息外我们也可以自定义节点的标签,其位置为`node.labels.<key>`,我们可以使用命令`docker node update --label-add <key>=<value> <node>`添加标签.
用`docker node update --label-rm <key> <node>`删除标签,用`docker node inspect`查看节点信息时顺便就查看节点标签.

如果使用portainer管理集群的话其中`swarm`下也可以直接在界面上管理节点标签.

节点的上述信息都可以用于在分发容器时按条件分配部署节点.这个后面介绍服务部署时再详细介绍.因此我们通常会在加入节点后第一时间在如下几个维度为节点打标签.

+ 分组环境划分,比如`group==test`,`group==dev`
+ 业务功能划分,比如`business==recommand`,`business==pay`
+ 节点针对的区域,比如`area==beijing`,`area==shanghai`
+ 算力类型,比如`calculation_type==cpu`,`calculation_type==gpu`
