# Implementation Log: comics-editor-publish

> Started: 2026-07-31
> Plan: [03-plan.md](03-plan.md)

## Progress Tracker

| Task | Status | Notes |
|------|--------|-------|
| 1.1 Verify/pick README subset | Done | Assumption in Specifications was wrong — see Discoveries |
| 1.2 Copy images + README section | Done | 2 images (not 3 — see 1.1), new `## Screenshots` section |
| 2.1 iOS screenshots (5 locales) | Done | 10 files |
| 2.2 Un-skip `ios/fastlane/Fastfile` | Done | |
| 3.1 Android screenshots (5 locales) | Done | 10 files |
| 3.2 Un-skip `android/fastlane/Fastfile` | Done | |
| 4.1 `macos/fastlane/Appfile`+`Fastfile` | Done | Significantly more involved than planned — see Discoveries |
| 4.2 macOS screenshots (5 locales) | Done | 5 files |
| 4.3 `release-macos` job in `release.yml` | Done | Includes `.NET` setup, not in original Plan |

## Session Log

### Session 2026-07-31 — Claude

**Started at**: Requirements phase (flow just spun out of `sdd-comics-editor-build` mid-session,
per user request).
**Context**: User asked to wire `design/dc`/`design/store` screenshots into fastlane publishing
and move all publishing work into its own SDD flow.

#### Completed
- Task 1.1: Inspected all 6 `design/dc/screenshots/*.png`. Specifications' assumed 3-image subset
  (`v3-overview`, `board`, `v3-desktop`) was wrong: `board.png`/`board2.png` are **entirely blank/
  white** images, and `board3.png`/`board4.png` are an **old "Comics Editor 2.8" WPF-recreation
  spec deck** (different app version entirely, not the current v3.0 Flutter UI). Only
  `v3-overview.png` and `v3-desktop.png` actually show the current app — used those 2, not 3.
- Task 1.2: Copied `v3-overview.png` → `screenshots/overview.png`, `v3-desktop.png` →
  `screenshots/desktop-workspace.png` inside `apps/comics-editor-v2.9/` (in-repo copy required —
  `design/` sits outside this app's own git repo boundary, confirmed earlier this session via
  `git remote -v`/`show-toplevel` while diagnosing `sdd-comics-editor-build`'s CI failure). Added
  `## Скриншоты` section to `README.md` (matches the README's existing all-Russian language).
  - Files changed: `apps/comics-editor-v2.9/screenshots/overview.png`,
    `apps/comics-editor-v2.9/screenshots/desktop-workspace.png`, `apps/comics-editor-v2.9/README.md`
  - Verified by: visual inspection of both source images before copying; Markdown syntax reviewed
- Task 2.1/2.2: Copied `design/store/appstore-01/02-1290x2796.png` into `ios/fastlane/screenshots/
  {ru,en-US,zh-Hans,hi,th}/`; removed `skip_screenshots: true` from `ios/fastlane/Fastfile`'s
  `appstore` branch.
  - Files changed: `ios/fastlane/screenshots/**` (10 files), `ios/fastlane/Fastfile`
  - Verified by: `find | wc -l` == 10; `ruby -c` syntax check passed
- Task 3.1/3.2: Copied `googleplay-01-1440x2560.png`/`googleplay-cover-1024x500.png` into
  `android/fastlane/metadata/android/{ru-RU,en-US,zh-CN,hi-IN,th}/images/`; removed
  `skip_upload_images`/`skip_upload_screenshots` from `android/fastlane/Fastfile`.
  - Files changed: `android/fastlane/metadata/android/**` (10 files), `android/fastlane/Fastfile`
  - Verified by: `find | wc -l` == 10; `ruby -c` syntax check passed
- Task 4.1: **Significant mid-implementation finding** (see Discoveries) changed this task's scope
  substantially from Specifications' original plan (`build_mac_app` + `upload_to_app_store`
  directly). Final `macos/fastlane/Fastfile` does: `flutter build macos --release` (raw, matching
  `build.yml`'s proven invocation) → `dotnet publish` the headless core + copy into
  `Contents/Resources/comics-core/` (same logic as `tool/build_headless.sh`, minus its ad-hoc
  re-sign) → real `codesign` with the `match`-installed "3rd Party Mac Developer Application"
  identity (found via `security find-identity`, not hardcoded) → `productbuild` into a signed
  `.pkg` using the separate "3rd Party Mac Developer Installer" identity → `upload_to_app_store(pkg:
  ...)`. Extensively commented explaining why (the header comment alone is ~50 lines) since this
  diverges from the simpler pattern `ios/fastlane/Fastfile` uses.
  - Files changed: `macos/fastlane/Appfile`, `macos/fastlane/Fastfile`, `macos/Gemfile` (new — not
    in original Plan's file list, but required for `bundle exec fastlane` to work at all, same
    pattern as `ios/Gemfile`/`android/Gemfile`)
  - Verified by: `ruby -c` syntax check on all 3 files. **Cannot verify the lane actually works** —
    no Mac Developer account/match repo/App Store Connect access available to the agent. This is
    the least-verified piece of this entire flow; flagged prominently in the Fastfile's own header
    comment, not just here.
- Task 4.2: Copied `pc-01-1440x900.png` into `macos/fastlane/screenshots/{ru,en-US,zh-Hans,hi,th}/`.
  - Files changed: `macos/fastlane/screenshots/**` (5 files)
  - Verified by: `find | wc -l` == 5
- Task 4.3: Added `release-macos` job to `release.yml`, mirroring `release-ios`'s structure
  (`macos-latest`, Flutter + Ruby setup) plus `actions/setup-dotnet@v4` (needed because — unlike
  `release-ios`/`release-android` — this lane calls `dotnet publish` directly; the original
  Specifications/Plan didn't anticipate this and the job initially had a now-corrected comment
  claiming ".NET isn't needed here"). Added `DOTNET_VERSION` to the workflow's top-level `env:`
  block (previously only had `FLUTTER_VERSION`, since neither of the other two release jobs needed
  .NET).
  - Files changed: `.github/workflows/release.yml`
  - Verified by: YAML parses (`python3 -c "import yaml; yaml.safe_load(...)"`); job structure
    diffed against `release-ios` for consistency. **Cannot verify the job succeeds** — same
    limitation as Task 4.1.
- Full-suite sanity check: `flutter analyze` (0 issues) after all changes — confirms nothing in the
  actual Dart app was disturbed by this flow's README/fastlane/workflow-only changes.

#### Deviations from Plan
- README subset: 2 images, not 3 (Task 1.1 found the planned 3rd/other candidates were blank or
  from an outdated app version — see Discoveries).
- macOS lane (Task 4.1): far more involved than Specifications originally described
  (`build_mac_app`+`upload_to_app_store` in ~10 lines). Real reason: found during implementation
  that `build_mac_app` alone would silently produce and upload a Mac App Store submission missing
  the C# headless core entirely (see Discoveries) — surfaced to the user via `AskUserQuestion`
  mid-implementation rather than either silently shipping something broken or silently deciding
  unilaterally to expand scope; user chose "do it automatically."
- `macos/Gemfile` and `release.yml`'s `.NET` setup: not in the original Plan's File Change Summary
  at all — both are genuine requirements only visible once Task 4.1's actual implementation
  approach was worked out, not oversights caught late.

#### Discoveries
- **README screenshot subset**: `design/dc/screenshots/board.png`/`board2.png` are blank/white;
  `board3.png`/`board4.png` are from an entirely different, older app version ("Comics Editor 2.8"
  WPF spec, not v3.0 Flutter). Only 2 of the original 6 candidate files are usable. This directly
  validated the Plan's own Task 1.1 (visual verification before finalizing) — the Specifications
  doc's assumption, written before actually opening the images, was wrong in a way that would have
  shipped broken/wrong content if Task 1.1 had been skipped.
- **macOS core-embedding gap**: the Xcode project (`macos/Runner.xcodeproj/project.pbxproj`) has no
  build phase that embeds the C# headless core — that only happens via the external
  `tool/build_headless.sh` script, run *after* Xcode/Flutter finishes building and signing, which
  is why that script re-signs ad-hoc afterward (documented in its own comments: "files added after
  this aren't part of the signature's resource seal"). A naive `build_mac_app` + `upload_to_app_store`
  lane (what Specifications originally called for) would have built, signed, and uploaded a Mac App
  Store submission that looks completely normal but is missing its actual editing functionality —
  only discoverable by someone actually trying to open a file in the shipped app. Caught this before
  implementing it as written, not after.

**Ended at**: All 4 phases complete. Flow substantively done; real end-to-end verification (all
three store lanes) is blocked on manual prerequisites outside the agent's reach (App Store Connect
records, `match` cert seeding, real credentials) — same category of limitation
`sdd-comics-editor-build` already operates under for anything requiring real store/signing access.
**Handoff notes**: Before a real `release-macos` run: (1) create the macOS App Store Connect record,
(2) run `fastlane match appstore --platform macos` once locally with real Apple Developer access —
both documented in `macos/fastlane/Fastfile`'s header comment. If the manual `codesign`/`productbuild`
sequence in that Fastfile turns out subtly wrong on a real run (identity lookup, `productbuild`
flags, etc.), the header comment explains the *intent* of each step precisely enough to debug/fix
without re-deriving the whole approach from scratch — read it first.

---

## Deviations Summary

| Planned | Actual | Reason |
|---------|--------|--------|
| README: 3-image subset (`v3-overview`, `board`, `v3-desktop`) | 2-image subset (`v3-overview`, `v3-desktop`) | `board.png` blank, `board3/4.png` from a different (older) app version — found during Task 1.1's own verification step |
| macOS lane: `build_mac_app` + `upload_to_app_store`, ~10 lines | Manual `flutter build` → embed core → real `codesign` → `productbuild` → `upload_to_app_store(pkg:)`, ~70 lines + extensive comments | `build_mac_app` alone would ship a Mac App Store submission missing the C# core entirely — found mid-implementation, confirmed with user before proceeding |
| `release-macos` job: no `.NET` setup needed | Added `actions/setup-dotnet@v4` + `DOTNET_VERSION` env var | The reworked macOS lane calls `dotnet publish` directly, unlike `release-ios`/`release-android` |

## Learnings

- Specifications-phase assumptions about *content* (which screenshots look right, whether an
  existing build pattern is safe to reuse as-is) genuinely need a real verification pass during
  Implementation, not just at Plan-approval time — both of this flow's two real deviations were
  caught exactly where the Plan's own checkpoints said to look (Task 1.1's explicit visual check;
  the Plan's general "verify against real state" ethos), not by luck.
- When a straightforward-looking task (macOS lane = "just add the 4th fastlane platform") turns out
  to have a real correctness trap that the other 3 platforms don't share, surfacing it explicitly
  (via `AskUserQuestion`) before building on the wrong foundation is worth the interruption — the
  alternative was either silently shipping something broken or silently deciding to redesign it
  without the user's awareness of the added complexity/risk.

## Completion Checklist

- [x] All tasks completed (4 phases, all Plan tasks done — no tasks skipped or deferred)
- [x] Tests passing (`flutter analyze`: 0 issues; no Dart app code touched by this flow, so no
      `flutter test` regression risk, but sanity-checked anyway)
- [x] No regressions (existing `ios/fastlane`/`android/fastlane` lanes only had `skip_*` flags
      removed — no other lines touched; `release-ios`/`release-android` jobs in `release.yml`
      untouched)
- [x] Documentation updated (this log, `_status.md`, README.md, extensive in-file comments in every
      new/modified Fastfile explaining rationale)
- [ ] Status updated to COMPLETE — pending: real verification of all 3 store lanes requires the
      user's manual credential/App-Store-Connect setup + a real `workflow_dispatch` run, which
      can't happen inside this session. Flow stays open until that's confirmed, per the same
      pattern `sdd-comics-editor-build` uses for anything requiring real CI/credentials access.

---

### Session 2026-07-31 (продолжение) — Claude (text metadata: full store listing copy)

**Started at**: user resumed the flow asking to fill in *all* fastlane metadata for store
publishing, explicitly asking for analysis of every README + every `sdd-`/`vdd-` flow in the repo
first — this supersedes the earlier Requirements' "Won't Have: full per-locale text metadata."

#### Completed
- Researched via a dedicated Explore-agent survey (not written to a file, synthesized directly):
  read `apps/comics-editor/README.md` plus every `flows/sdd-comics-editor-*`/`flows/vdd-comics-
  editor-*` requirements doc, plus a lighter pass over the Comics Viewer/Puzzle ecosystem flows,
  to ground the copy in what's actually shipped vs. still planned. Key findings that shaped the
  copy: (1) target user is production professionals (comic producers, letterers, localization
  teams), not casual hobbyists — every flow frames it this way; (2) AI-assisted balloon lettering
  is real UI but a **stub backend** (`stub_balloon_ai_client.dart`, deterministic placeholder
  pixels, no real model wired in) — store copy must not claim working AI generation; (3) no
  accounts/login/analytics/IAP found anywhere — genuinely local-only, safe to state a simple "no
  data collected" privacy claim; (4) product is always called "Comics Editor," no version number
  in the public name (the app directory was deliberately renamed away from `-v2.9` for this reason).
- Found the correct copyright holder already established in the shipped app itself
  (`bin/comics_editor.app/Contents/Info.plist`: "Copyright © 2026 NativeMind") — used this instead
  of guessing or reusing the Bhagavad-Gita example's unrelated company name.
- Asked the user directly (not guessed) for: privacy policy URL (mandatory for Apple) and support
  URL — got `https://comics.nativemind.net/policy.html` and `.../support.html`. Confirmed neither
  page's source exists in this repo (external, presumably managed elsewhere) — not this flow's job
  to build them, only to reference them.
- Asked the user whether to draft zh-Hans/hi/th copy as best-effort (vs. leaving empty) — chose
  best-effort, explicitly flagged as needing native-speaker review before real submission (both in
  each Fastfile's header comment and here).
- Wrote full text metadata for all 5 locales (ru primary, en-US, zh-Hans/zh-CN, hi/hi-IN, th) across
  three fastlane setups:
  - `ios/fastlane/metadata/`: account-level `copyright.txt` ("© 2026 NativeMind"),
    `primary_category.txt` ("GRAPHICS_AND_DESIGN"), `review_information/notes.txt` (explains no-
    login evaluation flow and the AI-lettering stub caveat explicitly, so reviewers don't flag it
    as broken); per-locale `name`/`subtitle`/`description`/`keywords`/`promotional_text`/
    `support_url`/`privacy_url.txt` — 5 locales × 7 files = 35 files + 6 account-level = 41 total.
  - `android/fastlane/metadata/android/`: per-locale `title`/`short_description`/
    `full_description.txt` — 5 locales × 3 files = 15 files. (Play category isn't part of `supply`'s
    text-file metadata convention — noted in the Fastfile comment that it needs setting via Play
    Console UI directly, recommended "Art & Design.")
  - `macos/fastlane/metadata/`: same content as iOS, copied wholesale (same product, same claims
    apply — just a separate App Store Connect record) — 41 files, same structure as iOS.
  - All character-limit-constrained fields (name/title ≤30, subtitle ≤30, Play short_description
    ≤80, keywords ≤100, promotional_text ≤170) verified via `python3 -c "print(len(...))"` against
    Unicode character count, not byte count (Cyrillic/CJK/Devanagari/Thai all multi-byte in UTF-8 —
    `wc -c` would have overcounted and given false confidence).
  - Removed `skip_metadata: true` / `skip_upload_metadata: true` from all three `Fastfile`s'
    `upload_to_app_store`/`upload_to_play_store` calls — matches the same pattern already used for
    `skip_screenshots`/`skip_upload_images` earlier this session; metadata now written but not
    wired to upload would have been silently useless.
  - Files changed: `ios/fastlane/metadata/**` (41 files), `android/fastlane/metadata/android/**`
    (+15 `.txt` files, alongside the images from earlier), `macos/fastlane/metadata/**` (41 files,
    new), `ios/fastlane/Fastfile`, `android/fastlane/Fastfile`, `macos/fastlane/Fastfile` (all 3:
    header comments extended, `skip_metadata` flags removed)
  - Verified by: `ruby -c` syntax check on all 3 Fastfiles; `flutter analyze` (0 issues, sanity
    check that nothing in the actual app was touched); per-file character-limit checks as above.
    **Cannot verify the actual upload succeeds** — same limitation as every other piece of this
    flow requiring real store credentials/access.

#### Deviations from Plan
- This whole session extends past the original `03-plan.md`'s 4 phases (which explicitly scoped
  text metadata as Won't Have) — not a correction of something done wrong, a genuine new request
  the user made after implementation had already finished. Documented as a Requirements amendment
  (strikethrough + supersession note) rather than silently rewriting the original Won't-Have as if
  it had never been said.

#### Discoveries
- The **stray top-level `apps/comics-editor/fastlane/`** directory (Bhagavad Gita example, see
  earlier session entry) had genuinely reusable review-contact info (developer's own name/email,
  not app-specific) — extracted into `ios/fastlane/metadata/review_information/` before the
  directory was removed (separate user exchange, same session, tracked in `_status.md`'s Context
  Notes rather than duplicated here).
- The app's own `bin/comics_editor.app/Contents/Info.plist` already had a real, authoritative
  copyright string — worth checking existing built artifacts for ground truth like this before
  asking the user or guessing, in general.

**Ended at**: Text metadata complete for all 3 fastlane setups, all 5 locales. Real upload
verification remains blocked on the same manual prerequisites as the rest of this flow (App Store
Connect access, `match` cert seeding, real credentials) — nothing new introduced by this session's
work specifically.
**Handoff notes**: Before real submission — (1) get zh-Hans/hi/th copy reviewed by a native/fluent
speaker (flagged, not blocking, but should happen before going live in those markets); (2) confirm
`https://comics.nativemind.net/policy.html` and `/support.html` are real, live pages by the time of
submission (this flow only references them, doesn't create them); (3) set the Google Play category
manually in Play Console (not part of `supply`'s file-based metadata).

---

### Session 2026-07-31 (продолжение 2) — Claude (real CI runs: ASC_KEY_CONTENT fix confirmed, match dropped, gradlew gitignore bug)

**Started at**: user resumed with `/sdd run sdd-comics-editor-publish`, then asked which GitHub
secrets to set and where from.

#### Completed
- Compiled and published a full secrets/variables reference as an artifact (name, source, which
  lane needs it) covering Apple API key, iOS signing, macOS signing, Android signing — rather than
  duplicating the full table in this log (kept current by redeploying to the same URL as the setup
  evolved).
- **Real CI run #2** (`release-ios`): confirmed the `ASC_KEY_CONTENT` base64 fix from the previous
  session worked — `app_store_connect_api_key` step now succeeds. Progressed to `match`, which
  failed with `fatal: repository '' does not exist` (`MATCH_GIT_URL` secret was never actually set).
- **Real CI run #2** (`release-android`, same push): failed with `Couldn't find gradlew at path
  '.../android/gradlew'`. Investigated locally: `android/.gitignore` explicitly excluded `gradlew`/
  `gradlew.bat`/`gradle-wrapper.jar` (Flutter's default template, assumes `flutter create` can
  regenerate them — breaks fresh CI checkouts). Confirmed via `git ls-files` that neither file was
  ever tracked. **This is why `build.yml`'s own `build-android` job never hit it** — `flutter build
  apk` manages Gradle through Flutter's own tooling, not the literal wrapper script; this was the
  first time anything in this repo actually needed the checked-in `android/gradlew`.
  - Files changed: `android/.gitignore` (removed the 3 offending lines + a stray garbage `?` line)
  - Verified by: confirmed all 3 files exist on disk (`ls`), confirmed `git status` now shows them
    as untracked (`??`) rather than ignored — ready for the user to `git add`/commit/push. **Cannot
    verify the actual CI re-run succeeds** without the user pushing first.
- User then asked whether `match` could be dropped entirely in favor of signing directly via GitHub
  secrets (same pattern `android/fastlane` already uses for its keystore) — confirmed yes: `match`
  and the App Store Connect API key solve unrelated problems (code signing vs. API auth), and
  `match`'s only real value is *where the certificate lives* — a private git repo is not mandatory,
  direct secrets work exactly as well and is simpler.
  - **`ios/fastlane/Fastfile`**: replaced `match(...)` with `create_keychain` → `import_certificate`
    → UUID/Name extracted from the `.mobileprovision` via `security cms -D -i ... | plutil -extract
    ...` (not guessed from any fastlane action's return value) → profile copied to `~/Library/
    MobileDevice/Provisioning Profiles/<uuid>.mobileprovision` → `build_app` with `export_options:
    signingStyle: manual` + explicit `xcargs` (`CODE_SIGN_STYLE`/`CODE_SIGN_IDENTITY`/
    `PROVISIONING_PROFILE_SPECIFIER`). Extensively commented (this is a well-documented but genuinely
    unverified-by-this-agent pattern, same transparency standard as the earlier macOS core-embedding
    fix).
  - **`macos/fastlane/Fastfile`**: same idea, but Mac App Store needs **two** certs (app + installer,
    a real Apple requirement, not a match artifact) — `create_keychain` + two `import_certificate`
    calls. Since this lane already did manual `codesign`/`productbuild` (not gym's auto-export, for
    the core-embedding reason from the previous session), most of the lane didn't need to change —
    just swapped where the identities come from. **Found and fixed a genuine gap that existed even
    with `match`**: the provisioning profile was never being embedded into the built `.app` at all
    (`Contents/embedded.provisionprofile`) — added that step before the final `codesign`, since Mac
    App Store apps need it regardless of signing method.
  - **`.github/workflows/release.yml`**: added "Configure signing" steps to `release-ios`/
    `release-macos`, decoding the new secrets to files — structurally identical to `release-android`'s
    existing keystore-decode step. Removed `MATCH_GIT_URL`/`MATCH_PASSWORD` from both jobs' env.
  - Files changed: `ios/fastlane/Fastfile`, `macos/fastlane/Fastfile`, `.github/workflows/release.yml`
  - Verified by: `ruby -c` on both Fastfiles, YAML parse on `release.yml`, `flutter analyze` (0
    issues). **Cannot verify the signing sequence actually works** — no real Apple Developer
    certs/CI access available to the agent; this is now the single least-proven piece of the whole
    flow (new code, replacing the also-unverified match-based version).
- Republished the secrets artifact with the corrected (match-free) content at the same URL.

#### Deviations from Plan
- `match` → direct secrets is a real architecture change to Task 4.1 (`macos/fastlane/Appfile`+
  `Fastfile`) and to the already-implemented `ios/fastlane/Fastfile` (which Plan never scoped for
  modification at all, since it existed and "worked" — as far as anyone knew — before this flow
  started). Driven entirely by real CI feedback (`MATCH_GIT_URL` friction) plus the user's explicit
  preference, not a bug being fixed.

#### Discoveries
- `android/.gitignore` excluding the Gradle wrapper is a pre-existing repo issue, unrelated to
  anything this flow built — only surfaced because `release-android`'s fastlane `gradle(...)` action
  is the first thing in this repo's history to need the literal `android/gradlew` file rather than
  going through `flutter build apk`'s own Gradle-invocation path.
- Mac App Store provisioning-profile embedding was missing even in the match-based version of the
  macOS lane from the previous session — not something match not being used introduced; a real gap
  found while re-examining the lane for an unrelated reason (dropping match), which is exactly the
  kind of thing a second careful pass over existing code sometimes catches that the first pass
  missed under time/context pressure.

**Ended at**: `match` fully removed from both Apple lanes; secrets reference published and current.
Two real, distinct bugs found via actual CI runs and fixed (the Android gitignore issue is a repo
bug unrelated to this flow's own changes; the profile-embedding gap was in this flow's own earlier
work). Nothing in this session's changes has been confirmed by a real run yet.
**Handoff notes**: The very next real CI attempt should be treated as the first genuine test of the
match-free signing approach for both iOS and macOS — if it fails, the Fastfile's own step-by-step
header comments name exactly which of the 4-5 sequential operations (keychain → import → extract →
build/sign → package) is implicated by where in the log it dies, same diagnostic discipline as
`sdd-comics-editor-build`'s Windows MSB1008 investigation history.

---

### Session 2026-08-04 — Codex (local store publishing preflight)

**Started at**: user resumed the flow and explicitly requested publication to the stores from the
local computer rather than another CI-only verification round.

#### Completed

- Restored the approved requirements/specification/plan and checked the current application tree.
- Confirmed that fastlane `2.237.0` is already installed globally, matching the lockfile, so a
  network-dependent gem install is not required for local publication.
- Confirmed store assets are present: 15 Apple screenshots, 10 Android image assets, and 107 total
  metadata/image files across the three platform setups.
- Confirmed app version is `3.2.0+1` and the expected package/bundle identifier is
  `net.nativemind.comics.editor`.
- Performed a credential/signing preflight without printing secret values: no required store
  environment variables are set, Keychain has `0 valid identities`, and no usable `.p12`, Android
  release keystore, or Play service-account JSON is available locally. The one discovered
  provisioning profile fails `security cms` decoding and cannot be used.
- Skipped the live privacy/support URL check at the user's explicit request.

#### Blocker and exact resume input

The upload lanes were deliberately not started because they would fail before producing a signed
artifact. To resume locally, make these inputs available (values must not be committed):

- Common Apple API: `ASC_KEY_ID`, `ASC_ISSUER_ID`, base64 `ASC_KEY_CONTENT`.
- iOS: `ios/ios_distribution.p12`, `ios/ios_appstore.mobileprovision`,
  `IOS_CERT_PASSWORD`, `SIGNING_KEYCHAIN_PASSWORD`.
- macOS: `macos/macos_app.p12`, `macos/macos_installer.p12`,
  `macos/macos_appstore.provisionprofile`, `MACOS_CERT_APP_PASSWORD`,
  `MACOS_CERT_INSTALLER_PASSWORD`, `SIGNING_KEYCHAIN_PASSWORD`.
- Android: `android/app/release.keystore`, `android/key.properties`, and raw service-account JSON
  in `PLAY_STORE_JSON_KEY`.
- Team identifiers where needed by Appfile: `APPLE_TEAM_ID`, `ASC_TEAM_ID`.

After those inputs exist, run Android to `internal`, iOS to `testflight`, and macOS to App Store;
promoting Android/iOS to production remains a separate deliberate action after processing/review.

**Ended at**: local toolchain and publication content are ready; external signing/API credentials
are the sole hard blocker to starting the real store uploads.

---

### Session 2026-08-07 — Claude (real Apple review feedback fix)

**Started at**: user reported that, sometime after Codex's 2026-08-04 preflight, they had unblocked
the local Xcode signing/upload path themselves (with this agent's help earlier in the same broader
session, unblocking two real issues: Apple ID not signed into Xcode, and the iOS 26.5 platform/SDK
missing — fixed via `xcodebuild -downloadPlatform iOS`) and completed a real archive + upload
directly through Xcode's Organizer GUI, bypassing fastlane/CI entirely. This produced Comics
Editor's **first genuine App Store Connect submission** — Version 3.2.1, Build 1, App Apple ID
6798479000 — which is real, independently-verifiable progress this flow has been blocked on since
its inception. The user then received real Apple review feedback on that build and asked for it to
be corrected.

#### Completed

- Reconciled the timeline: Codex's 2026-08-04 log entry shows zero usable local credentials at that
  time, so the real upload must have happened afterward, entirely through the Xcode GUI path, not
  through fastlane — explaining why no agent-visible log recorded the upload itself, only its
  aftermath (Apple's review email).
- Read Apple's real rejection feedback in full:
  - `ITMS-90683` (required): missing `NSPhotoLibraryUsageDescription`.
  - `ITMS-90683` (required): missing `NSCameraUsageDescription`.
  - `ITMS-90068` (advisory): `MinimumOSVersion` 13.0, must be ≥15.0 by Spring 2027.
  - `ITMS-90683` (advisory): missing `NSLocationWhenInUseUsageDescription`.
- Confirmed root cause by cross-referencing earlier session findings: `file_picker`'s iOS
  implementation transitively pulls in `DKImagePickerController`/`DKCamera` pods (seen in resolved
  Swift Package dependencies during this broader session's local build work), which link Photo
  Library/Camera/Location APIs even though Comics Editor's own code only calls
  `FilePicker.pickFiles(type: FileType.image, withData: true)` — Apple's static analysis flags the
  linked API regardless of whether the app's own code path invokes it.
- Edited `apps/comics-editor/ios/Runner/Info.plist`: added `NSPhotoLibraryUsageDescription` and
  `NSCameraUsageDescription` (both required, user-facing strings honestly scoped to the app's real
  behavior — choosing layer/balloon artwork), and `NSLocationWhenInUseUsageDescription` (not yet
  required, but same root cause — string honestly states the app doesn't use location and the key
  exists only because of a bundled dependency, rather than fabricating a plausible-sounding but
  false justification). Validated with `plutil -lint` → `OK`.
- Deliberately did **not** touch `macos/Runner/Info.plist` despite the same keys being absent there:
  no `macos/Podfile.lock` exists yet in this checkout (macOS has never resolved CocoaPods
  dependencies), so there is no evidence macOS's `file_picker` implementation links the same
  UIKit-only pods (macOS almost certainly uses `NSOpenPanel`, not `DKImagePickerController`) — an
  unverified guess would risk adding meaningless boilerplate or, worse, missing the real macOS-side
  requirement if one actually exists. Flagged to the user as worth rechecking when a real macOS
  submission is attempted.
- Left `MinimumOSVersion` (13.0) untouched — Apple marked it advisory only, deadline is Spring 2027,
  and raising it would drop support for older devices, a real product decision outside this fix's
  scope; not silently bumped.
- Confirmed Apple's feedback (Version 3.2.1, Build 1) matched `apps/comics-editor/pubspec.yaml`'s
  pre-edit value (`3.2.1+1`) exactly. Bumped it to `3.2.1+2` — App Store Connect rejects re-uploads
  that reuse a build number, so this is required before any next archive/upload attempt, independent
  of whether the Info.plist fix itself is correct.
- Ran `flutter analyze` from `apps/comics-editor/` after each edit — 0 issues both times.
- Discovered mid-session that `flows/` had been reorganized into per-app subdirectories
  (`flows/comics-editor/sdd-comics-editor-publish/`) outside any logged session; adapted by using
  the new path for this and all subsequent reads/writes.

#### Deviations from plan

None — this is a corrective fix to real reviewer feedback on the first real submission, not new
scope. No fastlane/CI files were touched (the actual successful upload bypassed fastlane entirely
via the local Xcode path), so the still-unverified match-free `Fastfile` rework from the prior
session remains exactly as unverified as before — this session doesn't change that status either
way.

**Ended at**: `Info.plist` fix and version bump complete, `flutter analyze` clean. Ready for the
user's next Xcode archive + upload attempt (same local GUI path that produced the first successful
submission). No further agent action possible until the user re-submits and either passes review or
receives new feedback.

**Note**: a subsequent same-day session mistakenly logged real `build.yml` (Native Build) CI-failure
fixes here. That work — `flutter analyze`/`dialogs.dart`, Linux `desktop-file-validate` ordering,
Android Gradle diagnosis, macOS `build-macos` signing — is `.github/workflows/build.yml` scope,
which belongs to `sdd-comics-editor-build`, not this flow (this flow owns `release.yml`/fastlane
only, per Context Notes above). Moved to
`flows/comics-editor/sdd-comics-editor-build/04-implementation-log.md` (2026-08-07 correction).

---

### Session 2026-08-07 (3rd same day) — Claude (real local CLI archive + direct App Store upload)

**Started at**: user asked to build locally and submit the iOS Archive to the App Store — first time
this whole flow used a pure CLI path (`flutter build ipa` + `xcodebuild -exportArchive
destination:upload`) instead of the Xcode Organizer GUI that produced the original Version 3.2.1
Build 1 upload.

#### Completed

- Confirmed working tree clean at commit `d08c357` before starting — no uncommitted changes to
  account for.
- **Real discrepancy found and resolved before uploading**: the archive's own "App Settings
  Validation" output showed Bundle Identifier `net.nativemind.comicseditor` (no dots) — different
  from `net.nativemind.comics.editor` (with dots) referenced throughout this flow's own
  `ios/fastlane/Fastfile` comments and earlier session log entries. Traced via `git log -p` on
  `project.pbxproj`: the real bundle id was renamed from `net.nativemind.comics.editor` to
  `net.nativemind.comicseditor` in an earlier commit (`5885105`), **before** the Version 3.2.1+1
  commit (`178999f`) that produced the real, already-reviewed Version 3.2.1 Build 1 submission —
  meaning `comicseditor` (no dots) has been the real, correct, already-registered App Store Connect
  bundle id all along, and this flow's own Fastfile/log comments referencing the dotted form were
  simply stale. Confirmed no risk of targeting a nonexistent/wrong app record before proceeding.
  (Follow-up: `ios/fastlane/Fastfile`'s comments and the earlier session log's Bundle ID references
  are now known-stale and should be corrected next time that file is touched — not done in this
  session, out of scope for a build-and-submit request.)
- **Also discovered**: `pubspec.yaml` version is now `3.2.2+3`, not the `3.2.1+2` this flow set in
  the earlier same-day session — real product work happened outside any logged session (commit
  `faf2e23`, by the user, message says "3.2.1+2" but the actual diff jumps straight to `3.2.2+3`,
  skipping build 2 entirely — likely an untracked local build/archive attempt in between). Build 3
  is safely higher than the last real upload's Build 1, so no duplicate-build-number risk.
- Ran `flutter build ipa --release --export-method app-store`: Dart AOT + Xcode archive + IPA export,
  fully automatic signing using `DEVELOPMENT_TEAM = 6XT4R7V83F` already in the project — succeeded
  without any manual credential setup (`build/ios/archive/Runner.xcarchive`, 191.3MB;
  `build/ios/ipa/*.ipa`, 23.4MB). Only warning: default placeholder launch image (pre-existing,
  unrelated, not a new issue).
- **Real direct upload from CLI (new territory for this flow)**: rather than using
  `flutter build ipa`'s local-export-only result (which would still require the Transporter app or
  `altool` + an API key I don't have locally), wrote a custom `ExportOptions.plist` with
  `destination: upload` and re-ran `xcodebuild -exportArchive -allowProvisioningUpdates` against the
  same archive. This performs the export **and** upload in one step using Xcode's own already-signed-in
  account session — the exact mechanism the Organizer GUI's "Distribute App → Upload" uses under the
  hood, just invoked from the command line. **Real result: `Upload succeeded.` / `EXPORT SUCCEEDED`.**
  Comics Editor Version 3.2.2, Build 3 is now uploaded to App Store Connect and processing.

#### Deviations from plan

None — direct execution of the user's explicit request. Notable: this is the first time this flow's
publishing work has gone through a pure CLI path end-to-end (no Xcode GUI, no fastlane/match either)
and it worked on the first attempt, using only the automatic-signing state already established on
this machine from the earlier local Xcode setup work.

**Ended at**: real upload complete and confirmed by `xcodebuild`'s own success output. Next step is
entirely the user's / Apple's: wait for App Store Connect processing to finish, then check for
review feedback (same cycle as Build 1) or submit for review if no issues are flagged. No further
agent action needed unless new feedback arrives.

---

### Session 2026-08-07 (4th same day) — Claude (real local CLI archive + direct macOS App Store upload — first ever, real bug found and fixed)

**Started at**: user asked to do for macOS what the previous session just did for iOS — build locally
and submit the Archive to the App Store. This flow's `macos/fastlane/Fastfile` had never been run for
real (documented as "the least-verified part of the whole flow"); this session is the very first real
attempt at a Mac App Store submission for this app.

#### Completed

- Confirmed clean-enough working tree (only the iOS `project.pbxproj` upgrade from the prior session
  was dirty, expected and unrelated).
- `xcodebuild archive` (workspace `macos/Runner.xcworkspace`, scheme `Runner`, Release) — succeeded,
  automatic signing during archive resolved to a local "Apple Development" identity (fine — this is
  intermediate, replaced at export/upload time).
- Embedded the headless C# core **into the archive itself** (not a plain `flutter build macos` output
  dir): `dotnet publish native/Comics.Editor.Headless/Comics.Editor.Headless.csproj -r osx-arm64
  --self-contained` + copied into
  `Runner.xcarchive/Products/Applications/comics_editor.app/Contents/Resources/comics-core/` —
  matching the exact "core must be embedded before final distribution signing" constraint the Fastfile
  itself documents at length.
- First `xcodebuild -exportArchive` attempt (custom `ExportOptions.plist`, `method:
  app-store-connect`, `destination: upload`, `-allowProvisioningUpdates` — same direct-upload technique
  proven for iOS this same day) — **archive, signing, .pkg build, and upload to Apple's server all
  succeeded**, further than this flow has ever gotten for macOS. Failed only at Apple's **server-side**
  validation (code 90296): `App sandbox not enabled ... Contents/Resources/comics-core/Comics.Editor`.
- **Real, previously-undiscovered bug found**: Apple's Mac App Store validator checks every Mach-O
  executable in the bundle individually for `com.apple.security.app-sandbox = true` in its own
  entitlements — not just the top-level app. The bundled self-contained `.NET` headless core (launched
  as a subprocess by the sandboxed main app) had no entitlements of its own at all. This would have
  blocked `macos/fastlane/Fastfile`'s own lane too, had it ever been run for real, since that lane's
  final `codesign --force --deep --sign` step does not touch loose executables sitting in `Resources/`
  (confirmed empirically — see below).
  - Presented the fix options to the user rather than guessing at a production entitlements change,
    since it's a product-correctness question, not just packaging: **`com.apple.security.inherit`
    alone** (correct pattern for a subprocess sharing the parent's sandbox container, but doesn't
    literally match what Apple's validator asks for) vs. **`com.apple.security.app-sandbox=true`
    alone** (matches the validator literally, but as a separately-sandboxed process could lose access
    to files the parent already has permission for) vs. stop and investigate further. User chose
    `inherit` first.
  - **Empirically tested `inherit` alone**: re-signed the nested `Comics.Editor` with just
    `com.apple.security.inherit=true`, re-ran the same export/upload — **identical failure, verbatim
    same error**. This proves Apple's validator does a literal key check for `app-sandbox`, not a
    semantic "is this sandboxed somehow" check, and also incidentally proves the nested signature
    *does* survive `xcodebuild -exportArchive`'s own re-signing pass (same specific error each time,
    not a generic "unsigned" error).
  - **Combined both entitlements** (`app-sandbox=true` + `inherit=true` together — the standard real-
    world pattern for exactly this "loose helper executable, not an XPC service" case, satisfying the
    validator's literal check while still sharing the parent's sandbox container at runtime): re-signed,
    re-exported. **Real result: `Upload succeeded.` / `EXPORT SUCCEEDED`.** Comics Editor's macOS build
    (same Version 3.2.2, Build 3 as the iOS submission this same day) is now uploaded to App Store
    Connect and processing — **the first real Mac App Store submission this app has ever had.**
  - Minor non-blocking warning both times: "Upload Symbols Failed... archive did not include a dSYM
    for Comics.Editor" — crash symbolication for that one native binary won't be available; not a
    blocker, not investigated further (out of scope for a build-and-submit request).
- **Persisted the fix for future builds** (this would have silently blocked every future attempt,
  local or CI, otherwise):
  - New file `macos/Runner/HeadlessCore.entitlements` — the exact two-key combination that produced
    the real successful upload.
  - Updated `macos/fastlane/Fastfile`: inserted a new signing step for the nested `Comics.Editor`
    binary (using `HeadlessCore.entitlements` + the same `3rd Party Mac Developer Application`
    identity already resolved for the whole app) positioned **before** the existing final `codesign
    --force --deep --sign` of the whole `.app` — order matters and is now documented inline: signing
    the nested binary first means the outer app's resource seal (computed at final signing time)
    already reflects its correct signed state; the reverse order would invalidate the outer seal.
    This part (the Fastfile edit) is **not independently re-verified by a real fastlane run** — the
    entitlements combination itself IS proven by the real upload above, but I haven't re-run the
    Fastfile's own codepath (no local ASC API key) to confirm the exact insertion point behaves
    identically to the `xcodebuild -exportArchive` path I actually tested.

#### Deviations from plan

None — direct execution of the user's explicit request, with one necessary pause (`AskUserQuestion`)
given the entitlements choice was a real product-correctness call, not a guessable build-config tweak.

**Ended at**: real macOS upload complete and confirmed by `xcodebuild`'s own success output, root
cause fully diagnosed and fixed, fix persisted to the repo (`HeadlessCore.entitlements` +
`macos/fastlane/Fastfile`) so it doesn't have to be rediscovered next time. Next step is entirely the
user's / Apple's: wait for App Store Connect processing, then handle review feedback if any (this is
the *first* real macOS submission, so unlike iOS there's no prior feedback cycle to compare against —
expect this one could get its own fresh round of reviewer notes, possibly about `MinimumOSVersion` or
other items not yet checked for macOS specifically). Separate macOS App Store Connect app record
existence was never independently confirmed this session — if the upload's "processing" step
eventually errors about a missing app record, that's the next thing to set up (per
`macos/fastlane/Fastfile`'s own "Перед первым релизом" checklist, item 1).
