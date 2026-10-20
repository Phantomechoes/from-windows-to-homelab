# Roadmap

记录日期：2026-10-20。

这个仓库跟着服务器一起长。已经发生的事写在 `docs/` 里，用完成时。还没做的事只写在这里，不用完成时。

Phase 1 文档的边界停在 Docker 安装之前。不要把 Phase 2 的容器回写成 Phase 1 里已经发生的事。Docker 的安装、离线镜像和第一张网页写在 Phase 2。

## Phase 1：Docker 之前

已经完成，并且在文档里有对应记录。

- [x] 重要文件先备份，再从 Ubuntu 安装介质清掉 Windows
- [x] Ubuntu Server 26.04.1 LTS 安装到整块内置 SSD
- [x] 坏掉的内屏不再挡住日常管理，Mac 可以远程进入系统
- [x] `wlo1` 通过 Netplan 连接开放校园网，并完成过网页认证
- [x] Mac 经 Tailscale 使用 SSH 进入 `dev@xin-server`
- [x] Ed25519 密钥和 `~/.ssh/config` 别名 `xin-server`
- [x] 外接电源下合盖，SSH 会话保持
- [x] `bjtu-autologin.timer` 已 enable，状态 active，出现过 `Internet OK; no login required.`
- [x] `apt upgrade` 之后重启，内核 `7.0.0-38-generic`，`ssh xin-server` 再次成功

Phase 1 里已经搭好、但还没有闭环验证的一项：

- [ ] 校园网认证**自然过期**之后，定时器发现门户页面、重新认证、并确认互联网恢复

定时检测在跑。自动恢复的完整路径还没有撞上过一次真实过期。在那次实测写进仓库之前，这一项保持未完成。

同样还没有做，因此不算 Phase 1 的安全加固成果：

- 关闭 SSH 密码登录
- 用防火墙把 22 端口收到 Tailscale 接口上
- 给朋友的 Mac 授权

## Phase 2：Docker 与第一张网页

引擎、离线镜像和第一张网页记录在 `docs/10` 到 `docs/15`。镜像传输和 Registry 记录在 `docs/16`、`docs/17`。

- [x] Docker Engine 安装（Ubuntu 源，`docker.io` 29.1.3，服务 active 且 enabled）
- [x] Docker Compose V2 安装（2.40.3）
- [x] Docker Buildx 安装（0.30.1）
- [x] 离线 BusyBox 镜像构建
- [x] 本地容器运行测试
- [x] Compose 测试
- [x] Docker 目录结构 `/srv/docker`
- [x] 第一个持续运行的 Web 服务 hello-web
- [x] Mac SSH Tunnel 浏览器访问 `http://localhost:18080`

Docker 官方 APT 源没有变成可用的安装渠道。Docker Hub 的直连也没有修好。离线构建、文件传输和 AWS Public ECR 是另外三条已经试过的路。

镜像获取的后续验证已经完成，记录在 [docs/16-cross-architecture-plan.md](docs/16-cross-architecture-plan.md) 和 [docs/17-registry-access-strategy.md](docs/17-registry-access-strategy.md)：

- [x] Mac ARM64 → Ubuntu AMD64 镜像传输
- [x] AMD64 镜像架构验证
- [x] docker save / SCP / docker load
- [x] 服务器运行 Mac 传输的 hello-world
- [x] Docker Hub 通过 Mac SSH 代理成功拉取
- [x] AWS Public ECR 无代理独立下载
- [x] AWS Public ECR Nginx 容器执行验证

经 Mac 的 Hub 代理是临时通道，drop-in 已经停用。它不计入 Docker Hub 直连。

尚未完成：

- [ ] Docker Hub 不经代理直接访问
- [ ] GHCR 实际镜像拉取验证
- [ ] PostgreSQL 部署
- [ ] Redis 部署
- [ ] 个人 API 服务
- [ ] 容器数据备份
- [ ] 监控和告警
- [ ] 生产级服务安全加固

后续服务仍然沿用 [SECURITY.md](SECURITY.md)：数据库、Docker API 和管理端口不直接暴露到校园网。hello-web 只绑定了 `127.0.0.1:8080`。

## 讨论过、尚未执行

让一台完全独立、没有加入当前 tailnet 的朋友 Mac 访问这台服务器。当时谈定的做法是：

1. 用 Tailscale 共享指定设备，朋友用自己的 Tailscale 账号接受邀请。
2. 需要 SSH 时，在 Ubuntu 上新建单独的 Linux 用户，只写入朋友自己的公钥。
3. 不提供 `dev` 的口令、这台 Mac 的 SSH 私钥，也不提供 Tailscale 登录信息和 auth key。

设备邀请没有发出，Linux 用户没有创建，对方也没有登录成功。这项保持未完成。

## 明确不在本次记录里的事

这些如果将来要做，也只能源于新的实施记录，不能回写成更早的阶段已经发生：

- NVIDIA 驱动
- 本地大模型运行时
- PostgreSQL、Redis 或个人 API 的正式上线
- 定时备份任务
- 完整的防火墙加固
- 正式的多用户共享
- 公网域名

Phase 1 结束时还没有容器。Phase 2 的 hello-web 单独记录，不回写进 Phase 1。

## 文档怎么跟着更新

1. 先在机器上做完，并核对输出。
2. 再改对应的 `docs/` 和 README 状态。
3. 密钥、校园网口令、真实 IP、MAC、Tailscale 地址、邀请链接不进提交。
4. 提交说明写清楚新增的是哪一段经历。
