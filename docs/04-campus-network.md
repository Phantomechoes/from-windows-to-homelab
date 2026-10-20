# 校园网：Netplan、Wi-Fi 与 Captive Portal

> 记录日期：2026-10-20。阶段：Phase 1，Docker 安装之前。
> 无线网卡 MediaTek MT7921。公开文本里的 SSID 使用 `<CAMPUS_WIFI_SSID>`。

返回 [项目首页](../README.md)。上一篇：[坏屏幕与启动菜单](03-headless-display-troubleshooting.md)。

这一章有两个先后发生、又很容易被说成同一件事的问题。第一个是 Netplan 写不对，接口起不来。第二个是接口起来了，互联网仍然不通。

## 名字：安装器里的 wlan0，系统里的 wlo1

安装阶段，无线接口曾显示为 `wlan0`。安装完成、进入系统之后，实际名字是 `wlo1`。

这是可预测网络接口名。内核和 udev 按固件信息给接口起名，安装器早期看到的名字可以和装完之后不一致。配置文件要跟当前系统走。判断方法是在已经装好的系统里看接口，而不是回忆安装器屏幕。

```bash
ip -br addr
```

当时的结果里，`wlo1` 处于 `DOWN`。没有地址，因为还没有一份能用的 Wi-Fi 配置。

## 安装器留下的配置，networkd 不接受

安装器生成的文件是：

```text
/etc/netplan/00-installer-config.yaml
```

里面带有 `match` 和 `set-name`。这种写法先按硬件特征找到网卡，再把它改名。有线网卡上很常见。这份文件被直接应用时，networkd 拒绝了无线部分：

```text
networkd backend does not support wifi with match
```

报错指向后端，不指向 SSID。`renderer: networkd` 时，Wi-Fi 配置不能再套一层 `match`。这次没有改去用 NetworkManager，而是删掉不兼容的匹配和改名，直接把配置写在接口名 `wlo1` 上。

下面这段只说明当时要删掉的结构。MAC 用占位符，不是从机器上抄出来的原文件。

```yaml
# 示意：这种写法触发了上面的报错，不要再使用。
wifis:
  wlan0:
    match:
      macaddress: "<WIFI_MAC_ADDRESS>"
    set-name: "wlo1"
```

## 中间还绊在 YAML 和编辑器上

替换配置的过程中，netplan 报过 YAML 错误。具体踩到的是：

- 缩进不一致。YAML 用空格表达层级，同一层必须对齐。
- 冒号后面少了空格。`dhcp4: true` 成立，`dhcp4:true` 这种挤在一起的写法会让解析失败。

编辑器是 nano。保存时 Ctrl+O 会先询问文件名，那一行看起来像“另存为”。当时在这里犹豫过，需要看清提示的路径是 `/etc/netplan/00-installer-config.yaml`，再按 Enter。写错文件名会得到一份新文件，而 netplan 仍然在读原来的那份。

改完之后执行：

```bash
sudo netplan generate
```

成功时通常什么都不输出。没有消息，表示生成通过，不是命令没运行。生成是把 YAML 渲染成后端配置。让它生效再执行：

```bash
sudo netplan apply
```

这两条都成功之后，`wlo1` 才真正按新配置工作。

## 最终的 Wi-Fi 配置

校园 SSID 是开放网络：关联无线时不需要 WPA 密码。开放，只说明无线层没有密码。校园网随后还有网页认证。

公开示例放在 [`examples/netplan/campus-open-wifi.yaml`](../examples/netplan/campus-open-wifi.yaml)，结构如下。

```yaml
network:
  version: 2
  renderer: networkd
  wifis:
    wlo1:
      dhcp4: true
      optional: true
      access-points:
        "<CAMPUS_WIFI_SSID>": {}
```

每个字段对应这次的一个决定：

- `renderer: networkd`：继续用报错里的那个后端，不中途换渲染器。
- `wlo1`：键名就是 `ip -br addr` 看到的接口。
- `dhcp4: true`：向校园网要 IPv4 地址。
- `optional: true`：这块网卡不在时，启动不必一直等它。第一次开机的 `network wait-online` 就是在等一个还没配好的网络。这个字段是配网时加上的，避免以后开机再被缺席的 Wi-Fi 拖住。
- `"<CAMPUS_WIFI_SSID>": {}`：空映射表示开放网络。SSID 在服务器上换成真实名字。真实名字不进这个仓库。

没有 `match`，没有 `set-name`，也没有把校园网账号写进 Netplan。账号不属于无线密码。

## 拿到地址之后，互联网还是不通

Netplan 生效后，`wlo1` 通过 DHCP 拿到了地址。用 curl 去看一个普通的 HTTP 网站，返回的不是那个网站，而是校园网认证入口的 HTML，里面是一段 JavaScript 跳转。

这就是 Captive Portal。网络已经完成了两层：

1. 无线关联成功。开放 SSID 接受了这块网卡。
2. DHCP 成功。接口上有了校园网地址。

第三层还没过：门户还没有放行这台设备的互联网访问。没认证的 HTTP 请求会被拦到登录页。

所以，Wi-Fi 已连接、`ip -br addr` 里有地址、浏览器打不开网页，这三件事可以同时为真。把第三件理解成“Linux 不会连 Wi-Fi”，排查会回到已经完成的那一层，越查越偏。

## 为什么 Windows 和 Mac 会弹窗，而这里不会

桌面系统有自己的门户检测。它们访问一个探测地址，发现响应不像预期，就打开认证窗口。人在窗口里登录。

Ubuntu Server 没有图形浏览器，也没有这套弹窗。检测不会替你出现。终端里能看到的，是 curl 拿回来的原始 HTML。

curl 不执行 JavaScript。页面想跳去哪里，curl 不会跟过去，它把跳转脚本原文交给终端。因此看到认证页的 HTML，恰恰说明请求碰到了门户，也说明不能靠“再 curl 一次同一个地址”来完成登录。登录要向认证接口提交凭据，而不是把 JavaScript 读给人看。

## 终端里完成的那次认证

后来直接测试了学校的认证服务：用终端发出 HTTPS 请求，把凭据提交给认证接口。接口返回了类似这样的结果：

```text
{"result":1,"msg":"Portal..."}
```

这次把 `result` 为 1 当作认证接口接受了这次登录。失败时长什么样，没有记下来，文档不补一个假的失败 JSON。

接着再用 HTTPS 网站做探测，得到正常页面，状态是 HTTP 200。互联网从这里算通。

HTTP 200 要和正文一起看。门户页面本身也可能以成功状态码返回一段跳转 HTML。判断互联网可用，看的是探测目标的正常内容，而不只是状态码。

这次的认证接口是这所学校当时的门户，不是一份稳定公开、可以换到任何高校的 API。别的学校的页面、字段和结果码都可能不同。照着这个 JSON 去猜另一所学校的接口，不会得到同样的行为。

## 这条登录路径的安全局限

现有认证使用 GET 把登录参数放进请求。即使外层是 HTTPS，服务端仍可能把完整 URL 写进访问日志。日志里就会留下本不该长期保存的凭据。

TLS 阻止的是路径上的窃听。它不阻止接收方记日志，也不阻止本机 shell history 记住那条命令。

因此这个仓库不记录：

- 校园网账号和密码
- 带参数的认证 URL
- 认证令牌或登录会话
- 当时分到的内网 IP 和网卡 MAC

自动重试如果要做，必须避免把 URL 打进日志。设计见 [自动检测与认证](07-auto-network-auth.md)。在那之前，Tailscale 和 SSH 还得先走通，因为 Mac 和这台机器虽然都在校园网里，直连 SSH 却失败了：[远程访问](05-remote-access.md)。
