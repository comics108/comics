# Status: vdd-comics-editor-preview-uiux

## Current Phase

DOCUMENTATION

## Phase Status

REVIEW

## Last Updated

2026-08-12 by Codex (Implementation complete; documentation drafted for approval)

## Blockers

- None for implementation. A pre-existing `flutter_comics` Bodymovin path mismatch found by baseline
  was corrected with a path-only compatibility change and targeted tests now compile/pass.

## Progress

- [x] Requirements drafted (v0.1, 2026-08-12)
- [x] Requirements decisions resolved (v0.2, 2026-08-12) — OR'd non-destructive canvas-wide toggle,
      canvas-local corner placement, silent placeholder fallback for missing assets, session-local
      (non-persisted) canvas-wide state
- [x] Requirements approved (2026-08-12, "reqs approved")
- [x] Visuals drafted (v0.1, 2026-08-12) — default state, per-element preview, canvas-wide preview,
      combined OR state (including "All off again" restoring prior per-element state), missing-asset
      silent fallback, bottom-right toggle-cluster component, and the toggle flow diagram
- [x] Visuals approved (2026-08-12, "visual approved")
- [x] Specifications drafted (v0.1, 2026-08-12) — real reuse of `stitchImage`/`imageDimensions`/the
      `balloon_editor_card.dart` resolve-and-cache pattern; new `EditorController.canvasWidePreview`
      (session-local, no undo/redo, no persistence); `_LayerItem` split into a stateless transform
      shell + a `_LayerContent` StatefulWidget passed as `AnimatedBuilder`'s `child`, specifically to
      avoid re-stitching on every pan/zoom frame; `images[0]` fixed as the previewed language slot;
      confirmed Puzzle-mode shares the same rendering path (no extra work needed)
- [x] Specifications approved (2026-08-12, "specs approved")
- [x] Plan drafted (v0.1, 2026-08-12) — 5 tasks: controller field/method (Task 1), `_LayerContent`
      resolution widget (Task 2), `_LayerItem` restructuring around `AnimatedBuilder.child` to avoid
      the pan/zoom re-stitch risk (Task 3, the real crux), toggle-cluster UI (Task 4), regression +
      real manual verification (Task 5)
- [x] Plan approved (2026-08-12, "plan approved")
- [x] Implementation started (2026-08-12)
- [x] Tasks 1-4 implemented — controller state, real plain/tiled layer content, OR rendering through
      `AnimatedBuilder.child`, and bottom-right `Preview` + `All` toggle cluster
- [x] Targeted verification complete — analyzer clean; 46 preview/controller/canvas/tile/balloon
      tests passed, including real file fixtures and no-reload viewport regression
- [x] Task 5 complete — full suite 436 passed / 3 expected skips / 0 failed; macOS app built and
      launched; visual inspection and four golden references confirm the new cluster layout
- [x] Implementation complete (2026-08-12)
- [x] Documentation drafted (`06-readme.md`, 2026-08-12)
- [ ] Documentation approved

## Context Notes

- Confirmed by direct code read (not assumed): `_LayerItem` in
  `apps/comics-editor/lib/src/ui/widgets/canvas_view.dart` always renders `HatchSwatch` (a colored
  placeholder rectangle) — there is currently no code path anywhere that renders a layer's real
  image content on the main canvas.
- `Layer.preview` (bool, `libs/flutter_comics/lib/src/models.dart:223`) and the existing
  `_PreviewToggle` control (`canvas_view.dart:641-661`, bottom-right, per selected layer) already
  exist and are wired to each other and to document serialization, but are **not** wired to any
  rendering behavior — toggling it today is a real, confirmed no-op visually.
- Anton's request adds: (1) wiring the existing per-element toggle to actually swap
  placeholder-vs-real rendering, and (2) a new second toggle, placed at the bottom of the screen,
  that does the same for the whole canvas at once.
- Resolved via AskUserQuestion, all recommended defaults selected: (1) canvas-wide toggle is a
  separate, non-persisted flag OR'd with each layer's own `preview` — never mutates per-element
  state; (2) new toggle lives in `CanvasView`'s own bottom corner next to `_PreviewToggle`/
  `_ZoomControl`, not the app-level bottom nav from `vdd-comics-editor-bottombar-uiux`; (3) a layer
  with preview requested but no real image asset silently falls back to the existing `HatchSwatch`
  placeholder; (4) canvas-wide toggle state is session-local (like zoom/pan), never written to the
  `.comics` schema.
- Only remaining open item: whether `_LayerItem` is shared between comic-strip and Puzzle-mode
  canvases (determines whether this feature naturally covers Puzzle mode too) — a real codebase
  check deferred to Specifications, not a product decision blocking Requirements approval.
- **Specifications finding (confirmed, not blocking)**: Puzzle mode DOES share `_LayerItem`/`_Page`
  (both go through `_interactiveViewer`, `canvas_view.dart:160-180`) — no separate Puzzle work needed.
- **Specifications finding, real reuse**: this app already has working, tested tile-compositing code
  (`stitchImage`/`imageDimensions` in `tile_writer.dart`/`models_mapping.dart`) and an existing
  resolve-and-cache pattern for exactly this problem (`balloon_editor_card.dart`'s
  `_stitchFor`/`_loadPreview`) — the new design reuses both rather than writing a new image pipeline.
- **Specifications finding, real risk**: `_LayerItem` is wrapped in an `AnimatedBuilder` that rebuilds
  on every canvas pan/zoom tick — real-content resolution must be isolated from that rebuild (via
  `AnimatedBuilder`'s `child` parameter) or every pan gesture would re-trigger tile stitching.

## Fork History

None — new flow.

## Next Actions

1. Request explicit `docs approved` for `06-readme.md`.
2. After approval, mark the VDD flow COMPLETE.
