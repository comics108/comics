# Specifications: comics-editor-v2.9 — Flutter-обвязка для существующего C# редактора

> Version: 1.1
> Status: APPROVED
> Last Updated: 2026-07-23
> Requirements: [01-requirements.md](01-requirements.md) (APPROVED)

## Overview

`apps/comics-editor-v2.9` реструктурируется в Flutter-приложение (Windows/macOS/Linux). Существующий C#-код **перемещается** в подпапку `native/` без переписывания; поверх него добавляется обвязка:

- **Этап 1 (Windows)**: WPF-редактор целиком встраивается в Flutter через PlatformView (архитектура заимствуется из `libs/comics_editor/flutter_comics_editor`). Фактическая сборка/проверка — на Windows-машине (на macOS готовим всё до упора, сборку пропускаем — решение пользователя).
- **Этап 2 (macOS/Linux)**: Flutter-UI из `design/comics-editor-maket-dart-v3` + headless C#-ядро на .NET 10 (отдельный процесс, JSON поверх stdin/stdout), переиспользующее не-UI исходники как есть.

**Ключевой факт из анализа кода**: `Comics.Editor` (WPF) **не ссылается** на `Comics.Core` — вся логика файлов комиксов (Models, `FileManager`, `ZipUtils`, `IWS/Utils`) живёт внутри `Comics.Editor`. `Comics.Core` (EF6, PushSharp, DAL) — серверная часть, редактором не используется. Поэтому:

- для этапа 1 достаточно собрать `Comics.Editor` под `net10.0-windows`;
- headless-ядро этапа 2 линкует не-UI исходники `Comics.Editor` (Models/Utils/IWS) через `<Compile Include>` по ссылке — без перемещения и переписывания;
- `Comics.Core` ретаргетируется на .NET 10 «чтобы собиралось» (AC-4), но в рантайме приложения не участвует.

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `apps/comics-editor-v2.9/` (корень) | Modify (реструктуризация) | Становится Flutter-проектом; C# уезжает в `native/` |
| `Comics.sln`, `Comics.Core/`, `Comics.Editor/`, `Utils/` | Move → `native/` | Перемещение как есть; далее минорные фиксы csproj |
| `native/Comics.Editor/Comics.Editor.csproj` | Modify (минорный фикс) | Старый формат → SDK-style, `net10.0-windows`, `UseWPF`, `EnableWindowsTargeting` |
| `native/Comics.Core/Comics.Core.csproj` | Modify (минорный фикс) | SDK-style, `net10.0`; EF6 → PackageReference; PushSharp — см. Edge Cases |
| `native/Comics.Editor.Flutter/` | Create (обвязка) | Wrapper для PlatformView (по образцу плагина), `net10.0-windows` |
| `native/Comics.Editor.Headless/` | Create (обвязка) | Консольный host `net10.0`: линкует не-UI исходники Comics.Editor, JSON-RPC по stdio |
| `pubspec.yaml`, `lib/`, `windows/`, `macos/`, `linux/` | Create | Flutter-приложение; UI копируется из `design/comics-editor-maket-dart-v3/lib` |
| `lib/src/bridge/` | Create (обвязка) | Dart-клиенты: PlatformView-виджет (Windows), stdio-клиент headless-ядра (macOS/Linux) |
| `.git` (вложенный) | **Не трогаем** | Git полностью на пользователе |
| `legacy/comics-editor-v2.8`, `libs/comics_editor/flutter_comics_editor`, `design/…` | Read-only | Образцы/источники для копирования |

## Architecture

### Целевая структура папок

```
apps/comics-editor-v2.9/
├── .git                        # НЕ ТРОГАТЬ (пользователь управляет вручную)
├── pubspec.yaml                # Flutter app "comics_editor" v2.9
├── README.md                   # сборка по платформам
├── lib/
│   ├── main.dart               # выбор режима по Platform: windows→WPF-view, иначе→maket UI
│   └── src/
│       ├── ui/                 # копия design/comics-editor-maket-dart-v3/lib/src (as is)
│       └── bridge/
│           ├── wpf_editor_view.dart      # PlatformView-виджет (Windows)
│           └── core_client.dart          # запуск/JSON-RPC клиент headless-ядра
├── windows/                    # flutter create + плагин-обвязка:
│   ├── runner/…
│   └── editor_plugin/          # CMake + editor_plugin.cpp (+ C++/CLI TODO, по образцу libs-плагина)
├── macos/                      # flutter create (runner as is)
├── linux/                      # flutter create (runner as is)
└── native/                     # ПЕРЕМЕЩЁННОЕ C#-решение
    ├── Comics.sln              # + новые проекты Flutter/Headless
    ├── Comics.Core/            # as is; csproj → SDK-style net10.0
    ├── Comics.Editor/          # as is; csproj → SDK-style net10.0-windows (WPF)
    ├── Comics.Editor.Flutter/  # НОВОЕ (обвязка): PlatformView + MethodChannelHandler
    ├── Comics.Editor.Headless/ # НОВОЕ (обвязка): stdio JSON-host, <Compile Include> не-UI файлов
    └── Utils/                  # as is: 7za.exe, ImageMagick (Windows-бинарники)
```

### Component Diagram

```
                    Flutter (Dart), одно приложение
        ┌────────────────────────────────────────────────┐
        │ main.dart — переключение по платформе           │
        │                                                │
        │  Windows                 macOS / Linux         │
        │  ┌──────────────────┐    ┌──────────────────┐  │
        │  │ WpfEditorView    │    │ UI из maket-v3   │  │
        │  │ (PlatformView)   │    │ (lib/src/ui)     │  │
        │  └───────┬──────────┘    └────────┬─────────┘  │
        └──────────┼───────────────────────┼─────────────┘
                   │ MethodChannel          │ CoreClient (stdin/stdout, JSON)
        ┌──────────▼──────────┐   ┌────────▼──────────────────┐
        │ windows/editor_plugin│   │ dotnet Comics.Editor.      │
        │ C++ (+C++/CLI, TODO │   │ Headless (net10.0, процесс)│
        │ на Windows-машине)  │   │ JSON-RPC: open/save/…      │
        └──────────┬──────────┘   └────────┬──────────────────┘
        ┌──────────▼──────────┐   ┌────────▼──────────────────┐
        │ Comics.Editor.Flutter│  │ линкованные не-UI исходники│
        │ net10.0-windows      │  │ Comics.Editor: Models/,    │
        │ хостит WPF           │  │ Utils/(FileManager,ZipUtils)│
        │ ComicsControl/       │  │ IWS/Utils/                 │
        │ MainWindow как есть  │  └───────────────────────────┘
        └─────────────────────┘
```

### Data Flow

- **Windows (этап 1)**: Flutter отрисовывает нативный HWND с WPF-контентом; весь workflow (файлы, диалоги, сохранение) остаётся внутри WPF-кода как в v2.8. MethodChannel — минимальный (создать view, закрыть, передать путь проекта).
- **macOS/Linux (этап 2)**: Dart-UI (maket) владеет состоянием экрана; операции с данными идут в headless-процесс: Dart сериализует запрос в JSON-строку → stdin процесса; ответ — JSON из stdout. Headless использует существующие `FileManager`/`ZipUtils`/Models для чтения/записи файлов комиксов.

## Interfaces

### JSON-RPC headless-ядра (stage 2, `Comics.Editor.Headless`)

Транспорт: длина-префиксованные строки JSON (или NDJSON) через stdio. Минимальный набор методов v1:

```jsonc
{"id":1,"method":"ping"}                          → {"id":1,"result":"pong","version":"2.9"}
{"id":2,"method":"openComics","params":{"path":"…"}}   → {"id":2,"result":{ /* Comics JSON: layers, sounds, anims */ }}
{"id":3,"method":"saveComics","params":{"path":"…","comics":{…}}} → {"id":3,"result":true}
{"id":4,"method":"exportPackage","params":{"path":"…"}} → архивация через ZipUtils
{"id":5,"method":"imageInfo","params":{"path":"…"}}     → размеры/превью (ImageMagick-обвязка)
```

Формат `comics` — существующая JSON-сериализация моделей `Comics.Editor/Models` (Newtonsoft.Json), без изменений схемы.

### Dart bridge

```dart
// lib/src/bridge/core_client.dart
class CoreClient {
  Future<void> start();                 // Process.start(self-contained бинарник Comics.Editor.Headless)
  Future<Map<String, dynamic>> call(String method, [Map? params]);
  Future<void> dispose();
}

// lib/src/bridge/wpf_editor_view.dart (Windows)
class WpfEditorView extends StatelessWidget {…} // PlatformView 'comics_editor_view'
```

### MethodChannel (Windows, по образцу плагина)

- канал `comics_editor` — `create`, `dispose`, `openProject(path)`; расширение отложено до работы на Windows-машине.

## Data Models

Без изменений: модели `Comics.Editor/Models` (Comics, Layer, Image, Sound, *Anim) и их JSON-формат остаются каноническими. Dart-модели макета (`lib/src/ui/models.dart`) — только view-state; конвертация Dart↔JSON-ядра выполняется в bridge (новый код, обвязка).

## Behavior Specifications

### Happy Path

**Windows**: пользователь запускает `flutter run -d windows` → Flutter-окно с встроенным WPF-редактором → работа идентична v2.8.

**macOS/Linux**: `flutter run -d macos|linux` → UI макета → «Open» вызывает `CoreClient.openComics` → headless читает файл существующим кодом → UI отображает; «Save» — обратный путь.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| PushSharp не совместим с .NET 10 | `dotnet build Comics.Core` | Минорный фикс: `PushManager.cs` исключается из компиляции условно (`<Compile Remove>`) с комментарием; логика не переписывается. Фиксируется в implementation-log |
| EF6 (`System.Data.Entity`) на .NET 10 | то же | PackageReference `EntityFramework 6.5.*` (поддерживает современный .NET); код не меняется |
| `7za.exe`/`ImageMagick` отсутствуют на macOS/Linux | вызов ZipUtils/ImageMagick из headless | Обвязка-резолвер путей: Windows → `native/Utils/…`; macOS/Linux → системные `7z`/`magick` (документируется в README; при отсутствии — понятная ошибка в JSON-ответе) |
| headless-процесс упал/бинарник не найден | старт CoreClient | UI показывает баннер «ядро недоступно», работа UI-макета продолжается без I/O |
| Windows-машина недоступна | этап 1 | Всё готовится (csproj, CMake, C#-wrapper, Dart), сборка отложена — допустимо по требованиям |
| Вложенный `.git` при перемещениях | `mv` внутри папки | Перемещаем только рабочие файлы; `.git` не трогаем; git-операции (`git add/mv`) не выполняем — пользователь вручную |

### Error Handling

| Error | Cause | Response |
|-------|-------|----------|
| JSON-RPC error | исключение в C#-коде | `{"id":N,"error":{"message":…,"stack":…}}`; Dart показывает диалог |
| Невалидный файл комикса | битый/чужой файл | Ошибка из существующего кода прокидывается как error-ответ, UI-диалог |
| PlatformView не зарегистрирован | C++/CLI слой ещё не собран | Windows-режим показывает заглушку с инструкцией по сборке (до завершения работ на Windows) |

## Dependencies

### Requires

- Flutter SDK ≥ 3.10 (макет); .NET 10 SDK — только на машине сборки (headless публикуется self-contained, конечному пользователю Runtime не нужен); на macOS/Linux — системные `7z`/`imagemagick` для полного I/O.
- Windows-машина + VS2022 (C++/CLI) — только для завершения и проверки этапа 1.

### Blocks

- Будущая интеграция maket-UI с реальными данными на Windows (может заменить WPF позже).

## Integration Points

- `design/comics-editor-maket-dart-v3/lib` → копируется в `lib/src/ui` (источник остаётся на месте, read-only).
- `libs/comics_editor/flutter_comics_editor` → образец: `windows/CMakeLists.txt`, `editor_plugin.cpp/h`, `Comics.Editor.Flutter/{ComicsEditorPlatformView,MethodChannelHandler}.cs` копируются/адаптируются в v2.9 (с ретаргетом net9→net10). Плагин не подключается как зависимость.
- Существующие csproj: `packages.config` → `PackageReference` (Newtonsoft.Json, log4net; EF6 для Core) — часть минорного фикса.

## Testing Strategy

### Unit Tests

- [ ] `Comics.Editor.Headless`: round-trip open→save на образце файла комикса (dotnet-тест или ручной прогон через stdio)

### Integration Tests

- [ ] macOS: `flutter run -d macos` — UI загружается, `ping` к headless проходит
- [ ] macOS: open/save реального файла через UI (если найдётся образец данных)
- [ ] `dotnet build native/Comics.sln` проходит на macOS (все проекты, включая windows-таргеты с `EnableWindowsTargeting`)

### Manual Verification

- [ ] `flutter analyze` чистый; приложение запускается на macOS (Linux — по доступности)
- [ ] Windows: отложено (см. требования) — чек-лист для будущей проверки в README
- [ ] `legacy/comics-editor-v2.8` не изменён (сравнение до/после)

## Migration / Rollout

Перемещения выполняются обычными `mv` (без git). Порядок: сначала C# → `native/`, затем генерация Flutter-каркаса (`flutter create`), затем копирование UI-макета и обвязки. Откат — обратные перемещения (история git не затрагивается агентом).

## Open Design Questions

- [x] Транспорт headless: **NDJSON** (v1, по умолчанию — возражений не поступило).
- [x] Дистрибуция headless: **self-contained publish** per-platform (решение пользователя, 2026-07-23): `dotnet publish -r osx-arm64|linux-x64|win-x64 --self-contained` → бинарник кладётся в ресурсы приложения; .NET Runtime у конечного пользователя не требуется. .NET 10 SDK нужен только на машине сборки.

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-07-23
- [x] Notes: «specs approved». Решения в ходе ревью: headless — self-contained publish; транспорт NDJSON; структура папок подтверждена.
