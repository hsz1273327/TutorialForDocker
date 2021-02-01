# 单机条件下网络性能比较

docker单机环境部署的例子.

本项目顺便构建了`iperf3:3.7`版本在arm64,armv7和amd64平台上的[镜像](hsz1273327/iperf3:3.7)

收录的docker-compose文件包括

同一机器上:

文件名|服务端|客户端|部署位置
---|---|---|---
`docker-compose_bridge_bridge.yml`|bridge|bridge|相同机器
`docker-compose_bridge_host.yml`|bridge|host|相同机器
`docker-compose_host_bridge.yml`|host|bridge|相同机器
`docker-compose_host_host.yml`|host|host|相同机器
`docker-compose_host_c.yml`|---|host|不同机器
`docker-compose_bridge_c.yml`|---|bridge|不同机器