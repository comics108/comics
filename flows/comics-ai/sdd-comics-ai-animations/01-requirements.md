# Requirements: comics-ai-transformations

> Version: 0.3 (renamed from `sdd-comics-ai-positioning-revised`, rescoped per explicit user
> direction to full-book coverage — including the previously-unmatched 73% — not just the
> already-matched training set; transformation/animation generation is the flow's specific new
> capability within that larger goal)
> Status: APPROVED (Auto Mode — "run" instruction treated as license to proceed with evidence-based
> resolution, same precedent as `sdd-comics-ai-script-context`'s "доделываем")
> Last Updated: 2026-08-01

## Origin

Renamed and rescoped from `flows/sdd-comics-ai-positioning-revised/` (built on
`sdd-comics-ai-positioning` and `sdd-comics-ai-script-context`, both COMPLETE) per explicit user
direction (2026-08-01, two messages): (1) the real, top-level deliverable is **finished `.comics`
files (vertical comic strip) for the entire photographed Mahabharata Book 1**, beyond the 27 that
already have cutting, positioning, balloons, and animation done, with **transformation/animation
generation** as this flow's specific new capability; (2) **full coverage is explicitly in scope,
not deferred** — "в рамках этого скоупа необходимо доделать весь непокрытый объем, в том числе
доразметить обучаемые данные, добавить везде текстовый контент и т.д. — полное покрытие везде и во
всем." An earlier draft of this document scoped the unmatched-content gap as a separate future
flow; that framing was overridden and is corrected here.

## The Real Scale of "The Whole Book" (checked before writing anything else)

Checked the real numbers rather than assume the gap is small, since this repo's established
practice is to size risk honestly before committing to it — not to avoid committing:

- **80 real photographed pages** exist in `dataset/.../comics_book_lowcamera/` — this *is* "the
  book, photographed" (the physical book runs to 198+ printed pages per `sdd-comics-ai-multimodal`
  Checkpoint A, so even full coverage of these 80 photos is bounded by what's actually been
  photographed — a prior, out-of-band gap this flow cannot close by itself).
- `sdd-comics-ai-multimodal`'s real `work/alignment.jsonl`: of **136 total detected page-rows**
  across those 80 photos, only **37 matched** an existing episode (27%) — **99 (73%) are
  `skipped_no_match`**.
- Only **27 `.comics` files exist**, and `Comics_Episodes.csv` (the episode registry) has exactly
  27 real rows — there is no list of episodes beyond these 27 to match against.
- **Correction (2026-08-02, `02-specifications.md`'s Criterion 4 Pilot)**: this section originally
  assumed most of the 99 unmatched rows must be content nobody has ever named/authored. **Checked
  directly instead of assuming**: 8 of the 27 known episodes still have zero matched photos even
  after criterion 3's fix, despite having real corpus text (14-52 OCR'd entries each) — meaning a
  real, bounded fraction of the gap is "find pages for already-known, already-authored episodes,"
  not "invent identity from nothing." Genuinely-new/uncatalogued content may still exist among the
  rest, but the balance is less dire than first assumed. See `02-specifications.md` for the full
  investigation (adjacency-based candidate signal, and a real illustration of why some episodes'
  short/generic dialogue resists phrase-based matching regardless of tuning).

**This flow's scope, per explicit direction, includes closing this gap** — Must-Have criteria below
break it into real phases rather than one undifferentiated "do everything" goal, so progress and
risk are both visible per phase, matching every other AI flow's practice in this repo.

## Naming: "transformations," not "actions"

A `.comics` layer's animatable properties are `TranslateAnim`/`RotateAnim`/`ScaleAnim`/`AlphaAnim`/
`SoundAnim` (`Comics.Editor.Models`, confirmed in a real file's `data.json`) — four of these are
literally geometric/visual **transforms**, the C# class-naming convention this codebase already
uses. "Actions" would suggest narrative actions (what a character *does*), a different, higher-level
concept `sdd-comics-ai-script-context` already extracts as descriptive text
(`CharacterMention.action_or_state`), not executable keyframe data. **Recommendation: "transformations"**
for this flow's actual output (the `Anim` keyframe data), with `script-context`'s "actions" as a
potential *input signal* to it, not a synonym.

## Real, disclosed complexity of the animation itself (checked, not assumed trivial)

Inspected a real file's `data.json` (`8a89f7d689fb441ea280cd782276bd7a.comics`, 200 layers): **mean
2.82 `Animations[]` entries per layer** (40 layers with 1, 84 with 2, 3 with 3, 41 with 4, 9 with 5,
23 with 6 — not a single static point per layer). Real, coordinated multi-property motion exists:
one sampled layer has a `ScaleAnim` 0.6→1.0 over `start=3806,end=4438`, a `TranslateAnim` sliding to
`x=705,y=4807` over `start=3015,end=4511`, and an `AlphaAnim` fading to 1.0 over
`start=3758,end=4438` — a coordinated scale/slide/fade reveal. Transformation generation is a real
content-generation problem, not a wrapper around positioning's static X/Y.

## Problem Statement

No flow builds transformation/animation generation today (`sdd-comics-ai-positioning`'s own
`PositionProposal.proposed_scale_x/y` are hardcoded to 1.0, alpha absent entirely — confirmed by
direct code read). Full-book coverage requires closing several gaps at once, per Anton's direction:

1. **Transformation generation itself** — the new capability, needed for both the 27 existing
   episodes' completeness bar and any newly-covered content.
2. **Training-data re-annotation/expansion** ("доразметить обучаемые данные") — re-attempting
   matching for the 99 unmatched page-rows, and defining new episode identity where no match to the
   27 will ever exist.
3. **Text content everywhere** ("добавить везде текстовый контент") — extending
   `sdd-comics-ai-script-context` beyond its current 6/27 (hand-verified `spiritual_text`) and
   16-episode training-relevant ceiling, toward every real episode/page this flow ends up covering,
   using every real source available (OCR dialogue, `spiritual_text`, and any new content's own
   OCR'd/translated text once it exists).
4. **Full pipeline completeness** — cutting (reused) + positioning (reused) + balloons (reused,
   `sdd-comics-ai-baloons`'s domain) + transformation (new, this flow) for whatever content this
   flow brings into coverage.

## User Stories

### Primary

**As a** pipeline maintainer
**I want** a model/pipeline that proposes the `Anim` keyframe set (properties, scroll-range, target
values) for a cut, positioned region, **and** a real plan/pipeline to bring the 73% currently-
unmatched book content into coverage at all
**So that** the whole photographed book, not just the 27 pre-existing episodes, can reach the same
completeness bar (cut, positioned, lettered, animated)

### Secondary

- **As a** pipeline maintainer, **I want** `sdd-comics-ai-script-context` extended with every real
  source available (OCR dialogue fallback, deeper `spiritual_text` mining, and text sourced from any
  newly-matched/newly-defined content), **so that** text coverage tracks however far the content
  coverage itself reaches, not capped at today's 16-episode training set.
- **As a** pipeline maintainer, **I want** the 99 unmatched page-rows re-processed with a real,
  disclosed methodology (improved matching first, then new-episode-identity definition for whatever
  remains genuinely unmatched), **so that** "full coverage" is a measured, honestly-reported
  outcome, not an unverified claim.

## Acceptance Criteria

### Must Have

1. **Transformation generation, core capability**: given real `Anim` ground truth already
   extractable from all 27 `.comics` files, build a baseline (rule-based/statistical, calibrated
   from real data, same precedent as `baseline_position.py`) and, only if a real checkpoint
   justifies it, a learned model; evaluate both honestly held-out, adopt whichever wins.
2. **Script-context coverage expansion**: implement the OCR-dialogue fallback (already scoped as
   that flow's deferred Open Design Question) to reach all 16 training-relevant episodes at minimum;
   extend further to any additional episode/page this flow brings into coverage under criteria 3-4,
   with honest per-source provenance preserved (hand-verified vs. OCR-derived vs. other).
3. **Re-attempt matching on the 99 unmatched page-rows**: re-run/improve `sdd-comics-ai-multimodal`'s
   alignment (lower confidence threshold with disclosed false-positive risk, and/or additional
   matching signal such as expanded OCR vocabulary) against the 27 known episodes first — report how
   many of the 99 are recoverable this way, honestly, before assuming the rest need new episode
   identity.
4. **New episode identity for genuinely unmatched content**: for page-rows that remain unmatched
   after criterion 3, design (and pilot on a real subset, not all 99 at once) a method for defining
   new episode boundaries/identity — this is the highest-risk, most exploratory Must-Have here;
   Specifications must size it as real, uncertain work, not assumed straightforward.
5. **Full pipeline run on newly-covered content**: for any page-row that clears criteria 3 or 4,
   run cutting → positioning → balloon-matching → transformation-generation end to end and report
   real completeness per page, not just per stage in isolation.

### Should Have

- A held-out evaluation stratified so episodes with rich multi-keyframe animation and episodes with
  simple 1-2-keyframe layers are both represented, not accidentally segregated by the random split.

### Won't Have (This Iteration)

- **Sound/audio animation (`SoundAnim`)** — conceptually distinct (audio-trigger gating vs. a
  visual transform); left for a future pass unless Anton says otherwise (see Open Questions).
- **Physical re-photographing** of book pages beyond the existing 80 — out of this flow's control.
- **Rebuilding cutting, positioning, or balloon-matching from scratch** — all three are reused as
  completed capabilities; this flow extends their *application* to more content, not their own
  design.

## Constraints

- **Data volume for transformation generation itself**: only 27 real files / 16 episodes with real
  matched training signal today — same small-data risk class as `sdd-comics-ai-positioning`; a real
  baseline is the floor.
- **Technical**: transformation output must be expressible as real `Anim` subclass fields — no new
  schema invented.
- **Editorial reality**: new-episode-identity work (criterion 4) is not a purely technical problem —
  naming/scoping a new "episode" has historically been a human/editorial decision (the 27 existing
  ones were chosen and named by people, not inferred). This flow can propose candidates; final
  episode identity may still need human confirmation, disclosed as such rather than fully automated
  away by assumption.
- **Dependencies**: hard dependency on `sdd-comics-ai-positioning` (position stage) and
  `sdd-comics-ai-script-context` (extraction pipeline), both reused/extended, not rebuilt.

## Open Questions

- [ ] Is `SoundAnim` genuinely out of scope, or should audio-trigger generation be included in
      "transformations" too?
- [ ] For criterion 4 (new episode identity), how much human-in-the-loop confirmation is acceptable
      per newly-proposed episode — fully automated, or a "нарезатор"-reviewed proposal (mirroring
      `sdd-comics-ai-multimodal`'s own cutting-review pattern)?
- [ ] What confidence-threshold change is safe to try for criterion 3's re-matching attempt, given
      the existing threshold was itself calibrated against real false-positive risk in
      `sdd-comics-ai-multimodal`?
- [ ] Held-out protocol for transformation generation — same file-wise split as positioning, or
      stratified by animation complexity (see Should Have)?

## References

- `flows/sdd-comics-ai-positioning/` — COMPLETE; position stage this flow depends on
- `flows/sdd-comics-ai-script-context/` — COMPLETE; extraction pipeline this flow extends
- `flows/sdd-comics-ai-multimodal/` — COMPLETE; `work/alignment.jsonl` is the source of the real
  37-matched/99-unmatched sizing above; its cutting/matching stages this flow re-applies to new
  content under criteria 3-4
- `flows/sdd-comics-editor-fromat-dot-comics/` — consolidated `.comics` format reference, including
  the `Anim`/`AnimType` model this flow's output must conform to
- `dataset/boranko/mahabharata/book1/comics_book_lowcamera/` — 80 real photographed pages
- `apps/comics-ai/comics-multimodal/work/alignment.jsonl` — real per-page match/skip status

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes:
