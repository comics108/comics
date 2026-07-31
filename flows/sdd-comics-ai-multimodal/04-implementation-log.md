# Implementation Log: comics-ai-multimodal

> Started: 2026-07-31
> Plan: [03-plan.md](03-plan.md)

## Progress Tracker

| Task | Status | Notes |
|------|--------|-------|
| 1.1 Python project scaffolding | Done | venv reuses global torch via `--system-site-packages` |
| 1.2 Reuse bridge to comics-ai-baloons | Done | Discovered + worked around a stale path bug in comics-ai-baloons |
| 2.1 Resting-position resolver | Done | Verified against real C# Anim/TranslateAnim/ScaleAnim/RotateAnim/AlphaAnim/PivotAnim source |
| 2.2 Kind inference heuristic | Done | Spot-checked visually; tuned `character_min_width` after finding a real false positive |
| 2.3 Checkpoint A | Done (finding: major pivot) | Falsified the whole-page-homography design; see Session below |
| 2.4 Full canvas compositor | Done | Verified on 3 real files + full 27-file batch, no crashes |
| ... | | |

**Specifications/Plan revised to 1.1 during this session** — see `02-specifications.md` "Revision
1.1" and `03-plan.md` Phase 3/5 — as a direct result of Task 2.3's finding.

## Session Log

### Session 2026-07-31 - Claude

**Started at**: Phase 1, Task 1.1
**Context**: Requirements/Specifications/Plan all approved this session; starting fresh
implementation.

#### Completed

- Task 1.1: Python project scaffolding
  - Files changed: `apps/comics-ai/comics-multimodal/requirements.txt`,
    `apps/comics-ai/comics-multimodal/.gitignore`, `apps/comics-ai/comics-multimodal/README.md`,
    `apps/comics-ai/comics-multimodal/.venv/` (gitignored)
  - Verified by: clean venv install succeeded; `import torch, torchvision, cv2, numpy, sklearn,
    skimage` + `from PIL import Image` all succeed; `torch.backends.mps.is_available()` is `True`
    (Apple GPU acceleration available for later training tasks)
  - Deviation from plan: created the venv with `--system-site-packages` so it could reuse an
    already-installed global `torch` (2.9.0) instead of re-downloading — disk had only ~31GB free
    (99% full disk). pip still pulled a newer `torch` (2.13.0) into the venv anyway to satisfy
    `torchvision`'s version constraint (~110MB download), but this kept the total install small
    (disk still shows 30GB free after full install).
- Task 1.2: Reuse bridge to `comics-ai-baloons`
  - Files changed: `apps/comics-ai/comics-multimodal/scripts/baloons_bridge.py`,
    `apps/comics-ai/comics-multimodal/tests/test_baloons_bridge.py`
  - Verified by: 4/4 tests pass, including a pixel-identical stitch comparison between the bridge
    and a direct `comics-ai-baloons` import, and a check that all 27 real dataset `.comics` files
    are discoverable via `rglob`

#### Discoveries

- **`comics-ai-baloons` has a real, currently-active bug**: its `REPO_ROOT = Path(__file__).
  parents[3]` computation (in `discover.py`, `tests/test_tiling.py`, and likely other modules)
  resolves to `apps/` instead of the true repo root. This is a stale off-by-one left over from
  before that app was nested under `apps/comics-ai/` (it used to live directly at
  `apps/comics-ai-baloons/`). Confirmed by running `comics-ai-baloons`'s own test suite: 2 of 4
  tests in `test_tiling.py` fail today with `FileNotFoundError` looking for
  `apps/dataset/8a89f7d689fb...comics`.
- **Separately**, the dataset itself was reorganized at some point from a flat `dataset/*.comics`
  layout to a nested one (`dataset/boranko/mahabharata/book1/comics_interactive/*.comics`) — even
  with the `REPO_ROOT` bug fixed, `comics-ai-baloons`'s hardcoded flat-path assumption would still
  break. Both issues together mean `comics-ai-baloons`'s pipeline (not just its tests) would fail
  to run today against the real dataset, despite that flow's status being "implementation complete,
  awaiting final sign-off."
- **This is out of scope to fix here** (a separate, already-approved flow) — flagged to the user
  directly. This pipeline's own code (`baloons_bridge.py`) works around both issues: it computes
  `REPO_ROOT` correctly (`parents[4]`, verified empirically) and locates `.comics` files via
  `rglob("*.comics")` rather than assuming a flat layout, so it isn't affected by either bug and
  won't break again if the dataset is reorganized further.
- Reused `comics-ai-baloons`'s flat-module-with-sys.path-injection convention (no package
  `__init__.py`) for consistency with its existing test style, rather than introducing a different
  import convention in the same repo.

**Ended at**: Phase 1, Task 1.2 (Phase 1 complete)
**Handoff notes**: Phase 2 (canvas reference & ground truth) is next. Task 2.3 (Checkpoint A) needs
real photos from `dataset/.../comics_book_lowcamera/` compared against a resting-position composite
— should use episode 21 (`ambas_plea`, `8a89f7d689fb441ea280cd782276bd7a.comics`) as one of the
comparison episodes since it's already a well-understood reference file.

---

### Session 2026-07-31 (continued) - Claude

**Started at**: Phase 2, Task 2.1

#### Completed

- Task 2.1: Resting-position resolver
  - Files changed: `apps/comics-ai/comics-multimodal/scripts/resting_position.py`,
    `apps/comics-ai/comics-multimodal/tests/test_resting_position.py`
  - Verified by: 6/6 tests pass, including a 4594-layer smoke test across every real dataset layer
    with no crashes, and three tests built from real (not synthesized) `data.json` fixtures
    (a multi-keyframe Translate+Alpha crossfade, a Rotate example, a Scale example with no
    AlphaAnim at all)
  - **Important correction vs. Specifications' framing**: read the actual C# `Anim`/`TranslateAnim`/
    `ScaleAnim`/`RotateAnim`/`AlphaAnim`/`PivotAnim` source
    (`apps/comics-editor/native/Comics.Editor/Models/`) rather than continuing to guess. The
    animation system is **scroll-position-driven**, not wall-clock-time-driven — `Start`/`End` on
    each keyframe are scroll-position (canvas y-pixel) bounds, matching the tall vertical-scroll
    canvas. `Anim.FindNearest`'s logic confirms "resting" = the last keyframe per Anim subtype
    (ordered by `Start`), which is what this resolver implements. Also confirmed real, non-obvious
    per-type defaults when a layer has *no* keyframes of a given type: `AlphaAnim.Init()` → alpha
    **1.0** (fully visible, not 0), `ScaleAnim.Init()` → scale **1.0/1.0** (not 0), `PivotAnim.
    Init()` → pivot **0.5/0.5** (normalized center). Missed defaults here would have silently made
    every non-animated layer invisible/zero-scaled in the canvas compositor (Task 2.4) — worth
    flagging since it's exactly the kind of bug that wouldn't show up until real images looked
    wrong.
- Task 2.2: Kind inference heuristic
  - Files changed: `apps/comics-ai/comics-multimodal/scripts/kind_heuristic.py`,
    `apps/comics-ai/comics-multimodal/tests/test_kind_heuristic.py`,
    `apps/comics-ai/comics-multimodal/scripts/baloons_bridge.py` (added `is_balloon_layer` as the
    single shared source of truth for the structural balloon rule)
  - Verified by: 5/5 tests pass; ran across all 27 real files (4594 layers) — balloon count came
    out to exactly 825, matching `comics-ai-baloons`'s independently-established total (strong
    cross-flow consistency signal); then did a real visual spot-check (Read tool on stitched PNGs
    from episode 21) rather than trusting the distribution numbers alone
  - **Spot-check findings** (as Specifications explicitly anticipated — this heuristic is not
    expected to be perfect): a thin walking-staff prop (106×597px) was misclassified `character`
    (portrait aspect ratio alone isn't enough to exclude narrow prop objects); a wide seated
    character in a horizontal pose (1052×946px) was misclassified `art` (aspect-ratio rule assumes
    upright/portrait framing); a bird-flock decorative overlay was misclassified `character` (same
    portrait-aspect blind spot). Fixed the first case by raising `character_min_width` from 60→150px
    (real characters in this dataset are never that narrow; verified the known-good "old man with
    staff" character example, 284px wide, still classifies correctly after the change — character
    count dropped 1012→874, i.e. ~138 thin-prop layers reclassified to `art`). Left the other two
    findings as documented, accepted approximation — per Specifications, `kind_source =
    "inferred_heuristic"` is meant to carry exactly this caveat downstream, and this heuristic's
    entire purpose is to bootstrap synthetic training labels for Phase 4's real segmentation model,
    not to be a final classifier itself.

**Ended at**: Phase 2, Task 2.2
**Handoff notes**: Task 2.3 (Checkpoint A) next — compare resting-position composites against real
`comics_book_lowcamera` photos before building the full Task 2.4 canvas renderer.

---

### Session 2026-07-31 (continued 2) - Claude

**Started at**: Phase 2, Task 2.3 (Checkpoint A)

#### Completed

- Task 2.3: Checkpoint A — visual inspection of real photos
  - Files changed: none (analysis task); downstream doc/plan edits below
  - Method: downscaled and visually read (Read tool) 4 real `comics_book_lowcamera/*.jpg` photos,
    including one specifically named-matchable one (a title-card photo reading "AMBA'S CURSE",
    heavily motion-blurred) and 3 random samples
  - **Finding (major, invalidates a Specifications/Plan design decision)**: the printed book is a
    **conventionally paginated comic** — fixed rectangular panel grids, real printed page numbers
    (28/29, 194/198, 10 seen across the 4 samples), two-page spreads — **not** a photographed
    rectangular crop of the tall (~33000px) scrolling digital canvas the `.comics` files use. Page
    numbers running to 198+ also indicate the print book covers substantially more content than the
    27 digitized interactive episodes. This directly falsifies Specifications' stage [4]
    ("Align Photo to Canvas" via ORB/SIFT keypoint matching + homography onto a canvas y-range) and
    Plan Task 5.1/5.2 as originally written — there is no rigid crop+perspective-warp relationship
    between a printed page and any canvas region, because the print edition independently
    re-composes the same story into a different panel grid.
  - Raised this to the user directly (AskUserQuestion) rather than silently reworking the
    architecture or quietly forcing the original design to "work" against evidence it plainly
    contradicts. User confirmed: pivot to **per-panel content-based matching** (detect panels on the
    page, OCR each panel's balloon text, fuzzy-match against `comics-ai-baloons`'s own per-balloon
    OCR corpus — the same content-based, skip+log-not-guess principle already used for CSV matching
    in that flow, just applied at panel instead of page granularity, and against a different corpus).
  - **Documents updated as a result** (both bumped to v1.1, both re-approved by the user for the
    delta): `02-specifications.md` (new "Revision 1.1" note; revised Component Diagram, Data Flow
    stages 2 and 4, `PanelBox`/`PanelAlignmentResult` replacing the page-level `AlignmentResult`,
    revised stage [4]/[5-6] behavior detail, revised Edge Cases, revised/added Open Design
    Questions, second Approval block) and `03-plan.md` (Task 3.2 now crops per-local-cluster
    "panel-shaped" regions instead of arbitrary canvas windows; Phase 5 tasks rewritten for panel
    detection + content matching instead of page homography; Task 6.2 evaluation now compares
    against a matched local cluster, not a homography-mapped rectangle; Risk Assessment updated).
  - Also confirmed a secondary fact worth remembering: `comics-ai-baloons`'s OCR corpus
    (`work/ocr.jsonl`) is a **cross-flow dependency** for the new Task 5.2 — it needs to actually
    exist (i.e. that pipeline's early stages need to have been run) before panel matching can work;
    flagged in the revised Task 5.2 as something to verify at the start of that task, not assume.

#### Deviations from Plan

- Phase 5's entire approach (page-level ORB/SIFT homography against the canvas) replaced with
  panel-level OCR+fuzzy-text matching against `comics-ai-baloons`'s balloon corpus. Reason: real
  data directly contradicted the original design's core assumption (see Finding above). This is
  exactly the kind of thing Checkpoint A was placed in the Plan to catch before over-investing in
  the wrong direction — it did its job.
- Task 3.2 (synthetic degradation) revised to crop panel-shaped local clusters instead of arbitrary
  canvas windows, so synthetic training data resembles what real photos actually contain.

**Ended at**: Phase 2, Task 2.3 (Specifications/Plan revision to v1.1 complete and re-approved)
**Handoff notes**: Task 2.4 (full canvas compositor) is next, and is **unaffected in its own right**
by this pivot — it's still needed exactly as designed, both for ground truth and as the source for
Task 3.2's (now panel-shaped) synthetic crops. Phase 5 implementation, when reached, should start by
confirming `comics-ai-baloons`'s `work/ocr.jsonl` exists/is current before building panel matching
against it.

---

### Session 2026-07-31 (continued 3) - Claude

**Started at**: Phase 2, Task 2.4

#### Completed

- Task 2.4: Full canvas compositor + ground-truth emitter — **Phase 2 now complete**
  - Files changed: `apps/comics-ai/comics-multimodal/scripts/render_canvas.py`,
    `apps/comics-ai/comics-multimodal/tests/test_render_canvas.py`
  - Verified by: 3/3 tests pass, including a fully-controlled synthetic fixture (hand-built 3-layer
    `.comics` zip) proving exact pixel-level compositing correctness (background placement,
    translated-layer placement, and — importantly — that a layer whose resting alpha resolves to 0
    is correctly excluded from both the composite and the ground-truth regions) and a real-data
    integration test (composite dimensions match `data.json`'s declared width/height, region count
    is sane)
  - **Full batch run over all 27 real dataset files**: completed cleanly in ~2m20s, no crashes, no
    exceptions. Canvas heights ranged 12,000–100,900px; region counts 86–297 per file. Output:
    `apps/comics-ai/comics-multimodal/work/canvas/` (618MB — fine within the ~30GB free disk budget,
    but worth remembering as this grows during Phase 3's augmentation step).
  - **Visual spot-check (3 different files, not just the one used throughout earlier tasks)**:
    read full-resolution detail crops of the episode-21 composite (`8a89f7d689fb...`, confirmed
    legible balloon text: "AND AMBA TOLD PARASHURAMA ABOUT ALL THE HARDSHIPS SHE HAD FACED WITH
    BHISHMA" plus dialogue, correctly composited over/around characters and a hut scene, with the
    earlier-identified bird-flock overlay visible in its correct position) and two more files
    (`96d4fcd2f634...`, a temple/smoke scene with narration captions; `f1976dc80cee...`, a
    night-sky/moon scene with dialogue) — all render as coherent, readable comic pages with no
    positional artifacts, missing chunks, or double-exposure bugs. This is strong, real-data
    confirmation that the resting-position resolver (Task 2.1, grounded in the actual C# animation
    source) and the compositor's layer ordering/alpha/scale handling are all correct in practice, not
    just in unit tests.
  - Known, documented simplifications carried into the code's own docstring (not silently dropped):
    rotation is not applied (rare in this dataset, small angles where present); compositing uses
    mask-based `paste`, not true alpha-over blending (fine for training-data synthesis, not claimed
    pixel-identical to the real editor).

#### Deviations from Plan

- None beyond the Revision 1.1 pivot already logged above.

**Ended at**: Phase 2 complete (Tasks 2.1-2.4 all done and verified)
**Handoff notes**: Phase 3 (synthetic training data) is next, using the now-revised Task 3.2 design
(panel-shaped local-cluster crops, not arbitrary canvas windows). This is a natural pause point —
Phase 1-2 delivered and verified a solid, real-data-tested foundation (bridge to comics-ai-baloons,
resting-position resolver grounded in actual editor source, kind-inference heuristic spot-checked
and tuned, full canvas+ground-truth compositor verified visually across 3 files and batch-run across
all 27) — before committing to Phase 3+ which starts involving actual model training (much longer,
more experimental, harder to checkpoint mid-task).

---

### Session 2026-07-31 (continued 4) - Claude

**Started at**: Phase 3, Task 3.1

#### Completed

- Task 3.1 (Checkpoint B): `analyze_photos.py` measured all 80 real `comics_book_lowcamera/*.jpg`
  photos — sharpness (Laplacian variance): min 67.7, p25 348, median 640, p75 950, max 1514; noise
  sigma (Immerkær estimator): min 0.72, p25 1.33, median 2.58, p75 3.20, max 5.93; all confirmed
  4080x3060 (or 3060x4080 rotated). These real measurements, not guesses, directly parameterize
  Task 3.2's degradation ranges.
- Task 3.2: Synthetic degradation pipeline (`augment.py`) — crops panel-shaped local content
  clusters (revised per the Checkpoint A pivot) and applies calibrated camera-realism degradation
  (perspective warp, vignette, blur, noise, JPEG re-compression).
  - **Found and fixed a real bug during verification, not just before it**: the first clustering
    approach (simple y-window transitive chaining, matching the *original* Task 3.2 design before
    Revision 1.1) was tried first and produced median cluster height 15,300px with up to 206 layers
    per cluster on the real dataset — giant multi-scene mega-clusters, nothing like a panel. Fixed
    by re-designing clustering to anchor on `kind == "background"` layers (a new background reliably
    marks a new scene in this dataset) with a defensive 3000px max-height re-split for sparse
    stretches — `cluster_layers_by_scene`, replacing the deprecated `cluster_layers_by_y` (kept only
    for its still-useful transitive-chaining unit tests).
  - **Found and fixed a second, subtler bug** in that same re-split fallback: it originally chained
    regions by center-to-center y-distance, which under-counts real bbox extent when individual
    regions have their own height — verified this let real clusters reach up to 9534px despite every
    center-distance check passing. Fixed by checking the tentative *union bbox* on each candidate
    addition instead. Added a regression test (`test_cluster_layers_by_scene_bounds_true_bbox_not_
    just_center_distance`) that specifically exercises this compounding-extent scenario.
  - **Final verified real-dataset run** (all 27 canvases): 753 training pairs; cluster height
    median 2653px (cap 3000px), p75 2957px; of 145/753 clusters still exceeding the cap, **all 145
    are single unsplittable oversized background-art layers** (explicitly verified: 0 multi-layer
    clusters exceed the cap) — the documented, acceptable edge case, not a residual bug.
  - Visual spot-check: read a real clean/degraded pair (a bird-flock overlay crop from episode 21)
    — the degraded version shows clearly visible perspective warp, vignette darkening, and blur/
    grain closely resembling the real motion-blurred book-cover photo seen back at Checkpoint A,
    while the underlying content stays recognizable.
  - Also fixed a `DecompressionBombWarning` (our own composites legitimately exceed PIL's default
    89M-pixel threshold at up to ~109M pixels) by setting `Image.MAX_IMAGE_PIXELS = None` in both
    `render_canvas.py` and `augment.py` (trusted local data, not user-uploaded content).
- Task 3.3: `dataset.py` — a `torch.utils.data.Dataset` wrapping the manifest, yielding
  (image tensor, target dict) pairs in the list-of-dicts shape torchvision's detection models
  expect. `collate_fn` returns parallel lists rather than a stacked tensor (variable image sizes/
  region counts can't be stacked) — matches the shape Task 4.x's Mask R-CNN option needs directly.

#### Verification

- 32/32 tests pass across the whole app (`baloons_bridge`, `resting_position`, `kind_heuristic`,
  `render_canvas`, `augment`, `dataset`), including full real-data integration tests for each stage.
- Disk usage: `work/canvas/` 618MB + `work/train_pairs/` ~1.2GB — comfortably within the ~28GB free
  budget.

#### Deviations from Plan

- Task 3.2's clustering approach changed twice during verification (see above) — both changes were
  driven by actually running the pipeline against real data and inspecting the result, not
  discovered by inspection/review alone. This is the same "verify against real data, don't guess"
  discipline the whole flow has followed since Requirements.

**Ended at**: Phase 3 complete (Tasks 3.1-3.3 all done and verified)
**Handoff notes**: Phase 4 (segmentation model: baseline U-Net first, then Mask R-CNN per the Plan's
Task 4.1 decision) is next — this is real model training, a longer and more experimental undertaking
than anything so far in this flow. `work/train_pairs/manifest.jsonl` (753 pairs) is ready to train
against.

---

## Deviations Summary

| Planned | Actual | Reason |
|---------|--------|--------|
| Task 1.1: fresh venv install | `--system-site-packages` venv reusing global torch | Disk space was very tight (31GB free); avoided a redundant multi-hundred-MB download where possible |

## Learnings

- Always verify cross-flow integration assumptions empirically (ran `comics-ai-baloons`'s actual
  test suite) rather than trusting its Specifications doc's claims at face value — that doc was
  accurate as of its own approval date, but the dataset/directory layout has since drifted.

## Completion Checklist

- [ ] All tasks completed or explicitly deferred
- [ ] Tests passing
- [ ] No regressions
- [ ] Documentation updated if needed
- [ ] Status updated to COMPLETE
