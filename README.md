# 镜像构建优化-go语言版

这个例子通过文中的方法加快构建速度,减小构建后的镜像体积

+ 执行`bash build_image.sh`构造镜像
+ 执行`bash build_manifest.sh`构造清单
+ 执行`bash push_manifest.sh`上传清单
+ 执行`bash run_container.sh`使用镜像执行容器

这样打开浏览器http://localhost:5000就可以看到helloworld字样.
