# Roadmap

初始记录：2026-10-20。Phase 3–5 补记：2026-10-28。

这个仓库跟着服务器一起长。已经发生的事写在 `docs/` 里，用完成时。还没做的事只写在这里，不用完成时。

Phase 1 文档的边界停在 Docker 安装之前。不要把 Phase 2 的容器回写成 Phase 1 里已经发生的事。Docker 的安装、离线镜像和第一张网页写在 Phase 2。

Phase 3–5 按补充的操作经历整理，本次维护未进入服务器复测。完成项表示记录中的局部验证，不表示当前所有服务已再次检查；缺少原始输出的版本和参数在对应章节中标注。阶段按主题划分，远程开发可能与工作负载及恢复过程交错。

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

Phase 2 留下的待办，按后续记录更新范围：

- [ ] Docker Hub 不经代理直接访问
- [ ] GHCR 实际镜像拉取验证
- [ ] PostgreSQL 部署
- [ ] Redis 部署
- [ ] 个人 API 服务
- [ ] 重要容器数据的完整备份与恢复演练（实验归档和备份已在 Phase 3 运行）
- [ ] 生产级监控和告警（实验监控已在 Phase 3 运行）
- [ ] 生产级服务安全加固

后续服务仍然沿用 [SECURITY.md](SECURITY.md)：数据库、Docker API 和管理端口不直接暴露到校园网。hello-web 只绑定了 `127.0.0.1:8080`。

## Phase 3：持续运行的实验工作负载

记录在 [持续运行的工作负载](docs/18-kubernetes-and-server-workloads.md)。

- [x] Ubuntu x86_64 上部署 kind 单节点集群，使用 kubectl 管理
- [x] 容器化多服务应用运行，检查服务发现、网络、存储与数据库访问
- [x] Prometheus、node-exporter 等实验监控组件安装并运行
- [x] Ubuntu cron 与 Kubernetes CronJob 用于定时采样、归档和备份
- [x] 对归档数据进行 SHA256 校验
- [x] 处理实验中 MySQL 5.7 内存不足的问题，后来采用 MariaDB 实验组件

MariaDB、MongoDB 是实验应用的组件，不计入个人 PostgreSQL、Redis 或个人 API 正式上线。主机和单节点集群仍共用一台机器；监控运行也不代表已经具备完整告警。

- [ ] 完整盘点数据卷，处理重要数据依赖 emptyDir 的生命周期风险
- [ ] 定期异机备份、失败告警、保留策略和恢复演练
- [ ] 生产级监控、容量规划与端到端告警机制
- [ ] 镜像版本或 digest、资源限额、TSDB retention 的可复核公开记录

## Phase 4：失联、异常停机与恢复

记录在 [服务器失联与恢复](docs/19-server-outage-and-recovery.md)。

- [x] 整理最后活动与重新启动时间：2026-10-24 06:47:46 UTC 左右、2026-10-26 08:34:55 UTC
- [x] 到实验室借助本地显示器和键盘调查，重新登录 Ubuntu
- [x] 排查 systemd、kernel journal、内存、SSH、Tailscale、Docker 与 Kubernetes
- [x] 确认 kind 节点 Ready，观察到绝大部分工作负载自动恢复
- [x] 两个 MongoDB Pod 的 emptyDir 数据先备份，再核对 UID/GID、权限和 capabilities
- [x] 指定目录做最小权限调整，WiredTiger 打开，ping 返回 `ok:1`
- [x] 核对业务读请求与自动采样，重要成果另存到 Mac

- [ ] 主机异常停机根因查明
- [ ] 数据库完整一致性验证和可复现恢复演练
- [ ] 主机重启、断网、代理中断等场景下的完整自动恢复验证

历史 MySQL 内存问题不等于此次停机由 OOM 导致，TPM timeout 的时间接近也不等于因果已证实。已完成的是这次服务可用性恢复，不把它改写成零数据损失或生产级稳定性。

## Phase 5：Mac 远程开发，从 Cursor 到 Codex

记录在 [Cursor](docs/20-cursor-remote-development.md) 与 [Codex](docs/21-codex-ssh-remote-development.md) 两篇。

- [x] Cursor Remote SSH 经 Tailscale / SSH 打开 Ubuntu 工程
- [x] Cursor Agent / Grok 协助远程读文件、执行命令、调试和整理记录
- [x] Mac 安装并登录 Codex 桌面应用，Ubuntu 使用 Linux x86_64 CLI
- [x] Mac 回环代理通过 SSH `-R` 提供给 Ubuntu，HTTPS 路径验证
- [x] `codex login --device-auth` 完成认证，CLI 纯模型响应测试通过
- [x] 非交互 SSH 的 PATH 经 `/usr/local/bin/codex` 符号链接修复
- [x] 确认残留 app-server 身份后，以 SIGTERM 结束并重新连接
- [x] 补齐 `codex-code-mode-host`，处理执行组件缺失
- [x] 安装 Ubuntu 仓库的 bubblewrap，基础隔离测试通过
- [x] 修正测试命令，最后默认沙箱内 `pwd`、`ls` 实际执行成功

上述验证未通过关闭 AppArmor 或全局放开 user namespaces 实现。记录中的 CLI 和 bubblewrap 版本见文章开头，本次没有把它们当作当前推荐版本或重装依据。

- [ ] 远程会话长期稳定性、Mac 休眠或代理中断后的重连验证
- [ ] 远程启动环境和组件安装方式的可复核记录（不含认证文件）
- [ ] 完整安全加固，包括尚未完成的 SSH 与防火墙收口

## 讨论过、尚未执行

让一台完全独立、没有加入当前 tailnet 的朋友 Mac 访问这台服务器。当时谈定的做法是：

1. 用 Tailscale 共享指定设备，朋友用自己的 Tailscale 账号接受邀请。
2. 需要 SSH 时，在 Ubuntu 上新建单独的 Linux 用户，只写入朋友自己的公钥。
3. 不提供 `dev` 的口令、这台 Mac 的 SSH 私钥，也不提供 Tailscale 登录信息和 auth key。

设备邀请没有发出，Linux 用户没有创建，对方也没有登录成功。这项保持未完成。

## 仍未实施或未完成的后续建设

这些如果将来要做，也只能源于新的实施记录，不能回写成更早的阶段已经发生：

- NVIDIA 驱动
- 本地大模型运行时
- PostgreSQL、Redis 或个人 API 的正式上线
- 完整的定期异机备份、保留策略和恢复演练
- 完整的防火墙加固
- 正式的多用户共享
- 公网域名

Phase 1 结束时还没有容器。Phase 2 的 hello-web 单独记录，不回写进 Phase 1。

Phase 3 的定时任务和实验监控已经运行；Phase 4 的 Mac 副本是一次成果备份，仍不能替代上述长期备份体系。

## 文档怎么跟着更新

1. 先在机器上做完，并核对输出。
2. 再改对应的 `docs/` 和 README 状态。
3. 密钥、校园网口令、真实 IP、MAC、Tailscale 地址、邀请链接不进提交。
4. 提交说明写清楚新增的是哪一段经历。
