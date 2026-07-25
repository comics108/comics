# Implementation Log: comics-editor-v2.9-fixes1

> Started: 2026-07-25
> Plan: [03-plan.md](03-plan.md)

## Progress Tracker

| Task | Status | Notes |
|------|--------|-------|
| 1.1 OS-aware RID-фильтр в `resolveBinary()` | Done | `flutter analyze` чисто, `core_client_test.dart` проходит нативно на macOS |
| 1.2 Удалить `publish/osx-arm64/` | Done | Удалено; пересобрано заново через `tool/build_headless.sh` для проверки Task 1.1 — не регрессия, просто локальный dev-артефакт |

## Session Log

### Session 2026-07-25 - Claude

**Started at**: обнаружено по ходу `sdd-comics-editor-build` (Docker Build verification)
**Context**: `tool/docker-build.sh linux` упал на `core_client_test.dart` — `CoreClient` запускал macOS Mach-O бинарник внутри Linux-контейнера.

#### Completed
- Task 1.1: `lib/src/bridge/core_client.dart` — `resolveBinary()` dev-режимный список RID теперь строится через `switch (Platform.operatingSystem)` (macos → osx-arm64/osx-x64; linux → linux-x64/linux-arm64; windows → win-x64) вместо фиксированного списка всех RID сразу.
  - Files changed: `lib/src/bridge/core_client.dart`
  - Verified by: `flutter analyze` (чисто) + `flutter test test/core_client_test.dart` на macOS (проходит после пересборки headless-ядра)
- Task 1.2: удалена `native/Comics.Editor.Headless/publish/osx-arm64/` (gitignored, локальный артефакт прошлой сборки — источник бага в этой сессии).
  - Verified by: `ls native/Comics.Editor.Headless/publish/`

#### Discoveries
- Баг обнаружен исключительно из-за одновременного наличия `publish/osx-arm64/` (старый) и `publish/linux-x64/` (свежий, из Docker Build) в одной рабочей копии, бинд-смонтированной в Linux-контейнер. На чистом CI-раннере (`ubuntu-latest`, свежий checkout) эта конкретная комбинация артефактов не воспроизводится — поэтому это, вероятно, **не** тот же баг, что нерешённый «Linux headless-процесс падает на CI на первом ping» из `sdd-comics-editor-v2.9-android-ios`, хотя относится к той же категории (недостаточно надёжный поиск/выбор бинарника ядра). Тот баг остаётся отдельным, не закрыт этим фиксом.

**Ended at**: оба таска завершены
**Handoff notes**: следующий шаг — вернуться в `sdd-comics-editor-build` и повторно прогнать `tool/docker-build.sh linux`, теперь без стороннего RID-артефакта и с исправленным `resolveBinary()`.

---

## Completion Checklist

- [x] All tasks completed
- [x] Tests passing (macOS native)
- [x] No regressions
- [x] Documentation updated if needed (n/a — internal fix)
- [x] Status updated to COMPLETE

---

# Iteration 2: Canvas zoom/pan (viewport camera)

> Started: 2026-07-25
> Plan: [03-plan.md](03-plan.md), секция "Iteration 2"

## Progress Tracker

| Task | Status | Notes |
|------|--------|-------|
| 2.1 Viewport-состояние в `EditorController` | Done | `canvasViewport`, `viewportKey`, `kCanvasZoomMin/Max/Step`, `zoomBy()`, `resetViewport()`; сброс в `openPath`/`newDoc`/`openRecent`; `dispose()` обновлён |
| 2.2 `_Stage` → `InteractiveViewer` | Done | Fit-расчёт `pageW`/`pageH` не тронут, `InteractiveViewer` обёрнут вокруг центрированного `SizedBox` |
| 2.3 `_LayerItem` drag-delta коррекция | Done | `onPanUpdate` теперь делит на `(k * canvasViewport.value.getMaxScaleOnAxis())` |
| 2.4 `_ZoomControl` rewiring | Done | `ListenableBuilder(listenable: c.canvasViewport)`, +/- → `zoomBy()` с focal-point через `viewportKey`, Fit → `resetViewport()`, guard `!c.isPuzzle` убран |
| 2.5 Ручная верификация жестов | Done | Пользователь прогнал чеклист Manual Verification (`02-specifications.md`) вручную и подтвердил ("confirm") — mouse wheel, trackpad pinch/pan, touch, +/- кнопки, Fit, drag слоя на разных zoom, клампинг pan |

## Session Log

### Session 2026-07-25 - Claude

**Started at**: после approval Requirements → Specifications → Plan (единая сессия)
**Context**: Пользователь запросил интерактивный zoom/pan канваса (trackpad pinch/pan, mouse wheel zoom, работающие +/- кнопки).

#### Completed
- Task 2.1: `lib/src/ui/controller.dart` — добавлены `canvasViewport` (`TransformationController`), `viewportKey` (`GlobalKey`), константы `kCanvasZoomMin=0.25`/`kCanvasZoomMax=4.0`/`kCanvasZoomStep=1.25`, методы `zoomBy(factor, focalPoint)` (матрица translate→scale→translate вокруг focal-точки через `toScene()`) и `resetViewport()`. Вызовы `resetViewport()` добавлены в `openPath()`, `newDoc()`, `openRecent()`. `canvasViewport.dispose()` добавлен в `dispose()`.
  - Files changed: `lib/src/ui/controller.dart`
  - Verified by: `flutter analyze`
- Task 2.2: `lib/src/ui/widgets/canvas_view.dart` (`_Stage`) — центрированный `SizedBox` со страницей обёрнут в `InteractiveViewer` (`key: c.viewportKey`, `transformationController: c.canvasViewport`, `minScale`/`maxScale` из констант контроллера, `boundaryMargin: EdgeInsets.all(200)`, `trackpadScrollCausesScale: false`). Fit-математика (`LayoutBuilder`, `pageW`/`pageH`, `doc.scale` для puzzle) не изменена.
  - Files changed: `lib/src/ui/widgets/canvas_view.dart`
- Task 2.3: `_LayerItem.onPanUpdate` — delta теперь делится на `(k * c.canvasViewport.value.getMaxScaleOnAxis())` вместо только `k`, чтобы drag слоя оставался 1:1 с курсором при любом viewport-zoom.
  - Files changed: `lib/src/ui/widgets/canvas_view.dart`
- Task 2.4: `_ZoomControl` — обёрнут в `ListenableBuilder(listenable: c.canvasViewport)`; % считается из `canvasViewport.value.getMaxScaleOnAxis()`; кнопки `+`/`-` вызывают `c.zoomBy(factor, focal)`, где `factor = kCanvasZoomStep`/`1/kCanvasZoomStep`, `focal` — центр `RenderBox` по `c.viewportKey` (fallback `Offset.zero`, если ещё не смонтирован); Fit → `c.resetViewport()`; guard `if (!c.isPuzzle) return;` убран — кнопки работают одинаково для comics и puzzle.
  - Files changed: `lib/src/ui/widgets/canvas_view.dart`
- Попутный фикс: `Matrix4.translate()`/`.scale()` в `zoomBy()` дали analyzer-info о deprecation (новый vector_math API) — заменено на `translateByDouble()`/`scaleByDouble()`.

#### Verification performed
- `flutter analyze` — чисто, 0 issues (после фикса deprecation-info на `translateByDouble`/`scaleByDouble`).
- `flutter test` — все 8 тестов проходят (`widget_test.dart`, `dart_io_core_test.dart` ×3, `core_client_test.dart` ×2, `ffi_core_test.dart` ×2) — без регрессий.
- `flutter run -d macos` — приложение собирается и запускается без ошибок (Dart VM Service поднялся, процесс `comics_editor` + headless-ядро `Comics.Editor` в списке процессов), значит `InteractiveViewer`-обёртка не ломает рендер/запуск.

#### Discoveries
- **Ограничение окружения**: в этой sandboxed-сессии нет разрешений Accessibility и Screen Recording для управляющего терминала (`osascript`/System Events → `-1719 not allowed assistive access`; `screencapture` → `could not create image from display`). Это значит: автоматизированная GUI-верификация (клик по кнопкам +/-, скриншот, симуляция pinch/scroll/трэкпада) в этой сессии физически невозможна — не решается кодом, только выдачей прав в System Settings → Privacy & Security на машине пользователя.
- Из-за этого **Task 2.5 (ручная верификация жестов) выполнена лишь частично**: подтверждено, что код компилируется, анализируется без ошибок, существующие тесты не сломаны, приложение запускается и не падает с новым `InteractiveViewer`. **Не подтверждено интерактивно**: mouse wheel zoom, trackpad pinch/pan, touch pinch/pan (Android/iOS), корректность focal-point у кнопок +/-, поведение `boundaryMargin` "на глаз", отсутствие конфликта gesture arena между drag слоя и pan канваса (риск, заранее описанный в `02-specifications.md` Edge Cases с Plan B fallback).
- Приложение (dev-сессия `flutter run -d macos`) было остановлено (`kill`) после проверки старта, т.к. дальнейшее взаимодействие с GUI недоступно в этой сессии.

**Ended at**: Iteration 2 завершена — пользователь подтвердил ручную верификацию жестов ("confirm")
**Handoff notes**: конфликт gesture arena (canvas pan vs drag слоя), заранее описанный как риск в спеке, по факту не проявился (пользователь подтвердил чеклист без замечаний) — Plan B (Task 2.6) не потребовался, остаётся задокументированным на будущее, если всплывёт позже.

---

## Completion Checklist

- [x] Все запланированные code-задачи (2.1–2.4) выполнены
- [x] `flutter analyze` — чисто
- [x] `flutter test` — без регрессий (8/8 passed)
- [x] Приложение собирается и запускается (`flutter run -d macos`)
- [x] Интерактивная ручная верификация жестов (Task 2.5) — подтверждена пользователем
- [x] Status → COMPLETE
