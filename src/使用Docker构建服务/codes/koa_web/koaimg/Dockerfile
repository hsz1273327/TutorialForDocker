# Version: 0.0.1
FROM centos:latest
MAINTAINER hsz "hsz1273327@gmail.com"
RUN yum update
ADD node-v4.4.5-linux-x64.tar.xz node4
RUN mkdir -p /opt/webapp
EXPOSE 3001
ENV PATH $PATH:/node4/node-v4.4.5-linux-x64/bin
WORKDIR /opt/webapp
CMD ["npm","run","app-dev"]
