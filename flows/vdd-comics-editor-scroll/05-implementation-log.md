# Implementation Log: comics-editor-scroll

> Started: 2026-08-02
> Plan: [04-plan.md](04-plan.md)

## Progress Tracker

| Task | Status | Notes |
|------|--------|-------|
| 1.1 `end`-default fix | Done | 205/206 suite tests pass; 1 pre-existing unrelated failure |
| 2.1 `KeyframeInterpolator` (translate) | Done | built together with 2.2 |
| 2.2 `KeyframeInterpolator` (scale/rotate/alpha) | Done | 13/13 new unit tests pass |
| 2.3 `controller.dart`: `playhead` → `currentTime` | Done, deviated from Plan | `playhead` kept, not removed — see Discoveries |
| 2.4 Wire `_LayerItem` | Done | 2/2 new widget tests pass |
| 3.1 Fit-width canvas layout | Done | puzzle mode explicitly unaffected |
| 3.2 `boundaryMargin` tuning | Done, real fix needed | `constrained: true` was silently clamping all panning to exactly `boundaryMargin` — see Discoveries |
| 3.3 Zoom-invariant `currentTime` | Done | math self-consistency + real-gesture translation confirmed; real pinch-zoom gesture not separately simulated |
| 4.1 `audioplayers` dependency | Done | macOS debug build succeeds |
| 4.2 `SoundPlayer` gating | Done | 10/10 new unit tests pass |
| 4.3 Wire `SoundPlayer` | Done, unverified path convention | see Discoveries — real playback not automated-tested, per Plan's own manual-verification designation |
| 5.1 Real-file integration test | Done | found + fixed a real stable-sort bug — see Discoveries |
| 5.2 Manual verification pass | Partially done | see Discoveries — real UI/audio interaction not performable in this environment |
| 6.1 Device profiles moved from Timeline | Done | iPad 768×1024, iPhone 390×844; app-level only |
| 6.2 Properties → General | Done | third tab, target chooser, dimensions, ratio, visible height |
| 6.3 Viewer target viewport + range band | Done | selected aspect ratio, travel-aware interval, tap/drag/a11y |
| 6.4 Verification | Done | analyzer clean; 335 pass, 3 expected skips; 4 visual goldens pass |

## Session Log

### Session 2026-08-05 — General target viewport and scroll range

- Moved device-dimension ownership out of `vdd-comics-editor-timeline` and into this scroll flow.
  Timeline artifacts retain only a relocation note/history and no longer track the overlay as a
  blocker or implementation responsibility.
- Added `DeviceProfile` as non-persisted editor state:
  - default iPad `768×1024`;
  - iPhone `390×844`;
  - vertical screenful is `document.width × height / width`.
- Extended Properties to `Selection / Document / General`. General shows the selected target,
  dimensions, aspect ratio, calculated visible strip height/percentage, and explicitly explains
  that the target is independent of the editor's host device.
- Fitted the Viewer surface itself to the selected target aspect ratio with neutral host
  letterboxing. This avoids the desktop window silently determining normalized scroll travel.
- Replaced the right-edge point slider with a selected-device viewport band:
  - two visible boundaries plus filled interval;
  - exact start–end percentage and profile label;
  - tap and drag update in one action;
  - Home/End, Up/Down, increase/decrease semantics;
  - semantics include current, increased, and decreased range values.
- Added unit/widget coverage for profile math, tab order, General profile switching, target aspect
  ratio, visible-range semantics, and rail input.
- Updated and visually inspected four golden references: desktop Editor, Viewer, phone Properties,
  and a new General target-viewport reference.
- Final verification:
  - `flutter analyze`: no issues;
  - `flutter test`: 335 passed, 3 expected environment/fixture skips;
  - focused vertical scroll/currentTime/layout regression set: 18 passed;
  - golden verification: 4 passed.

### Session 2026-08-05 — direction consistency audit

- Rechecked current editor code and the approved bottombar flow against the clarified product
  contract.
- Confirmed current/default Vertical-scroll behavior is internally consistent:
  - comics canvas fits width and retains proportional full height;
  - `currentTime` uses normalized negative Y translation;
  - New Document selects `Vertical-scroll comic strip` by default;
  - `Horizontal-scroll comic strip` and `Landscape` are separate disabled options;
  - Viewer position uses the right edge and is not rotated by device orientation.
- Confirmed the persisted editor model still has only `DocType { comics, puzzle }`; therefore
  existing `.comics` files naturally remain vertical and no accidental aspect-ratio inference is
  present.
- Added an explicit axis contract to requirements, visual, specifications, and plan. Future
  Horizontal-scroll will use width/X/bottom-edge mapping but remains out of current implementation
  scope and requires an explicit backward-compatible persisted scroll type.
- No scroll-engine or layout behavior changed during this audit. The disabled future card's label
  and its widget expectation were normalized from `Horizontal infinity scroll comic strip` to
  `Horizontal-scroll comic strip`.
- Focused verification passed: 16 tests covering New Document/Viewer/Properties, vertical
  interpolation, Y-derived zoom-invariant `currentTime`, fit-width layout, and tall-document pan
  boundaries. `dart format --set-exit-if-changed` also passed for the two touched Dart files.

### Session 2026-08-02 - Claude

**Started at**: Phase 1, Task 1.1
**Context**: Requirements/Visual/Specifications/Plan all approved same day; starting Implementation
fresh.

#### Completed

- **Task 1.1**: Fixed the `end`-default bug found during Specifications.
  `_animFromJson`'s absent-`end` fallback and `_animToJson`'s omit-comparison both moved from `200`
  to `0` (kept in sync, per the file's own existing comment on why they must match); `Anim`'s
  constructor default followed (`200` → `0`).
  - Files changed: `apps/comics-editor/lib/src/bridge/models_mapping.dart` (lines ~68, ~111),
    `apps/comics-editor/lib/src/ui/models.dart` (line 58)
  - Verified by: wrote a new test first (`test/models_mapping_test.dart`, "animation with no end
    key parses as end=0 and stays keyless on save"), ran it against the unfixed code to confirm it
    failed exactly as expected (`Actual: <200>`), then applied the fix and re-ran — passes. Full
    suite run afterward: 205/206 pass; the one failure
    (`dataset_backward_compat_test.dart`'s dataset-reachability sanity check) is pre-existing and
    unrelated — it lists `dataset/` non-recursively for `.comics` files, but real files live nested
    under `dataset/boranko/mahabharata/book1/comics_interactive/`, so it finds 0 regardless of this
    change. Confirmed by reading the test's own listing logic (`Directory.listSync()`, not
    recursive) rather than by reverting my change, per not running `git stash`.

- **Tasks 2.1-2.2**: Built `KeyframeInterpolator` (`lib/src/ui/anim/keyframe_interpolator.dart`)
  covering all four visual `AnimType`s at once, since 2.2 was mechanically identical to 2.1 per the
  Plan's own note. Faithful port of `FindNearest`/`Factor`/`Interpolate`, including the non-obvious
  detail that pivot is never eased (snaps straight to `curr`'s own pivot).
  - Files changed: `lib/src/ui/anim/keyframe_interpolator.dart` (new)
  - Verified by: `test/keyframe_interpolator_test.dart`, 13 tests covering cubic ease-out, all
    `FindNearest` cases (including a genuine, non-obvious distinction between "no anims of this
    type at all" → caller fallback, vs. "inside the very first anim's range with nothing yet
    completed" → interpolate from the type's own resting default, NOT the caller fallback — my
    first draft of this test got this wrong and was corrected before being trusted), all four
    types' resting defaults, and confirming the `curr.end==curr.start` guard is structurally
    unreachable through the public API (a real invariant, not just a rare case — my first version
    of that test and its accompanying code comment incorrectly implied real/hand-edited data could
    trigger it; fixed both).
- **Task 2.3**: Added `EditorController.currentTime`, wired `addAnim`/`addSound` to it.
  **Deviated from the Plan/Specifications' original design** (see Discoveries) — `playhead`/
  `setPlayhead`/`totalFrames` were NOT removed; they remain fully intact, and `currentTime` is an
  additional, independent getter.
  - Files changed: `lib/src/ui/controller.dart`
  - Verified by: `test/current_time_test.dart`, 5 tests — `currentTime` at rest, after a pan, its
    zoom-invariance (self-consistency of the formula against a directly-set `Matrix4`, NOT yet a
    real-gesture verification — that's still Task 3.3), and that `addAnim`/`addSound` now stamp
    from `currentTime` while `playhead` stays fully untouched.
- **Task 2.4**: Wired `_LayerItem` (`canvas_view.dart`) to `KeyframeInterpolator`, wrapped in an
  `AnimatedBuilder(animation: c.canvasViewport, ...)` so it rebuilds on pan (canvasViewport is a
  separate `ValueNotifier` from `EditorController`, so `EditorScope`'s own rebuild-on-`notifyListeners`
  wouldn't otherwise catch pan-driven changes). Composed scale (inner) inside rotate (outer),
  matching legacy's `LayersControl.xaml` nesting order; wrapped in `Opacity` for alpha.
  - Files changed: `lib/src/ui/widgets/canvas_view.dart`
  - Verified by: `test/canvas_view_interpolation_test.dart`, 2 widget tests — held position before
    an anim range, and a real position change after panning past it. (First draft's `Positioned`
    finder accidentally matched `CanvasView`'s own outer `Positioned.fill`, not the layer's —
    caught by the assertion failing with `top: 0.0`, fixed by indexing to the correct widget.)

#### Deviations from Plan

- **Task 2.3**: Plan/Specifications said `playhead`/`setPlayhead`/`totalFrames` would be REMOVED.
  During implementation, grepping for `playhead` usage found `timeline.dart` deeply dependent on it
  as a closed 0..600 coordinate system (bar widths, thumb position, frame text) — not an incidental
  reference. Given Anton's explicit "leave `timeline.dart` alone," removing `playhead` would have
  broken that widget outright. **Stopped and asked Anton directly** (rather than guessing) whether
  newly-authored keyframes should stamp from `currentTime` (fully realizing Acceptance Criterion 6,
  at the cost of `timeline.dart` rendering new keyframes off-scale until its own later redesign) or
  keep using `playhead` for authoring specifically (zero risk to `timeline.dart`'s rendering, at the
  cost of Criterion 6 staying partially unmet). **Anton chose `currentTime`.** Implemented by
  keeping `playhead`/`setPlayhead`/`totalFrames` completely untouched (so `timeline.dart` still
  compiles and behaves exactly as before) while adding `currentTime` as a new, separate getter used
  only by `addAnim`/`addSound`/the interpolation engine. `playhead` is now fully vestigial outside
  `timeline.dart` itself — an accepted, disclosed consequence, not a silent one.

#### Discoveries

- Confirmed the dataset-sanity test failure is a pre-existing test-infrastructure gap (non-recursive
  directory listing vs. real files being nested), not something this flow should fix — out of
  scope, noted for awareness only.
- The `playhead`/`timeline.dart` conflict above — not anticipated by Requirements, Specifications,
  or the Plan, all of which assumed `playhead` could simply be deleted.

- **Task 3.1**: Changed `_Stage`'s sizing for comics documents to fit-width (`pageW = maxW; pageH =
  pageW / aspect`), branching explicitly on `c.isPuzzle` so puzzle boards keep their existing
  fit-whole-board-then-zoom-slider behavior unchanged.
  - Files changed: `lib/src/ui/widgets/canvas_view.dart`
  - Verified by: `test/canvas_layout_test.dart`, 2 widget tests distinguishing the two branches by
    their resulting `k` (page-units→px scale), read back through a static layer's rendered `top`.
- **Task 3.2**: Attempted to verify (not just tune) `boundaryMargin: EdgeInsets.all(200)` would let
  panning reach a real tall document's bottom. **Found a real, more serious bug in the process**:
  a widget test simulating actual `tester.drag()` gestures on the canvas showed panning getting
  stuck at exactly `-200` (matching `boundaryMargin`'s value) no matter how many further drags were
  applied. Root cause: `InteractiveViewer`'s `constrained` parameter (default `true`, never
  previously changed) is documented in Flutter's own source as forcing the child to size itself to
  the viewport when true — "if constrained is true and the child can only size itself to the
  viewport, then areas initially outside of the viewport will not be able to receive user
  interaction events" — exactly our new case since Task 3.1 made the child real-height. Fixed by
  setting `constrained: false` (the child is already explicitly sized via `SizedBox` for both
  branches, satisfying that flag's requirement). Re-ran the same drag test after the fix: 5
  successive `-500` drags accumulated cleanly to `-2500` translation / `currentTime=2500`, with no
  clamping.
  - Files changed: `lib/src/ui/widgets/canvas_view.dart` (`constrained: false` added)
  - Verified by: `test/canvas_boundary_test.dart` — a real drag-gesture test (not a directly-set
    `Matrix4`), confirming panning is unclamped through a 33,000px-tall test document.
- **Task 3.3**: The zoom-invariant `currentTime` formula from Task 2.3 was already tested for
  self-consistency against directly-set `Matrix4` values (`current_time_test.dart`). Task 3.2's real
  drag-gesture test additionally confirms it under an actual `InteractiveViewer` pan gesture at
  zoom=1 (1:1 accumulation, matching the assumed sign convention exactly). **Not separately
  verified**: a real pinch/scale gesture at a non-1.0 zoom level — simulating that precisely in a
  widget test was judged lower-value given `getMaxScaleOnAxis()` reading back Flutter's own applied
  scale is well-established behavior, not something this port introduces risk into. Disclosed here
  rather than silently treated as fully proven.

#### Deviations from Plan (continued)

- **Task 3.2**: the Plan described this as "tuning" an existing value; it turned out to require a
  real code fix (`constrained: false`) to an unrelated `InteractiveViewer` parameter that was never
  in question before Task 3.1 made the child real-height. Caught by writing a real-gesture test
  first rather than assuming the existing `boundaryMargin` value was already correct.

- **Task 4.1**: Added `audioplayers` via `flutter pub add audioplayers` (resolved: android 5.3.0,
  darwin 6.5.0, linux 4.3.0, web 5.3.0, windows 4.4.1). `flutter analyze`: clean (fixed two
  self-introduced lints along the way -- an HTML-looking doc comment and an unused import).
  `flutter build macos --debug`: succeeded.
- **Task 4.2**: Built `SoundGating.decide` (`lib/src/ui/audio/sound_player.dart`) as a pure,
  playback-free port of `SoundAnim.FindCurrent` + the scroll-driven half of `SoundViewModel.Scroll`,
  per Specifications' explicit design note to separate the decision from the real
  `audioplayers` call. `SoundPlayer` wraps a real `AudioPlayer`, gated by that pure function, with
  the natural-clip-end restart-if-looping behavior wired separately to `onPlayerComplete` (mirrors
  legacy's `Player_MediaEnded` being a distinct event, not part of the scroll-driven decision).
  - Files changed: `lib/src/ui/audio/sound_player.dart` (new)
  - Verified by: `test/sound_gating_test.dart`, 10 tests — downward-vs-upward point-trigger
    crossing, range entry/exit at exact boundaries, already-playing not retriggered, no-match stops
    an already-playing sound, non-sound anims ignored.
- **Task 4.3**: Wired `SoundPlayer` into `EditorController` — one player per `EditorSound`
  (lazily created), evaluated via a `canvasViewport` listener added in a new explicit constructor
  (mirrors `ComicsViewModel.Scroll`'s per-tick `sound.Scroll()`), disposed alongside the controller.
  Confirmed the real file-path convention (`$tempFolder/sounds/$file`) against
  `legacy/comics-editor-v2.8/Comics.Editor/Utils/FileManager.cs:18`
  (`FolderSounds = "sounds"`) rather than guessing — not previously established anywhere in the
  Dart codebase (sounds had no existing path-resolution precedent the way images have
  `layersDir`).
  - Files changed: `lib/src/ui/controller.dart`
  - Verified by: nothing automated exercises real playback here, matching the Plan's own
    "Manual" designation for this task's verification -- see Discoveries for why, and what's
    still genuinely unverified.

#### Discoveries (continued)

- **A real scare, resolved as a false alarm**: right after wiring Task 4.3, a full suite run showed
  10 failures in `balloon_editor_card_test.dart` (unrelated to sound) — worrying, since it looked
  like the new `AudioPlayer`-touching constructor code was destabilizing unrelated tests via
  platform-channel calls with no mock available in a plain `flutter_test` environment. Investigated
  by re-running the full suite twice more, cleanly, in isolation from anything else: both times,
  238/239 passed with only the one pre-existing unrelated dataset failure — the `balloon_editor_card_test.dart`
  failures did not reproduce. Most likely cause: the failing run happened immediately after a
  `flutter build macos --debug` (Task 4.1's verification), which may have still held build-daemon
  resources. **Not fully root-caused**, but not reproducible after two clean re-runs — flagged here
  rather than either quietly ignored or over-corrected without evidence.
- The `$tempFolder/sounds/` path convention (Task 4.3) is now implemented per legacy's real
  `FileManager.FolderSounds` constant, but **has no real audio file to test against** anywhere in
  this repo's `dataset/` or test fixtures — the automated tests only exercise `SoundGating`'s pure
  decision logic, never a real file path. This is the one piece of Phase 4 that's implemented but
  genuinely unverified end-to-end, consistent with the Plan's own explicit "Manual" designation for
  Task 4.3 and Task 5.2's manual pass.

- **Task 5.1**: Inspected a real file directly
  (`dataset/boranko/mahabharata/book1/comics_interactive/8a89f7d689fb441ea280cd782276bd7a.comics`,
  unzipped and read `data.json`) to get concrete, real `Anim` values to hand-derive expectations
  from, rather than synthetic test data. **Found a real bug while doing this**: layer 1 and layer 2
  in this actual file each have two `TranslateAnim`s that both omit `start` (both `Start=0`,
  per Task 1.1's fix) — a genuinely common real shape, not a contrived edge case. My
  `KeyframeInterpolator._sorted` used Dart's `List.sort`, which is not documented as stable, while
  legacy's equivalent (`OrderBy`, LINQ) is a stable sort — meaning tie-broken order (which
  determines which anim `FindNearest` treats as already-passed) could silently diverge from legacy
  for this common, real pattern. Fixed by sorting on `(start, originalIndex)` explicitly, matching
  `OrderBy`'s stability guarantee exactly. Added a dedicated regression test to
  `keyframe_interpolator_test.dart` using this exact real data shape, including a check that
  reversing the two anims' order changes the outcome (not just re-orders it) --  confirming order
  is genuinely load-bearing, not incidental.
  - Files changed: `lib/src/ui/anim/keyframe_interpolator.dart`, `test/keyframe_interpolator_test.dart`
  - Verified by: `test/real_file_interpolation_test.dart` (new) — opens the real file via the same
    `DartIoCore`/`comicsFromCore` path `dataset_backward_compat_test.dart` uses, reads layer 2's
    two real `TranslateAnim`s, and checks `KeyframeInterpolator.translateAt` against hand-derived
    expectations at four real scroll positions (t=0, t=1054 exact boundary, t=5000 held-past, and
    t=500 genuinely mid-interpolation, computed via the same cubic-ease-out formula) — passed on
    the first run after the stable-sort fix.
- **Task 5.2**: Ran the full suite three times total across this implementation session (once after
  each risky change) — final tally 240/241, the one failure being the pre-existing, unrelated
  dataset-listing issue confirmed at the very start of Task 1.1. **What I could NOT do**: the Plan's
  own manual checklist (author a new animation in the running editor and visually confirm it; open
  several real files and visually confirm resting layers place instantly; confirm real sound
  plays/loops/stops and point-triggers respect direction) requires interactively running the
  desktop app and either watching it or listening to real audio -- neither is something I can do in
  this text-based tool environment. Confirmed the app *builds* (Task 4.1's macOS debug build), but
  building is not the same as manually exercising it. This is disclosed explicitly, not silently
  claimed as done.

#### Deviations from Plan (continued)

- **Task 5.1** surfaced a real correctness bug (`_sorted`'s stability) that none of the four earlier
  phases' tests happened to exercise, because none of my own hand-written test fixtures had two
  same-type anims tied on `start` -- only real dataset content did. This is itself a small lesson:
  synthetic test data missed a real shape that showed up immediately once a real file was used.

#### Discoveries (continued)

- The `_sorted` stability bug (above) — the single most consequential finding of Phase 5, found only
  because Task 5.1 used real data instead of synthetic fixtures.
- Task 5.2's real-UI/real-audio manual verification remains genuinely outstanding — needs Anton (or
  a future session with actual interactive/audio capability) to run the app for real.

**Ended at**: Phase 5 substantially complete (Task 5.1 fully done; Task 5.2 partially done —
automated regression coverage complete, real interactive/audio verification outstanding)
**Handoff notes**: All 5 phases have real code changes and passing automated tests (240/241, one
pre-existing unrelated failure). Two things remain genuinely open, both disclosed rather than
assumed: (1) Task 5.2's real interactive/audio manual pass — needs a human running the actual app;
(2) the `$tempFolder/sounds/` path convention (Task 4.3) has no real audio file anywhere in this
repo to test end-to-end against. Recommend reporting completion to Anton with both of these called
out explicitly, not glossed over.

---

## Deviations Summary

| Planned | Actual | Reason |
|---------|--------|--------|
| (none yet) | | |

## Learnings

- The "one test at a time" protocol caught the exact expected failure mode before the fix
  (`Actual: <200>`), confirming the test actually exercises the bug rather than passing vacuously.

## Completion Checklist

- [ ] All tasks completed or explicitly deferred
- [ ] Tests passing
- [ ] No regressions
- [ ] Documentation updated if needed
- [ ] Status updated to COMPLETE
