# 开发一个基于Nginx的静态网站

在之前的篇幅中我们已经尝试了一个最简单的静态服务器,我们访问宿主机的对应容器端口即可看到"Done!"字样.

接着我们来对它进行修改,让它可以用于前端开发,让我们从Dockerfile开始:

## 构建镜像

Dockerfile:
```Dockerfile
# Version: 0.0.2
FROM centos:latest
MAINTAINER hsz "hsz1273327@gmail.com"
ENV REFRESHED_AT 2016-06-10
RUN yum update
ADD nginx.repo /etc/yum.repos.d/nginx.repo
RUN yum install -y nginx
RUN mkdir -p /var/www/html
RUN cp /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
ADD conf/global.conf /etc/nginx/conf.d/default.conf
ADD conf/nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
```


global.config:

```config
server {
        listen          0.0.0.0:80;
        server_name     _;

        root            /var/www/html/website;
        index           index.html index.htm;

        access_log      /var/log/nginx/default_access.log;
        error_log       /var/log/nginx/default_error.log;
}
```
nginx.config:

```config
user root;
worker_processes 4;
pid /run/nginx.pid;
daemon off;

events {  }

http {
  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  keepalive_timeout 65;
  types_hash_max_size 2048;
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  access_log /var/log/nginx/access.log;
  error_log /var/log/nginx/error.log;
  gzip on;
  gzip_disable "msie6";
  include /etc/nginx/conf.d/*.conf;
}

```

静态文件我放在www文件夹下,可以看本节的代码获取
接着运行

```shell
docker build -t=hsz/static_web:v2 .
```
这个镜像将上面的两个配置文件写入进去了,这样Nginx会使用`/var/www/html/website`文件夹下的静态html文件作为访问时的传输数据(访问根路径).

我们也关闭了nginx的守护进程运行功能.


## 运行容器

接着我们该运行这个镜像的容器了.

```shell
docker run -d -p 80 --name website \
-v $PWD/www:/var/www/html/website \
hsz/static_web:v2 nginx
```

-v表示挂载一个外部磁盘空间到镜像内部某一地址,格式是<宿主机>:<镜像>

ps:在mac下因为本身docker跑在虚拟机中所以无法挂载,从这边开始我们使用阿里云上的vps来做实现.


这样我们可以通过修改宿主机的www文件夹下的内容来做静态网站了
