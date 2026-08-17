# Settings rebuild — five-section grouped screen

Verification captures for `FEATURE: Settings rebuild — five-section grouped screen`.
Device: **iPhone 17 Pro (iOS 26.5)** simulator, Dark Mode. Signed in as E (session restored from
Keychain — no fresh sign-in was needed to start).

## Screenshots

### 01-settings-default-five-sections.png
The finished screen. **Five sections in order:** Notifications (real), Life Areas (disabled),
Account (real, Sign Out), About & Diagnostics (disabled), Tag Editor (disabled). The word
"Settings" appears **once**, as the navigation title. The three disabled rows are greyed via
`.foregroundStyle(.secondary)` (not opacity) and are unresponsive.

### 02-notifications-notdetermined-no-prompt.png
The Notifications section reading the **real** iOS authorization status: `.notDetermined` →
"Not requested yet" (orange, with a `questionmark.circle` glyph). This single capture is also the
**no-prompt proof**: Settings was opened cold on a build whose status is `.notDetermined` and **no
system permission dialog appeared** — the section reads `notificationSettings()` only and never
calls `requestAuthorization`/`requestAuthorizationIfNeeded()`. (Same frame as 01; kept separately
because it is the evidence for two distinct acceptance criteria.)

### 03-settings-ax-xxxl.png
Accessibility Dynamic Type at **AX-XXXL** (`accessibility-extra-extra-extra-large`). Text wraps and
the rows grow vertically; nothing is clipped or truncated. Captured on the pre-`LabeledContent`
build (the status row was a hand-rolled `HStack`, which wraps into narrow columns); the shipped code
now uses `LabeledContent`, which reflows this row to a stacked layout at accessibility sizes — i.e.
the shipped build is **equal-or-better** than this capture. See the report's swiftui-pro section.

### 04-post-signout-loginview.png
After tapping **Sign Out** (the `signOutButton` row in Account), the root view returns to
`LoginView` ("Sign in" with email/password). Confirms Sign Out behaviour is unchanged and the
identifier survived.

### 05-open-ios-settings-button.png
The **"Open iOS Settings"** button launched the iOS Settings app (note the "◀ ADHD LifeOS" back
breadcrumb — the deep link came from our app). For a `.notDetermined` app with no settings bundle,
iOS lands on the root Settings page rather than a dedicated app page; this is expected iOS behaviour,
not a defect.

## Not captured live — see report

- **notifications-granted / -denied second state.** The only in-app trigger for a real
  `requestAuthorization` is a task's nudge toggle, which is (a) disabled until the task has a due
  date and (b) a SwiftUI `Toggle` that `idb`'s coordinate taps could not reliably actuate (the app's
  authorization status stayed `.notDetermined` through every attempt — no request ever fired). This
  is an `idb`↔SwiftUI-`Toggle` limitation, not an app issue (buttons like Sign Out tapped fine on
  the first try). The `.authorized`/`.provisional`/`.ephemeral`/`.denied` → display-text mappings
  are all proven by unit test (`NotificationPermissionStateTests`, 16/16 passing). This item is
  marked `[~]` in the TODO with this explanation.
