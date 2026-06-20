# Database and Developer Pages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the column database, ADB, and SSH settings pages open and perform their advertised actions.

**Architecture:** Repair the two page-creation contracts: expose the database slider property from C++, and supply valid image components to the service pages. Keep existing routes and service commands intact.

**Tech Stack:** Qt Quick 2.12 QML, Qt/C++, Python `unittest`, xmake, ADB

---

### Task 1: Add failing page-contract tests

**Files:**
- Modify: `scripts/test_build_ydp212_resource_tree.py`

- [ ] Require `Q_PROPERTY(int limit ...)`, `setLimit(int)`, configuration persistence, and hooks using `getLimit()`.
- [ ] Reject `iconComponent.source` and require inline `iconComponent: YImage` bindings in both service pages.
- [ ] Confirm developer routes still open `ADBManagePage` and `SSHManagePage`.
- [ ] Run the focused tests and confirm both fail on the missing contracts.

### Task 2: Implement the database limit property

**Files:**
- Modify: `src/tweaker/ColumnDBLimiter.h`
- Modify: `src/tweaker/ColumnDBLimiter.cpp`

- [ ] Add a persisted integer limit with a 10–100 clamp and `limitChanged` signal.
- [ ] Map legacy `patch` false/true to limits 10/80.
- [ ] Replace every hard-coded hook limit with `ColumnDBLimiter::getInstance().getLimit()`.
- [ ] Run the focused database test.

### Task 3: Repair ADB and SSH page components

**Files:**
- Modify: `resource/models/YDP02X/qml/settingpages/ADBManagePage.qml`
- Modify: `resource/models/YDP02X/qml/settingpages/SSHManagePage.qml`

- [ ] Replace invalid attached `source` assignments with inline `YImage` components.
- [ ] Bind each image source to the matching live service status.
- [ ] Run the focused service-page test and `qmllint`.

### Task 4: Build, deploy, and publish

**Files:**
- Regenerate: `resource/models/YDP02X/qrc_qml.h`

- [ ] Run all tests and regenerate the QML resource header.
- [ ] Build the AArch64 library and deploy it atomically.
- [ ] Restart the application and verify hash, process stability, and clean QML logs.
- [ ] Commit and push `codex/ydp212-port`.
