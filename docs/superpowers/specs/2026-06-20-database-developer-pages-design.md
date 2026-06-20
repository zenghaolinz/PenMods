# Database and Developer Pages Design

## Causes

`ColumnDbPage.qml` reads and writes `columnDb.limit`, but
`ColumnDBLimiter` exposes only the Boolean `patch` property. The page therefore
cannot bind its slider to the backend. In addition, `ADBManagePage.qml` and
`SSHManagePage.qml` assign `iconComponent.source`; `iconComponent` is a
`Component`, not an image object, so both subpages fail during creation.

## Design

Expose an integer `limit` property from `ColumnDBLimiter`, clamped to 10–100,
persist it in the existing `column_db` configuration section, and retain the
legacy `patch` property as a 10/80 compatibility switch. Every database hook
uses the configured limit instead of the compile-time constant.

Replace each invalid developer-service icon assignment with an inline `YImage`
component whose `source` binding reflects `serviceManager.adbStatus` or
`serviceManager.sshStatus`. Existing service actions and auto-run settings stay
unchanged. The device provides both `adb_onoff` and `/usr/bin/sshd_sevice`.

## Verification

Tests require the Q_PROPERTY, setter, persistence, configured hook usage, valid
inline status icons, and correct developer routes. Run all tests, `qmllint`,
resource generation, native build, deployment, hash comparison, and device log
checks before publishing.
