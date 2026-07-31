# Status: sdd-comics-editor-publish

## Current Phase

IMPLEMENTATION

## Phase Status

Starting Phase 1 (README screenshots)

## Last Updated

2026-07-31 by Claude

## Blockers

- None. All requirements decisions resolved 2026-07-31 (locale scope: ru/en-US/zh-Hans/hi/th;
  `pc-01` → new macOS App Store lane via `match`; `design/dc/screenshots` → README). Only remaining
  open item (README image subset) is a Specifications-phase judgment call, not a blocker.

## Progress

- [x] Requirements drafted (2026-07-31) — `01-requirements.md`
- [x] Requirements approved (2026-07-31)
- [x] Specifications drafted (2026-07-31) — `02-specifications.md`
- [x] Specifications approved (2026-07-31)
- [x] Plan drafted (2026-07-31) — `03-plan.md`, 4 independent phases (README, iOS, Android, macOS)
- [x] Plan approved (2026-07-31) — all 4 phases, including macOS lane
- [x] Implementation started (2026-07-31)
- [ ] Implementation complete
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
  is a *different app's* config (Bhagavad Gita, `com.ethnoapp.bgita`) kept intentionally as a
  **structural example** per the user — not a bug, not something to delete/modify in this flow.
  Its own `screenshots/`/`metadata/` are populated with locale folders (useful for the *shape* to
  follow) but the screenshot subfolders themselves are empty (no filled-in naming example) — real
  screenshot placement follows fastlane's own (`deliver`/`supply`) documented conventions.
- Real source assets already exist and were verified pixel-exact via `sips`: `design/store/`
  (`appstore-01/02-1290x2796.png` → iOS, `googleplay-01-1440x2560.png` + `googleplay-cover-
  1024x500.png` → Android — see `01-requirements.md`'s Investigation Findings for the full
  mapping). `design/dc/screenshots/*.png` (924x540) and `design/store/pc-01-1440x900.png` don't
  cleanly map to either store's screenshot requirements under current scope (no macOS release lane
  exists at all) — flagged as open questions, not silently dropped or silently force-fit somewhere.

## Fork History

N/A — new flow, not a fork (see Context Notes for the flow it was split out of).

## Next Actions

1. Get answers to `01-requirements.md`'s 3 Open Questions (locale scope; disposition of
   `pc-01`/`design/dc` screenshots; whether the single-size iOS screenshot coverage gap needs to be
   flagged as a follow-up or is acceptable as-is).
2. "Requirements approved" from user.
3. Move to Specifications: exact target paths/filenames for both fastlane screenshot directories,
   exact `Fastfile` diffs to un-skip screenshot upload, whether `Deliverfile`/other config needs
   updating too.
