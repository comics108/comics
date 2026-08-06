# Implementation Plan: comics-editor-v2.9-fixes1 — resolveBinary() OS-aware fallback

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-07-25
> Specifications: [02-specifications.md](02-specifications.md) (APPROVED)

## Summary

Один точечный фикс + одна очистка артефакта. Без фаз — оба таска независимы и делаются в одной сессии.

## Task Breakdown

#### Task 1.1: OS-aware RID-фильтр в `resolveBinary()`
- **Description**: Заменить константный список RID в dev-режимном цикле на список, зависящий от `Platform.operatingSystem` (macOS → `osx-arm64`/`osx-x64`; linux → `linux-x64`/`linux-arm64`; windows → `win-x64`).
- **Files**: `lib/src/bridge/core_client.dart` — Modify
- **Dependencies**: None
- **Verification**: `flutter analyze`; `flutter test test/core_client_test.dart` на нативной платформе (macOS) — проходит как раньше
- **Complexity**: Low

#### Task 1.2: Удалить устаревший артефакт
- **Description**: Удалить `native/Comics.Editor.Headless/publish/osx-arm64/` (gitignored, локальный, не часть репозитория).
- **Files**: `native/Comics.Editor.Headless/publish/osx-arm64/` — Delete
- **Dependencies**: None
- **Verification**: `ls native/Comics.Editor.Headless/publish/` — директории больше нет
- **Complexity**: Low

## File Change Summary

| File | Action | Reason |
|------|--------|--------|
| `lib/src/bridge/core_client.dart` | Modify | OS-aware фильтрация RID-кандидатов в dev-режиме |
| `native/Comics.Editor.Headless/publish/osx-arm64/` | Delete | Устаревший локальный артефакт, источник бага в этой сессии |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Фильтр слишком узкий, ломает существующий сценарий на какой-то платформе | Low | Med | Список кандидатов внутри одной ОС не сокращается (obj macOS — оба RID остаются), меняется только межплатформенная фильтрация |

## Rollback Strategy

1. `git diff`/`git checkout -- lib/src/bridge/core_client.dart` (пользователь вручную, per git-manual-only) — однострочная точечная правка, тривиально откатить.

## Checkpoints

- [ ] `flutter analyze` — чисто
- [ ] `flutter test test/core_client_test.dart` на macOS — без регрессий
- [ ] Повторный `tool/docker-build.sh linux` (`sdd-comics-editor-build`) — `core_client_test.dart` проходит в Docker

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-07-25
- [x] Notes: «сделай сейчас».

---

# Iteration 2: Canvas zoom/pan (viewport camera)

> Version: 1.0
> Status: DRAFT — pending review
> Last Updated: 2026-07-25
> Specifications: [02-specifications.md](02-specifications.md), секция "Iteration 2" (APPROVED)

## Summary

5 задач, последовательная зависимость 1 → (2,3) → 4 → 5 (ручная верификация). Один widget-файл (`canvas_view.dart`) + контроллер (`controller.dart`), без изменений в моделях/бизнес-логике/бриджах.

## Task Breakdown

#### Task 2.1: Viewport-состояние в `EditorController`
- **Description**: Добавить `TransformationController canvasViewport`, константы `kCanvasZoomMin/Max/Step`, методы `zoomBy(double factor, Offset focalPoint)` и `resetViewport()`; добавить `GlobalKey viewportKey` (нужен `_ZoomControl`, чтобы найти `RenderBox` `InteractiveViewer` для focal point кнопок +/-, т.к. `_ZoomControl` — не потомок `_Stage`, см. Edge Case в спеке). Вызвать сброс `canvasViewport.value = Matrix4.identity()` в `openPath()`, `newDoc()`, `openRecent()`. Добавить `canvasViewport.dispose()` в `dispose()`.
- **Files**: `lib/src/ui/controller.dart` — Modify
- **Dependencies**: None
- **Verification**: `flutter analyze`; беглый ручной тест — `zoomBy`/`resetViewport` вызываются без исключений на пустом контроллере
- **Complexity**: Low

#### Task 2.2: `_Stage` — обернуть страницу в `InteractiveViewer`
- **Description**: Обернуть текущий `Center(child: SizedBox(...))` в `InteractiveViewer` с `key: c.viewportKey`, `transformationController: c.canvasViewport`, `minScale`/`maxScale` из констант, `boundaryMargin: EdgeInsets.all(200)`, `trackpadScrollCausesScale: false`. Fit-расчёт (`pageW`/`pageH`) не меняется.
- **Files**: `lib/src/ui/widgets/canvas_view.dart` (`_Stage`) — Modify
- **Dependencies**: Task 2.1 (нужны `canvasViewport`, `viewportKey`, константы)
- **Verification**: `flutter run` (desktop) — канвас открывается в состоянии Fit, как раньше (регрессия by default при zoom=identity недопустима)
- **Complexity**: Low

#### Task 2.3: `_LayerItem` — коррекция drag-delta под viewport zoom
- **Description**: В `onPanUpdate` делить `d.delta.dx/dy` на `(k * c.canvasViewport.value.getMaxScaleOnAxis())` вместо просто `k`.
- **Files**: `lib/src/ui/widgets/canvas_view.dart` (`_LayerItem`) — Modify
- **Dependencies**: Task 2.1 (нужен `canvasViewport`)
- **Verification**: Ручной тест на этапе Task 2.5 — drag слоя 1:1 с курсором при zoom=100%, 50%, 200%
- **Complexity**: Low

#### Task 2.4: `_ZoomControl` — переключить +/-/Fit/% на `canvasViewport`
- **Description**: Обернуть содержимое в `ListenableBuilder(listenable: c.canvasViewport, ...)`; % считать из `getMaxScaleOnAxis()`; `+`/`-` → `c.zoomBy(factor, focalPoint)`, где `focalPoint` — центр `RenderBox` по `c.viewportKey` (не по `context` самой кнопки — см. Edge Case в спеке); убрать guard `if (!c.isPuzzle) return;`; Fit → `c.resetViewport()`.
- **Files**: `lib/src/ui/widgets/canvas_view.dart` (`_ZoomControl`) — Modify
- **Dependencies**: Task 2.1, Task 2.2 (нужен смонтированный `InteractiveViewer` с `viewportKey`, чтобы `RenderBox` был доступен)
- **Verification**: `flutter analyze`; ручной тест — клики +/- меняют % и визуальный zoom для comics И puzzle документов; Fit сбрасывает
- **Complexity**: Medium (focal-point математика через `toScene`/matrix translate-scale-translate — см. спек)

#### Task 2.5: Ручная верификация жестов (checkpoint, без изменений кода)
- **Description**: Прогнать полный чеклист Manual Verification из `02-specifications.md` — mouse wheel, trackpad pinch/pan, touch pinch/pan (Android/iOS), +/- кнопки на обоих типах документа, Fit, drag слоя при разных zoom, клампинг pan (`boundaryMargin`). Если обнаружится конфликт gesture arena (canvas pan vs layer drag) — реализовать Plan B из спеки (`EditorController.isDraggingLayer` + `Listener(onPointerDown)` в `_LayerItem` + `InteractiveViewer(panEnabled: !c.isDraggingLayer)`) как Task 2.6 (доп. задача, только если потребуется).
- **Files**: N/A (verification only; потенциально `lib/src/ui/controller.dart` + `canvas_view.dart` повторно, если понадобится Plan B)
- **Dependencies**: Tasks 2.1–2.4
- **Verification**: Чеклист из Testing Strategy (`02-specifications.md`) — все пункты пройдены
- **Complexity**: Medium (охватывает несколько платформ; trackpad/touch тестируются там, где физически доступны — macOS trackpad точно, mobile — по доступности эмулятора/устройства)

## File Change Summary

| File | Action | Reason |
|------|--------|--------|
| `lib/src/ui/controller.dart` | Modify | Новое transient viewport-состояние (`canvasViewport`, `viewportKey`, `zoomBy`, `resetViewport`), сброс в 3 местах, dispose |
| `lib/src/ui/widgets/canvas_view.dart` | Modify | `_Stage` → `InteractiveViewer`; `_LayerItem` drag-delta коррекция; `_ZoomControl` переключён на `canvasViewport`, guard `!c.isPuzzle` убран |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Gesture arena конфликт: `InteractiveViewer` pan "съедает" drag слоя | Low-Med | Med | Fallback Plan B уже спроектирован в 02-specifications.md (Edge Cases); Task 2.5 явно предусматривает его как Task 2.6 при необходимости |
| `boundaryMargin: 200` ощущается неверно (мало/много) на реальном UI | Med | Low | Чисто визуальная подстройка одного числа на этапе Task 2.5, не архитектурная правка |
| `_ZoomControl` focal point (Task 2.4) не туда указывает при неудачном `RenderBox` (например, `viewportKey` не смонтирован при первом клике) | Low | Low | Guard: если `viewportKey.currentContext == null`, fallback на `zoomBy` без focal-компенсации (zoom вокруг текущего центра трансформации, `Offset.zero` в scene-space) |
| Регрессия существующих widget-тестов, завязанных на старое поведение `_ZoomControl`/`doc.scale` | Low | Low | Проверено заранее: `test/` не содержит ссылок на `canvas_view`/`ZoomControl`/`doc.scale` (grep выполнен на этапе Specifications) |

## Rollback Strategy

1. `git diff`/`git checkout -- lib/src/ui/controller.dart lib/src/ui/widgets/canvas_view.dart` (пользователь вручную, per git-manual-only) — изменения локализованы в двух файлах, тривиально откатить одним махом.

## Checkpoints

- [ ] Task 2.1 — `flutter analyze` чисто
- [ ] Task 2.2 — канвас рендерится в Fit-состоянии как раньше при открытии документа
- [ ] Task 2.3 — drag слоя корректен на разных zoom-уровнях (проверяется вместе с 2.5)
- [ ] Task 2.4 — +/- и Fit работают на comics и puzzle
- [ ] Task 2.5 — полный чеклист Manual Verification из спеки пройден (или задокументированы платформенные ограничения, если часть жестов физически не проверяема в текущей среде — напр. нет доступа к реальному touch-устройству)
- [ ] `flutter analyze` — чисто
- [ ] `flutter test` — без регрессий

---

## Approval

- [ ] Reviewed by:
- [ ] Approved on:
- [ ] Notes:
