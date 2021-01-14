# Swarm集群节点管理

Swarm的结构是典型的主从结构.主节点被称作`manager`,从节点被称作`worker`.与Swarm集群的节点管理相关的命令有:

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

## 查看集上的节点状态

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



## 集群删除节点

集群删除节点的操作有两步

1. 要删除的节点先离开集群

    操作位置为**要离开的节点**,命令如下:

    ```bash
    sudo docker swarm leave
    ```

2. 在管理节点上删除节点

    操作位置为**任意Manager节点**,命令如下:

    ```bash
    sudo docker node rm <nodeid>
    ```