# Restore Home Menu Design

## Cause

`YIndexPage.mainMenuModel` infers the `pageIndex` role from the firmware
`YEnum.PageIndex` value appended for the dictionary card. Appending
`PageIndex.AIAssistant`, which is a different registered enum type, interrupts
the model's `Component.onCompleted` construction. Every firmware card appended
after that statement is therefore missing.

## Design

Keep the confirmed working title-bar Bing entry and remove the AI assistant
from the firmware `ListModel`. Restore the menu delegate and label switch to
firmware page types only. This preserves dictionary, speech, textbook,
favorites, audio, history, and settings behavior without enum coercion.

## Verification

A regression test must reject `PageIndex.AIAssistant` inside the home menu
model while confirming all unconditional firmware cards remain appended. Then
regenerate QML resources, run all tests and `qmllint`, rebuild, deploy, and
verify a stable device process with no QML errors.
