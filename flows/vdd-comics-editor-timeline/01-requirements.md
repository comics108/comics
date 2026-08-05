# Requirements: comics-editor-timeline

> Version: 1.3 (Option A1 approved as the chosen direction; corrected a wrong claim about the real
> mobile viewer having no keyframe engine — it does, in a library the first investigation missed,
> which narrows and de-risks prerequisite B's position-driven half considerably)
> Status: APPROVED
> Last Updated: 2026-08-01

> **Relocation note (2026-08-05):** Device dimensions and visibility are no longer Timeline
> requirements. Anton moved them to Properties → General and the Viewer scroll range in
> `vdd-comics-editor-scroll`. The older sections remain only as investigation history.

## Problem Statement

`flows/sdd-comics-editor-questions/01-requirements.md`'s Group C investigation (real code, not
memory) found something more fundamental than the timeline's visual orientation:

- **`playhead`** (the horizontal Timeline's scrub value, `controller.dart:99`, `0..600`) and
  **`canvasViewport`** (the canvas's actual scroll/zoom, `controller.dart:110`) are two completely
  unlinked pieces of state today. Moving one never touches the other — no binding exists in either
  direction.
- **`Anim`/`TranslateAnim` keyframes don't drive anything.** A layer's on-screen position comes
  from `EditorLayer.translate`, a plain `Offset` set once by a drag gesture
  (`controller.dart:627`) and never re-evaluated against time. There is no interpolation code
  anywhere in `apps/comics-editor/lib/` — the horizontal bars in Timeline are decorative metadata
  the app draws, not something it executes.
- **Correction (2026-08-01, caught before Specifications)**: an earlier draft of this doc claimed
  "the real end-user viewer has no keyframe concept at all." Wrong — that was based on an
  investigation scoped only to `apps/mahabharata-mobile-java-v2026`'s own source. The real
  rendering logic is delegated to a separate, live, shipping library,
  `libs/comics_viewer/comics-viewer-android` (confirmed consumed via
  `apps/mahabharata-mobile-java-v2026/settings.gradle:3-4` +
  `app/build.gradle:70`, not orphaned) — and **that library already has a complete, working,
  position-driven interpolation engine for all four visual types**: `Layer.java:118-143` walks
  each property's sorted keyframe list to find the surrounding `[start,end]` anim pair for the
  current `scrollOffset`, and `LayerAnim.java:8-17` computes a cubic-ease-out fraction and
  interpolates — the same start/end-range-lookup-and-interpolate shape as v2.8's
  `TranslateAnim.Interpolate`, evidently a real Java port of it (plus an easing curve neither v2.8
  nor the Flutter editor has). **So this gap is not cross-app — it's isolated to the Flutter
  editor.** The real production app already renders position-driven visual animation correctly for
  actual readers today; only the editor's own live preview is missing it.
- For contrast: the original v2.8 WPF editor had no separate timeline at all — "time" *was*
  literally the vertical `ScrollViewer`'s scroll offset, fed straight into
  `TranslateAnim.Interpolate(Anim, double scroll)` (`native/Comics.Editor/Models/
  TranslateAnim.cs:43-51`). Scroll position and animation time were the same number, by
  construction — there was nothing to keep in sync because there was only one value.

**Sound was on the same single value too, not a separate mechanism** (2026-08-01, verified):
`Sound.Create()` seeds a `SoundAnim { Start = scroll, End = scroll }` — the identical range concept
as `TranslateAnim` (`Models/Sound.cs:40`), and `ComicsViewModel.Scroll`'s setter drives *both*
`layer.Scroll()` and `sound.Scroll()` from the same value every scroll tick
(`ComicsViewModel.cs:158-184`). `SoundViewModel.Scroll()` triggers real `MediaPlayer.Play()`/
`Stop()` based on scroll-range membership (`SoundViewModel.cs:124-138`) — and **the real,
currently-shipping Android viewer does the same thing today**, for actual readers:
`Comics.process(scrollOffset)` drives both visual matrices and `sound.process()` from one shared
value (`comics-viewer-android/.../Comics.java:80-88`). This is strong evidence "one value drives
everything" isn't just old technical debt — it's the model the real, production rendering engine
still depends on. (Confirmed inert in the current Flutter editor too, same as visual `Anim` — no
audio package imported anywhere in `controller.dart`.)

**A real gap found via a follow-up question, affecting B's scope regardless of A1/A2** (2026-08-01):
what if an animation needs to keep moving while scroll is *stationary* — e.g. a character's leg
swinging back and forth while the reader has stopped scrolling? Checked: nothing in this system,
at any layer (v2.8, current editor, or the real viewer), supports this for visual properties.
`TranslateAnim.Interpolate(Anim, double scroll)` is a **pure function of scroll** — no clock, no
looping concept anywhere in the `AnimType` enum (`translate, rotate, scale, alpha, sound` —
`models.dart:43` — or any of the 5 C# `*Anim.cs` files). If scroll stops, every visual animation
freezes exactly where it is. Sound, however, already reveals the fix: it doesn't compute audio
*position* as `f(scroll)` — scroll only *gates* playback on/off, and once triggered, real audio
plays on the `MediaPlayer`'s own clock, independent of further scrolling. **Prerequisite B needs
two distinct keyframe behaviors, not one**: position-driven (current `TranslateAnim` shape — pure
function of scroll/playhead, correct for "slide in as you scroll past") and
time-driven-while-in-range (new for visual properties — scroll/playhead gates on/off, a real
`Ticker` drives looping motion while active, mirroring Sound's already-proven shape). This is
orthogonal to A1 vs. A2 — both options only decide what drives the *gating* value.

This flow exists to resolve **how scroll position and the timeline should relate** before any of
that missing interpolation engine gets built — building the engine against the wrong UX model
would need redoing. Per Anton's request, this flow's deliverable is a clear, visual comparison of
the two live candidate approaches (**A1**: restore scroll-as-time; **A2**: bidirectional bridge,
keep the modern horizontal timeline as the primary control) so a real choice can be made before
Specifications commits to one.

## Candidate Approaches (both to be visualized — no decision made yet)

### Option A1 — Restore scroll-as-time (closer to v2.8)

Canvas scroll position becomes the single source of truth for "time" again. The horizontal
Timeline stops being an independently-draggable scrubber and instead becomes a position
indicator/overview of where the current scroll sits — or, if kept draggable, dragging it scrolls
the canvas directly (one value, two views of it), matching v2.8's actual model rather than
approximating it.

### Option A2 — Bidirectional bridge, keep the Gantt as primary

`playhead` stays the primary authoring control (matches every other NLE/animation-tool
convention, more legible as "time" than a scroll thumb), but gets wired to `canvasViewport` both
ways: scrubbing the Timeline auto-scrolls the canvas to the matching position, and manually
scrolling the canvas updates the playhead to match. Two values, kept in sync, neither one silently
drifting from the other the way they can today.

### Shared prerequisite (B) — the interpolation engine, regardless of A1 vs. A2

Something has to actually evaluate `Anim` keyframes against whichever time value wins (scroll
offset directly, or a synced playhead) to compute a layer's live position/scale/rotation/alpha,
and trigger sound — mirroring `TranslateAnim.Interpolate`/`SoundViewModel.Scroll` from v2.8. This
doesn't exist today in either the editor or the mobile viewer, for either content type. Neither A1
nor A2 is useful without it; this flow visualizes A1/A2 as the UX question, but Specifications
(once a direction is picked) will need to scope B as real, non-optional work, not a footnote.

**B has two distinct keyframe behaviors with very different risk profiles** (see the "leg-swing"
finding above and the mobile-viewer correction): a **position-driven mode** — pure function of
scroll/playhead, matching `TranslateAnim`'s existing shape — and a **time-driven-while-in-range
mode** — scroll/playhead gates on/off, a real clock drives looping motion while active, matching
`SoundAnim`'s shape. These are not equally scoped:

- Position-driven is **low-risk, proven, portable work** — `libs/comics_viewer/comics-viewer-
  android`'s `Layer.java`/`LayerAnim.java`/`TranslateAnim.java`/`ScaleAnim.java`/`RotateAnim.java`/
  `AlphaAnim.java` (all four visual types, plus a cubic ease-out curve) is a real, shipping
  reference implementation to port to Dart for the editor's live preview — not a design problem,
  a porting task.
- Time-driven-while-in-range for visual properties is **genuinely new, unproven, and missing
  everywhere** — not built in v2.8, not built in the real Android library (confirmed: no
  `Choreographer`/looping `ValueAnimator` on any visual property there, only Sound loops), not
  built in the Flutter editor. This is real, novel product/architecture work, not a port.

**Also confirmed (worth keeping for later)**: the real Android app's autoplay feature
(`ComicsViewController.java`) doesn't use a separate wall-clock animation system either — it's a
~60fps `Handler` loop that monotonically auto-advances the *virtual scroll position* itself, then
feeds that into the exact same `comics.process(scrollOffset)` pipeline as manual scrolling
(`ComicsViewController.java:89-122`). This is a useful precedent if "auto-play" is ever wanted
under a pure scroll-driven model: advance the single source of truth automatically, rather than
building a second parallel clock.

### Device visibility overlay (Should Have — Anton's proposal, addresses part of Group A's aspect-ratio open question)

Show, on whichever position/timeline control A1 or A2 produces: (1) a live band showing what's
currently on-screen at the editor's own zoom (dynamic), and (2) fixed reference marks for how the
document would actually paginate on real target devices (e.g. iPad + iPhone), computed as
`doc.width × deviceAspectRatio` per screenful. Concrete, non-obvious motivator: an iPhone shows
*more* document height per screen than an iPad (≈2344 vs. ≈1440 doc-px for a 1080px-wide document),
because pagination normalizes to width and the iPhone is proportionally taller — easy to get
backwards without seeing it. Requires a small, new device-profile concept (name + screen
width×height or aspect ratio) that doesn't exist anywhere in the app today. Does **not** by itself
solve "how comics should be assembled/displayed for different ratios" — it's a visibility aid for
whatever that answer turns out to be, not a pagination/reflow mechanism. See `02-visual.md`'s
"Device visibility overlay" component for mockups under both A1 and A2.

### Named but deliberately out of scope for this flow

A third, bigger framing came up during investigation: given real documents run ~30:1 tall, a
single document-wide `0..600` playhead may be the wrong shape entirely — a per-region,
scroll-triggered model (an animation plays as *its own span* scrolls into view, closer to web
"scrollytelling" patterns) might fit a 33000px-tall canvas better than one global timeline. That's
a materially bigger architectural question than A1-vs-A2 and is **not** visualized in this flow —
flagged here so it isn't lost, tracked instead as a follow-up open question (see below).

## User Stories

### Primary

**As an** editor user authoring layer animations
**I want** the Timeline's scrub position and the canvas's scroll position to never silently
disagree with each other
**So that** what I see while authoring (canvas position) always matches what I'm scrubbing
(timeline position) — today they can point at completely different places with no warning

### Secondary

- **As** Anton, deciding the editor's animation model
  **I want** to see both candidate approaches (A1, A2) mocked up concretely, side by side
  **So that** I can pick a direction from something tangible rather than from prose description
  alone

## Acceptance Criteria

### Must Have

1. **Given** this flow's Visual phase
   **When** both A1 and A2 are mocked up
   **Then** each mockup shows the same concrete scenario (a document with a couple of authored
   animations) under both models, so the *difference in behavior* — not just a different-looking
   control — is what's being compared
2. **Given** the shared prerequisite (B)
   **When** either option is visualized
   **Then** the mockups and this doc are explicit that neither A1 nor A2 alone makes animations
   actually play back — B is required either way, not an implementation detail that disappears
   once a UX direction is picked
3. **Given** a decision is made after Visual review
   **Then** Specifications proceeds with *only* the chosen option — this flow does not build both

### Should Have

- A short, explicit pros/cons framing for A1 vs. A2 in the Visual doc (not just mockups), covering
  at minimum: fidelity to v2.8, discoverability/legibility as "time," and how much rework each
  implies given today's code (per the Problem Statement's findings)
- The device visibility overlay (see Candidate Approaches above), mocked under both A1 and A2 —
  not required to reach a decision on A1-vs-A2, but requested alongside it and cheap to visualize
  together

### Won't Have (This Iteration)

- Building the interpolation engine (B) itself — scoped to whichever flow picks this up after a
  direction is chosen, likely as its own Specifications/Plan given it touches both the editor and
  the mobile viewer
- The per-region/scroll-triggered "third framing" — explicitly deferred, not decided against
- Any change to the mobile viewer (`apps/mahabharata-mobile-java-v2026`) — visualized/considered
  only insofar as it explains *why* B is a real, cross-app prerequisite

## Constraints

- **Technical**: Whichever option is chosen must not break existing `.comics` files —
  `Anim`/`TranslateAnim` records already exist in real saved documents (as inert data today); a
  working interpolation engine must interpret them correctly, not require re-authoring.
- **Dependencies**: This flow's Visual comparison depends on the findings already investigated in
  `flows/sdd-comics-editor-questions/01-requirements.md` (Group C) — treat that doc as verified
  background, not something to re-derive.

## Open Questions

- [x] Which of A1/A2 does Anton prefer, once visualized? **Decided: A1 (restore scroll-as-time)**,
      approved 2026-08-01 — consistent with the "single source of truth" principle stated earlier
      in the same session.
- [ ] Is the per-region/scroll-triggered "third framing" worth a dedicated follow-up flow, or does
      picking A1/A2 make it moot? Deferred, not answered here.
- [x] Once a direction is picked, does the interpolation engine (B) become this same flow's
      Specifications scope, or a separate flow? **Decided: this flow's Specifications scope, but
      only the position-driven half** (the proven, portable Android engine) — see
      `03-specifications.md`. The time-driven-while-in-range/idle-loop half and sound triggering
      are excluded, explicitly deferred to a separate follow-on flow (both are genuinely novel
      design work, not a port, and reach into production Android code outside this flow's stated
      boundary).
- [x] Does the device visibility overlay's device-profile concept (name + screen dimensions/aspect
      ratio) belong in this flow's scope? **Decided: yes, folded in** — specified in
      `03-specifications.md` as a small, fixed, hardcoded `DeviceProfile` list (not part of the
      `.comics` schema), not deferred.

## References

- `flows/sdd-comics-editor-fromat-dot-comics/` — consolidated `.comics` format reference; this
  flow's vertical-strip confirmation (Anton, `03-specifications.md`), `Anim`/scroll-as-time model,
  and sound-on-same-value finding were extracted there alongside `sdd-comics-ai-positioning`'s
  format facts, 2026-08-01
- `flows/sdd-comics-editor-questions/01-requirements.md` (Group C) — the investigation this flow
  is built on; full file:line citations for every claim in the Problem Statement above
- `apps/comics-editor/lib/src/ui/controller.dart` — `playhead` (line 99), `setPlayhead` (506-509),
  `canvasViewport` (line 110), `dragSelected`/`translate` mutation (line 627)
- `apps/comics-editor/lib/src/ui/widgets/timeline.dart` — current horizontal Gantt timeline
- `apps/comics-editor/lib/src/ui/widgets/canvas_view.dart` — `_Stage`'s `InteractiveViewer`
  (canvas scroll/zoom), lines 52-54
- `apps/comics-editor/native/Comics.Editor/Views/ComicsControl.xaml(.cs)`,
  `native/Comics.Editor/ViewModel/ComicsViewModel.cs`,
  `native/Comics.Editor/Models/TranslateAnim.cs` — v2.8's scroll-as-time model
- `apps/comics-editor/native/Comics.Editor/Models/Sound.cs`, `SoundAnim.cs`,
  `native/Comics.Editor/ViewModel/SoundViewModel.cs` — v2.8's scroll-gated, real-time-played sound
  model, confirming "one value drives everything" included audio
- `apps/comics-editor/lib/src/ui/models.dart:43` — `AnimType` enum, confirming no loop/repeat
  concept exists for any visual property today
- `libs/comics_viewer/comics-viewer-android/.../model/Comics.java`, `Sound.java` — the real,
  currently-shipping Android viewer library, confirming the scroll-gated/real-time-played sound
  model is still in production use today, not just legacy v2.8 behavior
- `libs/comics_viewer/comics-viewer-android/src/main/java/net/nativemind/comics/viewer/comics/
  model/Layer.java` (118-143), `animation/LayerAnim.java` (8-17), `TranslateAnim.java`,
  `ScaleAnim.java`, `RotateAnim.java`, `AlphaAnim.java` — the real, shipping, proven
  position-driven interpolation engine for visual properties, confirming this gap is editor-only,
  not cross-app; the reference implementation to port for the Flutter editor's live preview
- `apps/mahabharata-mobile-java-v2026/settings.gradle:3-4`, `app/build.gradle:70` — confirms
  `comics-viewer-android` is a live, consumed dependency, not an orphaned module
- `libs/comics_viewer/comics-viewer-android/.../ComicsViewController.java` (89-122) — the real
  app's autoplay mechanism, confirming it auto-advances virtual scroll position through the
  existing pipeline rather than running a separate clock

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-01
- [x] Notes: Approved with **A1 (restore scroll-as-time) chosen over A2**. Prerequisite B's scope
      (position-driven + time-driven-while-in-range keyframes, plus sound triggering) and the
      device visibility overlay's device-profile concept remain open, to be resolved in
      Specifications. Alongside this approval, `apps/comics-editor`'s version was bumped
      3.1.0 → 3.2.0 (`pubspec.yaml`, `lib/src/app_version.dart`).
- [ ] Approved on:
- [ ] Notes:
