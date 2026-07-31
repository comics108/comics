# Implementation Plan: comics-ai-multimodal

> Version: 1.1
> Status: APPROVED (Phase 5, and Task 3.2, revised during Implementation — see `02-specifications.md` Revision 1.1)
> Last Updated: 2026-07-31
> Specifications: [02-specifications.md](02-specifications.md)

## Summary

Build the 8-stage pipeline from Specifications under `apps/comics-ai/comics-multimodal/`, following
the data dependency chain (canvas reference → synthetic training data → segmentation model → photo
alignment → inference/cutting → balloon handoff / library build → packaging → report). Unlike
`comics-ai-baloons` (which wired together off-the-shelf tools — Tesseract, OpenCV inpainting), the
central task here is genuinely training a model, which is a materially higher-risk, higher-effort,
more experimental undertaking. This plan front-loads the **cheapest possible end-to-end baseline**
(classical CV + a simple semantic-segmentation model) before investing in the heavier
instance-segmentation model, so the rest of the pipeline (alignment, handoff, library, packaging,
reporting) is integration-tested early against *something*, rather than blocking on the hardest
component first.

Per the resolved Specifications decisions, pretrained backbones/embeddings are permitted; **Tasks
4.1 and 8.1 below present the concrete options considered and the recommendation**, rather than
deferring the choice further.

Four checkpoints stop deliberately to look at real data/results before committing further spend:

- **Checkpoint A** (Task 2.3): visually verify the resting-position assumption against real photos
  before building the full canvas-reference renderer around it.
- **Checkpoint B** (Task 3.1): measure real photos' actual blur/noise/perspective distribution
  before calibrating synthetic degradation — don't guess parameter ranges.
- **Checkpoint C** (Task 5.4): run alignment on all 80 real photos and review the match/skip rate
  before investing further in the segmentation model's real-photo evaluation.
- **Checkpoint D** (Task 6.3): compare the cheap baseline segmenter vs. the pretrained
  instance-segmentation model on real, aligned photos before deciding whether the heavier model is
  worth keeping as the shipped default.

`dataset/` is read-only for every task in this plan. All new code/data live under
`apps/comics-ai/comics-multimodal/`. `apps/comics-ai/comics-ai-baloons/` is read and invoked, never
modified.

## Task Breakdown

### Phase 1: Environment & Foundation

#### Task 1.1: Python project scaffolding
- **Description**: Set up `apps/comics-ai/comics-multimodal/` as a Python project (own venv or
  shared conventions with `comics-ai-baloons`) — dependency pinning for `Pillow`, `opencv-python`,
  `numpy`, `torch`+`torchvision` (segmentation model), `scikit-learn` (clustering), plus a
  `requirements-dev.txt` for test tooling. `README.md` documents setup and how `comics-ai-baloons`
  is imported/invoked as a dependency (path-based import or subprocess — decide here).
- **Files**:
  - `apps/comics-ai/comics-multimodal/pyproject.toml` or `requirements.txt` - Create
  - `apps/comics-ai/comics-multimodal/README.md` - Create
- **Dependencies**: None
- **Verification**: clean-venv install succeeds; `python -c "import torch, torchvision, cv2, sklearn"`
  succeeds
- **Complexity**: Low

#### Task 1.2: Reuse bridge to `comics-ai-baloons`
- **Description**: A thin adapter module that imports (or subprocess-invokes)
  `comics-ai-baloons`'s `comics_io.py`/`tiling.py` (zip read/write, stitch/re-tile) rather than
  duplicating them, and later (Phase 7) its `discover.py`/OCR/match/classify/render chain.
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/baloons_bridge.py` - Create
- **Dependencies**: Task 1.1
- **Verification**: unit test — stitch a known multi-tile image from a real dataset file via the
  bridge, confirm pixel-identical result to calling `comics-ai-baloons` directly
- **Complexity**: Low

### Phase 2: Canvas Reference & Ground Truth

#### Task 2.1: Resting-position resolver
- **Description**: Parse each layer's `animations[]`; resolve the "resting" position/alpha as the
  keyframe with an `end` field (or the sole keyframe if only one exists) per Specifications'
  assumption.
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/resting_position.py` - Create
- **Dependencies**: Task 1.2
- **Verification**: unit test against a handful of real `data.json` layer fixtures (including the
  multi-keyframe crossfade example found during Specifications, `1_13_1_1/1_2/1_3`), asserting the
  resolved position/alpha matches manual inspection
- **Complexity**: Low

#### Task 2.2: Kind inference heuristic for legacy (untagged) layers
- **Description**: Implement the fallback rule from Specifications (`GroundTruthRegion.kind_source
  = "inferred_heuristic"`): single-slot + large area + bottom-of-stack → `background`; single-slot +
  mid-stack + humanoid aspect → `character`; ≥2 slots → `balloon` (reuse `comics-ai-baloons`'s
  already-validated structural rule via the bridge); else → `art`.
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/kind_heuristic.py` - Create
- **Dependencies**: Task 1.2
- **Verification**: run across all 27 files; manually spot-check ~30 layers spanning each inferred
  kind (Read tool, visual) — document accuracy honestly, this heuristic is not expected to be
  perfect and downstream stages must treat it as approximate (per Specifications' edge case)
- **Complexity**: Medium (the "humanoid aspect" character heuristic is the fuzziest part; expect
  iteration)

#### Task 2.3: **Checkpoint A** — verify resting-position assumption against real photos
- **Description**: Before building the full canvas renderer, manually composite 2-3 episodes at
  their resolved resting positions (Task 2.1) and visually compare against the corresponding real
  `comics_book_lowcamera` photos (found by episode metadata, not yet automatic alignment) to confirm
  the print edition really reflects the settled animation state.
- **Files**: None (analysis; decision recorded in this plan's Open Implementation Questions or as a
  correction to Task 2.1 if the assumption is wrong)
- **Dependencies**: Task 2.1
- **Verification**: documented side-by-side comparison for at least 2 episodes (one being episode 21
  / `ambas_plea`, since it's already a known reference point) with an explicit pass/fail call
- **Complexity**: Low

#### Task 2.4: Full canvas compositor + ground-truth emitter
- **Description**: `render_canvas.py` — for each of the 27 files, composite the full canvas using
  Task 2.1's resting positions in `data.json` layer order, and emit the `CanvasReference` +
  `GroundTruthRegion` list (using Task 2.2 for untagged layers, existing `Kind` where present).
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/render_canvas.py` - Create
  - `apps/comics-ai/comics-multimodal/scripts/models.py` - Create (shared dataclasses:
    `CanvasReference`, `GroundTruthRegion`, `AlignmentResult`, `CutRegion`, `LibraryEntry`)
- **Dependencies**: Task 2.2, Task 2.3 (assumption confirmed or corrected first)
- **Verification**: run over all 27 files; visually spot-check 3-4 full composites (Read tool) for
  gross correctness (layers not obviously missing/misplaced)
- **Complexity**: Medium

### Phase 3: Synthetic Training Data

#### Task 3.1: **Checkpoint B** — measure real photo characteristics
- **Description**: Before writing the augmentation pipeline, measure the 80 real photos' actual
  blur (e.g. variance-of-Laplacian), noise level, and estimated perspective distortion range, so
  Task 3.2's parameters are calibrated from real data, not guessed.
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/analyze_photos.py` - Create (one-off analysis script,
    kept for reproducibility)
- **Dependencies**: None (independent of Phase 2)
- **Verification**: documented distribution (min/median/max) for each measured characteristic,
  referenced directly by Task 3.2's parameter choices
- **Complexity**: Low

#### Task 3.2: Synthetic degradation pipeline
- **Description** *(revised per Specifications Revision 1.1 — Checkpoint A found the print book is
  a conventionally paginated comic, not a canvas crop; see `02-specifications.md`)*: `augment.py` —
  perspective warp, vignette/lighting, blur, sensor noise, JPEG re-compression, mild rotation, a
  print-style resize, parameterized from Task 3.1's measurements; crops **local content clusters**
  (each balloon layer's `kind_heuristic.py` y-window neighborhood — background/character/balloon
  layers grouped tightly together, panel-shaped) from Task 2.4's canvas composites, **not** arbitrary
  rectangular windows of the tall canvas.
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/augment.py` - Create
- **Dependencies**: Task 2.4, Task 3.1, Task 2.2 (kind-heuristic y-window clustering)
- **Verification**: visual spot-check — a batch of synthetic degraded crops should be plausibly
  mistakable for real camera *panel* photos (side-by-side comparison against real
  `comics_book_lowcamera` panels, not whole pages, human judgment call, documented)
- **Complexity**: Medium

#### Task 3.3: Training pair dataset loader
- **Description**: A `torch.utils.data.Dataset` wrapping Task 3.2's output, yielding
  (degraded-image, ground-truth-masks-and-kinds) pairs in the shape the chosen segmentation
  architecture (Task 4.1) expects.
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/dataset.py` - Create
- **Dependencies**: Task 3.2
- **Verification**: unit test — loader produces correctly-shaped tensors for a small fixture batch;
  no crashes iterating the full training set once
- **Complexity**: Low

### Phase 4: Segmentation Model

#### Task 4.1: Architecture decision (options considered, per resolved Specifications question)

**Option A — Mask R-CNN, pretrained backbone** (`torchvision.models.detection.
maskrcnn_resnet50_fpn_v2`, COCO-pretrained, fine-tuned on our synthetic data): native support for
overlapping instance masks (needed for the occlusion edge case — two characters or a character over
a background must not collapse into one blob), mature/well-documented training loop in torchvision,
and a pretrained backbone meaningfully de-risks learning from only 27 source files' worth of
synthetic variation. Heavier and slower than alternatives; COCO's real-world-photo pretraining is a
domain gap from comic art, but low-level features (edges/textures/shapes) still transfer.

**Option B — YOLO-seg (Ultralytics), pretrained, fine-tuned**: faster to train/iterate, strong
practical low-data performance via pretrained weights, simple CLI/API. Instance-segmentation output
is less flexible to customize (mask head, per-class handling) than Mask R-CNN, and Ultralytics'
license terms need a one-time check for this internal-tooling use case.

**Option C — Lightweight semantic-segmentation baseline** (a small U-Net, trained fully from
scratch or with a pretrained encoder e.g. `torchvision.models.resnet18` as the U-Net encoder) +
classical connected-components/watershed to derive instances: cheapest to implement and fastest to
get a first signal, plugs in the domain knowledge already validated in `comics-ai-baloons`
(structural balloon rule) for the balloon class specifically. Does **not** natively separate
overlapping same-kind instances (two overlapping characters become one blob) — a real, honestly-
acknowledged limitation against the occlusion edge case.

**Decision**: Build **Option C first** (Task 4.2) as the pipeline's initial, cheap baseline — it
unblocks Phase 5-9 integration testing immediately and gives an early real-photo signal at
Checkpoint D. Then build **Option A** (Task 4.3) as the higher-quality instance-segmentation upgrade,
compared against the baseline at Checkpoint D before deciding which ships as the default. Option B is
not pursued initially (Option A already covers the "pretrained + instance-level" requirement without
introducing a new dependency/license question) but is noted here in case Option A's training proves
impractical.

- **Files**: None (decision record; implementation in Tasks 4.2/4.3)
- **Dependencies**: None
- **Verification**: this section itself, reviewed by the user as part of Plan approval
- **Complexity**: N/A (decision task)

#### Task 4.2: Baseline semantic-segmentation model (Option C)
- **Description**: Small U-Net (ResNet-18 pretrained encoder optional per Task 4.1) predicting a
  per-pixel `Kind` label; instances derived via connected-components on same-kind regions; balloon
  regions additionally cross-checked against `comics-ai-baloons`'s structural rule where applicable
  (in-dataset content only).
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/models/unet_baseline.py` - Create
  - `apps/comics-ai/comics-multimodal/scripts/train_segmenter.py` - Create (supports both Task 4.2
    and 4.3 architectures via a config flag)
- **Dependencies**: Task 3.3, Task 4.1
- **Verification**: training loss decreases and converges on the synthetic training set; synthetic
  held-out per-region IoU reported
- **Complexity**: Medium

#### Task 4.3: Instance-segmentation model (Option A)
- **Description**: Fine-tune `maskrcnn_resnet50_fpn_v2` (COCO-pretrained) on the same synthetic
  training set, replacing the classification head for our `Kind` taxonomy.
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/models/maskrcnn.py` - Create
- **Dependencies**: Task 3.3, Task 4.1
- **Verification**: training converges; synthetic held-out per-region IoU + mask-AP reported,
  compared directly against Task 4.2's numbers on the same held-out set
- **Complexity**: High

### Phase 5: Photo Alignment (revised — Checkpoint A pivoted this from page-homography to per-panel content matching; see `02-specifications.md` Revision 1.1)

#### Task 5.1: Page rectification + panel detection
- **Description**: Detect the printed page's physical boundary in a raw photo (contour/rectangle
  detection, OpenCV) and perspective-correct to a top-down rectangle (unchanged from the original
  design). **New**: on the rectified page, detect individual panel boundaries (border/gutter
  contour or line detection) and perspective-correct each panel independently, producing a
  `PanelBox` list per photo.
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/rectify.py` - Create
  - `apps/comics-ai/comics-multimodal/scripts/detect_panels.py` - Create
- **Dependencies**: Task 1.1
- **Verification**: visual spot-check across a sample of real photos with varying angles/lighting/
  panel-grid layouts; document failure cases (glare, torn edges, non-standard grids) for the
  skip+log path
- **Complexity**: Medium-High (panel-grid detection on real photographed pages, given the variety of
  layouts already observed — single/double-page spreads, irregular panel counts — is new work, not
  covered by the original Specifications draft)

#### Task 5.2: Panel-to-scene content matching
- **Description** *(replaces the original ORB/SIFT+homography-vs-canvas design)*: `align_photo.py` —
  per detected panel, OCR any balloon text (reuse `comics-ai-baloons`'s OCR wrapper via the bridge)
  and fuzzy-match (rapidfuzz) against that pipeline's own per-balloon OCR corpus (`work/ocr.jsonl`)
  to identify the source episode + matched `layer_index`; derive `ground_truth_cluster` from
  `kind_heuristic.py`'s y-window neighborhood around that layer. Skip+log below threshold or on
  near-ties, exactly as `comics-ai-baloons`'s CSV matcher does — no index/order shortcuts, and no
  visual-only matching against the canvas (Checkpoint A showed the canvas isn't what a panel visually
  resembles anyway).
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/align_photo.py` - Create
- **Dependencies**: Task 5.1, Task 1.2 (bridge — needs `comics-ai-baloons`'s OCR corpus), Task 2.2
  (kind-heuristic clustering)
- **Verification**: unit test on synthetically-degraded (not real) panel-like crops with known
  origin — must recover correct episode + layer_index within tolerance; note `comics-ai-baloons`'s
  own `work/ocr.jsonl` must actually exist (may require running that pipeline's early stages first —
  flag as a cross-flow dependency to verify at the start of this task)
- **Complexity**: High (OCR quality on camera photos of print, through page/panel rectification, is
  a real compounding-error risk — expect iteration; silent/art-only panels are an expected, not
  exceptional, unmatched case — see Specifications Edge Cases)

#### Task 5.3: Match confidence threshold calibration
- **Description**: Run Task 5.2 against all detected panels across all 80 real photos; inspect the
  confidence-score distribution for genuine matches vs. genuine non-matches to set the skip
  threshold empirically, mirroring how `comics-ai-baloons` calibrated its own CSV match threshold.
- **Files**: None (calibration recorded as a constant in `align_photo.py`)
- **Dependencies**: Task 5.2
- **Verification**: documented threshold + 2-3 concrete examples justifying it
- **Complexity**: Low

#### Task 5.4: **Checkpoint C** — full real-photo panel-match review
- **Description**: Run the calibrated panel detector + matcher over all 80 photos; review the
  match/skip rate (including how many panels are silent/art-only and therefore unmatchable by
  design) and a sample of matched panels for correctness before investing further in real-photo
  segmentation evaluation.
- **Files**: None (review; findings documented)
- **Dependencies**: Task 5.3
- **Verification**: documented match rate + spot-checked accuracy; if match rate is very low,
  decide here whether Task 5.1/5.2's approach needs rework before proceeding to Phase 6
- **Complexity**: Low

### Phase 6: Inference & Cut Regions

#### Task 6.1: Inference stage
- **Description**: `infer_segmenter.py` — run a trained model (Task 4.2 or 4.3, selectable) on each
  detected/rectified **panel** crop (not a whole aligned page), producing raw predicted masks +
  `Kind` + confidence per panel.
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/infer_segmenter.py` - Create
- **Dependencies**: Task 4.2 (minimum), Task 5.4
- **Verification**: runs without error on all Checkpoint-C-matched panels; output shapes match
  `CutRegion` dataclass
- **Complexity**: Low

#### Task 6.2: Ground-truth evaluation
- **Description** *(revised)*: For panels with a confident stage-5 match, compute per-region IoU
  between predicted masks and the true `GroundTruthRegion` masks of the matched
  `ground_truth_cluster` (a local neighborhood of layers, per `PanelAlignmentResult` — **not** a
  homography-mapped rectangle, since no such geometric mapping exists per Checkpoint A) — the
  pipeline's primary real-world quality metric.
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/evaluate.py` - Create
- **Dependencies**: Task 6.1
- **Verification**: produces a per-photo, per-region IoU report; sanity-checked against 2-3 manually
  inspected examples
- **Complexity**: Medium

#### Task 6.3: **Checkpoint D** — baseline vs. instance-segmentation model comparison
- **Description**: Run Task 6.2's evaluation with both the Task 4.2 baseline and (once trained) the
  Task 4.3 Mask R-CNN model on the same real, aligned photos; compare real-world IoU, not just
  synthetic-eval numbers, and decide which model ships as the pipeline default (or whether both are
  kept, e.g. baseline as a fast fallback).
- **Files**: None (decision recorded here)
- **Dependencies**: Task 4.3, Task 6.2
- **Verification**: documented comparison table + decision
- **Complexity**: Low

### Phase 7: Balloon Handoff

#### Task 7.1: Balloon region adapter
- **Description**: `route_balloons.py` — convert `CutRegion`s with `predicted_kind == "balloon"`
  into `comics-ai-baloons`'s expected `BalloonLayer`/`ImageSlot` input shape and invoke its existing
  discover→extract→OCR→match→classify→render chain via Task 1.2's bridge.
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/route_balloons.py` - Create
- **Dependencies**: Task 1.2, Task 6.1
- **Verification**: for in-dataset photos, routed regions should correspond to the same balloons
  `comics-ai-baloons`'s own structural discovery finds directly on the source `.comics` file — cross-
  check overlap rate
- **Complexity**: Medium

### Phase 8: Character/Environment Library

#### Task 8.1: Clustering approach decision (options considered, per resolved Specifications question)

**Option A — classical descriptor** (color histogram + ORB/SIFT bag-of-visual-words, agglomerative
or HDBSCAN clustering): no training required, fast, fully interpretable, reasonable for a first
pass. Weak to pose/lighting variation — may fail to merge legitimately-same-character crops that
look very different across scenes (e.g. Amba in different emotional poses).

**Option B — pretrained CNN embedding** (e.g. `torchvision.models.resnet50` penultimate-layer
features, ImageNet-pretrained, optionally lightly fine-tuned via a triplet/contrastive pass using
same-episode crops as weak positive hints): substantially more robust to pose/lighting/scale
variation, and "lightly fine-tuned on our own data starting from pretrained weights" is consistent
with the resolved "trained from scratch" scope (our own trained embedding, not a frozen third-party
wrapper). More engineering to set up the weak-label triplet construction; risk of overfitting the
fine-tuning step to only 27 source files if pushed too hard.

**Decision**: Start with **Option A** to validate the clustering pipeline mechanics end-to-end
(folder structure, manifest, `unclustered/` bucket) against real crops — including a manual check
that Amba's episode-21 crops end up together. Then layer in **Option B**'s pretrained embedding as
the similarity signal (replacing or supplementing Option A's descriptor) since better pose/lighting
invariance directly matters for a useful character gallery; skip the fine-tuning half of Option B
initially (frozen pretrained features first) and only add fine-tuning if frozen features prove
insufficiently discriminative on real review.

- **Files**: None (decision record; implementation in Task 8.2)
- **Dependencies**: None
- **Verification**: reviewed by user as part of Plan approval
- **Complexity**: N/A (decision task)

#### Task 8.2: Library builder
- **Description**: `build_library.py` — seed identity names from `Comics_Episodes.csv` episode
  tokens for `character`/`environment`-kind `CutRegion`s, cluster via Task 8.1's chosen signal
  (starting frozen-pretrained-embedding + agglomerative clustering per the decision above), write
  `work/library/{characters,environments}/<name>/` + `unclustered/`.
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/build_library.py` - Create
- **Dependencies**: Task 6.1, Task 8.1
- **Verification**: run over all matched photos; manually verify the "amba" folder contains only
  Amba crops (episode 21) and no other character, with reasonable pose coverage — the concrete
  acceptance criterion from Requirements
- **Complexity**: Medium

### Phase 9: Packaging & Reporting

#### Task 9.1: `.comics` packaging
- **Description**: `package.py` — reuse `comics-ai-baloons`'s tiling/zip-assembly (via the Task 1.2
  bridge) to write a new `.comics` file per successfully-aligned photo, with `Kind`-tagged layers
  for the cut regions.
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/package.py` - Create
- **Dependencies**: Task 1.2, Task 7.1, Task 8.2
- **Verification**: at least one output `.comics` file opens correctly in `apps/comics-editor`
  (manual check, matching `comics-ai-baloons`'s equivalent verification step)
- **Complexity**: Medium

#### Task 9.2: Optional `.svg` export (low priority, may be dropped)
- **Description**: Best-effort contour-tracing + Bezier-fit vectorization for clean-edge regions
  (e.g. balloon outlines), embedded alongside the `.png` where it succeeds; silently raster-only
  otherwise. Time-boxed — if early trials look poor, drop per Specifications' explicit permission to
  do so.
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/vectorize.py` - Create (or omit entirely, see above)
- **Dependencies**: Task 9.1
- **Verification**: visual spot-check of a handful of auto-vectorized regions; go/no-go decision
  documented
- **Complexity**: Low (time-boxed; not allowed to block Task 9.1)

#### Task 9.3: Report generation
- **Description**: `report.py` — per-photo alignment/cut/kind/IoU/library summary (`report.jsonl` +
  human-readable `report.md`), mirroring `comics-ai-baloons`'s report structure.
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/report.py` - Create
- **Dependencies**: Task 6.2, Task 8.2, Task 9.1
- **Verification**: report accounts for all 80 photos (matched+packaged or skipped+reason) and every
  cut region within matched photos
- **Complexity**: Low

### Phase 10: Quality Correction (optional, lower priority)

#### Task 10.1: Quality-correction model (optional)
- **Description**: Per Requirements' explicit lower priority, a small image-to-image model
  (encoder-decoder CNN) trained on the same synthetic clean/degraded pairs (Task 3.2) to denoise/
  deskew/upscale real photos as an optional pre-pass before Task 5.1. **Not required for this
  iteration's acceptance criteria** — build only if time remains after Phases 1-9 are solid.
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/enhance.py` - Create
- **Dependencies**: Task 3.2
- **Verification**: if built, measure whether Task 5.2 alignment confidence or Task 6.2 IoU improves
  on real photos with vs. without this pre-pass
- **Complexity**: Medium (explicitly optional — do not let this block Phase 1-9 delivery)

### Phase 11: Integration

#### Task 11.1: Pipeline orchestrator
- **Description**: `pipeline.py` running all stages in order, resumable per-stage (skip stages whose
  cached output already exists), matching `comics-ai-baloons`'s orchestrator pattern.
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/pipeline.py` - Create
- **Dependencies**: Task 9.3 (all prior stages)
- **Verification**: full run over all 27 canvases + 80 photos completes; `dataset/` unchanged
  (`git status`/checksum spot-check)
- **Complexity**: Low

#### Task 11.2: End-to-end manual verification
- **Description**: Walk the full Specifications "Manual Verification" checklist (visual region
  spot-checks, resting-position confirmation already done at Checkpoint A, character library review,
  real-vs-synthetic IoU gap reported separately).
- **Files**: None
- **Dependencies**: Task 11.1
- **Verification**: checklist fully checked off
- **Complexity**: Low

## Dependency Graph

```
1.1 ─┬─→ 1.2 ─────────────────────────────────────────────────────────────────┐
     │                                                                        │
     ├─→ 2.1 ─→ 2.3(chkA) ─→ 2.4 ─┬─→ 3.2 ─→ 3.3 ─┬─→ 4.2 ─┬─→ 6.1 ─→ 6.2 ─→ 6.3(chkD)
     │   2.2 ──────────────┘      │                │        │        │
     │                    3.1(chkB)┘                └─→ 4.3 ─┘        │
     │                                                                 ├─→ 7.1 ──┐
     ├─→ 5.1 ─→ 5.2 ─→ 5.3 ─→ 5.4(chkC) ──────────────────────────────┘         │
     │                                                                 8.1 ─→ 8.2┤
     │                                                                          ▼
     │                                                          9.1 ─┬─→ 9.2 ─┐
     │                                                                └─→ 9.3 ─┼─→ 11.1 ─→ 11.2
     └─────────────────────────────────────────────────────(bridge used throughout)
(3.2 also feeds optional 10.1)
```

(Simplified — see per-task Dependencies for the exact list.)

## File Change Summary

| File | Action | Reason |
|------|--------|--------|
| `apps/comics-ai/comics-multimodal/pyproject.toml` / `requirements.txt` | Create | Pin pipeline dependencies |
| `apps/comics-ai/comics-multimodal/README.md` | Create | Setup + run instructions |
| `apps/comics-ai/comics-multimodal/scripts/baloons_bridge.py` | Create | Reuse comics-ai-baloons I/O + pipeline |
| `apps/comics-ai/comics-multimodal/scripts/resting_position.py` | Create | Resolve settled layer position/alpha |
| `apps/comics-ai/comics-multimodal/scripts/kind_heuristic.py` | Create | Legacy layer kind inference |
| `apps/comics-ai/comics-multimodal/scripts/render_canvas.py` | Create | Full canvas + ground-truth emitter |
| `apps/comics-ai/comics-multimodal/scripts/models.py` | Create | Shared dataclasses |
| `apps/comics-ai/comics-multimodal/scripts/analyze_photos.py` | Create | Real-photo characteristic measurement |
| `apps/comics-ai/comics-multimodal/scripts/augment.py` | Create | Synthetic degradation pipeline |
| `apps/comics-ai/comics-multimodal/scripts/dataset.py` | Create | Training pair dataset loader |
| `apps/comics-ai/comics-multimodal/scripts/models/unet_baseline.py` | Create | Baseline semantic-seg model |
| `apps/comics-ai/comics-multimodal/scripts/models/maskrcnn.py` | Create | Instance-seg model |
| `apps/comics-ai/comics-multimodal/scripts/train_segmenter.py` | Create | Training entrypoint (both models) |
| `apps/comics-ai/comics-multimodal/scripts/rectify.py` | Create | Page boundary detection + perspective correction |
| `apps/comics-ai/comics-multimodal/scripts/align_photo.py` | Create | Episode + offset matching |
| `apps/comics-ai/comics-multimodal/scripts/infer_segmenter.py` | Create | Model inference stage |
| `apps/comics-ai/comics-multimodal/scripts/evaluate.py` | Create | Ground-truth IoU evaluation |
| `apps/comics-ai/comics-multimodal/scripts/route_balloons.py` | Create | Balloon region → comics-ai-baloons handoff |
| `apps/comics-ai/comics-multimodal/scripts/build_library.py` | Create | Character/environment clustering |
| `apps/comics-ai/comics-multimodal/scripts/package.py` | Create | Output `.comics` packaging |
| `apps/comics-ai/comics-multimodal/scripts/vectorize.py` | Create (optional) | `.svg` best-effort export |
| `apps/comics-ai/comics-multimodal/scripts/report.py` | Create | Report generation |
| `apps/comics-ai/comics-multimodal/scripts/enhance.py` | Create (optional) | Quality correction pre-pass |
| `apps/comics-ai/comics-multimodal/scripts/pipeline.py` | Create | Orchestrator |
| `apps/comics-ai/comics-multimodal/work/**` | Create (gitignored) | All intermediate/output data + model checkpoints |

No existing files are modified or deleted. `dataset/**` is never touched.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Segmentation model doesn't generalize from synthetic-only training to real photos | High | High — the pipeline's core value proposition | Checkpoint D compares real-photo IoU explicitly, not just synthetic; baseline (Task 4.2) ships as a fallback if the heavier model underperforms |
| Panel-to-scene content matching (Task 5.2) fails often — either panel detection itself, or OCR quality on camera photos of print is too low to match confidently | Medium-High | High — blocks everything downstream for unmatched panels | Checkpoint C reviews real match rate early; skip+log (never guess) keeps failures visible rather than silently corrupting output; silent/art-only panels are an *expected* unmatchable case, not a failure to fix |
| Print book spans far more content (200+ pages) than the 27 digitized episodes cover | High (confirmed — page numbers up to 198+ seen) | Medium | Expected: many photos/panels will legitimately have no matching episode at all and should skip+log cleanly, not be forced to a wrong match |
| Resting-position assumption (stage 1) is simply wrong | Medium | High — the entire "free ground truth" premise depends on it | Checkpoint A verifies this *before* the expensive canvas-renderer/training-data investment, not after |
| Only 80 real photos means real-world evaluation itself is statistically thin | High (unavoidable, per Requirements' honest risk-sizing) | Medium | Report both synthetic and real-photo metrics separately; don't oversell precision on 80 samples |
| Character/environment clustering merges different characters or fragments one character across episodes | Medium | Medium | `unclustered/` bucket for ambiguous cases (never force-merge); manual Amba-folder check is a concrete acceptance gate (Task 8.2) |
| Mask R-CNN (Task 4.3) training cost/complexity blows the schedule | Medium | Medium | Task 4.2's cheaper baseline ships as a working fallback regardless of Task 4.3's outcome |
| `comics-ai-baloons` handoff (Task 7.1) drifts from that pipeline's actual current interface | Low-Medium | Medium | Task 1.2's bridge is a thin, testable adapter — a version-drift break surfaces as a bridge test failure, not a silent divergence |
| `.svg` vectorization (Task 9.2) quality is poor across the board | Medium | Low | Explicitly optional/time-boxed; drop entirely without blocking Task 9.1 |

## Rollback Strategy

Low risk by construction: no existing files are modified, `dataset/` is never written, and all
output (including trained model checkpoints) lives under the gitignored
`apps/comics-ai/comics-multimodal/work/`. Rollback is:

1. Delete `apps/comics-ai/comics-multimodal/work/` contents to discard any run's output/checkpoints.
2. Standard `git revert`/`git checkout` for any script changes under `scripts/` — no data-migration
   or external-system rollback needed.
3. `comics-ai-baloons` is invoked, never modified, so no rollback is ever needed there.

## Checkpoints

After each phase, verify:

- [ ] All unit tests for that phase's tasks pass
- [ ] Manual/visual verification steps for that phase are done (not skipped)
- [ ] Checkpoint A/B/C/D decisions (where applicable) are written down before the next phase starts
- [ ] `dataset/` is unchanged (`git status`/checksum spot-check)

## Open Implementation Questions

- [ ] Exact resting-position handling for multi-keyframe crossfade layers (the `1_13_1_1/1_2/1_3`
      pattern) — resolved at Checkpoint A (Task 2.3), not before
- [ ] Real photo blur/noise/perspective parameter ranges — resolved at Checkpoint B (Task 3.1)
- [ ] Alignment confidence threshold — resolved at Task 5.3, reviewed again at Checkpoint C
- [ ] Baseline vs. Mask R-CNN as shipped default (or both) — resolved at Checkpoint D (Task 6.3)
- [ ] Whether frozen pretrained embeddings (Task 8.1, Option B) are discriminative enough without
      fine-tuning — resolved during Task 8.2 based on manual cluster review

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-07-31
- [x] Notes: Approved as drafted. Checkpoints A/B/C/D stand — do not pre-resolve their decisions
      before the checkpoint task is reached.
