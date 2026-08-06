# Requirements: comics-editor-scroll

> Version: 0.5 (Edit Canvas target viewport and scroll binding addendum)
> Status: APPROVED BASE + v0.5 ADDENDUM AWAITING REVIEW
> Last Updated: 2026-08-05

## Method note (read this first)

Per Anton's explicit instruction: **the sole source of truth for how vertical scroll should
behave is `legacy/comics-editor-v2.8`** (confirmed to be the real, canonical v2.8 WPF source —
`apps/comics-editor/native/Comics.Editor` is a near-identical working copy of it, diverging only
in two unrelated additions: a "Convert" utility in `ComicsViewModel.cs` and lettering fields in
`Layer.cs`, neither touching scroll/animation code). `flows/vdd-comics-editor-timeline`,
`flows/sdd-comics-editor-questions`, and `flows/sdd-comics-editor-fromat-dot-comics` were consulted
**only to locate relevant files and functions faster** — their own design ideas (Option A1/A2
framing, the opt-in-toggle rollout decision, etc.) are deliberately **not** carried into this
flow. The one later exception is the target-device `DeviceProfile`/visible-range concept,
explicitly moved here by Anton on 2026-08-05 because it describes scroll viewport visibility, not
Timeline behavior. Where this flow's conclusions
happen to overlap with those flows' conclusions, it's because both looked at the same real code,
not because one was copied from the other — this is called out explicitly wherever it applies.

This investigation also surfaced a genuine correction to `vdd-comics-editor-timeline`'s own
Specifications (its single flagged "biggest risk") — see **Major Correction** below. Fixed there
as a disclosed correction, not silently.

## Direction Contract — clarified 2026-08-05

The product term is **comic strip** (not “stripe”). The current and default document mode is
**Vertical-scroll comic strip**. **Horizontal-scroll comic strip** is a separately visible future
mode; it is not enabled or implemented by this flow.

These are document reading directions, not device orientations:

- Vertical-scroll uses document height as its reading extent, vertical pan (`Y`) as progress, a
  portrait device preview by default, and a Viewer position control on the right edge.
- Future horizontal-scroll will use document width as its reading extent, horizontal pan (`X`) as
  progress, and a Viewer position control on the bottom edge.
- Portrait/landscape orientation remains an independent property. Landscape must never silently
  turn a vertical strip into a horizontal strip, and portrait must never imply vertical strip.
- `Anim.start`/`end`, sound ranges, and logical `currentTime` remain one-dimensional scroll
  positions. They are axis-neutral data: the selected document scroll type decides whether the
  value is derived from X or Y viewport movement.
- Existing `.comics` documents have no persisted scroll-direction discriminator. They must continue
  to open as Vertical-scroll comic strips. Future horizontal support therefore needs an explicit,
  backward-compatible persisted scroll type; it must not infer direction from width, height, or
  device orientation.

This clarification does not expand the approved implementation scope. It records why the current
code is intentionally vertical and the compatibility boundary a future horizontal flow must use.

## Problem Statement

Two separate, compounding gaps, both confirmed against real code, not assumed:

### Gap 1 (already known, restated precisely): the interpolation engine doesn't exist in Flutter

`apps/comics-editor/lib/src/ui/controller.dart`'s `playhead` (line 99) and `canvasViewport`
(line 110) are unlinked, and no code anywhere evaluates `Anim` keyframes against either value —
`EditorLayer.translate` (`models.dart:110`) is a static `Offset` set once by drag
(`controller.dart:627`) and never re-computed. This much was already established in
`vdd-comics-editor-timeline`.

### Gap 2 (new finding, not previously identified): the canvas itself doesn't scroll the way v2.8's does

`apps/comics-editor/lib/src/ui/widgets/canvas_view.dart:37-51` fits the **entire document height**
into the available viewport on every frame (`aspect = doc.width / doc.height`; `pageH = maxH`,
`pageW = pageH * aspect`) — for a real document (height 16,300–100,900px, width ~1080px), this
renders the whole multi-screen-tall strip shrunk down to fully fit on screen at once, and
`InteractiveViewer` (lines 52-58) then provides free zoom/pan **on top of** that already-shrunk
view. This is an "overview + free camera" model. It is architecturally different from:

- **v2.8's real model**: a `ScrollViewer` whose content `Grid` is sized to the document's real,
  unscaled pixel dimensions (`Controls/ComicsControl.xaml:26`, `Width="{Binding Width}"
  Height="{Binding Height}"`), scrolled vertically through a **fixed-aspect viewport window**
  (see Major Finding below) — never "fit the whole thing on screen," always "one screenful at a
  time," matching how a real reader experiences the document.
- **The confirmed real end-user experience** (Anton, 2026-08-01): press-and-hold, finger-attached
  1:1 drag, revealing new content below/above — also a fixed-window-scrolling-through-real-height
  model, not a fit-to-screen overview.

**Both gaps must close together for this flow's ask to make sense**: wiring up interpolation
against a canvas that already shows the whole document at once would make scrolling/panning
largely pointless for authoring — the point of scroll-as-time is that you don't see the whole
strip at once, you see one screenful and animations play as you move through it.

## Major Finding: v2.8's real vertical-scroll mechanics (exact, cited)

Traced end-to-end through `legacy/comics-editor-v2.8/Comics.Editor/`:

1. **`Controls/ComicsControl.xaml:23-32`**: an outer `<Viewbox Stretch="Uniform"
   StretchDirection="Both">` wraps a `<ScrollViewer Name="scrollViewer" ... Height="{Binding
   ActualWidth, RelativeSource={RelativeSource Self}, Converter={StaticResource ratioConverter},
   ConverterParameter={StaticResource ratio}}">` containing `<Grid Width="{Binding Width}"
   Height="{Binding Height}">` (the real document pixel dimensions).
2. **The `ratio` constant is `1.4`** (`App.xaml:10`, `<sys:Double x:Key="ratio">1.4</sys:Double>`),
   and `RatioConverter.Convert` (`ViewModel/RatioConverter.cs:20`) computes `value * parameter` —
   so **`ScrollViewer.Height = ScrollViewer.ActualWidth × 1.4`**. This is a real, load-bearing
   mechanic: the editor's own canvas viewport is a **fixed-aspect-ratio window** (one "screenful"),
   scrolling vertically through the full document height — not an incidental layout detail.
   (The outer `Viewbox`'s uniform scaling is purely a display fit for the app window; it does not
   change the `ScrollViewer`'s internal coordinate space — `VerticalOffset` stays in the `Grid`'s
   real, unscaled document-pixel units regardless of how large or small the app window is.)
3. **`Controls/ComicsControl.xaml.cs:41-53`**: `ScrollViewer_ScrollChanged` sets `Model.Scroll =
   e.VerticalOffset` (real document pixels, unscaled); `Model_PropertyChanged` mirrors `Model.Scroll`
   back onto `scrollViewer.ScrollToVerticalOffset` — a genuine two-way binding, one shared value.
4. **`ViewModel/ComicsViewModel.cs:158-172`**: the `Scroll` setter calls `layer.Scroll()` for every
   layer and `sound.Scroll()` for every sound, every tick — the single value driving both visual
   and audio state, confirmed exactly as `vdd-comics-editor-timeline` already found via the
   `apps/comics-editor/native` copy.
5. **`ViewModel/LayerViewModel.cs:181-188`**: `Scroll()` calls
   `Anim.Interpolate<TranslateAnim>(Layer.Animations, SelectedAnim, scroll)` (and the same for
   `RotateAnim`/`ScaleAnim`/`AlphaAnim`), and the result is bound directly to rendering —
   `Controls/LayersControl.xaml:18-21`: `Canvas.Left="{Binding Translate.X}"`, `Canvas.Top="{Binding
   Translate.Y}"`, `RenderTransformOrigin="{Binding Rotate.Pivot}"`. **`TranslateAnim.X`/`Y` is the
   absolute canvas position** — nothing is added to a separate base position.
6. **`Models/Anim.cs:71-93` (`FindNearest<T>`) — the exact keyframe-selection algorithm**: walks a
   layer's `Anim`s of one type, sorted by `Start`. For each, if `anim.End <= scroll`, it's fully
   "passed" — keep updating `prev` to the latest such anim. The first anim that hasn't fully passed
   either contains the current scroll (`Start < scroll`, in which case it becomes `curr`) or hasn't
   started yet (`curr` stays `null`); either way the loop stops there. **If `prev` is still `null`**
   (scroll hasn't reached any anim yet), a fresh default instance is used instead (see point 8).
7. **`Models/Anim.cs:60-64` (`Factor`) — the interpolation curve**: `t = (scroll - Start) / (End -
   Start)`; returns `(t-1)^3 + 1` (a cubic ease-out). **Not explicitly clamped** — but `FindNearest`
   only ever calls `Factor` on a `curr` it already confirmed satisfies `Start < scroll < End`, so
   `t` is always genuinely inside `(0,1)` when this runs. `Interpolate<T>`
   (`Models/Anim.cs:95-103`): if there's no `curr` (scroll hasn't reached the next segment, or has
   passed every segment), the layer just holds `prev`'s value **unchanged** — no computation at all.
8. **Per-type resting defaults** (`Init()` overrides, used only when `prev` is still `null` — i.e.
   scroll before any anim of that type has ever started): `ScaleAnim` → `ScaleX=ScaleY=1`
   (`Models/ScaleAnim.cs:57-62`); `AlphaAnim` → `Alpha=1` (`Models/AlphaAnim.cs:39-43`); `PivotAnim`
   (base of Rotate/Scale) → `PivotX=PivotY=0.5` (`Models/PivotAnim.cs:48-53`); `TranslateAnim` and
   `RotateAnim` have no override, so C#'s own defaults apply (`X=Y=0`, `Angle=0`).
9. **Keyframe authoring** (`Models/Anim.cs:105-113`, `Add<T>`): a new keyframe's `Start` is either
   the current `scroll` (if past the layer's last existing anim of that type) or `lastEnd + 1`
   (if not); `End = Start + 200`. **A single layer's resting/static position is achieved with one
   short-range `TranslateAnim` placed wherever the author was scrolled to when they created the
   layer** (`Models/Layer.cs:52`, `Layer.Create`: `layer.Animations.Add(new TranslateAnim { Y =
   (int)scroll })` — `Start`/`End` both default to `0`) — once scroll passes that anim's tiny `End`,
   the layer just holds that value for the rest of the (possibly 100,000px-tall) document. **There
   is no need for keyframe ranges to span anywhere near the document's full height.**
10. **Keyframe-editing UI** (`Controls/LayerControl.xaml:37`): a plain `ListBox` of
    `Layer.Animations`, showing each as its type name (`Anim.ToString()` →
    `Type.GetEnumName()` — "Translate", "Rotate", etc., `Models/Anim.cs:66-69`), no visual
    timeline/Gantt representation at all. Numeric `Start`/`End`/`X`/`Y` editing happens via a
    per-type `DataTemplate`d `ContentControl` (`Controls/LayerControl.xaml:45`) for whichever anim
    is currently selected in that list.
11. **Sound's scroll-gating** (`Models/Sound.cs:40`, `Models/SoundAnim.cs:22-24`,
    `ViewModel/SoundViewModel.cs:124-137`): `Sound.Create` seeds `{Start=End=scroll}` — a point
    trigger. `SoundAnim.FindCurrent` matches either a genuine range (`Start <= scroll <= End`) or a
    point crossed while scrolling *downward specifically* (`prevScroll < scroll && prevScroll <=
    Start && Start <= scroll`) — scrolling back up past a point-trigger does not replay it. A
    point-range (`Start==End`) plays once (`PlayerState.Playing`); a real range loops for as long as
    scroll stays inside it (`PlayerState.Looping`), stopping the instant scroll exits the range —
    real, wall-clock audio via `MediaPlayer`, gated purely by scroll membership.

## Major Correction (2026-08-02) — fixes `vdd-comics-editor-timeline`'s flagged risk

That flow's `03-specifications.md` flagged, as its single biggest open risk, an apparent mismatch:
real `.comics` files' `Anim.Start`/`End` values are small (~48–6000) while document heights are
large (16,300–100,900+), and it could not determine from static reading whether `currentTime`
needed a scale factor to reconcile them. **Point 9 above resolves this definitively: there is no
scale factor, and no mismatch.** `Anim.Start`/`End` are in the exact same raw-pixel coordinate
space as `scroll` — they simply only need to span the short window during which one specific
transition actively plays (typically ~200px, per the authoring convention). The rest of a very tall
document deliberately has zero active keyframes for most layers, because once scroll passes a
layer's last keyframe, its value is just held, unchanged, forever — there's nothing to "cover" with
a range spanning the full document. The small numbers observed in real files aren't scaled-down
positions; they're literally raw scroll pixels, mostly clustered near the top of the document
because that's where most authored transitions happen to occur. **`currentTime = raw pan offset in
document pixels`, no conversion, is correct — not a hypothesis needing an empirical test, a fact
confirmed by reading the exact authoring code that produced those numbers.** (Note: that flow now
lives at `flows/_blamed/vdd-comics-editor-timeline/`, apparently archived/superseded — this
correction is recorded here rather than edited into the archived copy, pending confirmation that's
the right treatment.)

## Current Flutter state — closer to legacy than previously understood

Re-checked against current code (2026-08-02):

- `controller.dart:940-945` (`addSound`) and `:963-974` (`addAnim`) **already** stamp new keyframes
  as `start: playhead, end: playhead + 200` — the exact `Start`/`End = Start+200` shape as legacy's
  `Anim.Add<T>` (point 9 above), just fed from the wrong source value (`playhead`, an unlinked
  0..600 field) instead of real scroll/pan position. (Missing: legacy's "continue from the last
  keyframe's end" branch when authoring mid-timeline — a minor gap, not a structural one.)
- `models.dart`'s `Anim` class (line 57-83) **already** has every field legacy's five `*Anim`
  subclasses need — `x`/`y`, `pivotX`/`pivotY`, `angle`, `scaleX`/`scaleY` (defaulted to `1`/`1`,
  matching `ScaleAnim.Init()` exactly), `alpha` (defaulted to `1`, matching `AlphaAnim.Init()`
  exactly) — one flat class instead of five subclasses, but the same data, already correctly
  defaulted.
- `EditorLayer`'s constructor (`models.dart:94-101`) **already** seeds `anims.add(Anim(AnimType
  .translate)..y = translate.dy)` with an explicit comment "default anim, like Layer.Create in the
  original" — a real, intentional mirror of `Layer.Create`'s `TranslateAnim { Y = (int)scroll }`.
  **One real discrepancy found**: Dart's `Anim` constructor defaults `end: 200`
  (`models.dart:58`), while legacy's `Layer.Create` leaves `Start`/`End` at C#'s implicit `0`/`0` —
  meaning Dart's seed anim would currently be treated as a *200px-long slide-in* once evaluated
  (interpolating from a default `(0,0)` up to `(0, dy)`), not legacy's *instant, un-interpolated*
  placement. Small, but real — flagged for Plan.

**Net effect**: the data model was already built anticipating this port; the missing pieces are
(a) the actual interpolation engine (Gap 1) and (b) the canvas's fundamental scroll/fit behavior
(Gap 2) — not a data-model rework.

## Explicit Scope Boundaries (things this flow deliberately does NOT inherit from sibling flows)

- **Target-device viewport range is now in scope.** The original v0.2 scope excluded
  `DeviceProfile`, but Anton explicitly moved it from `vdd-comics-editor-timeline` into this flow
  on 2026-08-05. It remains an authoring visibility aid, not legacy behavior, pagination, reflow,
  or a `.comics` schema field.
- **No idle-loop / time-driven-while-in-range animation.** Confirmed absent in legacy too (same
  conclusion `vdd-comics-editor-timeline` already reached independently) — a literal port
  naturally excludes it; no conflict between the two flows here.
- **No opt-in-toggle-for-rollout decision carried over** — that was a judgment call made in the
  other flow's context (multiple open unknowns at the time); this flow's Major Correction above
  removes the underlying uncertainty that motivated it in the first place.

## Open Questions — resolved by Anton (2026-08-02)

- [x] **Keyframe-editing UI**: **leave `timeline.dart` alone for now — to be addressed later, as
      its own separate decision.** This flow does not touch the Gantt-style keyframe-editing widget
      at all; it only changes what drives it (real scroll/pan position instead of the independent
      `playhead`), not its visual form.
- [x] **Fixed-aspect viewport windowing**: **responsive** — size the scrolling window to the actual
      available editor screen space, not a hardcoded `ratio = 1.4` constant. This is a deliberate
      *deviation* from a literal 1:1 copy of that one specific mechanic (legacy hardcoded 1.4
      because it targeted one fixed preview shape; the Flutter editor's window is resizable) — noted
      explicitly since it's the one place this flow doesn't copy v2.8 verbatim.
- [x] **Sound triggering**: **in scope now.** Requires adding a new audio-playback package
      dependency to `apps/comics-editor` (none exists today) — sized as real, first-class work in
      Plan, not a footnote.
- [x] **The Dart seed-anim discrepancy**: **fix to match legacy exactly** — a layer's auto-seeded
      default `TranslateAnim` gets `Start = End = 0` (matching `Layer.Create`'s implicit C# int
      defaults), not today's `Start: 0, End: 200`. This changes how already-authored documents'
      "resting" layers render once interpolation goes live (instant placement, not a 200px slide-in)
      — a real, accepted behavior change, not silent.

## User Stories

### Primary

**As** Anton, authoring `.comics` documents in `apps/comics-editor`
**I want** the canvas to scroll through the real document the same way `legacy/comics-editor-v2.8`
and the real end-user viewer do, with `Anim` keyframes actually animating as I move through it
**So that** what I see while authoring matches what readers actually experience, and previously
inert keyframe data in existing documents finally does something

### Secondary

**As** Anton, authoring a scene with a sound cue
**I want** sound to trigger and loop based on scroll position, exactly as it does in
`legacy/comics-editor-v2.8`
**So that** audio authoring works the same way it always has, without a separate mental model

**As** a corrector editing on any desktop, tablet, or phone
**I want** to choose a target reader device under Properties → General and see that device's
visible document interval on the scroll control
**So that** the editor window size does not masquerade as the reader viewport and I can judge
where content enters and leaves an iPad or iPhone screen

## Acceptance Criteria

### Must Have

1. **Given** the canvas view, **when** it renders, **then** it shows one responsive-sized
   "screenful" window into the document (sized to available editor screen space, not the whole
   document shrunk to fit) — replacing `canvas_view.dart:37-51`'s current fit-whole-document
   behavior.
2. **Given** a layer with real `Anim` keyframes of any type (translate/rotate/scale/alpha),
   **when** the canvas is panned/scrolled, **then** its rendered transform matches what
   `FindNearest`/`Factor`/`Interpolate` (`legacy/.../Models/Anim.cs`) would compute at that same raw
   pixel position — including the cubic ease-out curve and the "hold last value forever past the
   last keyframe" behavior.
3. **Given** a layer with no `Anim`s of a given type, **when** the canvas is panned, **then** it
   uses the same per-type resting defaults as legacy (`scale=1`, `alpha=1`, `pivot=(0.5,0.5)`,
   `angle=0`) — unchanged from today for the common case.
4. **Given** a sound with `Anim` (`SoundAnim`) triggers, **when** the canvas is panned through their
   range, **then** it plays/loops/stops exactly per legacy's point-vs-range, direction-sensitive
   gating (`SoundAnim.FindCurrent`) — requires adding a real audio-playback dependency.
5. **Given** a newly-created layer, **when** its default translate anim is seeded, **then** it uses
   `Start = End = 0` (matching `Layer.Create`), not today's `Start: 0, End: 200`.
6. **Given** `playhead`/`canvasViewport`, **when** this flow ships, **then** they are no longer two
   unlinked values — pan position is the one value driving both rendering and any future keyframe
   authoring.
7. **Given** Properties in Editor, **when** it is opened, **then** tabs are ordered `Selection`,
   `Document`, `General`; General exposes an app-level target device and its dimensions, starting
   with iPad `768×1024` and iPhone `390×844`, with iPad selected by default.
8. **Given** a Vertical-scroll comic strip and a selected target device, **when** Viewer displays
   the right-edge scroll control, **then** it renders the selected device's visible interval rather
   than a single point. For position `p`, `visibleHeight = document.width × device.height /
   device.width`, clamped to document height; the interval maps through the document's available
   travel and remains draggable/tappable as one viewport band. The Viewer content itself is fitted
   into the same selected-device aspect ratio, letterboxed within the host editor when necessary.
9. **Given** Comics Editor is running on a desktop or another device, **when** the target profile
   is changed, **then** the visible interval follows the selected target profile only; it does not
   follow the editor window's physical dimensions and is not written into `.comics`.
10. **Given** a Vertical-scroll comic strip in Edit mode, **when** the author pans the Canvas,
    **then** a right-edge target-device viewport band moves from `canvasViewport/currentTime` and
    shows the selected device's visible start/end boundaries. The same band is present in Edit,
    not only in Viewer.
11. **Given** the Edit range rail, **when** the author taps or drags it, **then** the Canvas scroll
    position changes in the same action. Canvas pan → band and band → Canvas are one two-way scroll
    binding; no independent Edit rail position is introduced.
12. **Given** Edit is hosted on desktop, tablet, or phone, **when** a target profile is selected in
    General, **then** the editable comic viewport uses that target aspect ratio and is fitted/
    letterboxed inside the host workspace. The host window dimensions do not define the reader
    viewport.
13. **Given** Editor and Viewer workspaces, **when** either workspace is active, **then** both use
    the same General target profile and range math, while each band reflects its active renderer's
    own scroll state. Switching workspaces must not silently overwrite the inactive workspace's
    saved position.

### Should Have

- A real `.comics` file, opened after this ships, visibly animates in ways consistent with what it
  would do in `legacy/comics-editor-v2.8` — a spot-check, not an automated guarantee, given the two
  are different runtimes.

### Won't Have (This Iteration)

- **`timeline.dart`'s visual form** — left untouched per Anton's explicit instruction; a separate,
  later decision.
- **Idle-loop/time-driven-while-in-range animation** — absent in legacy, so naturally excluded from
  a literal port.
- **Multiple simultaneous target-device guide rows or pagination marks.** This iteration selects
  one target profile and shows its current visible range; it does not reflow or paginate content.
- **A hardcoded `ratio` constant matching legacy's `1.4`** — deliberately not copied; the viewport
  is responsive instead (see Open Questions).
- **Horizontal-scroll comic strip rendering or authoring** — shown as a disabled future document
  type only. No X-axis progress engine, bottom-edge Viewer selector, or persisted scroll-type field
  is introduced by this flow.

## Constraints

- **Legacy fidelity is the acceptance bar for the interpolation math specifically**: given a real
  `.comics` file's `Anim` data and a chosen scroll position, the Flutter engine's computed
  translate/scale/rotate/alpha must match what `FindNearest`/`Factor`/`Interpolate` would produce
  in `legacy/comics-editor-v2.8` — this is now a checkable bar (Major Correction resolved the
  ambiguity that would have made it un-testable), not an aspiration.
- Per `vdd-comics-editor-timeline`'s own confirmed finding (independently re-confirmed here): the
  real production Android viewer (`libs/comics_viewer/comics-viewer-android`) already has a working
  Java port of this exact algorithm (plus an added easing curve) — worth a direct side-by-side
  comparison during Specifications to catch any divergence between the two existing ports before
  adding a third (Dart) one.

## References

- `legacy/comics-editor-v2.8/Comics.Editor/Controls/ComicsControl.xaml`, `.xaml.cs` — the
  Viewbox/ScrollViewer/ratio structure and two-way scroll binding
- `legacy/comics-editor-v2.8/Comics.Editor/App.xaml:10` — `ratio = 1.4`;
  `ViewModel/RatioConverter.cs` — the multiply-by-ratio conversion
- `legacy/comics-editor-v2.8/Comics.Editor/ViewModel/ComicsViewModel.cs:158-172` — the shared
  `Scroll` value
- `legacy/comics-editor-v2.8/Comics.Editor/ViewModel/LayerViewModel.cs:181-188` — per-layer
  `Scroll()` → `Anim.Interpolate<T>`
- `legacy/comics-editor-v2.8/Comics.Editor/Controls/LayersControl.xaml:18-21` — `Translate`/`Rotate`
  bound directly to `Canvas.Left`/`Top`/`RenderTransformOrigin`
- `legacy/comics-editor-v2.8/Comics.Editor/Models/Anim.cs` — `FindNearest`, `Factor`, `Interpolate`,
  `Add` (the complete algorithm)
- `legacy/comics-editor-v2.8/Comics.Editor/Models/{TranslateAnim,ScaleAnim,RotateAnim,AlphaAnim,
  PivotAnim}.cs` — per-type `Interpolate`/`Init` overrides
- `legacy/comics-editor-v2.8/Comics.Editor/Models/Layer.cs:39-54` (`Create`) — the resting-position
  seeding convention
- `legacy/comics-editor-v2.8/Comics.Editor/Controls/LayerControl.xaml:37,45` — the real (non-visual)
  keyframe-editing UI
- `legacy/comics-editor-v2.8/Comics.Editor/Models/Sound.cs:40`, `Models/SoundAnim.cs:22-24`,
  `ViewModel/SoundViewModel.cs:124-137` — scroll-gated sound triggering
- `apps/comics-editor/lib/src/ui/widgets/canvas_view.dart:37-58` — the current fit-whole-document
  canvas model (Gap 2)
- `apps/comics-editor/lib/src/ui/controller.dart:99,110,506-509,627,940-945,963-974` — current
  `playhead`/`canvasViewport`/`addAnim`/`addSound`
- `apps/comics-editor/lib/src/ui/models.dart:55-165` — current `Anim`/`EditorLayer` (already
  largely aligned with legacy's data shape)
- `flows/vdd-comics-editor-timeline/01-requirements.md`, `03-specifications.md` — consulted for
  file/function pointers only, per Method note; its unresolved-risk finding is corrected above,
  not inherited
- `flows/sdd-comics-editor-questions/01-requirements.md` (Group C) — consulted for pointers only
- `flows/sdd-comics-editor-fromat-dot-comics/01-requirements.md` — consulted for pointers only

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-02
- [x] Notes: Confirmed "responsive to screen space" for the viewport-windowing Open Question
      (resolves the "responsible"/"responsive" ambiguity flagged in `_status.md`).
- [x] Direction clarification supplied by Anton on 2026-08-05: Vertical-scroll comic strip is the
      current/default mode; Horizontal-scroll comic strip is a distinct future mode.
- [x] Target-device dimensions and viewport-band scope moved from `vdd-comics-editor-timeline` by
      Anton on 2026-08-05; General + selected-device range implemented as the clarified form.
- [ ] Edit binding addendum requested by Anton: target viewport and range must bind to Edit Canvas
      scroll as well as Viewer. Requirements captured on 2026-08-05; awaiting addendum review.
