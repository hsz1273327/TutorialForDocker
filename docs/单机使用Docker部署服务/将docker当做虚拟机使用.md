# 将docker当做虚拟机使用

docker内是可以跑完整linux操作系统的,因此有一种邪道用法就是将docker当虚拟机用,直接在容器中跑linux,然后进入其中做各种操作.当然常规情况下就仅限于针对linux系统.

但最近有人开源了windows和macos的基镜像,这让把docker当windows10,windows 11或macos虚拟机也成为了可能.不过,由于这套基镜像基于[kvm技术](https://linux-kvm.org/page/Main_Page),目前支持该技术的只有win11和linux,因此这一套工具目前只能在

+ linux原生docker engine环境
+ win11 docker desktop环境

这两种环境下使用.不用kvm技术当然并不是真的无法使用,而是慢到没有使用价值.

说道使用价值,其实这套工具对于不同的操作系统价值确实并不一样.

+ 对于windows,windows上已经有了官方的wsl这个linux虚拟机,一般也不太需要额外的macos环境或者别的windows环境
+ 对于macos,有terminal一般连linux虚拟机都用不着,但一些软件只有windows平台,这时候可能需要一个windows虚拟机.不过很可惜,这套没法使用.
+ 对于linux桌面操作系统,由于生态真的挺缺失的,这套工具是真的有用武之地的,尤其是windows.

本文将以linux原生docker engine环境为基础介绍如何使用这套工具.

## 需要的环境

上面也说了这套工具并不是所有地方都可以使用,我们需要满足如下几点才能使用

1. 硬件上,需要是x86_amd64架构或arm64架构处理器的pc.
2. 系统上,需要支持kvm.查看你的系统是否支持kvm可以像下面这样

    ```bash
    sudo apt install cpu-checker
    sudo kvm-ok
    ```

    如果报错则表明kvm无法使用骂我们需要重启机器进入`BIOS`中检查`虚拟化扩展(Intel VT-x或AMD SVM)`是否已启用.如果还是不行,试试在启动容器的docker compose中加上`privileged: true`再试试.

3. 对于macos,最好硬件是老x86mac对应的cpu,amd的似乎支持都不太好.

## 基本用法

这套镜像都有一套相同的特征

+ 镜像是安装工具.运行镜像执行的是安装操作,我们可以选择系统版本,在安装完成后容器中才是对应的操作系统
+ 通过浏览器连接本地端口(默认是`8006`)来在浏览器中操作gui

## macos虚拟机

macos本身支持x86_amd64架构和arm64架构,我们都可以使用镜像[dockur/macos](https://github.com/dockur/macos)

```yml
services:
    macos:
        image: dockurr/macos
        container_name: macos
        environment:
            VERSION: "13" # 推荐13即Ventura,这个性能比较好
            DISK_SIZE: "256G"
            RAM_SIZE: "8G"
            CPU_CORES: "4"
            ARGUMENTS: "-device usb-host,vendorid=0x1234,productid=0x1234" #有usb调用就加
        volumes:  # 需要指定位置给wmacos做硬盘可以加上,不用自己创建文件夹,容器会自己创建
            - /var/osx:/storage
        devices:
            - /dev/kvm
            - /dev/net/tun
            - /dev/bus/usb  #油usb调用就加
        cap_add:
            - NET_ADMIN
        ports:
            - 8006:8006 # webui端口
            - 5900:5900/tcp
            - 5900:5900/udp
        stop_grace_period: 2m
```

之后用浏览器进入`http://localhost:8006`,在浏览器中完成安装:

1. 选中`Disk Utility`,然后找到最大的那块命名为`Apple Inc. VirtIO Block Media disk`的盘,把它取个名字擦除成`APFS`格式.
2. 重新进入初始页面,选`Reinstall macOS`一路同意,最后选我们取名字那块盘把系统安装上就好了.

## window虚拟机

需要注意windows是分`windows`和`arm-windows`的,他们实际是两种操作系统.你需要根据你的cpu指令集选择合适的.

如果是`x86_amd64`架构可以使用[dockur/windows](https://github.com/dockur/windows)镜像

```yml
services:
    windows:
        image: dockurr/windows
        container_name: windows
        environment:
            VERSION: "11" # 推荐11即Windows 11 Pro
            USERNAME: "bill" #指定用户名
            PASSWORD: "gates" #指定密码
            LANGUAGE: "Chinese" #指定语言
            DISK_SIZE: "256G"
            RAM_SIZE: "8G"
            CPU_CORES: "4"
            ARGUMENTS: "-device usb-host,vendorid=0x1234,productid=0x1234" #油usb调用就加
        volumes: # 需要指定位置给window做硬盘可以加上,不用自己创建文件夹,容器会自己创建
            - /var/win:/storage # 系统盘
            -  /home/user/example:/data #和宿主机共享的空间
        devices:
            - /dev/kvm
            - /dev/net/tun
            - /dev/bus/usb  #油usb调用就加
        cap_add:
            - NET_ADMIN
        ports:
            - 8006:8006
            - 3389:3389/tcp
            - 3389:3389/udp
        stop_grace_period: 2m
```

如果是arm64架构,则需要使用[dockur/windows-arm](https://github.com/dockur/windows-arm)镜像

```yml
services:
    windows:
        image: dockur/windows-arm
        container_name: windows
        environment:
            VERSION: "11" # 推荐11即Windows 11 Pro
            USERNAME: "bill" #指定用户名
            PASSWORD: "gates" #指定密码
            LANGUAGE: "Chinese" #指定语言
            DISK_SIZE: "256G"
            RAM_SIZE: "8G"
            CPU_CORES: "4"
            ARGUMENTS: "-device usb-host,vendorid=0x1234,productid=0x1234" #油usb调用就加
        volumes: # 需要指定位置给window做硬盘可以加上
            - /var/win:/storage # 系统盘
            -  /home/user/example:/data #和宿主机共享的空间
        devices:
            - /dev/kvm
            - /dev/net/tun
            - /dev/bus/usb  #油usb调用就加
        cap_add:
            - NET_ADMIN
        ports:
            - 8006:8006
            - 3389:3389/tcp
            - 3389:3389/udp
        stop_grace_period: 2m
```

之后用浏览器进入`http://localhost:8006`,就和正常安装windows一样,各种选择各种下一步就可以安装完成了.

如果我们在ubuntu中用`docker compose up`启动windows虚拟机会发现报错起不起来,这是因为会和ubuntu的`远程桌面`端口冲突,关闭`远程桌面`即可.