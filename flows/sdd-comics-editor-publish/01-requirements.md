# Requirements: comics-editor-publish

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-31

## Problem Statement

`apps/comics-editor-v2.9` has a real, working store-publishing pipeline (`ios/fastlane/`,
`android/fastlane/`, wired into `.github/workflows/release.yml`) — but both are currently
"unfilled": `ios/fastlane/` has only `Appfile`/`Fastfile`, no `screenshots/` directory at all;
`android/fastlane/` has only `Appfile`/`Fastfile`, no `metadata/` directory at all. Both release
lanes (`deliver`/`upload_to_app_store`, `upload_to_play_store`) currently run with
`skip_screenshots`/`skip_upload_images`/`skip_upload_screenshots` set, so nothing store-visual
gets uploaded even once a real release runs.

Meanwhile, real store-ready visual assets already exist in `design/store/` (5 PNGs, exact
App Store Connect / Google Play required pixel dimensions) and `design/dc/` (design-tool source
files + a `screenshots/` folder of smaller in-app screenshots). Nothing currently connects them
to the fastlane pipeline.

Separately: this scope was originally raised inside `flows/sdd-comics-editor-build/` (a CI/build
flow, not publishing) — spinning it out here keeps that flow's charter (native + Docker build
verification) from absorbing an unrelated concern, matching the established pattern in this repo
(e.g. `vdd-comics-editor-jhanava` spun out of `vdd-comics-editor-uiux-lettering`).

## Investigation Findings (2026-07-31)

- **`ios/fastlane/`** (real, wired into `release.yml`'s `release-ios` job): `Appfile` uses
  `net.nativemind.comics.editor`; `Fastfile`'s `deploy` lane runs `deliver`/`upload_to_testflight`
  with `skip_screenshots: true` (App Store lane) — no `screenshots/` dir exists yet.
- **`android/fastlane/`** (real, wired into `release.yml`'s `release-android` job): `Appfile` uses
  `net.nativemind.comics.editor` (Play package name); `Fastfile`'s `deploy` lane runs
  `upload_to_play_store` with `skip_upload_images: true, skip_upload_screenshots: true` — no
  `metadata/android/` dir exists yet.
- **`apps/comics-editor-v2.9/fastlane/`** (top-level, *not* referenced by `release.yml` at all —
  `release.yml` only runs fastlane from inside `ios/`/`android/` working directories): this is a
  **different app's** fastlane setup — `Appfile` has `app_identifier("com.ethnoapp.bgita")`
  ("Bhagavad Gita"), an app that doesn't exist anywhere else in this monorepo. Per the user: this
  is being used as a **structural example** to follow (directory layout: `screenshots/<locale>/`,
  `metadata/<locale>/*.txt`, `metadata/android/<locale>/*.txt`), not something to delete or treat
  as a bug — but its own `screenshots/` is *also* empty (just a `README.txt` placeholder) and its
  own `deliver`/`upload_to_play_store` calls also skip screenshots, so it doesn't demonstrate a
  filled-in screenshot naming convention — only the folder-per-locale shape. Real screenshot
  naming/placement follows fastlane's own documented conventions (`deliver`/`supply`), not this
  example's contents.
- **`design/store/`** — 5 PNGs, verified pixel-exact via `sips`:
  - `appstore-01-1290x2796.png`, `appstore-02-1290x2796.png` — exact iPhone 6.9"/6.7" App Store
    Connect screenshot size. Clean fit for `ios/fastlane/screenshots/<locale>/`.
  - `googleplay-01-1440x2560.png` — within Play Store's phone screenshot bounds. Clean fit for
    `android/fastlane/metadata/android/<locale>/images/phoneScreenshots/`.
  - `googleplay-cover-1024x500.png` — exact Play Store feature graphic size. Clean fit for
    `android/fastlane/metadata/android/<locale>/images/featureGraphic.png`.
  - `pc-01-1440x900.png` — no fastlane lane consumes this: `release.yml` only has
    `release-android`/`release-ios` jobs, no macOS App Store lane exists in this repo. Not directly
    usable by this flow's scope as currently defined (see Open Questions).
- **`design/dc/screenshots/`** — 6 PNGs (`board.png`, `board2-4.png`, `v3-overview.png`,
  `v3-desktop.png`), all 924x540. Below/mismatched vs. both stores' required screenshot pixel
  dimensions for phone screenshots (App Store Connect requires exact per-device-class sizes;
  Play Store's minimum bound is looser but 924x540's landscape desktop-UI framing doesn't read as
  a phone screenshot). These look like marketing/README-style images (`design/dc/*Store Promo*
  .dc.html` files suggest they're source material *for* composing the final `design/store/*.png`
  exports, not independent upload-ready assets). Not directly usable by this flow's scope as
  currently defined (see Open Questions).

## User Stories

### Primary

**As** the person who runs `release.yml`'s `release-ios`/`release-android` jobs
**I want** the real store screenshots (already exported to `design/store/`) wired into
`ios/fastlane/screenshots/` and `android/fastlane/metadata/android/.../images/`, with
`skip_screenshots`/`skip_upload_images` turned off
**So that** a real release actually uploads the app's current screenshots instead of silently
skipping them every time.

## Acceptance Criteria

### Must Have

1. **Given** `design/store/appstore-01-1290x2796.png` and `appstore-02-1290x2796.png`
   **When** `ios/fastlane`'s `deploy appstore` lane runs
   **Then** both screenshots upload to App Store Connect for the target locale(s) (requires
   removing `skip_screenshots: true` from the `appstore` branch of `ios/fastlane/Fastfile`).

2. **Given** `design/store/googleplay-01-1440x2560.png` and `googleplay-cover-1024x500.png`
   **When** `android/fastlane`'s `deploy` lane runs
   **Then** the phone screenshot and feature graphic upload to Google Play (requires removing
   `skip_upload_images`/`skip_upload_screenshots` from `android/fastlane/Fastfile`).

3. **Given** this flow completes
   **When** `flows/sdd-comics-editor-build/`'s own docs are checked
   **Then** any publishing-scoped notes there point here instead (scope split documented in both
   flows' `_status.md`, not silently rewritten).

4. **Given** `design/store/pc-01-1440x900.png` and a new macOS App Store publishing lane
   **When** `macos/fastlane`'s deploy lane runs (new — doesn't exist today)
   **Then** the app is signed for Mac App Store distribution (not the current ad-hoc `"-"` identity
   `build.yml` uses for CI artifacts) and the screenshot uploads to App Store Connect for the same
   macOS app record.

5. **Given** `design/dc/screenshots/*.png` (6 raw UI captures)
   **When** `apps/comics-editor-v2.9/README.md` is viewed
   **Then** it shows a reasonable subset/layout of these as the app's visual introduction (README
   currently has zero images).

### Should Have

- Flag the iOS screenshot device-size gap (only one size class covered, 1290x2796) as a documented
  follow-up rather than pretend full device coverage is done.

### Won't Have (This Iteration)

- Re-purposing `design/dc/screenshots/*.png` (924x540) as store screenshots — wrong shape/size for
  either store's phone screenshot requirements; they go to the README instead (Acceptance
  Criteria 5).
- Any *new* screenshot content (composing/exporting fresh images) — this flow wires up what
  already exists, it doesn't design new marketing material.
- Full per-locale *text* metadata (name/description/keywords/promotional_text) for App Store
  Connect / Play Console — out of scope; this flow is screenshots/images only. (Both stores allow
  screenshots to exist per-locale independent of localized text, so this isn't blocking.)

## Decisions (2026-07-31, resolved via AskUserQuestion)

- **Locale scope**: replicate the same `design/store/` images across 5 locales — **ru** (primary),
  **en-US**, Chinese, Hindi, Thai. Exact locale codes differ per platform/tool and need pinning in
  Specifications: App Store Connect (`deliver`) uses `ru`, `en-US`, `zh-Hans` (assuming Simplified
  Chinese — not stated explicitly, flagged for confirmation), `hi`, `th`. Google Play (`supply`)
  uses `ru-RU`, `en-US`, `zh-CN`, `hi-IN`, `th` — these are NOT the same strings as the App Store
  Connect ones, both sets need to be resolved exactly, not assumed from folder-naming pattern alone.
- **`pc-01-1440x900.png`**: build a real macOS App Store release lane, not just place the image.
  Investigated the existing macOS build (`build.yml`'s `build-macos` job, `macos/Runner.xcodeproj`)
  to scope this realistically:
  - Bundle id already matches the existing convention: `net.nativemind.comics.editor` (same as
    iOS/Android — see `macos/Runner/Configs/AppInfo.xcconfig`), no new identifier needed.
  - `macos/Runner/Release.entitlements` **already has App Sandbox enabled**
    (`com.apple.security.app-sandbox = true`) — the single biggest usual blocker for Mac App Store
    submission is already done, not something this flow needs to add.
  - Current CI signs with `CODE_SIGN_IDENTITY = "-"` (ad-hoc, `build.yml`'s own log: "Re-signed
    (ad-hoc)") — genuinely insufficient for Mac App Store; needs a real Mac App Store distribution
    certificate/provisioning profile (via `match`, mirroring `ios/fastlane/Fastfile`'s existing
    pattern, or manual certs) plus a **new** App Store Connect macOS app record (manual, one-time,
    same as the existing iOS/Android Fastfiles already document as a prerequisite step) and new
    GitHub secrets.
- **`design/dc/screenshots/*.png`**: add to `apps/comics-editor-v2.9/README.md` (currently has no
  images at all) — a reasonable subset/layout, not necessarily all 6.

## Open Questions

- [x] **Chinese locale**: Simplified only — `zh-Hans` (App Store Connect) / `zh-CN` (Google Play).
      Resolved 2026-07-31.
- [x] **macOS signing approach**: reuse `ios/fastlane/Fastfile`'s `match(type: "appstore", ...)`
      pattern (shared cert repo, same team) for macOS too. Resolved 2026-07-31.
- [ ] **README screenshot subset**: pick a small representative set of the 6 `design/dc/screenshots/`
      images (Should Have: don't dump all 6 into a wall of images) — will propose a subset in
      Specifications, open to override.

Final locale scope, both platforms: **ru** (primary), **en-US**, **zh-Hans**/**zh-CN**, **hi**/
**hi-IN**, **th**.

## References

- `apps/comics-editor-v2.9/ios/fastlane/Fastfile`, `android/fastlane/Fastfile` — real lanes to modify.
- `apps/comics-editor-v2.9/fastlane/` — structural example (different app, do not modify/delete).
- `flows/sdd-comics-editor-build/` — origin flow this scope was split out of.

---

## Approval

- [ ] Reviewed by:
- [ ] Approved on:
- [ ] Notes:
