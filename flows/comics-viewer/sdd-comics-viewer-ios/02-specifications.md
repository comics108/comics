# Specifications: Comics Viewer iOS Package Build Recovery

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-08-05  
> Requirements: [01-requirements.md](01-requirements.md)

## Overview

Repair `comics-viewer-ios` as the native iOS engine required by the approved `sdd-comics-viewer` architecture. The implementation keeps the legacy Swift renderer and the existing public controller signatures, while adding a coherent archive session layer between an archived `.comics` file and the renderer's directory-based resource access.

The design fixes API drift at the correct ownership boundaries:

- archive extraction/decoding belongs to an archive loader and session;
- preview, language, and sound presentation belong to `ImageScrollView`;
- playback and consumer-facing lifecycle belong to the controllers;
- `Comics` remains the decoded animation model and retains `process(scrollOffset:)`;
- Flutter and React Native remain thin consumers of the same native facade.

This child flow unblocks parent-plan tasks 4.3.3, 5.3.3, and 6.2.2 without replacing the approved native-first architecture.

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `comics-viewer-ios` Swift Package | Modify | Restore compilable controllers, archive ownership, renderer controls, tests, documentation, and CI |
| Archive loading | Create/Modify | Add ZIP-to-temporary-directory session lifecycle while retaining directory resource reads |
| `ImageScrollView` / `TileImageView` | Modify | Use an explicit archive resource context and implement facade operations at the view layer |
| `ComicsViewerController` | Modify | Preserve public API; coordinate load, playback, state, and cleanup |
| `PuzzleViewerController` | Modify | Remove method collision and give every piece its own archive/resource session |
| `flutter_comics_viewer` | Verify; modify only if required | Existing SwiftPM dependency and iOS platform bridge define the concrete consumer contract |
| `react-native-comics-viewer` | Verify | Must continue compiling against the same facade |
| GitHub Actions | Modify/Verify | Package CI owns Swift/macOS/iOS checks; Flutter CI owns full example integration |
| Legacy `Mahabharata` app and renderer source | No change | Reference behavior/source provenance only |

## Architecture

### Component Diagram

```text
Flutter / React Native / native app
              │
              ▼
 ComicsViewerController ───── public facade, playback, callbacks
              │ owns
              ▼
   ComicsArchiveSession ───── extracted root + decoded Comics + cleanup
              │ supplies
              ▼
       ArchiveManager ─────── directory-backed data/layer/sound access
              │ injected into
              ▼
       ImageScrollView ─────── scroll, preview, language, sound, tiles
              │
              ├── TileImageView
              └── SoundManager

PuzzleViewerController
    └── one ComicsArchiveSession + ImageScrollView per piece
```

### Data Flow: Load Archived Comics

```text
loadComics(filePath)
  → validate source is a readable regular file
  → create unique temporary session directory
  → inspect/extract ZIP entries with traversal and size guards
  → require data.json and decode Comics
  → create ArchiveManager rooted at extracted directory
  → prepare a ComicsArchiveSession
  → hop to main thread
  → ignore/clean stale result if a newer load or dispose won the race
  → replace previous session
  → attach archive context + Comics to ImageScrollView
  → apply stored language/sound/preview settings
  → complete exactly once on main thread
```

### Lifecycle and Ownership

- A controller owns at most one active comics session; a puzzle controller owns one session per loaded piece.
- A session owns its unique temporary extraction directory and removes it when replaced, disposed, or abandoned after a stale asynchronous load.
- `ImageScrollView`, tiles, and sound callbacks use the session's `ArchiveManager`; they do not look up the active archive through process-global mutable state.
- `ArchiveManager.shared` may remain for source compatibility with direct legacy consumers, but controller-driven rendering must not depend on it.
- A monotonically increasing load generation (or equivalent cancellation token) prevents older asynchronous loads from replacing newer state.
- `dispose()` is idempotent: it stops playback/audio, detaches rendered state, invalidates pending loads, releases sessions, and leaves subsequent no-op calls safe.

## Interfaces

### Preserved Public Controller Interface

```swift
#if canImport(UIKit)
public final class ComicsViewerController {
    public init(scrollView: ImageScrollView)

    public var isPlaying: Bool { get }
    public var duration: CGFloat { get }
    public var currentPosition: CGFloat { get }
    public var onScrollChanged: ((CGFloat) -> Void)? { get set }

    public func loadComics(
        filePath: String,
        completion: @escaping (Result<Void, Error>) -> Void
    )
    public func play()
    public func pause()
    public func setScrollPosition(_ position: CGFloat)
    public func getScrollPosition() -> CGFloat
    public func togglePreview(_ show: Bool)
    public func toggleSounds(_ enabled: Bool)
    public func setLanguage(_ languageIndex: Int)
    public func dispose()
}
#endif
```

The Flutter bridge requires these spellings and types. `duration` deliberately converts the model's `Int` height into view-space `CGFloat` rather than changing the persistent model schema.

### Preserved Puzzle Interface

```swift
#if canImport(UIKit)
public final class PuzzleViewerController {
    public init()

    public var currentPieceIndex: Int { get }
    public var totalPieces: Int { get }
    public var onPieceSelected: ((Int) -> Void)? { get set }

    public func loadPuzzle(
        filePath: String,
        completion: @escaping (Result<Void, Error>) -> Void
    )
    public func selectPiece(_ index: Int)
    public func play()
    public func pause()
    public func togglePreview(_ show: Bool)
    public func toggleSounds(_ enabled: Bool)
    public func dispose()
    public func getScrollView(forPieceIndex index: Int) -> ImageScrollView?
    public func getCurrentScrollView() -> ImageScrollView?
    public func getPuzzle() -> Puzzle?
}
#endif
```

The implementation has one public `getCurrentScrollView()` only. Any internal lookup uses a distinct name such as `currentScrollView()` or directly delegates to `getScrollView(forPieceIndex:)`.

### New Internal Archive Interfaces

Exact access levels and names may be refined during planning, but responsibilities are fixed:

```swift
protocol ComicsArchiveLoading {
    func loadArchive(at sourceURL: URL) throws -> ComicsArchiveSession
}

final class ComicsArchiveSession {
    let rootURL: URL
    let comics: Comics
    let resources: ArchiveManager

    func dispose()
}
```

- Production loading extracts ZIP archives and decodes `data.json`.
- Tests inject a deterministic loader/session or construct temporary ZIP fixtures.
- Session cleanup is idempotent.
- The loader is Foundation-first and platform-neutral so it can be unit-tested by `swift test` on macOS.

### Archive Dependency

Use a Swift Package ZIP implementation rather than copying the legacy Objective-C/minizip tree into the Swift target. The selected dependency must:

- support Swift tools 5.9, iOS 13, and macOS 10.15;
- permit enumerating entries before extraction;
- preserve the `.comics` file as the source and extract only to temporary runtime storage;
- be pinned by a compatible semantic version range in `Package.swift`.

The implementation plan will select and pin the concrete maintained package after verifying current compatibility. No archive dependency API leaks into the public `ComicsViewer` facade.

### Error Interface

Expose stable, localized failures through an error enum or equivalent typed errors:

```swift
public enum ComicsViewerError: LocalizedError {
    case fileNotFound(URL)
    case unreadableFile(URL)
    case invalidArchive
    case unsafeArchiveEntry(String)
    case archiveLimitExceeded
    case missingDataJSON
    case invalidComicsData(Error)
    case invalidPuzzleData(Error)
    case missingPuzzlePiece(String)
    case disposed
}
```

Flutter continues receiving `localizedDescription` through its existing `onError` method-channel event; consumers are not forced to import the ZIP dependency's errors.

## Data Models

### Existing Persistent Models

`Comics`, `Layer`, `Image`, `Sound`, animations, `Puzzle`, and `Piece` remain Codable representations of the established archive schema. No persisted field is renamed or repurposed.

### Runtime-Only State

Add only non-Codable runtime state where ownership requires it:

- archive/session identity;
- selected preview visibility;
- selected language index;
- selected sound-enabled state;
- playback timer and load generation;
- per-piece session/view mappings.

These values must not alter `data.json` compatibility.

## Behavior Specifications

### Comics Happy Path

1. The consumer supplies the archived `sample.comics` path.
2. The loader creates a unique temporary directory and safely extracts the archive.
3. `data.json` decodes into the unchanged `Comics` model.
4. The controller installs the session on the main thread.
5. `ImageScrollView` prepares layers and renders from that session's `layers/` resources.
6. Scroll updates call `comics.process(scrollOffset:)`, transform tiles, and deliver `onScrollChanged` in view coordinates.
7. Sound lookup uses the same session root.
8. Replacing or disposing the document stops active work and removes only that session's temporary directory.

### Controller Operations

| Operation | Required behavior |
|-----------|-------------------|
| `play()` | Starts one timer only when a document exists; repeated calls are idempotent |
| `pause()` | Stops the timer safely even before load or after dispose |
| `setScrollPosition` | Clamps to valid view-space bounds, updates the scroll view, and lets the normal scroll pipeline process animations |
| `togglePreview` | `ImageScrollView` includes/excludes layers whose immutable model flag is `isPreview`; it does not mutate decoded schema |
| `toggleSounds` | Updates `soundEnabled`; disabling immediately mutes/stops active playback as appropriate |
| `setLanguage` | Stores a non-negative index, reloads language-dependent tiles, and preserves safe fallback behavior already implemented by `Layer.image(languageIndex:)` |
| `dispose` | Idempotently stops timer/sounds, clears callbacks/rendered state, invalidates loads, and cleans the session |

### Preview Rendering

- Add view-level `showPreview` state, defaulting to the legacy-visible behavior agreed in the plan/consumer defaults.
- Tile construction/reload filters preview layers consistently while preserving original Z-order of the remaining layers.
- Changing preview state rebuilds or updates tiles without modifying `Layer.preview`.
- Puzzle preview state is applied independently to each piece view.

### Sound Cleanup

- `Comics` does not gain artificial `setSoundEnabled` or `dispose` methods just to satisfy the controller.
- The existing `ImageScrollView.soundEnabled`, `pauseSounds()`, `resumeSounds()`, and `mute(_:)` behavior is the sound ownership boundary.
- Disposal detaches/pauses all players reachable from the view before archive files are removed.

### Language Reload

- `setLanguage` updates `ImageScrollView.languageIndex` and invokes the existing language tile reload path.
- Negative language indices are rejected or normalized consistently; out-of-range positive indices retain the model's current safe-index fallback.
- Reloading must not replay point sounds solely because language changed.

### Puzzle Loading

- The puzzle descriptor remains JSON at `filePath`; each `Piece.file` resolves relative to the descriptor directory unless it is already an allowed absolute URL.
- Each piece `.comics` file is loaded into its own archive session and `ImageScrollView` so layers/sounds cannot accidentally resolve against another piece's archive.
- Missing or invalid referenced pieces produce a deterministic failure rather than a partially successful puzzle with hidden missing content.
- Empty puzzle data succeeds with `totalPieces == 0`, no selection, and nil current scroll view.
- Selecting an invalid index is a no-op; selecting a valid index pauses prior playback and emits `onPieceSelected` once when selection changes.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| Missing file | Path does not exist | Main-thread `.failure(fileNotFound)` exactly once |
| Directory passed as comics | Source is not a regular ZIP file | `.failure(unreadableFile/invalidArchive)` |
| Malformed ZIP | Archive cannot be enumerated/extracted | Cleanup temp directory; `.failure(invalidArchive)` |
| ZIP path traversal | Absolute or `..` entry escapes session root | Reject archive before writing unsafe path |
| Oversized archive | Entry count or total uncompressed size exceeds documented limit | Reject and clean session directory |
| Missing `data.json` | Extraction succeeds without root metadata | `.failure(missingDataJSON)` |
| Invalid JSON | Codable decode fails | `.failure(invalidComicsData)` preserving underlying diagnostic |
| Load race | Load B starts before load A completes | Only B may become active; A is cleaned and cannot overwrite B |
| Dispose during load | Controller disposed before background work completes | Result is discarded/cleaned; no UIKit mutation after dispose |
| Repeated dispose | Consumer/deinit calls dispose more than once | No crash and no deletion outside owned temp directories |
| No document | Playback/control method called before load | Safe no-op or zero/nil getter result per existing facade |
| Zero-size comics | Width/height is zero | No divide-by-zero; view remains safe and playback does not start |
| Multiple controllers | Two viewers load different archives | Each resolves its own tiles/sounds without shared-root corruption |

## Dependencies

### Requires

- Swift tools 5.9 and Apple SDKs supporting iOS 13/macOS 10.15 deployment targets.
- One maintained Swift ZIP package selected under the archive-dependency criteria above.
- Existing legacy-derived model, animation, tiling, and sound code in `Sources/ComicsViewer`.
- Flutter 3.44.6 integration consumer and its remote `comics108/comics-viewer-ios` `main` dependency for final verification.

### Blocks

- `sdd-comics-viewer` task 4.3.3: Flutter example on iOS.
- `sdd-comics-viewer` task 5.3.3: React Native example on iOS.
- `sdd-comics-viewer` task 6.2.2: full cross-platform validation.

## Integration Points

### Flutter

The existing `ComicsViewerPlatformView.swift` remains the compile-time contract:

- constructs `ImageScrollView` and `ComicsViewerController`;
- calls the preserved controller methods;
- converts `CGFloat` values to `Double` for method-channel responses;
- reports `onLoaded`, `onError`, and `onScrollChanged`.

No local-path override is introduced. Flutter's staged SwiftPM plugin package continues to resolve `https://github.com/comics108/comics-viewer-ios.git` on `main`.

### React Native

The existing iOS view manager must compile against the same public facade. This child flow does not add a framework-specific controller API.

### Native App

Direct `ArchiveManager` compatibility remains available for the native app's manual SPM migration, but controller sessions are the recommended API. Xcode project surgery for the native app stays in parent-plan task 3.2.

## Testing Strategy

### Unit Tests (`swift test` on macOS)

- [ ] Decode representative comics JSON into unchanged models.
- [ ] Load a generated temporary `.comics` ZIP containing `data.json`, `layers/`, and `sounds/`.
- [ ] Report missing, malformed, unsafe, and oversized archives with typed errors.
- [ ] Ensure session cleanup removes only the owned temporary directory and is idempotent.
- [ ] Verify two simultaneous sessions retain distinct resource roots.
- [ ] Verify load-generation behavior with an injected deterministic loader where platform-neutral extraction logic permits it.

### iOS Simulator Tests / Build

- [ ] Build the `ComicsViewer` scheme for `generic/platform=iOS Simulator` without signing.
- [ ] Compile the full UIKit facade, including both controllers and `ImageScrollView` behavior.
- [ ] Add focused XCTest coverage for controller state transitions where UIKit test hosting is practical; otherwise cover them through a small package integration test target/fixture.

### Flutter Integration

- [ ] From `libs/comics_viewer/flutter_comics_viewer`, run the existing local wrapper for the iOS target (equivalent to `flutter build ios --debug --no-codesign --simulator`).
- [ ] Confirm the example consumes the remote package contract rather than a generated-file patch or local-only dependency.
- [ ] Confirm the checked-in `sample.comics` remains a ZIP archive before and after the build.
- [ ] Run `flutter analyze` and relevant Flutter tests if any integration file changes.

### React Native Compile Check

- [ ] Build the iOS example/module when its scaffold supports headless simulator compilation, or record the exact external blocker in the parent implementation log.

### Manual Verification

- [ ] Launch the Flutter example on an iOS Simulator.
- [ ] Load `sample.comics`; verify layers render and scrolling updates animations.
- [ ] Exercise play/pause, seek, preview, sound, and language methods.
- [ ] Verify load/error callbacks and teardown/reopen behavior.
- [ ] Puzzle visual verification is required if a representative puzzle fixture is available; absence of such a fixture must be recorded, not silently treated as passed.

## CI Specification

### `comics-viewer-ios/.github/workflows/build.yml`

On pushes/PRs:

1. checkout;
2. select the maintained Xcode available on the chosen macOS runner;
3. print Swift/Xcode versions for reproducibility;
4. resolve dependencies;
5. run macOS `swift build` and `swift test`;
6. run `xcodebuild` for the `ComicsViewer` scheme on a generic iOS Simulator destination;
7. use no signing credentials and upload no release artifacts.

Tag publishing remains isolated in `publish.yml` and is not expanded by this flow.

### `flutter_comics_viewer/.github/workflows/build.yml`

The existing `build-ios` job remains the end-to-end consumer gate. It must build the example with `--no-codesign --simulator` against the remote iOS package. Change this workflow only if verification shows a configuration defect independent of the repaired package.

## Migration / Rollout

1. Land the package fix and green package CI first.
2. Because Flutter references the package's `main` branch, verify the remote commit is available before treating Flutter CI as authoritative.
3. Run the Flutter example iOS job/local build and record the commit consumed by `Package.resolved` or build logs.
4. Run React Native/native-app compile validation from the parent plan.
5. Do not tag or publish a release in this flow.

Rollback is limited to reverting the package/session/facade changes and dependency entry. Temporary extraction directories are runtime-only and require no data migration.

## Open Design Questions

- None that change scope. The implementation plan must name the concrete ZIP package/version and exact test commands after toolchain compatibility is checked.

---

## Approval

- [x] Reviewed by: user
- [x] Approved on: 2026-08-05
- [x] Notes: Approved explicitly; implementation planning may proceed without changing the approved native-first scope.
