# Technology Stack - Flutter Comics Editor

> Updated: 2026-07-19
> Architecture: PlatformView (Variant 2)

## Core Technologies

### .NET Stack
- **.NET 9** (latest) - C# backend and native handler
- **C# 12** - Latest language features
- **WPF** - UI framework (existing editor controls)
- **NativeAOT Ready** - For potential future optimization

### Flutter Stack
- **Flutter 3.x** - Cross-platform UI framework
- **Dart 3.x** - Programming language
- **Platform Channels** - Native communication (Method Channels)
- **PlatformView** - Embedding native WPF controls

### Platform
- **Windows** - Primary platform (PlatformView with WPF)
- **Windows 10/11** - Target OS

---

## Project Structure

### C# Projects (.NET 9)

#### 1. Comics.Editor (existing)
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>
</Project>
```

**Existing code - no changes needed!**
- ViewModels (ComicsViewModel, LayerViewModel, etc.)
- Models (Layer, Animation, Sound, etc.)
- Controls (EditorControl.xaml, etc.)
- Business logic

#### 2. Comics.Editor.Flutter (new)
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <OutputType>Library</OutputType>
  </PropertyGroup>

  <ItemGroup>
    <ProjectReference Include="../Comics.Editor/Comics.Editor.csproj" />
    <!-- Flutter Windows SDK will be linked via CMake -->
  </ItemGroup>

  <ItemGroup>
    <PackageReference Include="System.Text.Json" Version="9.0.*" />
  </ItemGroup>
</Project>
```

**New code for Flutter integration:**
- PlatformView factories
- Method Channel handlers
- JSON serialization adapters

---

## C# Code Features (.NET 9 / C# 12)

### Modern C# Features We'll Use

#### 1. Primary Constructors
```csharp
public class ComicsEditorPlatformView(
    int viewId,
    Dictionary<string, object>? creationParams,
    FlutterEngine engine) : PlatformView
{
    private readonly UserControl _control = new EditorControl();
    private readonly ComicsViewModel _viewModel = new();

    // Clean, concise code
}
```

#### 2. Collection Expressions
```csharp
// Modern collection initialization
var layers = _viewModel.Layers
    .Select(l => new Dictionary<string, object>
    {
        ["id"] = l.Id,
        ["name"] = l.Name,
        ["x"] = l.X,
        ["y"] = l.Y
    })
    .ToList();
```

#### 3. Required Members
```csharp
public class EditorConfiguration
{
    public required string ViewType { get; init; }
    public required int ViewId { get; init; }
    public string? InitialEpisodePath { get; init; }
}
```

#### 4. File-Scoped Namespaces
```csharp
namespace Comics.Editor.Flutter;

public class ComicsEditorPlatformView : PlatformView
{
    // Cleaner code structure
}
```

#### 5. Global Usings
```csharp
// GlobalUsings.cs
global using System;
global using System.Collections.Generic;
global using System.Linq;
global using System.Windows;
global using System.Windows.Controls;
global using System.Text.Json;
```

#### 6. Nullable Reference Types
```csharp
public class MethodChannelHandler
{
    private MethodChannel? _channel;
    private readonly ComicsViewModel _viewModel;

    public void Handle(MethodCall call, MethodResult result)
    {
        // Compile-time null safety
        _channel?.InvokeMethod("callback", data);
    }
}
```

---

## Flutter Integration Architecture

### Communication Flow

```
Flutter (Dart)
    │
    ├─ PlatformViewLink
    │   └─> viewType: 'comics_editor_view'
    │
    ├─ MethodChannel('comics_editor_123')
    │   └─> invokeMethod('loadEpisode', params)
    │
    ▼
Windows C++ Plugin (CMake)
    │
    ├─ RegisterViewFactory('comics_editor_view')
    │
    ├─ FlutterDesktopMessenger
    │
    ▼
C# (.NET 9)
    │
    ├─ ComicsEditorViewFactory
    │   └─> Create() → ComicsEditorPlatformView
    │
    ├─ MethodChannelHandler
    │   └─> OnMethodCall() → ComicsViewModel
    │
    ▼
WPF Controls (Existing!)
    │
    └─ EditorControl.xaml
        └─> DataContext: ComicsViewModel
```

---

## Build Configuration

### CMake Configuration (windows/CMakeLists.txt)

```cmake
cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "editor")
project(${PROJECT_NAME} LANGUAGES CXX)

# Flutter Windows SDK
set(PLUGIN_NAME "editor_plugin")

# Add C# project
add_custom_target(
  ${PLUGIN_NAME}_csharp ALL
  COMMAND dotnet publish
    ${CMAKE_CURRENT_SOURCE_DIR}/../native/Comics.Editor.Flutter/Comics.Editor.Flutter.csproj
    -c Release
    -f net9.0-windows
    -o ${CMAKE_CURRENT_BINARY_DIR}/csharp
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

# C++ Plugin
add_library(${PLUGIN_NAME} SHARED
  "editor_plugin.cpp"
)

# Link with .NET 9 runtime
target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  flutter_wrapper_plugin
)

# Copy C# DLLs to output
add_custom_command(
  TARGET ${PLUGIN_NAME} POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_CURRENT_BINARY_DIR}/csharp
    $<TARGET_FILE_DIR:${PLUGIN_NAME}>
)
```

### Flutter Plugin Configuration (pubspec.yaml)

```yaml
name: flutter_comics_editor
description: Comics editor plugin with WPF integration
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
        # No FFI - using PlatformView + Method Channels
```

---

## Development Tools

### Required Tools

- ✅ **Visual Studio 2022** (17.8+) - For .NET 9 development
- ✅ **Flutter SDK** (3.x) - Flutter development
- ✅ **VS Code** or **Android Studio** - Dart/Flutter IDE
- ✅ **Git** - Version control

### Optional Tools

- **dotnet CLI** - Command-line .NET tools
- **flutter doctor** - Environment diagnostics
- **Hot Reload** - Supported for Dart code (not C#)

---

## Performance Considerations

### .NET 9 Benefits

1. **Performance Improvements**
   - Faster JIT compilation
   - Better GC performance
   - Reduced memory allocations

2. **Platform Invocation**
   - Optimized P/Invoke
   - Source-generated COM wrappers
   - Better interop performance

3. **JSON Serialization**
   - System.Text.Json improvements
   - Source generators for serialization
   - Zero-allocation JSON reading

### PlatformView Performance

- **Separate rendering pipeline** - WPF and Flutter render independently
- **No pixel copying** - Direct composition
- **Native performance** - WPF renders at native speed

---

## Memory Management

### C# Side

```csharp
public class ComicsEditorPlatformView : PlatformView, IDisposable
{
    private bool _disposed;

    public override void Dispose()
    {
        if (_disposed) return;

        _methodHandler?.Dispose();
        _viewModel?.Dispose();
        _control?.Dispose();

        _disposed = true;
        GC.SuppressFinalize(this);
    }
}
```

### Flutter Side

```dart
class EditorController {
  MethodChannel? _channel;

  void dispose() {
    _channel = null;
  }
}
```

---

## Threading Model

### C# Threading

- **UI Thread** - All WPF operations must be on UI thread
- **Background Tasks** - Use Task.Run() for heavy operations
- **Dispatcher** - WPF dispatcher for UI updates

```csharp
private async Task LoadEpisodeAsync(string path)
{
    // Heavy I/O on background thread
    var data = await Task.Run(() => File.ReadAllBytes(path));

    // UI updates on UI thread
    await Dispatcher.InvokeAsync(() =>
    {
        _viewModel.Load(data);
    });
}
```

### Flutter Threading

- **UI Thread** - Platform channel calls happen on platform thread
- **Isolates** - Not needed for this architecture (C# handles heavy work)

---

## Error Handling

### C# Exception Handling

```csharp
private void OnMethodCall(MethodCall call, MethodResult result)
{
    try
    {
        switch (call.Method)
        {
            case "loadEpisode":
                LoadEpisode(call, result);
                break;
            default:
                result.NotImplemented();
                break;
        }
    }
    catch (IOException ex)
    {
        result.Error("IO_ERROR", ex.Message, ex.StackTrace);
    }
    catch (JsonException ex)
    {
        result.Error("JSON_ERROR", ex.Message, ex.StackTrace);
    }
    catch (Exception ex)
    {
        result.Error("UNKNOWN_ERROR", ex.Message, ex.StackTrace);
    }
}
```

### Dart Error Handling

```dart
Future<void> loadEpisode(String path) async {
  try {
    await _channel?.invokeMethod('loadEpisode', {'path': path});
  } on PlatformException catch (e) {
    print('Error loading episode: ${e.code} - ${e.message}');
    rethrow;
  }
}
```

---

## Testing Strategy

### C# Unit Tests

```csharp
using Xunit;

public class MethodChannelHandlerTests
{
    [Fact]
    public void LoadEpisode_ValidPath_Success()
    {
        var handler = new MethodChannelHandler(/*...*/);
        var call = new MethodCall("loadEpisode", new { path = "test.comics" });
        var result = new MockMethodResult();

        handler.OnMethodCall(call, result);

        Assert.True(result.WasSuccessful);
    }
}
```

### Flutter Widget Tests

```dart
testWidgets('ComicsEditorWidget creates platform view', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ComicsEditorWidget(
        controller: EditorController(),
      ),
    ),
  );

  expect(find.byType(PlatformViewLink), findsOneWidget);
});
```

### Integration Tests

- Load sample.comics in Flutter app
- Verify Method Channel communication
- Test all CRUD operations on layers
- Test save/load round-trip

---

## Build & Deploy

### Development Build

```bash
# Build C# projects
cd native/Comics.Editor.Flutter
dotnet build -c Debug

# Run Flutter app
cd example
flutter run -d windows
```

### Release Build

```bash
# Build C# with optimizations
cd native/Comics.Editor.Flutter
dotnet publish -c Release -f net9.0-windows --self-contained false

# Build Flutter release
cd example
flutter build windows --release
```

### Distribution

- **Standalone EXE** - Flutter bundles all dependencies
- **.NET 9 Runtime** - Required on target machine (or self-contained)
- **WPF Dependencies** - Included in .NET runtime

---

## Migration Path (Future)

If needed to support other platforms later:

1. **macOS** - Replace WPF with AppKit, keep C# backend with .NET MAUI
2. **Linux** - Replace WPF with GTK, keep C# backend with Avalonia
3. **Web** - Use Blazor for editor, keep C# backend

But for now: **Windows-only with WPF** is the fastest path to MVP.

---

## Summary

- ✅ **.NET 9** - Latest framework, best performance
- ✅ **C# 12** - Modern language features
- ✅ **WPF** - Proven UI framework (existing code)
- ✅ **PlatformView** - Native embedding
- ✅ **Method Channels** - Bidirectional communication
- ✅ **Zero C# code rewrite** - Use existing ViewModels/Models
- ✅ **Fast development** - ~2 weeks for both editors

Ready to proceed with implementation!
