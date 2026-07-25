# Status: sdd-comics-viewer

## Current Phase

IMPLEMENTATION (in progress)

## Phase Status

IN_PROGRESS

## Last Updated

2026-07-23 by Claude (Phase 3.1 Android app wired to comics-viewer-android; both build and boot-verified)

## Blockers

- None. One item needs a human with real backend access: SplashActivity in mahabharata-mobile-java-v2026 blocks on a network call to comics.dev.ironwaterstudio.com before reaching any comics/puzzle screen, which isn't reachable from this sandbox — so the sound/language/puzzle behavior changes in 3.1 are verified by code inspection + clean build/boot, not by actually seeing/hearing them run.

## Progress

- [x] Requirements drafted
- [x] Requirements approved
- [x] Specifications drafted
- [x] Specifications approved
- [x] Plan drafted
- [x] Plan approved
- [x] Implementation started
- [x] Phase 1: Android Library (100% complete) ✅ — `./gradlew build` passes (assemble debug+release, unit tests, lint)
- [x] Phase 2: iOS Swift Package (100% complete) ✅
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
- Code must be moved (NOT rewritten) with only minor fixes for paths and bundle IDs
- Bundle ID Strategy: Option C - Framework-specific prefixes
  - Core: net.nativemind.comics.viewer
  - Flutter: net.nativemind.flutter.comics.viewer
  - React Native: net.nativemind.rn.comics.viewer
- Puzzle functionality included in same library as comics

## Fork History

N/A - New SDD flow

## Next Actions

1. Human verification of mahabharata-mobile-java-v2026 on a device/emulator with real backend access: confirm comics viewing, puzzle viewing, sound toggle, and language switching all still behave as before (the code changes are in place and build/boot-verified, but not audibly/visually exercised — see Blockers).
2. Complete Phase 3.2 manual Xcode steps for mahabharata-mobile-swift-v2026 (add SPM dependency, remove stale file references, build/run).
3. Build and run the Flutter (`flutter_comics_viewer`) and React Native (`react-native-comics-viewer`) example apps end-to-end on Android/iOS — Phases 4/5 have code but were never actually built/run.
4. Phase 6: cross-platform validation once 1-3 are done.
