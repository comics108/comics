# Status: sdd-comics-editor-v2.9-fixes2

## Current Phase

IMPLEMENTATION

## Phase Status

IN PROGRESS

## Last Updated

2026-07-25 by Claude

## Blockers

- Track B (Linux ping): Task B.1 требует реального CI-прогона (`build-linux`) или `tool/docker-build.sh linux` — агент не может триггернуть это сам, ждёт пользователя
- Track A (Windows): верификация (Task A.6) требует реального Windows CI-прогона — агент пишет код, пользователь коммитит/пушит/присылает лог
- Track D.7: ручная интерактивная верификация (Ctrl+Z/Ctrl+Shift+Z в реальном UI) — агент не может провести GUI-тест в песочнице, нужен пользователь

## Progress

- [x] Requirements drafted (scope: A. Windows hostfxr interop, B. Linux ping CI-краш, C. легаси `Convert()` TODO, D. Undo/Redo)
- [x] Requirements approved (2026-07-25)
- [x] Specifications drafted (все 4 раздела — A/B/C/D)
- [x] Specifications approved (2026-07-25)
- [x] Plan drafted (4 независимых трека A/B/C/D, см. `03-plan.md`)
- [x] Plan approved (2026-07-25)
- [x] Implementation started
- [x] Track C — done (`dotnet build` чистый)
- [x] Track D — код + тесты готовы (20 новых тестов зелёные, `flutter analyze` чистый, регрессий нет); D.7 ручная верификация ждёт пользователя. Два отклонения от Specifications задокументированы в `04-implementation-log.md` (снапшот через `ComicsDoc.clone()` вместо `comicsToCore`/`comicsFromCore` — `coreDoc` может быть null; побочный фикс `coreDoc = null` в `newDoc()`/`openRecent()`)
- [x] Track A — код готов (A.1–A.5): `hostfxr_bootstrap.h/.cpp`, `NativeExports.cs`, `editor_plugin.cpp` реальный вызов вместо `not_implemented`, CMake custom target раскомментирован + `POST_BUILD` copy в `runner/CMakeLists.txt`, `dispose()` в `wpf_editor_view.dart`. **C++/CMake не верифицированы** (нужен реальный Windows-тулчейн) — только `dotnet build`/`flutter analyze`/`flutter test` пройдены там, где применимо (macOS). A.6 (реальный `build-windows`) — ждёт пользователя
- [ ] Track B — не начат (ждёт Task B.1 от пользователя)
- [ ] Implementation complete (по трекам — см. `04-implementation-log.md`)

## Context Notes

Scope (все 4 пункта подтверждены пользователем 2026-07-25):

1. **A. Windows hostfxr/nethost interop** — C++-плагин (`editor_plugin.cpp`) не вызывает уже реализованный C#-мост (`Comics.Editor.Flutter`). На Specifications найдены 2 доп. пробела: (а) нет копирования опубликованной `Comics.Editor.Flutter.dll` из build-tree в упакованный `runner/Release/` — нужен `POST_BUILD` copy в `windows/runner/CMakeLists.txt`; (б) Dart-сторона (`wpf_editor_view.dart`) никогда не вызывает `dispose` — нужно добавить `State.dispose()` override. Дизайн: hostfxr резолвится вручную (без NuGet nethost.h) через `DOTNET_ROOT`/`host\fxr\<версия>`; новый C#-экспорт `NativeExports.HandleMethodCall`/`FreeResultString` (`[UnmanagedCallersOnly]`, UTF-16 строки).
2. **B. Linux ping CI-краш** — нерешённый баг (`sdd-comics-editor-v2.9-android-ios`, подтверждено НЕ тем же багом, что `resolveBinary()` из `fixes1`). Спецификация НЕ содержит дизайна фикса — только протокол расследования (реальный CI-прогон → читать stderr из уже улучшенной диагностики → сузить до одной из 4 гипотез — см. `02-specifications.md`).
3. **C. `Convert()` TODO** — решено пользователем: оставить, только заменить комментарий (реальная функциональность — кнопка «Convert» в Settings, не мёртвый код, как предполагалось изначально).
4. **D. Undo/Redo** — новая функциональность, отсутствует полностью. Дизайн: snapshot-стек (`EditHistory`, новый класс в `lib/src/ui/edit_history.dart`) поверх существующих `comicsToCore`/`comicsFromCore`; транзакции — `beginTransaction`/`commitTransaction`, дискретные мутаторы оборачиваются хелпером `_withHistory`, continuous-жест (drag слоя) — явные `beginGestureHistory`/`commitGestureHistory` вокруг `onPanStart`/`onPanEnd` в `canvas_view.dart`; клавиши — `Shortcuts`/`Actions` (не raw keyboard listener, чтобы не перебивать встроенный undo в фокусированных `TextField`). Решено пользователем: snapshot (не command-pattern), одна запись истории на весь жест, история не ограничена в рамках сессии.

## Fork History

- Новый flow (не форк), создан 2026-07-25.

## Next Actions

1. Пользователь: закоммитить/запушить Track A (проверить `git status`/`git diff` перед пушем — см. прецедент в `sdd-comics-editor-build`, где правка `build.yml` один раз осталась незакоммиченной), запустить `build-windows`, прислать лог (A.6)
2. Пользователь: вручную протестировать Undo/Redo в реальном UI (D.7) — Ctrl+Z/Ctrl+Shift+Z, кнопки в TopBar, drag слоя как один шаг истории
3. Пользователь: запустить `build-linux`/`tool/docker-build.sh linux` и прислать реальный вывод `CoreException` (Task B.1) — нужно для дизайна фикса Track B
