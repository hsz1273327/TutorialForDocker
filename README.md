# 健康检测

这是演示在构造镜像时设置健康检查的例子.

+ 执行`bash build_image.sh`构造镜像
+ 执行`bash run_container.sh`使用镜像执行容器

这样打开浏览器http://localhost:5000就可以看到helloworld字样.

使用`docker ps`可以在展示的`STATUS`信息中看到有`health: starting`字样,标明健康检查被激活了.
