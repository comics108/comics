# Implementation Log: Comics Editor Camera Path + Z-Depth UI/UX

> Status: IMPLEMENTATION COMPLETE
> Plan: [04-plan.md](04-plan.md) v0.2 (APPROVED)
> Implemented: 2026-08-10

## Outcome

The approved Editor authoring UX is implemented without changing the `.comics` schema or the
shared `flutter_comics` evaluator. Editor and Viewer now use the same selected-device range model;
camera/depth rendering in Editor delegates to `CameraPathEvaluator` exactly once.

## Delivered

### Selection and group operations

- Stable ID-based linked multi-selection with primary and range anchor, desktop modifier/range
  selection, touch long-press selection mode, Select All, Invert, Clear, and Done/collapse.
- Scene rows keep the visibility eye independent from selection and expose an explicit action menu.
  Compact tablet rows omit only the decorative thumbnail so checkbox, eye, kind, name, and actions
  retain usable touch targets.
- One-transaction batch Show/Hide, Z-Depth Set/Reset, hierarchy-safe Canvas translate, stable
  Up/Down, and confirmed multi-delete. Parent + selected descendant moves only once.
- Canvas paints full handles for the primary and passive outlines for the remaining selection.
  Timeline, Lettering, Cutting, and legacy layer fields continue to resolve through the primary.

### Target viewport and vertical rail

- Added `EditorViewportMetrics`; Edit scroll position is now true document space and divides both
  interactive zoom and target-frame fit scale.
- Edit Canvas is letterboxed through the selected General device profile. Device changes preserve
  normalized document progress and do not persist target-specific camera data.
- Added one shared `VerticalDocumentRail` used by Edit and Viewer. It renders a selected-device
  visible-range band on the right edge; Edit can add a separate camera-marker lane while Viewer
  remains result-only.
- Range and camera marker hit regions, semantics, keyboard stepping, tap/drag navigation, and
  document-height mapping are separate.

### Properties, Z-Depth, and Camera Path

- Properties order is `General / Selection / Document`; General is the calm initial state and an
  explicit layer selection opens Selection.
- General shows selected device dimensions, Vertical scroll + Portrait defaults, and disabled
  future Horizontal scroll + Landscape choices.
- Selection includes single/common/mixed Z-Depth UX, Near/Reference/Far scale, `-0.9…4` soft
  slider, finite `> -1` exact validation, Reset, response readout, and honest hidden/organizational
  counts. Desktop exact values remain beside sliders; touch exact edit is one tap.
- Document includes authoritative ordered Camera Path list, session-only guide eye, Add at current
  document position, anchor/empty explanations, position and X/Y exact controls, XY pad, Reset XY,
  Set current sample, Delete, duplicate Cancel/Replace, and confirmed Reset Path.
- Camera CRUD is sorted, neighbor-clamped for marker preview, one-history-step per commit, and
  reconciled through Undo/Redo. Deleting the last point normalizes the path to `null`.

### Rendering and guides

- Editor composes authored animation with the shared camera parallax adjustment before page
  scaling. Exact depth `0`, `1`, and `-0.5` cases are covered by tests.
- Camera authoring chrome is pointer-ignoring and context-gated to Editor + Document + eye. It
  paints origin, motion vector, current reticle, and a clipped edge arrow for off-canvas samples.
  Hiding the eye hides only guides; the camera/depth effect continues.
- Viewer keeps Scene, Properties, Timeline, selection handles, and camera authoring controls hidden
  while previewing the current unsaved document snapshot.

## Main Files

- `apps/comics-editor/lib/src/ui/controller.dart`
- `apps/comics-editor/lib/src/ui/editor_mode.dart`
- `apps/comics-editor/lib/src/ui/editor_viewport_metrics.dart`
- `apps/comics-editor/lib/src/ui/widgets/scene_panel.dart`
- `apps/comics-editor/lib/src/ui/widgets/canvas_view.dart`
- `apps/comics-editor/lib/src/ui/widgets/properties_panel.dart`
- `apps/comics-editor/lib/src/ui/widgets/numeric_property_control.dart`
- `apps/comics-editor/lib/src/ui/widgets/vertical_document_rail.dart`
- `apps/comics-editor/lib/src/ui/widgets/viewer_workspace.dart`

The planned small Z-Depth, Camera editor, and authoring-overlay files were kept as private widgets
beside their only consumers. This uses the Plan's explicit file-combination allowance and avoids
public widget surface without duplicating behavior.

## Tests Added or Extended

- `layer_selection_controller_test.dart`
- `layer_batch_actions_test.dart`
- `scene_multi_selection_test.dart`
- `current_time_test.dart`
- `vertical_document_rail_test.dart`
- `camera_path_controller_test.dart`
- `camera_depth_properties_test.dart`
- `camera_depth_canvas_test.dart`
- `bottombar_viewer_properties_test.dart`
- `canvas_layout_test.dart` and `canvas_boundary_test.dart`
- reviewed and regenerated four intentional visual goldens for desktop Editor, Viewer, phone
  Properties, and General target viewport.

## Verification Evidence

- Focused selection/batch/parenting/Undo suites: pass.
- Focused viewport/rail/Viewer/layout suites: pass.
- Focused Z-Depth/Camera controller/Properties/Canvas suites: pass.
- Lettering tablet regression after compact Scene adaptation: pass.
- `flutter test`: **430 passed, 3 skipped, 0 failed**. The skips are existing monorepo-only
  multimodal checkout conditions.
- Focused `flutter analyze` over every changed implementation file: no issues.
- Full `flutter analyze`: no errors or warnings; four pre-existing style infos remain in unrelated
  `process_cutting_client.dart`, `ffi_core.dart`, `cutting_canvas.dart`, and
  `bodymovin_import_dialog.dart` (`curly_braces_in_flow_control_structures`).
- Repository-wide format check remains non-green because 45 pre-existing test files do not match
  the current Dart formatter. Changed implementation and focused tests were formatted directly;
  unrelated files were not rewritten for this flow.
- Flutter Web debug compilation succeeded and served the application at a local URL. Interactive
  Chromium inspection could not run because the session exposed no browser backend (`[]`); no
  alternate automation surface was substituted.

## Compatibility and Deviations

- No changes were made to `libs/flutter_comics`, parser/schema, native Viewer, WPF, Timeline data,
  or `.comics` migration behavior.
- `AppVersion.fallback` was synchronized from `3.2.3` to the existing `pubspec.yaml` version
  `3.2.4`; this repairs an existing version-contract test and does not change package versioning.
- The Web server reports that the app has no generated `web/` platform scaffold, but the Flutter
  debug target still compiled and served. Cross-platform implementation uses Flutter-only widgets;
  device-level macOS/Windows/Linux/iOS/Android manual runs remain release-environment QA.

## Handoff

Implementation is ready for the separate Documentation phase. No unapproved schema or product
behavior was introduced.
