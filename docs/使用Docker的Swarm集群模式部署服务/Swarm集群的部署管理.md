# Swarm集群的部署管理

集群化部署服务在swarm中同样被抽象成了3层.

1. `task`,任务,用于实际部署镜像执行任务,是最小的部署单位.其本质就是一个`container`容器
2. `service`服务,用于完成实际的特定任务,每个`service`由1个以上的同镜像同配置容器构成.
3. `stack`服务栈,用于描述一组互不相同的`service`的集合,比较接近命名空间的概念,只是在同一个服务栈下会有一些默认设置可以方便容器相互识别

可以看出这个结构和单机情况下是一样的,不同之处在于`container`在集群中可以被分发到多个宿主机中了,因此service的配置就会变得更加复杂.为此就有了对`容器分发策略`的定制和`网络`和`存储共享`的扩展.而同时stack中对`service`启动和关闭顺序的约束也就无效了.

在集群环境下swarm扩展了`service`部署的功能,除了支持原本单机就有的`资源限制`和`重启策略`外,还新增了`更新发布策略`和`回滚策略`功能.

而在docker-compose v3版本中与v2版本最大的区别也在于将在急群中部署相关的操作全部移到了`deploy`字段内,这个字段涵盖了上面提到的中的5个方面

1. 资源限制
2. 重启策略
3. 更新发布策略
4. 回滚策略
5. 容器部署分发策略

注意v3版本依然支持v2版本中原有的配置项,只是`deploy`字段内的设置只会对swarm模式生效

## 资源限制设置

在`v3`版本中资源配置相关的设置项被移动到了`deploy`字段下的`resources`字段下,且只能在swarm模式下生效.其形式如下:

```yml
...
deploy:
    resources:
        limits:
            cpus: '0.50'
            memory: 50M
        reservations:
            cpus: '0.25'
            memory: 20M

...
```

`limits`限制了最高的用量,`reservations`限制了至少要保留的资源.其中`cpu`的限制是一个浮点数,其含义是使用单核的多少算力,比如`0.5`就是说只能使用单核的50%算力.

如果服务或容器尝试使用的内存超过系统可用的内存,则可能会遇到内存不足异常(俗称`oom`),docker内核会杀掉容器进程或者Docker守护程序.为防止这种情况发生,应该确保应用程序在具有足够内存的主机上运行.

除了最常规的cpu和memory外还可以设置如下几个项目用于限制资源.

+ `pids`,设置容器中的进程数量
+ `devices`,设置容器可以调用的设备资源,这个选项基本是为gpu设计的,通常放在`reservations`中.它又可以设置
    + `capabilities`设置能力,默认的可选项只有`gpu`和`tpu`两个,但也可以根据`driver`的设置填入其他,比如`driver`设置为`nvidia`则`capabilities`就可以设置为`"nvidia-compute"`
    + `driver`设置使用的驱动,通常就是`nvidia`
    + `count`设置使用设备的个数,比如用两个gpu就设置为2
    + `device_ids`指定设备的id,比如有两个gpu时同个这个id指定容器使用的是哪个,注意`device_ids`和`count`互斥
    + `options`,driver的设置项.

## 重启策略设置

在`v3`版本中重启策略相关的设置项被移动到了`deploy`字段下的`restart_policy`字段下,且只能在swarm模式下生效,在swarm模式下`restart`字段不会生效.其形式如下:

```yml
...
deploy:
    restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
...
```

其中

+ `condition`描述在何种情况下重启,可选的有
    + `on-failure`只在启动失败时重启
    + `any`,在任何情况下重启(默认值)
    + `none`,在任何情况下都不重启,

+ `delay`在重新启动尝试之间等待多长时间,默认不等待,即`0s`
+ `max_attempts`最大重启尝试次数,次数过了就不会再尝试重启.默认会一直重启
+ `window`在决定重新启动是否成功之前要等待多长时间,默认是立刻判断,有些容器启动时间比较长,需要指定一个"窗口期".

## 更新发布策略设置

在真实应用场景种服务更新是一个问题,在docker体系下通常我们更新服务发布就是更新镜像.因此为了除了问题便于回滚,更加建议镜像不用`latest`这样的标签来标识,老老实实按版本号发布.

在`v3`版本中更新发布策略相关的设置项被移动到了`deploy`字段下的`update_config`字段下,且只能在swarm模式下生效.其形式如下:

```yml
...
deploy:
    update_config:
        parallelism: 2
        delay: 10s
        order: stop-first
...
```

其中

+ `parallelism`: 用于设置一次同时更新的容器数量
+ `delay`: 用于设置每一批更新容器操作之间的间隔时间
+ `failure_action`: 用于设置当更新失败时的行为,由于更新可以是多次执行的,因此支持3种选择:
    + `continue`: 当有更新失败后继续其他的要更新的容器的更新操作
    + `rollback`: 回滚镜像并用之前的镜像启动
    + `pause`: 停止后续更新操作(默认)
+ `monitor`: 设置观察多久后认定为更新失败,默认5s,可以设置以`ns|us|ms|s|m|h`作为单位,当设置为0时也表示使用默认值
+ `max_failure_ratio`: 更新期间允许的最大失败率,在设置`failure_action`为`pause`时如果也设置了`max_failure_ratio`,则失败率超过`max_failure_ratio`就会停止更新
+ `order`: 单次更新操作种的执行顺序,支持
    + `stop-first`先停止旧任务然后再启动新任务(默认)
    + `start-first`先启动新任务再停止旧任务,注意会有新旧共存的小段时间可能引起冲突

## 回滚策略

回滚策略实际上是更新发布策略的扩展,当`update_config.failure_action`为`rollback`时才会生效,它会定义当更新失败时如何回滚.

在`v3`版本中更新发布策略相关的设置项被移动到了`deploy`字段下的`rollback_config`字段下,且只能在swarm模式下生效.其形式如下:

```yml
...
deploy:
    rollback_config:
        parallelism: 2
        delay: 10s
        order: stop-first
...
```

其中

+ `parallelism`: 用于设置一次同时回滚的容器数量
+ `delay`: 用于设置每一批回滚容器操作之间的间隔时间
+ `failure_action`: 用于设置当回滚失败时的行为,由于回滚可以是多次执行的,因此支持3种选择:
    + `continue`: 当有回滚失败后继续其他的要回滚的容器的回滚操作
    + `pause`: 停止后续回滚操作(默认)
+ `monitor`: 设置观察多久后认定为回滚失败,默认5s,可以设置以`ns|us|ms|s|m|h`作为单位,当设置为0时也表示使用默认值
+ `max_failure_ratio`: 回滚期间允许的最大失败率,在设置`failure_action`为`pause`时如果也设置了`max_failure_ratio`,则失败率超过`max_failure_ratio`就会停止回滚
+ `order`: 单次回滚操作种的执行顺序,支持
    + `stop-first`先停止旧任务然后再启动新任务(默认)
    + `start-first`先启动新任务再停止旧任务,注意会有新旧共存的小段时间可能引起冲突

## 容器部署分发策略

容器的部署分发有3种情况,使用`deploy.mode`,`deploy.max_replicas_per_node`,`deploy.replicas`,`deploy.placement`字段来共同描述.其中`mode`用于区分部署模式,`deploy.placement`用于描述容器挑选部署节点的策略.而`deploy.max_replicas_per_node`和`deploy.replicas`则是在`deploy.mode`为`replicated`时专用的.

swarm种部署模式有两种:

1. `global`模式,这种模式的特点是会在符合`deploy.placement`约束的每个节点上部署1个容器.一个典型的例子如下

    ```yaml
    deploy:
        mode: global
    ```

2. `replicated`模式(默认),这种模式的特点是需要用`replicas`指定要部署多少个容器,然后根据`deploy.max_replicas_per_node`和`deploy.placement`的约束随机的部署容器.`deploy.max_replicas_per_node`约束了每个节点上最多部署多少个该`service`的容器.一个典型的例子如下

    ```yaml
    deploy:
        replicas: 4
        max_replicas_per_node: 2
    ```

### 用`deploy.placement`字段描述容器挑选部署节点的策略

`deploy.placement`字段并不能非常精准的控制什么容器部署在什么地方.它之内给个"指导意见".这个"指导意见"的描述是通过描述与节点信息的匹配关系来实现的.节点信息可以看上一节中的内容.

其形式如下:

```yaml
deploy:
    placement:
        constraints:
            - "node.role==manager"
            - "node.labels.group==test"
            - "engine.labels.operatingsystem==ubuntu 18.04"
        preferences:
            - spread: node.labels.zone
```

`placement`有两种类型的设置:

+ `constraints`
+ `preferences`

#### `constraints`约束设置

`constraints`的含义是其包含的每条规则节点都必须满足才可以部署(也就是`AND`关系).其中的关系描述支持两种判断符

+ `==`表示`匹配`
+ `!=`表示`不匹配`

`constraints`可以使用全部的节点信息用于匹配.

#### `preferences`偏好设置

`preferences`用于根据不同的策略按设置时的顺序作为优先级顺序分发容器到节点.先被设置的策略会被先执行,然后再执行后设置的策略.不过这一设置一样还是带有很强的随机性.

而且注意,`preferences`偏好设置对`mode`为`global`的部署无效

不过`preferences`偏好设置目前只支持`spread`策略

##### `spread`策略

这个策略只可以使用节点信息中的`engine.labels`和`node.labels`,它的作用是指定一个标签,然后根据这个标签的值的数量平均分配要部署的容器数量给各个值对应的机器上.

比如我们有3台`node.labels.city`为`beijing`的机器,2台`node.labels.city`为`shanghai`的机器.`node.labels.city`为`guangzhou`和`shenzhen`的机器各一台,以及3台没有`node.labels.city`标签的机器,然后我们要部署15个容器上去,那么

+ `node.labels.city`为`beijing`的机器会分得3个容器,每台机器都会被部署一个容器
+ `node.labels.city`为`shanghai`的机器会分得3个容器,一台机器分得2个容器,另一台分得1个容器
+ `node.labels.city`为`guangzhou`和`shenzhen`的机器会各自获得3个容器,每个机器上都会有3个容器
+ 没有`node.labels.city`的三台机器被视为`node.labels.city`为空,也分得3个容器,每台机器上回被部署一个容器

因此`preferences`一般都要配合`constraints`使用,如果我们为所有有标签`node.labels.city`的节点都加上标签`node.labels.has_city=true`,然后加上约束

```yaml
constraints:
    - "node.labels.has_city==true"
```

则会变成:

+ `node.labels.city`为`beijing`的机器会分得3到4个容器,每台机器都会被部署一个到2个容器
+ `node.labels.city`为`shanghai`的机器会分得3到4个容器,一台机器分得2个容器,另一台分得1到2个容器
+ `node.labels.city`为`guangzhou`和`shenzhen`的机器会各自获得3到4个容器,每个机器上都会有被分配到的所有容器

也就是说`preferences`只是偏好策略,并不严格.

## 使用占位符创建服务

在swarm模式下我们的部署行为有的时候需要动态的生成,这时候就可以使用占位符了.占位符的用法遵循[go的模板语法](https://www.topgoer.com/%E5%B8%B8%E7%94%A8%E6%A0%87%E5%87%86%E5%BA%93/template.html),即`{{ }}`包裹的变量,且占位符并不能在所有位置生效.已知可以直接生效的位置包括:

+ `hostname`,用于设置每个容器自己的hostname,比如

    ```yml
    services:
        worker:
            ...
            hostname: 'test.{{ .Service.Name }}.{{.Task.Slot}}'
            deploy:
                mode: replicated
                replicas: 3
            ...
    ```

+ `volumes`,用于设置每个容器自己挂载的存储,比如

    ```yml
    services:
        worker:
            ...
            volumes:
            - foo:/mnt
            deploy:
                mode: replicated
                replicas: 3

    volumes:
    foo:
        name: 'worker-{{.Task.Slot}}'
        ...
    ```

+ `environments`,用于设置每个容器中自己的环境变量,比如

    ```yml
    services:
        worker:
            ...
            environment:
                X_NODE_ID: '{{.Node.ID}}'
                X_NODE_HOSTNAME: '{{.Node.Hostname}}'
                X_SERVICE_ID: '{{.Service.ID}}'
                X_SERVICE_NAMES: '{{.Service.Name}}'
                X_SERVICE_LABELS: '{{.Service.Labels}}'
                X_TASK_NAME: '{{.Task.Name}}'
                X_TASK_SLOT: '{{.Task.Slot}}'
            deploy:
                mode: replicated
                replicas: 3

        ...
    ```

除了上面三个外我们也可以在`command`中间接的使用,方法就是利用`environment`中转

```yml
services:
    worker:
        ...
        environment:
            X_NODE_ID: '{{.Node.ID}}'
            X_NODE_HOSTNAME: '{{.Node.Hostname}}'
            X_SERVICE_ID: '{{.Service.ID}}'
            X_SERVICE_NAMES: '{{.Service.Name}}'
            X_SERVICE_LABELS: '{{.Service.Labels}}'
            X_TASK_NAME: '{{.Task.Name}}'
            X_TASK_SLOT: '{{.Task.Slot}}'
        deploy:
            mode: replicated
            replicas: 3
        command: "echo $X_NODE_HOSTNAME-$X_SERVICE_NAMES-$X_TASK_SLOT
    ...
```

在swarm中支持的占位符包括:

| 占位符            | 说明                                                        |
| ----------------- | ----------------------------------------------------------- |
| `.Service.ID`     | 当前service的id                                             |
| `.Service.Name`   | 当前Service的名字                                           |
| `.Service.Labels` | 当前service的标签,在`deploy.labels`中设置                   |
| `.Node.ID`        | 部署在Node的ID                                              |
| `.Node.Hostname`  | 部署在Node的hostname                                        |
| `.Task.Name`      | 部署Task的名字                                              |
| `.Task.Slot`      | 部署Task所在的插槽,注意这个只会在使用`replicated`模式时生效 |
