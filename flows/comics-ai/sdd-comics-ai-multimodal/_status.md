# Status: sdd-comics-ai-multimodal

## Current Phase

IMPLEMENTATION

## Phase Status

COMPLETE (Phase 10 deliberately deferred, disclosed — see Blockers). **Reopened 2026-08-06 for one
architecture-decision reconsideration (Task 4.1's segmentation model choice) — see Blockers.** Not a
reversal of completion; original Phases 1-9/11 scope stands as shipped. **Also 2026-08-06: a major
new candidate source asset investigated (real findings below, no pipeline changes made) — see
"New Source Asset Investigation."**

## Last Updated

2026-08-06 by Claude (reopened Task 4.1's segmentation architecture decision at Anton's request —
YOLO11-seg reconsidered; see Blockers for the real gap found and the unresolved license question)

## Blockers

- **Reopened, real gap found, not yet resolved (2026-08-06)**: `infer_segmenter.py::infer_regions`
  (the shipped Option C/U-Net path) computes a real per-instance connected-component mask, then
  discards it — only a bbox survives into `regions.jsonl`, so every downstream consumer
  (`comics-ai-positioning`, `comics-ai-animations`) only ever sees rectangles for non-rectangular
  real content. At Anton's explicit request, reconsidered the previously-rejected Option B (YOLO-seg)
  as **YOLO11-seg trained from scratch** (sidesteps the original "pretrained-only" objection — a
  from-scratch `.yaml`-init training path is Ultralytics' own documented pattern, not independently
  verified in this environment) with model-size tiering matching this repo's existing mobile/server
  split: **YOLO11m-seg for mobile, YOLO11l-seg/YOLO11x-seg for server/desktop**. Full record in
  `03-plan.md`'s "Revision, 2026-08-06" note under Task 4.1.
  **Genuinely unresolved, Anton's call, not decided here**: Ultralytics' `ultralytics` package is
  AGPL-3.0. Verified real narrowing fact: the segmentation model only ever runs as this flow's own
  offline Python batch tool — no distributed end-user app (`comics-editor`,
  `mahabharata-mobile-java-v2026`, `mahabharata-mobile-swift-v2026`) executes any Python/torch code,
  they only consume already-produced `.comics` output. Whether that residual internal-tooling
  exposure is acceptable, or an Ultralytics Enterprise license should be purchased instead, is a
  real legal/business judgment this document does not make.
  **Not started**: no YOLO11-seg training/comparison code written this pass — this is a decision-
  record reopening only, same treatment Task 4.1 itself originally got at Plan approval.
- None otherwise. **Implementation complete.** Phases 1-9 and 11 done and verified against real data at
  every stage (101/101 tests passing) — see `04-implementation-log.md`. Phase 10 (quality
  correction) deliberately deferred: Requirements and Plan both explicitly frame it as
  lowest-priority/optional ("build only if time remains after Phases 1-9 are solid") — a disclosed
  prioritization decision, not an oversight.
- Task 9.1's real output was visually composited and confirmed to reconstruct the exact same
  Amba/Parashurama scene spot-checked in Phase 2 — the strongest end-to-end confirmation in the
  project that the full pipeline works correctly on real photos.
- Task 9.2 (.svg export) deliberately skipped per Specifications' explicit permission — not
  implemented, not blocking.
- Task 11.2: walked Specifications' full Testing Strategy checklist item-by-item; every item is now
  checked off in `02-specifications.md`, with the one partial exception disclosed explicitly:
  output `.comics` files are verified structurally valid + pixel-round-trip-correct via this
  project's own reader, but never literally opened in the real `apps/comics-editor` Flutter/C#
  application (out of scope for this pipeline's own test suite).
- `pipeline.py` (Task 11.1) orchestrates all 10 stages, verified resumable (skips already-computed
  stages, won't silently trigger an expensive retrain on a routine re-run).
- Task 7.1 turned out to be a lookup against `comics-ai-baloons`' already-completed work (825
  balloons, 22 packaged episodes), not a re-invocation of its pipeline — verified all 16 matched
  episodes are a real subset of its 22 successfully-packaged outputs.
- Phase 8's concrete Requirements acceptance criterion (an "Amba gallery" with no cross-
  contamination) is verified for real: `work/library/characters/amba/` (11 crops) all trace back
  to episode 21 via `alignment.jsonl`.
- Real-photo evaluation found and fixed a genuine train/inference scale mismatch (U-Net baseline
  was trained on panel-scale crops but inference runs on whole pages) — retrained on new page-scale
  synthetic data (191 pairs); real-world mean kind-count agreement improved 0.382 → 0.486. See
  `04-implementation-log.md` Session 2026-07-31 (continued 8).
- Mask R-CNN's checkpoint (Task 4.3) was NOT retrained on the new page-scale data — Checkpoint D's
  comparison is now even more stale/not-apples-to-apples than before if revisited.
- **Resolved 2026-07-31**: Mask R-CNN's MPS hang was root-caused as a one-time Metal shader
  compilation cost (reproduced directly: the first batched MPS call on a given session takes
  minutes, every batched call after that is a normal ~30-35s), not a permanent MPS incompatibility.
  `train_segmenter.py --model maskrcnn` now defaults to MPS when available (same auto-detect
  pattern the U-Net baseline already used); `--device cpu` still available to force the old
  behavior. See "Session 2026-07-31 (continued 7)" in `04-implementation-log.md`.
- Known open item (not blocking): Checkpoint D (baseline U-Net vs. Mask R-CNN) only has a partial,
  honestly-disclosed-as-unequal-budget verdict from the earlier CPU-only run. U-Net baseline is
  still the practically-vetted option for now; re-running Mask R-CNN at a matched data/epoch budget
  on MPS (now unblocked) would let this be finalized, but hasn't been done yet.
- **Resolved by the Phase 6 retrain**: Phase 5's `cluster_layers_by_scene` clustering-bug fix
  predates Phase 6's page-scale data regeneration, so the current U-Net baseline checkpoint already
  benefits from the corrected clustering — no separate retrain needed for that specific issue.
- Phase 5 also revealed real content (episode 21/`ambas_plea` correctly matched from real photos
  with verified-correct dialogue) validating the whole alignment pipeline end-to-end — see
  `04-implementation-log.md` Session 2026-07-31 (continued 7).
- **Major mid-implementation revision (2026-07-31)**: Checkpoint A (Task 2.3) found the printed
  book is a conventionally paginated comic (fixed panel grids, real page numbers to 198+), not a
  crop of the tall scrolling digital canvas. Specifications and Plan both revised to v1.1 and
  re-approved: Phase 5 (photo alignment) now does per-panel OCR+content matching against
  `comics-ai-baloons`'s balloon OCR corpus instead of page-level homography against the canvas; Task
  3.2 (synthetic degradation) crops panel-shaped local clusters instead of arbitrary canvas windows.
  See `04-implementation-log.md` Session 2026-07-31 (continued 2) for full detail.

## New Source Asset Investigation (2026-08-06) — real findings, no pipeline changes made

Anton added `dataset/mahabharata/boranko/Mahabharata-Book01-all.pdf` mid-session. Investigated for
real (rendered real pages, ran real OCR) — this is genuinely a candidate replacement/supplement for
`Mahabharataa-Book01-lowcamera`'s low-quality phone photos, not just a nice-to-have:

- **143 real pages**, Adobe InDesign/Acrobat Pro print-production file (`pdfinfo`-confirmed), not a
  scan of the photos already in the dataset.
- **Page-number OCR works on the first try**: cropped a page-number region and ran real Tesseract —
  read "21" correctly at `--psm 7` with only a plain 4x upscale, no special preprocessing. This is
  the *exact* problem `sdd-comics-ai-positioning`'s Phase 7 gave up on (Tesseract systematically
  failed on the phone photos' "small, stylized digits" — 1/10 photos got even a partial digit). Not
  re-attempted at scale this session (investigation only), but the single real spot-check is a
  strong, concrete signal this source could unblock that dead end.
- **Balloon-text OCR is also far cleaner**: a real caption ("I WONDERED IF THEY WOULD DARE...")
  OCR'd with only a minor letter-drop error (missed a "T"), vs. the phone-photo pipeline's much
  higher real error/garble rate documented throughout this flow and `sdd-comics-ai-transformations`.
- **Real multi-column panel grids confirmed directly** (page 72: one wide panel over two genuine
  side-by-side vertical panels) — independent visual confirmation of Checkpoint A's finding that the
  print source is conventionally paginated, not pre-stacked, and a much cleaner test case than the
  phone photos for `sdd-comics-ai-positioning`'s still-open reading-order/Z-path investigation.
- **Real evidence of content beyond the current 27 known episodes**: pages 1 and 143 (first and
  last) both show a first-person frame narration/dialogue between "Vyasa" (identified by name in the
  text, "I am Vyasa Dvaipayana, the island-born storyteller") and a wounded figure addressed as
  "brother Bhishma" — checked directly against the real 27-row `Comics_Episodes.csv`: **no episode
  title contains "vyasa," "bhishma," "goddess," or "arrow"**. This looks like a real frame-narrative
  device (a classical Mahabharata scene — Bhishma narrating from a bed of arrows) not represented in
  any currently-digitized episode, appearing at both ends of the book.
- **Real, disclosed discrepancy, not resolved**: 143 pages here vs. the "198+" real printed page
  numbers previously observed in `comics_book_lowcamera` photos (`sdd-comics-ai-multimodal`
  Checkpoint A). Could mean a different print run, a different volume boundary, or a digital-reflow
  edition not sharing 1:1 pagination with the physically-photographed copy — not determined this
  pass, flagged honestly rather than assumed.
- **Correction (same investigation, minutes later)**: the "missing corpus" note above was based on
  looking in the wrong (pre-reorg) path — `work/` now lives at the repo root, keyed by app name
  (`work/comics-ai-baloons/ocr.jsonl`, 1650 real entries, confirmed present), not nested inside each
  app's own directory. `apps/comics-ai/comics-ai-baloons/.venv` already has `rapidfuzz` installed.
  **Ran two real, cheap match checks (not a full 143-page batch run, but genuine matcher
  invocations against the real corpus, not simulated)**:
  - Page 21's real OCR'd text ("I WONDERED IF THEY WOULD DARE...") scored **100.0** (exact
    normalized match) against `d94d8557c94e41ebb760347f2ad9d2f1.comics` (Order 2 in
    `Comics_Episodes.csv`, `Product=NULL` — the same episode whose real dialogue about
    "Bhishma Gangeya... regent of Hastinapur" was already found via phone-photo OCR earlier in this
    flow's own alignment work).
  - Page 72's real OCR'd text (three separate lines about "Arjuna Kartavirya," "the three-headed
    Dattatreya," and "countless arms") scored **91.9 / 98.1 / 98.8** against
    `54e9d4bbf0864460b9ff06271b215bd0.comics` — the already-known `06_ram_of_the_axe` episode, part
    of the Kartavirya/Jamadagni/Parashurama cluster `sdd-comics-ai-positioning` identified by manual
    `spiritual_text` reading. Three independent lines clearing the real `MIN_CONFIDENT_PHRASES=2`
    threshold with near-perfect scores is exactly the "clean, high-confidence" pattern the existing
    matcher was built to trust automatically — no threshold tuning or new code needed.
  **Conclusion, now well-evidenced rather than hypothesized**: this PDF's real page content
  directly corresponds to already-known episodes, with dramatically higher OCR fidelity than the
  phone-photo source. Running the existing, **unmodified** `align_photo.py` against all 143 real
  pages (not attempted this session — a real batch pipeline run, correctly out of "investigation
  only" scope) is a low-effort, high-confidence-of-success next step with real potential to recover
  a large fraction of `sdd-comics-ai-transformations`' remaining unmatched-content gap (77 rows;
  see that flow's own status for the full count) — this is a recommendation, not a promise, since
  only 2 of 143 pages were actually checked.

## Progress

- [x] Requirements drafted
- [x] Requirements approved
- [x] Specifications drafted
- [x] Specifications approved
- [x] Plan drafted
- [x] Plan approved
- [x] Implementation started
- [x] Implementation complete
- [ ] Documentation drafted
- [ ] Documentation approved

## Context Notes

Key decisions and context for resuming:

- Working directory for all pipeline code/output: `apps/comics-ai/comics-multimodal/`
  (`dataset/` stays read-only, mirrors `apps/comics-ai/comics-ai-baloons/` convention).
- User explicitly wants the core "cutting"/segmentation model **trained from scratch**, not a
  wrapper around a third-party generative model. Off-the-shelf tools/APIs are acceptable only for
  lower-priority auxiliary tasks (quality correction, OCR).
- Explicit priority order (highest first): (1) segmentation/"cutting" model that decomposes a
  flattened page image into kind-tagged layer regions, (2) photo (low quality, from
  `comics_book_lowcamera/`) → `.comics` as the first end-to-end scenario, (3) input quality
  correction, (4) net-new image generation (lowest priority) — text→`.comics` and mixed
  drawn/text-chapter→`.comics` scenarios are deferred beyond this iteration.
- Confirmed: `comics_book_lowcamera/` photos are of the *same* pages as the existing
  `comics_interactive/*.comics` files (supervised pairs exist) — but per user decision, **no
  manual photo↔episode/page mapping will be authored**; the pipeline itself must auto-align photos
  to source content (content-based matching, no assumed frame-order/index correspondence).
- User wants eventual (not this-iteration) integration into `apps/comics-editor` with a
  human-corrector review workflow — should follow the existing `BalloonEditorCard`/
  `BalloonAiClient` pattern from `vdd-comics-editor-uiux-lettering` (per-item generate/regenerate,
  stale-output indicator, on-device/cloud routing, never silent auto-apply). Design-only this
  iteration; no editor code changes.
- Optional/non-blocking ask: package a vector (`.svg`) representation alongside `.png` for
  extracted/generated regions where feasible.
- Full research done before drafting: surveyed all `flows/sdd-*` and `flows/vdd-*` flows (two
  Explore-agent passes) plus live inspection of a sample `.comics` file's `data.json` (confirmed
  schema: `width`/`height`, `layers[].images[]` indexed by fixed `Cultures` enum `{En, Ru, Hi}`,
  typed `animations[]`) and `apps/comics-editor`'s live architecture (headless C# core over NDJSON,
  no generic plugin/import system, no timeline dimension, session-only undo/redo).
- Confirmed real example for character-library validation: episode 21 `ambas_plea` =
  `8a89f7d689fb441ea280cd782276bd7a.comics` (Princess Amba).
- `apps/comics-editor-v2.9` was renamed to `apps/comics-editor` by the user on 2026-07-31 — use the
  new path in all future work.

## Next Actions

**Implementation is functionally complete.** Remaining items are optional follow-ups, not blockers:

1. Phase 10 (optional quality correction) — lower priority per Requirements; build only if more
   capability is wanted later.
2. If revisiting Checkpoint D, re-run Mask R-CNN training on the page-scale data (matching the
   U-Net baseline's current manifest) on MPS for a true equal-budget comparison.
3. Episode-name-derived identity labels are weak/best-effort (many are generic, e.g. "the-2"
   through "the-5") — fine for this iteration per Specifications, but real character naming would
   need either manual curation or a better signal than episode titles.
4. Note for whoever picks this up: `comics-ai-baloons` currently has 2 failing tests of its own
   (stale `REPO_ROOT` path math + dataset reorg to a nested layout) — see
   `04-implementation-log.md` Session 2026-07-31 "Discoveries". Not this flow's problem, unrelated
   to Phase 7's handoff (which reads its output files directly, unaffected by those test failures).
5. If a Documentation phase is wanted (per this repo's SDD convention, e.g. `sdd-comics-ai-baloons`
   has one): would mean writing/polishing `apps/comics-ai/comics-multimodal/README.md` into a full
   usage guide. Not started; ask the user whether they want this before starting it.
