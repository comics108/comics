# Implementation Plan: comics-editor-v2.9 — Flutter-обвязка

> Version: 1.1
> Status: APPROVED
> Last Updated: 2026-07-23
> Specifications: [02-specifications.md](02-specifications.md) (APPROVED)

## Summary

Реструктуризация `apps/comics-editor-v2.9` в Flutter-приложение с C#-кодом в `native/`. Порядок: перемещения → ретаргет C# на .NET 10 (проверка `dotnet build` на macOS) → Flutter-каркас → UI из макета → headless-ядро (self-contained) + Dart-bridge → Windows-обвязка (подготовка, без сборки). Все операции — обычные файловые (`mv`/копирование); **никаких git-команд**, вложенный `.git` не трогаем. `legacy/comics-editor-v2.8` и `design/…` — read-only источники.

## Task Breakdown

### Phase 1: Реструктуризация и ретаргет C#

#### Task 1.1: Переместить C#-решение в native/
- **Description**: `mkdir native`; `mv` `Comics.sln`, `Comics.Core/`, `Comics.Editor/`, `Utils/` → `native/`. `.git`, `.gitignore` и прочие dot-файлы корня не трогать.
- **Files**: `apps/comics-editor-v2.9/native/*` — Move
- **Dependencies**: None
- **Verification**: `ls native/` показывает 4 элемента; в корне из старого осталось только `.git` и dot-файлы; diff содержимого файлов = пусто (перемещение без изменений)
- **Complexity**: Low

#### Task 1.2: Ретаргет Comics.Editor.csproj на net10.0-windows (SDK-style)
- **Description**: Переписать csproj (это обвязка, не код): SDK-style, `net10.0-windows`, `UseWPF=true`, `EnableWindowsTargeting=true` (для сборки на macOS), `PackageReference`: Newtonsoft.Json (актуальный 13.x), log4net. Удалить `packages.config`, `Properties/AssemblyInfo.cs` при конфликте авто-генерации (`GenerateAssemblyInfo=false` — предпочтительно, чтобы не трогать файлы). `.cs`/`.xaml` не изменяются.
- **Files**: `native/Comics.Editor/Comics.Editor.csproj` — Modify; `native/Comics.Editor/packages.config` — Delete
- **Dependencies**: 1.1
- **Verification**: `dotnet build native/Comics.Editor` на macOS проходит (компиляция WPF под EnableWindowsTargeting); ошибки компиляции старого кода фиксируются и решаются минорно (лог в 04)
- **Complexity**: High (первая встреча старого кода с .NET 10)

#### Task 1.3: Ретаргет Comics.Core.csproj на net10.0
- **Description**: SDK-style, `net10.0`; `PackageReference`: EntityFramework 6.5.*, log4net, Newtonsoft.Json; PushSharp — при несовместимости `<Compile Remove="Utils/PushManager.cs">` с комментарием (единственное ожидаемое исключение).
- **Files**: `native/Comics.Core/Comics.Core.csproj` — Modify; `native/Comics.Core/packages.config` — Delete
- **Dependencies**: 1.1
- **Verification**: `dotnet build native/Comics.Core` проходит на macOS
- **Complexity**: Medium

#### Task 1.4: Обновить Comics.sln
- **Description**: Поправить/пересоздать sln под новые пути и (позже) новые проекты. Допустимо `dotnet new sln` + `dotnet sln add` (файл sln — обвязка).
- **Files**: `native/Comics.sln` — Modify
- **Dependencies**: 1.2, 1.3
- **Verification**: `dotnet build native/Comics.sln` проходит целиком
- **Complexity**: Low

### Phase 2: Flutter-каркас и UI макета

#### Task 2.1: Создать Flutter-приложение в корне v2.9
- **Description**: `flutter create . --project-name comics_editor --platforms windows,macos,linux` в `apps/comics-editor-v2.9`; заполнить `pubspec.yaml` (name: comics_editor, version 2.9.0) по образцу макета (без сторонних пакетов).
- **Files**: `pubspec.yaml`, `lib/main.dart`, `windows/`, `macos/`, `linux/`, `analysis_options.yaml` — Create
- **Dependencies**: 1.1 (корень освобождён)
- **Verification**: `flutter analyze` чистый; `flutter run -d macos` показывает стартовый экран
- **Complexity**: Low

#### Task 2.2: Скопировать UI макета в lib/src/ui
- **Description**: Копия `design/comics-editor-maket-dart-v3/lib/src/*` → `lib/src/ui/` (без `.DS_Store`); `lib/main.dart` — адаптация main из макета: на macOS/Linux открывается `EditorScreen` макета, на Windows — маршрут к WPF-view (пока заглушка). Импорты в скопированных файлах поправить на новые пути (механическая правка).
- **Files**: `lib/src/ui/**` — Create (копия); `lib/main.dart` — Modify
- **Dependencies**: 2.1
- **Verification**: `flutter run -d macos` — редактор-макет работает (сцены, таймлайн, панели)
- **Complexity**: Medium

### Phase 3: Headless-ядро (этап 2 — macOS/Linux данные)

#### Task 3.1: Проект Comics.Editor.Headless
- **Description**: Новый консольный проект `net10.0`: `<Compile Include>` по ссылке не-UI исходников `../Comics.Editor/` (Models/*.cs, Utils/FileManager.cs, Utils/ZipUtils.cs, IWS/Utils/*.cs); NDJSON-цикл по stdio; методы v1: `ping`, `openComics`, `saveComics`, `exportPackage`, `imageInfo`. Резолвер внешних утилит: Windows → `native/Utils/…`, unix → `7z`/`magick` из PATH. Если какой-то линкованный файл тянет WPF-типы — исключается из линка, метод помечается unsupported (лог в 04).
- **Files**: `native/Comics.Editor.Headless/{Comics.Editor.Headless.csproj,Program.cs,Rpc.cs,ToolResolver.cs}` — Create
- **Dependencies**: 1.2 (пути исходников устоялись), 1.4
- **Verification**: `dotnet run` + ручной `ping`/`openComics` через stdin на образце файла; `dotnet publish -r osx-arm64 --self-contained` даёт рабочий бинарник
- **Complexity**: High

#### Task 3.2: Dart-bridge CoreClient + подключение к UI
- **Description**: `core_client.dart`: запуск self-contained бинарника (поиск в ресурсах приложения / `native/Comics.Editor.Headless/publish/<rid>/`), NDJSON request/response, таймауты, баннер «ядро недоступно». Подключить к Open/Save макетного контроллера (конвертация JSON ядра ↔ view-модели макета).
- **Files**: `lib/src/bridge/core_client.dart` — Create; `lib/src/ui/controller.dart` — Modify (точки Open/Save); `lib/src/bridge/models_mapping.dart` — Create
- **Dependencies**: 2.2, 3.1
- **Verification**: на macOS в UI открывается и сохраняется реальный файл комикса (или, при отсутствии образца, round-trip на сгенерированном файле)
- **Complexity**: High

#### Task 3.3: Скрипт публикации headless
- **Description**: `tool/build_headless.sh` (+ .ps1 для Windows): `dotnet publish` под osx-arm64/linux-x64/win-x64, раскладка бинарников в ресурсы платформенных бандлов (macos Runner Resources / linux bundle / windows runner).
- **Files**: `tool/build_headless.sh`, `tool/build_headless.ps1` — Create; правки `macos/`/`linux/` для включения бинарника в бандл
- **Dependencies**: 3.1
- **Verification**: `flutter build macos` содержит бинарник; приложение из бандла находит ядро
- **Complexity**: Medium

### Phase 4: Windows-обвязка (подготовка, сборка отложена)

#### Task 4.1: Проект Comics.Editor.Flutter (PlatformView-wrapper)
- **Description**: Копия/адаптация из `libs/comics_editor/flutter_comics_editor/native/Comics.Editor.Flutter/` (`ComicsEditorPlatformView.cs`, `MethodChannelHandler.cs`) с ретаргетом на `net10.0-windows`, ссылкой на `../Comics.Editor`.
- **Files**: `native/Comics.Editor.Flutter/*` — Create; `native/Comics.sln` — Modify (add)
- **Dependencies**: 1.2, 1.4
- **Verification**: `dotnet build` проходит на macOS (EnableWindowsTargeting); функциональная проверка — на Windows позже
- **Complexity**: Medium

#### Task 4.2: Windows-плагин (C++ каркас)
- **Description**: Копия/адаптация `windows/CMakeLists.txt`, `editor_plugin.cpp/.h` из libs-плагина в `windows/`; регистрация в runner; `wpf_editor_view.dart` с заглушкой, если view-factory не зарегистрирована. C++/CLI-слой остаётся TODO (только на Windows-машине).
- **Files**: `windows/editor_plugin/*` — Create; `windows/runner/*` — Modify; `lib/src/bridge/wpf_editor_view.dart` — Create
- **Dependencies**: 2.1, 4.1
- **Verification**: статическая (код на месте, CMake согласован); сборка — на Windows позже
- **Complexity**: Medium

### Phase 5: Финализация

#### Task 5.1: README + чек-лист Windows
- **Description**: README в корне v2.9: структура, сборка per-platform, публикация headless, зависимости (7z/imagemagick), чек-лист доделки/проверки на Windows (C++/CLI, сборка, PlatformView).
- **Files**: `apps/comics-editor-v2.9/README.md` — Create
- **Dependencies**: всё выше
- **Verification**: шаги воспроизводимы по README
- **Complexity**: Low

#### Task 5.2: Финальная проверка инвариантов
- **Description**: Убедиться: `legacy/comics-editor-v2.8` не изменён; `design/…` и `libs/…` не изменены; `.git` в v2.9 нетронут; `flutter analyze` чистый; `dotnet build native/Comics.sln` проходит; `flutter run -d macos` работает.
- **Files**: —
- **Dependencies**: все
- **Verification**: чек-лист в 04-implementation-log.md
- **Complexity**: Low

## Dependency Graph

```
1.1 ─→ 1.2 ─→ 1.4 ─→ 3.1 ─→ 3.2
  │      │      └──→ 4.1 ─→ 4.2
  │      └──────────────────┘ (пути исходников)
  ├──→ 1.3 ─→ 1.4
  └──→ 2.1 ─→ 2.2 ─→ 3.2
       2.1 ─→ 4.2
3.1 ─→ 3.3          все ─→ 5.1 ─→ 5.2
```

## File Change Summary

| File | Action | Reason |
|------|--------|--------|
| `Comics.sln`, `Comics.Core/`, `Comics.Editor/`, `Utils/` | Move → `native/` | Реструктуризация |
| `native/Comics.{Core,Editor}/…csproj` | Modify | Ретаргет .NET 10 (минорный фикс) |
| `native/Comics.{Core,Editor}/packages.config` | Delete | Заменён PackageReference |
| `native/Comics.Editor.Flutter/`, `native/Comics.Editor.Headless/` | Create | Обвязка |
| `pubspec.yaml`, `lib/`, `windows/`, `macos/`, `linux/`, `tool/`, `README.md` | Create | Flutter-каркас, bridge, скрипты |
| `lib/src/ui/**` | Create (копия макета) | UI этапа 2 |
| Всё прочее в `native/**` (.cs/.xaml) | Без изменений | «Код не переписывать» |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Старый C# не соберётся под .NET 10 без нетривиальных правок | Med | High | Правки только минорные, каждая логируется; при спорной правке — вопрос пользователю |
| WPF-сборка на macOS (EnableWindowsTargeting) упрётся в ограничения | Med | Med | Приемлемо: цель на macOS — компиляция; функциональная проверка на Windows отложена по требованиям |
| Не-UI исходники Comics.Editor тянут WPF-типы (headless не соберётся) | Med | High | Линковать выборочно; несобираемое — исключить из headless v1, метод unsupported, лог |
| Расхождение Dart-моделей макета и JSON ядра | High | Med | Слой `models_mapping.dart`; при нестыковке схемы — вопрос пользователю, схему не менять |
| Нет образца файла комикса для проверки | Med | Med | Round-trip: create→save→open в headless |
| Случайное задевание `.git`/legacy | Low | High | mv только белого списка из 4 элементов; финальная проверка 5.2 |

## Rollback Strategy

1. Обратные `mv` из `native/` в корень; удалить созданные папки (`lib/`, `windows/`, `macos/`, `linux/`, `native/Comics.Editor.{Flutter,Headless}`, `tool/`, `pubspec.yaml`, `README.md`).
2. csproj: восстановить из `legacy/comics-editor-v2.8` (идентичный источник копии) — вручную пользователем через git, либо файловым копированием (read-only источник не пострадает).
3. Git-история не затрагивалась агентом — откат на стороне пользователя тривиален.

## Checkpoints

После каждой фазы:

- [ ] `flutter analyze` / `dotnet build` без новых ошибок
- [ ] `legacy/comics-editor-v2.8`, `design/…`, `libs/…`, `.git` — нетронуты
- [ ] Отклонения от плана записаны в 04-implementation-log.md

## Open Implementation Questions

- [ ] Точный набор минорных фиксов C# станет известен только при первом `dotnet build` (решается по ходу, всё логируется).
- [x] Образец файла комикса: `libs/comics_viewer/flutter_comics_viewer/example/assets/sample.comics` (указано пользователем; копируется в `apps/comics-editor-v2.9/test/fixtures/`).

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-07-23
- [x] Notes: «Plan approved»; образец комикса — из flutter_comics_viewer example assets.
