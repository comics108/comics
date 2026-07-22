# Implementation Plan: Comics Viewer Architecture Restructuring

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-21

## Overview

This plan breaks down the architecture restructuring into atomic, testable tasks organized by phase. Each task includes dependencies, complexity estimates, and verification criteria.

### Complexity Scale
- **XS**: < 30 minutes (simple file moves, config changes)
- **S**: 30-60 minutes (multiple file moves with imports)
- **M**: 1-2 hours (complex refactoring, build config)
- **L**: 2-4 hours (new component creation, testing)
- **XL**: 4+ hours (major integration work)

---

## Phase 1: Extract Android Library (comics-viewer-android)

### 1.1 Setup Android Library Structure

**Task 1.1.1: Create Android Library Directory Structure**
- **Complexity**: XS
- **Dependencies**: None
- **Actions**:
  - Create `/libs/comics_viewer/comics-viewer-android/`
  - Create directory structure: `src/main/java/net/nativemind/comics/viewer/{comics,puzzle}/{model,view,util}/`
  - Create `src/main/res/`
  - Create `src/test/java/`
- **Verification**: Directory structure exists

**Task 1.1.2: Create build.gradle Configuration**
- **Complexity**: S
- **Dependencies**: 1.1.1
- **Actions**:
  - Create `build.gradle` with namespace `net.nativemind.comics.viewer`
  - Add dependencies: AndroidX, Gson, ZIP expansion library
  - Configure minSdk 21, targetSdk 34
- **Verification**: `./gradlew build` runs without errors (empty project)

**Task 1.1.3: Create AndroidManifest.xml**
- **Complexity**: XS
- **Dependencies**: 1.1.1
- **Actions**:
  - Create `src/main/AndroidManifest.xml`
  - Set package name
  - Add required permissions (INTERNET, ACCESS_NETWORK_STATE)
- **Verification**: Manifest is valid XML

### 1.2 Migrate Comics Core Models

**Task 1.2.1: Migrate Comics Model Files**
- **Complexity**: S
- **Dependencies**: 1.1.2, 1.1.3
- **Files to Move** (4 files):
  - `model/visual/Comics.java` → `comics/model/Comics.java`
  - `model/visual/Layer.java` → `comics/model/Layer.java`
  - `model/visual/Image.java` → `comics/model/Image.java`
  - `model/visual/Sound.java` → `comics/model/Sound.java`
- **Actions**:
  - Copy files to new locations
  - Replace package: `com.fulldome.mahabharata` → `net.nativemind.comics.viewer.comics.model`
  - Fix imports to reference new packages
- **Verification**: Files compile without errors

**Task 1.2.2: Migrate Animation Model Files**
- **Complexity**: S
- **Dependencies**: 1.2.1
- **Files to Move** (9 files):
  - All files from `model/visual/animation/` → `comics/model/animation/`
- **Actions**:
  - Copy animation files
  - Replace package: `com.fulldome.mahabharata.model.visual.animation` → `net.nativemind.comics.viewer.comics.model.animation`
  - Fix imports, including references to parent Anim class
  - Update LayerAnimTypeAdapter Gson deserializer
- **Verification**: All animation classes compile

### 1.3 Migrate Comics Utilities

**Task 1.3.1: Migrate ComicsDescriptor**
- **Complexity**: S
- **Dependencies**: 1.2.1
- **Files to Move** (1 file):
  - `model/ComicsDescriptor.java` → `comics/util/ComicsDescriptor.java`
- **Actions**:
  - Copy file
  - Replace package to `net.nativemind.comics.viewer.comics.util`
  - Fix imports
  - Verify ZipResourceFile dependency is in build.gradle
- **Verification**: ComicsDescriptor compiles

**Task 1.3.2: Migrate ImageManager**
- **Complexity**: M
- **Dependencies**: 1.3.1
- **Files to Move** (2 files):
  - `utils/ImageManager.java` → `comics/util/ImageManager.java`
  - `utils/ImageCallListener.java` → `comics/util/ImageCallListener.java`
- **Actions**:
  - Copy files
  - Replace package
  - Remove analytics calls (FbUtils.logEvent, etc.)
  - Remove app-specific Activity dependencies
  - Keep LRU cache integration
- **Verification**: ImageManager compiles without app dependencies

**Task 1.3.3: Migrate ComicsUtils (Kotlin)**
- **Complexity**: S
- **Dependencies**: 1.3.2
- **Files to Move** (1 file):
  - `utils/ComicsUtils.kt` → `comics/util/ComicsUtils.kt`
- **Actions**:
  - Copy file
  - Replace package
  - Fix imports
- **Verification**: Kotlin file compiles

**Task 1.3.4: Migrate SoundManager**
- **Complexity**: M
- **Dependencies**: 1.2.1
- **Files to Move** (1 file):
  - `com.ironwaterstudio.utils/SoundManager.java` → `util/SoundManager.java`
- **Actions**:
  - Copy file
  - Replace package: `com.ironwaterstudio.utils` → `net.nativemind.comics.viewer.util`
  - Update imports in Sound.java to use new SoundManager package
- **Verification**: SoundManager and Sound.java compile together

### 1.4 Migrate Comics Views

**Task 1.4.1: Migrate LayersView**
- **Complexity**: M
- **Dependencies**: 1.2.2, 1.3.2
- **Files to Move** (1 file):
  - `controls/LayersView.java` → `comics/view/LayersView.java`
- **Actions**:
  - Copy file
  - Replace package to `net.nativemind.comics.viewer.comics.view`
  - Fix imports (Layer, Comics, ImageManager)
  - Remove app-specific UI code if any
- **Verification**: LayersView compiles

**Task 1.4.2: Migrate TileImageView**
- **Complexity**: M
- **Dependencies**: 1.4.1, 1.3.2
- **Files to Move** (1 file):
  - `controls/TileImageView.java` → `comics/view/TileImageView.java`
- **Actions**:
  - Copy file
  - Replace package
  - Fix imports (ImageManager, Image)
  - Verify tile rendering logic (512x512, zoom levels)
- **Verification**: TileImageView compiles

**Task 1.4.3: Migrate ZoomFrameLayout**
- **Complexity**: S
- **Dependencies**: 1.4.2
- **Files to Move** (1 file):
  - `controls/ZoomFrameLayout.java` → `comics/view/ZoomFrameLayout.java`
- **Actions**:
  - Copy file
  - Replace package
  - Fix imports
- **Verification**: ZoomFrameLayout compiles

### 1.5 Migrate Puzzle Models and Views

**Task 1.5.1: Migrate Puzzle Models**
- **Complexity**: M
- **Dependencies**: 1.2.1 (Puzzle depends on Comics)
- **Files to Move** (4 files):
  - `model/puzzle/Puzzle.java` → `puzzle/model/Puzzle.java`
  - `model/puzzle/Puzzles.java` → `puzzle/model/Puzzles.java`
  - `model/puzzle/Piece.java` → `puzzle/model/Piece.java`
  - `model/puzzle/PieceState.java` → `puzzle/model/PieceState.java`
- **Actions**:
  - Copy files
  - Replace package to `net.nativemind.comics.viewer.puzzle.model`
  - Fix imports (especially Comics references in Piece.java)
  - Remove app-specific Settings dependencies
  - Update serialization code
- **Verification**: All puzzle models compile

**Task 1.5.2: Migrate PieceView**
- **Complexity**: M
- **Dependencies**: 1.5.1, 1.4.1
- **Files to Move** (1 file):
  - `controls/PieceView.java` → `puzzle/view/PieceView.java`
- **Actions**:
  - Copy file
  - Replace package to `net.nativemind.comics.viewer.puzzle.view`
  - Fix imports (Piece, LayersView)
  - Remove app-specific UI code
- **Verification**: PieceView compiles and extends LayersView correctly

### 1.6 Build and Test Android Library

**Task 1.6.1: Run Full Build**
- **Complexity**: S
- **Dependencies**: 1.5.2 (all migrations complete)
- **Actions**:
  - Run `./gradlew :comics-viewer-android:build`
  - Fix any remaining compilation errors
  - Verify all classes compile
- **Verification**: Build succeeds with 0 errors

**Task 1.6.2: Create ProGuard Rules (if needed)**
- **Complexity**: S
- **Dependencies**: 1.6.1
- **Actions**:
  - Create `proguard-rules.pro`
  - Add keep rules for Gson models
  - Add keep rules for public API classes
- **Verification**: ProGuard rules file exists

---

## Phase 2: Extract iOS Swift Package (comics-viewer-ios)

### 2.1 Setup iOS Swift Package Structure

**Task 2.1.1: Create Swift Package Directory Structure**
- **Complexity**: XS
- **Dependencies**: None
- **Actions**:
  - Create `/libs/comics_viewer/comics-viewer-ios/`
  - Create `Sources/ComicsViewer/{Comics,Puzzle}/{Models,Views,Utils}/`
  - Create `Tests/ComicsViewerTests/`
- **Verification**: Directory structure exists

**Task 2.1.2: Create Package.swift**
- **Complexity**: S
- **Dependencies**: 2.1.1
- **Actions**:
  - Create `Package.swift` with package name "ComicsViewer"
  - Set platforms: iOS 13.0+, macOS 10.15+
  - Define library target
  - Define test target
- **Verification**: `swift build` runs (empty package)

### 2.2 Migrate Comics Core Models (iOS)

**Task 2.2.1: Migrate Comics Model Files (iOS)**
- **Complexity**: S
- **Dependencies**: 2.1.2
- **Files to Move** (4 files):
  - `Model/DataClasses/Visual/Comics.swift` → `Comics/Models/Comics.swift`
  - `Model/DataClasses/Visual/Layer.swift` → `Comics/Models/Layer.swift`
  - `Model/DataClasses/Visual/Image.swift` → `Comics/Models/Image.swift`
  - `Model/DataClasses/Visual/Sound.swift` → `Comics/Models/Sound.swift`
- **Actions**:
  - Copy files
  - Update imports: remove `Mahabharata` module references
  - Add `import ComicsViewer` where needed
  - Fix any app-specific dependencies
- **Verification**: Files compile

**Task 2.2.2: Migrate Animation Models (iOS)**
- **Complexity**: S
- **Dependencies**: 2.2.1
- **Files to Move** (6 files):
  - All animation files from `Model/DataClasses/Visual/Animations/` → `Comics/Models/Animations/`
- **Actions**:
  - Copy animation Swift files
  - Update imports
  - Verify Codable conformance for JSON parsing
- **Verification**: Animation models compile

### 2.3 Migrate Comics Views (iOS)

**Task 2.3.1: Migrate TileImageView (iOS)**
- **Complexity**: M
- **Dependencies**: 2.2.1
- **Files to Move** (1 file):
  - `Views/Tiles/TileImageView.swift` → `Comics/Views/TileImageView.swift`
- **Actions**:
  - Copy file
  - Update imports
  - Verify CATiledLayer usage
  - Remove app delegate references
- **Verification**: TileImageView compiles

**Task 2.3.2: Migrate ImageScrollView (iOS)**
- **Complexity**: L
- **Dependencies**: 2.3.1, 2.2.2
- **Files to Move** (1 file):
  - `Views/Tiles/ImageScrollView.swift` → `Comics/Views/ImageScrollView.swift`
- **Actions**:
  - Copy file (501 lines - complex)
  - Update imports
  - Remove ImageScrollViewDelegate protocol if app-specific
  - Remove reloadLanguage() or make it library-compatible
  - Remove Settings.shared references
  - Keep ALL sound playback logic
  - Keep layer transformation logic
- **Verification**: ImageScrollView compiles without app dependencies

### 2.4 Migrate Comics Utilities (iOS)

**Task 2.4.1: Migrate SoundManager (iOS)**
- **Complexity**: M
- **Dependencies**: 2.2.1
- **Files to Move** (2 files):
  - `Library/SoundManager/SoundManager.swift` → `Comics/Utils/SoundManager.swift`
  - `Extensions/AVPlayer/AVPlayer+Fade.swift` → `Comics/Utils/AVPlayer+Fade.swift`
- **Actions**:
  - Copy files
  - Update imports
  - Verify AVAudioSession integration
- **Verification**: SoundManager compiles

**Task 2.4.2: Migrate ArchiveManager (iOS)**
- **Complexity**: M
- **Dependencies**: 2.2.1
- **Files to Move** (1 file):
  - `Model/DataClasses/ArchiveManager.swift` → `Comics/Utils/ArchiveManager.swift`
- **Actions**:
  - Copy file
  - Update imports
  - Remove app-specific cache paths
  - Keep ZIP extraction logic
- **Verification**: ArchiveManager compiles

**Task 2.4.3: Migrate ImageManager and CacheManager (iOS)**
- **Complexity**: M
- **Dependencies**: 2.4.2
- **Files to Move** (2 files):
  - `Library/ImageManager/ImageManager.swift` → `Comics/Utils/ImageManager.swift`
  - `Library/CacheManager/CacheManager.swift` → `Comics/Utils/CacheManager.swift`
- **Actions**:
  - Copy files
  - Update imports
  - Remove analytics calls
  - Remove app-specific code
- **Verification**: Both managers compile

### 2.5 Migrate Puzzle Models (iOS)

**Task 2.5.1: Migrate Puzzle Models (iOS)**
- **Complexity**: S
- **Dependencies**: 2.2.1
- **Files to Move** (2 files):
  - `Model/DataClasses/Puzzle.swift` → `Puzzle/Models/Puzzle.swift`
  - `Model/DataClasses/Piece.swift` → `Puzzle/Models/Piece.swift`
- **Actions**:
  - Copy files
  - Update imports
  - Verify Piece references Comics correctly
- **Verification**: Puzzle models compile

**Task 2.5.2: Create Puzzles Singleton (iOS) - NEW**
- **Complexity**: M
- **Dependencies**: 2.5.1
- **Files to Create** (1 file):
  - `Puzzle/Models/Puzzles.swift` (port from Java)
- **Actions**:
  - Port logic from Java Puzzles.java (~100 lines)
  - Implement singleton pattern
  - Add save/load to UserDefaults or file
  - Add puzzle collection management
- **Verification**: Puzzles.swift compiles and implements required methods

**Task 2.5.3: Create PieceState Model (iOS) - NEW**
- **Complexity**: S
- **Dependencies**: 2.5.1
- **Files to Create** (1 file):
  - `Puzzle/Models/PieceState.swift` (port from Java)
- **Actions**:
  - Port from Java PieceState.java (~50 lines)
  - Codable struct
  - Properties: loadedVersion, savedFile, currentScroll, showPreview, downloadInfo
- **Verification**: PieceState.swift compiles

**Task 2.5.4: Create PieceView (iOS) - NEW**
- **Complexity**: M
- **Dependencies**: 2.3.2, 2.5.1
- **Files to Create** (1 file):
  - `Puzzle/Views/PieceView.swift` (port from Java)
- **Actions**:
  - Port from Java PieceView.java (~80 lines)
  - Wrap LayersView from Comics
  - Implement scroll mapping: `finalScroll = width * (scrollX / scrollArea)`
  - Handle preview mode toggle
- **Verification**: PieceView.swift compiles

### 2.6 Build and Test iOS Swift Package

**Task 2.6.1: Run Full Build (iOS)**
- **Complexity**: S
- **Dependencies**: 2.5.4 (all migrations complete)
- **Actions**:
  - Run `swift build`
  - Fix any remaining compilation errors
  - Verify all Swift files compile
- **Verification**: Build succeeds with 0 errors

**Task 2.6.2: Create README for Swift Package**
- **Complexity**: XS
- **Dependencies**: 2.6.1
- **Actions**:
  - Create `README.md` with usage instructions
  - Document how to integrate via SPM
- **Verification**: README exists

---

## Phase 3: Update Native Apps to Use Libraries

### 3.1 Update Android App (mahabharata-mobile-java-v2026)

**Task 3.1.1: Configure Gradle to Include Library**
- **Complexity**: S
- **Dependencies**: 1.6.1 (Android library builds)
- **Actions**:
  - Edit `settings.gradle`: add `include ':comics-viewer-android'`
  - Edit `app/build.gradle`: add `implementation project(':comics-viewer-android')`
  - Sync Gradle
- **Verification**: Gradle sync succeeds

**Task 3.1.2: Update Imports in App Code**
- **Complexity**: M
- **Dependencies**: 3.1.1
- **Actions**:
  - Global find/replace in app code:
    - `com.fulldome.mahabharata.model.visual` → `net.nativemind.comics.viewer.comics.model`
    - `com.fulldome.mahabharata.model.puzzle` → `net.nativemind.comics.viewer.puzzle.model`
    - `com.fulldome.mahabharata.controls.LayersView` → `net.nativemind.comics.viewer.comics.view.LayersView`
    - etc. for all migrated classes
  - Fix compilation errors
- **Verification**: App compiles

**Task 3.1.3: Delete Migrated Files from App**
- **Complexity**: S
- **Dependencies**: 3.1.2 (app compiles with new imports)
- **Actions**:
  - Delete all files that were migrated to comics-viewer-android
  - Verify no duplicate code exists
- **Verification**: App still compiles, no duplicates

**Task 3.1.4: Test Android App Functionality**
- **Complexity**: M
- **Dependencies**: 3.1.3
- **Actions**:
  - Run app on emulator/device
  - Test comics viewing
  - Test puzzle functionality
  - Verify sounds work
  - Verify animations work
- **Verification**: App functionality unchanged from before migration

### 3.2 Update iOS App (mahabharata-mobile-swift-v2026)

**Task 3.2.1: Add Swift Package Dependency**
- **Complexity**: S
- **Dependencies**: 2.6.1 (iOS package builds)
- **Actions**:
  - In Xcode: File → Add Package Dependencies
  - Add Local Package: select `/libs/comics-viewer-ios`
  - Link ComicsViewer to Mahabharata target
- **Verification**: Xcode recognizes package

**Task 3.2.2: Update Imports in App Code (iOS)**
- **Complexity**: M
- **Dependencies**: 3.2.1
- **Actions**:
  - Find all files importing migrated types
  - Add `import ComicsViewer` at top
  - Remove references to Mahabharata module for migrated types
  - Fix compilation errors
- **Verification**: App compiles

**Task 3.2.3: Delete Migrated Files from App (iOS)**
- **Complexity**: S
- **Dependencies**: 3.2.2
- **Actions**:
  - Delete all Swift files migrated to comics-viewer-ios
  - Remove from Xcode project
  - Verify no duplicate code
- **Verification**: App still compiles

**Task 3.2.4: Test iOS App Functionality**
- **Complexity**: M
- **Dependencies**: 3.2.3
- **Actions**:
  - Run app on simulator/device
  - Test comics viewing
  - Test puzzle functionality
  - Verify sounds work
  - Verify animations work
- **Verification**: App functionality unchanged from before migration

---

## Phase 4: Create Flutter Plugin Wrapper (flutter_comics_viewer)

### 4.1 Setup Flutter Plugin Structure

**Task 4.1.1: Create Flutter Plugin Directory**
- **Complexity**: S
- **Dependencies**: None
- **Actions**:
  - Create `/libs/comics_viewer/flutter_comics_viewer/` (may already exist)
  - Run `flutter create --template=plugin --platforms=android,ios flutter_comics_viewer`
  - Update `pubspec.yaml` with correct metadata
- **Verification**: Flutter plugin structure exists

**Task 4.1.2: Configure Android Gradle for Flutter**
- **Complexity**: M
- **Dependencies**: 4.1.1, 1.6.1
- **Actions**:
  - Edit `android/build.gradle`
  - Add dependency: `implementation project(':comics-viewer-android')`
  - Edit `android/settings.gradle` to include comics-viewer-android
  - Set namespace: `net.nativemind.flutter.comics.viewer`
- **Verification**: Android module builds

**Task 4.1.3: Configure iOS for Flutter**
- **Complexity**: M
- **Dependencies**: 4.1.1, 2.6.1
- **Actions**:
  - Edit `ios/flutter_comics_viewer.podspec`
  - Add dependency on ComicsViewer Swift Package
  - Set platform iOS 13.0+
- **Verification**: iOS module builds

### 4.2 Implement Flutter Platform Channel

**Task 4.2.1: Create Dart Public API**
- **Complexity**: M
- **Dependencies**: 4.1.1
- **Actions**:
  - Create `lib/flutter_comics_viewer.dart` (main export)
  - Create `lib/src/comics_viewer.dart` (widget)
  - Create `lib/src/comics_viewer_controller.dart` (controller)
  - Implement methods: loadComics, play, pause, setScrollPosition, etc.
  - Implement callbacks: onScrollChanged, onLoaded, onError
- **Verification**: Dart code compiles

**Task 4.2.2: Implement Android Native Bridge**
- **Complexity**: L
- **Dependencies**: 4.1.2, 4.2.1
- **Actions**:
  - Create `FlutterComicsViewerPlugin.java`
  - Implement MethodCallHandler
  - Bridge Dart methods to comics-viewer-android library
  - Implement platform view for rendering
  - Handle lifecycle (dispose, etc.)
- **Verification**: Android bridge compiles

**Task 4.2.3: Implement iOS Native Bridge**
- **Complexity**: L
- **Dependencies**: 4.1.3, 4.2.1
- **Actions**:
  - Create `FlutterComicsViewerPlugin.swift`
  - Implement FlutterPlugin protocol
  - Bridge Dart methods to ComicsViewer package
  - Implement platform view
  - Handle lifecycle
- **Verification**: iOS bridge compiles

### 4.3 Create Flutter Example App

**Task 4.3.1: Setup Example App**
- **Complexity**: M
- **Dependencies**: 4.2.3
- **Actions**:
  - Navigate to `example/`
  - Update `lib/main.dart` to use ComicsViewer widget
  - Verify `assets/sample.comics` exists
  - Update `pubspec.yaml` to include asset
- **Verification**: Example app compiles

**Task 4.3.2: Test Flutter Example on Android**
- **Complexity**: M
- **Dependencies**: 4.3.1
- **Actions**:
  - Run `flutter run` on Android emulator
  - Load sample.comics
  - Test all methods (play, pause, scroll, etc.)
  - Verify callbacks work
- **Verification**: Example works on Android

**Task 4.3.3: Test Flutter Example on iOS**
- **Complexity**: M
- **Dependencies**: 4.3.1
- **Actions**:
  - Run `flutter run` on iOS simulator
  - Load sample.comics
  - Test all methods
  - Verify callbacks work
- **Verification**: Example works on iOS

---

## Phase 5: Create React Native Module Wrapper (react-native-comics-viewer)

### 5.1 Setup React Native Module Structure

**Task 5.1.1: Create React Native Module Directory**
- **Complexity**: S
- **Dependencies**: None
- **Actions**:
  - Create `/libs/comics_viewer/react-native-comics-viewer/`
  - Initialize with `npx create-react-native-library`
  - Setup package.json with metadata
  - Create TypeScript source structure
- **Verification**: Module structure exists

**Task 5.1.2: Configure Android Gradle for React Native**
- **Complexity**: M
- **Dependencies**: 5.1.1, 1.6.1
- **Actions**:
  - Edit `android/build.gradle`
  - Add dependency: `implementation project(':comics-viewer-android')`
  - Edit `android/settings.gradle` to include comics-viewer-android
  - Set namespace: `net.nativemind.rn.comics.viewer`
- **Verification**: Android module builds

**Task 5.1.3: Configure iOS for React Native**
- **Complexity**: M
- **Dependencies**: 5.1.1, 2.6.1
- **Actions**:
  - Edit `ios/ComicsViewer.podspec`
  - Add dependency on ComicsViewer Swift Package
  - Set platform iOS 13.0+
- **Verification**: iOS module builds

### 5.2 Implement React Native Bridge

**Task 5.2.1: Create TypeScript Public API**
- **Complexity**: M
- **Dependencies**: 5.1.1
- **Actions**:
  - Create `src/index.ts` (main export)
  - Create `src/types.ts` (TypeScript interfaces)
  - Create `src/ComicsViewer.tsx` (component)
  - Implement methods: loadComics, play, pause, setScrollPosition, etc. (IDENTICAL to Flutter)
  - Implement callbacks: onScrollChanged, onLoaded, onError
- **Verification**: TypeScript compiles, types are correct

**Task 5.2.2: Implement Android Native Module**
- **Complexity**: L
- **Dependencies**: 5.1.2, 5.2.1
- **Actions**:
  - Create `ComicsViewerModule.java`
  - Create `ComicsViewerPackage.java`
  - Implement ReactContextBaseJavaModule
  - Bridge JS methods to comics-viewer-android library
  - Implement view manager for rendering
  - Handle lifecycle
- **Verification**: Android native module compiles

**Task 5.2.3: Implement iOS Native Module**
- **Complexity**: L
- **Dependencies**: 5.1.3, 5.2.1
- **Actions**:
  - Create `ComicsViewerModule.swift`
  - Create `ComicsViewerBridge.m` (Objective-C bridge)
  - Implement RCTBridgeModule protocol
  - Bridge JS methods to ComicsViewer package
  - Implement view manager
  - Handle lifecycle
- **Verification**: iOS native module compiles

### 5.3 Create React Native Example App

**Task 5.3.1: Setup Example App**
- **Complexity**: M
- **Dependencies**: 5.2.3
- **Actions**:
  - Navigate to `example/`
  - Update `App.tsx` to use ComicsViewer component
  - Add sample.comics to assets
  - Update metro.config.js if needed
- **Verification**: Example app compiles

**Task 5.3.2: Test React Native Example on Android**
- **Complexity**: M
- **Dependencies**: 5.3.1
- **Actions**:
  - Run `npx react-native run-android`
  - Load sample.comics
  - Test all methods (play, pause, scroll, etc.)
  - Verify callbacks work
- **Verification**: Example works on Android

**Task 5.3.3: Test React Native Example on iOS**
- **Complexity**: M
- **Dependencies**: 5.3.1
- **Actions**:
  - Run `npx react-native run-ios`
  - Load sample.comics
  - Test all methods
  - Verify callbacks work
- **Verification**: Example works on iOS

---

## Phase 6: API Consistency Validation & Testing

### 6.1 API Consistency Check

**Task 6.1.1: Verify Method Signatures Match**
- **Complexity**: S
- **Dependencies**: 4.2.1, 5.2.1
- **Actions**:
  - Compare Flutter API to React Native API
  - Verify method names are identical
  - Verify parameter names and types match
  - Verify return types match
- **Verification**: APIs are 100% identical

**Task 6.1.2: Verify Event/Callback Names Match**
- **Complexity**: S
- **Dependencies**: 4.2.1, 5.2.1
- **Actions**:
  - Compare callback names
  - Verify parameters passed to callbacks match
- **Verification**: Callbacks are identical

**Task 6.1.3: Verify Property Names Match**
- **Complexity**: S
- **Dependencies**: 4.2.1, 5.2.1
- **Actions**:
  - Compare read-only properties
  - Verify naming and types
- **Verification**: Properties are identical

### 6.2 Cross-Platform Testing

**Task 6.2.1: Create Test Matrix Document**
- **Complexity**: S
- **Dependencies**: None
- **Actions**:
  - Document all test scenarios
  - Create checklist for each platform/framework combination
  - Define success criteria
- **Verification**: Test matrix exists

**Task 6.2.2: Execute Full Test Suite**
- **Complexity**: XL
- **Dependencies**: All previous tasks
- **Actions**:
  - Test Android native app
  - Test iOS native app
  - Test Flutter Android
  - Test Flutter iOS
  - Test React Native Android
  - Test React Native iOS
  - Verify sample.comics renders identically on all platforms
  - Test all API methods on all platforms
- **Verification**: All tests pass

---

## Task Dependency Graph

```
Phase 1 (Android Library)
1.1.1 → 1.1.2, 1.1.3
1.1.2 → 1.2.1
1.2.1 → 1.2.2, 1.3.1, 1.3.4
1.2.2 → 1.4.1
1.3.1 → 1.3.2
1.3.2 → 1.3.3, 1.4.2
1.4.1 → 1.4.2
1.4.2 → 1.4.3
1.2.1 → 1.5.1
1.5.1 → 1.5.2
1.4.1 → 1.5.2
1.5.2 → 1.6.1
1.6.1 → 1.6.2

Phase 2 (iOS Package)
2.1.1 → 2.1.2
2.1.2 → 2.2.1
2.2.1 → 2.2.2, 2.3.1, 2.4.1, 2.4.2, 2.5.1
2.3.1 → 2.3.2
2.2.2 → 2.3.2
2.4.2 → 2.4.3
2.5.1 → 2.5.2, 2.5.3, 2.5.4
2.3.2 → 2.5.4
2.5.4 → 2.6.1
2.6.1 → 2.6.2

Phase 3 (Update Native Apps)
1.6.1 → 3.1.1
3.1.1 → 3.1.2
3.1.2 → 3.1.3
3.1.3 → 3.1.4

2.6.1 → 3.2.1
3.2.1 → 3.2.2
3.2.2 → 3.2.3
3.2.3 → 3.2.4

Phase 4 (Flutter)
4.1.1 → 4.1.2, 4.1.3, 4.2.1
1.6.1 → 4.1.2
2.6.1 → 4.1.3
4.2.1 → 4.2.2, 4.2.3
4.1.2 → 4.2.2
4.1.3 → 4.2.3
4.2.3 → 4.3.1
4.3.1 → 4.3.2, 4.3.3

Phase 5 (React Native)
5.1.1 → 5.1.2, 5.1.3, 5.2.1
1.6.1 → 5.1.2
2.6.1 → 5.1.3
5.2.1 → 5.2.2, 5.2.3
5.1.2 → 5.2.2
5.1.3 → 5.2.3
5.2.3 → 5.3.1
5.3.1 → 5.3.2, 5.3.3

Phase 6 (Validation)
4.2.1, 5.2.1 → 6.1.1, 6.1.2, 6.1.3
All tasks → 6.2.2
```

---

## Critical Path

The critical path (longest sequence of dependent tasks):

1. 1.1.1 → 1.1.2 → 1.2.1 → 1.2.2 → 1.4.1 → 1.4.2 → 1.5.2 → 1.6.1 → **[Android Library Complete]**
2. 4.1.1 → 4.1.2 → 4.2.1 → 4.2.2 → 4.2.3 → 4.3.1 → 4.3.2 → **[Flutter Complete]**
3. 6.2.2 **[Full Validation]**

**Estimated Critical Path Time**: ~20-25 hours of focused work

---

## Rollback Plan

If issues arise during implementation:

### Rollback Phase 1 (Android Library)
- Revert Gradle changes in native app
- Restore deleted files from git history
- Remove comics-viewer-android directory

### Rollback Phase 2 (iOS Package)
- Remove SPM dependency from Xcode
- Restore deleted Swift files from git
- Remove comics-viewer-ios directory

### Rollback Phase 3 (Native Apps)
- Git revert to commit before library integration
- Verify apps work as before

### Rollback Phase 4 & 5 (Wrappers)
- Simply delete flutter_comics_viewer or react-native-comics-viewer
- No impact on native apps or core libraries

---

## Success Criteria

### Phase 1 Success
- [x] comics-viewer-android builds standalone
- [x] All 28+ files migrated
- [x] Package names use net.nativemind.comics.viewer
- [x] No app dependencies

### Phase 2 Success
- [x] comics-viewer-ios builds standalone
- [x] All Swift files migrated
- [x] Package.swift valid
- [x] No app dependencies

### Phase 3 Success
- [x] Both native apps build with libraries
- [x] App functionality unchanged
- [x] No duplicate code

### Phase 4 Success
- [x] Flutter plugin builds for Android and iOS
- [x] Example app works on both platforms
- [x] API fully functional

### Phase 5 Success
- [x] React Native module builds for Android and iOS
- [x] Example app works on both platforms
- [x] API identical to Flutter

### Phase 6 Success
- [x] All platforms render sample.comics identically
- [x] All API methods work across all platforms
- [x] Flutter and RN APIs are 100% consistent

---

## Approval

- [x] Reviewed by: User
- [x] Approved on: 2026-07-21
- [x] Notes: Plan approved, proceeding with implementation
