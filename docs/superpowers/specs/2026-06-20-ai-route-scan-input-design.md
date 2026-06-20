# AI 助手路由与扫描输入设计

## 目标

修复 YDP02X 2.1.2 首页 AI 图标点击无反应的问题，使 AI 页面内完成的词典笔扫描文字直接成为一条用户消息并发送给已配置的 OpenAI 兼容服务；同时补充项目来源和本分支修改说明，并将成果推送到 GitHub。

## 根因

当前 QML 使用 `MEnum.PG_NewBing` 打开 AI 页面，但当前 C++ `PageIndex` 只注册了录音和视频页面，不存在 `PG_NewBing`。点击图标因此向 `qmlGlobal.requestShowPage` 传入无效编号，`main.qml` 无法匹配有效页面路由。

## 页面路由

- 在 `mod::PageIndex` 中新增稳定枚举 `AIAssistant`，沿用现有 Mod 页面编号空间。
- 首页图标、`main.qml` 路由和 AI 页面当前页状态统一使用 `PageIndex.AIAssistant`。
- 不再复用或依赖旧 Bing 枚举；旧 Bing QML 仅作为历史资源存在，不参与新 AI 数据流。

## 扫描数据流

1. 用户打开 AI 页面并进行扫描。
2. `systemBase.onOcrStop` 触发后，AI 页面读取 `systemBase.ocrCompletedResult`。
3. 非空内容通过 AI 页统一的 `submitMessage` 函数加入消息列表，并调用 `aiAssistant.send`。
4. 全局 `YScanWordsResultLoader` 检测当前页为 `PageIndex.AIAssistant` 时停止查词跳转，避免 AI 页面被词典结果页覆盖。
5. 空扫描结果显示原系统提示；请求进行中时不重复发送，并给出明确提示。

扫描只在 AI 页面处于活动状态时发送，不自动发送打开页面前遗留的旧扫描结果。

## 文档与署名

README 保留原项目信息，并明确区分：

- 原创项目、既有架构和历史功能：PenUniverse/PenMods 及原贡献者。
- 本分支修改：YDP02X 2.1.2 资源基线、设置页适配、OpenAI 兼容 AI、扫描输入、文件管理和构建兼容修复。

不冒充上游原创，不删除原许可证、版权头或原作者链接。

## 验证与发布

- 先用静态回归测试证明旧无效枚举仍存在，然后修复至通过。
- 用 `qmllint` 检查修改页面，运行全部 Python 测试并重新构建 AArch64 动态库。
- 部署到设备后验证点击路由、扫描发送、PID、崩溃计数和 QML 日志。
- 提交到 `codex/ydp212-port`，将该分支推送到配置的 GitHub 远端；不强推、不覆盖上游默认分支。
