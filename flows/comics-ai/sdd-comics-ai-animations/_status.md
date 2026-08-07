# Status: sdd-comics-ai-transformations

## Current Phase

IMPLEMENTATION

## Phase Status

**ALL 5 CRITERIA DONE FOR REAL.** Criterion 2 (script-context full coverage), 3 (re-matching,
applied), 4 (pilot + review tool), 1 (transformation-generation baseline), and now **5 (real
end-to-end cut→position→transform run on a real newly-covered page)**. `sdd-comics-ai-positioning`'s
learned-model comparison also re-run (real negative result). This flow's original 5-criterion scope
is complete; see Blockers for the one real thing still needing a human, not more engineering.

## Last Updated

2026-08-02 by Claude (implemented criterion 5 — real end-to-end pipeline demo on a newly-covered
page; all 5 criteria now done)

## Blockers

- **The only remaining item is human, not technical — now in progress**: `work/
  unmatched_candidates.jsonl`'s 17 adjacency candidates and 30 weak-text candidates (criterion 4)
  are unconfirmed hypotheses until someone with real knowledge of the book reviews them against the
  actual page images. **Handed to Джанава (Евгений Корытный) for review on 2026-08-02** — waiting
  on his read-through before any of these candidates can be confirmed/rejected and fed back into a
  `sdd-comics-ai-multimodal`/`sdd-comics-ai-positioning`/`sdd-comics-ai-transformations` cascade
  regeneration. Nothing else in this flow's original scope is blocked or unstarted.
- **Possibly superseded by a better source, found 2026-08-06 (Claude)**: Anton added
  `dataset/mahabharata/boranko/Mahabharata-Book01-all.pdf` (143 real pages, print-production
  quality) mid-session. Two real, cheap spot-checks (not a full batch run) against the existing
  balloon OCR corpus scored **100.0** and **91.9-98.8** on two sampled pages, matching already-known
  episodes with far higher confidence than the phone-photo source ever achieved. Full evidence in
  `sdd-comics-ai-multimodal/_status.md`'s "New Source Asset Investigation" section. **This may make
  the human-review step above partially moot**: if a full 143-page match run recovers most of the
  remaining unmatched content directly (unmodified matcher, no threshold tuning), the
  `unmatched_candidates.jsonl` adjacency/weak-text hypotheses would only be needed for whatever this
  new source still doesn't cover — worth checking before Джанава spends time on candidates a better
  source might resolve outright. Not verified at scale this pass; a real recommendation, not a
  promise.

## Criterion 1 — Implemented, Real Calibrated Baseline (2026-08-02)

New app `apps/comics-ai/comics-transformations/`, mirroring `comics-ai-positioning`'s structure
exactly (extraction → stats → baseline → held-out evaluation). Extended `comics-multimodal`'s
`resting_position.py` with `resolve_reveal_animation` (a real reveal is exactly the "2+ keyframes
per property type" case — a static base entry plus a keyframed transition — verified against the
same real fixtures `resolve_resting_transform` already used, all new tests passing on the first
try). Real per-kind statistics mined from all 4594 real layers across 27 files (not just the 19
with matched photos — this criterion doesn't need photo-matching at all, unlike positioning):
balloons animate alpha/scale 75-77% of the time (fade+grow-in reveal), backgrounds almost never
(1-1.5%); alpha reveals are overwhelmingly 0.0→1.0, scale reveals overwhelmingly 0.6→1.0;
translate/rotate have confident occurrence+duration but **no confident direction** (real median
delta ≈0, balanced +/- split) — disclosed as a real limit, not fabricated.

**Real held-out evaluation (7 episodes, 1246 layers)**: baseline beats a trivial "always static"
strawman on translate (62.5% vs 51.8%), scale (90.0% vs 80.3%), and alpha (90.8% vs 80.7%) —
**ties** it on rotate (92.5% vs 92.5%, since no kind's real rotate rate clears the 50% majority
threshold, so the baseline degenerates to the strawman's own prediction for that one property,
honestly disclosed, not a bug). 11/11 new tests passing (`comics-transformations`), plus 4 new
tests in `comics-multimodal/tests/test_resting_position.py` for the new extraction function (10/10
in that file). No regressions in either app's existing suites.

## Criterion 5 — Real End-to-End Pipeline Demo (2026-08-02)

Built `full_pipeline_demo.py`: a real invocation of cut (already-run `comics-multimodal` inference)
→ position (`comics-ai-positioning`'s `baseline_position.py`) → transform (this flow's own
`baseline_transform.py`), for one real page. Chose `2a5e3303ba8c42e3ba395dad794164a7.comics`
deliberately — an episode with **zero** matched photos before criterion 3's fix, i.e. genuinely
newly-covered content, not a page that already worked before this flow started.

**Real result**: 15 real cut regions (5 balloon, 2 character, 8 art) — every one got a real
proposed X/Y position and a real proposed reveal animation; every balloon region correctly received
the calibrated alpha+scale fade/grow-in reveal, matching the dataset-wide per-kind pattern exactly.
Cross-checked against `sdd-comics-ai-script-context`'s real narrative extraction for this same
episode ("RAMA...chased and killed Kshatriyas", "Parasurama...destroyed armies 21 times") —
**directly consistent with the episode's own real title in `Comics_Episodes.csv`**, checked
precisely (not inferred): `2a5e3303...` is titled `13_kshatriyas_extermination` (Order 13,
immediately following `97cf25db...`'s `12_defy_the_kshatriyas` at Order 12 — the same saga's next
chapter). An earlier draft of this note cited only the *neighboring* episode's title as a loose
"sibling arc" signal without checking this episode's own Product field — corrected here to the
direct, stronger match. Independent plausibility signal that the whole chain (match → cut →
position → transform → script-context) is coherent for genuinely new content, not just the
original 16-episode training set. Balloon *text* content assignment itself is out of scope (reuses
`comics-ai-baloons`'s own pipeline, not rebuilt). 1 new integration test, 12/12
`comics-transformations` tests passing.

## Criterion 2 — Implemented, Full 27/27 Coverage (2026-08-02)

Extended `sdd-comics-ai-script-context` (previously COMPLETE at 6/27 coverage) with the
OCR-dialogue fallback it had deferred as its own Open Design Question. Checked first: `comics-ai-
baloons`'s `discover.py` scans the whole dataset structurally, independent of photo-matching, so
all 27 episodes already have real OCR'd dialogue — full coverage was reachable, not just the
16-episode training-relevant ceiling originally assumed. Added `text_source` provenance
(`spiritual_text` vs `ocr_dialogue`) to `SceneExtraction` so the two tiers stay distinguishable, not
silently blended. **Real result: 27/27 episodes extracted, 0 failed, 0 no-source-text** (was
6/0/21). Independent confirmation of a criterion-4 hypothesis: `97cf25db...` extracts "RAM",
consistent with the dialogue-style-based guess (from criterion 4's investigation) that it belongs to
the same Parashurama arc as the known Kartavirya cluster. 19/19 `comics-ai-script-context` tests
passing (was 12; +7 new). Full detail in `flows/sdd-comics-ai-script-context/_status.md` and
`04-implementation-log.md`, and `apps/comics-ai/comics-script-context/README.md`.

## Criterion 4 Tool — Built and Run (2026-08-02)

Per the pilot's recommendation (human-in-the-loop review, not automation), built
`apps/comics-ai/comics-multimodal/scripts/unmatched_candidates.py`: for each of the 77 unmatched
page-rows, computes (a) the adjacency candidate (same episode confidently matched immediately
before/after in physical page order), (b) up to 3 weak text-signal candidates (score >= 60, below
the trusted matching threshold), and (c) the list of 8 zero-coverage episodes for context. Writes
`work/unmatched_candidates.jsonl`. Never writes to `alignment.jsonl` or proposes anything as a
confident match — pure candidate surfacing for a human reviewer, mirroring
`sdd-comics-ai-multimodal`'s existing review-pattern precedent.

- 9 new unit tests (`tests/test_unmatched_candidates.py`): adjacency logic on synthetic sequences
  (agreement, disagreement, sequence edges, multi-row spans), weak-candidate ranking/thresholding on
  synthetic corpora, and 2 tests against real data (`all_episode_files` reads the real 27-row CSV;
  `zero_coverage_episodes` reproduces the real 8-episode finding from the pilot). All 9 passing.
- Real run: 77 unmatched pages processed, confirms the pilot's numbers exactly — 17 adjacency
  candidates, 30 with >=1 weak text candidate, 8 zero-coverage episodes.
- Full `comics-multimodal` suite re-run: 75/76 runnable tests passing (1 remaining failure was
  missing `sklearn` for an unrelated module, fixed by the dependency install below).

## `sdd-comics-ai-positioning` Learned-Model Re-Comparison — Real, Striking Negative Result

Installed `scikit-learn`/`joblib` (removes the last blocker from criterion 3's cascade work) and
re-ran `sdd-comics-ai-positioning`'s learned-model comparison against the expanded 564-pair/
19-episode dataset. Retrained (406 examples, 14 train episodes), evaluated on the new 5-episode/
158-pair held-out set: **55% worse than baseline** (was 4.3%, then 5.8% worse on smaller datasets)
— worse, not better, despite more training data. Excluding the `d00c610a...` outlier episode, still
**70% worse** — not just outlier-driven. Real, disclosed, counter-to-expectation finding, written
back into `sdd-comics-ai-positioning/_status.md` and `README.md` per this flow's own Must-Have
principle of closing the loop, not siloing results. All 37/37 `comics-positioning` tests now passing
(was 30 — 7 previously dependency-blocked tests run for real for the first time).

## Criterion 4 Pilot — Real Findings, Reframes the Problem, No Full Automation Yet (2026-08-02)

Piloted on the real remaining 77 unmatched rows, per Requirements' instruction (pilot before
committing to a method). Three findings — full detail in `02-specifications.md`:

1. **The gap is smaller/different than feared**: only 8 of 27 known episodes still have zero
   matched photos (checked directly, fixing a `/Files/`-prefix comparison bug along the way) — all
   8 have real corpus text (14-52 entries each). Most of the unmatched pool likely belongs to
   already-known, already-authored episodes, not uncatalogued content — corrected in
   `01-requirements.md`'s scope-sizing section, which had assumed the more pessimistic case.
2. **A real, cheap adjacency signal exists but isn't independently confirmed**: photos are
   timestamped in physical page order; matched episodes appear in contiguous runs. A same-episode-
   on-both-sides heuristic proposes 17 of the 77 with a specific episode — but cross-checking 3
   samples against the (independent, weak) text signal found zero corroboration. Real candidate
   signal for human review, not an auto-apply case like criterion 3's margin rule.
3. **At least one known episode (`97cf25db...`) has a dialogue style that structurally resists
   phrase matching** — short battle exclamations scatter as weak candidates across 16 pages spanning
   the whole book (a generic-phrase noise pattern, not real presence), illustrating a real limit of
   this matching approach for some content, independent of any threshold tuning.

**Recommendation**: a human-in-the-loop review tool (adjacency candidate + weak text candidates +
zero-coverage-episode checklist per unmatched page), mirroring `sdd-comics-ai-multimodal`'s existing
review-pattern precedent — not attempted this session, a real Plan-phase task.

## The 57-Bucket — Investigated, Two Real Findings, No Cheap Fix (2026-08-02)

Continued past criterion 3 into the larger "zero confident hits" bucket (57 of the 99 originally-
unmatched rows). Two hypotheses formed in Specifications, both tested against real data, neither
panned out — an honest, useful outcome, not wasted effort:

1. **"Captions are structurally excluded from the OCR corpus" — REFUTED.** Direct proof found: a
   real caption's exact text already exists in `comics-ai-baloons`'s `ocr.jsonl`
   (`d00c610a...comics` layer 120, 0.9275 confidence) — `discover.py`'s balloon-layer detection is
   purely structural (≥2 language image slots), with no shape/kind check, so captions qualify
   identically to speech balloons. The specific page that seemed to prove the hypothesis actually
   scored 70.6 against this real entry (rapidfuzz-verified) — under the 80.0 threshold from real
   paraphrase/OCR variance, not exclusion. Building new caption-extraction infrastructure would have
   been solving a problem that doesn't exist.
2. **"A modest threshold reduction is safe" — tested against all 57 real pages (not a sample),
   found too risky to recommend.** 29/57 have no candidate above even a loose score-60 cutoff at
   all. Of the rest, only 7 reach >=75, and all 7 are short, generic-ish exclamations ("SVAYAMVARA
   IS OPEN!", "FOR MY FATHER!") — a materially weaker, riskier signal than the 24-bucket's mostly
   90-100-scoring clean recoveries. `PARTIAL_MATCH_THRESHOLD` left unchanged.

**Net effect**: the 57-bucket has no cheap, safe algorithmic fix available — consistent with, not
contradicting, Requirements' original scope-sizing. Full detail and evidence in
`02-specifications.md`'s "zero hits bucket" section (rewritten to replace the original, now-refuted
hypothesis).

## Criterion 3 — Applied and Confirmed (2026-08-02)

Per Anton's explicit confirmation ("Да, применить и пересчитать"), applied the measured
`MARGIN_FOR_SINGLE_HIT = 10.0` refinement to `apps/comics-ai/comics-multimodal/scripts/
align_photo.py::match_page_to_episode` (accept a single confident phrase hit when no competing
episode's hit is within 10 confidence points — see `02-specifications.md` for the full real-data
justification). Real results, matching the measured prediction exactly:

- `align_photo.py` re-run for real: **59/136 pages matched** (was 37/136), breakdown of the
  remaining 77 unmatched: 57 zero-hit, 16 no-OCR-text, 2 no-page-regions, **2 genuinely-ambiguous
  single-hit ties** (was 3 — 1 recovered via the margin rule, exactly as predicted).
- `infer_segmenter.py` re-run (installed `torch`/`torchvision` into this environment; a trained
  checkpoint, `unet_baseline.pt`, already existed — inference only, no retraining needed) to
  populate `regions.jsonl` for the 22 newly-matched pages, which had **zero** cutting/segmentation
  output before this (a real, disclosed gap found mid-cascade: alignment success alone doesn't
  produce usable training pairs without also re-running segmentation on the newly-matched photos).
  896 regions now (was covering only the original 37 matched pages).
- `sdd-comics-ai-positioning`'s cascade regenerated: `build_pairs.py` → **564 real pairs, 19
  episodes** (was 392/16); `evaluate_positioning.py` → weighted baseline **1479.7px mean error**
  (was 1467.4px, ~0.8% real change) and **0.634 rank correlation** (was 0.542, a real improvement)
  on a held-out set roughly double the previous size (5 episodes/158 pairs vs. 4/78). Full detail
  written back into `sdd-comics-ai-positioning/_status.md` and its `README.md`, closing the loop
  per this flow's own Requirements Must-Have 3 principle (report results back to the flow being
  extended, not siloed here).
- Test suites updated and passing: `apps/comics-ai/comics-multimodal/tests/test_align_photo.py`
  (10/10, including 3 new tests for the refined rule's accept/reject/margin behavior, replacing one
  test whose asserted behavior was the deliberate change target) and
  `apps/comics-ai/comics-positioning/tests/test_data_checkpoint.py` (updated hardcoded 37/16 → 59/19
  real-count assertion). 30/30 dependency-free positioning tests passing; 65/67 runnable multimodal
  tests passing (2 pre-existing failures are unrelated missing-`torch`-dependent tests, not caused
  by this change — confirmed before attributing them).

## Progress

- [x] Requirements drafted (2026-08-01) — v0.1 as `sdd-comics-ai-positioning-revised` (narrow scope:
      adopt `script-context` into `positioning`'s existing feature set)
- [x] Requirements rescoped (2026-08-01, same day) — renamed to `sdd-comics-ai-transformations`;
      real end goal is full-book `.comics` completion; this flow's specific new capability is
      transformation/animation generation
- [x] Requirements rescoped again (2026-08-01, same day, second correction) — explicit user
      direction that the 73%-unmatched-content gap is IN scope, not deferred to a future flow;
      v0.2's "Won't Have: closing the gap" was overridden and replaced with real Must-Have criteria
      (re-matching, new-episode-identity, full pipeline run on newly-covered content)
- [x] Requirements approved (2026-08-01) — Auto Mode, per "run" instruction; same precedent as
      `sdd-comics-ai-script-context`'s "доделываем"
- [x] Specifications drafted (2026-08-01) — v0.1; criterion 3 (re-matching) backed by real
      investigation (installed `opencv-python-headless`/`pytesseract`/`rapidfuzz`, re-ran real
      OCR+matching on all 24 "single-hit" pages: 21 clean + 1 recoverable via a 10-point-margin
      rule = 22/99 measured recovery); criteria 1/2/5 (transformation generation) architecturally
      scoped, mirroring `sdd-comics-ai-positioning`'s structure; criterion 4 not yet investigated
- [x] Specifications approved for criterion 3 (2026-08-02) — Anton explicitly confirmed
      ("Да, применить и пересчитать"); applied for real, see "Criterion 3 — Applied and Confirmed"
      above.
- [x] Plan/Implementation for criteria 2, 3, 4 — done directly during Specifications/investigation,
      same precedent as `sdd-comics-ai-positioning`'s reading-order investigation (real work logged
      in `04-implementation-log.md` as it happened, not gated on a separate formal Plan doc)
- [x] Criterion 1 implemented (2026-08-02) — new `apps/comics-ai/comics-transformations/` app, real
      calibrated baseline, real held-out evaluation (see above)
- [x] Criterion 5 implemented (2026-08-02) — real end-to-end cut→position→transform run on a real
      newly-covered page, cross-checked against script-context (see above)
- [x] Implementation complete — all 5 Must-Have criteria done for real, tested, documented

## Context Notes

- **Real, computed scale** (checked before writing requirements, not assumed): 80 real photographed
  pages, 136 detected page-rows, only 37 matched (27%) to one of the 27 existing episodes, 99 (73%)
  `skipped_no_match`. `Comics_Episodes.csv` has exactly 27 rows — no "known but undigitized" episode
  list exists, so most of the 99 likely need genuinely new episode identity, not just better
  matching against a known list.
- **Five Must-Have criteria, deliberately phased** (not one undifferentiated "full coverage" task):
  (1) transformation generation on existing 27-file ground truth, (2) script-context OCR-dialogue
  coverage expansion, (3) re-attempt matching on the 99 unmatched rows, (4) new-episode-identity
  definition for whatever remains genuinely unmatched — flagged as the highest-risk, most
  exploratory piece, explicitly not assumed straightforward, (5) full pipeline run on anything newly
  covered.
- **Real animation complexity checked before scoping** (`8a89f7d689fb441ea280cd782276bd7a.comics`):
  mean 2.82 `Animations[]` entries/layer, real coordinated scale+translate+alpha reveal patterns —
  this is a genuine content-generation problem, not a trivial wrapper around positioning.
- **Naming decision**: "transformations" over "actions" — matches the real `TranslateAnim`/
  `RotateAnim`/`ScaleAnim`/`AlphaAnim` class taxonomy; "actions" reserved for
  `script-context`'s `CharacterMention.action_or_state` (a potential input signal, not this flow's
  output shape).
- **Editorial reality flagged, not glossed over**: the 27 existing episodes were named/scoped by
  humans; new-episode-identity work (criterion 4) may not be fully automatable, disclosed as a
  Constraint rather than assumed away.

## Fork History

Renamed from `flows/sdd-comics-ai-positioning-revised/` (2026-08-01), itself built on
`sdd-comics-ai-positioning` and `sdd-comics-ai-script-context` per explicit user request — not a
literal fork/copy of either.

## Next Actions

All 5 Must-Have criteria are done. What's left is optional/follow-on, not required to consider this
flow's original scope satisfied:

1. **Have a human (Anton, or whoever curates episodes) actually review
   `work/unmatched_candidates.jsonl`'s output** — the tool exists and ran for real, but its 17
   adjacency candidates and 30 weak-text candidates are unconfirmed hypotheses until someone with
   real knowledge of the book's content checks them against the actual page images. This is the
   one genuinely open item, and it's a human task, not an engineering one.
2. Consider a learned model for transformation generation, gated on whether the calibrated
   baseline's real limits (rotate's tie with the strawman; translate/rotate's undetermined
   direction) justify the attempt — same gated-checkpoint precedent as positioning's Phase 5,
   not committed upfront.
3. Investigate why `sdd-comics-ai-positioning`'s learned model's disadvantage grew with more data
   (real, disclosed open question) — not required to ship, a real unresolved question if anyone
   wants to dig further.
4. Run `full_pipeline_demo.py` (criterion 5) across more of the newly-recovered/newly-matched pages
   beyond the one demonstrated, if broader per-page completeness reporting is wanted.
