# Implementation Plan: Flutter Puzzle Library

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-07-19
> Approved by: User on 2026-07-19
> Specifications: [02-specifications.md](02-specifications.md)

## Summary

This plan outlines the atomic tasks for migrating native Java/Swift puzzle rendering to a Flutter plugin library. The library **DEPENDS** on flutter_comics for rendering individual puzzle pieces.

**Critical Dependency:** flutter_comics library MUST be completed first.

**Approach:**
1. Native-first architecture (maximum Java/Swift code reuse)
2. Dart only for Platform View bridging (AndroidView/UiKitView + MethodChannel)
3. Fix existing copied files (wrong packages, duplicates)
4. Add missing Swift implementations
5. Create Flutter integration layer

**Estimated Total:** ~45 tasks across 11 phases

---

## Task Breakdown

### Phase 1: Setup & Cleanup (7 tasks)

#### Task 1.1: Fix Android Package Names in Model Classes
- **Description**: Update package declarations from `com.fulldome.mahabharata` to `net.nativemind.puzzle` in all model classes
- **Files**:
  - `libs/flutter_puzzle/android/src/main/java/net/nativemind/puzzle/model/puzzle/Puzzle.java` - Modify
  - `libs/flutter_puzzle/android/src/main/java/net/nativemind/puzzle/model/puzzle/Piece.java` - Modify
  - `libs/flutter_puzzle/android/src/main/java/net/nativemind/puzzle/model/puzzle/Puzzles.java` - Modify
  - `libs/flutter_puzzle/android/src/main/java/net/nativemind/puzzle/model/puzzle/PieceState.java` - Modify
- **Dependencies**: None
- **Verification**: All files compile without package errors
- **Complexity**: Low

#### Task 1.2: Fix Android Package Names in Controls
- **Description**: Update package and imports in PieceView to use new structure and flutter_comics
- **Files**:
  - `libs/flutter_puzzle/android/src/main/java/net/nativemind/puzzle/controls/PieceView.java` - Modify
- **Dependencies**: Task 1.1
- **Verification**: PieceView compiles and extends flutter_comics LayersView
- **Complexity**: Low

#### Task 1.3: Remove Duplicate Android Utilities
- **Description**: Delete utility files that duplicate flutter_comics functionality
- **Files**:
  - `libs/flutter_puzzle/android/.../utils/SoundManager.java` - Delete
  - `libs/flutter_puzzle/android/.../utils/LruBitmapCache.java` - Delete
  - `libs/flutter_puzzle/android/.../utils/FileUtils.java` - Delete
  - `libs/flutter_puzzle/android/.../utils/ReflectionUtils.java` - Delete
- **Dependencies**: None
- **Verification**: No compilation errors, imports reference flutter_comics utils
- **Complexity**: Low

#### Task 1.4: Remove Android Activity/Fragment UI Code
- **Description**: Delete app-specific UI code not needed in library
- **Files**:
  - `libs/flutter_puzzle/android/.../screens/PuzzleActivity.java` - Delete
  - `libs/flutter_puzzle/android/.../screens/PiecesViewController.java` - Delete
  - `libs/flutter_puzzle/android/.../fragments/PuzzlePreviewFragment.java` - Delete
  - `libs/flutter_puzzle/android/.../fragments/MusicsFragment.java` - Delete
  - `libs/flutter_puzzle/android/.../controls/SoundBadge.java` - Delete
- **Dependencies**: None
- **Verification**: Library structure clean, no app-specific UI code
- **Complexity**: Low

#### Task 1.5: Remove Duplicate iOS Files
- **Description**: Delete iOS files that duplicate flutter_comics functionality
- **Files**:
  - `libs/flutter_puzzle/ios/puzzle/Sources/puzzle/Views/TileImageView.swift` - Delete
  - `libs/flutter_puzzle/ios/puzzle/Sources/puzzle/Views/ImageScrollView.swift` - Delete
- **Dependencies**: None
- **Verification**: iOS library structure clean
- **Complexity**: Low

#### Task 1.6: Update Android build.gradle Dependencies
- **Description**: Add flutter_comics dependency and required libraries
- **Files**:
  - `libs/flutter_puzzle/android/build.gradle` - Modify
- **Dependencies**: None
- **Verification**: Build configuration references flutter_comics, Gradle sync succeeds
- **Complexity**: Low

#### Task 1.7: Update iOS Package.swift Dependencies
- **Description**: Add flutter_comics dependency to iOS package
- **Files**:
  - `libs/flutter_puzzle/ios/puzzle/Package.swift` - Modify
- **Dependencies**: None
- **Verification**: iOS package depends on flutter_comics, builds successfully
- **Complexity**: Low

---

### Phase 2: Android Core Models (5 tasks)

#### Task 2.1: Copy Missing DownloadInfoMap.java
- **Description**: Copy DownloadInfoMap from legacy app with package updates
- **Files**:
  - `libs/flutter_puzzle/android/.../model/DownloadInfoMap.java` - Create
- **Dependencies**: Task 1.1
- **Verification**: DownloadInfoMap compiles with correct package
- **Complexity**: Low

#### Task 2.2: Remove App Dependencies from Puzzle.java
- **Description**: Remove references to Android Application context and app Settings, keep core puzzle logic
- **Files**:
  - `libs/flutter_puzzle/android/.../model/puzzle/Puzzle.java` - Modify
- **Dependencies**: Task 1.1
- **Verification**: Puzzle.java compiles without app dependencies, sound methods work
- **Complexity**: Medium

#### Task 2.3: Remove App Dependencies from Piece.java
- **Description**: Remove Activity/Context references, make download callback-based
- **Files**:
  - `libs/flutter_puzzle/android/.../model/puzzle/Piece.java` - Modify
- **Dependencies**: Task 1.1
- **Verification**: Piece.java library-friendly, no app dependencies
- **Complexity**: Medium

#### Task 2.4: Remove App Dependencies from Puzzles.java
- **Description**: Remove app Settings and Application context, keep singleton and persistence
- **Files**:
  - `libs/flutter_puzzle/android/.../model/puzzle/Puzzles.java` - Modify
- **Dependencies**: Task 1.1
- **Verification**: Puzzles.java singleton works without app dependencies
- **Complexity**: Medium

#### Task 2.5: Update PieceState.java for Library Use
- **Description**: Ensure PieceState works with updated package structure
- **Files**:
  - `libs/flutter_puzzle/android/.../model/puzzle/PieceState.java` - Modify
- **Dependencies**: Task 1.1
- **Verification**: PieceState compiles and serializes correctly
- **Complexity**: Low

---

### Phase 3: Android Puzzle Views (3 tasks)

#### Task 3.1: Update PieceView to Extend flutter_comics LayersView
- **Description**: Modify PieceView to extend LayersView from flutter_comics, preserve scroll mapping logic
- **Files**:
  - `libs/flutter_puzzle/android/.../controls/PieceView.java` - Modify
- **Dependencies**: Task 1.2, Task 1.6, Phase 2
- **Verification**: PieceView extends LayersView, scroll mapping works correctly
- **Complexity**: Medium

#### Task 3.2: Add Preview Mode Toggle to PieceView
- **Description**: Add togglePreview method that delegates to comics
- **Files**:
  - `libs/flutter_puzzle/android/.../controls/PieceView.java` - Modify
- **Dependencies**: Task 3.1
- **Verification**: Preview mode toggles properly
- **Complexity**: Low

#### Task 3.3: Add Sound Management to PieceView
- **Description**: Add pauseSounds, resumeSounds, releaseSounds methods
- **Files**:
  - `libs/flutter_puzzle/android/.../controls/PieceView.java` - Modify
- **Dependencies**: Task 3.1
- **Verification**: Sound lifecycle methods work
- **Complexity**: Low

---

### Phase 4: Android Flutter Bridge (4 tasks)

#### Task 4.1: Create PuzzleViewFactory.java
- **Description**: Create PlatformViewFactory for puzzle views
- **Files**:
  - `libs/flutter_puzzle/android/.../PuzzleViewFactory.java` - Create
- **Dependencies**: Phase 3
- **Verification**: ViewFactory creates PlatformView instances
- **Complexity**: Medium

#### Task 4.2: Create PuzzlePlatformView.java
- **Description**: Create PlatformView implementation with puzzle loading, piece management, method channel handling
- **Files**:
  - `libs/flutter_puzzle/android/.../PuzzlePlatformView.java` - Create
- **Dependencies**: Task 4.1, Phase 3
- **Verification**: PlatformView loads puzzles, handles method calls, manages pieces
- **Complexity**: High

#### Task 4.3: Extend PuzzlePlugin.java for PlatformView
- **Description**: Register PlatformView factory in plugin
- **Files**:
  - `libs/flutter_puzzle/android/.../PuzzlePlugin.java` - Modify
- **Dependencies**: Task 4.1
- **Verification**: Plugin registers PlatformView factory
- **Complexity**: Medium

#### Task 4.4: Add ZIP Archive Utilities for Android
- **Description**: Add ZIP loading logic to PuzzlePlatformView
- **Files**:
  - `libs/flutter_puzzle/android/.../PuzzlePlatformView.java` - Modify
- **Dependencies**: Task 4.2
- **Verification**: Puzzle ZIP loading works correctly
- **Complexity**: Medium

---

### Phase 5: iOS Core Models (4 tasks)

#### Task 5.1: Create Puzzles.swift Singleton
- **Description**: Port Puzzles.java to Swift with singleton pattern and persistence
- **Files**:
  - `libs/flutter_puzzle/ios/puzzle/Sources/puzzle/Model/Puzzles.swift` - Create
- **Dependencies**: Task 1.7
- **Verification**: Puzzles singleton manages collection with persistence
- **Complexity**: Medium

#### Task 5.2: Create PieceState.swift
- **Description**: Port PieceState.java to Swift with Codable
- **Files**:
  - `libs/flutter_puzzle/ios/puzzle/Sources/puzzle/Model/PieceState.swift` - Create
- **Dependencies**: Task 1.7
- **Verification**: PieceState struct with JSON serialization works
- **Complexity**: Low

#### Task 5.3: Update Puzzle.swift with Sound Management
- **Description**: Add sound coordination methods (toggleSounds, pauseSounds, etc.)
- **Files**:
  - `libs/flutter_puzzle/ios/puzzle/Sources/puzzle/Model/Puzzle.swift` - Modify
- **Dependencies**: Task 1.7
- **Verification**: Puzzle manages sound coordination across pieces
- **Complexity**: Medium

#### Task 5.4: Update Piece.swift with State Management
- **Description**: Add state property, download methods, comics reference
- **Files**:
  - `libs/flutter_puzzle/ios/puzzle/Sources/puzzle/Model/Piece.swift` - Modify
- **Dependencies**: Task 5.2
- **Verification**: Piece manages download state and comics reference
- **Complexity**: Medium

---

### Phase 6: iOS Puzzle Views (2 tasks)

#### Task 6.1: Create PieceView.swift
- **Description**: Port PieceView.java to Swift, wrap LayersView from flutter_comics
- **Files**:
  - `libs/flutter_puzzle/ios/puzzle/Sources/puzzle/Views/PieceView.swift` - Create
- **Dependencies**: Task 1.7, Phase 5
- **Verification**: PieceView wraps LayersView with scroll mapping logic
- **Complexity**: Medium

#### Task 6.2: Add Layout Calculation for PieceView
- **Description**: Implement layoutSubviews and position updates
- **Files**:
  - `libs/flutter_puzzle/ios/puzzle/Sources/puzzle/Views/PieceView.swift` - Modify
- **Dependencies**: Task 6.1
- **Verification**: PieceView handles layout correctly
- **Complexity**: Low

---

### Phase 7: iOS Flutter Bridge (4 tasks)

#### Task 7.1: Create PuzzleViewFactory.swift
- **Description**: Create FlutterPlatformViewFactory for puzzle views
- **Files**:
  - `libs/flutter_puzzle/ios/puzzle/Sources/puzzle/PuzzleViewFactory.swift` - Create
- **Dependencies**: Phase 6
- **Verification**: Factory creates PlatformView instances
- **Complexity**: Medium

#### Task 7.2: Create PuzzlePlatformView.swift
- **Description**: Create FlutterPlatformView with puzzle loading, piece management, method channel
- **Files**:
  - `libs/flutter_puzzle/ios/puzzle/Sources/puzzle/PuzzlePlatformView.swift` - Create
- **Dependencies**: Task 7.1, Phase 6
- **Verification**: PlatformView handles puzzle rendering and method calls
- **Complexity**: High

#### Task 7.3: Extend PuzzlePlugin.swift for PlatformView
- **Description**: Register PlatformView factory in plugin
- **Files**:
  - `libs/flutter_puzzle/ios/puzzle/Sources/puzzle/PuzzlePlugin.swift` - Modify
- **Dependencies**: Task 7.1
- **Verification**: Plugin registers PlatformView factory
- **Complexity**: Medium

#### Task 7.4: Add ArchiveManager for iOS ZIP Handling
- **Description**: Use ArchiveManager from flutter_comics for ZIP loading
- **Files**:
  - `libs/flutter_puzzle/ios/puzzle/Sources/puzzle/PuzzlePlatformView.swift` - Modify
- **Dependencies**: Task 7.2, Task 1.7
- **Verification**: ZIP loading uses flutter_comics ArchiveManager
- **Complexity**: Low

---

### Phase 8: Dart Bridge Layer (5 tasks)

#### Task 8.1: Create puzzle_platform_interface.dart
- **Description**: Define platform interface for puzzle plugin
- **Files**:
  - `libs/flutter_puzzle/lib/puzzle_platform_interface.dart` - Create
- **Dependencies**: None
- **Verification**: Platform interface compiles
- **Complexity**: Low

#### Task 8.2: Create puzzle_method_channel.dart
- **Description**: Implement method channel for platform communication
- **Files**:
  - `libs/flutter_puzzle/lib/puzzle_method_channel.dart` - Create
- **Dependencies**: Task 8.1
- **Verification**: Method channel implementation compiles
- **Complexity**: Low

#### Task 8.3: Create puzzle_view.dart Widget
- **Description**: Create PuzzleView widget with AndroidView/UiKitView and method channel
- **Files**:
  - `libs/flutter_puzzle/lib/widgets/puzzle_view.dart` - Create
- **Dependencies**: Task 8.2, Phase 4, Phase 7
- **Verification**: PuzzleView widget compiles and renders
- **Complexity**: High

#### Task 8.4: Create puzzle.dart Public API
- **Description**: Create library export file
- **Files**:
  - `libs/flutter_puzzle/lib/puzzle.dart` - Create
- **Dependencies**: Task 8.3
- **Verification**: Library exports public API correctly
- **Complexity**: Low

#### Task 8.5: Update pubspec.yaml Dependencies
- **Description**: Add flutter_comics dependency and configure plugin
- **Files**:
  - `libs/flutter_puzzle/pubspec.yaml` - Modify
- **Dependencies**: None
- **Verification**: Dependencies configured, flutter pub get succeeds
- **Complexity**: Low

---

### Phase 9: Example App & Documentation (4 tasks)

#### Task 9.1: Create Example App Structure
- **Description**: Generate Flutter example app
- **Files**:
  - `libs/flutter_puzzle/example/` - Create
- **Dependencies**: Phase 8
- **Verification**: Example app structure created
- **Complexity**: Low

#### Task 9.2: Implement Example App
- **Description**: Create main.dart with full puzzle demonstration
- **Files**:
  - `libs/flutter_puzzle/example/lib/main.dart` - Create
- **Dependencies**: Task 9.1
- **Verification**: Example app demonstrates all features
- **Complexity**: Medium

#### Task 9.3: Add Sample .puzzle File to Example
- **Description**: Copy test puzzle file and configure assets
- **Files**:
  - `libs/flutter_puzzle/example/assets/example.puzzle` - Copy
  - `libs/flutter_puzzle/example/pubspec.yaml` - Modify
- **Dependencies**: Task 9.2
- **Verification**: Example puzzle file loads in app
- **Complexity**: Low

#### Task 9.4: Create README.md for flutter_puzzle
- **Description**: Write comprehensive README with features, usage, API reference
- **Files**:
  - `libs/flutter_puzzle/README.md` - Create
- **Dependencies**: Phase 8
- **Verification**: README is comprehensive and accurate
- **Complexity**: Medium

---

### Phase 10: Testing & Validation (5 tasks)

#### Task 10.1: Create Android Unit Tests
- **Description**: Write unit tests for Puzzle, Piece, PieceView
- **Files**:
  - `libs/flutter_puzzle/android/src/test/java/net/nativemind/puzzle/PuzzleTest.java` - Create
  - `libs/flutter_puzzle/android/src/test/java/net/nativemind/puzzle/PieceTest.java` - Create
  - `libs/flutter_puzzle/android/src/test/java/net/nativemind/puzzle/PieceViewTest.java` - Create
- **Dependencies**: Phase 4
- **Verification**: Android tests pass
- **Complexity**: Medium

#### Task 10.2: Create iOS Unit Tests
- **Description**: Write unit tests for Puzzle, Piece, PieceView
- **Files**:
  - `libs/flutter_puzzle/ios/puzzle/Tests/puzzleTests/PuzzleTests.swift` - Create
  - `libs/flutter_puzzle/ios/puzzle/Tests/puzzleTests/PieceTests.swift` - Create
  - `libs/flutter_puzzle/ios/puzzle/Tests/puzzleTests/PieceViewTests.swift` - Create
- **Dependencies**: Phase 7
- **Verification**: iOS tests pass
- **Complexity**: Medium

#### Task 10.3: Create Flutter Integration Tests
- **Description**: Write integration tests for PuzzleView widget
- **Files**:
  - `libs/flutter_puzzle/test/puzzle_test.dart` - Create
- **Dependencies**: Phase 8
- **Verification**: Flutter integration tests pass
- **Complexity**: Medium

#### Task 10.4: Test with Real .puzzle Files
- **Description**: Manual testing on Android and iOS devices with real puzzle files
- **Files**: None (manual testing)
- **Dependencies**: Phase 9
- **Verification**: All features work on both platforms
- **Complexity**: Medium

#### Task 10.5: Performance Testing
- **Description**: Measure memory, frame rate, sound latency with profiling tools
- **Files**: None (profiling)
- **Dependencies**: Task 10.4
- **Verification**: Performance meets native app benchmarks
- **Complexity**: Medium

---

### Phase 11: Final Documentation & Cleanup (3 tasks)

#### Task 11.1: Create CHANGELOG.md
- **Description**: Document initial release version
- **Files**:
  - `libs/flutter_puzzle/CHANGELOG.md` - Create
- **Dependencies**: Phase 10
- **Verification**: CHANGELOG documents all features
- **Complexity**: Low

#### Task 11.2: Update _status.md to IMPLEMENTATION Complete
- **Description**: Mark SDD flow as complete
- **Files**:
  - `flows/sdd-flutter-puzzle/_status.md` - Modify
- **Dependencies**: Phase 10
- **Verification**: Status reflects completion
- **Complexity**: Low

#### Task 11.3: Create Migration Summary Document
- **Description**: Document migration metrics and decisions
- **Files**:
  - `libs/flutter_puzzle/MIGRATION.md` - Create
- **Dependencies**: Phase 10
- **Verification**: Migration summary is comprehensive
- **Complexity**: Medium

---

## Dependency Graph

```
Phase 1 (Setup & Cleanup)
  ├─> Phase 2 (Android Models)
  │    └─> Phase 3 (Android Views)
  │         └─> Phase 4 (Android Bridge)
  │
  └─> Phase 5 (iOS Models)
       └─> Phase 6 (iOS Views)
            └─> Phase 7 (iOS Bridge)

Phase 4 + Phase 7
  └─> Phase 8 (Dart Bridge)
       └─> Phase 9 (Example & Docs)
            └─> Phase 10 (Testing)
                 └─> Phase 11 (Final Docs)
```

---

## File Change Summary

| File | Action | Reason |
|------|--------|--------|
| `android/.../model/puzzle/*.java` | Modify | Fix package names, remove app dependencies |
| `android/.../controls/PieceView.java` | Modify | Extend flutter_comics LayersView, add methods |
| `android/.../utils/*.java` | Delete | Duplicates from flutter_comics |
| `android/.../screens/*.java` | Delete | App-specific UI code |
| `android/.../fragments/*.java` | Delete | App-specific UI code |
| `android/.../PuzzleViewFactory.java` | Create | Flutter PlatformView factory |
| `android/.../PuzzlePlatformView.java` | Create | Flutter PlatformView implementation |
| `ios/.../Views/TileImageView.swift` | Delete | Duplicate from flutter_comics |
| `ios/.../Views/ImageScrollView.swift` | Delete | Not needed |
| `ios/.../Model/Puzzles.swift` | Create | Missing singleton implementation |
| `ios/.../Model/PieceState.swift` | Create | Missing state model |
| `ios/.../Views/PieceView.swift` | Create | Missing view implementation |
| `ios/.../PuzzleViewFactory.swift` | Create | Flutter PlatformView factory |
| `ios/.../PuzzlePlatformView.swift` | Create | Flutter PlatformView implementation |
| `lib/puzzle_platform_interface.dart` | Create | Platform interface |
| `lib/puzzle_method_channel.dart` | Create | Method channel implementation |
| `lib/widgets/puzzle_view.dart` | Create | Main widget |
| `lib/puzzle.dart` | Create | Public API |
| `example/lib/main.dart` | Create | Example app |
| `README.md` | Create | Documentation |
| `CHANGELOG.md` | Create | Version history |
| `MIGRATION.md` | Create | Migration summary |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| flutter_comics not ready | High | High | Wait for flutter_comics completion before Phase 3/6 |
| Scroll mapping formula incorrect | Medium | High | Preserve exact logic from PieceView.java, test thoroughly |
| ZIP loading fails on iOS | Low | Medium | Use proven ArchiveManager from flutter_comics |
| Memory leaks with multiple pieces | Medium | Medium | Implement proper dispose() methods, profile memory |
| Sound coordination issues | Medium | High | Delegate to Puzzle.toggleSounds() → Comics API |
| Package name conflicts | Low | Low | Fixed in Phase 1, verify with clean build |

---

## Rollback Strategy

If implementation fails or needs to be reverted:

1. All changes are in `libs/flutter_puzzle/` directory - can delete entire directory
2. No changes to legacy apps in `apps/mahabharata-mobile-java-v2012` or `apps/mahabharata-mobile-swift-v2012`
3. No changes to flutter_comics library
4. Git history preserves all previous states for selective rollback

---

## Checkpoints

After each phase, verify:

- [ ] All code compiles without errors
- [ ] No new warnings in build output
- [ ] Unit tests pass (if applicable to phase)
- [ ] Manual smoke test on one platform
- [ ] Commit changes with descriptive message

---

## Open Implementation Questions

- [x] Download management strategy - RESOLVED: Callbacks to consuming app
- [x] iOS architecture - RESOLVED: Port from Java, use flutter_comics LayersView
- [ ] Error handling for corrupt .puzzle files - TBD during implementation
- [ ] Maximum puzzle size limits - TBD during performance testing
- [ ] Memory management for large piece counts - TBD during implementation

---

## Approval

- [ ] Plan reviewed by: _______
- [ ] Plan approved on: _______
- [ ] Ready to begin implementation: Yes / No
- [ ] Notes: _______________________________
