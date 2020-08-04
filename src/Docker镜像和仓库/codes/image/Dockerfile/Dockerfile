FROM centos:latest
MAINTAINER hsz "hsz1273327@gmail.com"
RUN yum update
ADD nginx.repo /etc/yum.repos.d/nginx.repo
RUN yum install -y nginx
RUN echo "done!" > /usr/share/nginx/html/index.html
EXPOSE 80
