# Specifications: comics-editor-publish

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-31
> Requirements: [01-requirements.md](01-requirements.md) (APPROVED)

## Overview

Four independent pieces of work, all inside `apps/comics-editor-v2.9/`: wire existing store
screenshots into the real iOS and Android fastlane lanes across 5 locales; stand up a new macOS
App Store release lane (signing + lane + CI job) so `pc-01-1440x900.png` has somewhere to go; add
a small screenshot section to the app's README using the design tool's raw UI captures.

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `ios/fastlane/screenshots/<locale>/` | Create | 10 files (2 images × 5 locales) |
| `ios/fastlane/Fastfile` | Modify | Remove `skip_screenshots: true` from the `appstore` branch |
| `android/fastlane/metadata/android/<locale>/images/` | Create | 10 files (2 images × 5 locales) |
| `android/fastlane/Fastfile` | Modify | Remove `skip_upload_images`/`skip_upload_screenshots` |
| `macos/fastlane/` | Create | New `Appfile`, `Fastfile`, `screenshots/<locale>/` (5 files) |
| `.github/workflows/release.yml` | Modify | New `release-macos` job |
| `apps/comics-editor-v2.9/screenshots/` | Create | 3 PNGs copied in for the README to reference |
| `apps/comics-editor-v2.9/README.md` | Modify | New `## Screenshots` section |

## 1. iOS screenshots (`ios/fastlane/`)

`deliver` reads `fastlane/screenshots/<locale>/*.png` relative to the fastlane working directory
(`ios/fastlane/` — `release.yml`'s `release-ios` job runs `bundle exec fastlane` with
`working-directory: ios`). Locale folder names must match App Store Connect's locale codes exactly.

Target layout (same 2 source images repeated per locale — `design/store/` has one screenshot set,
not per-locale content, per Requirements' locale-scope decision):

```
ios/fastlane/screenshots/
  ru/appstore-01.png       en-US/appstore-01.png      zh-Hans/appstore-01.png
  ru/appstore-02.png       en-US/appstore-02.png      zh-Hans/appstore-02.png
  hi/appstore-01.png       th/appstore-01.png
  hi/appstore-02.png       th/appstore-02.png
```

Copied from `design/store/appstore-01-1290x2796.png` / `appstore-02-1290x2796.png`, filename
dimension-suffix dropped on copy (`deliver` reads actual image dimensions to bucket into the
correct App Store Connect device-size slot; the suffix is source-side bookkeeping only). 1290x2796
maps to the "iPhone 6.9″ Display" bucket — the only device class covered (Requirements' flagged
follow-up: no iPad/other iPhone sizes provided).

`ios/fastlane/Fastfile`: the `appstore` branch's `deliver(...)` call currently has
`skip_screenshots: true` — remove that line. The `testflight` branch (`upload_to_testflight`)
doesn't touch screenshots — no change there.

## 2. Android screenshots (`android/fastlane/`)

`supply` reads `fastlane/metadata/android/<locale>/images/<slot>/*.png` relative to the fastlane
working directory (`android/fastlane/`). Locale folder names match Google Play Console's codes
(these differ from App Store Connect's — e.g. `ru-RU` not `ru`, `zh-CN` not `zh-Hans`).

Target layout:

```
android/fastlane/metadata/android/
  ru-RU/images/phoneScreenshots/1.png     ru-RU/images/featureGraphic.png
  en-US/images/phoneScreenshots/1.png     en-US/images/featureGraphic.png
  zh-CN/images/phoneScreenshots/1.png     zh-CN/images/featureGraphic.png
  hi-IN/images/phoneScreenshots/1.png     hi-IN/images/featureGraphic.png
  th/images/phoneScreenshots/1.png        th/images/featureGraphic.png
```

Copied from `design/store/googleplay-01-1440x2560.png` (phone screenshot) and
`googleplay-cover-1024x500.png` (feature graphic — exact required Play Store dimensions).

`android/fastlane/Fastfile`: `upload_to_play_store(...)` currently has
`skip_upload_images: true, skip_upload_screenshots: true` — remove both lines.

## 3. macOS App Store release lane (new)

### Signing

Reuse `ios/fastlane/Fastfile`'s `match(type: "appstore", readonly: true, api_key: ...)` pattern —
same Apple Developer team (`APPLE_TEAM_ID`/`ASC_TEAM_ID`), same match cert repo (`MATCH_GIT_URL`),
with an explicit `platform: "macos"` so match stores/reads the macOS-specific cert+profile as a
distinct entry from iOS's `platform: "ios"` in that same shared repo. Bundle id is already correct
and needs no change: `net.nativemind.comics.editor` (verified in
`macos/Runner/Configs/AppInfo.xcconfig`, matches iOS/Android). App Sandbox is already enabled in
`macos/Runner/Release.entitlements` — no entitlements change needed.

### New files

`macos/fastlane/Appfile` (mirrors `ios/fastlane/Appfile`, same env vars, no new secrets for
identity):
```ruby
app_identifier(ENV["MACOS_BUNDLE_ID"] || "net.nativemind.comics.editor")
apple_id(ENV["APPLE_ID"])
itc_team_id(ENV["ASC_TEAM_ID"])
team_id(ENV["APPLE_TEAM_ID"])
```

`macos/fastlane/Fastfile` — new `platform :macos do lane :deploy ... end`, structurally mirroring
`ios/fastlane/Fastfile`'s `deploy` lane: `match(type: "appstore", platform: "macos", readonly:
true, api_key: ...)` → `build_mac_app(scheme: "Runner", export_method: "app-store")` →
`upload_to_app_store(api_key: ..., skip_screenshots: false, skip_metadata: true, force: true)`.
`skip_metadata: true` deliberately — no text metadata in this flow's scope (mirrors how
`ios/fastlane`'s own `appstore` branch already sets `skip_metadata: true`).

`macos/fastlane/screenshots/<locale>/macos-01.png` — same 5-locale set, copied from
`design/store/pc-01-1440x900.png` (1440x900 is one of Apple's officially supported Mac App Store
screenshot sizes — usable as-is, no resizing needed).

### `.github/workflows/release.yml` — new job

New `release-macos` job, structurally mirroring `release-ios` (`macos-latest` runner, Flutter
setup, `bundle exec fastlane macos deploy` with `working-directory: macos`), no
Android-style keystore-decoding step (signing is entirely via `match` inside the lane, same as
`release-ios`). No new `workflow_dispatch` track input needed — Mac App Store has no
internal/alpha/beta/production track concept like Play; runs straight to App Store Connect
processing, same shape as iOS's `appstore` lane.

### Manual prerequisites (documented in the new Fastfile's header comment, same pattern the
existing iOS/Android Fastfiles already use for their own prerequisites — not automatable by this
flow)

1. Create the macOS app record in App Store Connect under `net.nativemind.comics.editor` — a
   separate record from the iOS one even sharing a bundle id in some account configurations; needs
   manual verification during setup (flagged as a real risk below, not glossed over).
2. Run `fastlane match appstore --platform macos` once, locally, by whoever holds Apple Developer
   account access, to seed the shared match repo with a macOS distribution cert/profile — the
   agent has no Apple Developer credentials and cannot do this step.
3. No new GitHub secrets beyond what `release-ios` already uses (`ASC_KEY_ID`, `ASC_ISSUER_ID`,
   `ASC_KEY_CONTENT`, `MATCH_GIT_URL`, `MATCH_PASSWORD`, `APPLE_TEAM_ID`, `ASC_TEAM_ID`) — same
   team, same match repo, just one more platform entry in it.

## 4. README screenshots (`apps/comics-editor-v2.9/README.md`)

Subset: 3 of the 6 `design/dc/screenshots/*.png` — `v3-overview.png` (whole-app "what is this"
shot), `board.png` (a representative canvas/board view), `v3-desktop.png` (desktop-specific
layout). Skips `board2-4.png` (same view, different content — redundant for a README) on the
assumption they're minor variants of `board.png`; **Plan's verification step confirms this
visually before finalizing**, not assumed here.

Images copied into a new `apps/comics-editor-v2.9/screenshots/` directory (not referenced from
`../../design/` — GitHub READMEs render relative to the repo they live in, and `design/` sits
outside `apps/comics-editor-v2.9`'s own git repo boundary entirely, confirmed this session via
`git remote -v`/`show-toplevel` while diagnosing the `sdd-comics-editor-build` CI failure — an
in-repo copy is required for the images to actually render on GitHub, not a style preference).
New `## Screenshots` section placed after the title/one-line description, before deep technical
sections; each image gets a one-line caption.

## Edge Cases

| Case | Handling |
|------|----------|
| `match` has no macOS-platform cert/profile yet in the shared repo | `release-macos` fails clearly at the `match` step with fastlane's own "no matching certificate/profile" error — same failure mode `release-ios` showed before its own first real `match appstore` run. This is expected until prerequisite 2 above is done manually; not silently worked around. |
| App Store Connect doesn't support a macOS record under the same bundle id/account configuration as iOS | Genuine risk, unverifiable without real App Store Connect access — listed in Plan's Risk Assessment, not something detectable from code alone. |
| Copying `design/store/*.png` into 5 locale folders per platform duplicates identical bytes 5x | Accepted — `deliver`/`supply` require real per-locale files (no symlink/reference support), and the existing top-level `fastlane/` example already establishes this per-locale-copy convention. |
| `board2.png`/`board3.png`/`board4.png` turn out NOT to be redundant with `board.png` on inspection | Plan's verification step visually checks all 6 `design/dc/screenshots/*.png` before finalizing the README subset — the 3-image pick above is a starting proposal, not locked in before that check. |

## Testing / Verification Strategy

Nothing here is unit-testable (it's file placement + CI workflow config, not application code).
Verification is: `flutter analyze`/`flutter test` still pass after `README.md`/workflow changes
(sanity — no app code touched, but confirms nothing broke incidentally); visual inspection of the
3 chosen `design/dc/screenshots/*.png` before finalizing the README subset; `.github/workflows/
release.yml` YAML syntax validated (e.g. via a YAML parser, since GitHub Actions can't be run
locally); real confirmation of the iOS/Android/macOS lanes ultimately requires a real
`workflow_dispatch` run by the user with real credentials configured — same "agent cannot verify,
user confirms via real CI" pattern already established in `sdd-comics-editor-build`.

## Open Design Questions

- [ ] None outstanding — all resolved in Requirements' Decisions section.

---

## Approval

- [ ] Reviewed by:
- [ ] Approved on:
- [ ] Notes:
