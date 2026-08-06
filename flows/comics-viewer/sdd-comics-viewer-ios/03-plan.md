# Implementation Plan: Comics Viewer iOS Package Build Recovery

> Version: 1.0  
> Status: APPROVED  
> Last Updated: 2026-08-05  
> Specifications: [02-specifications.md](02-specifications.md)

## Overview

Restore the `comics-viewer-ios` Swift Package in dependency order: establish a safe archive/session foundation, scope renderer resources to each session, repair the view/controller facade, cover comics and puzzle behavior, then validate the package and its Flutter/React Native consumers. The public facade and persisted archive models remain unchanged.

No release, tag, push, consumer local-path override, or native-app Xcode project surgery belongs to this plan. Remote Flutter acceptance occurs only after the repaired package commit is available on the branch consumed by SwiftPM.

## Planning Decisions

- Use `ZIPFoundation` from `https://github.com/weichsel/ZIPFoundation.git` with `.upToNextMinor(from: "0.9.20")`. The initial resolved version is `0.9.20`; the dependency stays internal to `ComicsViewer`.
- Keep Swift tools `5.9`, iOS `13`, and macOS `10.15` unchanged.
- Default `ImageScrollView.showPreview` to `true`, matching the legacy renderer that displayed all decoded layers until a consumer explicitly hides preview layers.
- Reject archives with more than 10,000 entries, any single declared uncompressed entry over 256 MiB, or more than 1 GiB total declared/extracted bytes. Enforce both metadata and bytes-written limits.
- Reject absolute paths, `..` traversal, paths escaping the session root after standardization, and symbolic-link entries. Require a regular root-level `data.json`.
- Perform file validation/extraction/JSON decoding off the main thread. Perform UIKit mutations and every public completion/callback on the main thread.
- Use monotonically increasing load generations to make latest-load-wins and dispose-vs-load races deterministic.
- Build behavior one focused test at a time where the platform allows it; retain a failing test only long enough to implement the corresponding behavior.

## Complexity Scale

- **XS**: under 30 minutes
- **S**: 30–60 minutes
- **M**: 1–2 hours
- **L**: 2–4 hours
- **XL**: more than 4 hours

## Phase 0: Baseline and Dependency Resolution

### Task 0.1: Record a Reproducible Baseline

- **Complexity:** S
- **Dependencies:** None
- **Files:**
  - `flows/sdd-comics-viewer-ios/04-implementation-log.md`
- **Actions:**
  - Confirm both the workspace and nested `comics-viewer-ios` repository status before edits.
  - Record `swift --version`, `xcodebuild -version`, current package commit, and the known controller compiler errors.
  - Record the checked-in Flutter `sample.comics` size, ZIP entry count, and SHA-256 without modifying it.
  - Route Swift/Clang module caches to a writable temporary directory when sandboxing prevents package inspection.
- **Verification:** Baseline commands, outputs, repository states, and sample hash are present in the implementation log.
- **Rollback:** Documentation-only; remove the appended baseline entry if incorrect.

### Task 0.2: Add the ZIP Dependency

- **Complexity:** S
- **Dependencies:** 0.1
- **Files:**
  - `libs/comics_viewer/comics-viewer-ios/Package.swift`
  - `libs/comics_viewer/comics-viewer-ios/Package.resolved` if SwiftPM generates a stable root lockfile for this package
- **Actions:**
  - Add `ZIPFoundation` with `.upToNextMinor(from: "0.9.20")` to the package and `ComicsViewer` target.
  - Add the product to the test target only if fixture construction needs direct ZIP APIs.
  - Keep the ZIP type names out of every public signature.
- **Verification:** `swift package dump-package` and `swift package resolve` succeed; the resolved dependency is compatible with all declared platforms.
- **Rollback:** Remove the dependency and any generated lockfile.

## Phase 1: Archive Errors, Loading, and Session Ownership

### Task 1.1: Define Stable Viewer Errors

- **Complexity:** S
- **Dependencies:** 0.2
- **Files:**
  - Create `libs/comics_viewer/comics-viewer-ios/Sources/ComicsViewer/Comics/Utils/ComicsViewerError.swift`
  - Create `libs/comics_viewer/comics-viewer-ios/Tests/ComicsViewerTests/ComicsViewerErrorTests.swift`
- **Actions:**
  - Implement the approved typed error cases and stable `LocalizedError` messages.
  - Preserve underlying JSON errors for diagnostics without exposing ZIPFoundation types.
- **Verification:** Focused tests cover every error message and associated path/context.
- **Rollback:** Remove the new error and test files.

### Task 1.2: Implement Safe Archive Inspection and Extraction

- **Complexity:** L
- **Dependencies:** 1.1
- **Files:**
  - Create `libs/comics_viewer/comics-viewer-ios/Sources/ComicsViewer/Comics/Utils/ComicsArchiveLoader.swift`
  - Create `libs/comics_viewer/comics-viewer-ios/Tests/ComicsViewerTests/ComicsArchiveLoaderTests.swift`
- **Actions:**
  - Add an internal `ComicsArchiveLoading` seam and production ZIP loader.
  - Validate readable regular-file input, create a unique session directory, inspect every entry, and enforce path/type/count/per-entry/total-byte limits before and during extraction.
  - Decode root `data.json` into the unchanged `Comics` model.
  - Map dependency and filesystem failures into `ComicsViewerError` and delete partial output on every failure.
  - Build generated fixtures for valid comics, missing/malformed JSON, invalid ZIP, traversal, absolute path, symlink, too many entries, oversized entry, and excessive total size.
- **Verification:** `swift test --filter ComicsArchiveLoaderTests` passes on macOS; no rejected fixture leaves a session directory behind.
- **Rollback:** Remove loader/tests and the dependency if no later task uses it.

### Task 1.3: Implement Idempotent Archive Sessions

- **Complexity:** M
- **Dependencies:** 1.2
- **Files:**
  - Create `libs/comics_viewer/comics-viewer-ios/Sources/ComicsViewer/Comics/Utils/ComicsArchiveSession.swift`
  - Create `libs/comics_viewer/comics-viewer-ios/Tests/ComicsViewerTests/ComicsArchiveSessionTests.swift`
- **Actions:**
  - Make the session own the extracted root, decoded `Comics`, and root-bound `ArchiveManager`.
  - Add idempotent cleanup that removes only the owned session root.
  - Ensure abandoned/stale sessions can be disposed independently and two sessions never share a root.
- **Verification:** Tests prove distinct roots, scoped cleanup, repeated dispose safety, and cleanup after loader/session release.
- **Rollback:** Remove session/tests; loader remains independently testable.

## Phase 2: Session-Scoped Renderer Resources

### Task 2.1: Make `ArchiveManager` Root-Bound

- **Complexity:** M
- **Dependencies:** 1.3
- **Files:**
  - `libs/comics_viewer/comics-viewer-ios/Sources/ComicsViewer/Comics/Utils/ArchiveManager.swift`
  - Create `libs/comics_viewer/comics-viewer-ios/Tests/ComicsViewerTests/ArchiveManagerTests.swift`
- **Actions:**
  - Add an instance initializer for an immutable archive root and use it for comics/layer/sound reads.
  - Retain `shared` and legacy root assignment only for source compatibility; controller sessions must never use them.
  - Normalize and validate resource paths so renderer lookups cannot escape the archive root.
- **Verification:** Tests load identical resource names from two roots without cross-talk and reject escaped resource paths.
- **Rollback:** Restore the legacy implementation and remove focused tests.

### Task 2.2: Inject Resources into Tiles and Sound Lookup

- **Complexity:** M
- **Dependencies:** 2.1
- **Files:**
  - `libs/comics_viewer/comics-viewer-ios/Sources/ComicsViewer/Comics/Views/TileImageView.swift`
  - `libs/comics_viewer/comics-viewer-ios/Sources/ComicsViewer/Comics/Views/ImageScrollView.swift`
  - `libs/comics_viewer/comics-viewer-ios/Sources/ComicsViewer/Comics/Utils/SoundManager.swift`
  - Create `libs/comics_viewer/comics-viewer-ios/Tests/ComicsViewerTests/ResourceIsolationTests.swift`
- **Actions:**
  - Pass the session manager explicitly into `ImageScrollView`, each tile, and sound resource resolution.
  - Remove controller-driven renderer reads through `ArchiveManager.shared`.
  - Prevent delayed image/audio callbacks from installing resources belonging to a replaced session.
- **Verification:** Tests or simulator integration harnesses prove simultaneous views with colliding filenames render/read from their own roots.
- **Rollback:** Restore global lookup paths; retain Phase 2.1 compatibility API.

## Phase 3: Repair `ImageScrollView` Presentation Operations

### Task 3.1: Stabilize Layer-to-View Mapping and Preview Filtering

- **Complexity:** L
- **Dependencies:** 2.2
- **Files:**
  - `libs/comics_viewer/comics-viewer-ios/Sources/ComicsViewer/Comics/Views/ImageScrollView.swift`
  - `libs/comics_viewer/comics-viewer-ios/Sources/ComicsViewer/Comics/Views/TileImageView.swift`
  - Create `libs/comics_viewer/comics-viewer-ios/Tests/ComicsViewerTests/ImageScrollViewTests.swift`
- **Actions:**
  - Replace fragile parallel-index assumptions with explicit layer/view bindings.
  - Implement document installation, preview visibility, and rerendering without changing model Codable fields.
  - Keep scroll transforms delegated to `Comics.process(scrollOffset:)` and preserve layer ordering.
- **Verification:** iOS-focused tests cover normal/preview layer sets, empty documents, correct binding after filtering, and no out-of-bounds access.
- **Rollback:** Restore existing render mapping and remove the new tests.

### Task 3.2: Add Language, Sound, and Teardown Controls

- **Complexity:** M
- **Dependencies:** 3.1
- **Files:**
  - `libs/comics_viewer/comics-viewer-ios/Sources/ComicsViewer/Comics/Views/ImageScrollView.swift`
  - `libs/comics_viewer/comics-viewer-ios/Sources/ComicsViewer/Comics/Views/TileImageView.swift`
  - `libs/comics_viewer/comics-viewer-ios/Sources/ComicsViewer/Comics/Utils/SoundManager.swift`
  - `libs/comics_viewer/comics-viewer-ios/Tests/ComicsViewerTests/ImageScrollViewTests.swift`
- **Actions:**
  - Implement bounded language selection and reload tiles from the active session.
  - Implement sound enable/disable with immediate stop on disable.
  - Add idempotent view teardown that cancels pending tile work, stops audio, clears callbacks, and detaches document/session state.
- **Verification:** Focused tests cover valid/invalid language indices, sound transitions, repeated teardown, and post-teardown no-ops.
- **Rollback:** Restore prior view/sound behavior while leaving resource injection intact.

## Phase 4: Repair the Public Controllers

### Task 4.1: Rebuild `ComicsViewerController` Around Sessions

- **Complexity:** L
- **Dependencies:** 3.2
- **Files:**
  - `libs/comics_viewer/comics-viewer-ios/Sources/ComicsViewer/ComicsViewerController.swift`
  - Create `libs/comics_viewer/comics-viewer-ios/Tests/ComicsViewerTests/ComicsViewerControllerTests.swift`
- **Actions:**
  - Preserve all approved public signatures and add only internal loader/executor injection for deterministic tests.
  - Load off-main, install on-main, use latest-load-wins generation checks, and complete exactly once on main.
  - Route play/pause/seek/preview/sound/language to view-owned operations.
  - Convert model `Int` dimensions to `CGFloat` at the facade boundary.
  - Make dispose idempotent, invalidate pending loads, stop timers/audio, clear callbacks, and release the session.
- **Verification:** Tests cover success/failure callbacks, callback thread, two overlapping loads, dispose during load, playback idempotence, seek bounds, state reporting, and repeated dispose.
- **Rollback:** Restore controller file; lower layers remain independently usable.

### Task 4.2: Repair `PuzzleViewerController`

- **Complexity:** L
- **Dependencies:** 4.1
- **Files:**
  - `libs/comics_viewer/comics-viewer-ios/Sources/ComicsViewer/PuzzleViewerController.swift`
  - Create `libs/comics_viewer/comics-viewer-ios/Tests/ComicsViewerTests/PuzzleViewerControllerTests.swift`
- **Actions:**
  - Preserve the approved public puzzle facade and remove the private/public `getCurrentScrollView()` collision.
  - Load puzzle metadata with typed errors and create one archive session/resource context per piece.
  - Clamp/ignore invalid piece selection, deliver selection callbacks on main, and route controls only to the selected view.
  - Dispose all piece views/sessions safely during replacement, partial failure, or controller teardown.
- **Verification:** Tests cover zero/multiple pieces, missing piece archive, partial load cleanup, selection bounds, per-piece isolation, selected-piece controls, callbacks, and repeated dispose.
- **Rollback:** Restore puzzle controller; comics controller remains repaired.

### Task 4.3: Prove the Public Facade Compiles for UIKit

- **Complexity:** S
- **Dependencies:** 4.2
- **Files:**
  - `libs/comics_viewer/comics-viewer-ios/Package.swift` only if a dedicated UIKit test target is required
  - `libs/comics_viewer/comics-viewer-ios/Tests/ComicsViewerTests/*ControllerTests.swift`
- **Actions:**
  - Compile every method used by Flutter and React Native with UIKit enabled.
  - Add an iOS-only compile/integration test target only if ordinary package tests cannot exercise the facade cleanly.
- **Verification:** `xcodebuild build -scheme ComicsViewer -destination 'generic/platform=iOS Simulator' -skipMacroValidation CODE_SIGNING_ALLOWED=NO` succeeds.
- **Rollback:** Remove only any extra test target/harness; keep production repairs.

## Phase 5: Documentation and Package CI

### Task 5.1: Document Archive and Controller Usage

- **Complexity:** S
- **Dependencies:** 4.3
- **Files:**
  - `libs/comics_viewer/comics-viewer-ios/README.md`
- **Actions:**
  - Document archived `.comics` loading, public controls, callback threading, errors, lifecycle, platform minimums, ZIP limits, and temporary cleanup.
  - Add exact local macOS and iOS Simulator verification commands.
  - Mark `ArchiveManager.shared` as legacy compatibility, not controller-session guidance.
- **Verification:** Every documented symbol/command matches the repaired package and approved API.
- **Rollback:** Revert the README section.

### Task 5.2: Harden the Swift Package Build Workflow

- **Complexity:** S
- **Dependencies:** 4.3
- **Files:**
  - `libs/comics_viewer/comics-viewer-ios/.github/workflows/build.yml`
- **Actions:**
  - Print both Swift and Xcode versions, resolve dependencies explicitly, and retain macOS build/test plus unsigned generic iOS Simulator build.
  - Keep supported `macos-15`/Xcode 16 selectors unless execution proves the image name has changed.
  - Add `permissions: contents: read`; do not upload release artifacts or modify `publish.yml`.
- **Verification:** Workflow syntax is valid and its commands match local commands; package CI passes on a branch/PR.
- **Rollback:** Restore the prior build workflow.

### Task 5.3: Run the Full Package Gate

- **Complexity:** M
- **Dependencies:** 5.1, 5.2
- **Files:**
  - `flows/sdd-comics-viewer-ios/04-implementation-log.md`
- **Actions:**
  - Run `swift build -v`, `swift test -v`, and the unsigned generic iOS Simulator `xcodebuild` command from the package root.
  - Check repository status for generated `.build`, `.swiftpm`, workspace, and lockfile noise; retain only intentional files.
  - Record test counts, skipped platform tests, tool versions, and exact failures if any.
- **Verification:** All three package commands pass with no unexplained repository changes.
- **Rollback:** Remove only generated untracked build state; never discard unrelated user changes.

## Phase 6: Consumer Integration Gates

### Task 6.1: Validate the Flutter Bridge Contract Locally

- **Complexity:** M
- **Dependencies:** 5.3
- **Files:**
  - `libs/comics_viewer/flutter_comics_viewer/ios/flutter_comics_viewer/Sources/flutter_comics_viewer/ComicsViewerPlatformView.swift` only if the preserved facade exposes a real incompatibility
  - `libs/comics_viewer/flutter_comics_viewer/.github/workflows/example-build.yml` only if verification exposes an independent workflow defect
  - `flows/sdd-comics-viewer-ios/04-implementation-log.md`
- **Actions:**
  - Compile-check the bridge against the repaired public signatures without introducing a committed local-path dependency or generated-file patch.
  - Run Flutter analyze/tests if any Flutter file changes.
  - Hash and ZIP-inspect `example/assets/sample.comics` before and after all commands.
- **Verification:** Bridge source compiles against the facade; the fixture hash/ZIP structure is unchanged; no local-only override remains.
- **Rollback:** Revert only consumer changes proven unnecessary.

### Task 6.2: Run the Authoritative Remote Flutter iOS Build

- **Complexity:** L
- **Dependencies:** 6.1 and the repaired package commit being available on the remote `main` branch through a separate user-authorized landing step
- **Files:**
  - `flows/sdd-comics-viewer-ios/04-implementation-log.md`
- **Actions:**
  - From `libs/comics_viewer/flutter_comics_viewer`, run `./tool/build-example.sh ios` (equivalent to `flutter build ios --debug --no-codesign --simulator`).
  - Confirm SwiftPM resolves `https://github.com/comics108/comics-viewer-ios.git` and record the consumed revision/version.
  - Verify the `build-ios` job in `example-build.yml` passes against that same remote revision.
- **Verification:** Local wrapper and GitHub Actions build the iOS Simulator example from the remote package; no signing or release occurs.
- **Rollback:** None for verification; workflow-only corrections can be reverted independently.

### Task 6.3: Validate the React Native iOS Facade

- **Complexity:** M
- **Dependencies:** 5.3
- **Files:**
  - `libs/comics_viewer/react-native-comics-viewer/ios/ComicsViewerViewManager.swift` only if an actual preserved-facade incompatibility is found
  - `flows/sdd-comics-viewer-ios/04-implementation-log.md`
- **Actions:**
  - Compile the CocoaPods/module scaffold when it supports a headless simulator build.
  - If the repository lacks a buildable example/workspace, record that exact external blocker and still compile-audit every controller call.
- **Verification:** The module builds, or the implementation log names the missing scaffold and confirms source-level API compatibility.
- **Rollback:** Revert only framework bridge edits not required by the unified facade.

### Task 6.4: Perform Simulator Behavior Verification

- **Complexity:** L
- **Dependencies:** 6.2
- **Files:**
  - `flows/sdd-comics-viewer-ios/04-implementation-log.md`
- **Actions:**
  - Launch the Flutter example on an iOS Simulator and load the checked-in archive.
  - Exercise scroll animation, play/pause, seek, preview, sound, language, failure callback, dispose, and reopen.
  - Verify puzzle behavior only if a representative fixture exists; record fixture absence explicitly otherwise.
- **Verification:** Manual checklist and observed outcomes are logged; no crash, stale callback, resource cross-talk, or fixture mutation occurs.
- **Rollback:** Verification-only.

## Phase 7: Flow Reconciliation and Handoff

### Task 7.1: Reconcile Child and Parent SDD Artifacts

- **Complexity:** S
- **Dependencies:** 5.3; include later remote/manual results when available
- **Files:**
  - `flows/sdd-comics-viewer-ios/_status.md`
  - `flows/sdd-comics-viewer-ios/04-implementation-log.md`
  - `flows/sdd-comics-viewer/_status.md`
  - `flows/sdd-comics-viewer/04-implementation-log.md`
- **Actions:**
  - Record completed tasks, verification evidence, remaining remote/manual gates, and repository state.
  - Mark parent tasks 4.3.3, 5.3.3, and 6.2.2 only to the level actually proven.
  - Do not mark either implementation complete while required remote or manual acceptance remains outstanding.
- **Verification:** Status, progress, blockers, and logs agree across both flows and contain no unsupported “passed” claims.
- **Rollback:** Correct the documentation entries; no production rollback required.

## Dependency Graph

```text
0.1 → 0.2 → 1.1 → 1.2 → 1.3 → 2.1 → 2.2
                                      ↓
3.1 → 3.2 → 4.1 → 4.2 → 4.3 → 5.1 ─┐
                                  └→ 5.2 ─┴→ 5.3 → 6.1 → 6.2 → 6.4
                                               └────→ 6.3
                                                        ↓
                                                       7.1
```

## Completion Criteria

- `ComicsViewer` builds and tests on macOS and builds for a generic iOS Simulator.
- Valid archived comics load through owned temporary sessions; invalid/unsafe/oversized archives fail with stable typed errors and no leaked directories.
- Controller-driven tiles and sounds use session-scoped resources; concurrent viewers and puzzle pieces cannot cross-talk.
- Existing comics and puzzle public interfaces compile unchanged for Flutter and React Native.
- Playback, seek, preview, sound, language, latest-load-wins, callback threading, and idempotent dispose behavior are covered.
- The package GitHub Actions workflow is green and performs no publishing.
- After the package change is remotely available, the Flutter example local wrapper and `build-ios` GitHub Actions job pass against the recorded remote revision.
- The checked-in `sample.comics` hash and ZIP validity are unchanged.
- Required manual simulator results or exact external blockers are recorded.
- Parent flow artifacts accurately reflect the evidence; no tag or release is created.

## Rollback Strategy

Revert in reverse phase order. Consumer/workflow/documentation changes are independent of the renderer repair. The package repair can be reverted as one session/facade slice plus the ZIP dependency. Runtime extraction creates only uniquely owned temporary directories, so rollback needs no persisted-data migration. Never remove broad temporary directories; cleanup targets only session roots created by the loader.

---

## Approval

- [x] Reviewed by: user
- [x] Approved on: 2026-08-05
- [x] Notes: Approved explicitly; implementation may proceed in dependency order.
