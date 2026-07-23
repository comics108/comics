# Requirements: comics-editor-v2.9 — мобильные платформы (iOS/Android) + системные файловые диалоги

> Version: 1.2
> Status: APPROVED
> Last Updated: 2026-07-23

## Problem Statement

`apps/comics-editor-v2.9` (см. завершённый flow `sdd-comics-editor-v2.9`) — Flutter-приложение для Windows/macOS/Linux: UI из макета `design/comics-editor-maket-dart-v3` + headless C#-ядро (`Comics.Editor.Headless`, отдельный self-contained процесс, NDJSON через stdio) для открытия/сохранения `.comics`/`.puzzle`.

Нужно:

1. **Мобильные платформы**: iPhone, iPad, Android-телефоны, Android-планшеты. Макет уже адаптивный (breakpoints phone ≤600dp / tablet 601–1024dp / desktop ≥1025dp — см. README макета), т.е. UI-слой к этому готов; нужны платформенные раннеры и рабочая работа с файлами.
2. **Системные файловые диалоги**: открытие и сохранение файла через диалоговый интерфейс системы (document picker / save dialog), а не текстовое поле с путём (текущий `showOpenPathDialog`). Это касается и десктопа: путь-в-текстовом-поле был временным решением v1.

## Ключевая техническая проблема (для Open Questions)

Текущая схема данных — **отдельный процесс** headless-ядра — на мобильных платформах не работает:

- **iOS**: запуск дочерних процессов запрещён платформой (никакой `Process.start`).
- **Android**: исполнение бинарников ограничено (запуск возможен только из `nativeLibraryDir`, упаковка .NET-приложения как `lib*.so` — хрупкий хак); плюс потребовалась бы сборка .NET под android-arm64.

Т.е. для мобильных нужен другой способ читать/писать формат `.comics` (zip: `data.json` + `layers/` + `sounds/`). Варианты — в Q1.

## User Stories

### Primary

**As a** пользователь iPhone/iPad/Android-устройства
**I want** открывать, редактировать и сохранять комиксы в том же редакторе, что и на десктопе
**So that** работа над комиксами возможна с любого устройства

### Secondary

**As a** пользователь на любой платформе
**I want** выбирать файл для открытия и место сохранения через привычный системный диалог
**So that** не нужно вручную вводить/помнить пути к файлам

## Acceptance Criteria

### Must Have

1. **Given** проект v2.9
   **When** выполняется `flutter build ios` / `flutter build apk` (и `flutter run` на устройстве/эмуляторе)
   **Then** приложение собирается и запускается на iPhone, iPad, Android-телефоне и Android-планшете с UI макета (адаптивные раскладки phone/tablet работают).

2. **Given** запущенное приложение на мобильном устройстве
   **When** пользователь выбирает Open → системный диалог → `.comics`-файл
   **Then** файл открывается: слои/звуки/анимации видны в UI (паритет с десктопным открытием).

3. **Given** открытый документ на мобильном устройстве
   **When** пользователь нажимает Save
   **Then** документ сохраняется в песочницу приложения без диалогов; команда Export/Share выгружает `.comics` через системный интерфейс (iOS: Files/share sheet; Android: SAF create document); данные не теряются (round-trip как в существующем интеграционном тесте).

4. **Given** десктоп (macOS/Linux/Windows)
   **When** пользователь выбирает Open/Save
   **Then** используются нативные диалоги открытия/сохранения вместо текстового поля пути; headless-ядро продолжает работать как раньше.

5. **Given** существующие десктопные функции и тесты
   **When** изменения внесены
   **Then** `flutter test` зелёный, headless round-trip не сломан, `dotnet build native/Comics.slnx` — 0 ошибок.

### Should Have

- Регистрация типов файлов `.comics`/`.puzzle` на iOS (UTI) и Android (intent-filter), чтобы файлы открывались из Files/проводника.
- Обработка scoped storage: контент, полученный из SAF/document picker, корректно импортируется (копия во внутреннее хранилище приложения).

### Won't Have (This Iteration)

- Изменения C#-кода (`native/` остаётся как есть; Windows-interop из прошлого flow не трогаем).
- Изменение формата данных `.comics`.
- Мобильная переработка дизайна за пределами того, что уже умеет адаптивный макет.
- Web-платформа.

## Constraints

- **Git**: агент не выполняет git-команды и не трогает `.git` (правило пользователя).
- **Рабочая зона**: `apps/comics-editor-v2.9` + этот flow-каталог; `design/`, `legacy/`, `libs/` — read-only.
- **C#-код**: не переписывается; допустимы только новые обвязочные проекты/файлы, если выбран FFI-вариант (Q1).
- **Окружение**: машина — macOS (iOS-сборка возможна; Android — при наличии SDK; проверка на реальных устройствах может быть недоступна — тогда эмулятор/симулятор либо отложенная проверка).

## Open Questions

Все вопросы решены пользователем 2026-07-23:

- [x] **Q1. Слой данных на мобильных**: **.NET NativeAOT + FFI** — C#-ядро (те же линкованные исходники, что в Comics.Editor.Headless) компилируется в нативную библиотеку (iOS: статическая `.a` в Runner; Android: `.so` в jniLibs) с C-экспортами (`UnmanagedCallersOnly`), вызовы через `dart:ffi`. Протокол сохраняется: JSON-запрос → JSON-ответ (те же методы openComics/saveComics/…), меняется только транспорт (FFI вместо stdio-процесса). Десктоп продолжает работать через процесс.
  - **Признанные риски** (принимаются, план должен их закрыть или явно отложить): NativeAOT для iOS/Android требует .NET mobile-workloads и NDK/Xcode; Newtonsoft.Json (reflection + TypeNameHandling) под NativeAOT требует полного рутинга типов (TrimmerRootDescriptor/rd.xml) — работоспособность подтверждается тестом на sample.comics; Android NativeAOT — экспериментальный статус в .NET 10.
  - **Fallback** (если NativeAOT непроходим на конкретной платформе): Dart-реализация I/O для этой платформы как временная мера — отдельным решением пользователя.
- [x] **Q2. Пакет файловых диалогов**: **`file_picker`** — open на всех платформах + save-диалог с записью байт на iOS/Android/desktop.
- [x] **Q3. Минимальные версии ОС**: дефолты Flutter (iOS 13+, Android API 26+).
- [x] **Q4. Сохранение на мобильных**: **песочница + Export** — Save пишет в копию документа в хранилище приложения (без диалогов), отдельная команда Export/Share выгружает файл через системный диалог.

## References

- `flows/sdd-comics-editor-v2.9/` — завершённый flow (архитектура, headless-ядро, mapping)
- `apps/comics-editor-v2.9/lib/src/bridge/` — core_client, models_mapping
- `design/comics-editor-maket-dart-v3/README.md` — адаптивные breakpoints макета
- `apps/comics-editor-v2.9/test/fixtures/sample.comics` — образец файла

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-07-23
- [x] Notes: «reqs approved». Q1 — NativeAOT+FFI; Q2 — file_picker; Q3 — дефолты Flutter; Q4 — песочница+Export.
