# Docker体系下的log分析与监控

Docker无论是单机还是集群,作用都是服务的部署平台.部署平台最重要的就是确保业务健康稳定的运行.因此log分析与监控是基础中的基础.

log的收集,分析,监控虽然不会直接影响部署服务,但会很大程度上影响业务发展和优化的方向,可以说极其有价值.一般来说我们会将log数据当作一般的数据来处理,也就是会按所处生命周期中的不同位置进行不同的处理.

## log数据的处理思路

首先我们看看log数据有什么特点:

1. log的主要作用是为了帮助发现业务或程序中的问题,其他目的都是捎带手的,不能本末倒置.
2. log应该是结构化(或者半结构)数据.毕竟我们打印log就是为了描述清除发生了什么,既然如此还有什么比结构化数据更加清晰表现力强呢?
3. log是append-only的时序数据.
4. log数据不应该丢失,但如果丢失了也没什么问题不会影响业务.
5. log数据不应延迟过大,但如果有较大延迟也没什么问题不会影响业务.

根据上面的特点,我们可以推论出log数据的一些处理原则

1. 我们应该直接要求log都用json作为统一的格式.
2. log应该尽量包含各种元信息.这些元信息可以帮助我们尽快的定位问题
3. 业务log应该只报必须报的,每个上报都必须有意义,避免因为上报过多造成监控的敏感度降低
4. log应该是有较短时效性的数据,发现log异常后应该立马着手解决而不是等着它滚雪球.

### log数据的生命周期

针对log分析和监控这个场景,我们大致可以像下面这样定义数据阶段

| 阶段   | 阶段时限    | 主要用途                         |
| ------ | ----------- | -------------------------------- |
| 热数据 | 1天内的数据 | 监控告警                         |
| 温数据 | 7天内的数据 | 分析                             |
| 冷数据 | 7天外的数据 | 制作周/月/季度/年度报告,数据归档 |

### docker体系下的log收集分析监控工具

在使用docker容器技术这个条件下,我们会将所有的相关组件全部使用docker部署.同时尽量使用已经成熟或者官方推荐的方案.
针对业务log数据,docker默认使用的driver是`json-file`,它可以将stdout和stderr输出的文本收集到json格式的文本文件中存放在宿主机的特定位置.我们需要通过`docker logs`这类专用命令才能看它,所以基本上这种方式收集到的log很难用于分析.

docker官方提供的`Fluentd`driver则相对更加实用,我们可以用它配合[Fluentd](https://www.fluentd.org/)或者[Fluentd bit](https://docs.fluentbit.io/manual/)收集log,然后借助EFK工具栈统计和分析这些log,并用Prometheus监控业务数据,用Grafana做可视化和异常警告.

而长期的log落库则可以通过定期的将数据导入冷数据仓库(比如对象存储,比如hdfs)中实现

对于log,我们要做的事情其实就4样:

1. log收集
2. log保存
3. log监控
4. log分析

再结合上面的数据生命周期,一个基本的工具使用框架就出来了

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

业务log的规范包括两部分:

1. 标签规范

    许多log收集工具都是通过解析标签来进行归档的,因此docker的log设置中tag很重要.在docker中log的标签使用`--log-opt tag="xxxx"`设置.我们可以通过设置模板来动态构造tag.具体的规则可以看[这个页面](https://docs.docker.com/config/containers/logging/log_tags/)

    我们一般习惯上会把业务log的tag设置为`app.{{.Name}}`

2. 结构规范

    每个业务log应该都是结构化数据,必须包含一些特定信息可以统一的查询到信息,比如:`app_name`,`app_version`,`event`,`time`四个字段用于定位事件发生的位置和时间,`prey_app`,`prey_app_version`,`prey`,`prey_query`用于指明引起事件的调用方信息,`level`用于标明严重性等级,以及如果是报错还应该把错误类型(`err_type`)和错误信息(`err_msg`)报出来等.

    另外建议在有反向代理的情况下应用中就不要打印access_log了,access_log可以交给反向代理统一打.

log的另外一个问题就是时间的统一.一般时间的表示方式有两种:

+ `时间戳`: 一般来说需要快速比较排序以及精确时间的场合我们会用时间戳,时间戳一般是一个`int64`的数据,根据精度不同我们一般用的是秒级时间戳(10位)和毫秒级时间戳(13位).有精度要求的场景一般用13位的毫秒级时间戳.
+ `时间字符串`: 一般对于需要一定可读性的数据会用时间字符串,时间字符串一般要求使用像`2021-06-24T02:27:45.045856Z`的格式(`ISO_8601`标准,`RFC3339`配置),并且因该使用utc时间而非本地时间,以避免在做国际化时出问题.

## 示例程序

我们来构造一个定时任务程序,每3s打印一次业务log,每5s打印一次业务事件log,这个示例程序放在[分支example-logapp](https://github.com/hsz1273327/TutorialForDocker/tree/example-logapp).它输出的log形式为:

+ 业务log

```json
{"event": "ping", "logger": "example-app", "level": "warning", "timestamp": "2021-06-24T02:27:45.045856Z"}
```

+ 业务事件log

```json
{"event": "ping", "logger": "example-app", "level": "warning", "timestamp": "2021-06-24T02:27:45.045856Z"}
```

这个例子的镜像我放在[docker hub上](https://registry.hub.docker.com/repository/docker/hsz1273327/log_example_app/general),我们用这个例子展示在docker体系下的log分析和监控

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

部署`fluentd bit`我们需要将配置文件加载进容器.而`fluentd bit`的行为主要靠配置文件控制.
我们按运行环境分别介绍如何部署`fluentd bit`

#### docker单机环境

单机环境下我们加载配置通过bind本地文件到镜像指定位置

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
    environment:
        HOST: '<你的主机名>'
    volumes:
        - "/var/run/docker.sock:/var/run/docker.sock"
        - "./config/fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf"
        - "./config/docker_parser.conf:/fluent-bit/etc/docker_parser.conf"
    command:
        - "/fluent-bit/bin/fluent-bit"
        - "-c"
        - "/fluent-bit/etc/fluent-bit.conf"
```

与之对应的单机部署应用项目的log配置为:

```yaml
x-log: &default-log
    driver: "fluentd"
    options:
        tag: "app.<你的主机名>.{{.Name}}.{{.ID}}"
```

#### docker swarm环境

swarm环境下我们通过`configs`分发配置

```yaml
version: "3.8"

x-log: &default-log
  options:
    max-size: "10m"
    max-file: "3"
services:
  fluentd-bit:
    image: fluent/fluent-bit:1.7
    logging:
      <<: *default-log
    environment:
      HOST: '{{ .Node.Hostname }}.{{ .Node.ID }}'
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    networks:
      - mynetwork
    configs:
      - source: fluent-bit-conf
        target: /fluent-bit/etc/fluent-bit.conf
      - source: fluent-docker_parser-conf
        target: /fluent-bit/etc/docker_parser.conf
    deploy:
      mode: global
      resources:
        limits:
          cpus: '0.50'
          memory: 50M
        reservations:
          cpus: '0.25'
          memory: 20M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
    command:
      - "/fluent-bit/bin/fluent-bit"
      - "-c"
      - "/fluent-bit/etc/fluent-bit.conf"

configs:
  fluent-bit-conf:
    external: true
  fluent-docker_parser-conf:
    external: true

networks:
  mynetwork:
    external: true
    name: host
```

与之对应的swarm下部署应用项目的log配置为:

```yaml
x-log: &default-log
    driver: "fluentd"
    options:
        tag: "app.{{.Name}}.{{.ID}}"
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

这里比较需要关注的有:

1. `Parsers_File`,这个字段用于导入数据格式的解析器配置.我们在后面会用到
2. `HTTP_Server`,`HTTP_Listen`和`HTTP_Port`三个字段可以开启让`Prometheus`轮询的http接口,设置好后就可以被监控到了

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

我们一般习惯上会把tag设置为`app.{{.Name}}.{{.ID}}`

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

通常在docker的使用场景下我们会用到的过滤器有`Parser`,`Rewrite Tag`和`Modify`.他们一般也只用在通过log构造事件上.

`FILTER`配置可以叠加,其叠加顺序就是配置的顺序.

> `Parser`

我们使用docker的`fluent`driver收集log会出现一个问题--我们输出的log无论是不是json格式的字符串,fluent bit永远会将其放在`log`字段中作为字符串输出.这并不符合我们使用结构化的json作为log输出格式的初衷.

比如在docker环境下我们在stdout中以json格式输出的log`{"status": "up and running"}`,在fluent bit中则会以如下形式展示:

```json
{"log":"{\"status\": \"up and running\"}\r\n","stream":"stdout","time":"2018-03-09T01:01:44.851160855Z"}
```

这种情况下我们可以这样做:

1. 定义一个`docker_parser.conf`文件,其内容为

    ```conf
    [PARSER]
        Name         docker
        Format       json
        Time_Key     time
        Time_Format  %Y-%m-%dT%H:%M:%S.%L %z
        Time_Keep    On
    ```

2. 将这个文件在`SERVICE`段进行加载

    ```conf
    [SERVICE]
        Flush     1
        Log_Level info
        Parsers_File /path/to/docker_parser.conf
    ```

3. 在配置文件中新增一段`Parser`类型的`FILTER`

    ```conf
    [FILTER]
        Name parser
        Match app.*
        Parser docker
        Key_Name log
    ```

我们通过`Parser`类型的`FILTER`的过滤器将解析器应用到特定字段,这样就可以将我们的log完整的解析为结构化数据了.

`Parser`型过滤器配置项如下:

| 键             | 描述                                                                        | 默认值          |
| -------------- | --------------------------------------------------------------------------- | --------------- |
| `Name`         | 过滤插件名称                                                                | 必填,为`parser` |
| `Match`        | 与传入记录的标签匹配的模式,它区分大小写并支持星号(`*`)作为通配符            | ---             |
| `Match_Regex`  | 与传入记录的标签匹配的正则表达式.如果要使用完整的正则表达式语法请使用此选项 | ---             |
| `Key_Name`     | 定义被解析的字段,docker中为`log`                                            | 必填            |
| `Parser`       | 申明使用的解析器                                                            | ---             |
| `Preserve_Key` | 是否保存被解析的key的原值                                                   | False           |
| `Reserve_Data` | 是否保存除了被解析字段外的其余字段的信息                                    | False           |
| `Unescape_Key` | 如果要解析的key中的值是转义字符串,是否要进行转义                            | False           |

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
    Match         events.*
    Remove        as_event
```

#### `OUTPUT`配置段指定记录标签匹配后的目的地

docker环境下我们用到的OUTPUT会有`Elasticsearch`,`PostgreSQL`,`Kafka`这实际上对应了不同需求的log存储.我们在下一节专门介绍.如果是测试使用,直接OUTPUT设置为stdout即可.

## 由log构造事件

由log构造的事件常用在对实时性不敏感,且允许丢失的场景中,比如一些对精度没有特别高要求的统计操作(配合flink或者spark streaming等).这种数据我们可以将其OUTPUT定义为kafka,发送事件到事件总线中.

在前面我们已经为使用log构造事件打下了基础,具体就是如下几点:

1. 为要作为事件的log规定了用于匹配的关键字`"as_event":"true"`,如果要使用`key`也可以规定个字段比如`event_key`用来指定key
2. 使用`Rewrite Tag`和`Modify`两种`FILTER`构造用于发布到kafka中的tag

现在我们只要设置`OUTPUT`就可以发送事件了.

### `Kafka`类型的`OUTPUT`

`Kafka`类型的`OUTPUT`配置项如下:

| 键                   | 描述                                                                                                                        | 默认值             |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| `Name`               | 插件名                                                                                                                      | 必填,固定为`kafka` |
| `Format`             | 指定发送时使用的序列化协议,支持json和msgpack                                                                                | `json`             |
| `Message_Key`        | 指定发送的key                                                                                                               | ---                |
| `Message_Key_Field`  | 指定字段的值作为发送的key                                                                                                   | --                 |
| `Timestamp_Key`      | 指定时间数据保存的key                                                                                                       | `@timestamp`       |
| `Timestamp_Format`   | 指定时间数据的格式支持`iso8601`和`double`                                                                                   | `double`           |
| `Brokers`            | 指定kafka的Broker地址,多个用`,`分隔                                                                                         | 必填               |
| `Topics`             | 指定发送去的topic,可以有多个.如果只有一个就会都发去这个topic,否则通过`Topic_Key`指定的字段分流                              | `fluent-bit`       |
| `Topic_Key`          | 如果`Topics`中指定了多个,则用它指定用于分流的字段.注意如果用于分流的字段中的值不在`Topics`中,则会默认使用`Topics`中的第一个 | ---                |
| `Dynamic_Topic`      | 当指定`Dynamic_Topic`时,如果`Topic_Key`中出现了`Topics`中不存在的topic,则创建这个topic                                      | `Off`              |
| `Queue_Full_Retries` | 发送不成功时的重试次数,注意设置为`0`意味不断重试                                                                            | `10`               |
| `rdkafka.{property}` | librdkafka的配置参数                                                                                                        | ---                |

通常我们会以`event`字段作为`Topic_Key`,同时设置`Dynamic_Topic`为`On`.通常我们用kafka的事件都是使用json作为序列化协议的,主要是各种大数据工具都支持

至此我们的config可以总结为:

```config
[SERVICE]
    Flush     1
    Log_Level info
    HTTP_Server  On
    HTTP_Listen  0.0.0.0
    HTTP_PORT    2020
    Parsers_File /fluent-bit/etc/docker_parser.conf

[INPUT]
    NAME   cpu
    Tag    metrics.${HOST}.cpu
    Interval_Sec 5

[INPUT]
    NAME   mem
    Tag    metrics.${HOST}.memory
    Interval_Sec 5

[INPUT]
    NAME   netif
    Tag    metrics.${HOST}.netif
    Interface eth0
    Interval_Sec 5

[INPUT]
    NAME   disk
    Tag    metrics.${HOST}.disk
    Interval_Sec 5

[INPUT]
    NAME   docker
    Tag    metrics.${HOST}.docker
    Interval_Sec 5
    
[INPUT]
    NAME   forward
    # Parser      docker

[FILTER]
    Name parser
    Match app.*
    Parser docker
    Key_Name log

[FILTER]
    Name          rewrite_tag
    Match         app.*
    Rule          $as_event ^(true)$  events.$TAG false
    Emitter_Name  re_emitted

[FILTER]
    Name          modify
    Match         events.*
    Remove as_event

[OUTPUT]
    Name          stdout
    Match         *

[OUTPUT]
    Name               kafka
    Match              events.*
    Format             json
    Timestamp_Key      ts
    Timestamp_Format   iso8601
    Topic_Key          event
    Dynamic_Topic      On
    Brokers            <urls>

```

## log存储

log的存储设置直接决定了如何使用这些log.在业务前期我们可能会觉得维护一套EFK过于沉重,因此可以使用`TimesacleDB`保存数据,直接使用pg体系的工具分析使用log

而如果业务扩大了需要更加细致的分析操作,那么可以使用`Elasticsearch`保存数据,然后用`kibana`做可视化和分析.但个人并不推荐在人力才力不足的情况下使用`Elasticsearch`,主要原因在于要稳定维护这么一套相当昂贵.本文暂时也不会介绍落库到`Elasticsearch`的方案.

### 落库到`TimesacleDB`(`PostgreSQL`)

[TimescaleDB](https://www.timescale.com/)是pg的一个时序数据库插件,性能不错,适用于LOAP场景.同时从2.0版本开始还支持了多节点部署,增加了横向扩展数据的能力.个人认为是目前开源时序数据库中最好用的一款.我自己就是它的老用户了,曾经用它保存k线数据,交易数据,以及一些用户行为数据.这款数据库的最大优势是它是pg的插件.极易扩展而且支持sql语句,而且内存控制非常稳定.而最大的缺点是写入性能.

关于这款数据库我会在以后的文章中专门介绍.

这一方案优点有:

1. `学习成本低`.由于`TimescaleDB`本质上还是pg的插件,完全可以当作pg来维护,对于一开始就使用pg的来说几乎没有学习成本,即便对于从其他关系数据库转来的用户来说至少也可以省去学习特定查询语言的成本.
2. `维护成本低`.pg的官方文档相当细致齐全,只要肯读肯翻一般不会有太大的维护问题.由于落库和分析是典型的`OLAP`场景,数据都是append only的,因此也会大大降低维护成本.只需要往批写入和大查询方向(索引)优化即可.而`TimescaleDB`自带数据过期,也为维护省了不少心.
3. `组件可复用`.pg生态相当丰富,几乎任何可视化工具都支持.因此数据探索完全可以复用业务上的工具.
4. 支持`Continuous aggregates`等时间序列操作,一些简单的统计操作可以直接在其中进行而没有必要再借助其他工具.
5. 支持`view`可以将查询固化,这也是pg带来的好处,我们可以将查询记录为view,这样就不用额外保存查询结果数据或者保存查询语句了.
6. `资源占用低`,对于小企业小业务来说了上那些很重的log收集分析方案成本上是不划算的,而`TimescaleDB`则相当廉价.除了对资源占用低外,`TimescaleDB`还支持数据分层,将热数据和温数据存放在不同的存储介质(热数据放SSD,温数据放HDD)中以降低硬件成本

当然了缺点也有:

1. `没有原生的中文全文搜索`.pg虽然支持全文搜索但默认只有英文的,这个缺陷自有全文搜索开始就有.要用中文全文搜索必须编译安装中文分词插件.这个后面介绍
2. `在不做优化的情况下查询性能偏差`.可以看这[篇文章](https://rocky.dev/full-text-search)作者对比了pg的全文搜索和es的查询效率,在没有优化的的情况下es的查询性能是pg的5倍以上,但优化过索引后pg可以比es快近40%.
3. `要用到SQL语言`.SQL好用但并不是所有人都会用,对于那些上来就不用关系数据库(直接用mongodb或者Cassandra)的企业来说可能学习SQL会是一件让人头疼的事情.
4. `分布式部署方案有缺陷`.TimescaleDB虽然支持分布式部署,但实际还是master-slaver架构,所有请求都必须经过master节点(access节点),因此依然容易造成单点故障,并且吞吐量会受影响

总结下这个方案适合如下情况:

1. 习惯于用关系数据库
2. 希望低维护成本运行
3. 希望工具尽量精简
4. 有比较强的时间序列分析需求
5. 穷人

Fluent bit支持设置Output为`PostgreSQL`,我们可以利用这一特性直接将log落库到TimescaleDB.但除非确实资源不够否则我们不会把log库放在业务库中,而是单独构造数据库来专门存放log信息.

#### 在TimescaleDB中部署数据库

我们创建数据库`logs`用于保存由`Fluent bit`收集来的数据,在其中创建三个结构一致的表,分别取名为

+ `app`用于存放业务log
+ `metrics`用于存放指标log
+ `events`用于存放事件log

通常这个表只会存不超过7天的数据,`metrics`表是定时送,规模可控,`app`则一般是警告和错误信息,是低概率触发的,`event`一般也不会是什么特别关键的数据,因此总提来说这个数据库的规模是可以预估的,我们可以根据预估的量来考虑要不要分库分表.

下面是表的创建语句(以`app`表为例)

1. 创建表
    这个表的结构必须符合`fluent bit`的`POSTGRESQL`类型的`OUTPUT`的表格格式

    ```sql
    CREATE TABLE IF NOT EXISTS app (
        tag            TEXT, -- 标签
        time           TIMESTAMP WITHOUT TIME ZONE, -- 时间戳
        data           JSONB-- log信息
    );
    ```

2. 创建超表
    将创建好的表转化为`TimescaleDB`的超表.`TimescaleDB`支持单节点超表也支持分布式超表,这里以单节点超表为例.

    ```sql
    SELECT create_hypertable('app', 'time','tag',10,chunk_time_interval=>INTERVAL '6 hours',if_not_exists=>TRUE);
    ```

    个人也更加推荐使用单节点超表,支持更多功能,关键是数据量可控用不着上多节点

3. 设置数据过期
    我们一般还是设置log7天过期

    ```sql
    SELECT add_retention_policy('app', INTERVAL '7 days');
    ```

4. 创建索引
    我们的log数据需要根据json中的字段来建立索引.针对业务log我们肯定会有的字段中比较重要的包括`event`和`level`,通常我们用这两个字段做索引就够了.

    ```sql
    CREATE INDEX IF NOT EXISTS event_index ON app ((data ->> 'event')) WHERE data ? 'event';
    CREATE INDEX IF NOT EXISTS level_index ON app ((data ->> 'level')) WHERE data ? 'level';
    CREATE INDEX IF NOT EXISTS idxgin ON app USING GIN (data); -- 对其他json的key做索引
    CREATE INDEX IF NOT EXISTS full_text_idxgin ON app USING GIN (to_tsvector('jiebacfg',tag || ' ' || data)); -- 创建全文搜索的索引
    ```

5. 设置数据压缩策略

    `TimescaleDB`支持通过添加任务的方式定时压缩较旧的数据,压缩后自然存储空间减少,查询性能受一定影响,但最主要的还是影响写入性能.通常我们会压缩3天以后的数据,因为虽说24小时内是热数据,但实际上3天内的数据往往都还是有效性比较高的.

    ```sql
    ALTER TABLE app SET (
        timescaledb.compress,
        timescaledb.compress_segmentby = 'tag'
    );
    SELECT add_compression_policy('app', INTERVAL '3 days',if_not_exists=>TRUE);
    ```

#### OUTPUT配置

`PostgreSQL`类型的`OUTPUT`配置项如下:

| 键              | 描述                   | 默认值           |
| --------------- | ---------------------- | ---------------- |
| `Host`          | PostgreSQL实例的主机名 | `127.0.0.1`      |
| `Port`          | PostgreSQL实例的端口   | `5432`           |
| `Database`      | 要连接的数据库名       | `fluentbit`      |
| `Table`         | 存储数据的表名         | `fluentbit`      |
| `User`          | PostgreSQL用户名       | 操作系统当前用户 |
| `Password`      | PostgreSQL密码         | ---              |
| `Timestamp_Key` | 存储记录时间戳的键     | `date`           |

结合我们的场景,可以定义如下配置:

```conf
[SERVICE]
    Flush     1
    Log_Level info
    HTTP_Server  On
    HTTP_Listen  0.0.0.0
    HTTP_PORT    2020
    Parsers_File /fluent-bit/etc/docker_parser.conf

[INPUT]
    NAME   cpu
    Tag    metrics.${HOST}.cpu
    Interval_Sec 5

[INPUT]
    NAME   mem
    Tag    metrics.${HOST}.memory
    Interval_Sec 5

[INPUT]
    NAME   netif
    Tag    metrics.${HOST}.netif
    Interface eth0
    Interval_Sec 5

[INPUT]
    NAME   disk
    Tag    metrics.${HOST}.disk
    Interval_Sec 5

[INPUT]
    NAME   docker
    Tag    metrics.${HOST}.docker
    Interval_Sec 5
    
[INPUT]
    NAME   forward
    # Parser      docker

[FILTER]
    Name parser
    Match app.*
    Parser docker
    Key_Name log

[FILTER]
    Name          rewrite_tag
    Match         app.*
    Rule          $as_event ^(true)$  events.$TAG false
    Emitter_Name  re_emitted

[FILTER]
    Name          modify
    Match         events.*
    Remove as_event

[OUTPUT]
    Name          pgsql
    Match         metrics.*
    Host          <主机>
    Port          <端口>
    User          postgres
    Password      postgres
    Database      logs
    Table         metrics
    Timestamp_Key ts

[OUTPUT]
    Name          pgsql
    Match         app.*
    Host          <主机>
    Port          <端口>
    User          postgres
    Password      postgres
    Database      logs
    Table         app
    Timestamp_Key ts

[OUTPUT]
    Name          pgsql
    Match         events.*
    Host          <主机>
    Port          <端口>
    User          postgres
    Password      postgres
    Database      logs
    Table         events
    Timestamp_Key ts

[OUTPUT]
    Name               kafka
    Match              events.*
    Format             json
    Timestamp_Key      ts
    Timestamp_Format   iso8601
    Topic_Key          event
    Dynamic_Topic      On
    Brokers            <主机>:<端口>
```

#### 数据分析与可视化

`TimescaleDB`落库方案的数据分析方案基本就是传统数据分析的方案,大致有3种:

1. `python`+`pandas`方案,这种方式需要有python编程能力,几乎什么都是手动,适合数据探索.优势是数据拉到本地不占用`TimescaleDB`的cpu资源,缺点是上手有门槛,而且只能用于数据探索,无法用于预警,而且需要借助其他工具(比如airflow)来实现定时.
2. `Hue`方案,如果你已经搭了一套hadoop/spark环境,更加推荐顺便就搭一套`Hue`.`Hue`也支持连接pg,也就可以直接通过SQL操作查询log数据了.优点是自带定时功能,而且预设了多种可视化方案以及dashboard,可以快速展示出效果直观体现结论.缺点是依赖sql,也就是计算在`TimescaleDB`上,而且也没办法做预警.
3. `Grafana`方案,如果我们已经借助`prometheus`体系来做监控了,一般我们都会有`Grafana`,而`Grafana`也可以连接pg,我们可以直接通过它来做数据探索和展示,`Grafana`同样也提供了多种可视化方案以及dashboard,可以快速展示出效果直观体现结论,而且有警告功能.缺点是依赖sql,也就是计算在`TimescaleDB`上,而定时任务只能借助`TimescaleDB`的定时任务功能配合物化视图来实现了.

第一种第二种我以后会在数据科学的相关文章中介绍,而第三种具体如果使用`Grafana`我们后面的监控部分会详细介绍.建议读者根据自己的实际情况选择合适的工具.

#### 冷数据归档

冷数据归档就必须使用定时任务了,我们一般希望冷数据尽量不占空间,并且可以方便的被各种工具加载做冷数据分析.这边建议使用[parquet](https://parquet.apache.org/)格式.实测之前timescale数据中约11G的股市数据经过压缩和转化后可以控制在不到200m.

一般转化完后我们会将其保存在比较廉价的存储空间中,如果是本地机房可以放在nas上,如果有hadoop环境则可以存放在hdfs上;而如果是云环境,建议直接放对象存储.

至于如何定时执行,如果用的是`Hue`那就已经是自带的了,如果使用的是docker warm或者k8s环境,则可以通过集群做定时任务.如果都没有,就得借助airflow这样的工具了.

另外注意,尽量不用crontab,分散的crontab任务极难维护.

##### 最简方案

一种最廉价的冷数据归档方法是借助timescaledb和nas实现.这种方案的适用情况是:

1. 所有log数据都存在同一个timescaledb中.且timescaledb版本高于2.0
2. nas可以启动nfs

timescaledb支持定时任务,借助pg的copy关键字我们可以实现将数据库中的查询结果写入本地文件.需要两步

1. 写一个函数用于保存数据到文件

    注意我们写入的文件位置需要是nfs上对应的位置.

2. 将函数添加到定时任务

这种方式的缺陷是不支持parquet格式,只能csv格式输出.如果一定要parquet格式的文件的话,可以通过起一个python脚本监听nfs上写入文件夹的变化,然后有写入完成事件就读取后转化为parquet格式的文件存入最终位置.

<!-- 
### 落库到`Elasticsearch`

落库到[Elasticsearch](https://www.elastic.co/cn/elasticsearch/)是相对比较传统的做法(也就是`ELK`体系的变种`EFK`).`Elasticsearch`是一个全文搜索引擎,使用特制的json语法作为请求,它的查询性能十分优异,广泛应用于各种搜索场景.之所以`Elasticsearch`可以称为log收集分析的工具,也是用到了它强大的搜索能力.

这一方案优点有:

1. `资料多`.`ELK`体系基本是行业标准.资料相当多,`Elasticsearch`的官网文档也相当优质
2. `高性能的全文搜索`.在不优化的情况下`Elasticsearch`的搜索性能是非常高的
3. `天生的分布式支持`.es天生支持集群部署,节点可以扩展到上百台,吞吐量可以随着节点扩展而扩展

当然了缺点也有:

1. `运维困难`.es由于分布式的特性,运维成本会比单机的timescaledb高出不少
2. `资源占用高`.es出了名的内存怪兽,而且存储效率很低,磁盘利用率低
3. `使用专用查询语言`.es的搜索语言是比较蛋疼的,为了用它你必须学一套别处完全用不到的东西
4. `数据延迟`,es由于天生的分布式特性只能保证数据的最终一致性,es默认允许1s的数据延迟
5. `没有自动数据过期`.也就是说我们需要自己使用定时任务在外部删除过期数据

#### OUTPUT配置

#### 数据分析

#### 冷数据归档

我们可以每天定时(比如早上2点到3点)从elasticsearch中将前一天的数据使用列存储格式比如`Parquet`保存到对象存储或者hdfs中.然后固定删除7天前的elasticsearch中的数据.
 -->

## 使用`Prometheus`收集监控指标数据

监控的目的是护航业务稳定,保障业务的快速迭代.`Prometheus`是目前主流的监控体系,可以认为是docker体系监控工具的事实标准.

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

### 指标收集

`Prometheus`使用的是定时轮询的方式收集指标数据,它需要被监控对象提供接口以供访问后获得当前指标信息.

一般稍微新一些的组件都会自带`Prometheus`可用的接口,而老一些的组件也可以通过安装各种[exporter](https://prometheus.io/docs/instrumenting/exporters/)

比较常用的组件exporter如下:

> [redis_exporter](https://github.com/oliver006/redis_exporter)收集redis指标信息

```yaml
redis-exporter:
    image: oliver006/redis_exporter:v1.24.0
    logging:
        <<: *default-log
    depends_on:
        - redis
    ports:
        - "9121:9121"
    environment:
        REDIS_ADDR: redis://redis:6379
        REDIS_PASSWORD: 0iY87blaERqARYie
```

> [postgres_exporter](https://github.com/prometheus-community/postgres_exporter)收集pg指标信息

我们需要指定pg的路径

```yaml
postgres-exporter:
    image: prometheuscommunity/postgres-exporter
    depends_on:
        - timescaledb
    logging:
        <<: *default-log
    ports:
        - "9187:9187"
    environment:
        DATA_SOURCE_NAME: postgresql://postgres:postgres@timescaledb:5432/postgres?sslmode=disable
```

> [kafka_exporter](https://github.com/danielqsj/kafka_exporter)

```yml
kafka-exporter:
    image: danielqsj/kafka-exporter
    depends_on:
        - kafka
    logging:
        options:
            max-file: 3
            max-size: 10m
    ports:
        - "9308:9308"
    networks:
        local:
            aliases:
                - "kafka-exporter.local"
    command: ["--kafka.server=host.docker.internal:9092"]
```

而像`Envoy`包括`Fluent bit`都是自带`Prometheus`可用的接口的,这类只要启动时带上相关配置即可.

在确认好要监控的组件都有接口给访问后,就是配置`Prometheus`了.

+ `/etc/prometheus/prometheus.yml`

    ```yml
    global:
    scrape_interval:     15s # By default, scrape targets every 15 seconds.

    # Attach these labels to any time series or alerts when communicating with
    # external systems (federation, remote storage, Alertmanager).
    external_labels:
        monitor: 'codelab-monitor'

    # A scrape configuration containing exactly one endpoint to scrape:
    # Here it's Prometheus itself.
    scrape_configs:
    # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
    - job_name: 'prometheus'
        # Override the global default and scrape targets from this job every 5 seconds.
        scrape_interval: 5s
        static_configs:
        - targets: ['localhost:9090']

    - job_name: redis_exporter
        scrape_interval: 5s
        static_configs:
        - targets: ['redis-exporter:9121']

    - job_name: timescaledb_exporter
        scrape_interval: 5s
        static_configs:
        - targets: ['postgres-exporter:9187']
    ...
    ```

配置这些待监控的项也很简单,就是在`scrape_configs`中设置一个由`job_name`,`scrape_interval`和`static_configs`构成的结构即可.`Prometheus`会每次以`scrape_interval`定义的时间间隔区遍历访问`static_configs`中定义的url,将获取到的结果存入自带的时序数据库.

必要需要注意的是`Fluent bit`的监控,有两个注意点:

1. `Fluent bit`的监控监控的是input和output的流量和写入成功率情况.虽然`Fluent bit`可以顺带收集宿主机的信息,但并不会原样上报给`Prometheus`.要监控这些指标我们需要在log收集落库后通过`Grafana`直接监控库中的数据

2. `Fluent bit`给`Prometheus`用的接口`metrics_path`为`/api/v1/metrics/prometheus`,这个需要修改下

3. 由于我们通常是用一个job来监控所有宿主机的`Fluent bit`,因此为了区分不同宿主机的来源,我们需要在`Fluent bit`的配置中为`OUTPUT`和`INPUT`设置别名,以使用timescaledb作为output为例:

    ```conf
    [SERVICE]
        Flush     1
        Log_Level info
        HTTP_Server  On
        HTTP_Listen  0.0.0.0
        HTTP_PORT    2020
        Parsers_File /fluent-bit/etc/docker_parser.conf

    [INPUT]
        NAME   cpu
        Alias  ${HOST}_cpu
        Tag    metrics.${HOST}.cpu
        Interval_Sec 5

    [INPUT]
        NAME   mem
        Alias  ${HOST}_mem
        Tag    metrics.${HOST}.memory
        Interval_Sec 5

    [INPUT]
        NAME   netif
        Alias  ${HOST}_netif
        Tag    metrics.${HOST}.netif
        Interface eth0
        Interval_Sec 5

    [INPUT]
        NAME   disk
        Alias  ${HOST}_disk
        Tag    metrics.${HOST}.disk
        Interval_Sec 5

    [INPUT]
        NAME   docker
        Alias  ${HOST}_docker
        Tag    metrics.${HOST}.docker
        Interval_Sec 5
        
    [INPUT]
        NAME   forward
        Alias  ${HOST}_forward
        # Parser      docker

    [FILTER]
        Name parser
        Match app.*
        Parser docker
        Key_Name log

    [FILTER]
        Name          rewrite_tag
        Match         app.*
        Rule          $as_event ^(true)$  events.$TAG false
        Emitter_Name  re_emitted

    [FILTER]
        Name          modify
        Match         events.*
        Remove as_event

    [OUTPUT]
        Name          pgsql
        Alias         ${HOST}_pgsql_metrics
        Match         metrics.*
        Host          <主机>
        Port          <端口>
        User          postgres
        Password      postgres
        Database      logs
        Table         metrics
        Timestamp_Key ts

    [OUTPUT]
        Name          pgsql
        Alias         ${HOST}_pgsql_app
        Match         app.*
        Host          <主机>
        Port          <端口>
        User          postgres
        Password      postgres
        Database      logs
        Table         app
        Timestamp_Key ts

    [OUTPUT]
        Name          pgsql
        Alias         ${HOST}_pgsql_events
        Match         events.*
        Host          <主机>
        Port          <端口>
        User          postgres
        Password      postgres
        Database      logs
        Table         events
        Timestamp_Key ts

    [OUTPUT]
        Name               kafka
        Alias              ${HOST}_kafka_events
        Match              events.*
        Format             json
        Timestamp_Key      ts
        Timestamp_Format   iso8601
        Topic_Key          event
        Dynamic_Topic      On
        Brokers            <主机>:<端口>
    ```

而数据的过期时间则通过启动项`--storage.tsdb.retention.time`来设置,默认为15天.我们的部署compose可以如下例:

```yml
version: "2.4"

x-log: &default-log
  options:
    max-size: "10m"
    max-file: "3"

services:
  # prometheus
  prometheus:
    image: prom/prometheus:latest
    logging:
      <<: *default-log
    ports:
      - "9090:9090"
    volumes:
      - "./prometheusconfig:/etc/prometheus"
    command:
      - "--storage.tsdb.retention.time=3d"

  # grafana
  grafana:
    image: grafana/grafana
    depends_on:
      - prometheus
    ports:
      - "3000:3000"

networks:
  local:
    driver: bridge
```

### 使用`Grafana`监控指标数据

上面的部署compose已经包含了`Grafana`的部署.`Grafana`并不是只能连`Prometheus`,它可以对接相当多的source.`Grafana`的作用主要是两方面

1. 通过定时访问这这些source获取数据的变化,构造dashboard用于监控
2. 通过构造预警规则在source有异常变化时发出警告
3. 直接访问source获得数据,并通过构造可视化图表协助分析数据

前两个是最常用的应用,而第3个其实也相当方便,只是很多人并不习惯这么用而已.

`Grafana`主要的操作场所有2个

1. `Explore`页面,用于尝试访问资源,支持单词访问和定时连续访问,只能输出时间序列折线图或者表格,且无法保存查询.一般用于探索尝试.
2. `Alert`页面,用于管理警告和设置警告频道,默认支持最常见的钉钉,邮件,也支持使用webhook方式回调.
3. `Dashboard`页面,也是最重要的页面.所有的监控,探索,警告实际都是基于此.

#### `Dashboard`

`Dashboard`实际上是`panel`的容器,一个`Dashboard`通常由复数个`panel`组成.每个`panel`包括4个部分

1. 标题.这很重要,清晰的标题可以降低维护成本.
2. 访问资源的请求设置,主要是使用什么资源,请求资源的请求(sql,或者各种请求语法),刷新数据时间间隔
3. 展示图形的设置,默认的是时间序列,但也支持饼图,柱状图,折线图等常用可视化图形.
4. 警告设置(可选),通常是设置一个时间间隔内某个指标的均值超过或者低于某个特定值来触发警告.

实际上合理配置一个`Dashboard`是个大工程,但一旦配置好后就可以只看图来监控了还是相当好用的.

我个人比较建议将`Dashboard`按用途区分不要将全部监控信息挤在一个默认`Dashboard`上.而默认`Dashboard`应该用于监控最关心的指标

### 使用`Prometheus`做指标监控的注意事项

首先我们应该明确使用`Prometheus`做指标监控的目的--护航业务稳定,保障业务的快速迭代

1. Prometheus作为一个基于指标的监控系统,在设计上就放弃了一部分数据准确性.比如在两次采样的间隔中内存用量有一个瞬时小尖峰,那么这次小尖峰我们是观察不到的;而QPS/RT/P95/P99这些值都只能估算.Prometheus无法和日志系统一样做到100%准确.降低一部分准确性带来的是更高的可靠性和更低的运维成本.而如果需要更高的准确性,我们应该使用日志分析系统.

2. 放弃一点准确性得到的是更高的可靠性,这里的可靠性体现为架构简单,数据简单,运维简单.假如你维护过`ELK`或其它日志架构的话就会发现相比于指标,日志系统想要稳定地跑下去需要付出几十倍的机器成本与人力成本.

3. 既然是权衡,那就没有好或不好,只有适合不适合.我推荐在应用`Prometheus`之初就要先考虑清楚这个问题并且将这个权衡明确地告诉使用方.

4. 关于监控的目标,个人认为并不需要所有东西都监控,我们主要要监控的就是那些会有较高负载需要保证稳定的服务,比如redis,比如数据库,而一些没有很高负载的我们可以手动找回的我们没有必要做实时的监控.
