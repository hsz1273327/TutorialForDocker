# Registry

这部分将讲解怎么搭建私有Registry,公有资源虽好但有你懂的墙的问题,而且很多时候我们的镜像不希望公开的话,私有Registry就是很好的措施了,Docker Hub开源了registry,我们可以随时自己搭建自己的Registry.

目前Registry还没有可视化界面面,只能通过api服务器的方式来运行.

要使用Registry只要直接跑Registry容器即可,注意需要绑定端口.

现在的Registry有俩版本
+ 第一版v1是python写的,成熟稳定
+ 第二版v2是go写的,高性能更加健壮

mac上使用Registry明显是个不靠谱的主意,我们在阿里云上为自己建一个Registry吧~~

## 阿里云上建立私有Registry v1

我自己有一台乞丐版阿里云vps,上面跑的centos,那么我们开始吧

各种依赖安装好后只要pull下官方的registry:last,然后运行容器即可.

## 上传镜像

上传镜像先要给镜像打好标签`docker tag <id> <tag>`

tag格式为:<host>:<port>/<img>

上传镜像只需要实用`docker push <tag>`即可

需要注意的是如果tag没有指定host和port那么它将默认push到Docker hub上

如果只是如上的设置并不能成功的将镜像上传,因为客户端docker必须可以识别这些私有的registry地址.
我们必须进行额外的客户端设置才可以实现

### linux端设置

修改`/etc/default/docker`文件,加入这句

```shell
DOCKER_OPTS="$DOCKER_OPTS --insecure-registry={你的仓库地址}"
```

之后再重启docker服务

```shell
service docker restart
```
这样你就可以在linux端上传了

### 在mac端设置

mac比较特殊,它的docker实际上是跑在一个虚拟机上,我们必须通过docker-machine的才可以设置:


```shell
docker-machine ssh default "echo $'EXTRA_ARGS=\"--insecure-registry {你的仓库地址}\"' | sudo tee -a /var/lib/boot2docker/profile && sudo /etc/init.d/docker restart"
```
## 搜索镜像

我们可以通过registry提供的restful api来搜索查看镜像:
一种是直接用docker查看:
```shell
docker search {你的仓库地址}/{镜像名}[:标签]
```
也可以直接利用浏览器或者http工具查看所有的镜像
```shell
curl {你的仓库地址}/v1/search/
```

## 阿里云上建立私有Registry v2

我自己有一台乞丐版阿里云vps,上面跑的centos,那么我们开始吧

各种依赖安装好后只要pull下官方的registry:2,然后运行容器即可.

上传拉取搜索都是差不多的,我把他的api找了下,方便查看

api|Entity|说明
---|---|---
`GET	/v2/`|	Base|	Check that the endpoint implements Docker Registry API V2.
`GET	/v2/<name>/tags/list`|	Tags|	Fetch the tags under the repository identified by name.
`GET	/v2/<name>/manifests/<reference>`	|Manifest	|Fetch the manifest identified by name and reference where reference can be a tag or digest. A HEAD request can also be issued to this endpoint to obtain resource information without receiving all data.
`PUT	/v2/<name>/manifests/<reference>`	|Manifest|	Put the manifest identified by name and reference where reference can be a tag or digest.
`DELETE	/v2/<name>/manifests/<reference>`	|Manifest|	Delete the manifest identified by name and reference. Note that a manifest can only be deleted by digest.
`GET	/v2/<name>/blobs/<digest>`	|Blob	|Retrieve the blob from the registry identified by digest. A HEAD request can also be issued to this endpoint to obtain resource information without receiving all data.
`DELETE	/v2/<name>/blobs/<digest>`|	Blob|	Delete the blob identified by name and digest
`POST	/v2/<name>/blobs/uploads/`	|Initiate Blob Upload|	Initiate a resumable blob upload. If successful, an upload location will be provided to complete the upload. Optionally, if the digest parameter is present, the request body will be used to complete the upload in a single request.
`GET	/v2/<name>/blobs/uploads/<uuid>`|	Blob Upload|	Retrieve status of upload identified by uuid. The primary purpose of this endpoint is to resolve the current status of a resumable upload.
`PATCH	/v2/<name>/blobs/uploads/<uuid>	`|Blob Upload|	Upload a chunk of data for the specified upload.
`PUT	/v2/<name>/blobs/uploads/<uuid>	`|Blob Upload|	Complete the upload specified by uuid, optionally appending the body as the final chunk.
`DELETE	/v2/<name>/blobs/uploads/<uuid>	`|Blob Upload|	Cancel outstanding upload processes, releasing associated resources. If this is not called, the unfinished uploads will eventually timeout.
`GET	/v2/_catalog`	|Catalog|	Retrieve a sorted, json list of repositories available in the registry.
