# Implementation Log: comics-editor-v2.9 — Flutter-обвязка

> Started: 2026-07-23
> Plan: [03-plan.md](03-plan.md) (APPROVED)

## Progress Tracker

| Task | Status | Notes |
|------|--------|-------|
| 1.1 Переместить C# в native/ | Done | mv 4 элементов; .git не тронут |
| 1.2 Ретаргет Comics.Editor | Done | net10.0-windows; 1 фикс кода (Logger.cs, 2 строки) |
| 1.3 Ретаргет Comics.Core | Done | net10.0; shim SystemWebCompat.cs; исключён PushManager.cs; Logger.cs фикс |
| 1.4 Обновить решение | Done | Пересоздано как Comics.slnx (в старом sln был несуществующий Comics.Web) |
| 2.1 Flutter-каркас | Done | flutter create (windows,macos,linux); pubspec 2.9.0 |
| 2.2 UI макета | Done | Копия в lib/src/ui; main.dart с платформенным переключением; smoke-тест |
| 3.1 Comics.Editor.Headless | Done | NDJSON stdio; линк не-UI исходников; WpfShims (Point, MessageBox) |
| 3.2 CoreClient + UI | Done | core_client, models_mapping (merge в raw JSON); Browse…/Save подключены |
| 3.3 Скрипт публикации | Done | tool/build_headless.sh/.ps1; self-contained + копия в бандл |
| 4.1 Comics.Editor.Flutter | Done | EditorHost (полный MainWindow в STA-потоке) + MethodChannelHandler; собирается |
| 4.2 Windows-плагин C++ | Done (подготовка) | editor_plugin (static lib) + CMake + регистрация в runner; interop — TODO на Windows |
| 5.1 README | Done | Структура, сборка, чек-лист Windows, список минорных фиксов |
| 5.2 Инварианты | Done | v2.8/design/libs — рабочие файлы не тронуты; .git интактны; сборки зелёные |

## Session Log

### Session 2026-07-23 - Claude

**Started at**: Phase 1, Task 1.1
**Context**: План утверждён; dotnet 10.0.302, Flutter на macOS; образец: `test/fixtures/sample.comics` (копия из flutter_comics_viewer example)

#### Completed

- **Phase 1**: C# перемещён в `native/`; оба csproj → SDK-style .NET 10; `dotnet build Comics.slnx` — 0 ошибок.
  - Минорные фиксы кода: `Logger.cs` (2 строки, log4net netstandard API) в Comics.Editor и Comics.Core.
  - Обвязка: `Comics.Core/Compat/SystemWebCompat.cs` (shim HostingEnvironment/HttpPostedFileBase).
  - Исключение: `Comics.Core/Utils/PushManager.cs` (PushSharp net45-only), файл сохранён.
- **Phase 2**: `flutter create .`; UI макета скопирован в `lib/src/ui` (импорты относительные — без правок); `main.dart`: Windows → WpfEditorView (заглушка до interop), иначе → EditorScreen макета. `flutter analyze` — 0 ошибок; smoke-тест зелёный; debug-бандл macOS собирается; приложение запускается.
- **Phase 3**: `Comics.Editor.Headless` (net10.0, NDJSON stdio: ping/openComics/saveComics/exportPackage/imageInfo) поверх линкованных исходников; zip — System.IO.Compression (кроссплатформенно, формат тот же); `WpfShims.cs` (Point + MessageBox→stderr).
  - **Критичная находка**: data.json использует `$type: "Comics.Editor.Models.*, Comics.Editor"` (TypeNameHandling.Auto) → имя сборки headless обязано быть `Comics.Editor`, иначе десериализация молча возвращает null (FromJson глотает исключения).
  - Dart: `core_client.dart` (процесс + NDJSON, поиск бинарника: env → бандл → dev-publish), `models_mapping.dart` (merge правок в исходный JSON — поля вне UI-моделей не теряются), контроллер: openPath/saveToPath; UI: Browse… → диалог пути, Save → реальное сохранение.
  - `tool/build_headless.sh` — self-contained publish (osx-arm64 проверен) + копия в macOS-бандл.
  - Интеграционный тест: open→edit→save→reopen на sample.comics — зелёный (высота меняется, слои/звуки/width изображений сохраняются).
- **Phase 4**: `Comics.Editor.Flutter` написан заново против реального API v2.9 (в плагине-образце обвязка ссылалась на несуществующие методы Load/Save у ComicsViewModel): `EditorHost.ShowMainWindow()` — полный MainWindow в отдельном STA/Dispatcher-потоке, `MethodChannelHandler` (create/dispose). Собирается на macOS (EnableWindowsTargeting). C++: `windows/editor_plugin` (канал `comics_editor`, static lib, CMake с dotnet publish в `<build>/dotnet/`), зарегистрирован в runner (flutter_window.cpp). Interop C++→.NET — TODO на Windows (hostfxr рекомендован в README).
- **Phase 5**: README переписан; инварианты проверены (см. ниже).

#### Deviations from Plan

- Решение — `Comics.slnx` вместо `.sln` (формат .NET 10 SDK; старый sln содержал мёртвый Comics.Web).
- ImageManager/ImageMagick в Comics.Core не исключались — вместо этого shim SystemWebCompat.cs (меньше исключений).
- Headless: AssemblyName = `Comics.Editor` (требование формата $type) — вместо планового `comics-editor-headless`.
- Comics.Editor.Flutter не скопирован из libs-плагина, а написан заново (обвязка плагина не соответствовала реальному API v2.9).
- Этап 1 v1 — полный MainWindow отдельным окном (EditorHost), встраивание ComicsControl как PlatformView — следующий шаг на Windows (зафиксировано в README).
- Zip в headless — System.IO.Compression вместо 7za.exe (кроссплатформенность; 7za остаётся для WPF на Windows).

#### Discoveries

- `Comics.Editor` не ссылается на `Comics.Core` — подтверждено сборкой; Core нужен только для AC-4.
- Весь старый C#-код потребовал ровно 2×2 строки фиксов — остальное решено обвязкой.
- `FileManager.TempFolder` содержит литеральный `\` (`"Comics Editor\Temp"`) — на unix это папка с backslash в имени; работает корректно (оба конца используют одну константу), не трогаем.

**Ended at**: все фазы завершены (Windows-часть — подготовлена, доделка по README)
**Handoff notes**: для этапа 1 нужна Windows-машина: реализовать interop в `windows/editor_plugin/editor_plugin.cpp` (hostfxr → Comics.Editor.Flutter.dll), затем `flutter run -d windows`. Чек-лист — README, раздел «Windows».

---

## Deviations Summary

| Planned | Actual | Reason |
|---------|--------|--------|
| Comics.sln обновить | Пересоздан как Comics.slnx | Формат .NET 10; мёртвая ссылка на Comics.Web |
| Исключить ImageManager/ImageMagick из Core | Shim SystemWebCompat.cs | ImageManager используется DAL-моделями — исключить нельзя |
| AssemblyName headless произвольный | Ровно `Comics.Editor` | $type в data.json (TypeNameHandling.Auto) |
| Копия Comics.Editor.Flutter из libs | Написан заново | Обвязка плагина ссылалась на несуществующий API |
| PlatformView-встраивание WPF | v1: полный MainWindow отдельным окном | Честный zero-rewrite; встраивание — на Windows-машине |

## Learnings

- TypeNameHandling.Auto делает имя сборки частью формата данных — при любом переносе кода в новую сборку это ломается молча (FromJson глотает исключения). Проверять на реальных файлах, не на пустых.
- EnableWindowsTargeting позволяет держать WPF-код компилируемым в CI/на macOS — ошибок «до Windows» почти не остаётся.

## Completion Checklist

- [x] All tasks completed or explicitly deferred (Windows interop — deferred по решению пользователя)
- [x] Tests passing (`flutter test`: 3/3, включая интеграционный round-trip; `dotnet build`: 0 ошибок)
- [x] No regressions (v2.8/design/libs не тронуты; .git интактны)
- [x] Documentation updated (README + этот flow)
- [x] Status updated to COMPLETE (кроме отложенной Windows-проверки)
