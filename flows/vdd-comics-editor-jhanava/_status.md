# Status: vdd-comics-editor-jhanava

## Current Phase

REQUIREMENTS / VISUAL (both drafted as a seed capture — see below, neither seeking approval yet)

## Phase Status

DRAFTING (unparked for continued hypothesis-level work now that open questions are tracked
separately in `sdd-comics-editor-questions`; still not an active build flow — no Specifications
until a real session happens)

## Last Updated

2026-07-30 by Claude (extracted open questions to `sdd-comics-editor-questions`; unparked for
continued conceptual drafting)

## Blockers

- **No hard blocker on continuing conceptual drafting.** Every stakeholder-dependent unknown this
  flow raised (Джанава's taxonomy questions, the video-sample scope-fork question, etc.) has been
  extracted to `flows/sdd-comics-editor-questions/` on 2026-07-30 so it's tracked without gating
  this flow. This flow now proceeds on stated hypotheses/defaults.
- **Still blocked on a real elicitation session** before anything here can move to Specifications
  or be treated as validated — that hasn't changed. What changed is that "blocked" no longer means
  "cannot do anything," it means "cannot finalize/approve anything." Sketching, hypothesis-level
  drafting, and structuring can continue; committing to a specific design still needs Джанава and
  Бхагаван's actual input.

## Progress

- [x] Requirements drafted (2026-07-30) — seed capture only, not a real elicitation
- [ ] Requirements approved — not being sought yet
- [x] Visual drafted (2026-07-30) — conceptual sketches only, not committed designs
- [ ] Visual approved — not being sought yet
- [ ] Specifications drafted
- [ ] Specifications approved
- [ ] Plan drafted
- [ ] Plan approved
- [ ] Implementation started
- [ ] Implementation complete
- [ ] Documentation drafted
- [ ] Documentation approved

## Context Notes

- **Purpose of this flow**: parking lot for a product insight that surfaced while scoping
  `vdd-comics-editor-uiux-lettering`, per explicit user instruction not to let it narrow that
  flow's scope. Captures Джанава's framing: a full content-kind taxonomy (background, character,
  balloon, sound — in increasing order of *decreasing* difficulty: background hardest, sound/
  balloon simplest) and a bigger prerequisite problem ("нарезка и систематизация имеющегося
  материала" — cutting/organizing raw source material before any placement work).
- Both `01-requirements.md` and `02-visual.md` are deliberately written as honest, hedged
  first-passes — full of "unvalidated," "unknown," "needs a real session" — not polished
  deliverables. That's intentional given the source material is one short exchange, not a proper
  elicitation.
- **Relationship to `vdd-comics-editor-uiux-lettering`**: that flow is NOT constrained by anything
  here. It returns to its original (pre-Джанава) plan. The only intended coupling: both flows use
  an open-string `kind` field (not a closed enum) so they can converge later without a migration,
  and both apply the "language lists must be dynamic, never a hardcoded count" correction the user
  gave while setting this flow up.
- Method note left in `02-visual.md` for whoever picks this up: `apps/comics-ai-baloons` is a good
  template for *how* to scope this properly (real dataset investigation before design), even though
  its subject (balloons) is explicitly the simplest of the four kinds here.
- **2026-07-30 addition**: per explicit user request, added
  `dataset/comics_video_sample(bad quality camera capture from phone).mov` — Бхагаван's example of
  what an "interactive video comic" result looks like — to this flow's scope. Analyzed via extracted
  frames + audio track (audio content itself not transcribed, no speech-to-text tool available
  here). Full breakdown in `01-requirements.md`'s new "Reference Example" section. Headline finding:
  the sample is a static comic panel with a brief animated overlay insert (a glowing butterfly),
  exported as a short vertical video from CapCut (an external tool) — this is NOT explained by the
  existing 4-kind taxonomy or material-intake problem alone. It surfaces at least: a 5th kind
  (motion/FX overlay), a timeline/timing dimension the current static-placement editor lacks, a
  video-export pipeline question, audio-sync, and an unresolved question of whether "interactive"
  literally means touch-driven (not shown in the sample) or is loose language.
- **2026-07-30, same session**: per explicit user request, all open questions from both sources
  (Джанава's framing + the video sample) were extracted verbatim into a new flow,
  `flows/sdd-comics-editor-questions/`, and removed from `01-requirements.md`'s Open Questions
  section (now just a pointer). This flow no longer carries them as inline blockers — they're
  tracked there until a real session resolves them, and answers get routed back here.

## Fork History

- Spun out of `flows/vdd-comics-editor-uiux-lettering/` on 2026-07-30, per explicit user request,
  to prevent one product consultation's answers from narrowing that flow's original scope while
  still preserving the bigger-picture insight for later.

## Next Actions

1. Now that the open questions live in `sdd-comics-editor-questions` rather than gating this flow,
   continued conceptual drafting here (e.g. sketching the video/motion-overlay idea in
   `02-visual.md` under explicit default assumptions) is fair game — see the sketch added
   2026-07-30 for the first instance of this.
2. Still true regardless: nothing here moves to Specifications, and no sketch gets treated as a
   real design, until there's an actual session with Джанава and Бхагаван. Answers from that session
   should be pulled back from `sdd-comics-editor-questions` into this flow's docs when they land.
3. When picked up for real: start by investigating actual source material (per the method note),
   not by refining these speculative sketches further.
