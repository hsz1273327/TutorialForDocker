# 使用Docker管理你的项目

我们使用docker作为部署平台为的就是降低运维成本,提高机器和人的工作效率.基本上要做到上面两点要做的事包括如下3个方面:

1. 执行环境管理
2. 监控,警告和log收集
3. 自动化

本部分也是围绕这3个方面展开.通过portainer,harbor以及jenkins让你的项目拥有快速检测快速部署的能力,通过fluent-bit,Prometheus,Grafana以及timescaledb(或者elasticsearch)让你可以监控自己的系统,及时了解负载快速响应错误