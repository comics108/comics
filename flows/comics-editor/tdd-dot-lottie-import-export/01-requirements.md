# Requirements: dot-lottie-import-export

> Version: 0.3 (2026-08-08: NEW addition to already-approved v0.2 — two export/import modes, Full
> Canvas vs. Playback Viewport, per Anton's direct specification. A disclosed re-opening of
> approved content, not a silent rewrite — see the new section below and the revised Approval.)
> Status: APPROVED (v0.2 baseline; v0.3 addition approved 2026-08-08 via `03-specifications.md`'s
> approval, which derives from and confirms it)
> Last Updated: 2026-08-08

## Origin

`flows/tdd-dot-lottie-format` investigated real Lottie content (`samples/sample.lottie`,
`dataset/mahabharata/boranko/mahabharata-dot-lottie`) and concluded, from direct inspection of real
keyframe data: `.comics → .lottie` conversion is mechanically simple for the model `.comics`
actually supports (flat image layers, position/rotation/scale/alpha keyframes); `.lottie → .comics`
is simple *conditionally* — only for Lottie content that stays within the same subset (image
layers only, no shapes/masks/gradients/text, uniform or approximable easing). That flow found no
existing reader/writer for Lottie anywhere in this repo. This flow is the real feature build: add
that import/export capability to `apps/comics-editor` specifically.

## Problem Statement

`apps/comics-editor` can only open/save `.comics`/`.puzzle` files. Real Lottie content already
exists (produced by an external pipeline, per `tdd-dot-lottie-format`'s episode-set findings — 7
real chapters) with no tool anywhere in this repo that can bring it into the editor, and no way to
export an existing `.comics` document as Lottie for use in a Lottie-based viewer (should one ever
get built — `tdd-dot-lottie-format` found a vendored-but-unused Lottie engine in
`apps/mahabharata-mobile-swift-v2026`/`legacy/mahabharata-mobile-swift-v2012`, but no working
reader). This flow closes that gap for the editor specifically — not for any mobile viewer.

## What's already known (from `tdd-dot-lottie-format` — not re-derived here)

- Real Lottie top-level keys: `v, fr, ip, op, w, h, nm, ddd, assets, layers, markers, props`.
  `fr` = framerate (60fps observed). `ip`/`op` = in/out point, in **frames**, not scroll-pixels.
- Real content structure (verified for `ASHES.json`, not yet confirmed for the other 6 real
  chapters — `tdd-dot-lottie-format`'s own open question): every layer is Lottie type `ty:2`
  (image layer) referencing a raster asset (`assets[]` entries: `id/w/h/u/p/e` — width, height,
  path, embedded flag). Zero shape (`ty:4`)/mask/text layers found in the one file inspected.
- Real keyframe shape: `{i: {x,y}, o: {x,y}, t: <frame>, s: [<value>, ...]}` for each animated
  property (`p`=position [x,y,z], `r`=rotation scalar degrees, `s`=scale [x%,y%,z%], `o`=opacity
  0-100). `i`/`o` are bezier ease handles — real content sampled uses After Effects' standard
  "Easy Ease" (`i:{x:0.833,y:0.833}, o:{x:0.167,y:0.167}`) uniformly, not arbitrary per-keyframe
  curves, in the one file checked.
- `.comics`'s own model (`apps/comics-editor/lib/src/ui/models.dart`): `Anim{type, start, end, x,
  y, angle, pivotX, pivotY, scaleX, scaleY, alpha}` — `start`/`end` in raw scroll-pixels (not
  frames), interpolated via a **fixed** cubic ease-out `(t-1)^3+1` (`KeyframeInterpolator`,
  `vdd-comics-editor-vertical-scroll`), not arbitrary bezier curves.
- Real precomps nest (a precomp layer's own `ip`/`op` can exceed its parent's — confirmed on real
  data, not yet confirmed whether this is normal Lottie semantics or an authoring quirk —
  `tdd-dot-lottie-format` Test Case L4, unresolved).

## User Stories

### Primary

**As** Anton (or a future editor user)
**I want** to open a real `.lottie` file in `apps/comics-editor` and have its image layers and
their position/rotation/scale/alpha keyframes become real, editable `EditorLayer`s
**So that** existing Lottie-produced content can be brought into the same authoring/review
workflow as classic `.comics` content, without hand-porting

### Secondary

**As** Anton, preparing content for a future Lottie-based viewer
**I want** to export a `.comics` document as a `.lottie` file
**So that** the same authored content can be previewed/used somewhere that expects Lottie, without
a separate export tool

## Acceptance Criteria

### Must Have

1. **Given** a real `.lottie` file whose layers are all Lottie image type (`ty:2`) with no shape/
   mask/text layers, **when** imported into `apps/comics-editor`, **then** each Lottie image layer
   becomes one `EditorLayer`, each animated transform property becomes the corresponding `Anim`
   type (`p`→translate, `r`→rotate, `s`→scale, `o`→alpha), and the imported document opens/renders
   correctly in the existing canvas.
2. **Given** a `.comics` document open in the editor, **when** exported as `.lottie`, **then** the
   output is valid Lottie JSON (parses, has the required top-level keys) that a generic Lottie
   viewer could play, with each `EditorLayer` becoming an image layer and each `Anim` becoming an
   equivalent keyframe (see Open Questions for the exact easing-curve mapping).
3. **Given** a `.lottie` file containing any shape/mask/gradient/text layer, **when** imported,
   **then** the import does not silently drop or misrepresent it as something else — it's either
   rejected with a clear message, or flattened/rasterized with an explicit, disclosed
   quality/fidelity tradeoff (see Open Questions — which behavior is chosen is a real decision,
   not assumed here).
4. **(NEW, 2026-08-08) Given** any import or export operation, **when** initiated, **then** the
   user's chosen mode (Full Canvas or Playback Viewport — see the new Export/Import Modes section)
   is explicit, never silently assumed, and each mode's own math is applied consistently: Full
   Canvas uses identity time-basis with no separate scroll-speed dialog; Playback Viewport requires
   a real constant-scroll-speed value and composes scroll-basis + time-basis `Anim`s per layer.

### Should Have

- Round-trip fidelity for the supported subset: import a `.lottie`, export it back out, and the
  result is behaviorally equivalent (same layer positions/keyframe timing within a reasonable
  tolerance) to the original — not necessarily byte-identical, given the easing-curve
  approximation `tdd-dot-lottie-format` already flagged as inherently lossy in one direction.

### Won't Have (This Iteration)

- No support for Lottie shape layers, masks, gradients, text layers, or precomp-of-precomp nesting
  beyond a flat image-layer stack — explicitly out of scope, per `tdd-dot-lottie-format`'s own
  finding that this breaks the "simple math" premise entirely.
- No changes to any mobile viewer (Android or iOS) — this is editor-only, matching this flow's own
  name/scope (`apps/comics-editor`).
- No sound/music import or export — Lottie's real content packages audio as a separate
  `<codename>_music/*.aac` folder outside the JSON entirely (`tdd-dot-lottie-format` Verified Fact
  1), not as Lottie keyframe data; reconciling that with `.comics`'s `Sound`/`SoundAnim` model is a
  separate, unscoped problem.
- No translation/multi-language import or export — same reasoning; Lottie's translations live in
  separate `_translations/*.json` files outside the animation JSON, a different mechanism from
  `.comics`'s inline `Layer.Translations`.

## Constraints

- **Technical**: must reuse the existing `KeyframeInterpolator`/`Anim` model
  (`vdd-comics-editor-vertical-scroll`) rather than inventing a parallel animation representation —
  Lottie import should produce ordinary `Anim`s that the existing canvas/interpolation code already
  knows how to render, not a special Lottie-only code path.
- **Fidelity**: the easing-curve mismatch (Lottie's per-keyframe arbitrary bezier vs. `.comics`'s
  one fixed cubic ease-out) is a genuine, disclosed lossy step in the `.lottie → .comics` direction
  whenever the source curve isn't already a close match — not something to hide or claim is exact.
- **Dependencies**: builds on `flows/tdd-dot-lottie-format`'s findings directly; if that flow's own
  open question (do the other 6 real chapters share `ASHES.json`'s simple structure) resolves
  negatively, this flow's Must-Have scope may need revisiting.

## Export/Import Modes — Full Canvas vs. Playback Viewport (NEW, 2026-08-08, Anton's direct spec)

Both directions of this flow now come in **two distinct modes**, chosen explicitly (not inferred),
because real Lottie content genuinely uses both shapes and they demand different math. Grounded
directly in two real fixtures (checked byte-level, not assumed from the description):

- `samples/sample_v2012.comics_unzip` — real classic `.comics`: **1080×41500** canvas (a genuinely
  tall page, not a viewport), 133 layers whose Y-keyframes span the *entire* height (538 to 40431)
  — this is what "Full Canvas" mode's assumptions describe exactly, using content this flow already
  had on hand.
- `samples/sample_playback_viewport.lottie_unzip` (`ASHES_content/ASHES.json`, a **different, real**
  file from `samples/sample.lottie` — confirmed by content hash, not a renamed duplicate) — a
  **720×1600** composition (phone-viewport-sized, not a tall canvas) with exactly **2 root-level
  precomp layers** ("All Objects1": frames 0-5220, "All Objects2": frames 3891-13491, deliberately
  overlapping — a crossfade handoff, not a hard cut), **each with one position keyframe pair**
  sweeping roughly ±12000/±6500px (e.g. `[360, 12000, 0] → [360, -11998, 0]`) — i.e. each scene's
  own tall content is dragged bodily past the fixed 1600px-tall viewport, top to bottom, over its
  frame span. Inside each scene's own precomp (`comp_0`/`comp_1`), individual image layers sit at
  their own large, spread-out Y positions (checked: comp_0's children span roughly Y=3250 to
  Y=19444 — an internal "tall canvas" of their own) *and* many of them carry their own small,
  local `p`-keyframe wiggles (tens to low hundreds of px) distinct from the big sweep — real
  candidates for independent decorative motion, not the scroll sweep itself.

### Full Canvas mode

- **Export**: the whole tall canvas is exported as one Lottie composition sized to the canvas
  itself (not a viewport). Animation is **timeline-based** — Lottie's frame axis and `.comics`'s
  scroll-pixel axis are the same axis, mapped 1:1 (this is exactly the existing "identity" time-base
  choice from the Open Questions below, now scoped specifically to this mode rather than being a
  generic global choice).
- **Import**: the inverse assumption — a Lottie file imported in this mode is assumed to already be
  one tall composition with scenes placed at fixed, non-moving absolute positions one after another
  (exactly `sample_v2012.comics_unzip`'s real shape, just expressed as Lottie instead of `.comics`).
  No root-level "scene sweeps past a viewport" precomp structure is expected or looked for.
- This mode requires **no new math** — it's what this flow's existing Interfaces/Specifications
  already assumed by default (identity ratio, direct absolute-position mapping). Naming it
  "Full Canvas" makes that assumption an explicit, chosen mode instead of the silent only option.

### Playback Viewport mode

- **Export**: exports the *viewport* (one scene's visible-area window, screen-sized — e.g. 720×1600
  real-world), not the full canvas. Scenes take turns filling that same viewport rectangle,
  replacing each other — in Lottie terms, each scene is its own precomp, dragged past the fixed
  viewport via one root-level position sweep (exactly `ASHES.json`'s real "All Objects1"/"All
  Objects2" structure above) — "они вплывают поочередно в область видимости" (they float into the
  viewport one after another), not an instant cut.
- Scroll is **assumed to move at a constant speed** for the purposes of this conversion — this
  assumption is *why* a single linear position-keyframe pair (start Y, end Y, one duration) can
  stand in for "the user scrolled through this scene," and it's the real, user-facing ratio
  parameter this mode needs (replacing the old generic "identity vs. custom ratio" framing —
  Full Canvas mode never needs this dialog at all, since it has no separate scroll-speed concept;
  Playback Viewport mode always needs it, since Lottie's frame-time has no scroll concept of its
  own to recover without one).
- Per-layer animation is then computed as **scroll-position-based** (the base motion, derived from
  the constant-speed assumption — i.e. today's existing `.comics` model, reused, not reinvented)
  **plus an overlay of time-based animation** (`Anim.basis == time`, per `flows/tdd-dot-comics-
  format`'s Plan Task 5.1-5.5, already implemented in `apps/comics-editor`) for motion that should
  look right regardless of whether the constant-speed assumption is exactly correct — e.g. a
  cloud drifting or a character's idle motion that shouldn't visibly hitch if the assumed scroll
  speed doesn't precisely match how a real user actually scrolls. **This is the real, concrete,
  non-hypothetical motivating case for `Anim.basis` that `tdd-dot-comics-format`'s own Requirements
  described abstractly (the "leg-swing" case) — this flow's real sample fixture is direct evidence
  that scenario already exists in produced content**, not a speculative future need.
- **Import**: the inverse — recovers each scene's Y-extent and the assumed scroll speed from the
  root-level sweep keyframes, converts the swept range into a normal `.comics` scroll-position
  layout (mirroring Full Canvas mode's own absolute-position model *within* one recovered scene),
  and classifies each child layer's own local keyframes as either folded into that scroll-based
  base motion or preserved as a separate time-basis `Anim` overlay — **the exact heuristic for that
  classification is not yet decided** (see Open Questions below; this is a real design question,
  not guessed here).

### Real, concrete round-trip fixtures (per Anton's direct instruction)

- `samples/sample_v2012.comics_unzip` anchors a **Full Canvas** round-trip. **CORRECTED (2026-08-08,
  Anton: "из .lottie в .comics затем в .lottie")**: the round-trip itself must run
  `.lottie → .comics → .lottie`, matching Playback Viewport's own direction below — not
  `.comics → .lottie → .comics` as an earlier draft of this section had it. Since
  `sample_v2012.comics_unzip` is a real `.comics` file, not a `.lottie` one, it's used as one-time
  **fixture prep**: export it to `.lottie` (Full Canvas mode) once to produce a real, trusted
  Full-Canvas-shaped `.lottie` file, then anchor the actual round-trip test on *that* derived file —
  import → re-export → compare, same direction as Playback Viewport, not the reverse.
- `samples/sample_playback_viewport.lottie_unzip` anchors a **Playback Viewport** round-trip: real
  `.lottie` → import (Playback Viewport mode) → export back to `.lottie` → compare, using this real
  file as ground truth for the direction that has real content to start from.

## Open Questions

- [x] **Time-base mapping — DECIDED (2026-08-07, Anton), RESCOPED (2026-08-08)**: **configurable,
      asked of the editor user at import/export time** — not a fixed constant baked into the tool,
      and not silently derived. Originally framed as one generic global choice; **now scoped per
      export/import mode** (see the new Export/Import Modes section above): Full Canvas mode always
      uses identity (1 frame = 1 scroll-unit, no dialog needed — the mode's own definition already
      is "no real scroll concept, timeline-based"); Playback Viewport mode always needs a real
      constant-scroll-speed value from the user (there's no "identity" option there — Lottie's
      frame-time has no scroll axis to be identical *to* without an assumed speed). The original
      "as-is is a real, honest choice" reasoning still holds, it's just now Full Canvas mode's own
      built-in behavior rather than one of several options in a mode-agnostic dialog.
- [x] **Easing-curve mapping precision — DECIDED (2026-08-07, Anton)**: **also asked of the user,
      with real options presented**, not silently chosen by the tool. At minimum: "exact cubic
      ease-out match" (solvable curve-fitting, guarantees round-trip fidelity to `.comics`'s own
      formula) vs. "AE Easy Ease approximation" (matches what real sampled Lottie content already
      uses, better compatibility with hand-authored Lottie files that were never meant to round-trip
      through `.comics` at all). Exact wording/UI for this choice not yet designed — see Q3.
- [x] **Unsupported-content policy — PARTIALLY DECIDED (2026-08-07, Anton)**: text/lettering is
      important enough to get first-class format support, not a reject-or-flatten case. Full
      analysis below (new "Text Region" section) — this doesn't resolve every remaining
      shape/mask/gradient case, but text specifically is no longer "unsupported content," it's a
      real new schema concept.

## Open Questions (Export/Import Modes, new 2026-08-08)

- [ ] **Mode selection UI** — an explicit choice the user makes (matching this flow's own
      established "never silently infer" pattern for the time-base/easing choices), or can it be
      reliably auto-detected from the source file's own shape (a Lottie composition sized like a
      viewport with root-level sweep precomps vs. one sized like a tall canvas with no such
      structure)? Leaning toward auto-detect-with-override (detect, show the user what was detected,
      let them correct it) rather than a cold blank choice, but not decided — ties into the same
      review-screen UI Q3 already established for import; export's mode choice is more clearly a
      simple explicit pick (mirrors the existing Export button pattern), since there's no file to
      detect a shape from yet.
- [ ] **Playback Viewport's scroll/time classification heuristic** — on import, which of a scene's
      own child-layer keyframes get folded into the scroll-based base motion vs. preserved as a
      separate time-basis `Anim` overlay? Not decided. Candidate heuristics (none chosen yet):
      (a) everything defaults to scroll-basis (today's exact existing import behavior, safest,
      zero time-basis anims created unless a human editor adds them afterward -- defers the
      classification problem entirely rather than solving it); (b) a magnitude/duration heuristic
      (large keyframe deltas spanning most of the scene's frame range -> scroll-basis; small,
      short-period, possibly-looping deltas -> time-basis); (c) ask the user per-flagged-layer in
      the review screen, extending Category A's existing flag mechanism to a new flag type rather
      than a hard reject/accept. (a) is the safe default to ship first; (b)/(c) are real
      improvements deferred, not silently abandoned.
- [x] **Is the assumed constant scroll speed a real Lottie-file-derivable value, or always a
      user-provided number? — DECIDED (2026-08-08), grounded in exact computation on real data**:
      **yes, auto-derivable, with an editable override** — never silently applied without being
      shown. Computed precisely from `ASHES.json`'s two real root sweeps: "All Objects1" (frames
      0→5216, Y 6496→-6500) = **2.4916 px/frame = 149.49 px/sec** (at `fr:60`); "All Objects2"
      (frames 3891→13490, Y 12000→-11998) = **2.5001 px/frame = 150.00 px/sec**. These two
      independently-authored scenes land within **0.34% of each other** — real evidence the file
      was authored against one consistent scroll speed, not per-scene-varying ones, and that the
      "assumed constant speed" isn't merely a modeling convenience but something real content
      already closely satisfies. **Design decision**: `ImportPreview.build` computes one detected
      speed per recognized root-sweep scene, shows it pre-filled in the review screen (not asked
      cold), and if multiple scenes agree closely (as here) presents one overall value the user can
      still edit — never blocks on "nothing to derive from" for files with the real sweep shape.
      Files with no such structure (hand-crafted, or a Full Canvas-shaped Lottie opened in the
      wrong mode) have nothing to derive from and fall back to a plain user-entered value, per the
      flow's own "never silently derive without a real signal" philosophy. Supersedes/resolves the
      "not decided" framing this question originally had.

## Text Region — a new `.comics` v2026 schema concept (added 2026-08-07)

### Why this exists

While resolving Q3 (unsupported-content policy), Anton specified that **text/lettering deserves
real format support**, with two requirements that rule out a simple rectangle-only design: (1) the
region can be bounded by an arbitrary **bitmap mask**, not just a rectangle, because the actual
content is **hand-lettering** (hand-drawn artwork), not rendered font text — an irregular balloon
tail or organic lettering stroke doesn't fit a clean rect or even always a clean polygon; (2) text
does **not** have to live inside a balloon at all — free-standing lettering (e.g. a sound-effect
"БУМ!" drawn directly onto a scene, no balloon shape) needs the same capability.

### What the real pipeline (`apps/comics-ai/comics-ai-baloons`) actually does today — investigated directly, not assumed

Confirmed by reading `layout.py`, `erase.py`, `classify.py`, `lettering_features.py`, `package.py`
directly:

- **The balloon interior is reduced to a plain axis-aligned rectangle** (`layout.py`'s
  `find_interior_rect` → `largest_inscribed_rectangle`), even though a real **pixel-precise mask**
  is computed first (`find_safe_interior_mask`, via `cv2.distanceTransform` from the balloon's alpha
  and outline ink) — **that mask is discarded immediately** after deriving the rectangle. Every
  downstream text-fit/render call (`render_latin.py`, `render_shaped.py`) only ever sees `(x, y, w,
  h)`.
- **`erase.py` computes an even more precise mask** — real connected-component glyph shapes
  (`text_mask`, distinguishing actual letter-ink components from the balloon's own outline+tail
  ink) — used to paint over old text pixel-by-pixel. This is genuinely shape-accurate, not a
  rectangle. **It is also discarded** the instant the erase operation finishes; nothing downstream
  ever sees it again.
- **Hand-lettered vs. machine-set classification (`classify.py`) produces a label + scalar
  confidence + scalar signals only** (`LetteringClass`, `models.py:68-74`) — zero geometry. Nothing
  tracks *where* the hand-lettering sits as its own shape, distinct from the balloon's outline.
- **Confirmed by an exhaustive grep of the whole `scripts/`/`tests/` tree: zero `polygon` usage
  anywhere, and every `mask` is a disposable local computation buffer inside one function** — never
  returned, stored in a dataclass, or serialized.
- **The final `.comics`/`data.json` output stores zero text-region geometry.** `package.py`'s
  balloon image-slot writes are exactly `{"file", "width", "height"}` — the same three keys every
  balloon slot has always had. The rectangle/mask computed during rendering is thrown away before
  the file is ever written.

**Conclusion: this is a confirmed, real gap ("недоработка"), not a hypothetical.** The AI pipeline
already computes real, pixel-accurate masks twice (once for interior-safe-area, once for existing-
text-erasure) — the capability to know a precise, non-rectangular shape already exists as *working
code* — it's simply never persisted past the function call that needs it transiently. Adding
persistence, not new geometry-computation capability, is most of what's needed.

### Proposed schema addition

A new, optional, additive field — **`Layer.TextRegion`** — following this format's established
"open, ignorable-by-old-readers" pattern (same shape as `Kind`/`Style`/`Translations`/the new
`GroupId`):

```
Layer.TextRegion (optional, null = no text region -- today's status quo for every existing layer):
  shape: "rect" | "polygon" | "mask"
  // shape == "rect":
  x, y, width, height        (ints, same coordinate space as the layer's own image)
  // shape == "polygon":
  points: [[x,y], [x,y], ...]  (a closed vertex list -- e.g. derived from cv2.findContours +
                                 approxPolyDP on layout.py's already-computed interior mask)
  // shape == "mask":
  maskFile: string             (reference to a bitmap mask PNG, alongside the layer's own tiles --
                                 e.g. erase.py's already-computed text_mask, persisted instead of
                                 discarded)
  isHandLettered: bool         (distinguishes hand-drawn lettering artwork from rendered font text --
                                 may simply mirror the existing Layer.Style == "hand_lettered" value
                                 rather than duplicating it; exact relationship TBD, see Open Qs)
```

**Not gated by `Kind == "balloon"`** — per Anton's explicit follow-up ("текст может быть не только
внутри балуна"), `TextRegion` can attach to any layer regardless of `Kind`, so free-standing
lettering (a sound-effect layer with no enclosing balloon shape, `Kind` unset or `"art"`) gets the
same capability as balloon-contained text.

**Backward compatible with v2012 by the same mechanism as every prior addition**: `TextRegion` is
pure annotation metadata — it does not change how the layer's own (already fully rendered) image
displays. A v2012 reader that has never heard of `TextRegion` renders the layer exactly as it does
today; the field only matters to tooling that wants to know *where within this layer's image the
lettering sits* (translation workflows, future AI processing, a future richer Lottie export that
could choose to preserve a real Lottie text layer instead of a baked image where appropriate).

**Why three shape types, not just mask (most precise) or just polygon (most compact)**: real
hand-lettering can be organic enough that a simplified polygon loses real shape fidelity a mask
wouldn't (matching Anton's explicit bitmap-mask requirement) — but a polygon is dramatically more
compact for the common case of a clean rect-like or simple-curved region, and — a genuine added
benefit — **polygon regions map directly onto Lottie's own mask model**, since Lottie masks are
themselves vector bezier paths, never raster bitmaps. Choosing polygon-when-possible, mask-when-
necessary gives better Lottie round-trip fidelity for free, not just a compactness tradeoff.

### Proposed fix for the `comics-ai-baloons` gap itself (options, not a decision)

Since this is a real, confirmed gap in already-working code (masks are computed correctly, just
discarded), fixing it is mostly about *persistence*, not new algorithms:

1. **Minimal**: have `layout.find_interior_rect` optionally also return the mask it already
   computes (a second return value or a `find_interior_region` variant), and have `package.py`
   persist it (as a saved mask PNG, or contour→polygon-simplified) into the new `TextRegion` field
   when writing a balloon's image slot. Same for `erase.py`'s `text_mask`, if the *original*
   lettering's shape (not just the balloon interior) is wanted.
2. **More complete**: expose both — `TextRegion.shape="polygon"` derived from `layout.py`'s
   interior-safe mask (the "where text is allowed to go" region) is probably the more useful
   default (compact, Lottie-compatible), with `shape="mask"` reserved for cases a caller explicitly
   requests pixel precision (e.g. a genuinely irregular hand-lettered scrawl a polygon
   under-approximates).
3. **Not recommended without more data**: relying on `erase.py`'s glyph-shaped `text_mask` as the
   *primary* source, since that mask describes the *old* (possibly different-language, differently
   laid-out) text's shape, not necessarily where *new* text should go — `layout.py`'s interior mask
   is the more semantically correct source for "the region text should be fit into."

## Open Questions (Text Region, new)

- [ ] Exact relationship between `TextRegion.isHandLettered` and the existing `Layer.Style ==
      "hand_lettered"` value — one field mirroring the other, or should `TextRegion` fully replace
      that use of `Style`?
- [ ] Coordinate space for `TextRegion`'s geometry — relative to the layer's own image (simplest,
      matches how `width`/`height` already work per image slot) or absolute canvas coordinates
      (matches how `TranslateAnim.X`/`Y` already work)? Leaning layer-local, not decided.
- [x] **DECIDED (2026-08-07, Anton: "обнови comics-ai/sdd-comics-ai-baloons сразу")**: yes, and
      done immediately — a real, scoped follow-on task added to
      `flows/comics-ai/sdd-comics-ai-baloons/_status.md` (not just a passive cross-reference note
      this time), covering exactly what changes in `layout.py`/`erase.py`/`package.py` to persist
      `TextRegion` geometry instead of discarding it.
- [x] **UI entry point — DECIDED (2026-08-07), informed by Джанава's UI/UX vision**: checked
      `flows/_blamed/vdd-comics-editor-jhanava/{01-requirements,02-visual}.md` directly for how
      Джанава would approach this, per Anton's explicit instruction. That flow's core, repeated
      principle: **"needs review"/ambiguous/partial states matter more than the happy path** — its
      "Material Intake" sketch (`02-visual.md`) treats bringing in *any* external, not-fully-
      understood source material as a **triage/review step** (per-item status: queued / needs
      review / ambiguous), never a silent one-shot conversion, precisely because real source
      material doesn't cleanly decompose. Applied here: **`.lottie → .comics` import (the direction
      with real precision loss and unsupported-content risk) gets a small review screen** — after
      picking a file, show what was found (N layers converted cleanly, N flagged — unsupported
      shape/mask/text layers, ambiguous `TextRegion` guesses), surface the Q1/Q2 choices (time-base
      ratio, easing precision) right there rather than as a buried settings toggle, and require an
      explicit "commit import" action — not import-and-hope. **`.comics → .lottie` export** (the
      "easy direction," per `tdd-dot-lottie-format`'s conversion-feasibility research) can stay a
      simpler one-shot menu action, closer to today's existing Export button's own pattern
      (`top_bar.dart:240-243`, though that button itself is a different, existing `.comics`-to-
      `.comics` Save-As mechanism and should not be repurposed) — export has materially lower risk
      of silent data loss, so a full review screen isn't Джанава-justified there the way import's
      is.
- [x] **Round-trip identity — DECIDED (2026-08-07, Anton)**: **behaviorally equivalent**, not
      byte-for-byte. Confirms the Should Have's original leaning.
- [x] **Precomp handling — DECIDED (2026-08-07, Anton)**: add real **layer-grouping** to the
      `.comics` v2026 format (a new, purely additive, optional field — e.g. `Layer.GroupId`),
      rather than forcing a flatten-with-no-trace. **Must stay backward compatible with v2012 —
      "correct display is enough"**: v2012 readers don't need to understand groups at all; they
      just need to keep rendering correctly. This is achieved the same way every other additive
      field in this format's history has been (`Kind`/`Style`/`Translations`): `GroupId` is
      **purely organizational/editor-side** (selection, move-together, expand/collapse in the
      layers panel) with **zero effect on rendering** — each layer's own `Anim` keyframes are
      always the complete, absolute, final values, exactly as today. A Lottie precomp's own
      transform (position/scale/rotation/opacity animated on the precomp layer itself, on top of
      its children) gets **baked/pre-multiplied into each child layer's own individual keyframes
      at import time** — the same "compile down to flat absolute values" step the format already
      requires for every layer, group or not. So: precomp nesting maps to (a) N `EditorLayer`s, one
      per nested image layer, each with fully-baked absolute keyframes, tagged with (b) a shared
      new `GroupId` for editor-side convenience only. No v2012 reader ever needs to know groups
      exist. **UI/UX visual for the grouping feature added to
      `flows/comics-editor/vdd-comics-editor-systematization-uiux/02-visual.md`** per Anton's
      explicit request — see that flow for the layers-panel mockups (expand/collapse, group
      selection, move-together behavior). The underlying schema addition itself should also be
      reflected in `flows/tdd-dot-comics-format` as a new format fact once this ships.

## References

- `flows/tdd-dot-lottie-format/01-requirements.md` — the conversion-feasibility analysis this flow
  builds directly on
- `flows/tdd-dot-comics-format/02-tests.md` — the classic `.comics` schema/test catalog
- `apps/comics-editor/lib/src/ui/models.dart` — `Anim`, `EditorLayer`, `ComicsDoc`
- `apps/comics-editor/lib/src/bridge/models_mapping.dart` — existing JSON I/O, the pattern any new
  Lottie I/O should follow
- `apps/comics-editor/lib/src/ui/anim/keyframe_interpolator.dart` — the interpolation engine new
  imports must produce compatible `Anim` data for
- `apps/comics-editor/lib/src/ui/widgets/top_bar.dart:240-243,279-294` — the existing (unrelated)
  Export mechanism
- `samples/sample.lottie`, `samples/sample.lottie_unzip` — the real reference sample
- `flows/_blamed/vdd-comics-editor-jhanava/01-requirements.md`, `02-visual.md` — Джанава's UI/UX
  vision, consulted directly for the UI-entry-point decision (the "Material Intake" triage/review
  pattern for handling not-fully-understood external source material)
- `flows/comics-ai/sdd-comics-ai-baloons/_status.md` — now carries the real follow-on task for
  persisting `TextRegion` geometry (added 2026-08-07, not just a cross-reference note)
- `samples/sample_v2012.comics_unzip` — (NEW, 2026-08-08) real 1080×41500 classic `.comics`, anchors
  the Full Canvas round-trip test fixture
- `samples/sample_playback_viewport.lottie_unzip` — (NEW, 2026-08-08) real 720×1600 Lottie
  composition with root-level scene-sweep precomps, anchors the Playback Viewport round-trip test
  fixture; confirmed a genuinely different file from `samples/sample.lottie` (content hash checked)
- `flows/tdd-dot-comics-format/05-plan.md` — (NEW, 2026-08-08) `Anim.basis`/`scrollType` is now
  shipped in `apps/comics-editor` (Phases 2 and 5); Playback Viewport mode's scroll+time composition
  directly reuses this, not a parallel mechanism

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-07 (v0.2 baseline)
- [x] Notes: v0.2 approved with 2 Text Region sub-questions explicitly deferred to later, not
      resolved now and not blocking: (1) `TextRegion.isHandLettered` vs. existing `Layer.Style ==
      "hand_lettered"` relationship, (2) `TextRegion`'s coordinate space (layer-local vs. absolute
      canvas). Both narrow, self-contained schema-detail questions — don't affect the rest of this
      document's decisions and can be resolved whenever picked up.
- [x] **v0.3 addition (2026-08-08, Export/Import Modes) — approved 2026-08-08.** Added per Anton's
      direct specification, grounded in the two real sample fixtures above. Of the original 3 new
      Open Questions, 2 were resolved same-day with real evidence (mode-selection UI:
      auto-detect-with-override; scroll speed: auto-derivable from real root-sweep keyframes,
      computed to 149.49/150.00 px/sec on `ASHES.json`'s two real scenes) — see
      `03-specifications.md`'s Open Design Questions for the full resolutions. The scroll/time
      classification heuristic remains genuinely open (ships as "everything scroll-basis" for now),
      carried forward to Plan, not blocking this approval.
