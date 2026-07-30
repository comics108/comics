# Requirements: comics-editor-jhanava

> Version: 0.1 (seed capture — not yet a validated requirements doc)
> Status: DRAFT
> Last Updated: 2026-07-30

## Origin

Spun out of `flows/vdd-comics-editor-uiux-lettering/` on 2026-07-30. While scoping that (narrower)
lettering/balloon flow, the user consulted a product friend — spiritual name **Джанава**, given
name **Евгений Корытный** — whose answer reframed the problem at a much larger scale than "balloon
text UI." Rather than let that reframing shrink the lettering flow's original scope, the user asked
to park Джанава's understanding here as its own flow, and return the lettering flow to its original
plan. **This document is a seed capture of that input, not a completed requirements-elicitation
session** — Джанава and the wider team still need to be looped in properly before this is real.

## Problem Statement

`apps/comics-editor-v2.9` has no concept of layer *kind* today — every layer (background,
character, balloon, sound-adjacent visual elements) is the same generic `Layer`. The
lettering-focused flow addresses this narrowly for balloons. Джанава's framing suggests the real
problem is broader and structured differently than "add balloon support":

> Задача размещения балуна — ничто по сравнению с задачей размещения персонажа. А персонаж на
> порядок проще фона. Ещё более глобальная задача — нарезка и систематизация имеющегося материала
> перед размещением.

(*Placing a balloon is nothing compared to placing a character. And a character is an order of
magnitude simpler than a background. An even bigger task is cutting/systematizing existing source
material before placement.*)

This implies at least two distinct, stacked problems, neither of which the lettering flow attempts
to solve:

1. **A unified content-kind model** spanning at minimum background, character, balloon, and sound
   (Джанава's list), each with *very different* placement/editing complexity — not a flat list of
   equally-weighted "kinds," but a real difficulty gradient the tooling needs to respect.
2. **Material preparation, prior to any placement**: getting raw source art (however it currently
   arrives — full illustrated pages, layered PSDs, whatever the actual production input is) cut
   into individual usable pieces and organized/tagged, *before* anyone places anything. Per the
   user: this may be the bigger, more foundational problem of the two.

## Reference Example: Бхагаван's video-comic sample (added 2026-07-30)

`dataset/comics_video_sample(bad quality camera capture from phone).mov` — a phone recording of a
Mac screen, added to scope per explicit user request as a concrete example of the kind of output
Бхагаван has in mind for "interactive video comic." Analyzed by extracting frames + audio (no
speech-to-text available in this environment, so the audio track — AAC, present, unreviewed — has
not been transcribed; someone should actually listen to it before treating this analysis as
complete).

**What the recording actually shows**: a ~6.5s (`00:00:06:16` timecode) portrait/vertical clip
being previewed inside **CapCut** (a general-purpose consumer video editor, Russian-localized menu)
on a Mac, looping ~2.7 times over the 17.8s phone capture. Within that one clip:

1. Opens on a **static illustrated comic panel** — a village/ashram scene (thatched hut, palm
   trees, robed figures), same house art style as the existing comic pages in `dataset/`.
2. Around ~1-3s in, the frame **cross-fades/cuts to a fully different animated graphic**: a
   glowing, swirling butterfly with a radiating light-trail effect, animating in place (not a
   static image — genuine motion).
3. By ~3s it returns to (or settles back on) the **same static village panel**, which then holds
   static for the remaining ~3.5s to the loop point.

So the deliverable is: **static comic panel → brief animated "magic" insert → static comic panel**,
assembled as an exported video file, vertical aspect ratio, short fixed duration, with an audio
track — built today in an external general-purpose tool (CapCut), not in `comics-editor-v2.9`.

**Important nuance**: nothing in the capture shows actual touch/tap/user interaction — it is a
straight, non-interactive video playing in an editor's preview pane. Whatever Бхагаван means by
"interactive video comic" is *not demonstrated* by this sample as literal touch-driven interaction;
either the word is being used loosely (interactive = "feels alive," not "responds to input"), or
the interactive part is a separate thing this clip doesn't capture. **Unvalidated — needs to be
asked directly**, not assumed either way.

### What else this implies is needed in scope (beyond the existing 4-kind taxonomy + material-intake
problem already in this document)

The existing kind taxonomy (background/character/balloon/sound) and the "cut & systematize before
placement" problem are necessary but **not sufficient** to produce this result. Additional gaps this
example surfaces:

1. **A 5th content kind: motion/FX overlay.** The glowing butterfly is neither background,
   character, balloon, nor sound — it's a short animated loop/clip asset. Nothing in the taxonomy so
   far accounts for "an animated element that gets composited over a panel for part of a timeline."
2. **Time as a first-class editing dimension.** `comics-editor-v2.9` today (per the rest of this
   codebase) is a static-placement tool — position/scale/rotate, no timeline, no "at t=1.2s show X
   for 0.8s then cross-fade back." This result requires sequencing/timing, which is a materially
   different editing model than anything the current editor or the lettering/balloon flow needs.
2a. **Transition authoring** — the cross-fade/cut between static panel and animated overlay is
   itself a thing someone chose (duration, easing, in/out point) — not free with just "place a video
   layer," needs its own controls.
3. **Export to video, not just interactive digital pages.** The current product's output (as far as
   this flow's authors know) is an interactive reading experience, not a rendered video file. This
   sample's output is an `.mp4`/`.mov`-shaped artifact: fixed duration, fixed vertical resolution,
   baked-in timing — a genuinely different export pipeline/target, likely aimed at social/short-form
   video (Reels/Shorts/Stories) distribution rather than the in-app reading experience.
4. **Audio timeline support.** The exported clip carries an audio track (unreviewed content) that
   has to be authored/synced against the visual timeline — another capability absent from a
   static-layer editor.
5. **Sourcing the motion asset itself.** Where does an animated "glowing butterfly" come from? Hand
   animated frame-by-frame, a licensed/stock motion asset, or AI-generated (e.g. image-to-video)?
   Unknown, but it's a production step upstream of any editor UI, and it's a new kind of raw material
   the "material intake/systematization" problem (see above) needs to account for — not just cut
   static pieces, but sourced/generated motion loops too.
6. **Scope-fork decision, unresolved**: is the target for this flow to build video-timeline/export
   capability *into* `comics-editor-v2.9` itself, or to accept CapCut (or similar) as the actual
   assembly tool and scope this flow's job as *feeding it well-prepared assets* (panel image +
   pre-cut motion overlay, correctly sized/timed)? These are very different-sized efforts and the
   sample alone doesn't tell us which Бхагаван/Джанава expect.

These six points are now open questions tracked in `flows/sdd-comics-editor-questions/` (Group B),
not settled scope — this section documents what the *example* implies is missing, it does not
commit to building any of it.

## User Stories

Speculative — not yet validated with Джанава or the wider team beyond the single exchange above.

### Primary (hypothesis)

**As a** comics production artist/technical director
**I want** raw source material systematically cut and categorized into placeable pieces (by kind:
background/character/balloon/sound/...), before touching any placement tooling
**So that** placement tooling (including the lettering flow's balloon work) has well-formed input
to work with, instead of ad-hoc undifferentiated layers

### Secondary (hypothesis)

- **As a** comics editor user, **I want** placement tooling whose complexity/sophistication matches
  each kind's actual difficulty (sound/balloon = simple, character = moderate, background = hard),
  **so that** simple cases aren't over-engineered and hard cases aren't under-served by one-size UI.

## Acceptance Criteria

Not yet defined — this document doesn't have enough real input to state Must/Should/Won't Have
responsibly. Placeholder structure kept for when a real elicitation session happens.

### Must Have

TBD — needs a proper session with Джанава (and likely production artists who do this work today)
before any criteria here would mean anything.

### Won't Have (This Iteration)

- Nothing is being built by this flow yet — see Visual phase note below on what *is* produced now
  (conceptual sketches to drive the next real conversation, not a build target).

## Constraints

- **Relationship to `vdd-comics-editor-uiux-lettering`**: that flow proceeds on its original plan,
  unconstrained by anything decided (or not decided) here. This flow's `kind` taxonomy thinking
  should stay compatible with that flow's open-string `kind` field (not a closed enum) so the two
  can converge later without a migration, but that's the only coupling.
- **Language handling** (a correction the user made while setting up this flow, applies here too if
  relevant): language lists must be **dynamic**, not hardcoded to a fixed count (neither 3 nor 20)
  anywhere in either flow's design.

## Open Questions

Extracted to `flows/sdd-comics-editor-questions/` on 2026-07-30 (per explicit user request), so this
flow's continued drafting isn't gated by needing every one of them answered first. That flow tracks
them until a real session with Джанава/Бхагаван happens; answers get routed back here as they land.
This flow proceeds in the meantime on stated hypotheses/defaults, not on resolved answers.

## References

- `flows/vdd-comics-editor-uiux-lettering/` — the narrower flow this was spun out of; see its
  `_status.md` for the full exchange this seed is based on
- `apps/comics-ai-baloons/` — worth studying as a *method* reference (real dataset investigation
  before design) even though its subject, balloons, is explicitly the "simplest" of the four kinds
- `dataset/comics_video_sample(bad quality camera capture from phone).mov` — Бхагаван's reference
  example of "interactive video comic," added 2026-07-30; see Reference Example section above for
  the full breakdown of what it shows and what it implies is missing from scope
- `flows/sdd-comics-editor-questions/` — consolidated backlog of every open question this flow has
  raised (both Джанава's kind-taxonomy framing and the video-sample analysis); extracted out on
  2026-07-30 so this flow isn't gated by needing all of them answered first

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: Not seeking approval yet — this is a parking-lot capture. Real requirements work
      starts when there's bandwidth for a proper session with Джанава and production stakeholders.
