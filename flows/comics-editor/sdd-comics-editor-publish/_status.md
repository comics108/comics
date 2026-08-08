# Status: sdd-comics-editor-publish

## Current Phase

IMPLEMENTATION

## Phase Status

All 4 implementation phases complete, plus a follow-up round filling in full text metadata (name/
subtitle/description/keywords/promotional_text/category/copyright/review-info) for all 3 fastlane
setups across 5 locales — see `04-implementation-log.md`'s "text metadata" session entry. Real
end-to-end verification of all 3 store lanes is blocked on manual prerequisites outside the agent's
reach (see Blockers) — not something this flow can close by itself.

## Last Updated

2026-08-07 by Claude (4th session same day — real macOS CLI archive + direct upload, first ever)

## Blockers (newest)

- **Real macOS CLI archive + direct upload succeeded (2026-08-07) — first-ever Mac App Store
  submission for this app**: same day, same technique as the iOS success below, but macOS hit a real,
  previously-undiscovered bug first: Apple's Mac App Store validator (code 90296) requires **every**
  Mach-O executable in the bundle to carry its own `com.apple.security.app-sandbox=true` entitlement,
  not just the top-level app — the bundled self-contained `.NET` headless core had none. Fixed by
  signing it with a combination of `com.apple.security.app-sandbox=true` +
  `com.apple.security.inherit=true` (new file `macos/Runner/HeadlessCore.entitlements`), applied
  **before** the final whole-app codesign (order matters — confirmed empirically). Persisted into
  `macos/fastlane/Fastfile` too (new signing step, **not independently re-verified** — only the
  entitlements combination itself is proven, via the real upload, not that exact Fastfile insertion
  point). Full blow-by-blow in `04-implementation-log.md`'s "4th same day" session — this would have
  silently blocked every future macOS submission attempt (local or CI) had it not been found now.
  Comics Editor Version 3.2.2 Build 3 (macOS) is uploaded and processing — this is the app's first
  real macOS submission ever, so unlike iOS there's no prior review-feedback cycle to compare
  against; also still unconfirmed whether the macOS App Store Connect app record itself already
  exists (per `macos/fastlane/Fastfile`'s own pre-release checklist item 1) — if processing errors on
  a missing app record, that's the next thing to set up.

- **Real CLI archive + direct upload succeeded (2026-08-07, iOS)**: Version 3.2.2, Build 3 uploaded to
  App Store Connect via `flutter build ipa` + `xcodebuild -exportArchive
  destination:upload -allowProvisioningUpdates` — no Xcode GUI, no fastlane, no manual credentials
  needed (reused Xcode's own already-signed-in account/automatic-signing state on this machine).
  First time this flow's publishing has gone through a pure CLI path end-to-end. Real bundle id
  confirmed as `net.nativemind.comicseditor` (no dots) — this flow's own `ios/fastlane/Fastfile`
  comments and earlier session-log entries referencing `net.nativemind.comics.editor` (with dots)
  are **stale**, should be corrected next time that file is touched. Full detail in
  `04-implementation-log.md`'s "3rd same day" session. Waiting on App Store Connect
  processing/review — no further agent action until new feedback arrives (same cycle as Build 1).

## Blockers (Info.plist / App Store review feedback, 2026-08-07 earlier)

- **Real milestone (2026-08-01 → 2026-08-07, mostly outside logged agent activity)**: after
  Codex's 2026-08-04 preflight found local credentials still missing, the user separately worked
  through the local Xcode path (this agent helped unblock two real issues in the process: no Apple
  ID signed into Xcode, and the iOS 26.5 platform/SDK not installed — fixed via `xcodebuild
  -downloadPlatform iOS`; confirmed an unsigned Release build succeeds end-to-end for a real device
  destination). The user then completed signing + archive + upload themselves via Xcode's own
  Organizer GUI (not fastlane/CI, not fully visible to any agent) and **successfully uploaded
  Comics Editor's first real build to App Store Connect** — Version 3.2.1, Build 1, App Apple ID
  6798479000. This is the first genuine end-to-end success this whole flow has produced.
- **Real Apple review feedback received (2026-08-07)** on that build — 2 required fixes, 1
  advisory:
  - `ITMS-90683`: missing `NSPhotoLibraryUsageDescription` and `NSCameraUsageDescription` in
    `ios/Runner/Info.plist` — required. Root cause: the `file_picker` plugin's iOS implementation
    pulls in `DKImagePickerController`/`DKCamera` (confirmed present in the resolved Swift Package
    dependencies during local builds this session), which link Photo Library/Camera APIs even
    though Comics Editor only ever calls the plain file-picker flow — Apple's static analysis
    flags the linked API regardless of whether the app's own code path invokes it.
  - `ITMS-90683`: missing `NSLocationWhenInUseUsageDescription` — flagged as advisory (not required
    yet), same underlying cause (a bundled dependency references location APIs; Comics Editor has
    no location feature anywhere in its own code).
  - `ITMS-90068`: `MinimumOSVersion` 13.0 — advisory only, becomes a hard requirement (≥15.0)
    "Spring 2027." Not touched this session — real scope decision (could affect device support),
    deliberately left for the user to decide, not silently bumped.
  - **Fixed**: added all 3 usage-description keys to `ios/Runner/Info.plist`, honestly scoped to
    what the app actually does (image import for layer/balloon artwork) for Photo/Camera; Location's
    string states plainly that it isn't used and exists only because a bundled component references
    the API — considered but rejected fabricating a plausible-sounding-but-false justification.
  - Bumped `pubspec.yaml` to `3.2.1+2` (Apple rejects re-uploads with a duplicate build number) —
    the fix above is otherwise inert until a new build is actually re-uploaded.
  - Checked whether `macos/Runner/Info.plist` needs the same fix: **inconclusive, left alone** — no
    `macos/Podfile.lock` exists yet (macOS build has never resolved CocoaPods dependencies in this
    checkout), so there's no evidence macOS's `file_picker` implementation links the same
    UIKit-only pods iOS does (macOS almost certainly uses a plain `NSOpenPanel`, not
    `DKImagePickerController`) — worth rechecking once a real macOS submission is attempted, not
    guessed at now.
- **First real `release-ios` run happened (2026-07-31)** — failed at `app_store_connect_api_key`
  with `string contains null byte` in `OpenSSL::PKey::EC.new(key)`. Diagnosed: `ASC_KEY_CONTENT`
  almost certainly holds the raw `.p8` PEM text instead of its base64 encoding (`app_store_connect_
  api_key(..., is_key_content_base64: true)` tries to base64-decode it, garbage-decodes PEM text
  into binary with null bytes). Fix given to user: re-set the secret to
  `base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy`'s output, not the file's raw contents. Also spotted in
  the same log: `MATCH_GIT_URL` is empty (not set at all) — will fail the next step once the key
  issue is fixed. Full secrets/variables reference (what each one is, where to get it, which lane
  needs it) published as an artifact for the user, not duplicated in full here — see this session's
  conversation. This is real progress: first actual signal from a real credentialed run, not just
  unverified-by-construction code.
- **`match` removed entirely (2026-07-31, user's call)**: after 2 real `release-ios` CI runs — 1st
  failed on `ASC_KEY_CONTENT` not being base64 (fixed, confirmed working on run 2), 2nd got past
  that and failed on `match` itself (`fatal: repository '' does not exist` — `MATCH_GIT_URL` was
  never actually set, and setting up a whole separate certs repo felt like unnecessary overhead) —
  user asked to drop `match` and sign directly from GitHub secrets instead, the same pattern
  `android/fastlane` already uses for its keystore. Reworked `ios/fastlane/Fastfile` (create_keychain
  + import_certificate + UUID/Name extracted from the `.mobileprovision` via `security cms -D`+
  `plutil` + `build_app` with `export_options: signingStyle: manual` + explicit `xcargs`) and
  `macos/fastlane/Fastfile` (same idea, but TWO certs — app + installer, per Apple's Mac App Store
  requirement — plus a **newly found gap**: the provisioning profile was never being embedded into
  the `.app` at all, match or not; now copied to `Contents/embedded.provisionprofile` before the
  final `codesign`). `release.yml`'s `release-ios`/`release-macos` jobs gained "Configure signing"
  steps decoding the new secrets to files (mirroring `release-android`'s existing keystore-decode
  step exactly). Full updated secrets list published as an artifact for the user (same URL,
  republished). **None of this is verified by a real run yet** — it's the least-proven part of the
  whole flow now, same caveat as before, just for a different reason (new code, not new platform).
- **Real Android CI run (2026-07-31) found a genuine, unrelated repo bug**: `android/.gitignore`
  was excluding `gradlew`/`gradlew.bat`/`gradle-wrapper.jar` from git entirely (Flutter's default
  template assumes `flutter create` can regenerate them locally — breaks any fresh CI checkout that
  needs the literal wrapper script, which `build.yml`'s `build-android` job never needed since
  `flutter build apk` manages Gradle through Flutter's own tooling, but `fastlane`'s `gradle(...)`
  action does need the literal file). Fixed the `.gitignore`; user still needs to `git add` the 3
  now-unignored files (they exist on disk, were just never tracked) and commit/push.
- **Mid-implementation finding, now resolved in code**: a naive macOS fastlane lane
  (`build_mac_app` + `upload_to_app_store`, as originally scoped in Specifications) would have
  silently shipped a Mac App Store submission missing the C# headless core entirely (Xcode's build
  has no phase that embeds it — that's an external post-build script, `tool/build_headless.sh`,
  which build.yml uses but which re-signs ad-hoc afterward — insufficient for a real store
  identity). Caught and fixed by restructuring the lane to embed the core before a real `codesign`
  + `productbuild` + `upload_to_app_store(pkg:)` sequence — see `04-implementation-log.md`'s
  Discoveries for the full account. This sequence is the least-verified part of the whole flow.

## Progress

- [x] Requirements drafted (2026-07-31) — `01-requirements.md`
- [x] Requirements approved (2026-07-31)
- [x] Specifications drafted (2026-07-31) — `02-specifications.md`
- [x] Specifications approved (2026-07-31)
- [x] Plan drafted (2026-07-31) — `03-plan.md`, 4 independent phases (README, iOS, Android, macOS)
- [x] Plan approved (2026-07-31) — all 4 phases, including macOS lane
- [x] Implementation started (2026-07-31)
- [x] Implementation complete (2026-07-31) — all 4 phases (README, iOS, Android, macOS) done; real
      store-lane verification pending user's manual steps (see Blockers), tracked there not as an
      unfinished task
- [ ] Documentation drafted
- [ ] Documentation approved

## Context Notes

Key decisions and context for resuming:

- Spun out of `flows/sdd-comics-editor-build/` (2026-07-31, user request) — that flow stays scoped
  to CI/build verification (Docker Build, native Windows/macOS/Linux build fixes); this one owns
  everything about actually publishing to the stores (screenshots, metadata, fastlane wiring).
- Target app: `apps/comics-editor-v2.9/` — real fastlane setups are `ios/fastlane/` and
  `android/fastlane/` (wired into `.github/workflows/release.yml`'s `release-ios`/`release-android`
  jobs), both currently missing `screenshots/`/`metadata/` entirely and running with
  `skip_screenshots`/`skip_upload_images`/`skip_upload_screenshots` set.
- **`apps/comics-editor-v2.9/fastlane/`** (top-level, separate from `ios/fastlane/`/`android/fastlane/`)
  was a *different app's* config (Bhagavad Gita, `com.ethnoapp.bgita`) kept intentionally as a
  **structural example** per the user while the real per-platform folders were still empty. Once
  `ios/`/`android/`/`macos/fastlane` were actually filled in (this session), the user asked what was
  worth keeping from it before removing it: extracted the reviewer contact info
  (`metadata/review_information/{first_name,last_name,email_address}.txt` — the developer's own
  contact, not app-specific, copied into `ios/fastlane/metadata/review_information/`) — everything
  else (category, description, keywords, copyright, privacy claims) was genuinely Bhagavad-Gita-
  specific content, not reusable, and out of this flow's scope anyway (text metadata was an
  explicit Won't-Have). The stray top-level `fastlane/` directory was then **removed** (2026-07-31).
- **App directory renamed mid-flow**: `apps/comics-editor-v2.9/` → `apps/comics-editor/` (done
  outside this session, noticed 2026-07-31 when a later command hit "No such file or directory").
  All paths in this flow's docs written before that point still say `comics-editor-v2.9` — accurate
  as of when written, not retroactively rewritten; use `apps/comics-editor/` (no version suffix)
  going forward.
- Real source assets already exist and were verified pixel-exact via `sips`: `design/store/`
  (`appstore-01/02-1290x2796.png` → iOS, `googleplay-01-1440x2560.png` + `googleplay-cover-
  1024x500.png` → Android — see `01-requirements.md`'s Investigation Findings for the full
  mapping). `design/dc/screenshots/*.png` (924x540) and `design/store/pc-01-1440x900.png` don't
  cleanly map to either store's screenshot requirements under current scope (no macOS release lane
  exists at all) — flagged as open questions, not silently dropped or silently force-fit somewhere.

## Fork History

N/A — new flow, not a fork (see Context Notes for the flow it was split out of).

## Next Actions

1. User: provide the local signing/API credentials listed in the 2026-08-04 implementation-log
   entry; then run the three fastlane lanes locally (Android internal, iOS TestFlight, macOS App
   Store) and retain their complete logs.
2. User: create the macOS App Store Connect record (separate from iOS, same bundle id) if it does
   not exist yet.
3. User: get `zh-Hans`/`hi`/`th` store copy reviewed by a native/fluent speaker (ru/en-US are
   native-quality confidence) — not blocking, but should happen before really going live there.
4. User: set the Google Play category manually in Play Console (Art & Design recommended) — not
   part of `supply`'s file-based metadata.
5. Once verified (or issues found and fixed from the local runs): move to Documentation phase.
