# Specifications: Flutter Comics Editor Plugin Refactoring

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-19
> Requirements: [01-requirements.md](./01-requirements.md)

## Overview

Refactor the `flutter_comics_editor` plugin to establish a clear separation between:
- Core editor functionality (in `lib/`) - the editor canvas/widget that integrates with C# native handler
- UI demo controls (in `example/`) - parameter panels, image selection, toolbars, etc.

Currently, the plugin contains only template FFI boilerplate. This refactoring will establish the proper file structure and organization pattern for future editor implementation.

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `lib/editor.dart` | Modify | Will become the main editor widget export |
| `lib/editor_bindings_generated.dart` | Modify | Will contain FFI bindings to C# handler |
| `lib/src/` | Create | New directory for internal plugin implementation |
| `example/lib/main.dart` | Modify | Will contain full UI demo with controls |
| `example/lib/widgets/` | Create | UI controls for editor parameters |
| `src/editor.h` | Modify | C FFI header connecting to C# |
| `src/editor.c` | Modify | C FFI implementation |
| `pubspec.yaml` | Modify | Update package name to `flutter_comics_editor` |

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────────┐
│         Flutter Application                  │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  example/lib/                          │ │
│  │  ┌──────────────────────────────────┐ │ │
│  │  │  main.dart                        │ │ │
│  │  │  - EditorScreen                   │ │ │
│  │  │  - ToolbarWidget                  │ │ │
│  │  │  - ParameterPanelWidget          │ │ │
│  │  │  - ImageSelectorWidget           │ │ │
│  │  └──────────────────────────────────┘ │ │
│  │            │                           │ │
│  │            ▼                           │ │
│  │  ┌──────────────────────────────────┐ │ │
│  │  │  lib/editor.dart (public API)    │ │ │
│  │  │  - ComicsEditorWidget            │ │ │
│  │  │  - EditorController              │ │ │
│  │  └──────────────────────────────────┘ │ │
│  │            │                           │ │
│  │            ▼                           │ │
│  │  ┌──────────────────────────────────┐ │ │
│  │  │  lib/src/ (internal)             │ │ │
│  │  │  - editor_widget_impl.dart       │ │ │
│  │  │  - ffi_bridge.dart               │ │ │
│  │  └──────────────────────────────────┘ │ │
│  └────────────────────────────────────────┘ │
│                 │                            │
│                 ▼                            │
│  ┌────────────────────────────────────────┐ │
│  │  dart:ffi                               │ │
│  └────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│  Native Layer (C FFI Bridge)                │
│  ┌────────────────────────────────────────┐ │
│  │  src/editor.c / editor.h               │ │
│  │  - FFI exported functions              │ │
│  └────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│  C# Native Handler (Comics.Editor)          │
│  ┌────────────────────────────────────────┐ │
│  │  WPF Editor Application                │ │
│  │  - ViewModels (ComicsViewModel, etc.)  │ │
│  │  - Models (Layer, Episode, etc.)       │ │
│  │  - Controls (XAML UI - for reference)  │ │
│  └────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### Data Flow

```
User Interaction (example app)
    ↓
UI Controls (ParameterPanel, ImageSelector, etc.)
    ↓
ComicsEditorWidget.updateLayer(layerData)
    ↓
EditorController (validates, marshals data)
    ↓
FFI Bridge (ffi_bridge.dart)
    ↓
C FFI Layer (src/editor.c)
    ↓
C# Handler (Comics.Editor ViewModels)
    ↓
Editor State Update
    ↓
Callback/Event to Flutter
    ↓
Widget State Update
    ↓
UI Refresh
```

## File Structure Specification

### lib/ (Plugin Core)

```
lib/
├── editor.dart                      # Public API export
├── src/                             # Internal implementation
│   ├── editor_widget.dart          # Core ComicsEditorWidget
│   ├── editor_controller.dart      # State management & API
│   ├── ffi_bridge.dart             # FFI call wrappers
│   ├── models/
│   │   ├── layer.dart              # Layer data model
│   │   ├── episode.dart            # Episode data model
│   │   └── animation.dart          # Animation data model
│   └── constants.dart              # Plugin constants
└── editor_bindings_generated.dart  # Auto-generated FFI bindings
```

### example/lib/ (UI Demo)

```
example/lib/
├── main.dart                        # App entry point
├── screens/
│   └── editor_screen.dart          # Main editor screen layout
├── widgets/
│   ├── toolbar/
│   │   ├── toolbar_widget.dart     # Top toolbar
│   │   └── tool_button.dart        # Tool buttons
│   ├── panels/
│   │   ├── parameter_panel.dart    # Layer parameters
│   │   ├── layers_panel.dart       # Layers list
│   │   ├── timeline_panel.dart     # Animation timeline
│   │   └── properties_panel.dart   # Selected item properties
│   ├── selectors/
│   │   ├── image_selector.dart     # Image file picker
│   │   ├── sound_selector.dart     # Sound file picker
│   │   └── color_picker.dart       # Color selection
│   └── canvas/
│       └── editor_canvas_wrapper.dart  # Wraps ComicsEditorWidget
└── utils/
    └── file_helpers.dart            # File I/O utilities
```

## Interfaces

### Public API (lib/editor.dart)

```dart
// lib/editor.dart

/// Main export file for the comics editor plugin
library flutter_comics_editor;

export 'src/editor_widget.dart';
export 'src/editor_controller.dart';
export 'src/models/layer.dart';
export 'src/models/episode.dart';
export 'src/models/animation.dart';
```

### Core Widget Interface

```dart
// lib/src/editor_widget.dart

/// The main comics editor widget that renders the editing canvas
class ComicsEditorWidget extends StatefulWidget {
  /// Controller for managing editor state
  final EditorController controller;

  /// Canvas size
  final Size canvasSize;

  /// Callback when editor is ready
  final VoidCallback? onReady;

  /// Callback when error occurs
  final Function(String error)? onError;

  const ComicsEditorWidget({
    Key? key,
    required this.controller,
    this.canvasSize = const Size(800, 600),
    this.onReady,
    this.onError,
  }) : super(key: key);
}
```

### Controller Interface

```dart
// lib/src/editor_controller.dart

/// Controller for managing comics editor state and operations
class EditorController extends ChangeNotifier {
  /// Add a new layer
  Future<void> addLayer(Layer layer);

  /// Update existing layer
  Future<void> updateLayer(String layerId, Layer layer);

  /// Remove layer
  Future<void> removeLayer(String layerId);

  /// Load episode data
  Future<void> loadEpisode(String episodePath);

  /// Save episode data
  Future<void> saveEpisode(String episodePath);

  /// Current layers
  List<Layer> get layers;

  /// Selected layer ID
  String? get selectedLayerId;
}
```

### FFI Bridge Interface

```dart
// lib/src/ffi_bridge.dart

/// FFI bridge to C# native editor
class EditorFFIBridge {
  /// Initialize the native editor
  static Future<void> initialize();

  /// Create a new editor instance
  static int createEditor(int width, int height);

  /// Destroy editor instance
  static void destroyEditor(int editorHandle);

  /// Add layer to editor
  static void addLayerNative(int editorHandle, LayerData data);

  /// Update layer in editor
  static void updateLayerNative(int editorHandle, String layerId, LayerData data);

  // ... more FFI methods
}
```

## Data Models

### Layer Model

```dart
// lib/src/models/layer.dart

/// Represents a layer in the comics editor
class Layer {
  final String id;
  final String name;
  final String imagePath;
  final Offset position;
  final Size size;
  final double rotation;
  final double opacity;
  final List<Animation>? animations;

  Layer({
    required this.id,
    required this.name,
    required this.imagePath,
    this.position = Offset.zero,
    this.size = const Size(100, 100),
    this.rotation = 0.0,
    this.opacity = 1.0,
    this.animations,
  });

  /// Convert to native data structure
  Map<String, dynamic> toNative();

  /// Create from native data
  factory Layer.fromNative(Map<String, dynamic> data);
}
```

### Episode Model

```dart
// lib/src/models/episode.dart

/// Represents a comics episode
class Episode {
  final String id;
  final String title;
  final List<Layer> layers;
  final Map<String, dynamic> metadata;

  Episode({
    required this.id,
    required this.title,
    required this.layers,
    this.metadata = const {},
  });
}
```

## Behavior Specifications

### Happy Path: Adding a Layer

1. User clicks "Add Layer" button in UI (example app)
2. `ImageSelector` widget opens, user selects image
3. Example app creates `Layer` object with selected image path
4. Example app calls `controller.addLayer(layer)`
5. Controller validates layer data
6. Controller calls `EditorFFIBridge.addLayerNative()`
7. FFI bridge marshals data to C format
8. C layer calls C# handler method
9. C# handler adds layer to internal state
10. C# handler returns success
11. Controller notifies listeners
12. `ComicsEditorWidget` rebuilds with new layer
13. UI updates to show layer in layers panel

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| Invalid image path | User selects non-existent file | Controller validates, shows error dialog |
| Duplicate layer ID | Adding layer with existing ID | Auto-generate new unique ID |
| Native handler crash | C# exception during operation | FFI catches, returns error code, Flutter shows graceful error |
| Large image file | Image > 10MB selected | Show loading indicator, async load |

### Error Handling

| Error | Cause | Response |
|-------|-------|----------|
| FFI initialization failure | Native library not found | Show error dialog, disable editor |
| Invalid layer data | Missing required fields | Validation error, highlight fields |
| Native exception | C# runtime error | Log error, show user-friendly message, maintain state |
| Save failed | File write permission denied | Show error dialog with suggestion to change location |

## Dependencies

### Requires

- `dart:ffi` - FFI support
- `ffi` package - FFI helpers
- `flutter` SDK - UI framework
- Native C library build (CMake)
- C# Comics.Editor compiled binary

### Provides

- `flutter_comics_editor` package for use in other Flutter apps

## Integration Points

### External Systems

- File system (for loading/saving episodes, images, sounds)
- C# Comics.Editor via FFI
- Platform-specific native build systems (CMake, Visual Studio, Xcode)

### Internal Systems

- `lib/` provides public API
- `example/` consumes public API
- FFI bindings connect to native layer

## Package Configuration

### pubspec.yaml Changes

```yaml
name: flutter_comics_editor  # Changed from "editor"
description: "Flutter plugin for comics editing with C# native integration"
version: 0.1.0

environment:
  sdk: ^3.12.2
  flutter: '>=3.3.0'

dependencies:
  flutter:
    sdk: flutter
  ffi: ^2.1.3
  path_provider: ^2.0.0  # For file paths

dev_dependencies:
  ffigen: ^20.1.1
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  plugin:
    platforms:
      windows:
        ffiPlugin: true
      macos:
        ffiPlugin: true
      linux:
        ffiPlugin: true
```

## Native Layer Specifications

### src/editor.h Structure

```c
#ifndef COMICS_EDITOR_H
#define COMICS_EDITOR_H

#include <stdint.h>

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

// Editor instance handle
typedef int32_t EditorHandle;

// Layer data structure
typedef struct {
  const char* id;
  const char* name;
  const char* image_path;
  double x;
  double y;
  double width;
  double height;
  double rotation;
  double opacity;
} LayerData;

// Initialize editor system
FFI_PLUGIN_EXPORT int32_t editor_initialize();

// Create editor instance
FFI_PLUGIN_EXPORT EditorHandle editor_create(int32_t width, int32_t height);

// Destroy editor instance
FFI_PLUGIN_EXPORT void editor_destroy(EditorHandle handle);

// Add layer
FFI_PLUGIN_EXPORT int32_t editor_add_layer(EditorHandle handle, const LayerData* layer);

// Update layer
FFI_PLUGIN_EXPORT int32_t editor_update_layer(EditorHandle handle, const char* layer_id, const LayerData* layer);

// Remove layer
FFI_PLUGIN_EXPORT int32_t editor_remove_layer(EditorHandle handle, const char* layer_id);

// ... more functions

#endif // COMICS_EDITOR_H
```

## Testing Strategy

### Unit Tests

- [ ] `Layer.toNative()` / `Layer.fromNative()` conversion
- [ ] `EditorController` layer management logic
- [ ] Data validation in controller methods
- [ ] FFI bridge data marshaling

### Integration Tests

- [ ] Create editor widget → verify FFI initialization
- [ ] Add layer → verify native call and state update
- [ ] Load episode → verify all layers loaded correctly
- [ ] Save episode → verify file written correctly

### Manual Verification

- [ ] Run example app on Windows
- [ ] Add layer with image
- [ ] Modify layer properties
- [ ] Verify canvas updates
- [ ] Save and reload episode
- [ ] Check C# editor state (if debugger attached)

## Migration / Rollout

### Phase 1: File Structure
- Create new directories (`lib/src/`, `example/lib/widgets/`)
- Move existing code to proper locations
- Update imports

### Phase 2: Stub Implementation
- Create widget/controller shells
- Implement basic FFI bridge structure
- No actual C# integration yet

### Phase 3: C# Integration (Future)
- Implement actual C FFI layer
- Connect to C# Comics.Editor
- Implement full functionality

## Open Design Questions

- [ ] Should we use method channels in addition to FFI for some operations?
- [ ] How to handle platform differences (Windows vs macOS vs Linux)?
- [ ] Should the editor widget be a PlatformView embedding native control?
- [ ] How to handle C# exceptions and propagate to Dart?
- [ ] Should we support hot reload during editor usage?

---

## Approval

- [ ] Reviewed by: Anton
- [ ] Approved on: [pending]
- [ ] Notes: [awaiting review]
