# 单机条件下挂载nfs作为共享存储

docker单机环境部署的例子.

使用前提:

1. 有nfs服务器
2. 宿主机安装了nfs-utils

使用步骤:

1. 外部创建nfs挂载.并命名为`nfssharev3`

2. 执行compose`docker-compose.yml`,它会监听nfssharev3中挂载的`test`文件夹内的文件变化
