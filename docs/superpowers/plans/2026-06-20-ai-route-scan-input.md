# AI Route and Scan Input Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the YDP02X 2.1.2 home AI icon open a working AI page and submit fresh pen scans as AI messages.

**Architecture:** Register a dedicated Mod page enum and use it consistently in the title bar, main router, and AI page. The AI page owns message submission while the global scan loader only suppresses its normal dictionary transition when that page is active.

**Tech Stack:** Qt 5.15 QML/C++, Python unittest, xmake, Zig AArch64, ADB, Git/GitHub.

---

### Task 1: Repair the AI page route

**Files:**
- Modify: `scripts/test_build_ydp212_resource_tree.py`
- Modify: `src/mod/Mod.h`
- Modify: `resource/models/YDP02X/qml/components/YMainTitleBar.qml`
- Modify: `resource/models/YDP02X/main.qml`
- Modify: `resource/models/YDP02X/qml/AIChatPage.qml`

- [ ] Add a failing static test requiring `PageIndex.AIAssistant` in the C++ enum and all three QML route sites, and forbidding `MEnum.PG_NewBing` in active files.
- [ ] Run `python -m unittest scripts.test_build_ydp212_resource_tree.PortedResourceTests.test_ai_route_uses_registered_mod_page -v` and verify it fails on the missing enum.
- [ ] Add `AIAssistant` after `VideoPlayer` in `PageIndex::Enum`; replace the title bar request, main switch case, and AI page current-page assignment with `PageIndex.AIAssistant`.
- [ ] Re-run the route test and verify it passes.

### Task 2: Send fresh scan text from the AI page

**Files:**
- Modify: `scripts/test_build_ydp212_resource_tree.py`
- Modify: `resource/models/YDP02X/qml/AIChatPage.qml`
- Modify: `resource/models/YDP02X/qml/components/YScanWordsResultLoader.qml`

- [ ] Add failing assertions requiring a single `submitMessage(content)` function, `onOcrStop`, `systemBase.ocrCompletedResult`, and an early AI-page return in the global scan loader.
- [ ] Run the targeted scan test and verify it fails because scan handling is absent.
- [ ] Move keyboard submission through `submitMessage`; reject empty or in-flight submissions; append user and assistant rows; send through `aiAssistant.send`.
- [ ] Add an AI-page `Connections` handler for `systemBase.onOcrStop` that submits only the newly completed non-empty scan.
- [ ] Add an early branch to the global scan loader's `onOcrStop` that hides its loader and returns when `qmlGlobal.currentPageIndex === PageIndex.AIAssistant`.
- [ ] Run all resource tests and `qmllint` on the changed QML files.

### Task 3: Document upstream authorship and this port

**Files:**
- Modify: `README.md`
- Modify: `scripts/test_build_ydp212_resource_tree.py`

- [ ] Add a failing README test requiring links to `PenUniverse/PenMods`, the GPL license, and a section named `YDP02X 2.1.2 适配修改`.
- [ ] Add an attribution section that credits PenUniverse and original contributors, preserves the license statement, and lists this branch's resource, AI, scan, settings, file-manager, and build changes without claiming upstream work.
- [ ] Run the README test and the complete Python suite.

### Task 4: Build and deploy the verified artifact

**Files:**
- Generate: `resource/models/YDP02X/resource.qrc`
- Generate: `resource/models/YDP02X/qrc_qml.h`
- Build: `build/linux/arm64-v8a/release/libPenMods.so`

- [ ] Sync the worktree to `/home/zengh/penmods_port_212`, regenerate 2.1.2 resources, and build with `xmake -j4`.
- [ ] Verify AArch64 ELF, no `libcrypt`, maximum GLIBC no newer than 2.27, and matching local/device SHA-256.
- [ ] Preserve the existing device library, deploy atomically, restart the dictionary process once, and monitor PID/crash count for 30 seconds.
- [ ] Verify logs contain `AIAssistant ready` and `Resource files have been replaced!` with no QML route/type errors.

### Task 5: Commit and push the feature branch

**Files:**
- Commit all files above on branch `codex/ydp212-port`.

- [ ] Run the full Python suite, QML lint, incremental AArch64 build, `git diff --check`, and device health checks.
- [ ] Commit with a message describing the AI route, scan input, and attribution.
- [ ] Push `codex/ydp212-port` to the configured GitHub remote without force and report the resulting remote branch URL.
