# Status: vdd-comics-editor-timeline

## Current Phase

SPECIFICATIONS

## Phase Status

SUPERSEDED IN PRACTICE, NOT FORMALLY ADVANCED — Requirements + Visual APPROVED 2026-08-01,
Specifications DRAFTED but never formally approved here. Anton redirected to a new, narrower flow
(`vdd-comics-editor-vertical-scroll`) instead of approving this one's Specifications — see "Current
real-world state" below for what actually happened and what that means for this flow now. Parked
briefly in `flows/_blamed/` (found there 2026-08-02, apparently archived, then moved back by Anton
before this update), now reactivated at Anton's explicit request to bring it up to date.

## Last Updated

2026-08-02 by Claude

## Current real-world state (2026-08-02) — read this before anything else here

This flow never reached "specs approved." Instead, Anton asked for a new, narrower flow —
`vdd-comics-editor-vertical-scroll` — to do a literal 1:1 port of `legacy/comics-editor-v2.8`'s
vertical scroll, using this flow only to locate files/functions, not to inherit its ideas. That
flow has since gone all the way through Implementation, with real, shipped code in
`apps/comics-editor`. Reconciling what that means for each of this flow's own artifacts:

- **The single biggest risk this flow ever flagged (the `Anim.start`/`end` unit-mismatch) is fully
  resolved** — not empirically as planned here, but by reading `Layer.Create`/`Anim.Add<T>`
  directly. There is no scale factor; `currentTime = raw pan pixels` was correct all along. Fixed
  in `03-specifications.md`'s Investigation Note, Testing Strategy, and Migration/Rollout sections.
- **Three of this flow's four Open Design Questions match what actually shipped**: `currentTime`
  stamping for new keyframes, and no opt-in toggle. Consistent.
- **⚠️ One contradicts what actually shipped**: this flow decided "delete the Timeline widget
  outright." The sibling flow's Anton explicitly said the opposite — leave `timeline.dart`
  untouched, deal with it later. It's still there today, now reading a vestigial, disconnected
  `playhead`/`totalFrames` while the real interpolation engine runs on `currentTime`. **Genuinely
  unresolved — needs a decision**, not something to silently pick a side on.
- **The device-visibility overlay (`DeviceProfile`, this flow's own Should Have) was never built
  anywhere.** The sibling flow explicitly excluded it as "not part of legacy's actual behavior" per
  its own narrower, literal-port mandate. If Anton still wants it, this flow (or a new one) is where
  that work would need to happen — it's real, wanted, unbuilt scope, not abandoned.
- **What this flow got right that mattered**: the "single source of truth" framing, the discovery
  that sound shares the same scroll value as visual layers, the leg-swing/idle-loop gap (still
  unaddressed anywhere, consistent across both flows), and the mobile-viewer correction (the
  position-driven engine already existing in `comics-viewer-android`) — all of this held up and
  fed directly into the sibling flow's own Requirements.

## Blockers

- **Needs Anton's decision on the Timeline contradiction** (see above): now that `timeline.dart`
  is live-disconnected from `currentTime` (renders newly-authored keyframes off-scale), does this
  flow's original "delete outright" verdict get carried out, or does something else happen to it?
- **Needs Anton's direction on the device-visibility overlay**: still wanted? If so, this flow could
  be narrowed to just that remaining scope and taken to Plan/Implementation; if not, this flow can
  be considered fully closed (its substantive scope having shipped via the sibling flow).

## Progress

- [x] Requirements drafted
- [x] Requirements approved
- [x] Visual drafted
- [x] Visual approved
- [x] Specifications drafted
- [ ] Specifications approved
- [ ] Plan drafted
- [ ] Plan approved
- [ ] Implementation started
- [ ] Implementation complete
- [ ] Documentation drafted
- [ ] Documentation approved

## Context Notes

- **This flow is decision-support, not a committed build.** Its Must Have deliverable is a clear
  visual comparison of two candidate approaches (A1: restore v2.8's scroll-as-time model; A2:
  bidirectional bridge keeping today's horizontal Timeline as the primary control) so Anton can
  pick a direction — it does not build either one yet. Once a direction is picked (via Visual
  review), Specifications proceeds with only the chosen option.
- **Root cause, not just orientation**: the real finding driving this flow is that `playhead`
  (Timeline scrub value) and `canvasViewport` (actual scroll) are completely unlinked today, and
  `Anim`/`TranslateAnim` keyframes don't drive anything at all in either the editor or the real
  mobile viewer — the whole animation-timeline system is currently inert/decorative. Both A1 and
  A2 need the same missing interpolation engine (labeled "B" throughout) built regardless of which
  UX direction wins; visualizing A1/A2 doesn't make B optional.
- **Explicitly deferred, not decided against**: a bigger "per-region, scroll-triggered" animation
  model (closer to web scrollytelling, possibly better suited to ~30:1-tall documents than one
  global 0..600 playhead) came up during investigation but is out of scope for this flow — named
  in `01-requirements.md` so it isn't lost, not silently dropped.
- Forked in spirit (not a literal `fork` command) from
  `flows/sdd-comics-editor-questions/01-requirements.md`'s Group C — that doc's investigation
  (real file:line citations against v2.8 WPF source and current Flutter/mobile code) is treated as
  verified background here, not re-derived.

## Corrections

- **2026-08-01**: Anton caught an inaccuracy in the first draft of `02-visual.md` — it described
  "scrolling the mouse wheel" as advancing time/pan position. Verified against Flutter's real
  `InteractiveViewer` source (`interactive_viewer.dart:885-936`) and this app's actual config
  (`trackpadScrollCausesScale: false`, `canvas_view.dart:58`): **mouse wheel zooms, two-finger
  trackpad scroll pans, click-drag pans, pinch zooms** — the opposite of what the mockup implied
  for mouse wheel specifically. Fixed throughout `02-visual.md`: every "scroll/pan" reference now
  correctly means drag/trackpad-scroll, with zoom called out explicitly as orthogonal to time in
  both A1 and A2 (zoom level never maps to animation position either way).

## Discoveries (2026-08-01, same day, after initial draft)

Three follow-up questions from Anton, each investigated against real code before being answered
or folded into the docs (not left as assumptions):

1. **"Single source of truth" principle stated** — confirmed this maps directly to A1 (one value)
   vs. A2 (two values, bridged); Anton's principle points toward A1, not yet a final decision.
2. **Was sound also on the vertical scroll in v2.8?** Yes, confirmed, and more significantly: the
   *same single `Scroll` value* drove both visual layers and audio (`ComicsViewModel.cs:158-184`),
   and **the real, currently-shipping Android viewer library still does this today**
   (`comics-viewer-android/.../Comics.java:80-88`) — strong evidence this is proven production
   architecture, not just legacy debt. Routed into `01-requirements.md`'s Problem Statement.
3. **What about looping motion (e.g. a leg swinging) while scroll is stationary?** Real gap found:
   nothing in this system supports continuous/looping visual motion independent of scroll —
   `TranslateAnim.Interpolate` is a pure function of scroll with no clock, and no `AnimType` has a
   loop concept. Sound already has the needed shape (scroll gates on/off, real `MediaPlayer` clock
   drives playback while active) — prerequisite **B** needs to replicate that shape for visual
   properties too, not just interpolate position from scroll. This is orthogonal to A1 vs. A2 (both
   only decide the gating value) but materially expands B's known scope. Routed into
   `01-requirements.md`'s Problem Statement and the B section.
4. **Device visibility overlay proposal** (Anton): show a live viewport band + fixed per-device
   "screenful" guide marks on the timeline/position strip. Worked out the actual math
   (`doc.width × deviceAspectRatio` per screen) and found a genuinely non-obvious, concrete result
   worth showing: an iPhone displays *more* document height per screen than an iPad (~2344 vs.
   ~1440 doc-px for a 1080px-wide doc), because pagination normalizes to width and iPhone is
   proportionally taller. Added as a new Should Have + a full mockup component (both A1 and A2) in
   `02-visual.md`. Explicitly scoped as a visibility aid, not a solution to the aspect-ratio
   question itself.

## Major correction (2026-08-01, after approval, before Specifications)

An earlier claim — "the real end-user viewer has no keyframe concept at all" — was **wrong**,
caught before it could shape Specifications incorrectly. It was based on an investigation scoped
only to `apps/mahabharata-mobile-java-v2026`'s own source; the real rendering logic lives in a
separate, live, shipping library the first pass missed: `libs/comics_viewer/comics-viewer-android`
(confirmed consumed, not orphaned, via `settings.gradle`/`build.gradle`). That library has a
**complete, working, position-driven interpolation engine for all four visual types**
(`Layer.java:118-143`, `LayerAnim.java:8-17` — same start/end-range-lookup-and-interpolate shape as
v2.8's `TranslateAnim.Interpolate`, plus a cubic ease-out curve). **This gap is editor-only, not
cross-app.** Real readers already see correct position-driven animation today; only the Flutter
editor's live preview is missing it. This substantially de-risks and narrows prerequisite B's
position-driven half (a porting task, not a design problem) while leaving the
time-driven-while-in-range half exactly as novel/missing as previously found (confirmed absent in
this same real library too — only Sound loops there).

## Next Actions

1. Draft `03-specifications.md` for the approved direction (A1), scoped to:
   - Retire the independently-draggable `playhead`/Timeline scrub; make `canvasViewport` pan
     position the single source of truth (per `02-visual.md`).
   - Port the proven `libs/comics_viewer/comics-viewer-android` position-driven interpolation
     engine (`LayerAnim`/`TranslateAnim`/`ScaleAnim`/`RotateAnim`/`AlphaAnim`, including the cubic
     ease-out) into Dart, wired into `canvas_view.dart`'s rendering — this is the concrete,
     low-risk shape of prerequisite B's position-driven half.
   - The device visibility overlay (Should Have).
   - **Explicitly excluded from this flow's Specifications**: time-driven-while-in-range/idle-loop
     animation for visual properties, and sound triggering — both confirmed missing in real
     production code too (not just the editor), both genuinely novel design work, not a port.
     Flagged for a separate follow-on flow given the cross-repo (editor + Android library) reach.
2. Get "specs approved" before Plan, per standard VDD phase discipline.
