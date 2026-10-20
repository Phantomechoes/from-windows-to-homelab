# 跨架构镜像：计划，还没有做

> **Planned / Not Yet Tested**
>
> 这一篇里的命令都没有在这次迁移里执行。
> 不要把它们读成已经成功的步骤。本次任务也不下载、不传输镜像。

返回 [项目首页](../README.md)。上一篇：[第一个网页](15-first-web-service.md)。

Mac 是 Apple Silicon，架构 ARM64。`xin-server` 是 x86_64，也就是 AMD64。Phase 2 的两张镜像都是在服务器上构建的，材料是 Ubuntu amd64 软件包里的静态 BusyBox。所以它们和服务器是同一种机器语言。Mac 没有参与构建，也还没有把一张镜像送上服务器。

以后如果镜像只能从别处拿到，而 Docker Hub 在服务器上仍然打不开，一条可讨论的路是：在一台能够访问仓库的机器上，取 **Linux AMD64** 的镜像，再把归档传到 Ubuntu 上加载。这台 Mac 是候选，不是已经验证过的构建机。Mac 自己能不能打开 Docker Hub，这次没有测。

## 镜像上的平台，和 CPU 的平台

容器里跑的是 Linux 程序，不是 macOS 程序。Docker 镜像的平台写成操作系统加架构，例如 `linux/arm64` 和 `linux/amd64`。

Mac 的芯片是 ARM64。如果在 Mac 上不加平台参数就拉取一个多平台镜像，客户端通常会拿 `linux/arm64`。把这张镜像加载到 AMD64 的 Ubuntu 上，内核会拒绝执行里面的程序。常见报错是 `exec format error`。那表示文件头里的机器类型和当前 CPU 不符。它不是网络超时，也不是权限问题。

Phase 2 没有遇到这个报错，因为还没有跨机器搬运镜像。写在这里是为了以后避免把它误判成 Docker 坏了。

## 多平台镜像是一份清单

很多官方镜像的同一个标签背后是一份清单，里面各有 `linux/amd64` 和 `linux/arm64` 的实际镜像。标签相同，内容可以不同。

所以只比较标签不够。要看这次拿到的那一层是什么架构。镜像 ID 标识的是具体那一层内容，比标签更接近“你到底加载了什么”。加载之后仍然要在服务器上再查一次平台，因为传输过程不改写文件头，但选错层会把错误的文件头原样送过去。

## 建议命令

下面每一条都是 **Planned / Not Yet Tested**。把占位符换成真实镜像名之后才有意义。不要把产生的归档提交进 Git。

在一台已经有 Docker 命令、并且能够访问镜像仓库的机器上，指定服务器需要的平台：

```bash
# Planned / Not Yet Tested
docker pull --platform linux/amd64 <IMAGE>
```

Mac 要执行它，就得先有本地 Docker 环境。Docker Desktop 或其他引擎都还没作为这台 Mac 的已完成安装写进仓库。没有本地引擎，这条命令不存在。

拉取之后先看平台，再打包：

```bash
# Planned / Not Yet Tested
docker image inspect --format '{{.Os}}/{{.Architecture}}' <IMAGE>
docker save <IMAGE> -o <IMAGE_ARCHIVE>.tar
```

`docker save` 保存的是本地已经有的那张镜像。它不一定包含清单里的全部平台。如果上一步拿成了 `linux/arm64`，归档里就是 ARM64。`--platform linux/amd64` 是为了在保存之前把层选对。

传到服务器再加载。SSH 别名沿用 `xin-server`，不写 Tailscale 地址：

```bash
# Planned / Not Yet Tested
scp <IMAGE_ARCHIVE>.tar xin-server:/tmp/<IMAGE_ARCHIVE>.tar
ssh xin-server 'sudo docker load -i /tmp/<IMAGE_ARCHIVE>.tar'
```

加载完成后，在 Ubuntu 上再查一次，确认架构是 `amd64`，然后再运行：

```bash
# Planned / Not Yet Tested
sudo docker image inspect --format '{{.Id}} {{.Os}}/{{.Architecture}}' <IMAGE>
```

如果仓库支持，也可以在拉取前看清单里有哪些平台。这仍然需要能访问注册表，而 `xin-server` 当前访问 Docker Hub 是失败的。所以这条更可能用在那台负责拉取的机器上，而不是用在服务器上：

```bash
# Planned / Not Yet Tested
docker buildx imagetools inspect <IMAGE>
```

服务器上的 Buildx 版本是 0.30.1。版本在，不表示它能连上 Hub。

## Compose 里的 platform

以后的 Compose 文件可以声明服务要的平台：

```yaml
# Planned / Not Yet Tested — 不要把这段当成已经部署的文件
services:
  app:
    image: <IMAGE>
    platform: linux/amd64
```

`platform: linux/amd64` 是给拉取和构建看的约束。hello-web 那份已经在跑的 Compose **没有**这个字段，因为它是在服务器上从本地文件构建的。不要回去改已运行的项目来“补上”一个还没测试的字段。

如果 Compose 在一台 ARM64 的 Mac 上构建，却打算把结果拿到 AMD64 服务器运行，还要使用 Buildx 的跨平台构建。那也还没有测。Phase 2 避免了这个问题：构建发生在目标机器上。

## 怎么确认没有拿错

计划中的核对顺序是：

1. 拉取时写明 `--platform linux/amd64`。
2. 保存前用 `docker image inspect` 看 `Os` 和 `Architecture`。
3. `docker load` 之后在 Ubuntu 上再查一次镜像 ID 和架构。
4. 然后才 `docker run`。出现 `exec format error` 时，先回到第 2 步，而不是先怀疑守护进程。

镜像归档可能很大，也可能在以后夹带不该公开的层。`.gitignore` 忽略 `*.tar`、`*.tar.gz` 和 `*.oci`。即使忽略规则漏了，也不要把归档加进提交。

## 还没做的相邻事项

Docker Hub 在服务器上的直接访问没有解决。真实应用镜像还没有导入。PostgreSQL、Redis、自己的 API、数据备份和监控都还没有部署。它们依赖“服务器能得到一张架构正确的镜像”，所以排在这次传输试验之后，而不是排在它前面冒充已经完成。

进度见 [Roadmap](../ROADMAP.md)。
