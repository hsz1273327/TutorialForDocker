# 多阶段构建

这个例子改用golang来演示.

这是演示在构造镜像时设置健康检查的例子.

+ 执行`bash build_image.sh`构造镜像
+ 执行`bash build_manifest.sh`构造清单
+ 执行`bash push_manifest.sh`上传清单
+ 执行`bash run_container.sh`使用镜像执行容器

这样打开浏览器http://localhost:5000就可以看到helloworld字样.
