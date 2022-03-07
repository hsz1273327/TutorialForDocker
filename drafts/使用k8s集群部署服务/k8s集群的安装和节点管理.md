# k8s集群的安装和节点管理

k8s有许多集成安装工具(发行版),他们的核心都是k8s,区别往往只是选择的组件不同,这里我推荐自建集群的话使用[k3s](https://rancher.com/docs/k3s/latest/en/),它是一个精简版的k8s发行版,且主要面对边缘环境,因此资源占用相对小.

## linux上的集群安装


## mac上安装调试环境

如果我们使用的是mac,我们也可以在其中借助[k3d](https://github.com/k3d-io/k3d)在docker中安装k3s用于调试.注意个人并不推荐使用docker desktop上自带的k8s环境,因为在国内因为墙的问题根本跑不起来.

mac上安装调试环境的需要:

1. 安装[docker desktop](https://docs.docker.com/desktop/mac/install/),且k8s处于关闭状态
2. 安装`k3d`,`helm`和`kubectl`,一般我们用[home brew](https://blog.hszofficial.site/recommend/2016/06/28/%E5%8C%85%E7%AE%A1%E7%90%86%E5%B7%A5%E5%85%B7homebrew/)安装

    ```bash
    brew install k3d helm@3 kubectl
    ```

在安装好以上工具后只需要执行`k3d cluster create [cluster_name] [options]`就可以创建一个k3s集群了.我们可以直接使用`kubectl`工具控制集群

要删除集群也很简单的使用`k3d cluster delete cluster_name`来删除集群,用`k3d cluster list`查看已经存在的k8s集群和其状态.

