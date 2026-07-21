# Детальный список файловых операций: PlatformView подход (Puzzle)

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

Используем **существующий WPF Puzzle Control** (PuzzleControl) через PlatformView.
Flutter панели (Toolbar, Grid Settings, Pieces) общаются с WPF через Method Channels.

```
┌──────────────────────────────────────────┐
│ Flutter App                              │
│ ┌─────────────┐  ┌────────────────────┐ │
│ │Flutter UI   │  │ PlatformView       │ │
│ │- Toolbar    │  │ ┌────────────────┐ │ │
│ │- Grid       │◄─┤►│ WPF Puzzle     │ │ │
│ │- Pieces     │  │ │ (СУЩЕСТВУЕТ!)  │ │ │
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
| `lib/editor.dart` | 📝 **РЕДАКТИРОВАТЬ** | Экспорт PuzzleEditorWidget (PlatformView обертка) |
| `lib/editor_bindings_generated.dart` | ❌ **УДАЛИТЬ** | НЕ НУЖЕН - нет FFI! |

#### Новые файлы (создать):

| Файл | Операция | Описание |
|------|----------|----------|
| `lib/src/puzzle_editor_widget.dart` | ➕ **СОЗДАТЬ** | PlatformView обертка |
| `lib/src/puzzle_controller.dart` | ➕ **СОЗДАТЬ** | Контроллер для Method Channel общения |
| `lib/src/method_channel.dart` | ➕ **СОЗДАТЬ** | Method Channel константы |

**ИТОГО lib/: 4 файла**

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
| `example/lib/screens/puzzle_editor_screen.dart` | ➕ **СОЗДАТЬ** | Layout: Flutter панели + WPF puzzle canvas |

**Панели (Flutter виджеты)**
| Файл | Операция | Описание |
|------|----------|----------|
| `example/lib/widgets/toolbar/toolbar_widget.dart` | ➕ **СОЗДАТЬ** | Toolbar с кнопками (Generate, Save, etc.) |
| `example/lib/widgets/panels/grid_settings_panel.dart` | ➕ **СОЗДАТЬ** | Настройки сетки (N x M) |
| `example/lib/widgets/panels/pieces_panel.dart` | ➕ **СОЗДАТЬ** | Список кусочков пазла |

**Селекторы**
| Файл | Операция | Описание |
|------|----------|----------|
| `example/lib/widgets/dialogs/image_picker_dialog.dart` | ➕ **СОЗДАТЬ** | Выбор исходного изображения |
| `example/lib/widgets/dialogs/difficulty_selector.dart` | ➕ **СОЗДАТЬ** | Easy/Medium/Hard |

**ИТОГО example/lib/: ~7 файлов**

---

### 1.3. Конфигурационные файлы

| Файл | Операция | Комментарий |
|------|----------|-------------|
| `pubspec.yaml` | 📝 **РЕДАКТИРОВАТЬ** | name: flutter_puzzle_editor, БЕЗ ffi/ffigen! |
| `example/pubspec.yaml` | 📝 **РЕДАКТИРОВАТЬ** | Ссылка на плагин |
| `README.md` | 📝 **РЕДАКТИРОВАТЬ** | Документация PlatformView подхода |
| `CHANGELOG.md` | 📝 **РЕДАКТИРОВАТЬ** | Запись о рефакторинге |
| `analysis_options.yaml` | ✅ **ОСТАВИТЬ** | Без изменений |
| `ffigen.yaml` | ❌ **УДАЛИТЬ** | НЕ НУЖЕН |

---

## 2. NATIVE C# КОД (Windows)

### 2.1. WPF Puzzle Control (ИСПОЛЬЗУЕМ СУЩЕСТВУЮЩИЙ!)

**ВСЕ ОСТАВЛЯЕМ КАК ЕСТЬ!**

| Директория/Файл | Операция | Комментарий |
|-----------------|----------|-------------|
| `native/Comics.Editor/Controls/PuzzleControl.xaml` | ✅ **ОСТАВИТЬ** | Существующий WPF контрол для puzzle |
| `native/Comics.Editor/Controls/PuzzleControl.xaml.cs` | ✅ **ОСТАВИТЬ** | Code-behind |
| `native/Comics.Editor/ViewModel/PuzzleViewModel.cs` | ✅ **ОСТАВИТЬ** | Вся логика уже есть! |
| `native/Comics.Editor/Models/*.cs` | ✅ **ОСТАВИТЬ** | Модели данных (shared с comics) |

### 2.2. Platform Channel Handler (НОВОЕ!)

**Новый проект: native/Comics.Editor.Flutter.Puzzle/** (или расширить существующий)

| Файл | Операция | Описание |
|------|----------|----------|
| `PuzzleEditorPlatformView.cs` | ➕ **СОЗДАТЬ** | PlatformView фабрика и обработчик |
| `PuzzleMethodChannelHandler.cs` | ➕ **СОЗДАТЬ** | Обработка вызовов от Flutter (puzzle-специфичные) |

**ИТОГО C#: 2 новых файла** (или добавить в существующий проект)

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
| `windows/editor_plugin.h` | 📝 **РЕДАКТИРОВАТЬ** | Регистрация PuzzleView |
| `windows/editor_plugin.cpp` | 📝 **РЕДАКТИРОВАТЬ** | Создание PuzzleView фабрики |
| `windows/CMakeLists.txt` | 📝 **РЕДАКТИРОВАТЬ** | Линковка с C# DLL |

---

## ИТОГОВАЯ СТАТИСТИКА

### По операциям:

| Операция | Количество | Детали |
|----------|-----------|--------|
| ✅ **ОСТАВИТЬ БЕЗ ИЗМЕНЕНИЙ** | ~200+ файлов | Весь C# WPF код (shared с comics) |
| 📝 **РЕДАКТИРОВАТЬ** | 6 файлов | pubspec.yaml, README, plugin.cpp, editor.dart |
| ➕ **СОЗДАТЬ НОВЫЕ** | ~9 файлов | 4 Dart (lib) + 2 C# + 3 Dart (example UI) |
| ❌ **УДАЛИТЬ** | 3 файла | FFI слой |
| 🔁 **ПЕРЕПИСАТЬ C# → Dart** | **0 файлов** | НЕТ! |

---

## ДЕТАЛЬНЫЕ СПИСКИ ФАЙЛОВ

### Dart файлы (lib/) - СОЗДАТЬ

#### 1. lib/editor.dart
```dart
library flutter_puzzle_editor;

export 'src/puzzle_editor_widget.dart';
export 'src/puzzle_controller.dart';
```

#### 2. lib/src/puzzle_editor_widget.dart (➕ СОЗДАТЬ ~100 строк)
```dart
/// PlatformView обертка над WPF PuzzleControl
class PuzzleEditorWidget extends StatefulWidget {
  final PuzzleController controller;

  const PuzzleEditorWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return PlatformViewLink(
        viewType: 'puzzle_editor_view',
        // ... аналогично comics
      );
    }

    return Center(
      child: Text('Puzzle Editor поддерживается только на Windows'),
    );
  }
}
```

#### 3. lib/src/puzzle_controller.dart (➕ СОЗДАТЬ ~150 строк)
```dart
/// Контроллер для управления WPF puzzle редактором
class PuzzleController {
  MethodChannel? _channel;

  // Генерировать пазл из изображения
  Future<void> generateFromImage(String imagePath, int rows, int cols) async {
    await _channel?.invokeMethod('generateFromImage', {
      'imagePath': imagePath,
      'rows': rows,
      'cols': cols,
    });
  }

  // Установить сетку
  Future<void> setGrid(int rows, int cols) async {
    await _channel?.invokeMethod('setGrid', {
      'rows': rows,
      'cols': cols,
    });
  }

  // Получить кусочки
  Future<List<Map<String, dynamic>>> getPieces() async {
    final result = await _channel?.invokeMethod('getPieces');
    return List<Map<String, dynamic>>.from(result ?? []);
  }

  // Сохранить пазл
  Future<void> savePuzzle(String path) async {
    await _channel?.invokeMethod('savePuzzle', {'path': path});
  }

  // Загрузить пазл
  Future<void> loadPuzzle(String path) async {
    await _channel?.invokeMethod('loadPuzzle', {'path': path});
  }
}
```

---

### C# файлы - СОЗДАТЬ

#### 1. PuzzleEditorPlatformView.cs (➕ СОЗДАТЬ ~200 строк)
```csharp
namespace Comics.Editor.Flutter
{
    public class PuzzleEditorViewFactory : PlatformViewFactory
    {
        // ... аналогично ComicsEditorViewFactory
    }

    public class PuzzleEditorPlatformView : PlatformView
    {
        private readonly UserControl _control;
        private readonly PuzzleViewModel _viewModel;
        private readonly PuzzleMethodChannelHandler _methodHandler;

        public PuzzleEditorPlatformView(int viewId, FlutterEngine engine)
        {
            // ✅ ИСПОЛЬЗУЕМ СУЩЕСТВУЮЩИЙ WPF КОНТРОЛ!
            _control = new PuzzleControl();

            // ✅ ИСПОЛЬЗУЕМ СУЩЕСТВУЮЩИЙ ViewModel!
            _viewModel = new PuzzleViewModel();
            _control.DataContext = _viewModel;

            var channelName = $"puzzle_editor_{viewId}";
            _methodHandler = new PuzzleMethodChannelHandler(
                engine.BinaryMessenger,
                channelName,
                _viewModel
            );
        }

        public override UIElement GetView() => _control;
    }
}
```

#### 2. PuzzleMethodChannelHandler.cs (➕ СОЗДАТЬ ~250 строк)
```csharp
namespace Comics.Editor.Flutter
{
    public class PuzzleMethodChannelHandler : IDisposable
    {
        private readonly MethodChannel _channel;
        private readonly PuzzleViewModel _viewModel;

        private void OnMethodCall(MethodCall call, MethodResult result)
        {
            switch (call.Method)
            {
                case "generateFromImage":
                    GenerateFromImage(call, result);
                    break;

                case "setGrid":
                    SetGrid(call, result);
                    break;

                case "getPieces":
                    GetPieces(result);
                    break;

                case "savePuzzle":
                    SavePuzzle(call, result);
                    break;

                case "loadPuzzle":
                    LoadPuzzle(call, result);
                    break;

                default:
                    result.NotImplemented();
                    break;
            }
        }

        private void GenerateFromImage(MethodCall call, MethodResult result)
        {
            var imagePath = call.Argument<string>("imagePath");
            var rows = call.Argument<int>("rows");
            var cols = call.Argument<int>("cols");

            // ✅ Вызываем существующий метод PuzzleViewModel!
            _viewModel.GeneratePuzzle(imagePath, rows, cols);
            result.Success(null);
        }

        private void SetGrid(MethodCall call, MethodResult result)
        {
            var rows = call.Argument<int>("rows");
            var cols = call.Argument<int>("cols");

            _viewModel.Rows = rows;
            _viewModel.Cols = cols;
            result.Success(null);
        }

        private void GetPieces(MethodResult result)
        {
            // ✅ Используем существующие данные!
            var pieces = _viewModel.Pieces
                .Select(p => new Dictionary<string, object>
                {
                    ["id"] = p.Id,
                    ["row"] = p.Row,
                    ["col"] = p.Col,
                    ["x"] = p.X,
                    ["y"] = p.Y,
                    // ...
                })
                .ToList();

            result.Success(pieces);
        }

        private void SavePuzzle(MethodCall call, MethodResult result)
        {
            var path = call.Argument<string>("path");
            _viewModel.Save(path);  // ✅ Существующий метод!
            result.Success(null);
        }

        private void LoadPuzzle(MethodCall call, MethodResult result)
        {
            var path = call.Argument<string>("path");
            _viewModel.Load(path);  // ✅ Существующий метод!
            result.Success(null);
        }
    }
}
```

---

## ПРИОРИТЕТ РЕАЛИЗАЦИИ

### Фаза 1: Базовая структура (0.5 дня)
1. ✅ Расширить C# проект или создать новый
2. ✅ Создать Dart файлы lib/
3. ✅ Обновить pubspec.yaml

### Фаза 2: C# PlatformView (1 день)
1. ✅ PuzzleEditorPlatformView.cs
2. ✅ PuzzleMethodChannelHandler.cs
3. ✅ Тестирование связи

### Фаза 3: Flutter UI (2 дня)
1. ✅ PuzzleEditorScreen layout
2. ✅ Grid settings panel
3. ✅ Pieces panel
4. ✅ Generate from image

### Фаза 4: Интеграция (0.5 дня)
1. ✅ Связать панели с WPF
2. ✅ Тестирование

**ИТОГО: ~4 рабочих дня** (меньше чем comics, т.к. проще!)

---

## ЧТО НЕ ПЕРЕПИСЫВАЕМ

- ❌ PuzzleViewModel → НЕ переписываем
- ❌ PuzzleControl.xaml → НЕ переписываем
- ❌ Логика генерации пазла → НЕ переписываем
- ❌ Любая бизнес-логика → НЕ переписываем

### ИТОГО: 0 файлов C# → Dart!

---

## ОГРАНИЧЕНИЯ

⚠️ **Только Windows**
⚠️ **Shared с comics** - изменения в native/Comics.Editor/ влияют на оба плагина

---

## ПРЕИМУЩЕСТВА

✅ **Быстро** - 4 дня
✅ **Используем 100% C# кода**
✅ **Меньше кода чем comics** (puzzle проще)

---

Готов начать реализацию?
