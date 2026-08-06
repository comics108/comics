# Specifications: comics-editor-v2.9-fixes2 — четыре независимых доработки

> Version: 1.1
> Status: APPROVED
> Last Updated: 2026-07-25
> Requirements: [01-requirements.md](01-requirements.md) (APPROVED)

## Overview

Четыре независимые спецификации (A/B/C/D), каждая — отдельный раздел ниже. Общей архитектуры между ними нет (разные подсистемы), поэтому не используется единый Component Diagram/Data Flow для всего документа — каждый раздел самодостаточен.

---

## A. Windows hostfxr/nethost interop

### Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `windows/editor_plugin/editor_plugin.cpp`/`.h` | Modify | Добавляется hostfxr-bootstrap и реальный вызов вместо `not_implemented` |
| `windows/editor_plugin/CMakeLists.txt` | Modify | Custom target `editor_plugin_csharp` раскомментируется; добавляется post-build копирование в `runner/Release/` |
| `native/Comics.Editor.Flutter/NativeExports.cs` | Create | Новый `[UnmanagedCallersOnly]`-экспорт — точка входа для hostfxr |
| `lib/src/bridge/wpf_editor_view.dart` | Modify | Добавляется вызов `dispose` при уничтожении виджета (сейчас отсутствует) |

### Два обнаруженных на этапе Specifications пробела (не были в Requirements)

1. **Нет копирования опубликованной сборки в упакованное приложение.** CMake custom target публикует `Comics.Editor.Flutter.dll`/`.runtimeconfig.json`/зависимости в `build/windows/x64/dotnet/` — это дерево СБОРКИ (build tree), соседнее с `runner/`, а не внутри `build/windows/x64/runner/Release/`, которое реально упаковывается (`upload-artifact` в `build.yml` берёт только `runner/Release/`). Без дополнительного шага копирования hostfxr на реальной машине пользователя не найдёт `Comics.Editor.Flutter.dll` рядом с `comics_editor.exe`. **Требуется**: `add_custom_command(TARGET ${BINARY_NAME} POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_BINARY_DIR}/dotnet" "$<TARGET_FILE_DIR:${BINARY_NAME}>/dotnet")` в `windows/runner/CMakeLists.txt` (после `add_dependencies(${BINARY_NAME} flutter_assemble)`).
2. **Dart-сторона никогда не вызывает `dispose`.** `WpfEditorView`/`_WpfEditorViewState` в `wpf_editor_view.dart` вызывает `channel.invokeMethod('create')` в `initState()`, но не переопределяет `State.dispose()` для вызова `channel.invokeMethod('dispose')`. Без этого AC A.2 («`dispose` вызывается корректно») недостижим через реальный UI-путь — только прямым вызовом канала в тесте. **Требуется**: переопределить `dispose()` в `_WpfEditorViewState`, fire-and-forget `WpfEditorView.channel.invokeMethod<void>('dispose')` (без `await`, т.к. `State.dispose()` синхронный).

### Architecture — Data Flow

```
Flutter (Dart)                C++ (editor_plugin)                    .NET (Comics.Editor.Flutter)
─────────────────              ────────────────────                    ─────────────────────────────
MethodChannel                  EditorPlugin::HandleMethodCall
  .invokeMethod('create')  →     method_name() == "create"
                                  → EnsureHostInitialized()  (once, lazy)
                                     - resolve hostfxr.dll path
                                     - hostfxr_initialize_for_runtime_config(
                                         "<exe_dir>/dotnet/Comics.Editor.Flutter.runtimeconfig.json")
                                     - hostfxr_get_runtime_delegate(hdt_load_assembly_and_get_function_pointer)
                                     - load_assembly_and_get_function_pointer(
                                         "<exe_dir>/dotnet/Comics.Editor.Flutter.dll",
                                         "Comics.Editor.Flutter.NativeExports, Comics.Editor.Flutter",
                                         "HandleMethodCall", UNMANAGEDCALLERSONLY_METHOD)
                                       → handle_method_call_fn (кэшируется после первого вызова)
                                  → handle_method_call_fn(L"create", nullptr)
                                                                          → NativeExports.HandleMethodCall(IntPtr, IntPtr)
                                                                             → MethodChannelHandler.HandleMethodCall("create", null)
                                                                                → EditorHost.ShowMainWindow()
                                                                                → returns JSON string
                                                                             → Marshal.StringToHGlobalUni(json) → IntPtr
                                  ← char16_t* (owned by C#, must be freed)
                                  → result->Success() или result->Error() по содержимому JSON
                                  → handle_method_call_fn возвращает управление,
                                    C++ вызывает free_result_string_fn(ptr)
result (Success/Error)     ←
```

### Interfaces

**Новый C#-экспорт** (`native/Comics.Editor.Flutter/NativeExports.cs`):

```csharp
using System.Runtime.InteropServices;

namespace Comics.Editor.Flutter;

/// <summary>
/// Точка входа для hostfxr/nethost (вызывается из C++, windows/editor_plugin).
/// Строки — UTF-16 (char16_t* на стороне C++, соответствует .NET string ABI
/// напрямую, без доп. перекодирования).
/// </summary>
public static class NativeExports
{
    [UnmanagedCallersOnly(EntryPoint = "HandleMethodCall")]
    public static IntPtr HandleMethodCall(IntPtr methodPtr, IntPtr argsJsonPtr)
    {
        string method = Marshal.PtrToStringUni(methodPtr) ?? string.Empty;
        string? argsJson = argsJsonPtr == IntPtr.Zero ? null : Marshal.PtrToStringUni(argsJsonPtr);
        string result;
        try
        {
            result = MethodChannelHandler.HandleMethodCall(method, argsJson);
        }
        catch (Exception ex)
        {
            // MethodChannelHandler уже ловит свои исключения и сериализует как
            // {"error": ..., "message": ...} — этот catch страхует от исключений
            // ВНЕ try/catch там (не должно происходить, но пересечение managed/native
            // границы необработанным исключением — падение всего процесса).
            result = $"{{\"error\":\"{ex.GetType().Name}\",\"message\":\"unmanaged boundary: {ex.Message}\"}}";
        }
        return Marshal.StringToHGlobalUni(result);
    }

    [UnmanagedCallersOnly(EntryPoint = "FreeResultString")]
    public static void FreeResultString(IntPtr ptr)
    {
        if (ptr != IntPtr.Zero) Marshal.FreeHGlobal(ptr);
    }
}
```

**C++ hostfxr bootstrap** (новый файл `windows/editor_plugin/hostfxr_bootstrap.cpp`/`.h`, отдельно от `editor_plugin.cpp` — держит .NET-хостинг изолированным от Flutter plugin API):

```cpp
// Резолвинг hostfxr.dll без NuGet-пакета Microsoft.NETCore.DotNetAppHost —
// вручную, по тому же принципу, что использует dotnet-install.ps1/CI:
// DOTNET_ROOT (или "C:\Program Files\dotnet" по умолчанию) →
// host\fxr\<самая новая версия>\hostfxr.dll. Свои typedef'ы для нужных
// hostfxr-функций объявляются здесь же (стабильный, документированный ABI
// hostfxr.h) — не тянем весь официальный заголовок ради трёх функций.

bool ResolveHostFxrPath(std::wstring& outPath);

// Ленивая инициализация + кэш function pointer'ов. Возвращает false и
// заполняет outError, если что-то пошло не так на любом из шагов (dll не
// найдена, runtimeconfig.json не найден, get_function_pointer вернул код
// ошибки) — HandleMethodCall в этом случае возвращает
// result->Error("interop_init_failed", outError) вместо падения.
bool EnsureHostInitialized(std::wstring& outError);

// Тонкие обёртки поверх закэшированных function pointer'ов.
std::wstring CallHandleMethodCall(const std::wstring& method, const std::wstring* argsJson);
```

### Data Models

Без новых персистентных структур — JSON-контракт между C++ и C# идентичен уже существующему протоколу `MethodChannelHandler.HandleMethodCall(string method, string? argumentsJson) -> string` (JSON с `success`/`error`+`message`).

**Ограничение области (осознанно, см. Won't Have ниже)**: методы `create`/`dispose`, единственные два, которые сейчас реально вызываются с Dart-стороны (`wpf_editor_view.dart`), вызываются БЕЗ аргументов (`invokeMethod<void>('create')` — второй параметр не передаётся). Поэтому C++-сторона в этой итерации не реализует полную сериализацию произвольного `flutter::EncodableValue` → JSON (это отдельная, более крупная задача — потребовался бы JSON-энкодер на C++, которого сейчас нет в `editor_plugin`); передаётся `nullptr`/`argsJsonPtr == 0`, если `method_call.arguments()` — null (текущий единственный кейс). Если/когда появится вызов с реальными аргументами — это Won't Have, фиксируется отдельно.

### Behavior Specifications

#### Happy Path

1. Flutter вызывает `invokeMethod('create')`.
2. `EditorPlugin::HandleMethodCall` видит `method_name() == "create"`, вызывает `EnsureHostInitialized()` (на первый раз — резолвит hostfxr, инициализирует runtime, получает delegate; на последующие — no-op, использует кэш).
3. `CallHandleMethodCall(L"create", nullptr)` → C# `NativeExports.HandleMethodCall` → `MethodChannelHandler.HandleMethodCall("create", null)` → `EditorHost.ShowMainWindow()` (создаёт STA-поток при первом вызове, дальше — переиспользует) → возвращает `{"success":true}`.
4. C++ парсит JSON-результат ровно так же, как раньше (`result->Success()`/`result->Error()` — логика парсинга уже должна быть в `HandleMethodCall`, т.к. предыдущая заглушка сразу звала `result->Error(...)`; теперь нужно добавить парсинг реального JSON от C#, минимальный — проверка ключа `"error"`).
5. Free результата: `FreeResultString(ptr)`.

#### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|--------------------|
| .NET 10 runtime не установлен на машине пользователя | Windows-десктоп без .NET | `EnsureHostInitialized` не находит hostfxr.dll/runtime → `HandleMethodCall` возвращает `result->Error("interop_init_failed", ...)`, Dart-сторона ловит `PlatformException` (уже обрабатывается в `wpf_editor_view.dart` — остаётся заглушка) |
| Повторный вызов `create` при уже показанном окне | Пользователь дважды жмёт «Открыть редактор» | `EditorHost.ShowMainWindow()` уже идемпотентен (проверяет `_dispatcher != null`, делает `Show()`/`Activate()` на существующем окне) — поведение не меняется |
| `dispose` вызывается до успешной инициализации хоста (`create` так и не вызывался или упал) | Виджет уничтожается сразу после неудачного `_probeNative()` | `CallHandleMethodCall` должен проверять, что хост инициализирован, прежде чем пытаться получить delegate для `dispose` — если нет, тихо no-op (не пытаться повторно инициализировать хост только чтобы тут же его остановить) |
| Приложение закрывается (весь процесс) без явного `dispose` | Пользователь закрывает всё Flutter-приложение | WPF-поток — `IsBackground = true` (см. `EditorHost.cs:54`), значит не блокирует завершение процесса — жёсткое завершение приемлемо, отдельной обработки не требуется |

### Testing Strategy

- **Manual verification (обязательно, т.к. агент не может собрать/запустить Windows-приложение)**: реальный Windows CI-прогон (`build-windows`) — зелёный, ПЛЮС (по возможности) ручная проверка пользователем на реальной машине: открыть редактор, увидеть WPF-окно v2.8, закрыть Flutter-приложение — без падений.
- **Unit/integration тесты на Dart-стороне**: `wpf_editor_view.dart` — тест на то, что `dispose()` виджета вызывает `channel.invokeMethod('dispose')` (через мок method channel — существующий паттерн, если в `test/` есть подобные моки для других каналов — проверить на этапе Plan).
- Нет способа юнит-тестировать C++/hostfxr-код в этом окружении (агент — macOS) — полагаемся на реальный CI.

### Won't Have (this spec)

- Полная сериализация произвольных `flutter::EncodableValue` аргументов в JSON на C++-стороне (см. Data Models выше) — только null-passthrough для текущих `create`/`dispose`.
- Embedded PlatformView (см. Requirements Won't Have) — WPF-окно остаётся отдельным top-level окном.

---

## B. Linux headless CI-краш на `ping`

### Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `.github/workflows/build.yml` (`build-linux`) / `docker-build.yml` | Возможно Modify | В зависимости от находки |
| `native/Comics.Editor.Headless`/`lib/src/bridge/core_client.dart` | Возможно Modify | В зависимости от находки |

### Подход: диагностика ДО дизайна фикса (не гадать)

В отличие от A/C/D, здесь нет известного дизайна решения — есть неподтверждённая причина. Спецификация фикса **намеренно не пишется заранее**; вместо неё — протокол расследования:

1. **Шаг 1 (без изменений кода)**: запустить `build-linux` (или `tool/docker-build.sh linux` — доступен и локально через Rosetta-эмуляцию `linux/amd64`, см. `sdd-comics-editor-build`) и посмотреть РЕАЛЬНОЕ содержимое `CoreException` (stderr + exit code, диагностика уже улучшена в `sdd-comics-editor-v2.9-android-ios`) — этого никто не делал/не задокументировал с реальным выводом.
2. **Шаг 2**: по содержимому stderr — сузить до одной из кандидат-гипотез (ранжированы по правдоподобности):
   - **Несовпадение glibc/musl** между образом, где собирался self-contained `linux-x64` апphost, и образом, где он запускается — самая частая причина «process exited immediately» для self-contained .NET на Linux.
   - Гонка старта процесса: `CoreClient` (Dart, `Process.start`) отправляет `ping` до того, как self-contained apphost полностью проинициализировался (нет ожидания готовности/health-check перед первым запросом).
   - Отсутствие исполняемых прав (`chmod +x`) на бинарнике после `actions/upload-artifact`/`download-artifact` или после `dotnet publish` в конкретной последовательности шагов CI.
   - Проблема, специфичная именно для `flutter test`-раннера (изоляция процесса/sandboxing в самом Flutter test harness), а не для процесса ядра как такового.
3. **Шаг 3**: спроектировать минимальный фикс под подтверждённую причину — оформляется в этом же документе ПОСЛЕ шага 1/2 (правка specs, не отдельная итерация SDD, если пользователь не потребует иного).

### Testing Strategy

- **Integration test**: `test/core_client_test.dart` (уже существует) — критерий успеха: проходит на реальном GH Actions `ubuntu-latest`.
- Разница с уже закрытым багом `resolveBinary()` (`sdd-comics-editor-v2.9-fixes1`) — явно фиксируется в implementation-log при подтверждении причины (см. AC B.2 в Requirements).

### Open Design Questions

- [ ] Ждём результата реального CI-прогона (Шаг 1) — design фикса невозможен раньше.

---

## C. `// TODO remove convert functionality`

### Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `native/Comics.Editor/ViewModel/ComicsViewModel.cs` | Modify (комментарий) | Логика не меняется — см. Requirements, решение «оставить» |

### Behavior Specifications

Чисто документирующая правка, логики не меняет. Новый комментарий вместо TODO:

```csharp
// Прогоняет каждое изображение документа через текущую логику тайлинга/
// пересчёта размеров (FileManager.UpdateTiles), копируя файл через временную
// папку и вызывая Image.Update(...) — тот же метод, что обычная замена файла
// изображения. Доступно пользователю через кнопку «Convert» в Settings
// (Controls/SettingsControl.xaml, ConvertCommand). Возможный сценарий
// использования — принудительная перенормализация изображений документа,
// созданного/отредактированного в другой версии редактора. Оставлено по
// решению пользователя (sdd-comics-editor-v2.9-fixes2, 2026-07-25) —
// происхождение исходного TODO не установлено (git-история репозитория
// начинается с единого squash-коммита переноса v2.8).
public void Convert()
{
    ...
}
```

Никаких Edge Cases/Testing Strategy сверх существующих (`dotnet build native/Comics.slnx` остаётся чистым) — это правка ровно одного блока комментариев.

---

## D. Undo/Redo

### Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `lib/src/ui/edit_history.dart` | Create | Новый класс `EditHistory` — стек снапшотов |
| `lib/src/ui/controller.dart` | Modify | `EditorController` держит `EditHistory`, оборачивает мутаторы транзакциями, добавляет `undo()`/`redo()`/`canUndo`/`canRedo` |
| `lib/src/ui/widgets/canvas_view.dart` | Modify | `onPanStart`/`onPanEnd` у drag-жеста слоя — явные границы транзакции истории |
| `lib/src/ui/widgets/top_bar.dart` (или аналог toolbar) | Modify | Кнопки Undo/Redo (Should Have) |
| Корневой виджет редактора (уточнить конкретный файл на Plan) | Modify | `Shortcuts`/`Actions` для Ctrl+Z/Ctrl+Shift+Z |

### Architecture

```
UI-жест/действие
  │
  ▼
EditorController.<mutator>()          (addLayer/deleteSelected/dragSelected/...)
  │  оборачивается транзакцией истории:
  │
  ├─ дискретная мутация (одиночный вызов, напр. addLayer):
  │     history.beginTransaction(coreDoc!)   // снапшот ДО
  │     <мутация doc>
  │     history.commitTransaction()          // кладёт снапшот в undo-стек, чистит redo-стек
  │     notifyListeners()
  │
  └─ continuous-жест (напр. drag слоя, много вызовов dragSelected подряд):
        canvas_view.dart: onPanStart → history.beginTransaction(coreDoc!)
                          onPanUpdate → controller.dragSelected(delta) (многократно, БЕЗ begin/commit)
                          onPanEnd   → history.commitTransaction()

EditorController.undo():
  snapshot = history.undo(currentSnapshot: comicsToCore(coreDoc!))
  if snapshot != null:
    coreDoc = comicsFromCore(snapshot, coreDoc!.path)
    doc = coreDoc!.doc
    _clearSelection()   // индексы слоёв/звуков могли не совпасть с новым состоянием
    notifyListeners()

EditorController.redo(): симметрично, из redo-стека.
```

### Interfaces

**Новый файл** `lib/src/ui/edit_history.dart`:

```dart
/// Стек истории отмены/повтора — снапшоты JSON-представления документа
/// (через [comicsToCore]/[comicsFromCore]). Живёт в рамках открытого
/// документа, не переживает newDoc()/openRecent() (см. Behavior Specifications).
class EditHistory {
  final List<Map<String, dynamic>> _undoStack = [];
  final List<Map<String, dynamic>> _redoStack = [];
  Map<String, dynamic>? _pending; // снапшот, взятый в beginTransaction()

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Вызывать ДО мутации. [snapshot] — результат comicsToCore(coreDoc!)
  /// на момент вызова (т.е. состояние ДО предстоящей мутации).
  void beginTransaction(Map<String, dynamic> snapshot) {
    _pending = snapshot;
  }

  /// Вызывать ПОСЛЕ мутации (или после серии мутаций одного жеста).
  /// No-op, если beginTransaction не вызывался.
  void commitTransaction() {
    if (_pending == null) return;
    _undoStack.add(_pending!);
    _redoStack.clear();
    _pending = null;
  }

  /// [currentSnapshot] — состояние ДО отмены (кладётся в redo-стек).
  /// Возвращает снапшот, на который нужно откатиться, или null, если
  /// стек пуст.
  Map<String, dynamic>? undo(Map<String, dynamic> currentSnapshot) {
    if (_undoStack.isEmpty) return null;
    _redoStack.add(currentSnapshot);
    return _undoStack.removeLast();
  }

  Map<String, dynamic>? redo(Map<String, dynamic> currentSnapshot) {
    if (_redoStack.isEmpty) return null;
    _undoStack.add(currentSnapshot);
    return _redoStack.removeLast();
  }

  /// Вызывать при открытии нового документа (newDoc/openRecent) — история
  /// одного документа не должна протекать в другой.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _pending = null;
  }
}
```

**`EditorController` — новые/изменённые члены**:

```dart
final EditHistory _history = EditHistory();
bool get canUndo => _history.canUndo;
bool get canRedo => _history.canRedo;

void undo() {
  final doc0 = coreDoc;
  if (doc0 == null) return;
  final snapshot = _history.undo(comicsToCore(doc0));
  if (snapshot == null) return;
  coreDoc = comicsFromCore(snapshot, doc0.path);
  doc = coreDoc!.doc;
  _clearSelection();
  notifyListeners();
}

void redo() { /* симметрично */ }

// Приватный хелпер для дискретных мутаторов — оборачивает существующее
// тело метода без изменения его сигнатуры извне.
void _withHistory(void Function() mutate) {
  final d = coreDoc;
  if (d != null) _history.beginTransaction(comicsToCore(d));
  mutate();
  _history.commitTransaction();
  notifyListeners();
}
```

Каждый из ~15 существующих мутаторов (`addLayer`, `moveLayer`, `deleteSelected`, `toggleVisible`, `setImageFile`, `addSound`, `moveSound`, `addAnim`, `deleteAnim`, `editAnim`, `setCanvasSize`, `setLanguage`, `setImagePopup`, и т.д. — но НЕ `dragSelected`, см. ниже) переписывается так, чтобы тело мутации оборачивалось `_withHistory(() { ... })` вместо самостоятельного финального `notifyListeners()`.

**`dragSelected` — особый случай** (continuous-жест, НЕ оборачивается `_withHistory` сам по себе):

```dart
// Публичные методы транзакции — вызываются из canvas_view.dart вокруг
// всего жеста, а не из самого dragSelected (который вызывается многократно
// за один жест).
void beginGestureHistory() {
  final d = coreDoc;
  if (d != null) _history.beginTransaction(comicsToCore(d));
}

void commitGestureHistory() {
  _history.commitTransaction();
}

void dragSelected(Offset delta) {
  // тело без изменений — drag и так обновляет UI на каждый кадр через
  // notifyListeners(); история же коммитится отдельно в commitGestureHistory().
  ...
  notifyListeners();
}
```

**`canvas_view.dart`** (drag слоя, строка ~148):

```dart
onPanStart: (_) {
  c.selectLayer(i);
  c.beginGestureHistory();
},
onPanUpdate: (d) {
  c.dragSelected(Offset(d.delta.dx / (k * vz), d.delta.dy / (k * vz)));
},
onPanEnd: (_) => c.commitGestureHistory(),
```

**Клавиатурные сочетания** — `Shortcuts`/`Actions` (НЕ raw `HardwareKeyboard`/`RawKeyboardListener` на корне дерева): стандартный механизм Flutter уже разруливает конфликт с встроенным text-undo в фокусированных `TextField` (Flutter's `EditableText` сам регистрирует свои Actions для Ctrl+Z ближе к фокусу — они и выигрывают, пока наш `Shortcuts` находится выше по дереву, не перехватывает события напрямую в обход системы фокуса/действий). Конкретное место обёртки (корневой Scaffold редактора) — уточняется на Plan после осмотра структуры виджетов верхнего уровня.

```dart
Shortcuts(
  shortcuts: {
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): const UndoIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyZ): const RedoIntent(),
  },
  child: Actions(
    actions: {
      UndoIntent: CallbackAction<UndoIntent>(onInvoke: (_) => controller.undo()),
      RedoIntent: CallbackAction<RedoIntent>(onInvoke: (_) => controller.redo()),
    },
    child: /* существующее поддерево редактора */,
  ),
)
```

### Data Models

Нет новых персистентных структур. `EditHistory` хранит `List<Map<String, dynamic>>` (сырые JSON-снапшоты, тот же формат, что уже используется для сохранения `.comics`/`.puzzle` файлов) — только в памяти, не сериализуется на диск (см. Won't Have в Requirements — история не переживает сессию).

### Behavior Specifications

#### Happy Path

1. Пользователь открывает документ → `EditorController` — синглтон на весь app lifecycle (подтверждено пользователем, 2026-07-25), поэтому `EditHistory.clear()` вызывается явно в начале `newDoc()` и `openRecent()` (иначе история предыдущего документа протечёт в новый — см. Edge Cases).
2. Пользователь добавляет слой (`addLayer`, дискретная мутация) → `_withHistory` снимает снапшот ДО, мутирует, коммитит.
3. Ctrl+Z → `controller.undo()` → документ возвращается к состоянию без нового слоя, `canRedo == true`.
4. Ctrl+Shift+Z → слой возвращается.

#### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|--------------------|
| Undo при пустом undo-стеке | Ctrl+Z сразу после открытия документа, до любых правок | No-op (`_history.undo()` возвращает `null`, `EditorController.undo()` рано возвращается) |
| Новая мутация после нескольких Undo | Undo×2, затем `addLayer()` | Redo-стек очищается (`commitTransaction()` вызывает `_redoStack.clear()`) — стандартное поведение undo/redo |
| `newDoc()`/`openRecent()` во время непустой истории | Открыть другой документ, не закрыв текущий | `EditHistory.clear()` должен вызываться в начале `newDoc()`/`openRecent()` — иначе Undo после переключения документа откатит ЧУЖОЙ документ на JSON от предыдущего |
| Drag с нулевым перемещением (клик без реального drag) | `onPanStart`→`onPanEnd` без `onPanUpdate` между ними | Получится избыточная запись в истории, идентичная текущему состоянию — Undo на неё no-op с точки зрения пользователя. Не критично (см. Open Design Questions) |
| Undo во время preview-режима (`togglePreview()`) | Открытый вопрос из Requirements | **Остаётся открытым вопросом** (см. ниже) |
| Снапшот не является полностью независимой копией | Гипотетический баг в `comicsToCore`/`_mergeLayer`/`_mergeSound`/`_animToJson` | Все проверенные пути (`_mergeLayer`, `_mergeImage`, `_mergeSound`) пересобирают вложенные `Map`/`List` заново (не переиспользуют объекты из `document.raw`) — похоже на безопасный полный снапшот, но **требует явной проверки на этапе Implementation** (напр. unit-тест: снять снапшот, замутировать `doc`, убедиться что снапшот не изменился) |

### Testing Strategy

- **Unit tests** (`test/`, новый файл `test/edit_history_test.dart`): `EditHistory` в изоляции — begin/commit/undo/redo, пустые стеки, редо-стек чистится после новой транзакции.
- **Integration test**: через `EditorController` — `addLayer()` → `undo()` → проверить `doc.layers.isEmpty`; `redo()` → проверить слой вернулся.
- **Manual verification**: Ctrl+Z/Ctrl+Shift+Z в реальном UI — добавление/удаление/перемещение слоя, drag (один шаг истории на весь жест, не на каждый кадр), поведение кнопок Undo/Redo (disabled при пустых стеках).

### Open Design Questions

Решено пользователем (2026-07-25):
- [x] `EditorController` — синглтон на весь app lifecycle. `EditHistory.clear()` вызывается в `newDoc()`/`openRecent()`.

Остаётся открытым (не блокирует Plan/Implementation, можно решить по ходу):
- [ ] Undo доступен во время preview-режима, или заблокирован (кнопки/шорткаты неактивны), пока `togglePreview()` включён? (Перенесено из Requirements, не решено.)
- [ ] Пропускать ли commit транзакции истории, если снапшот до/после идентичен (no-op жест/клик)? Предложение: не усложнять в первой итерации, пересмотреть только если пользователь сочтёт это раздражающим на верификации.

---

## Approval

- [ ] Reviewed by: Anton
- [ ] Approved on:
- [ ] Notes:
