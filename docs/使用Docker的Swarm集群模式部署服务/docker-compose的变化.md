# docker-compose的变化

前面的单机部署中我们已经接触过docker-compose,它的基本用法我们已经了解了,swarm模式下使用的`docker-compse`是`v3`版本,这个版本目前还在迭代,本文主要是介绍`v2`到`v3`的变化.

本文以3.8版本为基础介绍变化和使用注意点

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

## 重启逻辑设置

docker的重启策略相关的配置也被移动到了在`deploy`字段下的`restart_policy`字段下.其形式如下:

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

注意整个`deploy`字段都只在swarm模式下生效.

## 硬盘挂载设置

## 网络设置

## 灰度发布设置

