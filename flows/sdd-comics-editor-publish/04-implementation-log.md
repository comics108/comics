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
