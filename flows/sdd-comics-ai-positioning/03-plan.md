# Plan: comics-ai-positioning

> Version: 0.1
> Status: DRAFT
> Last Updated: 2026-08-01

## Summary

8 phases. Phases 1-4 build the Must-Have deliverable (training pairs → baseline positioner →
evaluation) using only already-existing `comics-multimodal` outputs — no new ML training required to
reach a shippable result. Phase 5 (learned model) and Phase 7 (cross-page page-number anchor) are
explicitly gated: attempt only if their own checkpoint shows real signal, ship the Phase 1-4 baseline
alone otherwise (an acceptable outcome per Requirements). Phase 6 (`spiritual_text` spike) and Phase
8 (reporting/contract docs) round out the Should-Haves.

## Task Breakdown

### Phase 1: Environment & Foundation

#### Task 1.1: Working directory + reuse wiring
- **Description**: Create `apps/comics-ai/comics-positioning/{scripts,work}/`. Add a bridge module
  (`positioning_bridge.py`, mirrors `comics-multimodal`'s own `baloons_bridge.py` pattern) that
  imports `render_canvas`, `resting_position`, `align_photo`, `kind_heuristic` directly from
  `apps/comics-ai/comics-multimodal/scripts/` (path-append, not a copy) — verifies at import time
  that `comics-multimodal`'s `work/canvas/*.gt.json` exists (fail with a clear message if that
  pipeline hasn't been run).
- **Files**:
  - `apps/comics-ai/comics-positioning/scripts/positioning_bridge.py` - Create
  - `apps/comics-ai/comics-positioning/requirements.txt` (or shared venv note) - Create
- **Dependencies**: None
- **Verification**: unit test importing each reused function and confirming it's the *same* object
  as `comics-multimodal`'s (not an accidental copy/fork)
- **Complexity**: Low

#### Task 1.2: Data availability Checkpoint
- **Description**: Before building anything else, run `align_photo.py` (or read its existing
  `work/alignment.jsonl` if current) and count how many real photos reach `status == "matched"` with
  a non-empty `ground_truth_cluster`. This number bounds everything downstream — if it's very small
  (e.g. under ~15-20 usable pairs), Phase 5 (learned model) should be skipped outright, not attempted
  and then abandoned.
- **Files**: None (analysis; result recorded in this Plan's Risk Assessment)
- **Dependencies**: Task 1.1
- **Verification**: documented count + a hand-picked spot check of 2-3 matched pairs' plausibility
  (region kinds present in the cluster look right for that page)
- **Complexity**: Low

### Phase 2: Training Pair Construction

#### Task 2.1: `RegionFeatures`/`PositionTrainingPair` dataclasses
- **Description**: Shared dataclasses per Specifications' Data Models section.
- **Files**:
  - `apps/comics-ai/comics-positioning/scripts/models.py` - Create
- **Dependencies**: Task 1.1
- **Verification**: round-trip serialize/deserialize test
- **Complexity**: Low

#### Task 2.2: Training pair builder
- **Description**: `build_pairs.py` — for each matched page in `align_photo.py`'s output, join its
  cut regions (kind + local bbox, from `comics-multimodal`'s existing `regions.jsonl` if present,
  else re-derive via `kind_heuristic`) against `ground_truth_cluster_for`'s `GroundTruthRegion`s
  (canvas bbox + `resolve_resting_transform`'s full X/Y/scale/alpha). Writes
  `work/train_pairs/<episode>.jsonl`.
- **Files**:
  - `apps/comics-ai/comics-positioning/scripts/build_pairs.py` - Create
- **Dependencies**: Task 2.1, Task 1.2 (need the real count to know if this is worth building in
  full vs. a minimal version)
- **Verification**: run over all matched pages; assert every emitted pair's `target_bbox` matches a
  real `GroundTruthRegion` from the corresponding `.gt.json` (no silent mismatch); manually inspect
  3-5 pairs' input/target visually plausible (Read tool image compare)
- **Complexity**: Medium

### Phase 3: Baseline Positioner (Must Have)

#### Task 3.1: Real-data spacing statistics
- **Description**: Mine `comics-multimodal`'s existing `work/canvas/*.gt.json` (all 27 files, not
  just matched-photo ones — this doesn't need the photo alignment, just the known-good canvases) for
  per-kind spacing statistics: median/IQR of Y-gap between a region and its nearest same-page
  neighbor of each other kind, and typical region height by kind. This calibrates Task 3.2, replacing
  guessed constants with real numbers.
- **Files**:
  - `apps/comics-ai/comics-positioning/scripts/spacing_stats.py` - Create
- **Dependencies**: Task 1.1
- **Verification**: sanity-check output against 2-3 manually-inspected files (do the numbers look
  like real comic-page spacing, not degenerate/zero)
- **Complexity**: Low

#### Task 3.2: Baseline positioner
- **Description**: `baseline_position.py` — given a page's regions in reading order (top-to-bottom
  by local bbox Y, per Specifications), stack them vertically using Task 3.1's calibrated spacing,
  emitting `PositionProposal`s with `source="baseline"`.
- **Files**:
  - `apps/comics-ai/comics-positioning/scripts/baseline_position.py` - Create
- **Dependencies**: Task 3.1, Task 2.1
- **Verification**: deterministic-output unit test (fixed input → fixed output); run against Task
  2.2's real training pairs, confirm output shape matches `PositionProposal`
- **Complexity**: Medium

### Phase 4: Evaluation (Must Have)

#### Task 4.1: Held-out split + metric
- **Description**: `evaluate_positioning.py` — split the training-pair episodes file-wise (not
  region-wise, per Specifications) into train/held-out; compute per-file mean/median L2 error
  (proposed vs. ground-truth canvas position), both raw px and normalized by canvas height. Writes
  `work/eval_report.jsonl`.
- **Files**:
  - `apps/comics-ai/comics-positioning/scripts/evaluate_positioning.py` - Create
- **Dependencies**: Task 3.2
- **Verification**: run baseline against held-out split; report is non-empty and numbers are
  finite/sane (not NaN/zero-division on an edge case)
- **Complexity**: Medium

#### Task 4.2: **Checkpoint B** — baseline sanity review
- **Description**: Visually overlay 2-3 held-out files' baseline proposals against their real
  composited canvas (`comics-multimodal/work/canvas/<file>.png`). Documented pass/fail call: is the
  baseline in the right ballpark (regions roughly where they should be, right relative order) even
  if not pixel-perfect?
- **Files**: None (analysis; result recorded in Risk Assessment / Open Implementation Questions)
- **Dependencies**: Task 4.1
- **Verification**: documented side-by-side comparison, explicit call
- **Complexity**: Low
- **Gate**: if this fails badly (baseline is not even roughly plausible), stop and revisit
  Specifications' core approach before spending effort on Phase 5's learned model — a bad baseline
  means the training-pair data itself is likely wrong, and a learned model would just fit noise.

**Must-Have deliverable complete at the end of Phase 4** — Phases 5-8 below are Should-Have/optional,
explicitly gated on Task 1.2's data-count check and Task 4.2's sanity check.

### Phase 5: Learned Positioner (optional — gated on Task 1.2's count and Task 4.2's pass)

#### Task 5.1: Feature engineering + simple model
- **Description**: Only attempted if Task 1.2 found enough usable pairs (rough bar: same order of
  magnitude as `comics-ai-baloons`'s smallest viable slices, not a from-scratch-deep-model volume).
  Engineered features (kind one-hot, local bbox size/position, neighbor-kind context) →
  gradient-boosted-tree or small MLP regression for X/Y (and scale, Should-Have) offset from the
  baseline's own proposal (residual learning — easier than predicting absolute position from
  scratch given tiny data).
- **Files**:
  - `apps/comics-ai/comics-positioning/scripts/train_positioner.py` - Create
  - `apps/comics-ai/comics-positioning/scripts/infer_positioner.py` - Create
- **Dependencies**: Task 2.2, Task 4.2 (baseline must pass sanity first)
- **Verification**: Task 4.1's evaluation harness re-run with `source="learned_model"` rows added
  side by side with baseline — model is only kept if it measurably beats baseline on held-out error,
  per Requirements' explicit baseline-vs-model criterion
- **Complexity**: High (real risk this doesn't beat baseline given data size — that's an acceptable,
  disclosed outcome, not a task failure)

### Phase 6: `spiritual_text` Spike (Should Have, time-boxed)

#### Task 6.1: Text↔episode alignment attempt
- **Description**: Small, standalone script — for each of the 27 episodes, attempt to find a
  matching passage in `spiritual_text/` (character-name + fuzzy-phrase matching, reusing
  `comics-ai-baloons`'s `match.normalize`, same technique that found the real episode-21 match by
  hand during Requirements). Report coverage (how many of 27 episodes get a confident match) — no
  other stage consumes this output this iteration, per Requirements' Won't-Have.
- **Files**:
  - `apps/comics-ai/comics-positioning/scripts/spike_text_alignment.py` - Create
- **Dependencies**: None (independent of Phases 2-5)
- **Verification**: coverage report; manually spot-check 2-3 matches for real correctness (not just
  a fuzzy-score threshold pass)
- **Complexity**: Medium
- **Time-box**: stop after this task regardless of outcome — do not chain into building consumption
  of this signal this iteration, even if coverage looks good (that's explicitly next-flow scope)

### Phase 7: Cross-Page Anchor (optional — real new work, not free)

#### Task 7.1: Printed page-number extraction
- **Description**: Crop a candidate page-number region from a photo (corner of the page, per
  Checkpoint A's visual examples) and OCR just that crop (digit-focused, not full-page OCR). New
  capability — nothing in `comics-multimodal` does this today.
- **Files**:
  - `apps/comics-ai/comics-positioning/scripts/page_number.py` - Create
- **Dependencies**: Task 1.1
- **Verification**: run against the same photos Checkpoint A manually inspected (`04-implementation-
  log.md` cites specific examples: "28/29", "194/198") — confirm automatic extraction matches the
  already-known-correct manual reading
- **Complexity**: Medium (OCR on a small crop is usually easier than full-page, but real risk of
  glare/angle failure on this specific photo set, per `comics-multimodal`'s own documented low-camera
  quality issues)

#### Task 7.2: Page-number → episode/Y-range mapping + anchor bootstrap
- **Description**: Only attempted if Task 7.1 succeeds at reasonable coverage. Since episodes are
  matched by content (balloon-text OCR), not page-number ranges, this requires deriving each matched
  episode's approximate page-number span from its own matched pages' extracted numbers (not an
  existing lookup table) — genuinely new inference, not a simple join.
- **Files**:
  - `apps/comics-ai/comics-positioning/scripts/page_anchor.py` - Create
- **Dependencies**: Task 7.1
- **Verification**: cross-check derived episode page-ranges against the print book's known 198+-page
  total and 27-episode coverage for gross plausibility (ranges shouldn't overlap nonsensically)
- **Complexity**: High
- **Fallback if this phase is skipped or fails**: per-page-cluster relative positioning only
  (Phase 3/4's baseline already produces this) — absolute cross-page placement left to a human
  reviewer, exactly as Specifications' Edge Cases table already designed for.

### Phase 8: Reporting & Contract Documentation

#### Task 8.1: Final report + README
- **Description**: Consolidate Phase 4 (and 5/6/7 if attempted) results into a single
  `work/report.md` (mirrors `comics-ai-baloons`'s/`comics-multimodal`'s report convention): what was
  built, baseline vs. model numbers, `spiritual_text` coverage if run, page-anchor outcome if
  attempted, and an honest statement of what's still unproven.
- **Files**:
  - `apps/comics-ai/comics-positioning/README.md` - Create
- **Dependencies**: Task 4.1 (minimum), others if attempted
- **Verification**: read-through against Requirements' Acceptance Criteria, confirm each is
  addressed or explicitly disclosed as not met
- **Complexity**: Low

#### Task 8.2: Editor Integration Contract doc
- **Description**: Write up the `PositionProposal`/`DetectedRegion.proposedPosition` extension from
  Specifications as a standalone doc section (design only, no Dart code) for a future editor-
  integration flow to pick up, mirroring how `comics-multimodal`'s own contract section was written.
- **Files**:
  - `apps/comics-ai/comics-positioning/README.md` - Modify (append section)
- **Dependencies**: Task 8.1
- **Verification**: cross-reference against `vdd-comics-editor-ai-uiux`'s actual shipped
  `CuttingReviewCard`/contract shape (once that flow is further along) for consistency — informal
  check, not a blocking dependency
- **Complexity**: Low

## Dependency Graph

```
1.1 → 1.2 → 2.2 (also needs 2.1)
1.1 → 2.1
1.1 → 3.1 → 3.2 (also needs 2.1)
3.2 → 4.1 → 4.2 (gate)
4.2 → 5.1 (gated, optional)
1.1 → 6.1 (independent branch, time-boxed)
1.1 → 7.1 → 7.2 (gated, optional)
4.1 (+5.1/6.1/7.2 if run) → 8.1 → 8.2
```

## File Change Summary

| File | Action | Phase |
|------|--------|-------|
| `apps/comics-ai/comics-positioning/scripts/positioning_bridge.py` | Create | 1 |
| `apps/comics-ai/comics-positioning/scripts/models.py` | Create | 2 |
| `apps/comics-ai/comics-positioning/scripts/build_pairs.py` | Create | 2 |
| `apps/comics-ai/comics-positioning/scripts/spacing_stats.py` | Create | 3 |
| `apps/comics-ai/comics-positioning/scripts/baseline_position.py` | Create | 3 |
| `apps/comics-ai/comics-positioning/scripts/evaluate_positioning.py` | Create | 4 |
| `apps/comics-ai/comics-positioning/scripts/train_positioner.py` | Create | 5 (optional) |
| `apps/comics-ai/comics-positioning/scripts/infer_positioner.py` | Create | 5 (optional) |
| `apps/comics-ai/comics-positioning/scripts/spike_text_alignment.py` | Create | 6 |
| `apps/comics-ai/comics-positioning/scripts/page_number.py` | Create | 7 (optional) |
| `apps/comics-ai/comics-positioning/scripts/page_anchor.py` | Create | 7 (optional) |
| `apps/comics-ai/comics-positioning/README.md` | Create | 8 |

No files under `apps/comics-editor/`, `apps/comics-ai/comics-multimodal/`, or `dataset/` are
modified by this flow.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Too few real matched-photo pairs (Task 1.2) to train anything meaningful | Medium — `comics-multimodal`'s own alignment is real but conservative (skip-and-log over guessing) | Medium | Baseline (Phase 3) doesn't need photo-matched pairs at all for calibration (Task 3.1 uses all 27 known-good canvases directly) — Must-Have deliverable survives even if Task 1.2's count is low |
| Learned model doesn't beat baseline | Medium-High, disclosed in Requirements as acceptable | Low (not a failure) | Task 4.2 gate + explicit "ship baseline alone" acceptable-outcome framing |
| Page-number OCR (Task 7.1) fails on this photo set's known quality issues (glare/angle) | Medium — same physical photos `comics-multimodal` already found challenging | Low | Entire Phase 7 is optional; Specifications' fallback (per-page relative positioning) is already the Phase 3/4 default, not a new path to build |
| `spiritual_text` spike (Phase 6) finds low coverage | Medium — only confirmed for 1/27 episodes so far | Low | Explicitly informational/time-boxed; no other phase depends on it |
| Baseline's spacing statistics (Task 3.1) are skewed by a few outlier files | Low-Medium | Medium | Task 4.2's visual sanity checkpoint catches this before Phase 5 investment |

## Rollback Strategy

Every stage writes to its own `work/` subdirectory; nothing is destructive or touches `dataset/` or
`comics-multimodal/work/` (read-only inputs). Any phase can be deleted/rerun independently. If Phase
5/7 are abandoned mid-attempt, Phases 1-4's Must-Have output is unaffected.

## Checkpoints

- **Checkpoint A** (Task 1.2): real matched-pair count — decides whether Phase 5 is attempted at all
- **Checkpoint B** (Task 4.2): baseline visual sanity — gates Phase 5 investment

## Open Implementation Questions

- [ ] Exact regression target for Phase 5 (Task 5.1): absolute position vs. residual-from-baseline —
      leaning residual (stated above) but confirm once Task 1.2's real data volume is known.
- [ ] Whether Task 3.1's spacing statistics should be global or per-episode-era (the dataset spans
      2017-2022 vintages per `comics-ai-baloons`'s own finding of divergent conventions) — decide
      during Task 3.1 itself based on whether the statistics look bimodal.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-01
- [x] Notes: Approved via "approved". Moving to Implementation, starting with Phase 1.
