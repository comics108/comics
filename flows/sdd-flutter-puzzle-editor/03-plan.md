# Implementation Plan: Flutter Puzzle Editor (PlatformView)

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-19
> Specifications: [02-specifications.md](./02-specifications.md)
> File Operations: [FILE_OPERATIONS_PLATFORMVIEW.md](./FILE_OPERATIONS_PLATFORMVIEW.md)

## Summary

Implement Flutter Puzzle Editor using **PlatformView approach** to embed existing WPF puzzle control. Similar to Comics Editor but simpler - puzzle generation logic already exists in C# PuzzleViewModel.

**Key Decisions:**
- ✅ Use PlatformView to embed WPF PuzzleControl
- ✅ .NET 9 with C# 12
- ✅ Reuse/extend Comics.Editor.Flutter project (shared infrastructure)
- ✅ Windows-only
- ✅ Zero C# business logic rewrite

**Timeline:** 4 working days

---

## Task Breakdown

### Phase 1: Project Setup (Day 1, Morning)

#### Task 1.1: Extend C# Flutter Integration Project

**Description:** Add puzzle-specific classes to existing Comics.Editor.Flutter project

**Files:**
- `native/Comics.Editor.Flutter/PuzzleEditorPlatformView.cs` - **CREATE**
- `native/Comics.Editor.Flutter/PuzzleMethodChannelHandler.cs` - **CREATE**

**Note:** Reuse existing project from Comics Editor implementation

**Dependencies:** Comics Editor Phase 1 complete
**Verification:** `dotnet build` succeeds with new classes
**Complexity:** Low

---

#### Task 1.2: Setup Flutter Plugin Structure

**Description:** Create puzzle_editor plugin structure (parallel to comics_editor)

**Files:**
- `pubspec.yaml` - **MODIFY** (name: flutter_puzzle_editor)
- `lib/editor.dart` - **MODIFY**
- `lib/src/puzzle_editor_widget.dart` - **CREATE**
- `lib/src/puzzle_controller.dart` - **CREATE**

**Dependencies:** None
**Verification:** `flutter pub get` succeeds
**Complexity:** Low

---

### Phase 2: C# PlatformView Implementation (Day 1, Afternoon)

#### Task 2.1: Implement PuzzleEditorPlatformView

**Description:** Create PlatformView wrapper around WPF PuzzleControl

**Files:**
- `native/Comics.Editor.Flutter/PuzzleEditorPlatformView.cs` - **CREATE** (~150 lines)

**Implementation:**
```csharp
namespace Comics.Editor.Flutter;

public class PuzzleEditorViewFactory(FlutterEngine engine)
    : PlatformViewFactory(StandardMessageCodec.Instance)
{
    private readonly FlutterEngine _engine = engine;

    public override PlatformView Create(int viewId, object? args)
    {
        return new PuzzleEditorPlatformView(viewId, _engine);
    }
}

public class PuzzleEditorPlatformView(
    int viewId,
    FlutterEngine engine) : PlatformView, IDisposable
{
    private readonly UserControl _control = new PuzzleControl(); // ✅ Existing!
    private readonly PuzzleViewModel _viewModel = new(); // ✅ Existing!
    private readonly PuzzleMethodChannelHandler _methodHandler;

    public PuzzleEditorPlatformView()
    {
        _control.DataContext = _viewModel;

        var channelName = $"puzzle_editor_{viewId}";
        _methodHandler = new PuzzleMethodChannelHandler(
            engine.BinaryMessenger,
            channelName,
            _viewModel
        );
    }

    public override UIElement GetView() => _control;

    public void Dispose()
    {
        _methodHandler?.Dispose();
        _viewModel?.Dispose();
        GC.SuppressFinalize(this);
    }
}
```

**Dependencies:** Task 1.1
**Verification:** Compiles without errors
**Complexity:** Low (copy from ComicsEditor)

---

#### Task 2.2: Implement Puzzle Method Channel Handler

**Description:** Handle puzzle-specific Method Channel calls

**Files:**
- `native/Comics.Editor.Flutter/PuzzleMethodChannelHandler.cs` - **CREATE** (~250 lines)

**Key Methods:**
- `GenerateFromImage(imagePath, rows, cols)` → calls `_viewModel.GeneratePuzzle()`
- `SetGrid(rows, cols)` → sets `_viewModel.Rows/Cols`
- `GetPieces()` → returns JSON array of puzzle pieces
- `SavePuzzle(path)` → calls `_viewModel.Save(path)`
- `LoadPuzzle(path)` → calls `_viewModel.Load(path)`

**Dependencies:** Task 2.1
**Verification:** Compiles, logic matches PuzzleViewModel
**Complexity:** Low

---

### Phase 3: Windows Integration (Day 2, Morning)

#### Task 3.1: Register Puzzle PlatformView in Windows Plugin

**Description:** Extend C++ plugin to register PuzzleEditorView factory

**Files:**
- `windows/editor_plugin.cpp` - **MODIFY** (add puzzle factory registration)

**Changes:**
```cpp
void EditorPluginRegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {

  // Comics editor view (already done)
  RegisterComicsEditorView(registrar);

  // Puzzle editor view (new)
  auto puzzle_factory = std::make_unique<PuzzleEditorViewFactoryWrapper>(
      registrar->messenger()
  );

  registrar->RegisterViewFactory(
      "puzzle_editor_view",
      std::move(puzzle_factory)
  );
}
```

**Dependencies:** Task 2.2, Comics Editor Phase 3
**Verification:** Both views registered, Flutter build succeeds
**Complexity:** Low

---

### Phase 4: Dart Implementation (Day 2, Afternoon)

#### Task 4.1: Implement PuzzleEditorWidget

**Description:** Create PlatformView widget for puzzle editor

**Files:**
- `lib/src/puzzle_editor_widget.dart` - **CREATE** (~120 lines)

**Key Code:**
```dart
class PuzzleEditorWidget extends StatefulWidget {
  final PuzzleController controller;

  const PuzzleEditorWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: 'puzzle_editor_view',
      // Similar to ComicsEditorWidget
    );
  }
}
```

**Dependencies:** Task 3.1
**Verification:** Widget renders without errors
**Complexity:** Low (copy from ComicsEditor)

---

#### Task 4.2: Implement PuzzleController

**Description:** Controller for puzzle-specific operations

**Files:**
- `lib/src/puzzle_controller.dart` - **CREATE** (~150 lines)

**Key Methods:**
```dart
class PuzzleController {
  Future<void> generateFromImage(String imagePath, int rows, int cols);
  Future<void> setGrid(int rows, int cols);
  Future<List<Map<String, dynamic>>> getPieces();
  Future<void> savePuzzle(String path);
  Future<void> loadPuzzle(String path);
}
```

**Dependencies:** Task 4.1
**Verification:** Methods callable
**Complexity:** Low

---

### Phase 5: Example UI (Day 3)

#### Task 5.1: Create Puzzle Editor Screen

**Description:** Main screen layout for puzzle editor

**Files:**
- `example/lib/screens/puzzle_editor_screen.dart` - **CREATE** (~150 lines)

**Layout:**
```
┌─────────────────────────────────────┐
│ Toolbar (New, Generate, Save)       │
├──────────┬─────────────────┬────────┤
│ Grid     │ WPF Canvas      │ Pieces │
│ Settings │ (PlatformView)  │ List   │
│ (Flutter)│                 │(Flutter)│
└──────────┴─────────────────┴────────┘
```

**Dependencies:** Task 4.2
**Verification:** Layout renders
**Complexity:** Low

---

#### Task 5.2: Implement Grid Settings Panel

**Description:** Left panel for grid configuration

**Files:**
- `example/lib/widgets/panels/grid_settings_panel.dart` - **CREATE** (~100 lines)

**Controls:**
- Rows slider (2-20)
- Columns slider (2-20)
- Apply button → calls `controller.setGrid()`

**Dependencies:** Task 5.1
**Verification:** Grid changes reflected in WPF
**Complexity:** Low

---

#### Task 5.3: Implement Pieces Panel

**Description:** Right panel showing generated puzzle pieces

**Files:**
- `example/lib/widgets/panels/pieces_panel.dart` - **CREATE** (~80 lines)

**Features:**
- Fetch pieces via `controller.getPieces()`
- Display as GridView
- Show piece position (row, col)

**Dependencies:** Task 5.1
**Verification:** Shows pieces after generation
**Complexity:** Low

---

#### Task 5.4: Implement Generate Dialog

**Description:** Dialog for generating puzzle from image

**Files:**
- `example/lib/widgets/dialogs/generate_puzzle_dialog.dart` - **CREATE** (~120 lines)

**Flow:**
1. User clicks "Generate Puzzle"
2. Dialog opens
3. Select image file
4. Choose grid size (or difficulty preset)
5. Call `controller.generateFromImage()`

**Dependencies:** Task 5.2
**Verification:** Generated puzzle appears in canvas
**Complexity:** Medium

---

### Phase 6: Integration & Testing (Day 4, Morning)

#### Task 6.1: End-to-End Test

**Description:** Test full puzzle workflow

**Test Steps:**
1. Launch app
2. Generate puzzle from image (4x4)
3. Verify pieces appear in panel
4. Modify grid settings
5. Save puzzle
6. Reload and verify

**Dependencies:** All Phase 5 tasks
**Verification:** Complete workflow works
**Complexity:** Low

---

#### Task 6.2: Error Handling

**Description:** Handle edge cases

**Scenarios:**
- Invalid image file
- Grid too large (>20x20)
- Save/load failures

**Files:**
- All Dart files - **MODIFY** (add error handling)

**Dependencies:** Task 6.1
**Verification:** Graceful error messages
**Complexity:** Low

---

### Phase 7: Documentation (Day 4, Afternoon)

#### Task 7.1: Update README

**Description:** Document puzzle editor usage

**Files:**
- `README.md` - **MODIFY**

**Sections:**
- Quick start
- Generating puzzles
- API reference
- Limitations

**Dependencies:** Task 6.2
**Verification:** README complete
**Complexity:** Low

---

#### Task 7.2: Polish Example App

**Description:** Make demo app presentation-ready

**Files:**
- `example/lib/main.dart` - **MODIFY**

**Features:**
- Welcome screen
- Sample images included
- Quick generate button

**Dependencies:** Task 7.1
**Verification:** Demo-ready
**Complexity:** Low

---

## Dependency Graph

```
Day 1: Setup & C#
┌────────┐   ┌────────┐
│ 1.1    │──▶│ 1.2    │
│ C#     │   │ Flutter│
│ Extend │   │ Setup  │
└────────┘   └────────┘
     │           │
     ▼           ▼
┌────────┐   ┌────────┐
│ 2.1    │──▶│ 2.2    │
│Platform│   │ Method │
│View    │   │Handler │
└────────┘   └────────┘
     │
     ▼
Day 2: Integration & Dart
┌────────┐
│ 3.1    │
│Register│
│View    │
└────────┘
     │
     ▼
┌────────┐   ┌────────┐
│ 4.1    │──▶│ 4.2    │
│Widget  │   │Control │
│        │   │-ler    │
└────────┘   └────────┘
     │
     ▼
Day 3: UI
┌────────┬────────┬────────┬────────┐
│ 5.1    │ 5.2    │ 5.3    │ 5.4    │
│ Screen │ Grid   │ Pieces │Generate│
│        │Settings│ Panel  │ Dialog │
└────────┴────────┴────────┴────────┘
     │
     ▼
Day 4: Testing & Polish
┌────────┐   ┌────────┐   ┌────────┬────────┐
│ 6.1    │──▶│ 6.2    │──▶│ 7.1    │ 7.2    │
│E2E Test│   │ Errors │   │ README │ Polish │
└────────┘   └────────┘   └────────┴────────┘
```

---

## File Change Summary

| File | Action | Lines | Complexity |
|------|--------|-------|------------|
| `native/Comics.Editor.Flutter/PuzzleEditorPlatformView.cs` | Create | ~150 | Low |
| `native/Comics.Editor.Flutter/PuzzleMethodChannelHandler.cs` | Create | ~250 | Low |
| `windows/editor_plugin.cpp` | Modify | +20 | Low |
| `lib/src/puzzle_editor_widget.dart` | Create | ~120 | Low |
| `lib/src/puzzle_controller.dart` | Create | ~150 | Low |
| `example/lib/screens/puzzle_editor_screen.dart` | Create | ~150 | Low |
| `example/lib/widgets/panels/grid_settings_panel.dart` | Create | ~100 | Low |
| `example/lib/widgets/panels/pieces_panel.dart` | Create | ~80 | Low |
| `example/lib/widgets/dialogs/generate_puzzle_dialog.dart` | Create | ~120 | Medium |

**Total:**
- Create: 9 files (~1,120 lines)
- Modify: 2 files

**Much simpler than Comics Editor!**

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| PuzzleViewModel missing generation logic | Low | High | Verify existing C# code has GeneratePuzzle() |
| Shared C# project conflicts with Comics | Low | Medium | Separate namespaces, test both plugins |
| Image processing slow in C# | Medium | Low | Show loading indicator |

---

## Checkpoints

### After Day 1:
- [ ] PuzzleEditorPlatformView compiles
- [ ] Method handlers implemented
- [ ] Dart widgets created

### After Day 2:
- [ ] PlatformView registered
- [ ] Can create PuzzleEditorWidget
- [ ] Method channels connect

### After Day 3:
- [ ] Can generate puzzle from image
- [ ] UI fully functional
- [ ] Grid settings work

### After Day 4:
- [ ] E2E test passes
- [ ] Error handling complete
- [ ] Documentation done

---

## Success Criteria

1. **Can generate puzzle from image** (core feature)
2. **Can modify grid settings**
3. **Can save/load puzzles**
4. **No crashes or errors**
5. **Documentation complete**

---

## Approval

- [ ] Reviewed by: Anton
- [ ] Approved on: [pending]
- [ ] Notes: Simpler than Comics Editor, should be quick to implement

---

**Estimated: 4 days (vs 9 for Comics)**

Puzzle Editor is simpler because:
- Fewer UI panels
- No timeline/animations
- Simpler data model
- Reuses Comics infrastructure
