# Roadmap

记录日期：2026-10-20。

这个仓库跟着服务器一起长。已经发生的事写在 `docs/` 里，用完成时。还没做的事只写在这里，不用完成时。

Phase 1 的边界很明确：Docker Engine 还没有安装。不要在旧文档里补一句“后来其实装过”。下一阶段会新开文档。

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

## Phase 2：服务

下面都还没做。实施时再写新的文档，并更新 README 的状态清单。

- [ ] 安装 Docker Engine
- [ ] 使用 Docker Compose 部署
- [ ] 部署数据库、API 或其他长期运行的服务
- [ ] 监控、备份和告警

部署这些服务时沿用 [SECURITY.md](SECURITY.md) 的约束：数据库、Docker API 和管理端口不直接暴露到校园网。

## 讨论过、尚未执行

让一台完全独立、没有加入当前 tailnet 的朋友 Mac 访问这台服务器。当时谈定的做法是：

1. 用 Tailscale 共享指定设备，朋友用自己的 Tailscale 账号接受邀请。
2. 需要 SSH 时，在 Ubuntu 上新建单独的 Linux 用户，只写入朋友自己的公钥。
3. 不提供 `dev` 的口令、这台 Mac 的 SSH 私钥，也不提供 Tailscale 登录信息和 auth key。

设备邀请没有发出，Linux 用户没有创建，对方也没有登录成功。这项保持未完成。

## 明确不在本次记录里的事

这些如果将来要做，也只能源于新的实施记录，不能回写成 Phase 1 已经发生：

- NVIDIA 驱动
- 本地大模型运行时
- 某一款具体数据库的正式上线
- 已经在跑的容器
- 定时备份任务
- 完整的防火墙加固
- 正式的多用户共享
- 公网域名

## 文档怎么跟着更新

1. 先在机器上做完，并核对输出。
2. 再改对应的 `docs/` 和 README 状态。
3. 密钥、校园网口令、真实 IP、MAC、Tailscale 地址、邀请链接不进提交。
4. 提交说明写清楚新增的是哪一段经历。
