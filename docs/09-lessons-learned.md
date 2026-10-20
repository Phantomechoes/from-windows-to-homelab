# 踩坑总结

> 记录日期：2026-10-20。阶段：Phase 1，Docker 安装之前。
> 这一篇不增加新的操作。它只收束已经发生的事。

返回 [项目首页](../README.md)。上一篇：[系统更新与重启](08-system-maintenance.md)。

## 屏幕

Windows 桌面里亮着的外接显示器，不代表 UEFI 和 GRUB 会在同一路输出上亮着。USB-C 转接和笔记本原生 HDMI，对固件可以是两条路。这次是在改用原生 HDMI 之后看见了联想启动菜单。

启动菜单里的 `ubuntu`、`Linpus lite` 会同时出现在 SSD 和 USB 上。选择时看设备位置。旧记录的来历没有在这次追完，也不影响选中安装 U 盘。

无头是 SSH 可用之后的状态。安装的那一段仍然需要一次看得见的 GRUB。重启后的 tty1 登录提示可以一直亮着，它不代表远程会话不存在。

## 安装

不需要先把 Windows 重置一遍。备份完成之后，可以从安装介质启动，在安装器里清除旧系统。清除整块 SSD 没有回收站。

Ubuntu Server 进入文本终端，是这款系统的界面，不是少装了桌面。提示符 `dev@xin-server:~$` 就是安装成功后的样子。

安装时连不上的 Wi-Fi 可以跳过。后果是第一次启动会在 `network wait-online` 上等。等等就会进系统。这份等待后来用 Netplan 的 `optional: true` 避免再次发生。

LVM 和 LUKS 这次都没启用。没有加密，就没有“无头机器如何在开机时解锁”这个问题。以后若要加密，先设计解锁，再打开 LUKS。

## 网络要分成层

| 层 | 这次怎样算通过 | 通过了还不包括 |
| --- | --- | --- |
| 无线关联 | 开放 SSID 接受 `wlo1` | 互联网访问 |
| DHCP | 接口上有地址 | 门户放行 |
| Captive Portal | 认证接口接受登录，外部 HTTPS 返回正常页面 | Mac 能访问这台机器的校园网 IP |
| Tailscale | 两端 Connected，SSH 走 Tailscale 地址成功 | Linux 用户的 shell 权限 |
| SSH | 密码或 `authorized_keys` 放行 | 以上任何一层自动成立 |

`wlan0` 是安装器里见过的名字。装完以后按 `ip -br addr` 配置，名字是 `wlo1`。

`networkd backend does not support wifi with match` 要删的是 `match` 和 `set-name`，不是去改 SSID。YAML 的缩进和冒号后的空格会在这之前先失败。`netplan generate` 成功时可以没有输出。

curl 拿到 JavaScript 跳转页，说明请求停在门户上。curl 不执行那段脚本。桌面系统会弹认证窗，Ubuntu Server 不会。这不是无线网卡失败。

认证接口的成功结果里见过 `{"result":1,"msg":"Portal..."}`。这是这所学校当时的门户，不是通用 API。现有提交方式是 HTTPS GET，查询字符串仍可能进服务器日志。

HTTP 200 要连正文一起读。门户页也可以返回 200。

## 远程

sshd 在 `0.0.0.0:22` 监听，只说明本机服务准备好了。Mac 访问校园网 IP 时仍然超时，也出现过 `Host is down`。关掉 Mac 上的另一个 VPN 之后，这条直连还是没有成为管理通道。路由检查里见过 `REJECT`。

现象与无线客户端隔离高度一致。管理员没有确认之前，它就停留在这个表述里。实际决策是改用 Tailscale，而不是继续证明隔离。

Tailscale 基于 WireGuard。同一个 tailnet 里的设备，有机会跨物理网络互访；打洞失败时可能走加密中继。这次会话是直连还是中继，没有记录。

网页里的设备授权不写入 `authorized_keys`。私钥 `~/.ssh/id_ed25519_xinserver` 只留在 Mac，带 passphrase。passphrase 不是 `dev` 的登录密码。公钥追加进 `authorized_keys`，原有条目保留。

第一次连接时确认的 host key，和用户密钥，是两次不同的检查。

密钥登录用下面这条验证过，之后 `ssh xin-server` 才能当作完成：

```bash
ssh -i ~/.ssh/id_ed25519_xinserver dev@<SERVER_TAILSCALE_IP>
```

密码登录到此还没有关闭。先确认钥匙，再考虑拆掉密码。

## 长期开着

合盖配置是 logind 的 drop-in。发送 SIGHUP 并且看到服务仍 active，只说明配置被重新读取的这一步做了。外接电源下的合盖加 SSH 测试，才说明那种用法当时是通的。电池和扩展坞没有单独测试。通风和固件策略也不能靠这三行代表。

定时器 active，加上日志 `Internet OK; no login required.`，说明“网络正常时不登录”已经发生。认证自然过期后的自动恢复还没有实测。这两句必须同时成立，否则以后会高估这台机器的自愈能力。

`ssh.service` inactive 时先看 `ssh.socket`。升级后的 Ubuntu 用 socket activation 监听 22 端口。升级前 service 本身 active 的记录也是真的，两次不要写成一次。

欢迎信息里的更新数量可能是缓存。`apt update` 当时看到大约 152 个可升级包。升级在 tmux 里做。重启后的内核是 `7.0.0-38-generic`，`ssh xin-server` 再次成功。

重启后的 Tailscale 连通，不能用来证明定时器在那一次做过登录。

## 还没做的事不要提前打勾

写这一篇时，Docker Engine、Compose、数据库、API、监控、备份、告警都还没装。朋友 Mac 的 Tailscale 共享和单独 Linux 用户，只讨论过。防火墙把 SSH 收到 Tailscale 接口、关闭密码登录，也还没做。

这些放在 [Roadmap](../ROADMAP.md)。Phase 1 的完成线是：一台合得上盖子的 Ubuntu Server，可以从 Mac 用 `ssh xin-server` 管起来。Docker 及其后的第一张网页从 [Docker 安装](10-docker-installation.md) 另起，不改写上面的判断。
