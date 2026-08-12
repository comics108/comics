# Specifications: Comics Editor Camera Path + Z-Depth UI/UX

> Version: 0.3
> Status: APPROVED
> Last Updated: 2026-08-10
> Requirements: [01-requirements.md](01-requirements.md) (v0.2, APPROVED)
> Visual: [02-visual.md](02-visual.md) (v0.3, APPROVED)

## 1. Scope and Source of Truth

This increment adds authoring and live preview for the already-implemented
`ComicsDoc.cameraPath` and `EditorLayer.zDepth`. It does not add another camera model, change the
`.comics` schema, or duplicate interpolation math in the editor.

The implementation must reuse `CameraPathEvaluator`, `KeyframeInterpolator`, the editor's existing
document-clone history, its bridge/save path, and the selected General `DeviceProfile`. This flow
implements only the enabled vertical-scroll comic strip. Puzzle stays unchanged; horizontal-scroll
and landscape stay visible-but-disabled future options.

`cameraPath.position` is an integer document scroll-axis coordinate. Camera X/Y and layer Z-Depth
are doubles. None of them are host-window pixels or tied to iPad/iPhone dimensions.

## 2. Confirmed Current-State Corrections

Code inspection found two prerequisites that this flow must correct:

1. `EditorController.currentTime` divides matrix translation by interactive zoom but not by the
   fitted document-to-screen scale. It therefore claims document pixels while returning fitted
   screen pixels.
2. Edit Canvas does not yet expose the approved target-device viewport band. Viewer does, through
   `VerticalPositionSelector`, but Edit and Viewer currently have separate incomplete geometry.

This completes the already-approved Edit binding from `vdd-comics-editor-scroll`; it is not a new
scroll redesign. Existing responsive breakpoints, panes, phone sheet, Canvas pan, and zoom controls
remain.

## 3. Affected Components

| Component | Change |
|---|---|
| `lib/src/ui/editor_mode.dart` | Reorder `PropertiesTab` to `general, selection, document` |
| `lib/src/ui/controller.dart` | Own ID-based layer selection/primary/anchor, batch mutations, measured Edit geometry, scroll conversion, camera selection/overlay, and undoable camera/depth mutations |
| `lib/src/ui/widgets/scene_panel.dart` | Render shared multi-selection, desktop modifiers, touch selection mode, batch bar, and explicit per-row context menu |
| `lib/src/ui/widgets/canvas_view.dart` | Share layer selection, move selected roots, report geometry, render target-device window/rail, apply camera-depth once, and paint guides |
| `lib/src/ui/widgets/properties_panel.dart` | Add single/mixed Selection Z-Depth and Document Camera Path; retain General device ownership |
| `lib/src/ui/widgets/numeric_property_control.dart` | Add optional validation text, semantics, and reference labels without breaking call sites |
| `lib/src/ui/widgets/viewer_workspace.dart` | Reuse vertical viewport-rail presentation without camera authoring markers |
| New editor rail widget | Share range geometry/semantics and optionally add a separate Edit camera lane |
| `apps/comics-editor/test` | Add geometry, control, history, rendering, responsive, and semantic coverage |

No parser/schema or native viewer changes are required. The Flutter editor is the cross-platform
implementation, including the Windows migration target.

## 4. Properties Information Architecture

Visible and focus order is exactly:

```text
General | Selection | Document
```

- General retains target device/dimensions and mode/orientation affordances.
- Selection shows Z-Depth for the selected layer alongside existing layer fields.
- Document shows Camera Path after existing document-wide fields.
- Viewer continues to replace the authoring workspace and never shows these tabs.

The controller's initial tab becomes `PropertiesTab.general`. Selecting a layer may move focus to
Selection only where current selection behavior already does so; file open, device change, and
Viewer entry must not unexpectedly switch tabs.

### 4.1 Shared layer-selection model

Replace index-only layer selection as the source of truth with stable `EditorLayer.id` identity:

```dart
final LinkedHashSet<String> selectedLayerIds = LinkedHashSet<String>();
String? primaryLayerId;
String? layerRangeAnchorId;
bool touchLayerSelectionMode = false;
```

The linked set preserves selection-recency order. `primaryLayerId` must be a member whenever the set
is non-empty; `layerRangeAnchorId` may remain an unselected prior anchor until a replace selection
or document change. Existing `selectedLayer`, `selectedAnims`, Timeline, Lettering, Cutting, and
single-layer Properties resolve through the primary layer. If compatibility fields `selKind` and
`selIndex` remain during migration, they are derived/synchronized outputs, never a competing source.

Layer and sound selections are mutually exclusive: selecting any sound clears all layer selection;
selecting a layer clears sound selection. Camera-point selection is independent because it belongs
to Document properties, but Canvas layer handles remain hidden while Document camera guides own
focus.

Selection state is transient and never serialized. It reconciles by ID after reorder and document
history restore, removes missing IDs after delete/Undo/Redo, and selects no replacement implicitly
after New/Open. Stable IDs already survive `EditorLayer.clone()`.

### 4.2 Primary and anchor rules

- Replace: set contains only clicked ID; it becomes primary and range anchor.
- Toggle-add: append ID; it becomes primary and range anchor.
- Toggle-remove non-primary: remove it; primary is unchanged.
- Toggle-remove primary: most recently selected remaining ID becomes primary; empty clears anchor.
- Shift range: use currently visible hierarchical Scene order from anchor through clicked row,
  replace the set with that inclusive range, and make clicked row primary. Collapsed descendants are
  excluded because they have no visible row.
- Select All: select all document layers, including eye-hidden and collapsed descendants, in raw
  document order; existing primary remains if included, otherwise last layer is primary.
- Invert Visible: toggle only rows returned by `hierarchicalLayerOrder`; preserve primary if it
  remains, otherwise use the last newly added/remaining visible ID.
- Clear: empty the set and primary/anchor.
- Done/Escape: collapse to primary as an ordinary one-layer selection, not an empty selection.

### 4.3 Input routing

Use Flutter `Shortcuts`/`Actions` and modifier state rather than platform-name branching:

- desktop/Web click replaces; Primary/Meta-or-Control click toggles; Shift-click ranges;
- `Cmd/Ctrl+A` selects all layers while Scene/Canvas has editing focus;
- Escape collapses multiple selection to primary;
- Canvas click/toggle uses the same controller intent as Scene;
- touch long-press on a Scene row or Canvas layer enters selection mode with that layer primary;
- while touch selection mode is active, tap toggles and never starts a transform drag; dragging the
  primary layer/its handles after selection is established moves the selected group;
- Done collapses to primary; All/Invert/Clear call the same controller operations;
- the existing touch long-press Parent menu moves to a 44-pixel `more_vert` row button; desktop
  secondary-click retains it.

The per-row eye remains visibility only and must not alter selection.
Local editors have shortcut priority: Escape inside an active numeric/text edit cancels that edit;
only an unconsumed Escape at Scene/Canvas scope collapses multi-selection.

## 5. Canonical Edit Scroll Geometry

### 5.1 Metrics

Add transient, non-persisted geometry owned by `EditorController`:

```dart
class EditorViewportMetrics {
  const EditorViewportMetrics({
    required this.documentToScreenScale,
    required this.viewportHeightDoc,
    required this.scrollTravelDoc,
  });

  final double documentToScreenScale;
  final double viewportHeightDoc;
  final double scrollTravelDoc;
}
```

For the vertical strip:

```text
documentToScreenScale = fittedTargetWidthPx / document.width
viewportHeightDoc = targetDevice.height / targetDevice.width * document.width
scrollTravelDoc = max(0, document.height - viewportHeightDoc)
documentScrollOffset = clamp(
  -matrix.translationY / (matrix.zoom * documentToScreenScale),
  0,
  scrollTravelDoc
)
normalizedPosition = scrollTravelDoc == 0 ? 0 : documentScrollOffset / scrollTravelDoc
```

The selected target profile defines the authoring viewport; the host may letterbox around it. Zoom
changes display scale only and must not change the document coordinate at the target viewport top.

`CanvasView` updates metrics synchronously during layout without notifying from build. Controller
exposes read-only current offset, normalized position, viewport extent, and a setter that updates
the transform while preserving interactive zoom and cross-axis translation.

### 5.2 Resize and device changes

Retain normalized progress before target profile or usable Canvas size changes, then restore it
against the new `scrollTravelDoc`. A document shorter than the target viewport has zero travel, a
full-height range band, and `currentTime == 0`.

Existing sound and animation evaluation use corrected `currentTime`; there is no parallel camera
playhead. A metrics-only layout change does not fire sound cues, while a real pan/rail action does.

### 5.3 Rail coordinates

Use document height for painting:

```text
bandStart = documentScrollOffset / document.height
bandExtent = min(1, viewportHeightDoc / document.height)
cameraMark = cameraPoint.position / document.height
```

Clamp values only for painting. The band maps interaction back to scroll travel. Selecting a point
navigates to `clamp(point.position, 0, scrollTravelDoc)`; a valid point near the document end remains
unchanged even when a large target viewport cannot place it exactly at the top.

## 6. Reusable Vertical Rail

Introduce an editor-local reusable rail (working name `VerticalDocumentRail`) with inputs for
normalized position, viewport extent, target label, scroll callback, optional camera points,
selected point, and optional marker select/drag callbacks.

Behavior is fixed:

- inner lane: capped visible-range band, draggable/tappable;
- outer lane in Edit only: camera diamonds while Document → Camera Path is active and overlay is on;
- at least 44 logical pixels per touch hit target without enlarging the visible mark;
- pointer capture keeps a drag in its originating lane;
- overlapping marks fan visually or expose an accessible ordered chooser and never block the band;
- range semantics state target and visible start/end; marker semantics state ordinal, position, X/Y,
  and selected state;
- Viewer passes no camera data/callbacks and remains result-only.

Keep `VerticalPositionSelector` as a compatibility wrapper or preserve its current test key while
migrating its internals.

## 7. Z-Depth Authoring

### 7.1 Control

Selection adds a `Z-Depth` group:

- soft slider `-0.9 ... 4.0`, step `0.05`;
- labelled reference mark and gentle snap at exactly `0`;
- exact input accepts any finite number strictly greater than `-1`;
- a valid out-of-slider value remains exact, displays `Custom`, and pins only the visual thumb;
- read-only response comes from `CameraPathEvaluator.responseForDepth(zDepth)`;
- sign copy is `Near / moves faster`, `Reference / no camera adjustment`, or
  `Far / moves slower`;
- Reset sets exactly `0` as one undoable edit.

Desktop/Web retain the editable number beside the slider. Touch retains the existing one-tap pill
that immediately focuses a signed decimal keyboard. Invalid input keeps the previous valid model
value and displays `Enter a finite value greater than -1.` locally and through semantics.

### 7.2 Mutation and history

Controller provides preview, commit, and reset operations for selected-layer Z-Depth. Slider start
uses existing gesture-history begin; ticks preview without snapshots; gesture end commits one
history entry. Exact Apply/Enter creates one entry. Cancel, invalid input, and unchanged values
create none.

Hidden layers remain editable but say preview is unavailable and use the existing eye affordance.
Organizational/non-renderable layers explain that no visible content will move. No second visibility
state is introduced.

### 7.3 Mixed and common Z-Depth

Selection Properties resolve depth across `selectedLayerIds`:

```dart
sealed class DepthSelectionValue {}
final class NoDepthSelection extends DepthSelectionValue {}
final class CommonDepth extends DepthSelectionValue { final double value; }
final class MixedDepth extends DepthSelectionValue {
  final List<(String layerId, String name, double value)> values;
}
```

Equivalent internal representation is acceptable. Equality is exact stored-double equality; the UI
may format values but must not merge values merely because rounded labels match.

- No selection: existing empty Selection state.
- One/common value: active slider/exact field labelled `Depth · N layers` when `N > 1`.
- Mixed: disabled illustrative slider, individual compact values, and explicit
  `Set depth for N layers` / `Reset all to 0`.
- `Set depth...` enters common-value edit and focuses exact input without mutating yet. The first
  valid preview applies one absolute value to all selected IDs. Relative offset editing is absent.
- Reset writes exactly zero to every selected layer in one history transaction.
- If selection changes during an active preview, cancel/revert that preview before resolving the new
  set; never apply to IDs that were not in the gesture-start snapshot.

Hidden and organizational members remain part of the batch, but the summary states how many selected
layers currently have no visible preview.

### 7.4 Group mutation and history contract

All group operations snapshot the selected IDs at gesture/action start, validate targets, call
`_beginHistory()` once, mutate all targets, and call `_commitHistory()` once. Missing IDs are skipped
safely. An empty target set or already-satisfied result creates no history item.

Required operations:

```dart
void selectAllLayers();
void invertVisibleLayerSelection();
void clearLayerSelection();
void collapseSelectionToPrimary();
void setSelectedLayersVisible(bool visible);
void previewSelectedLayersZDepth(double value);
void commitSelectedLayersZDepth(double value);
void dragSelectedLayers(Offset delta);
void moveSelectedLayers(int direction);
void deleteSelectedLayers();
```

Names may differ, but semantics may not.

#### Visibility

Show/Hide writes an explicit boolean to every selected layer. It is never a toggle: with mixed input
a toggle has no predictable result. Per-row eyes continue to affect only that row.

#### Canvas translate with hierarchy

Determine selected roots as selected layers with no selected ancestor through `parentId`. Apply the
delta only to those roots and recursively reuse descendant propagation. Therefore a selected child
of a selected parent receives the delta exactly once, while an independently selected root also
moves. One pointer drag is one history entry; primary alone owns full transform handles and all other
selected layers paint a passive outline.

#### Stable Up/Down

Move selected layers one legal stacking step as a stable block:

1. Work in raw persisted layer order, preserving relative order of selected and unselected items.
2. For Up, swap each selected run with the nearest preceding unselected sibling/run; for Down, use
   the following unselected sibling/run and process from the end.
3. Treat each selected parent subtree as atomic so a child is never reordered outside its parent by
   a group move. If selection crosses incompatible hierarchy levels and no single legal step exists,
   disable/no-op rather than flattening or changing `parentId`.
4. Primary remains the same ID; no-op at a boundary creates no history.

#### Delete

For two or more targets, require confirmation naming the count. Remove all targets in raw descending
index order. For every surviving layer whose `parentId` points to a removed layer, clear `parentId`
using the existing orphan policy. Clear removed selection IDs, choose no automatic replacement, and
commit one undo transaction. Cancel changes nothing.

Parent, Kind, artwork/language, Anim, and persistent `groupId` changes remain primary-only. This
flow adds batch operations, not a new persistent grouping format.

## 8. Camera Authoring State

Transient state, never persisted:

```dart
int? selectedCameraPointIndex;
bool showCameraAuthoringOverlay; // true for a newly opened document/session
```

Persisted points have no ID. After a path mutation, stable-sort and re-resolve selection to the
edited point deterministically. New/Open clears selection. Undo/Redo clears it if the point no
longer exists, otherwise it may reselect by full `(position, x, y)`. Overlay eye is session-only and
does not alter history, dirty state, save data, or rendered effect.

Markers and reticle appear only when workspace is Editor, document is vertical-scroll, Document tab
is active, and overlay is on.

## 9. Camera Path Operations

Controller provides add, select/reveal, position preview/commit, XY preview/commit, set-to-current-
sample, reset XY, delete selected, and reset path. Method names may differ; behavior may not.

### 9.1 Add at current

```text
position = round(currentTime)
sample = CameraPathEvaluator.sample(existingPath, currentTime)
newPoint = (position, sample.dx, sample.dy)
```

Absent/empty path produces the neutral `(position, 0, 0)` anchor. Capturing the current sample for
later points preserves continuity and prevents an insertion jump. If the rounded position already
exists, Add selects it and creates no mutation/history item.

### 9.2 Validation, range, ordering

- position: integer in inclusive `0 ... round(document.height)`;
- X/Y: any finite double;
- saved list: stable-sorted and strictly increasing;
- duplicate position: never committed silently.

The Position slider's soft range is current target `0 ... scrollTravelDoc`; exact input may address
the full document range so data stays target-independent. Out-of-travel points remain visible at
their document-rail location and navigate to the nearest reachable offset.

A marker drag may approach but not cross/reorder its neighbors; clamp preview between adjacent
integer positions. Exact duplicate entry shows Cancel/Replace. Replace removes the existing point
there and commits the edited point as the explicit last-point-wins result. Undo restores both prior
points and their order.

Messages:

- position: `Enter a whole document-pixel value from 0 to {documentHeight}.`
- X/Y: `Enter a finite document-pixel value.`
- collision: `Point {n} already uses this position.`

### 9.3 Delete and reset

Delete removes the selected point. Zero points normalize to `cameraPath == null`; one point remains
an inert anchor. Reset Path confirms because it removes multiple points, then writes null in one
undoable transaction. Single-point Delete needs no confirmation. Reset XY sets X/Y to zero. Set
current sample captures the evaluator sample before mutation.

## 10. Document Camera Path UI

The authoritative section contains, in order:

1. header, count, and session overlay eye;
2. ordered point list with position/X/Y summary;
3. Add at current;
4. selected-point Position, compact XY pad, X, and Y;
5. Delete and Reset Path;
6. zero/one-point inert explanation.

Desktop shows list and editor together when possible. Tablet may collapse the XY pad. Phone shows
the list first; row tap drills into its editor in the same Properties sheet and Back returns to the
list. Position/X/Y pills open exact editing in one tap.

The XY pad is not a free canvas gizmo. Its center is the selected value at drag start; drag delta is
converted to document pixels with stable, labelled sensitivity. Numeric controls remain
authoritative. One pad drag is one history transaction.

## 11. Edit Rendering and Guides

At corrected `currentTime`, each visible layer uses:

```dart
final authored = KeyframeInterpolator.translateAt(
  layer.anims,
  currentTime,
  layer.translate,
);
final parallax = CameraPathEvaluator.parallaxAdjustment(
  document.cameraPath,
  currentTime,
  layer.zDepth,
);
final effective = authored + parallax;
```

`effective` is multiplied by document-to-screen scale exactly once. Existing scale/rotate/alpha
composition remains. Camera adjustment is not applied to the strip, baked into Anims, or inherited
through `ParentId`. Absent/empty/one-point path and depth zero remain inert via the shared evaluator.

Guides paint in an `IgnorePointer` overlay above content and below selection handles: selected point,
current camera sample, origin/reference crosshair and useful vector, plus an edge indicator when the
reticle falls outside the clipped target viewport. Guides never save/export or intercept layer hits.
The reticle is display-only; XY pad/sliders/exact fields own editing.

## 12. Viewer Contract

Viewer continues through `flutter_comics_viewer`, which already consumes camera/depth and canonical
document scroll. `refreshViewer()` serializes current in-memory edits as for other preview fields.

Viewer contains the rendered result and selected-device range band. It contains no Properties tabs,
camera marks/reticle/XY controls, Z-Depth controls, Scene, or Timeline authoring chrome.

## 13. Numeric Control Extension

Extend `NumericPropertyControl` compatibly with optional local error text, semantic value, and
labelled marks/reference tick. Required behavior:

- desktop number remains beside slider;
- touch pill begins focused inline editing in one action;
- model changes only after valid commit;
- Escape/swipe/cancel restores edit-start text and model;
- exact values outside the soft slider are displayed, never model-clamped;
- slider preview retains one-history-item gesture behavior;
- labels/ticks do not rely on color.

The conceptual phone modal may use the existing inline focused editor if it provides one-action
access, local validation, keyboard focus, cancel/apply equivalence, and 44-pixel targets. No nested
modal is required.

## 14. Lifecycle

| Event | Required result |
|---|---|
| New/Open | Clear camera selection; overlay on; recompute target metrics after layout |
| Switch to Viewer | Retain Edit scroll/selection in memory; hide guides |
| Return to Editor | Restore Edit scroll; show guides only when tab/eye permit |
| Change target device | Preserve normalized Edit progress; recompute range/travel |
| Save/Reopen | Path/depth round-trip; transient authoring state does not |
| Undo/Redo | Restore document camera/depth and reconcile selection safely |
| Close phone Properties | Retain valid state/scroll; no implicit invalid commit |
| Hide overlay eye | Hide guides only; no history, dirty, or effect change |
| Hide layer eye | Retain depth; do not paint layer/parallax |
| Reorder selected layers | Preserve selected IDs, primary, and valid range anchor |
| Undo/Redo batch action | Restore the document in one step and reconcile selection by stable IDs |
| Delete selected layers | Drop removed IDs; Undo may restore data but does not re-enter touch selection mode |
| Leave touch selection mode | Collapse to primary; never persist mode across workspace/document changes |

## 15. Accessibility and Input

- Focus follows visual order: tab, overlay eye, rows, Add, point controls, destructive actions.
- Desktop/Web sliders support arrows; Shift+Arrow is a larger step. Enter commits; Escape cancels.
- List and Position input provide keyboard equivalents for marker selection/drag.
- Every touch target is at least 44 logical pixels.
- Semantics include `Z-Depth -0.5, Near, motion response 2 times`, point ordinal/position/X/Y,
  overlay hidden but effect active, and target visible-range start/end.
- Selection, hidden, reference, invalid, and mixed states use text/icon/shape as well as color.
- Multi-selected rows expose `selected`; primary also exposes `Primary`. Group actions announce verb
  and count, for example `Hide 3 selected layers`.
- After non-destructive batch actions focus returns to primary. After Delete it moves to the nearest
  surviving Scene row or Layers header, so keyboard/screen-reader focus never disappears.

## 16. Edge Cases

| Case | Behavior |
|---|---|
| v2012 / fields absent | Reference depth, empty path, no migration prompt/change |
| no/empty path | No marks/effect; Add creates neutral anchor |
| one point | Marker retained; explicit inert-anchor copy |
| all depths zero | Path editable; visible result unchanged |
| hidden/non-renderable layer | Value retained; accurate unavailable/no-content copy |
| depth `<= -1`, NaN, infinity | Reject and retain prior value |
| valid depth outside slider | Preserve exact value; Custom edge state |
| negative/non-integer/out-of-document position | Reject locally |
| duplicate position | Explicit Cancel/Replace |
| viewport >= document | Full band, zero travel/currentTime; path remains editable |
| point beyond target travel | Retain, paint by document position, navigate to nearest offset |
| resize/device switch | Preserve normalized progress and selected point |
| overlay hidden | Hide guides only; retain effect/data |
| puzzle | Camera authoring unavailable with vertical-strip explanation; Canvas unchanged |
| selected ID missing after history/external change | Drop it; use most-recent surviving selected ID as primary |
| primary toggled off | Promote most-recent remaining layer; empty selection clears anchor |
| parent and descendant selected for drag | Descendant moves once through selected-root propagation |
| mixed visibility | Explicit Show/Hide; no ambiguous toggle |
| mixed depth | No mutation before Set/Reset; gesture target IDs freeze at start |
| Shift across collapsed subtree | Select visible rows only; never invisible descendants |
| Select All with collapsed/eye-hidden layers | Include all document layers and label the scope |
| illegal hierarchy group reorder | Disable/no-op without changing order or parent IDs |
| delete multiple layers | Confirm count, apply orphan policy, and commit one Undo step |

## 17. Test Specification

### Unit/controller

- `currentTime` includes fitted scale and is invariant at multiple interactive zooms.
- Device/resize preserves normalized progress and recomputes viewport/travel.
- Add on empty creates neutral anchor; active path captures sample; occupied position only selects.
- Position/X/Y/depth validation preserves prior state on failure.
- Mutations sort strictly; Replace is deterministic; deleting last normalizes null.
- Slider/pad drag makes one undo record; invalid/no-op makes none; Undo/Redo restores exact values.
- New/Open/Undo/Redo reconcile selection; overlay eye never enters history.
- Replace/toggle/range/All/Invert/Clear/Done preserve ID-based primary and anchor invariants.
- Reorder and Undo/Redo keep selection on layer IDs despite changed indices.
- Show/Hide, common/mixed depth, translate, stable Up/Down, and Delete each create one history item;
  no-op/cancel creates none.
- Selected parent plus descendant receives one translate delta; independent selected roots move.
- Group reorder preserves relative order/hierarchy and refuses incompatible moves.
- Multi-delete clears every surviving orphan reference and Undo restores the snapshot.

### Widget

- Properties order is General → Selection → Document on desktop/tablet/phone.
- Z-Depth meaning, response, reset, overflow, hidden/non-renderable copy, and errors render.
- Desktop number stays beside slider; touch exact editing focuses in one tap.
- Empty/one/many path, list/edit/add/delete/reset, XY pad, collision, and phone drill-in are covered.
- Range band exists in Edit; camera lane exists only in Editor + Document + overlay-on, never Viewer.
- Marker/list selection synchronizes and navigation clamps by target travel.
- Semantics and 44-pixel targets are asserted where Flutter exposes them.
- Scene and Canvas synchronize replace/modifier/range selection and primary styling.
- Desktop `Cmd/Ctrl+A` and Escape route through Actions; touch long-press enters selection mode,
  taps toggle, Done collapses, and `more_vert` owns the Parent menu.
- Mixed/common depth never mutates on open; Set/Reset labels include selected count.
- Batch bar uses explicit Show/Hide, disables illegal reorder, and confirms multi-delete.
- Focus and semantics remain valid after batch actions and deletion.

### Rendering/integration

- Fixed-offset Edit positions match shared evaluator for depths `0`, `1`, and `-0.5`.
- Parallax applies once and does not alter scale/rotate/alpha or strip scroll.
- Absent/empty/one-point/zero-depth results match pre-feature positions.
- Save/reopen and Viewer preview retain the same path/depth result.
- v2012 and v2026 fixtures open; v2012 remains inert.
- Puzzle, manipulation, Timeline, sound, Viewer range, and responsive shell regressions pass.
- Primary-layer Timeline/Lettering/Cutting behavior remains compatible under multi-selection.
- Multi-selection is transient and does not alter `.comics` serialization or Viewer output.

Run from `apps/comics-editor`:

```text
flutter analyze
flutter test
```

Run focused `flutter_comics` tests only if shared code changes; none are expected here.

## 18. Deferred / Non-Goals

- No perspective, focal length, rotation, depth-of-field, lighting, or 3D gizmo.
- No schema/evaluator changes and no Camera Path Timeline rows.
- No persistent named selection groups, new `groupId` semantics, marquee/lasso, or saved selection.
- No batch Parent, Kind, artwork/language, or Anim editing; those remain primary-only.
- No Viewer authoring.
- No enabled horizontal-scroll/landscape. A later flow rotates the same logical rail to bottom.
- No redesign of Scene, bottom bar, or unrelated Properties.

## 19. Traceability

| Requirement | Sections |
|---|---|
| Z-Depth control and meaning | 7, 13, 15 |
| Shared live result | 1, 11, 12 |
| Camera CRUD | 8–10 |
| Position/movement context | 5, 6, 10, 11 |
| Target-device Edit viewport | 5, 6 |
| Legacy/inert compatibility | 11, 16, 17 |
| Validation and collision | 7, 9, 13, 16 |
| Undo/Redo and persistence | 7–9, 14, 17 |
| Cross-platform behavior | 4, 10, 13, 15 |
| Viewer authoring hidden | 12 |
| Hidden/non-renderable layers | 7, 14, 16 |
| Shared ID-based multi-selection | 4, 14–17 |
| Mixed/common Z-Depth | 7, 13, 16, 17 |
| Group visibility/translate/order/delete | 7, 14–17 |

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-10
- [x] Notes: Approval authorizes Plan drafting, not implementation.
