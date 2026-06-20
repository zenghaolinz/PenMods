# Keyboard Scan Input Design

## Cause

The native `KeyBoard` hook intercepts `YSystemBase::onScanFinish` while
`qmlGlobal.inputPageShowing` is true and emits `keyBoard.scanFinished(content)`.
The YDP02X 2.1.2 `YInputPage.qml` has no connection to that signal, so the
recognized text is discarded at the QML boundary.

## Design

Connect the shared `YInputPage` to `keyBoard.scanFinished`. While the input
page is visible, insert each non-empty scan result through
`YInputTextTitleArea.enterChar()`, which already inserts at the current cursor
position and restores focus. Because every keyboard consumer creates
`YInputPage`, one connection restores AI questions, settings, file rename, and
other keyboard pages.

The existing native hooks continue suppressing normal OCR start/stop handling
while a keyboard is visible. Therefore scanning in the AI keyboard inserts text
for review and does not trigger `AIChatPage`'s direct scan-submit path.

## Verification

Regression tests require the shared connection, visibility guard, non-empty
guard, and cursor-aware `enterChar(result)` call. The full tests, `qmllint`,
resource regeneration, native build, deployment hash, process stability, and
device QML logs must pass.
