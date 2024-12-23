#!/usr/bin/env bash

CONTAINER=xeyes

# 获取当前本机的内网ip作为作为容器环境变量`DISPLAY`的host部分
# IPADDR=$(ifconfig $NIC | grep "inet " | awk '{print $2}')
# 100 - 200间找个随机数,作为容器环境变量`DISPLAY`的端口
DISP_NUM=0

docker run \
    --rm \
    -e DISPLAY=host.docker.internal:$DISP_NUM \
    $CONTAINER
