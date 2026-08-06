# Specifications: comics-editor-v2.9-fixes1 — resolveBinary() OS-aware fallback

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-07-25
> Requirements: [01-requirements.md](01-requirements.md) (APPROVED)

## Overview

`CoreClient.resolveBinary()` (`lib/src/bridge/core_client.dart`) получает список кандидатов в порядке приоритета: `COMICS_CORE_PATH` env → bundle-relative пути (macOS `.app`/Linux `bundle/data/comics-core`) → dev-режим (поиск `native/Comics.Editor.Headless/publish/<rid>/` вверх от CWD). Только последний, dev-режимный, список не фильтруется по текущей платформе. Фикс: сузить список RID для dev-режима до тех, что соответствуют `Platform.operatingSystem` (и, где применимо, архитектуре через `Platform.version`/`Abi.current()` — не обязательно точно матчить arm64/x64, достаточно исключить чужую ОС).

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `lib/src/bridge/core_client.dart` — `CoreClient.resolveBinary()` | Modify | Фильтрация dev-режимных RID-кандидатов по `Platform.operatingSystem` |
| `native/Comics.Editor.Headless/publish/osx-arm64/` | Delete | Устаревший локальный артефакт, не часть репозитория (gitignored), провоцирует баг |

## Behavior Specifications

### Текущее поведение (баг)

```dart
for (final rid in const ['osx-arm64', 'osx-x64', 'linux-x64', 'linux-arm64', 'win-x64']) {
  candidates.add('$base/$rid/Comics.Editor');
  candidates.add('$base/$rid/Comics.Editor.exe');
}
```
Список фиксирован, не зависит от `Platform.operatingSystem`. Первый существующий на диске путь побеждает — даже если это бинарник другой ОС.

### Новое поведение

RID-список для dev-режима строится через фильтр по текущей ОС:

| `Platform.operatingSystem` | Допустимые RID (в порядке проверки) |
|---|---|
| `macos` | `osx-arm64`, `osx-x64` |
| `linux` | `linux-x64`, `linux-arm64` |
| `windows` | `win-x64` |

Реализация: заменить константный список на функцию/геттер, возвращающую подходящий под-список в зависимости от `Platform.operatingSystem`, остальная логика перебора (`candidates.add(...)`, `existsSync()`) не меняется.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| Ни один RID текущей ОС не существует на диске | Ядро не собрано локально для этой ОС | `resolveBinary()` возвращает `null`, как и раньше (не найдено) — поведение не регрессирует |
| iOS/Android (мобильные) | `Platform.isIOS`/`Platform.isAndroid` | Эти платформы используют `DartIoCore`, не `CoreClient` — dev-режимный fallback для них не вызывается вовсе; фильтр может не покрывать эти ОС явно (не требуется) |

## Testing Strategy

### Manual Verification

- [ ] В рабочей копии одновременно существуют `publish/osx-arm64/` и `publish/linux-x64/` (искусственно, для проверки) — `resolveBinary()` на Linux выбирает `linux-x64`
- [ ] Существующие тесты (`test/core_client_test.dart`) на своей нативной платформе продолжают проходить без регрессий
- [ ] Повторный прогон `tool/docker-build.sh linux` (после удаления `publish/osx-arm64/`) проходит `core_client_test.dart` полностью

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-07-25
- [x] Notes: «сделай сейчас» — специфицировано и сразу реализуется в рамках одной сессии.

---

# Iteration 2: Canvas zoom/pan (viewport camera)

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-07-25
> Requirements: [01-requirements.md](01-requirements.md), секция "Iteration 2" (APPROVED)

## Overview

Реализовать viewport-камеру (zoom + pan) поверх канваса через встроенный Flutter-виджет `InteractiveViewer`, а не через ручную сборку `Listener`/`GestureDetector`. `InteractiveViewer` уже умеет из коробки: touch pinch-zoom, trackpad pinch-zoom, trackpad two-finger pan, single-pointer drag-pan, mouse wheel → zoom (через `onPointerSignal`/`PointerScrollEvent`, независимо от `trackpadScrollCausesScale`, который управляет только тем, интерпретировать ли **не-pinch** двухпальцевый trackpad-скролл как zoom, по умолчанию `false` = обычный pan) — это закрывает Acceptance Criteria 1-3 почти без кастомного кода жестов, и снимает риск конфликта жестов между канвасом и вложенным `GestureDetector` слоя (`_LayerItem`) вручную не разруливая gesture arena.

Новое состояние — `EditorController.canvasViewport` (`TransformationController`), transient, не персистится, сбрасывается при загрузке/создании документа. Существующее бизнес-поле `ComicsDoc.scale` НЕ трогается (per requirements), логика fit-to-viewport в `_Stage` остаётся как есть — viewport-камера применяется как дополнительная трансформация поверх уже посчитанного fit-прямоугольника.

**Discovery (для сведения, не меняет scope):** Проверено — `doc.scale` (`ComicsDoc.scale`) нигде не сериализуется/не экспортируется (`models_mapping.dart` его не касается; там встречается только несвязанный `AnimType.scale`). Это чисто view-поле для puzzle, не бизнес/экспортное значение, как ошибочно предполагалось в Problem Statement требований. Не меняет решение (per approved "Won't Have"), но означает: после этой итерации `doc.scale` останется навсегда равным дефолту `1` (единственная кнопка, которая его меняла, `_ZoomControl` +/-, переключается на новую viewport-камеру) — это не регрессия, т.к. `doc.scale` уже ни на что не влияет за пределами `canvas_view.dart`. Если позже понадобится явно убрать мёртвое поле — отдельная итерация.

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `lib/src/ui/controller.dart` — `EditorController` | Modify | Новое поле `canvasViewport` (`TransformationController`), методы `zoomBy()`, `resetViewport()`, сброс во всех точках загрузки документа (`openPath`, `newDoc`, `openRecent`), `dispose()` |
| `lib/src/ui/widgets/canvas_view.dart` — `_Stage` | Modify | Обернуть fit-посчитанный `SizedBox` (страница) в `InteractiveViewer` |
| `lib/src/ui/widgets/canvas_view.dart` — `_LayerItem` | Modify | Коррекция `onPanUpdate`: delta делится на `(k * текущий viewport scale)`, не только на `k` |
| `lib/src/ui/widgets/canvas_view.dart` — `_ZoomControl` | Modify | +/- и Fit работают через `canvasViewport`/`zoomBy`/`resetViewport`, а не `doc.scale`; работает для обоих типов документа; live-обновление % через `canvasViewport` как отдельный `Listenable` |

## Behavior Specifications

### Новое состояние в `EditorController`

```dart
static const double kCanvasZoomMin = 0.25;
static const double kCanvasZoomMax = 4.0;
static const double kCanvasZoomStep = 1.25; // множитель на клик +/-

final TransformationController canvasViewport = TransformationController();

void resetViewport() {
  canvasViewport.value = Matrix4.identity();
}

/// focalPoint — точка в системе координат viewport (экранная, локальная
/// для InteractiveViewer), вокруг которой зумируем. Для кнопок +/- —
/// центр видимой области канваса (см. _ZoomControl).
void zoomBy(double factor, Offset focalPoint) {
  final current = canvasViewport.value.getMaxScaleOnAxis();
  final target = (current * factor).clamp(kCanvasZoomMin, kCanvasZoomMax);
  final scaleDelta = target / current;
  if (scaleDelta == 1.0) return;
  final scenePoint = canvasViewport.toScene(focalPoint);
  final m = canvasViewport.value.clone()
    ..translate(scenePoint.dx, scenePoint.dy)
    ..scale(scaleDelta)
    ..translate(-scenePoint.dx, -scenePoint.dy);
  canvasViewport.value = m;
}
```

- Сброс `canvasViewport.value = Matrix4.identity()` добавляется в `openPath()` (после `doc = coreDoc!.doc;`), `newDoc()`, `openRecent()` — везде, где сейчас происходит `doc = ComicsDoc(...)`/переоткрытие.
- `dispose()`: добавить `canvasViewport.dispose();`.
- `TransformationController` сам по себе `Listenable` (`ValueNotifier<Matrix4>`) — его изменения (в т.ч. вызванные жестами внутри `InteractiveViewer` напрямую, минуя `EditorController.notifyListeners()`) не проходят через `EditorController`. Виджетам, которым нужно живое обновление (`_ZoomControl`'s % label), нужно слушать `canvasViewport` отдельно (см. ниже).

### `_Stage`: обёртка в `InteractiveViewer`

Существующий fit-to-viewport расчёт (`pageW`/`pageH`, `LayoutBuilder`) не меняется — он по-прежнему определяет "базовый" размер страницы. Новое: обернуть возвращаемый `Center(child: SizedBox(...))` в `InteractiveViewer`:

```dart
InteractiveViewer(
  transformationController: c.canvasViewport,
  minScale: EditorController.kCanvasZoomMin,
  maxScale: EditorController.kCanvasZoomMax,
  boundaryMargin: const EdgeInsets.all(200), // допускает панорамирование с запасом, но не даёт странице полностью уйти из viewport
  trackpadScrollCausesScale: false, // обычный two-finger scroll трэкпада = pan, не zoom; pinch по-прежнему = zoom
  child: Center(
    child: SizedBox(width: pageW, height: pageH, child: _Page(c, Size(pageW, pageH))),
  ),
)
```

- `boundaryMargin: EdgeInsets.all(200)` — конкретное число ориентировочное, подбирается на глаз в Implementation/Testing (см. Testing Strategy) под реальные размеры панели канваса; главное свойство — конечный (не `EdgeInsets.zero`, не `double.infinity`) margin, чтобы: (а) страницу нельзя было утащить полностью за пределы видимой области (Acceptance Criteria 6), но (б) оставался запас для панорамирования при сильном zoom-in.
- Диапазон `0.25–4.0` — сознательно шире, чем старый бизнес-диапазон `doc.scale` (`0.125–1`), т.к. это чисто просмотровая функция (подтверждено пользователем в Requirements).

### `_LayerItem`: коррекция drag-delta под viewport zoom

Текущий код:
```dart
onPanUpdate: (d) => c.dragSelected(Offset(d.delta.dx / k, d.delta.dy / k)),
```
`d.delta` от `GestureDetector.onPanUpdate` — это движение указателя в глобальных пикселях экрана, не скомпенсированное под масштаб, применённый `InteractiveViewer` к предку. При zoom ≠ 1 через `InteractiveViewer` слой будет двигаться быстрее/медленнее курсора, если не поделить дополнительно на текущий viewport-scale. Исправление:

```dart
onPanUpdate: (d) {
  final vz = c.canvasViewport.value.getMaxScaleOnAxis();
  c.dragSelected(Offset(d.delta.dx / (k * vz), d.delta.dy / (k * vz)));
},
```

Это единственное изменение, необходимое для совместимости drag-слоя с новым zoom (Constraint из Requirements). Сам факт, что `_LayerItem`'s `GestureDetector(onPanUpdate)` в принципе продолжит получать события (не будет "съеден" `InteractiveViewer`'ом) — стандартное, документированное поведение Flutter при вложенных gesture-детекторах (дочерний recognizer первым видит движение по hit-test порядку и обычно выигрывает арену для одиночного указателя), но должно быть подтверждено вручную (см. Edge Cases/Testing).

### `_ZoomControl`: +/- и Fit через viewport-камеру

```dart
class _ZoomControl extends StatelessWidget {
  const _ZoomControl(this.c);
  final EditorController c;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c.canvasViewport,
      builder: (context, _) {
        final pct = (c.canvasViewport.value.getMaxScaleOnAxis() * 100).round();
        return Container(
          /* ...existing decoration... */
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _zoomBtn('−', () => _bump(context, c, 1 / EditorController.kCanvasZoomStep)),
            SizedBox(width: 50, child: Text('$pct%', /* ... */)),
            _zoomBtn('+', () => _bump(context, c, EditorController.kCanvasZoomStep)),
            /* divider */
            IconButton(onPressed: c.resetViewport, icon: const Icon(Icons.crop_free, size: 18), tooltip: 'Fit'),
          ]),
        );
      },
    );
  }

  void _bump(BuildContext context, EditorController c, double factor) {
    final box = context.findRenderObject() as RenderBox;
    final center = box.size.center(Offset.zero);
    c.zoomBy(factor, box.localToGlobal(center)); // либо через отдельный GlobalKey на InteractiveViewer — см. Edge Cases
  }
  /* ...остальное без изменений... */
}
```

- Убран guard `if (!c.isPuzzle) return;` — работает одинаково для comics и puzzle (Acceptance Criteria 4).
- % теперь всегда `canvasViewport`-based (не `c.isPuzzle ? doc.scale : 1.0`).
- Fit-кнопка → `c.resetViewport()` (сбрасывает и zoom, и pan к дефолту — Acceptance Criteria 5). `c.setScale(1)` (старый вызов на `doc.scale`) можно оставить как безобидный no-op для обратной совместимости или убрать — на усмотрение при реализации, поведенчески не важно (см. Discovery выше).

## Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| Focal point для кнопок +/- | Нажатие +/- (не жест, нет курсора) | Зумируем вокруг центра видимой области канваса. Технически: нужен `RenderBox` именно **viewport** `InteractiveViewer`, не самой кнопки `_ZoomControl` (которая в углу) — при реализации завести `GlobalKey` на `InteractiveViewer` (или на `_Stage`) и использовать его `RenderBox` для вычисления центра, а не `context` кнопки. Обновить псевдокод выше на этапе Implementation. |
| Конфликт жестов: drag слоя (`_LayerItem`) vs pan канваса (`InteractiveViewer`) | Пользователь тащит выделенный слой одиночным указателем | Ожидается: слой двигается, канвас не панорамируется (по документированному поведению вложенных gesture-детекторов). **Требует ручной проверки** (см. Testing Strategy). Fallback (Plan B), если на практике конфликтует: добавить `EditorController.isDraggingLayer` (bool), выставлять в `Listener(onPointerDown)` на `_LayerItem` (срабатывает раньше разрешения gesture arena) при попадании в bounds слоя; передавать `panEnabled: !c.isDraggingLayer` в `InteractiveViewer`. |
| Zoom за пределами `[kCanvasZoomMin, kCanvasZoomMax]` | Быстрый pinch/scroll/множественные клики +/- | `InteractiveViewer` сам клампит `minScale`/`maxScale` для жестов; `zoomBy()` клампит явно для кнопок — не роняет, не даёт scale ≤ 0 (Acceptance Criteria 7) |
| Смена документа (open/new/recent) во время активного зума/пана | Пользователь открывает другой файл, будучи zoomed-in | `canvasViewport` сбрасывается к `Matrix4.identity()` в `openPath`/`newDoc`/`openRecent` — новый документ всегда открывается в состоянии Fit |
| Resize окна (desktop) при активном zoom/pan | Пользователь ресайзит окно приложения | Не в скоупе (Won't Have implicit) — `boundaryMargin` может временно выглядеть иначе после resize; специально не обрабатывается, т.к. `LayoutBuilder` пересчитывает fit-размер, а `canvasViewport` остаётся как есть (может визуально "сместиться" — приемлемо, Fit-кнопка чинит) |
| Mobile: одиночный tap по слою (не drag) | Touch-тап на слое | Не меняется — `onTap` в `_LayerItem` работает как раньше, `InteractiveViewer` не блокирует tap-и (только pan/scale gestures) |

## Testing Strategy

### Manual Verification

- [ ] macOS trackpad: pinch внутри канваса → zoom к точке под пальцами; two-finger scroll (без pinch) → pan, не zoom
- [ ] Мышь: колесо над канвасом → zoom к позиции курсора
- [ ] Touch (Android/iOS реальное устройство или эмулятор с multi-touch): pinch → zoom; одиночный drag по пустому фону → pan; drag по слою → двигает слой, не канвас
- [ ] Кнопки +/- работают для comics-документа и для puzzle-документа одинаково; % label совпадает с фактическим zoom
- [ ] Fit-кнопка сбрасывает zoom и pan к дефолту из любого состояния
- [ ] Drag выделенного слоя при zoom ≠ 100% — слой двигается 1:1 с курсором (не быстрее/медленнее) — проверяет фикс `k * vz`
- [ ] Попытка утащить канвас панорамированием далеко за пределы — страница не уходит полностью из вида (визуальная проверка `boundaryMargin`)
- [ ] `flutter analyze` — чисто
- [ ] Существующие тесты (`flutter test`) — без регрессий, особенно если что-то полагалось на `_ZoomControl`/`doc.scale` в widget-тестах

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-07-25
- [x] Notes: "specs approved" получено.
