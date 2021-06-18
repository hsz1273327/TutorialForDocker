# log分析与监控

本文虽然写在单机部分,但整体架构和使用的工具可以直接扩展到其他集群模式,因此本文所述后面不会再重复,只会针对不同的集群环境有针对性的调整架构.

## log数据的处理思路

log收集虽然不会直接影响部署服务,但会很大程度上影响业务发展和优化的方向,可以说极其有价值.一般来说我们会将log数据当作一般的数据来处理,也就是会按所处生命周期中的不同位置进行不同的处理.

针对log分析和监控这个场景,我们大致可以像下面这样定义数据阶段

| 阶段   | 阶段时限     | 主要用途                   |
| ------ | ------------ | -------------------------- |
| 热数据 | 1天内的数据  | 监控告警                   |
| 温数据 | 30天内的数据 | 分析                       |
| 冷数据 | 30天外的数据 | 制作季度/年度报告,数据归档 |

在使用docker容器技术这个条件下,我们会将所有的相关组件全部使用docker部署.同时尽量使用已经成熟或者官方推荐的方案.
针对业务log数据,docker默认使用的driver是`json-file`,它可以将stdout和stderr输出的文本收集到json格式的文本文件中存放在宿主机的特定位置.我们需要通过`docker logs`这类专用命令才能看它,所以基本上这种方式收集到的log很难用于分析.

docker官方提供的`Fluentd`driver则相对更加实用,我们可以用它配合[Fluentd](https://www.fluentd.org/)或者[Fluentd bit](https://docs.fluentbit.io/manual/)收集log,然后借助EFK工具栈统计和分析这些log,并用Prometheus监控业务数据,用Grafana做可视化和异常警告.

而针对宿主机的运行状态数据,我们可以使用[cadvisor](https://github.com/google/cadvisor)来随时观察,同时由于其有RESTful接口,所以也可以用[Prometheus](https://prometheus.io/)监控业务数据,用Grafana做可视化和异常警告.

而针对其他系统组件的运行状态数据,我们就需要去找对应的[exporter](https://prometheus.io/docs/instrumenting/exporters/),有的组件比如envoy自己就带与Prometheus对接的接口

而长期的log落库则可以通过定期的将数据导入冷数据仓库(比如对象存储,比如hdfs)中实现

因此一个基本的框架就出来了

| 步骤                | 场景             | 工具                               |
| ------------------- | ---------------- | ---------------------------------- |
| log收集             | 业务log          | `Fluentd`/`Fluentd bit`            |
| log收集             | 系统log          | `cadvisor`/各种组件的对应接口,各种 |
| 热数据log汇总       | 业务log          | `elasticsearch`                    |
| 热数据log指标汇总   | 业务log          | `Prometheus server`                |
| 热数据log指标汇总   | 系统log          | `Prometheus server`                |
| 热数据log监控和警告 | 业务log          | `Grafana`                          |
| 热数据log监控和警告 | 系统log          | `Grafana`                          |
| 温数据log汇总       | 业务log          | `elasticsearch`                    |
| 温数据log汇总       | 系统log          | `elasticsearch`                    |
| 温数据log分析       | 业务log          | `kibana`                           |
| 温数据log分析       | 系统log          | `kibana`                           |
| 冷数据log归档       | 业务log和系统log | 对象存储或者hdfs                   |
| 冷数据log分析       | 业务log和系统log | spark或者dask                      |

我们可以每天定时(比如早上2点到3点)从elasticsearch中将前一天的数据使用列存储格式比如`Parquet`保存到对象存储或者hdfs中.然后固定删除30天前的elasticsearch中的数据

## 业务log的规范

业务log分析是一个系统工程,除了这些硬件的搭建外,更重要的是规范化.一般来说生产环境不会常打log,而且会把log级别设置在info以上,而测试环境则会用debug等级的log进行调试.

每个log应该都是结构化数据,包含必须包含一些特定信息可以统一的查询到信息,比如:`app_name`,`app_version`,`event`三个字段用于定位事件发生的位置,`prey_app`,`prey_app_version`,`prey`,`prey_query`用于指明引起事件的调用方信息,以及如果是报错还应该把错误类型(`err_type`)和错误信息(`err_msg`)报出来等.

另外建议在有反向代理的情况下应用中就不要打印access_log了,access_log可以交给反向代理统一打.

这个需要根据业务进行全局设计,否则不同app间log信息割裂会造成维护困难.

## log收集

首先我们在`Fluentd`/`Fluentd bit`之间需要做出一个选择,`Fluentd bit`性能更好,占用更低,但功能不及`Fluentd`丰富,而`Fluentd`则功能更加全,可以进行简单的分析监控工作.一般来说我们用docker环境就还是用`Fluentd bit`更好

log收集根据部署位置我们可以分为两种:

1. 宿主机部署,这种情况下就是每台宿主机都要部署一个,一般是用于收集机器资源使用信息,容器的使用状态以及容器中业务log.
2. 单独部署,这种情况一般用于收集外部有状态服务,比如用于收集redis,pg,hdfs,envoy等的使用指标.这种服务最好是单独一台宿主机部署,如果机器不宽裕可以选择和要收集的服务部署在同一台机器上,如果这都做不到就部署在Prometheus server部署的机器上


下面我们就介绍下不同数据的收集

### 宿主机部署

#### 使用`Fluentd bit`收集业务数据

#### 启动``收集宿主机器资源指标信息

#### 通用的部署stack

#### 开启docker的`metrics-addr`用于支持收集容器状态指标

### 单独部署

#### 启动``收集redis指标信息
#### 启动``收集pg指标信息

#### 单独部署的stack


## 使用`Prometheus`收集指标数据



## 使用`Grafana`监控指标数据


## 使用`ElasticSearch`收集业务log

## 使用`Kibana`分析业务log