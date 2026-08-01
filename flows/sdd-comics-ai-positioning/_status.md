# Status: sdd-comics-ai-positioning

## Current Phase

IMPLEMENTATION

## Phase Status

IN PROGRESS — Phases 1-6 done (Must-Have baseline pipeline, held-out evaluation, real text-context
now covering all 16 training episodes via the comic's own OCR'd dialogue, learned model trained and
honestly evaluated against baseline, including a local-OSS-multimodal-model detour). 33/33 tests
passing. **Net result of Phases 4 and 5 together, even after upgrading text context to 100%
coverage**: the calibrated rule-based baseline remains the best real deliverable — the learned model
does not beat it (5.8% worse, weighted, with full text coverage; was 4.3% worse with partial
coverage). Per Requirements' own Must-Have criterion 3, shipping the baseline alone is an explicitly
acceptable outcome. Remaining: Phase 7 (optional, cross-page page-number anchor — not started) and
Phase 8 (report/contract docs — not started).

## Last Updated

2026-08-01 by Claude

## Blockers

- None currently. The Checkpoint B decision point (baseline-calibration vs. Phase 5 vs. ship-as-is)
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
- [ ] Implementation complete — paused at Checkpoint B pending Anton's direction (see Blockers);
      Phases 1-4 are a real, working, honestly-evaluated deliverable regardless of which way this
      goes next

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
