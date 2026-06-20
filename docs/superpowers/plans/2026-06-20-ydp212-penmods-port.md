# PenMods 2.1.2 UI Port Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore every YDP021 2.1.2 official route while adding working PenMods settings, file management, and an OpenAI-compatible AI chat page.

**Architecture:** Rebuild the QRC from the device-exported 2.1.2 tree, then apply a small allowlisted overlay instead of copying old public QML wholesale. New AI QML talks only to the existing `aiAssistant` context object; legacy Bing transport is excluded.

**Tech Stack:** Qt 5.15 QML/C++, xmake, Zig aarch64 toolchain, Python resource validation, ADB/BusyBox.

---

### Task 1: Create a deterministic 2.1.2 resource baseline

**Files:**
- Create: `scripts/build_ydp212_resource_tree.py`
- Create: `scripts/test_build_ydp212_resource_tree.py`
- Generate: `resource/models/YDP02X/**`

- [ ] **Step 1: Write the failing resource-overlay test**

The test creates tiny `device` and `legacy` fixtures and asserts that official common files remain unchanged while legacy-only files are copied:

```python
def test_overlay_copies_only_legacy_only_files(tmp_path):
    device = tmp_path / "device"
    legacy = tmp_path / "legacy"
    output = tmp_path / "output"
    write(device / "qml/YIndexPage.qml", "device-index")
    write(legacy / "qml/YIndexPage.qml", "legacy-index")
    write(legacy / "qml/settingpages/AboutPenMods.qml", "penmods")
    build_tree(device, legacy, output)
    assert (output / "qml/YIndexPage.qml").read_text() == "device-index"
    assert (output / "qml/settingpages/AboutPenMods.qml").read_text() == "penmods"
```

- [ ] **Step 2: Run the test and verify RED**

Run: `python -m unittest scripts.test_build_ydp212_resource_tree -v`

Expected: FAIL because `build_ydp212_resource_tree` does not exist.

- [ ] **Step 3: Implement the allowlisted overlay builder**

`build_tree(device, legacy, output)` must copy the complete device tree first, then copy only legacy paths absent from the device tree. It must reject a source or generated header containing `STUB for build verification only`.

- [ ] **Step 4: Run the test and generate the baseline**

Run:

```powershell
python scripts/build_ydp212_resource_tree.py `
  --device D:\penmod\device_qrc `
  --legacy D:\penmod\penmods_qrc_1.2 `
  --output resource\models\YDP02X
python -m unittest scripts.test_build_ydp212_resource_tree -v
```

Expected: tests PASS; `qml/YIndexPage.qml`, `qml/YSettingPage.qml`, and `main.qml` match `device_qrc` byte-for-byte.

### Task 2: Port PenMods settings onto the current setting page

**Files:**
- Modify: `resource/models/YDP02X/qml/YSettingPage.qml`
- Copy: `resource/models/YDP02X/qml/settingpages/*.qml`
- Test: `scripts/test_build_ydp212_resource_tree.py`

- [ ] **Step 1: Add failing assertions for official and Mod setting entries**

```python
text = (output / "qml/YSettingPage.qml").read_text(encoding="utf-8")
assert "YEnum.SettingIndex.Network" in text
assert "settingpages/DeveloperSettingPage" in text
assert "settingpages/AISettingPage" in text
```

- [ ] **Step 2: Verify the assertions fail**

Run: `python -m unittest scripts.test_build_ydp212_resource_tree -v`

Expected: FAIL on the PenMods page routes while the official network assertion passes.

- [ ] **Step 3: Append Mod cases and model entries to the 2.1.2 file**

Use numeric indices `201..209` only for Mod entries. Keep the official `settingItemClicked` cases and `id_setting_model` initialization unchanged, then append routes for battery, database, logger, query, lock, torch, developer, AI, and About PenMods.

- [ ] **Step 4: Run static tests**

Expected: official and Mod assertions PASS; no legacy `settingIcon: res.getDisk(...)` replacements occur in official entries.

### Task 3: Replace legacy Bing UI with `AIAssistant`

**Files:**
- Create: `resource/models/YDP02X/qml/AIChatPage.qml`
- Create: `resource/models/YDP02X/qml/settingpages/AISettingPage.qml`
- Modify: `resource/models/YDP02X/qml/components/YMainTitleBar.qml`
- Modify: `resource/models/YDP02X/main.qml`

- [ ] **Step 1: Add failing AI binding checks**

```python
chat = read("qml/AIChatPage.qml")
assert "aiAssistant.send" in chat
assert "onReplyChunkChanged" in chat
assert "bing" not in chat.lower()
```

- [ ] **Step 2: Verify RED because the page is absent**

Run the resource unit suite and expect a missing-file failure.

- [ ] **Step 3: Implement the minimal chat and setting pages**

The chat page maintains a local message model, appends user text before calling `aiAssistant.send`, updates the assistant row from `currentReply`, displays `lastError`, and disables Send while `requesting`. The settings page edits the existing QObject properties and never prints the API key.

- [ ] **Step 4: Add only two route hooks**

Add an AI icon to the current `YMainTitleBar.qml`, and add one `MEnum.PG_NewBing` compatibility case in current `main.qml` that opens `AIChatPage`. Do not replace any official switch cases.

- [ ] **Step 5: Run resource tests**

Expected: AI binding checks PASS and every official main-menu model line still exists.

### Task 4: Port file management incrementally

**Files:**
- Modify: `resource/models/YDP02X/qml/audiopages/YMyImportPageComponent.qml`
- Modify: `resource/models/YDP02X/qml/audiopages/YMyImportPageComponentViewItem.qml`
- Copy: `resource/models/YDP02X/qml/audiopages/FileManagerDrawerLayer.qml`
- Copy: `resource/models/YDP02X/qml/audiopages/FileManagerTextViewer.qml`
- Copy: `resource/models/YDP02X/qml/audiopages/VideoPlayer.qml`

- [ ] **Step 1: Add failing checks for current page identity and file-manager bindings**

```python
page = read("qml/audiopages/YMyImportPageComponent.qml")
assert current_device_marker in page
assert "fileManager" in page
assert "FileManagerDrawerLayer" in page
```

- [ ] **Step 2: Verify RED on file-manager bindings**

- [ ] **Step 3: Port actions into the current firmware page**

Retain the 2.1.2 list model and navigation. Add long-press/more actions that call `fileManager`, and load the text/video components according to suffix. Do not copy the legacy page wholesale.

- [ ] **Step 4: Run static tests**

Expected: current marker and file-manager bindings both PASS.

### Task 5: Make configuration migration safe and persistent

**Files:**
- Modify: `src/mod/Config.cpp`
- Create: `scripts/test_config_migration.py`

- [ ] **Step 1: Write fixture tests for v120 and v200 JSON**

Assert that v120 preserves existing sections and gains all OpenAI fields at version 200, while v200 is unchanged on a second migration.

- [ ] **Step 2: Verify the migration fixture test fails against current logic**

- [ ] **Step 3: Correct migration guards and merge semantics**

Use `if (!data.contains("version")) return false;`, skip only when version equals `VERSION_CONFIG`, add missing keys without replacing the legacy `ai.bing` object, and save the updated document once.

- [ ] **Step 4: Run migration and resource tests**

Expected: all tests PASS and no fixture contains a real API key.

### Task 6: Generate, build, and validate the ARM64 artifact

**Files:**
- Generate: `resource/models/YDP02X/resource.qrc`
- Generate: `resource/models/YDP02X/qrc_qml.h`
- Generate: `build/linux/arm64-v8a/release/libPenMods.so`

- [ ] **Step 1: Generate QRC**

Run: `wsl -d Ubuntu -- bash /mnt/d/penmod/PenMods/scripts/gen_qt_res.sh YDP02X`

Expected: at least 889 resources; header has no stub marker.

- [ ] **Step 2: Configure and build**

Run:

```bash
xmake f -c -p linux -a arm64-v8a --toolchain=zigcc \
  --qt=/opt/qt-arm64 --build-platform=YDP02X --target-channel=dev -m release -y
xmake -j4
```

Expected: exit 0 and `libPenMods.so` is an AArch64 ELF.

- [ ] **Step 3: Inspect compatibility**

Run `readelf -d`, `readelf --version-info`, and `strings` checks. Expected: no `libcrypt` dependency, maximum GLIBC requirement not newer than device 2.27, and QML names include `AIChatPage.qml` and `AboutPenMods.qml`.

### Task 7: Controlled device deployment and acceptance test

**Files:**
- Deploy: `/userdisk/Loader/libPenMods.so`
- Preserve: `/userdisk/Loader/libPenMods.so.bak`

- [ ] **Step 1: Push with SHA-256 verification**

The local and device hashes must match before restart.

- [ ] **Step 2: Perform one controlled application restart**

Record the old PID, restart once, and monitor for 30 seconds. If PID changes again or crash count increases, remove the startup hook immediately.

- [ ] **Step 3: Verify runtime evidence**

Expected log lines:

```text
Resource files have been replaced!
AIAssistant ready.
```

Expected: no QML `ReferenceError`, `TypeError`, or missing-component errors.

- [ ] **Step 4: Verify user-visible flows**

Check the complete official home grid, official settings, PenMods settings, file manager, and AI request/error flow. Preserve the clean alternate A/B slot until these checks pass.
