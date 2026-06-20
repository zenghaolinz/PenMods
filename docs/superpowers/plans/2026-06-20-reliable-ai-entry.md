# Reliable AI Entry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the AI assistant reliably accessible from both the title bar and a full-size home card.

**Architecture:** Route both controls through a local `YIndexPage` signal and let `main.qml` load `AIChatPage` directly. Do not gate page navigation on network state or send a custom enum through the firmware signal.

**Tech Stack:** Qt Quick 2.12 QML, Python `unittest`, xmake, ADB

---

### Task 1: Add failing navigation regression tests

**Files:**
- Modify: `scripts/test_build_ydp212_resource_tree.py`

- [ ] Assert the title icon calls `id_container_index.openAIAssistant()`.
- [ ] Assert `YIndexPage` exposes `showAIAssistant`, adds an AI card, and handles its click locally.
- [ ] Assert `main.qml` handles `onShowAIAssistant` by loading `AIChatPage`.
- [ ] Assert the title icon no longer checks `wifiManager.internetConnect`.
- [ ] Run the focused test and confirm it fails for the missing local route.

### Task 2: Implement the local route and second entry

**Files:**
- Modify: `resource/models/YDP02X/qml/components/YMainTitleBar.qml`
- Modify: `resource/models/YDP02X/qml/YIndexPage.qml`
- Modify: `resource/models/YDP02X/main.qml`

- [ ] Add `showAIAssistant` and `openAIAssistant()` to `YIndexPage`.
- [ ] Route the title icon directly to `openAIAssistant()` without a network guard.
- [ ] Add an `AI 助手` home card using the existing Bing asset.
- [ ] Handle `onShowAIAssistant` in `main.qml` with `showPage("AIChatPage")`.
- [ ] Run the focused and full regression tests and confirm they pass.

### Task 3: Build and verify on device

**Files:**
- Regenerate: `resource/models/YDP02X/qrc_qml.h`

- [ ] Regenerate the embedded QML resource header.
- [ ] Build the AArch64 library with xmake under WSL.
- [ ] Deploy atomically to `/userdisk/Loader/libPenMods.so`.
- [ ] Restart the application and verify process stability and clean QML logs.
- [ ] Trigger both navigation paths with device input where possible and inspect logs.
- [ ] Commit and push the verified change to `codex/ydp212-port`.
