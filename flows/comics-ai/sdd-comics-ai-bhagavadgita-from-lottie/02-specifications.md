# Specifications: comics-ai-bhagavadgita-from-lottie

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-08-09
> Requirements: [01-requirements.md](./01-requirements.md)

## Overview

Extract real per-layer motion, per-layer z-depth, and a reconstructed camera path from
`Mediation of the Bhagavat Gita.json` (the one real Lottie source in the Bhagavad Gita dataset) and
export them into a new `.comics` v2026 document. Moved verbatim (renumbered, not re-derived) from
`flows/comics-ai/sdd-comics-ai-bhagavadgita-generator/02-specifications.md`'s v0.4 "Lottie
Camera-Path & Per-Layer Z-Depth Extraction" section, per Anton's explicit extraction instruction
(2026-08-09).

Implementation lives inside the existing `apps/comics-ai/comics-ai-bhagavadgita-generator/` Python
application (this flow does not create a separate app) — a new module alongside that pipeline's
existing adapters (`import_psd.py` etc.), producing a separate, additional `.comics` output, not
integrated into that pipeline's 18-chapter loop. See `01-requirements.md`'s Constraints for why this
stays a distinct output.

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/import_lottie.py` (new) | Create | Frame calibration, keyframe extraction, camera-path reconstruction, z-depth derivation |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/package_comics.py` | Modify | Extend `PackagingAsset`/`_layer_json`/`build_data_json` for keyframe lists, `zDepth`, document-root `cameraPath` — backward-compatible, existing 18-chapter path unaffected |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/pipeline.py` | Modify | New, separate CLI entry point, not part of `--all`'s 18-chapter loop |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/report.py` | Modify | Parallax-limitation disclosure text for this specific document |
| `flows/tdd-dot-comics-format/` | Cross-flow, not modified by this flow | Real, disclosed follow-up: `cameraPath` should eventually be formally adopted there, matching how `Layer.ZDepth`/`preferredViewportWidth` were each proposed by a motivating flow and later adopted — not done as part of this flow |

## Source: the Real Lottie File

`dataset/bhagavadgita/vaishnav/bhagavadgita_lottie/unzip/1/Mediation of the Bhagavat Gita_content/
Mediation of the Bhagavat Gita.json` — real structure confirmed in Requirements: 3 precomp "scenes",
each with a 2-keyframe top-level pan and a real minority of individually-animated layers.

### Module boundary

A new `scripts/import_lottie.py`, parallel to the existing `import_psd.py` (chapter-5 adapter) —
same pattern: a dedicated adapter for one specific external source, producing the same
`PackagingAsset`-shaped output the rest of the pipeline (`layout_chapter.py`, `package_comics.py`)
already consumes, not a parallel packaging path.

```python
# scripts/import_lottie.py -- NEW

@dataclass(frozen=True)
class LottieKeyframe:
    frame: int
    x: float
    y: float

@dataclass(frozen=True)
class LottieLayerMotion:
    position_keyframes: list[LottieKeyframe]  # empty if the layer is static
    scale_keyframes: list[tuple[int, float]]   # (frame, scale_percent); empty if static

def scene_pan(precomp_layer: dict) -> tuple[int, float, int, float]:
    """Returns (frame_start, y_start, frame_end, y_end) from a top-level precomp layer's own
    2-keyframe ks.p -- the real, confirmed linear pan calibrating this scene's frame->scroll-Y map."""

def frame_to_scroll_y(frame: int, pan: tuple[int, float, int, float]) -> float:
    """Linear interpolation through `pan` -- the same calibration `.comics`' own scroll-driven model
    needs: Lottie's frame axis IS this scene's scroll-progress axis, since the top-level pan is what
    makes the scene readable top-to-bottom in the first place."""

def extract_layer_motion(layer: dict) -> LottieLayerMotion: ...

def to_translate_anim_keyframes(
    motion: LottieLayerMotion, pan: tuple[int, float, int, float]
) -> list[dict]:
    """N Lottie position keyframes -> (N-1) `.comics` TranslateAnim JSON objects, chained per the
    existing Anim model (each covers one [start,end] scroll-Y segment, value = the segment's end
    point) -- see "TranslateAnim keyframe chaining" below."""

def select_camera_reference_layer(layers: list[dict]) -> dict | None:
    """Ranks animated layers by (has_scale_keyframes, keyframe_count, total_displacement), returns
    the richest one as this scene's camera-tracked subject. See "Reconstructed Camera-Path Element"
    below. Returns None if a scene has no animated layers at all (real edge case, see Edge Cases)."""

def build_camera_path(reference_layer: dict, pan: tuple[int, float, int, float]) -> list[dict]:
    """Reuses to_translate_anim_keyframes's own chaining logic against the selected reference
    layer -- the resulting list IS the scene's `cameraPath`, not a separately-derived structure."""

def derive_z_depth(
    motion: LottieLayerMotion, camera_path: list[dict], is_camera_reference: bool
) -> float:
    """See "Z-depth derivation" below. Returns 0.0 for a fully static layer OR the camera-reference
    layer itself."""
```

### Frame-to-scroll-Y calibration

`.comics` `Anim.start`/`end` live in the same raw-pixel coordinate space as scroll position (per
`flows/tdd-dot-comics-format`'s confirmed finding, "Layer & animation model"). Lottie's `t` (frame)
axis has no native pixel meaning — but each scene's own top-level precomp layer already has a real,
confirmed 2-keyframe position animation whose Y values ARE meant to represent scroll-through-content
(that's what makes the panned-past art visible over the read). Using that same pan as the
frame→scroll-Y calibration for every layer *within* that scene is the natural, principled choice —
not an invented one.

**Local-to-root frame conversion, resolved (not left open)**: a layer nested inside a precomp asset
(e.g. `comp_0`) has its own keyframe `t` values in the precomp's *local* timeline, while the pan's
own keyframes belong to the *root*-timeline layer (`0_3`) that references `comp_0` via `refId` — the
two are not directly comparable without conversion. Checked directly against the real file: each
top-level layer's `st` (start time) equals its own `ip` (in point), and `sr` (stretch ratio) is `1`
for all three scenes (`0_3`: `ip=st=6252`; `0_2`: `ip=st=2955`; `0_1`: `ip=st=-171`) — the standard
Lottie convention for "no time-remapping," meaning the conversion is simply `root_frame = st +
local_frame`. Verified end-to-end on the real 6-keyframe example layer (local frames 539–1377,
`comp_0`'s `st=6252`): converts to root frames 6791–7629, all falling **inside** `comp_0`'s own real
pan window (`6252–12168`) — no extrapolation needed for this example, and the resulting `scroll_y`
values (computed via `scroll_y(root_frame) = y_start + (root_frame - frame_start) /
(frame_end - frame_start) × (y_end - y_start)`) are well-defined real numbers (6051.73, 5271.0,
4913.16, 4620.38, 4392.67, 3954.76 for the six keyframes respectively). The final pipeline formula is
therefore: `scroll_y(local_frame, precomp_st) = scroll_y_from_pan(precomp_st + local_frame)`.

### A second, separate real problem: absolute canvas position, not yet resolved

The frame-axis calibration above answers "what `.comics` scroll-position does this Lottie frame
correspond to." It does **not** by itself answer what a layer's **absolute `.comics` canvas
position** should be — a real, separate compositing question this spec has not fully verified.

Checked directly: individual layers' own static/keyframed position values are small (e.g. the real
static layers cited in Requirements sit at Y values like `188.786`, `325`, `260.571` — well within
the `720×1600` viewport, nowhere near the multi-thousand-pixel range the scene's own pan spans:
`7400.5` down to `−7403.425`). This confirms a layer's own `p` value is **local to the precomp's own
coordinate frame**, not an absolute position on one tall `.comics` canvas — standard Lottie precomp
compositing means a nested layer's on-screen position is the parent (pan) layer's own position
**composited with** the nested layer's local position, not either value alone. `.comics` has no
separate camera/viewport transform (per `flows/tdd-dot-comics-format`'s own confirmed model, every
layer's position is one absolute value on the scroll canvas) — so this compositing has to happen
*before* export, producing one absolute Y per keyframe, not left as two separate numbers.

**Proposed (not yet verified against a rendered frame)**: `absolute_y(frame) = pan_y(frame_start) −
pan_y(root_frame) + local_y(root_frame)` — re-expresses everything relative to the pan's own starting
position, so the *first* moment of the scene has every static layer sitting at its own local Y value
(a sensible anchor: "top of scroll = local coordinates unchanged"), and later moments shift by however
far the pan itself has moved. This is a reasonable, principled guess consistent with how AE/Lottie
precomp nesting actually composites, but **it has not been checked against ground truth** — flagged
as a real, load-bearing Open Design Question below, not asserted as verified. The worked numeric
example in "Data Models" below is illustrative of the *keyframe-chaining shape*, not a claim that its
exact numbers are final. Verification method (per Anton's explicit no-external-tooling constraint):
cross-check against `flows/comics-editor/tdd-dot-lottie-import-export`'s own precomp/parent-chain
resolution findings and `libs/flutter_comics`'s existing, tested Lottie parser — not a rendered pixel
comparison via a newly-installed renderer.

### TranslateAnim keyframe chaining

`.comics`' existing `Anim` model (per `KeyframeInterpolator`, already implemented, unchanged by this
flow) already chains multiple same-type `Anim`s: each one's `start`/`end` is a scroll-position
window, its `x`/`y` is the value at `end`, and the value at `start` is implicitly the *previous*
chained `Anim`'s own `x`/`y` (or the layer's static resting position if it's the first). N real
Lottie position keyframes therefore become **N−1 `TranslateAnim` objects** (not N) — the real example
layer's 6 position keyframes (frames 539, 851, 994, 1111, 1202, 1377) become 5 chained
`TranslateAnim`s, each `start`/`end` from consecutive calibrated `scroll_y(frame)` pairs, each `x`/`y`
the *later* keyframe's real Lottie position. This preserves the real, confirmed irregular timing
(deltas 312, 143, 117, 91, 175 frames → correspondingly irregular `scroll_y` deltas once calibrated)
— the actual mechanism that makes the exported document's camera motion non-constant-speed, matching
Requirements' Must-Have 1 without inventing a new keyframe/interpolation concept.

### Reconstructed Camera-Path Element

Anton's direct instruction: "...moving against the shared linear pan, и именно эту ломанную кривую
необходимо восстановить и сохранить в отдельный элемент — движение камеры — в .comics v2026." The
reconstructed broken curve (not the trivial 2-keyframe linear pan) must be written as its **own**
schema element, not only distributed into per-layer `TranslateAnim`.

**Why the linear pan alone is the wrong reconstruction target**: it's real, but trivial — 2
keyframes, constant speed (Requirements' own table). Anton's "человеческий глаз видит по другому"
point is that the *perceived* camera follows whatever the eye locks onto — and the real data gives a
concrete, motivated candidate for that: the richest animated layer(s) (real example: `comp_0`/
`ind=43`, 6 position keyframes with irregular timing **and** scale growing 78%→112%, i.e. a "dolly
in" — the classic in-camera-language signature, not just an object moving) are exactly the shape a
camera-follow/push-in shot would produce. **Proposed reconstruction**: for each scene, select the
single richest animated layer (ranked by: has scale keyframes > keyframe count > total displacement
magnitude — the real example already wins on all three) as that scene's **camera reference layer**,
and export its own already-computed absolute trajectory (per "A second, separate real problem" above
— same compositing formula, no new math) as the scene's `cameraPath`, instead of (only) as that one
layer's own `TranslateAnim`.

```json
// New document-root (or per-scene, if Requirements' Open Question on 1-vs-3 files resolves that
// way) field, sibling to `layers`/`sounds`:
"cameraPath": [
  {"start": 6052, "end": 5271, "x": 436.12, "y": 3449.613},
  {"start": 5271, "end": 4913, "x": 417.329, "y": 3631.284},
  {"start": 4913, "end": 4620, "x": 450.989, "y": 3945.418},
  {"start": 4620, "end": 4393, "x": 201.029, "y": 4178.471},
  {"start": 4393, "end": 3955, "x": 181.595, "y": 4566.756}
]
```

Same keyframe-chaining shape as `TranslateAnim` (deliberately reused, not invented fresh — the values
above are literally the same real numbers already shown in "TranslateAnim keyframe chaining" above,
now also exported at the document level). The camera-reference layer itself is still written as an
ordinary layer too (with its own `TranslateAnim`s and, per the ratio formula below, `zDepth = 0`,
since it's the reference everything else is measured against) — `cameraPath` is an **additional**,
derived, redundant-but-explicit copy for any consumer that wants "the path" without having to guess
which layer was the reference.

**This is a genuinely new `.comics` v2026 schema concept with no existing counterpart** (unlike
`Layer.ZDepth`, which already had a home in `flows/tdd-dot-comics-format`) — this specification
proposes it here, motivated by this flow's own real, concrete need, matching the established
cross-flow pattern (`preferredViewportWidth` was proposed the same way, motivated by
`tdd-dot-lottie-import-export`, then adopted into `tdd-dot-comics-format` proper). **Real,
disclosed follow-up needed**: `tdd-dot-comics-format` should formally adopt `cameraPath` the same
way, not leave it as a one-pipeline-only convention — not done as part of this flow, flagged as an
Open Design Question below.

### Z-depth derivation

Two real signals found in Requirements' analysis, used in this priority order per layer, relative to
the reconstructed `cameraPath` above (not the trivial linear pan — a more physically meaningful
parallax reference, and the reason `cameraPath` must exist before z-depth can be computed at all):

1. **Scale animation present** (rarer, but the richest real example layer has it): `growth =
   final_scale_percent / initial_scale_percent` (real example: `111.95 / 78 ≈ 1.435`).
   `zDepth = round((1 / growth - 1) × K, 3)` — growth > 1 (the layer visually approaches, matching
   the classic 2.5D "objects scale up as camera nears" cue) → `zDepth < 0`; growth < 1 (recedes) →
   `zDepth > 0`. Real example: `zDepth ≈ round((1/1.435 - 1) × K, 3) = round(-0.303 × K, 3)` — **this
   is the camera reference layer itself**, so its own `zDepth` should really be pinned to `0`
   (it *is* the reference plane by construction) rather than computed from its own formula, which
   would otherwise self-referentially report it as "closer than itself." Flagged as an implementation
   detail: the camera-reference layer is excluded from this formula and hardcoded to `zDepth = 0`.
2. **Position (and/or scale) animation present, not the camera-reference layer**:
   `layer_amplitude = |Δ(x,y)|` (Euclidean) across the layer's own real keyframes over the
   overlapping time window; `camera_amplitude = |Δ(cameraPath.x,y)|` over that same window (linearly
   interpolating `cameraPath` at the layer's own keyframe times where they don't line up exactly);
   `ratio = layer_amplitude / camera_amplitude`; `zDepth = round((1/ratio − 1) × K, 3)` — moves more
   than the camera → closer/faster → negative; less → farther/slower → positive.
3. **Fully static** (no position or scale keyframes — the real majority, 62–87% of layers per
   scene): `zDepth = 0.0` — matches `Layer.ZDepth`'s own documented default/no-offset value. A
   background element pinned to the world, panned past at the camera's own rate, is depth-neutral
   relative to the camera by definition.

`K` (an overall scale constant converting a dimensionless ratio into `Layer.ZDepth`'s own units) is
**not yet fixed** — `flows/tdd-dot-comics-format` itself has not decided `ZDepth`'s exact unit/range
(see that flow's own Open Design Questions). This spec proposes `K = 1.0` as a working default
(making `zDepth` numerically equal to `1/ratio - 1`, a small, sign-meaningful, unitless coefficient)
but flags this as a real Open Design Question below, not a finalized constant.

### Data Models

```json
{
  "images": [{}, {"file": "lottie_43_{0}_{1}_{2}.png", "width": 320, "height": 380}, {}],
  "animations": [
    {"$type": "Comics.Editor.Models.TranslateAnim, Comics.Editor",
     "start": 6052, "end": 5271, "x": 436.12, "y": 3449.613},
    {"$type": "Comics.Editor.Models.TranslateAnim, Comics.Editor",
     "start": 5271, "end": 4913, "x": 417.329, "y": 3631.284},
    {"$type": "Comics.Editor.Models.TranslateAnim, Comics.Editor",
     "start": 4913, "end": 4620, "x": 450.989, "y": 3945.418},
    {"$type": "Comics.Editor.Models.TranslateAnim, Comics.Editor",
     "start": 4620, "end": 4393, "x": 201.029, "y": 4178.471},
    {"$type": "Comics.Editor.Models.TranslateAnim, Comics.Editor",
     "start": 4393, "end": 3955, "x": 181.595, "y": 4566.756}
  ],
  "zDepth": -0.303,
  "kind": "art"
}
```

`start`/`end` above are the real, computed `scroll_y(root_frame)` values (rounded to integers, matching
`Anim.start`/`end: int`) for the real 6-keyframe example layer — genuinely computed, not hand-picked.
**`x`/`y` are the layer's raw local Lottie position values, unmodified** — per "A second, separate
real problem" above, these still need the absolute-canvas compositing step resolved before they're
correct `.comics` values; this example shows the correct **keyframe-chaining shape** (N Lottie
keyframes → N−1 chained Anims, real irregular `start`/`end` spacing), not a claim that `436.12`/
`3449.613` etc. are final. Note `start > end` numerically (scroll_y *decreases* as frame increases,
since the pan's own Y decreases while scrolling proceeds) — `.comics`' `Anim` model doesn't require
`start < end`, but every other real `.comics` file/other layer in this same document uses increasing
ranges; **whether to negate/offset so this new content follows that convention too, or leave it
inverted, is a real, undecided detail**, added to Open Design Questions below. `zDepth` is written as
a plain additional root-level key on the layer object, per `flows/tdd-dot-comics-format`'s own
additive-field convention — omitted entirely (not written as `0`) for a static layer, matching that
flow's "absent and explicit-0 are the same value" rule and keeping output byte-smaller for the ~70%
of layers that don't need it. **`cameraPath`** is written once, as a sibling of `layers`/`sounds` at
the document root (per "Reconstructed Camera-Path Element" above) — not per-layer.

### Open Design Questions

- [ ] **Absolute canvas position compositing** — the proposed `absolute_y(frame) = pan_y(frame_start)
      − pan_y(root_frame) + local_y(root_frame)` formula is a principled guess, not verified against
      ground truth. Verifying it (per Anton's no-external-tooling constraint: cross-check against
      `tdd-dot-lottie-import-export`/`libs/flutter_comics` findings, not a rendered pixel comparison)
      is Plan Task 1.1.
- [ ] **`scroll_y` decreasing vs. `.comics`' usual increasing convention** — whether to invert/offset
      the sign so this content's `Anim.start < end` like every other real file, or leave it as the
      pan's own natural decreasing direction (functionally equivalent either way, per
      `KeyframeInterpolator`'s own math, but a real consistency question for whoever reviews the
      output by eye).
- [ ] **The `K` constant** in the z-depth formula (currently proposed `K = 1.0`) is a placeholder,
      not calibrated against anything — `flows/tdd-dot-comics-format` itself hasn't fixed `Layer
      .ZDepth`'s unit/range yet either, so this is a real, two-flow-spanning open question, not
      something this flow can close unilaterally.
- [ ] Whether the 3 scenes (`0_1`/`0_2`/`0_3`) export as 3 separate `.comics` files or one document
      with 3 internal regions — carried from Requirements' own Open Questions, restated here since it
      directly affects how `precomp_st` values are scoped per output file.
- [ ] **Camera-reference-layer selection heuristic**: "richest single layer" (has scale > keyframe
      count > displacement) is a concrete, implementable default, but not validated against any
      ground truth about what the artist actually intended as "the camera." A real risk: the richest
      layer might just be the most elaborately-animated *character*, not a camera surrogate at all —
      Task 1.1's cross-check (Plan) is the place to sanity-check this, not assumed correct from the
      formula alone.
- [ ] **Single layer vs. blended reference**: this spec picks exactly one layer per scene; whether a
      weighted blend of the top-N richest layers would reconstruct a more faithful camera path is a
      real, unexplored alternative, not ruled out, just not the default.
- [ ] **`cameraPath` × `Layer.ZDepth` composition at render time**: this spec defines how to *derive*
      both values but not how a future renderer should *combine* them into an actual on-screen
      parallax offset (e.g. `layer_offset = cameraPath(scroll) × f(layer.zDepth)` for some function
      `f`) — that's `flows/tdd-dot-comics-format`'s own still-open "scroll-response formula" question
      (see its Open Design Questions), now with a second free variable (`cameraPath` itself) that
      flow hadn't previously needed to account for. Real, disclosed, two-flow-spanning gap.
- [ ] **Cross-flow schema adoption**: `cameraPath` is proposed here, motivated by this flow's real
      need, but not yet formally added to `flows/tdd-dot-comics-format`'s own Requirements/
      Specifications the way `Layer.ZDepth`/`preferredViewportWidth` were — a real, disclosed,
      not-yet-done follow-up.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| A layer's own local keyframe range, once converted (`root_frame = st + local_frame`), falls partly or fully outside its scene's own pan `[frame_start, frame_end]` window | A layer whose local timeline extends before/after the pan's own span | The real example checked converts entirely inside the pan window (root frames 6791–7629 within `comp_0`'s `6252–12168`), so no extrapolation was needed there — but this isn't guaranteed for all ~120 animated layers across the 3 scenes. Where it does happen, linear extrapolation of `scroll_y` is mathematically well-defined but unverified against ground truth — same caveat as the absolute-position compositing question above |
| `camera_amplitude` (z-depth case 2) is 0 or near-0 (the camera-reference layer has ~0 displacement over the window being compared) | Degenerate/malformed input | Division-by-zero guard needed; fall back to `zDepth = 0.0` rather than crashing or producing `inf`/`NaN` |
| A layer has scale keyframes but they don't overlap the same frame range as its position keyframes (not observed in the one real example checked, but not ruled out across all ~120 animated layers in the 3 scenes) | Real possibility, not yet exhaustively checked | Case-1 formula (scale-based) still applies independent of position-keyframe timing — z-depth is derived from scale growth alone when scale is present, regardless of whether position keyframes align |
| Extrapolating `scroll_y(frame)` for a frame outside `[frame_start, frame_end]` (linear formula applied beyond its calibration range) | A layer's local keyframes span before/after the scene's own pan window | Mathematically well-defined (linear extrapolation), but not verified against any independent ground truth — disclosed as an approximation, not a confirmed-correct mapping |
| A scene has **no** animated layers at all (not observed — all 3 real scenes have real animated minorities — but not structurally guaranteed for other future Lottie sources this same module might process) | `select_camera_reference_layer` finds no candidates | Falls back to `cameraPath = [the trivial linear pan itself]` (still real, still correct, just not a "broken curve") — never crashes or omits the field entirely, since `zDepth`'s case-2 formula needs *some* reference to divide by |

### Testing Strategy

- [ ] Unit: `scene_pan`/`frame_to_scroll_y` against the 3 real, hand-verified pan tuples in
      Requirements' table
- [ ] Unit: `to_translate_anim_keyframes` against the real 6-keyframe example layer, asserting
      exactly 5 output `TranslateAnim`s with the real Lottie `x`/`y` values and correctly-chained
      `start`/`end`
- [ ] Unit: `select_camera_reference_layer` against a synthetic scene with several candidate layers,
      asserting the scale+keyframe-count+displacement ranking picks the expected one; against the
      real `comp_0` data, asserting it picks the real `ind=43` layer specifically
- [ ] Unit: `build_camera_path` produces the same keyframe values as `to_translate_anim_keyframes`
      would for the selected reference layer — no drift between the two representations
- [ ] Unit: `derive_z_depth` for all cases (scale-present, position-only, static, camera-reference-
      itself-pinned-to-0), including the division-by-zero guard
- [ ] Integration: run `import_lottie.py` against the real file end-to-end, assert the real
      static/animated layer counts per scene match Requirements' cited numbers (e.g. `comp_0`:
      131 static, 56 animated), that `cameraPath` is present and non-trivial (not identical to the
      raw linear pan), and that at least two output layers have different non-zero `zDepth` values
      (Requirements' Must-Haves 2 and 4's concrete proof)

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-09 — approved in the parent flow as v0.4 ("reqs,specs and plan approved")
      before extraction.
- [x] Notes: real open engineering questions remain (see Open Design Questions above), disclosed and
      unaffected by this extraction.
