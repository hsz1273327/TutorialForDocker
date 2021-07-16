# Swarm集群上的实用组件

swarm集群相比k8s一大缺陷就是功能不够全面,下面介绍扩展swarm集群能力的实用组件

## 使用`swarm-cronjob`让swarm支持定时任务

swarm在20.10.0版本开始支持`swarm jobs`,它允许定义一次性的任务.不过这个特性还没被docker-compose支持.而定时任务swarm目前是没办法原生支持的.而这个功能其实非常有价值.我们可以利用它部署一些定时脚本,而且关键可以将相关的服务,监听进程以及定时任务放在一个stack中,大大降低了项目维护难度.

### 部署

部署只需要挂载`/var/run/docker.sock`就可以正常使用,参数通过环境变量设置,只有3项

+ `TZ`: 设定时区
+ `LOG_LEVEL`: 设置log等级
+ `LOG_JSON`: 设置是否打印json格式的log

然后只需要将部署位置限制为manager节点即可

```yaml
version: "3.8"

services:
  swarm-cronjob:
    image: crazymax/swarm-cronjob:1.9.0
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    environment:
      TZ: Asia/Shanghai
      LOG_LEVEL: info
      LOG_JSON: "true"
    deploy:
      placement:
        constraints:
          - node.role == manager
```

### 添加定时任务

定时任务一定需要使用stack维护.比如:

```yaml
version: "3.2"

services:
  test:
    image: busybox
    command: date
    deploy:
      mode: replicated
      replicas: 0
      labels:
        - "swarm.cronjob.enable=true"
        - "swarm.cronjob.schedule=* * * * *"
        - "swarm.cronjob.skip-running=false"
      restart_policy:
        condition: none
```

上面的例子会每分钟打印一次当前时间.设置项都在`deploy.labels`中定义.可以设置的项包括:

参数|默认值|说明
---|---|---
`swarm.cronjob.enable`|`false`|声明service是否是定时任务
`swarm.cronjob.schedule`|---|设置定时器,必填
`swarm.cronjob.skip-running`|`false`|如果服务当前正在运行,是否还要启动任务
`swarm.cronjob.replicas`|`1`|在`replicated`部署模式下按计划设置的副本数.
`swarm.cronjob.registry-auth`|`false`|向`Swarm`发送registry的身份验证详细信息

需要注意的点有:

1. 执行模式必须是`replicated`
2. 执行实例数`replicas`需要设置为`0`
3. 重启策略`restart_policy`需要设置为`none`

在部署成功后,docker就会每隔你指定的时间执行一次这个service,执行完成后的容器就成了`completed`状态.

### 删除定时任务

删除设置了定时任务的service就可以删除定时任务了.
