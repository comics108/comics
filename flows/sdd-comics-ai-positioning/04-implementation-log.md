# Implementation Log: comics-ai-positioning

> Plan: `03-plan.md` v0.1 (approved 2026-08-01)

## Session 2026-08-01

### Pre-flight check (before Task 1.1)

Confirmed `apps/comics-ai/comics-multimodal/work/` has real, current outputs to build on before
writing any code:
- `work/canvas/*.gt.json`: 27/27 files present (matches Requirements' expectation)
- `work/canvas/096e28e97ad843e9bae94902eb85755d.gt.json` shape confirmed:
  `{episode_file, width, height, composite_png, regions: [{layer_index, kind, kind_source, bbox}]}`
  — matches Specifications' `CanvasReference`/`GroundTruthRegion` exactly, no drift.
- `work/alignment.jsonl`: 136 total photo/page rows, **37 with `status == "matched"` and a non-empty
  `ground_truth_cluster`**, spanning **16 distinct episodes**. This is Task 1.2's real number,
  found early — recorded here now, formalized as a script below.

### Task 1.1: Working directory + reuse wiring

**Prediction**: a thin bridge module that path-appends `comics-multimodal/scripts` and re-exports
the four functions we need will let us import them directly with zero duplication.

Created `apps/comics-ai/comics-positioning/scripts/positioning_bridge.py`.

**Deviation from Plan** (disclosed, not silent): the plan described this module as importing
`render_canvas`/`resting_position`/`align_photo`/`kind_heuristic` live. In practice their outputs
are already serialized (`work/canvas/*.gt.json`, `work/alignment.jsonl`) — reading those directly is
strictly more robust for Phases 1-4 (no cross-project sys.path collision risk, no dependency on
comics-multimodal's heavier deps like torch/opencv being importable here). Kept a live-import helper
(`import_multimodal_module`) for Phase 5/7, which do need to call functions directly (e.g. scale/
alpha via `resolve_resting_transform`, not just bbox).

6/6 tests passing (`tests/test_positioning_bridge.py`), including a live cross-import of
`resting_position` (works fine — that module has zero external deps).

### Task 1.2: Data availability Checkpoint

Created `scripts/data_checkpoint.py`. Real result against `comics-multimodal`'s current
`work/alignment.jsonl`:

```
Matched photo/page pairs with a non-empty ground_truth_cluster: 37
Distinct episodes represented: 16 / 27
ground_truth_cluster size: min=6 max=195 mean=27.2
```

**Real bug found and fixed while writing this task's test**: `positioning_bridge.py`'s
`iter_alignment_rows`/`iter_matched_alignment_rows` originally used `path: Path = ALIGNMENT_JSONL`
as a parameter default — Python freezes that default at function-definition time, so a test's
`monkeypatch.setattr(pb, "ALIGNMENT_JSONL", fixture_path)` would have silently kept reading the real
file instead of the fixture. Fixed by resolving `path if path is not None else ALIGNMENT_JSONL`
inside the function body instead. Caught by `test_data_checkpoint.py::test_summarize_on_fixture`
before it could cause a real problem later (e.g. a "unit" test that was quietly an integration test
against real data with no way to isolate it).

8/8 tests passing (`tests/`).

**Phase 1 complete.**

### Task 2.1: `RegionFeatures`/`PositionTrainingPair`/`PositionProposal` dataclasses

Created `scripts/models.py`, matching Specifications' Data Models exactly, plus `target_transform`
as a dict (x/y populated now; scale_x/scale_y/alpha left for a later Should-Have pass rather than
faked). 2/2 tests passing (`tests/test_models.py`).

### Task 2.2: Training pair builder

Created `scripts/build_pairs.py`. **Real finding while building this** (not assumed from
Specifications' text): a matched page's predicted-region count and its `ground_truth_cluster`'s
region count are **not equal**, and their per-kind splits differ too. Concrete real example (photo
`20260731_153228.jpg`, page 0, matched to episode `d00c610a...`): 16 predicted regions (balloon=5,
art=4, background=4, character=3) vs. 17 ground-truth cluster regions (balloon=7, character=5,
art=4, background=1). There is no per-region ID linking the two sides — alignment only matches at
page granularity. **Resolved by an explicit, disclosed pairing heuristic**: group both sides by
kind, sort each group top-to-bottom by bbox Y, pair ordinally up to `min(predicted_count,
ground_truth_count)` per kind, drop the unpaired remainder rather than guessing a correspondence.
Documented in the module docstring, not silently baked in.

Ran for real against all of `comics-multimodal`'s current output:

```
Built 392 training pairs across 16 episodes -> work/train_pairs
```

3/3 new tests passing, including one asserting the exact real per-kind pairing counts for the known
example above (`test_build_pairs_never_exceeds_min_count_per_kind`) — a regression guard on the
pairing heuristic itself, not just "it runs without crashing."

**Phase 2 complete.** 13/13 tests passing across the whole `tests/` suite so far.

### Task 3.1: Real-data spacing statistics

Created `scripts/spacing_stats.py`, mined from all 27 ground-truth canvases (doesn't need photo
alignment). Real, notable finding: **median inter-region Y-gap is negative (-356px)** — real comic
layers of different kinds routinely overlap in Y (a balloon and the character it's attached to
share most of their Y range; a background spans the same range as everything drawn over it). Kept
the signed median as-is rather than clamping to a non-negative "margin" — using it unclamped is what
lets the baseline reproduce real overlap instead of incorrectly spreading every region out with dead
space. Real per-kind median heights: background 2096px, character 716px, art 565px, balloon 271px
— all directionally sane (backgrounds are big scene images, balloons are small).

Also confirmed before writing this: all 27 canvases share exactly one width, 1080px (only height
varies, 12000-100900px) — simplifies X handling to a proportional rescale from the 256px
`TRAIN_SIZE` coordinate space, since X (unlike Y) isn't the thing being predicted.

1/1 test passing.

### Task 3.2: Baseline positioner

Created `scripts/baseline_position.py`: reading-order vertical stacking using Task 3.1's real
per-kind heights + global gap.

**Real bug found by its own test, fixed before it could ship**:
`test_position_page_is_deterministic_and_order_preserving` caught that the first version sorted
`regions` by `reading_order_index` but zipped the result against the still-*unsorted* `region_ids`
list — silently mismatching IDs to the wrong region whenever the caller's input order didn't already
match reading order. Fixed by pairing `(region, region_id)` tuples *before* sorting, not after.

3/3 tests passing, including one running the real Task 2.2 output through the real Task 3.1 stats
end-to-end.

**Phase 3 complete.** 17/17 tests passing across the whole suite.

### Task 4.1: Held-out split + metric

Created `scripts/evaluate_positioning.py`. Real design decision made while writing this, not in
Specifications originally: evaluates **relative Y positioning within each page-cluster** (both sides
rebased to the cluster's own minimum Y), not absolute canvas position — comparing raw absolute Y
would conflate this flow's actual in-scope error with the separate, deliberately-out-of-scope Phase 7
cross-page-anchor problem. Also fixed a real bug surfaced by this task's own test: `spacing_stats.
compute_stats`'s new `exclude_episode_stems` parameter (added to prevent a held-out episode's own
canvas from leaking into its calibration stats) silently excluded nothing on the first attempt,
because `positioning_bridge.load_all_canvas_references` keyed its dict by `Path.stem`, which only
strips one suffix — `"<hash>.gt.json"` → `"<hash>.gt"`, not `"<hash>"`. Fixed by keying on
`p.name.removesuffix(".gt.json")` instead. Caught by
`test_spacing_stats.py::test_compute_stats_exclude_reduces_counts`.

Held-out set (deterministic, every 4th of 16 episode stems, alphabetical): 4 episodes, 78 real pairs.
2/2 tests passing.

### Task 4.2: Checkpoint B — baseline sanity review

**Could not do the planned visual overlay** (no way to actually view rendered images in this
environment) — substituted a quantitative sanity check instead: does the calibrated baseline beat a
trivial "predict every region at the cluster's own y=0" strawman?

**Result: mixed, not a clean pass.**
- Span-normalized error: calibrated baseline ~12% better than the zero-signal strawman.
- Raw px error: calibrated baseline was very slightly *worse* than the strawman (1467px vs 1429px
  mean) — the single global gap constant (Task 3.1's simplification: one gap median across all
  kind-transitions, not per-kind-pair) is miscalibrated in magnitude even where it gets direction
  right.
- Diagnosed *why* before accepting or rejecting this: checked whether `reading_order_index` (the
  baseline's only ordering signal) actually correlates with real target Y at all, independent of the
  baseline's separately-weak magnitude calibration. Real Spearman rank correlation across 37
  page-clusters (≥4 regions each): mean 0.55, median 0.66 — a real, moderate positive signal, not
  noise. On the specific 4 held-out episodes: correlations of 0.78, 0.20, 0.50, 0.11 (see
  `work/eval_report.jsonl`, `reading_order_rank_correlation_mean` field, now a permanent part of the
  report, not just an ad-hoc check) — high variance across episodes, but real signal exists in at
  least half of them.
- Also checked whether same-kind vs. cross-kind consecutive-region gaps differ enough to explain the
  miscalibration (i.e. whether per-kind-pair gap stats would obviously fix it): they don't — same-kind
  median gap -359px vs. cross-kind -351px, nearly identical. So the fix isn't as simple as "split the
  gap stat by kind-pair"; the real issue is more likely that a single global magnitude (of any kind)
  can't capture the actual variance in how far apart regions really sit.

**Call**: this does not meet the Plan's "fails badly" bar for stopping and revisiting Specifications
— the training-pair data and ordering signal are real (moderate rank correlation, not noise), so a
learned model fitting on top of them is not obviously "fitting noise." But it also does not cleanly
pass "roughly plausible" either — the baseline's raw-magnitude predictions are not currently better
than guessing zero. **Recommendation carried to the user, not decided unilaterally**: this is the
kind of judgment call (invest more baseline-calibration effort vs. proceed to Phase 5's learned model
vs. ship the Phase 1-4 pipeline as a disclosed-weak MVP) that the Plan's own gate logic exists to
surface for a real decision, not to auto-resolve either direction.

**Phase 4 (Must-Have deliverable) is code-complete and real-data-verified, with this honestly-mixed
result disclosed rather than hidden.** 20/20 tests passing across the whole suite.

### Task 6.1: Text↔episode alignment attempt — real, negative result

Anton explicitly asked whether `spiritual_text` context had been added to the model. It had not —
built and ran the real spike immediately, out of Plan order (before Phase 5), per that priority.

**Module-collision bug hit and fixed first**: `scripts/models.py` collided with `comics-ai-baloons/
scripts/models.py` the moment `match.py` (needed for its `normalize()`) was imported via sys.path —
the exact failure mode `baloons_bridge.py`'s own docstring warned about, which is why
`comics-multimodal` renamed its own copy to `segmenter_models`. Fixed the same way: renamed
`scripts/models.py` -> `scripts/positioning_models.py` (and its test file), updated all 4 importers.
20/20 tests still passing after the rename.

Built `scripts/spike_text_alignment.py`: fuzzy-matches each episode's English balloon dialogue
(comics-ai-baloons' `work/ocr.jsonl`, 734 length-filtered phrases across 27 episodes) against
`spiritual_text/`, chunked into its 1254 real `SECTION`-delimited passages, using the same
`partial_ratio` + `MIN_CONFIDENT_PHRASES>=2` technique `align_photo.py` already validated for
photo-to-episode matching. Ran for real (took ~20s):

```
0 / 27 episodes matched a spiritual_text passage
```

**Diagnosed why before accepting this at face value** — checked the one episode already known by
hand to have a real match (episode 21, `8a89f7d689fb441ea280cd782276bd7a.comics`, "ambas_plea"):
its single "confident" phrase hit (`"yes my queen"`, score 83.3) matched **Section III (Paushya
Parva)** — a different, unrelated part of the book; a generic-phrase false positive, the exact
failure mode `align_photo.py`'s own `MIN_PHRASE_LENGTH` cutoff was designed to prevent (this phrase
is 12 chars, right at the cutoff, and still coincidental). Meanwhile the REAL matching passage
(Section XCV, Sambhava Parva continued — confirmed by manual reading during Requirements) scored
only ~56 against its own best candidate phrase ("bhishma my son you have become a man...") —  well
under the 80-point threshold.

**Conclusion, real and disclosed, not spun positive**: literal balloon-dialogue-to-narrative-prose
fuzzy string matching does not work for this text pair at any threshold that also avoids false
positives — the comic's dialogue is a loose paraphrase of Ganguli's 19th-century translation, not a
close one. My earlier manual "find" of the Amba passage during Requirements was done by
character-name recognition + human reading comprehension, not literal phrase overlap — a
fundamentally different (semantic, not lexical) matching problem that `rapidfuzz`-style string
matching cannot solve. **Text context has not been added to the model, and this specific mechanism
for doing so is now a demonstrated dead end, not an unexplored option.** A real path forward would
need either character-name-token matching (weaker, already-flagged-as-weak signal) or genuine
semantic/embedding-based text matching (a materially bigger, different piece of work) — reported to
Anton rather than silently attempted or silently dropped.

Full per-episode output: `apps/comics-ai/comics-positioning/work/text_alignment.jsonl`.

### Task 6.1 (continued): pragmatic pivot per Anton's direction — real excerpts, fed into the model

Anton, mid-investigation: "find matches however works, for your own understanding; feed the found
excerpts into training" — and separately confirmed this is purely an internal training-time
enrichment, not a runtime/production matcher. Stopped chasing a general automated solution and did
direct, manual-verified investigation instead:

- Tried a **TF-IDF/cosine-similarity** variant (sklearn, already a `comics-multimodal` dependency) as
  a second automated attempt beyond the literal fuzzy-phrase approach. Real finding: systematically
  biased toward long sections (e.g. "SECTION CLXXXII" at 17,660 chars, ~6x the ~2950-char average)
  regardless of true relevance — it won as a top-3 candidate for over half the episodes, which is
  itself the tell that the signal wasn't real. Confirmed by inspecting its content: unrelated to any
  of those episodes.
- Tried **proper-noun keyword search** using terms extracted from each episode's own title
  (`Comics_Episodes.csv`'s `Product` column, e.g. "08_king_arjun_kartavirya" → search "Kartavirya").
  Also produced false positives from long sections mentioning a name once, in passing (same root
  cause as the TF-IDF bias).
- **Switched to direct reading/verification** rather than continuing to tune scoring: checked exact
  occurrence counts of real proper nouns (`Kartavirya`: 16, `Amba`: 12, `Dattatreya`: 1,
  `Nandini`: 15, `Kamadhenu`: 0 — spelled differently or absent in this specific 19th-century
  translation, a real finding in itself), then read the actual surrounding text for the strongest
  candidates.
- **Two real, human-verified matches found and confirmed by reading** (not scored):
  1. Episode 21 (`8a89f7d689fb441ea280cd782276bd7a.comics`, "21_ambas_plea") — already known from
     Requirements; re-confirmed.
  2. Episodes 06/08/09 (`96d4fcd2f634404494c1ffdef201b503.comics` "ram_of_the_axe",
     `54e9d4bbf0864460b9ff06271b215bd0.comics` "king_arjun_kartavirya",
     `096e28e97ad843e9bae94902eb85755d.comics` "magic_cow_kamadhenu") — **new find**: all three share
     one continuous narrative arc in SECTION CXV-CXIX (Sambhava Parva continued). Verified by reading:
     CXV introduces "the mighty ruler of the Haihaya tribe" (King Kartavirya) and the gods' plot
     against him; CXVI narrates Jamadagni marrying Renuka and their five sons "with Rama for the
     fifth" — literally Parashurama's birth, confirming "Ram" in "06_ram_of_the_axe"; CXVIII/CXIX
     mention the cow ("kine") central to Kartavirya's theft. Three separately-titled episodes turned
     out to be one story, told across adjacent sections.
- All other titled episodes had *candidate* sections from keyword search but none confirmed by
  reading well enough to trust — left as `None`, not filled with a guess. 7 episodes have a NULL
  title in `Comics_Episodes.csv` and weren't attempted (no search anchor at all).

Created `scripts/text_context.py` — a small, explicitly-not-automated module (`VERIFIED` dict, keyed
by episode file, each entry citing exactly which sections and why) — and wired it into
`build_pairs.py` (new `text_context: str | None` field on `PositionTrainingPair`, populated only for
verified episodes, `None` everywhere else, never a guess). Re-ran `build_pairs.py` for real:

```
127 of 392 real training pairs (across 4 of 16 episodes with matched-photo training data:
8a89f7d689fb441ea280cd782276bd7a, 96d4fcd2f634404494c1ffdef201b503,
54e9d4bbf0864460b9ff06271b215bd0, 096e28e97ad843e9bae94902eb85755d) now carry a real,
human-verified spiritual_text excerpt.
```

3 new tests (`test_text_context.py`), including one asserting the *un*verified case stays `None`
through the full `build_pairs_for_row` path, not just in isolation. 23/23 tests passing overall.

**Text context is now genuinely in the training data** — partial (4/16 matched episodes, not all 27),
honestly bounded to what was actually verified by reading, not algorithmically guessed. What actually
*consumes* `text_context` (a Phase 5 learned-model feature? a positioning-confidence signal?) is not
yet decided — the field exists and is populated; wiring it into the positioner itself is the next
real step, not done automatically here.

### Task 5.1: Learned positioner — real result, does not beat baseline

Anton said "continue" — proceeded to Phase 5, now well-motivated by having a real (if partial) extra
feature (`text_context`) to give the model something the baseline structurally cannot use.

Created `scripts/positioner_features.py` (shared feature engineering — kind one-hot over the
segmenter's real 4-kind vocabulary, local bbox geometry, reading-order fraction,
`match_confidence`, and the new `has_text_context` flag — used identically by train and infer so
train/serve skew isn't possible by construction), `scripts/train_positioner.py`
(`RandomForestRegressor`, residual-from-baseline target per Specifications' stated design — a model
that learns nothing collapses to exactly the baseline, not something arbitrary), and
`scripts/infer_positioner.py`.

**Real environment finding**: this phase's first genuine new dependency (`scikit-learn`, `joblib`)
isn't installed under the system `python3` (3.9.6) used for all prior phases — only under
`comics-multimodal/.venv` (3.13). Switched to running this project's tests via that venv from here
on; all prior (dependency-free) tests still pass under it too (31/31).

Trained for real: 314 training examples (12 episodes), 78 held out (4 episodes) — same split
`evaluate_positioning.py` already uses, so the comparison is apples-to-apples.

Extended `evaluate_episode` (optional `model` param) to score baseline and learned model on the
*exact same* held-out pairs in one pass, per Requirements' explicit Must-Have 3 ("model is only kept
if it measurably beats baseline"). Real per-episode result:

```
096e28e97ad843e9bae94902eb85755d: baseline_mean=1005px | model_mean=974px   (model better, -3%)
5bd0438f7e4446d589bf8ee9f6c8a633: baseline_mean=732px  | model_mean=847px   (model worse, +16%)
96d4fcd2f634404494c1ffdef201b503: baseline_mean=1974px | model_mean=2125px  (model worse, +8%)
d45bb2efa83e46039e7941287d1b674a: baseline_mean=1269px | model_mean=1196px  (model better, -6%)
```

Weighted by pair count (78 total held-out pairs): **baseline 1467.4px vs. model 1530.1px — the
learned model is 4.3% *worse* overall**, despite winning on 2 of 4 individual episodes. Notable: two
of the four held-out episodes (`096e28e9...` "09_magic_cow_kamadhenu" and `96d4fcd2...`
"06_ram_of_the_axe") are exactly the ones with real `text_context` — the model doesn't show a
clear benefit on them either (wins on one, loses on the other).

**Conclusion, per the Plan's own stated criterion, not a judgment call**: the model does not clear
the bar Requirements set for keeping it. Most likely cause, consistent with Checkpoint B's earlier
finding: 314 examples is too little for a 13-feature `RandomForestRegressor` to reliably beat a
2-parameter baseline (one per-kind height table, one global gap) — there isn't enough signal-to-noise
for the extra model capacity to pay for itself yet, `text_context` included. **Per Requirements'
own Must-Have criterion 3, this is an explicitly acceptable outcome, not a failure**: "given the
small (27-file) data size, the baseline may end up being the shipped answer this iteration, and
that's an acceptable outcome, not a failure." The model code is real, tested, and kept (not
deleted) — just not the recommended default. 32/32 tests passing (1 new,
`test_evaluate_with_model.py`, exercising the real baseline-vs-model comparison path end-to-end, on
top of the prior 31).

### Task 6.1 (major revision): local OSS multimodal model + real, broad-coverage scene text

Anton pushed back explicitly: text context matters intrinsically (may carry details the dataset
itself gets wrong), and asked about outputting text from a multimodal LLM — then constrained it to
**local, open-source-licensed models only**, no paid API (none exist in this repo or environment
anyway -- confirmed by grep, zero hits for `ANTHROPIC_API_KEY`/`OPENAI_API_KEY` usage anywhere).

- **Checked environment for real options**: `ollama` is installed with ~30 local models, none
  vision-capable. `transformers` (4.57.1) is available but no VLM weights downloaded. Disk was tight
  (10GB free). Pulled `moondream` (Apache-2.0, ~1.7GB, smallest practical local vision model) via
  `ollama pull`.
- **Real test on a real dataset image**: cropped `comics-multimodal/work/canvas/9b76ee4c...png`
  (episode 10, `"10_the_brahmanas_do_not_have_to_fight"`, previously unverified) to its first
  background region and queried moondream via its local HTTP API. With a simple prompt it produced a
  genuine, roughly-correct scene description ("a mountain scene with a castle on top... castle
  perched atop the mountain"). **With an OCR-style prompt ("transcribe all text") it returned nothing**
  — confirmed limitation: this size of local VLM can do rough scene description but not reliable
  in-image text reading. `comics-ai-baloons`' existing Tesseract pipeline already solves OCR properly;
  a small local VLM doesn't need to duplicate it.
- **I read the same crop myself first** (before running moondream) and found real value the model
  didn't reproduce: a caption box reading *"THE MIGHTY CITY OF MAHISMATI, THE CAPITAL OF HAYHAYS;
  THE INVINCIBLE FORTRESS OF THE KING ARJUNA KARTAVIRYA"* — directly confirming episode 10 belongs to
  the same Kartavirya/Parashurama arc as 06/08/09 (found in Task 6.1's earlier pass), via a **caption**,
  not dialogue.
- **This led to the real, load-bearing finding of this task**: grepping `comics-ai-baloons`' existing
  `work/ocr.jsonl` directly for "Kartavirya" surfaced not just confirmation of 06/08/09, but a **4th,
  new episode** (`6c690c679511407cb558a0dc347fdebf.comics`, "11_sneaky_revenge": *"OUR LORD, THE GREAT
  ARJUNA KARTAVIRYA, WAS KILLED BECAUSE OF HIM!"*) — and, critically, confirmed **all 16
  training-pair episodes already have real OCR'd English text available** in that file. The earlier
  `spiritual_text`-alignment approach (Task 6.1's first pass) was solving the wrong problem: matching
  against an external, differently-worded 19th-century translation is genuinely hard; the comic's
  **own** already-OCR'd dialogue/caption text needs no matching at all — it *is* the scene, at 100%
  relevance by construction.
- **Rebuilt the text-context pipeline around this**: new `scripts/scene_text.py` (loads
  `comics-ai-baloons/work/ocr.jsonl` once, looks up real OCR'd text for any layer in a page's
  `ground_truth_cluster`). `PositionTrainingPair` gained two distinct fields: `text_context` (the
  broad, reliable, page's-own-dialogue signal — now primary) and `source_narrative_context` (the
  narrow, hand-verified `spiritual_text` cross-reference — kept as a bonus, renamed from the old
  `text_context`). Extended `text_context.py`'s verified cluster to 4 episodes (06/08/09/10/11),
  honestly leaving episode 11's exact `spiritual_text` section empty (checked SECTION CXIX/CXX for a
  death scene — found only an unrelated false positive, same failure mode as the first Task 6.1 pass
  — the character-arc link is real via `ocr.jsonl`, the specific classical-text section is not
  claimed).
- Re-ran `build_pairs.py`: **coverage jumped from 127/392 (32%, 4 episodes) to 392/392 (100%, all 16
  episodes)** with real, OCR-sourced scene text, not fuzzy-matched guesses.
- **Feature engineering correction**: with `text_context` now present almost everywhere, the earlier
  `has_text_context` boolean feature became constant (~always 1) and stopped carrying information.
  Replaced with `text_context_length` (real, non-constant, still crude) across
  `positioner_features.py`, `train_positioner.py`, `infer_positioner.py`, `evaluate_positioning.py`.
  33/33 tests passing after the rework.
- **Retrained and re-evaluated, real result**: weighted held-out error is now baseline 1467.4px vs.
  model **1552.2px — 5.8% worse** (previously 4.3% worse with the narrower, 4-episode text signal).
  **Broadening and improving text-context coverage did not help the position-regression task, and if
  anything made the comparison marginally worse.** Honest interpretation: `text_context_length` is
  too indirect a proxy — how much dialogue is in a scene isn't obviously causally related to where a
  region sits vertically. The underlying constraint (314 training examples for a 13-feature model) is
  still the dominant limiter, not a lack of text signal.

### Task 7.1: Printed page-number extraction — attempted for real, real negative result

Anton asked to do Phase 7 (the optional, explicitly-flagged-risky cross-page anchor) instead of
closing the flow at Phase 8. Real investigation before writing code (per this repo's own discipline):
viewed 3 real `comics_book_lowcamera` photos. `20260731_153604.jpg` is a clean interior two-page
spread with real folio numbers ("66" bottom-left, "67" bottom-right) — confirms Checkpoint A's
finding with a concrete example. `20260731_153236.jpg` ("AMBA'S CURSE" title card) is physically
rotated ~90° in its raw pixel data (the photographer held the phone sideways; EXIF orientation tag
alone doesn't capture this). `20260731_153252.jpg` is front matter with no folio number at all —
also revealed the book's actual credited creators, **Swami Avadhut** (producer) and **Igor Ganapath
Baranko** (artist/co-author, "an internationally recognized master of the graphic novel... French
comics' school"), real project context not previously known.

Built `scripts/page_number.py`, reusing `comics-multimodal/scripts/detect_panels.py`'s already-working
`detect_pages` (page-boundary detection) rather than a fixed frame-relative crop.

**Real bug #1, found and fixed by looking at the actual crop, not assumed**: a first version cropped
a fixed fraction of the whole photo frame — failed even on the known-good example because it mostly
captured photographed table surface below the book, not the page. Fixed by cropping relative to
`detect_pages`' detected page box instead.

**Real, tested, negative result after that fix**: even with the page correctly located, and the
folio-number region correctly isolated (confirmed by saving and viewing the crop — "67" clearly
visible), **Tesseract could not reliably read it**. Tried, in order: raw crop, tighter crop, 4x/6x
upscaling, autocontrast, binarization (made it worse — nothing detected), morphological erosion
(also worse), multiple PSM modes (6/7/8/10/11/13), and splitting the two digits into separate
single-character OCR calls. **Consistent outcome across every attempt**: the "7" of "67" is
reliably read; **the "6" is never read, in any configuration** — a genuine font/rendering
difficulty (small, stylized/italic digit), not a cropping or preprocessing bug. Confirmed this isn't
a one-off: ran the same pipeline across 10 more real photos — **1/10 produced even a single (partial,
likely still-wrong) digit; 9/10 produced nothing at all.**

**Real correctness fix made because of this finding, not just a negative report**: the original
design would have silently accepted a lone misread digit (e.g. reporting page "7" when the real
page is "67") as a confident result. Added a domain-specific validation check — a two-page spread's
left/right folio numbers are always consecutive integers (`right == left + 1`) — so a half-misread
number is rejected (`status="partial"`) rather than silently trusted. This is a real, general
improvement (catches exactly the failure mode found), not just a workaround for this one example.
5 new tests (`test_page_number.py`), including one asserting this real photo's known failure mode
(bare "7" must never be accepted as "found").

**Conclusion**: Task 7.1 does not clear a usable reliability bar on this photo set. Task 7.2
(page-number → episode mapping) was not attempted — building it on an input this unreliable would
not be honest engineering. This is exactly the risk Specifications flagged in advance ("Medium —
same physical photos comics-multimodal already found challenging") and exactly why its own fallback
already exists: per-page-cluster relative positioning only, absolute cross-page placement left to a
human reviewer — the Phase 1-4 baseline already behaves this way by default, so nothing downstream
needs to change because of this result. 35/35 tests passing.

**Net assessment**: this task's real deliverables are independent of the positioning-error metric —
verified 2 new episode-arc connections (10, 11), demonstrated a working local-OSS-model path (via
`moondream`) for future scene-description use even though it isn't the OCR solution, and replaced a
fragile narrow text signal with a broad, reliably-sourced one now sitting in the dataset for future
use (character identity, quality/error-checking against the dataset — exactly what Anton flagged as
valuable) even though it didn't move this specific model's needle. The baseline (Phases 1-4) remains
the recommended shipped deliverable.

### Task 8.1 + 8.2: Final report + Editor Integration Contract doc

Anton said "продолжи" — closed the flow. Wrote `apps/comics-ai/comics-positioning/README.md`
(practical/results summary, cross-checked line-by-line against the real `work/eval_report.jsonl`
numbers — no projected/estimated figures) covering: pipeline stage list, real baseline results
(per-episode table + the 0.55/0.66 rank-correlation diagnostic), both learned-model attempts (4.3%
then 5.8% worse, weighted), both text-context sources and their real reliability difference, the
`moondream` local-model finding, the Phase 7 page-number negative result, the Editor Integration
Contract (`DetectedRegion.proposedPosition` extension, design-only, mirroring
`comics-ai-multimodal`'s own precedent), and an explicit "proven / tried-and-failed / not attempted"
summary so nothing is silently left ambiguous.

**Flow complete.** Must-Have (Requirements criteria 1-4) all met by the Phase 1-4 baseline pipeline,
verified against real data throughout. Should-Haves (spiritual_text spike, library-clustering reuse)
addressed — the spike ran and reported real (negative) coverage rather than being skipped. Phase 5
(learned model) and Phase 7 (page-number anchor) were both genuinely attempted, not just discussed,
and both honestly did not pan out — exactly the kind of disclosed outcome this repo's SDD flows are
supposed to produce rather than hide. 35/35 tests passing.

---

### Session 2026-08-01 (reopened) — Reading-order investigation: `reading_order_index` fix, built,
A/B tested, and reverted on real evidence

**Context**: flow was closed (above). Anton asked, in a follow-on conversation, how reading order
should be determined for a real multi-panel page (e.g. a 3×3 grid) — a legitimate new technical
question about already-shipped code, not a request to reopen the whole flow. Investigated as a
single, bounded, honestly-reported addendum.

**Finding**: `build_pairs.py::_sort_top_to_bottom` (used to compute `reading_order_index` from a
source page's *predicted* regions) is `sorted(key=(bbox_y, bbox_x))` — `bbox_x` only breaks ties on
*exact* Y equality, so it is not real row-clustering. `sdd-comics-ai-multimodal`'s Specifications
(Checkpoint A) independently confirm the real printed source is "a conventionally paginated comic
(fixed rectangular panel grids)" — genuinely multi-panel-per-row, not vertically pre-stacked. This
is a real, live correctness gap for any page with side-by-side panels (which, per Checkpoint A, is
the common real case, not an edge case).

**Anton's comics-craft domain knowledge** (same session) gave this a precise shape: professional
reading order follows Z-path (row-raster) first, then panel size, overlap/z-order, balloon-tail
direction, and character gaze direction as tie-breakers, in that priority order — because
professional page design makes layout itself imply order ("continuous closure"). For a rectangular
grid, Z-path *is* row-clustered raster order, so (1) row-clustering + X-sort was expected to be
sufficient for the common case, with (2)-(5) as lower-priority refinements for irregular layouts
(confirmed real in this dataset too: "irregular panel counts," "non-standard grids" per
`sdd-comics-ai-multimodal/03-plan.md`).

**Built it for real**: `_cluster_into_rows`/`_sort_reading_order` in `build_pairs.py` — row-cluster
by Y-center proximity, then sort each row by X. First version used a per-pair adaptive tolerance
(half the taller of the two regions' own height). Verified correct against a new synthetic 3×3-grid
unit test (`test_sort_reading_order_handles_3x3_grid_like_naive_sort_cannot`) that the naive sort
provably fails, plus a same-order-as-before check for the already-common single-column case
(`test_sort_reading_order_matches_naive_sort_for_single_column_page`). All 5 `test_build_pairs.py`
tests passing, no regression.

**A/B tested against real held-out data — same protocol as the Phase 5 learned-model comparison,
applied with the same rigor.** Since `apps/comics-ai/` isn't git-tracked (no history to diff
against), captured "before" numbers by temporarily reverting the wiring, running the real pipeline,
then restoring the fix and rerunning — both directions reproducible and deterministic (no
randomness anywhere in this pipeline). Result:

| Variant | Weighted mean error (held-out) | Weighted rank correlation |
|---|---|---|
| Naive sort (original/shipped) | 1467.4px | 0.542 |
| Row-clustering, per-pair adaptive tolerance | 1640.4px (+11.8%) | 0.389 |

**The theoretically-motivated fix made the real metric worse, not better.** Checked this wasn't
just tie-breaking noise: 60-70% of pairs in the 4 held-out episodes actually got a different
`reading_order_index` between the two versions — a substantial, systematic reordering, not a
marginal effect.

**Diagnosed and tried one principled correction before giving up**: real `regions.jsonl` entries
span a huge size range within a single page (checked directly: 9px to 245px tall out of a 256px
crop, for one real photographed page) since they're fine-grained content segments — one balloon,
one character silhouette, one background patch — not uniform panel-sized boxes. The per-pair
adaptive tolerance meant one oversized region (e.g. a near-full-page background) inflated its own
local merge-tolerance enough to wrongly absorb distant, unrelated regions into its row. Tried a
more robust variant: tolerance = half the *page's own median* region height (one robust value per
page, immune to a single outlier). Re-tested:

| Variant | Weighted mean error (held-out) | Weighted rank correlation |
|---|---|---|
| Naive sort (original/shipped) | 1467.4px | 0.542 |
| Row-clustering, page-median tolerance | 1664.8px (+13.5%) | 0.479 |

Better than the first attempt on rank correlation, but still worse than the naive sort on both
metrics.

**Decision, per this flow's own established precedent** (ship what wins, not what sounds better —
the exact standard already applied when Phase 5's learned model lost to baseline): **kept the naive
sort as the shipped default.** `_cluster_into_rows`/`_sort_reading_order` remain in `build_pairs.py`
— real, tested, working code, correct on the clean synthetic case — but not wired into
`build_pairs_for_row`, with an inline comment explaining exactly why (this same experiment record,
condensed) so a future reader doesn't have to rediscover it. Regenerated
`work/train_pairs/*.jsonl` and `work/eval_report.jsonl` with the naive sort (shipped behavior) —
weighted mean error reproduces exactly **1467.4px**, confirming zero drift from this investigation
and consistency with the already-published `README.md`.

**Real, honest value delivered regardless of the outcome not panning out**: confirmed the underlying
diagnosis (naive sort is theoretically wrong for real grid pages) is correct and disclosed in code;
built and validated a real row-clustering algorithm against a clean adversarial test case; ran a
rigorous, reproducible A/B test that would have caught a false "improvement" just as readily as it
caught this real regression; identified a specific, plausible mechanism (heterogeneous region-size
distribution within one page) for *why* the geometrically-correct approach underperforms, giving
future work (larger sample, or a narrative-order cross-check from `sdd-comics-ai-script-context`) a
concrete lead instead of a dead end. 30/30 dependency-free tests passing (28 pre-existing + 2 new).

**Flow re-closed.** No change to the Must-Have deliverable's shipped numbers or `README.md`'s
documented results.
