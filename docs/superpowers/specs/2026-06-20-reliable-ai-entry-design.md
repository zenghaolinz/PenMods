# Reliable AI Entry Design

## Problem

The visible Bing icon can appear inert because it blocks navigation when
`wifiManager.internetConnect` is false and forwards a custom page enum through
the firmware-owned `qmlGlobal.requestShowPage` signal.

## Design

Keep the title-bar Bing icon and add an `AI 助手` card to the normal home menu.
Both entry points call `YIndexPage.openAIAssistant()`. That function emits a
local `showAIAssistant` signal, handled by `main.qml` with
`showPage("AIChatPage")`. This keeps custom navigation inside the injected QML
and avoids the firmware enum boundary.

Entering the page never depends on network state. Network and provider errors
remain the responsibility of the AI request layer when a message is sent.

## Verification

Regression tests assert that both entry points use the local route, that the
title bar has no network navigation guard, and that `main.qml` directly loads
`AIChatPage`. The full resource test suite, QML resource generation, native
build, deployment, process health, and device logs must pass before delivery.
