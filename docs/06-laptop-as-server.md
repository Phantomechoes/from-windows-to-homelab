# 笔记本当服务器：合盖

> 记录日期：2026-10-20。阶段：Phase 1，Docker 安装之前。

返回 [项目首页](../README.md)。上一篇：[远程访问](05-remote-access.md)。

内屏已经不能用。这台机器长期当服务器时，盖子应该合上，而不是掀开靠一块外接显示器证明它还醒着。笔记本的默认策略往往相反：合盖等于用户离开，系统准备休眠。

## 改的是 logind，不是某一条电源脚本

合盖事件由 `systemd-logind` 处理。配置写成 drop-in，避免修改发行版自带的 `/etc/systemd/logind.conf`。以后系统更新不容易把这段意图合并丢。

路径：

```text
/etc/systemd/logind.conf.d/90-server-lid.conf
```

内容就是这几行，示例文件在 [`examples/systemd/90-server-lid.conf`](../examples/systemd/90-server-lid.conf)。

```ini
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```

三个指令对应三种合盖场景：使用电池、接着外部电源、以及停在扩展坞上。`ignore` 表示 logind 不因为合盖去休眠或关机。

## 让配置被读到，和合盖测试，是两步

写入文件不会自动变成 logind 的当前内存配置。这次向 `systemd-logind` 发送了 SIGHUP，让它重新读取配置。完成这件事的命令是：

```bash
sudo systemctl kill -s SIGHUP systemd-logind
systemctl is-active systemd-logind
```

信号发出之后，服务仍是 active。SIGHUP 在这里是重读配置。整台机器没有因此重启，logind 也没有停掉。

这一步只证明进程还在，并且有机会读到新文件。它不证明合盖之后 SSH 还在。

合盖测试是单独做的：

1. 联想笔记本保持外部供电。
2. 合上屏幕。
3. 从 Mac 经 Tailscale 继续 SSH。
4. 会话仍然可用。

验证通过的是这一组条件：外接电源、盖子合上、Tailscale 上的 SSH。`HandleLidSwitchExternalPower=ignore` 和这次测试直接对应。

`HandleLidSwitch=ignore` 和 `HandleLidSwitchDocked=ignore` 写进了同一个文件。电池供电下的合盖，以及扩展坞上的合盖，这次没有单独记录测试。文件里有这三行，不能说成三种供电方式都已验证。

## 这几行不能代表所有笔记本

logind 只处理它负责的合盖动作。固件里的盖子行为、其他休眠策略、过热降频，都不由这个 drop-in 担保。

不同笔记本的电源设计和散热也不一样。合盖之后，出风口可能被挡住，桌面和被子是两种完全不同的环境。这台小新在外接电源下通过了一次 SSH 测试。把它抄到别的机器上时，需要自己再做一次合盖测试，并给机器留出通风。不能凭这三行配置断言所有笔记本都不会休眠。

远程管理现在可以在盖子合上时进行。校园网认证仍可能过期。下一篇是检测定时器的设计，以及它已经证明了什么、还没有证明什么：[自动检测与认证](07-auto-network-auth.md)。
