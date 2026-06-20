# Restore Home Menu Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore all firmware home cards while retaining the working title-bar AI entry.

**Architecture:** Keep custom AI navigation outside the firmware `ListModel`. The menu model and delegate use only `YEnum.PageIndex`, preventing construction from stopping on a foreign enum role value.

**Tech Stack:** Qt Quick 2.12 QML, Python `unittest`, xmake, ADB

---

### Task 1: Lock the firmware menu boundary

**Files:**
- Modify: `scripts/test_build_ydp212_resource_tree.py`

- [ ] Add assertions that `mainMenuModel` contains no `PageIndex.AIAssistant` value.
- [ ] Assert dictionary, favorites, history, and settings append statements remain present and ordered.
- [ ] Run the focused test and confirm it fails on the AI model append.

### Task 2: Remove the foreign enum from the menu

**Files:**
- Modify: `resource/models/YDP02X/qml/YIndexPage.qml`
- Modify: `README.md`

- [ ] Remove the AI case, card label, conditional Bing card image, and AI append from the firmware list.
- [ ] Keep `openAIAssistant()` for the title-bar Bing entry.
- [ ] Update README to describe the title-bar entry without claiming an AI home card.
- [ ] Run the focused and complete test suites.

### Task 3: Build and deploy

**Files:**
- Regenerate: `resource/models/YDP02X/qrc_qml.h`

- [ ] Regenerate the embedded QML resource header.
- [ ] Run `qmllint` on the changed QML files.
- [ ] Build the AArch64 library with xmake.
- [ ] Deploy it atomically to `/userdisk/Loader/libPenMods.so` and restart the application.
- [ ] Verify hashes, process stability, and zero QML errors; commit and push the branch.
