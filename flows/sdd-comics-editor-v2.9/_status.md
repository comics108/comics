# Status: sdd-comics-editor-v2.9

## Current Phase

IMPLEMENTATION

## Phase Status

COMPLETE (кроме отложенной Windows-доделки: interop C++→.NET и проверка на Windows-машине — по решению пользователя шаг Windows-сборки пропущен)

## Last Updated

2026-07-23 by Claude

## Blockers

- Нет (Windows-часть отложена сознательно; чек-лист — README apps/comics-editor-v2.9, раздел «Windows»)

## Progress

- [x] Requirements drafted
- [x] Requirements approved (2026-07-23; Windows-сборку на macOS пропускаем)
- [x] Specifications drafted
- [x] Specifications approved (2026-07-23; self-contained headless, NDJSON)
- [x] Plan drafted
- [x] Plan approved (2026-07-23)
- [x] Implementation started
- [x] Implementation complete (Windows interop — deferred, подготовлен полностью)

## Context Notes

Key decisions and context for resuming:

- Итоговая структура: apps/comics-editor-v2.9 = Flutter-приложение; C# в native/ (Comics.slnx: Comics.Editor net10.0-windows, Comics.Core net10.0, + обвязка Comics.Editor.Flutter и Comics.Editor.Headless); UI макета в lib/src/ui; мост в lib/src/bridge.
- Минорные фиксы C#: только Logger.cs (2×2 строки, log4net) + shim SystemWebCompat.cs + исключён PushManager.cs. Полный список — README.
- **AssemblyName headless = `Comics.Editor` обязательно** — data.json хранит `$type: "..., Comics.Editor"`.
- Headless: NDJSON stdio (ping/openComics/saveComics/exportPackage/imageInfo), self-contained publish (tool/build_headless.sh), zip через System.IO.Compression.
- Проверено на macOS: dotnet build 0 ошибок; flutter analyze 0 ошибок; flutter test 3/3 (включая round-trip open→edit→save→reopen на test/fixtures/sample.comics); приложение запускается.
- Git не трогался (правило пользователя); вложенный .git в v2.9 на месте; v2.8/design/libs не изменены.
- Для Windows: реализовать interop в windows/editor_plugin/editor_plugin.cpp (hostfxr → Comics.Editor.Flutter.dll → MethodChannelHandler; "create" → EditorHost.ShowMainWindow() = полный WPF-редактор). Следующий шаг после этого — PlatformView-встраивание ComicsControl.

## Fork History

- Новый flow (не форк), создан 2026-07-23.

## Next Actions

1. (Windows-машина) README → раздел «Windows»: собрать slnx, реализовать interop, `flutter run -d windows`
2. (опционально) Проверка на Linux: `tool/build_headless.sh linux-x64` + `flutter run -d linux`
3. (опционально) PlatformView-встраивание ComicsControl вместо отдельного окна
