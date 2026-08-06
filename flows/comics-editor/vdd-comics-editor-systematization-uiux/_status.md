# Status: vdd-comics-editor-systematization-uiux

## Current Phase

REQUIREMENTS

## Phase Status

DRAFTING (parked — extracted seed capture, not an active build; nothing to draft further until a
real stakeholder session with Джанава happens, same as the parent flow)

## Last Updated

2026-08-01 by Claude

## Blockers

- Same as `vdd-comics-editor-jhanava`: nothing here has been validated with Джанава — it's Anton's
  own elaboration of Джанава's "material systematization" framing, not a resolved requirement.
- Variant-tag *sourcing* (how tags actually get attached to library crops) rides on the unresolved
  text-grounding feasibility question tracked in `sdd-comics-ai-positioning`/
  `sdd-comics-editor-questions` — not a hard blocker on taxonomy/UI design, but a real open dependency
  before any auto-tagging could be built.

## Progress

- [x] Requirements drafted (2026-08-01) — v0.1, extracted verbatim from `vdd-comics-editor-jhanava`'s
      "Material Systematization — Concrete Shape" section, per explicit user request
- [ ] Requirements approved
- [ ] Specifications drafted
- [ ] Specifications approved
- [ ] Plan drafted
- [ ] Plan approved
- [ ] Implementation started
- [ ] Implementation complete
- [ ] Documentation drafted
- [ ] Documentation approved

## Context Notes

- **Purpose**: holds specifically the parts of the "material systematization" vision that are **not
  built anywhere and explicitly out of scope today** — variant-level (pose/emotion/action) tagging
  below the existing character-identity library, and the downstream aspiration of AI generating new
  in-style character variants from accumulated tagged data + text description. The parts that already
  exist for real (`work/library/characters/`, `comics-editor`'s Library tab) stay documented in
  `vdd-comics-editor-jhanava` as existing-system context, not duplicated here.
- **Relationship to `sdd-comics-ai-positioning`**: soft-coupled, not blocking. That flow's
  `spiritual_text` text-grounding spike (Should-Have, Phase 6/7) is the most plausible source of
  variant tags (text naming a character's action/emotion in a scene), but this flow's taxonomy/UI
  design doesn't need that spike to succeed first — it can also start from manually-tagged data.
- **Relationship to `vendors/anima`**: reference-only for its pose/action vocabulary shape (Location →
  Scene → named entity → pose/action) — its generation-oriented fields (camera framing, zones, TTS)
  don't apply here and should not be adopted; see the conversation this flow was extracted from for
  the full reasoning on why anima's actual pipeline doesn't fit this codebase's process-existing-art
  approach.
- **Explicitly not this flow's job**: building the generative capability itself (AI drawing a new
  Бирма variant). This flow only gets the data/taxonomy shape ready for that to be possible later —
  see Open Questions for the unresolved question of whether the generation step deserves its own
  flow name now or later.

## Fork History

- Extracted from `flows/vdd-comics-editor-jhanava/01-requirements.md`'s "Material Systematization —
  Concrete Shape" section (itself added 2026-08-01, same day) on 2026-08-01, per explicit user
  request: "вот именно все то, что 'не построена ни в одном флоу и явно out of scope сегодня'
  необходимо вынести в vdd-comics-editor-systematization-uiux". Mirrors the earlier
  `sdd-comics-editor-questions` extraction pattern from the same parent flow.

## Next Actions

1. Add a pointer in `vdd-comics-editor-jhanava/01-requirements.md` and `_status.md` replacing the
   extracted section, per the same pattern used for `sdd-comics-editor-questions`.
2. When picked up for real: same method-note as the parent flow applies — look at real
   `work/library/characters/` crops for an actual character before designing a variant taxonomy in
   the abstract, don't invent categories speculatively.
3. Still blocked on an actual session with Джанава before anything here moves past REQUIREMENTS.
