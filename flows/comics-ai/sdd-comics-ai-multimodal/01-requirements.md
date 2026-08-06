# Requirements: comics-ai-multimodal

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-07-31

## Problem Statement

The Mahabharata comics catalog (`dataset/boranko/mahabharata/book1/`) currently exists as a set of
27 hand-produced, digitally-authored `.comics` files (`comics_interactive/`) — each a tall
(1080×~33000px) vertically-scrolling page, built from many art/balloon/character layers, some
animated (`TranslateAnim`/`AlphaAnim`), some voiced (`sounds`). Producing one of these files today
requires an artist/producer to manually compose every layer.

Alongside this, the dataset now also contains:

- `comics_book_lowcamera/` — 80 photos (4080×3060, phone camera) of the **printed, physical**
  edition of this same book. Quality varies (lighting, angle, focus) — these are not clean scans.
- `spiritual_text/` — the source narrative in prose form (`The Mahabharata, Volume I., Book 1-3 by
  Kisari Mohan Ganguli.html`), i.e. the text the comic was adapted from.
- `comics_interactive_baloons_translations/` — present but currently empty (reserved for future
  per-language balloon translation assets, mirroring `sdd-comics-ai-baloons`'s CSV-driven work).

We want to train an AI pipeline — **trained from scratch on our own data**, not a wrapper around a
third-party generative model — whose foundational capability is: **given a flattened, already-drawn
page image (a camera photo of print, or any other flattened render), segment/"cut" it back into its
constituent layer regions** (panels, characters, balloons, backgrounds), tagged by content kind, at
a quality sufficient to reassemble a valid `.comics` file. This is the same "material
cutting/systematization" step that `flows/vdd-comics-editor-jhanava` independently identified as a
likely-harder prerequisite than character/background *placement* itself — this flow is where that
prerequisite gets solved, grounded in real production data (following the same
investigate-the-actual-dataset-before-designing method `sdd-comics-ai-baloons` used for balloons).

Longer-term (explicitly lower priority, see below), the same underlying model/asset library should
let us: reconstruct `.comics` from a photographed page end-to-end; generate a `.comics` chapter from
narrative text (`spiritual_text`) or from a mix of already-drawn/text-only material; and — lowest
priority — generate wholly new art (e.g. render a single existing character, such as Princess Amba
— confirmed present as episode 21, `ambas_plea`, `8a89f7d689fb441ea280cd782276bd7a.comics` — in a
new pose from a text prompt), backed by growing per-character/per-environment asset libraries.

Separately, this capability must eventually be usable **inside `apps/comics-editor`** (the
Flutter+C# editor, renamed from `comics-editor-v2.9` on 2026-07-31) so a **human corrector** can
review and fix AI output before it ships — mirroring the balloon-lettering flow's existing
`BalloonEditorCard`/`BalloonAiClient` review pattern (per-item generate/regenerate with a
stale-output indicator, routed on-device/cloud, never silently auto-applied).

### Working directory

All scripts, extracted/derived data, trained model artifacts, and output `.comics` files live under
**`apps/comics-ai/comics-multimodal/`** (mirrors `apps/comics-ai/comics-ai-baloons/`'s convention):

- `apps/comics-ai/comics-multimodal/scripts/` — tooling (survey, alignment, segmentation/cutting,
  training, packaging)
- `apps/comics-ai/comics-multimodal/work/` — gitignored scratch: extracted assets, intermediate
  data, trained model checkpoints, generated `.comics` output, reports
- `dataset/` is **read-only** source input for the entire feature — never written to, consistent
  with every prior flow that touches it.

### Priority order (explicit, per user decision)

This flow deliberately does **not** attempt all five original scenarios at once. Priority, highest
first:

1. **Cutting/segmentation model** (train-from-scratch): given an already-rendered flat image,
   detect and extract per-kind layer regions (background/character/balloon/sound-visual/motion-fx —
   reusing the open-string `Kind` values already added to `Layer` by the lettering flow, not a new
   enum). This is the foundation every other scenario depends on.
2. **Photo → `.comics`** (using `comics_book_lowcamera/`): the first end-to-end scenario built on
   top of (1). Since the photographed pages are the *same* pages as the existing digital
   `.comics` files (confirmed: printed book = existing episodes), this can be built and validated as
   a **supervised** task — but with **no manual photo↔episode/page mapping**. The pipeline must
   determine automatically which episode/page/region a given photo corresponds to (content-based
   matching, in the spirit of `sdd-comics-ai-baloons`'s OCR+fuzzy CSV matching — not filename or
   index assumptions), tolerating that photographed frame order/cropping won't line up 1:1 with the
   source page layout.
3. **Input quality correction** (lower priority): enhancing/cleaning up poor-quality camera input
   (deskew, denoise, upscale) before/alongside cutting, so extracted regions reach a "unified
   quality" bar. Explicitly de-prioritized below the cutting task itself.
4. **Net-new image generation** (lowest priority, this iteration): drawing art that doesn't already
   exist in the dataset (new character poses, new environments). Acknowledged as a real longer-term
   goal (character/environment libraries, e.g. "draw Princess Amba in a new scene") but not this
   iteration's build target.
5. Full **text → `.comics`** and **mixed drawn/text-chapter → `.comics`** generation scenarios are
   deferred beyond this iteration; when eventually tackled, the output must be a **complete
   `.comics`** (art + balloons + animation keyframes + voice/sound), not static art only — noted here
   so the cutting model's output contract doesn't foreclose that later requirement.

## User Stories

### Primary

**As a** comics content pipeline maintainer
**I want** a from-scratch-trained model that segments a flattened page image (starting with real
camera photos of the printed book) back into its constituent, kind-tagged layer regions, correctly
and automatically matched to the corresponding existing episode/page without manual mapping
**So that** I can reconstruct valid `.comics` files from photographed source material and begin
building reusable per-character/per-environment asset libraries (e.g. a Princess Amba gallery) for
future content work

### Secondary

- **As a** pipeline maintainer, **I want** a clear per-photo/per-region match/cut/kind-classify
  report (mirroring `sdd-comics-ai-baloons`'s match/skip report) **so that** I can see exactly what
  was reconstructed vs. skipped and why, without ever touching `dataset/`.
- **As a** future `apps/comics-editor` user (human corrector), **I want** AI-segmented output
  eventually importable into the editor with a review/correct UI per content kind (extending the
  existing `BalloonEditorCard`/`BalloonAiClient` pattern: per-item generate/regenerate, stale
  indicator, on-device/cloud routing, never silent) **so that** I can fix mistakes by hand before a
  reconstructed or generated `.comics` ships. (Design the output contract to not preclude this; do
  not build the editor UI itself this iteration.)
- **As a** future content creator, **I want** an optional vector (`.svg`) representation packaged
  alongside the raster `.png` for extracted/generated regions where feasible **so that** assets can
  be scaled/edited losslessly later. (Explicitly optional/non-blocking — most source material is
  raster/photographic and may not vectorize cleanly.)

## Acceptance Criteria

### Must Have

1. **Given** the 27 `.comics` files in `dataset/boranko/mahabharata/book1/comics_interactive/` and
   the 80 photos in `comics_book_lowcamera/`
   **When** the pipeline processes a photo
   **Then** it automatically determines which existing episode/page/region that photo corresponds
   to via content-based matching — no manually-authored photo→episode mapping table is created or
   required

2. **Given** a photo matched to its corresponding source region
   **When** the cutting/segmentation model runs
   **Then** it decomposes the photographed page into per-region crops, each tagged with a content
   kind (background/character/balloon/sound-visual/motion-fx, using the editor's existing
   open-string `Kind` values), at a quality sufficient to recompose valid `.comics` layers

3. **Given** the segmented/cut regions for a photographed page
   **When** the pipeline packages output
   **Then** a new, valid `.comics` file (correct `data.json` schema: `width`/`height`, `layers[]`
   with `images[]` indexed per the fixed `Cultures` enum `{En, Ru, Hi}`, `animations[]`) is written
   to `apps/comics-ai/comics-multimodal/work/`, and `dataset/` remains untouched

4. **Given** the cut character regions across the dataset
   **When** a specific character (e.g. Princess Amba, episode 21 `ambas_plea`) is queried
   **Then** the pipeline can retrieve/export a gallery of that character's extracted crops — the
   first concrete "character library" artifact, independent of any generative capability

5. **Given** a full batch run over the available photos
   **When** it completes
   **Then** a machine-readable report enumerates, per photo/region: matched vs. unmatched (+ why),
   cut regions produced, kind classification, and confidence — mirroring the
   `sdd-comics-ai-baloons` report pattern

### Should Have

- Input-quality correction (deskew/denoise/upscale) for camera photos as a pre/post-processing step
  around the cutting model — lower priority than cutting itself, may ship as a separate pass
- Reuse of matched ground-truth animation/sound data (from the corresponding existing `.comics`
  file) when reconstructing a photographed page, rather than inventing new animation — exact scope
  TBD in Specifications
- Optional `.svg` vector representation alongside `.png` for extracted/generated regions, where
  feasible (e.g. clean-edge auto-vectorization) — non-blocking, best-effort
- A designed (not built) output/import contract for future `apps/comics-editor` integration,
  informed by the existing `BalloonAiClient`/`BalloonEditorCard` pattern, so a human-corrector
  review UI per content kind isn't architecturally precluded later

### Won't Have (This Iteration)

- Net-new image generation (art with no dataset precedent) — deferred, lowest priority per above
- End-to-end text → `.comics` or mixed drawn/text-chapter → `.comics` generation — deferred; this
  iteration's end-to-end scenario is photo → `.comics` only
- Building the in-editor human-correction UI itself, or any new RPC/plugin surface in
  `apps/comics-editor` — contract design only, no editor code changes this iteration
- A generic "register a new layer kind" plugin system in the editor — confirmed not to exist today;
  out of scope to build here (tracked as a constraint, see below)
- Timeline/motion-FX authoring — the editor has no time dimension at all today; out of scope,
  tracked in `flows/vdd-comics-editor-jhanava`
- Modifying anything under `dataset/`

### Deferred (Explicitly Tracked, Not Silently Dropped)

1. **Text → `.comics` and mixed drawn/text-chapter → `.comics`** full generation — deferred to a
   future iteration once the cutting model and character/environment libraries exist; output must
   then be a complete `.comics` (art + balloons + animation + voice), not static art only.
2. **Net-new image generation** (single-character rendering from a text prompt, e.g. "draw Princess
   Amba in a new scene") — deferred; depends on character library groundwork done here.
3. **In-editor human-correction UI + import RPC** for non-balloon content kinds — deferred; design
   the contract now, build later, following the `BalloonEditorCard`/`BalloonAiClient` precedent.
4. **`.svg` vector export** — optional; may be dropped entirely if infeasible without harming the
   must-have raster pipeline.

## Constraints

- **Technical**: `dataset/` is read-only; all output goes to
  `apps/comics-ai/comics-multimodal/work/`. The core cutting/segmentation model must be
  **trained from scratch** on this project's own data (per explicit user decision) — this does not
  preclude using off-the-shelf tools/APIs for lower-priority auxiliary tasks (OCR, quality
  correction), same as `sdd-comics-ai-baloons` did, but the central "cutting" capability itself is
  not a thin wrapper around a third-party foundation model.
- **`.comics` schema compatibility**: must stay additive/compatible with the live model in
  `apps/comics-editor/native/Comics.Editor/Models/` — `Cultures` enum is fixed at exactly
  `{En, Ru, Hi}` (extend via `Images[]` index >2, not by growing the enum); `Layer.Kind` is an open
  string already introduced by the lettering flow — reuse it, don't redefine it.
- **No manual data-mapping labor**: per user decision, nobody will hand-map camera photos to
  episode/page ids — any photo↔source alignment must be automatic (a real subtask of this flow, not
  an assumed input).
- **Data volume**: 27 `.comics` files, 80 camera photos, 1 narrative-text source document. This is
  small for training a segmentation model from scratch — Specifications must size this risk honestly
  (data augmentation strategy, whether the existing layered `.comics` files can serve as
  auto-generated (rendered composite → known layer ground truth) training pairs at scale, etc.),
  echoing the honest risk-sizing precedent set in `sdd-comics-ai-baloons`'s requirements.
- **Editor integration constraints** (confirmed by reading `apps/comics-editor`'s live architecture
  and specs): no generic plugin/import system exists — every new content path needs bespoke
  plumbing (as the lettering flow built for balloons); no timeline/time dimension exists in the
  editor at all; undo/redo is a session-only, full-document-snapshot stack (fine for "revert this AI
  edit," not for any cross-session audit trail). None of this blocks this iteration (which doesn't
  touch the editor), but the output contract designed as a "Should Have" must account for it.
- **Platform/performance**: offline training + batch pipeline; no real-time constraint this
  iteration.
- **Dependencies**: builds conceptually on `sdd-comics-ai-baloons` (methodology, and the balloon
  `Kind`/`Style`/`Translations` layer-model additions it produced) but has no hard code dependency on
  it.

## Open Questions

To resolve in Specifications:

- [ ] **Segmentation/cutting model architecture**: what from-scratch model family fits (instance
      segmentation? panel/tile-boundary detection + connected components? a learned layer-decomposition
      model trained against the existing `.comics` files' *known* ground-truth layers)?
- [ ] **Photo↔page alignment approach**: concrete automatic-matching method (visual
      feature/keypoint matching, perceptual hashing, OCR-based content matching per the
      `ai-baloons` precedent, or a combination) — and its confidence-threshold/skip-and-log policy.
- [ ] **Training-data construction**: can the existing 27 layered `.comics` files be used to
      synthesize large numbers of (flattened composite → ground-truth layers) training pairs
      automatically (i.e., render each file's known layer stack to a flat image as a training
      target), supplementing the comparatively small 80-photo real-world sample?
- [ ] **Quality-correction approach and sequencing**: is input clean-up a pre-pass, post-pass, or
      trained jointly with the cutting model?
- [ ] **Evaluation metric(s)** for cutting/segmentation quality (per-region IoU vs. ground truth?
      recomposition visual diff? both, as in `ai-baloons`'s human + automated metric approach?)
- [ ] **Character/environment library data model**: storage format and structure for a growing
      per-character/per-environment asset gallery — new convention, or reuse `.comics`-like
      packaging?
- [ ] **`.svg` vector export feasibility**: is auto-vectorization of extracted raster regions worth
      pursuing given most source material is photographic/painterly, not line art?
- [ ] **Full `.comics` output scope for the photo→`.comics` MVP specifically**: for pages that have
      a matched ground-truth source, is animation/sound simply copied from that match, or does the
      model need to (re)derive it independently? (Only fully generative scenarios, deferred, clearly
      need to synthesize animation/sound from nothing.)

## References

- `dataset/boranko/mahabharata/book1/comics_interactive/` — 27 existing `.comics` files (ground
  truth), `Comics_Episodes.csv`/`Comics.csv` (episode metadata; confirms episode 21 = `ambas_plea` =
  `8a89f7d689fb441ea280cd782276bd7a.comics`)
- `dataset/boranko/mahabharata/book1/comics_book_lowcamera/` — 80 camera photos of the printed book
- `dataset/boranko/mahabharata/book1/spiritual_text/` — narrative source text (deferred scenario)
- `dataset/boranko/mahabharata/book1/comics_interactive_baloons_translations/` — currently empty,
  reserved
- `flows/sdd-comics-ai-baloons/` — methodology precedent (structural dataset investigation before
  design; OCR+fuzzy matching; skip-and-log policy) and the `Kind`/`Style`/`Translations` layer-model
  additions
- `flows/vdd-comics-editor-jhanava/` — content-kind taxonomy (background/character/balloon/sound/
  motion-fx) and the "material cutting/systematization" concept this flow directly addresses
- `flows/sdd-comics-editor-questions/` — open question backlog on kind taxonomy and material intake
- `flows/vdd-comics-editor-uiux-lettering/` — `BalloonEditorCard`/`BalloonAiClient` human-review
  pattern to follow for future editor integration
- `flows/sdd-comics-editor-v2.9/02-specifications.md` and `apps/comics-editor/native/Comics.Editor/
  Models/` — live `.comics`/`Layer`/`Cultures` schema and editor architecture (headless core, NDJSON
  RPC, no plugin system, session-only undo/redo)

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-07-31
- [x] Notes: Approved as drafted (v0.1 content, promoted to 1.0).
