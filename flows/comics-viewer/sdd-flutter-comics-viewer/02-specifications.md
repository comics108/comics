# Specifications: Flutter Comics Library

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-19

## Architecture Overview

The flutter_comics library follows a **native-first architecture** where ALL rendering, animation, and audio logic remains in platform-specific native code (Java/Swift). Dart code serves ONLY as a thin bridge layer using Platform Views and Method Channels.

**Note:** Android and iOS use different architectures internally, but both provide the same functionality.

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App (Dart)                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ├─ ComicsView Widget (Dart)
                       │  └─ AndroidView / UiKitView
                       │
                       ├─ Method Channel Bridge
                       │
       ┌───────────────┴────────────────┐
       │                                │
┌──────▼──────────┐           ┌────────▼─────────┐
│ Android (Java)  │           │   iOS (Swift)    │
├─────────────────┤           ├──────────────────┤
│ MODULAR:        │           │ ALL-IN-ONE:      │
│ • LayersView    │           │ ImageScrollView  │
│ • TileImageView │           │ • Rendering      │
│ • Sound         │           │ • Sound          │
│ • SoundManager  │           │ • Tiles          │
│ • ZoomFrameLayout│          │ • Scroll         │
│                 │           │ TileImageView    │
│ Comics Engine   │           │ SoundManager     │
└─────────────────┘           └──────────────────┘
```

**Architecture Differences:**
- **Android**: Modular design (separate classes for layers, sound, tiles)
- **iOS**: Monolithic design (ImageScrollView combines all functionality)
- **Both**: Provide identical .comics rendering behavior

## File Migration Specifications

### SECTION 1: Files to Copy Completely (1:1 Migration)

These files are copied AS-IS from legacy projects with ONLY package/import path changes.

#### 1.1 Android (Java) - Complete Copy

**Source:** `apps/mahabharata-mobile-java-v2012/app/src/main/java/com/fulldome/mahabharata/`
**Target:** `libs/flutter_comics/android/src/main/java/net/nativemind/comics/`

##### Core Models (model/visual/)

| Source File | Target Path | Lines | Changes |
|-------------|-------------|-------|---------|
| `model/visual/Comics.java` | `model/visual/Comics.java` | 155 | Package: `com.fulldome.mahabharata` → `net.nativemind.comics` |
| `model/visual/Layer.java` | `model/visual/Layer.java` | 162 | Package change only |
| `model/visual/Image.java` | `model/visual/Image.java` | ~40 | Package change only |
| `model/visual/Sound.java` | `model/visual/Sound.java` | 189 | Package change only |

**Critical dependencies to preserve:**
- `Sound.java` uses `com.ironwaterstudio.utils.SoundManager` → copy SoundManager
- `Comics.java` uses `ComicsDescriptor` → copy ComicsDescriptor
- `Layer.java` uses animation classes → copy all animation classes

##### Animation System (model/visual/animation/)

| Source File | Target Path | Lines | Changes |
|-------------|-------------|-------|---------|
| `model/visual/animation/Anim.java` | `model/visual/animation/Anim.java` | ~30 | Package change only |
| `model/visual/animation/LayerAnim.java` | `model/visual/animation/LayerAnim.java` | ~80 | Package change only (extends Anim) |
| `model/visual/animation/TranslateAnim.java` | `model/visual/animation/TranslateAnim.java` | ~60 | Package change only |
| `model/visual/animation/RotateAnim.java` | `model/visual/animation/RotateAnim.java` | ~70 | Package change only |
| `model/visual/animation/ScaleAnim.java` | `model/visual/animation/ScaleAnim.java` | ~70 | Package change only |
| `model/visual/animation/AlphaAnim.java` | `model/visual/animation/AlphaAnim.java` | ~50 | Package change only |
| `model/visual/animation/SoundAnim.java` | `model/visual/animation/SoundAnim.java` | ~40 | Package change only |
| `model/visual/animation/AnimType.java` | `model/visual/animation/AnimType.java` | ~20 | Package change only (enum) |

##### ZIP Archive Handler

| Source File | Target Path | Lines | Changes |
|-------------|-------------|-------|---------|
| `model/ComicsDescriptor.java` | `model/ComicsDescriptor.java` | 73 | Package change only |

**Dependency:** Uses `ZipResourceFile` from `com.android.vending.expansion.zipfile` (add to gradle)

##### Rendering Controls (controls/)

| Source File | Target Path | Lines | Changes |
|-------------|-------------|-------|---------|
| `controls/LayersView.java` | `controls/LayersView.java` | 201 | Package change only |
| `controls/TileImageView.java` | `controls/TileImageView.java` | 245 | Package change only |
| `controls/ZoomFrameLayout.java` | `controls/ZoomFrameLayout.java` | ~150 | Package change only |

**Critical features to preserve:**
- `TileImageView.java`:
  - TILE_SIZE = 512
  - ZOOM_LEVELS = {1.0f, 0.5f, 0.25f, 0.125f}
  - Tile naming: `{imageName}_{zoom*1000}_{col}_{row}.png`
  - Lazy loading/unloading based on visibility
  - Alpha-based hit testing (`isHit()` method)
- `LayersView.java`:
  - Static transformations via `getChildStaticTransformation()`
  - Matrix application from `Layer.getMatrix()`
  - Alpha blending from `Layer.getAlpha()`

##### Utilities

**Source:** `apps/mahabharata-mobile-java-v2012/app/src/main/java/com/ironwaterstudio/`
**Target:** `libs/flutter_comics/android/src/main/java/net/nativemind/comics/utils/`

| Source File | Target Path | Lines | Changes |
|-------------|-------------|-------|---------|
| `utils/SoundManager.java` | `utils/SoundManager.java` | 281 | Package: `com.ironwaterstudio.utils` → `net.nativemind.comics.utils` |

**Critical SoundManager features:**
- MediaPlayer wrapper with AudioFocus handling
- Async prepare with listener callbacks
- Volume animation support
- Looping support
- Position tracking
- Error handling with retry logic

**Source:** `apps/mahabharata-mobile-java-v2012/app/src/main/java/com/fulldome/mahabharata/utils/`

| Source File | Target Path | Lines | Changes |
|-------------|-------------|-------|---------|
| `utils/ImageManager.java` | `utils/ImageManager.java` | ~200 | Package change + remove app-specific analytics |

#### 1.2 iOS (Swift) - Complete Copy

**Source:** `apps/mahabharata-mobile-swift-v2012/Mahabharata/`
**Target:** `libs/flutter_comics/ios/comics/Sources/comics/`

##### Core Models (Model/DataClasses/Visual/)

| Source File | Target Path | Lines | Changes |
|-------------|-------------|-------|---------|
| `Model/DataClasses/Visual/Comics.swift` | `Model/Comics.swift` | 52 | Import changes only |
| `Model/DataClasses/Visual/Layer.swift` | `Model/Layer.swift` | ~193 | Import changes only |
| `Model/DataClasses/Visual/Image.swift` | `Model/Image.swift` | ~48 | Import changes only |
| `Model/DataClasses/Visual/Sound.swift` | `Model/Sound.swift` | 22 | Import changes only (data class only) |

**Note:** Swift Sound.swift is ONLY data class. Sound playback logic is separate (see SoundManager).

##### Animation System (Model/DataClasses/Visual/Animations/)

| Source File | Target Path | Lines | Changes |
|-------------|-------------|-------|---------|
| `Model/DataClasses/Visual/Animations/Anim.swift` | `Model/Animations/Anim.swift` | ~30 | Import changes only |
| `Model/DataClasses/Visual/Animations/LayerAnim.swift` | `Model/Animations/LayerAnim.swift` | ~80 | Import changes only |
| `Model/DataClasses/Visual/Animations/TranslateAnim.swift` | `Model/Animations/TranslateAnim.swift` | ~60 | Import changes only |
| `Model/DataClasses/Visual/Animations/RotateAnim.swift` | `Model/Animations/RotateAnim.swift` | ~70 | Import changes only |
| `Model/DataClasses/Visual/Animations/ScaleAnim.swift` | `Model/Animations/ScaleAnim.swift` | ~70 | Import changes only |
| `Model/DataClasses/Visual/Animations/AlphaAnim.swift` | `Model/Animations/AlphaAnim.swift` | ~50 | Import changes only |
| `Model/DataClasses/Visual/Animations/SoundAnim.swift` | `Model/Animations/SoundAnim.swift` | ~40 | Import changes only |

##### Rendering Views (Views/)

| Source File | Target Path | Lines | Changes |
|-------------|-------------|-------|---------|
| `Views/Tiles/ImageScrollView.swift` | `Views/ImageScrollView.swift` | 501 | Import changes + remove app-specific code |
| `Views/Tiles/TileImageView.swift` | `Views/TileImageView.swift` | 195 | Import changes only |

**Critical ImageScrollView features (ALL-IN-ONE view):**
- Combines LayersView + Sound Controller functionality
- Manages UIScrollView with tiles container
- Applies layer transformations: `tile.transform = CATransform3DGetAffineTransform(layer.element.matrix)`
- Applies alpha blending: `tile.alpha = CGFloat(layer.element.alpha)`
- Calls `comics.process(scrollOffset:)` on scroll
- **Sound playback** via `playSoundsByOffset()` (lines 271-316)
- Point sounds vs range sounds (looping)
- SoundManager integration via Associated Objects on SoundAnim
- Tile lazy loading: `prepareTiles()` for visible, `killTiles()` for off-screen
- Methods: `pauseSounds()`, `resumeSounds()`, `mute()`, `reloadLanguage()`

**Critical TileImageView features:**
- Uses `CATiledLayer` for tile rendering
- `CATiledLayerNoAnim` class to disable fade animation
- Tile size: 512x512
- `prepareTiles()` - lazy tile loading
- `killTiles()` - memory cleanup
- Integration with ArchiveManager

##### Sound System (Library/SoundManager/)

| Source File | Target Path | Lines | Changes |
|-------------|-------------|-------|---------|
| `Library/SoundManager/SoundManager.swift` | `Library/SoundManager.swift` | 162 | Import changes only |
| `Extensions/AVPlayer/AVPlayer+Fade.swift` | `Extensions/AVPlayer+Fade.swift` | ~50 | Import changes only |

**Critical SoundManager features:**
- AVPlayer wrapper with AVAudioSession management
- Loop playback support
- Fade in/out animations
- Seek support
- Notification-based completion handling

##### Archive Management (Controllers/)

| Source File | Target Path | Lines | Changes |
|-------------|-------------|-------|---------|
| `Controllers/ArchiveManager.swift` | `Library/ArchiveManager.swift` | ~150 | Import changes + remove app-specific code |

**Functions to preserve:**
- `layer(name:success:)` - load image from ZIP
- `data(success:)` - load data.json from ZIP
- `sound(name:)` - load sound from ZIP
- ZIP extraction and caching logic

##### Utilities (Library/)

| Source File | Target Path | Lines | Changes |
|-------------|-------------|-------|---------|
| `Library/ImageManager/ImageManager.swift` | `Library/ImageManager.swift` | ~100 | Import changes only |
| `Library/CacheManager/CacheManager.swift` | `Library/CacheManager.swift` | ~80 | Import changes only |

---

### SECTION 2: Files to Copy Partially (Extract Specific Functions)

These files contain both app-specific and reusable code. Copy ONLY the specified functions/classes.

#### 2.1 Android (Java) - Partial Copy

##### From: `model/Settings.java`

**Functions to extract:**
```java
public class Settings {
    private boolean soundOn;

    public boolean isSoundOn() { return soundOn; }
    public void setSoundOn(boolean soundOn) { this.soundOn = soundOn; }

    // Save/load from SharedPreferences
    public void save() { ... }
    public static Settings load(Context context) { ... }
}
```

**Target:** Create new `libs/flutter_comics/android/.../model/ComicsSettings.java`
**Why:** Remove app-specific settings (language, etc), keep only sound on/off

##### From: `model/LayerAnimTypeAdapter.java`

**Entire class needed:**
```java
public class LayerAnimTypeAdapter implements JsonDeserializer<LayerAnim> {
    @Override
    public LayerAnim deserialize(JsonElement json, Type typeOfT, ...) {
        // Custom Gson deserialization for animation polymorphism
    }
}
```

**Target:** `libs/flutter_comics/android/.../model/visual/animation/LayerAnimTypeAdapter.java`
**Why:** Required for Gson to deserialize animations from data.json

##### From: `utils/ImageManager.java`

**Functions to EXCLUDE:**
- Analytics tracking calls (`FbUtils.logEvent(...)`)
- App-specific error handling that references Activity classes

**Functions to KEEP:**
- `getBitmap()` - load image from ComicsDescriptor
- `cancel()` - cancel image loading
- `buildKey()` - cache key generation
- LRU cache integration

**Target:** `libs/flutter_comics/android/.../utils/ImageManager.java`

##### From: `server/CacheManager.java`

**Extract only:**
```java
public class CacheManager {
    private static LruCache<String, Bitmap> bitmapCache;

    public static LruCache<String, Bitmap> getBitmapCache() { ... }
    // Bitmap cache management only
}
```

**Target:** Create simplified `libs/flutter_comics/android/.../utils/BitmapCacheManager.java`
**Why:** Original has network cache, database cache - we only need bitmap cache

#### 2.2 iOS (Swift) - Partial Copy

##### From: `Views/Tiles/ImageScrollView.swift`

**Functions to EXCLUDE:**
- `ImageScrollViewDelegate` protocol - app-specific
- `reloadLanguage()` - app-specific language switching
- Analytics/logging calls
- References to `Settings.shared` - replace with library settings

**Functions to KEEP:**
- **ALL** sound playback logic (`playSoundsByOffset()`, `playSound()`, `stopSound()`)
- **ALL** layer transformation logic (matrix, alpha application)
- **ALL** tile management logic (`displayTiles()`, `loadComics()`)
- ScrollView delegate methods
- `pauseSounds()`, `resumeSounds()`, `mute()`

**Target:** `libs/flutter_comics/ios/comics/Sources/comics/Views/ImageScrollView.swift`
**Changes:**
- Remove ImageScrollViewDelegate protocol
- Remove reloadLanguage() or make it use library-provided language settings
- Remove Settings.shared references - use parameter-based configuration

##### From: Various extension files

**Only if needed by core functionality. Most extensions are app-specific.**

**Keep:**
- `Foundation+Extension.swift` - IF it has string/data utilities used by Comics
- `FileManager+Extension.swift` - IF used by ArchiveManager

**Skip:**
- UI styling extensions (UIColor+Style, UIFont+Style, etc)
- App-specific helpers

---

### SECTION 3: Unfinished/Incomplete Functionality

These are features that were started but NOT fully implemented in legacy code.

#### 3.1 ~~Sound Playback in Swift~~ - ✅ IMPLEMENTED

**Status:** **FOUND AND WORKING**
- Java version: Separate `Sound.java` class (189 lines)
- Swift version: **Integrated into `ImageScrollView.swift`** (lines 271-410)
- Sound playback is FULLY implemented using Associated Objects pattern

**How it works in Swift:**
```swift
// ImageScrollView.swift uses Associated Objects to store SoundManager per animation
extension SoundAnim {
    var player: SoundManager? { ... }  // Stored on SoundAnim instance
    var isPlaying: Bool { ... }
}

// Sound playback triggered in scrollViewDidScroll
private func playSoundsByOffset() {
    for sound in comics.sounds {
        for animation in sound.animations {
            // Point sound vs range sound logic
            if animationStart == animationEnd { playSound() }
            else if inRange && !isPlaying { playSound(loop: true) }
            else if outOfRange && isPlaying { stopSound(fadeOut) }
        }
    }
}
```

**Decision:** ✅ Use existing `ImageScrollView.swift` as-is - no new SoundController needed

#### 3.2 Popup Images (PARTIALLY IMPLEMENTED)

**Status:**
- Java: `Image.hasPopup()`, `Image.getPopup()` exist
- Java: `Layer.getPopup()` exists
- Swift: Similar methods exist
- **BUT:** NO UI implementation for displaying popups on tap

**What's missing:**
- Tap gesture recognition on layers
- Popup overlay view/dialog
- Popup dismissal logic

**Specification:**
Not required for MVP. Popup functionality is NOT used in current production .comics files.

**Decision:** Skip for initial release. Add in future version if needed.

#### 3.3 Image Manager Async Loading (INCOMPLETE)

**Status:**
- Java version has `ImageCallListener` callbacks
- But loading is not fully async - blocks on disk I/O

**What's missing:**
- True background thread loading
- Priority queue for visible tiles
- Cancellation of off-screen tiles

**Specification:**
Current implementation is "good enough". Optimize in future if performance issues arise.

**Decision:** Use existing implementation as-is.

#### 3.4 ~~Swift LayersView~~ - ✅ IMPLEMENTED

**Status:** **FOUND AND WORKING**
- Java has: `LayersView.java` (201 lines) - separate class
- Swift has: **`ImageScrollView.swift`** (501 lines) - combines LayersView + Sound + ScrollView

**How it works in Swift:**
```swift
// ImageScrollView.swift:244-259
for layer in comics.layers.enumerated() {
    let tile = self.tilingViews[layer.offset]
    tile.transform = CATransform3DGetAffineTransform(layer.element.matrix)  // Matrix transformation
    tile.alpha = CGFloat(layer.element.alpha)                              // Alpha blending

    if tile.frame.intersects(intersectRect) {
        tile.prepareTiles()  // Lazy load visible tiles
    }
}
```

**Decision:** ✅ Use existing `ImageScrollView.swift` - it's an all-in-one view combining:
- LayersView functionality (transformations, alpha)
- Sound playback (scroll-triggered)
- Tile management (lazy loading)
- ScrollView coordination

---

### SECTION 4: New Files to Create (Flutter Integration)

These files are NEW and specific to Flutter plugin architecture.

#### 4.1 Android (Java) - Flutter Bridge

##### ComicsPlugin.java (Flutter Entry Point)

**Path:** `libs/flutter_comics/android/src/main/java/net/nativemind/comics/ComicsPlugin.java`
**Lines:** ~120
**Purpose:** FlutterPlugin implementation

```java
package net.nativemind.comics;

public class ComicsPlugin implements FlutterPlugin, MethodCallHandler {
  private MethodChannel channel;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    channel = new MethodChannel(binding.getBinaryMessenger(), "net.nativemind.comics");
    channel.setMethodCallHandler(this);

    // Register PlatformView
    binding.getPlatformViewRegistry().registerViewFactory(
      "net.nativemind.comics/comics_view",
      new ComicsViewFactory(binding.getBinaryMessenger())
    );
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    // Handle method channel calls (if needed)
    result.notImplemented();
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
```

##### ComicsViewFactory.java (PlatformView Factory)

**Path:** `libs/flutter_comics/android/.../ComicsViewFactory.java`
**Lines:** ~80

```java
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

##### ComicsPlatformView.java (PlatformView Implementation)

**Path:** `libs/flutter_comics/android/.../ComicsPlatformView.java`
**Lines:** ~150

```java
public class ComicsPlatformView implements PlatformView, MethodCallHandler {
  private final ZoomFrameLayout rootView;
  private LayersView layersView;
  private Comics comics;
  private MethodChannel methodChannel;

  public ComicsPlatformView(Context context, int id, Map<String, Object> args, BinaryMessenger messenger) {
    // Create method channel for this view instance
    methodChannel = new MethodChannel(messenger, "net.nativemind.comics/view_" + id);
    methodChannel.setMethodCallHandler(this);

    // Initialize view
    rootView = new ZoomFrameLayout(context);

    // Load comics from args
    String filePath = (String) args.get("filePath");
    if (filePath != null) {
      loadComics(context, filePath);
    }
  }

  private void loadComics(Context context, String filePath) {
    // Use existing Comics.create() logic
    ComicsDescriptor descriptor = ComicsDescriptor.create(new File(filePath));
    comics = Serializer.get(JsonSerializer.class).read(
      FileUtils.readStream(descriptor.getData()),
      Comics.class
    );
    comics.prepare(context, descriptor);

    // Create LayersView
    layersView = new LayersView(context, comics);
    rootView.addView(layersView);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "updateScroll":
        int offset = call.argument("offset");
        if (comics != null) {
          comics.process(offset);
          layersView.invalidate();
        }
        result.success(null);
        break;
      case "togglePreview":
        boolean show = call.argument("show");
        // Implement preview toggle
        break;
      case "toggleSounds":
        if (comics != null) {
          comics.toggleSounds();
        }
        result.success(null);
        break;
      default:
        result.notImplemented();
    }
  }

  @Override
  public View getView() {
    return rootView;
  }

  @Override
  public void dispose() {
    if (comics != null) {
      comics.release();
    }
    methodChannel.setMethodCallHandler(null);
  }
}
```

#### 4.2 iOS (Swift) - Flutter Bridge

##### ComicsPlugin.swift (Flutter Entry Point)

**Path:** `libs/flutter_comics/ios/comics/Sources/comics/ComicsPlugin.swift`
**Lines:** ~100

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

##### ComicsViewFactory.swift (PlatformView Factory)

**Path:** `libs/flutter_comics/ios/comics/Sources/comics/ComicsViewFactory.swift`
**Lines:** ~60

```swift
import Flutter

class ComicsViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    return ComicsPlatformView(frame: frame, viewId: viewId, args: args, messenger: messenger)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}
```

##### ComicsPlatformView.swift (PlatformView Implementation)

**Path:** `libs/flutter_comics/ios/comics/Sources/comics/ComicsPlatformView.swift`
**Lines:** ~160

```swift
import Flutter
import UIKit

class ComicsPlatformView: NSObject, FlutterPlatformView {
  private let rootView: UIView
  private var imageScrollView: ImageScrollView?  // Use ImageScrollView instead of LayersView
  private var comics: Comics?
  private let methodChannel: FlutterMethodChannel

  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    rootView = UIView(frame: frame)

    methodChannel = FlutterMethodChannel(
      name: "net.nativemind.comics/view_\(viewId)",
      binaryMessenger: messenger
    )

    super.init()

    methodChannel.setMethodCallHandler(handleMethodCall)

    // Load comics from args
    if let params = args as? [String: Any],
       let filePath = params["filePath"] as? String {
      loadComics(filePath: filePath)
    }
  }

  func view() -> UIView {
    return rootView
  }

  private func loadComics(filePath: String) {
    let archiveManager = ArchiveManager()
    archiveManager.currentArchiveURL = URL(fileURLWithPath: filePath)

    // Load data.json
    archiveManager.data { [weak self] data in
      guard let self = self,
            let jsonData = data else { return }

      do {
        let decoder = JSONDecoder()
        self.comics = try decoder.decode(Comics.self, from: jsonData)

        // Create ImageScrollView (includes LayersView + Sound functionality)
        if let comics = self.comics {
          self.imageScrollView = ImageScrollView()
          self.imageScrollView?.comics = comics  // This triggers prepare() and displayTiles()
          if let scrollView = self.imageScrollView {
            scrollView.frame = self.rootView.bounds
            scrollView.isComics = true
            self.rootView.addSubview(scrollView)
          }
        }
      } catch {
        print("Failed to decode comics: \(error)")
      }
    }
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "updateScroll":
      if let args = call.arguments as? [String: Any],
         let offset = args["offset"] as? Int {
        imageScrollView?.contentOffset = CGPoint(x: 0, y: CGFloat(offset))
      }
      result(nil)
    case "togglePreview":
      // Implement preview toggle
      result(nil)
    case "toggleSounds":
      if let args = call.arguments as? [String: Any],
         let muted = args["muted"] as? Bool {
        imageScrollView?.mute(muted)
      }
      result(nil)
    case "pauseSounds":
      imageScrollView?.pauseSounds()
      result(nil)
    case "resumeSounds":
      imageScrollView?.resumeSounds()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
```

##### ~~LayersView.swift~~ - NOT NEEDED

**ImageScrollView.swift already includes all LayersView functionality**

##### ~~SoundController.swift~~ - NOT NEEDED

**ImageScrollView.swift already includes all Sound playback functionality**

#### 4.3 Dart (Bridge Layer)

##### comics_platform_interface.dart

**Path:** `libs/flutter_comics/lib/comics_platform_interface.dart`
**Lines:** ~40

```dart
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'comics_method_channel.dart';

abstract class ComicsPlatformInterface extends PlatformInterface {
  ComicsPlatformInterface() : super(token: _token);

  static final Object _token = Object();
  static ComicsPlatformInterface _instance = MethodChannelComics();

  static ComicsPlatformInterface get instance => _instance;

  static set instance(ComicsPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }
}
```

##### comics_method_channel.dart

**Path:** `libs/flutter_comics/lib/comics_method_channel.dart`
**Lines:** ~30

```dart
import 'package:flutter/services.dart';
import 'comics_platform_interface.dart';

class MethodChannelComics extends ComicsPlatformInterface {
  final methodChannel = const MethodChannel('net.nativemind.comics');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
```

##### widgets/comics_view.dart

**Path:** `libs/flutter_comics/lib/widgets/comics_view.dart`
**Lines:** ~120

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class ComicsView extends StatefulWidget {
  final String filePath;
  final ValueChanged<int>? onScrollChanged;
  final bool showPreview;

  const ComicsView({
    Key? key,
    required this.filePath,
    this.onScrollChanged,
    this.showPreview = false,
  }) : super(key: key);

  @override
  State<ComicsView> createState() => _ComicsViewState();
}

class _ComicsViewState extends State<ComicsView> {
  MethodChannel? _viewChannel;

  @override
  Widget build(BuildContext context) {
    const String viewType = 'net.nativemind.comics/comics_view';

    final Map<String, dynamic> creationParams = {
      'filePath': widget.filePath,
      'showPreview': widget.showPreview,
    };

    if (Platform.isAndroid) {
      return AndroidView(
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }

    return Text('$defaultTargetPlatform is not supported');
  }

  void _onPlatformViewCreated(int id) {
    _viewChannel = MethodChannel('net.nativemind.comics/view_$id');
  }

  Future<void> updateScroll(int offset) async {
    await _viewChannel?.invokeMethod('updateScroll', {'offset': offset});
  }

  Future<void> togglePreview(bool show) async {
    await _viewChannel?.invokeMethod('togglePreview', {'show': show});
  }

  Future<void> toggleSounds() async {
    await _viewChannel?.invokeMethod('toggleSounds');
  }

  @override
  void dispose() {
    _viewChannel = null;
    super.dispose();
  }
}
```

##### comics.dart (Public API)

**Path:** `libs/flutter_comics/lib/comics.dart`
**Lines:** ~10

```dart
library comics;

export 'widgets/comics_view.dart';
export 'comics_platform_interface.dart';
```

---

## Data Flow Specifications

### 1. Loading Comics File

```
Flutter App
  │
  ├─ ComicsView(filePath: "/path/to/file.comics")
  │
  └─> PlatformView created
       │
       ├─ Android: ComicsPlatformView
       │   └─> ComicsDescriptor.create(filePath)
       │       └─> ZipResourceFile opens .comics ZIP
       │           └─> Read data.json
       │               └─> Gson deserialize to Comics object
       │                   └─> Comics.prepare()
       │                       ├─> Layer.prepare() for each layer
       │                       └─> Sound.prepare() for each sound
       │                           └─> LayersView created
       │
       └─ iOS: ComicsPlatformView
           └─> ArchiveManager.currentArchiveURL = filePath
               └─> archiveManager.data { jsonData in ... }
                   └─> JSONDecoder().decode(Comics.self)
                       └─> comics.prepare()
                           └─> LayersView created
```

### 2. Scroll Update

```
Flutter App
  │
  ├─ comicsView.updateScroll(1500)
  │
  └─> MethodChannel('comics/view_0').invokeMethod('updateScroll', {offset: 1500})
       │
       ├─ Android:
       │   └─> comics.process(1500)
       │       ├─> For each Layer:
       │       │   └─> layer.buildMatrixAndAlpha(1500)
       │       │       └─> Apply animations at scroll position 1500
       │       │           └─> Update layer.matrix and layer.alpha
       │       └─> For each Sound:
       │           └─> sound.process(1500, previousScrollOffset, skipPointSounds)
       │               └─> Check if scroll position triggers sound
       │                   ├─> If in range: play(looping=true)
       │                   └─> If out of range: stop(animated=true)
       │
       └─ iOS:
           └─> comics.process(scrollOffset: 1500)
               ├─> For each Layer:
               │   └─> layer.buildMatrixAndAlpha(scrollOffset: 1500)
               │       └─> Update layer.matrix and layer.alpha
               └─> For each Sound (via SoundController):
                   └─> soundController.process(1500, previousScrollOffset, skipPointSounds)
                       └─> SoundManager.play(url:loop:)
```

### 3. Tile Rendering

```
LayersView draws
  │
  └─> For each TileImageView:
       │
       ├─> onUpdate(scale, scrollX, scrollY)
       │   └─> selectZoom() based on scale
       │       └─> Returns 1.0, 0.5, 0.25, or 0.125
       │
       ├─> loadBitmapIfNeeded()
       │   └─> Get visible rect
       │       └─> For each tile in selected zoom level:
       │           ├─> If tile.isPreloadBitmap():
       │           │   └─> ImageManager.getBitmap(descriptor, tile.fileName, sampleSize)
       │           │       └─> Check cache → Load from ZIP → Decode → Cache
       │           └─> Else:
       │               └─> ImageManager.cancel(descriptor, tile.fileName)
       │
       └─> onDraw(canvas)
           └─> For each visible tile:
               └─> Get bitmap from cache
                   └─> canvas.drawBitmap(bitmap, tile.rect)
```

---

## Dependencies

### Android (build.gradle)

```gradle
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

### iOS (Package.swift)

No external dependencies needed - uses Foundation, AVFoundation, UIKit.

### Dart (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  plugin_platform_interface: ^2.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

---

## Testing Strategy

### Unit Tests (Native Code)

**Android:**
- `ComicsDescriptorTest.java` - ZIP extraction
- `LayerTest.java` - Animation interpolation
- `SoundTest.java` - Sound triggering logic

**iOS:**
- `ComicsTests.swift` - JSON decoding
- `LayerTests.swift` - Matrix transformations
- `SoundControllerTests.swift` - Playback logic

### Integration Tests (Flutter)

```dart
testWidgets('ComicsView loads and displays', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ComicsView(filePath: 'path/to/test.comics'),
    ),
  );

  await tester.pumpAndSettle();

  // Verify native view is created
  expect(find.byType(ComicsView), findsOneWidget);
});
```

### Example App Tests

Test with real .comics files from production:
- Small file (~1MB, 5 layers, no sound)
- Medium file (~5MB, 10 layers, 2 sounds)
- Large file (~20MB, 20+ layers, tiled images, multiple sounds)

---

## Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| Comics loading | < 500ms | Time from `loadComics()` to first frame |
| Tile loading (visible) | < 100ms | Time from tile request to display |
| Scroll frame rate | 60 FPS | No frame drops during scroll |
| Memory usage | < 200MB | Peak memory for large comics |
| Sound sync | < 50ms lag | Delay between scroll trigger and audio start |

---

## Security Considerations

1. **File Path Validation**: Ensure `filePath` parameter doesn't allow directory traversal
2. **ZIP Bomb Protection**: Limit maximum uncompressed size
3. **Memory Limits**: Cap number of cached tiles
4. **Audio Focus**: Properly handle audio focus on Android
5. **AVAudioSession**: Properly configure session on iOS

---

## Migration Checklist

### Android (Java) - Native Code
- [ ] Copy all model classes (Comics, Layer, Image, Sound, animations)
- [ ] Copy rendering (LayersView, TileImageView, ZoomFrameLayout)
- [ ] Copy SoundManager
- [ ] Copy ComicsDescriptor (ZIP handler)
- [ ] Copy ImageManager + cache utilities
- [ ] Create ComicsPlugin.java (Flutter bridge)
- [ ] Create ComicsViewFactory.java (PlatformView factory)
- [ ] Create ComicsPlatformView.java (PlatformView impl)

### iOS (Swift) - Native Code
- [ ] Copy all model classes (Comics, Layer, Image, Sound, animations)
- [ ] Copy ImageScrollView.swift (all-in-one: rendering + sound + scroll)
- [ ] Copy TileImageView.swift
- [ ] Copy SoundManager.swift + AVPlayer+Fade.swift
- [ ] Copy ArchiveManager.swift (ZIP handler)
- [ ] Copy ImageManager + CacheManager
- [ ] Create ComicsPlugin.swift (Flutter bridge)
- [ ] Create ComicsViewFactory.swift (PlatformView factory)
- [ ] Create ComicsPlatformView.swift (PlatformView impl - uses ImageScrollView)

### Dart - Bridge Layer
- [ ] Create comics_platform_interface.dart
- [ ] Create comics_method_channel.dart
- [ ] Create widgets/comics_view.dart (AndroidView/UiKitView wrapper)
- [ ] Create comics.dart (public API)

### Configuration & Testing
- [ ] Update package identifiers (com.fulldome → net.nativemind)
- [ ] Configure Gradle dependencies (Android)
- [ ] Configure build settings (iOS)
- [ ] Test with example .comics files
- [ ] Performance profiling

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [any conditions or clarifications]
