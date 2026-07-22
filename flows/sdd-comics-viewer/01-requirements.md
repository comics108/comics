# Requirements: Comics Viewer Architecture Restructuring

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-21

## Problem Statement

The current comics and puzzle viewer implementations are tightly coupled within the mahabharata-mobile applications (Java and Swift versions). This creates several problems:

1. **No Code Reusability**: Comics and puzzle rendering code cannot be used by other applications or frameworks (Flutter, React Native)
2. **Code Duplication Across Frameworks**: To support Flutter and React Native, the entire rendering logic would need to be duplicated
3. **Maintenance Complexity**: Bug fixes and features must be updated in multiple locations
4. **No Clear Separation of Concerns**: App-specific code is mixed with reusable rendering logic

The goal is to restructure the architecture by extracting comics and puzzle rendering into standalone, reusable libraries that can be consumed by the native apps, Flutter, and React Native.

## User Stories

### Primary

**As a** library consumer (native app, Flutter plugin, React Native module)
**I want** a standalone Android Library and iOS Swift Package for comics/puzzle rendering
**So that** I can integrate comics viewing capabilities without reimplementing the rendering logic

**As a** Flutter developer
**I want** a thin Flutter plugin wrapper around native libraries
**So that** I can display comics and puzzles in Flutter applications with minimal integration effort

**As a** React Native developer
**I want** a thin React Native module wrapper around native libraries
**So that** I can display comics and puzzles in React Native applications with consistent API

**As a** maintainer
**I want** a single source of truth for rendering logic
**So that** bug fixes and features propagate to all consuming frameworks

### Secondary

**As a** developer
**I want** identical public APIs across Flutter and React Native wrappers
**So that** knowledge transfers between frameworks and documentation stays consistent

**As a** library integrator
**I want** clear separation between viewer logic and app-specific concerns
**So that** I can use the library without app-specific dependencies

## Acceptance Criteria

### Must Have

#### Step 1: Extract Native Libraries

1. **Given** comics and puzzle code exists in mahabharata-mobile-java-v2026
   **When** extracting to comics-viewer-android
   **Then** all relevant files are moved (not rewritten) with only path/package fixes

2. **Given** comics and puzzle code exists in mahabharata-mobile-swift-v2026
   **When** extracting to comics-viewer-ios
   **Then** all relevant files are moved (not rewritten) with only import/bundle fixes

3. **Given** the extracted libraries
   **When** building
   **Then** bundle ID is net.nativemind.comics.viewer for all components

#### Step 2: Update Native App Dependencies

4. **Given** comics-viewer-android library exists
   **When** mahabharata-mobile-java-v2026 builds
   **Then** it uses `implementation project(":comics-viewer-android")` instead of local code

5. **Given** comics-viewer-ios Swift Package exists
   **When** mahabharata-mobile-swift-v2026 builds
   **Then** it imports the package via Swift Package Manager

#### Step 3: Create Framework Wrappers

6. **Given** comics-viewer-android and comics-viewer-ios libraries
   **When** creating flutter_comics_viewer
   **Then** it wraps native libraries for both Android (implementation project) and iOS (SPM)

7. **Given** comics-viewer-android and comics-viewer-ios libraries
   **When** creating react-native-comics-viewer
   **Then** it wraps native libraries for both Android (implementation project) and iOS (SPM)

8. **Given** flutter_comics_viewer and react-native-comics-viewer
   **When** examining their public APIs
   **Then** methods, naming, and parameters are identical across both frameworks

#### Bundle ID & Puzzle Handling

9. **Given** the bundle ID requirement of net.nativemind.comics.viewer
   **When** integrating with puzzle functionality
   **Then** a clear strategy exists for handling bundle IDs in Flutter/React Native contexts

10. **Given** existing analysis in sdd-flutter-comics-viewer and sdd-flutter-puzzle-viewer
    **When** implementing wrappers
    **Then** insights from previous analysis are incorporated

11. **Given** sample.comics file in libs/comics_viewer/flutter_comics_viewer/example/assets
    **When** using for testing
    **Then** file remains archived (not extracted) and used as-is

### Should Have

1. **Consistent Error Handling**: Identical error codes and messages across all wrappers
2. **Documentation**: Clear integration guides for each wrapper (Flutter, React Native)
3. **Example Apps**: Working examples in flutter_comics_viewer/example and react-native-comics-viewer/example
4. **Version Alignment**: All libraries versioned together for compatibility

### Won't Have (This Iteration)

1. **Rewriting Code**: All code must be moved, not rewritten from scratch
2. **Feature Additions**: Focus is on restructuring, not adding new features
3. **Breaking API Changes**: Native libraries should maintain existing behavior
4. **Backend Integration**: Backend communication stays in app layer
5. **Analytics**: Event tracking remains app responsibility

## Constraints

- **Technical**:
  - Bundle ID: net.nativemind.comics.viewer
  - Android: Gradle project structure with implementation project(":comics-viewer-android")
  - iOS: Swift Package Manager with local or remote package import
  - Flutter: Platform channels for both Android and iOS
  - React Native: Turbo Modules or legacy bridge for both platforms

- **File Organization**:
  - Android Library: `/libs/comics_viewer/comics-viewer-android/`
  - iOS Swift Package: `/libs/comics_viewer/comics-viewer-ios/`
  - Flutter Plugin: `/libs/comics_viewer/flutter_comics_viewer/`
  - React Native Module: `/libs/comics_viewer/react-native-comics-viewer/`

- **Migration Rules**:
  - NO code rewriting - only file moves
  - ONLY minor fixes allowed: paths, imports, bundle IDs
  - Preserve all existing functionality
  - Maintain backward compatibility where possible

- **API Consistency**:
  - Flutter and React Native wrappers must have identical:
    - Method names
    - Parameter names and types
    - Return types
    - Error handling patterns

## Framework Wrapper API Requirements

### Unified Public API (Flutter & React Native)

Both framework wrappers must expose identical functionality:

#### Core Methods

```
ComicsViewer.loadComics(filePath: string): Promise<void>
ComicsViewer.play(): void
ComicsViewer.pause(): void
ComicsViewer.setScrollPosition(position: number): void
ComicsViewer.getScrollPosition(): number
ComicsViewer.togglePreview(show: boolean): void
ComicsViewer.toggleSounds(enabled: boolean): void
ComicsViewer.dispose(): void
```

#### Events/Callbacks

```
onScrollChanged(position: number): void
onComicsLoaded(): void
onError(error: Error): void
```

#### Properties

```
isPlaying: boolean
duration: number (total scrollable height)
currentPosition: number
```

### Bundle ID Strategy Options

User must choose approach for bundle ID handling:

**Option A - Unified Bundle ID**
- All components use net.nativemind.comics.viewer
- Simplest but may conflict if multiple viewers in same app

**Option B - Scoped Bundle IDs**
- Comics: net.nativemind.comics.viewer
- Puzzle: net.nativemind.puzzle.viewer
- More flexible but requires coordination

**Option C - Framework-Specific Prefixes**
- Flutter: net.nativemind.flutter.comics.viewer
- React Native: net.nativemind.rn.comics.viewer
- Clear ownership but more bundle IDs to manage

## Directory Structure

### Target Structure

```
/libs/
├── comics-viewer-android/              # Android Library
│   ├── build.gradle
│   ├── src/main/java/net/nativemind/comics/viewer/
│   │   ├── comics/                     # Comics rendering (moved from mahabharata-mobile-java-v2026)
│   │   └── puzzle/                     # Puzzle rendering (moved from mahabharata-mobile-java-v2026)
│   └── ...
│
├── comics-viewer-ios/                  # iOS Swift Package
│   ├── Package.swift
│   ├── Sources/ComicsViewer/
│   │   ├── Comics/                     # Comics rendering (moved from mahabharata-mobile-swift-v2026)
│   │   └── Puzzle/                     # Puzzle rendering (moved from mahabharata-mobile-swift-v2026)
│   └── ...
│
├── comics_viewer/
│   ├── flutter_comics_viewer/          # Flutter Plugin
│   │   ├── android/                    # Uses implementation project(":comics-viewer-android")
│   │   ├── ios/                        # Uses SPM import of comics-viewer-ios
│   │   ├── lib/                        # Dart wrapper code
│   │   └── example/                    # Example Flutter app
│   │       └── assets/sample.comics    # Test file (already exists)
│   │
│   └── react-native-comics-viewer/     # React Native Module
│       ├── android/                    # Uses implementation project(":comics-viewer-android")
│       ├── ios/                        # Uses SPM import of comics-viewer-ios
│       ├── src/                        # JavaScript/TypeScript wrapper
│       └── example/                    # Example RN app
│
├── comics_viewer/
│   └── mahabharata-mobile-java-v2026/  # Updated to use comics-viewer-android
│       └── app/build.gradle            # implementation project(":comics-viewer-android")
│
└── comics_viewer/
    └── mahabharata-mobile-swift-v2026/ # Updated to use comics-viewer-ios via SPM
```

## Migration Strategy

### Phase 1: Extract Android Library

1. Create `/libs/comics_viewer/comics-viewer-android/` structure
2. Move comics rendering code from mahabharata-mobile-java-v2026
3. Move puzzle rendering code from mahabharata-mobile-java-v2026
4. Fix package names: `com.fulldome.mahabharata` → `net.nativemind.comics.viewer`
5. Update internal imports
6. Configure build.gradle with bundle ID
7. Test standalone build

### Phase 2: Extract iOS Swift Package

1. Create `/libs/comics_viewer/comics-viewer-ios/` with Package.swift
2. Move comics rendering code from mahabharata-mobile-swift-v2026
3. Move puzzle rendering code from mahabharata-mobile-swift-v2026
4. Fix imports and module references
5. Update bundle identifiers
6. Configure Package.swift
7. Test standalone build

### Phase 3: Update Native Apps

1. Update mahabharata-mobile-java-v2026/app/build.gradle
   - Add: `implementation project(":comics-viewer-android")`
   - Remove local comics/puzzle code
2. Update mahabharata-mobile-swift-v2026 Package.swift or Xcode project
   - Add SPM dependency on comics-viewer-ios
   - Remove local comics/puzzle code
3. Test both apps build and run correctly

### Phase 4: Create Flutter Wrapper

1. Setup flutter_comics_viewer plugin structure
2. Android: Configure build.gradle with `implementation project(":comics-viewer-android")`
3. iOS: Configure podspec or Package.swift to depend on comics-viewer-ios
4. Implement Dart wrapper matching unified API
5. Create example app using sample.comics
6. Test on both platforms

### Phase 5: Create React Native Wrapper

1. Setup react-native-comics-viewer module structure
2. Android: Configure build.gradle with `implementation project(":comics-viewer-android")`
3. iOS: Configure podspec to depend on comics-viewer-ios
4. Implement JS/TS wrapper matching unified API (identical to Flutter)
5. Create example app
6. Test on both platforms

## Open Questions

- [x] Which bundle ID strategy should we use (A, B, or C)?
  - **DECIDED**: Option C - Framework-specific prefixes
    - Core library: net.nativemind.comics.viewer
    - Flutter: net.nativemind.flutter.comics.viewer
    - React Native: net.nativemind.rn.comics.viewer

- [x] Should puzzle functionality be in the same library or separate?
  - **DECIDED**: Puzzle in same library as comics

- [ ] How to handle versioning across all libraries?
  - **To Decide**: Monorepo versioning vs independent versioning

- [ ] What's the strategy for testing extracted libraries?
  - **To Decide**: Unit tests, integration tests, or rely on app-level tests

- [ ] How to handle asset bundling (sounds, images) in libraries?
  - **Analysis Needed**: Review how assets are currently loaded

- [ ] Should we support dynamic framework vs static linking for iOS?
  - **To Decide**: Performance vs app size trade-offs

## References

- **Existing Analysis**:
  - `flows/sdd-flutter-comics-viewer/` - Flutter comics analysis
  - `flows/sdd-flutter-puzzle-viewer/` - Flutter puzzle analysis

- **Source Code Locations**:
  - Android Source: `libs/comics_viewer/mahabharata-mobile-java-v2026/`
  - iOS Source: `libs/comics_viewer/mahabharata-mobile-swift-v2026/`
  - Flutter Example: `libs/comics_viewer/flutter_comics_viewer/example/`

- **Test Assets**:
  - Sample Comics: `libs/comics_viewer/flutter_comics_viewer/example/assets/sample.comics`

---

## Approval

- [x] Reviewed by: User
- [x] Approved on: 2026-07-21
- [x] Notes: Bundle ID Option C (framework-specific prefixes), puzzle in same library as comics
