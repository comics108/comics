# Status: vdd-comics-editor-preview-uiux

## Current Phase

VISUAL

## Phase Status

DRAFTING

## Last Updated

2026-08-12 by Claude (Requirements approved, starting Visual phase)

## Blockers

- None. Requirements v0.2 incorporate Anton's explicit answers to all four interaction/placement/
  fallback/persistence questions (all recommended defaults) — only Puzzle-mode scope remains open,
  and it's a Specifications-phase codebase check, not a product decision blocking approval.

## Progress

- [x] Requirements drafted (v0.1, 2026-08-12)
- [x] Requirements decisions resolved (v0.2, 2026-08-12) — OR'd non-destructive canvas-wide toggle,
      canvas-local corner placement, silent placeholder fallback for missing assets, session-local
      (non-persisted) canvas-wide state
- [x] Requirements approved (2026-08-12, "reqs approved")
- [x] Visuals drafted (v0.1, 2026-08-12) — default state, per-element preview, canvas-wide preview,
      combined OR state (including "All off again" restoring prior per-element state), missing-asset
      silent fallback, bottom-right toggle-cluster component, and the toggle flow diagram
- [ ] Visuals approved
- [ ] Specifications drafted
- [ ] Specifications approved
- [ ] Plan drafted
- [ ] Plan approved
- [ ] Implementation started
- [ ] Implementation complete
- [ ] Documentation drafted
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

## Fork History

None — new flow.

## Next Actions

1. Request explicit "visual approved" from Anton for `02-visual.md` v0.1.
2. Move to Specifications phase: design the actual `_LayerItem`/`_PreviewToggle`/`EditorController`
   changes, confirm whether `_LayerItem` is shared with Puzzle-mode rendering, and decide the real
   image-loading mechanism (sync vs. async decode, caching) behind Must-Have 7 (no eager decode when
   preview is off).
