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

2026-08-04 by Codex

## Blockers

- **Local publishing preflight (2026-08-04)**: user asked to publish all store builds directly
  from the local Mac. The repository metadata/assets and global fastlane `2.237.0` are present,
  but no store credentials are available to the process: none of the required `ASC_*`, signing,
  or `PLAY_STORE_JSON_KEY` environment variables are set; Keychain reports `0 valid identities`;
  no `.p12`, Android release keystore, or Play service-account JSON was found. The only local
  `.mobileprovision` file cannot be decoded by `security cms` and is unusable. Therefore none of
  the three upload lanes can safely start until credentials/signing files are supplied locally.
  User explicitly asked to skip the live privacy/support URL check, so it is not treated as a
  blocker for this attempt.
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
