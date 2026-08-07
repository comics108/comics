# Requirements: comics-editor-systematization-uiux

> Version: 0.2 (added a second, distinct topic 2026-08-07 — see "Layer Grouping" below; the
> original character-variant-tagging content is unchanged and still blocked on a Джанава session)
> Status: DRAFT
> Last Updated: 2026-08-07

## Scope note (2026-08-07) — this flow now covers TWO unrelated topics, not one

Everything from "Origin" through the end of the original "References"/"Approval" sections below is
the **original** scope: character variant/pose/emotion tagging in the material library
(`work/library/characters/`), blocked on a real Джанава session. **Layer Grouping** (new section
below, and `02-visual.md`) is a **second, unrelated topic** added per Anton's direct request while
answering an Open Question in `flows/comics-editor/tdd-dot-lottie-import-export/01-requirements.md`
— it's about grouping *layers within a single `.comics` document's canvas*, not about the character
library at all. The two share this flow's name only because "systematization" is broad enough to
cover both "organizing a character library" and "organizing a document's layers" — they don't share
data, code, or a stakeholder session. Flagging this explicitly rather than silently blending two
unrelated features into one narrative.

## Layer Grouping (added 2026-08-07 — unblocked, not waiting on Джанава)

### Origin

While drafting `flows/comics-editor/tdd-dot-lottie-import-export/01-requirements.md` (a real
feature build: import/export `.lottie` files in `apps/comics-editor`), one Open Question was how to
handle Lottie's precomp nesting (one composition embedded inside another) given `.comics`'s layer
model has no grouping concept at all. Anton's direct answer: **add real layer-grouping to the
`.comics` v2026 format**, kept backward compatible with v2012 ("достаточно правильного
отображения" — correct display is enough), and add the UI/UX visual for it here.

### Problem Statement

`apps/comics-editor`'s layers panel (`scene_panel.dart`'s `_LayersSection`/`_LayerRow`) is a flat,
unnested `ListView` — no way to select multiple layers and treat them as one unit (move together,
collapse in the list, hide/show together). This has two real drivers: (1) Lottie import needs
*somewhere* to put the fact that several imported image layers came from one precomp, without
losing that relationship; (2) independent of Lottie, grouping is a plain, common authoring
convenience (e.g. a character built from several separately-animated parts that should still move
together as a unit) that the flat layer list has never supported.

### The backward-compatibility mechanism (already decided, not open)

`Layer.GroupId` (new, optional, nullable string — same additive shape as the existing `Kind`/
`Style`/`Translations` fields, `apps/comics-editor/lib/src/ui/models.dart:129-138`). **Purely
organizational — zero effect on rendering.** Every layer's own `Anim` keyframes remain the
complete, final, absolute values they already are today; `GroupId` only groups rows in the
*editor's* layers panel and drives group-select/move-together *authoring* behavior. A v2012 reader
that has never heard of `GroupId` renders every file exactly as it does today — nothing about how a
layer's position/rotation/scale/alpha is computed changes. (For Lottie import specifically: a
precomp's own transform gets baked into each child layer's individual keyframes at import time,
before `GroupId` tagging — the same "compile to flat absolute values" step the format already
requires universally.)

### User Stories

**As** an editor user with several layers that make up one logical unit (e.g. a character's parts)
**I want** to group them, collapse the group in the layers panel, and drag any member to move the
whole group together on canvas
**So that** I don't have to select and drag N layers individually every time I reposition that unit

### Acceptance Criteria

**Must Have**:
1. Select 2+ layers → "Group" action → they collapse into one expandable row in the layers panel.
2. Dragging any grouped layer on canvas moves every member of that group by the same delta.
3. A `.comics` file saved with groups, opened by a v2012 (or any group-unaware) reader, renders
   identically to the same file with groups removed — group membership has zero rendering effect.

**Should Have**: nested groups (a group inside a group) — see Open Questions, not decided.

**Won't Have (this iteration)**: any *shared* group-level transform stored/animated separately from
its members (e.g. a single "group scale" keyframe applied on top of children at render time) — that
would break the zero-rendering-effect backward-compat guarantee and needs its own decision if ever
wanted; for now, moving/scaling a group in the editor immediately bakes the delta into each member's
own keyframes, exactly like ungrouped multi-select drag already does.

### Open Questions

- [ ] Nested groups (group-of-groups) — supported now, or single-level only for v1?
- [ ] Can a layer belong to more than one group, or is membership exclusive (one `GroupId` per
      layer, matching the simplest possible schema)? Leaning exclusive/single, not decided.
- [ ] Group naming — auto-generated ("Group 1"), inherited from a Lottie precomp's `nm` when
      imported, or always user-named?
- [ ] Does `Group` deserve to be its own top-level `data.json` entity (a list of `{id, name}`
      records) for storing a display name, or is `GroupId` alone (with names existing only in the
      editor's session state) enough for v1? The former is a second, tiny additive schema piece
      beyond just `Layer.GroupId`.

See `02-visual.md` for the layers-panel mockups (collapsed/expanded states, group-select, the
Lottie-import-produces-a-group case).

---

## Origin

Extracted verbatim from `flows/vdd-comics-editor-jhanava/01-requirements.md`'s "Material
Systematization — Concrete Shape" section on 2026-08-01, per explicit user request: that section
described exactly the parts of the systematized-material vision that are **not built in any flow
and are explicitly out of scope today** (as opposed to the parts already real — `work/library/
characters/`, the `comics-editor` Library tab — which stay in `vdd-comics-editor-jhanava` as
existing-system context). This flow exists to hold that unbuilt scope on its own, the same way
`flows/sdd-comics-editor-questions/` was split out of `vdd-comics-editor-jhanava` for open
questions.

## Problem Statement

Джанава's "нарезка и систематизация имеющегося материала" (material cutting/systematization,
`vdd-comics-editor-jhanava`'s Problem Statement) previously had no concrete structure. Anton gave it
one directly (2026-08-01): systematized material isn't a flat pile of tagged pieces, it's a **tree**:

```
image -> kind (character) -> identity (Бирма) -> variant (Бирма smiling, Бирма laughing,
                                                            Бирма crying, Бирма falling,
                                                            Бирма sitting, ...)
```

Below the existing `kind` level (background/character/balloon/sound), a `character` region further
branches by **identity** (which named character), and each identity further branches by
**variant** — a specific pose/emotion/action instance of that character, tagged descriptively.

**Levels 1-2 of this tree already exist for real** and are explicitly *not* this flow's job:
`sdd-comics-ai-multimodal` produces `work/library/characters/<name>/` (weakly-identified today —
episode-name token + visual clustering, per `flows/sdd-comics-editor-questions/`), surfaced in
`apps/comics-editor` via a producer-facing "Library" tab (`library_browser.dart`, built by
`flows/vdd-comics-editor-ai-uiux`). This flow does not rebuild or replace either of those.

**What this flow is actually about — the missing third level and beyond:**

1. **Variant tagging**: today a character's library folder is a flat set of crops with no
   pose/emotion/action tag on any of them — there's no "smiling" vs. "falling" distinction anywhere
   in the data model. Designing this taxonomy and the UI to browse/curate a character's library by
   variant (not just as an undifferentiated crop grid) is real, unbuilt scope.
2. **The downstream generative aspiration** this tagging is *for*: once enough tagged variants
   accumulate per character, plus a text description of a new desired action/emotion, **AI generates
   a new in-style variant of that character on demand** — e.g. "Бирма angry, pointing" — grounded in
   the accumulated real variants rather than generated from nothing. This is a **future capability**,
   explicitly not proposed as built or buildable in this iteration.

### How this relates to work already in flight (checked against real code, not assumed)

- **Tag sourcing overlaps with existing open work, doesn't duplicate it**: the same text-grounding
  problem already flagged in `flows/sdd-comics-editor-questions/` and taken up as a Should-Have spike
  in `flows/sdd-comics-ai-positioning/` (`spiritual_text` alignment) is the natural source for variant
  tags too — if narrative text describing a scene ("Бирма упал", "Бирма смеётся") can be reliably
  matched to a specific character region, that match gives both *identity* (already tracked there)
  and the *variant tag* (new, tracked here). Coverage/feasibility caveats already on record in those
  flows apply here directly — this flow is additive scope on the same open question, not a separate
  investigation.
- **The generative step is out of scope everywhere else today, on purpose**: `sdd-comics-ai-
  multimodal` explicitly deprioritized "net-new image generation" as lowest-priority/deferred;
  `sdd-comics-ai-positioning` only places *already-existing* hand-drawn cut regions, never generates
  new ones. Nothing contradicts building toward it eventually — this flow's variant-tagging tree is
  the prerequisite data shape for it — but no current Must-Have anywhere covers the generation step
  itself, and this flow doesn't propose changing that yet either.
- **`vendors/anima`** (Джанава's own shared material) has a compatible-shaped vocabulary for tagging
  a character instant by pose/expression/action within a scene. Its own pipeline (LLM script → AI-
  generated image/video) is not a fit for this codebase's "process existing hand-drawn art" approach
  (see the conversation this flow was extracted from) — it should not be adopted wholesale — but its
  pose/action tagging vocabulary is worth mining as a reference when this variant-tag taxonomy gets
  designed for real.

## User Stories

Speculative — not yet validated with Джанава, same caveat as the parent flow.

### Primary (hypothesis)

**As a** comics production artist/technical director
**I want** a character's accumulated library organized by pose/emotion/action, not a flat crop grid
**So that** I can find or reuse a specific expression (e.g. "Бирма falling") instead of scanning
every crop ever extracted for that character

### Secondary (hypothesis)

- **As a** pipeline maintainer, **I want** variant tags sourced from text-grounding work (once
  proven feasible) rather than 100% manual tagging, **so that** the tree fills in as a byproduct of
  existing pipeline runs, not a new manual-labeling burden
- **As a** product owner, **I want** the future "AI generates a new in-style variant from
  accumulated data + text" capability documented and scoped as a target shape, **so that** the data
  model built now (the tagging tree) doesn't need to be redesigned later to support it

## Acceptance Criteria

Not yet defined — same status as `vdd-comics-editor-jhanava`: no real elicitation session with
Джанава has happened yet. Placeholder structure kept for when one does.

### Must Have

TBD — needs a real session with Джанава (and whoever actually tags/curates this material today. if
anyone) before any criteria here would mean anything.

### Should Have

- A variant-tag taxonomy sketch (open-string, not a fixed enum — same principle as the existing
  `kind` field) and a conceptual UI extension of the existing Library tab to browse/filter by variant
- An explicit, documented data-shape proposal for what a "variant" record needs to carry (tag,
  source region reference, provenance — manual vs. text-grounded vs. inferred) so a future generative
  step has something real to train against, without committing to building that step now

### Won't Have (This Iteration)

- **Actual AI generation of new character art** — explicitly a future capability, not this flow's
  deliverable
- **An automatic tagging model** — depends on the still-unresolved text-grounding feasibility work in
  `sdd-comics-ai-positioning`/`sdd-comics-editor-questions`; this flow can design the taxonomy/UI
  around manually- or text-grounded-tagged data, but does not itself build automatic tagging

## Constraints

- **Depends on, does not rebuild**: `sdd-comics-ai-multimodal`'s `work/library/characters/` output
  and `apps/comics-editor`'s existing Library tab (`library_browser.dart`) — this flow extends that
  surface with a variant dimension, not a parallel library concept.
- **Soft-coupled to**: `sdd-comics-ai-positioning`'s text-context/`spiritual_text` work and
  `sdd-comics-editor-questions`' still-open text-grounded-identity question — variant-tag sourcing
  rides on whatever that work concludes about feasibility/coverage, not a hard blocking dependency for
  the taxonomy/UI design itself.
- **`vendors/anima`'s pose/action vocabulary**: reference only, not a pipeline to adopt (its
  generation-oriented fields — camera framing, zones, TTS — don't apply to this codebase's
  process-existing-art approach).

## Open Questions

- [ ] Same stakeholder gap as the parent flow: none of this has been validated with Джанава — needs
      a real session, not just Anton's framing.
- [ ] What's the actual variant-tag vocabulary worth using (open-ended set of poses/emotions/actions,
      or a smaller curated list)? Needs real examples from the dataset, not designed in the abstract
      (same method-note principle `vdd-comics-editor-jhanava` already flags re: `comics-ai-baloons`).
- [ ] Does manual tagging need to bootstrap this tree before any text-grounded auto-tagging is
      proven, or is the taxonomy/UI design independent of that timing question?
- [ ] Where does the line sit between "this flow" (tagging taxonomy + browsing UI) and a future
      generation flow — should the generative capability get its own flow name now (parking lot,
      like this one), or wait until the tagging tree itself exists?

## References

- `flows/vdd-comics-editor-jhanava/01-requirements.md` — source flow; "Material Systematization —
  Concrete Shape" section this flow was extracted from; also the existing-system context (Library
  tab, `work/library/`) that stays there
- `flows/sdd-comics-ai-positioning/` — the text-context/`spiritual_text` alignment work this flow's
  variant-tag sourcing would ride on
- `flows/sdd-comics-editor-questions/` — the still-open text-grounded-identity question this flow's
  variant tagging extends
- `flows/vdd-comics-editor-ai-uiux/` — built the existing Library tab (`library_browser.dart`) this
  flow extends
- `vendors/anima/markdown.md`, `vendors/anima/L.md` — Джанава's shared pose/action tagging vocabulary
  reference (generation-oriented fields not applicable, tagging vocabulary itself worth mining)

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: Not seeking approval — extracted seed capture, same status as the parent flow.
