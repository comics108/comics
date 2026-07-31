# Specifications: comics-ai-multimodal

> Version: 1.1
> Status: APPROVED (revised during Implementation, see Revision 1.1 note below)
> Last Updated: 2026-07-31
> Requirements: [01-requirements.md](01-requirements.md)

## Overview

A from-scratch-trained segmentation ("cutting") pipeline, living entirely under
`apps/comics-ai/comics-multimodal/`, that decomposes a flattened comic page image back into its
constituent, kind-tagged layer regions (background/character/balloon/sound-visual/motion-fx).

The key insight this design leans on: the 27 existing `dataset/.../comics_interactive/*.comics`
files are themselves a **free, exact ground-truth segmentation dataset** — every layer's pixels,
position, and (where tagged) `Kind` are already known. Rendering each file's known layer stack to a
flat composite gives a (flat image → known layers) training pair with zero manual labeling. The
80 `comics_book_lowcamera/*.jpg` photos are real camera captures of the *same* underlying pages, but
arrive with **no photo↔episode/page mapping** — so an automatic alignment step is the first real
piece of new engineering this flow contributes, and it does double duty: it is both the mechanism
that produces real (photo → ground truth) pairs for training/validation, *and* the mechanism the
photo→`.comics` end-to-end scenario needs at inference time.

Because every real photo in this dataset happens to have a known ground-truth match, this
iteration's photo→`.comics` scenario is best understood as a **validation vehicle** for the cutting
model (prove it recovers the true layers on real camera input, not just clean synthetic renders) —
the durable long-term value is the *same* model later generalizing to material with no ground truth
(new printed pages, sketches, text-only chapters — all explicitly deferred scenarios). Specs below
are written with that generalization in mind, not just to round-trip data we already have.

Balloon-specific deep processing (OCR, translation matching, erase/re-render) is **not
reimplemented** here — this pipeline only detects/cuts balloon *regions*; the existing
`apps/comics-ai/comics-ai-baloons/` pipeline remains the system of record for what happens inside a
balloon region once found.

### Revision 1.1 (Implementation Checkpoint A finding): per-panel matching, not whole-page homography

**During Implementation (2026-07-31), visually inspecting real `comics_book_lowcamera/*.jpg` photos
falsified this document's original alignment design.** The printed book is a conventionally
paginated comic (fixed rectangular panel grids, real page numbers running to 198+, two-page
spreads) — **not** a photographed rectangular crop of the tall (~33000px) scrolling digital canvas.
The print edition re-composes the same underlying story into an independently laid-out panel grid
(different cropping/resizing/arrangement per panel), so a single perspective-homography match of a
whole photographed page against a canvas y-range (the original stage [4]/Task 5.1-5.2 design) cannot
work — there is no rigid crop+warp relationship at the page level.

**Revised approach, confirmed with the user**: align at **panel granularity**, using **content**
(OCR + visual features), not page geometry — the same principle `comics-ai-baloons` already used for
CSV matching (never guess from position/order, always confirm from content). Concretely: detect
individual panels within a photographed page; OCR each panel's balloon text; fuzzy-match that text
against `comics-ai-baloons`'s own already-computed per-balloon OCR corpus (`work/ocr.jsonl` from
that pipeline, reused via the bridge — not the translation CSV, which isn't the right corpus here).
A matched balloon layer identifies both the source episode and a *local scroll-position
neighborhood* (via `kind_heuristic.py`'s existing y-window clustering) of nearby background/
character layers — that local cluster, not a rectangular canvas crop, is the ground truth a matched
panel is evaluated against. See the updated stage [4], `AlignmentResult`/`PanelBox` data models, and
Edge Cases below for the full revision. Section headers below are updated in place; this note is
kept for traceability rather than silently rewriting history.

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `dataset/*.comics`, `dataset/.../comics_book_lowcamera/*.jpg`, `spiritual_text/` | **Read-only** | Never written to. |
| `apps/comics-ai/comics-multimodal/scripts/` | Create | New Python pipeline. |
| `apps/comics-ai/comics-multimodal/work/` | Create (gitignored) | Rendered canvas references, alignment cache, trained model checkpoints, cut regions, character/environment library, output `.comics`, reports. |
| `apps/comics-ai/comics-ai-baloons/` | **Read + invoke, not modified** | Reused as-is for balloon-region deep processing (see Integration Points). |
| `apps/comics-editor` (native C# model) | **Not modified this iteration** | Read for schema ground-truth only (as `sdd-comics-ai-baloons` did). An editor-integration contract is *designed* (see Editor Integration Contract) but not built. |

## Architecture

### Component Diagram

```
dataset/*.comics ──▶ [1] Render Canvas Reference ──▶ [2] Synthetic Degradation ──▶ [3] Train
                        (composite + exact              (per-local-cluster crop,      Segmentation
                         ground-truth layer map,          not arbitrary rectangles     Model
                         per episode)                     → simulate camera capture)      │
                                                                                              │
dataset/.../comics_book_lowcamera/*.jpg ──▶ [4a] Detect Panels ──▶ [4b] Match Panel to    │
                                               (per photo, page-      Known Scene            │
                                                level rectify first)   (OCR+visual content,   │
                                                        │               skip+log if low        │
                                                        │               confidence — NOT        │
                                                        │               page-level homography)  │
                                                        └───────────────────┬─────────────────┘ │
                                                                            ▼                   ▼
                                                              matched episode + local    [5] Run Segmentation
                                                              layer cluster (via              Model (inference)
                                                              kind_heuristic y-window)              │
                                                                            │                        ▼
                                                                            └──────────────▶ [6] Cut Regions
                                                                                              (masks + kind + conf.)
                                                                                      │
                                          ┌───────────────────────────────────────────┼─────────────────────┐
                                          ▼                                           ▼                     ▼
                                [7a] Balloon regions                     [7b] Character/Environment   [7c] Other art
                                → handoff to                              regions → Library Builder     regions →
                                comics-ai-baloons (reused)                 (cluster + gallery export)    passthrough
                                          │                                           │                     │
                                          └───────────────────────────┬───────────────┴─────────────────────┘
                                                                       ▼
                                                          [8] Package `.comics`
                                                       (reuse tiling/packaging conventions
                                                              from comics-ai-baloons)
                                                                       ▼
                                          apps/comics-ai/comics-multimodal/work/output/
                                          + work/library/{characters,environments}/
                                          + work/report.*
```

[9] **Quality correction** (lower priority) is an optional pre-pass between a raw photo and stage
[4]/[5], trained on the same synthetic clean/degraded pairs stage [2] already produces — see
Behavior Specifications.

Each stage is a separate script with a serialized intermediate artifact in `work/`, resumable and
inspectable stage-by-stage, matching the `comics-ai-baloons` convention.

### Data Flow

1. **Render Canvas Reference**: for each of the 27 `.comics` files, resolve every layer's *resting*
   (post-animation, final-keyframe) position/alpha, composite the full 1080×H canvas, and emit a
   parallel ground-truth map: for every region, which `layer_index`, its `Kind` (open string — see
   Editor Schema Ground Truth), and its mask/bbox in canvas coordinates.
2. **Synthetic Degradation** *(revised)*: rather than cropping arbitrary rectangular windows of the
   tall canvas, crop **local content clusters** — for each balloon layer (or, more generally, each
   `kind_heuristic.py` y-window neighborhood), take the tight bounding region spanning that
   neighborhood's background/character/balloon layers together, i.e. something shaped like an
   actual printed panel rather than an arbitrary slice of scroll. Apply the camera-realism
   augmentation pipeline (perspective warp, lighting/vignette, blur, sensor noise, JPEG artifacting,
   mild rotation, plus a print-style resize since panels are laid out at varying print sizes) to
   produce (degraded panel-like crop → exact ground truth) training pairs at effectively unlimited
   volume from only 27 source files. This is a direct consequence of the Checkpoint A finding below:
   real photos show individually-composed print panels, not raw canvas windows, so synthetic
   training data should resemble panels, not windows.
3. **Train Segmentation Model**: a from-scratch instance-segmentation network (architecture TBD, see
   Open Design Questions) trained on stage-2 synthetic pairs, predicting per-region masks + `Kind`
   labels from a flattened input image.
4. **Detect Panels + Match Panel to Known Scene** *(revised — see Revision 1.1 above)*: for each
   real `comics_book_lowcamera/*.jpg`, first detect individual panel boundaries on the (page-level
   rectified) photo; then, per panel, OCR its balloon text and fuzzy-match against
   `comics-ai-baloons`'s own per-balloon OCR corpus (reused via the bridge, not the translation CSV)
   to identify which episode + balloon layer that panel's content matches — content-based, no manual
   mapping, no page-level homography. A matched balloon layer's local `kind_heuristic.py`
   neighborhood (background/character/balloon layers near the same resting y-position) is the
   ground-truth cluster that panel is evaluated against. Skip + log panels that can't be confidently
   matched, exactly as `comics-ai-baloons` does for CSV matching.
5. **Run Segmentation Model**: apply the stage-3 model to each detected (perspective-corrected)
   panel crop.
6. **Cut Regions**: materialize stage-5's predicted masks as cropped region images, each tagged with
   predicted `Kind` + confidence. Where a panel has a confident stage-4 match, its predicted regions
   can be **evaluated** against the true ground-truth cluster from stage 1 (this is the real,
   non-circular validation of the model, since the model itself never saw that photo during
   training, and stage 4's match only tells *which cluster* to compare against, not what the model
   should predict).
7. **Route by kind**:
   - **7a Balloon regions** → handed off to `comics-ai-baloons`'s existing discovery/OCR/match/erase
     pipeline (invoked as a library call or subprocess, not duplicated).
   - **7b Character/Environment regions** → Library Builder: cluster same-identity crops (see
     Data Models) into `work/library/{characters,environments}/<name>/`.
   - **7c** Other art (plain background/foreground art with no further specialized handling this
     iteration) passes through unchanged.
8. **Package**: reuse `comics-ai-baloons`'s tiling/packaging code (512px tile grid, `data.json`
   shape) to assemble a new, valid `.comics` file per successfully-aligned+cut photo into
   `apps/comics-ai/comics-multimodal/work/output/`.

## Editor Schema Ground Truth

Reused verbatim from `sdd-comics-ai-baloons/02-specifications.md` (verified against
`apps/comics-editor/native/Comics.Editor` C# source, not re-verified here) — see that document for
the `Cultures` enum, tiling algorithm, and `data.json` layer shape. One addition, from
`vdd-comics-editor-uiux-lettering` (implemented, live in code):

```csharp
// Models/Layer.cs — additive, nullable, DefaultValueHandling.Ignore (legacy files round-trip byte-identically)
public string Kind;                        // open string: "balloon", "caption", ... — not a closed enum
public string Style;                        // balloon-only today: "speech" | "hand_lettered"
public Dictionary<string,string> Translations;
```

This pipeline **reuses `Kind`** for its own region taxonomy (`"background"`, `"character"`,
`"balloon"`, `"sound"`, `"motion_fx"`, plus `"art"` as the fallback for otherwise-unclassified art
layers) rather than introducing a second, competing taxonomy field. Only 27 dataset files have any
`Kind` values today (balloons, from the lettering flow forward) — most existing layers have `Kind =
null`, meaning the ground-truth map from stage 1 above must derive an initial `Kind` for
non-balloon layers itself; see Data Models / `CanvasReference`.

## Interfaces

### New Interfaces (CLI, `apps/comics-ai/comics-multimodal/scripts/`)

```
render_canvas.py      <dataset dir> --out work/canvas/<episode>.png + work/canvas/<episode>.gt.json
augment.py             work/canvas/ --out work/train_pairs/ --count N
train_segmenter.py     work/train_pairs/ --out work/models/segmenter.pt
align_photo.py         <lowcamera dir> work/canvas/ --out work/alignment.jsonl
enhance.py             work/alignment.jsonl --out work/enhanced/          # quality correction, lower priority
infer_segmenter.py     work/models/segmenter.pt work/alignment.jsonl --out work/regions.jsonl
route_balloons.py      work/regions.jsonl --out work/balloon_handoff.jsonl   # feeds comics-ai-baloons
build_library.py       work/regions.jsonl --out work/library/
package.py             work/regions.jsonl work/alignment.jsonl --out work/output/
report.py              work/*.jsonl --out work/report.md work/report.jsonl
pipeline.py            # runs all of the above in order, resumable per-stage
```

### Modified Interfaces

None — `apps/comics-editor` and `apps/comics-ai/comics-ai-baloons` are not modified this iteration
(the latter is invoked, not edited).

## Data Models

### `CanvasReference` (per episode, from stage 1)

```python
@dataclass
class CanvasReference:
    episode_file: str            # dataset .comics filename
    width: int
    height: int                  # up to ~33000
    composite_png: str           # path under work/canvas/
    regions: list["GroundTruthRegion"]

@dataclass
class GroundTruthRegion:
    layer_index: int             # index into data.json "layers"
    kind: str                    # existing Layer.Kind if set, else inferred (see below)
    kind_source: Literal["explicit", "inferred_heuristic"]
    bbox: tuple[int, int, int, int]     # resting-position canvas coordinates
    mask_png: str | None          # per-pixel alpha-derived mask, if not a simple rect
```

`kind_source="inferred_heuristic"` covers the vast majority of legacy layers with no `Kind`: a
simple rule pass (single populated image slot + large area + bottom-of-stack → `"background"`;
single slot + mid-stack + roughly-humanoid aspect/size → `"character"`; ≥2 populated slots →
`"balloon"`, reusing the exact structural rule `sdd-comics-ai-baloons` already validated;
otherwise → `"art"`). This heuristic labeling is itself an approximation and must be spot-checked
(see Testing Strategy) — it is the one place this spec's "free ground truth" claim is not 100% exact,
called out explicitly rather than glossed over.

### `PanelBox` (stage 4a — per photo)

```python
@dataclass
class PanelBox:
    photo_file: str
    panel_index: int
    bbox_in_photo: tuple[int, int, int, int]   # after page-level deskew/rectification
    homography: list[float] | None             # 3x3, per-panel perspective correction, if applied
```

### `PanelAlignmentResult` (stage 4b — replaces the original page-level `AlignmentResult`)

```python
@dataclass
class PanelAlignmentResult:
    photo_file: str
    panel_index: int
    episode_file: str | None       # None if unmatched
    matched_layer_index: int | None      # the balloon layer whose OCR text matched this panel
    match_score: float                    # 0-1 fuzzy-match confidence (same scale as ai-baloons)
    matched_on: str                        # "en" | "ru" | ... (which OCR'd language matched)
    ground_truth_cluster: list[int] | None   # layer_indexes in the local kind_heuristic y-window
                                               # neighborhood around matched_layer_index -- this,
                                               # not a rectangular canvas crop, is what stage 6
                                               # evaluates a panel's cut regions against
    status: Literal["matched", "skipped_no_match", "skipped_ambiguous", "skipped_low_confidence"]
    reason: str
```

A photo with N detected panels produces N `PanelAlignmentResult`s (zero-to-many "matched"; the rest
skipped+logged individually) — not one result per photo. `homography` in `PanelBox` corrects
per-panel perspective distortion for cropping/inference purposes only; it is **not** a mapping into
canvas coordinates (there is no such mapping — see Revision 1.1).

### `CutRegion` (stage 6, per matched panel)

```python
@dataclass
class CutRegion:
    photo_file: str
    panel_index: int
    predicted_kind: str
    confidence: float
    mask_png: str                 # cropped region under work/regions/
    matched_ground_truth_layer: int | None   # filled in only for eval, when panel alignment succeeded
    iou_vs_ground_truth: float | None        # eval metric, None when no ground truth available
```

### `LibraryEntry` (stage 7b)

```python
@dataclass
class LibraryEntry:
    identity_name: str            # e.g. "amba" — seeded from episode/character metadata where
                                   # available (e.g. Comics_Episodes.csv "ambas_plea"), refined by
                                   # visual clustering across poses/episodes
    kind: Literal["character", "environment"]
    crops: list[str]              # source region image paths
    representative_thumbnail: str
```

### Report (`work/report.jsonl`, one line per photo)

```json
{
  "photo_file": "20260731_153113.jpg",
  "alignment": {"episode_file": "8a89f7d689fb441ea280cd782276bd7a.comics", "confidence": 0.91, "status": "matched"},
  "regions_cut": 14,
  "regions_by_kind": {"background": 2, "character": 3, "balloon": 8, "art": 1},
  "mean_iou_vs_ground_truth": 0.78,
  "library_entries_updated": ["amba"],
  "status": "packaged"
}
```

### Schema Changes

Output `.comics` files follow the same additive convention as `sdd-comics-ai-baloons`: new/updated
layers get `Kind` set (reusing the existing field), no fields removed/renamed. `dataset/` has zero
schema changes.

## Behavior Specifications

### Happy Path

1. Stage 1 renders all 27 canvases + ground-truth maps once (cached).
2. Stage 2/3 train the segmentation model on synthetic pairs derived from those canvases.
3. For each of the 80 real photos: stage 4 aligns it to an episode + y-range; stage 5 runs the
   trained model on the aligned crop; stage 6 materializes cut regions and, where alignment
   succeeded, scores them against true ground truth.
4. Balloon regions are hidden off to the existing balloon pipeline; character/environment regions
   feed the library builder; everything is packaged into a new `.comics` file plus a report.

### Stage Details

#### [1] Render Canvas Reference

- Resting position = each layer's final `TranslateAnim`/`AlphaAnim` keyframe value (the one with an
  `end` field, or the sole keyframe if there's only one) — i.e., where the layer settles once its
  reveal animation finishes. This is a modeling **assumption** (the print edition presumably reflects
  the settled state, not a mid-animation frame) that must be visually spot-checked against a handful
  of real photos before Plan locks it in (see Open Design Questions).
- Compositing order = `data.json["layers"]` array order (confirmed bottom-to-top in existing editor
  behavior, reused from `comics-ai-baloons`'s reading of the same file).
- Reuse `comics-ai-baloons`'s tile-stitching code for extracting each layer's raster before
  compositing (no need to reimplement).

#### [2] Synthetic Degradation

- Camera-realism augmentations, in order: random perspective warp (simulate hand-held photo angle),
  vignette/lighting gradient, gaussian/motion blur, sensor noise, JPEG re-compression, mild
  rotation. Parameter ranges to be calibrated against the *real* 80 photos' actual characteristics
  (measure their blur/noise/perspective distribution first, don't guess ranges blind).
- Crop window size matches the real photos' effective page coverage once perspective-corrected
  (measure from a few manually-inspected real photos during Plan/Implementation).

#### [3] Train Segmentation Model

- Trained **from scratch** on this project's synthetic pairs — see Open Design Questions for the
  concrete architecture choice and the pretrained-backbone-weights question (does "from scratch"
  forbid ImageNet-pretrained initialization of a standard architecture, or only forbid depending on
  a third-party *generative*/foundation model as the core capability? — needs an explicit user
  decision, not an assumption, since it materially changes expected quality given only 27 source
  files).
- Output head: per-region mask + `Kind` classification (a standard instance-segmentation output
  shape — Mask R-CNN-style or a simpler proposal-free approach — architecture TBD in Plan once the
  from-scratch/backbone question above is resolved).

#### [4] Detect Panels + Match Panel to Known Scene *(revised, Checkpoint A — see Revision 1.1)*

- **Step A — page rectification**: detect the printed page's physical boundary in the photo
  (contour/rectangle detection) and perspective-correct to a top-down rectangle, correcting for
  camera angle/lighting gradient — a classical CV step (OpenCV), not a trained model. Unchanged from
  the original design; this part of "page rectification" is still valid, only the *matching* step
  after it changed.
- **Step B — panel detection**: on the rectified page, detect individual panel boundaries (panel
  borders/gutters — classical CV: line/contour detection for the grid structure, since printed
  panels are bordered rectangles, not the free-form content the original per-page homography design
  assumed). Produces one `PanelBox` per detected panel, each independently perspective-correctable
  (book curvature can tilt panels differently even within one photo).
- **Step C — panel-to-scene matching (content-based, not geometric)**: per panel, OCR any balloon
  text it contains and fuzzy-match (rapidfuzz, same approach `comics-ai-baloons` uses for its CSV
  matching) against that pipeline's own per-balloon OCR corpus (`work/ocr.jsonl`, read via the
  bridge — this is matching against **known dataset balloon text**, not the translation CSV, since
  the goal here is "which episode/layer is this," not "what language variant to render"). A
  confident text match identifies the source episode + balloon `layer_index`; that layer's local
  `kind_heuristic.py` y-window neighborhood becomes `ground_truth_cluster`. Panels with no balloon
  text (silent/art-only panels) are a known, expected gap — see Edge Cases.
- **Skip + log**, never guess: below a confidence floor, or on an ambiguous near-tie between
  candidates, `status` reflects the failure reason per panel — inherits the exact same governing
  principle `comics-ai-baloons` established for CSV matching, now applied at panel instead of page
  granularity.

#### [5-6] Inference + Cut Regions

- Run the trained model on each detected (perspective-corrected) panel crop; for panels with a
  confident stage-4 match, compute per-region IoU against the matched `ground_truth_cluster`'s
  `GroundTruthRegion` masks — this is the pipeline's primary quantitative eval metric (see Testing
  Strategy), not just a training-loss number, since it directly measures "did we recover the true
  layers from a real, noisy photo."

#### [7a] Balloon Handoff

- Detected regions with `predicted_kind == "balloon"` are written in the exact `BalloonLayer`-input
  shape `comics-ai-baloons`'s `discover.py` already expects, then that pipeline's existing
  extract→OCR→match→classify→render stages run unmodified. This flow does not re-implement
  OCR/erase/hand-lettering logic.

#### [7b] Library Builder

- Seed identity names from known metadata where available (`Comics_Episodes.csv`'s episode-name
  tokens, e.g. `ambas_plea` → seed candidate name "amba" for character regions detected in that
  episode) — a weak label, not authoritative, since one episode can contain multiple characters.
- Cluster `character`-kind crops by visual similarity (embedding distance from a lightweight
  from-scratch-trained or classical feature descriptor — not a third-party pretrained embedding
  model, per the same "from scratch" constraint as the segmenter, unless the Open Design Question
  above resolves that constraint more narrowly) within an episode first, then merge clusters across
  episodes only when similarity is high confidence, to avoid false-merging different characters.
- Same approach for `environment`-kind crops → `work/library/environments/`.
- Every `LibraryEntry` is inspectable (a folder of crops + a thumbnail) — no automatic renaming/
  deletion of ambiguous clusters; ambiguous crops land in an `unclustered/` bucket for review rather
  than being force-assigned.

#### [8] Package

- Reuse `comics-ai-baloons`'s tiling/re-tiling and zip-assembly code directly (same 512px tile
  convention, same `png32`-equivalent encoding) — do not reimplement.
- Optional `.svg`: for regions with clean, high-contrast edges (heuristically detected — e.g. flat-
  color balloon outlines), attempt auto-vectorization (e.g. via a contour-tracing + Bezier-fit
  approach) and embed alongside the `.png` in the same layer entry's asset folder as a
  non-blocking best-effort extra; regions where this fails or looks poor are simply not given an
  `.svg` (raster-only, exactly like today). This must never block or degrade the raster path.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| Panel has no balloon text at all (silent/art-only panel) | Common — many panels are pure art | No OCR corpus to match against; `status = skipped_no_match` for that panel specifically. This is an *expected*, not exceptional, gap — silent panels simply never get a `ground_truth_cluster` and are excluded from real-photo eval, not force-matched by visual similarity alone (visual-only matching against a tall, repetitive canvas was exactly the approach Checkpoint A showed to be unreliable at page granularity; not trusted at panel granularity either without text corroboration) |
| Panel's OCR text matches multiple episodes/layers similarly well | Short/generic balloon phrases, or the same phrase reused | `status = skipped_ambiguous`, both candidates logged — same rule `comics-ai-baloons` uses |
| Photo/page doesn't confidently match any episode at all | Damaged/glare/off-book photo, or content from outside the 27 digitized episodes (print book runs to 198+ pages, digitized episodes cover far less) | Every panel on that page ends up `skipped_no_match`; logged per-panel, not assumed at the page level |
| Panel detection itself fails (no clear grid/gutters found) | Damaged page, extreme close-up photo, non-standard layout | Log a page-level panel-detection failure distinct from a per-panel match failure; skip that photo's panels entirely rather than guessing panel boundaries |
| Layer regions heavily overlap (character occluding background) | Common in art-dense pages | Instance-segmentation output must support overlapping masks, not a single flat label map; low-confidence overlaps logged, not forced |
| Legacy layer has no explicit `Kind` | Nearly all non-balloon layers today | Fall back to `kind_source="inferred_heuristic"` (see `CanvasReference`); flagged distinctly from explicit kinds in every downstream artifact |
| Same character's crops fail to cluster together across episodes | Pose/lighting variance too high for the similarity metric | Land in per-episode clusters rather than one merged identity; `unclustered/` bucket, not silently merged or dropped |
| Balloon region detected here doesn't match how `comics-ai-baloons`'s own structural rule finds it | Model prediction disagrees with the ≥2-image-slot structural rule | Structural rule (already validated against all 27 files) wins for anything going into the balloon handoff — the segmentation model's prediction is used for *localization* on new/unstructured input (e.g. future photo-only-no-JSON scenarios), not to override known-good structural detection on in-dataset content |
| `.svg` auto-vectorization produces a poor/garbled trace | Painterly/photographic region, not line art | Drop the `.svg`, keep the `.png` — never block packaging on vectorization quality |
| Training data volume insufficient for the segmentation model to generalize past synthetic pairs | Only 80 real photos exist | Report per-photo real-vs-synthetic eval gap explicitly (see Testing Strategy); this is an expected, honestly-sized risk from Requirements, not a bug to hide |

### Error Handling

| Error | Cause | Response |
|-------|-------|----------|
| `.comics` zip fails to open / corrupt | Bad file in dataset | Log file-level error, skip file, continue |
| Photo file unreadable/corrupt | Bad capture | Log, skip photo, continue |
| Feature-matching finds zero keypoint inliers | Extremely poor photo quality or wrong content | `status = skipped_no_match`, not a crash |
| Segmentation model checkpoint missing | Stage 3 not yet run | Fail fast with a clear "train the model first" message |
| `comics-ai-baloons` invocation fails for a routed balloon region | Version drift / missing dependency in that pipeline | Log the failure for that region, continue processing other regions/kinds — one balloon failure must not abort the whole photo's packaging |

## Dependencies

### Requires

- Python environment (can share `apps/comics-ai/comics-ai-baloons/.venv` conventions or a sibling
  venv under `apps/comics-ai/comics-multimodal/`)
- `Pillow`, `opencv-python` (rectification, feature matching, augmentation)
- A from-scratch-trainable deep learning framework (PyTorch proposed, matching the ecosystem's
  standard tooling for instance segmentation — final call in Plan)
- Reuses `apps/comics-ai/comics-ai-baloons/scripts/` (tiling, comics_io, discover/extract/ocr/match/
  classify/render) as an in-repo dependency, invoked not copied

### Blocks

- Future `apps/comics-editor` human-corrector integration (out of scope this iteration) depends on
  this pipeline's `CutRegion`/`LibraryEntry` shapes being stable.
- Deferred text→`.comics` and generation scenarios depend on the character/environment library this
  flow starts building.

## Integration Points

### External Systems

None this iteration — no network calls, no third-party model APIs for the core cutting capability
(consistent with the "trained from scratch" constraint).

### Internal Systems

- Reads `dataset/*.comics`, `dataset/.../comics_book_lowcamera/*.jpg` (read-only).
- **Invokes** `apps/comics-ai/comics-ai-baloons/scripts/` for balloon-region deep processing — a
  same-repo dependency, not a copy/fork of that code.
- Schema/tiling conventions borrowed from `apps/comics-editor/native/Comics.Editor` (read-only
  reference, no code dependency).

### Editor Integration Contract (design only, not built this iteration)

Modeled directly on the shipped `BalloonAiClient`/`BalloonEditorCard` pattern
(`vdd-comics-editor-uiux-lettering`), generalized past balloons:

```dart
abstract class MultimodalCuttingClient {
  Stream<CuttingEvent> segment(Uint8List sourceImageBytes);
}
sealed class CuttingEvent {}
class RoutingDecided extends CuttingEvent { final bool onDevice; final String reason; }
class Progress extends CuttingEvent { final double fraction; }
class Success extends CuttingEvent { final List<DetectedRegion> regions; }
class Failure extends CuttingEvent { final String reason; }

class DetectedRegion {
  final String kind;            // reuses Layer.Kind values
  final Uint8List maskPng;
  final Rect bbox;
  final double confidence;
}
```

A future `CuttingReviewCard` (per-kind, analogous to `BalloonEditorCard`) would let a human corrector
accept/reject/reclassify/adjust each `DetectedRegion` before it's committed as a real `Layer`, with a
stale-indicator if the source image changes after review — same UX principle as the balloon card
(never silently auto-apply). **Not implemented this iteration**; recorded here so a later flow can
build directly against this shape instead of re-deriving it.

## Testing Strategy

### Unit Tests

- [ ] Canvas rendering: resting-position compositing of a fixture file matches a manually-verified
      expected output
- [ ] Ground-truth kind inference heuristic: correctly classifies a labeled fixture set of
      layers spanning background/character/balloon/art
- [ ] Alignment: on a *synthetically* degraded (not real) photo with known origin, recovers the
      correct episode + y-range + homography within a tight tolerance
- [ ] Library clustering: a small hand-verified fixture (e.g. known Amba crops from episode 21)
      clusters together and doesn't merge with a different character's crops

### Integration Tests

- [ ] Full pipeline run on a small subset (2-3 real photos) produces valid output `.comics` files
      openable in `apps/comics-editor` without error
- [ ] Per-photo report accounts for every detected region (none silently dropped) and every photo
      (matched+packaged, or skipped+reason)
- [ ] Balloon-region handoff round-trips correctly into `comics-ai-baloons`'s existing pipeline
      (regions it structurally rediscovers match this pipeline's routed regions)

### Manual Verification

- [ ] Visual spot-check: cut regions overlaid on a handful of real photos across different episodes
- [ ] Resting-position assumption (stage 1) spot-checked against real photos before Plan finalizes it
- [ ] Character library folder for "amba" reviewed for correctness (no other character's crops
      present, reasonable pose coverage)
- [ ] Real-photo eval IoU reported separately from synthetic-eval IoU, so the real generalization gap
      is visible, not hidden behind a single blended metric

## Migration / Rollout

Not applicable — new, standalone pipeline; no existing system is migrated. `apps/comics-editor`
integration is explicitly a separate, later flow (see Editor Integration Contract).

## Open Design Questions

- [x] **"Trained from scratch" scope** → **Resolved by user decision (2026-07-31): pretrained
      weights/backbones are permitted.** "Trained from scratch" (Requirements) means the core
      cutting *capability* must be our own trained model (not a thin API wrapper around a
      third-party generative/foundation model), not that every weight must be randomly initialized.
      ImageNet-pretrained backbones and pretrained embedding models are in scope; Plan must
      **consider multiple concrete options** (architectures/backbones for the segmenter, embedding
      approaches for library clustering) and pick one with reasoning, rather than defaulting to the
      first option.
- [ ] **Segmentation model architecture**: concrete choice (Mask R-CNN-style two-stage vs. a
      simpler single-stage proposal-free approach), including backbone/pretraining option — deferred
      to Plan, which must present options per the resolution above.
- [x] **Resting-position assumption** → **Superseded, not confirmed-as-originally-asked.** The
      per-layer "last keyframe = settled state" *semantics* were verified directly against the C#
      `Anim`/`TranslateAnim`/`ScaleAnim`/`RotateAnim`/`AlphaAnim` source during Task 2.1 and are
      correct/load-bearing (used by the canvas compositor for synthetic training data). But the
      original question — "does the printed page reflect this settled state" — turned out to be the
      wrong question: the printed book is not a crop of the canvas at all (Revision 1.1). The
      resting-position semantics matter for *synthesizing* training data; they say nothing about how
      a print panel relates to canvas content, which is now solved by content-based matching instead.
- [x] **Synthetic degradation parameter ranges** → still needed, but the *shape* of what gets
      degraded changed (per-local-cluster crops mimicking panels, not arbitrary canvas windows —
      see the revised stage 2). Parameter values themselves are still deferred to Task 3.1
      (Checkpoint B), unaffected by this revision.
- [ ] **Panel detection method** *(new, from Revision 1.1)*: concrete approach for detecting
      individual panel boundaries on a rectified page photo (contour/line detection on
      borders/gutters vs. a small learned detector) — deferred to Plan/Implementation Phase 5.
- [x] **Character identity clustering approach** → **Resolved by user decision (2026-07-31):
      pretrained embedding models are permitted.** Plan must consider options (classical descriptor
      vs. a pretrained/fine-tuned embedding network) and pick one with reasoning.
- [ ] **`.svg` auto-vectorization method**: specific tracing approach (e.g. potrace-style
      contour+Bezier fit) — low priority, deferred to Plan/Implementation, may be dropped entirely if
      early trials look poor.
- [ ] **Quality-correction (stage 9) priority/timing**: build alongside the segmenter using the same
      synthetic pairs, or defer entirely to a follow-on pass — per Requirements this is lower priority
      than cutting itself; Plan should size it as an optional task, not a blocking one.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-07-31
- [x] Notes: Approved. Open questions 1 ("trained from scratch" scope) and 3 (character clustering
      approach) resolved: pretrained weights/backbones/embeddings are permitted — Plan must present
      and reason through concrete options rather than assume a single default. Remaining open
      questions (resting-position assumption, degradation parameter ranges, architecture choice,
      `.svg` method, quality-correction priority) carry into Plan.

### Revision 1.1 approval (2026-07-31, during Implementation)

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-07-31
- [x] Notes: Checkpoint A (Task 2.3) visual inspection of real `comics_book_lowcamera` photos
      falsified the whole-page-homography alignment design (see "Revision 1.1" note near the top of
      this document) — the print book is a conventionally paginated comic, not a canvas crop. User
      confirmed the fix: pivot Phase 5 (Plan) and this document's stage [4]/data
      models/edge-cases to **per-panel content-based matching** (OCR + fuzzy-match against
      `comics-ai-baloons`'s own balloon OCR corpus), replacing page-level homography. Stage [2]
      (synthetic degradation) revised in tandem to crop panel-like local content clusters instead of
      arbitrary canvas windows, so synthetic training data actually resembles what real photos
      contain. `03-plan.md` Phase 5 (and Phase 3) must be updated to match before implementation
      continues there.
