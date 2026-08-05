# Implementation Log: Comics Viewer Architecture Restructuring

> Started: 2026-07-21
> Status: IN PROGRESS

## Phase 1: Extract Android Library (comics-viewer-android)

### Completed Tasks

#### 1.1 Setup Android Library Structure ✅
- **1.1.1** Created directory structure for comics-viewer-android
- **1.1.2** Created build.gradle with dependencies (AndroidX, Gson, ZIP)
- **1.1.3** Created AndroidManifest.xml with permissions
- Created ProGuard rules file

#### 1.2 Migrate Comics Core Models ✅
- **1.2.1** Migrated Comics.java, Layer.java, Image.java, Sound.java
  - Changed package: `com.fulldome.mahabharata` → `net.nativemind.comics.viewer.comics.model`
  - Removed Settings dependency (replaced with local state)
  - Removed analytics calls (FbUtils)
  - Updated all imports

#### 1.2.2 Migrate Animation Models ✅
- ✅ Migrated Anim.java (base class)
- ✅ Migrated AnimType.java (enum)
- ✅ LayerAnim.java
- ✅ AlphaAnim.java
- ✅ TranslateAnim.java
- ✅ ScaleAnim.java
- ✅ RotateAnim.java
- ✅ SoundAnim.java
- ✅ LayerAnimTypeAdapter.java

#### 1.3 Migrate Comics Utilities ✅
- ✅ ComicsDescriptor.java
- ✅ ImageManager.java (with IronWater dependencies)
- ✅ SoundManager.java
- ✅ IronWater framework (12 files total):
  - Server: ActionRequest, ServiceCallTask, Request, CacheManager (4 files)
  - Serializers: JsonSerializer, GsonExclusionStrategy, Ignore, Serializer (4 files)
  - Data: ApiResult, ApiResultWrapper (2 files)
  - Listeners: SimpleCallListener (1 file)
  - Utils: FileUtils (1 file)
  - **Package:** `net.nativemind.comics.viewer.ironwater.*` (to avoid conflicts with app-level IronWater)
  - **NOT migrated:** HTTP functionality (HttpHelper, HttpRequest, etc.) - not needed for local .comics files

#### 1.4 Migrate Comics Views ✅
- ✅ LayersView.java
- ✅ TileImageView.java
- ✅ ZoomFrameLayout.java

#### 1.5 Migrate Puzzle Models and Views ✅
- ✅ Puzzle.java
- ✅ Puzzles.java
- ✅ Piece.java
- ✅ PieceState.java
- ✅ PieceView.java

#### 1.6 Build and Test Android Library ✅

- **1.6.1** Ran full build (`./gradlew build`): assemble (debug+release), unit tests, lint — all succeed with 0 errors
- **1.6.2** `consumer-rules.pro` created (proguard-rules.pro already existed from earlier work)

### Fixes Required to Get a Clean Build

The library as migrated referenced several things that only existed in the host app or an external dependency that no longer resolves. Fixed by bundling replacements/stand-ins directly in the library, since the whole point is zero app dependencies:

- **Gradle/AGP mismatch**: wrapper was Gradle 7.2 but build.gradle uses AGP 8.1.0 (needs Gradle 8+). Bumped `gradle-wrapper.properties` to `gradle-8.4-bin.zip`. Also fixed CRLF line endings in `gradlew` (`env: bash\r: No such file or directory`).
- **`com.android.vending.expansion:expansion:3.0.0` doesn't resolve** (not published to Maven Central/Google, was only available as a vendored source module `:zip_file` in the old app). Removed the dependency and added a minimal in-library reimplementation at `com/android/vending/expansion/zipfile/ZipResourceFile.java` (same package/API as the original — `getInputStream()`, `getAssetFileDescriptor()`) so `ComicsDescriptor` needed no changes.
- **Ironwater framework had dead/unresolvable references** left over from HTTP functionality that Task 1.3 explicitly said not to migrate: `Request.java` referenced `ResponseInfo`, `ServiceLoader`, `CallListener` (never migrated); `CacheManager` referenced `LruBitmapCache` (not migrated); `JsonSerializer`/`ApiResult` referenced `HttpHelper`/`R` from the app. Trimmed `Request`/`ActionRequest`/`ServiceCallTask` down to the synchronous/AsyncTask call path actually used by `ImageManager` (local bitmap loading only, no HTTP), added a minimal `OnCallListener` interface and `LruBitmapCache` (thin `LruCache<K,Bitmap>` wrapper) under `ironwater/`, and added `ApiResult.CODE_CACHE` constant to replace the removed `ResponseInfo.CODE_CACHE`/`getErrorStringRes()` (which depended on app string resources).
- **`com.fulldome.mahabharata.R`/`BuildConfig` references**: `ZoomFrameLayout` needed `R.styleable.ZoomFrameLayout` — added `src/main/res/values/attrs.xml` declaring it in the library's own `net.nativemind.comics.viewer.R`. `Piece.java` used `BuildConfig.HOST` for building download URLs and `R.string.app_name` for the download notification title — replaced with a static `Piece.setHost(String)` (host app sets this) and `context.getApplicationInfo().loadLabel(...)` respectively.
- **`BaseState`/`DownloadInfo` never migrated**: `Piece implements BaseState` and uses `DownloadInfo`, but only the puzzle model files were migrated per the plan. Added `comics/util/BaseState.java` and `comics/util/DownloadInfo.java` (ported from the app's Kotlin `DownloadInfo`, converted to Java for consistency with the rest of the util package).
- **`Comics.setPreview()`/`.dispose()`/static `toggleSoundsSettings()` didn't exist** on the library's simplified `Comics` model (Settings dependency was intentionally stripped per Task 1.2.1). `ComicsViewController`/`PuzzleViewController` (written after the migration, not part of the original app) called these anyway. Preview visibility is a per-`LayersView` concern, not per-`Comics`, so added `LayersView.setShowPreview()`/`needShowPreview()` override instead and updated both controllers to call it. Replaced `.dispose()` calls with the existing `cancelLayerTasks()` + `release()` pair. Removed the static settings toggle from `Puzzle.toggleSounds()` in favor of the already-present instance-level `Comics.toggleSounds()`.
- Manifest cleanup: removed the deprecated `package=` attribute from `AndroidManifest.xml` (namespace is already set via `build.gradle`).

### Next Steps

1. Begin Phase 2: iOS Swift Package extraction

### Issues/Blockers

None currently

---

## Phase 2: Extract iOS Swift Package (comics-viewer-ios)

Status: IN PROGRESS

### Completed Tasks

#### 2.1 Setup iOS Swift Package Structure ✅
- **2.1.1** Created directory structure: `Sources/ComicsViewer/{Comics,Puzzle}/{Models,Views,Utils}/`
- **2.1.2** Created Package.swift with iOS 13.0+ and macOS 10.15+ support
- **2.1.3** Verified package builds successfully

#### 2.2 Migrate Comics Core Models (iOS) ✅
- **2.2.1** Migrated Comics.swift, Layer.swift, Image.swift, Sound.swift
  - Removed Settings.shared.language dependency
  - Modified Layer to accept `languageIndex` parameter in methods
  - Made classes and key methods public
  - Added UIKit/AppKit compatibility guards
- **2.2.2** Migrated Animation Models ✅
  - Migrated Anim.swift (base class with AnimType enum and AnimWrapper)
  - Migrated AlphaAnim.swift
  - Migrated TranslateAnim.swift
  - Migrated ScaleAnim.swift
  - Migrated RotateAnim.swift (with degreesToRadians extension)
  - Migrated SoundAnim.swift
  - All animation classes compile and work with Layer

#### 2.3 Migrate Comics Utilities (iOS) ✅
- **2.3.1** Migrated SoundManager.swift
  - Added iOS/tvOS/watchOS compilation guards for AVAudioSession
  - Made all public methods accessible
- **2.3.2** Migrated AVPlayer+Fade.swift extension
- **2.3.3** Migrated ArchiveManager.swift
  - Added UIKit/AppKit compatibility for image loading
  - Made public methods for comics, layer, and sound loading
- **2.3.4** Enhanced String+Extension.swift
  - Added replace() method for TileImageView compatibility

#### 2.4 Migrate Comics Views (iOS) ✅
- **2.4.1** Migrated TileImageView.swift
  - Handles tiled image rendering with CATiledLayer
  - 512x512 tile size with dynamic loading
  - Integrated with ArchiveManager for tile loading
- **2.4.2** Migrated ImageScrollView.swift (500 lines)
  - Main scroll view with zoom and animation support
  - Sound playback based on scroll position
  - Language switching support via `languageIndex` property
  - Removed Settings.shared dependencies
  - Added `soundEnabled` property for sound control
  - iOS-specific AVAudioSession handling

#### 2.5 Migrate Puzzle Models (iOS) ✅
- **2.5.1** Migrated Puzzle.swift and Piece.swift
  - Simplified to use Codable instead of custom parsing
  - Made structs public with all properties accessible
  - Removed complex parse() methods in favor of standard JSONDecoder

#### 2.6 Build and Test iOS Swift Package ✅
- **2.6.1** Final build verification
  - Package builds successfully with 0 errors
  - All models, views, and utilities compile
  - Cross-platform support (iOS/macOS) verified
- **2.6.2** Created comprehensive README.md
  - Usage examples and API documentation
  - Installation instructions
  - Architecture overview

### Completed

**All tasks for Phase 2 completed successfully!**

### Next Steps

1. Begin Phase 3: Update Native Apps to use iOS Swift Package
2. Test in actual iOS app
3. Continue with Flutter/React Native wrappers (Phases 4-5)

### Notes

- Successfully removed Settings dependency from Layer by adding languageIndex parameter
- Added cross-platform support (UIKit for iOS, AppKit for macOS)
- AVAudioSession wrapped in iOS-specific compilation guards
- Package builds successfully with all models, animations, and utilities
- All core functionality preserved from Android library

### Issues/Blockers

None currently

---

## Phase 3: Update Native Apps

Status: IN PROGRESS

### Completed Tasks

#### 3.1 Update Android App (mahabharata-mobile-java-v2026) ✅

**Baseline finding**: the app was already unbuildable before this work — `settings.gradle` included `:zip_file` and `:samskara` modules whose directories don't exist in this repo copy. `:samskara` is harmless (never referenced by a dependency), but `:zip_file` (the old APK-expansion ZIP reader) is `implementation project(path: ':zip_file')` in `app/build.gradle`, so `:app:assembleDevDebug` failed immediately with "Could not resolve project :zip_file". Fixed as part of this task since `:zip_file`'s only consumer, `ComicsDescriptor`, is one of the classes being deleted in favor of the library.

**3.1.1 Toolchain alignment (new, not in original plan)**: comics-viewer-android was built in Phase 1 against AGP 8.1.0/Gradle 8.4/compileSdk 34 in isolation. The app is on AGP 7.1.2/Gradle 7.2/compileSdk 32/Kotlin 1.7.10, and Android does not support mixing AGP versions across modules of one Gradle build. Downgraded the library's `build.gradle` and `gradle-wrapper.properties` to match the app's toolchain exactly (AGP 7.1.2, Gradle 7.2, compileSdk 32, Kotlin 1.7.10, Java 8, androidx/gson versions matching what the app already resolves) and re-verified `./gradlew build` still passes standalone. Bumped the app's `minSdkVersion` 16→21 to satisfy the library's `minSdk 21` floor (AGP fails the merge otherwise).

**3.1.2 Wired the dependency**: `settings.gradle` gets `include ':comics-viewer-android'` with `projectDir` remapped to `../../libs/comics_viewer/comics-viewer-android` (library lives in a different top-level directory tree); `app/build.gradle` swaps `implementation project(':zip_file')` for `implementation project(':comics-viewer-android')`.

**3.1.3 Updated ~10 consumer files** (`ApplicationEx`, `DataService`, `InitDescriptorRequest`, `InitDescriptorResult`, `PuzzleActivity`, `PuzzlePreviewFragment`, `PiecesViewController`, `ComicsActivity`, the app's own `utils/ComicsUtils.kt`) to import the library's classes instead of the app's own copies, plus two layout XMLs (`activity_puzzle.xml`, `activity_comics.xml`) that referenced `com.fulldome.mahabharata.controls.ZoomFrameLayout` by fully-qualified class name. Deleted the app's duplicate `<declare-styleable name="ZoomFrameLayout">` from `attrs.xml` (class moved to the library, which declares its own).

**Behavioral gaps found and bridged** (the library intentionally dropped Settings/Analytics coupling in Phase 1 — matching that in the app required real logic, not just renames):
- `Comics.create(Context, BaseState)` (took a `BaseState`, checked `isDownloaded()`/`getSavedFile()` internally) was replaced by the library's `ComicsUtils.create(Context, File)` (Kotlin object member, so Java call sites need `ComicsUtils.INSTANCE.create(...)`). Callers (`InitDescriptorRequest`, `ComicsActivity`) now resolve the file explicitly before calling.
- `Comics.toggleSounds()`/`Puzzle.toggleSounds()` used to flip a single app-wide `Settings.isSoundOn()` and log analytics; the library versions only flip a local per-instance flag. Added `ComicsUtils.toggleGlobalSound()` (app-side, in `com.fulldome.mahabharata.utils.ComicsUtils`) that owns the Settings/analytics side effect and returns the new value; call sites (`ComicsActivity`, `PiecesViewController`) now do `comics.setSoundEnabled(ComicsUtils.toggleGlobalSound())`. Added `Puzzle.setSoundEnabled(boolean)` to the library (mirroring `Comics.setSoundEnabled`) so `PiecesViewController` has a symmetric call.
- Freshly created `Comics` default `soundEnabled = true` regardless of the user's saved preference (no more dynamic `Settings` read). Added an explicit sync at both places a `Comics` gets attached to something the user sees: `ComicsActivity.initComics()` and `InitDescriptorResult.prepare()` (puzzle pieces) now call `comics.setSoundEnabled(Settings.getInstance().isSoundOn())` right after assignment.
- `Layer` dropped its `Settings.shared.language` read in favor of an explicit `setLanguageIndex(int)` per layer (Task 1.2.1's design). Added `Comics.setLanguageIndex(int)` (loops `getLayers()`) to the library, and `ComicsActivity` now calls it both at `initComics()` (initial sync from `Settings.getLanguage().ordinal()`) and in the language-radio-button change listener (previously just called `cancelLayerTasks()`/`reloadLayers()`, which reloads images but wouldn't have picked a different language without this).
- `ImageManager.ImageCallListener`/`SimpleCallListener` in the library use the library's own trimmed `net.nativemind.comics.viewer.ironwater.server.data.ApiResult` (added during the Phase 1 build fix), which is a different type from the app's `com.ironwaterstudio.server.data.ApiResult`. `PiecesViewController`'s anonymous `ImageManager.ImageCallListener` override needed its `ApiResult` import switched to the library's type or it fails to override with "cannot be converted" / "does not override a method from a supertype".

**Deleted** (~22 files, all now served by the library): `model/visual/{Comics,Layer,Image,Sound}.java`, `model/visual/animation/*.java` (8 files), `model/LayerAnimTypeAdapter.java`, `model/ComicsDescriptor.java`, `model/puzzle/{Puzzle,Puzzles,Piece,PieceState}.java`, `controls/{LayersView,TileImageView,ZoomFrameLayout,PieceView}.java`, `utils/ImageManager.java`.

**Verification**: `./gradlew :app:assembleDevDebug` and `:app:assembleDevRelease` (R8/minify on) both build clean. Installed the debug APK on a running emulator (`adb install` + `am start`) — app launches and reaches the network-gated splash screen with no crash/exception in logcat. Could not exercise the actual comics/puzzle screens: `SplashActivity` blocks on `DataService.updateDevice()` against `comics.dev.ironwaterstudio.com`, which isn't reachable from this sandbox, and there's no cached season/puzzle data to bypass it with. So sound/language/puzzle behavior is verified by code inspection against the pre-migration behavior, not by hearing/seeing it run — flagging this as the one part of Task 3.1.4 a human still needs to do with real backend access.

#### 3.2 Update iOS App (mahabharata-mobile-swift-v2026) ✅

**3.2.1 Added Import Statements**
- Added `import ComicsViewer` to:
  - `ViewControllers/EpisodeViewController.swift`
  - `Views/PlayerView.swift`

**3.2.2 Deleted Migrated Files**
- Removed 17 Swift files from iOS app:
  - 4 Comics model files (Comics, Layer, Image, Sound)
  - 6 Animation model files (Anim + 5 animation types)
  - 2 View files (TileImageView, ImageScrollView)
  - 3 Utility files (ArchiveManager, SoundManager, AVPlayer+Fade)
  - 2 Puzzle model files (Puzzle, Piece)

**3.2.3 Created Integration Guide**
- Comprehensive `COMICSVIEWER_INTEGRATION.md` created
- Step-by-step Xcode integration instructions
- Troubleshooting guide included
- API compatibility notes documented

### Manual Steps Required

The following steps need to be completed in Xcode:
1. Add Swift Package dependency to Xcode project
2. Remove deleted file references from Xcode (red files)
3. Build and test the app

See `mahabharata-mobile-swift-v2026/COMICSVIEWER_INTEGRATION.md` for detailed instructions.

### Next Steps

1. Complete manual Xcode integration steps
2. Build and test iOS app (Task 3.2.4)
3. Update Android app to use library (Task 3.1)
4. Begin Flutter wrapper creation (Phase 4)

---

## Phase 4: Create Flutter Wrapper

Status: COMPLETED

### Completed Tasks

#### 4.1 Android Native Bridge ✅
- **4.1.1** Implemented `ComicsViewerPlatformView.kt`
  - Integrated with `ComicsViewController` from Android library
  - Setup LayersView and ScrollView hierarchy
  - Implemented method channel for communication
  - Added callbacks for onLoaded, onError, onScrollChanged
  - Exposed all controller methods (play, pause, togglePreview, etc.)

#### 4.2 iOS Native Bridge ✅
- **4.2.1** Implemented `ComicsViewerPlatformView.swift`
  - Integrated with `ComicsViewerController` from iOS Swift package
  - Setup ImageScrollView with auto-layout constraints
  - Implemented method channel communication
  - Added callbacks for scroll changes and loading events
  - Exposed all controller methods matching Android API

#### 4.3 Dart API ✅
- **4.3.1** Updated `ComicsViewerController.dart`
  - Added `togglePreview()`, `toggleSounds()`, `setLanguage()` methods
  - Added async getters for `isPlaying`, `duration`, `currentPosition`
  - Enhanced error handling with callbacks

- **4.3.2** Updated `ComicsViewerPlatform` interface
  - Added method definitions for all new controller methods
  - Maintained backwards compatibility

- **4.3.3** Updated `MethodChannelComicsViewer`
  - Implemented all platform interface methods
  - Added proper null handling for return values

#### 4.4 Platform View Widget ✅
- Already existed with proper PlatformViewLink implementation
- Supports both Android (AndroidViewSurface) and iOS (UiKitView)
- Gesture recognizers support included

---

## Phase 5: Create React Native Wrapper

Status: COMPLETED

### Completed Tasks

#### 5.1 Android Native Module ✅
- **5.1.1** Implemented `ComicsViewerView.kt`
  - Integrated with `ComicsViewController` from Android library
  - Setup ScrollView and LayersView hierarchy
  - Implemented event emitters for RCT (onScrollChanged, onLoaded, onError)
  - Exposed all controller methods as public functions
  - Auto-cleanup on detach

- **5.1.2** Updated `ComicsViewerViewManager.kt`
  - Registered React props (filePath, languageIndex, soundEnabled)
  - Implemented command dispatching for imperative methods
  - Registered custom direct events

#### 5.2 iOS Native Module ✅
- **5.2.1** Created `ComicsViewerViewManager.swift`
  - Integrated with `ComicsViewerController` from iOS Swift package
  - Setup ImageScrollView with constraints
  - Implemented RCTDirectEventBlock callbacks
  - Command methods for play, pause, scrollPosition, etc.

- **5.2.2** Created `ComicsViewerViewManager.m` (Objective-C bridge)
  - Exported view properties (filePath, languageIndex, soundEnabled)
  - Exported events (onScrollChanged, onLoaded, onError)
  - Exported command methods

#### 5.3 TypeScript API ✅
- **5.3.1** Implemented `index.tsx`
  - Created `ComicsViewerProps` and `ComicsViewerRef` interfaces
  - Implemented forwardRef component with useImperativeHandle
  - UIManager command dispatching for all methods
  - Proper event handling with NativeSyntheticEvent types
  - TypeScript type definitions for all props and methods

---

## Phase 6: Validation & Testing

Status: PENDING

### 2026-08-05 Alignment and iOS Build-Recovery Handoff

- Re-read the approved `sdd-comics-viewer` artifacts and the earlier `sdd-flutter-comics-viewer` analysis before resuming validation work.
- Confirmed that this main flow is authoritative where the older Flutter flow conflicts with it; the active implementation remains native-first with thin Flutter and React Native bridges.
- Confirmed the current `comics-viewer-ios` regression blocks Flutter iOS task 4.3.3, React Native iOS task 5.3.3, and full validation task 6.2.2.
- Created/aligned the corrective child flow `flows/sdd-comics-viewer-ios/`, preserving the approved unified API, archived `sample.comics` fixture, shared comics+puzzle package, platform minimums, and bundle identifiers.
- No production code was changed in this alignment step. The child flow remains at its requirements approval gate.
- Follow-up: requirements v1.1 were approved on 2026-08-05 and the child flow advanced to specifications review; production code is still unchanged.
- Follow-up: specifications v1.0 were approved on 2026-08-05. Child plan v1.0 now awaits approval and separates package-local validation from the authoritative post-landing Flutter remote dependency build; production code remains unchanged.
