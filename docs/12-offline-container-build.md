# 离线构建：不向 Docker Hub 要基础镜像

> Phase 2 的第一个运行里程碑。
> 成功输出：`Hello from Docker on xin-server!`
> 这不表示 Docker Hub 已经恢复。

返回 [项目首页](../README.md)。上一篇：[镜像仓库超时](11-docker-registry-troubleshooting.md)。

Hub 的连接一直没有好。继续重试 `hello-world`，只是把同一个超时再看一遍。我改成先证明这台机器自己会构建、会运行。外部仓库不参加这次测试。

## 材料来自 Ubuntu，不来自镜像仓库

从 Ubuntu 官方源安装了静态 BusyBox：

```bash
sudo apt install busybox-static
```

包里的可执行文件在 `/usr/bin/busybox`。工作目录是：

```text
~/docker-offline-test
```

把这个二进制复制进构建目录。仓库里的示例不包含这份 ELF。它是发行版软件包里的文件，留在服务器上。复现步骤见 [`examples/docker/offline-hello/README.md`](../examples/docker/offline-hello/README.md)。

Dockerfile 的核心就是这三行：

```dockerfile
FROM scratch
COPY busybox /busybox
CMD ["/busybox", "echo", "Hello from Docker on xin-server!"]
```

构建时明确不去拉基础镜像：

```bash
sudo docker build --pull=false -t xin-offline-hello:1 ~/docker-offline-test
```

运行时不给容器网络：

```bash
sudo docker run --rm --network none xin-offline-hello:1
```

终端里打出：

```text
Hello from Docker on xin-server!
```

## scratch 是空的根文件系统

`FROM scratch` 表示镜像从零开始，里面没有 shell、没有包管理器、没有 C 库，也没有一份从注册表下载的上层系统。构建时复制进去的文件，就是容器里的全部文件。

`scratch` 是引擎认识的空起点，不需要向 Docker Hub 拉取一个基础镜像。`--pull=false` 再明确告诉构建过程：不要为了刷新基础镜像去联系仓库。两条一起用，这次构建的网络需求和“拉一个 ubuntu 镜像”不是一类事。

## 静态 BusyBox 才能在空镜像里启动

BusyBox 把常用的小工具做进一个可执行文件。`echo` 只是其中一个。Ubuntu 上有动态链接的 BusyBox，也有 `busybox-static` 这个静态包。

动态链接的程序启动时要找 `ld-linux` 和 `libc`。scratch 镜像里没有这些文件，动态程序会在进 `main` 之前失败。静态二进制把需要的代码放在自己文件里，单独一个文件就能被内核执行。所以复制进 scratch 的是 `/usr/bin/busybox` 这份静态程序，而不是任意一个叫 busybox 的命令。

这次二进制来自服务器自己的 Ubuntu 软件包。构建也发生在 `xin-server` 上。镜像内容和这台 amd64 机器是同一种架构。Mac 没有参与这次构建。后来的跨机器传输是另一件事，见 [跨架构传输](16-cross-architecture-plan.md)。

## --network none 证明的是什么

`--network none` 给容器一个没有网络接口的网络命名空间。这个 `echo` 不需要网卡。命令能跑完，说明运行容器这件事没有偷偷再去连一次 Docker Hub。

再加上 `--rm`：进程结束，容器记录删掉。留下的是镜像 `xin-offline-hello:1`，不是一个常驻容器。

```mermaid
flowchart LR
  pkg[安装 busybox-static] --> bin["/usr/bin/busybox"]
  bin --> ctx[复制到构建目录]
  ctx --> imageNode["docker build --pull=false"]
  imageNode --> runNode["docker run --network none"]
  runNode --> hello["Hello from Docker on xin-server"]
```

## 这次成功证明了什么

它证明四件事：

- 本机 Docker 可以在不联系 Hub 的情况下完成一次 `docker build`。
- 构建产物能被 `dockerd` 创建成容器。
- 容器里的进程能运行，并把标准输出交回客户端。
- 静态 BusyBox 加 scratch 这条路径在这台 amd64 服务器上是通的。

它不证明：

- `hello-world` 现在拉得下来。
- `registry-1.docker.io` 的 HTTPS 已经恢复。
- 任意一个需要基础镜像的 Dockerfile 都能构建。`FROM ubuntu` 仍然要下载。
- 这个镜像适合当长期服务。它的命令是打印一行然后退出。

下一篇用 Compose 把同一张本地镜像再跑一遍：[Compose 测试](13-docker-compose.md)。
