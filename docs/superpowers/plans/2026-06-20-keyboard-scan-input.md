# Keyboard Scan Input Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore scan-to-cursor text insertion on every shared keyboard page.

**Architecture:** Keep the existing native OCR interception and consume its `keyBoard.scanFinished` signal in the common `YInputPage`. Insert text with the existing cursor-aware title-area API so all keyboard callers gain the behavior without page-specific code.

**Tech Stack:** Qt Quick 2.12 QML, C++ hooks, Python `unittest`, xmake, ADB

---

### Task 1: Add the keyboard scan regression test

**Files:**
- Modify: `scripts/test_build_ydp212_resource_tree.py`

- [ ] Read `qml/YInputPage.qml` in a new focused test.
- [ ] Require `target: keyBoard`, `function onScanFinished(result)`, a visible/non-empty guard, and `id_input_text_title_area.enterChar(result)`.
- [ ] Run the focused test and confirm it fails because the signal connection is absent.

### Task 2: Restore the shared QML connection

**Files:**
- Modify: `resource/models/YDP02X/qml/YInputPage.qml`

- [ ] Add a `Connections` object targeting `keyBoard` with unknown-signal tolerance.
- [ ] Enable it only while `id_input_page.visible`.
- [ ] Insert non-empty `result` with `id_input_text_title_area.enterChar(result)`.
- [ ] Run the focused and complete test suites and confirm they pass.

### Task 3: Build, deploy, and publish

**Files:**
- Regenerate: `resource/models/YDP02X/qrc_qml.h`

- [ ] Regenerate the QML resource header and run `qmllint`.
- [ ] Build the AArch64 library using xmake.
- [ ] Deploy atomically, restart the dictionary application, and compare hashes.
- [ ] Verify process stability and zero QML errors.
- [ ] Commit and push `codex/ydp212-port`.
