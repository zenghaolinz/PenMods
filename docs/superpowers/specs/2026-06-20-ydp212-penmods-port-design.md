# PenMods 2.1.2 UI Port Design

## Goal

在 YDP021 固件 2.1.2 上保留全部官方主页与设置功能，同时恢复 PenMods 设置、文件管理等扩展，并将旧 New Bing 页面替换为使用 `AIAssistant` 的 OpenAI 兼容 AI 页面。

## Baseline

- `D:\penmod\device_qrc` 是设备当前 2.1.2 的 664 个官方资源，是所有公共 QML 的唯一基线。
- `D:\penmod\penmods_qrc_1.2` 是从旧版 `libPenMods.so` 恢复出的 523 个资源，只作为 PenMods 增量的参考。
- 禁止再次用旧版同名公共 QML 整包覆盖 2.1.2 文件。

## Resource Architecture

最终资源树从官方资源复制生成。旧版中官方资源不存在的 Mod 页面、图标和文件管理组件可以直接追加；同名公共页面必须针对 2.1.2 逐点移植。

需要修改的公共入口只有：

- `qml/YSettingPage.qml`：保留官方设置模型，追加 PenMods 设置项及页面分发。
- `qml/components/YMainTitleBar.qml`：追加 AI 入口，不改变官方标题栏行为。
- `main.qml`：追加 Mod 页面路由，不替换官方路由。
- 当前固件的“我的导入”相关 QML：追加文件管理操作，不替换其官方数据模型。

## AI Page

旧 Bing 网络对象不再使用。新的 `qml/AIChatPage.qml` 直接绑定上下文对象 `aiAssistant`：

- 发送输入调用 `aiAssistant.send(text)`。
- 流式内容监听 `replyChunkChanged`。
- 停止请求调用 `aiAssistant.stop()`。
- 页面展示 `lastError`、`requesting` 和 `currentReply`。
- 设置页可以编辑启用状态、服务商、Base URL、API Key、模型、温度和系统提示词。
- API Key 仅写入设备本地 `/userdisk/Loader/config.json`，不写入仓库或日志。

## Configuration

配置从 v120 迁移到 v200 时保留 Bing 旧字段和其他用户设置，同时补齐 OpenAI 兼容字段。迁移必须落盘且可重复执行，不得因缺失旧字段抛异常。

## File Manager

以 2.1.2 当前“我的导入”页面为基础，移植旧版抽屉、文本查看器、视频播放器和文件操作入口。所有页面继续调用现有 C++ `fileManager`、`musicPlayer`、`videoPlayer` 与 `textReader` 上下文对象。

## Failure Handling

- QRC 生成前拒绝包含 `STUB for build verification only` 的头文件。
- 设备测试只允许一次受控应用重启。
- 若 PID 再次变化、资源替换日志缺失或崩溃计数增加，立即移除 `try_inject` 启动钩子。
- 保留上一版 `.so`，不覆盖用户配置备份。

## Acceptance Criteria

- 主页保留固件 2.1.2 的全部官方功能，而非只剩查词翻译和教材同步。
- 官方设置入口和全部原生设置项存在。
- PenMods 设置项可以打开对应页面。
- “我的导入”可以进入文件管理并打开受支持的文本、音频和视频文件。
- AI 页面可以调用 `AIAssistant`，并能显示流式回复或明确错误。
- 设备进程连续稳定至少 30 秒，`Resource files have been replaced!` 存在，崩溃计数为 0。
