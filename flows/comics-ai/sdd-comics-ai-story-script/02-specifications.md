# Specifications: comics-ai-script-context

> Version: 0.1
> Status: DRAFT
> Last Updated: 2026-08-01
> Requirements: `01-requirements.md` (v0.2, APPROVED)

## Overview

A standalone pipeline, `apps/comics-ai/comics-script-context/`, that runs each episode's
hand-verified `spiritual_text` excerpt (from `sdd-comics-ai-positioning`'s
`text_context.py::VERIFIED`) through a local Ollama model (`qwen2.5-coder:32b`, chosen by real
comparison in Requirements) to produce a structured record of named characters, props, and
locations with a short action/state description per character. Output is written per-episode to
`work/scenes/*.json`, plus one `work/report.md` disclosing real coverage (which episodes got a real
extraction vs. which have no source text at all — never silently guessed). This flow does not modify
any consumer flow's code; it only produces the source data and documents the contract.

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `apps/comics-ai/comics-script-context/` (new) | Create | New standalone app, mirrors `comics-multimodal`/`comics-ai-baloons`/`comics-positioning`'s layout |
| `dataset/` | None (read-only) | Never written to, per repo convention |
| `apps/comics-ai/comics-positioning/scripts/text_context.py` | Read-only reuse | `VERIFIED` dict is this flow's real input; not modified |
| `sdd-comics-ai-multimodal`, `sdd-comics-ai-positioning`, `vdd-comics-editor-systematization-uiux` | None this iteration | Contract documented (see Integration Points) for future adoption; no code changes here |

## Architecture

### Component Diagram

```
apps/comics-ai/comics-positioning/scripts/text_context.py::VERIFIED
              |  (6 episodes: 21, 06/08/09/10/11 Kartavirya arc)
              v
apps/comics-ai/comics-script-context/scripts/
  extract_scene.py       -- builds prompt, calls ollama, parses+validates JSON response
  scene_models.py         -- SceneExtraction / CharacterMention dataclasses, schema validation
  run_all.py               -- iterates all VERIFIED episodes, writes work/scenes/*.json + report.md
              |
              v
apps/comics-ai/comics-script-context/work/
  scenes/<episode_file>.json   -- one structured extraction per covered episode
  report.md                     -- honest coverage: N/27 episodes covered, per-episode raw model
                                     output alongside parsed result (for spot-checking)
```

### Data Flow

1. `run_all.py` iterates `text_context.VERIFIED` (currently 6 of 27 episode files).
2. For each, `extract_scene.py::extract(excerpt: str) -> SceneExtraction` builds the fixed prompt
   template (see Interfaces), invokes `ollama run qwen2.5-coder:32b` via `subprocess`, and parses the
   response as JSON.
3. On success: `SceneExtraction` is validated (no empty character names, no duplicate exact-name
   entries) and written to `work/scenes/<episode_file>.json`, alongside the raw model stdout (for
   spot-checking against the known coreference/duplication failure modes found in Requirements).
4. On any failure (ollama not running, model not pulled, malformed/non-JSON response, empty
   response): the episode is recorded in `report.md` as **failed**, with the raw output/error
   attached — never silently dropped or replaced with a guess.
5. For the 21 episodes with no `VERIFIED` entry at all: recorded in `report.md` as **no source
   text** — a third, distinct status from "extracted" and "failed", so a consumer can tell "we
   didn't have text for this" apart from "we tried and it broke."

## Interfaces

### New Interfaces

```python
# scene_models.py
from dataclasses import dataclass, field

@dataclass(frozen=True)
class CharacterMention:
    name: str
    action_or_state: str

@dataclass(frozen=True)
class SceneExtraction:
    episode_file: str
    source_excerpt: str          # the exact spiritual_text excerpt fed in, for auditability
    characters: tuple[CharacterMention, ...]
    props: tuple[str, ...]
    locations: tuple[str, ...]
    raw_model_output: str        # unparsed model stdout, kept for spot-checking coreference misses
    model_name: str = "qwen2.5-coder:32b"


# extract_scene.py
def build_prompt(excerpt: str) -> str: ...
def extract(excerpt: str, model: str = "qwen2.5-coder:32b") -> SceneExtraction:
    """Raises ExtractionFailed on any non-recoverable error (ollama unavailable, malformed JSON)."""

class ExtractionFailed(Exception):
    def __init__(self, episode_file: str, reason: str, raw_output: str | None): ...
```

### Modified Interfaces

None — this flow adds new files only, per Requirements' Won't-Have (no consumer flow code touched).

## Data Models

### New Types

Covered above (`CharacterMention`, `SceneExtraction`). Serialized to JSON per episode as:

```json
{
  "episode_file": "8a89f7d689fb441ea280cd782276bd7a.comics",
  "source_excerpt": "At heart I had chosen the king of Saubha...",
  "characters": [
    {"name": "Amba", "action_or_state": "permitted to choose her own path"},
    {"name": "king of Saubha", "action_or_state": "her originally chosen husband"}
  ],
  "props": [],
  "locations": ["Kasi"],
  "raw_model_output": "{...as returned by ollama, verbatim...}",
  "model_name": "qwen2.5-coder:32b"
}
```

### Schema Changes

None to `dataset/` or `.comics` files — this is a purely additive, out-of-band artifact under this
app's own `work/`.

## Behavior Specifications

### Happy Path

1. `run_all.py` reads `text_context.VERIFIED` (6 real entries today).
2. For each entry, `extract_scene.extract(excerpt)` is called with the excerpt text.
3. The model returns a JSON object matching the required shape.
4. `SceneExtraction` is constructed, validated, and written to `work/scenes/<episode_file>.json`.
5. `report.md` records this episode as **extracted**, with a one-line summary of characters found.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| No `VERIFIED` entry for an episode | 21 of 27 episodes today | Recorded as **no source text** in `report.md`; no extraction attempted, nothing written to `work/scenes/` |
| Model returns non-JSON / malformed JSON | LLM adds prose before/after the JSON, or truncates | Attempt a best-effort brace-matching extraction of the first `{...}` block; if that also fails to parse, record as **failed** with raw output attached, do not guess a partial result |
| Model duplicates an entity under two names (e.g. "Heroine" + "Amba", found in Requirements' `mozgach108` test) | Known real failure mode | Not auto-deduplicated (no reliable way to know they're the same entity without human/cross-check) — written through as-is; `report.md` flags any episode with a generic placeholder name (`"Heroine"`, `"the speaker"`, `"protagonist"`, case-insensitive substring check) for human attention |
| Model resolves an epithet but not the proper name (e.g. "the mighty ruler of the Haihaya tribe" not linked to "Kartavirya", found in Requirements' `qwen2.5-coder:32b` test) | Known real coreference-miss failure mode | Not corrected automatically — this is exactly what the Should-Have OCR-dialogue cross-check (Requirements) is for, out of scope for this flow's Must-Have; `raw_model_output` is retained specifically so a human or a future cross-check pass can catch this |
| Ollama not running / model not pulled | Environment issue | `extract()` raises `ExtractionFailed` with the subprocess error; `run_all.py` catches per-episode, continues to the next episode rather than aborting the whole run |
| `dataset/` write attempted | Should never happen — bug if it does | Not applicable: this app never opens a path under `dataset/` for writing; only reads `text_context.py`'s in-memory `VERIFIED` dict |

### Error Handling

| Error | Cause | Response |
|-------|-------|----------|
| `subprocess.TimeoutExpired` | Model hangs (observed real call times: 4-55s for the 4 tested models) | 180s timeout per call (generous margin over the slowest observed real call); on timeout, treat as `ExtractionFailed`, move on |
| `json.JSONDecodeError` after brace-matching fallback | Model output isn't valid JSON at all | `ExtractionFailed`, raw output preserved verbatim in `report.md` |
| Empty `characters` list on a non-empty excerpt | Model returned syntactically valid but semantically empty JSON | Written through as a real (if useless) result, not silently discarded — `report.md` flags zero-character extractions for human attention, same as the placeholder-name check above |

## Dependencies

### Requires

- `apps/comics-ai/comics-positioning/scripts/text_context.py` (read-only import) — the 6 real
  verified excerpts this flow's Must-Have operates on.
- Local `ollama` with `qwen2.5-coder:32b` pulled (confirmed present in this environment).

### Blocks

- Nothing currently — this flow's output is a **Should-Have adoption target** for
  `sdd-comics-ai-multimodal` (character identity), `sdd-comics-ai-positioning` (semantic
  `text_context` upgrade, reading-order cross-check), and `vdd-comics-editor-systematization-uiux`
  (variant tag), per Requirements' Won't-Have — none of those are blocked on this flow completing,
  they just have nothing to adopt until it does.

## Integration Points

### External Systems

- **Ollama** (local HTTP/CLI service, `qwen2.5-coder:32b` model) — the only external dependency,
  entirely local per the Requirements constraint (no paid API).

### Internal Systems

- Reads `apps/comics-ai/comics-positioning/scripts/text_context.py::VERIFIED` directly (Python
  import, not a file-format contract — both apps live in this monorepo).
- **Documented (not built) future consumption contract**, for each of the three flows identified in
  Requirements:
  - `sdd-comics-ai-multimodal`: a character named in `SceneExtraction.characters` for an episode
    already known to contain that episode's regions could replace/augment the current
    episode-name-token identity heuristic. Adoption is that flow's own future work.
  - `sdd-comics-ai-positioning`: `SceneExtraction` could replace `text_context_length`
    (`positioner_features.py`) with a semantic feature (e.g. embedding or keyword-overlap against a
    region's OCR'd dialogue) — a real feature-engineering task for that flow to pick up, not
    prescribed here.
  - `vdd-comics-editor-systematization-uiux`: `CharacterMention.action_or_state` is a direct
    candidate source for the "variant" tag (e.g. "permitted to choose her own path" →
    a pose/emotion tag) — needs that flow's own taxonomy-design work to map free text to a controlled
    vocabulary, not done here.

## Testing Strategy

### Unit Tests

- [ ] `scene_models.py` — `SceneExtraction`/`CharacterMention` construction and equality (pure data,
      no ollama call)
- [ ] `extract_scene.py::build_prompt` — deterministic prompt string given an excerpt (pure
      string-building, no ollama call)
- [ ] `extract_scene.py`'s JSON-parsing path — fed **canned model output strings** (not a live
      ollama call) covering: well-formed JSON, JSON wrapped in prose/markdown fences (brace-matching
      fallback), truly malformed output (`ExtractionFailed`), empty `characters` list
- [ ] `run_all.py`'s coverage bookkeeping — given a fake `VERIFIED` dict and a stubbed `extract()`,
      confirms all three status categories (extracted/failed/no-source-text) are correctly counted

### Integration Tests

- [ ] One real, live `ollama run qwen2.5-coder:32b` call against episode 21's real excerpt,
      asserting the response parses as valid `SceneExtraction` JSON and contains "Amba" among the
      character names (regression guard against a model/prompt change silently breaking the one
      known-good case) — marked slow/optional (real model call, ~20-55s), skippable in fast test runs

### Manual Verification

- [ ] Run `run_all.py` for real against all 6 `VERIFIED` episodes; read `work/report.md` and
      spot-check at least the 2 episodes already tested manually in Requirements (21, and one
      Kartavirya-arc episode) against the known real entities to confirm no regression from the
      spike's ad hoc CLI runs to the real committed script

## Migration / Rollout

None — new, standalone, read-only-on-`dataset/` app; no existing system is migrated.

## Open Design Questions

- [ ] Should `run_all.py` also attempt extraction against `comics-ai-baloons`'s OCR'd dialogue
      (broad coverage, all 16 training episodes) as a fallback when no `spiritual_text` match exists,
      or stay strictly scoped to the 6 hand-verified excerpts this iteration? Leaning toward staying
      scoped (Requirements' Must-Have only commits to episodes with real matched narrative) and
      leaving OCR-dialogue extraction as a clearly-separated future extension, since OCR dialogue is
      balloon speech, not narrative description — a different kind of text with different extraction
      characteristics, worth its own evaluation pass rather than assuming the same prompt/model works.

---

## Approval

- [x] Reviewed by: Anton Dodonov (via "доделываем" directive)
- [x] Approved on: 2026-08-01
- [x] Notes: Proceeding to Plan on the same Auto Mode basis as Requirements approval.
