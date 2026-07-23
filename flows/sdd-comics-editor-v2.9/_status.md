# Status: sdd-comics-editor-v2.9

## Current Phase

IMPLEMENTATION

## Phase Status

IN PROGRESS (Phase 1: реструктуризация и ретаргет C#)

## Last Updated

2026-07-23 by Claude

## Blockers

- None

## Progress

- [x] Requirements drafted
- [x] Requirements approved (2026-07-23, с поправкой: Windows-сборку на macOS пропускаем)
- [x] Specifications drafted
- [x] Specifications approved (2026-07-23; self-contained headless, NDJSON, структура подтверждена)
- [x] Plan drafted
- [x] Plan approved (2026-07-23; образец: libs/comics_viewer/flutter_comics_viewer/example/assets/sample.comics)
- [x] Implementation started  ← current
- [ ] Implementation complete

## Context Notes

Key decisions and context for resuming:

- `apps/comics-editor-v2.9` = копия `legacy/comics-editor-v2.8` (WPF, .NET Framework 4.5.2, старые csproj + packages.config). v2.8 — read-only. В формулировке задачи опечатка «работы вести в v2.8» — принято как v2.9.
- Задача: обвязка + перемещение папок, C#-код не переписывать; .NET можно поднять до последнего, минорные фиксы разрешены.
- Существующий задел: `libs/comics_editor/flutter_comics_editor` — PlatformView-плагин (Windows-only), своя копия native C# + Comics.Editor.Flutter (net9.0-windows); C++/CLI-слой не завершён (нужен Windows). См. flows sdd-flutter-comics-editor-pview/-ffi.
- WPF не работает вне Windows. Решение пользователя (2026-07-23): двухэтапный план — этап 1: Windows, полный WPF как есть внутри Flutter (ничего не дописывать в C#); этап 2: macOS/Linux с Flutter-UI из `design/comics-editor-maket-dart-v3` (чистый Dart-макет, UI-паритет с v2.8).
- Решения пользователя по открытым вопросам (2026-07-23): v2.9 — самодостаточное приложение (плагин flutter_comics_editor — только образец); **git не трогать вообще** (включая вложенный .git — пользователь делает всё с git вручную); целевой .NET — **10**; данные на этапе 2 — **headless Comics.Core** на кросс-платформенном .NET.
- Текущая машина — macOS; WPF-сборку можно проверить только на Windows.

## Fork History

- Новый flow (не форк), создан 2026-07-23.

## Next Actions

1. Получить «plan approved» (или правки); заодно спросить про образец файла комикса для проверки open/save
2. Начать реализацию с Phase 1 (перемещение в native/, ретаргет csproj), лог в 04-implementation-log.md

## Key Findings (SPECIFICATIONS)

- `Comics.Editor` НЕ ссылается на `Comics.Core` (0 ProjectReference) — вся логика файлов в Comics.Editor (Models, Utils/FileManager, Utils/ZipUtils, IWS/Utils). Comics.Core (EF6, PushSharp) — серверный, редактору не нужен в рантайме.
- Headless-ядро этапа 2 = новый консольный проект, линкующий не-UI исходники Comics.Editor через <Compile Include> (без перемещения/переписывания). JSON-RPC (NDJSON) через stdio. Дистрибуция — **self-contained publish** per-platform (решение пользователя 2026-07-23), .NET SDK нужен только на сборочной машине.
- Плагин flutter_comics_editor: заимствуем windows/CMakeLists, editor_plugin.cpp, Comics.Editor.Flutter/*.cs (net9→net10). C++/CLI-слой там не завершён — работа на Windows-машине, отложено.
- PushSharp скорее всего не совместим с .NET 10 → минорный фикс: <Compile Remove> PushManager.cs в Comics.Core (задокументировать). EF6 → PackageReference 6.5.*.
