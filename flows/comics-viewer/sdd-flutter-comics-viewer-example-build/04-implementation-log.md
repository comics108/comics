# Implementation Log: flutter-comics-viewer-example-build

> Status: IMPLEMENTED LOCALLY — patched CI rerun and upstream iOS fix remain
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
- [ ] All six CI jobs proven green; the first observed Actions run exposed
  Linux/Windows build integration defects and an iOS runner/upstream failure.

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
runner selection and artifact paths are present in the workflow.

### 2026-08-05 — First GitHub Actions execution and follow-up fixes

Observed push run
[`30975574221`](https://github.com/comics108/flutter_comics_viewer/actions/runs/30975574221)
for nested-repository commit `6123669c5348afdaa9e6985976223569207f20db`.
It completed with these independent results:

- passed: `validate-example`, `build-android`, `build-macos`, `build-web`;
- failed: `build-linux`, `build-windows`, `build-ios`.

Uploaded artifacts were proven for Android, macOS and Web. Failure diagnosis and
local corrections:

1. Linux generated CMake links `${plugin}_plugin`, which resolves to
   `flutter_comics_viewer_plugin`, while the plugin declared `viewer_plugin`.
   Linux and Windows plugin project/target/bundled-library names now follow the
   Flutter package name expected by generated build rules.
2. Windows release configuration fetched the scaffold's GoogleTest 1.11 and
   failed under runner CMake 4 before compiling the app. Example consumer builds
   no longer opt into native plugin test targets; Dart/widget tests remain in
   the validation gate.
3. iOS selected `/Applications/Xcode_16.app`, but that runner installation did
   not have the requested iOS 18 simulator platform. The iOS job now uses the
   runner-selected Xcode/SDK and reports its version instead of forcing an
   incompatible installation. A local Xcode 26.6 build then independently
   confirmed the remaining remote `comics-viewer-ios/main` source errors.

Ruby YAML parsing and `git diff --check` pass after these changes. Linux and
Windows need a new Actions run after commit/push. Per the approved Git constraint,
Codex did not create a commit or push the patched workflow.

### 2026-08-05 — iOS upstream re-verification

`comics108/comics-viewer-ios/main` advanced from `8337b59` to `4cd96df` and its
local checkout is clean and equal to the remote branch. The first repeat build
still compiled `8337b59` because both tracked Xcode `Package.resolved` files
pinned that revision. Resolving from a fresh SwiftPM clone cache updated the
dependency graph to:

- `comics-viewer-ios` `4cd96df` on branch `main`;
- ZIPFoundation `0.9.20` (`22787ff`).

The former upstream Swift errors disappeared. Compilation then exposed a local
SwiftPM module mismatch: the package product built legacy target `viewer`, but
Flutter's generated registrant imports `flutter_comics_viewer`; the current
plugin source already lives under `Sources/flutter_comics_viewer`. Updating the
product target to `flutter_comics_viewer` and synchronizing both tracked lockfiles
fixed the integration without changing runtime API or UI.

Final command `./tool/build-example.sh ios` passed with local Xcode 26.6 and
produced `example/build/ios/iphonesimulator/Runner.app` (139 MB). Only the
non-fatal missing example build name/number warning remains; this unsigned
simulator verification build is not an App Store submission.

### 2026-08-05 — Second GitHub Actions execution

An external actor committed the first CMake/workflow corrections as `6d0996d`;
Codex did not create that commit or push it. Push run
[`30976166970`](https://github.com/comics108/flutter_comics_viewer/actions/runs/30976166970)
again passed validation, Android, macOS and Web. It provided two additional
native diagnostics:

- Linux and Windows generated registrants include package-namespaced headers
  `flutter_comics_viewer/viewer_plugin.h` and
  `flutter_comics_viewer/viewer_plugin_c_api.h`, while the legacy public headers
  remain under `include/viewer`. Two forwarding headers were added under the
  generated package namespace, preserving the existing C/C++ API.
- iOS used Xcode 16.4 successfully but still consumed the then-committed
  `8337b59` lockfile, producing its old duplicate-method error. The subsequent
  local lockfile update to `4cd96df` and Swift target alignment are not part of
  this run; the local green build verifies those follow-up changes.

A third Actions execution is required after the current iOS lock/target and
desktop forwarding-header changes are committed and pushed.

### 2026-08-05 — Attached iPhone smoke run

Flutter detected `Anton iPhone` (`iOS 15.8.4`) over USB. The first signed debug
deployment built, installed and launched, but the example's legacy `Viewer` API
called method channel `viewer` while the current iOS plugin registered only
`flutter_comics_viewer`, causing `MissingPluginException`. The iOS registrar now
registers the same plugin instance on both the current and legacy channels.

The second `flutter run -d 028bf5298942f7cfa1e9585d304fbb181750b046
--debug` passed code signing with the saved Apple Development identity, installed
and launched on the physical phone, connected the Dart VM Service, and emitted
no plugin/runtime exception. Flutter CLI was detached so the installed app could
remain on the device.

### 2026-08-05 — Safety review

- `git diff --check`: passed in the nested repository.
- Existing `.github/workflows/build.yml` and `publish.yml`: no diff.
- Both tracked SwiftPM resolution files are synchronized to the verified
  upstream revision and ZIPFoundation dependency.
- The Gradle problems report was restored to its committed contents after local
  Android verification changed its requested-task metadata.
- No cleanup, signing, publishing, commit, push or release command was run.
