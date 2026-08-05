# Implementation Log: flutter-comics-viewer-example-build

> Status: IMPLEMENTED — external verification blockers remain  
> Started: 2026-08-05  
> Plan: [03-plan.md](03-plan.md)

## Progress Tracker

- [x] Requirements, specifications and plan approved.
- [x] Baseline captured.
- [x] Local wrappers implemented and checked.
- [x] README updated.
- [x] GitHub Actions workflow implemented and checked.
- [x] Local validation and feasible host builds attempted.
- [x] Final safety review completed.
- [ ] All six CI jobs proven green; iOS upstream currently fails and Linux/
  Windows require GitHub runners.

## Session Log

### 2026-08-05 — Baseline

- Outer repository already contains unrelated user changes; they are preserved.
- Nested `libs/comics_viewer/flutter_comics_viewer` repository initially has
  only untracked `example/android/build/`; it is user-owned and must remain
  untouched.
- `flutter` resolves to `/Users/anton/development/flutter/bin/flutter`.
- `pwsh` and `actionlint` are not installed locally.
- A sandboxed `flutter --version` attempt failed because Flutter tried to update
  its SDK cache outside the writable workspace. Verification will use the
  already approved `flutter` execution permission.

### 2026-08-05 — Wrappers, documentation and workflow

- Created executable `tool/build-example.sh` with strict error handling,
  host/target validation, deterministic `all`, Android sibling validation and
  approved build commands.
- Created `tool/build-example.ps1` with the equivalent Windows contract.
- Replaced the generated example README with prerequisites, repository layout,
  wrapper/direct commands, outputs, validation scope and limitations.
- Added `.github/workflows/example-build.yml` with the approved triggers,
  read-only permissions, Flutter 3.44.6, one validation job, six independent
  platform jobs and six 14-day artifacts.
- Static wrapper checks passed: `bash -n`; no argument and unknown target return
  64; unsupported macOS/Linux target combination returns 69.
- PowerShell runtime parsing was not available because `pwsh` is not installed;
  the script was reviewed for command/path symmetry.
- Ruby YAML parsing passed. The workflow contains exactly seven jobs and six
  `actions/upload-artifact@v4` steps, with no `needs`, integration-test gate or
  publish permissions.
- During the session an external actor committed these files plus Flutter-
  generated registrants as nested-repository commit `26c2c0f`. Codex did not
  run commit or push. Subsequent native build fixes remain uncommitted.

### 2026-08-05 — Validation

- `flutter --version`: Flutter 3.44.6, Dart 3.12.2, revision `ee80f08bbf`.
- `flutter pub get`: passed; four newer incompatible package versions reported
  informationally.
- Initial strict format check found `example/lib/main.dart`; applied `dart
  format lib test`. Recheck passed with 0 changed files.
- `flutter analyze lib test`: passed with no issues (final rerun).
- `flutter test test`: passed, 1 test (final rerun).
- `swift package dump-package --package-path macos/flutter_comics_viewer`:
  passed; package `flutter_comics_viewer`, product
  `flutter-comics-viewer`, macOS 10.15.
- `actionlint` was unavailable. YAML syntax and workflow invariants were checked
  with Ruby, `rg`, and manual review.

### 2026-08-05 — Local builds and necessary build-only fixes

Successful wrapper builds:

- Web release: `example/build/web`.
- macOS release: `example/build/macos/Build/Products/Release/viewer_example.app`
  (38.2 MB app; local Xcode 26.6).
- Android release: `example/build/app/outputs/flutter-apk/app-release.apk`
  (43.6 MB).

Non-material deviations required to make approved builds executable:

1. `example/lib/main.dart` received formatter-only wrapping for the CI format
   gate.
2. The stale macOS plugin scaffold `macos/viewer`/`viewer.podspec` was renamed
   to the package name Flutter 3.44.6 requires:
   `macos/flutter_comics_viewer`/`flutter_comics_viewer.podspec`. Swift class and
   method-channel behavior are unchanged.
3. Added the Android sibling project to `example/android/settings.gradle.kts`,
   because a consumed Flutter plugin's own settings file is not evaluated by
   the example Gradle root.
4. Removed the obsolete Android manifest `package` attribute; namespace remains
   defined in Gradle as required by AGP 9.
5. Replaced unresolved `ScrollView.LayoutParams` references with the equivalent
   `FrameLayout.LayoutParams` accepted by the current Kotlin compiler.

Android still emits non-fatal warnings about the sibling library's legacy
Kotlin Gradle plugin and Java 8 source/target level. These are future migration
work, not current build failures.

### 2026-08-05 — External blocker

The unsigned iOS simulator build reached the remote
`comics108/comics-viewer-ios` Swift package, proving Flutter/SwiftPM plugin
wiring works, but that package's current `main` branch fails compilation. Errors
include duplicate `getCurrentScrollView()`, missing `ArchiveManager.loadComics`,
missing `Comics.setPreview`/`setSoundEnabled`/`dispose`, and incompatible
`setScrollOffset` calls.

The approved specification explicitly keeps branch `main` and defers dependency
pinning, so the implementation did not mask the job, edit the external
repository, or choose an unapproved commit. The GitHub iOS job will correctly
remain red until the upstream branch is repaired or a new SDD decision approves
pinning.

Linux and Windows builds were not locally executable on macOS. Their commands,
runner selection and artifact paths are present in the workflow and await an
Actions run.

### 2026-08-05 — Safety review

- `git diff --check`: passed in the nested repository.
- Existing `.github/workflows/build.yml` and `publish.yml`: no diff.
- Generated SwiftPM resolution files from the failed iOS attempt were removed.
- The Gradle problems report was restored to its committed contents after local
  Android verification changed its requested-task metadata.
- No cleanup, signing, publishing, commit, push or release command was run.
