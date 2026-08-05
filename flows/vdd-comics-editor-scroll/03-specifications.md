# Specifications: comics-editor-scroll

> Version: 1.2
> Status: APPROVED
> Last Updated: 2026-08-05
> Requirements: [01-requirements.md](01-requirements.md)
> Visual: [02-visual.md](02-visual.md)

## Overview

Ports `legacy/comics-editor-v2.8`'s scroll-as-time model into `apps/comics-editor` (Flutter),
one-to-one for the interpolation math and sound-gating, with one deliberate deviation (a
responsive viewport instead of v2.8's hardcoded `ratio=1.4`) and one deferred item (`timeline.dart`
untouched). Three real subsystems change: (1) `canvas_view.dart`'s canvas layout, from
fit-whole-document to a responsive scrolling window; (2) a new `KeyframeInterpolator`, a faithful
Dart port of `Anim.cs`'s `FindNearest`/`Factor`/`Interpolate`, wired into layer rendering; (3) a new
sound-playback path, porting `SoundAnim.FindCurrent`'s point/range gating onto a real audio
package. A fourth, smaller fix corrects a pre-existing JSON round-trip default that would otherwise
misinterpret real files' legacy-authored seed keyframes once interpolation goes live (found during
this Specifications pass — see Data Models).

The shipped implementation is intentionally the Vertical-scroll comic strip specialization. The
axis contract below documents how it remains compatible with a separately scoped future
Horizontal-scroll comic strip without prematurely adding that mode.

## Scroll Axis Contract

| Concern | Current/default: Vertical-scroll | Future: Horizontal-scroll |
|---|---|---|
| Availability | Enabled and implemented | Visible but disabled; not implemented here |
| Main document extent | `document.height` | `document.width` |
| Cross-axis fit | Fit page width to viewport width | Fit page height to viewport height |
| Viewport translation used | `translation.y` | `translation.x` |
| Logical progress | `-translation.y / zoom` | `-translation.x / zoom` |
| Viewer position selector | Right edge, top → bottom | Bottom edge, left → right |
| Default device preview | Portrait | To be decided independently |

`currentTime` is the logical, non-negative document-scroll position consumed by keyframe and sound
evaluation. Keyframe data is not duplicated by axis and `TranslateAnim.x/y` remains a full 2D
render transform in both modes. Only the mapping from viewport movement to logical progress changes.

The future persisted model must use an explicit scroll-type value. Missing values map to vertical
for backward compatibility. Implementations must not infer a scroll type from document aspect ratio
or portrait/landscape orientation. Device orientation and comic-strip direction are orthogonal.

Version 1.1 does not add that field or generalize production code: current `DocType.comics`,
fit-width sizing, Y-derived `currentTime`, and the right-edge Viewer selector remain the correct
vertical specialization. Horizontal behavior requires its own approved implementation flow.

## Target Device and Visible Range

The device-visibility concept formerly placed in `vdd-comics-editor-timeline` belongs here because
it maps scroll position to a reader viewport. Version 1.2 uses one selected target instead of the
timeline proposal's simultaneous guide rows.

```dart
class DeviceProfile {
  const DeviceProfile({
    required this.id,
    required this.label,
    required this.width,
    required this.height,
  });

  final String id;
  final String label;
  final int width;
  final int height;

  double verticalViewportHeight(double documentWidth) =>
      documentWidth * height / width;

  static const iPad = DeviceProfile(
    id: 'ipad', label: 'iPad', width: 768, height: 1024);
  static const iPhone = DeviceProfile(
    id: 'iphone', label: 'iPhone', width: 390, height: 844);
}
```

- `PropertiesTab` order is `selection`, `document`, `general`.
- General owns the target-device chooser, dimensions, aspect ratio, and calculated visible strip
  height. iPad is the app-session default.
- Selection is editor UI state only: it is not inferred from the host window and not serialized.
- Viewer centers and fits its renderer inside `device.width / device.height`; excess host space is
  letterboxed. This makes backend normalized travel and the selected-device band describe the same
  viewport rather than the desktop window.
- For vertical documents, `extent = clamp(deviceViewportHeight / document.height, 0, 1)`.
- Viewer backend `position` remains normalized over available scroll travel. Therefore the band is
  `start = position × (1 − extent)`, `end = start + extent`.
- A tap/drag centers the band at the pointer, clamps `start` to `0…1−extent`, and maps back to
  backend position with `position = start / (1−extent)`.
- If the device viewport covers the whole document, the band spans `0…100%` and cannot scroll.
- Semantics expose `Viewer visible range`, target name, current start/end, and next values for
  increment/decrement actions.

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `apps/comics-editor/lib/src/ui/widgets/canvas_view.dart` | Modify | `_Stage`/`_Page` layout: fit-width + real proportional height instead of fit-whole-document (Requirements Gap 2) |
| `apps/comics-editor/lib/src/ui/controller.dart` | Modify | `playhead` removed as an independent field; a `currentTime` getter derived from `canvasViewport`'s pan position replaces it; `addAnim`/`addSound` read from it instead |
| `apps/comics-editor/lib/src/ui/anim/keyframe_interpolator.dart` (new) | Create | Dart port of `Anim.cs`'s `FindNearest<T>`/`Factor`/`Interpolate<T>`, one function per `AnimType` |
| `apps/comics-editor/lib/src/ui/audio/sound_player.dart` (new) | Create | Wraps a new audio-playback package; ports `SoundAnim.FindCurrent`'s point/range, direction-sensitive gating |
| `apps/comics-editor/lib/src/ui/device_profile.dart` (new) | Create | App-level iPad/iPhone target dimensions and vertical screenful math |
| `apps/comics-editor/lib/src/ui/widgets/properties_panel.dart` | Modify | Add General after Selection/Document and expose the target viewport |
| `apps/comics-editor/lib/src/ui/widgets/viewer_workspace.dart` | Modify | Fit the renderer to the selected target ratio and replace point thumb with its viewport band |
| `apps/comics-editor/lib/src/ui/models.dart` | Modify | `Anim`'s constructor default `end: 200` → `end: 0` (only affects the one bare-default call site, see Data Models) |
| `apps/comics-editor/lib/src/bridge/models_mapping.dart` | Modify | `_animFromJson`'s absent-`end` fallback and `_animToJson`'s omit-comparison both move from `200` to `0`, kept in sync (see Data Models — this is the more consequential half of the fix) |
| `apps/comics-editor/pubspec.yaml` | Modify | New audio-playback dependency (see Dependencies) |
| `apps/comics-editor/lib/src/ui/widgets/timeline.dart` | **Unmodified** | Explicitly deferred per Anton — reads/writes `Anim.start`/`end` the same way; only what feeds `currentTime` changes underneath it |
| `legacy/comics-editor-v2.8`, mobile viewer, `.comics` schema | Unmodified | Reference/source of truth only; no schema changes — see Data Models |

## Architecture

### Component Diagram

```
   canvasViewport (TransformationController, existing)
             |
   pan position (Matrix4 translation, screen px, at current zoom)
             |
   currentTime = pan position converted to real document px
   (see Data Flow -- replaces `playhead` entirely)
             |
   +---------+----------------------------+
   |                                       |
KeyframeInterpolator (new)          SoundPlayer (new)
per layer, per AnimType             per EditorSound, gates a real
(translate/rotate/scale/alpha)      audio package's play/loop/stop
   |                                       |
effective layer transform          real audio playback
   |
canvas_view.dart's _LayerItem
(modified: renders interpolated
transform instead of static
l.translate/identity scale-rotate-alpha)
```

### Data Flow

```
User pans the canvas (drag / trackpad-scroll -- confirmed pan gesture, not mouse-wheel zoom)
  -> canvasViewport.value (a Matrix4) changes
  -> currentTime = translationY-component of canvasViewport.value, converted from screen px
     back to real document px by dividing out both the render scale `k` (page-space -> px,
     canvas_view.dart's existing `k = pageW / doc.width`) and canvasViewport's own zoom factor
     (`canvasViewport.value.getMaxScaleOnAxis()`) -- i.e. currentTime must be invariant to zoom
     level, exactly like legacy's ScrollViewer.VerticalOffset is invariant to the outer Viewbox's
     display scaling (Requirements, Major Finding point 2). Sign/exact derivation to be pinned down
     empirically against a real pan gesture during Implementation (Matrix4 translation sign
     conventions are easy to get backwards) -- flagged in Testing Strategy, not guessed here.
  -> for each visible layer L, for each AnimType in {translate, rotate, scale, alpha}:
       anims = L.anims.where((a) => a.type == type).sortedBy(start)
       (prev, curr) = KeyframeInterpolator's port of FindNearest (see Interfaces)
       if curr == null: use prev's value verbatim (or the type's resting default if prev is also
         absent) -- NO computation, matching legacy exactly
       else: value = lerp(prev's value, curr's value, cubicEaseOut(curr.Factor(currentTime)))
  -> canvas_view.dart's _LayerItem renders using these computed values
  -> for each EditorSound: SoundPlayer.evaluate(sound.anims, prevTime, currentTime) -> play/loop/stop
     on the chosen audio package, per legacy's exact point-vs-range, direction-sensitive rules
```

## Interfaces

### New Interfaces

```dart
// lib/src/ui/anim/keyframe_interpolator.dart
/// Faithful Dart port of legacy/comics-editor-v2.8/Comics.Editor/Models/Anim.cs's
/// FindNearest<T>/Factor/Interpolate<T> (see 01-requirements.md, Major Finding points 6-8).
/// One function per visual AnimType; each returns the type's own value shape and resting default
/// when no anim of that type exists yet.
class KeyframeInterpolator {
  /// AnimType.translate. Falls back to [fallback] (the layer's static `translate`) if the layer
  /// has no translate-type anims at all -- unchanged current behavior for that common case.
  static Offset translateAt(List<Anim> anims, double currentTime, Offset fallback);

  /// AnimType.scale. Falls back to (1, 1) -- ScaleAnim.Init()'s resting default.
  static (double scaleX, double scaleY, double pivotX, double pivotY) scaleAt(
      List<Anim> anims, double currentTime);

  /// AnimType.rotate. Falls back to (0, pivot 0.5/0.5) -- RotateAnim's C# default + PivotAnim.Init().
  static (double angle, double pivotX, double pivotY) rotateAt(
      List<Anim> anims, double currentTime);

  /// AnimType.alpha. Falls back to 1.0 -- AlphaAnim.Init()'s resting default.
  static double alphaAt(List<Anim> anims, double currentTime);

  /// Shared with all four above -- Anim.cs's FindNearest<T>: walks [animsOfOneType] (already
  /// filtered + sorted by start), returns (prev, curr) exactly per Requirements point 6, including
  /// the "prev stays null, curr null too, use resting default" case.
  static (Anim? prev, Anim? curr) _findNearest(List<Anim> animsOfOneType, double currentTime);

  /// Anim.cs's Factor: t = (currentTime - curr.start) / (curr.end - curr.start); cubic ease-out
  /// (t-1)^3+1. Guarded against curr.end == curr.start (legacy never hits this given how Add<T>
  /// seeds End = Start + 200, but real/hand-edited data could) -- returns 1.0 (treat as "reached")
  /// rather than dividing by zero.
  static double _factor(Anim curr, double currentTime);
}
```

```dart
// lib/src/ui/audio/sound_player.dart
/// Faithful port of SoundAnim.FindCurrent (legacy Models/SoundAnim.cs:22-24) +
/// SoundViewModel.Scroll (ViewModel/SoundViewModel.cs:124-137) gating logic, wired to a real
/// audio-playback package (see Dependencies) instead of WPF's MediaPlayer.
class SoundPlayer {
  SoundPlayer(this.filePath);
  final String filePath;

  /// Call once per currentTime change (mirrors ComicsViewModel.Scroll's per-tick sound.Scroll()
  /// call). [prevTime] is the currentTime from the previous call -- needed for point-trigger
  /// direction-sensitivity (Requirements point 11: only plays crossing DOWNWARD through a point).
  void evaluate(List<Anim> soundAnims, double prevTime, double currentTime);

  void dispose();
}
```

```dart
// lib/src/ui/controller.dart -- modified
class EditorController {
  // AMENDED DURING IMPLEMENTATION (2026-08-02, disclosed in 05-implementation-log.md): this
  // originally said `playhead`/`setPlayhead`/`totalFrames` would be REMOVED. Implementation found
  // `timeline.dart` deeply dependent on them as a closed 0..600 coordinate system (bar widths,
  // thumb position) -- not an incidental reference. Given Anton's "leave timeline.dart alone,"
  // removing them would have broken that widget. Asked Anton directly: he confirmed `addAnim`/
  // `addSound` should still switch fully to `currentTime` (below), accepting that `timeline.dart`
  // will render newly-authored keyframes off-scale until its own later redesign. Resolution:
  // `playhead`/`setPlayhead`/`totalFrames` are KEPT, untouched, fully vestigial outside
  // `timeline.dart` itself; `currentTime` is a new, separate, additional getter.

  /// The single source of truth for "time" for the interpolation engine and newly-authored
  /// keyframes -- derived from canvasViewport's pan position, in real document pixels, invariant
  /// to zoom (see Data Flow). Never independently settable; `addAnim`/`addSound` read this instead
  /// of `playhead`, which remains a separate, now-vestigial field `timeline.dart` alone still uses.
  double get currentTime => /* see Data Flow */;
}
```

### Modified Interfaces

- `canvas_view.dart`'s `_Stage.build` (lines 37-51): replace `pageH = maxH; pageW = pageH * aspect`
  (fit-whole-document) with `pageW = maxW; pageH = pageW / aspect` (fit-width, real proportional
  height) -- for a real document this makes `pageH` far taller than the available viewport, which
  is the point: `InteractiveViewer`'s existing pan (already wired to `canvasViewport`) now has real
  vertical distance to scroll through, matching legacy's `ScrollViewer` scrolling through a
  full-height `Grid`. `boundaryMargin` (currently `EdgeInsets.all(200)`, line 57) needs revisiting
  so panning isn't artificially clamped before reaching the document's true bottom -- an
  Implementation-time tuning task, not a design change.
- `addAnim`/`addSound` (`controller.dart:940-945,963-974`): `start: playhead` → `start:
  currentTime.round()`; otherwise unchanged (the `end = start + 200` shape already matches legacy).

## Data Models

No `.comics`/`data.json` schema changes -- `Anim`'s existing fields are sufficient (Requirements
already established this). **One real, pre-existing bug found during this Specifications pass**,
more consequential than Requirements' framing suggested:

- `models_mapping.dart:68`'s `_animFromJson` currently parses an **absent** `end` key as `200`
  (`_asInt(json['end'], 200)`). But legacy's Newtonsoft serializer omits `end` from JSON *whenever
  its true value is C#'s int default, `0`* (`DefaultValueHandling.Ignore` compares against
  `default(int)`) -- and per Requirements point 9, `Layer.Create`'s seed `TranslateAnim` is
  *exactly* this case (`Start`/`End` both left at their implicit `0`). **So every real, existing
  `.comics` file's legacy-authored seed keyframe -- likely most layers in most real documents --
  currently loads into Flutter with `end` silently misread as `200` instead of the true `0`.** This
  has been harmless so far only because nothing evaluates `Anim` keyframes yet (today's Gap 1) --
  once `KeyframeInterpolator` goes live, this bug would make every legacy-authored layer's resting
  position render as a 200px slide-in instead of instant placement, for real existing documents,
  not just newly-created layers. Requirements' Acceptance Criterion 5 already approved "fix to
  match exactly" for the *newly-created-layer* case; this generalizes that same fix to the
  *read path*, which is the one that actually matters for existing content.
- **The fix must touch two places together, kept in sync** (per the existing code comment at
  `models_mapping.dart:102-110`, which already explains why these two constants must match to
  avoid silently drifting saved files): `_animFromJson`'s fallback (`200` → `0`) and
  `_animToJson`'s omit-comparison (`put('end', anim.end, 200)` → `... , 0)`, line 111). Changing
  only one would either misread real files' true `end=0` as `200` (today's bug, reading) or write
  spurious explicit `end` values onto every re-saved animation that never had one (the exact bug
  that comment's own prior fix already prevented, if only the write side changes).
- `models.dart:100`'s `EditorLayer` constructor (`Anim(AnimType.translate)..y = translate.dy`) then
  naturally gets `end: 0` once the class default changes, no separate fix needed there.
- Confirmed via `grep` that no other call site in `lib/` relies on `Anim`'s bare/implicit default
  (`controller.dart`'s `addAnim`/`addSound`/demo-seed-data all pass `start`/`end` explicitly) --
  this is a fully localized, three-spot fix.

## Behavior Specifications

### Happy Path

1. Author opens a real `.comics` document. Canvas shows one responsive-sized window into the
   document's top, not the whole thing shrunk to fit.
2. Author drags/trackpad-scrolls down. `currentTime` increases. Layers with translate/scale/
   rotate/alpha keyframes in that range visibly interpolate; layers without simply sit at their
   (now correctly `end:0`-seeded) resting position, unchanged from before.
3. A sound cue's range is entered -- real audio starts looping; exiting the range stops it
   immediately, matching legacy exactly.
4. Author scrolls back up past a point-trigger sound cue -- it does not replay (direction-sensitive,
   matching `SoundAnim.FindCurrent`).

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| Layer has no anims of a given type | Most layers, most properties | Resting default (unchanged behavior) -- `translate` falls back to the layer's static field, others to their type's identity default |
| `curr.end == curr.start` on a real anim | Malformed/hand-edited data (legacy's own `Add<T>` never produces this) | `_factor` returns `1.0` rather than dividing by zero -- treated as "reached," not a crash |
| Document taller than any practical zoom-out | Every real document (16,300-100,900px) | Fit-width sizing plus real pan is the whole point -- no special-casing needed, `InteractiveViewer` already supports arbitrarily tall children given the right `boundaryMargin` |
| A previously-saved real file's seed keyframes | Any existing `.comics` file | Once the `models_mapping.dart` fix ships, these correctly render as instant placement, not a 200px slide-in -- a real, disclosed behavior *correction* (fixing a latent bug), not a regression |
| Sound cue with `Start == End` (point) vs. real range | Author-created via `addSound` (always creates `end = start + 200`, a range) vs. legacy files that may have real `Start==End` points | Point semantics (play-once, direction-sensitive) only trigger for genuine `Start==End`; `SoundPlayer` must implement both branches, not just the range case, since real legacy files may contain point-triggers even though today's Flutter authoring UI only ever creates ranges |

### Error Handling

| Error | Cause | Response |
|-------|-------|----------|
| Audio file referenced by an `EditorSound` is missing/corrupt | Broken document, moved asset | `SoundPlayer` catches the playback package's own error, logs, does not crash the canvas render loop |
| `canvasViewport` not yet laid out | First frame | `currentTime` defaults to `0` (top of document), matching legacy's initial `Scroll = 0` |

## Dependencies

### Requires

- Approved `01-requirements.md` (v0.2) and `02-visual.md` (v1.0) -- done.
- A new audio-playback package. Recommending **`audioplayers`** (actively maintained, supports all
  five platforms this app already targets -- `android/ios/linux/macos/windows`, confirmed present
  in `apps/comics-editor/`) over alternatives with weaker desktop-platform support -- final version
  pin is a Plan-time detail, not a Specifications decision.

### Blocks

- Nothing outside this flow. A future `timeline.dart` redesign (explicitly deferred) would consume
  `currentTime`/`KeyframeInterpolator` as a foundation but isn't blocked from being scoped
  separately.

## Integration Points

### External Systems

- The new audio-playback package (platform-native audio APIs underneath it) -- otherwise none;
  this remains Flutter-editor-internal, no mobile-viewer or backend changes.

### Internal Systems

- `canvas_view.dart`, `controller.dart`, `models.dart`, `models_mapping.dart` (modify); new
  `anim/keyframe_interpolator.dart`, `audio/sound_player.dart`; `pubspec.yaml` (new dependency).
  `timeline.dart` explicitly untouched.

## Testing Strategy

### Unit Tests

- [ ] `KeyframeInterpolator`: cubic ease-out matches `Anim.cs`'s `(t-1)^3+1` exactly; `FindNearest`
      port matches all of Requirements' documented cases (before-any-anim, mid-range, past-all,
      the `curr.end==curr.start` guard)
- [ ] Per-type resting defaults match exactly: translate falls back to static `translate`,
      scale→(1,1), alpha→1, rotate→(0, pivot 0.5/0.5)
- [ ] `models_mapping.dart`: an `Anim` JSON blob with no `end` key round-trips as `end=0` in memory
      and stays keyless on re-save (the fixed pair, read+write, tested together)
- [ ] `SoundPlayer.evaluate`: point-trigger fires only on a downward crossing, not upward; a real
      range starts/stops exactly at its boundaries

### Integration Tests

- [ ] Open a real `.comics` file from `dataset/.../comics_interactive/`, pan through its full real
      height, confirm every layer's computed transform at several sample points is finite and
      matches manual hand-calculation against the same file's raw `Anim` data (a concrete,
      checkable bar per Requirements' Constraints -- no longer blocked on an ambiguous units
      question, since Requirements resolved that)
- [ ] Confirm the `currentTime` derivation is genuinely zoom-invariant: pan to a fixed document
      position at two different zoom levels, confirm `currentTime` reads the same both times (this
      is the one piece of math not yet empirically verified -- see Data Flow)

### Manual Verification

- [ ] Author a new translate+alpha animation in the running editor, pan through it, confirm visual
      behavior matches expectations
- [ ] Open several real `dataset/` files (read-only copies) and visually confirm previously-inert
      layers now hold their resting position instantly, not sliding in
- [ ] A real sound cue plays/loops/stops correctly while panning; scrolling back up past a
      point-trigger does not replay it

## Migration / Rollout

No data migration -- the `.comics` file format itself is unchanged. Two real, disclosed behavior
changes on existing files, both intentional corrections rather than regressions: (1) previously
inert `Anim` keyframes will animate for the first time; (2) legacy-authored seed keyframes will
render as instant placement instead of a spurious 200px slide-in (a latent bug fix, per Data
Models). Both ship live, no opt-in toggle -- consistent with Requirements' framing that the
underlying uncertainty motivating a toggle in the sibling flow no longer applies here.

Existing `.comics` documents also remain Vertical-scroll comic strips by default. No direction
migration is performed in this flow because no scroll-type discriminator is written yet.

## Open Design Questions

- [ ] Exact `currentTime` derivation from `canvasViewport.value`'s `Matrix4` (sign, and confirming
      division by both `k` and zoom scale produces a truly zoom-invariant, document-pixel value) --
      flagged for empirical verification during Implementation (see Testing Strategy), not asserted
      as certain here.
- [ ] `InteractiveViewer`'s `boundaryMargin` tuning once `_Page` is real-height instead of
      shrunk-to-fit -- needs real testing against actual tall documents, not a guessed constant.
- [ ] Exact `audioplayers` version pin and any platform-specific setup (e.g. Linux backend
      requirements) -- Plan-time detail.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-02
- [x] Notes: Approved as drafted, including the `models_mapping.dart` finding and both Open Design
      Questions deferred to empirical verification during Plan/Implementation.
- [x] Axis-contract addendum requested by Anton on 2026-08-05; it documents current/default
      vertical behavior and defers horizontal implementation without altering approved code scope.
- [x] Target-device/visible-range addendum explicitly requested by Anton on 2026-08-05 and moved
      from the timeline flow into this scroll specification.
