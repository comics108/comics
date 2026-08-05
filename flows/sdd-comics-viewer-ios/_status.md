# Status: sdd-comics-viewer-ios

## Current Phase

PLAN

## Phase Status

REVIEW

## Last Updated

2026-08-05 by Codex

## Blockers

- Waiting for explicit implementation-plan approval or corrections.

## Progress

- [x] Requirements drafted
- [x] Requirements approved
- [x] Specifications drafted
- [x] Specifications approved
- [x] Plan drafted
- [ ] Plan approved
- [ ] Implementation started
- [ ] Implementation complete
- [ ] Documentation drafted
- [ ] Documentation approved

## Context Notes

- The flow directory follows the user's requested identifier exactly: `flows/sdd-comics-viewer-ios`.
- The nested `comics-viewer-ios` repository was clean at baseline, at commit `8337b59` on `main`.
- The observed iOS build failure is deterministic API drift in the Swift Package controllers, not a Flutter dependency-resolution failure.
- `ArchiveManager` currently exposes instance-based archive access, while controllers reference a nonexistent static loader.
- `Comics` exposes `process(scrollOffset:)` and `hasPreview()` but not the facade methods referenced by the controllers.
- `PuzzleViewerController` contains a private/public method-signature collision.
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
- Local planning toolchain observed: Swift 6.3.3 and Xcode 26.6; CI remains aligned to its supported macOS 15/Xcode 16 image unless execution disproves availability.
- No implementation, commits, pushes, tags, or releases have been performed.

## Fork History

- None. This is a new flow informed by the completed `sdd-flutter-comics-viewer-example-build` integration diagnosis.

## Next Actions

1. Receive `plan approved`, or incorporate requested plan corrections.
2. Begin Task 0.1 only after explicit plan approval.
