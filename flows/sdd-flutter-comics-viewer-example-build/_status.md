# Status: sdd-flutter-comics-viewer-example-build

## Current Phase

IMPLEMENTATION

## Phase Status

IMPLEMENTED LOCALLY — patched CI rerun remains

## Last Updated

2026-08-05 by Codex

## Blockers

- The first Actions run exposed Linux/Windows CMake integration defects. They
  were partially fixed in externally-created commit `6d0996d`; its run then
  exposed missing package-namespaced forwarding headers. Those headers are now
  added locally and still require a rerun on GitHub-hosted runners.
- iOS is now locally green on upstream `comics-viewer-ios/main` revision
  `4cd96df`; the updated workflow and SwiftPM lockfiles still require the same
  post-push Actions rerun for CI confirmation.

## Progress

- [x] Requirements drafted
- [x] Requirements approved
- [x] Specifications drafted
- [x] Specifications approved
- [x] Plan drafted
- [x] Plan approved
- [x] Implementation started
- [ ] Implementation complete

## Context Notes

- User requested local and GitHub Actions builds for the Flutter viewer example.
- Actual path is `libs/comics_viewer/flutter_comics_viewer/example` (underscore),
  not `libs/comics-viewer/...`.
- `flutter_comics_viewer` is a separate git repository nested in the monorepo.
- Existing workflow validates the package and builds only Android+iOS examples.
- Android currently requires sibling `comics-viewer-android`; iOS uses remote
  `comics-viewer-ios` through SwiftPM.
- Example has generated targets for Android, iOS, Linux, macOS, Windows and Web.
- Existing integration test imports stale `package:viewer/viewer.dart`; do not
  make it a CI gate before requirements/specifications decide its scope.
- Existing untracked `example/android/build/` is user-owned and untouched.
- User approved requirements and recommended defaults Q1–Q8 on 2026-08-05.
- Specifications define wrappers, six platform jobs, validation, artifacts and
  pinned Flutter 3.44.6 without changing existing build/publish workflows.
- User approved specifications without corrections on 2026-08-05.
- Plan orders baseline checks, two wrappers, documentation, seven workflow jobs,
  feasible local builds, workflow validation and final safety review.
- User approved the plan without corrections on 2026-08-05.
- Baseline captured: nested repo has only user-owned untracked
  `example/android/build/`; `pwsh` and `actionlint` are unavailable locally.
- Initial sandboxed `flutter --version` could not update the external SDK cache;
  local Flutter checks must run with the approved command permission.
- Added wrappers, build README and a seven-job/six-artifact example workflow.
- An external actor committed those files as nested-repo commit `26c2c0f` during
  the session; Codex did not commit or push.
- Scoped format/analyze/test pass. Local Web, macOS and Android release builds
  pass with Flutter 3.44.6 after build-only packaging/wiring compatibility fixes.
- iOS upstream was rechecked at `4cd96df`; its former Swift errors are fixed.
  Both tracked SwiftPM lockfiles now resolve that commit and ZIPFoundation
  0.9.20. The local Swift package target was aligned with Flutter's expected
  `flutter_comics_viewer` module, after which the unsigned simulator build
  produced `Runner.app` successfully.
- Push run
  [`30975574221`](https://github.com/comics108/flutter_comics_viewer/actions/runs/30975574221)
  proved validation plus Android/macOS/Web jobs and artifact uploads green.
  Linux failed on the stale native target name, Windows on GoogleTest 1.11 with
  CMake 4, and iOS first on a forced Xcode installation lacking the simulator
  platform.
- Linux/Windows target naming and consumer test opt-in are fixed locally. iOS
  now uses the runner-selected Xcode/SDK and passes locally with Xcode 26.6.
- A signed debug build was installed and launched on the attached iPhone running
  iOS 15.8.4. A legacy `viewer` method-channel alias was added after the first
  run exposed a mismatch; the second run connected to the Dart VM Service with
  no runtime exception.
- Push run
  [`30976166970`](https://github.com/comics108/flutter_comics_viewer/actions/runs/30976166970)
  on `6d0996d` reconfirmed validation/Android/macOS/Web green. Linux/Windows
  reached compilation and failed only because their generated registrants use
  the package header namespace; forwarding headers now cover it. iOS in that
  run still used the old committed SwiftPM pin, predating the locally verified
  lock/target fixes.
- Implementation details and exact verification evidence are recorded in
  `04-implementation-log.md`.

## Fork History

- New flow created 2026-08-05; not forked.

## Next Actions

1. Commit/push the remaining nested-repository CMake/workflow compatibility
   fixes when explicitly desired, then rerun `Example Build`.
2. Confirm iOS, Linux and Windows jobs/artifacts on GitHub-hosted runners; then mark
   implementation complete.
