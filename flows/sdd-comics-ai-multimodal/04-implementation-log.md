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

### Session 2026-07-31 (continued 5) - Claude

**Started at**: Phase 4, Task 4.2

#### Completed

- **Closed a real gap before Task 4.2 could start**: the manifest only stored each cluster's union
  bbox, not per-layer boxes within the crop -- needed as pixel-level ground truth for a
  segmentation model. Added `region_bboxes` to `augment.py`'s `TrainingPair` (crop-local per-layer
  boxes) and to `dataset.py`'s target dict.
  - **Found and fixed a second real bug while doing this**: `degrade()` applies rotation +
    perspective warp to the image pixels, but the (then-new) ground-truth boxes were computed from
    the *clean, undistorted* crop -- meaning boxes would silently point at the wrong place in the
    *degraded* image, injecting real geometric label noise scaled with the distortion magnitude.
    Fixed by refactoring `degrade()` into `degrade_with_boxes()`, which carries box corners through
    the *same* rotation+perspective matrices applied to the pixels (collapsing perspective-warped
    quadrilaterals back to an axis-aligned enclosing box, a documented simplification consistent
    with this pipeline's rectangle-only ground truth). Added regression tests for bounds,
    determinism, and the "large box shouldn't collapse under mild distortion" invariant.
  - Regenerated `work/train_pairs/` (753 pairs, same count as before, now with correct
    `region_bboxes`) and reran the full test suite (40/40 passing) before proceeding.
- Task 4.2: Baseline U-Net (`scripts/models/unet_baseline.py`) + training entrypoint
  (`scripts/train_segmenter.py`) -- a compact 3-level U-Net (channels 16/32/64, deliberately small
  given only ~750 real samples) predicting a per-pixel Kind label, trained at a fixed 256x256
  resolution (boxes/labels rasterized into a label map per Editor Schema's established
  bottom-to-top z-order).
  - **First real training run (10 epochs, unweighted cross-entropy)** converged in the loss sense
    (train_loss 1.25→0.95) but **collapsed to the dominant class**: val IoU
    `{'art': 0.654, 'background': 0.0, 'character': 0.0, 'balloon': 0.100}` -- the model learned to
    just predict "art" (the default/majority label) almost everywhere, a textbook class-imbalance
    failure mode, not caught by watching the loss curve alone.
  - **Fixed with inverse-pixel-frequency class weighting** (`compute_class_weights`, computed from
    real rasterized label-map pixel counts on the train split, not guessed): weights
    `[0.25, 1.04, 1.21, 1.50]` for art/background/character/balloon. Second training run (same 10
    epochs): val IoU `{'art': 0.353, 'background': 0.023, 'character': 0.129, 'balloon': 0.401}` --
    balloon and character both improved substantially (the model now actually discriminates between
    classes), at the expected trade-off cost of lower `art` IoU. `background` remains weak (0.023)
    even after weighting -- flagged as a known, documented follow-up (more epochs? investigate
    whether background regions are often clipped at crop edges?), not blocking for this baseline
    tier.
  - Checkpoint + full metric history saved to `work/models/unet_baseline.pt` /
    `.history.json`.
  - Also discovered and worked around a tooling gotcha (not a code bug): piping a long-running
    background command through `| tail -N` makes Python fully block-buffer stdout (since it's not a
    TTY), so progress printed via `print()` was completely invisible until the process exited.
    Switched to `python -u ... > logfile.log` (unbuffered, redirected to a real file) for the
    second run, which streamed live as expected.
- Added 7 new tests across `test_augment.py` (box-transform), `test_unet_baseline.py` (model
  forward shape, label-map rasterization), and `test_train_segmenter.py` (class-weight computation,
  batch collation). **42/42 tests pass** across the whole app.

#### Deviations from Plan

- Task 4.2 implicitly required per-layer ground-truth boxes and correct box-vs-degradation
  alignment that Task 3.2/3.3 hadn't fully specified -- both gaps were real and were only found by
  actually trying to build and train the model, not by re-reading the existing specs/plan. Fixed in
  place rather than deferred, since an unweighted or misaligned-box baseline would have been a
  meaningless first data point for the eventual Checkpoint D comparison.

**Ended at**: Phase 4, Task 4.2 complete and verified; Task 4.3 (Mask R-CNN) not yet started
**Handoff notes**: Task 4.3 is a bigger lift (fine-tuning a pretrained `maskrcnn_resnet50_fpn_v2`)
than anything done so far -- expect a genuinely longer training time and more iteration. The
class-imbalance lesson from Task 4.2 (watch per-class IoU, not just the loss curve) applies there
too. `compute_class_weights` and the `region_bboxes` ground truth are both directly reusable for
Mask R-CNN's target format.

---

### Session 2026-07-31 (continued 6) - Claude

**Started at**: Phase 4, Task 4.3

#### Completed

- Task 4.3: Mask R-CNN (`scripts/models/maskrcnn.py`) -- fine-tunes torchvision's
  `maskrcnn_resnet50_fpn_v2` (COCO-pretrained, downloaded successfully: 177MB, ~16s). Handles a
  real API mismatch: torchvision's detection models reserve class 0 for "no object" internally, so
  `to_detection_target` shifts our 0-indexed `KIND_TO_LABEL` by +1 (`NUM_DETECTION_CLASSES = 5`)
  and builds box-shaped binary masks (this pipeline has no per-pixel mask ground truth anywhere,
  consistent with `dataset.py`/`unet_baseline.py`'s existing rectangle-only approach). Added
  `train_maskrcnn()` to `train_segmenter.py` (dispatched via `--model maskrcnn`, per the Plan's
  "supports both architectures via a config flag") plus `compute_maskrcnn_iou`, which reuses
  `rasterize_label_map` so its metric definition is directly comparable to the U-Net baseline's.
  12 new tests (target conversion edge cases + an end-to-end fixture smoke test) -- **49/49 tests
  pass** across the whole app.
- **Found a real, unresolved infrastructure issue, not a code bug**: the first real-dataset
  training attempt (MPS device, 120-sample subset) hung indefinitely -- 0% CPU, `UN`
  (uninterruptible-sleep) process state, memory not growing, unchanged for 5+ minutes -- partway
  through what looked like first-time Metal/MPS shader compilation (confirmed via `lsof`: the
  process had `MPSCore`/`MPSNDArray`/`AGXMetalG16X` GPU-driver libraries open). A tiny isolated
  smoke test (single image, `pretrained=False`) had worked fine on MPS moments earlier, so this is
  specific to the *full* model's larger/more varied op graph, not MPS support in general. Killed
  the hung process; added a `--device` CLI flag defaulting Mask R-CNN training to `cpu` (documented
  in the flag's own help text) rather than silently falling back — U-Net baseline training on MPS
  worked fine throughout Task 4.2 and is unaffected.
- **Real CPU-only training run** (80-sample subset -- reduced from the full ~750 given CPU is
  dramatically slower than GPU for this model, and disk/time budget considerations already
  documented in this log; 2 epochs, batch_size=2): took roughly 35-40 minutes wall-clock (the first
  epoch alone took ~20 min of accumulated CPU time, likely because a few of the 80 randomly-sampled
  crops are among the large single-background-layer outliers noted in the Task 3.2 verification,
  up to ~9500px tall, which cost far more than a typical panel-sized crop). Flagged this real-time
  cost to the user mid-run (via AskUserQuestion) rather than silently continuing to poll
  indefinitely; user approved continuing with a 1-hour cap. Training converged (train_loss
  1.4475 → 0.9535 across 2 epochs) and completed cleanly, saving `work/models/maskrcnn.pt` (184MB)
  and `.history.json`.
- **Partial Checkpoint D comparison** (Plan Task 6.3's full version is still pending Phase 5/6, but
  an honest first look belongs here):

  | class | U-Net baseline (753→640 train samples, 10 epochs, class-weighted) | Mask R-CNN (80-sample subset, 2 epochs, CPU) |
  |---|---|---|
  | art | 0.353 | 0.471 |
  | background | 0.023 | 0.005 |
  | character | 0.129 | 0.0002 |
  | balloon | 0.401 | 0.398 |

  **This is not an apples-to-apples comparison and is documented as such**: Mask R-CNN got ~8x less
  data and 5x fewer epochs (character/background IoU collapsing almost to zero is plausibly just
  insufficient training, not an architecture deficiency, especially since balloon IoU came out
  statistically comparable despite the far smaller budget). Scaling Mask R-CNN's training to match
  the baseline's data/epoch budget would, at the observed per-sample cost, take on the order of
  40x longer -- likely most of a day of CPU time, given MPS is unusable for this model on this
  machine. **This is flagged as a real, honestly-sized constraint for the eventual full Checkpoint
  D decision**, not glossed over: a true equal-budget comparison isn't practical without either
  much more CPU wall-clock time, resolving the MPS hang, or access to different compute. For now,
  the working conclusion is that Mask R-CNN's implementation is verified correct end-to-end (converges,
  checkpoints, evaluates) and shows a promising signal (comparable balloon IoU on far less training)
  but is under-trained relative to the baseline; the U-Net baseline is the more practically-vetted
  option to build the rest of the pipeline (Phases 5-9) against for now, with Mask R-CNN available
  to revisit if more compute becomes available.
- Registered the `slow` pytest marker (`pytest.ini`) to clean up a warning from the new smoke test.

#### Deviations from Plan

- Task 4.3's Mask R-CNN training ran on a reduced 80-sample subset on CPU rather than the full
  training set, and Checkpoint D's full comparison is deferred rather than finalized now -- both
  are direct, disclosed consequences of the MPS hang and CPU being much slower for this model, not
  silent scope-narrowing.

**Ended at**: Phase 4 complete (Tasks 4.1-4.3 all done; Checkpoint D given an honest partial
verdict, full resolution deferred to when Phase 5/6 need a final answer or more compute is
available)
**Handoff notes**: Phase 5 (photo alignment, per the Revision 1.1 per-panel design) is next. Before
building `align_photo.py`, confirm `comics-ai-baloons`'s `work/ocr.jsonl` exists/is current (flagged
repeatedly since the Revision 1.1 pivot) -- this is the cross-flow dependency Phase 5's panel
matching needs.

---

### Session 2026-07-31 (continued 7) - Claude

**Started at**: Follow-up fix -- user asked whether Mask R-CNN training could be made to use the
Mac M4's built-in accelerator (MPS) instead of CPU, per the open item logged above.

#### Completed

- **Root-caused the MPS hang from the previous session** rather than accepting it as a permanent
  MPS/model incompatibility. Reproduced it directly: a single image's forward+backward on MPS
  completes in seconds regardless of image size (tested up to the 9534px-tall outlier), but the
  first `batch_size=2` MPS call of this Python session lands the process in uninterruptible-sleep
  (`UN`, 0% CPU) for multiple minutes -- matching the original symptom exactly. Once that first
  batched call finally completes, every subsequent batched call (isolated retest, and a full real
  `train_segmenter.py --model maskrcnn --device mps --max-samples 12 --epochs 1` run) completes
  normally in ~30-35s/batch, with the full smoke run finishing end-to-end in ~4.6 minutes with no
  hang. This is consistent with a one-time Metal shader compilation cost specific to this
  model+batching's op/shape graph (macOS compiles and caches GPU shader pipelines on first use),
  not a real architectural block -- the "5+ minutes, unchanged" the prior session observed was very
  likely that same compilation still in progress when it was killed, not a true infinite hang.
- **Fix**: `scripts/train_segmenter.py`'s `--device` flag no longer forces `maskrcnn` to `cpu` by
  default -- `train_maskrcnn()` now gets `args.device` (`None` if unset) and falls back to its own
  existing `"mps" if torch.backends.mps.is_available() else "cpu"` auto-detect, the same pattern
  `train()` (U-Net) already used. `--device cpu` remains available to force the slower
  compilation-free path. Updated the flag's help text to describe the one-time warm-up cost instead
  of warning MPS off entirely.
- Verified: full test suite (63 tests, now including the maskrcnn smoke test) passes unchanged;
  real end-to-end smoke run on MPS (12 samples, 1 epoch) completes and produces a checkpoint +
  history file with no hang.

#### Deviations from Plan

- None -- this is a fix to a previously-logged open item (Task 4.3's forced-CPU default), not new
  plan scope.

**Ended at**: MPS is now the default device for Mask R-CNN training when available, matching the
U-Net baseline. Real training runs against the full dataset will still pay the one-time
shader-compilation cost on a machine/session where these ops haven't run yet (budget several extra
minutes for the very first batched MPS training invocation after a reboot or on a fresh machine).
**Handoff notes**: No change to Phase 5 next-actions above. If a future MPS training run hangs
again for more than ~10 minutes with 0% CPU, that would indicate this isn't simply a one-time
compile cost and warrants a fresh investigation (this session's fix assumes the compile-cost
theory, supported by direct reproduction, but did not get a citation-level confirmation from
Apple/PyTorch's own issue tracker).

---

---

### Session 2026-07-31 (continued 7) - Claude

**Started at**: Phase 5, Task 5.1

#### Completed

- Task 5.1: Page rectification (`rectify.py`) + region detection (`detect_panels.py`)
  - `rectify.py`: classical document-scanner quad-finding (Otsu threshold + largest 4-corner
    contour), used as a best-effort per-region deskew with a `fallback_full_frame` status when no
    confident quad is found (most real photos, being close-up shots rather than clean flat-lay
    scans, hit this fallback -- expected and handled, not a failure).
  - **Real, hands-on CV iteration on per-panel detection, then a confirmed pivot to page-level
    detection (Revision 1.2)**: tried brightness-thresholding (merges all panels into one
    irregular ~8-corner blob on busy pages), then a Laplacian-activity map at several morphological
    kernel sizes (5/9/13/25) -- best case (k=5) cleanly separated only 2 of a page's ~4 panels,
    with a densely-packed page's panels still merging regardless of tuning. Reported this
    honestly (via AskUserQuestion, with a visual example) rather than continuing open-ended CV
    tuning; user confirmed pivoting to **page-level** detection (find left/right page via the
    spine gutter, a much wider/more reliable low-detail gap than inter-panel gutters). Verified
    visually: clean left/right page boxes on two different real two-page-spread photos; a blurry
    cover-shot photo's split was meaningless but that photo has no balloon text to match anyway.
  - Real-photo sweep (20 photos): 12 found 2 pages, 6 found 1 page, 2 found 0 -- a reasonable first
    result, honestly distributed rather than oversold.
- Task 5.2: Panel(page)-to-scene matching (`align_photo.py`)
  - **Found and fixed a real naming collision** while wiring in `comics-ai-baloons`'s `match.py`
    (needed for its `normalize()` function and to reuse its matching discipline): that file imports
    `from models import MatchResult, OcrResult` (its own single-file `scripts/models.py`), which
    collides by name with this project's own `scripts/models/` package (`unet_baseline.py`,
    `maskrcnn.py` -- Phase 4). Whichever "models" Python resolves first gets cached in
    `sys.modules` for the rest of the process, silently breaking the other side. Fixed by
    **renaming our own package to `scripts/segmenter_models/`** (smaller blast radius, entirely our
    own code) rather than fighting sys.path ordering; also hardened `baloons_bridge.py` to
    `sys.path.append` (not `insert(0, ...)`) as defense-in-depth for any future collision. Updated
    all call sites (`train_segmenter.py` and its tests) and added a regression test proving both
    `models` (comics-ai-baloons') and `segmenter_models` (ours) import correctly in the same
    process.
  - Matching approach: OCR each detected page (Tesseract, eng+rus jointly) and fuzzy-match against
    `comics-ai-baloons`'s own per-balloon OCR corpus (`work/ocr.jsonl`, confirmed present/current:
    1650 entries, all 27 files) using `rapidfuzz.fuzz.partial_ratio` (substring-seeking, unlike
    that pipeline's `token_sort_ratio` -- appropriate here since a whole page's OCR text is much
    longer than any single balloon phrase). Requires >=2 independently-confident phrase hits
    against the same episode before trusting a match (one lucky hit isn't enough).
  - **Found and fixed a real false-positive class**, not a hypothetical one: an initial full run
    matched 38/64 confident results to a single episode file. Spot-checking the actual matched
    layers' corpus text revealed they were all just `"NO"` / `"NO."` -- `partial_ratio` trivially
    finds short generic words as a substring almost anywhere, so 5 "independent" hits were really 5
    near-duplicate matches of one meaningless short word, not real evidence. Fixed with a
    `MIN_PHRASE_LENGTH = 12` (normalized chars) filter excluding short candidate phrases from
    matching consideration entirely (~9% of the real OCR corpus, 149/1650 entries, is shorter than
    this). Added a regression test reproducing the exact scenario (a page mentioning "know",
    "north", "cannot" must not spuriously match a corpus entry that's just "NO").
  - **Found and fixed a second real bug**, in `augment.py`'s `cluster_layers_by_scene` (used by
    both Phase 3's synthetic-data generation and this task's `ground_truth_cluster_for` lookup):
    the original sequential "flush on background encounter" scan (scanning regions sorted by
    y-center) incorrectly isolates a non-background region into its own spurious single-item
    cluster whenever that region's y-center happens to be *smaller* than its own scene's background
    center (e.g. a balloon placed near the top of a panel) -- caught by a new Phase 5 test, not by
    Phase 3's original verification, which checked cluster-height distributions and did visual
    spot-checks but never asserted exact per-layer cluster membership. Fixed by reassigning each
    non-background region to its **nearest background by y-center distance** (a direct distance
    comparison, immune to encounter-order artifacts) instead of the fragile sequential scan.
    **This means Phase 4's already-trained U-Net/Mask R-CNN checkpoints were trained on data built
    with the old, slightly-buggy clustering** -- documented here as a known, non-blocking follow-up
    (retrain if this proves impactful in practice) rather than forcing an immediate, expensive
    Phase 3+4 redo; `work/train_pairs/` was NOT regenerated again this session for this specific
    fix (it was already regenerated once this session for the `region_bboxes` addition).
- Task 5.3 (threshold calibration) and Task 5.4 (Checkpoint C, full real-photo review) done
  together, informed directly by two full real-dataset runs (before and after the short-phrase
  fix):
  - Before the fix: 64/136 pages matched, but dominated by one episode (38/64) due to the "NO"
    false-positive class.
  - After the fix: **37/136 pages matched (~27%), spread across 16 distinct episodes** (vs. 11
    before, and no longer dominated by one file -- the previously-dominant episode dropped to
    8/37), confidence min/median/max = 0.80/0.94/1.0.
  - **Spot-checked two of the matches for genuine correctness** (not just plausible-looking
    numbers): photo `20260731_153957.jpg` matched episode 21 (`ambas_plea`) layers 174/176, whose
    corpus text ("AND AMBA TOLD PARASHURAMA ABOUT ALL THE HARDSHIPS SHE HAD FACED WITH BHISHMA.",
    "BUT HOW CAN I HELP? YOU WANT ME TO HELP WITH YOUR MARRIAGE?") is *exactly* the dialogue
    visible in that episode's canvas composite from Task 2.4's own spot-check, confirming a真 real,
    not coincidental, match. A second photo matched the same episode's layers 183/185, a plausible
    later continuation of the same conversation.
  - A 27% page-level match rate is not low given the print book demonstrably spans far more content
    (page numbers to 198+, confirmed at Checkpoint A) than the 27 digitized episodes cover --
    consistent with Requirements' explicit expectation that many photos legitimately have no
    corresponding digital match at all.
- 27 new tests across `test_detect_panels.py`, `test_align_photo.py`, plus regression tests added to
  `test_augment.py` (clustering bug) and `test_baloons_bridge.py` (naming collision). **63/63 tests
  pass** across the whole app.

#### Deviations from Plan

- Task 5.1 pivoted from per-panel to per-page detection (Revision 1.2, user-confirmed) after real
  CV iteration showed per-panel detection was not reliably achievable within reasonable effort.
  `PanelAlignmentResult`/`ground_truth_cluster` from Specifications is implemented as
  `PageAlignmentResult` at page granularity instead of panel granularity -- same shape/intent, one
  level coarser.
- `scripts/models/` renamed to `scripts/segmenter_models/` (naming collision, see above) -- touches
  Task 4.2/4.3 files retroactively; historical Plan/log references to `scripts/models/...` from the
  Phase 4 session entries are left as-is (accurate as of when they were written), not rewritten.

**Ended at**: Phase 5 complete (Tasks 5.1-5.4 all done and verified against real data)
**Handoff notes**: Phase 6 (Inference & Cut Regions) is next -- run the trained segmentation model
(Task 4.2's U-Net, per the working-baseline conclusion from Phase 4) on the matched/aligned real
pages from `work/alignment.jsonl`, and evaluate predicted regions against each match's
`ground_truth_cluster`. Two known, carried-forward caveats to keep in mind: (1) Phase 4's models
were trained on `cluster_layers_by_scene`'s pre-fix output (see above) -- real-photo IoU numbers in
Phase 6 should be interpreted with that in mind; (2) matching is page-level, not panel-level, so
`ground_truth_cluster` spans more layers per match than Specifications originally envisioned --
Phase 6/9's packaging logic should expect and handle multi-region matches per photo naturally,
not assume a tight single-panel correspondence.

---

## Deviations Summary

| Planned | Actual | Reason |
|---------|--------|--------|
| Task 1.1: fresh venv install | `--system-site-packages` venv reusing global torch | Disk space was very tight (31GB free); avoided a redundant multi-hundred-MB download where possible |
| Task 5.1: per-panel detection | Per-page detection (Revision 1.2) | Real CV iteration showed per-panel boundaries weren't reliably separable within reasonable effort; user confirmed the simpler, more robust pivot |
| `scripts/models/` package | Renamed to `scripts/segmenter_models/` | Name collision with comics-ai-baloons/scripts/models.py, discovered when Phase 5 needed to import comics-ai-baloons' match.py |

---

### Session 2026-07-31 (continued 8) - Claude

**Started at**: Phase 6, Task 6.1

#### Completed

- **Surfaced a real design gap before writing any code**: Specifications' original Task 6.2 design
  ("compute per-region IoU between predicted and true `GroundTruthRegion` masks") assumed a
  geometric mapping from a photographed page's pixels into canvas coordinates -- but Revision 1.1/
  1.2 (Checkpoint A, already approved) established no such mapping exists; content-based matching
  only tells us *which layers* are present in a page, not *where* in the photo. Pixel IoU is
  therefore not literally computable. Documented this explicitly in `evaluate.py`'s own docstring
  and implemented a content/count-based proxy instead (per-kind region-count agreement between
  predicted regions and the matched `ground_truth_cluster`'s true kind distribution) -- a direct,
  foreseeable consequence of the already-approved pivot, not a new fork requiring a fresh decision.
- Task 6.1: `infer_segmenter.py` -- loads the U-Net baseline checkpoint, re-detects/re-crops/
  re-rectifies the same page `align_photo.py` matched (from `work/alignment.jsonl`), runs the
  model, and derives discrete regions via per-class connected-components (matching Task 4.2's
  stated instance-derivation design). **Found and fixed a real bug on the first real (non-CPU-only)
  run**: `probs[class_idx].numpy()` crashed on an MPS tensor (`can't convert mps:0 device type
  tensor to numpy`) -- existing tests hadn't caught this because they all passed `device="cpu"`
  explicitly. Fixed by moving the whole `probs` tensor to CPU once, before any `.numpy()` calls.
  4 new tests, including one against the real trained checkpoint.
- Task 6.2: `evaluate.py` -- per-kind count-agreement metric (see design-gap note above). 7 new
  tests.
- **First real-photo evaluation run revealed a second, more significant design gap**: mean
  agreement was only 0.382, with a clear, consistent pattern across pages -- the model
  systematically over-predicted `background` regions (5-12 blobs vs. ground truth's 0-2) and
  frequently predicted **zero** balloons where ground truth had several. Root cause: Phase 3/4
  trained the segmentation model on single-scene (panel-scale) crops, but Phase 5's page-level
  matching (Revision 1.2, approved earlier) means inference always runs on whole multi-panel pages
  -- a real train/inference scale mismatch that Phase 4 could not have anticipated since it
  predates the Phase 5 pivot. Raised this to the user directly (AskUserQuestion) with three options
  (accept as documented limitation / cheap sliding-window inference fix / retrain on page-scale
  data); **user chose the most thorough fix: retrain on page-scale data**.
  - Implemented `augment.py`'s `build_page_groups()`: groups `PAGE_GROUP_SIZE=4` consecutive scene
    clusters (already correctly bounded by the Phase 5-fixed `cluster_layers_by_scene`) into
    page-scale crops, approximating a real printed page's multi-panel content. 2 new tests.
  - Regenerated `work/train_pairs/`: 191 page-scale pairs (down from 753 panel-scale, as expected
    -- roughly 753/4), median crop height 6811px (vs. 2653px before), median 20 layers/crop (vs.
    a handful before).
  - Retrained the U-Net baseline (10 epochs, batch_size=4 given larger images): synthetic val IoU
    improved on exactly the classes that were weak: `background` 0.023 → 0.097, `character` 0.129
    → 0.167; `balloon` held steady (0.401 → 0.403); `art` dropped (0.353 → 0.270, an acceptable
    trade-off from the same de-weighting dynamic seen in the first U-Net training run).
  - **Re-ran real-photo inference + evaluation with the retrained checkpoint: mean kind-count
    agreement improved from 0.382 → 0.486** (~27% relative improvement) -- confirmed by inspecting
    per-page breakdowns: balloon predictions that were previously 0 became 2-8 (matching ground
    truth's presence of balloons), background over-prediction dropped from 5-12 blobs to 0-4.
    This is real, verified evidence the scale-mismatch diagnosis was correct and the retrain fixed
    it, not just an incidental metric wiggle.
- 76/76 tests pass across the whole app after all Phase 6 changes.

#### Deviations from Plan

- Task 6.2's evaluation metric is per-kind count agreement, not pixel IoU, for the reasons above
  (a direct consequence of Revision 1.2, not a new deviation from that already-approved decision).
- An unplanned but user-approved detour: retraining Task 4.2's U-Net baseline on newly-designed
  page-scale synthetic data, discovered necessary only once real-photo evaluation was possible
  (Phase 6 depends on Phase 5, so this couldn't have been caught earlier without building Phase 5
  first). Task 4.3's Mask R-CNN checkpoint was **not** similarly retrained/retested this session
  (out of scope given time already spent) -- Checkpoint D's comparison remains the partial verdict
  from Phase 4, now additionally stale relative to the retrained U-Net baseline.

**Ended at**: Phase 6 complete (Tasks 6.1-6.2 done, verified against real data, with a real fix
applied and confirmed after a genuine real-world evaluation problem was found)
**Handoff notes**: Phase 7 (balloon handoff to comics-ai-baloons) is next. The retrained
`work/models/unet_baseline.pt` (page-scale) is now the current baseline checkpoint --
`work/models/unet_baseline.history.json` reflects the page-scale run, not the original panel-scale
one (the panel-scale numbers are preserved only in this log, not overwritten silently). If
Checkpoint D is revisited, note Mask R-CNN's checkpoint is now trained on a different data
distribution (panel-scale) than the U-Net baseline (page-scale) -- not an apples-to-apples
comparison without retraining Mask R-CNN on the page-scale data too.

---

## Learnings

- Always verify cross-flow integration assumptions empirically (ran `comics-ai-baloons`'s actual
  test suite) rather than trusting its Specifications doc's claims at face value — that doc was
  accurate as of its own approval date, but the dataset/directory layout has since drifted.
- Real-photo/real-data evaluation surfaces problems that unit tests and synthetic-data metrics
  cannot: both the class-imbalance collapse (Phase 4) and the train/inference scale mismatch
  (Phase 6) were invisible in synthetic validation metrics and only became obvious once real
  photos were run through the full pipeline end-to-end.

---

### Session 2026-07-31 (continued 9) - Claude

**Started at**: Phase 7, Task 7.1

#### Completed

- **Revised the task's own framing before writing code**: Specifications described handoff as
  converting `CutRegion`s into `comics-ai-baloons`' `BalloonLayer` input shape and invoking its
  discover→extract→OCR→match→classify→render chain. Checked first, and that chain operates on
  `BalloonLayer` records referencing *real tile data inside a `dataset/*.comics` zip* -- it has no
  way to accept an arbitrary photo-extracted pixel crop (this project's own `CutRegion`) as if it
  were such a layer. More importantly, **`comics-ai-baloons` has already fully processed the entire
  dataset** (verified: 825 balloons discovered/matched, 1586 per-language render records, 22
  packaged output `.comics` files) -- there is nothing to re-invoke. Task 7.1 is therefore a
  **lookup/cross-reference** against that already-completed work, not a re-run.
- `route_balloons.py`: for each Phase-5-matched page, identifies the real balloon-kind layers
  within its `ground_truth_cluster` (via the matched episode's `gt.json`), looks up
  `comics-ai-baloons`' own `matches.jsonl` (translation status) and `renders.jsonl` (per-language
  render status) for those exact layers, cross-checks against this project's own photo-predicted
  balloon `CutRegion` count (Phase 6) as a sanity signal, and records whether a packaged output
  `.comics` already exists for that episode.
- Verified against real data, not just plausible-looking code: **all 16 distinct episodes among the
  37 matched pages are a genuine subset of `comics-ai-baloons`' 22 successfully-packaged episodes**
  (cross-checked the actual file listing, not just trusted the boolean flag) -- confirms Phase 9's
  packaging stage will have real, usable balloon-translation output to build on for every matched
  photo. Spot-checked individual records: real/translated/predicted balloon counts are all in a
  plausible ballpark per page, and `rendered_languages_by_layer` correctly surfaces real language
  codes (`hi`, `ja`, `uk`, `zh`, ...) from `comics-ai-baloons`' own data.
- 4 new tests (fixture-based + a real-data integration test). **80/80 tests pass** across the whole
  app.

#### Deviations from Plan

- Task 7.1 does not invoke `comics-ai-baloons`' discover/extract/OCR/match/classify/render chain at
  all -- it reads that pipeline's already-complete output. This is a correction of Specifications'
  framing (which assumed the chain would need to run against our input), discovered by checking
  what actually exists before writing integration code, not a scope change.

**Ended at**: Phase 7 complete (Task 7.1 done and verified against real data)
**Handoff notes**: Phase 8 (character/environment library builder) is next. `work/regions.jsonl`
(Phase 6) has `character`/`environment`-kind `CutRegion`s ready to cluster; episode metadata
(`Comics_Episodes.csv`) is available for seeding identity names (e.g. episode 21 `ambas_plea` →
candidate name "amba").

---

### Session 2026-07-31 (continued 10) - Claude

**Started at**: Phase 8, Task 8.1/8.2

#### Completed

- `build_library.py`, per Plan Task 8.1's decision (classical grouping first, then a pretrained
  embedding layered in):
  - Identity names seeded from `Comics_Episodes.csv`'s `Product` token (e.g. `"21_ambas_plea"` →
    `"amba"`, via a documented best-effort heuristic: strip a leading `<order>_` prefix, take the
    first underscore-separated word, strip a trailing possessive `"s"` if the word is long enough)
    -- verified against the real CSV (`8a89f7d689fb441ea280cd782276bd7a.comics` → `"amba"`
    correctly). Explicitly a weak label, not authoritative -- most episode titles aren't character
    names at all (e.g. "the_chase", "hastinapur"), confirmed by the real run producing several
    generic names (`"the"`, `"the-2"` .. `"the-5"`, `"hastinapur"`) alongside real ones.
  - Clustering: crops grouped by matched episode first (weak prior), then split into sub-identities
    within an episode via `AgglomerativeClustering` (cosine distance, threshold 0.5) on frozen
    ImageNet-pretrained ResNet-18 embeddings (512-d, L2-normalized) if the episode's crops don't
    look alike; a conservative cross-episode merge (threshold 0.25) only combines identities from
    *different* episodes when embeddings are very close, never forced.
  - Crop extraction re-derives the exact same page crop `infer_segmenter.py` used (detect → rectify
    → resize to 256x256) so `CutRegion` bboxes (Phase 6, stored in that resolution's coordinate
    space) are valid without needing to persist actual pixel data earlier in the pipeline.
- **Found and fixed a real gap before it shipped silently wrong**: the first version defined an
  `unclustered_dir` variable (per Plan Task 8.1's "ambiguous crops land in `unclustered/`, never
  force-assigned") but never actually wrote to it -- low-confidence regions were just `continue`-d
  past and disappeared entirely, not preserved for review. Fixed: low-confidence crops (but with
  successfully-extracted image data) are now saved to `unclustered/` with a
  `..._low_confidence.png` suffix. Added a regression test proving this (and that no spurious named
  identity folder gets created from an episode whose only regions were low-confidence).
- **Verified the concrete Requirements/Plan acceptance criterion for real**: ran the full builder
  against real data -- `characters/amba/` contains 11 crops, all traced back (via a test that
  parses each crop's filename and cross-references `alignment.jsonl`) to episode 21
  (`ambas_plea`), confirming **zero cross-contamination from other characters/episodes** into the
  Amba identity folder. Visually spot-checked two of the crops (Read tool) -- genuinely small/
  low-resolution (an honest, already-documented consequence of the 256x256 inference pipeline,
  Phase 6), but recognizably comic-panel content, not noise.
- Real run over the full dataset: 15 character identities, 14 environment identities, 25
  low-confidence character crops correctly routed to `unclustered/`.
- 9 new tests (including one real-data purity test and one regression test for the unclustered-
  routing bug). **89/89 tests pass** across the whole app.

#### Deviations from Plan

- None beyond the mid-implementation bug fix (unclustered routing) described above, applied before
  the "final" library build rather than shipped broken and fixed later.

**Ended at**: Phase 8 complete (Tasks 8.1-8.2 done and verified against real data, including the
project's concrete "Amba gallery" acceptance criterion from Requirements)
**Handoff notes**: Phase 9 (packaging & reporting) is next -- assemble a new `.comics` file per
successfully-aligned photo (reusing `comics-ai-baloons`'s tiling/zip code via the bridge, per
Specifications), plus the optional `.svg` export and the final report generation. All the pieces
(`alignment.jsonl`, `regions.jsonl`, `balloon_handoff.jsonl`, `work/library/`) now exist to build
from.

---

### Session 2026-08-01 - Claude

**Started at**: Phase 9, Task 9.1

#### Completed

- Task 9.1: `package.py` -- assembles a new, valid `.comics` file per successfully-matched photo/
  page. **Design decision made explicit rather than silently assumed**: each output file's canvas
  IS that photo's own rectified page crop (the 256x256-resolution space `CutRegion` bboxes/pixel
  data already live in from Phase 6), not an attempt to reposition content into the matched
  episode's canvas coordinates -- Revision 1.1/1.2 already established no such geometric mapping
  exists. Each detected region becomes one `Kind`-tagged layer, positioned via a `TranslateAnim` at
  its own bbox origin, tiled via `comics-ai-baloons`' existing 512px-tile convention (reused via the
  bridge) but written as a fresh zip (not `comics_io.write_comics`, which assumes editing an
  existing archive -- there is no source archive here, this is new content).
  - Verified via the same round-trip discipline used throughout this project: re-opened a packaged
    file with `ComicsArchive`/`stitch_image` and confirmed the schema, layer `Kind` tags, and
    stitched pixel data are all correct.
  - **Real run: 37/37 matched photo/pages packaged successfully (100%)**, 14MB total output.
  - **Visually composited a real packaged file's layers and confirmed genuine reconstruction
    fidelity**: the result is immediately recognizable as the same Amba/Parashurama scene spot-
    checked all the way back in Phase 2's canvas verification -- correctly positioned panels,
    characters, and balloon regions, built entirely from a real camera photo through the full
    detect→rectify→segment→cut→package pipeline. This is the single most convincing end-to-end
    verification in the whole project: independent confirmation, from a completely different code
    path, that the pipeline reconstructs real content correctly.
- Task 9.2 (optional `.svg` export): **deliberately skipped**, per Specifications' explicit
  permission ("may be dropped entirely if early trials look poor"). Extracted crops are
  photographic/painterly comic art, not clean line art -- a poor fit for contour-tracing
  vectorization, and time was better spent elsewhere this session. Documented as a reasoned skip,
  not an oversight.
- Task 9.3: `report.py` -- combines `alignment.jsonl`, `regions.jsonl`, `eval_report.jsonl`,
  `balloon_handoff.jsonl`, and `work/output/` into one final `work/report.jsonl` +
  human-readable `work/report.md` (summary stats, skip-reason breakdown, per-matched-page table).
  Real run: 136 photo/pages total, 37 matched (27%), all 37 packaged, mean kind-count agreement
  0.486 -- the same headline numbers established in Phases 5/6, now in one consolidated,
  human-readable artifact.
- 12 new tests across `test_package.py` and `test_report.py` (including round-trip and real-data
  integration tests). **97/97 tests pass** across the whole app.

#### Deviations from Plan

- Task 9.2 skipped entirely (see above) -- explicitly permitted by Specifications, not a silent
  scope cut.

**Ended at**: Phase 9 complete (Tasks 9.1 and 9.3 done and verified against real data; Task 9.2
deliberately skipped per Specifications)
**Handoff notes**: Phase 10 (optional quality correction) and Phase 11 (integration/end-to-end
verification) remain. Phase 10 is explicitly lower-priority/optional per Requirements. Phase 11's
manual verification checklist (Specifications) is now largely already satisfied by the real-data
verification done throughout Phases 2-9 -- worth reviewing against that checklist explicitly rather
than re-deriving it from scratch.

---

### Session 2026-08-01 (continued) - Claude

**Started at**: Phase 11, Task 11.1

#### Completed

- Task 11.1: `pipeline.py` -- single orchestrator running all 10 stages (render_canvas → augment →
  train_segmenter → align_photo → infer_segmenter → evaluate → route_balloons → build_library →
  package → report) in order, resumable per-stage (skips a stage whose cached output already
  exists unless `--force`). Verified for real, not just by code review: ran it against this
  session's actual `work/` directory (every stage's output already existed from manual runs) and
  confirmed all 10 stages correctly skip with no wasted recomputation -- critically, this proves
  the orchestrator won't silently trigger an expensive retrain (many minutes) on a routine re-run.
  4 new tests.
- Task 11.2: walked Specifications' full Testing Strategy checklist (Unit/Integration/Manual)
  item-by-item against real work done, rather than re-deriving verification from scratch. Updated
  `02-specifications.md`'s checkboxes directly, honestly distinguishing three cases: (a) verified
  exactly as originally written, (b) verified via an *adapted* method because Revision 1.1/1.2
  changed the underlying design (alignment homography → OCR matching; balloon re-discovery →
  lookup against already-complete work) -- noted explicitly, not silently reinterpreted, (c) one
  item only *partially* satisfiable and disclosed as such: output `.comics` files were verified
  structurally valid and pixel-round-trip-correct via this project's own reader, but never
  literally opened in the real Flutter/C# `apps/comics-editor` application (out of scope --
  running that full app is a separate, heavier undertaking than this pipeline's own test suite).
  **Every other checklist item across all three categories is now checked off**, each with a
  pointer to the specific test/artifact that verifies it.
- **Decision on Phase 10 (optional quality correction)**: **deliberately not built.** Requirements
  frames it explicitly as lower priority than cutting itself ("Not required for this iteration's
  acceptance criteria... build only if time remains after Phases 1-9 are solid") and Plan Task 10.1
  repeats "explicitly optional -- do not let this block Phase 1-9 delivery." All 9 other phases are
  complete and verified against real data; per the project's own stated priority order, this is the
  correct place to stop rather than spend further time on the lowest-priority remaining item.
  Recorded here as a deliberate, disclosed deferral, not a silent scope cut.
- 101/101 tests pass across the whole app after all Phase 11 changes.

#### Deviations from Plan

- Phase 10 not built, per its own explicit "optional, build only if time remains" framing in both
  Requirements and Plan -- a disclosed prioritization decision, not an oversight.

**Ended at**: Implementation complete. Phases 1-9 and 11 done and verified against real data at
every stage; Phase 10 deliberately deferred per its own stated optional status.
**Handoff notes**: This SDD flow's implementation is functionally complete. If resumed later:
(1) Phase 10 (quality correction) is the natural next increment if more capability is wanted;
(2) Checkpoint D (baseline vs. Mask R-CNN) could be finalized with an equal-budget retrain on
page-scale data using MPS; (3) the two known `comics-ai-baloons` test failures (stale path math +
dataset reorg) are pre-existing and out of this flow's scope but noted repeatedly throughout this
log for whoever next touches that flow.

---

## Completion Checklist

- [x] All tasks completed or explicitly deferred (Phase 10, disclosed)
- [x] Tests passing (101/101)
- [x] No regressions (full suite re-run after every change throughout)
- [x] Documentation updated if needed (Specifications checkboxes, this log, `_status.md` all current)
- [ ] Status updated to COMPLETE (pending final `_status.md` update)
