# Specifications: Flutter Puzzle Library

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-19

## Architecture Overview

The flutter_puzzle library follows the same **native-first architecture** as flutter_comics. It **DEPENDS** on flutter_comics for rendering individual puzzle pieces.

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App (Dart)                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ├─ PuzzleView Widget (Dart)
                       │  └─ AndroidView / UiKitView
                       │
                       ├─ Method Channel Bridge
                       │
       ┌───────────────┴────────────────┐
       │                                │
┌──────▼──────────┐           ┌────────▼─────────┐
│ Android (Java)  │           │   iOS (Swift)    │
├─────────────────┤           ├──────────────────┤
│ PuzzleActivity  │           │ PuzzleView       │
│ PieceView       │           │ PieceView        │
│   ↓ uses        │           │   ↓ uses         │
│ LayersView ─────┼───────────┼──> LayersView    │
│ (from comics)   │           │ (from comics)    │
└─────────────────┘           └──────────────────┘
```

**Key Dependency:** Puzzle pieces contain .comics content, rendered via flutter_comics library.

## Current State Analysis

### Already Copied to libs/flutter_puzzle (INCOMPLETE)

#### Android (Java) - Partially copied:
- ✅ `PuzzlePlugin.java` - Basic boilerplate (needs extension for PlatformView)
- ✅ `model/puzzle/Puzzle.java` - WRONG package (`com.fulldome.mahabharata`)
- ✅ `model/puzzle/Piece.java` - WRONG package
- ✅ `model/puzzle/Puzzles.java` - WRONG package
- ✅ `model/puzzle/PieceState.java` - WRONG package
- ✅ `screens/PuzzleActivity.java` - NOT NEEDED (Android Activity code)
- ✅ `screens/PiecesViewController.java` - NOT NEEDED
- ✅ `fragments/` - NOT NEEDED (UI fragments)
- ✅ `controls/PieceView.java` - NEEDED but has wrong package
- ✅ `controls/SoundBadge.java` - NOT NEEDED (UI control)
- ✅ `utils/SoundManager.java` - DUPLICATE (should use from flutter_comics)
- ✅ `utils/LruBitmapCache.java` - DUPLICATE (should use from flutter_comics)
- ✅ `utils/FileUtils.java` - DUPLICATE
- ✅ `utils/ReflectionUtils.java` - NOT NEEDED

**ACTION REQUIRED:**
1. Fix package names in all model classes
2. Remove duplicate utils (use from flutter_comics)
3. Remove Android Activity/Fragment UI code
4. Keep only PieceView control
5. Extend PuzzlePlugin for PlatformView support

#### iOS (Swift) - Partially copied:
- ✅ `PuzzlePlugin.swift` - Basic boilerplate (needs extension)
- ✅ `Model/DataClasses/Puzzle.swift` - Basic data class
- ✅ `Model/DataClasses/Piece.swift` - Basic data class
- ✅ `Views/TileImageView.swift` - DUPLICATE (should use from flutter_comics)
- ✅ `Views/ImageScrollView.swift` - NOT NEEDED

**ACTION REQUIRED:**
1. Remove duplicate TileImageView (use from flutter_comics)
2. Remove ImageScrollView
3. Add PieceView implementation
4. Extend PuzzlePlugin for PlatformView support

---

## File Migration Specifications

### SECTION 1: Files to Copy Completely (1:1 Migration)

These files are copied AS-IS with ONLY package/import path changes.

#### 1.1 Android (Java) - Complete Copy

**Source:** `apps/mahabharata-mobile-java-v2012/app/src/main/java/com/fulldome/mahabharata/`
**Target:** `libs/flutter_puzzle/android/src/main/java/net/nativemind/puzzle/`

##### Puzzle Models (model/puzzle/)

| Source File | Target Path | Lines | Changes | Status |
|-------------|-------------|-------|---------|--------|
| `model/puzzle/Puzzle.java` | `model/puzzle/Puzzle.java` | 108 | Package: `com.fulldome.mahabharata` → `net.nativemind.puzzle` | ⚠️ COPIED with WRONG package |
| `model/puzzle/Piece.java` | `model/puzzle/Piece.java` | 176 | Package change + remove app dependencies | ⚠️ COPIED with WRONG package |
| `model/puzzle/Puzzles.java` | `model/puzzle/Puzzles.java` | 148 | Package change + remove app dependencies | ⚠️ COPIED with WRONG package |
| `model/puzzle/PieceState.java` | `model/puzzle/PieceState.java` | ~60 | Package change only | ⚠️ COPIED with WRONG package |

**Critical features to preserve:**
- `Puzzle.java`:
  - `toggleSounds()` - coordinates sound on/off for all pieces
  - `pauseSounds()`, `resumeSounds()`, `releaseSounds()` - lifecycle management
  - `getPiece(id)` - piece lookup
  - `getDownloadedIds()` - track download state
- `Piece.java`:
  - `comics` property (Comics instance from flutter_comics)
  - `download()`, `completeDownload()`, `delete()` - download management
  - `isDownloaded()` - download state check
  - State persistence via `PieceState`
- `Puzzles.java`:
  - Singleton pattern
  - `save()`, `load()` - JSON persistence
  - `update()` - sync puzzle collection
  - `queryDownloads()` - download tracking

##### Puzzle Controls (controls/)

| Source File | Target Path | Lines | Changes | Status |
|-------------|-------------|-------|---------|--------|
| `controls/PieceView.java` | `controls/PieceView.java` | 62 | Package change + extend flutter_comics LayersView | ⚠️ COPIED with WRONG package |

**Critical PieceView features:**
- Extends LayersView from flutter_comics
- Calculates scroll based on horizontal position
- Formula: `percent = scroll / scrollArea; finalScroll = width * percent`
- Preview mode toggle integration
- Piece state management

##### Data Classes

| Source File | Target Path | Lines | Changes | Status |
|-------------|-------------|-------|---------|--------|
| `model/DownloadInfoMap.java` | `model/DownloadInfoMap.java` | ~40 | Package change only | ❌ NOT copied yet |

#### 1.2 iOS (Swift) - Complete Copy

**Source:** `apps/mahabharata-mobile-swift-v2012/Mahabharata/`
**Target:** `libs/flutter_puzzle/ios/puzzle/Sources/puzzle/`

##### Puzzle Models (Model/DataClasses/)

| Source File | Target Path | Lines | Changes | Status |
|-------------|-------------|-------|---------|--------|
| `Model/DataClasses/Puzzle.swift` | `Model/Puzzle.swift` | ~80 | Import changes only | ✅ COPIED |
| `Model/DataClasses/Piece.swift` | `Model/Piece.swift` | ~120 | Import changes only | ✅ COPIED |
| `Model/DataClasses/Puzzles.swift` | `Model/Puzzles.swift` | ~100 | Import changes only | ❌ NOT copied yet |
| `Model/DataClasses/PieceState.swift` | `Model/PieceState.swift` | ~50 | Import changes only | ❌ NOT copied yet |

##### Puzzle Views (Views/)

| Source File | Target Path | Lines | Changes | Status |
|-------------|-------------|-------|---------|--------|
| `Views/Puzzle/PieceView.swift` | `Views/PieceView.swift` | ~80 | Import changes + use flutter_comics LayersView | ❌ NOT copied yet |

**Note:** PieceView.swift should wrap LayersView from flutter_comics, NOT implement its own rendering.

---

### SECTION 2: Files to REMOVE (Already Copied by Mistake)

These files were copied but are NOT needed for Flutter library.

#### 2.1 Android (Java) - Remove

| File | Reason | Action |
|------|--------|--------|
| `screens/PuzzleActivity.java` | Android Activity - UI code not needed in library | DELETE |
| `screens/PiecesViewController.java` | Android Fragment - UI code not needed | DELETE |
| `fragments/PuzzlePreviewFragment.java` | Android Fragment - app-specific UI | DELETE |
| `fragments/MusicsFragment.java` | Android Fragment - app-specific UI | DELETE |
| `controls/SoundBadge.java` | UI control - app-specific | DELETE |
| `utils/SoundManager.java` | DUPLICATE - use from flutter_comics | DELETE |
| `utils/LruBitmapCache.java` | DUPLICATE - use from flutter_comics | DELETE |
| `utils/FileUtils.java` | DUPLICATE - use from flutter_comics | DELETE |
| `utils/ReflectionUtils.java` | Not needed for puzzle | DELETE |

#### 2.2 iOS (Swift) - Remove

| File | Reason | Action |
|------|--------|--------|
| `Views/TileImageView.swift` | DUPLICATE - use from flutter_comics | DELETE |
| `Views/ImageScrollView.swift` | Not needed - custom UI | DELETE |

---

### SECTION 3: Files to Copy Partially (Extract Specific Functions)

#### 3.1 Android (Java) - Partial Copy

##### From: `controls/PieceView.java`

**Functions to MODIFY:**

```java
public class PieceView extends LayersView { // Use LayersView from flutter_comics
    // KEEP:
    protected void onScroll(int scrollX, int scrollY) {
        // Calculate vertical scroll from horizontal position
        float percent = (float) scrollX / (float) getScrollArea();
        int finalScroll = (int) (getWidth() * percent);
        if (getComics() != null) {
            getComics().process(finalScroll);
        }
        invalidate();
    }

    // KEEP:
    protected int getScrollArea() {
        return getPuzzleWidth() - getWidth();
    }

    // REMOVE: App-specific UI code
    // REMOVE: Analytics calls
}
```

**Target:** `libs/flutter_puzzle/android/.../controls/PieceView.java`
**Changes:**
- Remove app-specific UI methods
- Remove analytics
- Keep scroll mapping logic
- Extend flutter_comics LayersView

##### From: `model/puzzle/Piece.java`

**Functions to EXCLUDE:**
- References to Android Activity/Context for download UI
- References to app-specific download manager

**Functions to KEEP:**
- `download()` - but make it callback-based (library doesn't handle actual download)
- `completeDownload()` - persist download completion
- `delete()` - file deletion
- `isDownloaded()` - download state check
- State serialization

**Target:** `libs/flutter_puzzle/android/.../model/puzzle/Piece.java`

##### From: `model/puzzle/Puzzles.java`

**Functions to EXCLUDE:**
- References to app-specific Settings
- References to Android Application context for global state

**Functions to KEEP:**
- Singleton pattern
- JSON serialization/deserialization
- Puzzle collection management
- Download tracking

**Target:** `libs/flutter_puzzle/android/.../model/puzzle/Puzzles.java`

---

### SECTION 4: Unfinished/Incomplete Functionality

#### 4.1 Swift Puzzles Model (MISSING)

**Status:**
- Java has full `Puzzles.java` implementation (148 lines)
- Swift project has NO equivalent Puzzles singleton
- Puzzle collection management is missing

**What's missing:**
- Swift equivalent of Puzzles singleton
- Save/load to JSON
- Puzzle update logic
- Download tracking

**Specification:**
Create new `ios/puzzle/Sources/puzzle/Model/Puzzles.swift` that:
1. Implements singleton pattern
2. Manages array of Puzzle instances
3. JSON serialization/deserialization
4. Save to UserDefaults or file
5. Query download state

**Estimated:** ~100 lines (port from Java Puzzles.java)

#### 4.2 Swift PieceState (MISSING)

**Status:**
- Java has `PieceState.java` for persisting piece state
- Swift project has NO equivalent

**What's missing:**
- Download state tracking
- Current scroll position persistence
- Preview mode state

**Specification:**
Create new `ios/puzzle/Sources/puzzle/Model/PieceState.swift` that:
1. Codable struct
2. Properties: loadedVersion, savedFile, currentScroll, showPreview, downloadInfo
3. JSON serialization

**Estimated:** ~50 lines (port from Java PieceState.java)

#### 4.3 Swift PieceView (MISSING)

**Status:**
- Java has `PieceView.java` (62 lines)
- Swift project has NO equivalent

**What's missing:**
- Scroll mapping from horizontal to vertical
- Integration with flutter_comics LayersView
- Preview toggle

**Specification:**
Create new `ios/puzzle/Sources/puzzle/Views/PieceView.swift` that:
1. Wraps LayersView from flutter_comics
2. Implements scroll mapping: `finalScroll = width * (scrollX / scrollArea)`
3. Updates comics on scroll change
4. Handles preview mode toggle

**Estimated:** ~80 lines (port from Java PieceView.java)

#### 4.4 Download Management (INCOMPLETE)

**Status:**
- Java/Swift have `download()` methods in Piece
- BUT actual download implementation is app-specific

**What's missing:**
- Download progress callbacks
- Network layer integration
- File writing

**Specification:**
Library should expose download events via Method Channel, but NOT implement actual downloading.

**Decision:**
- Library provides callbacks: `onDownloadStart(pieceId)`, `onDownloadProgress(pieceId, bytes, total)`, `onDownloadComplete(pieceId, filePath)`
- Consuming app implements actual download logic
- Library handles file path storage and state persistence

---

### SECTION 5: New Files to Create (Flutter Integration)

These files are NEW and specific to Flutter plugin architecture.

#### 5.1 Android (Java) - Flutter Bridge

##### PuzzlePlugin.java (Extend Existing)

**Path:** `libs/flutter_puzzle/android/src/main/java/net/nativemind/puzzle/PuzzlePlugin.java`
**Current:** Basic boilerplate (39 lines)
**Target:** ~120 lines
**Changes:** Add PlatformView registration

```java
package net.nativemind.puzzle;

public class PuzzlePlugin implements FlutterPlugin, MethodCallHandler {
  private MethodChannel channel;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    channel = new MethodChannel(binding.getBinaryMessenger(), "net.nativemind.puzzle");
    channel.setMethodCallHandler(this);

    // Register PlatformView
    binding.getPlatformViewRegistry().registerViewFactory(
      "net.nativemind.puzzle/puzzle_view",
      new PuzzleViewFactory(binding.getBinaryMessenger())
    );
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    // Handle global puzzle operations (load puzzles collection, etc)
    result.notImplemented();
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
```

##### PuzzleViewFactory.java (NEW)

**Path:** `libs/flutter_puzzle/android/.../PuzzleViewFactory.java`
**Lines:** ~80

```java
public class PuzzleViewFactory extends PlatformViewFactory {
  private final BinaryMessenger messenger;

  public PuzzleViewFactory(BinaryMessenger messenger) {
    super(StandardMessageCodec.INSTANCE);
    this.messenger = messenger;
  }

  @Override
  public PlatformView create(Context context, int viewId, Object args) {
    Map<String, Object> params = (Map<String, Object>) args;
    return new PuzzlePlatformView(context, viewId, params, messenger);
  }
}
```

##### PuzzlePlatformView.java (NEW)

**Path:** `libs/flutter_puzzle/android/.../PuzzlePlatformView.java`
**Lines:** ~200

```java
public class PuzzlePlatformView implements PlatformView, MethodCallHandler {
  private final FrameLayout rootView;
  private Puzzle puzzle;
  private final List<PieceView> pieceViews = new ArrayList<>();
  private MethodChannel methodChannel;

  public PuzzlePlatformView(Context context, int id, Map<String, Object> args, BinaryMessenger messenger) {
    methodChannel = new MethodChannel(messenger, "net.nativemind.puzzle/view_" + id);
    methodChannel.setMethodCallHandler(this);

    rootView = new FrameLayout(context);

    // Load puzzle from args
    String filePath = (String) args.get("filePath");
    if (filePath != null) {
      loadPuzzle(context, filePath);
    }
  }

  private void loadPuzzle(Context context, String filePath) {
    // Load puzzle.json from ZIP
    // Create PieceView for each piece
    // Layout pieces in grid based on x, y, width, height
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "loadPiece":
        int pieceId = call.argument("pieceId");
        String comicsPath = call.argument("comicsPath");
        loadPieceComics(pieceId, comicsPath);
        result.success(null);
        break;
      case "updateScroll":
        int scrollX = call.argument("scrollX");
        updatePiecesScroll(scrollX);
        result.success(null);
        break;
      case "togglePreview":
        boolean show = call.argument("show");
        togglePreview(show);
        result.success(null);
        break;
      case "toggleSounds":
        if (puzzle != null) {
          puzzle.toggleSounds();
        }
        result.success(null);
        break;
      default:
        result.notImplemented();
    }
  }

  private void loadPieceComics(int pieceId, String comicsPath) {
    Piece piece = puzzle.getPiece(pieceId);
    if (piece != null) {
      // Use flutter_comics to load .comics file
      Comics comics = Comics.create(context, new File(comicsPath));
      piece.setComics(comics);

      // Find corresponding PieceView and set comics
      for (PieceView view : pieceViews) {
        if (view.getPiece() == piece) {
          view.setComics(comics);
          break;
        }
      }
    }
  }

  @Override
  public View getView() {
    return rootView;
  }

  @Override
  public void dispose() {
    if (puzzle != null) {
      puzzle.releaseSounds();
    }
    methodChannel.setMethodCallHandler(null);
  }
}
```

#### 5.2 iOS (Swift) - Flutter Bridge

##### PuzzlePlugin.swift (Extend Existing)

**Path:** `libs/flutter_puzzle/ios/puzzle/Sources/puzzle/PuzzlePlugin.swift`
**Current:** Basic boilerplate
**Target:** ~100 lines

```swift
import Flutter

public class PuzzlePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "net.nativemind.puzzle",
      binaryMessenger: registrar.messenger()
    )
    let instance = PuzzlePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Register PlatformView
    let factory = PuzzleViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "net.nativemind.puzzle/puzzle_view")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }
}
```

##### PuzzleViewFactory.swift (NEW)

**Path:** `libs/flutter_puzzle/ios/puzzle/Sources/puzzle/PuzzleViewFactory.swift`
**Lines:** ~60

```swift
import Flutter

class PuzzleViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    return PuzzlePlatformView(frame: frame, viewId: viewId, args: args, messenger: messenger)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}
```

##### PuzzlePlatformView.swift (NEW)

**Path:** `libs/flutter_puzzle/ios/puzzle/Sources/puzzle/PuzzlePlatformView.swift`
**Lines:** ~200

```swift
import Flutter
import UIKit

class PuzzlePlatformView: NSObject, FlutterPlatformView {
  private let rootView: UIView
  private var puzzle: Puzzle?
  private var pieceViews: [PieceView] = []
  private let methodChannel: FlutterMethodChannel

  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    rootView = UIView(frame: frame)

    methodChannel = FlutterMethodChannel(
      name: "net.nativemind.puzzle/view_\(viewId)",
      binaryMessenger: messenger
    )

    super.init()

    methodChannel.setMethodCallHandler(handleMethodCall)

    // Load puzzle from args
    if let params = args as? [String: Any],
       let filePath = params["filePath"] as? String {
      loadPuzzle(filePath: filePath)
    }
  }

  func view() -> UIView {
    return rootView
  }

  private func loadPuzzle(filePath: String) {
    // Load puzzle.json from ZIP
    // Create PieceView for each piece
    // Layout pieces based on x, y, width, height
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "loadPiece":
      if let args = call.arguments as? [String: Any],
         let pieceId = args["pieceId"] as? Int,
         let comicsPath = args["comicsPath"] as? String {
        loadPieceComics(pieceId: pieceId, comicsPath: comicsPath)
      }
      result(nil)
    case "updateScroll":
      if let args = call.arguments as? [String: Any],
         let scrollX = args["scrollX"] as? Int {
        updatePiecesScroll(scrollX: scrollX)
      }
      result(nil)
    case "togglePreview":
      if let args = call.arguments as? [String: Any],
         let show = args["show"] as? Bool {
        togglePreview(show: show)
      }
      result(nil)
    case "toggleSounds":
      puzzle?.toggleSounds()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func loadPieceComics(pieceId: Int, comicsPath: String) {
    // Use flutter_comics to load .comics file
    // Set comics on piece
    // Update PieceView
  }
}
```

##### PieceView.swift (NEW)

**Path:** `libs/flutter_puzzle/ios/puzzle/Sources/puzzle/Views/PieceView.swift`
**Lines:** ~80
**Purpose:** Port of Java PieceView.java

```swift
import UIKit
// Import flutter_comics LayersView

class PieceView: UIView {
  private let piece: Piece
  private var layersView: LayersView?
  private var comics: Comics?

  init(piece: Piece, frame: CGRect) {
    self.piece = piece
    super.init(frame: frame)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setComics(_ comics: Comics) {
    self.comics = comics
    self.layersView = LayersView(comics: comics, frame: bounds)
    if let layersView = self.layersView {
      addSubview(layersView)
    }
  }

  func updateScroll(scrollX: Int) {
    // Calculate vertical scroll from horizontal position
    let scrollArea = calculateScrollArea()
    let percent = Float(scrollX) / Float(scrollArea)
    let finalScroll = Int(Float(piece.width) * percent)

    comics?.process(scrollOffset: finalScroll)
    layersView?.update(scrollOffset: finalScroll)
  }

  private func calculateScrollArea() -> Int {
    // Calculate based on puzzle width and piece position
    return 1000 // Placeholder
  }
}
```

#### 5.3 Dart (Bridge Layer)

##### puzzle_platform_interface.dart

**Path:** `libs/flutter_puzzle/lib/puzzle_platform_interface.dart`
**Lines:** ~40

```dart
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'puzzle_method_channel.dart';

abstract class PuzzlePlatformInterface extends PlatformInterface {
  PuzzlePlatformInterface() : super(token: _token);

  static final Object _token = Object();
  static PuzzlePlatformInterface _instance = MethodChannelPuzzle();

  static PuzzlePlatformInterface get instance => _instance;

  static set instance(PuzzlePlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }
}
```

##### puzzle_method_channel.dart

**Path:** `libs/flutter_puzzle/lib/puzzle_method_channel.dart`
**Lines:** ~30

```dart
import 'package:flutter/services.dart';
import 'puzzle_platform_interface.dart';

class MethodChannelPuzzle extends PuzzlePlatformInterface {
  final methodChannel = const MethodChannel('net.nativemind.puzzle');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
```

##### widgets/puzzle_view.dart

**Path:** `libs/flutter_puzzle/lib/widgets/puzzle_view.dart`
**Lines:** ~140

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PuzzleView extends StatefulWidget {
  final String filePath;
  final ValueChanged<int>? onScrollChanged;
  final Function(int pieceId)? onPieceDownloadRequested;

  const PuzzleView({
    Key? key,
    required this.filePath,
    this.onScrollChanged,
    this.onPieceDownloadRequested,
  }) : super(key: key);

  @override
  State<PuzzleView> createState() => _PuzzleViewState();
}

class _PuzzleViewState extends State<PuzzleView> {
  MethodChannel? _viewChannel;

  @override
  Widget build(BuildContext context) {
    const String viewType = 'net.nativemind.puzzle/puzzle_view';

    final Map<String, dynamic> creationParams = {
      'filePath': widget.filePath,
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
    _viewChannel = MethodChannel('net.nativemind.puzzle/view_$id');
  }

  Future<void> loadPiece(int pieceId, String comicsPath) async {
    await _viewChannel?.invokeMethod('loadPiece', {
      'pieceId': pieceId,
      'comicsPath': comicsPath,
    });
  }

  Future<void> updateScroll(int scrollX) async {
    await _viewChannel?.invokeMethod('updateScroll', {'scrollX': scrollX});
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

##### puzzle.dart (Public API)

**Path:** `libs/flutter_puzzle/lib/puzzle.dart`
**Lines:** ~10

```dart
library puzzle;

export 'widgets/puzzle_view.dart';
export 'puzzle_platform_interface.dart';
```

---

## Data Flow Specifications

### 1. Loading Puzzle File

```
Flutter App
  │
  ├─ PuzzleView(filePath: "/path/to/file.puzzle")
  │
  └─> PlatformView created
       │
       ├─ Android: PuzzlePlatformView
       │   └─> Load puzzle.json from ZIP
       │       └─> Gson deserialize to Puzzle object
       │           └─> For each Piece:
       │               └─> Create PieceView (empty, no comics yet)
       │
       └─ iOS: PuzzlePlatformView
           └─> ArchiveManager opens .puzzle ZIP
               └─> JSONDecoder().decode(Puzzle.self)
                   └─> For each Piece:
                       └─> Create PieceView (empty, no comics yet)
```

### 2. Loading Piece Comics

```
Flutter App
  │
  ├─ puzzleView.loadPiece(pieceId: 1, comicsPath: "/path/to/piece1.comics")
  │
  └─> MethodChannel('puzzle/view_0').invokeMethod('loadPiece', ...)
       │
       ├─ Android:
       │   └─> Find Piece by id
       │       └─> Comics.create(comicsPath)  // Use flutter_comics
       │           └─> piece.setComics(comics)
       │               └─> Update PieceView with comics
       │
       └─ iOS:
           └─> Find Piece by id
               └─> Load Comics via flutter_comics ArchiveManager
                   └─> piece.comics = comics
                       └─> Update PieceView with layersView
```

### 3. Scroll Update (Horizontal → Vertical Mapping)

```
Flutter App
  │
  ├─ puzzleView.updateScroll(scrollX: 500)
  │
  └─> For each PieceView:
       │
       ├─ Calculate vertical scroll:
       │   scrollArea = puzzleWidth - viewportWidth
       │   percent = scrollX / scrollArea
       │   finalScroll = pieceWidth * percent
       │
       └─> piece.comics.process(finalScroll)
           └─> Layers update matrices/alpha
               └─> Sounds trigger based on scroll position
```

---

## Dependencies

### Android (build.gradle)

```gradle
dependencies {
    // Dependency on flutter_comics
    implementation project(':flutter_comics')

    // JSON parsing
    implementation 'com.google.code.gson:gson:2.10.1'

    // AndroidX
    implementation 'androidx.annotation:annotation:1.7.0'
}
```

### iOS (Package.swift)

```swift
// Add dependency on flutter_comics package
dependencies: [
    .package(path: "../flutter_comics")
]
```

### Dart (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  plugin_platform_interface: ^2.0.2
  comics:  # Dependency on flutter_comics
    path: ../flutter_comics

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

---

## Testing Strategy

### Unit Tests (Native Code)

**Android:**
- `PuzzleTest.java` - Puzzle model operations
- `PieceTest.java` - Piece state management
- `PieceViewTest.java` - Scroll mapping logic

**iOS:**
- `PuzzleTests.swift` - JSON decoding
- `PieceTests.swift` - State persistence
- `PieceViewTests.swift` - Scroll calculations

### Integration Tests (Flutter)

```dart
testWidgets('PuzzleView loads and displays', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: PuzzleView(filePath: 'path/to/test.puzzle'),
    ),
  );

  await tester.pumpAndSettle();

  expect(find.byType(PuzzleView), findsOneWidget);
});
```

---

## Migration Checklist

- [ ] Fix package names in all copied Java model classes
- [ ] Remove duplicate utils (SoundManager, LruBitmapCache, FileUtils)
- [ ] Remove Android Activity/Fragment code
- [ ] Remove duplicate TileImageView from iOS
- [ ] Copy missing Java files (DownloadInfoMap)
- [ ] Copy missing Swift files (Puzzles, PieceState, PieceView)
- [ ] Create PuzzleViewFactory.java
- [ ] Create PuzzlePlatformView.java
- [ ] Create PuzzleViewFactory.swift
- [ ] Create PuzzlePlatformView.swift
- [ ] Create PieceView.swift
- [ ] Create Dart bridge layer (4 files)
- [ ] Add dependency on flutter_comics in build files
- [ ] Test with example .puzzle files
- [ ] Test piece loading and scroll mapping

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [any conditions or clarifications]
