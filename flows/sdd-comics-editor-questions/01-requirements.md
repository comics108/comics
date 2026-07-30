# Requirements: comics-editor-questions

> Version: 0.1 (consolidation, not a build spec)
> Status: DRAFT
> Last Updated: 2026-07-30

## Origin

Extracted verbatim from `flows/vdd-comics-editor-jhanava/01-requirements.md` on 2026-07-30, per
explicit user request, so that flow could keep moving without being gated by needing every open
question answered first. This is **not a feature to build** — it's a consolidated backlog of
unresolved questions about comics-editor's future scope (content-kind taxonomy, material intake,
video/motion-comic export) that surfaced while scoping that flow. Its job is to hold these
questions in one place until there's a real session with **Джанава** (Евгений Корытный) and
**Бхагаван** (whoever holds that name in this context — not yet clarified) to resolve them.

## Problem Statement

`vdd-comics-editor-jhanava` accumulated a large set of open questions from two sources: (1)
Джанава's framing of a content-kind taxonomy + material-systematization problem, and (2)
Бхагаван's `comics_video_sample` reference example of an "interactive video comic." Leaving all of
them embedded in that flow's requirements doc meant every future touch of that flow read as
"blocked on everything" rather than distinguishing "what's settled enough to sketch" from "what
genuinely needs a stakeholder's answer." This flow exists to carry the latter so the former can
proceed.

## Consolidated Open Questions

### Group A — Kind taxonomy & material intake (Джанава)

- [ ] What does "raw source material" actually look like today in the real production pipeline
      (layered PSD exports? flat art with manual re-cutting? something else)? Unknown without
      talking to whoever produces it.
- [ ] Is "cutting/systematizing material" a tooling problem (build a feature for it) or a process/
      workflow problem (change how art is delivered upstream so it arrives pre-organized)? Very
      different scopes.
- [ ] What's the full kind taxonomy really, beyond Джанава's 4 examples (background, character,
      balloon, sound)? Are there more? Is "sound" a *layer* kind (e.g. visual SFX/onomatopoeia
      lettering) or does it mean the existing audio-file Sounds list — genuinely ambiguous from the
      one exchange this is based on (also flagged in the lettering flow's specs).
  - [ ] Are there examples worth looking at in `dataset/*.comics` for each kind, the way
        `apps/comics-ai-baloons` already did deep, evidence-based investigation for balloons
        specifically? That investigation's method (structural discovery, not assumptions) is a
        good template for however this gets scoped for real.
- [ ] What does "character placement, an order of magnitude harder than balloon" actually consist
      of? Pose/perspective matching? Layering against background depth? Occlusion? Unknown.
- [ ] What does "background," the hardest category, actually require? Parallax/multi-layer depth?
      Seamless tiling? Lighting/color match to adjacent pages? Unknown.
- [ ] Priority/sequencing: does material-systematization block character/background tooling
      entirely, or can they proceed in parallel with a rougher/manual systematization step for now?

### Group B — Video/motion-comic example (Бхагаван's `comics_video_sample`)

- [ ] What does "interactive" mean in "interactive video comic"? The reference sample shows a
      straight, non-interactive looping video (static panel → animated insert → static panel) built
      in CapCut — no touch/tap/branching shown. Is "interactive" loose marketing language for
      "feels alive," or is there a real interaction model (e.g. tap-to-reveal) this sample simply
      doesn't capture? Needs a direct question to Бхагаван/Джанава, not an assumption.
- [ ] Is video/timeline export (per the reference sample) meant to live *inside*
      `comics-editor-v2.9` as a new capability, or is the real job just to produce well-prepared
      static + motion assets for people to assemble in an external tool like CapCut? Materially
      different scopes.
- [ ] Where do animated overlay/FX assets (e.g. the glowing butterfly in the sample) come from —
      hand-animated, licensed/stock, or AI-generated (image-to-video)? Unknown; affects whether
      "material intake" needs to cover motion assets, not just static cut pieces.
- [ ] What's the audio track in `comics_video_sample` actually carrying (narration, music, ambient
      mic noise)? Not transcribed (no speech-to-text tooling was available in the environment where
      this was analyzed) — someone should actually listen to it before relying on any conclusion
      about audio scope.

## Acceptance Criteria

### Must Have

"Done" for this flow means every question above has: an actual answer from a real conversation with
the relevant stakeholder(s), and a note on which downstream flow(s) — `vdd-comics-editor-jhanava`,
`vdd-comics-editor-uiux-lettering`, or a new one — the answer unblocks or reshapes. This flow doesn't
build anything itself; it closes when the backlog is empty (answered) or explicitly re-triaged.

### Won't Have (This Iteration)

- No design, mockups, or code — this is a question backlog, not a feature spec.

## Constraints

- This flow does not gate `vdd-comics-editor-jhanava`'s continued drafting. That flow proceeds using
  stated hypotheses/defaults where useful, and treats these questions as tracked-elsewhere, not as
  blockers on its own next steps.

## Open Questions

See "Consolidated Open Questions" above — this flow's entire payload is open questions, so they're
kept as the primary section rather than duplicated here.

## References

- `flows/vdd-comics-editor-jhanava/` — source flow these questions were extracted from; see its
  `01-requirements.md` (Reference Example section) and `_status.md` for full context on both
  Джанава's framing and the `comics_video_sample` analysis
- `flows/vdd-comics-editor-uiux-lettering/` — the narrower, currently-unblocked flow some of these
  answers may eventually feed back into (via the shared open-string `kind` field)
- `dataset/comics_video_sample(bad quality camera capture from phone).mov` — Бхагаван's reference
  example (Group B questions)
- `apps/comics-ai-baloons/` — method reference for investigating `dataset/*.comics` per-kind

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: Not seeking approval — this is a consolidated backlog awaiting a real stakeholder
      session, not a spec to sign off on.
