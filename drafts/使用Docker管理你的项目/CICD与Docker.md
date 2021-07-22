# CI/CD与Docker

CI/CD几乎是现代软件工程的标配,我们可以通过定义任务管道自动的将测试,校验,打包,部署完成.而且这些是非侵入式的,这就让开发和运维解耦了.开发人员只需要写好程序,其他工作将交给程序自动完成.

本文将以jenkins作为CI/CD工具,借助gitea作为代码仓库,配合harbor以及portainer的api来实现完整的CI/CD管道.不了解这两个工具的朋友可以看我博客[使用Github开始你的开源生涯系列文章](https://blog.hszofficial.site/series/%E4%BD%BF%E7%94%A8Github%E5%BC%80%E5%A7%8B%E4%BD%A0%E7%9A%84%E5%BC%80%E6%BA%90%E7%94%9F%E6%B6%AF/)中的这[使用Git管理你的代码](https://blog.hszofficial.site/introduce/2020/10/31/%E4%BD%BF%E7%94%A8Git%E7%AE%A1%E7%90%86%E4%BD%A0%E7%9A%84%E4%BB%A3%E7%A0%81)和[使用Jenkins代替GithubActions自动化工作流](https://blog.hszofficial.site/recommend/2020/12/02/%E4%BD%BF%E7%94%A8Jenkins%E4%BB%A3%E6%9B%BFGithubActions%E8%87%AA%E5%8A%A8%E5%8C%96%E5%B7%A5%E4%BD%9C%E6%B5%81/)两篇文章.

本文也是接在这系列文章之后的内容,毕竟现今的CI/CD几乎docker已经不可能缺席了.

## Docker体系下的CI/CD管道

在Docker体系下我们的CI/CD管道可以分为5步:

1. 代码风格(静态类型)校验
2. 单元测试
3. 镜像打包
4. 镜像漏洞扫描
5. 镜像部署

`使用Jenkins代替GithubActions自动化工作流`一文中我们已经可以用其中例子依葫芦画瓢完成1,2两步了,而harbor中我们也可以直接配置镜像漏洞扫描,剩下的我们则会在本文中介绍.

本文将在gitea上创建项目`test/helloworld`,用之前[golang版本helloworld](https://github.com/hsz1273327/TutorialForDocker/tree/example-image-build-opt-build-go)的代码做例子演示

Docker体系下的CI/CD管道

### 自动化打包镜像

我们希望自动化打包可以使用buildx,打包跨平台的镜像,因此我们需要使用镜像[jdrouet/docker-with-buildx](https://hub.docker.com/r/jdrouet/docker-with-buildx),这个镜像是`docker:dind`的扩展.

此外我们需要将登录我们harbor的信息注册到jenkins中.下面是`Jenkinsfile`示例

```Jenkinsfile
pipeline {
  agent none
  environment {
    VERSION = '0.0.0'
    REGISTRY = 'xxxx'
    NAMESPACE = 'test'
    ARTIFACT_NAME = 'hellodocker'
    ARTIFACT_PLATFORMS = 'linux/amd64,linux/arm64'
  }
  stages {
    stage('BuildArtifact') {
      when {
        anyOf {
          branch 'test'
          branch 'dev'
          branch 'master'
        }
      }
      agent {
        docker {
          image 'jdrouet/docker-with-buildx:latest'
        }
      }
      steps {
        echo '[BuildArtifact] buildx init'
        sh 'docker buildx create --use'
        echo '[BuildArtifact] login harbor'
        withCredentials([usernamePassword(credentialsId: 'xxxxx', usernameVariable: 'HARBOR_USER',passwordVariable: 'HARBOR_PWD')]) {
            sh 'docker login -u "$HARBOR_USER" -p "$HARBOR_PWD" $REGISTRY'
        }
        echo '[BuildArtifact] start build'
        sh 'docker buildx build --platform $ARTIFACT_PLATFORMS  -t $REGISTRY/$NAMESPACE/$ARTIFACT_NAME:$VERSION -t $REGISTRY/$NAMESPACE/$ARTIFACT_NAME:latest --push .'
        echo '[BuildArtifact] build done'
      }
    }
  }
}
```

这样推送后就可以在镜像仓库中找到了,如果我们的镜像仓库还设置了自动扫面,那么扫描工作也是自动化的了.

### 镜像部署

镜像部署要不要自动化,在什么情况下要自动化实际上是有争论的.主要的争论点在于如何平衡自动化持续交付和人工校验修改配置.我们可以将情况分为如下几大类:

1. 第一次stack部署
2. 已存在的stack只更新配置
3. 已存在的stack只更新镜像
4. 已存在的stack同时更新镜像和配置

很明显1,2,4只能手动部署,而3则可以完全自动化部署更新.

#### 使用portainer关联gitea上的仓库实现

获取SwarmID
http GET :9000/api/endpoints/1/docker/swarm \
"Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwidXNlcm5hbWUiOiJhZG1pbiIsInJvbGUiOjEsImV4cCI6MTQ5OTM3NjE1NH0.NJ6vE8FY1WG6jsRQzfMqeatJ4vh2TWAeeYfDhP71YEE"

## 镜像标签与版本管理

docker系体下镜像标签一版用于管理应用版本.但docker镜像标签的特点是同一个镜像可以有多个标签,因为实际上标签真的就是标签而已,镜像的唯一标识是一串hash字符串.针对这一特点,再结合git的常用工作流就有了不同的思路来管理容器使用的应用版本(工作流带来的路径依赖).但无论哪种方式,我的建议是镜像无论如何都要有明确的版本号,并且只给可以用于生产的镜像打`latest`标签.我们就针对`使用Git管理你的代码`一文中介绍的3种常见工作流来谈下在各自的工作流中怎么打标签

### [主干分支策略](https://blog.hszofficial.site/introduce/2020/10/31/%E4%BD%BF%E7%94%A8Git%E7%AE%A1%E7%90%86%E4%BD%A0%E7%9A%84%E4%BB%A3%E7%A0%81/#%E4%B8%BB%E5%B9%B2%E5%88%86%E6%94%AF%E7%AD%96%E7%95%A5trunk-baseddevelopment)及其变种的镜像标签管理

这种工作流的特点是`master`分支由于有频繁的merge而无法保证一直可用,`release-<大版本>`分支由于也会有从`master`分支合并进来的情况只能大概率保证可用.只有打tag留档的才能保证确实可用.因此我们可以用如下策略构造镜像

| 分支                 | 镜像标签命名             | 期望                                              | 管道主要步骤 |
| -------------------- | ------------------------ | ------------------------------------------------- | ------------ |
| `release-<大版本号>` | `release-<版本号>`标签   | 预发版环境可用,用于`端到端测试`和`消费者驱动测试` | 1,2,3,4,5    |
| `maste`              | `dev-<版本号>`标签       | 允许不能使用,更多的用于本地`单元测试`和`服务测试` | 1,2,3        |
| 各种tag              | `<版本号>`及`latest`标签 | 线上环境确保可用                                  | 1,2,3,4,5    |

### [GithubFlow](https://blog.hszofficial.site/introduce/2020/10/31/%E4%BD%BF%E7%94%A8Git%E7%AE%A1%E7%90%86%E4%BD%A0%E7%9A%84%E4%BB%A3%E7%A0%81/#githubflow)及其变种的镜像标签管理

这种工作流特点是通过`pull request`强制要求code review来确保合并进`master`来代码后可用,因此每次merge后就应该重新打包更新版本.这种工作流的镜像标签策略也是最简单的:

| 分支     | 镜像标签命名               | 期望             | 管道主要步骤 |
| -------- | -------------------------- | ---------------- | ------------ |
| `master` | `<commit号>`及`latest`标签 | 线上环境确保可用 | 1,2,3,4,5    |

至于单元测试和服务测试使用的镜像,则应该由pull request的发起者自己构造,构造管道的主要步骤就是1,2,3三步,这主要是两种类型

1. 本地仓库的`feature`分支:使用分支名作为镜像标签名打包镜像
2. fork出去仓库的分支(通常是`master`分支):一般使用维护组织的名字作为镜像标签名

### [gitflow](https://blog.hszofficial.site/introduce/2020/10/31/%E4%BD%BF%E7%94%A8Git%E7%AE%A1%E7%90%86%E4%BD%A0%E7%9A%84%E4%BB%A3%E7%A0%81/#gitflow)及其变种的镜像标签管理

这种工作流中应用版本非常明确,分支角色也相当明确,可以看到`master`分支上永远都是可用版本;`release`分支上永远是预发布版本,通常也应该是可用版本;而`dev`分支则是用于merge各种特性和hotfix的分支,通常它的目的就是让应用可用,为了验证其可符合要求,我们也会给上面的节点打镜像,至于其他分支就没必要打镜像了.这样就非常明确了.

| 分支      | 镜像标签命名             | 期望                                              | 管道主要步骤 |
| --------- | ------------------------ | ------------------------------------------------- | ------------ |
| `master`  | `<版本号>`及`latest`标签 | 线上环境确保可用                                  | 1,2,3,4,5    |
| `release` | `release-<版本号>`标签   | 预发版环境可用,用于`端到端测试`和`消费者驱动测试` | 1,2,3,4,5    |
| `dev`     | `dev-<版本号>`标签       | 允许不能使用,更多的用于本地`单元测试`和`服务测试` | 1,2,3        |

### 部署镜像时的标签选择

一般是两种思路,这两种方式各有优缺点:

1. 永远只部署`latest`标签的镜像
    + 优点:
        + 是部署的stack可以不用改,每次原样update就好
    +缺点:
        + 镜像版本不是显式的,不够明确,这会让更新和回滚操作难以辨识是否成功
        + 更新会带来许多标签为`<none>`的虚悬镜像,需要定期使用`docker system prune -f`清理虚悬镜像

2. 部署时指定版本号的镜像
    + 优点:
        + 部署明确,利于观测更新和回滚操作
    + 缺点:
        + 更新无法体现到部署时的stack文件上.
