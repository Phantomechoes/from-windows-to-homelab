# 系统更新与重启

> 记录日期：2026-10-20。阶段：Phase 1，Docker 安装之前。
> 重启后的内核：`7.0.0-38-generic`。

返回 [项目首页](../README.md)。上一篇：[自动检测与认证](07-auto-network-auth.md)。

远程通道、合盖和检测定时器都在之后，才做这轮系统更新。顺序是有意的。升级可能要求重启，重启会断开 SSH。在唯一的入口还不稳定时重启，排障会回到坏屏幕前面。

## 先看有多少更新

```bash
sudo apt update
```

当时大约有 152 个软件包可以升级。这是 `apt update` 刷新索引之后的数字。

登录时 Ubuntu 可能在欢迎信息里显示可升级数量。那一行可以来自上次缓存的快照，不能当作此刻的软件包状态。以刚刚执行的 `apt update` 为准。

## 在 tmux 里升级

SSH 会话如果在 `apt upgrade` 中途断开，终端里的前台进程会收到挂断。tmux 把升级放在服务器上的会话里，连接断开时会话还在，重新 SSH 之后可以接回去。

这次安装并使用了 tmux，然后在其中执行升级：

```bash
sudo apt install tmux
tmux
sudo apt upgrade
```

没有记录会话名字。`tmux` 打开的就是默认会话。也没有记录升级中途 SSH 真的断过。tmux 是预防，不是一次断线事故的复盘。

升级完成后，系统提示需要重启才能加载新内核。

## ssh.service 变成 inactive 的那一刻

升级之后看到：

- `ssh.service` 是 inactive 或 disabled
- `ssh.socket` 是 active，并且 enabled
- `tailscaled` 已启用
- `bjtu-autologin.timer` 已启用

`ssh.service` 不在运行，SSH 却没有因此失效。Ubuntu 这里使用 socket activation：`ssh.socket` 负责监听 22 端口，连接到来时再启动对应服务。服务单元空闲时显示 inactive，是这种启动方式的正常状态。

判断 SSH 是否还在，要看 `ssh.socket`，再实际连一次。只看 `ssh.service` 会把正常状态读成故障。

这也解释了为什么升级前的笔记和升级后的笔记不同。升级前 `systemctl is-active ssh` 返回过 `active`。升级后监听方变成了 socket。两次观察都保留，不把其中一次改写成另一一次。

## 重启

然后执行了重启。结果：

- Ubuntu 从内置 SSD 正常启动。
- 本地显示器仍然停在 tty1 的登录提示。这不影响远程会话。没有人在那块屏幕前登录，Mac 一侧的 SSH 也可以独立建立。
- Mac 再次执行 `ssh xin-server`，登录成功。
- `uname -r` 显示 `7.0.0-38-generic`。
- `ssh.socket`、`tailscaled`、`bjtu-autologin.timer` 都是 active。

新内核是这次重启要确认的事。远程登录恢复，说明 Tailscale 和 SSH 在新内核起来之后仍会跟随系统启动。合上的盖子和坏掉的内屏没有参与这次登录。

重启后的 SSH 成功，也说明服务器重新具备走到 Tailscale 的条件。这次没有单独记录校园网认证是否在重启时过期，也没有记录定时器在那一次执行了登录。重启成功不能用来给“过期后自动重认证”打勾。那一项的边界仍以 [自动检测与认证](07-auto-network-auth.md) 为准。

## Phase 1 在这里结束

到此，Docker 安装之前的基础工作完成：

- 系统是 Ubuntu Server，根分区在内置 SSD 上
- 校园网 Wi-Fi 和一次成功的网页认证已经发生
- Mac 用 `ssh xin-server` 进入 `dev@xin-server`
- 外接电源下合盖，会话还在
- 检测定时器在跑
- 升级和重启之后，内核是 `7.0.0-38-generic`，远程入口还在

Docker Engine 没有安装。下一阶段从它开始，而不是从补装一个桌面开始。

可以带走的判断集中在最后一篇：[踩坑总结](09-lessons-learned.md)。
