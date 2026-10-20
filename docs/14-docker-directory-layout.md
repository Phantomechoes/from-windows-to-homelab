# 目录：先把位置定下来

> Phase 2。`/srv/docker` 已创建。
> Docker 的 data-root 仍是 `/var/lib/docker`。备份还没有做。

返回 [项目首页](../README.md)。上一篇：[Compose 测试](13-docker-compose.md)。

Windows 那台旧环境最后变得难管，有一个很具体的原因：工具、数据和试验项目堆在一起，过几个月就分不清哪一摊还要留。容器一多，同样的事会再来一遍。所以在部署第一个长期服务之前，先把服务器上的项目根目录定死。

## 实际创建的树

```text
/srv/docker/
├── stacks/
├── data/
└── secrets/
```

| 路径 | 权限 | 所有者 |
| --- | --- | --- |
| `/srv/docker` | `750` | `dev:dev` |
| `/srv/docker/stacks` | `750` | `dev:dev` |
| `/srv/docker/data` | `750` | `dev:dev` |
| `/srv/docker/secrets` | `700` | `dev:dev` |

用的是 `install -d`，在创建时就把所有者和权限一起设上。不是先建一个谁都能写的目录，再指望以后想起来收紧。对应这次结果的写法是：

```bash
sudo install -d -o dev -g dev -m 750 /srv/docker /srv/docker/stacks /srv/docker/data
sudo install -d -o dev -g dev -m 700 /srv/docker/secrets
```

`750` 让所有者可进可写，同组可读可进入，其他用户进不去。`secrets` 是 `700`，同组也不进。

## 三个目录各放什么

`stacks` 放 Compose 项目。每个服务自己一个子目录，里面是 `compose.yaml`、Dockerfile 和它的构建文件。第一个长期项目在 `/srv/docker/stacks/hello-web`。

`data` 留给以后要跨容器重启保留的文件，比如数据库的数据目录。Phase 2 没有往这里放数据库，也没有把某个容器的数据卷绑到这里作为已完成的持久化方案。

`secrets` 留给权限更紧的配置。目录模式严格，只说明这个文件夹不对外可读。它不表示可以把密码提交到 GitHub，也不表示已经有一份生产凭据放在里面。这个仓库继续不收录校园网口令、令牌和 `.env`。

## 它不是引擎的数据盘

Docker Engine 的镜像、容器层和默认卷仍在：

```text
/var/lib/docker
```

这次没有修改 data-root，没有把引擎的内部目录迁到 `/srv/docker`。`/srv/docker` 是人管理项目的位置。删掉 stacks 里的一份 Compose 文件，不会自动删掉 `/var/lib/docker` 里的镜像。反过来，整理 `/srv/docker/data` 也不会代替引擎自己的磁盘占用。

## 容量只是当时的快照

检查根文件系统时，大约是：

| 项目 | 当时的大约值 |
| --- | --- |
| 根文件系统容量 | 915GB |
| 已使用 | 8.4GB |
| 可用 | 860GB |

这是那一次看到的用量，不是配额，也不会一直保持。安装镜像和以后的数据都会改变它。Phase 1 安装器里看到的根分区约 930GiB，是分区时的大约值。两处数字来自不同的观察，都按当时的记录保留。

## 有目录还不等于有备份

`/srv/docker/data` 只是一个权限定好的文件夹。没有定时拷贝，没有异地副本，没有恢复演练。把数据库文件放进这个目录，只说明文件在这台磁盘上。磁盘坏了，目录规划救不回来。

备份仍在未完成清单里，见 [Roadmap](../ROADMAP.md)。

第一个真正留在线上的服务，放在 `stacks/hello-web`：[第一个网页](15-first-web-service.md)。
