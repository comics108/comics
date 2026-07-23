# Requirements: comics-editor-v2.9 — Flutter-обвязка для существующего C# редактора

> Version: 1.2
> Status: APPROVED
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
   **Then** запускается приложение с интерфейсом из `design/comics-editor-maket-dart-v3` (макет перенесён/подключён в приложение), а данные (открытие/сохранение комиксов) обслуживает headless-ядро `Comics.Core` на кросс-платформенном .NET 10.

4. **Given** C#-проекты `Comics.Core` / `Comics.Editor`
   **When** выполняется `dotnet build` под последний .NET
   **Then** сборка проходит; допускаются только минорные правки (retarget csproj, замена несовместимых API, NuGet-версии) — без переписывания логики.

5. **Given** папка `legacy/comics-editor-v2.8`
   **When** все работы завершены
   **Then** в ней нет ни одного изменения (byte-for-byte идентична текущему состоянию).

### Should Have

- Заимствование наработок `libs/comics_editor/flutter_comics_editor` (PlatformView-архитектура, MethodChannelHandler) как образца — при этом v2.9 самодостаточен.
- Скрипт/README со сборочными шагами по платформам.

### Won't Have (This Iteration)

- Переписывание WPF UI на Dart/Flutter (на этапе 2 используется уже готовый макет из `design/`, а не новое переписывание).
- Портирование WPF на macOS/Linux (WPF принципиально Windows-only).
- Изменение бизнес-логики, форматов данных, DAL.
- Любые изменения в `legacy/comics-editor-v2.8` и других legacy-папках.
- Мобильные платформы (iPhone/iPad/Android), хотя макет их поддерживает — вне текущего объёма.

## Constraints

- **Технические**: C#-код — as is; разрешены только минорные фиксы «чтобы завелось» (target framework, csproj-формат, пакеты). Целевой .NET — **.NET 10**. WPF (`Comics.Editor`) работает только на Windows даже на современном .NET (`net10.0-windows`).
- **Git**: агент не выполняет git-команды и не трогает `.git` (в т.ч. вложенный в v2.9) — все операции с git пользователь делает вручную.
- **Платформа**: Flutter desktop: Windows, macOS, Linux.
- **Рабочая зона**: только `apps/comics-editor-v2.9` (плюс этот flow-каталог). `legacy/comics-editor-v2.8` — read-only. *(В исходной формулировке пользователя опечатка: «работы вести только в папке comics-editor-v2.8» — принято как v2.9, т.к. v2.8 явно объявлена неприкасаемой.)*
- **Зависимости**: `Utils/7za.exe`, `Utils/ImageMagick` — Windows-бинарники; на macOS/Linux потребуются платформенные аналоги (уровень обвязки, не переписывание).
- **Окружение**: текущая машина — macOS; сборка/проверка WPF-части возможна только на Windows (тот же блокер, что и в `sdd-flutter-comics-editor-pview`). **Решение пользователя (2026-07-23): шаг фактической Windows-сборки допустимо пропустить** — этап 1 готовится «до упора» на macOS (структура, обвязка, csproj, CMake), а сборка/проверка на Windows выполняется позже на Windows-машине.

## Open Questions

Все вопросы решены пользователем 2026-07-23:

- [x] **Q1. Объём функциональности на macOS/Linux**: двухэтапный план. Этап 1 — Windows с полным WPF как есть; этап 2 — macOS/Linux с Flutter-интерфейсом из `design/comics-editor-maket-dart-v3`.
- [x] **Q2. Отношение к `libs/comics_editor/flutter_comics_editor`**: v2.9 — **самодостаточное приложение**; весь C#-код и обвязка живут в `apps/comics-editor-v2.9`, архитектура PlatformView и готовые файлы плагина заимствуются как образец. Плагин остаётся отдельным экспериментом.
- [x] **Q3. Вложенный `.git`**: **не трогать**. Все операции с git пользователь выполняет вручную; агент не выполняет никаких git-команд и не удаляет/не изменяет `.git`.
- [x] **Q4. Целевая версия .NET**: **.NET 10**.
- [x] **Q5. Данные на этапе 2**: **headless C#-ядро** — `Comics.Core` собирается под кросс-платформенный .NET 10 и обслуживает Flutter-UI на macOS/Linux (обвязка, без переписывания логики).

## References

- `flows/sdd-flutter-comics-editor-pview/` — PlatformView-подход, реализация до фазы C++/CLI
- `flows/sdd-flutter-comics-editor-ffi/` — альтернативный FFI-подход
- `libs/comics_editor/flutter_comics_editor/README.md`, `WINDOWS_INTEGRATION_TODO.md`
- `apps/comics-editor-v2.9/Comics.sln` — исходное C#-решение
- `design/comics-editor-maket-dart-v3/` — Dart-макет UI для этапа 2 (Comics Editor 3.0, adaptive, HolySpots Design System)

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-07-23
- [x] Notes: «Requirements approved». Поправка: если Windows-сборку невозможно выполнить на macOS — шаг фактической сборки Windows-версии пропускается (подготовка делается полностью, проверка — позже на Windows).
