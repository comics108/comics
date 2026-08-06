# Specifications: Comics Viewer Architecture Restructuring

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-21

## Architecture Overview

This specification defines the restructuring of comics and puzzle rendering code from tightly-coupled native apps into standalone, reusable libraries that can be consumed by native apps, Flutter, and React Native.

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Application Layer                             │
│  - mahabharata-mobile-java-v2026                                │
│  - mahabharata-mobile-swift-v2026                               │
└────────────────────────┬────────────────────────────────────────┘
                         │ (uses via Gradle/SPM)
         ┌───────────────┴────────────────┐
         │                                │
┌────────▼──────────┐          ┌─────────▼────────┐
│ comics-viewer-    │          │ comics-viewer-   │
│ android           │          │ ios              │
│                   │          │                  │
│ - Comics Models   │          │ - Comics Models  │
│ - Puzzle Models   │          │ - Puzzle Models  │
│ - Rendering Views │          │ - Rendering Views│
│ - Utils           │          │ - Utils          │
└────────┬──────────┘          └─────────┬────────┘
         │                                │
         │ (wrapped by)    (wrapped by)   │
         │                                │
┌────────▼──────────┐          ┌─────────▼────────┐
│ flutter_comics_   │          │ react-native-    │
│ viewer            │          │ comics-viewer    │
│                   │          │                  │
│ Android: impl     │          │ Android: impl    │
│  project(:lib)    │          │  project(:lib)   │
│ iOS: SPM          │          │ iOS: SPM         │
└───────────────────┘          └──────────────────┘
```

### Bundle ID Strategy (Approved: Option C)

**Core Libraries:**
- Android: `net.nativemind.comics.viewer`
- iOS: `net.nativemind.comics.viewer`

**Flutter Wrapper:**
- Plugin ID: `net.nativemind.flutter.comics.viewer`
- Android: uses core library bundle ID
- iOS: uses core library bundle ID

**React Native Wrapper:**
- Module ID: `net.nativemind.rn.comics.viewer`
- Android: uses core library bundle ID
- iOS: uses core library bundle ID

---

## Part 1: Android Library Extraction (comics-viewer-android)

### 1.1 Directory Structure

```
/libs/comics_viewer/comics-viewer-android/
├── build.gradle
├── src/
│   ├── main/
│   │   ├── java/net/nativemind/comics/viewer/
│   │   │   ├── comics/
│   │   │   │   ├── model/           # Comics data models
│   │   │   │   ├── view/            # Rendering views
│   │   │   │   └── util/            # Comics utilities
│   │   │   └── puzzle/
│   │   │       ├── model/           # Puzzle data models
│   │   │       └── view/            # Puzzle views
│   │   ├── res/                     # Resources (if any)
│   │   └── AndroidManifest.xml
│   └── test/
└── proguard-rules.pro
```

### 1.2 File Migration Map (Android)

**IMPORTANT - SOURCE LOCATION:**
- **Original Source:** `/legacy/mahabharata-mobile-java-v2012/` (DO NOT MODIFY)
- **All files must be COPIED (not moved) from the legacy source**
- **Writing code from scratch is PROHIBITED**
- **Only minor fixes allowed:** package names, imports, bundle IDs

#### Comics Core Models
**Source Location:** `/legacy/mahabharata-mobile-java-v2012/app/src/main/java/com/fulldome/mahabharata/`
**Source Package:** `com.fulldome.mahabharata.model.visual`
**Target Package:** `net.nativemind.comics.viewer.comics.model`

| Source File | Target Location | Changes Required |
|-------------|----------------|------------------|
| `model/visual/Comics.java` | `comics/model/Comics.java` | Package rename only |
| `model/visual/Layer.java` | `comics/model/Layer.java` | Package rename only |
| `model/visual/Image.java` | `comics/model/Image.java` | Package rename only |
| `model/visual/Sound.java` | `comics/model/Sound.java` | Package rename only |

#### Animation Models
**Source Package:** `com.fulldome.mahabharata.model.visual.animation`
**Target Package:** `net.nativemind.comics.viewer.comics.model.animation`

| Source File | Target Location | Changes Required |
|-------------|----------------|------------------|
| `model/visual/animation/Anim.java` | `comics/model/animation/Anim.java` | Package rename only |
| `model/visual/animation/AnimType.java` | `comics/model/animation/AnimType.java` | Package rename only |
| `model/visual/animation/AlphaAnim.java` | `comics/model/animation/AlphaAnim.java` | Package rename + import fixes |
| `model/visual/animation/TranslateAnim.java` | `comics/model/animation/TranslateAnim.java` | Package rename + import fixes |
| `model/visual/animation/ScaleAnim.java` | `comics/model/animation/ScaleAnim.java` | Package rename + import fixes |
| `model/visual/animation/RotateAnim.java` | `comics/model/animation/RotateAnim.java` | Package rename + import fixes |
| `model/visual/animation/SoundAnim.java` | `comics/model/animation/SoundAnim.java` | Package rename + import fixes |
| `model/visual/animation/LayerAnim.java` | `comics/model/animation/LayerAnim.java` | Package rename + import fixes |
| `model/visual/animation/LayerAnimTypeAdapter.java` | `comics/model/animation/LayerAnimTypeAdapter.java` | Package rename only |

#### Comics Utilities
**Source Package:** `com.fulldome.mahabharata`
**Target Package:** `net.nativemind.comics.viewer.comics.util`

| Source File | Target Location | Changes Required |
|-------------|----------------|------------------|
| `model/ComicsDescriptor.java` | `comics/util/ComicsDescriptor.java` | Package rename + import fixes |
| `utils/ImageManager.java` | `comics/util/ImageManager.java` | Package rename + remove analytics |
| `utils/ImageCallListener.java` | `comics/util/ImageCallListener.java` | Package rename only |
| `utils/ComicsUtils.kt` | `comics/util/ComicsUtils.kt` | Package rename + import fixes |

#### Comics Views
**Source Package:** `com.fulldome.mahabharata.controls`
**Target Package:** `net.nativemind.comics.viewer.comics.view`

| Source File | Target Location | Changes Required |
|-------------|----------------|------------------|
| `controls/LayersView.java` | `comics/view/LayersView.java` | Package rename + import fixes |
| `controls/TileImageView.java` | `comics/view/TileImageView.java` | Package rename + import fixes |
| `controls/ZoomFrameLayout.java` | `comics/view/ZoomFrameLayout.java` | Package rename + import fixes |

#### Puzzle Models
**Source Package:** `com.fulldome.mahabharata.model.puzzle`
**Target Package:** `net.nativemind.comics.viewer.puzzle.model`

| Source File | Target Location | Changes Required |
|-------------|----------------|------------------|
| `model/puzzle/Puzzle.java` | `puzzle/model/Puzzle.java` | Package rename + import fixes |
| `model/puzzle/Puzzles.java` | `puzzle/model/Puzzles.java` | Package rename + import fixes |
| `model/puzzle/Piece.java` | `puzzle/model/Piece.java` | Package rename + import fixes |
| `model/puzzle/PieceState.java` | `puzzle/model/PieceState.java` | Package rename + import fixes |

#### Puzzle Views
**Source Package:** `com.fulldome.mahabharata.controls`
**Target Package:** `net.nativemind.comics.viewer.puzzle.view`

| Source File | Target Location | Changes Required |
|-------------|----------------|------------------|
| `controls/PieceView.java` | `puzzle/view/PieceView.java` | Package rename + import fixes |

#### Shared Dependencies (IronWaterStudio Framework)

**IMPORTANT - IronWater Package Strategy:**

IronWater framework exists in TWO places with DIFFERENT package names to avoid conflicts:

**1. Application Level (mahabharata-mobile-java-v2026):**
- **Package:** `com.ironwaterstudio.*` (ORIGINAL)
- **Location:** `/apps/mahabharata-mobile-java-v2026/app/src/main/java/com/ironwaterstudio/`
- **Purpose:** App-level functionality (HTTP requests, UI controls, backend integration)
- **Scope:** Full IronWater framework including HTTP

**2. Library Level (comics-viewer-android):**
- **Package:** `net.nativemind.comics.viewer.ironwater.*` (RENAMED)
- **Location:** `/libs/comics_viewer/comics-viewer-android/src/main/java/net/nativemind/comics/viewer/ironwater/`
- **Purpose:** Internal library dependencies (async execution, caching, JSON serialization)
- **Scope:** Minimal subset - NO HTTP functionality

**Why Different Packages:**
- Prevents class conflicts between app and library
- Library is self-contained and autonomous
- App can update its IronWater independently
- Clear separation: library internals vs app utilities

**IronWater Components - Library Migration Map:**

| Source Package | Target Package | Components | Migrate? |
|----------------|----------------|------------|----------|
| `com.ironwaterstudio.server` | `net.nativemind.comics.viewer.ironwater.server` | ActionRequest, ServiceCallTask, Request, CacheManager | ✅ YES |
| `com.ironwaterstudio.server.serializers` | `net.nativemind.comics.viewer.ironwater.serializers` | JsonSerializer, GsonExclusionStrategy, Ignore, Serializer | ✅ YES |
| `com.ironwaterstudio.server.data` | `net.nativemind.comics.viewer.ironwater.server.data` | ApiResult, ApiResultWrapper | ✅ YES |
| `com.ironwaterstudio.server.listeners` | `net.nativemind.comics.viewer.ironwater.server.listeners` | SimpleCallListener | ✅ YES |
| `com.ironwaterstudio.utils` | `net.nativemind.comics.viewer.ironwater.utils` | FileUtils | ✅ YES |
| `com.ironwaterstudio.utils` | `net.nativemind.comics.viewer.util` | SoundManager (standalone) | ✅ YES |
| `com.ironwaterstudio.server.http` | N/A | HttpHelper, HttpRequest, HttpImageRequest, PersistentCookieStore, etc. | ❌ NO |

**NOT Migrated (HTTP functionality - 10+ files):**
- All `/server/http/` directory components
- Reason: Comics library works ONLY with local .comics files (ZIP archives), NO network access needed
- File downloading is responsibility of consuming application

**Required Fix:**
- `JsonSerializer.java` line 16: Replace `HttpHelper.CT_JSON` with hardcoded `"application/json"`
- Reason: HttpHelper not migrated, only constant value needed

### 1.3 Simplified Public API (Android)

**IMPORTANT:** To unify the API across all platforms (Android, iOS, Flutter, React Native), create a simplified controller class that wraps internal complexity.

#### ComicsViewController Class

High-level controller matching Flutter/React Native API.

**File:** `src/main/java/net/nativemind/comics/viewer/ComicsViewController.java`

```java
package net.nativemind.comics.viewer;

public class ComicsViewController {
    // Properties
    public boolean isPlaying();
    public float getDuration();
    public float getCurrentPosition();

    // Methods (matching Flutter/RN API)
    public void loadComics(String filePath, ComicsLoadListener listener);
    public void play();
    public void pause();
    public void setScrollPosition(float position);
    public float getScrollPosition();
    public void togglePreview(boolean show);
    public void toggleSounds(boolean enabled);
    public void setLanguage(int languageIndex);
    public void dispose();

    // Callbacks
    public interface ComicsLoadListener {
        void onLoaded();
        void onError(String error);
    }

    public interface ScrollListener {
        void onScrollChanged(float position);
    }

    public void setScrollListener(ScrollListener listener);
}
```

#### PuzzleViewController Class

High-level controller for puzzles.

**File:** `src/main/java/net/nativemind/comics/viewer/PuzzleViewController.java`

```java
package net.nativemind.comics.viewer;

public class PuzzleViewController {
    // Properties
    public int getCurrentPieceIndex();
    public int getTotalPieces();

    // Methods
    public void loadPuzzle(String filePath, PuzzleLoadListener listener);
    public void selectPiece(int index);
    public void play();
    public void pause();
    public void togglePreview(boolean show);
    public void toggleSounds(boolean enabled);
    public void dispose();

    // Callbacks
    public interface PuzzleLoadListener {
        void onLoaded();
        void onError(String error);
    }

    public interface PieceSelectListener {
        void onPieceSelected(int index);
    }

    public void setPieceSelectListener(PieceSelectListener listener);
}
```

**Usage in v2026 apps:**
```java
// Instead of working with LayersView, ComicsDescriptor, etc. directly:
ComicsViewController controller = new ComicsViewController(context, layersView);
controller.loadComics("/path/to/file.comics", new ComicsViewController.ComicsLoadListener() {
    @Override
    public void onLoaded() {
        controller.play();
    }
    @Override
    public void onError(String error) {
        Log.e(TAG, "Error: " + error);
    }
});
```

**Benefits:**
- Unified API across all platforms
- Hides internal complexity (LayersView, ComicsDescriptor, ImageManager)
- Easier migration for apps
- Matches Flutter/React Native API exactly

### 1.4 Build Configuration (Android)

**File:** `/libs/comics_viewer/comics-viewer-android/build.gradle`

```gradle
plugins {
    id 'com.android.library'
    id 'kotlin-android'
}

android {
    namespace 'net.nativemind.comics.viewer'
    compileSdk 34

    defaultConfig {
        minSdk 21
        targetSdk 34

        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles "consumer-rules.pro"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = '11'
    }
}

dependencies {
    // AndroidX
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'

    // JSON parsing
    implementation 'com.google.code.gson:gson:2.10.1'

    // ZIP handling (for .comics files)
    implementation 'com.android.vending.expansion:expansion:3.0.0'

    // Testing
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
}
```

**File:** `/libs/comics_viewer/comics-viewer-android/src/main/AndroidManifest.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="net.nativemind.comics.viewer">

    <!-- Required permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

</manifest>
```

### 1.4 Package Rename Rules

**Global Find & Replace:**
```
Find:    com.fulldome.mahabharata
Replace: net.nativemind.comics.viewer

Find:    com.ironwaterstudio.server
Replace: net.nativemind.comics.viewer.ironwater.server

Find:    com.ironwaterstudio.utils.SoundManager
Replace: net.nativemind.comics.viewer.util.SoundManager

Find:    com.ironwaterstudio.utils (other files)
Replace: net.nativemind.comics.viewer.ironwater.utils
```

**Import Cleanup:**
- Remove app-specific imports (Settings, Analytics, etc.)
- Remove Activity/Fragment imports (if migrating to library components)
- Update internal cross-references between migrated files

**IronWater-Specific Fixes:**
1. **JsonSerializer.java**: Replace HTTP dependency
   ```java
   // BEFORE (references non-existent HttpHelper):
   private static final String[] CONTENT_TYPES = new String[]{HttpHelper.CT_JSON};

   // AFTER (hardcoded constant):
   private static final String[] CONTENT_TYPES = new String[]{"application/json"};
   ```

2. **Verify no other HTTP references** in migrated IronWater files

---

## Part 2: iOS Swift Package Extraction (comics-viewer-ios)

### 2.1 Directory Structure

```
/libs/comics_viewer/comics-viewer-ios/
├── Package.swift
├── Sources/
│   └── ComicsViewer/
│       ├── Comics/
│       │   ├── Models/          # Comics data models
│       │   ├── Views/           # Rendering views
│       │   └── Utils/           # Comics utilities
│       └── Puzzle/
│           ├── Models/          # Puzzle data models
│           └── Views/           # Puzzle views
├── Tests/
│   └── ComicsViewerTests/
└── README.md
```

### 2.2 Simplified Public API (iOS)

**IMPORTANT:** Create a simplified Swift controller class matching the Android/Flutter/React Native API.

#### ComicsViewerController Class

High-level controller matching Android/Flutter/React Native API.

**File:** `Sources/ComicsViewer/ComicsViewerController.swift`

```swift
import Foundation
import UIKit

public class ComicsViewerController {
    // Properties
    public var isPlaying: Bool { get }
    public var duration: CGFloat { get }
    public var currentPosition: CGFloat { get }

    // Initialization
    public init(scrollView: ImageScrollView)

    // Methods (matching Android/Flutter/RN API)
    public func loadComics(filePath: String, completion: @escaping (Result<Void, Error>) -> Void)
    public func play()
    public func pause()
    public func setScrollPosition(_ position: CGFloat)
    public func getScrollPosition() -> CGFloat
    public func togglePreview(_ show: Bool)
    public func toggleSounds(_ enabled: Bool)
    public func setLanguage(_ languageIndex: Int)
    public func dispose()

    // Callbacks
    public var onScrollChanged: ((CGFloat) -> Void)?
}
```

#### PuzzleViewerController Class

High-level controller for puzzles.

**File:** `Sources/ComicsViewer/PuzzleViewerController.swift`

```swift
import Foundation

public class PuzzleViewerController {
    // Properties
    public var currentPieceIndex: Int { get }
    public var totalPieces: Int { get }

    // Initialization
    public init()

    // Methods
    public func loadPuzzle(filePath: String, completion: @escaping (Result<Void, Error>) -> Void)
    public func selectPiece(_ index: Int)
    public func play()
    public func pause()
    public func togglePreview(_ show: Bool)
    public func toggleSounds(_ enabled: Bool)
    public func dispose()

    // Callbacks
    public var onPieceSelected: ((Int) -> Void)?
}
```

**Usage in v2026 apps:**
```swift
// Instead of working with ImageScrollView, ArchiveManager, etc. directly:
let scrollView = ImageScrollView()
let controller = ComicsViewerController(scrollView: scrollView)

controller.onScrollChanged = { position in
    print("Position: \(position)")
}

controller.loadComics(filePath: comicsURL.path) { result in
    switch result {
    case .success:
        controller.play()
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

**Benefits:**
- Unified API across all platforms
- Hides internal complexity (ImageScrollView, ArchiveManager, SoundManager)
- Easier migration for apps
- Matches Android/Flutter/React Native API exactly

### 2.3 File Migration Map (iOS)

**IMPORTANT - SOURCE LOCATION:**
- **Original Source:** `/legacy/mahabharata-mobile-swift-v2012/` (DO NOT MODIFY)
- **All files must be COPIED (not moved) from the legacy source**
- **Writing code from scratch is PROHIBITED**
- **Only minor fixes allowed:** imports, module references, bundle IDs

#### Comics Core Models
**Source Location:** `/legacy/mahabharata-mobile-swift-v2012/Mahabharata/`
**Source Path:** `Mahabharata/Model/DataClasses/Visual/`
**Target Path:** `Sources/ComicsViewer/Comics/Models/`

| Source File | Target Location | Changes Required |
|-------------|----------------|------------------|
| `Model/DataClasses/Visual/Comics.swift` | `Comics/Models/Comics.swift` | Import fixes only |
| `Model/DataClasses/Visual/Layer.swift` | `Comics/Models/Layer.swift` | Import fixes only |
| `Model/DataClasses/Visual/Image.swift` | `Comics/Models/Image.swift` | Import fixes only |
| `Model/DataClasses/Visual/Sound.swift` | `Comics/Models/Sound.swift` | Import fixes only |

#### Animation Models
**Source Path:** `Mahabharata/Model/DataClasses/Visual/Animations/`
**Target Path:** `Sources/ComicsViewer/Comics/Models/Animations/`

| Source File | Target Location | Changes Required |
|-------------|----------------|------------------|
| `Animations/Anim.swift` | `Comics/Models/Animations/Anim.swift` | Import fixes only |
| `Animations/AlphaAnim.swift` | `Comics/Models/Animations/AlphaAnim.swift` | Import fixes only |
| `Animations/TranslateAnim.swift` | `Comics/Models/Animations/TranslateAnim.swift` | Import fixes only |
| `Animations/ScaleAnim.swift` | `Comics/Models/Animations/ScaleAnim.swift` | Import fixes only |
| `Animations/RotateAnim.swift` | `Comics/Models/Animations/RotateAnim.swift` | Import fixes only |
| `Animations/SoundAnim.swift` | `Comics/Models/Animations/SoundAnim.swift` | Import fixes only |

#### Comics Views
**Source Path:** `Mahabharata/Views/Tiles/`
**Target Path:** `Sources/ComicsViewer/Comics/Views/`

| Source File | Target Location | Changes Required |
|-------------|----------------|------------------|
| `Views/Tiles/TileImageView.swift` | `Comics/Views/TileImageView.swift` | Import fixes only |
| `Views/Tiles/ImageScrollView.swift` | `Comics/Views/ImageScrollView.swift` | Import fixes + remove app delegate refs |

#### Comics Utilities
**Source Path:** `Mahabharata/Library/` and `Mahabharata/Model/DataClasses/`
**Target Path:** `Sources/ComicsViewer/Comics/Utils/`

| Source File | Target Location | Changes Required |
|-------------|----------------|------------------|
| `Library/ImageManager/ImageManager.swift` | `Comics/Utils/ImageManager.swift` | Import fixes + remove analytics |
| `Library/CacheManager/CacheManager.swift` | `Comics/Utils/CacheManager.swift` | Import fixes only |
| `Library/SoundManager/SoundManager.swift` | `Comics/Utils/SoundManager.swift` | Import fixes only |
| `Extensions/AVPlayer/AVPlayer+Fade.swift` | `Comics/Utils/AVPlayer+Fade.swift` | Import fixes only |
| `Model/DataClasses/ArchiveManager.swift` | `Comics/Utils/ArchiveManager.swift` | Import fixes + remove app refs |

#### Puzzle Models
**Source Path:** `Mahabharata/Model/DataClasses/`
**Target Path:** `Sources/ComicsViewer/Puzzle/Models/`

| Source File | Target Location | Changes Required |
|-------------|----------------|------------------|
| `Model/DataClasses/Puzzle.swift` | `Puzzle/Models/Puzzle.swift` | Import fixes only |
| `Model/DataClasses/Piece.swift` | `Puzzle/Models/Piece.swift` | Import fixes only |

**Note:** Puzzle views may not exist in Swift version. If needed, port from Android PieceView.

### 2.3 Build Configuration (iOS)

**File:** `/libs/comics_viewer/comics-viewer-ios/Package.swift`

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ComicsViewer",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "ComicsViewer",
            targets: ["ComicsViewer"]
        ),
    ],
    dependencies: [
        // Add external dependencies if needed
        // .package(url: "https://github.com/ZipArchive/ZipArchive.git", from: "2.5.5")
    ],
    targets: [
        .target(
            name: "ComicsViewer",
            dependencies: [],
            path: "Sources/ComicsViewer"
        ),
        .testTarget(
            name: "ComicsViewerTests",
            dependencies: ["ComicsViewer"],
            path: "Tests/ComicsViewerTests"
        ),
    ]
)
```

### 2.4 Import Cleanup Rules

**Remove App-Specific Imports:**
```swift
// Remove these:
import MahabharataApp
import AnalyticsManager
import Settings

// Keep these:
import Foundation
import UIKit
import AVFoundation
```

**Update Module References:**
```swift
// Old:
import Mahabharata

// New:
import ComicsViewer
```

---

## Part 3: Update Native Apps to Use Libraries

### 3.1 Android App Integration

**File:** `/apps/mahabharata-mobile-java-v2026/settings.gradle`

Add module:
```gradle
include ':app'
include ':comics-viewer-android'
project(':comics-viewer-android').projectDir = new File(rootDir, '../../libs/comics_viewer/comics-viewer-android')
```

**File:** `/apps/mahabharata-mobile-java-v2026/app/build.gradle`

Add dependency:
```gradle
dependencies {
    // ... existing dependencies

    // Comics Viewer Library
    implementation project(':comics-viewer-android')
}
```

**Code Changes:**
1. Delete migrated files from `app/src/main/java/com/fulldome/mahabharata/`
2. Update imports in remaining app code:
   ```java
   // Old:
   import com.fulldome.mahabharata.model.visual.Comics;

   // New:
   import net.nativemind.comics.viewer.comics.model.Comics;
   ```

### 3.2 iOS App Integration

**Option A: Local Swift Package**

In Xcode project:
1. File → Add Package Dependencies
2. Add Local → select `/libs/comics-viewer-ios`
3. Link `ComicsViewer` to app target

**Option B: Package.swift (if app uses SPM)**

```swift
dependencies: [
    .package(path: "../comics-viewer-ios")
],
targets: [
    .target(
        name: "Mahabharata",
        dependencies: ["ComicsViewer"]
    )
]
```

**Code Changes:**
1. Delete migrated files from `Mahabharata/Model/DataClasses/Visual/`
2. Update imports:
   ```swift
   // Old:
   import Mahabharata

   // New:
   import ComicsViewer
   ```

---

## Part 4: Flutter Plugin Wrapper (flutter_comics_viewer)

### 4.1 Directory Structure

```
/libs/comics_viewer/flutter_comics_viewer/
├── android/
│   ├── build.gradle              # Uses implementation project(':comics-viewer-android')
│   └── src/main/java/net/nativemind/flutter/comics/viewer/
│       └── FlutterComicsViewerPlugin.java
├── ios/
│   ├── flutter_comics_viewer.podspec
│   └── Classes/
│       └── FlutterComicsViewerPlugin.swift
├── lib/
│   ├── flutter_comics_viewer.dart           # Public API
│   ├── src/
│   │   ├── comics_viewer.dart               # Main widget
│   │   ├── comics_viewer_controller.dart    # Controller
│   │   └── platform_interface.dart          # Platform interface
│   └── method_channel.dart
├── example/
│   ├── lib/main.dart
│   └── assets/sample.comics
├── pubspec.yaml
└── README.md
```

### 4.2 Flutter Android Configuration

**File:** `/libs/comics_viewer/flutter_comics_viewer/android/build.gradle`

```gradle
group 'net.nativemind.flutter.comics.viewer'
version '1.0-SNAPSHOT'

buildscript {
    ext.kotlin_version = '1.9.0'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply plugin: 'com.android.library'
apply plugin: 'kotlin-android'

android {
    namespace 'net.nativemind.flutter.comics.viewer'
    compileSdk 34

    defaultConfig {
        minSdk 21
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = '11'
    }
}

dependencies {
    // Flutter
    implementation 'io.flutter:flutter_embedding_release:1.0.0'

    // Comics Viewer Android Library
    implementation project(':comics-viewer-android')
}
```

**File:** `/libs/comics_viewer/flutter_comics_viewer/android/settings.gradle`

```gradle
include ':comics-viewer-android'
project(':comics-viewer-android').projectDir = new File(rootDir, '../../../comics-viewer-android')
```

### 4.3 Flutter iOS Configuration

**File:** `/libs/comics_viewer/flutter_comics_viewer/ios/flutter_comics_viewer.podspec`

```ruby
Pod::Spec.new do |s|
  s.name             = 'flutter_comics_viewer'
  s.version          = '1.0.0'
  s.summary          = 'Flutter plugin for Comics Viewer'
  s.description      = <<-DESC
Flutter plugin that wraps ComicsViewer iOS Swift Package for rendering .comics files
                       DESC
  s.homepage         = 'https://nativemind.net'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'NativeMind' => 'support@nativemind.net' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'

  # Swift version
  s.swift_version    = '5.0'

  # Dependency on local ComicsViewer Swift Package
  s.dependency 'ComicsViewer', :path => '../../../comics-viewer-ios'
end
```

### 4.4 Flutter Public API

**File:** `/libs/comics_viewer/flutter_comics_viewer/lib/flutter_comics_viewer.dart`

```dart
library flutter_comics_viewer;

export 'src/comics_viewer.dart';
export 'src/comics_viewer_controller.dart';
```

**File:** `/libs/comics_viewer/flutter_comics_viewer/lib/src/comics_viewer.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'comics_viewer_controller.dart';

class ComicsViewer extends StatefulWidget {
  final String filePath;
  final ComicsViewerController? controller;
  final ValueChanged<double>? onScrollChanged;
  final VoidCallback? onLoaded;
  final ValueChanged<String>? onError;

  const ComicsViewer({
    Key? key,
    required this.filePath,
    this.controller,
    this.onScrollChanged,
    this.onLoaded,
    this.onError,
  }) : super(key: key);

  @override
  State<ComicsViewer> createState() => _ComicsViewerState();
}

class _ComicsViewerState extends State<ComicsViewer> {
  static const MethodChannel _channel =
      MethodChannel('net.nativemind.flutter.comics.viewer');

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
  }

  @override
  Widget build(BuildContext context) {
    // Platform view implementation
    return Container(); // TODO: Implement platform view
  }

  Future<void> loadComics(String filePath) async {
    try {
      await _channel.invokeMethod('loadComics', {'filePath': filePath});
      widget.onLoaded?.call();
    } catch (e) {
      widget.onError?.call(e.toString());
    }
  }

  Future<void> play() async {
    await _channel.invokeMethod('play');
  }

  Future<void> pause() async {
    await _channel.invokeMethod('pause');
  }

  Future<void> setScrollPosition(double position) async {
    await _channel.invokeMethod('setScrollPosition', {'position': position});
  }

  Future<double> getScrollPosition() async {
    final position = await _channel.invokeMethod<double>('getScrollPosition');
    return position ?? 0.0;
  }

  Future<void> togglePreview(bool show) async {
    await _channel.invokeMethod('togglePreview', {'show': show});
  }

  Future<void> toggleSounds(bool enabled) async {
    await _channel.invokeMethod('toggleSounds', {'enabled': enabled});
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _channel.invokeMethod('dispose');
    super.dispose();
  }
}
```

**File:** `/libs/comics_viewer/flutter_comics_viewer/lib/src/comics_viewer_controller.dart`

```dart
import 'comics_viewer.dart';

class ComicsViewerController {
  _ComicsViewerState? _state;

  void _attach(_ComicsViewerState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  Future<void> loadComics(String filePath) async {
    await _state?.loadComics(filePath);
  }

  Future<void> play() async {
    await _state?.play();
  }

  Future<void> pause() async {
    await _state?.pause();
  }

  Future<void> setScrollPosition(double position) async {
    await _state?.setScrollPosition(position);
  }

  Future<double> getScrollPosition() async {
    return await _state?.getScrollPosition() ?? 0.0;
  }

  Future<void> togglePreview(bool show) async {
    await _state?.togglePreview(show);
  }

  Future<void> toggleSounds(bool enabled) async {
    await _state?.toggleSounds(enabled);
  }

  bool get isPlaying => false; // TODO: Implement
  double get duration => 0.0; // TODO: Implement
  double get currentPosition => 0.0; // TODO: Implement
}
```

---

## Part 5: React Native Module Wrapper (react-native-comics-viewer)

### 5.1 Directory Structure

```
/libs/comics_viewer/react-native-comics-viewer/
├── android/
│   ├── build.gradle              # Uses implementation project(':comics-viewer-android')
│   └── src/main/java/net/nativemind/rn/comics/viewer/
│       ├── ComicsViewerModule.java
│       └── ComicsViewerPackage.java
├── ios/
│   ├── ComicsViewer.podspec
│   └── ComicsViewer/
│       ├── ComicsViewerModule.swift
│       └── ComicsViewerBridge.m
├── src/
│   ├── index.ts                  # Public API (TypeScript)
│   ├── ComicsViewer.tsx          # Component
│   └── types.ts                  # Type definitions
├── example/
│   ├── App.tsx
│   └── assets/sample.comics
├── package.json
└── README.md
```

### 5.2 React Native Android Configuration

**File:** `/libs/comics_viewer/react-native-comics-viewer/android/build.gradle`

```gradle
buildscript {
    ext.kotlin_version = '1.9.0'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

apply plugin: 'com.android.library'
apply plugin: 'kotlin-android'

android {
    namespace 'net.nativemind.rn.comics.viewer'
    compileSdk 34

    defaultConfig {
        minSdk 21
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = '11'
    }
}

repositories {
    mavenCentral()
    google()
}

dependencies {
    implementation 'com.facebook.react:react-native:+'

    // Comics Viewer Android Library
    implementation project(':comics-viewer-android')
}
```

**File:** `/libs/comics_viewer/react-native-comics-viewer/android/settings.gradle`

```gradle
include ':comics-viewer-android'
project(':comics-viewer-android').projectDir = new File(rootDir, '../../../comics-viewer-android')
```

### 5.3 React Native iOS Configuration

**File:** `/libs/comics_viewer/react-native-comics-viewer/ios/ComicsViewer.podspec`

```ruby
require "json"

package = JSON.parse(File.read(File.join(__dir__, "../package.json")))

Pod::Spec.new do |s|
  s.name         = "ComicsViewer"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "13.0" }
  s.source       = { :git => package["repository"]["url"], :tag => "#{s.version}" }

  s.source_files = "ComicsViewer/**/*.{h,m,mm,swift}"

  s.dependency "React-Core"

  # Dependency on local ComicsViewer Swift Package
  s.dependency "ComicsViewer", :path => "../../../comics-viewer-ios"
end
```

### 5.4 React Native Public API (TypeScript)

**File:** `/libs/comics_viewer/react-native-comics-viewer/src/index.ts`

```typescript
import ComicsViewer from './ComicsViewer';

export default ComicsViewer;
export * from './types';
```

**File:** `/libs/comics_viewer/react-native-comics-viewer/src/types.ts`

```typescript
export interface ComicsViewerProps {
  filePath: string;
  onScrollChanged?: (position: number) => void;
  onLoaded?: () => void;
  onError?: (error: string) => void;
  style?: any;
}

export interface ComicsViewerRef {
  loadComics(filePath: string): Promise<void>;
  play(): void;
  pause(): void;
  setScrollPosition(position: number): void;
  getScrollPosition(): number;
  togglePreview(show: boolean): void;
  toggleSounds(enabled: boolean): void;

  // Properties
  readonly isPlaying: boolean;
  readonly duration: number;
  readonly currentPosition: number;
}
```

**File:** `/libs/comics_viewer/react-native-comics-viewer/src/ComicsViewer.tsx`

```typescript
import React, { forwardRef, useImperativeHandle } from 'react';
import { requireNativeComponent, NativeModules } from 'react-native';
import type { ComicsViewerProps, ComicsViewerRef } from './types';

const { ComicsViewerModule } = NativeModules;
const NativeComicsViewer = requireNativeComponent('ComicsViewer');

const ComicsViewer = forwardRef<ComicsViewerRef, ComicsViewerProps>(
  (props, ref) => {
    useImperativeHandle(ref, () => ({
      async loadComics(filePath: string) {
        await ComicsViewerModule.loadComics(filePath);
      },
      play() {
        ComicsViewerModule.play();
      },
      pause() {
        ComicsViewerModule.pause();
      },
      setScrollPosition(position: number) {
        ComicsViewerModule.setScrollPosition(position);
      },
      getScrollPosition(): number {
        return ComicsViewerModule.getScrollPosition();
      },
      togglePreview(show: boolean) {
        ComicsViewerModule.togglePreview(show);
      },
      toggleSounds(enabled: boolean) {
        ComicsViewerModule.toggleSounds(enabled);
      },
      get isPlaying() {
        return ComicsViewerModule.isPlaying;
      },
      get duration() {
        return ComicsViewerModule.duration;
      },
      get currentPosition() {
        return ComicsViewerModule.currentPosition;
      },
    }));

    return <NativeComicsViewer {...props} />;
  }
);

export default ComicsViewer;
```

---

## Part 6: API Consistency Verification

### 6.1 Unified API Contract

Both Flutter and React Native wrappers MUST expose identical functionality:

#### Methods (Identical Names & Parameters)

| Method | Parameters | Returns | Description |
|--------|-----------|---------|-------------|
| `loadComics` | `filePath: string` | `Promise<void>` | Load .comics file |
| `play` | - | `void` | Start playback |
| `pause` | - | `void` | Pause playback |
| `setScrollPosition` | `position: number` | `void` | Set scroll offset |
| `getScrollPosition` | - | `number` | Get current scroll |
| `togglePreview` | `show: boolean` | `void` | Toggle preview layers |
| `toggleSounds` | `enabled: boolean` | `void` | Toggle audio |
| `dispose` | - | `void` | Cleanup resources |

#### Properties (Read-Only)

| Property | Type | Description |
|----------|------|-------------|
| `isPlaying` | `boolean` | Playback state |
| `duration` | `number` | Total scrollable height |
| `currentPosition` | `number` | Current scroll position |

#### Events/Callbacks

| Event | Parameters | Description |
|-------|-----------|-------------|
| `onScrollChanged` | `position: number` | Scroll position changed |
| `onLoaded` | - | Comics file loaded |
| `onError` | `error: string` | Error occurred |

### 6.2 Bundle ID Summary

```
Core Libraries:
  Android: net.nativemind.comics.viewer
  iOS:     net.nativemind.comics.viewer

Flutter Plugin:
  ID:      net.nativemind.flutter.comics.viewer
  Android: uses net.nativemind.comics.viewer (core)
  iOS:     uses net.nativemind.comics.viewer (core)

React Native Module:
  ID:      net.nativemind.rn.comics.viewer
  Android: uses net.nativemind.comics.viewer (core)
  iOS:     uses net.nativemind.comics.viewer (core)
```

---

## Part 7: Testing & Validation

### 7.1 Library Validation Checklist

**Android Library (comics-viewer-android):**
- [ ] Builds standalone without app dependencies
- [ ] All package names use `net.nativemind.comics.viewer`
- [ ] No references to `com.fulldome.mahabharata`
- [ ] ProGuard rules defined if needed
- [ ] Unit tests pass

**iOS Swift Package (comics-viewer-ios):**
- [ ] Builds standalone without app dependencies
- [ ] All imports reference `ComicsViewer` module
- [ ] No references to `Mahabharata` module
- [ ] Package.swift configures correctly
- [ ] Unit tests pass

### 7.2 App Integration Validation

**mahabharata-mobile-java-v2026:**
- [ ] Builds with `:comics-viewer-android` dependency
- [ ] All imports updated to new package
- [ ] No duplicate code (old files removed)
- [ ] App functionality unchanged

**mahabharata-mobile-swift-v2026:**
- [ ] Builds with ComicsViewer SPM dependency
- [ ] All imports updated to new module
- [ ] No duplicate code (old files removed)
- [ ] App functionality unchanged

### 7.3 Wrapper Validation

**flutter_comics_viewer:**
- [ ] Builds for both Android and iOS
- [ ] Example app runs with sample.comics
- [ ] All API methods work correctly
- [ ] Events fire correctly

**react-native-comics-viewer:**
- [ ] Builds for both Android and iOS
- [ ] Example app runs with sample.comics
- [ ] All API methods work correctly
- [ ] Events fire correctly
- [ ] TypeScript types are correct

### 7.4 API Consistency Check

- [ ] Method names match between Flutter and RN
- [ ] Parameter types match (string, number, boolean)
- [ ] Return types match
- [ ] Event names match
- [ ] Property names match

---

## Approval

- [x] Reviewed by: User
- [x] Approved on: 2026-07-21
- [x] Notes: Specifications approved, ready for plan phase
