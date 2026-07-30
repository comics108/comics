# Requirements: comics-editor-v2.9-fixes2 — четыре независимых доработки

> Version: 1.1
> Status: APPROVED
> Last Updated: 2026-07-25

## Problem Statement

Пользователь запросил «дореализуй то, что нужно дореализовать» без конкретного списка. По результатам поиска по кодовой базе и предыдущим SDD-флоу пользователю предложены кандидаты; выбраны четыре независимых пункта (см. `AskUserQuestion`, 2026-07-25):

- **A. Windows hostfxr/nethost interop** — C++-плагин (`windows/editor_plugin/editor_plugin.cpp`) не вызывает уже реализованный C#-мост (`Comics.Editor.Flutter`), всегда возвращает `not_implemented`.
- **B. Linux headless CI-краш на первом `ping`** — известный, дважды подтверждённый нерешённым баг (`sdd-comics-editor-v2.9-android-ios`, `sdd-comics-editor-v2.9-fixes1`), воспроизводится только на реальном GH Actions `ubuntu-latest`.
- **C. Легаси `// TODO remove convert functionality`** в `ComicsViewModel.cs` — не исследовано, происхождение до этих SDD-флоу.
- **D. Undo/Redo** — новая функциональность, сейчас отсутствует полностью (Ctrl+Z / Ctrl+Shift+Z или другая комбинация).

Это НЕ одна фича — четыре независимых доработки в разных частях системы (C++/interop, CI/Linux, легаси C#, новый Flutter-функционал). Ведутся в одном flow по решению пользователя (аналогично тому, как Windows CI-баг вёлся внутри `sdd-comics-editor-build`), но задачи независимы: любая может быть реализована/принята отдельно от других.

## Предварительное исследование (сделано на этапе Requirements)

### A. Windows hostfxr/nethost interop

- C#-сторона моста уже реализована и рабочая: `native/Comics.Editor.Flutter/EditorHost.cs` (STA-поток, WPF `Dispatcher`, показывает/скрывает/закрывает `Comics.Editor.MainWindow`) и `MethodChannelHandler.cs` (JSON-диспетчер методов `create`/`dispose`).
- C++-плагин (`windows/editor_plugin/editor_plugin.cpp:39-48`) не вызывает этот C#-код вообще — `HandleMethodCall` безусловно возвращает `result->Error("not_implemented", ...)`.
- CMake custom-target, публиковавший `Comics.Editor.Flutter.dll` в `build/windows/x64/dotnet`, был **отключён** (закомментирован, не удалён) в `sdd-comics-editor-build` именно из-за отсутствия потребителя — эта доработка его вернёт к жизни.
- Dart-сторона (`lib/src/bridge/wpf_editor_view.dart`) уже вызывает `MethodChannel('comics_editor')` с методами, соответствующими `MethodChannelHandler` — готова принимать реальный ответ вместо заглушки.

### B. Linux headless CI-краш на `ping`

- История: `sdd-comics-editor-v2.9-android-ios/04-implementation-log.md:159` — `flutter test` падал на `core_client_test.dart` с `CoreException: Core process exited` на первом же `client.call('ping')`; self-contained `Comics.Editor` (linux-x64) стартовал и почти сразу завершался.
- Локальная попытка воспроизвести (имитация через `bash coproc`, точное поведение `CoreClient`) в `ubuntu:24.04` под Docker (linux-arm64, единственная архитектура, доступная на этой машине без сломанной Rosetta/qemu на тот момент) — **сработала полностью**, включая реальное открытие `sample.comics`. Значит бинарник/протокол/логика корректны сами по себе — проблема специфична для amd64-окружения GH Actions и/или взаимодействия с `flutter test`, что не воспроизводится локально из-за архитектуры машины разработчика.
- `sdd-comics-editor-v2.9-fixes1` отдельно нашёл и исправил СМЕЖНЫЙ, но другой баг (`CoreClient.resolveBinary()` выбирал бинарник чужой ОС при одновременном наличии artefacts разных RID) — явно задокументировано, что это НЕ тот же баг, что здесь.
- Диагностика уже улучшена (stderr + exit code прокидываются в `CoreException`), но её реального содержимого (что фактически пишет процесс в stderr при падении на CI) в логах предыдущих флоу нет — то есть у нас есть улучшенный инструмент диагностики, но не факт, что кто-то читал его вывод с реального CI-прогона.

### C. `// TODO remove convert functionality`

- `native/Comics.Editor/ViewModel/ComicsViewModel.cs:247-266`, метод `Convert()`: для каждого изображения каждого слоя документа копирует файл во временную папку и вызывает `image.Update(folder, file, puzzle, popup)` (тот же метод, что используют обычные операции «заменить файл изображения») — эффект: принудительно прогоняет каждое изображение через текущую логику тайлинга/пересчёта размеров (`FileManager.UpdateTiles`), как если бы оно было только что импортировано заново.
- **Уточнение (исправляет предыдущий вывод)**: это НЕ мёртвый код — есть реальная кнопка «Convert» в `Controls/SettingsControl.xaml` (`Command="{Binding ConvertCommand}"`), `SettingsControl` встроен в `MainWindow.xaml`. Функциональность доступна пользователю прямо сейчас.
- `git blame`/`git log` по файлу — единственный коммит `first` (история этого репозитория начинается со squash-импорта всего кода v2.8), более ранняя история недоступна — невозможно установить из git, когда и почему появился TODO.
- **Решение пользователя (2026-07-25): оставить `Convert()` как есть**, функциональность не удаляется.

### D. Undo/Redo

- Полностью отсутствует — грепом по `lib/`/`native/Comics.Editor` не найдено реализации ни на Flutter, ни на C#-стороне (единственные совпадения на `undo`/`redo` — ложные срабатывания подстроки внутри `CoreDocument`/`coreDoc`).
- Архитектура состояния: `lib/src/ui/controller.dart` — `EditorController extends ChangeNotifier`, единый мутабельный источник истины (`doc`, `coreDoc`), ~15 дискретных методов-мутаторов (`addLayer`, `moveLayer`, `deleteSelected`, `toggleVisible`, `dragSelected`, `setImageFile`, `addSound`, `moveSound`, `addAnim`, `deleteAnim`, `editAnim`, `setCanvasSize`, `setLanguage`, и т.д.), каждый вызывает `notifyListeners()` в конце. Мутации — in-place (не immutable/redux-style).
- Уже существует JSON-сериализация всего документа (`comicsToCore`/`comicsFromCore` в `models_mapping.dart`) — пригодна как основа для snapshot-подхода к истории отмены (сериализовать `doc` в JSON до мутации → положить в стек), не требуя переписывать каждый из ~15 методов-мутаторов в обратимую команду.
- **Решение пользователя (2026-07-25)**: snapshot-стек (не command-pattern); одна запись истории на весь continuous-жест (drag/pan/zoom), не по кадрам; глубина истории не ограничена в рамках сессии.

## User Stories

### A. Windows hostfxr/nethost interop

**As a** пользователь Windows-версии редактора
**I want** видеть и использовать полноценный WPF-редактор (v2.8) внутри Flutter-приложения при нажатии «Открыть редактор» (или аналогичного действия)
**So that** функциональность v2.8 (New/Open/Save, слои, звуки, языки) доступна из нового Flutter-интерфейса, а не заглушки

### B. Linux headless CI-краш на `ping`

**As a** мейнтейнер CI
**I want** чтобы `build-linux`/Docker-Linux job в `build.yml`/`docker-build.yml` проходил тест `core_client_test.dart` без падения на первом `ping`
**So that** зелёный CI на Linux реально проверяет работоспособность headless-ядра, а не скрывает падающий тест/не блокирует пайплайн годами

### C. `// TODO remove convert functionality`

**As a** мейнтейнер кодовой базы
**I want** чтобы легаси-метод `Convert()` (уже решено — остаётся) получил точный комментарий вместо вводящего в заблуждение TODO
**So that** в коде не было ложного сигнала «это нужно удалить», когда решение — оставить

### D. Undo/Redo

**As a** пользователь редактора (comics/puzzle)
**I want** отменять (Ctrl+Z) и повторять (Ctrl+Shift+Z или аналог) последние изменения документа
**So that** можно безопасно экспериментировать с правками, не боясь необратимо испортить документ

## Acceptance Criteria

### A. Windows hostfxr/nethost interop — Must Have

1. **Given** Windows-сборка с реализованным hostfxr/nethost-интеропом
   **When** Flutter-сторона вызывает `MethodChannel('comics_editor').invokeMethod('create')`
   **Then** C++-плагин загружает `Comics.Editor.Flutter.dll` (через hostfxr) и вызывает `MethodChannelHandler.HandleMethodCall("create", argsJson)`, результат (успех/ошибка) возвращается обратно во Flutter как раньше делала заглушка (тот же контракт JSON-результата)
2. **Given** тот же интероп
   **When** вызывается `dispose`
   **Then** `EditorHost.Shutdown()` вызывается корректно (WPF-окно закрывается, поток останавливается) без падения приложения
3. **Given** реализованный интероп
   **When** CMake-сборка Windows выполняется в CI
   **Then** custom target `editor_plugin_csharp` (сейчас закомментирован в `windows/editor_plugin/CMakeLists.txt`) раскомментирован и снова публикует `Comics.Editor.Flutter.dll`, реальный Windows CI-прогон (`build-windows`) — зелёный (не полагаться только на локальную/macOS-проверку — см. handoff-заметку `sdd-comics-editor-build`)

### B. Linux headless CI-краш — Must Have

1. **Given** `build-linux` job (или `docker-build-linux`)
   **When** запускается `flutter test test/core_client_test.dart` на реальном GH Actions раннере
   **Then** тест проходит — `client.call('ping')` получает ответ, процесс не завершается преждевременно
2. **Given** найденная причина
   **When** документируется фикс
   **Then** явно указано, отличается ли она от уже исправленного бага `resolveBinary()` (`sdd-comics-editor-v2.9-fixes1`), и почему

### C. `// TODO remove convert functionality` — Must Have

1. **Given** решение оставить `Convert()`
   **When** правка применяется
   **Then** `// TODO remove convert functionality` заменён на комментарий, описывающий фактическое поведение (прогоняет все изображения документа через `image.Update`/`FileManager.UpdateTiles`, доступно через кнопку «Convert» в Settings) — без изменения самой логики метода
2. **Given** правка применена
   **When** собирается `dotnet build native/Comics.slnx`
   **Then** сборка чистая, существующие тесты не ломаются (это правка комментария, не поведения)

### D. Undo/Redo — Must Have

1. **Given** документ открыт в редакторе (comics или puzzle)
   **When** пользователь вносит изменение (добавление/удаление/перемещение слоя или звука, drag, изменение поля и т.п.) и нажимает Ctrl+Z
   **Then** последнее изменение отменяется, UI обновляется, соответствует состоянию до изменения
2. **Given** отменённое изменение
   **When** пользователь нажимает Ctrl+Shift+Z (redo)
   **Then** изменение повторно применяется
3. **Given** серия из N изменений
   **When** пользователь нажимает Undo N раз
   **Then** документ возвращается к состоянию при открытии (или к первому изменению — см. Open Questions про глубину истории)

### Should Have

- (D) Кнопки Undo/Redo в toolbar/top_bar (не только keyboard shortcuts) — доступность без клавиатуры
- (D) Визуальная индикация недоступности (disabled-состояние кнопки/пункта меню), когда стек пуст

### Won't Have (This Iteration)

- (D) Undo/Redo, переживающий закрытие и повторное открытие документа (персистентная история между сессиями) — только в рамках текущей сессии редактирования
- (A) Полноценная интеграция WPF-окна как embedded PlatformView внутри Flutter-окна (упоминается в комментариях кода как «следующий шаг») — в этой итерации WPF-окно остаётся отдельным top-level окном (как сейчас спроектировано в `EditorHost.ShowMainWindow`), не встраивается в дерево виджетов Flutter
- (B) Полный редизайн IPC-протокола `CoreClient`/`Comics.Editor.Headless` — если причина бага в протоколе, чиним минимально необходимое, не переписываем архитектуру

## Constraints

- **Git**: агент не выполняет git-команды (см. память `git-manual-only`) — пользователь коммитит/пушит вручную.
- **Windows (A)**: агент работает на macOS, реальная Windows-машина/CI недоступна для интерактивной проверки — верификация A возможна только через GitHub Actions логи, присылаемые пользователем (как в `sdd-comics-editor-build`).
- **Linux CI (B)**: то же самое — воспроизведение только через реальный CI-прогон, локальная Docker-эмуляция на этой машине ограничена архитектурой (arm64 vs CI amd64), хотя `--platform linux/amd64` через Rosetta теперь работает (см. `sdd-comics-editor-build`) — можно использовать `tool/docker-build.sh linux` для попытки локальной x64-верификации перед CI.
- **Обратная совместимость**: изменения A/B/C не должны ломать существующие тесты (`flutter test`, `dotnet build native/Comics.slnx`) на macOS/Linux desktop путях.
- **D (Undo/Redo) — область охвата**: должно работать одинаково для comics и puzzle документов (оба используют один и тот же `EditorController`).

## Open Questions

Решено пользователем (2026-07-25):
- [x] **C**: `Convert()` остаётся, не удаляется (см. Acceptance Criteria выше — только правка комментария).
- [x] **D**: подход — snapshot-стек (сериализация `doc` в JSON через существующие `comicsToCore`/`comicsFromCore` до каждой мутации), не command-pattern.
- [x] **D**: continuous-жесты (drag/pan/zoom) — одна запись в истории на весь жест (start→release), не по кадрам.
- [x] **D**: глубина истории — неограничена в рамках сессии редактирования.

Остаётся открытым:
- [ ] **B**: если реальный CI-прогон с улучшенной диагностикой (stderr+exit code) даст новую информацию — потребуется ли отдельная итерация расследования перед фиксом, или фикс можно спроектировать сразу по гипотезам из прошлых флоу? (Решается по факту на этапе Implementation — не блокирует Specifications.)
- [ ] **D**: Undo должен быть доступен во время preview-режима (`togglePreview()`) или только в режиме редактирования?

## References

- `flows/sdd-comics-editor-build/04-implementation-log.md` — история отключения CMake custom target (A)
- `flows/sdd-comics-editor-v2.9-android-ios/04-implementation-log.md:159` — история Linux ping-краша (B)
- `flows/sdd-comics-editor-v2.9-fixes1/04-implementation-log.md:28` — подтверждение, что resolveBinary-фикс НЕ тот же баг, что B
- `native/Comics.Editor/ViewModel/ComicsViewModel.cs:247` — `Convert()` (C)
- `lib/src/ui/controller.dart` — `EditorController` (D)

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-07-25
- [x] Notes: «requirements approved»
