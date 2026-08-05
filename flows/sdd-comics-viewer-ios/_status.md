# Status: sdd-comics-viewer-ios

## Current Phase

REQUIREMENTS

## Phase Status

REVIEW

## Last Updated

2026-08-05 by Codex

## Blockers

- Waiting for explicit requirements approval or corrections.

## Progress

- [x] Requirements drafted
- [ ] Requirements approved
- [ ] Specifications drafted
- [ ] Specifications approved
- [ ] Plan drafted
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
- No implementation, specification design, commits, pushes, tags, or releases have been performed.

## Fork History

- None. This is a new flow informed by the completed `sdd-flutter-comics-viewer-example-build` integration diagnosis.

## Next Actions

1. Receive `requirements approved` / `reqs approved`, or incorporate requested corrections to the aligned requirements v1.1.
2. Draft architectural specifications only after approval.
