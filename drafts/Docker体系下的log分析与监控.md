# Docker体系下的log分析与监控

Docker无论是单机还是集群,作用都是服务的部署平台.部署平台最重要的就是确保业务健康稳定的运行.因此log分析与监控是基础中的基础.

log的收集,分析,监控虽然不会直接影响部署服务,但会很大程度上影响业务发展和优化的方向,可以说极其有价值.一般来说我们会将log数据当作一般的数据来处理,也就是会按所处生命周期中的不同位置进行不同的处理.

## log数据的处理思路

针对log分析和监控这个场景,我们大致可以像下面这样定义数据阶段

| 阶段   | 阶段时限     | 主要用途                   |
| ------ | ------------ | -------------------------- |
| 热数据 | 1天内的数据  | 监控告警                   |
| 温数据 | 30天内的数据 | 分析                       |
| 冷数据 | 30天外的数据 | 制作季度/年度报告,数据归档 |

在使用docker容器技术这个条件下,我们会将所有的相关组件全部使用docker部署.同时尽量使用已经成熟或者官方推荐的方案.
针对业务log数据,docker默认使用的driver是`json-file`,它可以将stdout和stderr输出的文本收集到json格式的文本文件中存放在宿主机的特定位置.我们需要通过`docker logs`这类专用命令才能看它,所以基本上这种方式收集到的log很难用于分析.

docker官方提供的`Fluentd`driver则相对更加实用,我们可以用它配合[Fluentd](https://www.fluentd.org/)或者[Fluentd bit](https://docs.fluentbit.io/manual/)收集log,然后借助EFK工具栈统计和分析这些log,并用Prometheus监控业务数据,用Grafana做可视化和异常警告.

而长期的log落库则可以通过定期的将数据导入冷数据仓库(比如对象存储,比如hdfs)中实现

对于log,我们要做的事情其实就4样:

1. log收集
2. log保存
3. log监控
4. log分析

再结合上面的数据生命周期,一个基本的框架就出来了

| 步骤                 | 场景             | 工具                               |
| -------------------- | ---------------- | ---------------------------------- |
| log收集              | 业务log          | `Fluentd`/`Fluentd bit`            |
| log收集              | 系统log          | `cadvisor`/各种组件的对应接口,各种 |
| 热数据log汇总        | 业务log          | `elasticsearch`                    |
| 热数据指标汇总       | 指标             | `Prometheus server`                |
| 热数据指标监控和警告 | 指标             | `Grafana`                          |
| 温数据log汇总        | 业务log          | `elasticsearch`                    |
| 温数据log汇总        | 系统log          | `elasticsearch`                    |
| 温数据log分析        | 业务log          | `kibana`                           |
| 温数据log分析        | 系统log          | `kibana`                           |
| 冷数据log归档        | 业务log和系统log | 对象存储或者hdfs                   |
| 冷数据log分析        | 业务log和系统log | spark或者dask                      |

## 业务log的规范

业务log分析是一个系统工程,除了这些硬件的搭建外,更重要的是规范化.一般来说生产环境不会常打log,而且会把log级别设置在info以上,而测试环境则会用debug等级的log进行调试.

每个log应该都是结构化数据,包含必须包含一些特定信息可以统一的查询到信息,比如:`app_name`,`app_version`,`event`三个字段用于定位事件发生的位置,`prey_app`,`prey_app_version`,`prey`,`prey_query`用于指明引起事件的调用方信息,以及如果是报错还应该把错误类型(`err_type`)和错误信息(`err_msg`)报出来等.

另外建议在有反向代理的情况下应用中就不要打印access_log了,access_log可以交给反向代理统一打.

这个需要根据业务进行全局设计,否则不同app间log信息割裂会造成维护困难.

## log收集

首先我们在`Fluentd`/`Fluentd bit`之间需要做出一个选择,fluentd和fluent-bit都是有Treasure Data公司赞助开发,目标是解决日志收集,处理和转发的问题.

这两个项目有很多相似之处,fluent-bit完全基于Fluentd体系结构和设计经验,从体系结构的角度来看,选择使用哪个取决于使用场景.我们可以对照下面的矩阵图进行考虑:


| 对比项   | fluentd                 | fluent-bit        |
| -------- | ----------------------- | ----------------- |
| 功能     | 日志收集,处理,聚合,警告 | 日志收集和处理    |
| 适用范围 | 容器/服务器             | 容器/服务器       |
| 构造语言 | C和Ruby                 | C                 |
| 程序大小 | 约40MB约                | 450KB             |
| 性能     | 一般性能                | 高性能            |
| 依赖关系 | 主要依赖gems            | 其它零依赖        |
| 插件支持 | 超过650个可用插件       | 大约35个可用插件  |
| 许可证   | Apache许可证2.0版       | Apache许可证2.0版 |

综合来看`Fluentd bit`性能更好,占用更低,但功能不及`Fluentd`丰富,而`Fluentd`则功能更加全,可以进行简单的分析监控工作.

根据使用场景我们可以这样搭配:

1. 不需要精细程度很高的log分析,主要以入库为需求的情况下使用`Fluentd bit`收集处理log,将pg作为output并用于分析,再外接Prometheus用于监控.
2. 需要精细程度更高的log分析时使用`Fluentd bit`收集处理log,将elasticsearch作为output并用于分析,再外接外接Prometheus用于监控.

可以看出基本上`Fluentd`是可选组件,而且基本只在前期过渡用得到,但`Fluentd bit`基本算是必选组件.

因此我们介绍`Fluentd bit`,`Fluentd`的聚合和警告本文就不介绍了,本文一步到位介绍`Fluentd bit`+`elasticsearch`+`Prometheus`的方案

`Fluentd bit`的工作流程如下:

![fluentdbit工作流程](../IMGS/fluentdbit/工作流程.jpg)

### 部署`fluentd bit`

fluentd bit官方镜像中已经给出了部署方式:

+ 部署`fluentd bit`

    ```bash
    docker run -p 127.0.0.1:24224:24224 fluent/fluent-bit:1.7 /fluent-bit/bin/fluent-bit -i forward -o stdout -p format=json_lines -f 1
    ```

+ 测试docker的`fluentd driver`

    ```bash
    docker run --log-driver=fluentd -t ubuntu echo "{\"event\":\"Testing a log message\"}"
    ```

### 配置`fluentd bit`

`fluentd bit`的镜像通过配置容器中的文件`/fluent-bit/etc/fluent-bit.conf`来确定配置.`fluentd bit`分为最多5段,其格式类似python的setup.cfg,使用`Sections`划分配置项,每个`Section`中用键值对`Daemon  off`的形式确定配置内容,不同之处在于键值对严格要求缩进.一个配置文件大致可以参考如下例子:

```conf
[SERVICE]
    Flush     1
    Log_Level info

[INPUT]
    NAME   dummy
    Dummy  {"tool": "fluent", "sub": {"s1": {"s2": "bit"}}}
    Tag    test_tag

[FILTER]
    Name          rewrite_tag
    Match         test_tag
    Rule          $tool ^(fluent)$  from.$TAG.new.$tool.$sub['s1']['s2'].out false
    Emitter_Name  re_emitted

[OUTPUT]
    Name   stdout
    Match  from.*
```

我们也可以通过命令行构造简单的配置,下面是参数flag:

| flag | 对应配置          |
| ---- | ----------------- |
| `-i` | `Input.Name`      |
| `-t` | `Input.Tag`       |
| `-p` | `Input.xxxx=xxxx` |
| `-o` | `Output.Name`     |
| `-m` | `Output.Match`    |

可以配置的`Sections`有如下枚举:

#### `SERVICE`配置段定义了服务的全局属性

下表中介绍了此版本可用的键

| 键                | 描述                                                                                          | 默认值    |
| ----------------- | --------------------------------------------------------------------------------------------- | --------- |
| `Flush`           | 以`seconds.nanoseconds`格式设置刷新时间.设置引擎将由输入插件进入的记录何时由输出插件输出      | `5`       |
| `Daemon`          | Fluent Bit是否应该作为守护(后台)进程运行                                                      | `Off`     |
| `Log_File`        | 可选日志文件的绝对路径.                                                                       | `stdout`  |
| `Log_Level`       | 设置日志级别.可选值为`error`/`warning`/`info`/`debug`/`trace`(必须构建时启用`WITH_TRACE`编译) | `info`    |
| `Parsers_File`    | parsers配置文件路径,配置段中可配置多个`Parsers_File`配置项                                    | ---       |
| `Plugins_File`    | plugins配置文件路径.plugins配置文件中可定义外部插件的路径                                     | ---       |
| `Streams_File`    | 流式处理器配置文件路径.                                                                       | ---       |
| `HTTP_Server`     | 是否启用内置 HTTP 服务                                                                        | `Off`     |
| `HTTP_Listen`     | HTTP 服务启用时,监听地址                                                                      | `0.0.0.0` |
| `HTTP_Port`       | `HTTP 服务的 TCP 端口`                                                                        | 2020      |
| `Coro_Stack_Size` | 设置协程栈大小(单位:字节).不要轻易修改此参数默认值                                            | `245`     |

这里比较需要关注的是`Parsers_File`,在docker环境下我们在stdout中以json格式输出的log`{"status": "up and running"}`在fluent bit中以如下形式进来:

```json
{"log":"{\"status\": \"up and running\"}\r\n","stream":"stdout","time":"2018-03-09T01:01:44.851160855Z"}
```

可以看出`log`字段内容并非json的object类型而是一个string,这里就需要定义一个`Parser`并将如下配置导入其中:

+ `docker_parser.conf`

```config
[PARSER]
    Name         docker
    Format       json
    Time_Key     time
    Time_Format  %Y-%m-%dT%H:%M:%S.%L
    Time_Keep    On
    # Command       |  Decoder  | Field | Optional Action   |
    # ==============|===========|=======|===================|
    Decode_Field_As    json     log
```

#### `INPUT`配置段定义数据源(与输入插件相关联)

一般来说在受用docker的场景下我们会使用的输入插件可能会有`forward`,`CPU Metrics`,`Memory Metrics`,`Network I/O Metrics`,`Disk I/O Metrics`,`Docker Metrics`输入插件.

> `forward`输入插件的配置项

这种输入插件是用于收集业务数据的.它的特点是tag是动态的,其配置项如下:

| 键                  | 描述                    | 默认值               |
| ------------------- | ----------------------- | -------------------- |
| `Name`              | 插件名                  | 必填,固定为`forward` |
| `Listen`            | 监听的地址              | `0.0.0.0`            |
| `Port`              | 监听的端口              | `24224`              |
| `Buffer_Chunk_Size` | buffer中每个chunk的大小 | `32KB`               |
| `Buffer_Max_Size`   | buffer最大值            | `Buffer_Chunk_Size`  |

`forward`会使用传入数据的`tag`字段来作为input的Tag,对应的在docker中就是log设置的`--log-opt tag="xxxx"`.在docker中我们可以通过设置模板来动态构造tag.具体的规则可以看[这个页面](https://docs.docker.com/config/containers/logging/log_tags/)

我们一般习惯上会把tag设置为`{{.Name}}`

> `CPU Metrics`

这个输入插件用于每隔一段事件收集宿主机的cpu使用信息.其配置项如下:

| 键              | 描述                                | 默认值           |
| --------------- | ----------------------------------- | ---------------- |
| `Name`          | 插件名                              | 必填,固定为`cpu` |
| `Interval_Sec`  | 每次获取信息的时间间隔,单位s        | `1`              |
| `Interval_NSec` | 每次获取信息的时间间隔,单位ns       | `0`              |
| `PID`           | 指定要监控的进程id,不指定则获取全部 | ---              |
| `Tag`           | 输入标签                            | ---              |

间隔时间由`Interval_Sec`和`Interval_NSec`共同决定,其公式为:

```txt
Total interval (sec) = Interval_Sec + (Interval_Nsec / 1000000000).
```

我们可以用如下命令验证:

```bash
docker run fluent/fluent-bit:1.7 /fluent-bit/bin/fluent-bit -i cpu -t my_cpu -o stdout -m '*'
```

其中结果中的字段含义如下:

| 键              | 说明                              |
| --------------- | --------------------------------- |
| `cpu_p`         | cpu的总使用情况                   |
| `user_p`        | 用户态cpu的使用情况               |
| `system_p`      | 操作系统内核态cpu使用情况         |
| `cpuN.p_cpu`    | 某个核的总使用情况                |
| `cpuN.p_user`   | 某个核的用户态cpu的使用情况       |
| `cpuN.p_system` | 某个核的操作系统内核态cpu使用情况 |

> `Memory Metrics`

每隔一定的时间间隔收集正在运行的系统的内存和交换区使用情况的信息,并报告内存总量和可用空间.其配置项如下:

| 键              | 描述                                | 默认值           |
| --------------- | ----------------------------------- | ---------------- |
| `Name`          | 插件名                              | 必填,固定为`mem` |
| `Interval_Sec`  | 每次获取信息的时间间隔,单位s        | `1`              |
| `Interval_NSec` | 每次获取信息的时间间隔,单位ns       | `0`              |
| `PID`           | 指定要监控的进程id,不指定则获取全部 | ---              |
| `Tag`           | 输入标签                            | ---              |

```txt
Total interval (sec) = Interval_Sec + (Interval_Nsec / 1000000000).
```

我们可以使用如下命令验证:

```bash
docker run fluent/fluent-bit:1.7 /fluent-bit/bin/fluent-bit -i mem -t memory -o stdout -m '*'
```

其中结果中的字段含义如下:

| 键           | 说明           |
| ------------ | -------------- |
| `Mem.total`  | 总内存空间     |
| `Mem.used`   | 已用内存空间   |
| `Mem.free`   | 未用内存空间   |
| `Swap.total` | 总交换区空间   |
| `Swap.used`  | 已用交换区空间 |
| `Swap.free`  | 可用交换区空间 |

> `Network I/O Metrics`

每隔一定的时间间隔收集正在运行的系统的网络io使用情况的信息,其配置项如下:

| 键              | 描述                          | 默认值             |
| --------------- | ----------------------------- | ------------------ |
| `Name`          | 插件名                        | 必填,固定为`netif` |
| `Interface`     | 指定网卡(必须指定)            | ---                |
| `Interval_Sec`  | 每次获取信息的时间间隔,单位s  | `1`                |
| `Interval_NSec` | 每次获取信息的时间间隔,单位ns | `0`                |
| `Verbose`       | 是否精确获取                  | `false`            |
| `Tag`           | 输入标签                      | ---                |

我们可以使用如下命令验证:

```bash
docker run fluent/fluent-bit:1.7 /fluent-bit/bin/fluent-bit -i netif -p interface=eth0 -o stdout
```

其中结果中的字段含义如下:

| 键                | 说明         |
| ----------------- | ------------ |
| `ethN.rx.bytes`   | 发送字节数   |
| `ethN.rx.packets` | 发送数据包数 |
| `eth0.rx.errors`  | 发送错误数   |
| `ethN.tx.bytes`   | 接收字节数   |
| `ethN.tx.packets` | 接收数据包数 |
| `eth0.tx.errors`  | 接收错误数   |

> `Disk I/O Metrics`

每隔一定的时间间隔收集正在运行的系统的磁盘io使用情况的信息.其配置项如下:

| 键              | 描述                          | 默认值                   |
| --------------- | ----------------------------- | ------------------------ |
| `Name`          | 插件名                        | 必填,固定为`disk`        |
| `Dev_Name`      | 指定硬盘                      | 不指定则监控全部硬盘挂载 |
| `Interval_Sec`  | 每次获取信息的时间间隔,单位s  | `1`                      |
| `Interval_NSec` | 每次获取信息的时间间隔,单位ns | `0`                      |
| `Tag`           | 输入标签                      | ---                      |

我们可以使用如下命令验证:

```bash
docker run fluent/fluent-bit:1.7 /fluent-bit/bin/fluent-bit -i disk -o stdout
```

其中结果中的字段含义如下:

| 键           | 说明   |
| ------------ | ------ |
| `read_size`  | 读取量 |
| `write_size` | 写入量 |

> `Docker Metrics`

每隔一定的时间间隔收集正在运行的docker容器的信息.其配置项如下:

| 键             | 描述                         | 默认值              |
| -------------- | ---------------------------- | ------------------- |
| `Name`         | 插件名                       | 必填,固定为`docker` |
| `Interval_Sec` | 每次获取信息的时间间隔,单位s | `1`                 |
| `Include`      | 监控的容器id列表             | ---                 |
| `Exclude`      | 排除监控的容器id列表         | ---                 |
| `Tag`          | 输入标签                     | ---                 |

如果`Include`和`Exclude`都不监控则监控全部容器.

我们可以使用如下命令验证:

```bash
docker run fluent/fluent-bit:1.7 /fluent-bit/bin/fluent-bit -i docker -o stdout -m '*'
```

#### `FILTER`配置段定义了过滤器(与过滤插件相关联)

通常在docker的使用场景下我们会用到的过滤器有`Rewrite Tag`和`Modify`.他们一般也只用在通过log构造事件上.

> `Rewrite Tag`

我们用它重新定义输入记录的tag,然后借助路由做重新定向.这多用于对由log构造的事件的分发.

`Rewrite Tag`型过滤器配置项如下:

| 键                     | 描述                                                                        | 默认值               |
| ---------------------- | --------------------------------------------------------------------------- | -------------------- |
| `Name`                 | 过滤插件名称                                                                | 必填,为`rewrite_tag` |
| `Match`                | 与传入记录的标签匹配的模式,它区分大小写并支持星号(`*`)作为通配符            | ---                  |
| `Match_Regex`          | 与传入记录的标签匹配的正则表达式.如果要使用完整的正则表达式语法请使用此选项 | ---                  |
| `Rule`                 | 定义重写标签的规则,                                                         | 必填                 |
| `Emitter_Name`         | 定义发送新纪录的发射器的名称                                                | ---                  |
| `Emitter_Storage.type` | 为新记录定义缓冲机制,可选值为 memory(默认)或 filesystem                     | ---                  |

这个里面主要要说明的就是`Rule`字段,Rule字段格式一般为`KEY REGEX NEW_TAG KEEP`

+ `KEY`用于指定日志记录中存在的键

    其值用于正则表达式(REGEX)匹配.键名以`$`作为前缀,如果键为嵌套结构,则可以用`[xx]`的形式一层一层的向下搜索.注意`KEY`必须指向包含字符串值的键,对于数字/布尔值/映射或数组无效

+ `REGEX`用于匹配指定`KEY`的值是否与`REGEX`定义的正则表达式匹配.如果匹配则会重写标签,不匹配则会跳过
+ `NEW_TAG`用于指定重写的标签模式,标签可以是包含以下任意字符的字符串`a-z,A-Z,0-9,.-,`.我们可以通过占位符`$`动态构造新标签,有如下情况:

    1. `$TAG`表示原有tag
    2. `$TAG[index]`表示原有tag中以`.`分隔的第几段内容,比如`Tag = aa.bb.cc`会匹配出`$TAG[1]="bb"`
    3. `$[index]`表示前面匹配规则中匹配出的占位符,比如`abc-123`就会被匹配出`$0 = "abc-123"`,`$1 = "abc"`,`$2 = "123"`
    4. `$[key]`表示记录中的key位置对应的值,规则和`KEY`的查找规则一致
    5. `${ENV}`表示从环境变量中获取值

+ `KEEP`用于定义旧标签的记录是否被丢弃,必填,取值为true或者false

我们可以在log中通过字段`"as_event":"true"`这样的字段来标识是否要将log作为字段丢进kafka,可以设置为:

```config

[FILTER]
    Name          rewrite_tag
    Match         *
    Rule          $log["as_event"] ^(true)$  Event false
    Emitter_Name  re_emitted
```

> `Modify`

我们用它将tag为`Event`的事件信息中的`as_event`字段去除.


```config

[FILTER]
    Name          modify
    Match         Event
    Condition Key_Exists as_event
    Remove_wildcard Mem
```

#### `OUTPUT`配置段指定记录标签匹配后的目的地

docker环境下我们用到的OUTPUT会有`Elasticsearch`,`PostgreSQL`,`Kafka`这实际上对应了不同需求的log存储.我们在下一节专门介绍.如果是测试使用,直接OUTPUT设置为stdout即可.

## log存储

log的存储设置直接决定了如何使用这些log.在业务前期我们可能会觉得维护一套EFK过于沉重,因此可以使用`TimesacleDB`保存数据,直接使用pg体系的工具分析使用log

而如果业务扩大了需要更加细致的分析操作,那么可以使用`Elasticsearch`保存数据,然后用kibana做可视化和分析

### 落库到`TimesacleDB`(`PostgreSQL`)

[TimescaleDB](https://www.timescale.com/)是pg的一个时序数据库插件,性能不错,适用于LOAP场景.

Fluent bit支持设置Output为`PostgreSQL`,我们可以利用这一特性直接将log落库到TimescaleDB

#### 部署TimescaleDB

#### OUTPUT配置

#### 修改表结构

> 将表改造为Hypertable
> 为log数据设置索引


#### 数据分析

TimescaleDB可以


#### 冷数据归档



### 落库到`Elasticsearch`

log的第一步落库是放在elasticsearch中

我们可以每天定时(比如早上2点到3点)从elasticsearch中将前一天的数据使用列存储格式比如`Parquet`保存到对象存储或者hdfs中.然后固定删除30天前的elasticsearch中的数据.

#### OUTPUT配置
#### 数据分析
#### 冷数据归档

### 将log作为事件发送到`Kafka`

前面我们已经介绍了将特定要作为事件的log如何处理重写标签,这种数据我们可以将其OUTPUT定义为kafka,发送事件到事件总线中.

#### OUTPUT配置
#### 数据分析
#### 冷数据归档


## 全局统一部署fluentd-bit的compose

我们可以给每一台宿主机部署如下stack:

```yaml
version: "2.4"

x-log: &default-log
    options:
        max-size: "10m"
        max-file: "3"
services:
    fluentd-bit:
        image: fluent/fluent-bit:1.7
        logging:
            <<: *default-log
        ports:
            - "24224:24224"
        command: 
            - "/fluent-bit/bin/fluent-bit"
            - "-i"
            - "forward"
            - "-o"
            - "stdout"
            - "-p"
            - "format=json_lines"
            - "-f"
            - "1"
```

+ `fluentd-bit.conf`

+ ``

## 使用`Prometheus`收集监控指标数据

Prometheus是目前主流的监控体系,它的核心目标是护航业务稳定,保障业务的快速迭代.

而针对宿主机的运行状态数据,我们可以使用[cadvisor](https://github.com/google/cadvisor)来随时观察,同时由于其有RESTful接口,所以也可以用[Prometheus](https://prometheus.io/)监控业务数据,用Grafana做可视化和异常警告.

而针对其他系统组件的运行状态数据,我们就需要去找对应的[exporter](https://prometheus.io/docs/instrumenting/exporters/),有的组件比如envoy自己就带与Prometheus对接的接口.关于监控的目标,个人认为并不需要所有东西都监控,我们主要要监控的就是那些有较高负载的服务,比如redis,比如数据库,而一些没有很高负载的我们可以手动找回的我们没有必要做实时的监控.

下面是它的一个整体架构:

![Prometheus架构](../IMGS/prometheus/架构.jpg).

prometheus存储的是时序数据,即按相同时序(相同名称和标签)以时间维度存储连续的数据的集合.

时序(time series)是由度量(Metric)以及一组key/value标签定义的,具有相同的名字以及标签属于相同时序.

+ `metric`:用于描述一个指标的度量,如`http_request_total`.时序的名字由ASCII字符/数字/下划线/冒号组成,它必须满足正则表达式`[a-zA-Z_:][a-zA-Z0-9_:]*`,其名字应该具有语义化,一般表示一个可以度量的指标.例如`http_requests_total`,可以表示http请求的总数
    Metric类型有如下四种,:

    + `Counter`:一种累加的metric,用于描述一段时间内某种状态的出现次数,如请求的个数,结束的任务数,出现的错误数等.

    + `Gauge`:常规的metric,用于描述状态,如温度,可任意加减.其为瞬时的,与时间没有关系的,可以任意变化的数据.

    + `Histogram`:柱状图,用于观察结果采样,分组及统计.如:请求持续时间,响应大小,其主要用于表示一段时间内对数据的采样分布,并能够对其指定区间及总数进行统计.根据统计区间计算

    + `Summary`:类似Histogram,用于表示一段时间内数据采样结果,其直接存储quantile数据,而不是根据统计区间计算出来的.不需要计算,直接存储结果

+ `标签`:用于描述区分度量指标的文本被称作

+ `样本`:按照某个时序以时间维度采集的数据称之为样本.实际的时间序列每个序列包括一个float64的值和一个毫秒级的时间戳

一个 float64 值

一个毫秒级的 unix 时间戳

格式：Prometheus时序格式与OpenTSDB相似：

### 指标收集


> 通用的部署stack

我们将上面的例子整理成docker-compose

+ log-collector.docker-compose.yaml

    ```yaml
    version: "2.4"

    x-log: &default-log
        options:
            max-size: "10m"
            max-file: "3"
    services:
        cadvisor:
            image: unibaktr/cadvisor:0.37.5
            logging:
                <<: *default-log
            volumes:
                - "/:/rootfs:ro"
                - "/var/run:/var/run:ro"
                - "/sys:/sys:ro"
                - "/var/lib/docker/:/var/lib/docker:ro"
                - "/dev/disk/:/dev/disk:ro"
                - "/etc/machine-id:/etc/machine-id:ro"
                - "/var/lib/dbus/machine-id:/var/lib/dbus/machine-id:ro"
            devices:
                - "/dev/kmsg"
            ports:
                - "8080:8080"
            privileged: true

        fluentd-bit:
            image: fluent/fluent-bit:1.7
            logging:
                <<: *default-log
            ports:
                - "24224:24224"
            command: 
                - "/fluent-bit/bin/fluent-bit"
                - "-i"
                - "forward"
                - "-o"
                - "stdout"
                - "-p"
                - "format=json_lines"
                - "-f"
                - "1"
    ```

> 开启docker的`metrics-addr`用于支持收集容器状态指标

这是dockerd的一项实验性功能,可以通过启动dockerd时带上参数`--metrics-addr=<host:port>`来启动对docker的监控.虽然这个功能很不错但需要较高版本的docker环境,所以也不用强求.


> 启动`cadvisor`收集宿主机器资源指标信息

注意cadvisor是监控linux的,因此windows上无法测试.官方给的例子如下

```bash
docker run \
--volume=/:/rootfs:ro \
--volume=/var/run:/var/run:ro \
--volume=/sys:/sys:ro \
--volume=/var/lib/docker/:/var/lib/docker:ro \
--volume=/dev/disk/:/dev/disk:ro \
--publish=8080:8080 \
--detach=true \
--name=cadvisor \
--privileged \
--device=/dev/kmsg \
gcr.io/cadvisor/cadvisor
```

用它有几个问题:

1. 由于`gcr.io`在墙外难以使用,可以使用dockerhub上的`unibaktr/cadvisor`镜像代替
2. 官网例子漏了俩要挂在的路径`/etc/machine-id:/etc/machine-id:ro`和`/var/lib/dbus/machine-id:/var/lib/dbus/machine-id:ro`
3. arm版本(至少是树莓派和JETSONNANO)没有办法监听到cpu的情况



### 单独部署

> 启动[redis_exporter](https://github.com/oliver006/redis_exporter)收集redis指标信息

```bash
docker run -d --name redis_exporter -e REDIS_ADDR=redis://localhost:6379 -e REDIS_PASSWORD=pwd -p 9121:9121 oliver006/redis_exporter
```

> 启动[postgres_exporter](https://github.com/prometheus-community/postgres_exporter)收集pg指标信息

我们需要指定pg的路径

```bash
docker run \
  --net=host \
  -e DATA_SOURCE_NAME="postgresql://postgres:password@localhost:5432/postgres?sslmode=disable" \
  prometheuscommunity/postgres-exporter
```

> 单独部署的stack

+ exporters.docker-compose.yaml

    ```yaml
    version: "2.4"

    x-log: &default-log
        options:
            max-size: "10m"
            max-file: "3"
    services:
        redis-exporter:
            image: oliver006/redis_exporter:v1.24.0
            logging:
                <<: *default-log
            ports:
                - "9121:9121"
            environment:
                REDIS_ADDR: redis://192.168.31.212:6379 
                REDIS_PASSWORD: password

        postgres-exporter:
            image: prometheuscommunity/postgres-exporter
            logging:
                <<: *default-log
            ports:
                - "9187:9187"
            environment:
                DATA_SOURCE_NAME: postgresql://postgres:password@192.168.31.212:5432/postgres?sslmode=disable
    ```


### 使用`Grafana`监控指标数据

### 使用`Prometheus`做指标监控的注意事项

首先我们应该明确使用`Prometheus`做指标监控的目的--护航业务稳定，保障业务的快速迭代

1. Prometheus作为一个基于指标的监控系统,在设计上就放弃了一部分数据准确性.比如在两次采样的间隔中内存用量有一个瞬时小尖峰,那么这次小尖峰我们是观察不到的;而QPS/RT/P95/P99这些值都只能估算.Prometheus无法和日志系统一样做到100%准确.降低一部分准确性带来的是更高的可靠性和更低的运维成本.而如果需要更高的准确性,我们应该使用日志分析系统.


放弃一点准确性得到的是更高的可靠性，这里的可靠性体现为架构简单、数据简单、运维简单。假如你维护过 ELK 或其它日志架构的话，就会发现相比于指标，日志系统想要稳定地跑下去需要付出几十倍的机器成本与人力成本。

既然是权衡，那就没有好或不好，只有适合不适合，我推荐在应用 Prometheus 之初就要先考虑清楚这个问题，并且将这个权衡明确地告诉使用方。


## 使用`ElasticSearch`收集业务log

### 使用`Kibana`分析业务log