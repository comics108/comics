# Requirements: comics-ai-script-context

> Version: 0.2 (v0.1's Open Questions resolved against a real Ollama model-comparison spike, not left
> as guesses)
> Status: APPROVED
> Last Updated: 2026-08-01

## Origin

Spun out of `flows/sdd-comics-editor-questions/`'s "Group D" discussion (2026-08-01): Anton shared a
pipeline idea from Джанава (materials in `vendors/anima/`) — simplify scripture narrative into a
pseudo-script with named entities via LLM, then train downstream models ("нарезатор"/"позиционер")
on that simplified representation. Investigation across every real flow in this repo (see that
discussion) found **no flow does LLM-based narrative→structured-script conversion anywhere** — this
is genuinely new capability, not an extension disguised as one. Rather than bolt an LLM step onto
three different flows independently (`sdd-comics-ai-multimodal`, `sdd-comics-ai-positioning`,
`vdd-comics-editor-systematization-uiux`) with incompatible schemas, this flow exists to build **one
shared source** the others consume.

**User constraint given at flow creation**: use a **local LLM via Ollama** — no paid API. This
resolves a blocker flagged during the Group D discussion (no confirmed paid-API access in this
environment). Verified real environment state (2026-08-01): Ollama is installed and has many models
pulled already, including `qwen2.5-coder:32b`, `deepseek-coder:33b`, `llama2:7b`, and several
custom `nativemind/*` models (`braindler`, `mozgach108` variants, `spheres`) — but **nothing
purpose-built for narrative/creative text extraction**; the largest capable options
(`qwen2.5-coder:32b`, `deepseek-coder:33b`) are code-branded models of unverified quality for this
task, and the `nativemind/*` custom models' capabilities are unknown without direct testing. Model
selection is deliberately left to Specifications (needs a real eval, not a guess) — see Open
Questions.

## Problem Statement

Three separate flows each have a text-related gap that traces back to the same missing capability:

1. **`sdd-comics-ai-multimodal`** (COMPLETE): character identity uses a weak heuristic
   (episode-name token + visual clustering), producing generic labels like "the-2"/"the-3" — flagged
   as a known limitation, never fixed.
2. **`sdd-comics-ai-positioning`** (IMPLEMENTATION, Phase 6/8): `text_context` is currently just the
   character-length of OCR'd dialogue (no semantic content); a richer, hand-verified narrative
   signal (`spiritual_text`) exists but for 6 of 16 training-relevant episodes (episode 21, plus a 5-episode Kartavirya arc: 06/08/09/10/11), found via
   direct human reading — prior automatic matching attempts failed honestly (fuzzy-dialogue match:
   0/27; TF-IDF: biased toward long sections).
3. **`vdd-comics-editor-systematization-uiux`** (REQUIREMENTS, seed capture): proposes a
   character-library tree with a "variant" level (pose/emotion/action tag per crop, e.g. "Бирма
   falling") that has no data source at all today.

All three need the same thing: **a reliable way to turn scripture narrative text into structured,
named-entity-grounded scene information** — who's present, what they're doing/feeling. Anton's
proposal, informed by Джанава's own already-built `vendors/anima` pipeline (a *different* production
system — LLM script → AI-generated video, not applicable to this codebase's "process existing
hand-drawn art" approach, per prior analysis), is to solve this once via a local-LLM
scripture-simplification step, not three times.

## User Stories

### Primary

**As a** pipeline maintainer across `sdd-comics-ai-multimodal`, `sdd-comics-ai-positioning`, and
`vdd-comics-editor-systematization-uiux`
**I want** a single pipeline that takes an episode's real scripture narrative text (where it exists)
and produces a structured record of named entities (characters, props, locations) and their
actions/emotions
**So that** each downstream flow consumes one consistent, versioned signal instead of inventing its
own ad hoc text-parsing logic

### Secondary

- **As a** pipeline maintainer, **I want** the pipeline to run entirely on a local Ollama model, with
  no external API dependency, **so that** it matches this environment's actual constraints (no
  confirmed paid-API access) and this repo's existing precedent (`moondream` via `ollama` in
  `sdd-comics-ai-positioning`'s Phase 5 detour).
- **As a** pipeline maintainer, **I want** honest coverage reporting (which episodes got real
  extracted signal vs. which had no source text at all), **so that** downstream flows don't silently
  treat a missing signal as a negative/empty result.
- **As a** pipeline maintainer, **I want** the 6 already-human-verified matches
  (`sdd-comics-ai-positioning`'s episode 21 and the 06/08/09/10/11 Kartavirya cluster) usable as a small
  held-out sanity-check set, **so that** the LLM's extraction quality can be judged against a real,
  trusted baseline before anyone downstream relies on it.

## Acceptance Criteria

### Must Have

1. **Given** an episode with real matched `spiritual_text` narrative (currently known: episode 21,
   06/08/09/10/11 — more may be found), **when** the pipeline runs, **then** it produces a structured
   output (not free text) listing named entities present and a simplified description of their
   actions/state, grounded in that specific text — not invented/hallucinated beyond what the source
   says.
2. **Given** an episode with no matched narrative text, **when** the pipeline runs, **then** it
   honestly reports "no source text" rather than fabricating an extraction — mirrors this repo's
   established pattern (`sdd-comics-ai-multimodal`, `sdd-comics-ai-positioning`) of disclosed
   partial coverage over silently-guessed completeness.
3. **Given** the local-Ollama constraint, **when** a model is chosen for this task, **then** the
   choice is backed by a real comparison against known-good verified cases (episode 21,
   06/08/09/10/11), not assumed from a model's general reputation or its code-focused branding.
4. **Given** this output feeds three different consumer flows, **when** the output schema is
   designed, **then** it's additive/versioned so each consumer flow can adopt it independently and
   incrementally, without forcing a synchronized breaking change across all three.

### Should Have

- A lightweight automatic cross-check of extracted entities against existing OCR'd dialogue
  (`comics-ai-baloons`'s `ocr.jsonl`) or reading order, to catch obvious extraction errors without
  requiring full manual review of every episode.
- A documented recommendation (not a build requirement) for how each of the three consumer flows
  would adopt this output — concretely: identity resolution in `sdd-comics-ai-multimodal`, the
  variant tag in `vdd-comics-editor-systematization-uiux`, and a semantic replacement for
  `text_context_length` in `sdd-comics-ai-positioning`.
- **Reading-order disambiguation signal (added 2026-08-01, from Anton)**: for a source page with
  multiple panels per row (confirmed real — `sdd-comics-ai-multimodal`'s Checkpoint A found the
  printed source is "a conventionally paginated comic, fixed rectangular panel grids"), the correct
  read order is normally raster (left-to-right per row, row by row — not a true alternating
  "snake"/boustrophedon, which is rare in real comics) but can be genuinely ambiguous for irregular/
  staggered/inset panel layouts where geometry alone doesn't resolve it. The narrative's own action
  sequence (this flow's core output) is an independent signal that could confirm or correct a
  geometric guess in those cases. Directly relevant to a **real, currently-unfixed bug** found the
  same day in `sdd-comics-ai-positioning`'s `build_pairs.py::_sort_top_to_bottom` — a naive
  `(y, x)`-tuple sort that isn't real row-clustering and likely misorders genuine multi-column pages
  (see that flow's `_status.md` Blockers). This flow's output is a candidate fix/cross-check for that
  gap, not a replacement for the geometric row-clustering fix, which should happen regardless.

### Won't Have (This Iteration)

- **Any generative art step** — this flow produces text/structured-data output only, never touches
  image generation. The "AI draws a new character variant" aspiration
  (`vdd-comics-editor-systematization-uiux`) stays out of scope here entirely.
- **Full 27-episode coverage guarantee** — coverage is bounded by how much real scripture narrative
  text exists and can be matched at all; sizing this honestly (same precedent as every other AI flow
  in this repo) is a first-class deliverable, not a gap to hide.
- **Adopting `vendors/anima`'s generation-oriented DSL fields** (camera framing `!wide/medium/close`,
  zone placement `$left/center/right`, TTS/lipsync `~тон`) — not applicable to this codebase, which
  processes already-existing hand-drawn art rather than generating new visuals. Only the
  entity/action decomposition *idea* is being reused, not the DSL's generation-specific vocabulary.
- **Actually modifying `sdd-comics-ai-multimodal`, `sdd-comics-ai-positioning`, or
  `vdd-comics-editor-systematization-uiux`'s own code** to consume this output — this flow builds and
  documents the source and its contract; wiring each consumer up is each consumer flow's own future
  work (mirrors this repo's established pattern of designing an integration contract without
  building every side of it in the same flow — e.g. `sdd-comics-ai-multimodal` designed but didn't
  build its editor-review UI either).

## Constraints

- **Technical**: local Ollama only, no paid API — explicit user instruction. Model choice TBD in
  Specifications via real comparison, not assumed.
- **Technical**: `dataset/` remains read-only; output goes to a new
  `apps/comics-ai/comics-script-context/work/` (mirroring `comics-multimodal`/`comics-ai-baloons`/
  `comics-positioning`'s established convention).
- **Data availability**: real narrative source is `dataset/boranko/mahabharata/book1/spiritual_text/`
  — confirmed "Volume I., Book 1-3" only, with the file's own table of contents pointing some
  characters' continued stories to a Book 5 volume not present in `dataset/`. Coverage beyond the
  already-verified 4 episodes is unproven going in.
- **Dependencies**: soft dependency on `sdd-comics-ai-positioning`'s existing verified
  episode↔narrative matches (reused as an eval set, not rebuilt); soft dependency on
  `comics-ai-baloons`'s OCR'd dialogue (`ocr.jsonl`) if the Should-Have cross-check is pursued. No
  hard dependency on any of the three consumer flows' own code.

## Open Questions

- [x] **Which Ollama model actually performs well enough for this task? — resolved by real test
      (2026-08-01).** Ran the same structured-extraction prompt (characters/props/locations JSON)
      against the two hand-verified `text_context.py` excerpts (episode 21 "Amba's plea"; the
      06/08/09 Kartavirya cluster) on four real candidates:
      - **`qwen2.5-coder:32b` (recommended primary)**: episode 21 — correctly extracted "Amba" by
        name and correctly treated "king of Saubha" as a title, not a person's name (unlike smaller
        models); missed Bhishma. Kartavirya excerpt — correctly named 5/6 real entities (Indra,
        Jamadagni, Prasenajit, Renuka, Rama), missed only linking the epithet "the mighty ruler of
        the Haihaya tribe" to the name "Kartavirya" itself (a coreference miss, not a fabrication).
        ~20-55s/call.
      - **`nativemind/mozgach108-quality` (viable fast alternative, different error profile)**: on
        the Kartavirya excerpt it *did* resolve "Kartavirya" by name (where qwen missed it), but on
        episode 21 it duplicated the protagonist as both a generic "Heroine" placeholder *and* the
        real name "Amba" (an internal-consistency error) and mislabeled "Saubha" as a location twice.
        Much faster (~4-19s/call) — worth keeping as a fallback/cross-check model, not the primary.
      - **`qwen2.5-coder:7b`**: missed "Amba" (the actual protagonist) entirely and mislabeled
        "Saubha" as a character name rather than a place — real, disqualifying quality gap.
      - **`deepseek-coder:33b`**: also missed "Amba" entirely, same title/name confusion as the 7B
        model, weakest of the four despite similar size to the 32B model.
      - **Decision**: `qwen2.5-coder:32b` as primary extraction model. Real, disclosed residual
        limitation carried into Specifications: **coreference resolution (linking an epithet/title
        to a proper name mentioned elsewhere) is not reliable in any tested model** — this is a
        genuine accuracy ceiling, not a solved problem, and downstream consumers must treat output as
        best-effort, same as every other AI signal in this repo.
- [x] **What granularity should extraction target? — resolved: per-episode.** Matches how
      `spiritual_text` matching already works, and the source prose isn't pre-segmented into scenes —
      per-scene would require building a new segmentation step first, real added scope not justified
      until per-episode output is shown useful downstream.
- [x] **Exact output schema — resolved: flat per-episode entity list, not an anima-style tree.**
      `{characters: [{name, action_or_state}], props: [...], locations: [...]}` — validated directly
      by the real spike above, and matches what the three consumer flows actually need (a name +
      action per character), not a deeper Location→Scene nesting nothing downstream asks for.
- [x] **Validation strategy — resolved: no automated validation is trustworthy enough to be silent.**
      Given the real coreference-miss and duplication failures found above, every extraction must
      carry its raw model output alongside the parsed result (for spot-checking) and the OCR-dialogue
      cross-check stays Should-Have, not a substitute for disclosing per-episode confidence. Full
      human review of all 27 episodes is not required before internal/training use, matching Anton's
      existing direction on `spiritual_text` ("find matches however works, for your own
      understanding").

## References

- `flows/sdd-comics-editor-questions/01-requirements.md` — Group D discussion this flow was spun out
  of; the survey confirming no flow currently does LLM-based script generation
- `flows/sdd-comics-ai-positioning/` — existing `spiritual_text` spike (2 verified episode matches,
  reusable as an eval set), `text_context_length` feature this flow could eventually replace
- `flows/sdd-comics-ai-multimodal/` — the weak character-identity heuristic this flow's output could
  ground
- `flows/vdd-comics-editor-systematization-uiux/` — the variant-tag consumer; this flow's output is
  its most direct proposed data source
- `vendors/anima/markdown.md`, `vendors/anima/L.md` — Джанава's shared pipeline; source of the
  entity/action decomposition idea (not the generation-oriented DSL fields)
- `dataset/boranko/mahabharata/book1/spiritual_text/` — real narrative source text, confirmed
  partial/incomplete coverage
- `apps/comics-ai/comics-positioning/README.md` — documents the existing `ollama`+`moondream`
  precedent for local-model usage in this repo

---

## Approval

- [x] Reviewed by: Anton Dodonov (via explicit "доделываем" directive, not line-by-line review)
- [x] Approved on: 2026-08-01
- [x] Notes: Advancing on real evidence (the model-comparison spike above) rather than pausing for
      sign-off, per this repo's established Auto Mode precedent (e.g.
      `sdd-comics-ai-positioning`'s "дальше" resolution). Flagged transparently in Open Questions
      above so Anton can redirect if any resolution there is wrong.
