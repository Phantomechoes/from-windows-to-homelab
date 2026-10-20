# Compose：本地镜像跑通，然后把测试容器删掉

> Phase 2。Compose 的本地编排已经测过。
> 测试容器不是那个后来一直开着的网页。

返回 [项目首页](../README.md)。上一篇：[离线容器](12-offline-container-build.md)。

引擎负责创建容器。Compose 负责读一份项目文件，按里面的服务定义去调用引擎。这次要确认的是：刚才那个只存在于本地的镜像，Compose 会不会自作主张再去仓库拉一次，以及它会不会把退出码交回来。

## 项目文件

仍在 `~/docker-offline-test`。`compose.yaml` 是：

```yaml
services:
  hello:
    image: xin-offline-hello:1
    pull_policy: never
    network_mode: none
    restart: "no"
```

`restart: "no"` 的引号是有意义的。YAML 里不加引号的 `no` 会被读成布尔值。重启策略需要的是字符串 `no`。

先让 Compose 把文件解析出来：

```bash
sudo docker compose config
```

检查通过。这一步渲染配置，不创建容器。

然后按“容器一退出就结束这次 up”来跑：

```bash
sudo docker compose up --abort-on-container-exit --exit-code-from hello
```

实际输出里有：

```text
Hello from Docker on xin-server!
hello-1 exited with code 0
Aborting on container exit...
```

之后清理：

```bash
sudo docker compose down
sudo docker ps -a
```

`down` 删掉了这次测试创建的容器。随后 `docker ps -a` 看到的是没有剩余容器。这是清理之后的那一次观察。后来的网页服务是再往后部署的，不要把这次空列表理解成服务器上永远没有容器。

## 引擎和 Compose 各管一段

Docker Engine 保存镜像、创建容器、连接网络、挂载文件系统。没有 Compose，刚才的 `docker build` 和 `docker run` 已经能工作。

Compose 是这上面的项目层。它读 `compose.yaml`，决定服务叫什么、用哪张镜像、要不要替你拉取、网络和重启策略是什么。`docker compose up` 最后还是在请引擎创建容器。Compose 自己不是另一个容器运行时。

## pull_policy: never

`xin-offline-hello:1` 只存在于这台机器的本地镜像库。Hub 上没有这个名字，Hub 本身也连不上。

`pull_policy: never` 告诉 Compose：不要拉取这张镜像。本地有，就用本地的。本地没有，就失败，而不是去 `docker.io` 碰运气。没有这条策略的话，Compose 的默认行为可能在启动前访问注册表，然后重新掉进上一篇的超时。

`network_mode: none` 和手工运行时的 `--network none` 是同一件事。这个服务不需要网卡。

## 退出码 0，以及那句 Aborting

`hello-1 exited with code 0` 表示容器里的主进程以状态 0 结束。对这个镜像，主进程就是 BusyBox 的 `echo`。它打印完那一行，工作就做完了，所以退出码 0 是成功。

`Aborting on container exit...` 来自 `--abort-on-container-exit`。这个参数的含义就是：有容器退出时，停止这次 `up`。进程正常结束，Compose 按参数收尾。那一行是这个参数的正常输出，不是构建失败，也不是守护进程报错。

`--exit-code-from hello` 让 Compose 把 `hello` 这个服务的退出码当作自己的退出码。服务是 0，这次 `up` 就是成功结束。

## 跑完就退出，和一直开着

这次测试的容器生命周期是：创建、打印、退出、被 `down` 删除。它用来证明 Compose 能编排一张本地镜像。

长期服务是另一种用法。网页那个项目用 `restart: unless-stopped`，进程留在前台提供 HTTP，不靠“打印一行然后退出”来表示成功。两种都合法。把测试容器的退出当成故障，或者把常驻服务的不退出当成挂死，都是把场景看反了。

网页是下一阶段的目录定好之后才部署的。目录本身先记在 [目录规划](14-docker-directory-layout.md)。
