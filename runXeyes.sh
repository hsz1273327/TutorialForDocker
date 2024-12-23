#!/usr/bin/env bash

CONTAINER=xeyes

# 获取当前本机的内网ip作为作为容器环境变量`DISPLAY`的host部分
# 100 - 200间找个随机数,作为容器环境变量`DISPLAY`的端口
DISP_NUM=$(jot -r 1 100 200)  
# 6000+上面的随机数,构造为TCP监听的端口
PORT_NUM=$((6000 + DISP_NUM)) 

socat TCP-LISTEN:${PORT_NUM},reuseaddr,fork UNIX-CLIENT:\"$DISPLAY\" 2>&1 > /dev/null &

docker run \
    --rm \
    -e DISPLAY=host.docker.internal:$DISP_NUM \
    $CONTAINER

# 回收socat的转发服务
kill %1 