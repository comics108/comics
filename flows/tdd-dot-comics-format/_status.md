# Status: sdd-comics-editor-fromat-dot-comics

## Current Phase

REQUIREMENTS

## Phase Status

DRAFTING (parked — this is a reference consolidation, not an active build; same shape as
`sdd-comics-editor-questions`, kept purely for its durable, resumable, citable-document role)

## Last Updated

2026-08-01 by Claude

## Blockers

None — this isn't gated on anything; it's a consolidation of already-established facts, not new
investigation.

## Progress

- [x] Requirements drafted (2026-08-01) — v0.1, consolidated verbatim from
      `vdd-comics-editor-timeline` and `sdd-comics-ai-positioning`, per explicit user request
- [ ] Requirements approved — not applicable; see Acceptance Criteria in `01-requirements.md` for
      this flow's actual "done" condition (a faithful, checkable reference), not a doc sign-off
- [ ] Specifications drafted — not applicable to this flow's purpose
- [ ] Plan drafted — not applicable to this flow's purpose
- [ ] Implementation started — not applicable to this flow's purpose

## Context Notes

- **Purpose**: single authoritative reference for `.comics`/`data.json` format facts, so future
  flows check here first instead of re-deriving what two prior flows already investigated from real
  code. Same role in this repo's flow ecosystem as `flows/sdd-comics-editor-questions/` (a
  consolidation document, not a feature build) — SDD phase machinery beyond Requirements doesn't
  really apply here.
- **Explicitly scoped to two named sources** (`vdd-comics-editor-timeline`,
  `sdd-comics-ai-positioning`) per the user's exact request — real format facts also exist in
  `sdd-comics-ai-multimodal`, `sdd-comics-ai-baloons`, and `sdd-comics-editor-questions` (Group C)
  that were deliberately **not** pulled into this pass; flagged as an Open Question in
  `01-requirements.md` rather than silently left out.
- **Headline fact, stated explicitly per the user's request**: `.comics` is a vertical comic strip
  by default — one continuous scrollable strip with no built-in scene/page boundaries, confirmed
  directly by Anton in `vdd-comics-editor-timeline/03-specifications.md`, not just inferred from
  file geometry (though the geometry — real files 16,300-100,900px tall, all far taller than wide —
  independently agrees).

## Fork History

N/A — new flow, consolidated (not forked) from two existing flows' content per explicit user
request: "вынеси из vdd-comics-editor-timeline и sdd-comics-ai-positioning описание формата
.comics и добавь что по дефолту он vertical comic strip".

## Next Actions

1. Anton reviews `01-requirements.md` v0.1 for faithfulness to the two source flows.
2. Decide on the Open Question: extend this consolidation to the other flows known to hold real
   format facts (`sdd-comics-ai-multimodal`, `sdd-comics-ai-baloons`, `sdd-comics-editor-questions`),
   or leave this deliberately scoped to the two originally-named sources.
3. Consider adding back-references from the two source flows to this new consolidated doc (not yet
   done — mirrors the extraction pattern already used elsewhere this session, e.g.
   `sdd-comics-editor-questions` → `sdd-comics-ai-script-context`).
