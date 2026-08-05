# Status: sdd-comics-viewer-ios

## Current Phase

IMPLEMENTATION

## Phase Status

IN_PROGRESS

## Last Updated

2026-08-05 by Codex

## Blockers

- Package-local implementation has no blocker and passes macOS plus iOS Simulator builds/tests.
- Authoritative Flutter iOS build and manual simulator acceptance require a separately authorized commit/push of this package revision to the remote `main` branch consumed by SwiftPM.
- The concurrently edited Flutter package currently has an independent Dart test compile error at `test/dart_comics_viewer_backend_test.dart:14`; it is not caused by the preserved iOS facade.

## Progress

- [x] Requirements drafted
- [x] Requirements approved
- [x] Specifications drafted
- [x] Specifications approved
- [x] Plan drafted
- [x] Plan approved
- [x] Implementation started
- [ ] Implementation complete
- [x] Documentation drafted
- [ ] Documentation approved

## Context Notes

- The flow directory follows the user's requested identifier exactly: `flows/sdd-comics-viewer-ios`.
- The nested `comics-viewer-ios` repository was clean at baseline, at commit `8337b59` on `main`.
- The original iOS build failure was deterministic API drift in the Swift Package controllers, not a Flutter dependency-resolution failure.
- The repaired controllers now use owned archive sessions instead of the nonexistent static loader.
- Presentation operations now route through `ImageScrollView` while the persistent `Comics` model remains unchanged.
- The `PuzzleViewerController` private/public method-signature collision has been removed.
- The Flutter platform view is treated as the required external consumer contract.
- Alignment audit completed against `sdd-comics-viewer` and `sdd-flutter-comics-viewer`.
- `sdd-comics-viewer` is authoritative; `sdd-flutter-comics-viewer` is historical analysis where the two differ.
- This flow is the corrective slice that unblocks parent-plan tasks 4.3.3, 5.3.3, and 6.2.2.
- Inherited decisions resolve all scope questions: native-first renderer, archived `sample.comics`, puzzle in the core package, iOS 13 + macOS 10.15, unified facade, and no release.
- Requirements v1.1 explicitly approved by the user on 2026-08-05.
- Specifications place archive extraction in an owned session layer and presentation controls in `ImageScrollView`; the persistent models remain unchanged.
- Controller-driven resource resolution is session-scoped so multiple viewers/puzzle pieces cannot corrupt each other through `ArchiveManager.shared`.
- The specifications deferred the concrete ZIP package/version to planning; plan v1.0 selects ZIPFoundation without leaking it into public API.
- Specifications v1.0 were explicitly approved by the user on 2026-08-05.
- Plan v1.0 selects ZIPFoundation 0.9.20 with a patch-compatible range, defines archive safety limits, and separates local package validation from the post-landing remote Flutter gate.
- Plan v1.0 was explicitly approved by the user on 2026-08-05; implementation started from Task 0.1.
- Local planning toolchain observed: Swift 6.3.3 and Xcode 26.6; CI remains aligned to its supported macOS 15/Xcode 16 image unless execution disproves availability.
- Package-local Tasks 0.1–5.3 are implemented and verified: macOS build, 10 macOS tests, iOS test-target cross-compilation, generic iOS Simulator Xcode build, and 16 iOS Simulator XCTest cases all pass.
- Consumer API audit is complete for Flutter and React Native without bridge changes or a committed local-path override.
- No commits, pushes, tags, signing, or releases have been performed.

## Fork History

- None. This is a new flow informed by the completed `sdd-flutter-comics-viewer-example-build` integration diagnosis.

## Next Actions

1. Review and separately authorize landing the repaired `comics-viewer-ios` revision on remote `main`.
2. After landing, run `./tool/build-example.sh ios` and confirm the consumed remote revision plus the GitHub Actions `build-ios` job.
3. Run the Flutter simulator behavior checklist, then reconcile the remote/manual evidence and mark implementation complete.
