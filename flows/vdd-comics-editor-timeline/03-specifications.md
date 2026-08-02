# Specifications: comics-editor-timeline

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-08-01
> Requirements: [01-requirements.md](01-requirements.md)
> Visual: [02-visual.md](02-visual.md)

## Investigation note before Specifications (read this first)

**RESOLVED (2026-08-02), correction added while this flow was superseded/parked — see the
"Current real-world state" section in `_status.md` for full context.** The unit-mismatch risk
described below turned out to be a non-issue, resolved definitively (not empirically, and not by
this flow's own Implementation, which never happened here) by reading
`legacy/comics-editor-v2.8/Comics.Editor/Models/Layer.cs`'s `Create` method and `Anim.cs`'s
`FindNearest`/`Add` directly, during the sibling flow `vdd-comics-editor-vertical-scroll`'s
Requirements work:

- `Anim.Start`/`End` are in the **exact same raw-pixel coordinate space** as `scroll` — there is no
  scale factor, and never was one to find. A keyframe range only needs to span the short window
  (~200px, per `Anim.Add<T>`'s own authoring convention) during which one specific transition
  actively plays.
- Once scroll passes a layer's last keyframe, `Interpolate<T>` just holds that value **unchanged**
  for the rest of the document, however tall (16,300–100,900px in real files) — there's nothing to
  "cover" with a range spanning the full height.
- The small numbers observed in real files (~48–6000) aren't scaled-down positions; they're
  literally raw scroll pixels, mostly clustered near the top of the document because that's where
  most authored transitions happen to occur.
- `currentTime = raw pan offset in document pixels`, no conversion, is correct — confirmed by
  reading the exact authoring code that produced those numbers, not by an empirical test.

The original (now-superseded) note is preserved below for history, but should not be treated as
current:

> Before writing interfaces, I tried to pin down the exact legacy unit relationship between
> `canvasViewport`'s pan position and the real `Anim.start`/`end` values already sitting in saved
> `.comics` files... [original investigation found real files' values small (~48-6000) vs. document
> heights large (16,300-100,900+), could not reconcile two Android `Comics.process()` call sites'
> apparent unit spaces from static reading alone, and deferred to an empirical test during
> Implementation as "the single biggest risk in this spec."] This risk is now closed — see above.

## Overview

Implements Option A1 (approved): canvas pan position (`EditorController.canvasViewport`) becomes
the single source of truth for animation time. The independently-draggable `playhead`/Timeline
scrub is retired. A new interpolation engine — a Dart port of the real, shipping
`libs/comics_viewer/comics-viewer-android` position-driven keyframe logic — is wired into the
editor's canvas so `Anim` keyframes (`translate`/`scale`/`rotate`/`alpha`) finally drive live
preview, matching what real readers already see today. A device visibility overlay (Should Have)
is added to the same position indicator. Time-driven-while-in-range (idle-loop) animation and
sound triggering are explicitly out of scope (see Requirements' Won't Have) — confirmed missing
in real production code too, not just here, and are novel design work for a separate flow.

**End-user model, confirmed by Anton (2026-08-01)**: the real viewer is a press-and-hold,
finger-attached vertical drag -- the content moves 1:1 with the touch point, up or down, revealing
new objects below or previously-drawn ones above. There is no separate scroll physics/abstraction
layer between the gesture and content position, and -- critically -- **no built-in concept of
scene or screen boundaries at all**: it's one continuous strip, not a sequence of pages. Two
consequences for this spec: (1) it directly confirms pan position as the correct, unmediated
source of truth for `currentTime` -- same shape as v2.8's `ScrollViewer.VerticalOffset` and today's
`canvasViewport`, no separate physics to reconcile; (2) it sharpens *why* the device visibility
overlay (Should Have, see Data Models/`DeviceProfile`) is needed at all -- since the content format
itself has no notion of "what fits on one screen," the overlay's guide marks aren't reflecting
something already in the data, they're manufacturing a reference that doesn't otherwise exist.

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `apps/comics-editor/lib/src/ui/controller.dart` | Modify | Remove `playhead`/`setPlayhead`/`totalFrames` as an independent scrub value; add a pan-derived `currentTime` getter; no more `Anim.start` stamped from `playhead` when authoring (Task-level detail, see Interfaces) |
| `apps/comics-editor/lib/src/ui/anim/keyframe_interpolator.dart` (new) | Create | Dart port of `LayerAnim`/`TranslateAnim`/`ScaleAnim`/`RotateAnim`/`AlphaAnim` — keyframe lookup + cubic ease-out + per-property lerp |
| `apps/comics-editor/lib/src/ui/widgets/canvas_view.dart` | Modify | `_LayerItem` renders the *interpolated* transform when a layer has matching-type `Anim`s, falling back to today's static `l.translate`/identity scale/rotate/alpha otherwise |
| `apps/comics-editor/lib/src/ui/widgets/timeline.dart` | Modify/Delete | Retired as an independent scrubber; replaced by a position indicator (see `02-visual.md`) |
| `apps/comics-editor/lib/src/ui/widgets/position_indicator.dart` (new) | Create | A1's read-only (or pan-driving-if-dragged) position strip, plus the device visibility overlay |
| `apps/comics-editor/lib/src/ui/device_profile.dart` (new) | Create | Small, fixed built-in device profile list (name + aspect ratio) for the visibility overlay — not part of `.comics` schema |
| `native/Comics.Editor/*`, mobile viewer, `data.json` schema | Unmodified | No schema change; no C#/Android/mobile-viewer changes — this flow is Flutter-editor-only, per Requirements' Won't Have |

## Architecture

### Component Diagram

```
                    canvasViewport (TransformationController, existing)
                              |
                    pan position (dy, document px)
                              |
                    currentTime = f(pan)  <-- Data Flow section: formula + open risk
                              |
              +---------------+----------------+
              |                                |
   KeyframeInterpolator (new)          PositionIndicator (new)
   per layer, per property type        read-only strip + device
   (translate/scale/rotate/alpha)      visibility overlay
              |
   effective transform per layer
              |
      canvas_view.dart's _LayerItem (modified: renders interpolated
      transform instead of static l.translate when Anims exist)
```

### Data Flow — pan to rendered transform

```
User pans the canvas (drag / trackpad scroll -- never the mouse wheel, which zooms; see 02-visual.md)
  -> canvasViewport.value changes
  -> currentTime = canvasViewport's vertical pan offset, in document pixels
     (SAME formula/units as EditorLayer.translate.dy already uses -- NOT scaled to the small
     0-6000 range real Anim.start/end values were found in; see Investigation Note and Open
     Design Questions for why this is flagged, not asserted, as the final answer)
  -> for each visible layer L, for each property P in {translate, scale, rotate, alpha}:
       anims = L.anims.where((a) => a.type == P).sortedBy(start)
       if anims.isEmpty: use L's existing default (l.translate for translate; identity
         scale=1/rotate=0/alpha=1 otherwise) -- unchanged from today, no behavior change for
         non-animated layers
       else:
         (prev, next) = the keyframe pair surrounding currentTime (before first -> clamp to
           first; after last -> clamp to last -- mirrors LayerAnim.java's fraction clamp(0,1))
         fraction = clamp((currentTime - next.start) / (next.end - next.start), 0, 1)
         eased = cubicEaseOut(fraction)   // (f-1)^3 + 1, LayerAnim.java:16
         value = lerp(prev's value, next's value, eased)
  -> canvas_view.dart's _LayerItem renders using these computed values instead of the static
     l.translate / implicit identity scale/rotate/alpha
```

## Interfaces

### New Interfaces

```dart
// lib/src/ui/anim/keyframe_interpolator.dart
/// Dart port of libs/comics_viewer/comics-viewer-android's LayerAnim/TranslateAnim/ScaleAnim/
/// RotateAnim/AlphaAnim (Layer.java:118-143, LayerAnim.java:8-17) -- same keyframe-lookup +
/// cubic-ease-out + lerp shape, so the editor's live preview matches what real readers already
/// see via that library.
class KeyframeInterpolator {
  /// Returns the interpolated Offset for AnimType.translate keyframes in [anims] (already
  /// filtered to one layer, may include non-translate anims -- this filters internally) at
  /// [currentTime]. Returns [fallback] (the layer's static `translate`) if there are no
  /// translate-type anims at all.
  static Offset translateAt(List<Anim> anims, double currentTime, Offset fallback);

  /// Returns (scaleX, scaleY, pivotX, pivotY) for AnimType.scale keyframes, or (1,1,0,0) if none.
  static (double, double, double, double) scaleAt(List<Anim> anims, double currentTime);

  /// Returns (angle, pivotX, pivotY) for AnimType.rotate keyframes, or (0,0,0) if none.
  static (double, double, double) rotateAt(List<Anim> anims, double currentTime);

  /// Returns alpha for AnimType.alpha keyframes, or 1.0 if none.
  static double alphaAt(List<Anim> anims, double currentTime);

  /// Shared keyframe-pair lookup + cubic ease-out fraction, used by all four methods above --
  /// mirrors LayerAnim.java's shared base logic instead of duplicating it four times.
  static double _easedFraction(List<Anim> sortedAnimsOfOneType, double currentTime);
}
```

```dart
// lib/src/ui/controller.dart -- modified
class EditorController {
  // REMOVED: int playhead, void setPlayhead(int), final int totalFrames.
  // (Anim.start/end are no longer stamped from an abstract 0..600 frame value when authoring --
  // see Open Design Questions for what a newly-authored Anim's start/end should be stamped with
  // instead, since that also depends on resolving the units question.)

  /// The single source of truth for "time" everywhond that reads Anim keyframes -- derived from
  /// canvasViewport's current pan offset, never independently settable.
  double get currentTime => /* see Data Flow */;
}
```

```dart
// lib/src/ui/device_profile.dart (new)
/// Fixed, built-in list for v1 (Should Have) -- not user-editable, not part of .comics schema.
class DeviceProfile {
  const DeviceProfile(this.name, this.aspectRatio); // aspectRatio = height/width
  final String name;
  final double aspectRatio;

  static const iPad = DeviceProfile('iPad', 4 / 3);
  static const iPhone = DeviceProfile('iPhone', 19.5 / 9);
  static const all = [iPad, iPhone];

  /// One screenful of document height, in document px, for a document of [docWidth].
  double screenfulHeight(double docWidth) => docWidth * aspectRatio;
}
```

### Modified Interfaces

- `canvas_view.dart`'s `_LayerItem.build` — currently reads `l.translate` directly
  (`canvas_view.dart:139-140`) and has no scale/rotate/alpha rendering at all for layers (the
  swatch is a fixed size/color, per Specifications Finding 3 from `vdd-comics-editor-ai-uiux` —
  still true, unrelated flow, unaffected by this one). This flow adds interpolated
  translate/scale/rotate/alpha application on top of the existing swatch rendering — **it does
  not** add real-pixel image rendering (that remains a separate, pre-existing limitation, not
  this flow's problem to fix).
- `addAnim`/sound-adding helpers in `controller.dart` (lines ~940-945 per earlier citation) that
  currently stamp `Anim.start = playhead` need a replacement source for a newly-authored anim's
  initial `start`/`end` — see Open Design Questions.

## Data Models

No `.comics`/`data.json` schema changes. `Anim`'s existing fields (`start`, `end`, `type`, plus
per-type `x`/`y`/`scaleX`/`scaleY`/`pivotX`/`pivotY`/`angle`/`alpha`) are sufficient — this flow
changes what *drives* the interpolation input, not the keyframe data shape itself.

`DeviceProfile` is new, app-level, hardcoded (not persisted, not per-document) — see Interfaces.

## Behavior Specifications

### Happy Path

1. Corrector opens a `.comics` document with a layer that has real `translate` and `alpha` `Anim`
   keyframes (previously inert).
2. Corrector pans the canvas (drag or two-finger trackpad scroll).
3. `currentTime` updates from the new pan position.
4. The layer's rendered swatch position and opacity update to match the interpolated keyframe
   values — for the first time, live, in the editor.
5. Corrector continues panning past the last keyframe's `end` — the layer holds at its final
   keyframe value (clamped), matching `LayerAnim.java`'s fraction clamp behavior.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| Layer has no `Anim`s of a given type at all | Most layers, most properties, today | Falls back to existing static behavior (`l.translate` for translate; identity 1/0/1 for scale/rotate/alpha) — **no behavior change** for the common case |
| Pan position before the first keyframe's `start` | Scrolled above where an animation begins | Clamp to the first keyframe's own value (fraction=0), not extrapolated |
| Pan position after the last keyframe's `end` | Scrolled past where an animation ends | Clamp to the last keyframe's own value (fraction=1) |
| `Anim.start == Anim.end` (a "point," valid for `SoundAnim` per v2.8) on a visual property | Legacy or malformed data | Treat as an instant step at that point (fraction undefined below/above, defined as 0 before and 1 at/after) — needs a divide-by-zero guard in `_easedFraction`, unlike Sound's own point semantics which don't use `Factor` at all |
| A real, previously-never-visually-verified document is opened for the first time after this ships | Any existing `.comics` file with real `Anim` data | Its layers may suddenly animate in ways nobody has seen or tuned, since the authoring tool never rendered them before — **a real, disclosed behavior change**, not a bug; flagged in Migration/Rollout |
| Multiple layers with independent, overlapping `Anim` ranges | Normal multi-layer authoring | Each layer's interpolation is independent — no cross-layer coupling, matching both reference implementations |

### Error Handling

| Error | Cause | Response |
|-------|-------|----------|
| `next.end - next.start == 0` in `_easedFraction` | Malformed or point-style Anim data on a visual property | Guarded explicitly (see Edge Cases), not a crash |
| `canvasViewport` not yet laid out (e.g. very first frame) | Widget lifecycle timing | `currentTime` should have a sane default (0) rather than reading an uninitialized transform |

## Dependencies

### Requires

- Approved Option A1 (`01-requirements.md`, `02-visual.md`) — done.
- `libs/comics_viewer/comics-viewer-android`'s `LayerAnim`/`TranslateAnim`/`ScaleAnim`/
  `RotateAnim`/`AlphaAnim` as the reference implementation to port — read, not modified.

### Blocks

- Nothing outside this flow. The idle-loop/sound-triggering follow-on flow depends on this flow's
  `KeyframeInterpolator` existing as a foundation, but isn't blocked from being scoped in parallel.

## Integration Points

### External Systems

None — this is Flutter-editor-internal work. No mobile viewer, no backend.

### Internal Systems

- `lib/src/ui/controller.dart`, `lib/src/ui/widgets/{canvas_view,timeline}.dart` (modify), new
  `lib/src/ui/anim/keyframe_interpolator.dart`, `lib/src/ui/widgets/position_indicator.dart`,
  `lib/src/ui/device_profile.dart`.

## Testing Strategy

### Unit Tests

- [ ] `KeyframeInterpolator`: cubic ease-out formula matches `LayerAnim.java:16`'s
      `(f-1)^3 + 1` exactly, for known fraction inputs
- [ ] Keyframe-pair lookup: before-first-keyframe clamp, after-last-keyframe clamp, exact-boundary
      values, multiple overlapping ranges
- [ ] `Anim.start == Anim.end` point case doesn't divide by zero
- [ ] No-anims-of-this-type fallback returns the documented default (static translate / identity
      scale-rotate-alpha) unchanged from today's behavior
- [ ] `DeviceProfile.screenfulHeight` matches the worked example from `01-requirements.md`
      (≈1440 doc-px for iPad, ≈2344 for iPhone, at `docWidth=1080`)

### Integration Tests

- [x] **RESOLVED, and actually done** — not by this flow (which never reached Implementation), but
      by `vdd-comics-editor-vertical-scroll`'s Task 5.1: opened a real `.comics` file
      (`dataset/boranko/mahabharata/book1/comics_interactive/8a89f7d689fb441ea280cd782276bd7a.comics`),
      hand-derived expected `KeyframeInterpolator` output from its actual `TranslateAnim` data at
      four real scroll positions, and confirmed an exact match (after fixing an unrelated stable-sort
      bug the real data exposed). See that flow's `05-implementation-log.md`, Task 5.1.
- [ ] Full pan-through of a multi-layer, multi-anim-type real document, confirming no crash and
      independent per-layer behavior

### Manual Verification

- [ ] Author a new translate+alpha animation on a layer in the running editor, pan through it,
      visually confirm it slides/fades as expected
- [ ] Open several real `dataset/` files (read-only, copies) and visually sanity-check that their
      previously-inert animations now look intentional, not chaotic (the units question itself is
      resolved — this check is now about authoring quality, not a units go/no-go)

## Migration / Rollout

No data migration. The real behavior change to disclose: existing documents' previously-inert
`Anim` keyframes will start actually rendering once this ships. The units-question risk that this
section originally hedged against is closed (see Investigation Note) — `vdd-comics-editor-vertical-
scroll` shipped this live with no opt-in toggle, exactly as this section anticipated it would if the
integration test passed.

## Open Design Questions

- [x] What should a newly-authored `Anim`'s initial `start`/`end` be stamped with, now that
      `playhead` no longer exists? **Decided here: the current `currentTime` value directly.**
      **What actually shipped** (`vdd-comics-editor-vertical-scroll`): the same answer, `currentTime`
      — consistent.
- [x] Does the old `Timeline` widget get deleted outright, or kept (dead code, disabled) as a
      reference during the transition? **Decided here: delete outright.**
      **⚠️ What actually shipped disagrees**: in `vdd-comics-editor-vertical-scroll`, Anton
      explicitly said to leave `timeline.dart` untouched ("текущий timeline не трогай, с ним
      разберемся позже") — it was NOT deleted, and now renders newly-authored keyframes off-scale
      (still reads/writes the old `playhead`/`totalFrames` 0..600 system, disconnected from the real
      `currentTime` the interpolation engine uses). **This is a real, unresolved contradiction
      between this flow's own decision and what was later decided in the sibling flow — flagged for
      discussion, not silently picked one way.**
- [x] `DeviceProfile`'s fixed built-in list (iPad, iPhone) — worth making user-extensible in v1, or
      genuinely fine hardcoded for now? **Decided here: hardcoded for v1.**
      **What actually shipped**: nothing — `vdd-comics-editor-vertical-scroll` explicitly excluded
      `DeviceProfile`/the device-visibility overlay as "not part of legacy's actual behavior," per
      Anton's "don't rely on ideas from there" instruction for that flow. **This feature has not
      been built anywhere** — it remains real, wanted (per Requirements' Should Have), unbuilt work.
- [x] Should real documents' newly-live animations be gated behind an opt-in toggle for the first
      release, or shipped live immediately? **Decided here: shipped live, no toggle.**
      **What actually shipped**: the same — consistent (no toggle exists in
      `vdd-comics-editor-vertical-scroll`'s implementation either).

All four Open Design Questions are now resolved in fact (via the sibling flow's real
implementation), not just in judgment — see `_status.md`'s "Current real-world state" section for
the reconciliation and what's genuinely still open (the Timeline contradiction and the unbuilt
device overlay).

---

## Approval

- [ ] Reviewed by:
- [ ] Approved on:
- [ ] Notes:
