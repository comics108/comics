# Requirements: dot-bodymovin-format

> Version: 1.0 (forked out of `flows/tdd-dot-comics-format/02-tests.md`'s "Part 0" discovery,
> 2026-08-07, per Anton's explicit request — that discovery was originally mislabeled as
> "sample_v2026.comics" before Anton corrected the naming to `.Bodymovin`)
> Status: DRAFT
> Last Updated: 2026-08-07

## Origin

While comparing `.comics` v2012 vs. what was then called "v2026" for `tdd-dot-comics-format`, the
file at that time named `samples/sample_v2026.comics` turned out to unzip to `ASHES_content/
ASHES.json` + `ASHES_music/*.aac` + `ASHES_translations/ASHES_{bn,en,hi,ru,uk}.json` — and
`ASHES.json`'s content is genuine **Bodymovin/Bodymovin JSON** (Adobe After Effects' animation export
format), not an extension of the classic `.comics`/`Comics.Editor.Models` schema at all. Anton
confirmed this was a real, distinct format — not a mislabeled `.comics` file — and renamed the
fixtures accordingly: `samples/sample_v2026.comics`/`_unzip` → `samples/sample.Bodymovin`/
`sample.Bodymovin_unzip`; `dataset/mahabharata/boranko/mahabharata-dot-comics_v2026` →
`dataset/mahabharata/boranko/mahabharata-dot-bodymovin`. This flow is that discovery, extracted into
its own dedicated place, with paths re-verified against the corrected names (see References).

**Why a separate flow, not a section of `tdd-dot-comics-format`**: Bodymovin is not a version of
`.comics` — it's an unrelated container/animation format, produced by a different pipeline
(After Effects → Bodymovin export), with its own schema, its own asset model, and (per this
research) no confirmed reader anywhere in this repo yet. Keeping it inside the `.comics`-format
flow would have blurred two genuinely separate compatibility stories: "is `.comics` backward
compatible across its own versions" (yes — see `tdd-dot-comics-format`, re-confirmed clean of this
Bodymovin confusion) vs. "what is this new Bodymovin content, and how does it eventually get played."

## Problem Statement

Real, produced 2026 content exists in a format (Bodymovin/Bodymovin JSON) that nothing in this repo
currently reads. Before any compatibility test cases can be meaningfully written for it, the basic
questions of *what this format actually is*, *how much real content already exists in it*, and
*whether a player is planned/in-progress anywhere* need answers — right now those are genuinely
unknown, not just untested.

## Verified Facts (real, cited — not inferred)

1. **Container shape**: `sample.Bodymovin` (a zip) unzips to `ASHES_content/ASHES.json` (5.2MB),
   `ASHES_music/*.aac` (32 named SFX/music files), `ASHES_translations/ASHES_{bn,en,hi,ru,uk}.json`
   (5 languages — bn/en/hi/ru/uk), and a `S1_B1_C1_cover.jpg`. No `data.json`, no `layers/`, no
   `sounds/` — the classic `.comics` container shape is entirely absent.
2. **`ASHES.json` is genuine Bodymovin/Bodymovin JSON**: top-level keys `v, fr, ip, op, w, h, nm, ddd,
   assets, layers, markers, props` — the standard Bodymovin schema, `v: "5.12.2"` (real
   Bodymovin/bodymovin version string). `fr: 60` (60fps). Root `w×h: 720×1600` (a portrait
   phone-shaped canvas — different from the classic model's 1080-wide document convention). Root
   `op: 11640` → total composition length ≈194 seconds of **real wall-clock time**, not a
   scroll-pixel value. 103 `assets`. First top-level layer is `ty: 0` (a Bodymovin precomp layer)
   referencing a nested `720×24000` composition with its own `ip`/`op` (`3891`/`13491` frames).
3. **This breaks the "scroll is time" invariant** that `tdd-dot-comics-format` confirmed unchanged
   since 2012 for the classic lineage. Bodymovin addresses keyframes by frame number at a fixed
   framerate — wall-clock time, not scroll position. Whether/how a future player reconciles this
   with scroll-driven reading is unresolved (see Open Questions).
4. **Other real data differences beyond container/compression**: translations moved from inline
   per-layer image-slot indices (3-culture En/Ru/Hi) to separate per-language JSON files, and the
   language set expanded to 5 (added bn, uk). Sound/music went from 1-2 narration `.mp3` files to a
   32-file named SFX/music library in `.aac`. Visual assets referenced through Bodymovin's own
   `assets` array rather than tiled PNGs.
5. **CORRECTED (2026-08-07): Bodymovin is not new to v2026 — it has been present, unused, since
   v2012.** Original research only checked `mahabharata-mobile-swift-v2026`; Anton pointed out
   `legacy/mahabharata-mobile-swift-v2012` needed checking too, and it changes the picture
   significantly:
   - **`legacy/mahabharata-mobile-swift-v2012` has the exact same complete, vendored Objective-C
     Bodymovin rendering engine** as the v2026 copy, byte-for-byte the same file layout
     (`Mahabharata/Library/Bodymovin/Classes/{RenderSystem,Models,AnimatableLayers,Private,
     PublicHeaders}/`, the `LOT*`-prefixed classes — an older Bodymovin version, ~v1.x/2.x
     Objective-C API). **Confirmed unused there too**: zero `LOT*` class references anywhere in
     the app's own code, in either the 2012 or 2026 copy. This engine has apparently been dead,
     copy-forwarded code since 2012 — never removed, never activated, across at least two
     generations of the app.
   - **The one real, functioning Bodymovin usage found is small, unrelated to comics, and uses a
     completely different mechanism**: `Mahabharata/Views/MusicTableViewCell.swift:37-41` (present
     in the v2012 copy; the v2026 copy's equivalent file has the same `import Bodymovin` but wasn't
     re-checked line-by-line) instantiates `AnimationView(name: "equalizer")` — the modern,
     pure-Swift `bodymovin-ios` CocoaPod's API (`Podfile: pod 'bodymovin-ios', '3.1.3'`), **not** the
     vendored `LOT*` Objective-C engine. It plays `Mahabharata/Resources/Animations/
     equalizer.json` — a genuinely tiny Bodymovin file (`w:14, h:14`, a 14×14px icon, ~1.5 second
     loop) that renders a "now playing" equalizer-bars animation next to an active music track in
     a list. **This has nothing to do with comics rendering** — it's a UI micro-animation, using a
     separate install path from the dead vendored engine.
   - **Android had zero Bodymovin presence in either generation**: re-checked
     `legacy/mahabharata-mobile-java-v2012` directly — no `bodymovin`/`Bodymovin`/`airbnb` references
     anywhere in source, and no `com.airbnb.android:bodymovin` (the standard Android Bodymovin library)
     or any equivalent in any `build.gradle`. Combined with the already-established zero-Bodymovin
     finding for `apps/mahabharata-mobile-java-v2026`: **Bodymovin has never been used on Android, in
     any generation, for anything, comics or otherwise.**
   - **Net correction**: this is not "a new v2026 engine, staged but unused." It's "a dead engine
     copy-forwarded since 2012, on iOS only, alongside one small unrelated real usage that's also
     been there since 2012." No confirmed reader for `ASHES.json`-scale comics content exists
     anywhere, in any generation — that conclusion is unchanged, but the *history* behind it is
     now accurately dated to 2012, not misattributed as a 2026 addition.

6. **Episode-set comparison** (`dataset/mahabharata/boranko/mahabharata-dot-bodymovin/unzip/`):
   43 total organizational chapter-slots (`Story 1/Book {1,2,3}`, `Story 2`, `Story 3/Book 1`), but
   only **7 have real, produced Bodymovin content** (verified by an actual `*_content` subfolder, not
   just a cover placeholder): `Story 1/Book 1` chapters 1-3 (redoing the *start* of the same book
   the classic `.comics` pipeline already fully completed), `Story 1/Book 2` chapters 1-3 (new
   content), `Story 1/Book 3` chapter 1. The other 36 slots are "coming soon" cover-image-only
   placeholders. Each produced chapter uses its own content-specific codename (`ASHES_*` for one,
   `RAMA'S CHALLENGE_*` for another, confirmed by direct inspection) — "ASHES" is not a universal
   container name, it's specific to whichever chapter's content that is.

## How was Bodymovin used in legacy v2012 Java (Android)? — it wasn't

Direct answer, not inferred: **Bodymovin was never used in `legacy/mahabharata-mobile-java-v2012` at
all** — no source reference, no Gradle dependency, in any form. This is a genuine, confirmed
cross-platform asymmetry that has existed since 2012: Bodymovin is an iOS-only presence in this
codebase's history (both the dead vendored engine and the one small real equalizer-icon usage),
never touched on Android in any generation checked (2012 or 2026).

## Can `.Bodymovin` and `.comics` be converted via simple mathematical transformations?

Investigated by inspecting real keyframe data in `ASHES.json` directly (not answered from general
Bodymovin knowledge alone). **Short answer: yes, in the `.comics → .Bodymovin` direction, for the model
`.comics` actually supports; only conditionally in the `.Bodymovin → .comics` direction, and only for
content that stays within a specific simple subset — which, encouragingly, is exactly what this
real content actually does.**

**What the real content's structure actually looks like** (verified, not assumed): every asset
layer in `ASHES.json` is Bodymovin layer type `ty:2` (image layer) — **zero** shape layers (`ty:4`),
zero masks, zero text layers, zero solids, across all 101 layers checked (61 in one nested
composition, 40 in another). Every image layer is a plain raster PNG reference (Bodymovin `assets`
entries have `id/w/h/u/p/e` — width, height, path, embedded-flag — the same shape as a tiled PNG
reference). Position/scale keyframes consistently use the exact same bezier handle pair
(`i:{x:0.833,y:0.833}, o:{x:0.167,y:0.167}`) — After Effects' standard "Easy Ease" preset, applied
uniformly, not arbitrary custom curves per keyframe. Opacity/rotation are frequently left static
(no keyframes at all) when unanimated, same as `.comics` layers with no `AlphaAnim`/`RotateAnim`.

**Why this matters**: this is structurally almost the same model as `.comics` — a flat stack of
raster image layers, each with simple affine-transform keyframes (position/scale/rotation/opacity),
just addressed by frame-number-at-fixed-framerate instead of scroll-pixel-position, and eased by a
fixed AE preset instead of a fixed cubic formula. Concretely:

- **`.comics → .Bodymovin` (the easy direction)**: each `.comics` layer becomes a Bodymovin image layer
  referencing the same PNG; each `Anim` keyframe range (`start`/`end` in scroll-pixels + target
  value) becomes two Bodymovin keyframes (one holding the previous value at frame=`start`, one at the
  target value at frame=`end`), with bezier handles chosen to reproduce `.comics`'s cubic ease-out
  `(t-1)^3+1` as closely as a single cubic bezier segment can (an exact algebraic match isn't
  guaranteed for every case, but a very close approximation is a solved, mechanical problem, not a
  design one). Scroll-pixel values become frame numbers under a chosen scale constant (e.g. "1
  scroll-pixel = 1 frame," or any other fixed ratio — an arbitrary but simple choice, not derived
  from the data). This direction is genuinely simple, mechanical math plus a vocabulary translation.
- **`.Bodymovin → .comics` (the hard direction, conditionally simple)**: simple and mechanical **only
  if** the source Bodymovin file stays within the same subset this real content happens to use (image
  layers only, no shapes/masks/gradients/text/precomp-of-precomp beyond a flat stack, and either
  the same fixed easing preset or a willingness to approximate any bezier curve with `.comics`'s
  one fixed cubic). Under those conditions: each image layer maps back to a `.comics` layer 1:1,
  keyframes map back with frame-numbers rescaled to scroll-pixels (inverse of the same constant),
  and Easy-Ease keyframes map back to `.comics`'s cubic ease-out with a small, bounded
  approximation error (not exact, since Easy Ease and `(t-1)^3+1` aren't the identical curve, just
  the same "smooth ease" family). **Outside that subset, it stops being simple**: any real shape
  layer, mask, gradient, trim path, or text layer has no `.comics` equivalent at all and would need
  lossy rasterization (baking a vector layer down to a PNG per relevant keyframe) — a real content
  decision with real quality/asset-count tradeoffs, not a formula.
- **CORRECTED (2026-08-07): checked, and the answer is no, this does NOT generalize.** Direct
  inspection of all 7 real produced chapters found: vector masks in 1/7 (`THE CHASE`, 6 masked
  layers), null/organizational layers (`ty:3`) in 1/7 (`SVAYAMWARA`), solid color layers (`ty:1`)
  in 1/7 (`THE BROKEN TUSK`), and — the most consequential finding — **layer parenting (`parent`
  field, one layer's transform relative to another's) in 5 of 7 files, up to 64% of all layers in
  `THE BROKEN TUSK` (190/295)**. `.comics` has zero parent-relative transform concept — every
  `Anim` is an absolute value. **The "conditionally simple" framing above was only ever validated
  against `ASHES.json`; for most real chapters, `.Bodymovin → .comics` conversion additionally
  requires resolving arbitrary parent chains into baked absolute keyframes, a real, larger task
  than "flat image-layer mapping."** See `flows/tdd-dot-comics-format/01-requirements.md`'s
  animation-inventory section for the full per-file table, and
  `flows/comics-editor/tdd-dot-bodymovin-import-export` for the direct consequence to that flow's
  Precomp Handling design (needs to generalize from "precomp-children only" to "any parented
  layer").

## User Stories

### Primary

**As** a future engineer tasked with building a Bodymovin-based comics viewer
**I want** the real Bodymovin content's schema, asset model, and current production state documented
accurately
**So that** the player gets built against real, verified facts instead of re-discovering them, and
doesn't accidentally assume the classic `.comics` scroll-driven model applies unchanged

### Secondary

**As** Anton, deciding whether Bodymovin is the committed v2026 direction
**I want** a clear inventory of what exists (7 real episodes, one vendored-but-unused iOS engine)
**So that** the decision is made with full information, not partial visibility

## Acceptance Criteria

### Must Have

1. **Given** this document, **when** a future flow needs to know what the Bodymovin content actually
   contains, **then** it finds verified facts here, cited to real files, not re-derived from
   scratch.
2. **Given** the corrected fixture paths (`samples/sample.Bodymovin`, `dataset/mahabharata/boranko/
   mahabharata-dot-bodymovin`), **when** any fact in this document is checked against them, **then**
   it matches — this document must stay accurate to the renamed locations, not the original
   (mislabeled) `sample_v2026.comics` paths from before the correction.

### Should Have

- A recommendation on what "cases-first" analysis should even cover here, given no player exists
  yet to test against — likely schema-validation cases (does a given `.json` parse as valid
  Bodymovin, do the expected asset/translation files exist alongside it) rather than
  rendering-behavior cases, until a player is built.

### Won't Have (This Iteration)

- No attempt to build or spec a Bodymovin player — that's real, substantial future work contingent on
  Open Question 1 being answered.
- No claim about whether `mahabharata-mobile-swift-v2026`'s vendored Bodymovin engine is "supposed to"
  be wired up somewhere — that's Anton's call, flagged as a question, not assumed either way.

## Constraints

- **This document must stay a faithful, corrected record.** It was born from a naming mistake
  (Bodymovin content mislabeled as "v2026 `.comics`") — any future correction to these facts must be
  applied here explicitly, not left stale, matching the discipline already established in
  `tdd-dot-comics-format`.

## Open Questions

- [ ] Is this Bodymovin pipeline a real, committed v2026 direction, or exploratory/vendor-delivered
      content ahead of any decision? This flow can only report what exists — not decide intent.
- [ ] If Bodymovin is the real direction, how does frame/time-based addressing (`ip`/`op` at a fixed
      `fr`) reconcile with "scroll position is time," the model every classic-lineage
      implementation shares? Does a future player map scroll onto Bodymovin's frame-seek API, or does
      reading move to an autoplay/wall-clock model for this content specifically? **Partially
      informed (2026-08-07)** by `flows/tdd-dot-comics-format`'s new decision that `.comics` v2026
      gains an independent, optional time-basis dimension alongside scroll — a real precedent for
      "scroll and time as two separate inputs" now exists on the `.comics` side, though it doesn't
      by itself answer how a Bodymovin-native frame timeline maps onto either dimension.
- [ ] Where is `mahabharata-mobile-swift-v2026`'s vendored Bodymovin engine meant to be wired in? Is
      integration in progress elsewhere (a branch, a different checkout), or genuinely not started?
- [ ] Should the 5-language translation set (bn/en/hi/ru/uk) become the new standard for the
      classic `.comics` format too, or is it specific to this Bodymovin content?
- [ ] **(new, 2026-08-07)** Why has the vendored `LOT*` Objective-C Bodymovin engine been
      copy-forwarded, unused, from 2012 through 2026 in the Swift app? Worth asking whoever
      maintains that app's history — was it ever active further back than this repo's visible
      history, planned for a feature that got cut, or just never cleaned up?
- [ ] **(new, 2026-08-07)** Do the other 6 real produced chapters (only `ASHES.json` was inspected
      closely) also stay within the image-layer-only, Easy-Ease-only subset that makes conversion
      simple? Needs checking before assuming the conversion-feasibility conclusion generalizes.
- [ ] **(new, 2026-08-07)** If `.comics → .Bodymovin` conversion is ever wanted for real (e.g. to
      preview classic content in a Bodymovin-based viewer, or vice versa), who would own building it,
      and is the scroll-pixel-to-frame-number ratio a fixed constant or configurable per document?

## References

- `samples/sample.Bodymovin`, `samples/sample.Bodymovin_unzip` — the reference sample, corrected paths
- `dataset/mahabharata/boranko/mahabharata-dot-bodymovin/unzip/` — the full real episode set
- `flows/tdd-dot-comics-format/02-tests.md` (prior "Part 0", now removed there and superseded by
  this flow) — origin of this investigation
- `apps/mahabharata-mobile-swift-v2026/Mahabharata/Library/Bodymovin/`,
  `legacy/mahabharata-mobile-swift-v2012/Mahabharata/Library/Bodymovin/` — the vendored, unused Bodymovin
  engine, confirmed present and equally unused in both generations
- `libs/comics_viewer/comics-viewer-ios/Mahabharata/Views/MusicTableViewCell.swift:10`,
  `legacy/mahabharata-mobile-swift-v2012/Mahabharata/Views/MusicTableViewCell.swift:37-41`,
  `legacy/mahabharata-mobile-swift-v2012/Mahabharata/Resources/Animations/equalizer.json` — the one
  real, functioning Bodymovin usage found (a 14×14px "now playing" icon), confirmed present since 2012
- `legacy/mahabharata-mobile-java-v2012` — confirmed zero Bodymovin presence (source or Gradle),
  matching the already-established zero-Bodymovin finding for `apps/mahabharata-mobile-java-v2026`
- `samples/sample.Bodymovin_unzip/ASHES_content/ASHES.json` — direct inspection of `assets`/`layers`
  structure for the conversion-feasibility analysis (all `ty:2` image layers, uniform Easy-Ease
  bezier handles, zero shapes/masks/text)

---

## Approval

- [ ] Reviewed by:
- [ ] Approved on:
- [ ] Notes:
