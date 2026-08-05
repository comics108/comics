# Status: sdd-comics-viewer

## Current Phase

IMPLEMENTATION (in progress)

## Phase Status

IN_PROGRESS

## Last Updated

2026-08-05 by Codex (iOS package regression reconciled with child flow `sdd-comics-viewer-ios`)

## Blockers

- iOS Swift Package `main` currently fails the Flutter iOS Simulator consumer build because its controller facade drifted from `ArchiveManager`/`Comics` APIs and contains a duplicate method signature. Corrective work is tracked in `flows/sdd-comics-viewer-ios/`; requirements and specifications are approved, and the implementation plan awaits approval.
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
- [~] Phase 2: iOS Swift Package extraction complete; current build regression tracked by `sdd-comics-viewer-ios`
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

1. Approve the implementation plan and execute `sdd-comics-viewer-ios` to restore the package build and unblock iOS consumers.
2. Complete main-plan tasks 4.3.3 and 5.3.3: build/run Flutter and React Native examples on iOS against the repaired package.
3. Complete Phase 3.2 manual Xcode steps for mahabharata-mobile-swift-v2026 (add SPM dependency, remove stale file references, build/run).
4. Human verification of mahabharata-mobile-java-v2026 on a device/emulator with real backend access: confirm comics viewing, puzzle viewing, sound toggle, and language switching all still behave as before.
5. Execute Phase 6.2.2 cross-platform validation once the platform-specific blockers above are cleared.
