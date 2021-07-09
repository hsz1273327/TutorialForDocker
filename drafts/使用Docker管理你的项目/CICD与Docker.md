## 用https://crazymax.dev/diun/监控镜像更新


## 使用api调用portainer

Portainer的http api可以在[swaggerhub](https://app.swaggerhub.com/apis/deviantony/Portainer/1.24.1)上找到,截止至Portainer 2.0版本,它的api文档还在1.24.1版本,但好在上面的api都还可以用,借助这个我们可以自动化除k8s端点外的各种端点上的部署过程.以swarm上为例可以参考下面的python脚本

```python
import os
import yaml
import requests as rq
IMG_VERSION = os.getenv("IMG_VERSION")
if not IMG_VERSION:
    assert AttributeError("IMG_VERSION 不存在")
CI_REGISTRY_IMAGE = os.getenv("CI_REGISTRY_IMAGE")
if not CI_REGISTRY_IMAGE:
    assert AttributeError("CI_REGISTRY_IMAGE 不存在")
DEPLOY_ENV = os.getenv("DEPLOY_ENV")
if DEPLOY_ENV not in ("dev", "release"):
    assert AttributeError("DEPLOY_ENV 不合法,只能是dev和release")


def deploy(*, url: str, username: str, password: str, endpoint_id: int, task_id: str, service_name: str, image_name: str) -> None:
    res = rq.post(
        url + "/auth",
        json={
            "Username": username,
            "Password": password
        }
    )
    jwt = res.json().get("jwt")
    res = rq.get(
        f"{url}/stacks/{task_id}/file",
        headers=rq.structures.CaseInsensitiveDict({"Authorization": "Bearer " + jwt})
    )
    StackFileContent = res.json().get("StackFileContent")
    s = yaml.load(StackFileContent)
    s['services'][service_name]['image'] = image_name
    compose = yaml.dump(s)
    res = rq.put(
        f"{url}/stacks/{task_id}",
        headers=rq.structures.CaseInsensitiveDict({"Authorization": "Bearer " + jwt}),
        params={"endpointId": endpoint_id},
        json={
            "StackFileContent": compose,
            "Prune": False
        }
    )
    print(res.json())


if __name__ == "__main__":
    if DEPLOY_ENV == "dev":
        image_name = f"{CI_REGISTRY_IMAGE}:dev-{IMG_VERSION}"
        CI_DEV_DEPLOY_USER = os.getenv("CI_DEV_DEPLOY_USER")
        if not CI_DEV_DEPLOY_USER:
            raise AttributeError("CI_DEV_DEPLOY_USER 不存在")
        CI_DEV_DEPLOY_PWD = os.getenv("CI_DEV_DEPLOY_PWD")
        if not CI_DEV_DEPLOY_PWD:
            raise AttributeError("CI_DEV_DEPLOY_PWD 不存在")
        CI_DEV_DEPLOY_URL = os.getenv("CI_DEV_DEPLOY_URL")
        if not CI_DEV_DEPLOY_URL:
            raise AttributeError("CI_DEV_DEPLOY_URL 不存在")
        url = CI_DEV_DEPLOY_URL
        username = CI_DEV_DEPLOY_USER
        password = CI_DEV_DEPLOY_PWD
        CI_DEV_DELPOY_PATH = os.getenv("CI_DEV_DELPOY_PATH")
        if not CI_DEV_DELPOY_PATH:
            raise AttributeError("CI_DEV_DELPOY_PATH 不存在")
        for p in CI_DEV_DELPOY_PATH.split(","):
            try:
                CI_DEV_ENDPOINT_ID, CI_DEV_STACK_ID, CI_DEV_SERVICE_NAME = p.split("/")
                if not CI_DEV_STACK_ID.isdigit():
                    raise AttributeError(f"CI_DEV_STACK_ID 必须为数字型,实际为{CI_DEV_STACK_ID}")
                if not CI_DEV_ENDPOINT_ID.isdigit():
                    raise AttributeError(f"CI_DEV_ENDPOINT_ID 必须为数字型,实际为{CI_DEV_ENDPOINT_ID}")
                endpoint_id = int(CI_DEV_ENDPOINT_ID)
                task_id = CI_DEV_STACK_ID
                service_name = CI_DEV_SERVICE_NAME
                deploy(
                    url=url,
                    username=username,
                    password=password,
                    endpoint_id=endpoint_id,
                    task_id=task_id,
                    service_name=service_name,
                    image_name=image_name)
            except Exception as e:
                print(f"{username}@{password} deploy {image_name} in dev {url} failed at {p}")
                print(f"err: {e}")
            else:
                print(f"{username}@{password} deploy {image_name} in dev {url} succeed at {p}")
    if DEPLOY_ENV == "release":
        image_name = f"{CI_REGISTRY_IMAGE}:latest"
        CI_PRO_DEPLOY_USER = os.getenv("CI_PRO_DEPLOY_USER")
        if not CI_PRO_DEPLOY_USER:
            raise AttributeError("CI_PRO_DEPLOY_USER 不存在")
        CI_PRO_DEPLOY_PWD = os.getenv("CI_PRO_DEPLOY_PWD")
        if not CI_PRO_DEPLOY_PWD:
            raise AttributeError("CI_PRO_DEPLOY_PWD 不存在")
        CI_PRO_DEPLOY_URL = os.getenv("CI_PRO_DEPLOY_URL")
        if not CI_PRO_DEPLOY_URL:
            raise AttributeError("CI_PRO_DEPLOY_URL 不存在")
        url = CI_PRO_DEPLOY_URL
        username = CI_PRO_DEPLOY_USER
        password = CI_PRO_DEPLOY_PWD
        CI_PRO_DELPOY_PATH = os.getenv("CI_PRO_DELPOY_PATH")
        if not CI_PRO_DELPOY_PATH:
            raise AttributeError("CI_PRO_DELPOY_PATH 不存在")
        for p in CI_PRO_DELPOY_PATH.split(","):
            try:
                CI_PRO_ENDPOINT_ID, CI_PRO_STACK_ID, CI_PRO_SERVICE_NAME = p.split("/")
                if not CI_PRO_STACK_ID.isdigit():
                    raise AttributeError(f"CI_PRO_STACK_ID 必须为数字型,实际为{CI_PRO_STACK_ID}")
                if not CI_PRO_ENDPOINT_ID.isdigit():
                    raise AttributeError(f"CI_PRO_ENDPOINT_ID 必须为数字型,实际为{CI_PRO_ENDPOINT_ID}")
                endpoint_id = int(CI_PRO_ENDPOINT_ID)
                task_id = CI_PRO_STACK_ID
                service_name = CI_PRO_SERVICE_NAME
                deploy(
                    url=url,
                    username=username,
                    password=password,
                    endpoint_id=endpoint_id,
                    task_id=task_id,
                    service_name=service_name,
                    image_name=image_name)
            except Exception as e:
                print(f"{username}@{password} deploy {image_name} in pro {url} failed at {p}")
                print(f"err: {e}")
            else:
                print(f"{username}@{password} deploy {image_name} in pro {url} succeed at {p}")

```

上面这个脚本依赖于如下几个环境变量

| 环境变量             | 说明                                              | 形式                                                            |
| -------------------- | ------------------------------------------------- | --------------------------------------------------------------- |
| `IMG_VERSION`        | 镜像版本                                          | `0.0.0`                                                         |
| `CI_REGISTRY_IMAGE`  | 镜像标签,不含版本                                 | `hsz1273327/test_sanic`                                         |
| `DEPLOY_ENV`         | 执行环境                                          | `release`,`dev`                                                 |
| `CI_DEV_DEPLOY_USER` | 测试环境有部署权限的portainer的注册用户           | ---                                                             |
| `CI_DEV_DEPLOY_PWD`  | 测试环境有部署权限的portainer的注册用户的登录密码 | ---                                                             |
| `CI_DEV_DEPLOY_URL`  | 测试环境portainer的根url                          | ---                                                             |
| `CI_DEV_DELPOY_PATH` | 在测试环境要部署的位置                            | `endpoint/stackid/servicename;endpoint/stackid/servicename;...` |
| `CI_PRO_DEPLOY_USER` | 生产环境有部署权限的portainer的注册用户           | ---                                                             |
| `CI_PRO_DEPLOY_PWD`  | 生产环境有部署权限的portainer的注册用户的登录密码 | ---                                                             |
| `CI_PRO_DEPLOY_URL`  | 生产环境portainer的根url                          | ---                                                             |
| `CI_PRO_DELPOY_PATH` | 在生产环境要部署的位置                            | `endpoint/stackid/servicename;endpoint/stackid/servicename;...` |
