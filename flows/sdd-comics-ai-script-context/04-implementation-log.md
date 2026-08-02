# Implementation Log: comics-ai-script-context

> Started: 2026-08-01
> Plan: `03-plan.md` (v0.1, APPROVED)

## Progress Tracker

| Task | Status | Notes |
|------|--------|-------|
| 1.1 `scene_models.py` | Done | 1/1 test passing |
| 1.2 `extract_scene.py` parsing | Done | 6/6 canned-output tests passing |
| 1.3 Live ollama invocation | Done | 1/1 live integration test passing (found "Amba") |
| 2.1 `run_all.py` | Done | 3/3 tests passing, real full run: 6 extracted / 0 failed / 21 no-source-text |
| 2.2 Quality flags | Done | Placeholder-name + zero-character flags verified against real output |
| 2.3 Real full run + spot-check | Done | See Session Log below |
| 3.1 `README.md` | Done | Written against real `work/scenes/*.json` output, not from memory of the design |

## Session Log

### Session 2026-08-01 - Claude

**Started at**: Phase 1, Task 1.1 (flow created fresh this session per Anton's "доделываем" directive)
**Context**: Requirements/Specifications/Plan all drafted and approved earlier this same session
(Auto Mode, per explicit "доделываем" instruction rather than line-by-line sign-off).

#### Completed

- **Requirements Open Questions resolved by real spike, before writing any implementation code**:
  ran the same structured-extraction prompt against `text_context.py`'s real hand-verified excerpts
  (episode 21; the Kartavirya cluster) on 4 real local models. `qwen2.5-coder:32b` won (correctly
  named "Amba", the protagonist, and correctly distinguished a title from a person's name, unlike
  `qwen2.5-coder:7b`/`deepseek-coder:33b`, which both missed "Amba" entirely). `nativemind/
  mozgach108-quality` noted as a fast, viable fallback with a *different* error profile (better on
  one coreference case, worse on entity-duplication). This resolved Requirements v0.1's model-choice
  Open Question with evidence, matching this repo's established practice everywhere else.
- Task 1.1: `scene_models.py` (`CharacterMention`/`SceneExtraction` dataclasses + dict
  serialization). Verified: `tests/test_scene_models.py`, round-trip test, 1/1 passing.
- Task 1.2: `extract_scene.py`'s `build_prompt`/`parse_model_output` (pure parsing, no live call).
  Verified: `tests/test_extract_scene.py`, 6 canned-output cases (well-formed, markdown-fence-wrapped,
  malformed, empty-characters, duplicate-name dedup, missing-required-field), all passing.
- Task 1.3: live `ollama` subprocess wiring in `extract()`. **Real finding before trusting the
  design**: confirmed via a direct subprocess call that non-TTY `ollama run` output is clean JSON
  with no ANSI spinner codes (the spinner escapes seen during the Requirements spike were an
  artifact of the interactive Bash-tool TTY, not something a real Python subprocess call would ever
  see) — this was verified empirically, not assumed, before writing the "obviously fine" subprocess
  code. Verified: `tests/test_extract_scene.py::test_live_extraction_finds_amba_in_episode_21`
  (marked `slow`), 1/1 passing, ~6s real call.
  - **Test bug caught and fixed during this task**: the first version of the live test reused the
    same short `EXCERPT` constant used by the fast unit tests — a first-person quote from Amba
    herself ("At heart I had chosen...") that never actually names her. The live call correctly
    extracted "I" (the only named-ish entity in that short text) and the test failed. Fixed by
    importing the *real* full verified excerpt from `text_context.VERIFIED` instead of hand-copying
    a fragment — the failure was in the test's input data, not the extraction code.
- Task 2.1-2.2: `run_all.py` (full-coverage run + `report.md` with three honest status categories,
  plus placeholder-name/zero-character flags). Verified: `tests/test_run_all.py`, 3/3 passing
  (fake `VERIFIED` + stubbed `extract()`, confirming correct bucketing and file-writing).
- Task 2.3: real full run (`python3 scripts/run_all.py`) against all 27 real `.comics` files.
  **Result: 6 extracted, 0 failed, 21 honestly reported as no-source-text.** Spot-checked against
  the Requirements spike's manual findings:
  - Episode 21: extracted **all four** real entities this run (Amba, king of Saubha, father,
    Bhishma) — better than either individual spike run (which each missed one), consistent with
    known LLM output variance across calls, not a regression.
  - Episode `10_the_brahmanas_do_not_have_to_fight`: reproduced the exact known coreference-miss
    ("mighty ruler" instead of "Kartavirya") predicted in Requirements/Specifications — confirms the
    disclosed limitation is real and consistent, not a one-off.
  - Episode `09_magic_cow_kamadhenu`: correctly returned **zero characters** (its excerpt genuinely
    only mentions a possessed object, "Jamadagni's cow", no person acting) — the Task 2.2
    zero-character flag fired exactly as designed on real data, not just the synthetic test case.
- Task 3.1: `README.md` written directly against the real `work/scenes/*.json`/`report.md` output
  from Task 2.3 — every claim in it (coverage numbers, the two disclosed limitation examples) is
  copied from actual pipeline output, not from memory of the design.

#### Deviations from Plan

- None substantive. Plan's task order followed exactly (1.1→1.2→1.3→2.1→2.2→2.3→3.1, matching the
  linear dependency graph).

#### Discoveries

- Non-TTY `ollama run` output is clean (no ANSI codes) — worth documenting since the Requirements
  spike's raw terminal output looked alarming (interleaved escape codes) but that was purely a
  TTY-rendering artifact, not a real data-quality risk for the actual pipeline.
- Real coreference-miss and zero-character edge cases both reproduced on the very first full run —
  the Requirements spike's small 2-excerpt sample was representative of real, systematic model
  behavior, not a fluke.

**Ended at**: Phase 3, Task 3.1 — all planned tasks complete.
**Handoff notes**: This flow's Must-Have deliverable is done and real (6/27 episodes, honestly
disclosed limitations, documented adoption contract). Nothing here blocks moving to
`sdd-comics-ai-positioning` next, per Anton's stated intent this session. The one Open Design
Question from Specifications (whether to extend to OCR-dialogue-derived episodes for broader
coverage) remains deliberately unresolved — a future extension, not required for this flow's
Must-Have.

---

### Session 2026-08-02 - Claude (extension, from `sdd-comics-ai-transformations`' criterion 2)

**Started at**: Post-COMPLETE, extending coverage per a sibling flow's Must-Have criterion.
**Context**: `sdd-comics-ai-transformations`' Requirements (v0.3, criterion 2) called for
implementing this flow's own previously-deferred Open Design Question — the OCR-dialogue fallback
for episodes without `spiritual_text`.

#### Completed

- Checked first, not assumed: `comics-ai-baloons`'s `discover.py` scans the whole dataset
  structurally, independent of photo-matching — confirmed all 27 episodes already have real OCR'd
  dialogue in `ocr.jsonl`, so full 27/27 coverage was actually reachable, not just the
  previously-assumed 16-episode training-relevant ceiling.
- Added `text_source` provenance field to `SceneExtraction` (`scene_models.py`) — defaults to
  `"spiritual_text"` for backward compatibility with existing serialized output.
- Built `ocr_dialogue_source.py`: concatenates an episode's own real English balloon dialogue
  (layer-index order) as a fallback excerpt when no `spiritual_text` match exists.
- Threaded `text_source` through `extract_scene.py` (`extract`/`parse_model_output`) and
  `run_all.py` (tries `spiritual_text` first, falls back to `ocr_dialogue`, only reports
  "no source text" if neither has anything).
  - Files changed: `scripts/scene_models.py`, `scripts/ocr_dialogue_source.py` (new),
    `scripts/extract_scene.py`, `scripts/run_all.py`.
  - Tests: `tests/test_ocr_dialogue_source.py` (new, 6 tests, including one against the real
    corpus confirming all 27 episodes are covered), `tests/test_run_all.py` (+1 new fallback test,
    2 existing tests updated for the new report line format). 19/19 total passing.
- **Real full run: 27/27 episodes extracted, 0 failed, 0 no-source-text** (was 6/0/21). Spot-checked
  plausibility across previously-uncovered episodes (real Mahabharata/Bhagavata character names
  throughout — Krishna, Yashoda, Karna, Putana, etc.), including an independent confirmation of a
  hypothesis from `sdd-comics-ai-transformations`' criterion 4 investigation: `97cf25db...`
  (`Comics_Episodes.csv` title "12_defy_the_kshatriyas") extracts "RAM" — consistent with it
  belonging to the same Parashurama-vs-Kshatriyas arc as the already-known Kartavirya cluster,
  guessed from dialogue-style clues alone before this run confirmed it via actual content.
  - Files changed: `README.md` (coverage numbers, two-tier provenance explanation).

#### Discoveries

- A capability's own "deferred, not required for Must-Have" open question can turn out cheap to
  resolve once a *different* flow's real need makes it worth doing — the OCR-dialogue fallback was
  always feasible, just never prioritized until criterion 2 gave it a concrete consumer.

**Ended at**: Full 27/27 episode coverage, two explicit provenance tiers, all tests passing.
**Handoff notes**: This flow is COMPLETE again at a broader scope. `sdd-comics-ai-transformations`'
criterion 2 is done; its criteria 1 (transformation generation) and 5 (full pipeline run) remain.

---

## Deviations Summary

| Planned | Actual | Reason |
|---------|--------|--------|
| (none) | (none) | Plan executed as written |

## Learnings

- When testing an LLM extraction pipeline, always verify the *test's own input excerpt* actually
  contains the fact being asserted — a first-person source quote can omit the very name a
  third-person consumer expects to find in it (real bug caught in Task 1.3, not hypothetical).
- Ad hoc interactive-terminal spikes (this flow's Requirements-phase model comparison) can look
  noisier (ANSI codes) than the real committed code path (clean subprocess capture) — worth a
  direct empirical check before assuming the spike's rough edges are real production risk.

## Completion Checklist

- [x] All tasks completed or explicitly deferred (none deferred — all 7 tasks done)
- [x] Tests passing (12/12: 11 fast + 1 slow/live)
- [x] No regressions (new, standalone app; nothing else in the repo touched)
- [x] Documentation updated (`README.md` written against real output)
- [x] Status updated to COMPLETE (see `_status.md`)
