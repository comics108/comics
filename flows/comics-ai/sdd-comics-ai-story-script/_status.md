# Status: sdd-comics-ai-script-context

## Current Phase

IMPLEMENTATION

## Phase Status

COMPLETE — original 7 planned tasks (Phases 1-3) done and verified against real data, not stubs.
**Extended 2026-08-02 by `sdd-comics-ai-transformations`' criterion 2**: added an OCR-dialogue
fallback source (`ocr_dialogue_source.py`) for episodes without a hand-verified `spiritual_text`
match, plus a `text_source` provenance field on `SceneExtraction` so the two tiers stay
distinguishable. 19/19 tests passing (was 12; +6 new for the OCR source, +1 for the fallback path
in `run_all`). Real full run against all 27 dataset episodes: **27 extracted, 0 failed, 0
no-source-text** (was 6/0/21).

## Last Updated

2026-08-02 by Claude (extended to full 27-episode coverage via an OCR-dialogue fallback tier, per
`sdd-comics-ai-transformations`' criterion 2)

## Blockers

None. Original Must-Have (Requirements' Acceptance Criteria 1-4) still satisfied; the criterion-2
extension is additive, real, and tested — see `04-implementation-log.md` for the extension record.

## Progress

- [x] Requirements drafted (2026-08-01) — v0.1, seeded from `sdd-comics-editor-questions` Group D
- [x] Requirements approved (2026-08-01) — v0.2, all Open Questions resolved via a real 4-model
      comparison spike against hand-verified excerpts, not guessed
- [x] Specifications drafted (2026-08-01) — v0.1, architecture/schema/error-handling for the
      extraction pipeline
- [x] Specifications approved (2026-08-01)
- [x] Plan drafted (2026-08-01) — v0.1, 3 phases / 7 tasks, linear dependency chain
- [x] Plan approved (2026-08-01)
- [x] Implementation started (2026-08-01)
- [x] Implementation complete (2026-08-01) — all 7 tasks done, real full pipeline run executed,
      README written against real output

## Context Notes

- **Real model-choice evidence**: `qwen2.5-coder:32b` beat `qwen2.5-coder:7b`, `deepseek-coder:33b`,
  and `nativemind/mozgach108-quality` on a real 2-excerpt comparison (episode 21, Kartavirya
  cluster) — the smaller/other models missed "Amba" (the protagonist) entirely; `mozgach108` is a
  viable fast fallback with a different, non-overlapping error profile.
- **Real, disclosed residual limitations** (not fixed, not hidden): coreference misses (epithet not
  linked to the proper name mentioned elsewhere in the same excerpt — reproduced live on
  `10_the_brahmanas_do_not_have_to_fight`), occasional non-person entries (e.g. "four boys").
  `raw_model_output` is kept in every output file specifically so these can be spot-checked.
  `report.md` flags placeholder-name and zero-character results automatically.
  - See also `flows/sdd-comics-ai-positioning/_status.md`'s Blockers: this flow's
    `CharacterMention.action_or_state` output was flagged there as a candidate cross-check signal
    for that flow's `reading_order_index` bug — not yet wired up (that's `sdd-comics-ai-positioning`'s
    own future work, this flow only documents the contract).
- **No consumer flow's code was touched** — `sdd-comics-ai-multimodal`, `sdd-comics-ai-positioning`,
  `vdd-comics-editor-systematization-uiux` all have a documented adoption path in this app's
  `README.md` but none were modified, per Requirements' explicit Won't-Have.
- **Real coverage is 6 of 27 episodes** — bounded by how many episodes have a hand-verified
  `spiritual_text` match (`sdd-comics-ai-positioning`'s `text_context.py::VERIFIED`), not by this
  flow's own model or code. Extending coverage (e.g. to OCR-dialogue-derived episodes) is an
  explicit, deliberately-deferred Open Design Question in `02-specifications.md`.

## Fork History

N/A — new flow. Spun out of `flows/sdd-comics-editor-questions/`'s Group D discussion (problem
framing), not a literal fork/copy.

## Next Actions

Per Anton's stated intent this session ("доделываем и после перейдем к sdd-comics-ai-positioning"):
this flow is done — next is resuming `flows/sdd-comics-ai-positioning/`, in particular its logged
`reading_order_index` bug (naive `(y, x)` sort, doesn't handle real multi-panel-per-row source
pages) and the open decision of whether/how to fix it and re-run Phases 2-4.

## Superseded/Extended By

- `flows/sdd-comics-ai-transformations/` (2026-08-01, renamed same day from
  `sdd-comics-ai-positioning-revised` and substantially rescoped to full-book coverage plus
  transformation/animation generation) — wires this flow's `SceneExtraction` output into
  `sdd-comics-ai-positioning`'s feature set/reading-order evaluation (the adoption contract this
  flow's own `README.md` documented but didn't build) **and** extends this flow's own coverage
  beyond 6/27 episodes (OCR-dialogue fallback, this flow's own deferred Open Design Question, now
  picked up there). This flow's existing code/output stay as-is, consumed and extended, not
  rewritten.
