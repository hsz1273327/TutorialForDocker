# Version: 0.0.1
FROM centos:latest
MAINTAINER hsz "hsz1273327@gmail.com"
RUN yum update
RUN yum install yum install wget  make gcc gcc-c++ zlib-devel openssl openssl-devel pcre-devel kernel keyutils  patch perl
RUN wget http://download.redis.io/releases/redis-3.2.1.tar.gz
RUN tar xvf redis-3.2.1.tar.gz
WORKDIR redis-3.2.1
RUN make
EXPOSE 6379
ENTRYPOINT ["src/redis-server"]
CMD []
