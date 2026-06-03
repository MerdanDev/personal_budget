# Home-screen widget setup

The widget shows balance / income / expense on top and two deep-link buttons on
the bottom (large **Add expense**, small **+ income**). Tapping a button opens
the app on the matching add dialog.

## How it works

```
Bloc persists entry  ─►  CounterRepository.setIncomeExpenseList
                         └► WidgetService.sync()  (lib/core/widget_service.dart)
                              • computes balance/income/expense
                              • HomeWidget.saveWidgetData(...)   → shared storage
                              • HomeWidget.updateWidget(...)     → refresh native widget

Native widget reads shared storage and renders.
Button tap → wallet://add?type=expense|income
           → HomeWidget delivers the URI to WidgetService._handleUri
           → navigatorKey pushes IncomeExpenseDialog(isMinus: …)
```

Shared keys: `balance`, `income`, `expense` (pre-formatted strings) and
`balance_negative` (bool, for red tint).

The Dart and Android sides are fully wired and need no further setup. iOS needs
a one-time target added in Xcode (below).

---

## Android — done

- Provider: `android/app/src/main/kotlin/dev/merdan/WalletWidgetProvider.kt`
- Layout: `android/app/src/main/res/layout/wallet_widget.xml`
- Config: `android/app/src/main/res/xml/wallet_widget_info.xml`
- Drawables/strings under `res/drawable` and `res/values/strings.xml`
- Registered in `AndroidManifest.xml`

To test: build & install, long-press the home screen → **Widgets** → *[DEV]
Gapjyk* → drag the "Balance with quick add buttons" widget.

---

## iOS — done

The `WalletWidgetExtension` target exists and builds (verified for the
`production` flavor on the simulator). Configuration applied:

- `ios/WalletWidget/WalletWidget.swift` + `WalletWidgetBundle.swift` — the
  balance widget (medium family). Xcode's emoji template and the unused
  Control / Live Activity / AppIntent files were removed.
- App Group `group.dev.merdan.wallet` is on **both** the Runner and the widget
  (`Runner/Runner.entitlements`, `WalletWidget/WalletWidget.entitlements`); the
  widget's `CODE_SIGN_ENTITLEMENTS` is wired in all 9 build configs.
- `wallet://` URL scheme registered in `Runner/Info.plist`.
- Widget deployment target lowered to iOS 16.0.

Two project-file fixes were needed and are already applied (note them if you
ever recreate the target):
- The `WalletWidget` folder is an Xcode 16 *synchronized group*, so `Info.plist`
  was auto-swept into Copy Bundle Resources and collided with the processed
  plist ("Multiple commands produce Info.plist"). Fixed with a
  `membershipExceptions` entry excluding `Info.plist`.
- The Runner's *Embed Foundation Extensions* phase was reordered to run **before**
  *Thin Binary* to break a build dependency cycle.

To test: run the Runner scheme on a device/simulator, long-press the home
screen ▸ **+** ▸ search "Balance" ▸ add the medium widget.

### If you ever need to recreate the target from scratch

All source files exist in `ios/WalletWidget/`. Create the extension target and
attach those files.

1. Open `ios/Runner.xcworkspace` in Xcode.
2. **File ▸ New ▸ Target… ▸ Widget Extension.**
   - Product Name: **WalletWidget**
   - Uncheck *Include Configuration App Intent* and *Include Live Activity*.
   - Team: your signing team. Click **Finish**, then **Activate** the scheme.
3. Xcode generated a `WalletWidget` group with its own `WalletWidget.swift`,
   `Info.plist`, and `Assets.xcassets`. **Delete the generated
   `WalletWidget.swift` and `Info.plist`** (move to trash).
4. Add the pre-written files to the **WalletWidget** target:
   - Right-click the WalletWidget group ▸ **Add Files to "Runner"…**
   - Select `ios/WalletWidget/WalletWidget.swift`,
     `ios/WalletWidget/Info.plist`, and
     `ios/WalletWidget/WalletWidget.entitlements`.
   - Ensure **Target membership = WalletWidget** for each.
5. Point the target at the right Info.plist / entitlements:
   - Select the **WalletWidget** target ▸ **Build Settings**.
   - `INFOPLIST_FILE` → `WalletWidget/Info.plist`
   - `CODE_SIGN_ENTITLEMENTS` → `WalletWidget/WalletWidget.entitlements`
   - Set `IPHONEOS_DEPLOYMENT_TARGET` to 14.0+ (the widget uses `Link`).
6. **App Groups** (both targets must share the group):
   - Select **Runner** target ▸ **Signing & Capabilities** — `App Groups`
     capability with `group.dev.merdan.wallet` is already in
     `Runner/Runner.entitlements`; just confirm it shows and is checked.
   - Select **WalletWidget** target ▸ **Signing & Capabilities** ▸ **+
     Capability ▸ App Groups**, then check `group.dev.merdan.wallet`.
   - If the group doesn't exist yet on your Apple Developer account, click the
     **+** under App Groups and create `group.dev.merdan.wallet`.
7. Build & run the **Runner** scheme on a device/simulator. Long-press the home
   screen ▸ **+** ▸ search "Balance" ▸ add the medium widget.

### Notes
- The widget kind string `WalletWidget` and app group `group.dev.merdan.wallet`
  must stay in sync across `WidgetService` (Dart), `WalletWidget.swift`, and the
  entitlements. If you rename the app group, change all three.
- Flavors: the dev/staging flavors use suffixed bundle IDs
  (`dev.merdan.wallet.dev`, `.stg`). A single App Group works for all of them
  because the group ID is independent of the bundle ID. The widget will read
  whichever flavor last wrote to the group.
`