# Specifications: comics-ai-bhagavadgita-from-bodymovin

> Version: 1.2 (implementation-verified compositing + seed-keyframe correction)
> Status: APPROVED
> Last Updated: 2026-08-09
> Requirements: [01-requirements.md](./01-requirements.md)

## Overview

Extract real per-layer motion, per-layer z-depth, and a reconstructed camera path from
`Mediation of the Bhagavat Gita.json` (the one real Bodymovin source in the Bhagavad Gita dataset) and
export them into a new `.comics` v2026 document. Moved verbatim (renumbered, not re-derived) from
`flows/comics-ai/sdd-comics-ai-bhagavadgita-generator/02-specifications.md`'s v0.4 "Bodymovin
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
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/import_bodymovin.py` (new) | Create | Frame calibration, keyframe extraction, camera-path reconstruction, z-depth derivation |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/package_comics.py` | Modify | Extend `PackagingAsset`/`_layer_json`/`build_data_json` for keyframe lists, `zDepth`, document-root `cameraPath` — backward-compatible, existing 18-chapter path unaffected |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/pipeline.py` | Modify | New, separate CLI entry point, not part of `--all`'s 18-chapter loop |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/report.py` | Modify | Parallax-limitation disclosure text for this specific document |
| `flows/tdd-dot-comics-format/03-specifications.md` | Canonical dependency, not modified by this flow | Sole format contract for the producer's emitted `cameraPath`/`zDepth`; shared Dart and viewer mappings are downstream owners |

## Source: the Real Bodymovin File

`dataset/bhagavadgita/vaishnav/bhagavadgita_bodymovin/unzip/1/Mediation of the Bhagavat Gita_content/
Mediation of the Bhagavat Gita.json` — real structure confirmed in Requirements: 3 precomp "scenes",
each with a 2-keyframe top-level pan and a real minority of individually-animated layers.

### Module boundary

A new `scripts/import_bodymovin.py`, parallel to the existing `import_psd.py` (chapter-5 adapter) —
same pattern: a dedicated adapter for one specific external source, producing the same
`PackagingAsset`-shaped output the rest of the pipeline (`layout_chapter.py`, `package_comics.py`)
already consumes, not a parallel packaging path.

```python
# scripts/import_bodymovin.py -- NEW

@dataclass(frozen=True)
class BodymovinKeyframe:
    frame: int
    x: float
    y: float

@dataclass(frozen=True)
class BodymovinLayerMotion:
    position_keyframes: list[BodymovinKeyframe]  # empty if the layer is static
    scale_keyframes: list[tuple[int, float]]   # (frame, scale_percent); empty if static

def scene_pan(precomp_layer: dict) -> tuple[int, float, int, float]:
    """Returns (frame_start, y_start, frame_end, y_end) from a top-level precomp layer's own
    2-keyframe ks.p -- the real, confirmed linear pan calibrating this scene's frame->scroll-Y map."""

def frame_to_scroll_y(frame: int, pan: tuple[int, float, int, float]) -> float:
    """Linear interpolation through `pan` -- the same calibration `.comics`' own scroll-driven model
    needs: Bodymovin's frame axis IS this scene's scroll-progress axis, since the top-level pan is what
    makes the scene readable top-to-bottom in the first place."""

def extract_layer_motion(layer: dict) -> BodymovinLayerMotion: ...

def to_translate_anim_keyframes(
    motion: BodymovinLayerMotion, pan: tuple[int, float, int, float]
) -> list[dict]:
    """N Bodymovin position keyframes -> N `.comics` TranslateAnim JSON objects: one zero-width seed
    carrying the first authored value, followed by N-1 chained [start,end] segments whose values
    are their endpoints -- see "TranslateAnim keyframe chaining" below."""

def select_camera_reference_layer(layers: list[dict]) -> dict | None:
    """Ranks animated layers by (has_scale_keyframes, keyframe_count, total_displacement), returns
    the richest one as this scene's camera-tracked subject. See "Reconstructed Camera-Path Element"
    below. Returns None if a scene has no animated layers at all (real edge case, see Edge Cases)."""

def build_camera_path(reference_layer: dict, pan: tuple[int, float, int, float]) -> list[dict]:
    """Reuses to_translate_anim_keyframes's own chaining logic against the selected reference
    layer -- the resulting list IS the scene's `cameraPath`, not a separately-derived structure."""

def derive_z_depth(
    motion: BodymovinLayerMotion, camera_path: list[dict], is_camera_reference: bool
) -> float:
    """See "Z-depth derivation" below. Returns 0.0 for a fully static layer OR the camera-reference
    layer itself."""
```

### Frame-to-scroll-Y calibration

`.comics` `Anim.start`/`end` live in the same raw-pixel coordinate space as scroll position (per
`flows/tdd-dot-comics-format`'s confirmed finding, "Layer & animation model"). Bodymovin's `t` (frame)
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
Bodymovin convention for "no time-remapping," meaning the conversion is simply `root_frame = st +
local_frame`. Verified end-to-end on the real 6-keyframe example layer (local frames 539–1377,
`comp_0`'s `st=6252`): converts to root frames 6791–7629, all falling **inside** `comp_0`'s own real
pan window (`6252–12168`) — no extrapolation needed for this example, and the resulting `scroll_y`
values (computed via `scroll_y(root_frame) = y_start + (root_frame - frame_start) /
(frame_end - frame_start) × (y_end - y_start)`) are well-defined real numbers (6051.73, 5271.0,
4913.16, 4620.38, 4392.67, 3954.76 for the six keyframes respectively). The final pipeline formula is
therefore: `scroll_y(local_frame, precomp_st) = scroll_y_from_pan(precomp_st + local_frame)`.

### Absolute canvas position — resolved by Plan Task 1.1

The frame-axis calibration above answers "what `.comics` scroll-position does this Bodymovin frame
correspond to." It does **not** by itself answer what a layer's **absolute `.comics` canvas
position** should be — a real, separate compositing question this spec has not fully verified.

Checked directly: individual layers' own static/keyframed position values are small (e.g. the real
static layers cited in Requirements sit at Y values like `188.786`, `325`, `260.571` — well within
the `720×1600` viewport, nowhere near the multi-thousand-pixel range the scene's own pan spans:
`7400.5` down to `−7403.425`). This confirms a layer's own `p` value is **local to the precomp's own
coordinate frame**, not an absolute position on one tall `.comics` canvas — standard Bodymovin precomp
compositing means a nested layer's on-screen position is the parent (pan) layer's own position
**composited with** the nested layer's local position, not either value alone. `.comics` has no
separate camera/viewport transform (per `flows/tdd-dot-comics-format`'s own confirmed model, every
layer's position is one absolute value on the scroll canvas) — so this compositing has to happen
*before* export, producing one absolute Y per keyframe, not left as two separate numbers.

Plan Task 1.1 checked the real root anchors/positions and the already-tested Flutter import/export
composition. The v1.1 guess `scroll + local` was wrong: it omitted anchors/parents and then added the
root sweep a second time. The implemented, verified conversion is:

```text
screenMatrix(frame) = rootPrecompMatrix(rootFrame) × parentChain(frame) × layerMatrix(frame)
screenTopLeft(frame) = screenMatrix(frame) × (0, 0)
documentPosition(frame) = sceneOffset + (rootStartY - rootY(rootFrame))
absoluteX = screenTopLeft.x
absoluteY = screenTopLeft.y + documentPosition
```

Every transform matrix uses Bodymovin's `T(position) × R(rotation) × S(scale) × T(-anchor)` order.
For the common real case where the root starts with `position == anchor`, has identity scale/
rotation, and the layer has no parent, the root sweep cancels exactly once against viewer scroll;
the layer's absolute position therefore remains its local top-left, as expected. A focused automated
test evaluates the same layer at the sweep's start/end and proves both absolute positions are equal.

### TranslateAnim keyframe chaining

`.comics`' existing `Anim` model (per `KeyframeInterpolator`, already implemented, unchanged by this
flow) already chains multiple same-type `Anim`s: each one's `start`/`end` is a scroll-position
window, and its `x`/`y` is the value at `end`. The shared `KeyframeInterpolator` does **not** use its
fallback as the previous value once the first segment becomes active; without a seed it interpolates
from `(0,0)`. Therefore N real Bodymovin position keyframes become **N `TranslateAnim` objects**: one
zero-width seed (`start == end == first position`, carrying the first X/Y) plus N−1 segments. This is
the exact pattern the existing tested Flutter Bodymovin importer already uses. It preserves irregular timing
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

The cross-flow format contract now gives this element a canonical point shape. Source pan Y runs
downward as frames advance, so it is normalized to an increasing document scroll coordinate:

```text
position(rootFrame) = panY(frameStart) - panY(rootFrame)
```

For the real six-keyframe `comp_0` reference example, this yields approximately `1348.77`,
`2129.50`, `2487.34`, `2780.12`, `3007.83`, and `3445.74`; serialized integer positions use the
existing nearest-integer convention. The first camera coordinate is retained explicitly:

```json
"cameraPath": [
  {"position": 1349, "x": 592.164, "y": 3231.145},
  {"position": 2130, "x": 436.120, "y": 3449.613},
  {"position": 2487, "x": 417.329, "y": 3631.284},
  {"position": 2780, "x": 450.989, "y": 3945.418},
  {"position": 3008, "x": 201.029, "y": 4178.471},
  {"position": 3446, "x": 181.595, "y": 4566.756}
]
```

The X/Y values above still illustrate the real raw local trajectory; Task 1.1 must replace them with
verified absolute document-space values if its compositing check changes them. The schema shape and
increasing positions do not depend on that result. The camera-reference layer remains an ordinary
layer too (with its own `TranslateAnim`s and `zDepth = 0`); `cameraPath` is additional explicit data,
not endpoint-only `TranslateAnim`s whose first coordinate would be ambiguous.

This was proposed here from a real need and is now adopted by the approved
`tdd-dot-comics-format` v0.11/v0.8 addendum. This producer must use that shared contract rather than
a private one-pipeline-only alternative.

### Z-depth derivation

Two real signals found in Requirements' analysis, used in this priority order per layer, relative to
the reconstructed `cameraPath` above (not the trivial linear pan — a more physically meaningful
parallax reference, and the reason `cameraPath` must exist before z-depth can be computed at all):

1. **Scale animation present** (rarer, but the richest real example layer has it): `growth =
   final_scale_percent / initial_scale_percent` (real example: `111.95 / 78 ≈ 1.435`).
   `zDepth = round(1 / growth - 1, 3)` — growth > 1 (the layer visually approaches, matching
   the classic 2.5D "objects scale up as camera nears" cue) → `zDepth < 0`; growth < 1 (recedes) →
   `zDepth > 0`. Real example: `zDepth ≈ round(1/1.435 - 1, 3) = -0.303` — **this
   is the camera reference layer itself**, so its own `zDepth` should really be pinned to `0`
   (it *is* the reference plane by construction) rather than computed from its own formula, which
   would otherwise self-referentially report it as "closer than itself." Flagged as an implementation
   detail: the camera-reference layer is excluded from this formula and hardcoded to `zDepth = 0`.
2. **Position (and/or scale) animation present, not the camera-reference layer**:
   `layer_amplitude = |Δ(x,y)|` (Euclidean) across the layer's own real keyframes over the
   overlapping time window; `camera_amplitude = |Δ(cameraPath.x,y)|` over that same window (linearly
   interpolating `cameraPath` at the layer's own keyframe times where they don't line up exactly);
   `ratio = layer_amplitude / camera_amplitude`; `zDepth = round(1/ratio − 1, 3)` — moves more
   than the camera → closer/faster → negative; less → farther/slower → positive.
3. **Fully static** (no position or scale keyframes — the real majority, 62–87% of layers per
   scene): `zDepth = 0.0` — the producer's neutral/reference fallback. A background element pinned
   to the world, panned past at the camera's own rate, is treated as depth-neutral by this heuristic;
   that inference is not physical-depth ground truth.

`K = 1` is the canonical definition in the approved `tdd-dot-comics-format` v0.11/v0.8 contract:
`zDepth` is unitless and `motionRatio = 1 / (1 + zDepth)`. The valid authored domain is
`zDepth > -1`; this importer falls back to `0` for degenerate or non-finite derivations.

### Data Models

```json
{
  "images": [{}, {"file": "bodymovin_43_{0}_{1}_{2}.png", "width": 320, "height": 380}, {}],
  "animations": [
    {"$type": "Comics.Editor.Models.TranslateAnim, Comics.Editor",
     "start": 1349, "end": 1349, "x": 592.164, "y": 3231.145},
    {"$type": "Comics.Editor.Models.TranslateAnim, Comics.Editor",
     "start": 1349, "end": 2130, "x": 436.12, "y": 3449.613},
    {"$type": "Comics.Editor.Models.TranslateAnim, Comics.Editor",
     "start": 2130, "end": 2487, "x": 417.329, "y": 3631.284},
    {"$type": "Comics.Editor.Models.TranslateAnim, Comics.Editor",
     "start": 2487, "end": 2780, "x": 450.989, "y": 3945.418},
    {"$type": "Comics.Editor.Models.TranslateAnim, Comics.Editor",
     "start": 2780, "end": 3008, "x": 201.029, "y": 4178.471},
    {"$type": "Comics.Editor.Models.TranslateAnim, Comics.Editor",
     "start": 3008, "end": 3446, "x": 181.595, "y": 4566.756}
  ],
  "zDepth": 0.0,
  "kind": "art"
}
```

`start`/`end` above are the real frame positions normalized into increasing document scroll pixels
and rounded to `Anim.start`/`end: int` for the real six-keyframe example — computed, not hand-picked.
**`x`/`y` are the layer's raw local Bodymovin position values, unmodified** — per "A second, separate
real problem" above, these still need the absolute-canvas compositing step resolved before they're
correct `.comics` values; this example shows the correct **keyframe-chaining shape** (one seed plus
N−1 segments, real irregular `start`/`end` spacing), not a claim that `436.12`/
`3449.613` etc. are final. The old v1.0 draft's decreasing ranges were incorrect for the real
`KeyframeInterpolator`; v1.1 intentionally normalizes them. `zDepth` is written as
a plain additional root-level key on the layer object, per `flows/tdd-dot-comics-format`'s own
additive-field convention — omitted entirely (not written as `0`) for a static layer, matching that
flow's "absent and explicit-0 are the same value" rule and keeping output byte-smaller for the ~70%
of layers that don't need it. **`cameraPath`** is written once, as a sibling of `layers`/`sounds` at
the document root (per "Reconstructed Camera-Path Element" above) — not per-layer.

The serialized output records the inferred values but no confidence score or causal/provenance
metadata tying a value to verified camera intent or physical depth. Those limitations remain
producer knowledge rather than format semantics.

### Open Design Questions

- [x] Absolute canvas position compositing — resolved by Plan Task 1.1 with full affine
      root/parent/layer composition plus exactly one document-scroll compensation; covered by an
      executable regression test.
- [x] Decreasing source pan vs. increasing `.comics` scroll — resolved in v1.1 by
      `position = panY(frameStart) - panY(rootFrame)`. This is required by the actual shared
      interpolator, not only a readability convention.
- [x] `K` constant — resolved as `1` by the approved canonical format contract.
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
- [x] `cameraPath` × `Layer.ZDepth` render composition — defined only by the current canonical
      `flows/tdd-dot-comics-format/03-specifications.md`; this importer derives/persists values and
      does not render or redefine the format contract.
- [x] Cross-flow schema adoption — approved in `tdd-dot-comics-format` v0.11/v0.8 and
      `sdd-flutter-comics` v0.4.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| A layer's own local keyframe range, once converted (`root_frame = st + local_frame`), falls partly or fully outside its scene's own pan `[frame_start, frame_end]` window | A layer whose local timeline extends before/after the pan's own span | The real example checked converts entirely inside the pan window (root frames 6791–7629 within `comp_0`'s `6252–12168`), so no extrapolation was needed there — but this isn't guaranteed for all ~120 animated layers across the 3 scenes. Where it does happen, linear extrapolation of `scroll_y` is mathematically well-defined but unverified against ground truth — same caveat as the absolute-position compositing question above |
| `camera_amplitude` (z-depth case 2) is 0 or near-0 (the camera-reference layer has ~0 displacement over the window being compared) | Degenerate/malformed input | Division-by-zero guard needed; fall back to `zDepth = 0.0` rather than crashing or producing `inf`/`NaN` |
| A layer has scale keyframes but they don't overlap the same frame range as its position keyframes (not observed in the one real example checked, but not ruled out across all ~120 animated layers in the 3 scenes) | Real possibility, not yet exhaustively checked | Case-1 formula (scale-based) still applies independent of position-keyframe timing — z-depth is derived from scale growth alone when scale is present, regardless of whether position keyframes align |
| Extrapolating `scroll_y(frame)` for a frame outside `[frame_start, frame_end]` (linear formula applied beyond its calibration range) | A layer's local keyframes span before/after the scene's own pan window | Mathematically well-defined (linear extrapolation), but not verified against any independent ground truth — disclosed as an approximation, not a confirmed-correct mapping |
| A scene has **no** animated layers at all (not observed — all 3 real scenes have real animated minorities — but not structurally guaranteed for other future Bodymovin sources this same module might process) | `select_camera_reference_layer` finds no candidates | Falls back to `cameraPath = [the trivial linear pan itself]` (still real, still correct, just not a "broken curve") — never crashes or omits the field entirely, since `zDepth`'s case-2 formula needs *some* reference to divide by |

### Testing Strategy

- [ ] Unit: `scene_pan`/`frame_to_scroll_y` against the 3 real, hand-verified pan tuples in
      Requirements' table
- [x] Unit: `to_translate_anim_keyframes` against the real 6-keyframe example layer, asserting
      exactly 6 output `TranslateAnim`s (seed + 5 segments) with the real Bodymovin `x`/`y` values and correctly-chained
      `start`/`end`
- [ ] Unit: `select_camera_reference_layer` against a synthetic scene with several candidate layers,
      asserting the scale+keyframe-count+displacement ranking picks the expected one; against the
      real `comp_0` data, asserting it picks the real `ind=43` layer specifically
- [x] Unit: `build_camera_path` preserves all N source coordinates as N canonical camera points
      (including the first), while `to_translate_anim_keyframes` produces N animations (seed + N−1 segments);
      both use the same normalized increasing scroll positions and verified absolute X/Y values
- [ ] Unit: `derive_z_depth` for all cases (scale-present, position-only, static, camera-reference-
      itself-pinned-to-0), including the division-by-zero guard
- [ ] Integration: run `import_bodymovin.py` against the real file end-to-end, assert the real
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

### v1.1 review gate

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-09
- [x] Notes: aligns this producer with the canonical format/shared-library contract, including
      increasing scroll positions, point-shaped `cameraPath`, and unitless `zDepth` math.
