# Implementation Plan: comics-ai-script-context

> Version: 0.1
> Status: APPROVED
> Last Updated: 2026-08-01
> Specifications: `02-specifications.md` (v0.1, APPROVED)

## Summary

Three phases: (1) core extraction (prompt + ollama call + schema validation, already spiked
manually against the real model-comparison in Requirements — this phase productionizes that spike
into tested code), (2) full-coverage run + honest report across all 27 episodes, (3) contract
documentation for the three consumer flows (no code changes to them, per Specifications' Won't-Have).
No learned-model training, no new CV work — this is a thin, real wrapper around an already-chosen
local LLM plus already-existing verified text.

## Task Breakdown

### Phase 1: Core Extraction

#### Task 1.1: `scene_models.py` — data types
- **Description**: `CharacterMention`/`SceneExtraction` frozen dataclasses per Specifications'
  Data Models section, plus JSON (de)serialization helpers.
- **Files**:
  - `apps/comics-ai/comics-script-context/scripts/scene_models.py` - Create
- **Dependencies**: None
- **Verification**: Unit tests — construct, serialize to dict/JSON, round-trip back to the dataclass
- **Complexity**: Low

#### Task 1.2: `extract_scene.py` — prompt building + JSON parsing (no live model call)
- **Description**: `build_prompt(excerpt)` (deterministic string) and the parsing/validation path
  (brace-matching fallback, `ExtractionFailed` on unrecoverable failure), unit-tested against
  **canned model output strings**, not a live call — isolates the fragile/slow part (actually
  calling ollama) from the fast, deterministic part (parsing whatever it returns).
- **Files**:
  - `apps/comics-ai/comics-script-context/scripts/extract_scene.py` - Create
- **Dependencies**: Task 1.1
- **Verification**: Unit tests covering all four canned-output cases from Specifications' Testing
  Strategy (well-formed, prose-wrapped, malformed, empty-characters)
- **Complexity**: Medium (the brace-matching fallback needs real edge-case coverage — models
  wrapping JSON in ` ```json ` fences was observed informally during the Requirements spike)

#### Task 1.3: Live ollama invocation
- **Description**: The actual `subprocess.run(["ollama", "run", model, ...])` call wired into
  `extract()`, with the 180s timeout from Specifications.
- **Files**:
  - `apps/comics-ai/comics-script-context/scripts/extract_scene.py` - Modify (adds the subprocess
    call on top of Task 1.2's pure-parsing logic)
- **Dependencies**: Task 1.2
- **Verification**: One real, live call against episode 21's excerpt (the Specifications
  integration test) — confirms "Amba" appears in the result, matching the Requirements spike exactly
- **Complexity**: Low (the hard part — prompt design, model choice — is already done; this is
  wiring)

### Phase 2: Full Run + Honest Coverage Report

#### Task 2.1: `run_all.py`
- **Description**: Iterates `text_context.VERIFIED` (6 entries today), calls `extract()` per
  episode, writes `work/scenes/<episode_file>.json`, and builds `work/report.md` with the three
  status categories (extracted / failed / no-source-text) per Specifications.
- **Files**:
  - `apps/comics-ai/comics-script-context/scripts/run_all.py` - Create
- **Dependencies**: Task 1.3
- **Verification**: Unit test with a fake `VERIFIED` dict + stubbed `extract()` confirming correct
  status bucketing; then one real full run against all 6 real entries
- **Complexity**: Low

#### Task 2.2: Quality flags (placeholder names, zero-character extractions)
- **Description**: The two `report.md` disclosure checks from Specifications' Edge Cases table —
  flag generic placeholder names (`"Heroine"`, `"the speaker"`, `"protagonist"`, case-insensitive
  substring) and zero-character results, so a human reader of `report.md` sees exactly the failure
  modes the Requirements spike already found in real model output, not just a silent pass/fail.
- **Files**:
  - `apps/comics-ai/comics-script-context/scripts/run_all.py` - Modify
- **Dependencies**: Task 2.1
- **Verification**: Unit test feeding a `SceneExtraction` containing `"Heroine"` and one with empty
  `characters`, confirming both are flagged in the generated report
- **Complexity**: Low

#### Task 2.3: Real full run + manual spot-check
- **Description**: Run `run_all.py` for real against all 6 `VERIFIED` episodes (not a stub). Read
  `work/report.md`; manually compare the episode 21 and one Kartavirya-arc result against the known
  real entities (same check as the Requirements spike) to confirm the committed pipeline reproduces
  what the ad hoc CLI testing found — not a regression.
- **Files**: None (verification task, `work/` output only, gitignored per this repo's convention)
- **Dependencies**: Task 2.2
- **Verification**: Manual read-through, documented in `04-implementation-log.md`
- **Complexity**: Low

### Phase 3: Contract Documentation (no consumer code changes)

#### Task 3.1: `README.md` — consumer adoption guide
- **Description**: Per Specifications' Integration Points, write a short README documenting, for
  each of the three consumer flows, exactly what field of `SceneExtraction` maps to what gap
  (character identity / `text_context` upgrade / variant tag) — a pointer for whoever picks up that
  adoption work later, not new code.
- **Files**:
  - `apps/comics-ai/comics-script-context/README.md` - Create
- **Dependencies**: Task 2.3 (needs real output to reference concretely, not a hypothetical schema)
- **Verification**: Read-through; cross-check every claim against the actual `work/scenes/*.json`
  produced in Task 2.3, not written from memory of the design
- **Complexity**: Low

## Dependency Graph

```
Task 1.1 ─→ Task 1.2 ─→ Task 1.3 ─→ Task 2.1 ─→ Task 2.2 ─→ Task 2.3 ─→ Task 3.1
```

Linear — no parallel branches. Each phase's output is a real precondition for the next (can't run
all-episodes coverage before the single-episode extractor works; can't write an honest adoption
guide before real output exists to point at).

## File Change Summary

| File | Action | Reason |
|------|--------|--------|
| `apps/comics-ai/comics-script-context/scripts/scene_models.py` | Create | Data types (Task 1.1) |
| `apps/comics-ai/comics-script-context/scripts/extract_scene.py` | Create | Prompt + parsing + live ollama call (Tasks 1.2-1.3) |
| `apps/comics-ai/comics-script-context/scripts/run_all.py` | Create | Full-coverage run + report (Tasks 2.1-2.2) |
| `apps/comics-ai/comics-script-context/README.md` | Create | Consumer adoption contract (Task 3.1) |
| `apps/comics-ai/comics-script-context/tests/*` | Create | Unit tests per task above |
| `apps/comics-ai/comics-script-context/work/scenes/*.json`, `work/report.md` | Create (gitignored) | Real pipeline output |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| `qwen2.5-coder:32b` unavailable/removed from local Ollama later | Low (already pulled, confirmed present) | Medium (pipeline breaks) | `extract()` raises a clear `ExtractionFailed`, not a silent fallback to a different, untested model |
| Coreference-miss / duplicate-entity failure modes (already found in Requirements) mislead a future consumer flow into trusting bad data | Medium — these are real, disclosed, unfixed model limitations | Medium | `raw_model_output` kept alongside every parsed result; `report.md`'s placeholder/zero-character flags surface the known failure signatures; README explicitly documents this as best-effort, not ground truth |
| Only 6 of 27 episodes have real coverage — a future consumer might expect more | Certain (known going in) | Low (honestly disclosed, not a surprise) | `report.md`'s "no source text" category makes the gap explicit per-episode, not just an aggregate number |

## Rollback Strategy

New, additive, standalone app under `apps/comics-ai/comics-script-context/` with no writes to
`dataset/` or any other app's code — rollback is deleting the directory, nothing else is affected.

## Checkpoints

After each phase, verify:

- [ ] All unit tests pass
- [ ] The one live-ollama integration test (Task 1.3) still finds "Amba" in episode 21's output
- [ ] `work/report.md` accounts for all 27 episodes across exactly the three status categories
      (extracted/failed/no-source-text) — no episode silently missing from the report

## Open Implementation Questions

- [ ] None currently — Specifications' one Open Design Question (whether to extend to OCR-dialogue
      episodes) is explicitly deferred past this plan's scope, not a mid-implementation decision.

---

## Approval

- [x] Reviewed by: Anton Dodonov (via "доделываем" directive)
- [x] Approved on: 2026-08-01
- [x] Notes: Proceeding to Implementation on the same Auto Mode basis as Requirements/Specifications.
