# Requirements: comics-editor-v2.9-fixes1 — точечные баг-фиксы прикладной логики

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-07-25

## Problem Statement

Обнаружено в ходе `sdd-comics-editor-build` (Docker-верификация Linux-сборки): `CoreClient.resolveBinary()` в `lib/src/bridge/core_client.dart` в dev-режиме (fallback-поиск publish-папки вверх от CWD, используется при `flutter test`/`flutter run`, когда бандл-путь `$exeDir/data/comics-core/...` недоступен) перебирает RID-кандидаты в жёстко заданном порядке (`osx-arm64`, `osx-x64`, `linux-x64`, `linux-arm64`, `win-x64`) и возвращает первый существующий на диске путь — **без проверки `Platform.operatingSystem`**.

Если в рабочей копии одновременно лежат publish-артефакты нескольких платформ (например, старая `native/Comics.Editor.Headless/publish/osx-arm64/` с прошлой локальной macOS-сборки и свежая `publish/linux-x64/` от Docker-сборки), метод молча выбирает `osx-arm64` первым и пытается запустить macOS Mach-O бинарник на Linux. Результат — Linux shell пытается интерпретировать бинарник как скрипт: `Syntax error: word unexpected (expecting ")")`, процесс падает мгновенно, `CoreClient.start()` бросает `CoreException`. Это заблокировало верификацию `test/core_client_test.dart` в Docker Build (`sdd-comics-editor-build`).

Этот flow — не про сборку/CI/Docker (эта область — `sdd-comics-editor-build`, где трогать бизнес-логику решено не делать), а про сам баг в прикладном Dart-коде. Правки логики и точечные баг-фиксы `comics-editor-v2.9`, обнаруженные по ходу работы над другими flow, документируются здесь.

## User Stories

**As a** разработчик, запускающий тесты локально (или в Docker) на любой машине, где раньше собирались бинарники под другую платформу
**I want** чтобы `resolveBinary()` в dev-режиме выбирал бинарник, соответствующий текущей ОС/архитектуре
**So that** наличие устаревших publish-артефактов другой платформы в рабочей копии не приводило к попытке запуска чужого бинарника

## Acceptance Criteria

### Must Have

1. **Given** dev-режим поиска (`Directory.current` вверх на несколько уровней), несколько `publish/<rid>/` директорий существуют одновременно
   **When** `resolveBinary()` формирует список RID-кандидатов
   **Then** кандидаты фильтруются так, чтобы проверялся только RID (или RID'ы), соответствующие текущей `Platform.operatingSystem` — бинарник чужой ОС не выбирается, даже если существует на диске

2. **Given** старая директория `native/Comics.Editor.Headless/publish/osx-arm64/` в рабочей копии `apps/comics-editor-v2.9` (артефакт прошлой локальной сборки, не связан с текущим кодом)
   **When** флоу завершается
   **Then** директория удалена — не мусорит рабочую копию и не может снова спровоцировать эту же ошибку

### Won't Have (This Iteration)

- Изменения сборки/CI/Docker — область `sdd-comics-editor-build`, не трогается здесь.
- Расследование отдельного, ранее не решённого CI-бага «Linux headless-процесс падает на CI на первом `ping`» (`sdd-comics-editor-v2.9-android-ios`) — возможно смежно по классу ошибки, но не тот же баг (на чистом CI-раннере нет постороннего RID-артефакта, провоцирующего именно эту ветку). Остаётся отдельным, не закрывается автоматически этим фиксом.

## Constraints

- **Git**: агент не выполняет git-команды (`apps/comics-editor-v2.9` — отдельный git-репозиторий, управляется пользователем вручную).
- **Область**: только `lib/src/bridge/core_client.dart` — не трогать сборочную инфраструктуру.

## References

- `flows/sdd-comics-editor-build/` — где обнаружен баг (Docker Build, Linux verification)
- `flows/sdd-comics-editor-v2.9-android-ios/04-implementation-log.md` — незакрытый смежный CI-баг

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-07-25
- [x] Notes: обнаружено и утверждено к немедленному исправлению в ходе `sdd-comics-editor-build` («и то, и другое» + «сделай сейчас»); формальная фиксация — здесь, отдельно от build-flow.

---

# Iteration 2: Canvas zoom/pan (viewport camera)

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-07-25

## Problem Statement

`CanvasView` (`lib/src/ui/widgets/canvas_view.dart`) сейчас не имеет никакой интерактивной навигации: `_Stage` — статичный `LayoutBuilder` + `Center`, без панорамирования и без обработки жестов масштабирования (нет `InteractiveViewer`, `Listener(onPointerSignal:)`, `onScaleStart/onScaleUpdate`). Единственный связанный со «scale» механизм — бизнес-поле `ComicsDoc.scale` (puzzle Scale, 0.125–1, зеркалит оригинальный WPF `Puzzle.Scale`, влияет на экспорт), управляемое кнопками `_ZoomControl` (+/-/Fit). Эти кнопки — no-op для `DocType.comics` (`_bump()` возвращает сразу, `if (!c.isPuzzle) return;`), т.к. в оригинале comics — fixed-fit.

Пользователь хочет полноценную навигацию по канвасу как в обычном графическом редакторе: панорамирование трэкпадом/тачем, pinch-to-zoom, зум колесом мыши — и рабочие кнопки +/- у зума. Это НЕ то же самое, что бизнес-поле `doc.scale`: пользователь подтвердил, что это должна быть отдельная viewport-камера (просмотр), не влияющая на экспорт/бизнес-данные, одинаково работающая для обоих типов документа (comics и puzzle).

## User Stories

**As a** пользователь редактора (desktop: mouse+trackpad; mobile: touch)
**I want** масштабировать и панорамировать канвас жестами (pinch, trackpad-pan, scroll-wheel-zoom) и кнопками +/-
**So that** я мог удобно рассматривать и редактировать страницу независимо от типа документа (comics или puzzle), не будучи ограничен диапазоном бизнес-поля Puzzle Scale

## Acceptance Criteria

### Must Have

1. **Given** канвас открыт (comics или puzzle документ)
   **When** пользователь крутит колесо мыши над канвасом
   **Then** viewport-zoom плавно меняется (zoom in/out), центрируясь на позиции курсора

2. **Given** канвас открыт на desktop (macOS/Linux/Windows) с трэкпадом
   **When** пользователь делает pinch-жест (раздвигает/сдвигает пальцы) или two-finger pan
   **Then** pinch меняет viewport-zoom, а two-finger pan сдвигает канвас (панорамирование)

3. **Given** канвас открыт на touch-устройстве (Android/iOS)
   **When** пользователь делает pinch двумя пальцами
   **Then** viewport-zoom меняется соответственно расстоянию между пальцами; одиночный drag по пустому фону канваса (не по слою) панорамирует канвас

4. **Given** канвас открыт (любой тип документа)
   **When** пользователь нажимает кнопку `+`/`−` в `_ZoomControl`
   **Then** viewport-zoom меняется на фиксированный шаг — работает одинаково для comics и puzzle (не no-op для comics)

5. **Given** viewport запанорамирован и/или зумирован
   **When** пользователь нажимает кнопку Fit
   **Then** viewport-zoom и pan сбрасываются к значению по умолчанию (100%, pan = 0), страница снова полностью в виде "fit to viewport" (как исходное поведение)

6. **Given** пользователь тащит (drag) содержимое канваса near/за пределы видимой области
   **When** панорамирование выполняется (трэкпад/тач/программно)
   **Then** pan клампится так, чтобы страница не могла полностью уйти за пределы видимой области канваса (см. Constraints)

7. **Given** любой из способов зума (wheel/pinch/+/-) применяется
   **When** новое значение zoom выходит за разумные пределы
   **Then** zoom клампится к диапазону (нижняя/верхняя граница — см. Specifications), не роняя приложение и не давая отрицательный/нулевой масштаб

### Won't Have (This Iteration)

- Изменение бизнес-поля `ComicsDoc.scale` (Puzzle Scale, 0.125–1) — остаётся отдельным, эта итерация его не трогает и не переиспользует.
- Zoom/pan не персистится в документе (сбрасывается при переоткрытии/смене документа) — это чисто view-состояние.
- Перетаскивание отдельных слоёв (`_LayerItem` drag через `onPanUpdate`) не меняется — остаётся приоритетнее панорамирования канваса (drag по слою двигает слой, не канвас).
- Клавиатурные шорткаты зума (Cmd/Ctrl + +/-/0) — не запрошены явно, не в этой итерации.

## Constraints

- **Git**: агент не выполняет git-команды (`apps/comics-editor-v2.9` — отдельный git-репозиторий, управляется пользователем вручную).
- **Область**: `lib/src/ui/widgets/canvas_view.dart`, при необходимости `lib/src/ui/controller.dart` (новое transient view-состояние, НЕ в `ComicsDoc`/`models.dart` — не бизнес-данные).
- **Совместимость**: перетаскивание слоя (`_LayerItem.onPanUpdate`) должно продолжать работать поверх zoom/pan viewport без регрессий — координаты слоя остаются в page-space (текущая логика `k = size.width / doc.width` пересчитывается с учётом viewport zoom).
- **Панорамирование**: с ограничением (clamped) — страница не должна полностью уходить за пределы видимой области (подтверждено пользователем).
- **Диапазон zoom**: отдельный от `doc.scale` (который остаётся 0.125–1); конкретные числовые границы — уточняются в Specifications (ожидается более широкий диапазон, т.к. это просмотр, а не бизнес-значение).

## References

- `lib/src/ui/widgets/canvas_view.dart` — `CanvasView`, `_Stage`, `_ZoomControl`, `_LayerItem`
- `lib/src/ui/controller.dart` — `EditorController`, `setScale()`
- `lib/src/ui/models.dart` — `ComicsDoc.scale` (бизнес-поле, не трогается)

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-07-25
- [x] Notes: дизайн-развилки подтверждены через уточняющие вопросы — (1) отдельный viewport-zoom, не связан с `doc.scale`; (2) панорамирование с ограничением (clamped). "requirements approved" получено.
