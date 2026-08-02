# Status: sdd-comics-ai-positioning

## Current Phase

IMPLEMENTATION

## Phase Status

COMPLETE (Phases 1-8 all done, per `04-implementation-log.md`'s Task 8.1/8.2 entry and the real
`apps/comics-ai/comics-positioning/README.md` it produced — this section below had drifted stale,
still describing Phase 7 as the latest state; corrected 2026-08-01 while investigating the
reading-order finding below, which reopened this closed flow for one real fix-and-A/B-test session,
now re-closed with no change to the previously-shipped/documented numbers).

Phases 1-6 done (Must-Have baseline pipeline, held-out evaluation, real text-context
now covering all 16 training episodes via the comic's own OCR'd dialogue, learned model trained and
honestly evaluated against baseline, including a local-OSS-multimodal-model detour). 33/33 tests
passing. **Net result of Phases 4 and 5 together, even after upgrading text context to 100%
coverage**: the calibrated rule-based baseline remains the best real deliverable — the learned model
does not beat it (5.8% worse, weighted, with full text coverage; was 4.3% worse with partial
coverage). Per Requirements' own Must-Have criterion 3, shipping the baseline alone is an explicitly
acceptable outcome.

**Phase 7 (optional, cross-page page-number anchor) attempted for real, real negative result.**
`page_number.py` reuses `comics-multimodal`'s `detect_pages` to locate the real page box (a fixed
frame-relative crop failed first — caught by viewing the actual crop). Even with the page and folio
number correctly located, **Tesseract cannot reliably read this book's small, stylized digits**:
tried raw/tighter crops, 4x-6x upscaling, autocontrast, binarization, erosion, 6 PSM modes, and
per-digit splitting — the "7" of a real "67" is read consistently, the "6" is *never* read, across
every configuration tried. Confirmed systematic (not a one-off) on 10 more real photos: 1/10 got even
a partial digit, 9/10 got nothing. Added a real correctness fix regardless (a two-page spread's
folio numbers must be consecutive integers — `right == left + 1` — rejecting a lone misread digit
instead of silently trusting it). Task 7.2 (page-number → episode mapping) was not attempted — not
honest to build on an unreliable input. This is exactly the risk Specifications flagged in advance;
its own fallback (per-page relative positioning, human handles absolute placement) already covers
it — nothing downstream needs to change. 35/35 tests passing.

**Reading-order investigation (2026-08-01) added, tested, A/B'd, and ultimately did not change
shipped behavior** — see Blockers for the full record. 30/30 dependency-free tests still passing
(added 2 new tests for the investigated-but-unadopted row-clustering code); `work/train_pairs/` and
`work/eval_report.jsonl` regenerated, numbers unchanged from before this investigation (1467.4px
weighted baseline mean error). Phase 8 (report/contract docs) was already done in an earlier
session — `apps/comics-ai/comics-positioning/README.md` exists and its documented 1467px baseline
number matches exactly, confirming no drift from this investigation.

**Data expansion (2026-08-02), from `sdd-comics-ai-transformations`'s re-matching refinement.**
That flow measured and (with Anton's explicit confirmation) applied a refined single-hit matching
rule to `comics-multimodal`'s `align_photo.py`, recovering 22 of 99 previously-unmatched pages —
real matched pages/episodes went from 37/16 to **59/19**. Cascade regenerated here: `build_pairs.py`
(392 → **564 real pairs**), `evaluate_positioning.py` (4-episode/78-pair held-out set → **5
episodes/158 pairs**). New weighted baseline: **1479.7px mean error** (was 1467.4px — real, honest
~0.8% change, not treated as a regression or improvement on its own) and **0.634 rank correlation**
(was 0.542 — a real improvement, on a held-out sample roughly double the previous size). Net
finding: more real data confirmed the baseline's performance level with higher statistical
confidence, rather than changing it. One new real outlier surfaced: held-out episode
`d00c610a6f4647dcbd8116014674d255` has 6120px mean error (14.7% of its canvas height) — flagged,
not investigated further this pass. `apps/comics-ai/comics-positioning/README.md` updated with the
new numbers. One hardcoded test (`test_data_checkpoint.py::
test_summarize_on_real_data_matches_manual_count`) updated from `37/16` to `59/19` to match the new
real counts.

**Learned-model re-comparison, same day, `scikit-learn`/`joblib` installed to make it possible.**
Retrained on the expanded 406-example/14-episode training set, evaluated on the new 5-episode/
158-pair held-out set: **55% worse than baseline** (2294px vs. 1480px weighted), worse than either
prior attempt (4.3%, then 5.8%). Excluding the `d00c610a...` outlier, still **70% worse** (1804px
vs. 1064px) — not just outlier-driven. Real, disclosed, counter-to-expectation finding: more data
made the model's relative disadvantage larger, not smaller. Plausible (unconfirmed) explanation:
the newly-recovered episodes' pairs come from lower-confidence single-hit matches, possibly noisier
than the model can generalize past, while the baseline's simpler per-kind median statistic is more
robust to that noise. **Recommendation to ship the baseline only stands, now on stronger evidence.**
Full detail in `apps/comics-ai/comics-positioning/README.md`. All 37/37 tests passing (was 30 —
7 previously dependency-blocked tests now run for real).

## Last Updated

2026-08-02 by Claude (regenerated pairs/eval after `sdd-comics-ai-transformations`'s confirmed
re-matching refinement — real data expansion, baseline performance level confirmed, not changed;
see Context Notes)

## Blockers

- **RESOLVED (2026-08-01) — investigated, fixed, A/B tested, and the naive sort was kept after
  all, on real evidence.** Original finding: `reading_order_index`'s `_sort_top_to_bottom`
  (`build_pairs.py`) is a naive `sorted(key=(bbox_y, bbox_x))` — `bbox_x` only breaks ties on
  *exact* Y equality, not real row-clustering — and `sdd-comics-ai-multimodal`'s Checkpoint A
  independently confirms the real printed source is "a conventionally paginated comic (fixed
  rectangular panel grids)," i.e. genuinely multi-panel-per-row, not vertically pre-stacked. Raised
  by Anton asking how reading order should work for e.g. a 3×3 grid page.
  **Built and tested a real fix** (`_sort_reading_order`/`_cluster_into_rows` in `build_pairs.py`):
  row-cluster by Y-proximity, then sort each row by X — confirmed correct on a synthetic 3×3-grid
  unit test the naive sort provably gets wrong (`test_build_pairs.py`).
  **Then A/B tested it for real** against the naive sort, same held-out episodes/protocol as the
  Phase 5 learned-model comparison — and the "fix" made the actual metric *worse*, not better, in
  two independent tolerance variants:
  | Variant | Weighted mean error | Reading-order rank correlation |
  |---|---|---|
  | Naive sort (shipped) | **1467px** | **0.542** |
  | Row-clustering, per-pair adaptive tolerance | 1640px (+11.8%) | 0.389 |
  | Row-clustering, page-median tolerance | 1665px (+13.5%) | 0.479 |

  Confirmed this wasn't just tie-breaking noise: 60-70% of pairs in the held-out episodes actually
  got a different `reading_order_index` between naive and fixed. Diagnosed likely cause: real
  `regions.jsonl` content spans a huge size range within one page (9-245px tall out of a 256px
  crop, since these are fine-grained content segments — one balloon, one character silhouette —
  not uniform panel-sized boxes), which defeats simple Y-proximity clustering more than the clean
  synthetic test case suggested. **Per this flow's own established precedent (ship what wins, not
  what sounds better — same standard as Phase 5's learned model losing to baseline), the naive sort
  stays the shipped default.** The row-clustering code is kept, tested, and documented in
  `build_pairs.py` as a real, disclosed negative result — not deleted — since the underlying
  geometric argument (real pages are multi-panel grids) remains true even though this specific fix
  didn't pan out; future work (larger held-out sample, or `sdd-comics-ai-script-context`'s
  narrative-order signal as an independent cross-check) might explain why or do better. Full
  experiment record in `04-implementation-log.md`. `work/train_pairs/*.jsonl` and
  `work/eval_report.jsonl` regenerated with the naive sort (shipped behavior) — numbers match the
  original 1467.4px exactly, confirming no drift from this investigation.
- **Refined understanding of the underlying craft (2026-08-01, from Anton's comics-craft domain
  knowledge, informed the fix attempt above even though it didn't ultimately change shipped
  behavior)**:
  professional comics reading order follows a small, well-established heuristic stack, in priority
  order — Z-path (row-raster; the dominant case), then panel size, then overlap/compositional
  z-order, then balloon-tail direction, then character gaze direction — because professional artists
  design pages so **layout itself implies order** ("continuous closure"); genuine ambiguity is
  considered a page-design flaw, not a normal reading experience. This reframes the whole
  recomposition task precisely: what Джанава called "нарезатор" creative judgment
  (`flows/vdd-comics-editor-jhanava/`) *is* determining true panel order via this heuristic stack for
  non-trivial layouts, then laying panels out sequentially along the target strip's Y-axis — literally
  the historical newspaper comic-strip model (one linear sequence, `1→2→3→4→5→6`), rotated from
  horizontal to vertical, with a page-grid detour in between that this pipeline has to undo. Concrete
  priority for the actual fix: (1) row-clustering + X-sort implements Z-path exactly and is already
  sufficient for confirmed "fixed rectangular panel grids" — the common case, no further heuristics
  needed there; (2) panel bbox area (already computed) as a tie-break for size; (3) region overlap
  (already representable — `sdd-comics-ai-multimodal` already supports overlapping instance masks)
  as a tie-break for compositional z-order; (4) balloon-tail direction and (5) character gaze
  direction both require CV capability that **does not exist anywhere in this codebase today**
  (confirmed in `sdd-comics-editor-questions`'s survey: no orientation/gaze concept exists) — real,
  possibly large new scope, not a small addition; low priority until (1)-(3) are shown insufficient
  on real ambiguous pages. Matches this repo's own "skip + log, never guess" convention: pages where
  (1)-(3) still leave real ambiguity are exactly where `sdd-comics-ai-script-context`'s narrative-order
  signal is the intended fallback/cross-check (see that flow's Should-Have), not a replacement for
  the geometric heuristics.
  **Correction, same day, after actually building and testing (1)**: "already sufficient" turned out
  to be the theory, not the result — see the RESOLVED entry above. (1) alone measurably
  underperformed the naive sort on real held-out data; (2)/(3) were not implemented or tested this
  session (deprioritized once (1) itself didn't pan out), so their own real-world value is still
  unverified, not just (4)/(5)'s.
- None otherwise currently. The Checkpoint B decision point (baseline-calibration vs. Phase 5 vs. ship-as-is)
  is resolved by evidence, not by choosing one of the three options blind: Anton said "continue" ->
  proceeded to Phase 5 for real -> the model was built, evaluated fairly against baseline, and lost
  (4.3% worse, weighted). That answers the original question: more model investment isn't currently
  the productive direction at this data size; the calibrated baseline is the real deliverable.
  Remaining open choice (not a blocker): whether to spend more effort on Phase 7's cross-page anchor
  or close the flow at Phase 8 — recommend the latter given Phase 7's own disclosed risk (page-number
  OCR not yet built, real new work) versus the flow's Must-Have already being satisfied.
- **Task 6.1 (`spiritual_text`), resolved pragmatically per Anton's explicit direction** ("find
  matches however works, for your own understanding; feed the found excerpts into training" — and
  confirmed this is internal/training-time only, not a runtime feature). Two automated approaches
  failed honestly (literal fuzzy-dialogue match: 0/27; TF-IDF: biased toward long sections). Switched
  to direct reading/verification and found **2 real, human-confirmed matches**: episode 21 (Amba,
  already known) and a newly-found 3-episode cluster (06/08/09 — the Kartavirya/Jamadagni/Parashurama
  cow-theft arc, verified by reading SECTION CXV-CXIX). Wired into `build_pairs.py` as a real
  `text_context` field — **127 of 392 real training pairs (4 of 16 matched episodes) now carry a
  verified excerpt**; everything else stays honestly `None`, not guessed. Text context is now
  genuinely present in the training data.
- **Phase 5 (learned model) built and evaluated for real — does not beat baseline, even after a
  major text-context upgrade.** First pass: `RandomForestRegressor` w/ `has_text_context` (4/16
  episodes covered) — 4.3% worse than baseline, weighted. Anton then pushed on text context's
  intrinsic value and proposed a local open-source multimodal model (no paid APIs — none exist in
  this repo/environment). Pulled `moondream` (Apache-2.0) via `ollama`; confirmed it does rough scene
  description but not reliable in-image OCR (existing Tesseract pipeline already owns that). Reading
  a real dataset image myself surfaced a caption confirming episode 10 joins the existing 06/08/09
  Kartavirya arc; grepping `comics-ai-baloons`' existing `ocr.jsonl` for "Kartavirya" found a 4th
  episode (11) **and** confirmed all 16 training episodes already have real OCR'd dialogue available.
  Rebuilt around this: new `scene_text.py` sources `text_context` from the comic's own OCR'd
  dialogue (100% relevant by construction) — coverage jumped from 127/392 to **392/392 pairs**.
  Swapped the now-constant `has_text_context` feature for `text_context_length`. Retrained: weighted
  error **1467px (baseline) vs. 1552px (model) — 5.8% worse**, marginally worse than before. Real,
  honest conclusion: broader/better text coverage didn't help *this specific regression task* — the
  binding constraint is training-set size (314 examples), not text signal availability. Independent
  real value delivered regardless: 2 new verified episode-arc connections, a working local-OSS-model
  path validated for future scene-description use, and a genuinely reliable text-context field now
  in the dataset for other future uses (identity, QA against dataset errors) — exactly what Anton
  flagged as valuable, even though it didn't move this particular metric.

## Progress

- [x] Requirements drafted (2026-08-01) — v0.1, seeded directly from the architecture proposal
      already discussed with Anton in this session, not a fresh elicitation Q&A
- [x] Requirements revised (2026-08-01) — v0.2, all four v0.1 Open Questions resolved against real
      code in `apps/comics-ai/comics-multimodal/scripts/` rather than left as guesses
- [ ] Requirements approved
- [x] Specifications drafted (2026-08-01) — v0.1, built directly on two real, already-existing
      scripts (`align_photo.py`'s `ground_truth_cluster_for`, `render_canvas.py`'s
      `GroundTruthRegion`) whose join is this flow's core training-data insight
- [x] Specifications approved (2026-08-01) — "approved"; one correction made same day before Plan:
      the page-number cross-page anchor is real but nothing extracts it automatically yet (Checkpoint
      A found it by manual inspection) — sized as real work in Plan, not assumed free
- [x] Plan drafted (2026-08-01) — v0.1, 8 phases; Must-Have deliverable is Phases 1-4 only (baseline
      positioner, no ML training required); Phases 5/7 (learned model, page-number cross-page anchor)
      explicitly gated on real checkpoints, not committed upfront; Phase 6 (`spiritual_text` spike)
      time-boxed and isolated
- [x] Plan approved (2026-08-01)
- [x] Implementation started (2026-08-01) — Phase 1 (bridge + data checkpoint: 37 real matched
      pairs, 16 episodes), Phase 2 (392 real training pairs, `work/train_pairs/`), Phase 3
      (real spacing stats + baseline positioner), Phase 4 (held-out evaluation + Checkpoint B) all
      code-complete and run against real data, 20/20 tests passing
- [x] Implementation complete — Phases 1-8 all done (Phases 5-7 each a genuine attempt with an
      honestly-reported real result, not a skip); see `04-implementation-log.md` for the full record
      and this doc's Phase Status note above on the stale-progress correction made 2026-08-01

## Context Notes

- **Purpose**: closes the gap `sdd-comics-ai-multimodal` explicitly left open — that flow solved
  cutting/segmentation (flattened page → kind-tagged regions); this flow addresses recomposition/
  positioning (regions → their place in the final continuous-strip layout), which turned out via a
  direct 2026-08-01 answer from Anton to be the real substance of Джанава's "character/background
  placement, order of magnitude harder than balloon" framing from `vdd-comics-editor-jhanava`.
- **Core technical bet**: training data for this problem is largely already free — the 27 existing
  `.comics` files' known final layer positions, paired with `sdd-comics-ai-multimodal`'s existing
  photo↔episode alignment, give (paneled input → recomposed output) pairs without new manual
  labeling. This was not understood as reusable signal until this flow's requirements drafting.
  Sizing this honestly (still only 27 source files) is a first-class constraint, same lesson as
  `comics-ai-baloons`/`comics-ai-multimodal`.
- **Editor architecture constraint carried in**: `apps/comics-editor` has no layer-grouping concept
  at all (verified in `Layer.cs`, zero `Group` matches repo-wide) — every layer's position is an
  independent `TranslateAnim.X`/`Y` int pair. This flow's output must be per-layer coordinates, not
  a group/composite transform.
- **`spiritual_text` is a should-have spike, not a dependency**: confirmed real, scene-matching
  narrative text exists for at least one validated episode (21, `21_ambas_plea`), but coverage isn't
  proven complete (same source file explicitly defers part of that very character's story to a
  volume not present in `dataset/`). Scoped as an optional, time-boxed investigation.
- **Deliberately excludes the review UI** this iteration, mirroring `sdd-comics-ai-multimodal`'s own
  precedent of designing an editor-integration contract without building the UI — that's left to a
  future flow analogous to how `vdd-comics-editor-ai-uiux` followed on from `comics-ai-multimodal`.

## Fork History

N/A — new flow. Spun out of `flows/sdd-comics-editor-questions/` (problem framing) after a
2026-08-01 direct answer resolved what "placement" actually means; not a literal fork/copy.

## Context Notes (added 2026-08-01, Specifications pass)

- **Load-bearing discovery**: `apps/comics-ai/comics-multimodal/scripts/align_photo.py`'s
  `ground_truth_cluster_for` and `render_canvas.py`'s `GroundTruthRegion` already produce, between
  them, real (paneled-page-cluster → resting-canvas-position) pairs for every confidently-matched
  real photo against all 27 dataset files — the free training data hypothesized in Requirements is
  not hypothetical, it's two existing scripts' outputs joined on `layer_index`.
- **`package.py`'s own design note** (written during `comics-multimodal`'s implementation) states no
  pixel-level photo→canvas mapping is obtainable — independent confirmation that positioning must be
  a learned regression from region properties, not a geometric transform. This was already the
  planned approach; the note just confirms it wasn't overlooked as an easier alternative.
- **Cross-page ordering resolved by dissolving it**: since canvas target space is one continuous
  Y-axis, relative-Y placement within a page *is* the ordering; absolute per-page anchoring
  bootstraps from real printed page numbers rather than needing a learned ordering step.
- **Scale/alpha promoted to Should-Have**: `resting_position.py::resolve_resting_transform` already
  extracts these alongside X/Y at zero extra engineering cost, so restricting to X/Y-only would have
  discarded free signal.

## Next Actions

1. Anton reviews `03-plan.md` v0.1 — in particular whether the Phase 1-4-only "Must Have, ship the
   baseline alone if that's all that pans out" framing is the right bar, and whether Phase 5/7's
   gating (attempt only if their own checkpoint passes) is the right level of caution vs. just
   committing to build them.
2. On "plan approved": move to Implementation — start with Phase 1 (environment + reuse wiring) and
   Task 1.2's real data-count checkpoint, per this repo's one-test-at-a-time protocol. Log progress
   in `04-implementation-log.md`.

## Superseded/Extended By

- `flows/sdd-comics-ai-transformations/` (2026-08-01, renamed same day from
  `sdd-comics-ai-positioning-revised` and substantially rescoped to full-book coverage plus
  transformation/animation generation) — this flow (`sdd-comics-ai-positioning`) is COMPLETE and
  stays as the shipped position-prediction stage; the new flow depends on it directly (a region
  needs a resting position before a reveal animation into that position makes sense) and also
  carries forward the reading-order investigation's flagged next step (test
  `sdd-comics-ai-script-context`'s narrative signal) and the never-adopted `text_context_length`
  semantic upgrade. This flow's own numbers/docs stay as the historical record unless the new flow
  reports a real win back here.
