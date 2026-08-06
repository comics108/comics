# Варианты архитектуры: Максимум логики в C#

> Дата: 2026-07-19
> Цель: Минимизировать переписывание C# кода, оставить логику в native

---

## Текущая ситуация

У нас есть:
- ✅ Полностью рабочий C# редактор (WPF приложение)
- ✅ Модели данных (Layer, Animation, Sound, Episode и т.д.)
- ✅ ViewModels с бизнес-логикой
- ✅ Сериализация/десериализация .comics файлов
- ✅ Формат .comics = ZIP архив с XML и ресурсами

Нужно:
- Создать Flutter UI поверх существующего C# кода
- **Минимизировать дублирование** логики на Dart
- Использовать C# как "движок"

---

## 🎯 ВАРИАНТ 1: Thin Dart Client (РЕКОМЕНДУЕМЫЙ)

### Концепция
Flutter - только **UI оболочка**. Вся логика, модели, валидация - в C#.

### Архитектура

```
┌─────────────────────────────────────────────────┐
│ FLUTTER (UI Layer)                              │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ Dart UI Widgets                          │  │
│  │ - ToolbarWidget                          │  │
│  │ - LayersPanelWidget                      │  │
│  │ - PropertiesPanelWidget                  │  │
│  │ - TimelinePanelWidget                    │  │
│  │ - CanvasWidget                           │  │
│  └──────────────────────────────────────────┘  │
│               │                                 │
│               ▼                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ Thin Dart Controller                     │  │
│  │ - Только UI state (selected layer, zoom)│  │
│  │ - Маршалинг вызовов к C#                │  │
│  │ - Подписка на события от C#             │  │
│  └──────────────────────────────────────────┘  │
│               │                                 │
│               ▼                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ Minimal Dart Models (DTOs)               │  │
│  │ - LayerDTO {id, name, x, y, ...}        │  │
│  │ - Только для передачи данных            │  │
│  │ - Без логики, без валидации             │  │
│  └──────────────────────────────────────────┘  │
│               │                                 │
│               ▼                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ FFI Bridge (очень тонкий)                │  │
│  │ - Просто маршалинг C struct ↔ Dart      │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
                 │
                 ▼ FFI calls
┌─────────────────────────────────────────────────┐
│ C FFI Layer (src/editor.c)                      │
│ - editor_create()                               │
│ - editor_load_episode(path)                     │
│ - editor_add_layer(handle, layer_json)          │
│ - editor_update_layer(handle, id, layer_json)   │
│ - editor_get_layers(handle) → JSON string       │
│ - editor_save_episode(handle, path)             │
│ - editor_undo() / editor_redo()                 │
└─────────────────────────────────────────────────┘
                 │
                 ▼ вызовы методов
┌─────────────────────────────────────────────────┐
│ C# CORE (вся логика остается здесь!)            │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ FFI Interop Wrapper (новый)              │  │
│  │ - Принимает вызовы от C FFI              │  │
│  │ - Маршалит в C# объекты                  │  │
│  │ - Возвращает JSON/структуры              │  │
│  └──────────────────────────────────────────┘  │
│               │                                 │
│               ▼                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ Существующие ViewModels                  │  │
│  │ - ComicsViewModel ✅                     │  │
│  │ - LayerViewModel ✅                      │  │
│  │ - SoundViewModel ✅                      │  │
│  │ - PuzzleViewModel ✅                     │  │
│  └──────────────────────────────────────────┘  │
│               │                                 │
│               ▼                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ Существующие Models                      │  │
│  │ - Layer.cs ✅                            │  │
│  │ - Animation.cs, Sound.cs ✅              │  │
│  │ - Comics.cs (Episode) ✅                 │  │
│  └──────────────────────────────────────────┘  │
│               │                                 │
│               ▼                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ Сериализация / Десериализация            │  │
│  │ - Чтение/запись .comics (ZIP+XML) ✅     │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### Что пишем на Dart (МИНИМУМ!)

**lib/** (~15 файлов вместо 38!)
```
lib/
├── editor.dart                      # Public API export
├── src/
│   ├── editor_widget.dart          # Canvas widget (рендеринг)
│   ├── editor_controller.dart      # UI state + FFI вызовы
│   ├── ffi_bridge.dart             # FFI маршалинг
│   └── models/                     # ТОЛЬКО DTOs!
│       ├── layer_dto.dart          # Простая структура без логики
│       ├── animation_dto.dart      # Простая структура
│       └── episode_info_dto.dart   # Метаинфо эпизода
└── editor_bindings_generated.dart
```

**example/lib/** (~20 файлов UI)
- Все UI виджеты как планировалось
- Но логика в них - только вызовы к C# через FFI

### Что добавляем в C#

**native/Comics.Editor.FFI/** (новый проект)
```csharp
// EditorFFIWrapper.cs - главная точка входа
public class EditorFFIWrapper
{
    private Dictionary<int, ComicsViewModel> _editors = new();

    [UnmanagedCallersOnly(EntryPoint = "editor_create")]
    public static int Create(int width, int height)
    {
        var editor = new ComicsViewModel();
        int handle = GenerateHandle();
        Instance._editors[handle] = editor;
        return handle;
    }

    [UnmanagedCallersOnly(EntryPoint = "editor_load_episode")]
    public static int LoadEpisode(int handle, IntPtr pathPtr)
    {
        string path = Marshal.PtrToStringUTF8(pathPtr);
        var editor = Instance._editors[handle];
        editor.Load(path);  // ✅ Используем существующий код!
        return 0;
    }

    [UnmanagedCallersOnly(EntryPoint = "editor_get_layers")]
    public static IntPtr GetLayers(int handle)
    {
        var editor = Instance._editors[handle];
        var layers = editor.Layers;  // ✅ Используем существующие данные
        string json = JsonSerializer.Serialize(layers);
        return Marshal.StringToHGlobalUTF8(json);
    }

    [UnmanagedCallersOnly(EntryPoint = "editor_add_layer")]
    public static int AddLayer(int handle, IntPtr layerJsonPtr)
    {
        string json = Marshal.PtrToStringUTF8(layerJsonPtr);
        var layerData = JsonSerializer.Deserialize<Layer>(json);
        var editor = Instance._editors[handle];
        editor.Layers.Add(layerData);  // ✅ Используем существующий код!
        return 0;
    }

    [UnmanagedCallersOnly(EntryPoint = "editor_save_episode")]
    public static int SaveEpisode(int handle, IntPtr pathPtr)
    {
        string path = Marshal.PtrToStringUTF8(pathPtr);
        var editor = Instance._editors[handle];
        editor.Save(path);  // ✅ Используем существующий код!
        return 0;
    }
}
```

### Преимущества

✅ **Минимум кода на Dart** - только UI и DTOs
✅ **Вся логика в C#** - используем существующий код
✅ **Нет дублирования** - модели, валидация, сериализация в одном месте
✅ **Проще тестировать** - C# код уже протестирован
✅ **Проще поддерживать** - одна кодовая база логики

### Недостатки

⚠️ Накладные расходы на FFI вызовы (marshal JSON)
⚠️ Нужно держать C# runtime живым
⚠️ Сложнее отладка (два процесса)

---

## 🎯 ВАРИАНТ 2: Platform View (Native WPF Embedding)

### Концепция
Встраиваем **существующий WPF Canvas** напрямую в Flutter через PlatformView.

### Архитектура

```
┌─────────────────────────────────────────────────┐
│ FLUTTER APP                                     │
│                                                 │
│  ┌─────────────────┐  ┌────────────────────┐   │
│  │ Flutter Panels  │  │ PlatformView       │   │
│  │ - Toolbar       │  │ ┌────────────────┐ │   │
│  │ - Layers List   │  │ │                │ │   │
│  │ - Properties    │  │ │  WPF Canvas    │ │   │
│  │ - Timeline      │  │ │  (C# control)  │ │   │
│  └─────────────────┘  │ │                │ │   │
│           │           │ └────────────────┘ │   │
│           │           └────────────────────┘   │
│           │                     ▲               │
│           │                     │               │
│           └─────────method──────┘               │
│                   channels                      │
└─────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│ WPF Control (существующий!)                     │
│ - EditorControl.xaml ✅                         │
│ - ComicsViewModel ✅                            │
│ - Вся логика рендеринга ✅                      │
└─────────────────────────────────────────────────┘
```

### Реализация

**Dart:**
```dart
// Используем существующий WPF контрол напрямую!
class ComicsEditorWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: 'comics_editor_view',
      onCreatePlatformView: (params) {
        return PlatformViewsService.initExpensiveAndroidView(
          id: params.id,
          viewType: 'comics_editor_view',
          layoutDirection: TextDirection.ltr,
          creationParams: {'episodePath': episodePath},
          creationParamsCodec: const StandardMessageCodec(),
        );
      },
    );
  }
}
```

**C# (Windows):**
```csharp
// Регистрируем существующий WPF контрол!
public class ComicsEditorViewFactory : PlatformViewFactory
{
    public PlatformView Create(int viewId, object args)
    {
        // Используем СУЩЕСТВУЮЩИЙ контрол!
        var control = new EditorControl();  // ✅ Уже есть в Comics.Editor!
        return new ComicsEditorPlatformView(control);
    }
}
```

### Преимущества

✅ **Вообще не переписываем код** - используем существующий WPF UI!
✅ **Вся логика и рендеринг в C#**
✅ **Минимум FFI** - только method channels для команд
✅ **Быстро реализовать** - почти нет новой работы

### Недостатки

⚠️ **Только Windows** - PlatformView с WPF работает только на Windows
⚠️ **Ограниченная кастомизация UI** - Flutter виджеты не смешиваются с WPF
⚠️ **Производительность** - может быть overhead на композитинг

---

## 🎯 ВАРИАНТ 3: C# Backend Service (HTTP/gRPC)

### Концепция
C# редактор как отдельный **backend service**, Flutter общается по HTTP/gRPC.

### Архитектура

```
┌─────────────────────────────────────────────────┐
│ FLUTTER APP                                     │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ Flutter UI (полностью на Dart)           │  │
│  └──────────────────────────────────────────┘  │
│               │                                 │
│               ▼                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ HTTP/gRPC Client                         │  │
│  │ - editor.loadEpisode(path)               │  │
│  │ - editor.getLayers()                     │  │
│  │ - editor.addLayer(layer)                 │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
                 │
                 ▼ HTTP/gRPC
┌─────────────────────────────────────────────────┐
│ C# Backend Service (ASP.NET Core)               │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ REST API Controllers                     │  │
│  │ - POST /editor/create                    │  │
│  │ - POST /editor/load                      │  │
│  │ - GET  /editor/layers                    │  │
│  │ - POST /editor/layers                    │  │
│  │ - POST /editor/save                      │  │
│  └──────────────────────────────────────────┘  │
│               │                                 │
│               ▼                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ Comics.Editor (существующий код!) ✅     │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### Преимущества

✅ **Cross-platform** - работает везде (Windows, macOS, Linux, Web!)
✅ **Легко тестировать** - обычный REST API
✅ **Вся логика в C#**
✅ **Масштабируемо** - можно несколько редакторов одновременно

### Недостатки

⚠️ **Два процесса** - нужно управлять жизненным циклом service
⚠️ **Накладные расходы** - HTTP сериализация
⚠️ **Сложнее offline** - нужен локальный сервер

---

## 🎯 ВАРИАНТ 4: Hybrid (Компромисс)

### Концепция
**Критичная UI логика** в Dart, **вся бизнес-логика** в C#.

### Разделение ответственности

**DART (Flutter):**
- Рендеринг canvas (CustomPainter)
- UI state (selected layer, zoom, pan)
- Анимация UI
- Immediate feedback для пользователя

**C# (Native):**
- Модели данных (Layer, Animation, Sound)
- Валидация
- Сериализация .comics файлов
- Undo/Redo стек
- Сложные вычисления

### Архитектура

```
DART                          C#
┌─────────────────┐          ┌──────────────────┐
│ Canvas Renderer │          │ Data Models      │
│ (CustomPaint)   │◄────────►│ (Layer, Anim)    │
└─────────────────┘   sync   └──────────────────┘

┌─────────────────┐          ┌──────────────────┐
│ UI State        │          │ Business Logic   │
│ (selected, zoom)│◄────────►│ (validation)     │
└─────────────────┘   FFI    └──────────────────┘

┌─────────────────┐          ┌──────────────────┐
│ Minimal DTOs    │          │ File I/O         │
│ (для передачи)  │◄────────►│ (.comics ZIP)    │
└─────────────────┘   JSON   └──────────────────┘
```

---

## 📊 СРАВНИТЕЛЬНАЯ ТАБЛИЦА

| Критерий | Вариант 1<br>Thin Client | Вариант 2<br>PlatformView | Вариант 3<br>HTTP Service | Вариант 4<br>Hybrid |
|----------|----------|----------|----------|----------|
| **Код на Dart** | Минимум (~15 файлов) | Минимум (~10 файлов) | Средне (~30 файлов) | Средне (~25 файлов) |
| **Переписывание C#→Dart** | 0 файлов | 0 файлов | 0 файлов | ~5 файлов (DTOs) |
| **Использование C# кода** | 100% | 100% | 100% | ~80% |
| **Cross-platform** | Win/Mac/Linux | **Только Windows** | Win/Mac/Linux/Web | Win/Mac/Linux |
| **Производительность** | Хорошая | Отличная | Средняя | Отличная |
| **Сложность реализации** | Средняя | **Низкая** | Средняя | Высокая |
| **Гибкость UI** | Высокая | Низкая | Высокая | Высокая |
| **Отладка** | Сложная | Простая | Средняя | Сложная |

---

## 🏆 РЕКОМЕНДАЦИЯ

### Для быстрого старта (MVP):
**ВАРИАНТ 2: PlatformView** (только Windows)
- Используем существующий WPF контрол напрямую
- Почти нулевая доработка
- Быстро получаем рабочий прототип

### Для production (все платформы):
**ВАРИАНТ 1: Thin Dart Client** (рекомендуемый)
- Минимум Dart кода
- Вся логика остается в C#
- Cross-platform
- Оптимальный баланс

### Если нужна максимальная производительность:
**ВАРИАНТ 4: Hybrid**
- Flutter рендерит canvas (быстро)
- C# управляет данными

---

## 📝 ДЕТАЛЬНЫЙ ПЛАН ДЛЯ ВАРИАНТА 1 (Thin Client)

### Что НЕ переписываем (остается в C#):

❌ **Модели данных** - используем существующие C# классы
❌ **ViewModels логика** - вызываем через FFI
❌ **Сериализация** - .comics файлы парсит C#
❌ **Валидация** - делает C#
❌ **Undo/Redo** - реализовано в C#

### Что пишем на Dart (МИНИМУМ):

#### lib/ (5-7 файлов!)

```
lib/
├── editor.dart                      # Экспорт API
├── src/
│   ├── editor_widget.dart          # Canvas виджет (рендеринг слоев)
│   ├── editor_controller.dart      # FFI вызовы + UI state
│   ├── ffi_bridge.dart             # Маршалинг FFI
│   └── models/                     # DTOs (только структуры!)
│       ├── layer_dto.dart          # {id, name, x, y, w, h, rotation, opacity}
│       └── episode_info_dto.dart   # {id, title, layerCount}
└── editor_bindings_generated.dart
```

**Пример layer_dto.dart:**
```dart
// НИКАКОЙ логики - только данные!
class LayerDTO {
  final String id;
  final String name;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final double opacity;

  // Только конструктор и JSON conversion
  LayerDTO.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      name = json['name'],
      // ...

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    // ...
  };
}
```

#### example/lib/ (~20 файлов UI)
- UI виджеты как планировалось
- Но вызывают методы через EditorController → FFI → C#

### Что добавляем в C#:

#### native/Comics.Editor.FFI/ (новый C# проект)

**1 файл:** EditorFFIWrapper.cs (~500 строк)

```csharp
using System.Runtime.InteropServices;
using System.Text.Json;

public class EditorFFIWrapper
{
    private static EditorFFIWrapper? _instance;
    public static EditorFFIWrapper Instance => _instance ??= new();

    private Dictionary<int, ComicsViewModel> _editors = new();
    private int _nextHandle = 1;

    // Создать редактор
    [UnmanagedCallersOnly(EntryPoint = "editor_create")]
    public static int Create(int width, int height)
    {
        var vm = new ComicsViewModel();  // ✅ Существующий код!
        int handle = Instance._nextHandle++;
        Instance._editors[handle] = vm;
        return handle;
    }

    // Загрузить эпизод из .comics файла
    [UnmanagedCallersOnly(EntryPoint = "editor_load_episode")]
    public static int LoadEpisode(int handle, IntPtr pathPtr)
    {
        string path = Marshal.PtrToStringUTF8(pathPtr);
        var vm = Instance._editors[handle];
        vm.Load(path);  // ✅ Существующий метод!
        return 0;
    }

    // Получить список слоев как JSON
    [UnmanagedCallersOnly(EntryPoint = "editor_get_layers_json")]
    public static IntPtr GetLayersJson(int handle)
    {
        var vm = Instance._editors[handle];
        string json = JsonSerializer.Serialize(vm.Layers);  // ✅ Существующие данные!
        return Marshal.StringToHGlobalUTF8(json);
    }

    // Добавить слой (получаем JSON от Dart)
    [UnmanagedCallersOnly(EntryPoint = "editor_add_layer_json")]
    public static int AddLayerJson(int handle, IntPtr jsonPtr)
    {
        string json = Marshal.PtrToStringUTF8(jsonPtr);
        var layer = JsonSerializer.Deserialize<Layer>(json);  // ✅ Существующий класс!
        var vm = Instance._editors[handle];
        vm.Layers.Add(layer);  // ✅ Существующая коллекция!
        return 0;
    }

    // Обновить слой
    [UnmanagedCallersOnly(EntryPoint = "editor_update_layer_json")]
    public static int UpdateLayerJson(int handle, IntPtr idPtr, IntPtr jsonPtr)
    {
        string id = Marshal.PtrToStringUTF8(idPtr);
        string json = Marshal.PtrToStringUTF8(jsonPtr);
        var layer = JsonSerializer.Deserialize<Layer>(json);
        var vm = Instance._editors[handle];

        var existing = vm.Layers.FirstOrDefault(l => l.Id == id);
        if (existing != null)
        {
            // ✅ Используем существующие свойства!
            existing.Name = layer.Name;
            existing.X = layer.X;
            existing.Y = layer.Y;
            // и т.д.
        }
        return 0;
    }

    // Сохранить эпизод
    [UnmanagedCallersOnly(EntryPoint = "editor_save_episode")]
    public static int SaveEpisode(int handle, IntPtr pathPtr)
    {
        string path = Marshal.PtrToStringUTF8(pathPtr);
        var vm = Instance._editors[handle];
        vm.Save(path);  // ✅ Существующий метод!
        return 0;
    }

    // Undo/Redo
    [UnmanagedCallersOnly(EntryPoint = "editor_undo")]
    public static int Undo(int handle)
    {
        var vm = Instance._editors[handle];
        vm.Undo();  // ✅ Если есть в ViewModel
        return 0;
    }

    // Освободить память для JSON строки
    [UnmanagedCallersOnly(EntryPoint = "editor_free_string")]
    public static void FreeString(IntPtr ptr)
    {
        Marshal.FreeHGlobal(ptr);
    }
}
```

**Компиляция:**
```bash
dotnet publish -c Release -r win-x64 /p:NativeLib=Shared
# Получаем Comics.Editor.FFI.dll
```

---

## 🔧 ИТОГОВАЯ СТАТИСТИКА (Вариант 1)

### Создаем:

**Dart файлы:** ~15 вместо 38!
- lib/ - 7 файлов (только DTOs и обертки)
- example/lib/ - ~20 файлов UI

**C# файлы:** 1 новый файл!
- EditorFFIWrapper.cs (~500 строк)

### НЕ переписываем:

- ❌ Layer.cs → НЕ переписываем (используем через JSON)
- ❌ Animation.cs → НЕ переписываем
- ❌ Sound.cs → НЕ переписываем
- ❌ ComicsViewModel → НЕ переписываем
- ❌ Сериализация → НЕ переписываем

### Экономия:

- **С переписыванием (было):** 38 Dart файлов + 13 моделей переписать
- **С Thin Client (стало):** 15 Dart файлов + 0 моделей переписать
- **Экономия:** ~60% кода!

---

Какой вариант предпочтительнее для вас? Могу детализировать любой из них!
