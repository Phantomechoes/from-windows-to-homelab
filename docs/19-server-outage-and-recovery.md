# 服务器失联：先找回主机，再恢复数据库

> Phase 4。整理日期：2026-10-28。
> 时间线来自这次补充的系统记录摘要，本次维护未读取原始 journal 或操作服务器。已恢复的是服务可用性，停机根因仍未完全查明。

返回 [项目首页](../README.md)。上一篇：[持续运行的工作负载](18-kubernetes-and-server-workloads.md)。

## Mac 上只剩下超时

服务器开始承载持续工作以后，我习惯了从 Mac 进入它。这次 SSH 等到的却是超时，Tailscale 也显示服务器无法连接。远程入口一起失效时，不能再靠同一条 SSH 去检查 SSH 自己。

最后还是到了实验室，接上本地显示器和键盘调查，并重新登录 Ubuntu。坏屏幕没有影响平时的管理，却让这次恢复重新依赖一块外接显示器。无头运行，并没有取消本地救援入口的价值。

## 能确定的两个时间点

为避免 Mac 与 Ubuntu 的时区混在一起，下面以 UTC 为主，附上北京时间（UTC+8）。

| 时间（UTC） | 北京时间 | 记录说明 |
| --- | --- | --- |
| 2026-10-24 06:47:46 左右 | 2026-10-24 14:47:46 左右 | 服务器最后的活动记录，是观察边界，不是精确的故障触发时间 |
| 两条记录之间 | 两条记录之间 | Mac SSH 超时，Tailscale 显示服务器不可连接；没有连续的本地观测来确定每一刻的电源和系统状态 |
| 2026-10-26 08:34:55 | 2026-10-26 16:34:55 | 系统记录显示服务器重新启动 |

最后活动与重新启动之间相隔约 49 小时 47 分钟。这是两条记录的间隔，不是已经测准的宕机时长。本地排查、数据库修复和成果复制没有逐项精确时间，文档不编造钟点。

## 先把能看到的证据分开

重新登录后，我排查了 systemd、kernel journal、内存、SSH、Tailscale、Docker 和 Kubernetes。日志里有曾经进入服务关停流程的迹象，也有时间接近失联的 TPM timeout。这两点都值得保留，但都还没有单独解释整件事。

| 观察或历史 | 可以保留的判断 | 还不能写下的结论 |
| --- | --- | --- |
| 实验中的 MySQL 5.7 曾内存不足 | 这台机器确实遇到过数据库资源问题 | 本次主机停机就是 OOM |
| TPM timeout 与最后活动时间接近 | 时间上接近，值得继续查 | TPM timeout 导致了关机 |
| journal 出现服务关停流程 | 系统曾走到关停服务的步骤 | 已经证明是一次正常、完整且由用户发起的关机 |
| SSH 超时、Tailscale 不可连接 | 当时远程管理路径不可用 | 已经证明内核 panic 或硬件过热 |

这里没有足够证据给出唯一根因。恢复以后看到的空闲内存，也不能代替故障时刻的内存记录。

复查同类故障时，我会先定位正确的 boot，再读取日志。下面是只读检查示例，输出需留在私有环境：

```bash
date -u
uptime -s
systemctl --failed --no-pager
sudo journalctl --list-boots

# 用 list-boots 中确认过的故障启动 ID，不能盲目假定是 -1。
sudo journalctl --boot='<BOOT_ID>' --utc \
  --since='2026-10-24 06:30:00 UTC' \
  --until='2026-10-24 07:15:00 UTC' --no-pager
sudo journalctl --boot='<BOOT_ID>' -k --utc --no-pager

free -h
df -h
systemctl status ssh.socket ssh.service tailscaled docker --no-pager
sudo ss -lntp
kubectl config current-context
kubectl get nodes
kubectl -n '<NAMESPACE>' get pods
```

SSH 仍要同时看 socket 和 service。Phase 1 升级后已经遇到过 socket activation，`ssh.service` 暂时 inactive 不能独自判定 SSH 已坏。journal 查不到某段内容时，也要考虑日志持久化和保留情况，不能把“没有留下证据”写成“没有发生”。

## 集群先回来，两个数据库没有回来

主机恢复后，kind 节点回到了 Ready，绝大部分工作负载自动恢复。这个结果说明现有环境在这一次启动后恢复了大部分服务，不代表所有断电、断网和数据损坏场景都已演练过。

两个 MongoDB Pod 留在 CrashLoopBackOff。日志指向 `/data/db/journal` 和 `/data/db/diagnostic.data`，报的是 `Permission denied`。

这时最容易顺手做的是删掉 Pod，让控制器重建。但这两个 Pod 的数据在 `emptyDir` 中。按 Kubernetes 的 [卷生命周期说明](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)，同一个 Pod 内的容器崩溃重启不会因此清空 emptyDir；Pod 被移除后，卷数据会被删除。kind 还多一层节点容器，重建整个集群也不能拿来当无损修复。

所以这次没有把“删掉再来”当作第一步。先保住原 Pod 和数据，再处理权限。

## 先备份，再核对谁能写目录

实际恢复的顺序是：先备份两个 Pod 的 emptyDir 数据，再核对 UID/GID、目录权限和受限 capabilities，最后对指定目录做最小权限调整。公开记录不收录 Pod 名称、备份内容、节点内部目录或具体 UID/GID 数值。

检查入口可以写成下面这样，但 CrashLoopBackOff 里的容器不一定有足够长的执行窗口，也不一定带 shell 或这些工具：

```bash
kubectl -n '<NAMESPACE>' describe pod '<POD_NAME>'
kubectl -n '<NAMESPACE>' logs '<POD_NAME>' -c '<CONTAINER_NAME>' --previous
kubectl -n '<NAMESPACE>' get pod '<POD_NAME>' -o yaml
kubectl -n '<NAMESPACE>' exec '<POD_NAME>' -c '<CONTAINER_NAME>' -- id
kubectl -n '<NAMESPACE>' exec '<POD_NAME>' -c '<CONTAINER_NAME>' -- \
  stat -c '%u:%g %a %n' /data/db /data/db/journal /data/db/diagnostic.data
```

`--previous` 读上一次容器退出前的日志，不是另一个 Pod 的日志。YAML 需要看 Pod 与容器各自的 securityContext、实际挂载和 volume 类型；其中可能包含内部地址或敏感配置，不能直接公开。

UID/GID 核对的是数据库进程身份和目录所有者是否匹配。capabilities 要单独核对：容器里即使显示 UID 0，丢掉相关能力后也不能假定它可以任意改属主、绕过文件权限。目录存在，也不代表数据库身份可以进入和写入。

备份不是把正在写入的数据库目录随便打个 tar 就宣告成功。要确认读取过程没有失败、归档能打开、文件已复制到原卷之外，并记录复制时数据库的状态。校验值只能核对字节；这次故障时的文件副本没有被写成数据库一致性验证或完整恢复演练。

当容器不能稳定进入时，需要根据现场选择数据提取方式，保留原 Pod 和节点。没有准确的挂载、进程身份和备份记录，就不适合给出一条通用 `chown` 命令让人照抄。这一篇只保留已经确认的顺序和修改范围：两个卷先分别备份，再调整确有问题的指定目录，没有把整个数据根目录放开。

## 数据库起来以后，还要继续看请求

调整之后，数据库重新启动，WiredTiger 打开，MongoDB 的 ping 返回 `ok:1`。随后又核对了业务读请求和自动采样，确认服务重新可用。重要实验成果还另行备份到了 Mac。

这里有几层不同的证据：

| 看到的结果 | 说明了什么 |
| --- | --- |
| Pod Running | 容器进程已经运行，不代表应用健康或数据完整 |
| WiredTiger 打开 | 存储引擎完成了这一步启动，不代表所有数据已经校验 |
| ping 返回 `ok:1` | 数据库可以响应这个命令，不代表业务集合都一致 |
| 业务读请求成功 | 检查到的访问路径恢复，不代表所有读写路径都通过 |
| 自动采样继续产生记录 | 定时流程重新工作，不代表停机期间没有数据缺口 |

这次完成的是服务可用性恢复，没有做出“数据库全部一致、没有数据损失”的结论。Mac 上多了一份成果副本，也没有因此变成完整的自动异机备份体系。

## 这些命令不能靠碰运气执行

下面是排障时要拦住的动作，不是本次维护要运行的命令：

| 危险动作 | 为什么不能盲目做 |
| --- | --- |
| `kubectl delete pod`、批量重建 Deployment | 原 Pod 的 emptyDir 可能随之消失，重建出来的不是原数据卷 |
| `kind delete cluster` 或删除 kind 节点容器 | 把集群和节点内部的数据一起置于风险中 |
| `docker system prune --volumes` | 会清理资源，不能拿来代替空间和卷归属调查 |
| `chmod -R 777 /data/db` | 放开全部数据权限，还可能掩盖实际运行身份问题 |
| 对 `/var/lib/docker` 递归改属主 | 修改引擎内部文件，影响范围远大于出错目录 |
| 直接删除 WiredTiger、journal 或 lock 文件 | 可能破坏恢复所需信息，必须依据数据库的专门恢复流程 |
| 连续强制重启主机或 Docker | 中断其他已恢复服务，也可能减少保留现场的机会 |

以后再遇到类似问题，顺序仍然是：找回主机入口，保留日志，确认集群和卷，复制数据，定位身份与权限，做最小修改，再逐层验证。停机的根因另开调查，不因为服务回来了就自动结案。

下一篇回到平时的入口：Mac 作为开发终端，Ubuntu 作为执行环境。[Cursor 远程开发](20-cursor-remote-development.md)。
