# Детальный список файловых операций: PlatformView подход

> Дата: 2026-07-19
> Архитектура: Вариант 2 - PlatformView (встраивание WPF контрола)
> Платформа: **Только Windows**

## Легенда

- ✅ **ОСТАВИТЬ** - файл остается как есть, без изменений
- 📝 **РЕДАКТИРОВАТЬ** - файл будет изменен/дополнен
- 🔄 **ПЕРЕМЕСТИТЬ** - файл будет перемещен в другое место
- ❌ **УДАЛИТЬ** - файл больше не нужен
- ➕ **СОЗДАТЬ (новый)** - новый файл, написанный с нуля
- 🔁 **ПЕРЕПИСАТЬ (C# → Dart)** - взять логику из C# и переписать на Dart

---

## 🎯 КОНЦЕПЦИЯ

Используем **существующий WPF Canvas** (EditorControl) через PlatformView.
Flutter панели (Toolbar, Layers, Properties) общаются с WPF через Method Channels.

```
┌──────────────────────────────────────────┐
│ Flutter App                              │
│ ┌─────────────┐  ┌────────────────────┐ │
│ │Flutter UI   │  │ PlatformView       │ │
│ │- Toolbar    │  │ ┌────────────────┐ │ │
│ │- Layers     │◄─┤►│  WPF Canvas    │ │ │
│ │- Properties │  │ │  (СУЩЕСТВУЕТ!) │ │ │
│ └─────────────┘  │ └────────────────┘ │ │
│                  └────────────────────┘ │
└──────────────────────────────────────────┘
         │                     │
         └─── Method Channels ─┘
```

---

## 1. FLUTTER DART КОД

### 1.1. lib/ (Основной код плагина)

**МИНИМУМ кода! Только обертки над PlatformView**

#### Существующие файлы:

| Файл | Операция | Комментарий |
|------|----------|-------------|
| `lib/editor.dart` | 📝 **РЕДАКТИРОВАТЬ** | Экспорт ComicsEditorWidget (PlatformView обертка) |
| `lib/editor_bindings_generated.dart` | ❌ **УДАЛИТЬ** | НЕ НУЖЕН - нет FFI! |

#### Новые файлы (создать):

| Файл | Операция | Описание |
|------|----------|----------|
| `lib/src/comics_editor_widget.dart` | ➕ **СОЗДАТЬ** | PlatformView обертка (AndroidView/UiKitView/AppKitView) |
| `lib/src/editor_controller.dart` | ➕ **СОЗДАТЬ** | Контроллер для Method Channel общения |
| `lib/src/method_channel.dart` | ➕ **СОЗДАТЬ** | Method Channel константы и вызовы |

**ИТОГО lib/: 4 файла (вместо 15+!)**

---

### 1.2. example/lib/ (UI Demo приложение)

#### Существующие файлы:

| Файл | Операция | Комментарий |
|------|----------|-------------|
| `example/lib/main.dart` | 📝 **ПЕРЕПИСАТЬ** | Главное приложение с layout |

#### Новые файлы (создать):

**Основное**
| Файл | Операция | Описание |
|------|----------|----------|
| `example/lib/screens/editor_screen.dart` | ➕ **СОЗДАТЬ** | Layout: Flutter панели + WPF canvas |

**Панели (Flutter виджеты)**
| Файл | Операция | Описание |
|------|----------|----------|
| `example/lib/widgets/toolbar/toolbar_widget.dart` | ➕ **СОЗДАТЬ** | Toolbar с кнопками (Add Layer, Save, etc.) |
| `example/lib/widgets/panels/layers_panel.dart` | ➕ **СОЗДАТЬ** | Список слоев (читает из WPF через channel) |
| `example/lib/widgets/panels/properties_panel.dart` | ➕ **СОЗДАТЬ** | Свойства выбранного слоя |

**Селекторы**
| Файл | Операция | Описание |
|------|----------|----------|
| `example/lib/widgets/dialogs/file_picker_dialog.dart` | ➕ **СОЗДАТЬ** | Диалог выбора файла (episode, image) |

**ИТОГО example/lib/: ~8 файлов**

---

### 1.3. Конфигурационные файлы

| Файл | Операция | Комментарий |
|------|----------|-------------|
| `pubspec.yaml` | 📝 **РЕДАКТИРОВАТЬ** | name: flutter_comics_editor, зависимости (БЕЗ ffi/ffigen!) |
| `example/pubspec.yaml` | 📝 **РЕДАКТИРОВАТЬ** | Ссылка на плагин |
| `README.md` | 📝 **РЕДАКТИРОВАТЬ** | Документация PlatformView подхода |
| `CHANGELOG.md` | 📝 **РЕДАКТИРОВАТЬ** | Запись о рефакторинге |
| `analysis_options.yaml` | ✅ **ОСТАВИТЬ** | Без изменений |
| `ffigen.yaml` | ❌ **УДАЛИТЬ** | НЕ НУЖЕН |

---

## 2. NATIVE C# КОД (Windows)

### 2.1. WPF Editor Control (ИСПОЛЬЗУЕМ СУЩЕСТВУЮЩИЙ!)

**ВСЕ ОСТАВЛЯЕМ КАК ЕСТЬ!** Это ключевое преимущество PlatformView.

| Директория/Файл | Операция | Комментарий |
|-----------------|----------|-------------|
| `native/Comics.Editor/Controls/*.xaml` | ✅ **ОСТАВИТЬ** | Существующие WPF контролы |
| `native/Comics.Editor/ViewModel/*.cs` | ✅ **ОСТАВИТЬ** | Вся логика уже есть! |
| `native/Comics.Editor/Models/*.cs` | ✅ **ОСТАВИТЬ** | Модели данных |
| `native/Comics.Editor/App.xaml.cs` | ✅ **ОСТАВИТЬ** | WPF приложение |

### 2.2. Platform Channel Handler (НОВОЕ!)

Создаем обработчик Method Channels для связи Flutter ↔ WPF.

**Новый проект: native/Comics.Editor.Flutter/**

| Файл | Операция | Описание |
|------|----------|----------|
| `ComicsEditorPlatformView.cs` | ➕ **СОЗДАТЬ** | PlatformView фабрика и обработчик |
| `MethodChannelHandler.cs` | ➕ **СОЗДАТЬ** | Обработка вызовов от Flutter |
| `Comics.Editor.Flutter.csproj` | ➕ **СОЗДАТЬ** | Проект библиотеки для Flutter |

**ИТОГО C#: 3 новых файла**

---

### 2.3. src/ (C FFI слой)

| Файл | Операция | Комментарий |
|------|----------|-------------|
| `src/editor.h` | ❌ **УДАЛИТЬ** | НЕ НУЖЕН - нет FFI! |
| `src/editor.c` | ❌ **УДАЛИТЬ** | НЕ НУЖЕН - нет FFI! |
| `src/CMakeLists.txt` | ❌ **УДАЛИТЬ** | НЕ НУЖЕН |

---

## 3. WINDOWS PLATFORM INTEGRATION

### 3.1. windows/ (Flutter Windows plugin)

| Файл | Операция | Комментарий |
|------|----------|-------------|
| `windows/editor_plugin.h` | 📝 **РЕДАКТИРОВАТЬ** | Регистрация PlatformView |
| `windows/editor_plugin.cpp` | 📝 **РЕДАКТИРОВАТЬ** | Создание PlatformView фабрики |
| `windows/CMakeLists.txt` | 📝 **РЕДАКТИРОВАТЬ** | Линковка с C# DLL |

### 3.2. example/windows/ (Example app)

| Файл | Операция | Комментарий |
|------|----------|-------------|
| `example/windows/runner/main.cpp` | ✅ **ОСТАВИТЬ** | Генерируется Flutter |
| Все остальные | ✅ **ОСТАВИТЬ** | Генерируется Flutter |

---

## 4. ДРУГИЕ ПЛАТФОРМЫ (НЕ ПОДДЕРЖИВАЮТСЯ)

### 4.1. macOS

| Директория | Операция | Комментарий |
|------------|----------|-------------|
| `macos/*` | ✅ **ОСТАВИТЬ или ❌ УДАЛИТЬ** | PlatformView только для Windows |

### 4.2. Linux

| Директория | Операция | Комментарий |
|------------|----------|-------------|
| `linux/*` | ✅ **ОСТАВИТЬ или ❌ УДАЛИТЬ** | PlatformView только для Windows |

**Рекомендация:** Оставить папки, но добавить README с пояснением "Windows only"

---

## 5. PLATFORM-SPECIFIC FILES

### 5.1. Example assets

| Файл | Операция | Комментарий |
|------|----------|-------------|
| `example/assets/sample.comics` | ✅ **ОСТАВИТЬ** | Используется для демо |

---

## ИТОГОВАЯ СТАТИСТИКА

### По операциям:

| Операция | Количество | Детали |
|----------|-----------|--------|
| ✅ **ОСТАВИТЬ БЕЗ ИЗМЕНЕНИЙ** | ~200+ файлов | Весь C# WPF код, все модели, вся логика |
| 📝 **РЕДАКТИРОВАТЬ** | 6 файлов | pubspec.yaml, README, plugin.cpp, editor.dart |
| ➕ **СОЗДАТЬ НОВЫЕ** | ~11 файлов | 4 Dart (lib) + 3 C# + 4 Dart (example UI) |
| ❌ **УДАЛИТЬ** | 3 файла | FFI слой (editor.h, editor.c, ffigen.yaml) |
| 🔁 **ПЕРЕПИСАТЬ C# → Dart** | **0 файлов** | НЕТ! Все остается в C# |
| 🔄 **ПЕРЕМЕСТИТЬ** | 0 файлов | - |

### Сравнение с Thin Client подходом:

| Критерий | PlatformView | Thin Client |
|----------|--------------|-------------|
| Новых Dart файлов | ~12 | ~15 |
| Новых C# файлов | 3 | 1 |
| Переписать C#→Dart | 0 | 0 |
| Удалить файлов | 3 (FFI) | 0 |
| Сложность | **Низкая** | Средняя |
| Платформы | **Только Win** | Win/Mac/Linux |

---

## ДЕТАЛЬНЫЕ СПИСКИ ФАЙЛОВ

### Dart файлы (lib/) - СОЗДАТЬ

#### 1. lib/editor.dart
```dart
// Экспорт публичного API
library flutter_comics_editor;

export 'src/comics_editor_widget.dart';
export 'src/editor_controller.dart';
```

#### 2. lib/src/comics_editor_widget.dart (➕ СОЗДАТЬ ~100 строк)
```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// PlatformView обертка над WPF EditorControl
class ComicsEditorWidget extends StatefulWidget {
  final EditorController controller;
  final String? initialEpisodePath;

  const ComicsEditorWidget({
    Key? key,
    required this.controller,
    this.initialEpisodePath,
  }) : super(key: key);

  @override
  State<ComicsEditorWidget> createState() => _ComicsEditorWidgetState();
}

class _ComicsEditorWidgetState extends State<ComicsEditorWidget> {
  @override
  Widget build(BuildContext context) {
    // Только Windows поддерживается
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return _buildWindowsView();
    }

    return Center(
      child: Text('Comics Editor поддерживается только на Windows'),
    );
  }

  Widget _buildWindowsView() {
    // PlatformViewLink для Windows
    return PlatformViewLink(
      viewType: 'comics_editor_view',
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (params) {
        return PlatformViewsService.initExpensiveAndroidView(
          id: params.id,
          viewType: 'comics_editor_view',
          layoutDirection: TextDirection.ltr,
          creationParams: {
            'episodePath': widget.initialEpisodePath,
          },
          creationParamsCodec: const StandardMessageCodec(),
          onFocus: () {
            params.onFocusChanged(true);
          },
        )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..addOnPlatformViewCreatedListener(_onPlatformViewCreated)
          ..create();
      },
    );
  }

  void _onPlatformViewCreated(int id) {
    widget.controller._connect(id);
  }
}
```

#### 3. lib/src/editor_controller.dart (➕ СОЗДАТЬ ~200 строк)
```dart
import 'package:flutter/services.dart';

/// Контроллер для управления WPF редактором через Method Channel
class EditorController {
  MethodChannel? _channel;
  int? _viewId;

  // Подключиться к PlatformView
  void _connect(int viewId) {
    _viewId = viewId;
    _channel = MethodChannel('comics_editor_$viewId');
  }

  // Загрузить эпизод
  Future<void> loadEpisode(String path) async {
    await _channel?.invokeMethod('loadEpisode', {'path': path});
  }

  // Сохранить эпизод
  Future<void> saveEpisode(String path) async {
    await _channel?.invokeMethod('saveEpisode', {'path': path});
  }

  // Добавить слой
  Future<void> addLayer(String imagePath) async {
    await _channel?.invokeMethod('addLayer', {'imagePath': imagePath});
  }

  // Удалить слой
  Future<void> removeLayer(String layerId) async {
    await _channel?.invokeMethod('removeLayer', {'layerId': layerId});
  }

  // Получить список слоев
  Future<List<Map<String, dynamic>>> getLayers() async {
    final result = await _channel?.invokeMethod('getLayers');
    return List<Map<String, dynamic>>.from(result ?? []);
  }

  // Обновить свойства слоя
  Future<void> updateLayer(String layerId, Map<String, dynamic> properties) async {
    await _channel?.invokeMethod('updateLayer', {
      'layerId': layerId,
      'properties': properties,
    });
  }

  // Undo
  Future<void> undo() async {
    await _channel?.invokeMethod('undo');
  }

  // Redo
  Future<void> redo() async {
    await _channel?.invokeMethod('redo');
  }

  void dispose() {
    _channel = null;
  }
}
```

#### 4. lib/src/method_channel.dart (➕ СОЗДАТЬ ~50 строк)
```dart
// Константы для Method Channel
class EditorMethodChannel {
  static const String channelPrefix = 'comics_editor_';

  // Методы
  static const String loadEpisode = 'loadEpisode';
  static const String saveEpisode = 'saveEpisode';
  static const String addLayer = 'addLayer';
  static const String removeLayer = 'removeLayer';
  static const String getLayers = 'getLayers';
  static const String updateLayer = 'updateLayer';
  static const String undo = 'undo';
  static const String redo = 'redo';
}
```

---

### C# файлы - СОЗДАТЬ

**native/Comics.Editor.Flutter/** (новый проект)

#### 1. ComicsEditorPlatformView.cs (➕ СОЗДАТЬ ~300 строк)
```csharp
using System;
using System.Windows;
using System.Windows.Controls;
using System.Collections.Generic;
using Flutter;
using Flutter.Embedding.Engine;
using Flutter.MethodChannel;

namespace Comics.Editor.Flutter
{
    /// PlatformView фабрика для регистрации в Flutter
    public class ComicsEditorViewFactory : PlatformViewFactory
    {
        private readonly FlutterEngine _engine;

        public ComicsEditorViewFactory(FlutterEngine engine)
            : base(StandardMessageCodec.Instance)
        {
            _engine = engine;
        }

        public override PlatformView Create(int viewId, object args)
        {
            var creationParams = args as Dictionary<string, object>;
            return new ComicsEditorPlatformView(viewId, creationParams, _engine);
        }
    }

    /// PlatformView обертка над WPF EditorControl
    public class ComicsEditorPlatformView : PlatformView
    {
        private readonly int _viewId;
        private readonly UserControl _control;
        private readonly ComicsViewModel _viewModel;
        private readonly MethodChannelHandler _methodHandler;

        public ComicsEditorPlatformView(
            int viewId,
            Dictionary<string, object> creationParams,
            FlutterEngine engine)
        {
            _viewId = viewId;

            // ✅ ИСПОЛЬЗУЕМ СУЩЕСТВУЮЩИЙ WPF КОНТРОЛ!
            _control = new EditorControl();

            // ✅ ИСПОЛЬЗУЕМ СУЩЕСТВУЮЩИЙ ViewModel!
            _viewModel = new ComicsViewModel();
            _control.DataContext = _viewModel;

            // Создаем Method Channel для этого view
            var channelName = $"comics_editor_{viewId}";
            _methodHandler = new MethodChannelHandler(
                engine.BinaryMessenger,
                channelName,
                _viewModel
            );

            // Загрузить начальный эпизод если указан
            if (creationParams?.ContainsKey("episodePath") == true)
            {
                var path = creationParams["episodePath"] as string;
                if (!string.IsNullOrEmpty(path))
                {
                    _viewModel.Load(path);  // ✅ Существующий метод!
                }
            }
        }

        public override UIElement GetView() => _control;

        public override void Dispose()
        {
            _methodHandler?.Dispose();
            _viewModel?.Dispose();
        }
    }
}
```

#### 2. MethodChannelHandler.cs (➕ СОЗДАТЬ ~200 строк)
```csharp
using System;
using System.Collections.Generic;
using System.Linq;
using Flutter.MethodChannel;
using Newtonsoft.Json;

namespace Comics.Editor.Flutter
{
    /// Обработчик Method Channel вызовов от Flutter
    public class MethodChannelHandler : IDisposable
    {
        private readonly MethodChannel _channel;
        private readonly ComicsViewModel _viewModel;

        public MethodChannelHandler(
            BinaryMessenger messenger,
            string channelName,
            ComicsViewModel viewModel)
        {
            _viewModel = viewModel;
            _channel = new MethodChannel(messenger, channelName);
            _channel.SetMethodCallHandler(OnMethodCall);
        }

        private void OnMethodCall(MethodCall call, MethodResult result)
        {
            try
            {
                switch (call.Method)
                {
                    case "loadEpisode":
                        LoadEpisode(call, result);
                        break;

                    case "saveEpisode":
                        SaveEpisode(call, result);
                        break;

                    case "addLayer":
                        AddLayer(call, result);
                        break;

                    case "removeLayer":
                        RemoveLayer(call, result);
                        break;

                    case "getLayers":
                        GetLayers(result);
                        break;

                    case "updateLayer":
                        UpdateLayer(call, result);
                        break;

                    case "undo":
                        Undo(result);
                        break;

                    case "redo":
                        Redo(result);
                        break;

                    default:
                        result.NotImplemented();
                        break;
                }
            }
            catch (Exception ex)
            {
                result.Error("ERROR", ex.Message, ex.StackTrace);
            }
        }

        private void LoadEpisode(MethodCall call, MethodResult result)
        {
            var path = call.Argument<string>("path");
            _viewModel.Load(path);  // ✅ Существующий метод!
            result.Success(null);
        }

        private void SaveEpisode(MethodCall call, MethodResult result)
        {
            var path = call.Argument<string>("path");
            _viewModel.Save(path);  // ✅ Существующий метод!
            result.Success(null);
        }

        private void AddLayer(MethodCall call, MethodResult result)
        {
            var imagePath = call.Argument<string>("imagePath");

            // ✅ Используем существующую логику!
            var layer = new Layer
            {
                Id = Guid.NewGuid().ToString(),
                Name = "New Layer",
                ImagePath = imagePath,
                // ... другие свойства по умолчанию
            };

            _viewModel.Layers.Add(layer);
            result.Success(layer.Id);
        }

        private void RemoveLayer(MethodCall call, MethodResult result)
        {
            var layerId = call.Argument<string>("layerId");
            var layer = _viewModel.Layers.FirstOrDefault(l => l.Id == layerId);

            if (layer != null)
            {
                _viewModel.Layers.Remove(layer);  // ✅ Существующая коллекция!
                result.Success(true);
            }
            else
            {
                result.Success(false);
            }
        }

        private void GetLayers(MethodResult result)
        {
            // ✅ Существующие данные!
            var layers = _viewModel.Layers
                .Select(l => new Dictionary<string, object>
                {
                    ["id"] = l.Id,
                    ["name"] = l.Name,
                    ["x"] = l.X,
                    ["y"] = l.Y,
                    ["width"] = l.Width,
                    ["height"] = l.Height,
                    ["rotation"] = l.Rotation,
                    ["opacity"] = l.Opacity,
                    // ... другие свойства
                })
                .ToList();

            result.Success(layers);
        }

        private void UpdateLayer(MethodCall call, MethodResult result)
        {
            var layerId = call.Argument<string>("layerId");
            var properties = call.Argument<Dictionary<string, object>>("properties");

            var layer = _viewModel.Layers.FirstOrDefault(l => l.Id == layerId);
            if (layer != null)
            {
                // Обновляем свойства
                if (properties.ContainsKey("x")) layer.X = Convert.ToDouble(properties["x"]);
                if (properties.ContainsKey("y")) layer.Y = Convert.ToDouble(properties["y"]);
                if (properties.ContainsKey("name")) layer.Name = properties["name"].ToString();
                // ... и т.д.

                result.Success(true);
            }
            else
            {
                result.Success(false);
            }
        }

        private void Undo(MethodResult result)
        {
            // Если есть Undo в ViewModel
            _viewModel.Undo?.Execute(null);
            result.Success(null);
        }

        private void Redo(MethodResult result)
        {
            // Если есть Redo в ViewModel
            _viewModel.Redo?.Execute(null);
            result.Success(null);
        }

        public void Dispose()
        {
            _channel?.Dispose();
        }
    }
}
```

#### 3. Comics.Editor.Flutter.csproj (➕ СОЗДАТЬ)
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net6.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
  </PropertyGroup>

  <ItemGroup>
    <!-- Ссылка на существующий проект! -->
    <ProjectReference Include="../Comics.Editor/Comics.Editor.csproj" />

    <!-- Flutter SDK (будет указан позже) -->
    <PackageReference Include="Flutter.Windows.SDK" Version="*" />
  </ItemGroup>
</Project>
```

---

### Windows Platform Integration - РЕДАКТИРОВАТЬ

#### windows/editor_plugin.cpp (📝 РЕДАКТИРОВАТЬ)
```cpp
#include "include/editor/editor_plugin.h"

void EditorPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {

  // Регистрируем PlatformView фабрику
  auto factory = std::make_unique<ComicsEditorViewFactory>(
      FlutterDesktopPluginRegistrarGetEngine(registrar)
  );

  FlutterDesktopPluginRegistrarRegisterViewFactory(
      registrar,
      "comics_editor_view",
      factory.get()
  );
}
```

---

## ПРИОРИТЕТ РЕАЛИЗАЦИИ

### Фаза 1: Базовая структура (1 день)
1. ✅ Создать C# проект Comics.Editor.Flutter
2. ✅ Создать Dart файлы lib/
3. ✅ Обновить pubspec.yaml (убрать FFI зависимости)
4. ✅ Удалить FFI слой (src/)

### Фаза 2: C# PlatformView (2 дня)
1. ✅ ComicsEditorPlatformView.cs
2. ✅ MethodChannelHandler.cs
3. ✅ Тестирование связи Flutter ↔ WPF

### Фаза 3: Flutter UI (3 дня)
1. ✅ EditorScreen layout
2. ✅ Toolbar widget
3. ✅ Layers panel (читает через channel)
4. ✅ Properties panel

### Фаза 4: Интеграция (1 день)
1. ✅ Связать панели с WPF
2. ✅ Тестирование всех команд
3. ✅ Загрузка sample.comics

### Фаза 5: Доработка (2 дня)
1. ✅ Обработка ошибок
2. ✅ Документация
3. ✅ Примеры использования

**ИТОГО: ~9 рабочих дней**

---

## ЧТО НЕ ПЕРЕПИСЫВАЕМ (ОГРОМНАЯ ЭКОНОМИЯ!)

### C# код (ВСЕ остается!)

- ❌ Layer.cs → НЕ переписываем
- ❌ Animation.cs → НЕ переписываем
- ❌ Sound.cs → НЕ переписываем
- ❌ ComicsViewModel → НЕ переписываем
- ❌ LayerViewModel → НЕ переписываем
- ❌ EditorControl.xaml → НЕ переписываем
- ❌ Сериализация .comics → НЕ переписываем
- ❌ Любая бизнес-логика → НЕ переписываем

### ИТОГО: 0 файлов C# → Dart!

---

## ОГРАНИЧЕНИЯ ПОДХОДА

⚠️ **Только Windows** - PlatformView с WPF работает только на Windows
⚠️ **Композитинг** - WPF рендерится отдельно от Flutter
⚠️ **Кастомизация UI** - WPF Canvas нельзя "смешать" с Flutter виджетами

---

## ПРЕИМУЩЕСТВА

✅ **Минимум работы** - ~11 новых файлов
✅ **Используем 100% C# кода** - вообще ничего не переписываем
✅ **Быстро** - за неделю можно реализовать
✅ **Надежно** - C# код уже протестирован

---

## ВОПРОСЫ ДЛЯ УТОЧНЕНИЯ

1. Есть ли у вас в WPF приложении уже EditorControl.xaml как отдельный UserControl?
2. Можем ли использовать .NET 6+ или нужна совместимость с .NET Framework?
3. Нужно ли поддерживать несколько экземпляров редактора одновременно?

Готов начать создавать файлы?
