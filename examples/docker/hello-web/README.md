# hello-web

`xin-server` 上第一个一直运行的网页。镜像从 scratch 和静态 BusyBox 在服务器本地构建。主机端口只绑定 `127.0.0.1:8080`。

## 准备二进制

仓库不包含 BusyBox。在 Ubuntu 上：

```bash
sudo apt install busybox-static
./prepare-context.sh
```

脚本确认 `/usr/bin/busybox` 是静态可执行文件，再复制到本目录。它不会执行 `apt`，也不会改 Docker 守护进程、数据目录或用户组。

`index.html` 收录了页面上的四句文案，以及当时的视觉要素：深色背景、白色大标题、绿色状态。它是按这个记录整理的示例页面。

## 在服务器上启动

在本目录：

```bash
sudo docker compose config
sudo docker compose up -d --build
curl -fsS http://127.0.0.1:8080
```

## 从 Mac 看

另开一个终端，让这条命令保持运行：

```bash
ssh -N -L 18080:127.0.0.1:8080 xin-server
```

浏览器打开 `http://localhost:18080`。关掉 SSH 进程后，这个本地端口不再转发。服务器上的容器继续按 `unless-stopped` 运行。

不要把 `8080` 改成 `0.0.0.0:8080` 再放到校园网上。完整记录在 [第一个网页](../../../docs/15-first-web-service.md)。
