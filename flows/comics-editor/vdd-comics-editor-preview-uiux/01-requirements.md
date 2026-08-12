# Requirements: comics-editor-preview-uiux

> Version: 0.2 (2026-08-12, APPROVED): Open Questions resolved by Anton's explicit answers — see
> "Decisions" section, replacing the four previously-open interaction/placement/fallback/persistence
> questions.
> Status: APPROVED (2026-08-12, "reqs approved")
> Last Updated: 2026-08-12

## Problem Statement

Every layer on the main editor canvas (`apps/comics-editor/lib/src/ui/widgets/canvas_view.dart`,
`_LayerItem`) always renders as a colored placeholder swatch (`HatchSwatch`: a flat color rectangle
with a diagonal hatch pattern and the layer's name) — it never shows the layer's real image content,
regardless of any toggle state. This is confirmed by direct inspection, not assumed: `_LayerItem.build`
unconditionally wraps `HatchSwatch(l.swatch, ...)`, and nothing in that method reads `l.preview`.

Two real, relevant pieces of plumbing already exist but are disconnected from rendering:

- **`Layer.preview`** (`libs/flutter_comics/lib/src/models.dart:223`) — a persisted `bool`, already
  serialized to/from `.comics` documents (`apps/comics-editor/lib/src/bridge/models_mapping.dart:382,562-565`).
- **`_PreviewToggle`** (`canvas_view.dart:641-661`) — an existing bottom-right control on the canvas,
  enabled only when a layer is selected, that flips `c.selectedLayer.preview` via
  `EditorController.togglePreview()` (`controller.dart:1576-1581`). Toggling it today changes the
  persisted flag but has **no visible effect** — confirmed, not a bug being fixed elsewhere, since no
  rendering code reads `l.preview`.

Anton's request: wire this up for real, and add a second, canvas-wide toggle. Verbatim: *"Именно
функция preview на основном canvas, когда preview выключен - показываются цветные блоки
прямоугольнички, когда preview включен у элемента или у всего canvas на toggle снизу, тогда у всего
canvas"* — i.e.:

- **Preview off** (per element, the default): show the colored placeholder rectangle (today's
  `HatchSwatch` — unchanged visually).
- **Preview on for one element** (via the existing per-element `_PreviewToggle`, now wired to actually
  change rendering): that element shows its real content instead of the placeholder.
- **Preview on for the whole canvas** (via a new toggle, placed at the bottom of the screen): every
  element shows its real content, not just a selected one.

## Users and Workflows

### Primary user

A comics production editor using `apps/comics-editor` to lay out a document's layers, who wants a
fast way to check what the finished page actually looks like without losing the fast, lightweight
placeholder-block workflow for everyday positioning/timing work.

### Primary workflow

1. Open a document. All layers render as colored placeholder blocks (today's existing behavior,
   unchanged) — fast to drag, resize, and reason about spatially regardless of asset load cost.
2. Select one layer and toggle its own preview on (existing bottom-right control, `_PreviewToggle`) to
   check that one layer's real art in place, still surrounded by every other layer's placeholder block.
3. Toggle preview off again to go back to the fast placeholder view for continued layout work.
4. Use the new canvas-wide toggle (bottom of the screen) to see the whole page's real content at once
   — e.g. before a review or export — then toggle it back off to resume fast editing.

### Secondary workflows

- A layer with no real image asset yet (empty/missing `LayerImage.file`) has preview requested, either
  per-element or via the canvas-wide toggle — falls back to the placeholder swatch, unchanged (see
  Decisions).
- A user has several individual layers with `preview = true` saved from a previous session, then opens
  the canvas-wide toggle — those layers keep showing real content (their own flag already satisfies
  the OR), every other layer also switches to real content, and turning canvas-wide back off returns
  exactly to the prior per-element-only state (see Decisions).

## Must Haves

1. **Real content rendering exists at all**: at least one code path in `_LayerItem` (or its
   replacement) renders a layer's actual image content (from `Layer.images`), not just the
   `HatchSwatch` placeholder — this is the actual gap being closed; today no such path exists.
2. **Per-element toggle is wired to real rendering**: `_PreviewToggle`'s existing bottom-right control
   (enabled only when a layer is selected) continues to flip that one layer's `preview` flag, and that
   flag now visibly determines whether that specific layer shows real content or the placeholder.
3. **New canvas-wide toggle, OR'd with per-element state**: a new toggle in `CanvasView`'s own bottom
   corner (alongside `_PreviewToggle`/`_ZoomControl`) turns real-content rendering on for every layer
   at once when active. A layer renders as real content if EITHER its own `Layer.preview` is `true`
   OR this canvas-wide toggle is `true` — the canvas-wide toggle never reads or mutates any
   individual `Layer.preview` value, and turning it off never changes per-element state.
4. **Placeholder path is preserved unchanged**: when a layer's own `preview` is `false` AND the
   canvas-wide toggle is off, rendering is pixel-identical to today's `HatchSwatch` behavior — this
   change adds a new rendering path, it does not alter the existing one. The same applies as a
   fallback for any layer with a missing/empty `LayerImage.file`, even while preview is otherwise
   requested for it (per-element or via the canvas-wide OR) — no crash, no blank layer, no new
   "broken asset" indicator in this flow's scope.
5. **Transform/animation state still applies to real content**: today's swatch already goes through
   the full transform pipeline (translate/scale/rotate/alpha via `KeyframeInterpolator`, parallax via
   `CameraPathEvaluator`) before being positioned on the canvas (`canvas_view.dart:283-323`) — real
   content must go through the same pipeline, not bypass it, so preview mode shows a faithful
   in-place representation, not a separately-positioned overlay.
6. **Per-element state persists, canvas-wide state does not**: `Layer.preview` is already a
   serialized field — its real-content-toggling behavior must not break existing save/load
   round-tripping. The new canvas-wide toggle is session-local view state only (like zoom/pan) —
   it is never written to the `.comics` schema, and always starts `false` when a document is opened
   or reopened.
7. **No performance regression in the default (placeholder) state**: layers with `preview = false`
   and the canvas-wide toggle off must not eagerly decode/load real image assets — decoding should be
   driven by actually needing to show real content, not happen unconditionally for every layer up
   front.

## Should Haves

- A visibly different affordance for the canvas-wide toggle vs. the per-element one, so a user glancing
  at the screen can tell whether they're looking at "this one real, rest placeholder" vs. "everything
  real" vs. "everything placeholder" without opening a menu.

## Non-Goals

- Redesigning the placeholder swatch itself (`HatchSwatch`'s hatch pattern/labeling) — out of scope,
  it stays as-is for the "preview off" state.
- Changing what counts as a layer's "real content" beyond its existing `Layer.images` — no new asset
  pipeline, no AI-generated preview art.
- Any change to the Puzzle-mode canvas rendering path, unless investigation during Specifications
  finds `_LayerItem` is shared between comic-strip and puzzle modes (not yet confirmed either way).
- Any change to `flutter_comics_viewer` (the separate real-content Viewer destination from
  `vdd-comics-editor-bottombar-uiux`) — that already renders real content in its own tab; this flow is
  specifically about the main editing canvas showing real content in place, without leaving the
  layout-editing view.

## Decisions (2026-08-12, Anton's explicit answers)

- **Per-element vs. canvas-wide interaction — OR'd, non-destructive**: a layer shows real content if
  EITHER its own `Layer.preview` is `true` OR the new canvas-wide toggle is `true`. The canvas-wide
  toggle is a separate, independent flag — it never reads, writes, or otherwise mutates any layer's
  own `preview` value. Turning canvas-wide off never changes per-element state; whatever per-element
  flags were set before stay exactly as they were.
- **Canvas-wide toggle placement — canvas-local corner**: lives alongside the existing
  `_PreviewToggle`/`_ZoomControl` pair, already `Positioned` in `CanvasView`'s own bottom corners
  (`canvas_view.dart:26-31`) — not the app-level bottom navigation from
  `vdd-comics-editor-bottombar-uiux`. No changes needed outside `canvas_view.dart`/`controller.dart`
  for placement.
- **Missing real-image fallback — placeholder swatch, unchanged**: a layer with preview requested
  (per-element or via canvas-wide OR) but an empty/missing `LayerImage.file` silently falls back to
  today's `HatchSwatch` — visually identical to a layer with preview off. No new "broken asset"
  indicator in this flow's scope.
- **Canvas-wide toggle persistence — session-local only**: the canvas-wide flag is view state, like
  zoom/pan/selection — it always starts `false` on document open/reopen and is never written to the
  `.comics` document/schema. `Layer.preview` remains the only persisted preview-related field,
  unchanged from today.

## Open Questions

- [ ] **Puzzle-mode canvas**: does `_LayerItem` render both the comic-strip and puzzle boards (shared
  code), or is there a separate puzzle-specific layer widget? If shared, this feature naturally
  applies to Puzzle mode too; if separate, Puzzle mode is out of scope by default (see Non-Goals) —
  not yet confirmed either way, real codebase check needed during Specifications.

## References

- `apps/comics-editor/lib/src/ui/widgets/canvas_view.dart` (`_LayerItem`, `_PreviewToggle`, `_Stage`)
- `apps/comics-editor/lib/src/ui/controller.dart` (`togglePreview`, `EditorController`)
- `apps/comics-editor/lib/src/ui/widgets/common.dart` (`HatchSwatch`, `_HatchPainter`)
- `libs/flutter_comics/lib/src/models.dart` (`Layer.preview`, `Layer.images`, `LayerImage`)
- `apps/comics-editor/lib/src/bridge/models_mapping.dart` (`preview` serialization)
- `flows/comics-editor/vdd-comics-editor-bottombar-uiux/` (existing bottom-navigation/Viewer-tab work,
  a related but distinct destination for real-content viewing)
