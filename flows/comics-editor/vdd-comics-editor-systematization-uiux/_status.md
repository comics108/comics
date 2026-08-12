# Status: vdd-comics-editor-systematization-uiux

## Current Phase

REQUIREMENTS (character-variant topic) / VISUAL (layer-grouping topic — see below, phases now
diverge per topic)

## Phase Status

**Two unrelated topics now live in this flow** (see `01-requirements.md`'s Scope note,
2026-08-07):
1. **Character variant tagging** (original scope) — still DRAFTING/parked, unchanged, still
   blocked on a real Джанава session.
2. **Layer Grouping** (new, 2026-08-07, per Anton's direct request while resolving an Open
   Question in `flows/comics-editor/tdd-dot-bodymovin-import-export`) — NOT blocked, real, immediately
   actionable. Requirements + Visual both drafted same day.

## Last Updated

2026-08-07 by Claude

## Blockers

- **Character-variant topic**: same as `vdd-comics-editor-jhanava` — nothing validated with
  Джанава yet; variant-tag sourcing also rides on the unresolved text-grounding feasibility
  question in `sdd-comics-ai-positioning`/`sdd-comics-editor-questions`.
- **Layer-grouping topic**: none — the backward-compatibility mechanism (`Layer.GroupId`, purely
  organizational, zero rendering effect) is already decided, not open. Four smaller Open Questions
  remain (nested groups, exclusive membership, group naming, whether `Group` needs its own
  top-level `data.json` entity) but none block moving to Specifications once Anton reviews.

## Progress

**Character-variant topic** (unchanged):
- [x] Requirements drafted (2026-08-01) — v0.1, extracted verbatim from `vdd-comics-editor-jhanava`'s
      "Material Systematization — Concrete Shape" section, per explicit user request
- [ ] Requirements approved
- [ ] Specifications drafted / approved / Plan / Implementation — all pending, blocked as above

**Layer-grouping topic** (new):
- [x] Requirements drafted (2026-08-07) — added as a new section in `01-requirements.md` v0.2
- [ ] Requirements approved
- [x] Visual drafted (2026-08-07) — `02-visual.md` v1.0: layers-panel before/after grouping,
      multi-select→Group, collapsed/expanded states, group-drag-moves-all-members, and the
      Bodymovin-import-produces-a-pre-populated-group case
- [ ] Visual approved
- [ ] Specifications drafted
- [ ] Plan drafted
- [ ] Implementation started

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
- **Second addition (2026-08-07)**: Layer Grouping content added directly by Claude per Anton's
  explicit instruction while resolving an Open Question in the sibling flow
  `flows/comics-editor/tdd-dot-bodymovin-import-export`. Not extracted from another flow's content —
  authored fresh here, grounded in real code (`scene_panel.dart`, `models.dart`) and the already-
  decided backward-compatibility mechanism.

## Next Actions

**Character-variant topic**:
1. Add a pointer in `vdd-comics-editor-jhanava/01-requirements.md` and `_status.md` replacing the
   extracted section, per the same pattern used for `sdd-comics-editor-questions`.
2. When picked up for real: same method-note as the parent flow applies — look at real
   `work/library/characters/` crops for an actual character before designing a variant taxonomy in
   the abstract, don't invent categories speculatively.
3. Still blocked on an actual session with Джанава before anything here moves past REQUIREMENTS.

**Layer-grouping topic**:
1. Anton reviews `01-requirements.md`'s Layer Grouping section and `02-visual.md` — in particular
   the 4 Open Questions (nested groups, exclusive membership, group naming, whether `Group` needs
   its own top-level entity).
2. Once approved, the schema addition (`Layer.GroupId`) should also be reflected as a new fact in
   `flows/tdd-dot-comics-format` (the format's own consolidated reference), and the sibling
   `flows/comics-editor/tdd-dot-bodymovin-import-export` flow can un-block its precomp-handling
   Must-Have criteria against a concrete, approved design.
3. This topic is NOT blocked on the character-variant topic or on Джанава — it can proceed
   independently through Specifications/Plan/Implementation on its own timeline.
