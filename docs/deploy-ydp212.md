# 使用 ADB 部署 PenMods

在词典笔上确认型号为 **YDP02X**，固件为 **2.1.2**，并且已安装 PenMods Loader。脚本更新 `/userdisk/Loader/` 下的 PenMods 主库和视频解码组件。

## 准备

1. 在电脑安装 Python 3.8 或以上版本，以及 [Android SDK Platform-Tools](https://developer.android.com/tools/releases/platform-tools)。将包含 `adb` 的 `platform-tools` 目录加入 `PATH`，也可以运行脚本时用 `--adb` 指定可执行文件。
2. 从 [v2.0.0-ydp212.3 Release](https://github.com/zenghaolinz/PenMods/releases/tag/v2.0.0-ydp212.3) 下载 `deploy_ydp212.py`，在下载目录打开 PowerShell。通过 Git 获取项目时，脚本在 `scripts` 目录中。

## 一键部署

**Wi-Fi ADB**。让电脑和词典笔连接同一局域网，在笔上开启 Wi-Fi ADB。把下面的 IP 替换成词典笔显示的地址。默认使用 `5555` 端口，也可以写成 `IP:端口`。

```powershell
py -3 .\deploy_ydp212.py --connect 192.168.1.50
```

**USB ADB**。用支持数据传输的 USB 线连接词典笔，在笔上开启 USB ADB，然后运行：

```powershell
py -3 .\deploy_ydp212.py
```

在 macOS 或 Linux 上，将示例中的 `py -3 .\deploy_ydp212.py` 换成 `python3 ./deploy_ydp212.py`。

脚本显示设备序列号后，确认型号和固件，输入 `y`。脚本会下载并校验发布包、上传文件、保存旧版并验证笔上的新文件。看到 `Files verified on device.` 后，脚本会请求重启。若提示手动重启，直接在词典笔上重启即可。

如果自动下载失败，可以在同一 Release 手动下载 ZIP，再在原命令末尾加上 `--package .\PenMods-YDP02X-2.1.2-r3.zip`。

| 参数 | 用途 |
| --- | --- |
| `--serial SERIAL` | 通过 `adb devices` 查看序列号并指定目标设备。适合同时连接多台设备时使用。 |
| `--adb "C:\platform-tools\adb.exe"` | 指定 ADB 路径。 |
| `--package .\PenMods-YDP02X-2.1.2-r3.zip` | 使用已下载的 Release ZIP，部署时无需访问 GitHub。 |
| `--yes` | 已确认型号、固件和 Loader 时，跳过交互确认。 |
| `--no-reboot` | 写入后暂缓重启。 |

## 恢复上一版

记下部署输出中的 `Backup ID`。旧文件保存在笔上的 `/userdisk/Loader/.penmods-backup-<ID>/`。如果需要恢复，重新连接 ADB，把示例中的 ID 换成自己的备份 ID，再运行：

```powershell
py -3 .\deploy_ydp212.py --connect 192.168.1.50 --restore 012345abcdef
```

通过 USB 恢复时去掉 `--connect` 和 IP。恢复也会备份当前文件，因此会输出一个新的备份 ID。
