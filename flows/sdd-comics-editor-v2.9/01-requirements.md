# Requirements: comics-editor-v2.9 — Flutter-обвязка для существующего C# редактора

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-23

## Problem Statement

`/apps/comics-editor-v2.9` — копия legacy WPF-редактора комиксов (`/legacy/comics-editor-v2.8`): C#-решение `Comics.sln` с проектами `Comics.Editor` (WPF, .NET Framework 4.5.2, старый формат csproj + packages.config) и `Comics.Core` (DAL, утилиты), плюс `Utils/` (7za.exe, ImageMagick — Windows-бинарники).

Нужно превратить эту папку в Flutter-приложение для **Windows, macOS, Linux**, при этом:

- **C#-код не переписывается** — существующая логика и WPF UI остаются как есть;
- добавляется только **обвязка** (Flutter-каркас, каналы/интеграция, скрипты сборки);
- выполняется **реструктуризация папок** (перемещение файлов, без переписывания содержимого);
- .NET можно поднять до последнего (retarget проектов, минорные фиксы, чтобы собиралось).

Работа разбита на **два этапа** (решение пользователя, 2026-07-23):

1. **Этап 1 — Windows**: запустить полный WPF-редактор как есть внутри Flutter-приложения, ничего не дописывая в C#-код (только обвязка).
2. **Этап 2 — macOS/Linux**: запустить приложение с Flutter-интерфейсом из `design/comics-editor-maket-dart-v3` (готовый Dart-макет «Comics Editor 3.0», чистый Flutter SDK без сторонних пакетов, функциональный паритет с v2.8 на уровне UI).

Существующий задел: `libs/comics_editor/flutter_comics_editor` — Flutter-плагин с подходом PlatformView (Windows-only), содержит собственную копию нативного кода (`native/Comics.Core`, `Comics.Editor`, `Comics.Editor.Flutter` на net9.0-windows) и C++/CLI-слой (не завершён, требует Windows-машину). См. flows `sdd-flutter-comics-editor-pview` / `-ffi`.

## User Stories

### Primary

**As a** разработчик/мейнтейнер редактора комиксов
**I want** запускать существующий C#-редактор внутри Flutter-приложения на десктопе
**So that** UI-платформа унифицируется с остальными Flutter-проектами (viewer, puzzle) без дорогостоящего переписывания C#-кода

### Secondary

**As a** мейнтейнер репозитория
**I want** чтобы `apps/comics-editor-v2.9` имел стандартную структуру Flutter-приложения с нативным C# в подпапке
**So that** проект собирается стандартными командами (`flutter build`) и понятен без археологии

## Acceptance Criteria

### Must Have

1. **Given** папка `apps/comics-editor-v2.9`
   **When** реструктуризация завершена
   **Then** это валидный Flutter-проект (pubspec.yaml, `lib/`, `windows/`, `macos/`, `linux/`), а C#-решение перемещено в подпапку (например `native/`) без изменения содержимого исходников (кроме минорных фиксов для сборки).

2. **Этап 1 (Windows). Given** Windows-машина с Flutter SDK и .NET SDK
   **When** выполняется `flutter run -d windows`
   **Then** запускается Flutter-приложение со встроенным полным WPF-редактором (весь существующий функционал v2.8), C#-код не дописан — только обвязка.

3. **Этап 2 (macOS/Linux). Given** машина с macOS или Linux
   **When** выполняется `flutter run -d macos` / `-d linux`
   **Then** запускается приложение с интерфейсом из `design/comics-editor-maket-dart-v3` (макет перенесён/подключён в приложение).

4. **Given** C#-проекты `Comics.Core` / `Comics.Editor`
   **When** выполняется `dotnet build` под последний .NET
   **Then** сборка проходит; допускаются только минорные правки (retarget csproj, замена несовместимых API, NuGet-версии) — без переписывания логики.

5. **Given** папка `legacy/comics-editor-v2.8`
   **When** все работы завершены
   **Then** в ней нет ни одного изменения (byte-for-byte идентична текущему состоянию).

### Should Have

- Переиспользование наработок `libs/comics_editor/flutter_comics_editor` (PlatformView-архитектура, MethodChannelHandler) вместо дублирования.
- Скрипт/README со сборочными шагами по платформам.
- Удаление вложенного `.git` внутри `apps/comics-editor-v2.9` (артефакт копирования из v2.8), чтобы папка стала обычной частью основного репозитория.

### Won't Have (This Iteration)

- Переписывание WPF UI на Dart/Flutter (на этапе 2 используется уже готовый макет из `design/`, а не новое переписывание).
- Портирование WPF на macOS/Linux (WPF принципиально Windows-only).
- Изменение бизнес-логики, форматов данных, DAL.
- Любые изменения в `legacy/comics-editor-v2.8` и других legacy-папках.
- Мобильные платформы (iPhone/iPad/Android), хотя макет их поддерживает — вне текущего объёма.

## Constraints

- **Технические**: C#-код — as is; разрешены только минорные фиксы «чтобы завелось» (target framework, csproj-формат, пакеты). WPF (`Comics.Editor`) работает только на Windows даже на .NET 9/10 (`net*-windows`).
- **Платформа**: Flutter desktop: Windows, macOS, Linux.
- **Рабочая зона**: только `apps/comics-editor-v2.9` (плюс этот flow-каталог). `legacy/comics-editor-v2.8` — read-only. *(В исходной формулировке пользователя опечатка: «работы вести только в папке comics-editor-v2.8» — принято как v2.9, т.к. v2.8 явно объявлена неприкасаемой.)*
- **Зависимости**: `Utils/7za.exe`, `Utils/ImageMagick` — Windows-бинарники; на macOS/Linux потребуются платформенные аналоги (уровень обвязки, не переписывание).
- **Окружение**: текущая машина — macOS; сборка/проверка WPF-части возможна только на Windows (тот же блокер, что и в `sdd-flutter-comics-editor-pview`).

## Open Questions

- [x] **Q1. Объём функциональности на macOS/Linux** — РЕШЕНО (2026-07-23): двухэтапный план. Этап 1 — Windows с полным WPF как есть; этап 2 — macOS/Linux с Flutter-интерфейсом из `design/comics-editor-maket-dart-v3`.
- [ ] **Q2. Отношение к `libs/comics_editor/flutter_comics_editor`**: приложение v2.9 использует этот плагин как зависимость (и тогда чей C#-код канонический — плагина или apps/v2.9?), или v2.9 самодостаточно и плагин остаётся отдельным экспериментом?
- [ ] **Q3. Вложенный `.git`** в `apps/comics-editor-v2.9` — удалить при реструктуризации? (Сейчас git видит папку как один нетрекаемый путь.)
- [ ] **Q4. Целевая версия .NET** — «последний»: .NET 9 (как в flutter_comics_editor) или .NET 10?
- [ ] **Q5. Данные на этапе 2**: макет содержит Dart-контроллер с UI-паритетом v2.8, но открытие/сохранение реальных файлов комиксов на macOS/Linux — через Dart-реализацию макета, через headless C#-ядро (Comics.Core на кросс-платформенном .NET), или на этапе 2 достаточно UI-макета без реального I/O?

## References

- `flows/sdd-flutter-comics-editor-pview/` — PlatformView-подход, реализация до фазы C++/CLI
- `flows/sdd-flutter-comics-editor-ffi/` — альтернативный FFI-подход
- `libs/comics_editor/flutter_comics_editor/README.md`, `WINDOWS_INTEGRATION_TODO.md`
- `apps/comics-editor-v2.9/Comics.sln` — исходное C#-решение
- `design/comics-editor-maket-dart-v3/` — Dart-макет UI для этапа 2 (Comics Editor 3.0, adaptive, HolySpots Design System)

---

## Approval

- [ ] Reviewed by:
- [ ] Approved on:
- [ ] Notes:
