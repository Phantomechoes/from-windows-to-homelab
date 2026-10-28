# Mac 做开发终端：用 Cursor 进入 Ubuntu

> Phase 5，远程开发的 Cursor 部分。整理日期：2026-10-28，按补充经历回顾；本次未连接服务器复测。
> 这一阶段的划分按主题组织，不表示每一步都发生在故障恢复之后。

返回 [项目首页](../README.md)。上一篇：[服务器失联与恢复](19-server-outage-and-recovery.md)。

## 不把服务器再装进 Mac

最初改造小新，是为了让它离开混乱的 Windows 开发环境。后来真正开发时，我也不想把同一套服务器环境重新复制到 Mac 上。

Mac 继续负责屏幕、键盘和编辑器；Ubuntu 负责 Linux 工具链、容器和持续运行的任务。远程开发不需要把 Mac 改装成 Linux，也不需要在 Mac 上复刻服务器的 Docker 环境。Phase 2 曾经借 Mac Docker Desktop 下载并转移 AMD64 镜像，那是获取镜像的路径，不是后面每次远程开发的前提。

已经配好的 Tailscale 和 SSH，让这两台机器各自上网后仍能相遇。`xin-server` 继续是 Mac 的 SSH 别名，真实地址不写进公开文章。

## 先有 SSH，再有编辑器

在打开远程工程之前，我先确认 Mac 的终端能登录：

```bash
ssh xin-server
```

Cursor 再通过 Remote SSH 连接同一个别名，打开 Ubuntu 上的工程。打开的是远程目录，终端命令也在服务器上执行。界面在 Mac，并不意味着运行按钮后面的进程也在 Mac。

我用 Cursor Agent / Grok 协助读取文件、执行命令、调试容器和整理实验记录。这样编辑和观察结果可以留在同一个窗口里。模型协助并不改变执行位置：它触发的远程命令仍消耗 Ubuntu 的资源，仍可能修改服务器上的文件和运行状态。

公开记录只保留这种分工，不放内部工程目录、实验脚本、研究报告或终端截图，也不补写未提供记录的 Cursor、Remote SSH 扩展和 Grok 具体版本。

## Operation timed out 不只发生在编辑器里

远程 SSH 曾经出现 `Operation timed out`。遇到它时，先退出编辑器这一层，在 Mac 终端单独检查 SSH 比较有用：

```bash
# Mac：只检查连接和远程身份，不进入研究目录。
ssh -o ConnectTimeout=10 xin-server 'hostname; uname -s; uname -m'
```

这是一条排查示例，不是本次文档维护实际执行的远程命令。连不上时，返回码和错误类型都比“编辑器正在转圈”更具体。需要更详细日志时可以私下使用 SSH 的调试选项，但日志可能带真实地址、用户名和本地路径，不能原样贴进 GitHub。

Tailscale 显示 Connected，不能代替这条 SSH 测试。它既不证明当下的端到端路径可用，也不证明 Ubuntu 的 SSH 正在接受连接，更不会替我完成 Linux 用户授权。主机上的 ssh.socket、sshd、资源状态都还要单独看。

## 编辑器断开，和主机关机，是两类事

如果普通 SSH 还能成功，而 Cursor 连接断了，排查可以继续放在远程编辑器、它的远程进程和连接状态上。不能因为窗口断开，就宣布 Ubuntu 已经停机。

反过来，SSH 超时、Tailscale 也不可达时，也不能只靠重装 Remote SSH 扩展解释。Phase 4 那次已经走到本地显示器和键盘前调查，后面还有主机启动和数据库恢复。完整过程在 [故障恢复记录](19-server-outage-and-recovery.md)。

这两类故障的共同表象都是“Mac 进不去”，需要分层验证才能知道下一步该去哪里。

## Cursor 使用期结束，任务还留在服务器

后来 Cursor 的使用期结束，服务器上的项目、Kubernetes CronJob、Ubuntu crontab 和备份并没有跟着消失。文件和调度定义属于 Ubuntu 上的环境，不属于 Mac 编辑器窗口的生命周期。

这不表示所有从远程终端启动的前台命令都会自动存活。普通 shell 进程可能受会话断开影响；systemd、cron、Kubernetes 管理的任务则有各自的生命周期。任务定义还在，也仍需检查最近一次执行和输出，不能只看它的名字。

更换开发工具因此不必迁移整套实验环境。下一步要打通的是新的控制端：让 Mac 上的 Codex 桌面应用真正能在 Ubuntu 执行命令。[Codex SSH 远程开发](21-codex-ssh-remote-development.md)。
