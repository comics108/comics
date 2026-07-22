# Implementation Plan: Flutter Comics Editor (PlatformView)

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-19
> Specifications: [02-specifications.md](./02-specifications.md)
> File Operations: [FILE_OPERATIONS_PLATFORMVIEW.md](./FILE_OPERATIONS_PLATFORMVIEW.md)
> Tech Stack: [TECH_STACK.md](./TECH_STACK.md)

## Summary

Implement Flutter Comics Editor using **PlatformView approach** to embed existing WPF editor control. This minimizes code rewriting by using 100% of existing C# code (ViewModels, Models, Controls) and creating only thin Flutter UI layer and Method Channel bridge.

**Key Decisions:**
- ✅ Use PlatformView to embed WPF EditorControl directly
- ✅ .NET 9 with C# 12 modern features
- ✅ Method Channels for Flutter ↔ C# communication
- ✅ Windows-only (fastest to market)
- ✅ Zero C# business logic rewrite

**Timeline:** 9 working days

---

## Task Breakdown

### Phase 1: Project Setup & Infrastructure (Day 1)

#### Task 1.1: Create C# Flutter Integration Project

**Description:** Create new .NET 9 C# class library project for Flutter integration

**Files:**
- `native/Comics.Editor.Flutter/Comics.Editor.Flutter.csproj` - **CREATE**
- `native/Comics.Editor.Flutter/GlobalUsings.cs` - **CREATE**

**Implementation:**
```bash
cd native/
dotnet new classlib -n Comics.Editor.Flutter -f net9.0-windows
cd Comics.Editor.Flutter
dotnet add reference ../Comics.Editor/Comics.Editor.csproj
dotnet add package System.Text.Json
```

**Project file:**
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <ProjectReference Include="../Comics.Editor/Comics.Editor.csproj" />
    <PackageReference Include="System.Text.Json" Version="9.0.*" />
  </ItemGroup>
</Project>
```

**Dependencies:** None
**Verification:** `dotnet build` succeeds
**Complexity:** Low

---

#### Task 1.2: Setup Flutter Plugin Structure

**Description:** Remove FFI layer, update pubspec.yaml for PlatformView approach

**Files:**
- `pubspec.yaml` - **MODIFY** (remove ffi/ffigen, change name)
- `ffigen.yaml` - **DELETE**
- `src/editor.h` - **DELETE**
- `src/editor.c` - **DELETE**
- `src/CMakeLists.txt` - **DELETE**
- `lib/editor_bindings_generated.dart` - **DELETE**

**Changes to pubspec.yaml:**
```yaml
name: flutter_comics_editor
description: Comics editor plugin with WPF integration via PlatformView
version: 0.1.0

environment:
  sdk: ^3.12.2
  flutter: '>=3.3.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  plugin:
    platforms:
      windows:
        pluginClass: EditorPlugin
```

**Dependencies:** None
**Verification:** `flutter pub get` succeeds, no FFI warnings
**Complexity:** Low

---

#### Task 1.3: Create Dart Plugin Structure

**Description:** Create minimal Dart file structure for PlatformView

**Files:**
- `lib/editor.dart` - **MODIFY** (export new widgets)
- `lib/src/comics_editor_widget.dart` - **CREATE**
- `lib/src/editor_controller.dart` - **CREATE**
- `lib/src/method_channel.dart` - **CREATE**

**Dependencies:** Task 1.2
**Verification:** `flutter analyze` passes
**Complexity:** Low

---

### Phase 2: C# PlatformView Implementation (Days 2-3)

#### Task 2.1: Implement ComicsEditorPlatformView

**Description:** Create PlatformView wrapper around existing WPF EditorControl

**Files:**
- `native/Comics.Editor.Flutter/ComicsEditorPlatformView.cs` - **CREATE**

**Implementation:**
```csharp
namespace Comics.Editor.Flutter;

/// <summary>
/// PlatformView factory for registering with Flutter
/// </summary>
public class ComicsEditorViewFactory(FlutterEngine engine) : PlatformViewFactory(StandardMessageCodec.Instance)
{
    private readonly FlutterEngine _engine = engine;

    public override PlatformView Create(int viewId, object? args)
    {
        var creationParams = args as Dictionary<string, object>;
        return new ComicsEditorPlatformView(viewId, creationParams, _engine);
    }
}

/// <summary>
/// PlatformView that hosts WPF EditorControl
/// </summary>
public class ComicsEditorPlatformView(
    int viewId,
    Dictionary<string, object>? creationParams,
    FlutterEngine engine) : PlatformView, IDisposable
{
    private readonly int _viewId = viewId;
    private readonly UserControl _control = new EditorControl(); // ✅ Existing!
    private readonly ComicsViewModel _viewModel = new(); // ✅ Existing!
    private readonly MethodChannelHandler _methodHandler;
    private bool _disposed;

    public ComicsEditorPlatformView()
    {
        // Setup WPF control
        _control.DataContext = _viewModel;

        // Create Method Channel for this view
        var channelName = $"comics_editor_{_viewId}";
        _methodHandler = new MethodChannelHandler(
            engine.BinaryMessenger,
            channelName,
            _viewModel
        );

        // Load initial episode if provided
        if (creationParams?.TryGetValue("episodePath", out var pathObj) == true)
        {
            var path = pathObj as string;
            if (!string.IsNullOrEmpty(path))
            {
                _viewModel.Load(path); // ✅ Existing method!
            }
        }
    }

    public override UIElement GetView() => _control;

    public void Dispose()
    {
        if (_disposed) return;

        _methodHandler?.Dispose();
        _viewModel?.Dispose();

        _disposed = true;
        GC.SuppressFinalize(this);
    }
}
```

**Dependencies:** Task 1.1
**Verification:** Compiles without errors
**Complexity:** Medium

---

#### Task 2.2: Implement Method Channel Handler

**Description:** Create handler for Method Channel calls from Flutter

**Files:**
- `native/Comics.Editor.Flutter/MethodChannelHandler.cs` - **CREATE**

**Implementation:** ~300 lines (see detailed code in FILE_OPERATIONS_PLATFORMVIEW.md)

**Key Methods:**
- `LoadEpisode(path)` → calls `_viewModel.Load(path)`
- `SaveEpisode(path)` → calls `_viewModel.Save(path)`
- `AddLayer(imagePath)` → creates Layer, adds to `_viewModel.Layers`
- `RemoveLayer(layerId)` → removes from `_viewModel.Layers`
- `GetLayers()` → returns JSON array of layers
- `UpdateLayer(layerId, properties)` → updates layer properties
- `Undo()` / `Redo()` → calls ViewModel commands

**Dependencies:** Task 2.1
**Verification:** Compiles, unit tests pass
**Complexity:** Medium

---

#### Task 2.3: Build and Test C# Project

**Description:** Compile C# project and verify it builds correctly

**Commands:**
```bash
cd native/Comics.Editor.Flutter
dotnet build -c Release
dotnet publish -c Release -f net9.0-windows -o ../../build/csharp
```

**Dependencies:** Task 2.1, 2.2
**Verification:** DLL created in build output, no warnings
**Complexity:** Low

---

### Phase 3: Windows C++ Plugin Integration (Day 3)

#### Task 3.1: Update Windows Plugin to Register PlatformView

**Description:** Modify C++ plugin to register PlatformView factory

**Files:**
- `windows/editor_plugin.h` - **MODIFY**
- `windows/editor_plugin.cpp` - **MODIFY**

**Changes to editor_plugin.cpp:**
```cpp
#include "include/editor/editor_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>

namespace editor {

// Load C# assembly and get factory
// This will be implemented via COM or C++/CLI bridge

void EditorPluginRegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {

  // Register PlatformView factory
  auto view_factory = std::make_unique<ComicsEditorViewFactoryWrapper>(
      registrar->messenger()
  );

  registrar->RegisterViewFactory(
      "comics_editor_view",
      std::move(view_factory)
  );
}

}  // namespace editor
```

**Dependencies:** Task 2.3
**Verification:** Compiles with Flutter build
**Complexity:** Medium

---

#### Task 3.2: Configure CMake to Build C# Project

**Description:** Update CMakeLists.txt to build and copy C# DLLs

**Files:**
- `windows/CMakeLists.txt` - **MODIFY**

**Changes:**
```cmake
# Build C# project as part of build
add_custom_target(
  ${PLUGIN_NAME}_csharp ALL
  COMMAND dotnet publish
    ${CMAKE_CURRENT_SOURCE_DIR}/../native/Comics.Editor.Flutter/Comics.Editor.Flutter.csproj
    -c Release
    -f net9.0-windows
    -o ${CMAKE_CURRENT_BINARY_DIR}/csharp
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

# Copy C# DLLs to Flutter output
add_custom_command(
  TARGET ${PLUGIN_NAME} POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_CURRENT_BINARY_DIR}/csharp
    $<TARGET_FILE_DIR:${PLUGIN_NAME}>
)

add_dependencies(${PLUGIN_NAME} ${PLUGIN_NAME}_csharp)
```

**Dependencies:** Task 3.1
**Verification:** `flutter build windows` includes C# DLLs
**Complexity:** Medium

---

### Phase 4: Dart PlatformView Widget (Day 4)

#### Task 4.1: Implement ComicsEditorWidget

**Description:** Create Flutter widget that hosts PlatformView

**Files:**
- `lib/src/comics_editor_widget.dart` - **CREATE** (~150 lines)

**Key Code:**
```dart
class ComicsEditorWidget extends StatefulWidget {
  final EditorController controller;
  final String? initialEpisodePath;

  const ComicsEditorWidget({
    Key? key,
    required this.controller,
    this.initialEpisodePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildWindowsView();
    }
    return Center(child: Text('Comics Editor supports Windows only'));
  }

  Widget _buildWindowsView() {
    return PlatformViewLink(
      viewType: 'comics_editor_view',
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: _createPlatformView,
    );
  }

  PlatformViewController _createPlatformView(PlatformViewCreationParams params) {
    return PlatformViewsService.initExpensiveAndroidView(
      id: params.id,
      viewType: 'comics_editor_view',
      layoutDirection: TextDirection.ltr,
      creationParams: {
        'episodePath': widget.initialEpisodePath,
      },
      creationParamsCodec: const StandardMessageCodec(),
    )
      ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
      ..addOnPlatformViewCreatedListener(widget.controller._connect)
      ..create();
  }
}
```

**Dependencies:** Task 1.3
**Verification:** Widget renders, no errors in console
**Complexity:** Medium

---

#### Task 4.2: Implement EditorController

**Description:** Create controller for Method Channel communication

**Files:**
- `lib/src/editor_controller.dart` - **CREATE** (~250 lines)

**Key Methods:**
```dart
class EditorController {
  MethodChannel? _channel;
  int? _viewId;

  void _connect(int viewId) {
    _viewId = viewId;
    _channel = MethodChannel('comics_editor_$viewId');
  }

  Future<void> loadEpisode(String path) async {
    await _channel?.invokeMethod('loadEpisode', {'path': path});
  }

  Future<void> saveEpisode(String path) async {
    await _channel?.invokeMethod('saveEpisode', {'path': path});
  }

  Future<void> addLayer(String imagePath) async {
    await _channel?.invokeMethod('addLayer', {'imagePath': imagePath});
  }

  Future<List<Map<String, dynamic>>> getLayers() async {
    final result = await _channel?.invokeMethod('getLayers');
    return List<Map<String, dynamic>>.from(result ?? []);
  }

  // ... more methods
}
```

**Dependencies:** Task 4.1
**Verification:** Methods callable without errors
**Complexity:** Low

---

### Phase 5: Example App UI (Days 5-6)

#### Task 5.1: Create Editor Screen Layout

**Description:** Main screen with panels around PlatformView

**Files:**
- `example/lib/screens/editor_screen.dart` - **CREATE** (~200 lines)

**Layout:**
```
┌─────────────────────────────────────┐
│ Toolbar (Flutter)                   │
├──────────┬─────────────────┬────────┤
│ Layers   │ WPF Canvas      │ Props  │
│ Panel    │ (PlatformView)  │ Panel  │
│ (Flutter)│                 │(Flutter)│
│          │                 │        │
├──────────┴─────────────────┴────────┤
│ Timeline Panel (Flutter)            │
└─────────────────────────────────────┘
```

**Dependencies:** Task 4.2
**Verification:** Layout renders correctly, resizes properly
**Complexity:** Medium

---

#### Task 5.2: Implement Toolbar Widget

**Description:** Top toolbar with common actions

**Files:**
- `example/lib/widgets/toolbar/toolbar_widget.dart` - **CREATE** (~100 lines)

**Buttons:**
- New Episode
- Open Episode
- Save Episode
- Add Layer
- Remove Layer
- Undo / Redo

**Dependencies:** Task 5.1
**Verification:** Buttons call controller methods
**Complexity:** Low

---

#### Task 5.3: Implement Layers Panel

**Description:** Left panel showing layer list

**Files:**
- `example/lib/widgets/panels/layers_panel.dart` - **CREATE** (~150 lines)

**Features:**
- Fetch layers via `controller.getLayers()`
- Display as ListView
- Click to select
- Drag to reorder

**Dependencies:** Task 5.1
**Verification:** Shows layers from WPF, updates on changes
**Complexity:** Medium

---

#### Task 5.4: Implement Properties Panel

**Description:** Right panel for selected layer properties

**Files:**
- `example/lib/widgets/panels/properties_panel.dart` - **CREATE** (~200 lines)

**Properties:**
- Name (TextField)
- Position X, Y (Sliders)
- Size W, H (Sliders)
- Rotation (Slider)
- Opacity (Slider)

**Update flow:**
```dart
onChanged: (value) {
  controller.updateLayer(selectedLayerId, {
    'x': value,
  });
}
```

**Dependencies:** Task 5.3
**Verification:** Changes update WPF canvas
**Complexity:** Medium

---

#### Task 5.5: Implement File Picker Dialogs

**Description:** Dialogs for selecting episode/image files

**Files:**
- `example/lib/widgets/dialogs/file_picker_dialog.dart` - **CREATE** (~80 lines)

**Use:**
- Open Episode (.comics file)
- Add Layer (image file)

**Dependencies:** Task 5.2
**Verification:** Selected files passed to controller
**Complexity:** Low

---

### Phase 6: Integration & Testing (Day 7)

#### Task 6.1: End-to-End Integration Test

**Description:** Test full workflow: Load → Edit → Save

**Test Steps:**
1. Launch app
2. Load sample.comics
3. Verify layers appear in panel
4. Add new layer
5. Modify layer properties
6. Save episode
7. Reload and verify changes persisted

**Files:**
- `example/test/integration_test.dart` - **CREATE**

**Dependencies:** All previous tasks
**Verification:** All steps succeed without errors
**Complexity:** Medium

---

#### Task 6.2: Error Handling & Edge Cases

**Description:** Handle errors gracefully

**Scenarios:**
- Invalid file path
- Corrupted .comics file
- WPF control crash
- Method channel timeout

**Files:**
- All Dart files - **MODIFY** (add try/catch)
- All C# files - **MODIFY** (add error codes)

**Dependencies:** Task 6.1
**Verification:** Errors shown to user, app doesn't crash
**Complexity:** Medium

---

### Phase 7: Documentation & Polish (Days 8-9)

#### Task 7.1: Update README

**Description:** Document PlatformView architecture and usage

**Files:**
- `README.md` - **MODIFY**

**Sections:**
- Architecture overview
- Build instructions
- Usage example
- API reference
- Limitations (Windows only)

**Dependencies:** Task 6.2
**Verification:** Can follow README to build and run
**Complexity:** Low

---

#### Task 7.2: Add Code Comments

**Description:** Document all public APIs

**Files:**
- All Dart files - **MODIFY**
- All C# files - **MODIFY**

**Dependencies:** Task 7.1
**Verification:** `flutter analyze` and `dartdoc` succeed
**Complexity:** Low

---

#### Task 7.3: Create Sample App

**Description:** Polish example app for demonstration

**Files:**
- `example/lib/main.dart` - **MODIFY**
- `example/assets/sample.comics` - **VERIFY** (already exists)

**Features:**
- Welcome screen
- Load sample.comics button
- Polished UI

**Dependencies:** Task 7.2
**Verification:** Demo-ready app
**Complexity:** Low

---

## Dependency Graph

```
Phase 1: Setup (Day 1)
┌────────┐   ┌────────┐   ┌────────┐
│ 1.1    │   │ 1.2    │   │ 1.3    │
│ C#     │──▶│ Flutter│──▶│ Dart   │
│ Project│   │ Config │   │ Files  │
└────────┘   └────────┘   └────────┘
                │
                ▼
Phase 2: C# Implementation (Days 2-3)
┌────────┐   ┌────────┐   ┌────────┐
│ 2.1    │──▶│ 2.2    │──▶│ 2.3    │
│Platform│   │ Method │   │ Build  │
│View    │   │Handler │   │        │
└────────┘   └────────┘   └────────┘
                │
                ▼
Phase 3: Windows Integration (Day 3)
┌────────┐   ┌────────┐
│ 3.1    │──▶│ 3.2    │
│ C++    │   │ CMake  │
│ Plugin │   │ Config │
└────────┘   └────────┘
                │
                ▼
Phase 4: Dart Widget (Day 4)
┌────────┐   ┌────────┐
│ 4.1    │──▶│ 4.2    │
│ Widget │   │Control │
│        │   │-ler    │
└────────┘   └────────┘
                │
                ▼
Phase 5: Example UI (Days 5-6)
┌────────┬────────┬────────┬────────┬────────┐
│ 5.1    │ 5.2    │ 5.3    │ 5.4    │ 5.5    │
│ Screen │Toolbar │ Layers │ Props  │ Dialogs│
└────────┴────────┴────────┴────────┴────────┘
                │
                ▼
Phase 6: Testing (Day 7)
┌────────┐   ┌────────┐
│ 6.1    │──▶│ 6.2    │
│E2E Test│   │ Errors │
└────────┘   └────────┘
                │
                ▼
Phase 7: Polish (Days 8-9)
┌────────┬────────┬────────┐
│ 7.1    │ 7.2    │ 7.3    │
│ README │Comments│ Sample │
└────────┴────────┴────────┘
```

---

## File Change Summary

| File | Action | Reason |
|------|--------|--------|
| `native/Comics.Editor.Flutter/Comics.Editor.Flutter.csproj` | Create | New C# project for Flutter integration |
| `native/Comics.Editor.Flutter/ComicsEditorPlatformView.cs` | Create | PlatformView wrapper around WPF control |
| `native/Comics.Editor.Flutter/MethodChannelHandler.cs` | Create | Handle Method Channel calls |
| `windows/editor_plugin.cpp` | Modify | Register PlatformView factory |
| `windows/CMakeLists.txt` | Modify | Build and bundle C# DLLs |
| `lib/src/comics_editor_widget.dart` | Create | PlatformView Flutter widget |
| `lib/src/editor_controller.dart` | Create | Method Channel communication |
| `example/lib/screens/editor_screen.dart` | Create | Main UI layout |
| `example/lib/widgets/**/*.dart` | Create | UI components (toolbar, panels, etc.) |
| `src/editor.h` | Delete | No FFI needed with PlatformView |
| `src/editor.c` | Delete | No FFI needed |
| `ffigen.yaml` | Delete | No FFI code generation needed |
| `pubspec.yaml` | Modify | Remove FFI deps, rename package |
| `README.md` | Modify | Document new architecture |

**Total:**
- Create: 11 files
- Modify: 6 files
- Delete: 3 files

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| PlatformView not working on Windows | Low | High | Test early (Task 3.1), fallback to Thin Client approach |
| Method Channel performance issues | Low | Medium | Profile and optimize JSON serialization |
| WPF control crashes affecting Flutter | Medium | Medium | Robust error handling (Task 6.2), isolate in separate process if needed |
| .NET 9 runtime not on user machine | Medium | High | Include runtime in installer or use self-contained publish |
| Existing C# code incompatible | Low | High | Verified existing code works (already used in WPF app) |

---

## Rollback Strategy

If PlatformView approach fails:

1. **Keep all C# code** - it's unchanged
2. **Switch to Thin Client** (Variant 1) - use FFI instead
3. **Estimated switch time**: 3-4 days

**Trigger points:**
- Cannot register PlatformView (Task 3.1 fails)
- Performance unacceptable (>100ms latency)
- Crashes too frequent

---

## Checkpoints

### After Phase 2 (Day 3):
- [ ] C# project builds successfully
- [ ] MethodChannelHandler compiles
- [ ] No errors in `dotnet build`

### After Phase 3 (Day 3):
- [ ] Windows plugin registers PlatformView
- [ ] Flutter build includes C# DLLs
- [ ] No CMake errors

### After Phase 4 (Day 4):
- [ ] ComicsEditorWidget renders (even if empty)
- [ ] Method channel connects
- [ ] No Dart analyze errors

### After Phase 5 (Day 6):
- [ ] Can load sample.comics
- [ ] Layers appear in panel
- [ ] Can modify layer properties

### After Phase 6 (Day 7):
- [ ] Full workflow works (load → edit → save)
- [ ] Error handling graceful
- [ ] No crashes

### After Phase 7 (Day 9):
- [ ] README complete
- [ ] Code documented
- [ ] Demo app ready

---

## Open Implementation Questions

- [ ] **Decided:** Use .NET 9 ✅
- [ ] **C++/CLI or COM** for C++ ↔ C# bridge? (Decide in Task 3.1)
- [ ] **Self-contained or framework-dependent** publish? (Decide in Task 2.3)
- [ ] **Multiple editor instances** - do we need to support? (Defer to Phase 2)

---

## Success Criteria

**Phase 1-3:** Basic integration works
- PlatformView renders WPF control
- Method Channel connects

**Phase 4-5:** Functional editor
- Can load/save episodes
- Can add/edit layers
- UI responsive

**Phase 6-7:** Production ready
- No crashes
- Good error handling
- Documented

---

## Approval

- [ ] Reviewed by: Anton
- [ ] Approved on: [pending]
- [ ] Notes: Ready to proceed with implementation once approved

---

**Ready to start Phase 1?**
