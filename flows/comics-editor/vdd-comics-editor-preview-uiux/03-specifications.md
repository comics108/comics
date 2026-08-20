# Specifications: comics-editor-preview-uiux

> Version: 0.1
> Status: APPROVED (2026-08-12, "specs approved")
> Last Updated: 2026-08-12
> Requirements: [01-requirements.md](01-requirements.md) (v0.2, APPROVED)
> Visual: [02-visual.md](02-visual.md) (v0.1, APPROVED)

## Overview

This closes a confirmed, real gap: `Layer.preview` and `_PreviewToggle` already exist and are wired
to each other and to document serialization, but **no code path today renders real image content on
the main canvas** — `_LayerItem` unconditionally draws `HatchSwatch`. This design wires that up and
adds the new canvas-wide toggle, reusing existing, already-tested asset-resolution code
(`stitchImage`/`imageDimensions`) rather than writing a new image pipeline.

## Affected Systems

| File | Change |
|---|---|
| `apps/comics-editor/lib/src/ui/widgets/canvas_view.dart` | `_LayerItem` gains real-content rendering; `_PreviewToggle` becomes a two-toggle cluster |
| `apps/comics-editor/lib/src/ui/controller.dart` | New session-local `canvasWidePreview` field + `toggleCanvasWidePreview()` |
| `apps/comics-editor/lib/src/io/tile_writer.dart` | **Unchanged** — `stitchImage` is reused as-is |
| `apps/comics-editor/lib/src/bridge/models_mapping.dart` | **Unchanged** — `imageDimensions` is reused as-is |
| `libs/flutter_comics/lib/src/models.dart` | **Unchanged** — `Layer.preview`/`Layer.images` already exist and already round-trip |

No `.comics` schema change. No change to `flutter_comics_viewer` (the separate read-only Viewer tab).

## Real, Already-Existing Building Blocks (confirmed by direct inspection, reused not reinvented)

- **`stitchImage({layersDir, fileTemplate, width, height})`**
  (`apps/comics-editor/lib/src/io/tile_writer.dart:156-185`) — given a tile-template filename
  (`<name>_{0}_{1}_{2}.ext`) and real pixel dimensions, reads each 512px tile off disk from
  `layersDir` and composites them into one PNG-encoded `Uint8List`. Returns `null` for a non-tiled
  template, non-positive dimensions, or any missing/undecodable tile — an existing, safe "can't
  render" signal already used exactly this way elsewhere.
- **`imageDimensions(document, layerIndex, imageIndex)`**
  (`apps/comics-editor/lib/src/bridge/models_mapping.dart:485-503`) — reads real width/height for one
  `Layer.images[n]` slot out of `CoreDocument.raw` (the UI model doesn't carry width/height itself).
  Returns `null` if absent.
- **The exact resolve-and-cache pattern already implemented once**: `_BalloonArtworkPreview`'s
  `_stitchFor`/`_loadPreview` in `apps/comics-editor/lib/src/ui/widgets/balloon_editor_card.dart:150-190`
  — guards on a non-empty, real tile-template file (`file.contains('{0}')`, matching `stitchImage`'s
  own guard), looks up `imageDimensions`, calls `stitchImage`, and holds the result in `State` behind
  a monotonically increasing `_previewRequestId` to discard stale results from superseded requests.
  This flow's real-content rendering reuses the same shape, not a new one.
- **Single (non-tiled) images**: when `LayerImage.file` doesn't contain `{0}`, it's a plain filename
  under `layersDir` — loads via `Image.file(File('$layersDir/$file'))` directly, no stitching needed
  (mirrors `library_browser.dart:237`'s existing use of `Image.file` with an `errorBuilder`).
- **Puzzle-mode reuse confirmed**: `_Page` (which contains the `for (i) _LayerItem(...)` loop,
  `canvas_view.dart:207`) is built by the shared `_interactiveViewer` helper
  (`canvas_view.dart:160-180`), called from **both** the Puzzle branch (`centered: true`) and the
  comic-strip branch of `_Stage.build`. This feature therefore applies to Puzzle mode automatically —
  Requirements' Open Question is resolved: no separate Puzzle-mode work is needed.

## Data Model & State

### `EditorController` — new session-local field

```dart
/// View-only: never persisted to the .comics document (Requirements' approved
/// "session-local" decision), never routed through _beginHistory/_commitHistory
/// (undo/redo is a document-content mechanism; this isn't document content).
bool canvasWidePreview = false;

void toggleCanvasWidePreview() {
  canvasWidePreview = !canvasWidePreview;
  notifyListeners();
}
```

Deliberately **not** modeled like `togglePreview()` (`controller.dart:1576-1581`), which wraps its
mutation in `_beginHistory()`/`_commitHistory()` because `Layer.preview` is real, persisted document
content and participates in undo/redo today (existing, unchanged behavior — out of scope to alter).
`canvasWidePreview` is view state, so it must not create undo/redo entries or dirty the document's
save state.

### Effective per-layer preview — the OR, made concrete

```dart
bool _showsRealContent(EditorController c, EditorLayer l) =>
    l.preview || c.canvasWidePreview;
```

This one-line predicate is the entire "interaction semantics" decision from Requirements — no new
per-layer field, no mutation of `l.preview` by the canvas-wide toggle, exactly the approved
non-destructive OR.

### Language/image-slot selection for real content (new decision, not covered by prior Open Questions)

`Layer.images` is a list of per-culture slots (En/Ru/Hi — `libs/flutter_comics/lib/src/models.dart:193`
doc comment). The placeholder swatch is language-independent, but real content must pick **one** slot
to display. `balloon_editor_card.dart`'s own `_selectedLangCode` is local to that widget's own
language-tab UI and isn't a controller-level "current editing language" — no such concept exists
today (confirmed: no `currentLang`/`activeLang` field on `EditorController`).

**Decision for this flow**: use `images[0]` unconditionally (the same slot `EditorLayer`'s constructor
seeds as primary, `models.dart:210-212`, and the same index `balloon_editor_card.dart` falls back to
when a selected language has no artwork, `registry.codeFor(0)`). If `images[0]` is empty or fails to
stitch, fall back to the placeholder swatch (Must-Have 4's missing-asset rule) — no per-language
preview switching in this flow's scope (matches Requirements' Non-Goals: no new asset pipeline or
language-selection UI). Flagged as an Open Design Question below since a future flow may want the
canvas to preview the currently-edited language instead.

## Rendering Design

### Problem: `_LayerItem` is already wrapped in a viewport-driven `AnimatedBuilder`

`_LayerItem.build` (`canvas_view.dart:225-320`) returns `AnimatedBuilder(animation:
c.canvasViewport, builder: ...)` — this rebuilds on every pan/zoom gesture (confirmed: it's how
translate/scale/rotate/parallax stay live during panning). If real-content resolution (async
tile-stitch or file decode) ran inside that builder without caching, **every pan/zoom frame would
re-trigger a fresh stitch/decode** — a real, confirmed performance risk this design must avoid
(sharpens Must-Have 7 beyond just "no eager decode when off" to "no *repeated* decode while on").

### Chosen structure: split `_LayerItem` into a stateless transform shell + a stateful content resolver

```dart
class _LayerItem extends StatelessWidget {
  // unchanged: selection/drag/gesture handling, AnimatedBuilder for transform math
  // `swatch` (today's HatchSwatch) becomes `content`, built once per (layer, preview-state)
  // change, not per viewport frame:
  Widget content = _LayerContent(
    key: ValueKey(l.id), // survives AnimatedBuilder rebuilds; new instance only if layer identity changes
    controller: c,
    layer: l,
    showReal: _showsRealContent(c, l),
  );
}

class _LayerContent extends StatefulWidget {
  // StatefulWidget, NOT rebuilt by c.canvasViewport's AnimatedBuilder (parent passes it down as
  // a pre-built child, same "child" optimization AnimatedBuilder already supports) -- only
  // rebuilds when `showReal` or `layer.images[0].file` actually change.
}

class _LayerContentState extends State<_LayerContent> {
  Uint8List? _stitched;
  int _requestId = 0; // same discard-stale-results pattern as balloon_editor_card.dart's _previewRequestId

  @override
  void didUpdateWidget(_LayerContent old) {
    if (widget.showReal && !old.showReal) _load();
    // showReal -> false: no eager clear needed, just stop rendering _stitched (Must-Have 4/7)
  }

  Future<void> _load() async { /* same stitchImage/imageDimensions/_stitchFor shape as balloon_editor_card.dart */ }

  @override
  Widget build(context) => widget.showReal && _stitched != null
      ? Image.memory(_stitched!, width: w, height: h, fit: BoxFit.contain)
      : HatchSwatch(widget.layer.swatch, ...); // unchanged placeholder, including missing-asset fallback
}
```

`AnimatedBuilder`'s own `child` parameter (unused today, `canvas_view.dart`'s current `AnimatedBuilder`
has no `child:` argument) is the standard Flutter mechanism for exactly this: a subtree that should
NOT rebuild when the animation ticks. Passing `_LayerContent` as `child` and referencing it via the
builder's `child` parameter (not rebuilding it inline) is what prevents the re-stitch-per-frame risk.

### Single-file vs. tiled resolution inside `_LayerContentState._load()`

```dart
Future<Uint8List?> _resolve() async {
  final document = widget.controller.coreDoc;
  final tempFolder = document?.tempFolder;
  if (tempFolder == null) return null;
  if (widget.layer.images.isEmpty) return null;
  final image = widget.layer.images[0];
  if (image.file.isEmpty) return null;
  if (!image.file.contains('{0}')) {
    // plain file, not tiled
    final file = File('$tempFolder/layers/${image.file}');
    return file.existsSync() ? file.readAsBytes() : null;
  }
  final layerIndex = widget.controller.doc!.layers.indexOf(widget.layer);
  final dims = imageDimensions(document!, layerIndex, 0);
  if (dims == null) return null;
  return stitchImage(
    layersDir: '$tempFolder/layers',
    fileTemplate: image.file,
    width: dims.width,
    height: dims.height,
  );
}
```

Any `null` result (missing dims, missing/undecodable tiles, empty file, no tempFolder) resolves to
"keep showing the placeholder" — the single, uniform missing-asset fallback path Requirements
approved, with no distinct broken-image state.

### Sizing

Today's `HatchSwatch` sizes to `w = doc.width * l.size * k`, `h = w * 1.3` (`canvas_view.dart:232-233`)
— an artificial aspect ratio for the placeholder-only swatch. Real content should size to the
resolved image's own real aspect ratio (`dims.width/dims.height` from `imageDimensions`, or the
decoded image's natural size for a plain file) inside the same `(w, h)` bounding box, via
`Image.memory(..., fit: BoxFit.contain)` — visible in-place without distorting the real artwork,
while keeping the existing transform/position math (`translate`, `k`) untouched (Must-Have 5).

## Toggle-Cluster UI

Replaces the single `_PreviewToggle` (`canvas_view.dart:641-661`) with two adjacent controls in the
same bottom-right `Positioned` slot:

```dart
Positioned(
  right: 14, bottom: 14,
  child: Row(children: [
    _PreviewToggle(c),          // unchanged: enabled only when c.selectedLayer != null, flips l.preview
    const SizedBox(width: 8),
    _CanvasWidePreviewToggle(c), // new: always enabled, flips c.canvasWidePreview
  ]),
)
```

`_CanvasWidePreviewToggle` mirrors `_PreviewToggle`'s existing structure (`canvas_view.dart:641-661`)
minus the selection-gated `onTap: c.selectedLayer == null ? () {} : c.togglePreview` guard — it's
always tappable, calling `c.toggleCanvasWidePreview()`, and reflects `c.canvasWidePreview` for its
on/off visual state (per `02-visual.md`'s `● All` / `○ All`).

## Edge Cases

| Case | Trigger | Expected Behavior |
|---|---|---|
| Layer has no images at all (`images.isEmpty`) | Newly created layer before any artwork import | `_resolve()` returns `null` → placeholder, same as today |
| `images[0].file` is the constructor's synthetic placeholder (`file == name`, no `{0}`) | Freshly created `EditorLayer`, never had real artwork | Not tiled → attempts plain-file load at a path that doesn't exist → `existsSync()` false → `null` → placeholder (same missing-asset path, no special-case needed) |
| Tile files partially missing (some `col_row` files absent) | Interrupted/corrupted asset write | `stitchImage` already returns `null` for any missing tile (`tile_writer.dart:173`) → placeholder |
| `canvasWidePreview` toggled on with zero layers selected | Direct requirement scenario | Every layer's `_showsRealContent` evaluates true via the OR; no selection needed (Must-Have 3) |
| Layer selected, its own `preview` toggled on, then deselected | Selection changes, `_PreviewToggle` becomes disabled again | `l.preview` is unchanged by deselection — that layer keeps showing real content; only the *toggle control's* enabled/disabled state depends on selection, not the rendering |
| Rapid toggling during an in-flight stitch | User flips `Preview`/`All` faster than a stitch resolves | `_requestId` guard (mirroring `balloon_editor_card.dart`'s `_previewRequestId`) discards a stale result if a newer request/hide superseded it before the `Future` completed |
| Undo/redo after toggling canvas-wide preview | User presses Undo | No-op for `canvasWidePreview` (never enters history); may still undo an unrelated prior `l.preview` toggle if that's next on the stack — unchanged existing behavior |
| Puzzle-mode board | Any layer in a Puzzle document | Same `_LayerItem`/`_LayerContent` path (confirmed shared code) — feature works identically, no extra work |

## Testing Strategy

- [ ] Unit: `_showsRealContent` truth table (own-flag only, canvas-wide only, both, neither)
- [ ] Unit: `EditorController.toggleCanvasWidePreview` flips the field, calls `notifyListeners`, and
      does **not** call `_beginHistory`/`_commitHistory` (assert history stack length unchanged)
- [ ] Widget: `_LayerContent` shows `HatchSwatch` when `showReal=false`; shows `Image.memory` with
      stitched bytes when `showReal=true` and a real tiled asset exists on disk (test fixture,
      real `stitchImage` call against small real tiles — same style as `tile_writer_test.dart` if it
      exists, not mocked)
- [ ] Widget: missing-asset fallback — `showReal=true` but no real file on disk → still renders
      `HatchSwatch`, not an error/blank widget
- [ ] Widget: toggling `canvasWidePreview` off after being on with one layer's own `preview=true`
      leaves that one layer real and every other layer placeholder (the "OR, non-destructive" case
      from `02-visual.md`'s "After turning All back off" mockup)
- [ ] Regression: rapid `AnimatedBuilder` rebuilds (simulate pan/zoom ticks) while `showReal=true`
      do not trigger additional `stitchImage`/file-read calls beyond the initial load — the specific
      performance risk this design exists to avoid
- [ ] Regression: existing `_PreviewToggle`/`togglePreview` selection-gating and undo/redo behavior
      unchanged (existing tests, if any, must still pass)

## Open Design Questions

- [ ] **Which language slot to preview** (`images[0]` fixed default, decided above) — a future flow
  may want the canvas to track whichever language is currently being edited elsewhere in the UI; not
  in this flow's scope.
- [ ] **Cache invalidation on asset re-import**: if a layer's `images[0].file`/tiles change (e.g. via
  the balloon editor's own artwork import) while that layer's preview is already showing real
  content, does `_LayerContentState` need to detect the change and re-stitch? `didUpdateWidget`
  above only re-triggers on `showReal` transitioning false→true; a `file` string comparison should
  probably also trigger reload — needs confirming during Implementation against how often this
  realistically happens mid-session.
- [ ] **Toggle-cluster exact visual treatment** (colors/icons for `Preview`/`All`, matching this
  app's existing `Hs.*` design tokens) — left to Implementation to match `_PreviewToggle`'s current
  styling (`canvas_view.dart:641-661`) as closely as possible, not respecified pixel-by-pixel here.

## Specification Acceptance Checklist

- [ ] All Requirements Must-Haves map to a concrete design element above
- [ ] All Visual states (`02-visual.md`) have a corresponding code path
- [ ] Reuses `stitchImage`/`imageDimensions` rather than reimplementing tile compositing
- [ ] Addresses the `AnimatedBuilder` re-render/performance risk explicitly
- [ ] Puzzle-mode scope resolved (shared code, no extra work)

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-12 ("specs approved")
- [ ] Notes:
