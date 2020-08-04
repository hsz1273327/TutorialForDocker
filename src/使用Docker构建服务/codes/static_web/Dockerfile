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
