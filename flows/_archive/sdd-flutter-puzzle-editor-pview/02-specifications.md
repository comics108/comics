# Specifications: Flutter Puzzle Editor Plugin Refactoring

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-19
> Requirements: [01-requirements.md](./01-requirements.md)

## Overview

Refactor the `flutter_puzzle_editor` plugin to establish a clear separation between:
- Core editor functionality (in `lib/`) - the editor canvas/widget that integrates with C# native handler
- UI demo controls (in `example/`) - parameter panels, image selection, toolbars, etc.

Currently, the plugin contains only template FFI boilerplate. This refactoring will establish the proper file structure and organization pattern for future puzzle editor implementation.

**Note:** The puzzle editor shares the same C# native handler (Comics.Editor) with the comics editor but uses puzzle-specific functionality.

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `lib/editor.dart` | Modify | Will become the main puzzle editor widget export |
| `lib/editor_bindings_generated.dart` | Modify | Will contain FFI bindings to C# handler |
| `lib/src/` | Create | New directory for internal plugin implementation |
| `example/lib/main.dart` | Modify | Will contain full UI demo with controls |
| `example/lib/widgets/` | Create | UI controls for puzzle editor parameters |
| `src/editor.h` | Modify | C FFI header connecting to C# |
| `src/editor.c` | Modify | C FFI implementation for puzzle operations |
| `pubspec.yaml` | Modify | Update package name to `flutter_puzzle_editor` |

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
│  │  │  - PuzzleEditorScreen             │ │ │
│  │  │  - ToolbarWidget                  │ │ │
│  │  │  - PuzzlePiecePanelWidget        │ │ │
│  │  │  - ImageSelectorWidget           │ │ │
│  │  └──────────────────────────────────┘ │ │
│  │            │                           │ │
│  │            ▼                           │ │
│  │  ┌──────────────────────────────────┐ │ │
│  │  │  lib/editor.dart (public API)    │ │ │
│  │  │  - PuzzleEditorWidget            │ │ │
│  │  │  - PuzzleController              │ │ │
│  │  └──────────────────────────────────┘ │ │
│  │            │                           │ │
│  │            ▼                           │ │
│  │  ┌──────────────────────────────────┐ │ │
│  │  │  lib/src/ (internal)             │ │ │
│  │  │  - puzzle_widget_impl.dart       │ │ │
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
│  │  - FFI exported puzzle functions       │ │
│  └────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│  C# Native Handler (Comics.Editor)          │
│  │  - Shared with comics editor             │
│  ┌────────────────────────────────────────┐ │
│  │  WPF Editor Application                │ │
│  │  - ViewModels (PuzzleViewModel, etc.)  │ │
│  │  - Models (PuzzlePiece, etc.)          │ │
│  │  - Controls (PuzzleControl.xaml)       │ │
│  └────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### Data Flow

```
User Interaction (example app)
    ↓
UI Controls (PuzzlePiecePanel, ImageSelector, etc.)
    ↓
PuzzleEditorWidget.addPiece(pieceData)
    ↓
PuzzleController (validates, marshals data)
    ↓
FFI Bridge (ffi_bridge.dart)
    ↓
C FFI Layer (src/editor.c - puzzle functions)
    ↓
C# Handler (Comics.Editor PuzzleViewModel)
    ↓
Puzzle State Update
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
│   ├── puzzle_widget.dart          # Core PuzzleEditorWidget
│   ├── puzzle_controller.dart      # State management & API
│   ├── ffi_bridge.dart             # FFI call wrappers
│   ├── models/
│   │   ├── puzzle_piece.dart       # Puzzle piece data model
│   │   ├── puzzle_grid.dart        # Grid configuration
│   │   └── puzzle_settings.dart    # Puzzle settings model
│   └── constants.dart              # Plugin constants
└── editor_bindings_generated.dart  # Auto-generated FFI bindings
```

### example/lib/ (UI Demo)

```
example/lib/
├── main.dart                        # App entry point
├── screens/
│   └── puzzle_editor_screen.dart   # Main puzzle editor screen layout
├── widgets/
│   ├── toolbar/
│   │   ├── toolbar_widget.dart     # Top toolbar
│   │   └── tool_button.dart        # Tool buttons
│   ├── panels/
│   │   ├── pieces_panel.dart       # Puzzle pieces list
│   │   ├── grid_settings_panel.dart # Grid configuration
│   │   ├── properties_panel.dart   # Selected piece properties
│   │   └── preview_panel.dart      # Puzzle preview
│   ├── selectors/
│   │   ├── image_selector.dart     # Image file picker
│   │   └── difficulty_selector.dart # Difficulty level
│   └── canvas/
│       └── puzzle_canvas_wrapper.dart  # Wraps PuzzleEditorWidget
└── utils/
    └── file_helpers.dart            # File I/O utilities
```

## Interfaces

### Public API (lib/editor.dart)

```dart
// lib/editor.dart

/// Main export file for the puzzle editor plugin
library flutter_puzzle_editor;

export 'src/puzzle_widget.dart';
export 'src/puzzle_controller.dart';
export 'src/models/puzzle_piece.dart';
export 'src/models/puzzle_grid.dart';
export 'src/models/puzzle_settings.dart';
```

### Core Widget Interface

```dart
// lib/src/puzzle_widget.dart

/// The main puzzle editor widget that renders the editing canvas
class PuzzleEditorWidget extends StatefulWidget {
  /// Controller for managing puzzle editor state
  final PuzzleController controller;

  /// Canvas size
  final Size canvasSize;

  /// Grid configuration
  final PuzzleGrid grid;

  /// Callback when editor is ready
  final VoidCallback? onReady;

  /// Callback when error occurs
  final Function(String error)? onError;

  const PuzzleEditorWidget({
    Key? key,
    required this.controller,
    required this.grid,
    this.canvasSize = const Size(800, 600),
    this.onReady,
    this.onError,
  }) : super(key: key);
}
```

### Controller Interface

```dart
// lib/src/puzzle_controller.dart

/// Controller for managing puzzle editor state and operations
class PuzzleController extends ChangeNotifier {
  /// Set puzzle grid configuration
  Future<void> setGrid(PuzzleGrid grid);

  /// Add a new puzzle piece
  Future<void> addPiece(PuzzlePiece piece);

  /// Update existing puzzle piece
  Future<void> updatePiece(String pieceId, PuzzlePiece piece);

  /// Remove puzzle piece
  Future<void> removePiece(String pieceId);

  /// Load puzzle data
  Future<void> loadPuzzle(String puzzlePath);

  /// Save puzzle data
  Future<void> savePuzzle(String puzzlePath);

  /// Generate puzzle from image
  Future<void> generateFromImage(String imagePath, int rows, int cols);

  /// Current puzzle pieces
  List<PuzzlePiece> get pieces;

  /// Current grid configuration
  PuzzleGrid? get grid;

  /// Selected piece ID
  String? get selectedPieceId;
}
```

### FFI Bridge Interface

```dart
// lib/src/ffi_bridge.dart

/// FFI bridge to C# native puzzle editor
class PuzzleFFIBridge {
  /// Initialize the native puzzle editor
  static Future<void> initialize();

  /// Create a new puzzle editor instance
  static int createPuzzleEditor(int width, int height);

  /// Destroy puzzle editor instance
  static void destroyPuzzleEditor(int editorHandle);

  /// Set grid configuration
  static void setGridNative(int editorHandle, int rows, int cols);

  /// Add piece to puzzle
  static void addPieceNative(int editorHandle, PuzzlePieceData data);

  /// Update piece in puzzle
  static void updatePieceNative(int editorHandle, String pieceId, PuzzlePieceData data);

  /// Generate puzzle from image
  static void generatePuzzleNative(int editorHandle, String imagePath, int rows, int cols);

  // ... more FFI methods
}
```

## Data Models

### PuzzlePiece Model

```dart
// lib/src/models/puzzle_piece.dart

/// Represents a piece in the puzzle
class PuzzlePiece {
  final String id;
  final String name;
  final String imagePath;
  final int row;
  final int col;
  final Offset position;
  final Size size;
  final double rotation;
  final bool isLocked;
  final PieceShape shape;

  PuzzlePiece({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.row,
    required this.col,
    this.position = Offset.zero,
    required this.size,
    this.rotation = 0.0,
    this.isLocked = false,
    this.shape = PieceShape.rectangle,
  });

  /// Convert to native data structure
  Map<String, dynamic> toNative();

  /// Create from native data
  factory PuzzlePiece.fromNative(Map<String, dynamic> data);
}

enum PieceShape {
  rectangle,
  jigsaw,
  hexagon,
}
```

### PuzzleGrid Model

```dart
// lib/src/models/puzzle_grid.dart

/// Represents the grid configuration for a puzzle
class PuzzleGrid {
  final int rows;
  final int columns;
  final double pieceWidth;
  final double pieceHeight;
  final double spacing;

  const PuzzleGrid({
    required this.rows,
    required this.columns,
    required this.pieceWidth,
    required this.pieceHeight,
    this.spacing = 2.0,
  });

  int get totalPieces => rows * columns;
}
```

### PuzzleSettings Model

```dart
// lib/src/models/puzzle_settings.dart

/// Overall puzzle configuration
class PuzzleSettings {
  final String id;
  final String title;
  final String sourceImage;
  final PuzzleGrid grid;
  final DifficultyLevel difficulty;

  PuzzleSettings({
    required this.id,
    required this.title,
    required this.sourceImage,
    required this.grid,
    this.difficulty = DifficultyLevel.medium,
  });
}

enum DifficultyLevel {
  easy,   // 3x3 or 4x4
  medium, // 6x6 or 8x8
  hard,   // 12x12 or more
}
```

## Behavior Specifications

### Happy Path: Creating a Puzzle from Image

1. User clicks "Create Puzzle" button in UI (example app)
2. `ImageSelector` widget opens, user selects source image
3. User sets grid size (e.g., 4x4) in `GridSettingsPanel`
4. Example app creates `PuzzleGrid` object
5. Example app calls `controller.generateFromImage(imagePath, 4, 4)`
6. Controller validates parameters
7. Controller calls `PuzzleFFIBridge.generatePuzzleNative()`
8. FFI bridge marshals data to C format
9. C layer calls C# handler's puzzle generation method
10. C# handler slices image into pieces, creates puzzle pieces
11. C# handler returns piece data array
12. Controller creates `PuzzlePiece` objects
13. Controller notifies listeners
14. `PuzzleEditorWidget` rebuilds with puzzle pieces
15. UI updates to show pieces in pieces panel

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| Invalid image path | User selects non-existent file | Controller validates, shows error dialog |
| Grid too large | User requests 100x100 grid | Show warning, limit to max (e.g., 20x20) |
| Native handler crash | C# exception during generation | FFI catches, returns error code, Flutter shows graceful error |
| Very large image | Image > 20MB selected | Show loading indicator, async processing |
| Non-divisible dimensions | Image size not evenly divisible by grid | Resize or crop image automatically |

### Error Handling

| Error | Cause | Response |
|-------|-------|----------|
| FFI initialization failure | Native library not found | Show error dialog, disable editor |
| Invalid grid configuration | Rows or columns = 0 or negative | Validation error, highlight fields |
| Native exception | C# runtime error during puzzle generation | Log error, show user-friendly message, maintain state |
| Save failed | File write permission denied | Show error dialog with suggestion to change location |
| Image decode failure | Corrupted or unsupported image format | Show error with supported formats list |

## Dependencies

### Requires

- `dart:ffi` - FFI support
- `ffi` package - FFI helpers
- `flutter` SDK - UI framework
- Native C library build (CMake)
- C# Comics.Editor compiled binary (shared with comics editor)

### Provides

- `flutter_puzzle_editor` package for use in other Flutter apps

## Integration Points

### External Systems

- File system (for loading/saving puzzles, images)
- C# Comics.Editor via FFI (shared handler with comics editor)
- Platform-specific native build systems (CMake, Visual Studio, Xcode)

### Internal Systems

- `lib/` provides public API
- `example/` consumes public API
- FFI bindings connect to native layer
- Shares C# native handler with `flutter_comics_editor`

## Package Configuration

### pubspec.yaml Changes

```yaml
name: flutter_puzzle_editor  # Changed from "editor"
description: "Flutter plugin for puzzle editing with C# native integration"
version: 0.1.0

environment:
  sdk: ^3.12.2
  flutter: '>=3.3.0'

dependencies:
  flutter:
    sdk: flutter
  ffi: ^2.1.3
  path_provider: ^2.0.0  # For file paths
  image: ^4.0.0  # For image processing

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

### src/editor.h Structure (Puzzle Functions)

```c
#ifndef PUZZLE_EDITOR_H
#define PUZZLE_EDITOR_H

#include <stdint.h>

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

// Puzzle editor instance handle
typedef int32_t PuzzleEditorHandle;

// Puzzle piece data structure
typedef struct {
  const char* id;
  const char* name;
  const char* image_path;
  int32_t row;
  int32_t col;
  double x;
  double y;
  double width;
  double height;
  double rotation;
  int32_t is_locked;
  int32_t shape;  // 0=rectangle, 1=jigsaw, 2=hexagon
} PuzzlePieceData;

// Initialize puzzle editor system
FFI_PLUGIN_EXPORT int32_t puzzle_editor_initialize();

// Create puzzle editor instance
FFI_PLUGIN_EXPORT PuzzleEditorHandle puzzle_editor_create(int32_t width, int32_t height);

// Destroy puzzle editor instance
FFI_PLUGIN_EXPORT void puzzle_editor_destroy(PuzzleEditorHandle handle);

// Set grid configuration
FFI_PLUGIN_EXPORT int32_t puzzle_set_grid(PuzzleEditorHandle handle, int32_t rows, int32_t cols);

// Add puzzle piece
FFI_PLUGIN_EXPORT int32_t puzzle_add_piece(PuzzleEditorHandle handle, const PuzzlePieceData* piece);

// Update puzzle piece
FFI_PLUGIN_EXPORT int32_t puzzle_update_piece(PuzzleEditorHandle handle, const char* piece_id, const PuzzlePieceData* piece);

// Remove puzzle piece
FFI_PLUGIN_EXPORT int32_t puzzle_remove_piece(PuzzleEditorHandle handle, const char* piece_id);

// Generate puzzle from image
FFI_PLUGIN_EXPORT int32_t puzzle_generate_from_image(PuzzleEditorHandle handle, const char* image_path, int32_t rows, int32_t cols);

// ... more functions

#endif // PUZZLE_EDITOR_H
```

## Testing Strategy

### Unit Tests

- [ ] `PuzzlePiece.toNative()` / `PuzzlePiece.fromNative()` conversion
- [ ] `PuzzleController` piece management logic
- [ ] Grid calculation logic
- [ ] Data validation in controller methods
- [ ] FFI bridge data marshaling

### Integration Tests

- [ ] Create puzzle editor widget → verify FFI initialization
- [ ] Generate puzzle from image → verify pieces created
- [ ] Add/remove pieces → verify native call and state update
- [ ] Load puzzle → verify all pieces loaded correctly
- [ ] Save puzzle → verify file written correctly

### Manual Verification

- [ ] Run example app on Windows
- [ ] Select source image
- [ ] Generate 4x4 puzzle
- [ ] Modify piece properties
- [ ] Verify canvas updates
- [ ] Save and reload puzzle
- [ ] Check C# puzzle editor state (if debugger attached)

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
- Implement actual C FFI layer for puzzle operations
- Connect to C# Comics.Editor PuzzleViewModel
- Implement full puzzle generation functionality

## Open Design Questions

- [ ] Should we use method channels in addition to FFI for some operations?
- [ ] How to handle platform differences (Windows vs macOS vs Linux)?
- [ ] Should the puzzle editor widget be a PlatformView embedding native control?
- [ ] How to handle C# exceptions and propagate to Dart?
- [ ] Should we support hot reload during puzzle editing?
- [ ] Should puzzle piece shapes be rendered in Flutter or C#?

---

## Approval

- [ ] Reviewed by: Anton
- [ ] Approved on: [pending]
- [ ] Notes: [awaiting review]
