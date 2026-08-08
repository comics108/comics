# Specifications: dot-comics-format (TDD)

> Version: 0.7 (2026-08-08: NEW — `Layer.ZDepth`, an optional per-layer parallax-depth field,
> default `0`, absent-key treated identically to explicit `0` for v2012 compatibility)
> Status: APPROVED
> Last Updated: 2026-08-08
> Requirements: [01-requirements.md](01-requirements.md)
> Tests: [02-tests.md](02-tests.md) (Test Cases B2-B5, D4, and the animation-inventory background
> this derives from)

## Overview

Five schema/design items, specified here ahead of this flow's full Specifications phase, per
Anton's explicit request that they not live only in Tests:

1. **Scroll position and time as two independent animation-driving dimensions** (Test Case D4).
2. **The complete `.comics` animation-type inventory and its real, confirmed gaps against actual
   produced Lottie content** — not a hypothetical comparison; grounded in direct inspection of all
   7 real produced chapters (`dataset/mahabharata/boranko/mahabharata-dot-lottie/unzip/`).
3. **`Layer.ParentId` and organizational (non-content) layers** — a new hierarchical-parenting
   mechanism and a new organizational-layer concept, both directly motivated by the real Lottie
   parenting/null-layer evidence found while investigating item 2.
4. **`Layer.Mask`/`Layer.SolidColor`** — two new additive fields for content-source/compositing,
   deliberately kept separate from `Kind` (role).
5. **`scrollType` vs. device orientation as two independent dimensions** (Test Cases B2-B5) —
   content-scroll-axis vs. device-screen-orientation, never coupled or inferred from each other.
6. **`Layer.ZDepth`** — a new optional per-layer parallax-depth field, default `0`, for faking depth
   via scroll-response scaling on a format that otherwise remains genuinely flat 2D.

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `.comics`/`data.json` schema | Modify (additive) | New optional per-`Anim` time-basis field (exact name TBD, see Open Design Questions) |
| `apps/comics-editor/lib/src/ui/models.dart`'s `Anim` | Modify (additive) | New nullable field; every existing `Anim` continues to default to scroll-basis |
| `apps/comics-editor/lib/src/ui/anim/keyframe_interpolator.dart` | Modify (additive, new code path) | Needs a second, time-driven evaluation path alongside the existing scroll-driven one; the two must compose independently per Test D4's edge case |
| `flows/comics-editor/tdd-dot-lottie-import-export`'s Precomp Handling design | **Needs generalizing** | Currently scoped to precomp-child baking only; real content requires resolving arbitrary `parent` chains (see Animation-Type Inventory below) — now has a cleaner target: map onto `Layer.ParentId` directly instead of baking-and-discarding |
| `.comics`/`data.json` schema (`Layer`) | Modify (additive) | New `Layer.Id` (stable identity, prerequisite), `Layer.ParentId` (nullable, references another `Layer.Id`), new `Kind` value for organizational layers |
| `apps/comics-editor/lib/src/ui/models.dart`'s `EditorLayer` | Modify (additive) | New `id`, `parentId` fields; every existing layer has no parent, behaves exactly as today |
| `apps/comics-editor`'s canvas/layers-panel editing logic | Modify (new behavior) | Moving a parent layer should visually move its children live during editing — new interaction, doesn't exist today (flat, independent layers) |
| Any reader (2012 Java/Swift, v2.8, current) | None required | Absent `parentId`/organizational `Kind` → today's exact behavior; file always persists resolved absolute `Anim` values regardless of parenting, so no reader ever needs to resolve a parent chain to render correctly |

## Architecture

### Component Diagram

```
Existing (unchanged):
  scrollPosition -> KeyframeInterpolator.translateAt/scaleAt/rotateAt/alphaAt(anims, scrollPosition)
                     -> effective transform (per Anim.FindNearest-equivalent walk)

New, additive, parallel path:
  wallClockTime  -> KeyframeInterpolator.translateAt/scaleAt/rotateAt/alphaAt(anims, wallClockTime)
                     -> effective transform (same walk logic, different driving scalar)

Per-property composition (Test D4's edge case):
  for each layer, for each property (translate/rotate/scale/alpha):
    anims_for_property = layer.anims.where(type matches)
    basis = anims_for_property's own declared basis (scroll, default) -- NOT a per-layer or
            per-document setting; each anim range independently declares its own basis
    value = KeyframeInterpolator.<property>At(anims_for_property,
                basis == time ? wallClockTime : scrollPosition)
```

### Data Flow

```
Both scrollPosition and wallClockTime are computed independently, every frame:
  scrollPosition <- canvasViewport pan position (existing, per vdd-comics-editor-vertical-scroll)
  wallClockTime  <- a Ticker/Handler/CADisplayLink-driven clock (NEW -- doesn't exist in any
                     reader today; needs a real per-platform implementation)
Neither is derived from the other. A layer with translate=scroll-based and rotate=time-based
evaluates both inputs every frame and applies both results to the same transform, independently.
```

## Interfaces

### New Interfaces

```dart
// lib/src/ui/models.dart -- Anim, modified (additive)
enum AnimBasis { scroll, time } // default: scroll, for every existing/unmarked Anim

class Anim {
  Anim(this.type, {this.start = 0, this.end = 0, this.basis = AnimBasis.scroll});
  // ...existing fields unchanged...
  AnimBasis basis; // NEW -- see Open Design Questions for exact JSON field name/serialization
}
```

```dart
// lib/src/ui/anim/keyframe_interpolator.dart -- conceptual addition, not yet implemented
class KeyframeInterpolator {
  // Existing scroll-driven functions (translateAt, scaleAt, rotateAt, alphaAt) already take a
  // `double currentTime` parameter (per vdd-comics-editor-vertical-scroll) -- these do NOT need
  // new signatures. What's new is which value the CALLER passes in per anim-list: scrollPosition
  // for basis==scroll anims, wallClockTime for basis==time anims, resolved per-anim-type before
  // calling in, not inside the interpolator itself. This keeps the interpolator's own math
  // completely unchanged -- only the caller-side value selection is new.
}
```

## Data Models

### New Types

```
Anim.basis: "scroll" | "time"  (optional; absent == "scroll", full backward compat)
```

### Schema Changes

One new optional key per `Anim` JSON entry: `basis` (or equivalent — name not finalized, see Open
Design Questions). Omitted entirely when scroll-based (the default and, for every real file today,
the *only* value that has ever existed) — matches the exact same additive, ignorable-by-old-readers
pattern already used for `Kind`/`Style`/`Translations`/`scrollType`/`GroupId`/`TextRegion`.

## Behavior Specifications

### Happy Path

Per Test D4: a `.comics` file with one anim marked time-based renders that property continuously
driven by wall-clock time, independent of whether the reader is currently scrolling — e.g. a
swinging-leg rotation keeps looping while the reader has stopped scrolling to read balloon text.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| Mixed basis on one layer | translate=scroll, rotate=time on the same layer | Both evaluated independently every frame, composed into one transform (Test D4) |
| Absent `basis` on any anim, any file, any generation | Every real file today | Resolves to scroll-basis, byte-identical to pre-this-decision behavior |
| Time-based anim's start condition | Not yet specified | **Undecided** — document load? First scroll-visibility? An explicit trigger? Flagged, not guessed (Test D4) |
| Time-based anim's loop semantics | Not yet specified | **Undecided** — once? Forever? N times? Flagged, not guessed (Test D4) |

### Error Handling

| Error | Cause | Response |
|-------|-------|----------|
| Unknown `basis` value (neither "scroll" nor "time") | Malformed/future file | Should default to `scroll` (safest, matches every reader's existing unknown-key-tolerant JSON parsing — Newtonsoft/Gson/`Decodable` all ignore-unknown by default, per `02-tests.md` D3) — not yet implemented, stated as the intended behavior |

## Dependencies

### Requires

- Nothing new — additive to the existing `Anim` model.

### Blocks

- `flows/comics-editor/tdd-dot-lottie-import-export`'s eventual handling of any Lottie content that
  turns out to need a genuinely time-driven (not scroll-driven) reading — not currently in that
  flow's scope, but this addition is the schema prerequisite if it ever is.

## Integration Points

### Internal Systems

`models.dart`, `models_mapping.dart` (new field read/write), `keyframe_interpolator.dart` (new
caller-side value selection), whichever component owns `apps/comics-editor`'s render loop (needs a
new wall-clock ticker source, doesn't exist today).

## Testing Strategy

### Unit Tests

- [ ] `Anim.basis` defaults to `scroll` when absent from JSON (mirrors the same test shape already
      used for `end`/`scaleX`/`alpha`'s own JSON-absence-default bugs elsewhere in this format)
- [ ] A layer with mixed-basis anims on different properties evaluates both independently (Test D4)

### Integration Tests

- [ ] Real-file regression: every one of the 27 classic dataset files + `samples/sample_v2012.comics`
      has zero `basis` keys anywhere — confirms this addition doesn't accidentally alter parsing of
      any existing real file

## Migration / Rollout

No migration — purely additive, same non-breaking pattern as every prior schema addition in this
format's history.

---

## `Layer.ParentId` & Organizational Layers — Specification

Directly motivated by the real Lottie parenting/null-layer evidence found while building the
Animation-Type Inventory below — moved to its own section since it's a `Layer`-level structural
concept, not an `Anim`-level one like the time-basis addition above.

### Interfaces (New Types)

```dart
// lib/src/ui/models.dart -- EditorLayer, modified (additive)
class EditorLayer {
  // ...existing fields unchanged...
  String id;          // NEW, prerequisite -- stable identity, assigned once at layer creation
                       // (e.g. a UUID), never reassigned, never derived from list position.
  String? parentId;   // NEW -- references another layer's `id` within the same document.
                       // null (the default, and every existing layer's value) == no parent,
                       // today's exact behavior.
}
```

```
// Kind (existing open-string field, models.dart / Layer.cs) gains one new conventional value:
Kind == "organizational"  // (exact string TBD) -- a layer with no populated image slots, existing
                           // purely as a parent anchor for other layers. Not a new field -- reuses
                           // the field's own open-ended design.
```

### Data Models — Schema Changes

Two new optional `Layer` keys in `data.json`: `id` (string, becomes effectively required going
forward for any v2026-authored file, but absent on every pre-existing file, which have no parent
relationships to express anyway) and `parentId` (string, nullable). Plus one new conventional
`Kind` string value. All three are additive and ignorable by old readers, per this format's
established pattern.

### Behavior Specification — the critical backward-compatibility invariant

**A `.comics` file's `Anim` keyframes are ALWAYS the fully resolved, absolute values — regardless
of whether `ParentId` is set.** `ParentId` does not change what gets persisted; it changes how the
*editor* computes what to persist:

- **Without a parent** (today, and every layer in every existing file): the author positions a
  layer; its `Anim.x`/`y`/etc. are that position, directly.
- **With a parent** (new): the author positions a layer *relative to its parent's current resolved
  position* during editing (moving the parent live-updates the child's on-canvas position); at
  save time, the editor resolves the full parent chain and writes each layer's fully resolved,
  absolute `Anim` values — exactly as if there had been no parent at all. `ParentId` itself is also
  written (so re-opening the file in a `ParentId`-aware editor preserves the live-relative editing
  behavior), but **a reader that ignores `ParentId` entirely still renders every layer correctly**,
  because the absolute values it reads are already fully resolved.

This is the same "bake absolute, new field is editor-side/live-authoring metadata only" pattern
already established for `GroupId` — `ParentId` is a more general, hierarchical version of the same
idea, not a different backward-compatibility strategy.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| Circular parenting (A parents B parents A) | Malformed/buggy authoring | Must be rejected/prevented at authoring time — the editor's own UI should not allow creating a cycle; a file that somehow has one should be treated as an error, not resolved (no well-defined resolution exists) |
| Parent deleted while children reference it | User deletes a layer that others are parented to | Needs a defined policy — orphan the children (clear their `parentId`, keep their last-resolved absolute position) is the safest default; not yet decided as final |
| Organizational layer with populated image slots (contradicts its own `Kind`) | Authoring mistake, or a `Kind` value applied after content was already added | Should be a soft warning in the editor UI, not a hard error — the `Kind` value is descriptive, not enforced |
| Deep parent chains (matches real `THE BROKEN TUSK`, potentially many levels) | Real content | Resolution must walk the full chain at save time regardless of depth — no arbitrary depth limit assumed, though very deep chains should be checked for real performance impact (not yet measured) |

### Testing Strategy

- [ ] Unit: a 3-level parent chain (grandparent → parent → child) resolves to the correct absolute
      position at save time
- [ ] Unit: circular parenting is rejected/prevented, not silently infinite-looped
- [ ] Integration: a file with `ParentId` set, opened by a `ParentId`-unaware reader (simulate by
      stripping the field), renders identically to the same file with `ParentId` present — the
      core backward-compat guarantee, must be verified directly, not assumed
- [ ] Real-data: attempt round-tripping `THE BROKEN TUSK`'s real parent structure (190/295 layers)
      through this mechanism once `tdd-dot-lottie-import-export` implements the mapping

---

## Masks & Solid Colors — Specification (DECIDED, 2026-08-07)

Answering Anton's direct question (should masks/solid-color layers be new `Kind` values):
**decided: no — two separate additive fields instead**, since they describe content-*source*/
compositing, not semantic *role* (see `01-requirements.md`'s full rationale). Anton confirmed this
recommendation as-is ("используем твою рекомендацию") — the design below is adopted, not a
proposal awaiting review.

### Interfaces (New Types)

```dart
// lib/src/ui/models.dart -- EditorLayer, modified (additive)
class EditorLayer {
  // ...existing + id/parentId from above...
  String? solidColor; // NEW, proposed -- hex string (e.g. "#ffffff"), mirrors Lottie's `sc`.
                       // When set, render as a flat fill; mutually exclusive with populated
                       // Images[] slots (an editor-side validation, not a hard schema constraint).
  LayerMask? mask;     // NEW, proposed -- a general compositing clip on this layer's own content.
                       // Deliberately a SEPARATE field from TextRegion (different question: "what
                       // shape is my own content clipped to" vs. "where does lettering go").
}

class LayerMask {
  LayerMask({required this.shape, this.rect, this.points, this.maskFile});
  final String shape; // "rect" | "polygon" | "mask" -- same vocabulary as TextRegion, reused for
                       // convenience, not because the two concepts are the same thing.
  final Rect? rect;
  final List<Offset>? points;
  final String? maskFile;
}
```

### Data Models — Schema Changes

Two new optional `Layer` keys: `solidColor` (string) and `mask` (object, same shape union as
`TextRegion`). Both additive, both omitted when unset, both ignorable by old readers — an old
reader that doesn't understand `solidColor` simply has nothing to render for that layer (matches
existing behavior for a layer with all-empty `Images[]` slots today); one that doesn't understand
`mask` renders the layer's full, unclipped content, which is a real, disclosed visual difference
for legacy readers if this content is ever opened there. **Real-world impact is currently zero**:
this content doesn't exist in any file predating this decision, and no legacy reader is expected to
ever open new v2026-authored content that uses it.

### Behavior Specification

- **`solidColor`**: takes precedence when set — the layer's `Images[]` slots (if any) are ignored
  for rendering purposes (an editor-side rule; the exact precedence/coexistence behavior is a real
  design detail for whoever implements this, not fully specified here).
- **`mask`**: clips the layer's own rendered content (whether from `Images[]` or `solidColor`) to
  the given shape. Given all 6 real masks found are static rectangles, a `shape:"rect"` should be
  the common/default case in practice, with `polygon`/`mask` available but likely unexercised by
  real content for some time.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| Both `solidColor` and populated `Images[]` set | Authoring mistake, or intentional fallback design | Needs a defined precedence rule — not yet specified, flagged rather than guessed |
| `mask` on a layer with no content at all (e.g. also `Kind=="organizational"`) | Unusual combination | Almost certainly meaningless (nothing to clip) — likely worth a soft editor warning, not a hard error |

### Testing Strategy

- [ ] Unit: `solidColor` renders as a flat fill, `Images[]` ignored when both present (once
      precedence is decided)
- [ ] Unit: `mask.shape=="rect"` correctly clips rendered content to the given bounds
- [ ] Real-data: re-render `THE BROKEN TUSK`'s "White Solid 1" and `THE CHASE`'s 6 masked layers
      through this mechanism once `tdd-dot-lottie-import-export` implements the mapping, compare
      against the original Lottie rendering for visual equivalence

---

## `Layer.ZDepth` — Parallax Depth — Specification (NEW, 2026-08-08)

Per Anton's direct instruction: add a `z-depth` field to `.comics` v2026 for a parallax effect,
defaulting to `0` — the same value whether the key is absent or explicitly `0` — for v2012
compatibility. See `01-requirements.md`'s own section for the full narrative/rationale; this section
states the interface/data-model/behavior shape.

### Interfaces (New Types)

```dart
// lib/src/ui/models.dart -- EditorLayer, modified (additive)
class EditorLayer {
  // ...existing + id/parentId/solidColor/mask from above...
  double zDepth = 0.0; // NEW -- optional per-layer parallax depth. 0 (the default, and every
                        // existing/unmarked layer's implicit value) == no depth offset -- today's
                        // exact 1:1-with-scroll behavior, unchanged. Absent JSON key and an
                        // explicit `0` are the SAME value, not two distinguishable states.
                        // Sign convention, scroll-response formula, and unit/range are not yet
                        // decided -- see Open Design Questions.
}
```

### Data Models — Schema Changes

One new optional `Layer` key in `data.json`: `zDepth` (number). Absent → `0` — and, per Anton's
explicit instruction, absent and explicit-`0` must resolve to the identical behavior, not be treated
as two distinguishable states. Additive and ignorable by old readers, the same pattern as `id`/
`parentId`/`solidColor`/`mask` above.

### Behavior Specification

**Happy path**: every existing file (all 27 dataset files, `samples/sample_v2012.comics`, every
2012-through-2026-authored document) has no `zDepth` key on any layer, resolves every layer to `0`,
and renders byte-identical to today — no reader anywhere currently has a concept of depth to apply.

**The critical backward-compatibility invariant (mirrors `ParentId`'s own framing)**: a layer's
`Anim` keyframes remain the literal, authored motion regardless of `zDepth`. `zDepth` is meant to
modulate how a *`ZDepth`-aware reader* computes a layer's effective on-screen position from its
authored `Anim` value and the current scroll position — it does not change what gets persisted, and
a reader that has never heard of `zDepth` still renders every layer using its `Anim` values exactly
as it does today. (Contrast with `ParentId`, where the *editor* resolves live-relative values into
absolutes at save time — here, per the Requirements framing, the modulation is conceptually applied
at *render* time by a reader that understands `zDepth`, not baked into the persisted `Anim` values.
This distinction, and its consequences for a `zDepth`-unaware reader opening `zDepth`-bearing content,
is flagged in Open Design Questions rather than fully specified here.)

**Not a new driving dimension**: per "Layer & animation model" and the scroll-vs-time section in
`01-requirements.md`, every `Anim` is a pure function of one driving value (scroll, or optionally
time). `zDepth` modulates the scroll-driven case specifically; it is a coefficient, not a third
independent value a layer's `Anim` is a function of.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| `zDepth` absent | Every existing v2012-2026 file | Resolves to `0`, byte-identical rendering to today |
| `zDepth == 0` explicit | Any file | Resolves identically to absent — no distinguishable behavior between the two states anywhere in this format, per Anton's explicit instruction |
| Negative `zDepth` | Author intentionally marks a layer "closer" than the default plane (or the reverse, depending on the eventual sign convention) | Must be accepted, not rejected — the value's exact effect is part of the open sign-convention question, but the value itself is legal |
| `zDepth` set on a layer that also has `ParentId` set | A parented, depth-shifted layer | Not yet resolved whether depth composes through the parent chain (child inherits/adds to parent's own depth) or is purely per-layer/independent — flagged as a new open question, mirroring the existing `ParentId`/`GroupId` relationship question |
| `zDepth` combined with a time-basis anim (`Anim.basis == time`) on the same layer | Real, valid combination once both features exist | Per the Requirements framing, depth should modulate the scroll-driven contribution only — a purely time-based property on that layer should be unaffected by `zDepth`, though this composition has not been tested or fully confirmed |
| `zDepth` on a `Kind == "organizational"` layer (no visual content) | Unusual combination | Almost certainly meaningless (nothing to visually offset) — likely worth a soft editor warning, not a hard error, mirroring the equivalent `mask`-on-organizational-layer edge case above |

### Testing Strategy

- [ ] Unit: absent `zDepth` and explicit `zDepth: 0` produce identical rendered output for the same
      layer at the same scroll position
- [ ] Integration: every real dataset file + `samples/sample_v2012.comics` has zero `zDepth` keys —
      confirms this addition doesn't alter parsing of any existing real file
- [ ] Unit (blocked on the formula being decided): a nonzero `zDepth` layer's effective on-screen
      position differs from its literal authored `Anim` value by the decided scroll-response formula
- [ ] Unit (blocked on the `ParentId`-composition question being decided): a `zDepth`-bearing layer
      that also has a `zDepth`-bearing parent resolves depth per whatever composition rule is chosen

---

## `scrollType` vs. Device Orientation vs. Preferred Viewport Size — Specification (DECIDED 2026-08-02, escalated 2026-08-07, CORRECTED 2026-08-07, third field added 2026-08-08)

Escalated from `02-tests.md`'s Test Cases B2-B5 into Specifications proper, per Anton's explicit
request. **Corrected 2026-08-07**: device orientation is no longer platform-config-only — it becomes
a real `.comics` field too (`preferredOrientation`), per Anton's direct instruction. **New
2026-08-08**: a third field, `preferredViewportWidth`/`preferredViewportHeight` (default 720×1600),
motivated by `flows/comics-editor/tdd-dot-lottie-import-export`'s Playback Viewport export/import
mode. Three genuinely independent *fields*, specified separately below — see `01-requirements.md`
for the full narrative/rationale; this section states interfaces/data models/behavior.

### Interfaces (New Types)

```dart
// lib/src/ui/models.dart -- ComicsDoc, modified (additive)
enum ScrollType { vertical, horizontal } // default: vertical, for every existing/unmarked doc

// CORRECTED 2026-08-07: device orientation is now also a real field, not platform-config-only.
// Three values per Anton's follow-up -- "auto" means no fixed preference, reader may free-rotate.
enum PreferredOrientation { portrait, landscape, auto } // default: portrait, backward compat

class ComicsDoc {
  // ...existing fields unchanged...
  ScrollType scrollType = ScrollType.vertical; // NEW -- document-root, content-scroll-axis only.
                                                 // Deliberately NOT named `orientation` -- that
                                                 // word is reserved for device screen orientation,
                                                 // a completely separate field this one must never
                                                 // be confused with or derived from.
  PreferredOrientation preferredOrientation = PreferredOrientation.portrait; // NEW, 2026-08-07 --
      // the document's OWN declared preference for device orientation. Independent of
      // scrollType -- neither field may be inferred from the other, even though most real
      // content will likely pair scrollType=vertical with preferredOrientation=portrait.

  // NEW, 2026-08-08: independent of both fields above -- scale/extent of the intended viewing
  // window, not direction. Default 720x1600 matches the real value found in
  // samples/sample_playback_viewport.lottie_unzip (checked byte-level). Flat ints, not a nested
  // {width,height} object, to stay structurally parallel with ComicsDoc's own width/height.
  int preferredViewportWidth = 720;
  int preferredViewportHeight = 1600;
}
```

Device orientation's *enforcement* (actually locking the device) still lives entirely in platform
config (`AndroidManifest.xml`'s `android:screenOrientation`, iOS `Info.plist`'s
`UISupportedInterfaceOrientations`, Flutter's `SystemChrome.setPreferredOrientations`) — what's new
is that `.comics` now has a field a reader *may* consult to decide what to tell the platform,
per-document, instead of the platform lock being one static, app-wide, content-blind setting.
`preferredOrientation` is a declared preference on the content; it does not itself change how any
platform API is called — that mapping is Plan/Implementation work, not specified here.

### Data Models — Schema Changes

Four new optional root-level `data.json` keys: `scrollType` (string, `"vertical"`/`"horizontal"`),
`preferredOrientation` (string, `"portrait"`/`"landscape"`/`"auto"`), and (NEW, 2026-08-08)
`preferredViewportWidth`/`preferredViewportHeight` (ints). All four omitted → their respective
defaults (`"vertical"`, `"portrait"`, `720`, `1600`) — matching every real file's current, unchanged
behavior, the same additive/ignorable-by-old-readers pattern as every other schema change here.

### Behavior Specifications

**Happy path**: every existing file (all 27 dataset files, `samples/sample_v2012.comics`, every
2012-through-2026-authored document) has none of the four keys and resolves to
`scrollType="vertical"`, `preferredOrientation="portrait"`, `preferredViewportWidth=720`,
`preferredViewportHeight=1600` — the exact behavior every reader already has today, verified by Test
Case B4 (and its `preferredOrientation`/`preferredViewportWidth`/`Height` equivalents, not yet their
own test IDs — see Testing Strategy).

**The independence invariant (must be tested directly, not assumed)**: a reader's decision logic
for "which axis does content scroll" must read `scrollType` and nothing else; its decision logic
for "what orientation should this document request" must read `preferredOrientation` and nothing
else; its decision logic for "what viewport size was this authored for" must read
`preferredViewportWidth`/`Height` and nothing else. No field's code path may branch on another's
value, even now that all three live in the same file.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| `scrollType="horizontal"` on a device locked to portrait | A hypothetical future horizontal document, opened on today's portrait-only apps | Must still render as a horizontal-scrolling document *within* a portrait-shaped viewport — cramped, but correct; the reader must NOT force landscape just because content is horizontal (Test B5) |
| `scrollType` absent, but `width > height` | Any real file with unusual proportions (not yet seen in real data, per `02-tests.md` Category B2) | Resolves to `"vertical"` regardless of `width`/`height`'s relative magnitude — `scrollType` is authoritative, not inferred from document proportions |
| Unknown `scrollType`/`preferredOrientation` value (neither of the recognized strings) | Malformed/future file | Should default to `"vertical"`/`"portrait"` respectively (safest), matching this format's established unknown-value-tolerant convention (Test D3's JSON-unknown-key tolerance, applied here to an unknown *value* instead) |
| `preferredOrientation="auto"` combined with any `scrollType` | Real, valid combination | No coupling — a reader honoring `auto` lets the device rotate freely regardless of whether content scrolls vertically or horizontally; still two independent lookups |
| `scrollType="horizontal", preferredOrientation="portrait"` (or any other "unusual" pairing) | Real, valid combination — must not be rejected | The independence principle means this is a legal, if unusual, combination — no validation should reject it just because it doesn't match today's only-exercised pairing |
| `preferredViewportWidth`/`Height` present but `scrollType`/`preferredOrientation` absent (or any other partial combination) | Real, valid combination | Each of the three fields resolves independently to its own default when absent — no field's presence implies or requires another's presence |
| Non-positive or absurd `preferredViewportWidth`/`Height` (e.g. 0 or negative) | Malformed/hand-edited file | Not yet specified whether this should clamp to the default, reject, or pass through as-is — flagged as a genuine gap, not guessed (mirrors this format's general stance of tolerating unknown *values* per the row above, but a non-positive dimension is a different class of problem than an unrecognized enum string) |

### Testing Strategy

- [ ] Unit: absent `scrollType`/`preferredOrientation`/`preferredViewportWidth`/`Height` resolve to
      `vertical`/`portrait`/`720`/`1600` (Test B4 + new equivalents)
- [ ] Unit: a reader's orientation-preference decision never reads `scrollType` or
      `preferredViewportWidth`/`Height`; its scroll-axis decision never reads `preferredOrientation`
      or the viewport-size fields; its viewport-size decision never reads the other two — a real,
      direct test of the independence invariant across all three fields (e.g. a mock reader
      configured with all combinations of the three fields' values, asserting no setting leaks into
      another's decision)
- [ ] Integration: every one of the 27 real dataset files + `samples/sample_v2012.comics` has zero
      `scrollType`/`preferredOrientation`/`preferredViewportWidth`/`Height` keys — confirms this
      addition doesn't alter parsing of any existing real file

### UI Component (New Document dialog)

Per the already-decided UI treatment, **and confirmed already implemented in real code**
(`apps/comics-editor/lib/src/ui/widgets/dialogs.dart:39-114` — see `04-visual.md`'s Screen 1 for
exact citations): a "DOCUMENT TYPE" section with a third, visible-but-disabled "Horizontal-scroll
comic strip" card, and a separate "DEVICE ORIENTATION" section with Portrait (enabled, selected)
and Landscape (visible-but-disabled) tiles. **Still missing, now with a real target**: neither
section is wired to `scrollType`/`preferredOrientation` — both fields need adding to `ComicsDoc`
and the dialog's `choice`/orientation-tile state needs to actually write them on `newDoc()`. The
"Auto" third value for `preferredOrientation` has **no UI representation yet at all** — the real
dialog only shows Portrait/Landscape tiles, two options, not three — a real gap for Plan to size.
`preferredViewportWidth`/`Height` (NEW, 2026-08-08) has **no UI proposal at all yet**, in either the
New Document dialog or anywhere else — its primary real motivation so far is the Lottie Playback
Viewport export/import path (`flows/comics-editor/tdd-dot-lottie-import-export`), not a general
editor-authoring concern the way `scrollType`/`preferredOrientation` are; whether it needs its own
New Document dialog control, or only ever gets set indirectly (e.g. by the Lottie import flow itself
when it detects a viewport-shaped source), is undecided.

---

## Animation-Type Inventory & Lottie Coverage — Specification-Level Detail

(See `01-requirements.md`'s own copy of this table for the full narrative; this section states the
specification-relevant consequences.)

### The complete `.comics` Anim type set (final, no 6th type exists)

`translate`, `rotate`, `scale`, `alpha`, `sound` — this is the complete, closed set, unchanged since
2012 across all four independent implementations (2012 Java, 2012 Swift, v2.8 C#, current Dart).
Any future addition to this set (e.g. a 6th type) would be a materially bigger change than anything
in this format's history to date and is **not proposed here** — only the new `basis` dimension
(orthogonal to *which* type an anim is) is being added.

### Real, confirmed gaps against actually-produced Lottie content (specification impact)

| Real Lottie feature found | Files affected | Specification consequence |
|---|---|---|
| Vector masks (`masksProperties`) | 1/7 (`THE CHASE`) | `flows/comics-editor/tdd-dot-lottie-import-export`'s Won't-Have ("no shape/mask/text Lottie support") excludes real, already-produced content — needs Anton's explicit acknowledgment in that flow, not silent scope-narrowing |
| Null/organizational layers (`ty:3`) | 1/7 (`SVAYAMWARA`) | No `.comics` equivalent; that flow's import path needs a defined behavior for these (likely: skip, since they carry no visual content — not yet decided) |
| Solid color layers (`ty:1`) | 1/7 (`THE BROKEN TUSK`) | No `.comics` equivalent (no flat-color-fill layer type); same open question as masks |
| **Layer parenting (`parent` field)** | **5/7**, up to **64% of layers** in `THE BROKEN TUSK` | **Highest-impact finding**: the "bake absolute values at import time" mechanism already decided for precomp-children (`tdd-dot-lottie-import-export`'s Precomp Handling) must generalize to **arbitrary parent chains** between sibling layers, not just precomp-nesting — a real, larger implementation task than that flow's current Specifications (`03-specifications.md`) scopes. This is the most consequential correction from this investigation. |

### Resolution — DECIDED (2026-08-07), supersedes the earlier recommendation below

Given parenting affects the majority of at least one real chapter's layers, `.comics` v2026 gains a
real `Layer.ParentId` mechanism (see the new section above) — `tdd-dot-lottie-import-export`'s
import path should map Lottie's `parent` field **directly onto `Layer.ParentId`**, not bake-and-
discard it. This is a better outcome than the original recommendation (bake-only): the hierarchy
survives into `.comics`, live-editing behavior (move a parent, children follow) becomes possible in
the editor, and backward compatibility is unaffected either way (both approaches persist absolute
values for old readers). `tdd-dot-lottie-import-export`'s own Specifications should be updated to
reflect this — flagged there directly (see its `_status.md`).

*(Original recommendation, preserved for history, now superseded)*: "cannot treat 'resolve one
precomp's children' as sufficient — needs a general parent-chain-resolution step." Still true as
far as it goes, but incomplete — the real fix isn't just resolving-and-discarding the chain, it's
representing it for real via `ParentId`.

## Open Design Questions

- [ ] Exact `Anim.basis`/time-dimension field name and JSON shape — not finalized (see
      `02-tests.md`'s own Open Design Questions for the 5 sub-questions: field shape, time units,
      start/loop semantics, composition rule, which reader implements first).
- [ ] How does the new time-basis dimension interact with `flows/comics-editor/
      tdd-dot-lottie-import-export`'s time-base-ratio dialog (scroll-pixels ↔ frames)? That dialog
      was designed assuming everything is scroll-driven on the `.comics` side — a genuinely
      time-based anim wouldn't need that ratio at all. Not yet reconciled.
- [x] Should the parenting-generalization finding block `tdd-dot-lottie-import-export`'s progress to
      Plan? **Decided (2026-08-07): resolved via `Layer.ParentId`**, not a blocking question anymore
      — that flow maps onto the new mechanism directly (see the Resolution note above).
- [ ] `Layer.Id` generation/uniqueness scheme (UUID? sequential? something else?) — not specified,
      only that it must be stable and never reassigned.
- [ ] Exact organizational `Kind` string value (`"organizational"`, `"anchor"`, `"null"`, or
      something else) — not finalized.
- [ ] Orphan policy when a parent layer is deleted (clear `parentId`, keep last-resolved position —
      the specification's stated leaning, not confirmed as final).
- [ ] Relationship between `ParentId` and `GroupId` — does one subsume the other, or do both
      coexist for different cases? Explicitly left open in `01-requirements.md`, repeated here
      since it affects `EditorLayer`'s final field set.
- [x] **Masks/solid colors as separate fields vs. `Kind` values — DECIDED (2026-08-07)**: separate
      additive fields (`Layer.SolidColor`/`Layer.Mask`), not new `Kind` values. Anton confirmed the
      recommendation as-is.
- [ ] `solidColor`/`Images[]` precedence when both are somehow set — still open, not specified
      (the one remaining detail under the now-decided design).
- [ ] `Layer.ZDepth`'s sign convention (positive = farther/slower vs. closer/faster) — not decided.
- [ ] Exact scroll-response formula/unit relating `ZDepth` to a position-scaling factor — not
      decided.
- [ ] Whether `ZDepth` is baked into persisted `Anim` values at save time (mirroring `ParentId`'s
      editor-side-resolution pattern) or applied at render time by a `ZDepth`-aware reader (the
      current draft's assumption) — genuinely undecided; changes what a `ZDepth`-unaware reader sees
      when opening `ZDepth`-bearing content.
- [ ] Whether `ZDepth` composes through `ParentId` parent chains (child inherits or adds to parent's
      depth) or is purely independent per layer — not decided.
- [ ] Which reader(s) implement the actual parallax rendering math first — not decided (mirrors the
      same open question already carried for the time-basis dimension).

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-07 (v0.5 baseline); v0.6 (2026-08-08, `preferredViewportWidth`/`Height`)
      and v0.7 (2026-08-08, `Layer.ZDepth`) additions approved same-session, same reasoning as
      `01-requirements.md`'s v0.9/v0.10 Approval notes — narrow, directly-dictated additions.
- [x] Notes: Approved as drafted (v0.7), including the `preferredOrientation` correction and the
      `preferredViewportWidth`/`Height` and `Layer.ZDepth` fields. Still partial/early — scoped to
      the seven items above, not a claim that this flow's full Specifications phase is complete —
      and the Open Design Questions above (`Anim.basis` field shape, `Layer.Id` generation scheme,
      exact organizational `Kind` string, orphan policy, `ParentId`/`GroupId` relationship,
      `solidColor`/`Images[]` precedence, non-positive-viewport-dimension question, plus
      `Layer.ZDepth`'s sign convention/formula/bake-vs-render-time/`ParentId`-composition questions)
      remain genuinely open, carried forward to Plan to resolve rather than blocking approval of
      what's already decided.
