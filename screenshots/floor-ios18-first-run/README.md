# The app on its floor OS for the first time — iOS 18.0 simulator, 2026-09-24

**Environment:** "iPhone 16 Pro (iOS 18 floor)" simulator on the iOS 18.0 (22A3351) runtime
installed this day (`memory: simulator-runtime-install`), and the iPhone 17 Pro on iOS 26.5 for the
comparison frame; both running the same `Debug-iphonesimulator` build of `main @ 8be293e`
(`F-Floor18` merged at `42d84e7`); Firebase emulator UP; a fresh, signed-out simulator on both, so
the first screen is the sign-in door. Light appearance.

**Why this folder exists.** `F-Floor18` raised the minimum iOS to 18, and every "Verified paths"
line until this day had to read "18–25 path: COMPILE-ONLY — no 18 runtime installed". A test can
prove the floor branch is reached by injection; it cannot prove the app boots and draws on an iOS
18 device. This is the first time it did. The full unit suite also ran on this runtime:
**3,320 tests, 0 failures, 6 skipped** — the six are `JournalLargeTitleReTapTests`, which cover
the iOS 26 large-title re-tap and skip below 26 by design.

**What driving it caught that the tests could not:** nothing wrong. The door is pixel-for-pixel
the same layout on 18.0 and 26.5; the one difference is the Sign In button's corner rounding,
which is each OS's own system control style, not the app's. (The auth design record's segmented
sign-in / create-account control is not part of this first state on either OS.)

**Throwaway data:** none created; nothing was signed in.

| file | proves |
|---|---|
| `00-ios18.0-sign-in-door.jpg` | The app launches and draws its first screen on iOS 18.0, the floor. |
| `01-ios26.5-same-door.jpg` | The same screen on 26.5, same build: identical layout, system button rounding the only difference. |
