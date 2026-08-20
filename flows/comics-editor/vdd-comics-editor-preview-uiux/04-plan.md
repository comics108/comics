# Implementation Plan: comics-editor-preview-uiux

> Version: 0.1
> Status: APPROVED (2026-08-12, "plan approved")
> Last Updated: 2026-08-12
> Specifications: [03-specifications.md](03-specifications.md) (v0.1, APPROVED)

## Summary

Four small, mostly-independent code changes (controller field/method, a new stateful content
widget, `_LayerItem` restructuring, toggle-cluster UI), each reusing existing, already-tested
building blocks (`stitchImage`, `imageDimensions`, the `balloon_editor_card.dart` resolve pattern) —
no new image pipeline, no schema change. Real risk is concentrated in one place: making sure
real-content resolution doesn't re-run on every canvas pan/zoom frame (Specifications' `AnimatedBuilder`
finding) — Task 3 and its dedicated regression test are the actual crux of this Plan.

## Task Breakdown

### Task 1: `EditorController.canvasWidePreview` + `toggleCanvasWidePreview()`
- **Description**: Add the session-local `bool canvasWidePreview = false` field and
  `toggleCanvasWidePreview()` method per Specifications' Data Model section — explicitly not routed
  through `_beginHistory()`/`_commitHistory()` (unlike the existing `togglePreview()`), and never
  written to `document.raw`/serialization.
- **Files**:
  - `apps/comics-editor/lib/src/ui/controller.dart` — Modify (add field + method near
    `togglePreview()`, `controller.dart:1576-1581`)
- **Dependencies**: None
- **Verification**: unit test asserting `toggleCanvasWidePreview()` flips the field, calls
  `notifyListeners()`, and leaves the undo/redo history stack length unchanged (extends
  `controller_undo_redo_test.dart`)
- **Complexity**: Low

### Task 2: `_LayerContent` — real-content resolution widget
- **Description**: New `StatefulWidget` implementing Specifications' `_resolve()` logic: plain-file
  vs. tile-template detection (`file.contains('{0}')`), `imageDimensions` + `stitchImage` for the
  tiled case, direct `File(...).readAsBytes()` for the plain case, all `null`-safe fallbacks
  collapsing to "render nothing here" (caller decides placeholder). Includes the monotonic
  `_requestId` guard against stale async results (same shape as `balloon_editor_card.dart`'s
  `_previewRequestId`), and `didUpdateWidget` re-triggering on a `showReal` false→true transition.
- **Files**:
  - `apps/comics-editor/lib/src/ui/widgets/canvas_view.dart` — Modify (new private widget class in
    the same file, alongside `_LayerItem`/`_PreviewToggle`)
- **Dependencies**: None (only depends on already-existing `stitchImage`/`imageDimensions`)
- **Verification**: widget test with real small tile fixtures on disk (same fixture style as
  `tile_writer_test.dart`) confirming stitched bytes resolve correctly; a second case for a plain
  (non-tiled) file; a third for every `null`-fallback trigger (empty file, missing dims, missing
  tile, no tempFolder)
- **Complexity**: Medium (mostly porting an already-proven pattern, but real async/state-guard logic
  to get right)

### Task 3: `_LayerItem` restructuring — wire real content into the transform pipeline
- **Description**: Split today's inline `swatch` construction (`canvas_view.dart:236-263`) so that
  the layer's visual content — `HatchSwatch` or `_LayerContent` depending on
  `l.preview || c.canvasWidePreview` — is built **once** and passed into `AnimatedBuilder` via its
  `child` parameter, not rebuilt inside `builder:` on every `c.canvasViewport` tick. This is the
  specific fix for Specifications' confirmed performance risk (pan/zoom re-triggering stitch). Real
  content sizes via `BoxFit.contain` inside the existing `(w, h)` bounding box; falls back to
  `HatchSwatch` whenever `_LayerContent` has nothing to show yet (loading or permanently unresolvable).
- **Files**:
  - `apps/comics-editor/lib/src/ui/widgets/canvas_view.dart` — Modify (`_LayerItem.build`,
    `canvas_view.dart:225-320`)
- **Dependencies**: Task 1 (needs `c.canvasWidePreview`), Task 2 (needs `_LayerContent`)
- **Verification**: widget test asserting `HatchSwatch` renders when both preview sources are off;
  `_LayerContent`'s real-image path renders when either is on; **the regression test that matters
  most**: simulate multiple `c.canvasViewport` change notifications (pan/zoom ticks) while
  `showReal=true` and assert the underlying stitch/file-read is invoked exactly once, not once per
  tick
- **Complexity**: Medium-High (the `AnimatedBuilder`/`child` wiring must be done correctly or the
  performance regression test will catch a real, silent slowdown during panning)

### Task 4: Toggle-cluster UI — add the canvas-wide toggle alongside the existing one
- **Description**: New `_CanvasWidePreviewToggle` widget (same visual structure as `_PreviewToggle`,
  `canvas_view.dart:641-661`, minus the selection-gating), placed in a `Row` with the existing
  `_PreviewToggle` inside `CanvasView`'s existing bottom-right `Positioned` slot
  (`canvas_view.dart:26-31`). Calls `c.toggleCanvasWidePreview()`, reflects `c.canvasWidePreview` for
  on/off state, per `02-visual.md`'s toggle-cluster mockup.
- **Files**:
  - `apps/comics-editor/lib/src/ui/widgets/canvas_view.dart` — Modify (`CanvasView.build`,
    `_PreviewToggle` class becomes a sibling `_CanvasWidePreviewToggle` class)
- **Dependencies**: Task 1 (needs `c.canvasWidePreview`/`toggleCanvasWidePreview`)
- **Verification**: widget test confirming the new toggle is always tappable regardless of selection
  (unlike `_PreviewToggle`), and that tapping it flips `c.canvasWidePreview` and triggers a rebuild
  showing real content across multiple layers at once
- **Complexity**: Low

### Task 5: Full regression pass + real visual verification
- **Description**: Run the full existing `apps/comics-editor` test suite (confirm no regressions in
  `canvas_layout_test.dart`, `canvas_view_interpolation_test.dart`, `controller_undo_redo_test.dart`,
  `tile_writer_test.dart`, `balloon_editor_card_test.dart` — none of which this Plan intends to
  change, but all touch code this Plan's changes are adjacent to). Then a real, manual visual
  check: open an actual document with a real tiled asset in the running editor, confirm the
  placeholder-block default, per-element toggle, and canvas-wide toggle all look and behave exactly
  as `02-visual.md` describes — not just asserted by widget tests.
- **Files**: None (verification only)
- **Dependencies**: Tasks 1-4
- **Verification**: full `flutter test` run, green; one real documented manual pass in the actual
  desktop Comics Editor app (screenshot or explicit description of what was seen), per this repo's
  own established "real completion proof" standard (not unit tests alone)
- **Complexity**: Low

## Dependency Graph

```
1.1 (controller field/method) ─┬─> 3 (LayerItem restructuring) ─┐
2 (_LayerContent widget) ──────┘                                 ├─> 5 (regression + real verification)
1.1 ────────────────────────> 4 (toggle-cluster UI) ─────────────┘
```

## File Change Summary

| File | Action | Reason |
|---|---|---|
| `apps/comics-editor/lib/src/ui/controller.dart` | Modify | `canvasWidePreview` field + `toggleCanvasWidePreview()` (Task 1) |
| `apps/comics-editor/lib/src/ui/widgets/canvas_view.dart` | Modify | New `_LayerContent` widget (Task 2); `_LayerItem` restructuring for `AnimatedBuilder.child` (Task 3); new `_CanvasWidePreviewToggle` + toggle-cluster layout (Task 4) |
| `apps/comics-editor/test/*` | Modify/Create | Unit/widget tests per Tasks 1-4's own verification steps |

No changes to `tile_writer.dart`, `models_mapping.dart`, or `libs/flutter_comics` — all reused as-is.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Real-content resolution re-runs on every pan/zoom tick if `AnimatedBuilder.child` is wired incorrectly | Medium — easy to get subtly wrong (e.g. building `_LayerContent` inside `builder:` instead of passing it as `child`) | High (real, user-visible stutter while panning with preview on) | Task 3's dedicated regression test asserts stitch/read call count, not just visual correctness |
| `images[0]`-only preview surprises a user editing a non-default language | Low — real but narrow (Specifications' own flagged Open Design Question) | Low (preview shows the "wrong" language's art, not a crash) | Explicitly disclosed as a known scope limitation, not silently assumed correct; easy follow-up flow if it matters in practice |
| Missing-asset fallback silently looks identical to preview-off | Certain — this is the approved design, not a bug | Low (a user might not realize an asset failed to resolve vs. simply not having preview on) | Anton's own explicit choice (`01-requirements.md` Decisions) over a distinct broken-image indicator; not revisited here |
| Toggling `canvasWidePreview` interacts unexpectedly with undo/redo if wired like `togglePreview()` by mistake | Low — explicitly designed against in Specifications | Medium (would dirty save state / create spurious undo entries for a view-only toggle) | Task 1's own verification explicitly checks history stack length is unchanged |

## Rollback Strategy

All changes are additive to two existing files (`controller.dart`, `canvas_view.dart`) plus new
tests — no schema change, no new files outside tests. Rollback is reverting those two files; no
migration, no data loss, `Layer.preview`'s existing persisted behavior is untouched either way.

## Checkpoints

After each task, verify:

- [ ] The specific task's own verification step passes
- [ ] No regression in adjacent existing test files listed in Task 5
- [ ] `flutter analyze` clean on changed files

## Open Implementation Questions

- [ ] Exact `Row`/spacing/styling for the two-toggle cluster (Specifications left this to
  Implementation, matching `_PreviewToggle`'s existing visual style) — decide when actually building
  Task 4, not guessed here.
- [ ] Whether `_LayerContent` needs to react to `images[0].file` changing mid-session (Specifications'
  own flagged Open Design Question) — attempt the simple `didUpdateWidget` file-comparison check
  during Task 2; skip if it adds real complexity disproportionate to how often this happens in
  practice (asset re-import while that exact layer's preview is already on).

---

## Approval

- [ ] Reviewed by: Anton Dodonov
- [ ] Approved on:
- [ ] Notes:
