# Requirements: comics-ai-bhagavadgita-from-lottie

> Version: 1.1
> Status: APPROVED
> Last Updated: 2026-08-09

## Origin

Originally drafted as an addition (v0.2-v0.3) to `flows/comics-ai/sdd-comics-ai-bhagavadgita-generator`
— Anton: "В отрисованной вручную художниками серии комикса Бхагавад Гита
`dataset/bhagavadgita/vaishnav/bhagavadgita_lottie/unzip/1` присутствовала глубина z-depth и камера
перемещалась не с постоянной скоростью строго сверху вниз а по ломанной кривой. Комикс был
экспортирован в формат Lottie. Необходимо найти точный путь перемещения камеры и найти z-dept для
каждого из layers (а не всех на одну глубину) и экспортировать в формат .comics v2026, включая
данные перемещения камеры и глубины z-depth, чтобы восстановить просмотр с эффектом паралакс." — a
hand-drawn artist source has real depth and a non-constant-speed, non-straight camera path; find
both per-layer and export into `.comics` v2026.

**Extracted into this standalone flow per Anton's explicit follow-up instruction (2026-08-09)**:
"Вынеси в отдельный sdd, из прошлого sdd удали" — move it into its own SDD flow, remove it from the
parent flow. This document, `02-specifications.md`, and `03-plan.md` are moved verbatim (renumbered
from that flow's Must-Haves 11-14/Phase 10, not re-derived) from the parent flow's own v0.3
Requirements / v0.4 Specifications / v0.3 Plan, which were already reviewed and approved there
("reqs,specs and plan approved", 2026-08-09) before this extraction. The parent flow's own docs now
carry a pointer here instead of the full content — see that flow's `_status.md`.

**Real, computed output already produced, ahead of formal Plan execution** (per Anton's direct
"Дай координаты кривой перемещения камеры сейчас" ask, 2026-08-09): the actual reconstructed
`cameraPath` coordinates for all 3 real scenes, computed directly from the algorithm specified below,
are recorded in `04-implementation-log.md` — real numbers, not illustrative placeholders. This flow
starts already partway toward Implementation in substance, even though its own Plan phase/task
checkboxes below start unchecked, matching this repo's practice of not silently back-filling
completed-looking checkboxes for work done outside the formal task sequence.

## Lottie Camera-Path & Per-Layer Z-Depth Source

**A real Lottie source exists in the dataset and had not been audited by
`sdd-comics-ai-bhagavadgita-generator`'s original Dataset Findings** (that audit covered only
CSV/PSD sources): `dataset/bhagavadgita/vaishnav/bhagavadgita_lottie/unzip/1/Mediation of the
Bhagavat Gita_content/Mediation of the Bhagavat Gita.json` (~19MB), plus sibling
`_translations/{en,ru}.json` (caption overlay Lotties) and `_music/BG_items_frames.json` (audio
timing). This is the **only** Lottie file anywhere under `dataset/bhagavadgita/` — there is exactly
one, not one per chapter.

**Open, unresolved**: the file is titled "Mediation of the Bhagavat Gita" and its content does not
obviously correspond to any single one of the 18 numbered Bhagavad Gita chapters (per the parent
flow's own chapter list) — it reads as a distinct, standalone piece (a meditation/framing animation),
not chapter-5 material alongside the existing PSDs. **This flow does not assume a chapter mapping**
— the extraction/export work below targets this file as its own additional `.comics` output, not a
replacement for or component of any of the parent flow's 18 chapter files, unless Anton says
otherwise.

**Direct inspection of the real file** (not assumed from general Lottie/After Effects knowledge):

- `w:720, h:1600` (top-level canvas) — matches this format's own `preferredViewportWidth`/
  `preferredViewportHeight` default (720×1600) decided the same day in
  `flows/tdd-dot-comics-format/01-requirements.md`, independent confirmation the two numbers weren't
  arbitrary.
- `ddd: 0` — **not** a true 3D composition. There is **no explicit camera layer** anywhere in the
  file (Lottie/Bodymovin's real camera layer type, `ty:13`, appears zero times; no layer name
  contains "cam"/"depth"/"parallax" either). **There is no single monolithic "camera" object to
  extract** — this corrects the command's own framing ("найти точный путь перемещения камеры")
  before it becomes a Specifications assumption: what's real is per-layer motion, described next.
- 3 top-level layers (`0_1`/`0_2`/`0_3`, each a precomp reference into `comp_2`/`comp_1`/`comp_0`
  respectively — likely 3 scenes within the one piece). **Each has exactly 2 position keyframes** —
  a simple, near-linear vertical pan per scene, real extracted values:

  | Scene | Frame range | Y start → end | X drift |
  |---|---|---|---|
  | `0_1`/`comp_2` | −171 → 5007 | 6480 → −6481 | 360 → 359.881 (negligible) |
  | `0_2`/`comp_1` | 2955 → 7662 | 5881.424 → −5884.696 | 360.242 → 360.284 (negligible) |
  | `0_3`/`comp_0` | 6252 → 12168 | 7400.5 → −7403.425 | 360 → 360.275 (negligible) |

  This top-level pan alone is constant-speed and purely vertical — it is **not** the "broken curve"
  Anton described. That comes from individual layers, next.
- Within each scene's precomp, most individual layers are **static** (no position animation at
  all) — real counts: `comp_0` 187 layers, 131 static / 56 animated; `comp_1` 175 layers, 152 static
  / 23 animated; `comp_2` 158 layers, 117 static / 41 animated (roughly 13–30% animated per scene,
  not 100%).
- The animated minority have their own **independent, multi-keyframe (2–6 point) local paths with
  irregular frame spacing** — a real, concrete, non-constant-speed polyline, confirmed on a specific
  layer (`comp_0`, `ind=43`, name `"177"`): position keyframes at frames 539, 851, 994, 1111, 1202,
  1377 (deltas 312, 143, 117, 91, 175 — irregular, i.e. non-constant speed), with **X not
  monotonic** (592.164 → 436.12 → 417.329 → 450.989 → 201.029 → 181.595) while **Y is monotonic**
  (3231.145 → 3449.613 → 3631.284 → 3945.418 → 4178.471 → 4566.756) — a real 2D wander, not a
  straight vertical line. The **same layer's scale animates too**, overlapping in time: 78% (frame
  539) → 83.565% (851) → 111.95% (1202) — a real ~1.44× growth, the classic 2.5D "object approaches
  camera" depth cue riding alongside its XY motion.

**What this means for extraction, stated plainly, and confirmed/refined by Anton directly
(2026-08-09, two messages)**: "Все относительно. С учетом того, что экспорт в .lottie был сделан
верно, то строго математически камера двигается сверху вниз без кривой (и данные по камере
отсутствуют), но человеческий глаз видит по-другому: если человеческий глаз смотрит относительно
некоторых layers, то другие layers движутся относительно этих layers, которые кажутся статичными." —
it's relative: assuming the Lottie export itself is correct, the "camera" (the top-level pan) really
does move top-to-bottom without a curve, strictly mathematically — there is no camera data because
there is no camera, matching this section's own direct finding (`ddd:0`, no `ty:13` layer). The
perceived **non-constant-speed, broken curve** is a real but purely perceptual/relative effect: the
human eye anchors on whichever layer it's currently tracking, and every *other* layer's own local
motion (relative to that anchor) is what reads as "the camera swerving."

**Immediate follow-up, refining the design rather than just confirming it**: "...moving against the
shared linear pan, и именно эту ломанную кривую необходимо восстановить и сохранить в отдельный
элемент — движение камеры — в .comics v2026." — it's precisely *that* broken curve (the aggregate,
perceived relative motion, not the boring linear pan) that must be **reconstructed and saved as its
own separate camera-movement element** in `.comics` v2026 — not only distributed implicitly across
per-layer `TranslateAnim` keyframes. Both a per-layer motion/z-depth representation *and* a
reconstructed, explicit, document/scene-level camera-path element are required — see Must-Have 4
below and `02-specifications.md`'s design (a genuine new `.comics` v2026 schema concept, analogous to
how `Layer.ZDepth` itself was added, but at the document/scene level rather than per-layer).

`.comics`' existing per-layer `TranslateAnim`/`ScaleAnim` keyframe system (already implemented,
already scroll-driven, per `flows/tdd-dot-comics-format`'s "Layer & animation model") is **still the
right target shape for each layer's own residual/local motion** — real per-layer keyframes with
irregular timing map onto it directly, no schema change needed there. **Two things are genuinely
new**: (1) **z-depth** — `Layer.ZDepth` is a real field in `flows/tdd-dot-comics-format/
01-requirements.md`/`03-specifications.md` (added the same week, 2026-08-08) but **is not yet
implemented** in `apps/comics-editor`'s real model (`libs/flutter_comics/lib/src/models.dart` has no
`zDepth` field today) or rendered as parallax by any current `.comics` viewer; (2) **a reconstructed
camera-path element** — a genuinely new document/scene-level schema concept with **no existing
counterpart anywhere in `.comics`**, unlike z-depth which at least already has a Requirements/
Specifications home in `tdd-dot-comics-format`. Writing both is valid and additive/backward-compatible
by the same established pattern this format has used for every prior forward-looking field, but
**must not be presented as visually working today** — no current reader composites a document-level
camera path against per-layer z-depth into an actual parallax rendering; see the new Must-Have 4
below and that flow's own Open Design Questions (sign convention, scroll-response formula still
undecided) — now joined by this addition's own new open questions about exactly how a camera-path
element and `Layer.ZDepth` compose at render time.

## Problem Statement

The Bhagavad Gita dataset contains one real, hand-animated Lottie piece with genuine per-layer depth
and motion cues that no current tooling extracts or preserves — today it exists only as a Lottie
JSON, unusable by any `.comics` viewer/editor. This flow exists to extract that real signal (camera
path, per-layer z-depth, per-layer motion) faithfully and export it as a `.comics` v2026 document,
without inventing data the source doesn't actually contain.

## User Stories

**As** Anton, validating fidelity, **I want** every extracted value (camera path, z-depth, per-layer
keyframes) traced to a specific real number in the source Lottie file, not invented or approximated
without disclosure, **so that** the exported `.comics` document is provably faithful to what the
artists actually made, not a plausible guess.

**As** a future `.comics` renderer implementer, **I want** the reconstructed camera path and
per-layer z-depth values available as real, inspectable data in a real file, **so that** implementing
actual parallax rendering later has real ground-truth data to render, not just a schema proposal.

## Acceptance Criteria

### Must Have

1. **Real per-layer motion preserved**: every layer that has real Lottie position and/or scale
   keyframes is exported with that same keyframe structure (irregular timing preserved, not
   resampled to constant speed and not flattened to one static placement) — the concrete, testable
   proof being that a layer with N real Lottie position keyframes produces an `Anim` list with N
   real `TranslateAnim` keyframes at the corresponding scroll positions, not 1.
2. **Non-uniform per-layer z-depth**: every layer in the document gets its own individually-derived
   `zDepth` value via a disclosed, reproducible formula (see `02-specifications.md`) grounded in
   that layer's own real Lottie signals — **not** one constant value applied to every layer. The
   concrete, testable proof: at least two layers in the real output have measurably different
   `zDepth` values.
3. **Disclosed limitation, not oversold**: the manifest/report for this document states plainly that
   `zDepth` values are written per `flows/tdd-dot-comics-format`'s additive schema design (safe,
   round-trippable, ignorable by old readers) but **are not yet rendered as a visible parallax
   effect by any current `.comics` editor/viewer** — this flow does not claim to have "restored" the
   visual parallax effect end-to-end, only to have extracted and exported the real data needed for a
   future renderer to do so.
4. **Reconstructed camera path as its own element**: the aggregate, perceived "broken curve" (not
   the trivial linear top-level pan) is reconstructed from the real per-layer relative-motion
   signals and written as a distinct camera-movement element in the exported `.comics` v2026
   document — a real, separate, inspectable data structure, not solely implicit in the sum of
   individual layers' own `TranslateAnim` keyframes. The concrete, testable proof: the output
   document has an identifiable camera-path field/structure whose own keyframe values are NOT
   identical to the trivial 2-keyframe linear pan found directly in the Lottie source (the table
   above) — i.e. it demonstrably captures the reconstructed curve, not just a copy of the boring
   input.

### Should Have

- Reuse `flows/comics-editor/tdd-dot-lottie-import-export`'s own real, tested Lottie-parsing
  precedent (`libs/flutter_comics/lib/src/lottie/lottie_mapping.dart`) as a cross-check where
  applicable, rather than re-deriving Lottie-parsing logic independently from scratch.

### Won't Have (This Iteration)

- Claiming `Mediation of the Bhagavat Gita.json` maps to any specific one of
  `sdd-comics-ai-bhagavadgita-generator`'s 18 numbered chapters — that mapping is unconfirmed (see
  the Lottie section above) and not assumed here.
- Implementing the real parallax rendering (the actual scroll-response math that makes a `zDepth`
  value visually do anything) — that's `flows/tdd-dot-comics-format`'s / a future viewer flow's
  scope, not this one's. This flow only extracts and writes the data.
- Installing third-party Lottie rendering packages (`python-lottie`, `lottie-web`, etc.) for any
  verification purpose — per Anton's explicit constraint (2026-08-09): verification instead reuses
  `flows/comics-editor/tdd-dot-lottie-import-export`'s own findings and `libs/flutter_comics`'s
  existing, tested Lottie parser.

## Constraints

- **Input**: `dataset/bhagavadgita/vaishnav/bhagavadgita_lottie/`, read-only — same rule as the rest
  of `dataset/`, never created, modified, renamed, or deleted by this flow.
- **Output cardinality**: exactly one additional `.comics` document (or possibly 3, if the
  1-file-vs-3-scenes Open Question below resolves that way) — never counted toward or presented as
  one of `sdd-comics-ai-bhagavadgita-generator`'s 18 chapters.
- **Compatibility, narrow disclosed exception**: `Layer.ZDepth` and the new `cameraPath` element are
  written even though not yet implemented by any real reader — permitted because `Layer.ZDepth`'s
  own design in `flows/tdd-dot-comics-format` is additive/ignorable-by-old-readers by construction
  (the same property every other forward-looking field in this format has had before its own
  implementation), and because Must-Have 3 requires disclosing this plainly rather than silently
  depending on it as if it already worked.
- **No external Lottie tooling**: per Anton's explicit instruction, no `python-lottie`/`lottie-web`/
  similar third-party rendering package may be installed for verification — reuse
  `tdd-dot-lottie-import-export`/`libs/flutter_comics` instead.
- **Dirty worktree**: unrelated existing changes in the repository must be preserved (same standing
  rule as every other flow this session).

## Open Questions

- [ ] Does `Mediation of the Bhagavat Gita.json` belong to one of the 18 Bhagavad Gita chapters (and
      if so, which), or is it genuinely a separate, standalone piece? Not resolved — the translation
      JSONs (`_translations/{en,ru}.json`) weren't read for narrative content to cross-check against
      chapter titles; a real, cheap next step if this matters.
- [x] Exact `zDepth` scale constant — resolved by the approved `tdd-dot-comics-format` v0.11/v0.8
      contract as `K = 1`: `zDepth` is unitless and the inverse relation is
      `motionRatio = 1 / (1 + zDepth)`.
- [ ] Should the 3 scenes (`0_1`/`0_2`/`0_3`) become 3 separate `.comics` files or one combined
      document with 3 internal scroll regions? Not decided — leaning toward one document (matching
      the parent flow's own "one continuous-scroll document" convention) but a real open call.
- [ ] Absolute canvas position compositing formula (see `02-specifications.md`) — a principled guess,
      not verified against ground truth. Verification method revised per Anton's no-external-tooling
      constraint (see `03-plan.md`'s Task 1.1).
- [ ] Camera-reference-layer selection heuristic ("richest single layer") — a concrete default, not
      validated against what the artist actually intended as "the camera."

## References

- `dataset/bhagavadgita/vaishnav/bhagavadgita_lottie/unzip/1/Mediation of the Bhagavat Gita_content/
  Mediation of the Bhagavat Gita.json` — the real Lottie source inspected directly for this flow
- `flows/tdd-dot-comics-format/01-requirements.md`, `03-specifications.md` — `Layer.ZDepth`'s own
  design (default 0, additive), source of the "not yet implemented anywhere" constraint, and the
  canonical adopted home of this flow's `cameraPath` proposal
- `flows/comics-editor/tdd-dot-lottie-import-export/` — the general Lottie↔`.comics` mapping
  precedent (parent chains, precomp handling), and the source of `libs/flutter_comics`'s tested
  Lottie parser this flow's verification work reuses instead of installing new tooling
- `flows/comics-ai/sdd-comics-ai-bhagavadgita-generator/` — the parent flow this work was extracted
  from (2026-08-09); see that flow's own `_status.md` for the disclosed extraction note

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-09 — approved in the parent flow as v0.3 ("reqs,specs and plan approved")
      before extraction; the extraction itself (moving, not re-deriving, the same approved content)
      does not require re-approval.
- [x] Notes: real open engineering questions remain (see Open Questions above), disclosed and
      unaffected by this extraction.

### v1.1 review gate

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-09
- [x] Notes: aligns this producer with the canonical `cameraPath`/`zDepth` contract in
      `tdd-dot-comics-format` v0.11/v0.8; no implementation work is included.
