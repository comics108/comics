# Implementation Plan: Comics Editor Camera Path + Z-Depth UI/UX

> Version: 0.2
> Status: APPROVED
> Last Updated: 2026-08-10
> Requirements: [01-requirements.md](01-requirements.md) (v0.2, APPROVED)
> Visual: [02-visual.md](02-visual.md) (v0.3, APPROVED)
> Specifications: [03-specifications.md](03-specifications.md) (v0.3, APPROVED)

## 1. Delivery Strategy

Implement in dependency order, preserving a green editor after each phase:

```text
baseline
  → ID-based selection compatibility
  → batch controller operations
  → Scene/Canvas multi-selection UX
  → canonical Edit viewport + shared rail
  → Z-Depth Properties
  → Camera Path controller + Properties
  → camera/depth Canvas rendering + guides
  → responsive/accessibility/regression verification
```

Selection lands before camera/depth UI because Selection Properties and Canvas transforms depend on
it. Correct document-space viewport geometry lands before camera markers/rendering because every
camera position and range must use that coordinate. Controller behavior is tested before widgets so
responsive surfaces share one proven contract.

Do not change `libs/flutter_comics` unless a focused test proves an existing shared evaluator defect.
No parser/schema, native viewer, WPF, Timeline model, or `.comics` migration work is planned.

## 2. Expected File Map

### Modify

- `apps/comics-editor/lib/src/ui/editor_mode.dart`
- `apps/comics-editor/lib/src/ui/controller.dart`
- `apps/comics-editor/lib/src/ui/widgets/scene_panel.dart`
- `apps/comics-editor/lib/src/ui/widgets/canvas_view.dart`
- `apps/comics-editor/lib/src/ui/widgets/properties_panel.dart`
- `apps/comics-editor/lib/src/ui/widgets/numeric_property_control.dart`
- `apps/comics-editor/lib/src/ui/widgets/viewer_workspace.dart`
- selection-dependent tests for Timeline, Lettering, Cutting, viewer/properties, interpolation, and
  Undo/Redo where assertions need the compatibility model

### Create (working names)

- `apps/comics-editor/lib/src/ui/editor_viewport_metrics.dart`
- `apps/comics-editor/lib/src/ui/widgets/vertical_document_rail.dart`
- `apps/comics-editor/lib/src/ui/widgets/z_depth_control.dart`
- `apps/comics-editor/lib/src/ui/widgets/camera_path_editor.dart`
- `apps/comics-editor/lib/src/ui/widgets/camera_authoring_overlay.dart`
- focused controller/widget tests listed in Phase 9

Files may be combined if the resulting widget/controller remains small and independently testable;
behavior and ownership from Specifications must not move into duplicate implementations.

## 3. Phase 0 — Baseline and Regression Guard

### Task 0.1 — Record clean baseline

- [ ] Run focused current tests:
  - `current_time_test.dart`
  - `controller_parenting_test.dart`
  - `controller_undo_redo_test.dart`
  - `canvas_view_interpolation_test.dart`
  - `bottombar_viewer_properties_test.dart`
  - `lettering_*`, `cutting_*`, and `viewer_snapshot_test.dart`
- [ ] Run `flutter analyze` and `flutter test` from `apps/comics-editor`.
- [ ] Record pre-existing failures verbatim in `05-implementation-log.md`; do not weaken assertions
  to hide unrelated failures.

### Task 0.2 — Add failing contract tests first

- [ ] Add focused tests for ID selection invariants, mixed depth, batch history, corrected viewport
  scale, rail lanes, camera CRUD, and exact parallax positions.
- [ ] Keep each red test tied to one subsequent task so failures identify the missing behavior.

Exit: baseline is known and new tests describe the approved contract without production changes.

## 4. Phase 1 — ID-Based Selection Foundation

### Task 1.1 — Introduce selection state

- [ ] Add linked ID selection, `primaryLayerId`, range anchor, and touch-selection-mode state to
  `EditorController`.
- [ ] Add safe lookup helpers: selected layers in document order, selected layers in selection
  recency order, primary index/layer, visible hierarchical IDs, selected count, and membership.
- [ ] Enforce invariants after every selection mutation.
- [ ] Keep layer and sound selection mutually exclusive.
- [ ] Clear/reconcile state on New/Open/close, document replacement, Undo/Redo, delete, and import.

### Task 1.2 — Preserve single-selection consumers

- [ ] Make `selectedLayer`, `selectedAnims`, current Anim, Timeline, Lettering, Cutting, image actions,
  kind fields, parent menu, and other legacy consumers resolve the primary layer.
- [ ] Retain `selKind`/`selIndex` only as synchronized compatibility outputs where removing them in
  this flow would cause unrelated churn.
- [ ] Ensure selecting a sound clears the layer set and selecting a layer clears sound selection.
- [ ] Verify existing single-layer tests before adding multi-selection UI.

### Task 1.3 — Implement selection intents

- [ ] Implement Replace, Toggle, visible Shift Range, Select All, Invert Visible, Clear, and Collapse
  to Primary exactly as Specifications §4.
- [ ] Preserve primary and anchor rules, including primary removal/promotion.
- [ ] Ensure hidden-by-eye layers can be selected, while Shift/Invert do not reach collapsed rows.
- [ ] Add controller tests covering reorder and snapshot restore by stable IDs.

Exit: existing UI behaves as before for one selected layer; controller tests prove multi-selection
state without requiring Scene/Canvas redesign.

## 5. Phase 2 — Batch Controller Operations

### Task 2.1 — Shared transaction helper

- [ ] Add a private helper that freezes selected IDs, resolves surviving targets, opens history once,
  commits once, and produces no history entry for no-op/cancel.
- [ ] Prevent selection changes during a preview gesture from changing its target snapshot.
- [ ] Reconcile primary/focus metadata after mutation without serializing selection.

### Task 2.2 — Visibility and depth

- [ ] Implement explicit Show and Hide for all frozen targets.
- [ ] Add no/common/mixed exact depth resolver.
- [ ] Implement common-depth preview/commit and reset-to-zero for selected targets.
- [ ] Retain hidden/organizational targets while exposing accurate preview-unavailable counts.
- [ ] Validate finite `zDepth > -1` before any mutation.

### Task 2.3 — Hierarchy-safe group translate

- [ ] Determine selected roots by walking `parentId` ancestors.
- [ ] Apply the document-space delta to selected roots and reuse recursive descendant propagation.
- [ ] Verify selected parent+child moves the child once; independent roots each move once.
- [ ] Make one pointer gesture one history entry.

### Task 2.4 — Stable Up/Down

- [ ] Represent selected parent subtrees as atomic reorder blocks.
- [ ] Move legal selected runs one step while preserving internal/raw relative order.
- [ ] Disable/no-op boundary or incompatible hierarchy moves without changing `parentId`.
- [ ] Preserve primary/range selection by ID.

### Task 2.5 — Multi-delete

- [ ] Expose target-count/confirmation state to UI.
- [ ] Delete in descending raw index order.
- [ ] Clear `parentId` on surviving orphans using existing policy.
- [ ] Clear removed IDs/focus safely and commit once; cancellation commits nothing.
- [ ] Verify Undo restores every removed layer and relationship in one step.

Exit: all approved batch semantics are controller-complete and independently tested.

## 6. Phase 3 — Scene and Canvas Selection UX

### Task 3.1 — Scene rows and action header

- [ ] Render checkbox/selection affordance, primary label, selected background/edge, count, and batch
  actions without repurposing the eye.
- [ ] Implement desktop click/modifier/Shift routing through one controller intent.
- [ ] Add `Shortcuts`/`Actions` for platform-standard Select All and unconsumed Escape.
- [ ] Preserve desktop secondary-click Parent menu.
- [ ] Move touch Parent menu to a 44-pixel `more_vert` row control.
- [ ] Show explicit Show/Hide; disable illegal reorder; confirm Delete with count.

### Task 3.2 — Touch selection mode

- [ ] Long-press Scene or Canvas layer to enter selection mode.
- [ ] Make taps toggle while active; All/Invert/Clear/Done call controller operations.
- [ ] Done collapses to primary; document/workspace changes leave touch mode.
- [ ] Ensure local numeric/text Escape handling wins over Scene/Canvas Escape.

### Task 3.3 — Canvas selection and translate

- [ ] Route Canvas click/modifier/long-press through shared selection intents.
- [ ] Paint full handles only for primary and passive outline for other selected layers.
- [ ] Drag primary/handles to call group translate; preserve one-layer behavior exactly.
- [ ] Keep invisible layers non-painted even when selected in Scene.
- [ ] Verify selection does not interfere with pan/zoom gesture arenas.

### Task 3.4 — Compatibility verification

- [ ] Verify primary continues to drive Timeline, Lettering, Cutting, layer fields, and image actions.
- [ ] Verify batch selection is transient and absent from save/Viewer output.
- [ ] Update existing selection assertions only where approved behavior intentionally changes.

Exit: desktop, Web, tablet, and phone can create and act on one shared selection.

## 7. Phase 4 — Canonical Edit Viewport and Shared Rail

### Task 4.1 — Metrics value object and conversion

- [ ] Add `EditorViewportMetrics` with fit scale, target viewport height, and scroll travel.
- [ ] Correct `currentTime` to divide by interactive zoom and document-to-screen fit scale.
- [ ] Add normalized/document offset getters and matrix setter preserving zoom/cross-axis position.
- [ ] Keep metrics update synchronous/non-notifying during layout and avoid sound events on metrics-
  only updates.
- [ ] Preserve normalized progress through target-profile and Canvas-size changes.

### Task 4.2 — Target-device Edit frame

- [ ] Fit the selected General device window inside the existing central Canvas with neutral
  letterboxing.
- [ ] Keep puzzle path and existing responsive panel breakpoints unchanged.
- [ ] Clip comic/result to the target frame while keeping editor controls outside it.
- [ ] Verify iPad/iPhone change visible range, not persisted camera coordinates.

### Task 4.3 — Extract vertical rail

- [ ] Create `VerticalDocumentRail` with viewport lane and optional camera lane.
- [ ] Migrate Viewer range presentation through a wrapper or preserved public/test key.
- [ ] Add Edit range binding to real `currentTime`/matrix, not a second position field.
- [ ] Provide independent 44-pixel hit regions, pointer capture, document-height marker mapping, and
  accessible visible-range semantics.
- [ ] Viewer passes no camera markers or authoring callbacks.

Exit: Edit and Viewer show the same target-range language while retaining independent live scroll
positions; corrected `currentTime` is proven zoom-invariant.

## 8. Phase 5 — Z-Depth Properties

### Task 5.1 — Extend numeric control compatibly

- [ ] Add optional validation copy, semantic value, marks/reference tick, and out-of-soft-range
  presentation without changing existing call-site behavior.
- [ ] Keep desktop exact number beside slider.
- [ ] Keep touch precise edit one tap, focused keyboard, and cancel/restore behavior.
- [ ] Verify slider preview/history boundaries and keyboard adjustments.

### Task 5.2 — Build Z-Depth control

- [ ] Add Near/Reference/Far labels, `-0.9...4`/`0.05` soft slider, exact `> -1` validation, zero
  snap/reset, Custom overflow, shared response readout, and explanatory copy.
- [ ] Render single/common/mixed states and selected count.
- [ ] Mixed remains inert until Set or Reset; Set focuses exact edit before mutation.
- [ ] Report hidden/organizational members honestly.

### Task 5.3 — Integrate Selection Properties

- [ ] Reorder `PropertiesTab` and rendered/focus order to General → Selection → Document.
- [ ] Set initial tab to General without creating unwanted tab switches on file/device/workspace
  changes.
- [ ] Insert Z-Depth alongside existing layer fields without duplicating Scene.
- [ ] Verify desktop/tablet/phone layouts and Properties phone sheet.

Exit: one or many selected layers can safely author and undo depth values on every form factor.

## 9. Phase 6 — Camera Path Controller and Properties

### Task 6.1 — Transient camera authoring state

- [ ] Add selected point and session overlay-eye state.
- [ ] Clear/reconcile on New/Open/Undo/Redo; never dirty/save overlay state.
- [ ] Gate guides to Editor + vertical strip + Document tab + overlay on.

### Task 6.2 — Camera CRUD and validation

- [ ] Add at `round(currentTime)` using `CameraPathEvaluator.sample` before mutation.
- [ ] Select existing point instead of duplicating an occupied Add position.
- [ ] Preview/commit Position and XY with one gesture transaction.
- [ ] Validate Position `0...document.height`, integer, and finite XY.
- [ ] Stable-sort strictly; clamp marker drag between neighbors.
- [ ] Implement explicit duplicate Cancel/Replace and verify Undo restores both prior points.
- [ ] Delete selected; normalize zero points to null; retain/label one anchor.
- [ ] Reset XY, Set current sample, and confirmed Reset Path.

### Task 6.3 — Camera list and point editor

- [ ] Build ordered authoritative list, count, eye, empty/anchor/active explanations, Add, Delete, and
  Reset actions.
- [ ] Build Position slider/exact field and compact XY pad plus exact X/Y controls.
- [ ] Keep XY pad sensitivity stable/labelled and one drag one transaction.
- [ ] Desktop shows list/editor together; tablet can collapse pad; phone drills list → point editor
  within the existing sheet and returns without closing it.
- [ ] Synchronize row selection, rail diamond, Canvas navigation, and selected point after reorder.

Exit: camera paths can be authored, validated, undone, saved, and reopened without JSON editing.

## 10. Phase 7 — Camera/Depth Canvas Rendering and Guides

### Task 7.1 — Apply shared parallax once

- [ ] Compose authored translation with
  `CameraPathEvaluator.parallaxAdjustment(path, currentTime, zDepth)` before screen scaling.
- [ ] Keep strip scroll, scale, rotation, alpha, and Parent semantics unchanged.
- [ ] Verify depth `0`, `1`, and `-0.5` exact positions against shared evaluator.
- [ ] Prove absent/empty/one-point path and all-zero depth are pixel/position inert.

### Task 7.2 — Camera marker lane

- [ ] Feed document-height-normalized points into Edit rail only under the guide gate.
- [ ] Select/tap a diamond and navigate with current-device travel clamp.
- [ ] Drag selected diamond with value bubble, neighbor collision limits, and one history item.
- [ ] Handle overlapping marker hit/accessibility without blocking viewport-band interaction.

### Task 7.3 — Authoring overlay

- [ ] Add pointer-ignoring reticle/current sample, origin/reference, useful vector, and clipped edge
  indicator below selection handles.
- [ ] Hide guides with eye while effect continues rendering.
- [ ] Ensure guides never participate in layer hit-testing, save, export, or Viewer.

### Task 7.4 — Viewer preview

- [ ] Verify `refreshViewer()` includes unsaved in-memory path/depth through existing bridge.
- [ ] Keep Viewer result-only with target range band and no Scene/Properties/Timeline/camera guides.
- [ ] Compare Editor and `flutter_comics_viewer` transforms at the same document offsets.

Exit: Edit and Viewer show the same saved/preview result, with authoring chrome only in Edit.

## 11. Phase 8 — Responsive, Accessibility, and Polish

### Task 8.1 — Responsive verification

- [ ] Desktop: stable panes, editable values beside sliders, list+point editor, independent rail lanes.
- [ ] Tablet: compact three-pane density, collapsible XY pad, 44-pixel touch targets.
- [ ] Phone: selection mode/action bar, Properties drill-in, one-tap exact edits, rail remains usable
  when sheet is closed.
- [ ] Verify macOS, Windows Flutter target, Linux, Web, Android, and iOS use identical semantics with
  input adaptations only.

### Task 8.2 — Keyboard, focus, semantics

- [ ] Verify Tab order, slider arrows/Shift+Arrow, Enter, local Escape, Select All, selection Escape,
  and keyboard alternatives for marker drag.
- [ ] Add semantics for primary/multi-selection, group action count, mixed depth/response, point
  ordinal/X/Y, overlay effect distinction, and target range.
- [ ] Restore focus after batch action/delete as specified.
- [ ] Verify state is never communicated by color alone.

### Task 8.3 — Empty/error/destructive polish

- [ ] Verify v2012, absent/one-point, zero-depth, hidden/non-renderable, invalid number, duplicate
  point, short document, out-of-travel point, illegal reorder, and cancelled delete/reset states.
- [ ] Ensure destructive confirmation names scope and default focus is not destructive on touch.

Exit: every approved Visual state works with pointer, keyboard, touch, and assistive semantics.

## 12. Phase 9 — Test Matrix and Final Verification

### New focused test files (working names)

- [ ] `layer_selection_controller_test.dart`
- [ ] `layer_batch_actions_test.dart`
- [ ] `scene_multi_selection_test.dart`
- [ ] `canvas_multi_selection_test.dart`
- [ ] `editor_viewport_metrics_test.dart`
- [ ] `vertical_document_rail_test.dart`
- [ ] `z_depth_properties_test.dart`
- [ ] `camera_path_controller_test.dart`
- [ ] `camera_path_properties_test.dart`
- [ ] `camera_depth_canvas_test.dart`
- [ ] `camera_depth_responsive_test.dart`
- [ ] `camera_depth_accessibility_test.dart`

### Existing regression suites

- [ ] Update `bottombar_viewer_properties_test.dart` to General → Selection → Document.
- [ ] Extend `current_time_test.dart` for fit scale, zoom invariance, profile/resize preservation.
- [ ] Extend `controller_parenting_test.dart` for selected-root movement and hierarchy reorder.
- [ ] Extend `controller_undo_redo_test.dart` for batch depth/visibility/translate/order/delete and
  camera transactions.
- [ ] Extend `canvas_view_interpolation_test.dart` for exact camera-depth composition.
- [ ] Keep `models_mapping_test.dart` camera/depth round-trip checks green.
- [ ] Keep Lettering, Cutting, Timeline, viewer, sound, puzzle, file association, and v2012 dataset
  suites green.
- [ ] Update goldens only after widget/semantic assertions pass; review every changed pixel rather
  than bulk-accepting output.

### Final commands

From `apps/comics-editor`:

```text
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

If shared Flutter Comics code was necessarily touched, also run its analyzer and complete tests from
`libs/flutter_comics`; otherwise do not expand scope.

### Manual smoke matrix

- [ ] Desktop pointer/keyboard: multi-select, batch move/depth, camera list/rail/XY, Viewer compare.
- [ ] Web Chromium: modifier behavior, focus, exact inputs, rail drag, responsive resize.
- [ ] Touch-sized Flutter test/device: long-press mode, tap toggles, group drag, phone sheet drill-in,
  numeric keyboard path, destructive confirmation.
- [ ] Open both v2012 and v2026 samples; confirm v2012 inert and v2026 camera/depth active.

Exit: analysis and full tests pass, approved states are manually smoke-tested, and any environment-
specific limitation is recorded rather than hidden.

## 13. Phase 10 — Implementation Record and Handoff

- [ ] Update `05-implementation-log.md` after each completed phase with files, tests, deviations, and
  evidence.
- [ ] Keep `_status.md` phase/checklist current.
- [ ] Record any approved Plan deviation before implementing it.
- [ ] After implementation and verification, request the separate Documentation phase; do not mark
  this VDD complete merely because code landed.

## 14. Risk Controls

| Risk | Control |
|---|---|
| Multi-selection breaks single-selection modes | Compatibility facade plus Lettering/Cutting/Timeline tests in Phase 1 before widgets |
| Index drift after reorder/history | Stable `EditorLayer.id` source of truth and reconciliation tests |
| Parent+child moves twice | Selected-root algorithm and exact-delta tests |
| Batch action creates many Undo entries | Frozen-target transaction helper and history-count assertions |
| Edit camera disagrees with Viewer | Shared evaluator and same-offset exact transform tests |
| Scroll uses host/screen pixels | Metrics object, fit-scale conversion, zoom/profile invariance tests |
| Rail lanes steal gestures | Separate hit regions/pointer capture and widget gesture tests |
| Mixed values are silently overwritten | Explicit Set/Reset state and no-mutation-on-open tests |
| Phone becomes action-heavy | Long-press entry, single selection header/action bar, one-tap exact input |
| Scope grows into grouping/Timeline/3D | Explicit non-goals enforced during review and implementation log |

## 15. Completion Criteria

Implementation is complete only when:

- all Must Have Requirements 1–16 pass automated or documented manual verification;
- General/Selection/Document order and Viewer result-only behavior match Visual;
- selection/group actions are ID-stable, hierarchy-safe, accessible, and one-step undoable;
- Edit range and camera positions use selected-device document-space math;
- Z-Depth and Camera Path authoring round-trip and match shared Viewer rendering;
- desktop/tablet/phone behavior is verified;
- `flutter analyze` and full `flutter test` pass, except any explicitly recorded pre-existing failure;
- Implementation Log contains evidence and no unapproved deviation remains.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-10
- [x] Notes: Approval authorizes implementation in this order; it does not waive phase verification.
