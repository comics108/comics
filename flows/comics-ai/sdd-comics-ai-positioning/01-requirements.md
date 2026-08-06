# Requirements: comics-ai-positioning

> Version: 0.2 (v0.1's Open Questions resolved against real code in `apps/comics-ai/comics-multimodal/
> scripts/` rather than left as guesses — see "resolved by codebase investigation" section)
> Status: APPROVED
> Last Updated: 2026-08-01

## Origin

Spun out of `flows/sdd-comics-editor-questions/` on 2026-08-01, after a direct answer from Anton
clarified what "character/background placement" actually means (previously an open question in
`flows/vdd-comics-editor-jhanava/`), and a follow-up architecture proposal discussion. `sdd-comics-
ai-multimodal` (COMPLETE) already solved **cutting/segmentation** — decomposing a flattened page
image into kind-tagged regions. This flow addresses the problem that turned out to be distinct and
still unbuilt: **recomposition/positioning** — arranging those cut regions into the final continuous
strip, the "order of magnitude harder than balloon" problem Джанава's original framing pointed at.

## Problem Statement

Per Anton's direct answer (2026-08-01, recorded in `flows/sdd-comics-editor-questions/
01-requirements.md`): the artist hand-draws the entire comic on paper in traditional
paneled/scened page layout. This gets digitized, then cut into kind-tagged regions (solved by
`sdd-comics-ai-multimodal`). Those regions are then **moved and recomposed** into the product's
actual final form — a single long continuous vertical strip ("лента"), not the original paneled
book layout — confirmed to match exactly what all 27 existing `dataset/.../comics_interactive/*
.comics` files already are (tall ~33000px scrolling canvases; `sdd-comics-ai-multimodal`'s
Checkpoint A independently found the printed source to be conventionally paginated, which this
answer now explains). The person doing this ("нарезатор") exercises real creative judgment —
deciding transitions, spacing, and continuity across what were originally separate panels. If a
human cutter doesn't know how, the product vision calls for **AI to propose a composition**,
trained on the corpus of what human cutters have historically produced.

Nothing today builds this. `sdd-comics-ai-multimodal` explicitly stops at cutting (Won't Have:
"Timeline/motion-FX authoring... tracked in `flows/vdd-comics-editor-jhanava`" — recomposition is
adjacent to that same gap, not literally timeline, but equally unbuilt). `vdd-comics-editor-ai-uiux`
(in progress) reviews AI-cut regions into layers **at their original cut bounding box** — it does
not recompose them into a new strip position. This flow closes that specific gap.

### Key technical grounding (from investigation prior to this draft, not assumption)

- **Training data is largely already free**: for all 27 existing `.comics` files, the ground-truth
  final position of every layer is already known (`Layer.Animations` → `TranslateAnim.X`/`Y` in
  `data.json`). `sdd-comics-ai-multimodal`'s alignment stage already maps photographed printed pages
  (paneled form) to their corresponding episode content. So (cut region from paneled source) →
  (ground-truth target X/Y in the finished strip) pairs already exist for most of the dataset — this
  was not previously understood as reusable training signal for *this* task (it was built for
  segmentation ground truth).
- **Editor has no grouping/layout-assist concept** (`apps/comics-editor/native/Comics.Editor/Models/
  Layer.cs`, grepped repo-wide for `Group` — zero matches). Every layer's position is a plain,
  independent `int X`/`int Y` (`TranslateAnim.cs:19-41`), keyframed by scroll position. A positioning
  model's output must be **per-layer absolute (or relative-to-neighbor) coordinates**, not a group
  transform — there's no group primitive to emit output into.
- **512×512 tiling is unrelated to this problem** — confirmed fully automatic at the storage/render
  layer (`FileManager.cs`, `ImagePathConverter.cs` on desktop; `TileImageView.java` for the mobile
  viewer's viewport virtualization). A positioning model works in full-image coordinate space; tiling
  happens transparently underneath whatever position is chosen.
- **Text grounding is a real but unproven auxiliary signal**: `dataset/.../spiritual_text/` contains
  real, scene-matching narrative prose (including direct speech) for at least one validated episode
  (21, `21_ambas_plea`) — found by direct inspection, not assumed. Coverage is not proven complete
  (the same file's own table of contents defers part of Amba's story to a Book 5 volume not present
  in `dataset/`). Not yet attempted: automatic text↔episode/panel alignment. Treated as a
  should-have spike, not a dependency, given the coverage uncertainty.

## User Stories

### Primary

**As a** comics content pipeline maintainer
**I want** a model/pipeline that, given a set of already-cut, kind-tagged regions from a paneled
source page (the output of `sdd-comics-ai-multimodal`'s cutting stage), proposes their target
positions in a continuous vertical strip layout
**So that** reconstructing or producing a `.comics` page from photographed/paneled source material
doesn't require a human to manually calibrate every layer's X/Y from scratch

### Secondary

- **As a** pipeline maintainer, **I want** the proposed layout evaluated against the 27 existing
  files' real ground-truth positions (held-out per-file, not per-region, to avoid leaking a file's
  own layout style into its own eval) **so that** I know whether the model's suggestions are
  plausible before anyone reviews them by hand.
- **As a** future `apps/comics-editor` human corrector (not built this iteration, per
  `sdd-comics-ai-multimodal`'s own precedent), **I want** proposed positions delivered as an
  extension of the existing cutting-review contract (`DetectedRegion`/`CuttingEvent`) **so that** a
  later editor-integration flow can reuse the same never-silent-auto-apply review pattern
  (`BalloonEditorCard`/`CuttingReviewCard`) instead of inventing a new one.
- **As a** pipeline maintainer, **I want** a cheap, disclosed spike into whether `spiritual_text` can
  be automatically aligned to episodes/panels **so that** the team knows whether text-grounded
  ordering/identity is worth investing in further, without committing to it as a dependency now.

## Acceptance Criteria

### Must Have

1. **Given** the cut, kind-tagged regions `sdd-comics-ai-multimodal` already produces for a matched
   photo/episode
   **When** the positioning pipeline runs
   **Then** it outputs a proposed target X/Y (and any other needed placement, e.g. scale) per region,
   in the same coordinate space as the episode's final continuous-strip canvas

2. **Given** a held-out set of the 27 existing `.comics` files (not used in training)
   **When** their known layer arrangement is used as ground truth
   **Then** the pipeline's proposed positions are evaluated against it with an explicit, documented
   metric (e.g. positional error vs. ground truth, ordering/sequence correctness) — sized honestly per
   this repo's established precedent (`comics-ai-baloons`, `comics-ai-multimodal`), not overstated

3. **Given** a rule-based/heuristic baseline (vertical stacking by panel/reading order, spacing
   calibrated from real dataset statistics)
   **When** it's compared against any learned-model variant attempted
   **Then** both are reported, so a learned model is only adopted if it demonstrably beats the
   baseline — given the small (27-file) data size, the baseline may end up being the shipped answer
   this iteration, and that's an acceptable outcome, not a failure

4. **Given** the existing `MultimodalCuttingClient`/`CuttingEvent`/`DetectedRegion` contract designed
   in `sdd-comics-ai-multimodal`'s Specifications
   **When** this flow designs its own output contract
   **Then** it's an additive extension of that shape (e.g. a `proposedPosition` field), not a
   competing/parallel contract — so a future editor-integration flow can adopt both together

### Should Have

- A disclosed spike (time-boxed) on automatic `spiritual_text` ↔ episode/panel alignment, reporting
  coverage (how many of the 27 episodes have a real matching passage) and whether it measurably
  improves ordering or character-identity confidence over the existing OCR-dialogue/episode-name
  heuristics — not a commitment to use it if coverage turns out low
- Reuse of `sdd-comics-ai-multimodal`'s library clustering (character/environment identity) to keep
  a recurring character's regions positioned/scaled consistently across a page

### Won't Have (This Iteration)

- **In-editor review UI** for proposed positions — this flow is pipeline/contract-design only,
  mirroring `sdd-comics-ai-multimodal`'s own precedent (that flow designed but didn't build the
  cutting-review UI either; `vdd-comics-editor-ai-uiux` built that as a separate, later flow). A
  `vdd-comics-editor-positioning-uiux`-shaped follow-on would build the review surface.
- **Multi-page-to-single-episode assembly logistics** beyond what's needed to position regions within
  one matched episode's strip — see Open Questions below on episode/page granularity.
- **Full generative recomposition** (inventing new transitions/art, not just placing existing cut
  regions) — out of scope; this is a layout/placement problem over already-cut material, not content
  generation.
- **Text→`.comics` generation** using `spiritual_text` as a primary driver — the Should-Have spike is
  about *alignment/grounding*, not generating new content from text.

## Constraints

- **Technical**: `dataset/` remains read-only; output goes to a new
  `apps/comics-ai/comics-positioning/work/` (mirroring `comics-multimodal`'s/`comics-ai-baloons`'s
  convention) — working directory TBC in Specifications, likely `apps/comics-ai/comics-positioning/`.
- **Technical**: output must be expressible as plain per-layer `TranslateAnim.X`/`Y` (ints) — no
  group/parent-child transform, since the editor has no such concept.
- **Data volume**: same honest-risk-sizing constraint as `sdd-comics-ai-multimodal` — 27 source files
  is small for a learned layout model; the Must-Have baseline exists specifically so this flow has a
  real deliverable even if a learned model doesn't clear the baseline.
- **Dependencies**: hard dependency on `sdd-comics-ai-multimodal`'s completed cutting/segmentation
  and alignment stages (reused, not rebuilt). Soft/optional dependency on `spiritual_text` per the
  Should-Have spike. No dependency on `vdd-comics-editor-ai-uiux`'s in-progress editor UI work — this
  flow's output contract should anticipate it, not require it to exist first.

## Open Questions — resolved by codebase investigation (2026-08-01), pending Anton's read-through

Anton said "дальше" (proceed) rather than answering these one by one. Per Auto Mode guidance
(reasonable default + keep moving, redirect if wrong), each is now resolved against real code in
`apps/comics-ai/comics-multimodal/scripts/`, not left as a guess — see `02-specifications.md` for
full detail:

- [x] **Episode/page granularity — resolved, not just decided**: `align_photo.py` already matches at
      *page* granularity (`PageAlignmentResult`), and `ground_truth_cluster_for` already expands a
      matched page's layers to their full local scene cluster via `augment.py`'s clustering. Positioning
      trains/infers at this same page-cluster granularity — no new granularity concept needed. Cross-page
      ordering *within* an episode turns out not to need a separate mechanism either: the target space is
      one continuous Y-axis (the strip), so correct relative-Y placement *is* the ordering; an
      individual page's absolute Y-anchor within its episode can bootstrap from the printed book's real
      page numbers (confirmed present, `sdd-comics-ai-multimodal` Checkpoint A) rather than requiring a
      new sub-model.
- [x] **Output scope beyond X/Y — resolved in favor of all four transform types, not just X/Y**:
      `resting_position.py::resolve_resting_transform` already extracts ground-truth X/Y **and**
      scale/rotate/alpha from every existing layer's `animations[]` (verified against the C# `Anim`
      subclasses). Since this ground-truth extraction is already built and already used by
      `render_canvas.py` to produce training targets, restricting this flow's Must-Have to X/Y-only
      would be discarding free signal, not simplifying scope. Revised: Must-Have is X/Y; scale/alpha
      prediction promoted to Should-Have (reuses the same extracted ground truth, low incremental cost);
      rotation stays lowest-priority per `render_canvas.py`'s own documented finding that only
      1146/4594 real layers use `RotateAnim` at all.
- [x] **Baseline-vs-model decision authority — resolved as originally recommended**: baseline-or-model,
      whichever measurably wins, is the Must-Have; a learned model is not a hard requirement regardless
      of outcome. Unchanged from v0.1's recommendation.
- [x] **`spiritual_text` spike timing — resolved as originally recommended**: bundled into this flow's
      Plan as one small, explicitly time-boxed phase, not spun out. Unchanged from v0.1's
      recommendation.

## New finding this pass, materially reframes the core approach

`apps/comics-ai/comics-multimodal/scripts/package.py`'s own design note (written during that flow's
implementation) states directly: *"no pixel-level mapping from a real photo into canvas space exists
or is practically obtainable"* — this is why that pipeline's packaged output stays in the photo's own
coordinate space rather than attempting to place content into the matched episode's canvas. **This
confirms recomposition/positioning cannot be a geometric/registration problem** (there is no direct
photo-pixel ↔ canvas-pixel correspondence to solve for) — it has to be a **learned regression from
region properties (kind, size, local order) to canvas position**, trained on the real (page-cluster →
resting-position) pairs already latent in the existing 27 files via `align_photo.py` +
`render_canvas.py`. This isn't a new decision so much as independent confirmation that the
recommended approach (baseline + optional learned model, not a coordinate-transform) was the right
framing from the start.

## References

- `flows/sdd-comics-editor-fromat-dot-comics/` — consolidated `.comics` format reference; this
  flow's layer/no-grouping model, `TranslateAnim.X`/`Y` position representation, canvas geometry
  facts, and RotateAnim usage stat were extracted there alongside `vdd-comics-editor-timeline`'s
  format facts, 2026-08-01
- `flows/sdd-comics-ai-multimodal/` — COMPLETE; cutting/segmentation, alignment, and library-
  clustering stages this flow reuses directly; its `02-specifications.md` "Editor Integration
  Contract" (`MultimodalCuttingClient`/`CuttingEvent`/`DetectedRegion`) is the shape this flow's own
  output contract extends
- `flows/vdd-comics-editor-ai-uiux/` — in progress; builds the review UI for cutting output following
  the `BalloonEditorCard` pattern; the natural (but not this-iteration) home for a future positioning
  review surface
- `flows/vdd-comics-editor-jhanava/` — original source of the character/background "placement"
  framing this flow addresses; see its `_status.md` "Related Work Since This Flow Was Drafted" note
- `flows/sdd-comics-editor-questions/01-requirements.md` — the 2026-08-01 direct answer (raw
  material → paneled paper → cut → recomposed strip) and the Technical Verification section (no
  grouping in the editor, automatic tiling, `spiritual_text` findings) this flow is built on
- `apps/comics-editor/native/Comics.Editor/Models/Layer.cs`,
  `apps/comics-editor/native/Comics.Editor/Models/TranslateAnim.cs` — confirms the per-layer,
  group-less positioning model this flow's output must target
- `dataset/boranko/mahabharata/book1/comics_interactive/*.comics` — 27 files, the free ground-truth
  source for training/eval
- `dataset/boranko/mahabharata/book1/spiritual_text/` — text-grounding spike source
- `apps/comics-ai/comics-multimodal/scripts/render_canvas.py` — already computes exact ground-truth
  resting position (`GroundTruthRegion.bbox`) per layer for all 27 files; this flow's primary
  training-target source
- `apps/comics-ai/comics-multimodal/scripts/resting_position.py` — already extracts X/Y/scale/
  rotate/alpha ground truth from `animations[]`, verified against the real C# `Anim` subclasses
- `apps/comics-ai/comics-multimodal/scripts/align_photo.py` — already matches photographed pages to
  episodes at page granularity (`PageAlignmentResult`) and expands matches to a full scene cluster
  (`ground_truth_cluster_for`); this flow's primary training-input source
- `apps/comics-ai/comics-multimodal/scripts/package.py` — its design note confirms no pixel-level
  photo→canvas mapping is obtainable, grounding this flow's "learned regression, not geometric
  transform" approach

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-01
- [x] Notes: Approved via "approved" after v0.2's Open-Questions resolution pass (codebase-grounded,
      not just recommended defaults). No line-by-line pushback received — proceeding on this version
      as-is.
