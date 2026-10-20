# 离线 Hello 镜像

这是 `xin-server` 上那张本地镜像的可复现形状。构建发生在服务器上，不拉取 Docker Hub。

仓库里没有 BusyBox 可执行文件。使用前在目标机器上准备静态二进制。

## 准备

在 Ubuntu 上安装发行版包：

```bash
sudo apt install busybox-static
```

然后在本目录执行准备脚本。它只检查 `/usr/bin/busybox` 是不是静态文件，并复制到当前目录。它不安装软件包，也不修改 Docker 的配置、服务或用户组。

```bash
./prepare-context.sh
```

Phase 2 当时是手工把 `/usr/bin/busybox` 复制进 `~/docker-offline-test`。这个脚本是仓库里的复现助手，不是那天服务器上跑过的命令。

## 构建和运行

```bash
sudo docker build --pull=false -t xin-offline-hello:1 .
sudo docker run --rm --network none xin-offline-hello:1
```

期望输出：

```text
Hello from Docker on xin-server!
```

Compose 测试使用同目录的 `compose.yaml`。镜像要先按上面的标签构建好。`pull_policy: never` 阻止它去仓库拉取一个并不存在的公开镜像。

```bash
sudo docker compose config
sudo docker compose up --abort-on-container-exit --exit-code-from hello
sudo docker compose down
```

`Aborting on container exit...` 是 `--abort-on-container-exit` 在进程退出后的正常收尾。退出码 0 表示这行 echo 跑完了。

过程记录在 [离线构建](../../../docs/12-offline-container-build.md) 和 [Compose 测试](../../../docs/13-docker-compose.md)。
