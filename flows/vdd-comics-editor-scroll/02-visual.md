# Visual Mockups: comics-editor-vertical-scroll

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-08-02

## Overview

Five things need showing, straight from `01-requirements.md`'s Acceptance Criteria: (1) the canvas
switching from today's fit-whole-document view to a responsive scrolling window; (2) a layer
actually animating as that window scrolls through its keyframes, then holding steady past them —
exactly `FindNearest`/`Factor`; (3) sound's point-vs-range, direction-sensitive triggering; (4) a
newly-created layer's instant placement (no more 200px slide-in); (5) confirmation that
`timeline.dart` itself is visually untouched — only what feeds it changes. No new screens, no new
navigation — this is one existing screen (the canvas editor) behaving differently.

---

## Screen: Canvas editor — before vs. after

### Before (today) — fits the whole document into view, then free zoom/pan

```
+----------------------------------------------------------------+
|  Layers | Sounds |                                    | Props  |
+----------------------------------------------------------------+
|                                                                  |
|                      ___________________                        |
|                     |###################|  <- entire 33,000px   |
|                     |###################|     document, shrunk  |
|                     |###################|     down to fit       |
|                     |#####[layer A]#####|     fully on screen   |
|                     |###################|                       |
|                     |###################|                       |
|                     |#####[layer B]#####|                       |
|                     |###################|                       |
|                     |___________________|                       |
|                                                                  |
|  InteractiveViewer: pinch/drag = free zoom & pan over this       |
|  already-shrunk thumbnail. Nothing here corresponds to "how      |
|  far a reader has scrolled" -- there IS no such position.        |
+----------------------------------------------------------------+
|  [Timeline / keyframe editor -- unchanged, see below]            |
+----------------------------------------------------------------+
```

### After — a responsive-sized window scrolls through the real document

```
+----------------------------------------------------------------+
|  Layers | Sounds |                                    | Props  |
+----------------------------------------------------------------+
|                     ___________________                         |
|                    |###################|  <- ONE screenful,     |
|                    |#####[layer A]#####|     sized to the       |
|                    |###################|     available editor   |
|                    |- - - - - - - - - -|     panel (responsive, |
|                    ^ drag/trackpad-     ^     not a hardcoded    |
|                      scroll moves this        1.4 ratio like    |
|                      window vertically        legacy)           |
|                      through the real                           |
|                      33,000px document                          |
|                                                                  |
|  (zoom still free, independent of this -- panning IS scrolling  |
|   time now, matching legacy's ScrollViewer.VerticalOffset)      |
+----------------------------------------------------------------+
|  [Timeline / keyframe editor -- unchanged, see below]            |
+----------------------------------------------------------------+
```

### Elements

| Symbol | Meaning |
|--------|---------|
| `#` | Rendered document content (layers) |
| `- - -` | The responsive viewport window's edge, scrolling vertically |
| `[layer A]` | A named layer, for reference across states below |

---

## Component: scroll-driven keyframe interpolation (Acceptance Criteria 2, 3)

Three moments as the window scrolls down past a layer's translate `Anim` range
(`Start=4800, End=5000`, per the real authoring convention — 200px window):

```
Moment 1 -- scroll = 4200 (before the anim starts)
+---------------------+
|                     |
|     (layer A)       |   layer A sits at its resting position --
|      not moved      |   held from an earlier, already-passed
|                     |   keyframe (or a default if none exists yet)
+---------------------+
scroll position: ----4200----[4800..5000]---------------->

Moment 2 -- scroll = 4900 (inside the anim range, mid-transition)
+---------------------+
|         (layer A)   |   Factor(4900) = t=(4900-4800)/200=0.5
|           moving-->  |   eased via (t-1)^3+1 (cubic ease-out) --
|                     |   layer A is 50%-eased between its prior
+---------------------+   value and this keyframe's target
scroll position: ----------4900------------------------->
                              ^ inside [4800,5000]

Moment 3 -- scroll = 6000 (well past the anim's end)
+---------------------+
|             (layer A)|  Interpolate returns the keyframe's value,
|              settled  |  UNCHANGED -- no further computation, holds
|                       |  here for the rest of the document (even if
+---------------------+  it's 100,000px tall)
scroll position: --------------------------6000---------->
                              [4800..5000] already passed
```

### Notes on this component

- This is the exact `FindNearest`/`Factor`/`Interpolate` algorithm from
  `legacy/comics-editor-v2.8/Comics.Editor/Models/Anim.cs` — no new curve, no new selection logic,
  a faithful port.
- Scale/rotate/alpha behave identically in shape; only their resting defaults differ
  (`scale=1`, `alpha=1`, `angle=0`, `pivot=(0.5,0.5)`) per Acceptance Criterion 3.

---

## Component: sound triggering (Acceptance Criterion 4)

```
Point trigger (Start == End == 3000) -- plays once, only when scrolling DOWN through it

  scrolling down:   ---2900-->3000-->3100-->   PLAYS at the instant scroll crosses 3000
  scrolling back up: --3100-->3000-->2900-->   does NOT replay (direction-sensitive)

Range trigger (Start=5000, End=5400) -- loops while scroll stays inside

  scroll=4900:  [silence]
  scroll=5100:  [#### looping audio ####]  <- inside [5000,5400]
  scroll=5300:  [#### looping audio ####]  <- still inside
  scroll=5500:  [silence]                  <- exited range, stops immediately
```

Requires a new audio-playback dependency in `apps/comics-editor` (none exists today) — sized as
real work in Plan, not assumed free.

---

## Component: new-layer default seed (Acceptance Criterion 5)

```
Before (today)                         After (this flow)
scroll=0                scroll=200     scroll=0            scroll=200
+--------+              +--------+     +--------+          +--------+
| (new   |   sliding    | (new   |     | (new   |          | (new   |
|  layer)|   in over    |  layer)|     |  layer)|          |  layer)|
|  at 0  |   200px -->  | at dy  |     |  at dy |  (no      |  at dy |
+--------+              +--------+     +--------+   change) +--------+
 Start=0, End=200                       Start=0, End=0
 (unintentional slide-in)               (instant, matches Layer.Create)
```

---

## Flow: what does NOT change

```
[timeline.dart -- unchanged, deferred to a later decision]
        ^
        | still reads/writes Anim.start/end the same way it does today
        |
[canvasViewport pan position] ---becomes the shared "scroll" value--->
        |
        v
[KeyframeInterpolator: FindNearest + Factor + Interpolate, ported from legacy]
        |
        v
[layer transforms + sound playback, both driven by the same value]
```

`playhead` as an independently-settable field goes away (folded into pan position), but nothing
about `timeline.dart`'s rendering or interaction changes in this flow — only the value it's wired
to underneath.

---

## Notes

- No empty/loading/error states apply here — this is a rendering/interpolation behavior change to
  an existing screen, not a new flow with its own lifecycle.
- The "responsive viewport" sizing (vs. legacy's hardcoded `ratio=1.4`) means the on-screen
  proportions won't visually match legacy's exact screenshots — confirmed acceptable by Anton as
  the one deliberate deviation from a literal port.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-02
- [x] Notes: Approved as drafted.
