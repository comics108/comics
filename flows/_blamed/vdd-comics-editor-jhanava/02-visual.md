# Visual Mockups: comics-editor-jhanava

> Version: 0.1 (conceptual sketches — conversation starters, not committed designs)
> Status: DRAFT
> Last Updated: 2026-07-30

## Overview

Per `01-requirements.md`, this flow is a seed capture of one product conversation, not a scoped
feature — these mockups exist to give Джанава and the team something concrete to react to, not to
lock in a design. Two ideas sketched, both directly from the requirements doc's two stacked
problems: **(1)** material systematization before placement, **(2)** a unified kind model whose
tooling complexity should match each kind's real difficulty (background > character > balloon /
sound). Nothing here should be read as more settled than "here's one way this *could* look."

Kind-chip visual language borrows from `vdd-comics-editor-uiux-lettering`'s design (violet/amber/
etc. chips) only for *consistency of vocabulary* — colors/values here are placeholders, not a
commitment, and the two flows' `kind` fields are meant to converge later, not diverge now.

---

## Screen: Material intake (conceptual)

The "cutting/systematizing before placement" problem, sketched as a triage screen: raw source art
comes in, gets sliced into candidate pieces (manually, or assisted), each piece gets a kind tag and
either goes to a placement queue or gets flagged as unresolved.

```
+----------------------------------------------------------------+
|  Material Intake                              [Import source]  |
+----------------------------------------------------------------+
|  SOURCE: beach_page_04_raw.psd                    12 layers    |
+----------------------------------------------------------------+
|  Detected pieces                     Kind          Status      |
|  +------------------------------------------------------------+|
|  | [thumb] sky_gradient              [Background]  -> queue   ||
|  | [thumb] hero_standing              [Character]   -> queue   ||
|  | [thumb] hero_arm_raised            [Character]   ? split?   ||  <- ambiguous: same
|  | [thumb] balloon_outline_04         [Balloon]      -> queue   ||     character, two poses?
|  | [thumb] rock_formation             [Background]  -> queue   ||
|  | [thumb] unlabeled_shape_07         [?]            ! review   ||  <- couldn't classify
|  +------------------------------------------------------------+|
|                                                                  |
|  6 pieces detected · 4 queued · 1 needs review · 1 ambiguous    |
|              [ Send queued pieces to placement ]                |
+----------------------------------------------------------------+
```

### Notes on this sketch

- "Detected" implies some automated slicing/classification assist — **unvalidated assumption**;
  might really be a fully manual cutting workflow instead. The open question in requirements
  ("is this a tooling problem or a process/workflow problem") is exactly about whether this screen
  should exist at all vs. upstream art delivery just arriving pre-organized — if it's the latter,
  this entire screen is the wrong shape and the real fix is upstream of the editor entirely.
- The `[?]` / "needs review" / "ambiguous" states matter more than the happy path here — Джанава's
  framing suggests this step is inherently messy (real source art won't cleanly decompose), so
  whatever this becomes needs to handle "couldn't tell" as a first-class, common case, not an edge
  case.

---

## Screen: Kind-complexity aware placement (conceptual)

Sketch of the *idea* that tooling sophistication should scale with each kind's real difficulty —
not a specific screen so much as a way of organizing what "placement" even means per kind.

```
Sound / Balloon (simple)          Character (moderate)           Background (hard)
+---------------------+           +----------------------+       +-------------------------+
| position + size      |          | position + size        |     | multi-layer depth        |
| (already ~done for    |         | + pose/perspective      |     | + parallax               |
|  balloon, per the      |        |   match to scene        |     | + seamless tiling/extend  |
|  lettering flow)        |       | + occlusion vs.          |     | + lighting/color match    |
|                          |      |   background/other       |     |   to adjacent pages       |
| [Lettering flow already |       |   characters             |     |                           |
|  covers this kind]      |       | [NOT built anywhere yet] |     | [NOT built anywhere yet]  |
+---------------------+           +----------------------+       +-------------------------+
      simplest  <---------------------------------------------------------------->  hardest
```

### Notes on this sketch

- This is a **complexity map, not a UI** — meant to make Джанава's ordering (balloon "nothing"
  compared to character, character "an order of magnitude simpler" than background) legible as
  something to confirm/correct, not to prescribe three different editor screens, before it's clear
  which of these need dedicated tooling at all vs. reuse of the generic layer-transform controls
  the editor already has (position/scale/rotate, which arguably already "solve" the simple end of
  this for any kind, balloon included).
- Genuinely open: does *character* placement need bespoke tooling, or does it mostly need the
  *material* (individual poses, pre-cut) to already exist correctly, with placement itself being
  close to what balloons already need? Can't tell from one exchange — needs real examples.

---

## Component: Kind picker (shared vocabulary sketch)

Placeholder for whatever `kind` picker either flow ends up building — sketched once here so the two
flows can compare notes rather than invent incompatible pickers independently.

```
+--------------------------------------------+
|  Layer kind                                 |
|  ( ) Background   ( ) Character              |
|  (*) Balloon        ( ) Sound                 |
|  ( ) Unassigned (today's default)             |
+--------------------------------------------+
```

Deliberately a flat list here, *not* implying the complexity ordering above should show up in the
picker itself — that ordering is about tooling investment, not about how a user picks a kind.

---

## Screen: Motion/FX overlay timeline (conceptual, default-assumption sketch, added 2026-07-30)

Sketch of what `comics_video_sample` implies is needed, **under a stated default assumption**: that
this becomes an in-editor capability rather than "export assets, assemble in CapCut" (the scope-fork
question — tracked in `flows/sdd-comics-editor-questions/`, Group B — is unresolved; this sketch
picks one branch deliberately to have something concrete to react to, not because that branch is
decided). If the answer comes back "CapCut stays the assembly tool," this whole screen is the wrong
shape and the real deliverable becomes an asset exporter instead.

```
+----------------------------------------------------------------+
|  Panel: beach_page_04                        [Export video >]  |
+----------------------------------------------------------------+
|                                                                  |
|                    [ static panel preview ]                     |
|                                                                  |
+----------------------------------------------------------------+
|  Timeline                                          00:06.16    |
|  +------------------------------------------------------------+|
|  | Base panel  |████████████████████████████████████████████ ||
|  | Overlay: fx |        |~~~butterfly~~~|                     ||  <- motion/FX kind,
|  |             |        [fade in][fade out]                    ||     drag to reposition
|  | Audio       |################################################||     /resize in time
|  +------------------------------------------------------------+|
|  0s        1s        2s        3s        4s        5s        6s |
|                                                                  |
|  [+ Add overlay clip]   [+ Add audio]     Aspect: 9:16 (social)  |
+----------------------------------------------------------------+
```

### Notes on this sketch

- The base panel is a full-duration static track; the "Overlay: fx" row is where a motion/FX asset
  (5th kind, per requirements) gets placed **in time**, not just in space — this is the concrete
  form of "time as a first-class editing dimension" from the requirements doc's gap analysis.
  Fade in/out handles represent transition authoring (gap 2a), deliberately drawn as a distinct,
  adjustable affordance rather than assumed free.
- This is the first screen in this flow that isn't a variant of position/scale/rotate — it requires
  a timeline UI the current `comics-editor-v2.9` doesn't have in any form. Flagging that explicitly
  so nobody mistakes this sketch for "a small extension of the existing layer editor."
- Where the overlay clip itself comes from (hand-animated/stock/AI-generated) is untouched by this
  sketch — it assumes the clip already exists as an importable asset, per the still-open "sourcing"
  question in `sdd-comics-editor-questions`.
- Genuinely a placeholder for a conversation, same as every other sketch in this document — drawn
  now only because the *decision* of whether to build it lives in the questions backlog, not because
  this shape is validated.

---

## Notes

- **2026-07-30**: `01-requirements.md` gained a new "Reference Example" section analyzing
  `dataset/comics_video_sample(...).mov` (Бхагаван's video-comic sample), and a first sketch for it
  was added above once the open questions blocking it were moved to
  `flows/sdd-comics-editor-questions/` rather than gating this flow directly.
- Language handling: per the user's correction, any language-related UI in future iterations of
  this flow must be **dynamic** (driven by whatever language set exists in the data), never
  hardcoded to a fixed count — same principle as `vdd-comics-editor-uiux-lettering`.
- Everything in this document is downstream of a single short exchange, not a validated design
  process — treat every mockup here as a question ("is this even the right shape?"), not an answer.
- Method note for whoever picks this up next: `apps/comics-ai-baloons` is worth studying not for
  its balloon-specific conclusions (balloon is explicitly the *simplest* case here) but for its
  *method* — it didn't design anything until it had actually opened real files and counted real
  things. The Material Intake sketch above is exactly the kind of screen that should not be
  finalized without first looking at what real `dataset/`-style raw source material (pre-cutting,
  if such a thing is even archived) actually looks like.

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: Not seeking approval — conceptual sketches for discussion, per this flow's seed status.
