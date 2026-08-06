# Visual Mockups: comics-editor-timeline

> Version: 1.1 (adds the device visibility overlay component, under both A1 and A2; corrects
> initial "mouse wheel" pan/zoom mislabeling, caught by Anton)
> Status: DRAFT
> Last Updated: 2026-08-01

> **Relocation note (2026-08-05):** The device overlay mockups are historical. The approved
> product location is now Properties → General plus one selected-device viewport band on the
> Viewer scroll control, specified in `vdd-comics-editor-scroll/02-visual.md`.

## Overview

Both options below use the **same example scenario** on purpose, so what's being compared is
behavior, not just which control looks nicer:

> A page has one layer, `hero`, with two authored animations spanning the same scroll range:
> a **Translate** (slides in from the left) and an **Alpha** (fades in). Today, per
> `01-requirements.md`'s Problem Statement, neither actually plays — this doc assumes the shared
> prerequisite (**B**, the interpolation engine) has been built, so the mockups can show what
> *authoring* feels like once animations genuinely work, under each candidate model.

Reading order: A1 first (restore scroll-as-time), then A2 (bidirectional bridge), then a
side-by-side Notes section with the pros/cons Requirements asked for.

### A note on "scrolling" — pan vs. zoom, verified against real code

Confirmed against Flutter's `InteractiveViewer` source (`interactive_viewer.dart:885-936`), given
this app sets `trackpadScrollCausesScale: false` (`canvas_view.dart:58`):

| Input | Effect today |
|---|---|
| Mouse scroll wheel | **Zoom** in/out |
| Trackpad two-finger scroll | **Pan** (moves through the document) |
| Click-and-drag (either device) | **Pan** |
| Pinch gesture | **Zoom** |

Everywhere below, **"scroll"/"scrolling the canvas" means *pan* (drag, or two-finger trackpad
scroll) — never the mouse wheel, which zooms today and would keep doing so under either option.**
Zoom level is orthogonal to "time" in both A1 and A2: it changes how large `hero` looks, never
which point in the document's animation range you're at. Only pan position maps to time.

---

## Option A1 — Restore scroll-as-time

No independently-draggable timeline. The canvas's own vertical scroll position *is* "time," full
stop — matching v2.8. A slim, non-interactive position strip along the top shows where you are in
the document as a fraction, purely for orientation (not a control).

### Screen: Canvas at the top of the document (scroll = 0%)

```
+--------------------------------------------------------------------------------+
|  Comics Editor 3.0   beach.comics                                    [Save]    |
+--------------------------------------------------------------------------------+
|  position: [#-------------------------------------------] 0%   <- read-only    |
+--------------------------------------------------------------------------------+
|                                                                                  |
|     +----------------------------------------------------------------+         |
|     |                                                                  |        |
|     |    (top of page -- hero not visible yet, its Translate/Alpha    |        |
|     |     keyframes haven't started: alpha=0, off-screen left)        |        |
|     |                                                                  |        |
|     |                                                                  |        |
|     +----------------------------------------------------------------+         |
|                                                                                  |
+--------------------------------------------------------------------------------+
```

### Screen: same canvas, scrolled halfway into hero's animation range

```
+--------------------------------------------------------------------------------+
|  Comics Editor 3.0   beach.comics                                    [Save]    |
+--------------------------------------------------------------------------------+
|  position: [#####################-------------------------] 41%  <- moved      |
+--------------------------------------------------------------------------------+
|                                                                                  |
|     +----------------------------------------------------------------+         |
|     |                                                                  |        |
|     |        (hero) <-- half-slid-in from the left, alpha ~50%,       |        |
|     |         because *panning the canvas* (drag, or two-finger       |        |
|     |         trackpad scroll) is what advanced the animation -- no   |        |
|     |         separate scrub happened. Zooming with the mouse wheel   |        |
|     |         would NOT move this -- zoom is orthogonal to time.      |        |
|     |                                                                  |        |
|     +----------------------------------------------------------------+         |
|                                                                                  |
+--------------------------------------------------------------------------------+
```

The corrector never touched a timeline control at all in this scenario — they panned the canvas
normally (drag, or two-finger trackpad scroll — as if reading/positioning the page), and that pan
position *is* what advanced `hero`'s animation. This is the direct, one-value model: pan position
↔ animation time, always exactly in sync, because they're the same number by construction (no
separate state to drift apart). Zooming in/out to see detail doesn't touch it either way.

### Optional: interactive position strip (if kept draggable)

```
|  position: [#####################O------------------------] 41%               |
                                    ^ drag this to scrub -- dragging it PANS      |
                                      the canvas to match, it doesn't move        |
                                      independently                              |
```

If this strip is made draggable at all (Should Have, not required), dragging it must pan the
canvas — there is still only one value, just two ways to move it (drag/trackpad-scroll the canvas
directly, or drag the strip).

---

## Option A2 — Bidirectional bridge, keep the Gantt

Today's horizontal Timeline stays the primary, familiar control. It gets wired to canvas pan
position both ways: scrubbing it pans the canvas; panning the canvas moves it. Two visible values,
mechanically kept equal. Zoom stays completely separate from both, exactly as it is today.

### Screen: scrubbing the Timeline (canvas auto-scrolls to follow)

```
+--------------------------------------------------------------------------------+
|  Comics Editor 3.0   beach.comics                                    [Save]    |
+--------------------------------------------------------------------------------+
|                                                                                  |
|     +----------------------------------------------------------------+         |
|     |                                                                  |        |
|     |        (hero) <-- half-slid-in, alpha ~50% -- canvas just        |        |
|     |         auto-panned here BECAUSE the playhead below moved,       |        |
|     |         not because anyone panned it directly                    |        |
|     |                                                                  |        |
|     +----------------------------------------------------------------+         |
+--------------------------------------------------------------------------------+
|  TIMELINE                                                                       |
|  hero · Translate  [========O--------------------------------------]           |
|  hero · Alpha      [========O--------------------------------------]           |
|                             ^ dragged here by the corrector                     |
|  0 ----------------------- 246/600 ------------------------------------ 600    |
+--------------------------------------------------------------------------------+
```

### Screen: panning the canvas directly (Timeline playhead follows)

```
+--------------------------------------------------------------------------------+
|  Comics Editor 3.0   beach.comics                                    [Save]    |
+--------------------------------------------------------------------------------+
|                                                                                  |
|     +----------------------------------------------------------------+         |
|     |                                                                  |        |
|     |        (hero) <-- corrector panned the canvas directly (drag,    |        |
|     |         or two-finger trackpad scroll) to look further down      |        |
|     |                                                                  |        |
|     +----------------------------------------------------------------+         |
+--------------------------------------------------------------------------------+
|  TIMELINE                                                                       |
|  hero · Translate  [==============O----------------------------------]         |
|  hero · Alpha      [==============O----------------------------------]         |
|                                   ^ playhead moved on its own, matching         |
|                                     the new pan position                        |
|  0 --------------------------- 318/600 --------------------------------- 600   |
+--------------------------------------------------------------------------------+
```

### State: what happens today (the bug this whole flow exists to fix), for contrast

```
+--------------------------------------------------------------------------------+
|     (hero) <-- stuck at its static, drag-set position; panning OR              |
|      scrubbing does nothing to it                                              |
+--------------------------------------------------------------------------------+
|  TIMELINE                                                                       |
|  hero · Translate  [========O--------------------------------------]           |
|  hero · Alpha      [========O--------------------------------------]           |
|                     scrubbed here -- canvas did NOT move; panning the          |
|                     canvas separately would NOT move this playhead either       |
+--------------------------------------------------------------------------------+
```

---

## Flow: how the two models differ under one interaction

```
A1 (one value):
  [pan canvas: drag / trackpad scroll] --> [pan position] ------> [Anim interpolation] --> [hero moves]
  [drag position strip, if any] -------> [pan position] ------> [Anim interpolation] --> [hero moves]
  [zoom: mouse wheel / pinch] ---------> [zoom level] --X (orthogonal -- never read for Anim)
  (only one arrow ever writes "pan position" -- nothing to keep in sync)

A2 (two values, bridged):
  [pan canvas: drag / trackpad scroll] --> [pan position] --+
                                                              +--> [Anim interpolation] --> [hero moves]
  [drag Timeline playhead] ---------------> [playhead] -----+
                    ^                            |
                    +------ sync both ways ------+
  [zoom: mouse wheel / pinch] ---------> [zoom level] --X (orthogonal -- never read for Anim)
  (two arrows write two different values; a bridge keeps them equal every frame)

Today (neither, the bug):
  [pan canvas: drag / trackpad scroll] --> [pan position] --X (nothing reads this for Anim)
  [drag Timeline playhead] -------------> [playhead] -------X (nothing reads this for Anim)
  [Anim interpolation] does not exist -- hero's position is a static Offset, set once by a drag
```

---

## Component: Device visibility overlay (works under either A1 or A2)

Anton's proposal, in response to Group C's still-open "different devices, different aspect
ratios" question: show, directly on the timeline/position strip, (1) what's on-screen *right now*
at the editor's current zoom, and (2) fixed reference marks for how the document would actually
paginate on real target devices — so a corrector can see, while authoring, whether an animation or
story beat lands awkwardly at a device's screen edge.

**The math, worked out concretely (not just "devices differ")**: under the already-confirmed
fixed-width/scale-to-fit-width model, one screenful of document height =
`doc.width × (deviceScreenHeight / deviceScreenWidth)`. For a 1080px-wide document:

- **iPad** (~4:3, aspect ≈ 1.33): ≈1440 doc-px visible per screen
- **iPhone** (~19.5:9, aspect ≈ 2.17): ≈2344 doc-px visible per screen

**Non-obvious result worth seeing, not just reading**: the iPhone — the physically smaller device
— shows *more* of the document per screen than the iPad, because everything normalizes to width
and the iPhone is proportionally much taller. iPhone guide marks should therefore be **sparser**
(further apart) than iPad's, not denser — easy to get backwards without a picture, which is
exactly the point of building this.

These are two different, complementary things, not one:

| | Current live viewport | Per-device screenful guides |
|---|---|---|
| Source | Editor's own `canvasViewport` zoom/pan | A device profile (screen width×height), fixed |
| Changes when | You zoom or pan | Never, until you edit the device profile |
| Purpose | "What am I looking at right now" | "How will a real reader's screen actually break this up" |

### Screen: A2's Timeline with both overlays added

```
+--------------------------------------------------------------------------------+
|  TIMELINE                                                                       |
|  hero · Translate   [========O--------------------------------------]          |
|  hero · Alpha       [========O--------------------------------------]          |
|  VISIBLE NOW        [=====[#####]===================================]          |
|                            ^ live band -- your current zoom/pan window,        |
|                              moves as you scroll or zoom                       |
|  iPad screenfuls    ¦    ¦    ¦    ¦    ¦    ¦    ¦    ¦    ¦    ¦    ¦        |
|  iPhone screenfuls  ¦        ¦        ¦        ¦        ¦        ¦             |
|                     ^ fixed, device-specific spacing -- iPhone's marks are      |
|                       sparser because it shows MORE per screen than iPad does   |
|  0 ----------------------- 246/600 ------------------------------------ 600   |
+--------------------------------------------------------------------------------+
```

### Screen: A1's position strip with both overlays added

```
|  position: [#####################O------------------------] 41%               |
|  visible:  [#####################[###]---------------------]  <- live band     |
|  iPad:     ¦   ¦   ¦   ¦   ¦   ¦   ¦   ¦   ¦   ¦   ¦   ¦   ¦   ¦   ¦   ¦        |
|  iPhone:   ¦      ¦      ¦      ¦      ¦      ¦      ¦      ¦      ¦           |
```

### Notes on this component

- A corrector should be able to configure/select which device profiles show guides for (at least
  iPad + iPhone per Anton's example) — this implies a small device-profile concept (name, screen
  width×height or just aspect ratio) doesn't exist anywhere in the app today and would be new,
  small scope, not a blocker to building the rest of this component.
- This is genuinely independent of the A1-vs-A2 decision — both options have *some* horizontal
  strip representing position (a full Gantt in A2, a slim indicator in A1), and this overlay draws
  on top of either one the same way.
- This does not, by itself, resolve Group C's aspect-ratio question ("how should comics be
  assembled/displayed for different ratios") — it's a *visibility* aid for whatever the answer
  turns out to be, not a pagination or reflow mechanism. Worth noting explicitly so it isn't
  mistaken for solving more than it does.

---

## Notes — pros/cons

| | **A1 — restore scroll-as-time** | **A2 — bidirectional bridge** |
|---|---|---|
| Fidelity to v2.8 | Exact — same model, same guarantee (one value can't drift from itself) | Approximates it — two values kept in sync by code, not identity |
| Legibility as "time" | Weaker — a scroll thumb reads as "position in a document," not obviously as "animation time," especially for animations that don't span the whole visible page | Stronger — a horizontal Gantt bar is the convention every other timeline/NLE tool already uses; multi-track view (multiple `Anim`s per layer, multiple layers) is naturally visible |
| Rework vs. today's code | Timeline widget's role shrinks to an indicator (or a thin scroll-proxy) — less new code, but a real UX step back from the current Gantt view for anyone who's gotten used to it | Keeps `timeline.dart` largely as-is; adds a bridge writing `canvasViewport` from `playhead` and vice versa — more moving parts, but preserves the existing, already-built Gantt UI |
| Risk of "sync bugs" | None structurally — there's only one value | Real, ongoing risk — any future feature that moves one side without going through the bridge silently reintroduces today's exact bug |
| Best fit for a ~30:1-tall document | Arguably better — scrolling *is* the natural way to move through something this tall; a 0-600 playhead abstracts that away | Timeline gives a compact overview of the *whole* animation timing without needing to scroll 33000px to see it — a real advantage A1 doesn't have |

Both options still require **B** (the interpolation engine) before either one does anything —
neither table row above changes that.

---

## Approval

- [ ] Reviewed by:
- [ ] Approved on:
- [ ] Notes:
