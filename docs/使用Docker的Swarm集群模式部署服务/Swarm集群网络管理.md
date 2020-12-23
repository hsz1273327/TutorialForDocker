# Swarm集群的网络设置

Swarm集群的网络设置一般是3种:

+ overlay网络
+ host网络
+ macvlan网络

macvlan网路需要每个实例指定ip因此非常的不好用.这里也就不介绍了.本文将只介绍前两种.

## overlay网络

overlay网络是Swarm的默认网络形式.它是一个全功能的虚拟网络,自带服务注册,服务发现,负载均衡.


### 端口映射使用`host`模式提高io性能


#### 使用etcd作为外置的服务发现工具



## host网络

另一种更加手动档的网络配置方式是host网络,它的性能损失是最小的,因为它本质上就是用的宿主机的网络.这种模式下无法做端口映射,因为容器种的端口会直接暴露给宿主机.而在容器中我们可以直接获取到宿主机的网络信息(ip,mac地址等)

一个典型的host网络配置的`docker-compse`文件如下:

```yml
version: "3.7"
services:
  example_go_grpc_grpc_service1:
    image: hsz/example-go-grpc:0.0.2
    environment:
      EXAMPLE_GO_GRPC_ADDRESS: "0.0.0.0:500"
    deploy:
      mode: global
    networks:
      - mynetwork

networks:
  mynetwork:
    external: true
    name: host
```

在上面的例子中我们将服务挂载到了`host`网络上,这样服务就是使用的host网络部署的了.使用host网络的注意点有:

+ 不要再申明`ports`,host网络无法做端口映射.容器中绑定了什么端口就会在宿主机中绑定什么端口
+ 部署时只能使用`global`模式.
+ 不要混用`host`网络和其他网络,避免造成混乱

host网络的优缺点都非常明显.优点就是性能,毕竟就是使用的宿主机网络,缺点就是管理的复杂度,因为它在管理方面基本就只有批量部署的能力了.


## 网络性能测试

这个部分我们使用3台8g版本树莓派4b构建warm集群.一台2015款macbook air作为外部机器来做这个实验

下面是几种情况下的bechmark

| 客户端位置  | 服务端位置                                                             | qps |
| ----------- | ---------------------------------------------------------------------- | --- |
| macbook air | 全部部署在单节点的overlay网络,3个实例                                  |
| macbook air | global方式部署在各个节点的overlay网络,3个实例                          |
| macbook air | global方式部署在各个节点,且使用host模式开放端口的的overlay网络,3个实例 |
| macbook air | global方式部署在各个节点的host网络,3个实例                             |
