# Status: sdd-comics-viewer

## Cross-reference (2026-08-08/10, disclosed, added by `flows/comics-viewer/sdd-flutter-comics-viewer-dart`)

Two sibling flows modified files this flow owns (`libs/comics_viewer/flutter_comics_viewer`) after this
flow's own status here was last updated (2026-08-05):

- `flows/sdd-flutter-comics` rewrote `dart_comics_viewer_backend.dart`/`dart_comics_viewer_surface.dart`
  to consume a new shared `libs/flutter_comics` package instead of this file's own duplicate model —
  this also **resolved** this doc's own Blockers line about
  `test/dart_comics_viewer_backend_test.dart:14`'s `List<int>`/`Uint8List` compile error (confirmed:
  that file compiles and passes cleanly as of 2026-08-08).
- `flows/comics-viewer/sdd-flutter-comics-viewer-dart` (this note's author) added real sound playback
  to the same backend (`_evaluateSounds`, `SoundPlaybackTrack` in a new `sound_playback.dart`, real
  `setSoundEnabled`/`setMuted`/`dispose`) — previously no-ops. Also fixed an unrelated regression found
  along the way: this package's `pubspec.yaml` `flutter_comics` dependency was malformed, breaking
  `flutter pub get` outright.
- The same Dart-viewer flow's v1.1 continuation now makes visual animation, sound, camera sampling,
  and strip movement share one measured document-space scroll offset; applies shared z-depth camera
  adjustment once per layer; verifies full v2012/v2026 fixtures; and updates the example to switch
  between both archives. Package tests are 33/33, example widget tests 3/3, Web build passes, and the
  macOS dual-fixture integration test passes. Native Android/iOS and Windows WPF code remain unchanged.

Neither sibling flow's own Plan/Specifications attempted to reconcile this flow's broader,
still-stale Progress/Blockers below (Android/iOS native-app integration, React Native wrapper, Phase 6
validation) — those remain this flow's own responsibility to update when it resumes.

## Current Phase

IMPLEMENTATION (in progress)

## Phase Status

IN_PROGRESS

## Last Updated

2026-08-05 by Codex (iOS package regression reconciled with child flow `sdd-comics-viewer-ios`)

## Blockers

- The iOS Swift Package regression is repaired and verified locally in `flows/sdd-comics-viewer-ios/`; authoritative Flutter iOS acceptance now waits for a separately authorized landing of that revision on the remote `main` branch consumed by SwiftPM.
- One item needs a human with real backend access: SplashActivity in mahabharata-mobile-java-v2026 blocks on a network call to comics.dev.ironwaterstudio.com before reaching any comics/puzzle screen, which isn't reachable from this sandbox — so the sound/language/puzzle behavior changes in 3.1 are verified by code inspection + clean build/boot, not by actually seeing/hearing them run.

## Progress

- [x] Requirements drafted
- [x] Requirements approved
- [x] Specifications drafted
- [x] Specifications approved
- [x] Plan drafted
- [x] Plan approved
- [x] Implementation started
- [x] Phase 1: Android Library (100% complete) ✅ — `./gradlew build` passes (assemble debug+release, unit tests, lint)
- [~] Phase 2: iOS Swift Package extraction and local build recovery complete; remote landing/consumer acceptance tracked by `sdd-comics-viewer-ios`
- [~] Phase 3: Update Native Apps
  - [x] 3.1 Android app: wired to comics-viewer-android, ~22 duplicate files deleted, ~10 consumer files updated, Settings/soundEnabled/languageIndex sync gaps bridged (see 04-implementation-log.md). `assembleDevDebug`/`assembleDevRelease` (R8) both build; installed+launched on emulator with no crash. Real device/backend testing of actual comics+puzzle screens still needed (network-gated splash blocks further nav in this sandbox). ← current
  - [x] 3.2 iOS app: imports added, migrated files deleted, integration guide written; manual Xcode steps (add SPM dependency, remove red file refs, build/run) still pending — cannot be done headlessly
- [~] Phase 4: Flutter Wrapper — Dart API + Android/iOS native bridge code written per plan, but never built/run end-to-end (4.3.2/4.3.3 device tests not done)
- [~] Phase 5: React Native Wrapper — TS API + Android/iOS native module code written per plan, but never built/run end-to-end (5.3.2/5.3.3 device tests not done)
- [ ] Phase 6: Validation & Testing (not started)
- [ ] Implementation complete

## Context Notes

Key decisions and context for resuming:

- This is an architecture restructuring project to extract comics and puzzle rendering into standalone Android Library and iOS Swift Package
- Existing analysis from sdd-flutter-comics-viewer and sdd-flutter-puzzle-viewer will be leveraged
- `sdd-comics-viewer` is authoritative over the earlier `sdd-flutter-comics-viewer` wherever their architectural directions differ; the implemented architecture remains native-first.
- Code must be moved (NOT rewritten) with only minor fixes for paths and bundle IDs
- Bundle ID Strategy: Option C - Framework-specific prefixes
  - Core: net.nativemind.comics.viewer
  - Flutter: net.nativemind.flutter.comics.viewer
  - React Native: net.nativemind.rn.comics.viewer
- Puzzle functionality included in same library as comics

## Fork History

N/A - New SDD flow

## Next Actions

1. Review and separately authorize landing the locally verified `sdd-comics-viewer-ios` package revision on its remote `main` branch.
2. Complete main-plan tasks 4.3.3 and 5.3.3: build/run Flutter and React Native examples on iOS against that landed revision.
3. Complete Phase 3.2 manual Xcode steps for mahabharata-mobile-swift-v2026 (add SPM dependency, remove stale file references, build/run).
4. Human verification of mahabharata-mobile-java-v2026 on a device/emulator with real backend access: confirm comics viewing, puzzle viewing, sound toggle, and language switching all still behave as before.
5. Execute Phase 6.2.2 cross-platform validation once the platform-specific blockers above are cleared.
