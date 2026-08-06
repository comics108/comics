# Specifications: comics-ai-positioning

> Version: 0.1 (drafted directly against real code in `apps/comics-ai/comics-multimodal/scripts/`)
> Status: APPROVED
> Last Updated: 2026-08-01

## Overview

Given a page's already-cut, kind-tagged regions (`sdd-comics-ai-multimodal`'s output), predict where
each region belongs in the target episode's continuous-strip canvas. This is a **learned regression
from region properties to canvas position**, not a geometric/registration problem —
`comics-multimodal/scripts/package.py`'s own design note already established that no pixel-level
photo→canvas mapping is obtainable, so positioning must be *predicted*, grounded in the real
(page-cluster → resting-position) pairs already latent in the 27 existing `.comics` files.

Working directory: **`apps/comics-ai/comics-positioning/`** (mirrors `comics-multimodal`'s/
`comics-ai-baloons`'s convention: `scripts/` for tooling, `work/` gitignored for output/checkpoints).
`dataset/` and `apps/comics-ai/comics-multimodal/work/` are both **read-only** inputs.

## Affected Systems

- **New**: `apps/comics-ai/comics-positioning/` (this flow's entire deliverable)
- **Read-only dependency**: `apps/comics-ai/comics-multimodal/scripts/` — `render_canvas.py`,
  `resting_position.py`, `align_photo.py`, `kind_heuristic.py`, `infer_segmenter.py` are imported/
  called, not duplicated (same cross-flow reuse pattern `comics-multimodal` itself used for
  `comics-ai-baloons`'s `match.py`/OCR corpus)
- **Read-only dependency**: `apps/comics-ai/comics-multimodal/work/` — reuses its already-computed
  `canvas/*.gt.json` (ground truth) and, where useful, `alignment.jsonl`/`regions.jsonl` rather than
  recomputing them
- **Not touched**: `apps/comics-editor` (no editor code changes — contract design only, same
  precedent `comics-multimodal` set for its own editor-integration section)

## Architecture

### Training Pair Construction (the core reused insight)

For each of the 27 `dataset/.../comics_interactive/*.comics` files, `comics-multimodal`'s
`render_canvas.py` already produces `work/canvas/<file>.gt.json`, a `CanvasReference` with one
`GroundTruthRegion` per layer: `layer_index`, `kind`, `bbox` (resting position in canvas
coordinates, via `resolve_resting_transform`). Separately, `align_photo.py` matches real photos to
episodes at **page granularity**, producing `PageAlignmentResult.ground_truth_cluster` — the set of
`layer_index`es belonging to that matched page's local scene.

Joining these two (already-computed, not new) artifacts gives, for every confidently-matched real
photo/page:

```
(page photo, cut/segmented regions on it)  →  (that page's ground_truth_cluster's GroundTruthRegions)
        INPUT                                              TARGET
```

i.e. real (paneled input → recomposed canvas position) supervised pairs, without new manual
labeling — this is the free training signal identified in Requirements, now traced to the exact two
scripts that produce each half of it.

### Position Representation

Absolute canvas X/Y (matching `TranslateAnim.X`/`Y`'s own representation, ints) is the direct
Must-Have target. Two derived/normalized views are used internally, not as separate outputs:

- **Relative-to-page-anchor Y**: canvas Y minus the page's own estimated anchor Y (see "Cross-Page
  Ordering" below) — this is what the model actually predicts, since absolute canvas Y depends on an
  episode's total prior content, which a per-page model shouldn't need to know.
- **X** is predicted directly (no anchor issue — pages/panels don't stack horizontally in this
  format, confirmed by all 27 files' geometry: canvas `width` is bounded/page-scale, `height` is the
  ~33000px scroll axis).

### Cross-Page Ordering (resolves Requirements' Open Question on episode/page granularity)

No separate ordering *model* is needed. Since the target space is one continuous Y-axis, correct
relative-Y placement *within* a page's cluster is the hard part this flow solves; a page's own
absolute Y-anchor within its episode is intended to bootstrap from the printed book's real page
numbers (`sdd-comics-ai-multimodal` Checkpoint A visually confirmed these exist and are legible —
`04-implementation-log.md`: "28/29, 194/198, 10 seen across the 4 samples") — a simple monotonic
mapping (page number → approximate canvas Y range), not a learned component.

**Correction, not yet reflected when this was first drafted**: this page-number signal is real but
**nothing extracts it automatically today** — Checkpoint A found it by visual/manual inspection, not
via a script. Two real, un-built pieces of work sit between "the numbers exist" and "usable anchor":
(1) OCR/digit-detection of the printed page number from a photo (new, small — cropped-region digit
OCR, not full-page text), and (2) a page-number → episode/Y-range mapping, which doesn't exist either
(episodes are matched by balloon-text content, not by page-number ranges — the print book runs to
198+ pages while only 27 episodes are digitized, so most page numbers won't even have a matching
episode). Plan must size this as real, disclosed work, not assume it away. **Fallback, already
designed for**: per-page-cluster relative positioning only, with absolute cross-page placement left
to a human/reviewer — this is the safe default if the page-number pipeline proves not worth building
this iteration.

### Data Flow

1. **Reuse (no new code)**: `comics-multimodal/work/canvas/*.gt.json` — ground-truth positions, all
   27 files.
2. **Reuse (no new code)**: `comics-multimodal/scripts/align_photo.py` — run (or reuse its existing
   `work/alignment.jsonl` output) to get page→episode matches + `ground_truth_cluster`.
3. **New — Training Pair Builder** (`build_pairs.py`): join stages 1+2 into
   `work/train_pairs/*.jsonl`: per matched page, its cut regions' `kind` (from
   `comics-multimodal`'s `kind_heuristic.py`/segmenter output where available, else re-derived) and
   local (within-page) bbox, paired with the matched `GroundTruthRegion`'s canvas bbox.
4. **New — Baseline Positioner** (`baseline_position.py`): rule-based vertical stacking by
   within-page reading order, with per-kind spacing/scale calibrated from real statistics mined from
   stage 1's ground truth (e.g. median gap between a `balloon` and its nearest `character`/
   `background` neighbor).
5. **New — Learned Positioner** (`train_positioner.py`/`infer_positioner.py`, optional, only
   attempted if Plan budgets it): a small regression model (architecture TBD in Plan, likely a
   lightweight per-region MLP/GBDT over [kind, size, local-order, neighbor-kind-context] features
   given the tiny data budget — not a from-scratch deep model, unlike the segmenter, since this is a
   low-dimensional regression, not pixel-level perception).
6. **Evaluate** (`evaluate_positioning.py`): both baseline and any learned model, against a held-out
   split of the 27 files (per-file held out, not per-region, to avoid a file's own layout leaking
   into its own eval — same discipline `comics-multimodal`'s Testing Strategy used).
7. **[Should Have] `spiritual_text` spike** (`spike_text_alignment.py`, own small script, clearly
   separable/removable): attempt automatic passage↔episode alignment (e.g. character-name +
   fuzzy-phrase matching, reusing `comics-ai-baloons`' `match.normalize`), report coverage across the
   27 episodes. Informational only — no other stage depends on its output this iteration.

## Data Models

### `PositionTrainingPair` (stage 3, `work/train_pairs/<episode>.jsonl`)

```python
@dataclass
class RegionFeatures:
    kind: str
    kind_source: str            # "explicit" | "inferred_heuristic" | "predicted"
    local_bbox: tuple[int, int, int, int]   # region's bbox within its own page/photo crop
    page_index: int
    reading_order_index: int    # this region's index among the page's regions, top-to-bottom

@dataclass
class PositionTrainingPair:
    episode_file: str
    photo_file: str
    region: RegionFeatures
    target_layer_index: int
    target_bbox: tuple[int, int, int, int]   # GroundTruthRegion.bbox — canvas coordinates
    target_transform: dict       # resolve_resting_transform() output — x, y, scale_x, scale_y, alpha
    match_confidence: float      # from PageAlignmentResult, carried through for eval weighting
```

### `PositionProposal` (stage 4/5 output, per region)

```python
@dataclass
class PositionProposal:
    region_id: str               # matches the corresponding DetectedRegion (comics-multimodal contract)
    proposed_x: int
    proposed_y: int
    proposed_scale_x: float = 1.0    # Should Have; 1.0 = unscaled if not predicted
    proposed_scale_y: float = 1.0
    source: str                  # "baseline" | "learned_model"
    confidence: float | None     # learned model only; baseline has no natural confidence score
```

### Report (`work/eval_report.jsonl`, one line per held-out file)

Mirrors `comics-multimodal`'s own report shape (`work/eval_report.jsonl`): per-file positional error
(e.g. mean/median L2 distance between proposed and ground-truth canvas position, in px, plus a
normalized-by-canvas-height version since files vary from small episodes to the full ~33000px case),
baseline vs. learned-model columns side by side.

## Behavior Specifications

### Happy Path

**Given** a real photo already matched to an episode+page by `comics-multimodal`'s `align_photo.py`,
with `comics-multimodal`'s segmenter having produced kind-tagged `CutRegion`s for it
**When** this flow's positioner runs (baseline, and learned model if built)
**Then** each region gets a `PositionProposal` (canvas X/Y, optionally scale), and — if this page's
episode is one of the 27 held-out-eval files — an error metric against its real `GroundTruthRegion`

### Edge Cases

| Case | Handling |
|------|----------|
| Page has zero confident regions (segmenter found nothing) | No `PositionProposal`s emitted; logged, not an error |
| Page's alignment confidence is low (`PageAlignmentResult.status == "skipped_no_match"`) | Excluded from training pairs and from eval; positioning can still run at inference time on unmatched real input (no ground truth to check against, proposal-only) |
| Region's kind is `"art"`/generic (fallback, not a real taxonomy match) | Still positioned (kind is a model feature, not a gate) but flagged low-confidence by convention, consistent with `vdd-comics-editor-ai-uiux`'s existing kind-confidence UI pattern |
| Printed page number missing/unreliable for the anchor bootstrap | Falls back to per-page relative positioning only (see "Cross-Page Ordering"); episode-level absolute placement left unresolved, disclosed in the report, not silently guessed |
| A page's `ground_truth_cluster` spans layers whose resting alpha is 0 (invisible) | Excluded — `render_canvas.py` already skips these when building `GroundTruthRegion`s, so they never enter training pairs |

### Error Handling

Same skip-and-log discipline as `comics-ai-baloons`/`comics-multimodal`: never guess a position for
a region with no usable training signal or no confident alignment; log it in the report instead.

## Editor Integration Contract (design only, not built this iteration)

Additive extension of `comics-multimodal`'s existing contract (not a competing shape):

```dart
class DetectedRegion {
  final String kind;
  final Uint8List maskPng;
  final Rect bbox;              // existing: region's own cut bbox
  final double confidence;      // existing: kind/cut confidence
  final Offset? proposedPosition;   // NEW: this flow's suggested canvas X/Y, null if not computed
  final double? positionConfidence; // NEW: null for baseline-sourced proposals (no natural score)
}
```

A future `PositioningReviewCard` (analogous to `CuttingReviewCard`/`BalloonEditorCard`) would let a
corrector drag-adjust `proposedPosition` before it's committed as the layer's real
`TranslateAnim.X`/`Y` — never-silent-auto-apply, same rule as every prior AI-assist surface in this
app. Not built this iteration; this section exists so a later flow doesn't need to re-derive the
shape.

## Testing Strategy

### Unit Tests

- [ ] `build_pairs.py`: joining a known `GroundTruthRegion` set with a known `ground_truth_cluster`
      produces the expected `PositionTrainingPair`s (hand-built fixture)
- [ ] `baseline_position.py`: given a fixed set of region features, produces deterministic,
      order-preserving Y stacking
- [ ] `resolve_resting_transform` reuse: confirm this flow imports rather than reimplements it (a
      regression guard against silent drift from `comics-multimodal`'s copy)

### Integration Tests

- [ ] End-to-end on 2-3 real, already-aligned pages from `comics-multimodal`'s existing
      `work/alignment.jsonl`: baseline positioner runs, produces proposals, eval report generated
- [ ] Held-out-file eval: baseline (and learned model, if built) evaluated on files never used to
      calibrate baseline spacing / train the model

### Manual Verification

- [ ] Visually overlay a held-out file's proposed positions against its real composited canvas
      (`comics-multimodal/work/canvas/<file>.png`) — sanity check before trusting the error metric
      alone

## Dependencies

### Requires

- `sdd-comics-ai-multimodal` (COMPLETE) — `render_canvas.py`, `resting_position.py`,
  `align_photo.py`, `kind_heuristic.py`, and their existing `work/canvas/`, `work/alignment.jsonl`
  outputs, all reused directly

### Blocks

- A future editor-integration flow (positioning review UI) — this flow only designs that contract

## Open Design Questions

- [ ] **Learned model architecture** (if Plan budgets attempting one beyond baseline): lightweight
      regression (GBDT/small MLP) over engineered features, vs. a small learned embedding of
      kind+neighbor context — decide in Plan based on how much signal the baseline leaves on the
      table during Specifications' own quick data exploration.
- [ ] **Page-number anchor reliability**: needs a real check against `Comics_Episodes.csv`/printed
      page numbers before Plan commits to it as the cross-page bootstrap — sizing this honestly is a
      Plan-phase task, not assumed here.
- [ ] **`spiritual_text` spike scope**: exact matching approach (character-name + fuzzy phrase, per
      the precedent found for episode 21) — small enough to decide during Plan, not blocking here.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-01
- [x] Notes: Approved via "approved" — the training-pair-construction insight (joining
      `align_photo.py`'s `ground_truth_cluster` with `render_canvas.py`'s `GroundTruthRegion`) is the
      load-bearing design decision; everything else follows from it. Two disclosed risks (page-number
      OCR not yet built; learned model may not beat baseline) carried into Plan for honest sizing.
