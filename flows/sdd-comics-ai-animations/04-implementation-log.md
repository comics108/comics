# Implementation Log: comics-ai-transformations

> Started: 2026-08-01
> Plan: `03-plan.md` (not yet drafted — this log starts early because criterion 3's real
> investigation/implementation happened during Specifications, same precedent as
> `sdd-comics-ai-positioning`'s reading-order investigation)

## Progress Tracker

| Task | Status | Notes |
|------|--------|-------|
| Criterion 3: re-matching investigation | Done | 24 real single-hit cases analyzed, 22/24 recoverable |
| Criterion 3: refined rule implementation | Done | `align_photo.py::match_page_to_episode` |
| Criterion 3: applied to real data | Done | Anton confirmed 2026-08-02; cascade regenerated |
| Criterion 4: pilot investigation | Done | 3 real findings, reframes problem size |
| Criterion 4: review tool | Done | `unmatched_candidates.py`, real output, unreviewed by a human yet |
| `sdd-comics-ai-positioning` learned-model re-comparison | Done | 55% worse (was 5.8%) — real negative result |
| Criterion 2: script-context coverage expansion | Done | 27/27 episodes (was 6/27) |
| Criterion 1: transformation generation core | Not started | Architecture scoped in `02-specifications.md` only |
| Criterion 5: full pipeline run on newly-covered content | Not started | Depends on criterion 1 |

## Session Log

### Session 2026-08-01/02 - Claude

**Started at**: Specifications phase, criterion 3 investigation
**Context**: Flow renamed/rescoped twice same day (see `_status.md` Progress); real investigation
into the 99 unmatched page-rows was the first concrete technical work.

#### Completed

- **Real diagnostic investigation of all 99 `skipped_no_match` rows** (`apps/comics-ai/
  comics-multimodal/work/alignment.jsonl`): broke down by real reason (57 zero-hit / 24 single-hit /
  16 no-OCR / 2 no-regions), not left as one undifferentiated "unmatched" bucket.
- **Installed missing dependencies** into this environment to do real (not simulated) investigation:
  `opencv-python-headless`, `pytesseract`, `rapidfuzz` (later also `torch`/`torchvision` for
  segmentation inference — `tesseract` binary and `numpy` were already present).
- **Re-ran real OCR + matching on all 24 "single confident hit" pages** — found 21/24 had no
  competing episode (real, trustworthy matches missing only a second corroborating phrase) and 3/24
  were genuinely ambiguous (2 episodes each with 1 hit, margins 2.9/7.5/13.0 points).
- **Designed and implemented a refined matching rule** (`MARGIN_FOR_SINGLE_HIT = 10.0` in
  `align_photo.py`): accept a single confident hit only when no competing episode's hit is within
  10 confidence points. Does not relax the existing `MIN_CONFIDENT_PHRASES = 2` path at all — that
  stays unconditionally trusted.
  - Files changed: `apps/comics-ai/comics-multimodal/scripts/align_photo.py`
    (`match_page_to_episode`, new `MARGIN_FOR_SINGLE_HIT` constant).
  - Tests: `apps/comics-ai/comics-multimodal/tests/test_align_photo.py` — replaced one test whose
    asserted behavior (reject any single hit) was the deliberate change target, added 2 new tests
    (accept-clean-single-hit, reject-ambiguous-tie, accept-with-clear-margin — 3 new total). All
    fixture scores verified against real `rapidfuzz.fuzz.partial_ratio` calls before writing
    assertions, not guessed. 10/10 passing.
  - Verified by: full `align_photo.py` test suite (10/10) + broader `comics-multimodal` suite
    (65/67 runnable — 2 pre-existing failures confirmed unrelated, missing `torch` for other
    modules, not caused by this change).
- **Applied to real data, per Anton's explicit confirmation** ("Да, применить и пересчитать" —
  the auto-mode classifier correctly blocked the first attempt at this exact step, requiring
  specific confirmation beyond the earlier general "up to you," which I then obtained):
  - `align_photo.py` re-run: 59/136 matched (was 37/136) — exactly the predicted +22.
  - **Discovered mid-cascade**: newly-matched pages had zero cutting/segmentation output
    (`regions.jsonl` only ever covered the original 37 matched pages) — alignment success alone
    doesn't produce usable training pairs. Installed `torch`/`torchvision`; a trained checkpoint
    (`unet_baseline.pt`) already existed, so this was inference-only, not retraining.
    `infer_segmenter.py` re-run: 896 regions (up from covering only 37 pages).
  - `sdd-comics-ai-positioning`'s cascade regenerated: `build_pairs.py` (564 pairs/19 episodes, was
    392/16), `evaluate_positioning.py` (weighted baseline 1479.7px/0.634 rank correlation, was
    1467.4px/0.542, on a held-out set roughly double the size).
  - One hardcoded test updated (`sdd-comics-ai-positioning`'s
    `test_data_checkpoint.py::test_summarize_on_real_data_matches_manual_count`, 37/16 → 59/19).
  - Results written back into `sdd-comics-ai-positioning/_status.md` and its own
    `README.md` (with the learned-model comparison numbers explicitly marked as not yet re-run
    against the expanded dataset — `scikit-learn`/`joblib` not installed in this environment).

#### Deviations from Plan

- No `03-plan.md` existed yet when this work started — criterion 3's investigation happened during
  Specifications drafting itself, same as `sdd-comics-ai-positioning`'s reading-order investigation
  precedent. Logged here regardless, per "log progress" discipline, rather than waiting for a
  formal Plan phase to retroactively justify already-done real work.
- The auto-mode permission classifier blocked the first attempt to regenerate `alignment.jsonl`,
  correctly distinguishing "up to you, whatever's more effective" (general encouragement) from the
  specific confirmation needed for a named, flagged, cross-flow action. Asked explicitly via
  `AskUserQuestion` and got clear confirmation before proceeding — this was the right outcome, not
  a workaround-worthy obstacle.

#### Discoveries

- **Real, generalizable lesson**: in a multi-stage pipeline (align → segment → build pairs →
  evaluate), fixing an upstream stage's coverage does not automatically benefit downstream stages
  that cache their own output keyed by the old coverage. Each stage in the chain needed its own
  explicit re-run, and the segmentation gap (regions.jsonl not covering newly-matched pages) would
  have silently produced zero benefit from the re-matching fix if not caught and diagnosed
  mid-cascade.
- Real environment gaps found and closed as needed (not pre-emptively): `opencv-python-headless`,
  `pytesseract`, `rapidfuzz`, `torch`, `torchvision` all had to be installed via `pip install --user`
  into the system Python (3.9.6) for real investigation/execution — `scikit-learn`/`joblib` remain
  missing (needed only for the learned-model re-comparison, not attempted this session).

**Ended at**: Criterion 3 complete and applied; criteria 1/2/4/5 not started.
**Handoff notes**: Criterion 4 (new-episode-identity) is the next real investigation needed before
Plan can size the remaining scope honestly — Requirements calls for piloting on a real subset, not
designing a method in the abstract. The 57-bucket's caption/narration-corpus hypothesis
(Specifications' Open Design Question) is a separate, real, not-yet-attempted piece.

---

### Session 2026-08-02 (continued) - Claude

**Started at**: 57-bucket investigation (Specifications' Open Design Question)
**Context**: Anton said "продолжай" (continue) after the criterion-3 summary — proceeded into the
57-row zero-hit bucket next, as the other named next-step alongside criterion 4.

#### Completed

- **Tested Specifications' caption/narration-corpus-exclusion hypothesis directly — REFUTED.**
  Found a real caption's exact text already present in `comics-ai-baloons/work/ocr.jsonl`
  (`d00c610a...comics` layer 120, 0.9275 confidence), proving `discover.py`'s purely structural
  balloon-layer detection (≥2 language image slots, no shape/kind check) already captures captions.
  The page that originally seemed to prove the hypothesis scored 70.6 (rapidfuzz-verified) against
  this real entry — under threshold from real paraphrase/OCR variance, not structural exclusion.
- **Tested a `PARTIAL_MATCH_THRESHOLD` reduction against all 57 real pages (full set, not a
  sample)** — OCR'd every one, scored with a wide net (>=60) to see the real near-miss distribution:
  29/57 had no candidate at all above 60; only 7 reached >=75, all short/generic-ish exclamations
  ("SVAYAMVARA IS OPEN!"). Judged too weak/risky to recommend, unlike the 24-bucket's clean 90-100
  scoring recoveries — **no threshold change made**.
  - Files changed: `flows/sdd-comics-ai-transformations/02-specifications.md` (rewrote the "zero
    hits bucket" section to replace the original, now-refuted hypothesis with these two tested,
    negative findings), `_status.md` (same).
  - Verified by: direct `rapidfuzz.fuzz.partial_ratio` calls against real corpus/OCR data, not
    inference from docstrings or assumption.

#### Discoveries

- A docstring's framing ("balloon/text layer") can be misleading about actual code behavior — always
  check the real implementation (here, a pure structural check with no kind/shape filter) before
  trusting a comment's implied scope.
- Two real, honest negative results in a row (this session) is a legitimate, valuable outcome, not a
  failure to find something — it closes off wrong directions before time is spent building on them,
  and correctly redirects effort toward criterion 4 as the real remaining lever.

**Ended at**: 57-bucket investigation complete (no code change — both hypotheses tested and
rejected). Criterion 4 is next.
**Handoff notes**: The 99-unmatched-row gap's "cheap" recovery paths (single-hit margin rule,
corpus/threshold tweaks) are now exhausted — 22/99 recovered, no more available this way. Criterion
4 (new-episode-identity) is the only remaining lever for the bulk of the gap; Requirements calls for
piloting on a real subset before committing to a method, not designing one in the abstract.

---

### Session 2026-08-02 (continued further) - Claude

**Started at**: Criterion 4 pilot (Requirements' explicit next step)
**Context**: Continued past the 57-bucket's negative results into criterion 4 itself, same
"продолжай" continuation.

#### Completed

- **Checked the real zero-coverage-episode count, found and fixed a comparison bug along the way**:
  first attempt showed all 27 episodes as "zero coverage" (wrong) because `Comics_Episodes.csv`
  filenames have a `/Files/` prefix not present in `alignment.jsonl`'s bare filenames — fixed the
  comparison, found the real number: **8 of 27**, each with real corpus text already (14-52 OCR'd
  entries). This directly corrected an overly pessimistic claim in `01-requirements.md` (now
  annotated with the correction, not silently rewritten).
- **Built and tested a same-episode-adjacency heuristic** using photo filename timestamps as a
  physical-page-order proxy: 17/77 unmatched rows get a confident same-episode-both-sides proposal,
  52 are genuine boundary/transition zones, 8 are at sequence edges.
- **Cross-validated 3 adjacency proposals against the independent weak-text-signal data from the
  57-bucket investigation** — found zero corroboration, tempering confidence appropriately (does not
  disprove the proposals; pages with little dialogue would show exactly this null result either way,
  but means the signal isn't self-confirming the way criterion 3's fix was).
- **Found a concrete illustration of a structural matching limit**: `97cf25db...` (one of the 8
  zero-coverage episodes) scatters as a weak candidate across 16 pages spanning the *entire* book's
  timestamp range, not a contiguous run — diagnosed as generic short-battle-exclamation phrases
  producing noise, not a real widespread match.
  - Files changed: `flows/sdd-comics-ai-transformations/02-specifications.md` (new "Criterion 4
    Pilot" section), `01-requirements.md` (correction annotation), `_status.md` (same content,
    status-file form).
  - Verified by: direct computation against real `alignment.jsonl`/`ocr.jsonl`/`Comics_Episodes.csv`
    data throughout; no simulated/assumed numbers.

#### Deviations from Plan

- No code shipped this sub-session (unlike criterion 3) — the honest conclusion from the evidence is
  "recommend a review tool, don't automate yet," which is itself the correct Specifications-level
  output, not a gap.

#### Discoveries

- Always verify string-format assumptions (the `/Files/` prefix) before trusting a set-difference
  result that looks suspiciously total (all 27, not a subset) — a real bug, caught before it
  propagated into a wrong conclusion.
- A heuristic "looking right" (adjacency matches basic intuition about book layout) is not the same
  as being confirmed — cross-checking against an independent signal, even a weak one, is worth doing
  before recommending automation, not just before shipping code.

**Ended at**: Criterion 4 pilot complete — reframed the problem's real size, produced one candidate
signal (adjacency) recommended for human review, not automation; no code shipped.
**Handoff notes**: Remaining `sdd-comics-ai-transformations` work: build the criterion-4 review tool
(Plan-phase-ready), re-run positioning's learned-model comparison against the expanded dataset (needs
`scikit-learn`/`joblib`), and begin Specifications→Plan for criteria 1/2/5 (transformation
generation + script-context expansion), which have not been touched since the initial architecture
scoping.

---

### Session 2026-08-02 (continued yet further) - Claude

**Started at**: Building the criterion-4 review tool (Requirements/Specifications-recommended next
step from the pilot)
**Context**: Anton said "продолжай" again — continued into building the recommended tool, then the
positioning learned-model re-comparison.

#### Completed

- **Built `apps/comics-ai/comics-multimodal/scripts/unmatched_candidates.py`**: real
  `compute_adjacency_candidates`/`weak_text_candidates`/`zero_coverage_episodes`/`build_report`
  functions, per the pilot's recommended shape (surface candidates for human review, never
  auto-apply). Ran for real: `work/unmatched_candidates.jsonl` now exists with all 77 unmatched
  rows' candidates.
  - Files changed: `apps/comics-ai/comics-multimodal/scripts/unmatched_candidates.py` (new),
    `apps/comics-ai/comics-multimodal/tests/test_unmatched_candidates.py` (new, 9 tests).
  - Verified by: 9/9 new unit tests (synthetic-fixture logic tests plus 2 tests against real data
    confirming the pilot's own 27-episode/8-zero-coverage numbers reproduce exactly), full
    `comics-multimodal` suite re-run (75/76 runnable — 1 remaining failure due to missing `sklearn`
    in an unrelated module, fixed next).
- **Installed `scikit-learn`/`joblib`** (removes the last dependency gap from criterion 3's cascade
  work) and **re-ran `sdd-comics-ai-positioning`'s learned-model comparison** against the expanded
  564-pair/19-episode dataset: retrained (406 examples/14 episodes), evaluated on the new 5-episode/
  158-pair held-out set. **Result: 55% worse than baseline** (was 4.3%, then 5.8% on smaller
  datasets) — worse, not better, with more data. Excluding the `d00c610a...` outlier episode, still
  **70% worse** — confirmed not purely outlier-driven.
  - Files changed: `apps/comics-ai/comics-positioning/README.md`,
    `flows/sdd-comics-ai-positioning/_status.md` (both updated with the new numbers, closing the
    loop per this flow's own Must-Have 3).
  - Verified by: full `comics-positioning` suite, 37/37 passing (was 30 — 7 previously
    dependency-blocked tests now run for real for the first time).

#### Discoveries

- More training data does not automatically help a learned model relative to a robust baseline —
  here it made the gap *worse*, a real, counter-to-naive-expectation result worth taking at face
  value rather than assuming a bug (checked: no bug found, the result reproduces the pilot's own
  numbers correctly, tests pass, methodology matches prior comparisons exactly).
- Building a "surface candidates, don't auto-apply" tool is itself a complete, real deliverable when
  the evidence doesn't support automation — matches this repo's established pattern (design-only
  contracts, e.g. `sdd-comics-ai-multimodal`'s own un-built review UI) rather than a compromise.

**Ended at**: Criterion 4 tool built and run; positioning's learned-model question closed
(negative, definitively so now). Criteria 1/2/5 remain the only unstarted piece of this flow's
original 5-criterion scope.
**Handoff notes**: This flow's remaining real work is entirely in criteria 1/2/5 (transformation
generation + script-context coverage expansion) — everything else (3, 4's pilot+tool, the
positioning re-comparison) has real, tested, documented output. A human still needs to review
`work/unmatched_candidates.jsonl`'s proposals before any of them are acted on.

---

### Session 2026-08-02 (continued once more) - Claude

**Started at**: Criterion 2 (script-context coverage expansion)
**Context**: Anton said "продолжай" again; criterion 2 was the smaller/more contained of the two
remaining pieces (vs. criterion 1's full new ML pipeline), tackled first.

#### Completed

- Checked real feasibility before implementing: `comics-ai-baloons`'s structural `discover.py`
  already covers all 27 episodes' balloon dialogue in `ocr.jsonl`, independent of photo-matching —
  full 27/27 script-context coverage was reachable, not capped at 16.
- Implemented the OCR-dialogue fallback in `sdd-comics-ai-script-context`: new
  `ocr_dialogue_source.py`, `text_source` provenance field on `SceneExtraction`, wired through
  `extract_scene.py` and `run_all.py`. 7 new/updated tests, 19/19 passing.
- Real full run: **27/27 episodes extracted, 0 failed, 0 no-source-text** (was 6/0/21). Independent
  confirmation of the criterion-4 `97cf25db...`/"defy the kshatriyas" hypothesis.
- Updated `sdd-comics-ai-script-context/_status.md`, `04-implementation-log.md`, and
  `apps/comics-ai/comics-script-context/README.md` with the real new numbers.

**Ended at**: Criterion 2 complete. Only criterion 1 (transformation generation core) and criterion
5 (full pipeline run, depends on criterion 1) remain of this flow's original 5-criterion scope.
**Handoff notes**: Criterion 1 is a substantial new build (a full ML pipeline mirroring
`sdd-comics-ai-positioning`'s Phase 1-4 architecture: ground-truth `Anim` extraction, training pairs,
calibrated baseline, held-out evaluation) — not yet started, the last major piece of this flow.

---

### Session 2026-08-02 (continued the furthest) - Claude

**Started at**: Criterion 1 (transformation generation core)
**Context**: Anton said "продолжи" again — the last substantial unstarted piece of this flow.

#### Completed

- **Extended `comics-multimodal`'s `resting_position.py`** with `resolve_reveal_animation` (new
  `PropertyReveal`/`RevealAnimation` dataclasses): a real reveal is the "2+ keyframes per property
  type" case (a static base + a keyframed transition), verified against the exact same real
  fixtures (`CROSSFADE_ANIMS`/`ROTATE_ANIMS`/`SCALE_ANIMS`) `resolve_resting_transform`'s own tests
  already used — all new assertions passed on the first try, confirming the extraction logic
  against real, previously-vetted data. 4 new tests in `test_resting_position.py`, 10/10 passing.
- **Computed real per-kind reveal statistics across all 4594 real layers** (not just matched-photo
  episodes — this criterion needs no photo-matching at all): balloons animate alpha/scale 75-77% of
  the time; backgrounds almost never (1-1.5%); alpha reveals are ~universally 0.0→1.0 (fade-in),
  scale ~universally 0.6→1.0 (grow-in); translate/rotate have real occurrence+duration but no
  confident direction (median delta ≈0, near-balanced +/- split).
- **Built a new app**, `apps/comics-ai/comics-transformations/`, mirroring `comics-ai-positioning`'s
  file layout exactly: `transforms_bridge.py` (live-import bridge to comics-multimodal, same pattern
  as `positioning_bridge.py`), `build_transform_pairs.py` (real ground-truth extraction, all 27
  files), `transform_stats.py` (real per-kind calibration, held-out-exclusion supported),
  `baseline_transform.py` (rule-based proposal — confident from/to values for alpha/scale, honest
  zero-delta for translate/rotate rather than a fabricated direction), `evaluate_transforms.py`
  (held-out file-wise evaluation vs. a trivial "always static" strawman, same discipline as
  `evaluate_positioning.py`).
  - Files changed/created: `apps/comics-ai/comics-multimodal/scripts/resting_position.py` (extended),
    `apps/comics-ai/comics-multimodal/tests/test_resting_position.py` (+4 tests), and 5 new files
    each in `apps/comics-ai/comics-transformations/scripts/` and `tests/`.
  - Verified by: 11/11 new tests in `comics-transformations` (all against real data — no mocking of
    the dataset itself), plus the extended `comics-multimodal` suite (13/13 across
    `test_resting_position.py` + `test_render_canvas.py`, confirming no regression from extending a
    shared module).
- **Real full pipeline run**: `build_transform_pairs.py` → 4594 real pairs across 27 episodes;
  `transform_stats.py` → real calibration (written to `work/transform_stats.json`);
  `evaluate_transforms.py` → held-out evaluation on 7 episodes/1246 layers.
  - **Real result**: baseline beats the trivial strawman on translate (62.5% vs 51.8%), scale
    (90.0% vs 80.3%), alpha (90.8% vs 80.7%) — **ties** it on rotate (92.5% vs 92.5%), since no
    region kind's real rotate-occurrence rate clears the 50% majority threshold used to decide
    "does this kind typically animate this property" — the baseline degenerates to "always predict
    no rotation" for every kind, identical to the strawman for that one property. Disclosed
    explicitly in `README.md`, not hidden as a rounding artifact.

#### Deviations from Plan

- None — followed the architecture already scoped in `02-specifications.md`'s "Architecture:
  Transformation Generation" section closely (component names, data flow) once real investigation
  confirmed the underlying data supported it.

#### Discoveries

- Reusing a sibling flow's own already-vetted test fixtures (rather than writing new synthetic ones)
  to validate a new extraction function is a strong sanity check — passing on the first try against
  data someone else already hand-verified is stronger evidence of correctness than a fresh synthetic
  fixture would have been.
- A calibrated majority-vote baseline can legitimately *tie* a trivial strawman on one sub-metric
  while clearly beating it on others — worth reporting per-property rather than only an aggregate,
  since an aggregate could have hidden the rotate result inside an overall "beats strawman" headline
  that wouldn't have been fully honest.

**Ended at**: Criterion 1 complete — real app, real calibration, real held-out evaluation, honestly
disclosed limitations. Only criterion 5 (full pipeline run on newly-covered content) remains of this
flow's original 5-criterion scope.
**Handoff notes**: `apps/comics-ai/comics-transformations/` is a real, standalone, tested deliverable
now — criterion 5 would wire its `baseline_transform.py` into the same end-to-end run as cutting/
positioning/balloon-matching for a real newly-covered page, and report per-page completeness.

---

### Session 2026-08-02 (final, this scope) - Claude

**Started at**: Criterion 5 (full pipeline run on newly-covered content) — the last unstarted piece
**Context**: Anton said "продолжи, ревью пропусти" — continued straight through without a
checkpoint pause.

#### Completed

- Built `full_pipeline_demo.py`: a real integration script invoking already-built stages (cutting =
  comics-multimodal's already-computed `regions.jsonl`, positioning = `comics-ai-positioning`'s
  `baseline_position.py`, transformation = this flow's own `baseline_transform.py`) for one real
  page, plus a cross-check against `sdd-comics-ai-script-context`'s real narrative extraction for
  the same episode.
- **Deliberately chose a genuinely newly-covered page**: `2a5e3303ba8c42e3ba395dad794164a7.comics`
  had zero matched photos before this flow's own criterion 3 fix — demonstrating the chain on
  content this flow itself unlocked, not a page that already worked before any of this session's
  changes.
- **Real result**: 15 real cut regions (5 balloon/2 character/8 art), each with a real position and
  reveal proposal; every balloon correctly got the calibrated alpha+scale reveal. Script-context
  cross-check ("RAMA...chased and killed Kshatriyas", "Parasurama...destroyed armies 21 times") is
  directly consistent with the episode's own real title (checked precisely, not inferred, after
  Anton asked whether `Comics_Episodes.csv` was actually consulted): `2a5e3303...` is titled
  `13_kshatriyas_extermination`, immediately following `97cf25db...`'s `12_defy_the_kshatriyas` —
  the same saga's next chapter, a stronger match than the "neighboring title" framing first written
  here (corrected in `_status.md`/`README.md`) — independent evidence the whole chain
  (match→cut→position→transform→narrative) is coherent for new content, not just the original
  training set.
  - Files changed: `apps/comics-ai/comics-transformations/scripts/full_pipeline_demo.py` (new),
    `apps/comics-ai/comics-transformations/tests/test_full_pipeline_demo.py` (new, 1 test),
    `README.md` (criterion 5 section).
  - Verified by: 1 new integration test against real data (no mocking), full suite re-run
    (12/12 passing).

#### Discoveries

- End-to-end integration scripts are a good final validation step even when every individual stage
  was already tested in isolation — this run surfaced no bugs, but confirming that firsthand (all
  three stages' real outputs compose correctly, region IDs stay aligned, episode-file lookups match
  between `alignment.jsonl` and `script-context`'s scene files) is worth more than assuming it from
  each piece's own passing tests.

**Ended at**: All 5 Must-Have criteria complete. This flow's original scope is done — remaining
items (human review of criterion 4's candidates, an optional learned-model attempt, an optional
positioning-model investigation) are follow-ons, not gaps in what was asked for.
**Handoff notes**: `flows/sdd-comics-ai-transformations/` can be considered COMPLETE for its
original 5-criterion Requirements. The one non-engineering item outstanding is human review of
`apps/comics-ai/comics-multimodal/work/unmatched_candidates.jsonl`.

---

## Deviations Summary

| Planned | Actual | Reason |
|---------|--------|--------|
| Criterion 3 investigation only (Specifications) | Investigation + real implementation + real application, same session | Anton's explicit confirmation made this a natural continuation, not a separate future step |

## Learnings

- Always check whether a "fixed" upstream stage's benefit actually reaches the end metric before
  declaring success — the `regions.jsonl` segmentation gap would have made the re-matching fix a
  no-op for `sdd-comics-ai-positioning` if not caught.
- A real, principled refinement (margin-based tie-breaking) beat a naive threshold relaxation
  (`>=1` instead of `>=2`) both in measured safety (correctly rejects true ambiguity) and in
  actually being defensible to a future reader who asks "why 10 points?" — the number traces to a
  real, disclosed sample, not a guess.

## Completion Checklist

- [x] Criterion 3 tasks completed (investigation, implementation, real application)
- [x] Criterion 4 piloted and tooled (investigation + `unmatched_candidates.py`, real output —
      human review of that output still pending, not this flow's job to perform)
- [x] `sdd-comics-ai-positioning` learned-model re-comparison completed (real negative result)
- [x] Criterion 2 (script-context coverage expansion) completed — 27/27 episodes, was 6/27
- [x] Criterion 1 (transformation generation core) completed — new `comics-transformations` app,
      real calibrated baseline beats strawman on 3/4 properties, ties on the 4th (honestly disclosed)
- [x] Criterion 5 (full pipeline run on newly-covered content) completed — real end-to-end demo on
      a genuinely newly-covered page, cross-checked against script-context
- [x] Tests passing (all touched test files, `comics-multimodal`: 75/76 runnable,
      `comics-positioning`: 37/37, `comics-script-context`: 19/19, `comics-transformations`: 12/12)
- [x] No regressions (confirmed pre-existing failures are unrelated, environment-only)
- [x] Documentation updated (`sdd-comics-ai-positioning`'s and `sdd-comics-ai-script-context`'s
      `_status.md`/`README.md`, this flow's own `_status.md`, new `comics-transformations/README.md`)
- [x] Status updated to COMPLETE — all 5 Must-Have criteria done; see `_status.md`
