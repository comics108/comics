# Specifications: comics-editor-ai-uiux

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-08-01
> Requirements: [01-requirements.md](01-requirements.md)
> Visual: [02-visual.md](02-visual.md)

## Implementation-relevant findings (read before building from this doc)

Six things verified against the real, current code/pipeline before writing the rest of this
document — each one would have produced a wrong design if assumed instead of checked, the same
discipline `vdd-comics-editor-uiux-lettering`'s Specifications called out for its own RPC mistake.

1. **No new RPC is needed to turn an accepted region into a real `Layer`.** `ComicsCore` is one
   generic `call(method, params)` (`lib/src/bridge/comics_core.dart`); the lettering flow already
   established (and this doc confirms by re-reading `controller.dart:455-576`) that layer mutation
   is 100% local Dart state + direct tile-file writes into `CoreDocument.tempFolder/layers/`
   (`lib/src/io/tile_writer.dart`'s `writeTiles`), only persisted wholesale by the existing
   `saveComics` RPC. Accepting a region is `addLayer()` + `setImageFile()`'s pattern, not new
   plumbing.
2. **`Layer.Kind` is already schema-ready for all four kinds.** It's an open string
   (`native/Comics.Editor/Models/Layer.cs:34`), not a closed enum — `background`/`character`/`art`
   need zero C#/schema changes, only new Dart-side UI that interprets values the lettering flow
   already made room for but didn't build editors for.
3. **The shared canvas renders every layer as an opaque placeholder swatch, not real pixels, for
   every kind, today.** `lib/src/ui/widgets/canvas_view.dart:113-136`: box size is
   `doc.width * l.size * k` with a **hardcoded** `h = w * 1.3` aspect ratio, filled with
   `HatchSwatch(l.swatch, ...)` — no `Image.memory`/decoded-bytes rendering exists anywhere in this
   file. This is true for balloons too (their real pixels are only ever previewed inside
   `BalloonEditorCard` via `stitchImage`, never on the shared canvas). **Consequence**: `02-visual.md`'s
   "canvas shows the real source photo + region overlays" is correctly scoped as Cutting mode's
   *own* bespoke widget (new, real-pixel-rendering, decode-and-draw), not a modification of the
   shared Edit-mode canvas — building real-pixel rendering into the shared canvas for every layer
   kind is out of scope (Requirements' "no redesigning unrelated parts of the editor").
4. **`EditorLayer.size` is never serialized or read back — it's a display-only constant (`0.5`
   default) with no backing field in `Layer.cs` at all**, confirmed by `models_mapping.dart:160-196`
   never assigning to `.size` while deserializing. Only `translate` is real, sourced from the first
   `TranslateAnim`'s `(x, y)` (`models_mapping.dart:189-193`; `Layer.Create` in `Layer.cs:72-87`
   writes position the same way). **Consequence**: positioning an accepted region's new layer only
   needs a `TranslateAnim`; there is no meaningful "size" concept to compute or round-trip.
5. **`pipeline.py` has no single-image entry point.** Every stage (`infer_segmenter.py` included)
   operates over `work/alignment.jsonl` — a whole dataset run matched against a known book, not an
   arbitrary image handed to it ad hoc. A **new script** is required for "segment this one image the
   corrector just staged" (see Interfaces).
6. **`infer_regions()`'s bbox coordinates are in fixed 256×256 (`TRAIN_SIZE`) resized space, and no
   region ever gets its pixels exported** — `regions.jsonl` stores only
   `kind`/`confidence`/`bbox` (`infer_segmenter.py:44-50`); crop images are only ever produced later,
   internally, by `build_library.py:119-139` for clustering, and never written to a standalone file
   for a region that isn't accepted into the library. **Consequence**: the new single-image script
   must both rescale bbox back to the source image's real pixel dimensions and emit each region's
   cropped pixels — neither exists today.

## Overview

Adds a third editor mode, **Cutting** (`[Edit | Lettering | Cutting]`, per `02-visual.md`), that
invokes the `comics-multimodal` segmentation model on a staged source image via a real local
subprocess, lets the corrector review/accept/reject/reclassify/adjust the returned regions through a
shared `CuttingReviewCard`, and turns accepted regions into real `Layer`s using the exact
local-mutation + tile-write pattern the lettering flow already proved. A Library tab reads the
pipeline's already-built `work/library/{characters,environments}/<name>/*.png` clusters directly off
disk. Desktop (Windows/macOS/Linux — all three route through `CoreClient`'s NDJSON headless core, per
`lib/src/bridge/comics_core.dart:18-29`; there is no separate Windows-specific core) gets full
functionality; mobile (`DartIoCore`, iOS/Android) gets the disabled-switch state from `02-visual.md`
only — layers a desktop cut produced are ordinary layers and appear normally there regardless.

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `apps/comics-ai/comics-multimodal/scripts/segment_image.py` | Create | New single-image CLI entry point (see Interfaces) — the pipeline has no equivalent today (Finding 5) |
| `apps/comics-ai/comics-multimodal/scripts/infer_segmenter.py` | Modify | Extract a reusable `infer_regions_with_crops()` that also returns rescaled real-pixel bboxes + per-region cropped arrays (Finding 6), used by both the new script and (optionally, later) the existing batch stage |
| `apps/comics-editor/lib/src/ai/cutting_client.dart` | Create | `MultimodalCuttingClient` abstract contract + `CuttingEvent`/`DetectedRegion` (Dart), analogous to `balloon_ai_client.dart` |
| `apps/comics-editor/lib/src/ai/process_cutting_client.dart` | Create | Real desktop implementation: spawns `segment_image.py`, parses NDJSON stdout |
| `apps/comics-editor/lib/src/ai/stub_cutting_client.dart` | Create | Deterministic fake for mobile/tests, mirrors `stub_balloon_ai_client.dart` |
| `apps/comics-editor/lib/src/ai/multimodal_paths.dart` | Create | Shared discovery: Python interpreter + `comics-multimodal` checkout location, and `work/library` path — one resolver used by both the client and the Library tab |
| `apps/comics-editor/lib/src/ui/controller.dart` | Modify | New `CuttingSession` state + `triggerCutting`/`acceptRegion`/`rejectRegion`/`reclassifyRegion`/`adjustRegionBbox` methods, all local mutation (Finding 1) |
| `apps/comics-editor/lib/src/ui/widgets/cutting_canvas.dart` | Create | Bespoke real-pixel canvas: decodes the source image, draws region overlays + spotlight/handles for the selected region (Finding 3 — does not touch `canvas_view.dart`) |
| `apps/comics-editor/lib/src/ui/widgets/cutting_review_card.dart` | Create | Shared, kind-parameterized review card per `02-visual.md`'s Component section |
| `apps/comics-editor/lib/src/ui/widgets/library_browser.dart` | Create | Reads `work/library/{characters,environments}/*` off disk (no subprocess) |
| `apps/comics-editor/lib/src/ui/screens/editor_screen.dart` | Modify | Third mode-switch segment; disabled+popover/inline-note on mobile per `02-visual.md` |
| `native/Comics.Editor/Models/Layer.cs` | Unmodified | Already schema-ready (Finding 2) |
| `apps/comics-ai/comics-multimodal/` batch pipeline (`pipeline.py` et al.) | Unmodified | Untouched — this flow adds a parallel single-image entry point, doesn't change the batch/training pipeline |

## Architecture

### Component Diagram

```
                    Flutter UI (editor_screen.dart)
                              |
      +----------------+-----------------+------------------+
      |                |                 |                  |
  Edit mode        Lettering mode    Cutting mode (new)      |
  (existing)         (existing)       - cutting_canvas.dart  |
                                       - cutting_review_card  |
                                       - library_browser      |
      |                |                 |                  |
      +----------------+-----------------+------------------+
                              |
                     ComicsCore (bridge, existing, unmodified)
                    /                          \
      CoreClient (Windows/macOS/Linux,   DartIoCore (iOS/Android,
      NDJSON, spawns Comics.Editor)      pure Dart, no subprocess)

  Cutting mode's canvas/review card also calls (new, this flow):
                     MultimodalCuttingClient
                    /                        \
      ProcessCuttingClient              StubCuttingClient
      (desktop only: spawns                (mobile — mode switch is
       segment_image.py via                 disabled, so this exists
       dart:io Process)                     only for tests)
              |
    apps/comics-ai/comics-multimodal/scripts/segment_image.py (new)
    -- loads work/models/unet_baseline.pt, runs infer_regions_with_crops(),
       prints NDJSON events to stdout

  Library tab reads directly (new, this flow, no subprocess):
    work/library/{characters,environments}/<name>/*.png
```

### Data Flow — trigger a cut, accept a region

```
Corrector stages a source image (an existing layer, or a freshly imported one -- import mechanism
unchanged, out of scope per Requirements) and taps "Cut / Segment"
  -> EditorController.triggerCutting(sourceImageBytes, sourceLayerIndex)
  -> MultimodalCuttingClient.segment(sourceImageBytes) [ProcessCuttingClient on desktop]
       -> spawns `python3 segment_image.py --image <tmp path> --checkpoint work/models/unet_baseline.pt`
       -> parses stdout NDJSON: {"event":"routing",...} -> {"event":"progress","stage":...}* -> {"event":"success","regions":[...]} | {"event":"failure","reason":...}
  -> EditorController holds CuttingSession { regions: List<DetectedRegion>, status per region }
  -> cutting_canvas.dart renders sourceImageBytes + one overlay box per region (Finding 3: bespoke
     real-pixel widget, not the shared canvas_view.dart)
  -> corrector selects a region -> cutting_review_card.dart shows crop preview (region.cropPng),
     kind dropdown, Accept/Reject
  -> Accept:
       -> EditorController.acceptRegion(region)
       -> writeTiles(bytes: region.cropPng, layersDir: '$tempFolder/layers', name: sanitizeStem(...))
            [identical call shape to setImageFile's Task 2.3 path]
       -> new EditorLayer(tiled.fileTemplate)..kind = region.kind
       -> add a TranslateAnim(x: sourceLayer.translate.dx + region.bbox.x0,
                               y: sourceLayer.translate.dy + region.bbox.y0)   [Finding 4]
       -> doc.layers.add(newLayer); _beginHistory()/_commitHistory(); notifyListeners()
  -> Reject: region marked rejected in CuttingSession only, no layer, no RPC
  -> Reclassify: region.kind reassigned in CuttingSession before Accept (no layer exists yet to mutate)
```

### Data Flow — Library tab

```
Corrector opens the Library tab (within Cutting mode)
  -> MultimodalPaths.libraryDir() resolves work/library/ (env var override, else upward search
     from CWD for apps/comics-ai/comics-multimodal/work/library -- same discovery pattern as the
     Python interpreter, see Interfaces)
  -> library_browser.dart lists Directory(libraryDir/characters) and .../environments,
     each subdirectory = one cluster; thumbnail = first file in it, count = file count
     (no manifest file exists or is needed -- build_library.py's own output has none)
  -> "Insert as layer": reads the chosen PNG's bytes, same writeTiles()+EditorLayer path as
     acceptRegion above, kind set from which top-level folder (characters -> "character",
     environments -> "background")
  -> "Insert into library" (from an accepted region's review card): writes region.cropPng into
     libraryDir/<kindDir>/<name>/<generated-filename>.png, where <name> is a corrector-typed text
     field (new, small addition to 02-visual.md's card -- see Open Design Questions) defaulting to
     "unclustered"; plain filesystem append, no re-clustering/embedding logic in Dart
```

## Data Models

### New Python-side types (`segment_image.py`)

```python
@dataclass
class ImageRegion:
    kind: str                              # "background" | "character" | "balloon" | "art"
    confidence: float
    bbox: tuple[int, int, int, int]        # x0, y0, x1, y1 -- RESCALED to the source image's
                                            # real pixel dimensions, not TRAIN_SIZE (Finding 6)
    crop_png_base64: str                   # rectangular bbox crop of the source image, PNG,
                                            # base64-encoded for NDJSON transport (see rationale
                                            # below on why not a mask)
```

Decision: **rectangular crop, not an alpha-masked cutout.** The underlying model is a
256×256-resolution semantic segmentation baseline (`unet_baseline.pt`); a mask upsampled from that
resolution to real photo resolution produces a blocky, low-quality alpha edge — worse than a clean
rectangular crop, and `02-visual.md`'s own review-card mock shows a plain rectangular "Crop preview,"
not a cutout. `bbox` is retained on `DetectedRegion` for the on-canvas overlay box and for the
`acceptRegion` positioning math either way, so nothing is lost by not also producing a mask this
iteration — a true cutout is a reasonable future refinement, not built here.

### New Dart-side types (`lib/src/ai/cutting_client.dart`)

```dart
abstract class MultimodalCuttingClient {
  Stream<CuttingEvent> segment({required Uint8List sourceImageBytes});
}

sealed class CuttingEvent {}
class RoutingDecided extends CuttingEvent { final bool onDevice; final String? reason; }
class Progress extends CuttingEvent { final String stage; }  // "loading_model" | "segmenting" | "extracting_regions"
class Success extends CuttingEvent { final List<DetectedRegion> regions; }
class Failure extends CuttingEvent { final String reason; final bool retryable; }

class DetectedRegion {
  final String kind;          // "background" | "character" | "balloon" | "art"
  final double confidence;
  final Rect bbox;            // real source-image pixel coordinates
  final Uint8List cropPng;    // rectangular crop -- see rationale above; named cropPng, not
                              // maskPng, deliberately diverging from sdd-comics-ai-multimodal's
                              // original Editor Integration Contract sketch, which used
                              // `maskPng`/`Uint8List maskPng` -- that name would misdescribe what
                              // this iteration actually produces (a crop, not a mask)
}
```

This is a deliberate, disclosed rename from the `DetectedRegion` shape sketched in
`sdd-comics-ai-multimodal`'s Specifications (`maskPng` → `cropPng`) — that sketch predates this
flow's decision (above) to ship rectangular crops, and keeping the old name would leave a
comment/code mismatch (a named anti-pattern this project avoids elsewhere).

### `EditorLayer` / `Layer.cs` — no schema changes

`kind` already accepts `"background"`/`"character"`/`"art"` as an open string (Finding 2); no new
fields needed on either the C# or Dart model. `CuttingSession` (pending/accepted/rejected regions
+ their live edits) is transient `EditorController` state, never serialized into `data.json` — once
a region is accepted it *becomes* an ordinary `Layer`/`EditorLayer` indistinguishable from any other,
which is exactly the cross-device-sync behavior `02-visual.md`'s high-fidelity reference confirmed.

## Interfaces

### New Interfaces — Python (`segment_image.py`)

```
$ python3 segment_image.py --image <path> --checkpoint work/models/unet_baseline.pt

stdout (NDJSON, one line per event):
{"event": "routing", "on_device": true, "reason": null}
{"event": "progress", "stage": "loading_model"}
{"event": "progress", "stage": "segmenting"}
{"event": "progress", "stage": "extracting_regions"}
{"event": "success", "regions": [{"kind": "...", "confidence": 0.92, "bbox": [x0,y0,x1,y1], "crop_png_base64": "..."}]}
-- or, on failure --
{"event": "failure", "reason": "model_checkpoint_not_found", "retryable": false}

exit code 0 on success or a clean failure event; non-zero + no "success"/"failure" line = crash,
mapped by the Dart client to Failure(reason: "process_error", retryable: true)
```

`routing` is always `on_device: true, reason: null` this iteration — there is no server path built
(Requirements Won't Have); the event still fires so the Dart contract and UI (`(o) Local process`
indicator) don't special-case "no routing event" as a distinct state.

### New Interfaces — Dart

```dart
// lib/src/ai/process_cutting_client.dart
class ProcessCuttingClient implements MultimodalCuttingClient {
  // Resolves the Python interpreter + segment_image.py path via MultimodalPaths (below),
  // mirroring CoreClient.resolveBinary()'s env-var-override + upward-search pattern:
  //   COMICS_MULTIMODAL_PYTHON (interpreter) / COMICS_MULTIMODAL_PATH (checkout root) env vars,
  //   else search up to 6 parent directories from CWD for apps/comics-ai/comics-multimodal/.
  // Writes sourceImageBytes to a temp file, spawns the process, decodes NDJSON stdout lines into
  // CuttingEvents, base64-decodes crop_png_base64 into DetectedRegion.cropPng.
}

// lib/src/ai/multimodal_paths.dart
class MultimodalPaths {
  static String? resolvePython();       // interpreter path, or null if not found
  static String? resolveScriptsDir();   // .../comics-multimodal/scripts, or null
  static String? resolveLibraryDir();   // .../comics-multimodal/work/library, or null
}
```

```dart
// lib/src/ui/controller.dart -- new methods, all local mutation (Finding 1), no new RPC
class EditorController {
  CuttingSession? cuttingSession;

  Future<void> triggerCutting(Uint8List sourceImageBytes, int sourceLayerIndex);
  void acceptRegion(int regionIndex);      // writeTiles + new EditorLayer + TranslateAnim, per Data Flow
  void rejectRegion(int regionIndex);      // CuttingSession-only, no layer created
  void reclassifyRegion(int regionIndex, String newKind);
  void adjustRegionBbox(int regionIndex, Rect newBbox); // before accept, canvas resize-handle drag
  Future<void> insertIntoLibrary(int regionIndex, String name); // writes cropPng into work/library/
}

class CuttingSession {
  final Uint8List sourceImageBytes;
  final int sourceLayerIndex;
  List<PendingRegion> regions;
}
class PendingRegion {
  DetectedRegion region;
  RegionStatus status; // pending | accepted | rejected
}
```

### Modified Interfaces

None — `ComicsCore`, `Layer.cs`, existing `EditorController` methods (`addLayer`, `setImageFile`,
`writeTiles`) are reused as-is, not changed.

## Behavior Specifications

### Happy Path

1. Corrector opens a `.comics` document, stages a source image (an existing imported layer),
   switches to Cutting mode, selects it as source, taps "Cut / Segment."
2. `ProcessCuttingClient` spawns `segment_image.py`; UI shows `RoutingDecided` → `Progress` stages →
   `Success` with N `DetectedRegion`s.
3. `cutting_canvas.dart` renders the real source image with all N region boxes overlaid, color-coded
   by kind, confidences shown per `02-visual.md`'s badge tokens.
4. Corrector selects region #4, sees its crop preview + kind + confidence in
   `cutting_review_card.dart`, optionally adjusts its box via resize handles or reclassifies it, taps
   Accept.
5. `acceptRegion` writes tiles, creates a new `Layer` with `kind` set and a `TranslateAnim` at the
   correct document-space position, adds it to `doc.layers`.
6. Corrector repeats for remaining regions (or uses "Accept all >90%"), returns to Edit mode; new
   layers appear in the normal layers list with kind chips already set (rendered as placeholder
   swatches, same as every other layer — Finding 3, not a regression this flow introduces).
7. Corrector saves; `saveComics` persists the whole document including the new layers, same as any
   other edit.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| Python/interpreter not found | `MultimodalPaths.resolvePython()` returns null | `Failure(reason: "python_not_found", retryable: false)` before spawning; UI: "Cutting pipeline not found on this machine" + link/hint, not a crash |
| Checkpoint missing (`work/models/unet_baseline.pt` absent) | Pipeline never trained/run for this checkout | `segment_image.py` emits `{"event":"failure","reason":"model_checkpoint_not_found"}` |
| Source image changed after regions generated | Corrector picks a different source layer or re-imports | Stale-output banner per `02-visual.md`, "Re-run"/"Dismiss" — mirrors `BalloonEditorCard`'s pattern |
| Region rejected then reconsidered | Corrector wants it back | Rejected rows stay visible (grayed, per `02-visual.md`) until the session ends; re-clicking a rejected row returns it to pending, no re-run needed |
| Reclassify a region to "balloon" post-cut | Corrector decides a mis-detected background box is actually a balloon | Allowed freely (kind is just a dropdown value on `PendingRegion`, not tied to the model's original class) before Accept; once accepted, kind is edited the normal way any layer's kind is edited (existing `setLayerKind`) |
| Cutting mode entered with no source image staged | Fresh document, nothing imported yet | Trigger screen's `[ Cut / Segment ]` disabled until a source is picked, with the same "Set as source" prompt from `02-visual.md`'s empty state |
| Library dir doesn't exist yet | Pipeline never run for this project | Library tab's empty state per `02-visual.md`: "Library builds up as you run Cutting on pages" (technically imprecise now that manual inserts also populate it — copy should say "...as you cut or insert items", a small wording note for Plan) |
| `insert into library` with an existing cluster name typed | Corrector types "amba", a folder already exists | Plain append — new file added into the existing `<name>/` directory, no de-dup/merge validation (disclosed simplification, see Open Design Questions) |
| Region's cropPng fails to decode client-side | Corrupted transport / truncated base64 | Region shown with a broken-image placeholder in the review card, kind chip and confidence still usable, Accept disabled for that region until a re-run |

### Error Handling

| Error | Cause | Response |
|-------|-------|----------|
| `python_not_found` | No interpreter resolved | Non-retryable failure, actionable message |
| `model_checkpoint_not_found` | Pipeline never trained in this checkout | Non-retryable, points at running the Python pipeline first |
| `process_error` | Non-zero exit with no structured event | Retryable; "View details" surfaces stderr tail, mirrors `CoreClient._onExit`'s stderr-tail-on-failure pattern |
| Cancel requested mid-run | Corrector taps Cancel (per `02-visual.md`'s running state) | `Process.kill()`; `CuttingSession` cleared back to trigger/empty state, no partial regions kept |

## Dependencies

### Requires

- `apps/comics-ai/comics-multimodal`'s trained checkpoint (`work/models/unet_baseline.pt`) from
  `sdd-comics-ai-multimodal` — must exist in the corrector's checkout for Cutting to function at all.
- `vdd-comics-editor-uiux-lettering`'s `Layer.Kind` field, `writeTiles`/`sanitizeStem`
  (`tile_writer.dart`), and `_beginHistory`/`_commitHistory` undo pattern — all reused, not
  reimplemented.

### Blocks

- Nothing outside this flow.

## Integration Points

### External Systems

None — `segment_image.py` is invoked as a local subprocess, not a network service (Requirements
Won't Have: no server this iteration).

### Internal Systems

- `apps/comics-ai/comics-multimodal/scripts/` (new script + a small `infer_segmenter.py` refactor)
- `apps/comics-editor/lib/src/{ai,ui,io}/*` (new Cutting mode + client)
- `apps/comics-editor/lib/src/bridge/*` — read-only dependency (`ComicsCore.call`, `tempFolder`),
  unmodified

## Testing Strategy

### Unit Tests

- [ ] `segment_image.py`: bbox rescaling from `TRAIN_SIZE` back to real image dimensions, against a
      known synthetic image + known model output
- [ ] `segment_image.py`: NDJSON event sequence (routing → progress* → success|failure) — process
      exit codes for each case
- [ ] Dart `ProcessCuttingClient`: NDJSON parsing, base64 crop decoding, `MultimodalPaths` discovery
      (env var override + upward search), against a fake process/stub stdout
- [ ] `EditorController.acceptRegion`: correct `TranslateAnim` position math
      (`sourceLayer.translate + bbox.origin`), correct `kind` assignment, tile files actually written
- [ ] `EditorController.rejectRegion`/`reclassifyRegion`: `CuttingSession`-only mutation, no tile
      writes, no layer created
- [ ] `library_browser.dart`'s directory scan: cluster name = folder name, count = file count, empty
      state when the directory doesn't exist

### Integration Tests

- [ ] Full trigger→results→accept flow against `StubCuttingClient` (deterministic fake regions),
      confirming real layers with correct `kind`/position land in `doc.layers`
- [ ] Full trigger→results→accept flow against the **real** `segment_image.py` + a real trained
      checkpoint and a real photo from `dataset/.../comics_book_lowcamera/`, confirming at least one
      region round-trips end-to-end (mirrors `sdd-comics-ai-multimodal`'s own real-data verification
      discipline, not just a stub-only test suite)
- [ ] `insertIntoLibrary` writing into an existing `work/library/characters/<name>/` directory
      without disturbing existing files in it

### Manual Verification

- [ ] Full walkthrough of every state in `02-visual.md` (trigger, running, results, stale, failure,
      Library tab, mobile disabled popover/inline-note) against the running desktop app
- [ ] Cut a real page, accept a character region, confirm it appears in Edit mode's layers list with
      the `[Chr]` kind chip, and round-trips through save/reopen
- [ ] Cross-device check: cut a page on macOS, open the saved file on the iPad build, confirm the new
      layers appear normally and Cutting's mode switch is disabled there

## Migration / Rollout

No migration needed — purely additive (new mode, new files, zero schema changes per Finding 2).
Existing documents/layers are unaffected until a corrector actively uses Cutting mode.

## Open Design Questions

- [ ] **"Insert into library" naming field**: `02-visual.md`'s mock shows a plain button with no name
      input; this doc adds a small text field (defaulting to "unclustered") so a corrector can
      target an existing cluster by name. Small, disclosed addition — confirm before Plan, or treat
      as a Plan-time UI detail rather than a Visual amendment.
- [ ] **Library empty-state copy** ("...as you run Cutting on pages") is slightly stale now that
      manual inserts also populate it — cosmetic, fix during Plan/Implementation.
- [ ] **Non-1.0 scale on the source layer**: the `translate`-based positioning math (Finding 4)
      assumes the source layer renders at document-pixel 1:1. If a `ScaleAnim` is ever applied to a
      source layer, region positions would be off by that scale factor. Given `.size`/scale isn't a
      load-bearing concept anywhere else in the app today (Finding 3/4), this is treated as an
      acceptable v1 limitation, not a blocking design gap — confirm.
- [ ] **`segment_image.py`'s temp-file lifecycle**: where the source image bytes get written before
      invoking Python (system temp dir vs. inside `tempFolder`), and cleanup timing — a Plan-time
      detail, not architecturally significant.
- [ ] **Multiple simultaneous cuts**: this spec assumes one `CuttingSession` at a time (matches
      `02-visual.md`, which shows one page's regions at a time). Batch-cutting multiple pages in one
      trigger is out of scope, not precluded by anything here.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-01
- [x] Notes: Approved as-is, including the 6 implementation-relevant findings (no new RPC needed;
      Layer.Kind already schema-ready; shared canvas is swatch-only for every layer today; `size` is
      display-only; the Python pipeline needs a new single-image entry point; region crop/bbox
      rescaling doesn't exist yet) and the `maskPng` → `cropPng` rename. Open Design Questions left
      unresolved, to be settled during Plan.
