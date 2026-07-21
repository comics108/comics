# Implementation Plan: Flutter Comics Library

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-07-19
> Approved by: User on 2026-07-19

## Overview

This plan breaks down the migration into atomic, executable tasks. Each task is designed to be completed independently with clear success criteria.

**Estimated Total:** ~40-50 tasks
**Estimated Duration:** 3-5 implementation sessions
**Dependencies:** Tasks are numbered to indicate execution order and dependencies

---

## Phase 1: Setup & Configuration (Tasks 1-5)

### Task 1.1: Create Android Source Structure
**Complexity:** Low | **Time:** 10 min

**Steps:**
```bash
cd libs/flutter_comics/android/src/main/java
mkdir -p net/nativemind/comics/{model/visual/animation,controls,utils}
```

**Success Criteria:**
- Directory structure matches: `net/nativemind/comics/model/visual/animation/`
- Directory structure matches: `net/nativemind/comics/controls/`
- Directory structure matches: `net/nativemind/comics/utils/`

**Files:** None (directory creation only)

---

### Task 1.2: Create iOS Source Structure
**Complexity:** Low | **Time:** 10 min

**Steps:**
```bash
cd libs/flutter_comics/ios/comics/Sources/comics
mkdir -p Model/{Animations,Visual}
mkdir -p Views
mkdir -p Library
mkdir -p Extensions
```

**Success Criteria:**
- Directory structure matches: `Model/Animations/`
- Directory structure matches: `Model/Visual/`
- Directory structure matches: `Views/`
- Directory structure matches: `Library/`

**Files:** None (directory creation only)

---

### Task 1.3: Configure Android build.gradle
**Complexity:** Low | **Time:** 15 min

**File:** `libs/flutter_comics/android/build.gradle`

**Changes:**
```gradle
android {
    namespace 'net.nativemind.comics'
    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}

dependencies {
    // ZIP file handling
    implementation 'com.android.vending.expansion:expansion:3.0.0'

    // JSON parsing
    implementation 'com.google.code.gson:gson:2.10.1'

    // AndroidX
    implementation 'androidx.annotation:annotation:1.7.0'

    // Interpolators
    implementation 'androidx.interpolator:interpolator:1.0.0'
}
```

**Success Criteria:**
- Gradle sync passes
- Dependencies download successfully
- No build errors

---

### Task 1.4: Configure iOS Package.swift (if needed)
**Complexity:** Low | **Time:** 10 min

**File:** `libs/flutter_comics/ios/comics.podspec` OR create Package.swift

**Success Criteria:**
- iOS build configuration is valid
- No framework/module dependencies needed (uses Foundation, AVFoundation, UIKit only)

---

### Task 1.5: Configure Dart pubspec.yaml
**Complexity:** Low | **Time:** 10 min

**File:** `libs/flutter_comics/pubspec.yaml`

**Changes:**
```yaml
name: comics
description: Flutter plugin for rendering .comics files with native performance
version: 0.1.0
publish_to: none

environment:
  sdk: '>=3.12.2 <4.0.0'
  flutter: ">=3.3.0"

dependencies:
  flutter:
    sdk: flutter
  plugin_platform_interface: ^2.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  plugin:
    platforms:
      android:
        package: net.nativemind.comics
        pluginClass: ComicsPlugin
      ios:
        pluginClass: ComicsPlugin
```

**Success Criteria:**
- `flutter pub get` runs without errors
- Plugin configuration is valid

---

## Phase 2: Android Core Models (Tasks 2.1-2.9)

### Task 2.1: Copy Animation Base Classes
**Complexity:** Low | **Time:** 20 min

**Source:** `apps/mahabharata-mobile-java-v2012/app/src/main/java/com/fulldome/mahabharata/model/visual/animation/`
**Target:** `libs/flutter_comics/android/src/main/java/net/nativemind/comics/model/visual/animation/`

**Files to copy:**
1. `AnimType.java` - Change package to `net.nativemind.comics.model.visual.animation`
2. `Anim.java` - Change package
3. `LayerAnim.java` - Change package

**Success Criteria:**
- Files compile without errors
- Package declarations are correct
- Imports are resolved

---

### Task 2.2: Copy Animation Implementations
**Complexity:** Low | **Time:** 30 min

**Source:** Same as 2.1
**Target:** Same as 2.1

**Files to copy:**
1. `TranslateAnim.java` - Change package
2. `RotateAnim.java` - Change package
3. `ScaleAnim.java` - Change package
4. `AlphaAnim.java` - Change package
5. `SoundAnim.java` - Change package

**Success Criteria:**
- All files compile
- No missing imports
- Animation inheritance hierarchy is intact

---

### Task 2.3: Copy Image and Layer Models
**Complexity:** Medium | **Time:** 30 min

**Source:** `apps/mahabharata-mobile-java-v2012/app/src/main/java/com/fulldome/mahabharata/model/visual/`
**Target:** `libs/flutter_comics/android/src/main/java/net/nativemind/comics/model/visual/`

**Files to copy:**
1. `Image.java`
   - Change package to `net.nativemind.comics.model.visual`
   - Update imports

2. `Layer.java`
   - Change package
   - Update animation imports to `net.nativemind.comics.model.visual.animation`
   - Check Settings references (may need to create stub)

**Success Criteria:**
- Both files compile
- Layer correctly imports animation classes
- No external dependencies missing

---

### Task 2.4: Create ComicsSettings.java
**Complexity:** Low | **Time:** 20 min

**Target:** `libs/flutter_comics/android/src/main/java/net/nativemind/comics/model/ComicsSettings.java`

**Create new file (simplified from Settings.java):**
```java
package net.nativemind.comics.model;

import android.content.Context;
import android.content.SharedPreferences;

public class ComicsSettings {
    private static final String PREFS_NAME = "comics_settings";
    private static final String KEY_SOUND_ON = "sound_on";

    private static ComicsSettings instance;
    private SharedPreferences prefs;
    private boolean soundOn = true;

    private ComicsSettings(Context context) {
        prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        soundOn = prefs.getBoolean(KEY_SOUND_ON, true);
    }

    public static void init(Context context) {
        if (instance == null) {
            instance = new ComicsSettings(context);
        }
    }

    public static ComicsSettings getInstance() {
        return instance;
    }

    public boolean isSoundOn() { return soundOn; }

    public void setSoundOn(boolean soundOn) {
        this.soundOn = soundOn;
        prefs.edit().putBoolean(KEY_SOUND_ON, soundOn).apply();
    }
}
```

**Success Criteria:**
- File compiles
- No external dependencies
- Singleton pattern works

---

### Task 2.5: Copy SoundManager
**Complexity:** Medium | **Time:** 30 min

**Source:** `apps/mahabharata-mobile-java-v2012/app/src/main/java/com/ironwaterstudio/utils/SoundManager.java`
**Target:** `libs/flutter_comics/android/src/main/java/net/nativemind/comics/utils/SoundManager.java`

**Changes:**
- Change package to `net.nativemind.comics.utils`
- Keep ALL functionality as-is (281 lines)
- No dependencies to remove

**Success Criteria:**
- File compiles
- MediaPlayer functionality intact
- All listener interfaces work

---

### Task 2.6: Copy Sound Model
**Complexity:** Medium | **Time:** 30 min

**Source:** `apps/mahabharata-mobile-java-v2012/app/src/main/java/com/fulldome/mahabharata/model/visual/Sound.java`
**Target:** `libs/flutter_comics/android/src/main/java/net/nativemind/comics/model/visual/Sound.java`

**Changes:**
- Change package to `net.nativemind.comics.model.visual`
- Update SoundManager import to `net.nativemind.comics.utils.SoundManager`
- Update SoundAnim import

**Success Criteria:**
- File compiles
- Sound playback logic intact
- Volume animation works

---

### Task 2.7: Copy ComicsDescriptor
**Complexity:** Low | **Time:** 20 min

**Source:** `apps/mahabharata-mobile-java-v2012/app/src/main/java/com/fulldome/mahabharata/model/ComicsDescriptor.java`
**Target:** `libs/flutter_comics/android/src/main/java/net/nativemind/comics/model/ComicsDescriptor.java`

**Changes:**
- Change package to `net.nativemind.comics.model`
- Verify ZipResourceFile import (from gradle dependency)

**Success Criteria:**
- File compiles
- ZipResourceFile dependency resolved
- getData(), getSound(), getImage() methods work

---

### Task 2.8: Copy Comics Model
**Complexity:** Medium | **Time:** 40 min

**Source:** `apps/mahabharata-mobile-java-v2012/app/src/main/java/com/fulldome/mahabharata/model/visual/Comics.java`
**Target:** `libs/flutter_comics/android/src/main/java/net/nativemind/comics/model/visual/Comics.java`

**Changes:**
- Change package to `net.nativemind.comics.model.visual`
- Update all imports (Layer, Sound, ComicsDescriptor)
- Replace `Settings.getInstance()` with `ComicsSettings.getInstance()`
- Remove analytics calls (FbUtils.logEvent)
- Simplify `create()` method to not depend on BaseState

**Success Criteria:**
- File compiles
- All dependencies resolved
- prepare(), process(), release() methods work
- No app-specific dependencies

---

### Task 2.9: Create LayerAnimTypeAdapter (if needed)
**Complexity:** Low | **Time:** 20 min

**Target:** `libs/flutter_comics/android/src/main/java/net/nativemind/comics/model/visual/animation/LayerAnimTypeAdapter.java`

**Create Gson deserializer for polymorphic animations:**
```java
package net.nativemind.comics.model.visual.animation;

import com.google.gson.*;
import java.lang.reflect.Type;

public class LayerAnimTypeAdapter implements JsonDeserializer<LayerAnim> {
    @Override
    public LayerAnim deserialize(JsonElement json, Type typeOfT, JsonDeserializationContext context)
            throws JsonParseException {
        JsonObject jsonObject = json.getAsJsonObject();
        String type = jsonObject.get("type").getAsString();

        switch (AnimType.valueOf(type.toUpperCase())) {
            case TRANSLATE:
                return context.deserialize(json, TranslateAnim.class);
            case ROTATE:
                return context.deserialize(json, RotateAnim.class);
            case SCALE:
                return context.deserialize(json, ScaleAnim.class);
            case ALPHA:
                return context.deserialize(json, AlphaAnim.class);
            case SOUND:
                return context.deserialize(json, SoundAnim.class);
            default:
                throw new JsonParseException("Unknown animation type: " + type);
        }
    }
}
```

**Success Criteria:**
- File compiles
- Gson can deserialize animations from JSON

---

## Phase 3: Android Rendering (Tasks 3.1-3.4)

### Task 3.1: Copy TileImageView
**Complexity:** High | **Time:** 45 min

**Source:** `apps/mahabharata-mobile-java-v2012/app/src/main/java/com/fulldome/mahabharata/controls/TileImageView.java`
**Target:** `libs/flutter_comics/android/src/main/java/net/nativemind/comics/controls/TileImageView.java`

**Changes:**
- Change package to `net.nativemind.comics.controls`
- Update ComicsDescriptor import
- Update ImageManager import (will create in Task 3.3)
- Preserve ALL tile logic (TILE_SIZE=512, ZOOM_LEVELS, etc)

**Success Criteria:**
- File compiles
- Tile rendering logic intact
- Lazy loading works

---

### Task 3.2: Copy ZoomFrameLayout
**Complexity:** Medium | **Time:** 30 min

**Source:** `apps/mahabharata-mobile-java-v2012/app/src/main/java/com/fulldome/mahabharata/controls/ZoomFrameLayout.java`
**Target:** `libs/flutter_comics/android/src/main/java/net/nativemind/comics/controls/ZoomFrameLayout.java`

**Changes:**
- Change package to `net.nativemind.comics.controls`
- Update any imports

**Success Criteria:**
- File compiles
- Zoom/pan functionality works
- ZoomableView interface defined

---

### Task 3.3: Copy ImageManager (Simplified)
**Complexity:** Medium | **Time:** 40 min

**Source:** `apps/mahabharata-mobile-java-v2012/app/src/main/java/com/fulldome/mahabharata/utils/ImageManager.java`
**Target:** `libs/flutter_comics/android/src/main/java/net/nativemind/comics/utils/ImageManager.java`

**Changes:**
- Change package to `net.nativemind.comics.utils`
- Remove analytics calls (FbUtils.logEvent)
- Remove Activity references
- Keep core functionality: getBitmap(), cancel(), buildKey()
- Integrate with LruBitmapCache (create in Task 3.4)

**Success Criteria:**
- File compiles
- Image loading works
- No app-specific dependencies

---

### Task 3.4: Copy LruBitmapCache
**Complexity:** Low | **Time:** 20 min

**Source:** `apps/mahabharata-mobile-java-v2012/app/src/main/java/com/ironwaterstudio/utils/LruBitmapCache.java`
**Target:** `libs/flutter_comics/android/src/main/java/net/nativemind/comics/utils/LruBitmapCache.java`

**Changes:**
- Change package to `net.nativemind.comics.utils`

**Success Criteria:**
- File compiles
- LRU cache functionality works

---

### Task 3.5: Copy LayersView
**Complexity:** High | **Time:** 45 min

**Source:** `apps/mahabharata-mobile-java-v2012/app/src/main/java/com/fulldome/mahabharata/controls/LayersView.java`
**Target:** `libs/flutter_comics/android/src/main/java/net/nativemind/comics/controls/LayersView.java`

**Changes:**
- Change package to `net.nativemind.comics.controls`
- Update Comics import
- Update TileImageView import
- Update ComicsDescriptor import
- Preserve matrix transformation logic

**Success Criteria:**
- File compiles
- getChildStaticTransformation() works
- Layer rendering works
- Preview toggle works

---

## Phase 4: Android Flutter Bridge (Tasks 4.1-4.3)

### Task 4.1: Extend ComicsPlugin.java
**Complexity:** Medium | **Time:** 30 min

**File:** `libs/flutter_comics/android/src/main/java/net/nativemind/comics/ComicsPlugin.java`

**Changes:**
```java
package net.nativemind.comics;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class ComicsPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
  private MethodChannel channel;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    channel = new MethodChannel(binding.getBinaryMessenger(), "net.nativemind.comics");
    channel.setMethodCallHandler(this);

    // Register PlatformView
    binding.getPlatformViewRegistry()
      .registerViewFactory("net.nativemind.comics/comics_view",
        new ComicsViewFactory(binding.getBinaryMessenger()));
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    result.notImplemented();
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
```

**Success Criteria:**
- File compiles
- Plugin registers successfully
- PlatformView factory registered

---

### Task 4.2: Create ComicsViewFactory.java
**Complexity:** Low | **Time:** 20 min

**File:** `libs/flutter_comics/android/src/main/java/net/nativemind/comics/ComicsViewFactory.java`

**Create:**
```java
package net.nativemind.comics;

import android.content.Context;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import java.util.Map;

public class ComicsViewFactory extends PlatformViewFactory {
  private final BinaryMessenger messenger;

  public ComicsViewFactory(BinaryMessenger messenger) {
    super(StandardMessageCodec.INSTANCE);
    this.messenger = messenger;
  }

  @Override
  public PlatformView create(Context context, int viewId, Object args) {
    Map<String, Object> params = (Map<String, Object>) args;
    return new ComicsPlatformView(context, viewId, params, messenger);
  }
}
```

**Success Criteria:**
- File compiles
- Factory creates PlatformView instances

---

### Task 4.3: Create ComicsPlatformView.java
**Complexity:** High | **Time:** 60 min

**File:** `libs/flutter_comics/android/src/main/java/net/nativemind/comics/ComicsPlatformView.java`

**Create full implementation** (see specifications for details)

**Success Criteria:**
- File compiles
- Loads .comics file
- Creates LayersView
- Method channel works
- Scroll updates work
- Sound toggle works

---

## Phase 5: iOS Core Models (Tasks 5.1-5.7)

### Task 5.1: Copy Swift Model Classes
**Complexity:** Low | **Time:** 30 min

**Source:** `apps/mahabharata-mobile-swift-v2012/Mahabharata/Model/DataClasses/Visual/`
**Target:** `libs/flutter_comics/ios/comics/Sources/comics/Model/`

**Files to copy:**
1. `Comics.swift` - Update imports
2. `Layer.swift` - Update imports
3. `Image.swift` - Update imports
4. `Sound.swift` - Update imports (data class only)

**Success Criteria:**
- All files compile
- No missing imports
- Codable protocol works

---

### Task 5.2: Copy Swift Animation Classes
**Complexity:** Low | **Time:** 30 min

**Source:** `apps/mahabharata-mobile-swift-v2012/Mahabharata/Model/DataClasses/Visual/Animations/`
**Target:** `libs/flutter_comics/ios/comics/Sources/comics/Model/Animations/`

**Files to copy:**
1. `Anim.swift`
2. `LayerAnim.swift`
3. `TranslateAnim.swift`
4. `RotateAnim.swift`
5. `ScaleAnim.swift`
6. `AlphaAnim.swift`
7. `SoundAnim.swift`

**Success Criteria:**
- All files compile
- Codable works
- Inheritance hierarchy intact

---

### Task 5.3: Copy SoundManager.swift
**Complexity:** Low | **Time:** 20 min

**Source:** `apps/mahabharata-mobile-swift-v2012/Mahabharata/Library/SoundManager/SoundManager.swift`
**Target:** `libs/flutter_comics/ios/comics/Sources/comics/Library/SoundManager.swift`

**Changes:**
- Update imports (minimal)

**Success Criteria:**
- File compiles
- AVPlayer integration works
- Fade in/out works

---

### Task 5.4: Copy AVPlayer+Fade.swift
**Complexity:** Low | **Time:** 10 min

**Source:** `apps/mahabharata-mobile-swift-v2012/Mahabharata/Extensions/AVPlayer/AVPlayer+Fade.swift`
**Target:** `libs/flutter_comics/ios/comics/Sources/comics/Extensions/AVPlayer+Fade.swift`

**Success Criteria:**
- File compiles
- Fade extension works

---

### Task 5.5: Copy ArchiveManager.swift
**Complexity:** Medium | **Time:** 30 min

**Source:** `apps/mahabharata-mobile-swift-v2012/Mahabharata/Controllers/ArchiveManager.swift`
**Target:** `libs/flutter_comics/ios/comics/Sources/comics/Library/ArchiveManager.swift`

**Changes:**
- Remove app-specific code
- Keep: data(), layer(), sound() methods
- Update imports

**Success Criteria:**
- File compiles
- ZIP extraction works
- File loading works

---

### Task 5.6: Copy TileImageView.swift
**Complexity:** Low | **Time:** 20 min

**Source:** `apps/mahabharata-mobile-swift-v2012/Mahabharata/Views/Tiles/TileImageView.swift`
**Target:** `libs/flutter_comics/ios/comics/Sources/comics/Views/TileImageView.swift`

**Changes:**
- Update imports
- Update ArchiveManager references

**Success Criteria:**
- File compiles
- CATiledLayer works
- Tile loading works

---

### Task 5.7: Copy ImageScrollView.swift (Simplified)
**Complexity:** High | **Time:** 60 min

**Source:** `apps/mahabharata-mobile-swift-v2012/Mahabharata/Views/Tiles/ImageScrollView.swift`
**Target:** `libs/flutter_comics/ios/comics/Sources/comics/Views/ImageScrollView.swift`

**Changes:**
- Remove `ImageScrollViewDelegate` protocol
- Remove `reloadLanguage()` or make it parameter-based
- Remove `Settings.shared` references - use instance variables
- Remove analytics
- Keep ALL sound playback logic
- Keep ALL layer transformation logic
- Keep ALL tile management logic

**Success Criteria:**
- File compiles
- Sound playback works (playSoundsByOffset)
- Layer transformations work
- Tile lazy loading works
- No app dependencies

---

## Phase 6: iOS Flutter Bridge (Tasks 6.1-6.3)

### Task 6.1: Extend ComicsPlugin.swift
**Complexity:** Medium | **Time:** 20 min

**File:** `libs/flutter_comics/ios/comics/Sources/comics/ComicsPlugin.swift`

**Changes:**
```swift
import Flutter

public class ComicsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "net.nativemind.comics",
      binaryMessenger: registrar.messenger()
    )
    let instance = ComicsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Register PlatformView
    let factory = ComicsViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "net.nativemind.comics/comics_view")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }
}
```

**Success Criteria:**
- File compiles
- Plugin registers
- PlatformView factory registered

---

### Task 6.2: Create ComicsViewFactory.swift
**Complexity:** Low | **Time:** 15 min

**File:** `libs/flutter_comics/ios/comics/Sources/comics/ComicsViewFactory.swift`

**Create** (see specifications)

**Success Criteria:**
- File compiles
- Factory creates views

---

### Task 6.3: Create ComicsPlatformView.swift
**Complexity:** High | **Time:** 60 min

**File:** `libs/flutter_comics/ios/comics/Sources/comics/ComicsPlatformView.swift`

**Create full implementation** using ImageScrollView

**Success Criteria:**
- File compiles
- Loads .comics file
- Creates ImageScrollView
- Method channel works
- Scroll updates work
- Sound toggle works

---

## Phase 7: Dart Bridge Layer (Tasks 7.1-7.4)

### Task 7.1: Create comics_platform_interface.dart
**Complexity:** Low | **Time:** 10 min

**File:** `libs/flutter_comics/lib/comics_platform_interface.dart`

**Create** (see specifications)

**Success Criteria:**
- File compiles
- Interface defined

---

### Task 7.2: Create comics_method_channel.dart
**Complexity:** Low | **Time:** 10 min

**File:** `libs/flutter_comics/lib/comics_method_channel.dart`

**Create** (see specifications)

**Success Criteria:**
- File compiles
- Method channel works

---

### Task 7.3: Create widgets/comics_view.dart
**Complexity:** Medium | **Time:** 30 min

**File:** `libs/flutter_comics/lib/widgets/comics_view.dart`

**Create full widget** with AndroidView/UiKitView

**Success Criteria:**
- File compiles
- AndroidView creates on Android
- UiKitView creates on iOS
- Method channel communication works

---

### Task 7.4: Create comics.dart (Public API)
**Complexity:** Low | **Time:** 5 min

**File:** `libs/flutter_comics/lib/comics.dart`

```dart
library comics;

export 'widgets/comics_view.dart';
export 'comics_platform_interface.dart';
```

**Success Criteria:**
- File compiles
- Public API exported

---

## Phase 8: Example App & Documentation (Tasks 8.1-8.4)

### Task 8.1: Create Example App Structure
**Complexity:** Low | **Time:** 15 min

**Steps:**
```bash
cd libs/flutter_comics
flutter create example
cd example
# Update pubspec.yaml to depend on parent comics plugin
```

**File:** `libs/flutter_comics/example/pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  comics:
    path: ../
```

**Success Criteria:**
- Example app created
- Depends on comics plugin
- `flutter pub get` works

---

### Task 8.2: Implement Example App
**Complexity:** Medium | **Time:** 45 min

**File:** `libs/flutter_comics/example/lib/main.dart`

**Create:**
```dart
import 'package:flutter/material.dart';
import 'package:comics/comics.dart';
import 'dart:io';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comics Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ComicsScreen(),
    );
  }
}

class ComicsScreen extends StatefulWidget {
  const ComicsScreen({Key? key}) : super(key: key);

  @override
  State<ComicsScreen> createState() => _ComicsScreenState();
}

class _ComicsScreenState extends State<ComicsScreen> {
  String? comicsPath;

  @override
  void initState() {
    super.initState();
    // TODO: Load sample .comics file
  }

  @override
  Widget build(BuildContext context) {
    if (comicsPath == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Comics Example')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comics Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () {
              // Toggle sounds
            },
          ),
        ],
      ),
      body: ComicsView(
        filePath: comicsPath!,
        showPreview: false,
      ),
    );
  }
}
```

**Success Criteria:**
- Example app runs
- ComicsView displays
- No crashes

---

### Task 8.3: Add Sample .comics File to Example
**Complexity:** Low | **Time:** 20 min

**Steps:**
1. Copy a small test .comics file to `example/assets/test.comics`
2. Update `example/pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/test.comics
```
3. Update example app to load from assets

**Success Criteria:**
- Asset loads
- Comics renders
- Sound plays (if file has sounds)

---

### Task 8.4: Create README.md for flutter_comics
**Complexity:** Low | **Time:** 30 min

**File:** `libs/flutter_comics/README.md`

**Content:**
```markdown
# Flutter Comics Library

A Flutter plugin for rendering .comics files with native performance. Provides cross-platform support for animated, layered comics content with scroll-based animations and sound playback.

## Features

- ✅ Native rendering performance (Java on Android, Swift on iOS)
- ✅ Scroll-based layer animations (translate, rotate, scale, alpha)
- ✅ Tiled image loading for large comics (512x512 tiles, multiple zoom levels)
- ✅ Audio playback synchronized with scroll position
- ✅ Preview layer toggle
- ✅ Zoom and pan support
- ✅ Memory-efficient tile caching

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  comics:
    path: ../flutter_comics  # Or published version
```

## Usage

### Basic Example

```dart
import 'package:comics/comics.dart';

ComicsView(
  filePath: '/path/to/file.comics',
  showPreview: false,
)
```

### With Controls

```dart
class ComicsScreen extends StatefulWidget {
  @override
  State<ComicsScreen> createState() => _ComicsScreenState();
}

class _ComicsScreenState extends State<ComicsScreen> {
  late ComicsViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comics Viewer'),
        actions: [
          IconButton(
            icon: Icon(Icons.volume_up),
            onPressed: () => _controller.toggleSounds(),
          ),
        ],
      ),
      body: ComicsView(
        filePath: widget.comicsPath,
        onViewCreated: (controller) {
          _controller = controller;
        },
      ),
    );
  }
}
```

## File Format

The `.comics` file is a ZIP archive containing:

```
file.comics (ZIP)
├── data.json           # Comics metadata and animations
├── layers/             # Layer images and tiles
│   ├── layer1.png
│   ├── layer1_1000_0_0.png  # Tiles: {zoom}_{col}_{row}
│   └── ...
└── sounds/             # Audio files
    └── ambient.mp3
```

### data.json Schema

```json
{
  "width": 1080,
  "height": 15000,
  "layers": [
    {
      "preview": false,
      "images": [{
        "file": "layer1.png",
        "width": 1080,
        "height": 1920
      }],
      "animations": [
        {
          "type": "translate",
          "start": 0,
          "end": 1000,
          "x": 0,
          "y": 100
        }
      ]
    }
  ],
  "sounds": [
    {
      "file": "ambient.mp3",
      "animations": [
        {"type": "sound", "start": 0, "end": 5000}
      ]
    }
  ]
}
```

## API Reference

### ComicsView

Main widget for displaying comics content.

**Properties:**
- `filePath` (String, required) - Path to .comics file
- `showPreview` (bool) - Show preview layers (default: false)
- `onScrollChanged` (ValueChanged<int>?) - Callback for scroll position changes
- `onViewCreated` (Function(ComicsViewController)?) - Callback when view is ready

### ComicsViewController

Controller for interacting with comics view.

**Methods:**
- `updateScroll(int offset)` - Update scroll position
- `togglePreview(bool show)` - Toggle preview layers
- `toggleSounds()` - Toggle sound on/off
- `pauseSounds()` - Pause all sounds
- `resumeSounds()` - Resume all sounds

## Platform-Specific Implementation

### Android
- Uses native `LayersView` and `TileImageView` for rendering
- `MediaPlayer` for audio playback
- Gson for JSON parsing
- ZipResourceFile for .comics archive handling

### iOS
- Uses `ImageScrollView` (all-in-one: rendering + sound + scroll)
- `CATiledLayer` for efficient tile rendering
- `AVPlayer` for audio playback
- Native ZIP extraction

## Performance

- Comics loading: < 500ms
- Tile loading (visible): < 100ms
- Scroll frame rate: 60 FPS
- Memory usage: < 200MB for large comics

## Requirements

- Flutter SDK: >= 3.3.0
- Dart SDK: >= 3.12.2
- Android: API 21+ (Android 5.0+)
- iOS: 13.0+

## License

[Your license here]

## Credits

Migrated from production apps with proven rendering performance.
```

**Success Criteria:**
- README is comprehensive
- Examples are clear
- API is documented

---

## Phase 9: Testing & Validation (Tasks 9.1-9.5)

### Task 9.1: Test Android Build
**Complexity:** Low | **Time:** 15 min

**Steps:**
```bash
cd libs/flutter_comics/example
flutter build apk --debug
flutter install
```

**Success Criteria:**
- Build completes without errors
- App installs on device/emulator
- Comics renders
- No crashes

---

### Task 9.2: Test iOS Build
**Complexity:** Low | **Time:** 15 min

**Steps:**
```bash
cd libs/flutter_comics/example
flutter build ios --debug --no-codesign
# OR
open ios/Runner.xcworkspace  # Build via Xcode
```

**Success Criteria:**
- Build completes
- App runs on simulator
- Comics renders
- No crashes

---

### Task 9.3: Test Sound Playback
**Complexity:** Medium | **Time:** 30 min

**Test Cases:**
1. Load comics with point sounds
2. Scroll to trigger point sound → Verify sound plays once
3. Load comics with range sounds
4. Scroll into range → Verify sound loops
5. Scroll out of range → Verify sound stops with fade
6. Toggle sound off → Verify sound mutes
7. Toggle sound on → Verify sound resumes

**Success Criteria:**
- All test cases pass
- Sound synchronization < 50ms lag
- No audio glitches

---

### Task 9.4: Test Tile Loading
**Complexity:** Medium | **Time:** 30 min

**Test Cases:**
1. Load large comics (20+ MB)
2. Scroll quickly → Verify tiles load without lag
3. Zoom in → Verify correct zoom level tiles load
4. Scroll off-screen → Verify tiles unload (check memory)
5. Return to area → Verify tiles reload

**Success Criteria:**
- Tiles load within 100ms
- No blank squares
- Memory usage stable
- 60 FPS maintained

---

### Task 9.5: Test Animations
**Complexity:** Medium | **Time:** 30 min

**Test Cases:**
1. Load comics with translate animations
2. Scroll → Verify layers move correctly
3. Test rotate animations → Verify layer rotation
4. Test scale animations → Verify layer scaling
5. Test alpha animations → Verify transparency
6. Test combined animations → Verify all apply correctly

**Success Criteria:**
- All animation types work
- Cubic interpolation smooth
- 60 FPS maintained
- No visual glitches

---

## Phase 10: Final Documentation (Tasks 10.1-10.2)

### Task 10.1: Create CHANGELOG.md
**Complexity:** Low | **Time:** 15 min

**File:** `libs/flutter_comics/CHANGELOG.md`

```markdown
# Changelog

## [0.1.0] - 2026-07-XX

### Added
- Initial release
- Native comics rendering for Android and iOS
- Scroll-based animations (translate, rotate, scale, alpha)
- Tiled image loading with multiple zoom levels
- Sound playback synchronized with scroll
- Preview layer toggle
- Example app with sample comics

### Known Issues
- None

### Migration Notes
- First release, no migration needed
```

**Success Criteria:**
- CHANGELOG exists
- Initial version documented

---

### Task 10.2: Update Package Metadata
**Complexity:** Low | **Time:** 10 min

**File:** `libs/flutter_comics/pubspec.yaml`

**Update:**
```yaml
name: comics
description: Flutter plugin for rendering .comics files with native performance. Supports scroll-based animations, tiled images, and audio playback.
version: 0.1.0
homepage: https://github.com/yourorg/flutter_comics
repository: https://github.com/yourorg/flutter_comics

# ... rest of file
```

**Success Criteria:**
- Metadata complete
- Version set to 0.1.0

---

## Summary & Checklist

### Total Tasks: 46
- Phase 1 (Setup): 5 tasks
- Phase 2 (Android Models): 9 tasks
- Phase 3 (Android Rendering): 5 tasks
- Phase 4 (Android Bridge): 3 tasks
- Phase 5 (iOS Models): 7 tasks
- Phase 6 (iOS Bridge): 3 tasks
- Phase 7 (Dart Layer): 4 tasks
- Phase 8 (Example & Docs): 4 tasks
- Phase 9 (Testing): 5 tasks
- Phase 10 (Final Docs): 2 tasks

### Critical Path
1. Setup (Phase 1) → MUST complete first
2. Android Models (Phase 2) → Can parallel with iOS Models (Phase 5)
3. Android Rendering (Phase 3) → Depends on Phase 2
4. iOS Models (Phase 5) → Can parallel with Android
5. iOS Rendering (Phase 5.7) → Depends on iOS models
6. Bridges (Phases 4, 6) → Depend on native code
7. Dart (Phase 7) → Depends on bridges
8. Example (Phase 8) → Depends on all above
9. Testing (Phase 9) → Final validation
10. Docs (Phase 10) → Can do anytime

### Estimated Timeline
- **Fast track:** 3 sessions (8-10 hours)
- **Normal:** 4-5 sessions (12-15 hours)
- **With testing:** 5-6 sessions (15-18 hours)

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [any conditions or clarifications]
