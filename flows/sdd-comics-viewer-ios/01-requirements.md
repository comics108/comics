# Requirements: Comics Viewer iOS Package Build Recovery

> Version: 1.1  
> Status: REVIEW  
> Last Updated: 2026-08-05

## Problem Statement

The Swift package in `libs/comics_viewer/comics-viewer-ios` does not currently compile as the iOS dependency of `flutter_comics_viewer`. Its recently added controller facade has drifted from the package's existing model and archive APIs:

- `ArchiveManager.loadComics(from:)` is referenced but does not exist;
- `Comics.process(at:)`, `setPreview`, `setSoundEnabled`, and `dispose` are referenced but do not exist;
- `PuzzleViewerController` declares private and public `getCurrentScrollView()` methods with the same signature;
- an `Int` comics height is exposed where the controller API requires `CGFloat`.

As a result, the Flutter example cannot complete an iOS Simulator build against the package's `main` branch. The package's own GitHub Actions workflow is also unable to provide a reliable green build contract for consumers.

This flow will restore a coherent Swift Package API and make both local and GitHub Actions builds verify the supported package and its Flutter iOS integration.

## Alignment With Approved Flows

This is a corrective implementation slice of the approved [`sdd-comics-viewer`](../sdd-comics-viewer/) architecture plan, not a competing viewer design.

- `sdd-comics-viewer` is the authoritative plan for the extracted native libraries, unified controller API, Flutter/React Native wrappers, and cross-platform validation.
- [`sdd-flutter-comics-viewer`](../sdd-flutter-comics-viewer/) is retained as historical analysis of the file format, native rendering behavior, sound, tiling, and Flutter bridge. Where it conflicts with the later plan (for example its early pure-Dart direction), the approved native-first architecture in `sdd-comics-viewer` wins.
- The present flow repairs the iOS package regression that blocks main-plan tasks 4.3.3 (Flutter iOS example), 5.3.3 (React Native iOS example), and 6.2.2 (full cross-platform validation).
- The renderer remains copied from the legacy Swift implementation. Changes are limited to compatibility/build fixes, facade adapters, tests, and CI needed to satisfy the already approved contract.

## User Stories

### Primary

**As a** maintainer of `flutter_comics_viewer`  
**I want** `comics-viewer-ios` to compile and expose the controller API used by the Flutter platform view  
**So that** the Flutter example builds for an iOS Simulator without maintaining a private patch or pinning an obsolete revision.

**As a** maintainer of `comics-viewer-ios`  
**I want** local build/test commands and GitHub Actions to exercise the same supported package surfaces  
**So that** API drift is detected before changes reach consumers.

### Secondary

**As a** native Swift Package consumer  
**I want** loading, scrolling, preview, sound, language, playback, and disposal behavior to have a consistent public contract  
**So that** I can embed the viewer without depending on legacy application internals.

## Acceptance Criteria

### Must Have

1. **Given** a clean checkout of `libs/comics_viewer/comics-viewer-ios` on a supported macOS/Xcode host  
   **When** the documented local package verification commands are run  
   **Then** the package resolves, compiles, and its tests pass without Swift compiler errors.

2. **Given** the `ComicsViewer` Swift Package target  
   **When** its public controllers compile  
   **Then** every referenced model/archive method exists with the correct signature, numeric types are converted deliberately, and no controller has an invalid redeclaration.

3. **Given** a valid `.comics` archive path  
   **When** `ComicsViewerController.loadComics(filePath:completion:)` is called  
   **Then** the still-archived ZIP is extracted/read through one owned loading path, the decoded `Comics` is installed into the supplied `ImageScrollView` on the main thread, and the completion reports success or a meaningful failure exactly once.

   **And** `libs/comics_viewer/flutter_comics_viewer/example/assets/sample.comics` remains archived and can be used directly as the integration fixture.

4. **Given** an initialized comics controller  
   **When** the Flutter iOS platform view invokes play, pause, seek/scroll position, preview, sound, language, or dispose operations  
   **Then** those calls compile, are safe before and after loading, and retain the unified public signatures already approved for native, Flutter, and React Native consumers.

   **And** the `isPlaying`, `duration`, `currentPosition`, `onScrollChanged`, loaded, and error semantics remain compatible with the approved cross-framework contract.

5. **Given** a puzzle definition and its referenced piece archives  
   **When** `PuzzleViewerController` loads and navigates the puzzle  
   **Then** it uses the same archive-loading contract, exposes the selected piece's scroll view without ambiguous methods, and safely handles empty, missing, or invalid pieces.

   **And** puzzle support remains in the same `ComicsViewer` package, as required by the main architecture plan.

6. **Given** `libs/comics_viewer/flutter_comics_viewer/example` consuming `comics-viewer-ios` from its configured Swift Package dependency  
   **When** the documented local iOS Simulator build is run  
   **Then** `flutter build ios --simulator` succeeds without patching generated files or changing the dependency to a local-only path.

7. **Given** a push or pull request to `comics-viewer-ios`  
   **When** GitHub Actions runs  
   **Then** it verifies the supported Swift Package build/tests and an iOS Simulator build using maintained runner/Xcode settings, and fails on a recurrence of the controller/API compile errors.

8. **Given** the package currently declares iOS 13 and macOS 10.15  
   **When** package CI runs  
   **Then** both declared platform contracts compile, with UIKit-only facade code conditionally isolated where necessary.

9. **Given** the core library's approved identity  
   **When** package metadata and consumer configuration are inspected  
   **Then** the core remains `ComicsViewer` / `net.nativemind.comics.viewer`, while Flutter remains `net.nativemind.flutter.comics.viewer` and React Native remains `net.nativemind.rn.comics.viewer`.

10. **Given** the implementation is complete  
   **When** repository changes are reviewed  
   **Then** generated build products, DerivedData, dependency caches, signing credentials, and release artifacts are not committed.

### Should Have

1. Loading and facade behavior have focused unit tests using temporary fixtures or dependency seams rather than network access.
2. CI commands are mirrored by a short local-build section or script so failures can be reproduced outside GitHub Actions.
3. Existing public model/view APIs remain source-compatible unless changing one is necessary to produce a single coherent loading contract.

### Won't Have (This Iteration)

- A redesign of the viewer UI or Flutter widget API.
- Modernization of the legacy `Mahabharata` application, its Xcode project/workspace, or checked-in CocoaPods tree.
- Android or React Native feature work beyond checking that shared API expectations are not contradicted.
- Broad refactoring of animation, audio, tiling, or archive formats unrelated to build correctness.
- General warning cleanup, dependency upgrades, App Store signing, publishing, tagging, or release creation.
- Changes to other repositories unless an integration-only adjustment is proven necessary and separately approved.
- Replacing the approved native-first architecture with a pure-Dart renderer.

## Constraints

- **Repository boundary**: Implementation is primarily limited to the nested repository `libs/comics_viewer/comics-viewer-ios`; the parent workspace is used for the Flutter consumer verification.
- **Source provenance**: Preserve the renderer copied from `legacy/mahabharata-mobile-swift-v2012`; do not rewrite animations, tiles, sound, or scrolling from scratch.
- **Public integration**: `libs/comics_viewer/flutter_comics_viewer/ios/.../ComicsViewerPlatformView.swift` is the current concrete consumer contract and must keep compiling.
- **Toolchain**: Preserve Swift tools 5.9 compatibility and the currently declared iOS 13 minimum unless specifications document and justify a change.
- **Platforms**: iOS Simulator support is mandatory. The package currently declares macOS 10.15 and CI builds macOS; its final status must be explicit rather than accidentally broken.
- **Concurrency/UI**: File work may occur off the main thread, but UIKit state and completion delivery must obey a documented main-thread contract.
- **Error behavior**: Missing paths, malformed archives/JSON, and missing puzzle pieces must not crash through force unwraps or `try!` in the newly touched loading path.
- **Compatibility**: Prefer adapting the controller facade to the existing package model semantics over adding no-op methods solely to satisfy the compiler.
- **Unified API**: The approved cross-framework methods are `loadComics`, `play`, `pause`, `setScrollPosition`, `getScrollPosition`, `togglePreview`, `toggleSounds`, and `dispose`; the established language extension must remain compatible with the current Flutter bridge.
- **Fixture integrity**: `sample.comics` must remain a ZIP archive; tests may extract it only into temporary runtime storage.
- **Identity**: Preserve approved bundle/package identifiers: core `net.nativemind.comics.viewer`, Flutter `net.nativemind.flutter.comics.viewer`, React Native `net.nativemind.rn.comics.viewer`.
- **Automation**: CI must not require signing secrets for simulator/package verification, and the build workflow must remain independent from tag publishing.
- **Change authority**: No commits, pushes, tags, releases, or external repository mutations are part of this flow without a direct user request.

## Resolved Decisions Inherited From Approved Flows

- [x] Repair the Swift Package and its framework integrations; do not modernize the legacy app in this slice.
- [x] Preserve iOS 13 and macOS 10.15 package declarations and CI coverage.
- [x] Preserve the unified native/Flutter/React Native facade while allowing internal compatibility adapters.
- [x] Keep native rendering; Dart remains a thin Flutter bridge.
- [x] Keep puzzle support in the same core package.
- [x] Keep `sample.comics` archived and load it directly as the integration fixture.
- [x] Run Swift package/tests and iOS Simulator build in the iOS repository workflow; run the full Flutter example build in the Flutter repository workflow/local verification path.
- [x] Do not publish, tag, or release as part of this corrective slice.

## Open Questions

- None. Scope and compatibility choices are inherited from the approved parent flows. Requirements still require explicit approval before specifications are drafted.

## References

- [`libs/comics_viewer/comics-viewer-ios/Package.swift`](../../libs/comics_viewer/comics-viewer-ios/Package.swift)
- [`ComicsViewerController.swift`](../../libs/comics_viewer/comics-viewer-ios/Sources/ComicsViewer/ComicsViewerController.swift)
- [`PuzzleViewerController.swift`](../../libs/comics_viewer/comics-viewer-ios/Sources/ComicsViewer/PuzzleViewerController.swift)
- [`ArchiveManager.swift`](../../libs/comics_viewer/comics-viewer-ios/Sources/ComicsViewer/Comics/Utils/ArchiveManager.swift)
- [`Comics.swift`](../../libs/comics_viewer/comics-viewer-ios/Sources/ComicsViewer/Comics/Models/Comics.swift)
- [`comics-viewer-ios build workflow`](../../libs/comics_viewer/comics-viewer-ios/.github/workflows/build.yml)
- [`Flutter iOS consumer`](../../libs/comics_viewer/flutter_comics_viewer/ios/flutter_comics_viewer/Sources/flutter_comics_viewer/ComicsViewerPlatformView.swift)
- Prior integration flow: [`sdd-flutter-comics-viewer-example-build`](../sdd-flutter-comics-viewer-example-build/)
- Authoritative parent flow: [`sdd-comics-viewer`](../sdd-comics-viewer/)
- Historical Flutter analysis: [`sdd-flutter-comics-viewer`](../sdd-flutter-comics-viewer/)

---

## Approval

- [ ] Reviewed by: user
- [ ] Approved on: pending
- [ ] Notes: Awaiting explicit requirements approval; scope decisions are inherited from the approved parent flows and no open questions remain.
