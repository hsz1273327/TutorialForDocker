# docker容器调用gpu

,但在`docker 19.03`之前如果我们想使用gpu,那么我们必须使用`nvidia-docker`这个docker的实现,而在之后docker已经原生支持gpu了,我们可以声明`nvidia-container-runtime`的位置来直接支持使用gpu.本文以`docker 19.03`以后的版本为准,因此就不介绍`nvidia-docker`了.