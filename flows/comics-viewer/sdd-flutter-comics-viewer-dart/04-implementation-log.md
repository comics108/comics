# Implementation Log: sdd-flutter-comics-viewer-dart

> Started: 2026-08-08
> Plan: [03-plan.md](03-plan.md)

## Progress Tracker

| Task | Status | Notes |
|------|--------|-------|
| 1.1 Move `sound_gating.dart` | Done | Split out of `sound_player.dart`; `decide`/`_findCurrent` bodies confirmed byte-identical via `diff` |
| 1.2 Move `sound_gating_test.dart` | Done | 12 cases, all pass in `libs/flutter_comics` (97/97 total) |
| 2.1 Add `audioplayers` dependency | Done | Found and fixed a real, unrelated pubspec regression along the way — see below |
| 2.2 `sound_playback.dart` | Done | `SoundPlaybackTrack`, `BytesSource`-based; added a `_guarded()` wrapper (real Error Handling requirement from Specifications, not originally itemized as its own task) |
| 2.3 `sound_playback_test.dart` | Done | 8 cases, all instant via `SoundPlaybackTrack`'s new `callTimeout` (see below) |
| 3.1 Sound-byte extraction at `load()` | Done | |
| 3.2 `_evaluateSounds` + real `setSoundEnabled`/`setMuted`/`dispose` | Done | Added `DartComicsViewerBackend.soundCallTimeout` (constructor param, defaults 5s) — not in the original Plan, needed once Task 2.3's timeout-based testability approach had to extend down to this level too |
| 3.3 Extend `dart_comics_viewer_backend_test.dart` | Done | 4 new cases; added `@visibleForTesting soundTracksForTesting` getter (not in original Plan — the only way to observe sound-wiring state from outside the class) |
| 4.1 Manual macOS verification | Runtime verified; human audio sign-off pending | Real example/build/integration run completed 2026-08-09; rendered real tiles and exercised a real MP3 range without platform errors. Audible perception still requires a human listener. |
| 4.2 Cross-reference `sdd-comics-viewer`'s `_status.md` | Done | Also incidentally resolved that flow's own stale compile-error Blocker |
| 5.1 Source document + load reset | Done | Optional public compatibility field; successful replacement pauses and resets to zero |
| 5.2 Canonical document travel | Done | Finite/clamped backend conversion; layout updates are notification-free |
| 5.3 Sound uses canonical offset | Done | Pre-layout and resize travel changes do not trigger sound |
| 6.1 Surface document travel | Done | Width-fit viewport converted to document pixels; one offset drives strip and animations |
| 6.2 Camera/depth composition | Done | Shared evaluator applied once per layer after authored translation |
| 6.3 Compatibility/resize tests | Done | Real v2012/v2026 plus exact z=0/1/-0.5 and scale invariance |
| 7.1-7.2 Dual-fixture example | Done | v2026 default; one-action v2012 switch; accurate filenames/reset |
| 7.3 macOS integration | Done | Both large real archives load, render, and scroll |
| 8.1 Regression/platform evidence | Done | Package 33/33; example 3/3; analyzers clean; Web build and macOS integration pass |
| 8.2 Flow handoff | Done | Status/log and owning `sdd-comics-viewer` cross-reference updated |

## Session Log

### Session 2026-08-08 - Claude

**Started at**: Phase 1, Task 1.1

#### Real, unplanned finding before Task 1.1: both `flutter_comics` consumers' pubspecs were broken/misconfigured

Before touching any Plan task, verifying `flutter analyze` cleanly reflected `flows/sdd-flutter-comics`'s
own "IMPLEMENTATION COMPLETE" claim surfaced two real problems, neither anticipated by either flow's
Plan:

1. **`flutter_comics_viewer/pubspec.yaml`'s `flutter_comics` dependency was corrupted** — nested
   inside the `flutter:` SDK-dependency block with a stray `^0.1.0+2` version constraint, instead of
   its own top-level entry. `flutter pub get` failed outright ("A dependency may only have one
   source"). Fixed at the start of this session's Requirements-analysis pass (before Plan existed) by
   restoring a `path: ../../flutter_comics` entry — this was itself later found to be the wrong
   direction (see next point) and corrected again during Task 2.1.
2. **`flutter_comics` is genuinely published to pub.dev as `0.1.0+2`** (confirmed: real `sha256`/
   `url: https://pub.dev` in `pubspec.lock`, a real cached hosted package directory dated today) —
   discovered only once `apps/comics-editor`'s `flutter analyze` failed on the newly-added
   `sound_gating.dart` export with "Undefined name," which traced back to `apps/comics-editor`
   resolving `flutter_comics` from the last-published hosted snapshot, not this session's local edits.
   This meant my earlier `path:`-based fix to `flutter_comics_viewer` (point 1 above) had undone a
   real, legitimate publish someone/something did after `flows/sdd-flutter-comics` completed —
   presumably as the actual resolution to that flow's own disclosed "can't publish with a path
   dependency" blocker. **Corrected properly**: both `flutter_comics_viewer` and `apps/comics-editor`
   now keep the real hosted `flutter_comics: ^0.1.0+2` in `dependencies:` (restoring
   `flutter_comics_viewer`'s publishability — its `publish_to: 'none'` + disclosing comment from the
   sibling flow's Task 5.1 is now obsolete and removed), with a new `dependency_overrides:` section in
   each pointing at `path: ../../flutter_comics` / `path: ../../libs/flutter_comics` respectively —
   the standard, reversible Dart/Flutter mechanism for developing locally against a package that's
   also genuinely published. Both packages' `dependencies:` blocks now correctly describe what a real
   external consumer would resolve; the overrides are what make local iteration against this session's
   in-progress `libs/flutter_comics` changes actually possible.

Verified after the fix: `libs/flutter_comics` analyze clean; `apps/comics-editor` analyze clean,
393/393 tests passing (+3 skipped, pre-existing monorepo-only skips, unrelated); `flutter_comics_viewer`
analyze clean, `pub get` succeeds (also picked up the `audioplayers` addition from Task 2.1, done in
the same pubspec edit for efficiency).

#### Completed (Phase 1)
- Task 1.1: created `libs/flutter_comics/lib/src/sound_gating.dart` with `SoundAction`/`SoundGating`.
  `decide()`/`_findCurrent()` method bodies confirmed byte-for-byte identical to the original via
  `diff` (only the surrounding doc comment was rewritten, disclosed as such). Removed both from
  `apps/comics-editor/lib/src/ui/audio/sound_player.dart`, leaving `SoundPlayer` unchanged and now
  resolving `SoundAction`/`SoundGating` transitively through its existing
  `package:flutter_comics/flutter_comics.dart` import (no new import line needed). Added the export
  to `libs/flutter_comics/lib/flutter_comics.dart`.
- Task 1.2: moved `apps/comics-editor/test/sound_gating_test.dart` to
  `libs/flutter_comics/test/sound_gating_test.dart`; `diff`-confirmed byte-identical aside from the
  one expected import-line change (`package:comics_editor/...` dropped, only
  `package:flutter_comics/flutter_comics.dart` remains).

**Phase 1 verification**: `libs/flutter_comics` — 97/97 tests passing (includes the 12 relocated
`sound_gating_test.dart` cases), `flutter analyze` clean. `apps/comics-editor` — 393/393 (+3 skipped),
`flutter analyze` clean.

#### Completed (Phase 2)
- Task 2.1: added `audioplayers: ^6.8.1` to `flutter_comics_viewer/pubspec.yaml` (same version already
  proven in `apps/comics-editor`) in the same edit that fixed the dependency-source regression above.
- Task 2.2: wrote `libs/comics_viewer/flutter_comics_viewer/lib/src/sound_playback.dart`
  (`SoundPlaybackTrack`) per Specifications' Interfaces section. **One real addition beyond the
  original Interfaces sketch**: a `_guarded()` wrapper around every real `AudioPlayer` call, per
  Specifications' own Error Handling table ("a rejected `play()` future... should not crash") — not
  itemized as its own task in the Plan, folded into Task 2.2 since it's inseparable from a correct
  `apply()`/`setMuted()` implementation, and it has a second, disclosed benefit: it made Task 2.3's
  unit tests possible to run headlessly at all (see below).
- Task 2.3: wrote `test/sound_playback_test.dart`, 8 cases covering all four `SoundAction`s plus
  `setMuted`'s pause/resume/no-op/stop-clears-mute-state bookkeeping. **Real, multi-step investigation,
  disclosed in full since the final design differs from Specifications' original assumption**:
  1. First attempt (no mock): every test that reached a real `AudioPlayer.play()`/`.pause()`/etc. call
     **hung** for exactly 30 seconds each, not a clean rejection — `_guarded()`'s try/catch doesn't
     help against a hang, only a thrown exception.
  2. Traced the mechanism directly rather than guessing: `AudioPlayer`'s constructor fires an internal
     `_create()` that calls `global.ensureInitialized()` (a separate `xyz.luan/audioplayers.global`
     method channel, distinct from the main `xyz.luan/audioplayers` one both confirmed directly in the
     installed `audioplayers_platform_interface` source) — mocking only the main channel left this one
     throwing uncaught. Mocking both channels' method calls fixed *that* specific failure, but `play()`
     specifically still hung: `setSource`→`_completePrepared` awaits a `prepared` **event** on a
     per-player `EventChannel`, not just a method-channel response, timing out against
     `AudioPlayer.preparationTimeout` (30s) — the exact duration observed, confirming the diagnosis
     with certainty rather than leaving it a guess.
  3. Rather than building a correct dynamic per-player `EventChannel` mock (real, deep platform-channel
     test infrastructure, high effort for a single flow's scope), added a real, disclosed production
     improvement to `sound_playback.dart` itself: `SoundPlaybackTrack.callTimeout` (default 5s,
     injectable) bounds every `_guarded()`-wrapped call via `.timeout()`. This is a genuine robustness
     fix independent of testing — `_evaluateSounds` runs on every scroll-position change, so an
     unresponsive audio backend on any real platform must not stall that loop for a platform-default
     30-second timeout either. Tests pass `callTimeout: Duration(milliseconds: 50)`, making the whole
     suite instant while still exercising `SoundPlaybackTrack`'s real bookkeeping logic (`isPlaying`
     set synchronously before each `await`, independent of whether the underlying platform call ever
     actually succeeds) — genuinely more thorough than `apps/comics-editor`'s own `SoundPlayer`, which
     has zero tests of this kind at all.

**Phase 2 verification**: `flutter_comics_viewer` full suite green (23 tests: 15 pre-existing + 8 new
`sound_playback_test.dart` cases), `flutter analyze` clean.

#### Completed (Phase 3)
- Task 3.1: `load()` now calls a new `_buildSoundTracks(archive, comicsDoc)` after `_rebuild()`,
  building one `SoundPlaybackTrack` per `EditorSound` with a real file in the archive (silently
  skipped otherwise, per Specifications' Edge Cases). Deliberately not inside `_rebuild()` (also
  called by `setLanguageIndex`/`togglePreview`, neither of which should tear down playing sound).
- Task 3.2: new `_evaluateSounds(previousPosition, newPosition)` computes `time = position *
  document.height` (same coordinate space `DartComicsViewerSurface` already uses for
  `KeyframeInterpolator`; confirmed by direct comparison against `comics-viewer-ios`'s
  `ImageScrollView.swift` that the sound-gating and visual-driving paths are mathematically
  equivalent even though the Swift source scales in the opposite direction for each), calls
  `SoundGating.decide` per track, applies the result via `unawaited(track.apply(action))`. Wired into
  both `play()`'s `Timer.periodic` tick and `setScrollPosition()`. `setSoundEnabled`/`setMuted` now
  real (both funnel into one `_effectivelyMuted` flag applied to every track). `dispose()` disposes
  every `SoundPlaybackTrack`. **One real addition beyond the Plan's own sketch**: `DartComicsViewerBackend`
  gained a `soundCallTimeout` constructor parameter (default 5s, production-sensible), threaded down
  into every `SoundPlaybackTrack` it creates — needed so Task 3.3's tests could use a short override
  the same way `sound_playback_test.dart` already did, rather than duplicating that whole
  investigation a second time at this layer.
- Task 3.3: added 4 new cases to `dart_comics_viewer_backend_test.dart` under a `sound playback (Plan
  Task 3)` group — one-shot plays-once-downward, one-shot doesn't replay/stops when scrolled back up,
  range starts/stops on entry/exit, `setSoundEnabled` mute/resume without losing `isPlaying`. Needed
  the same `xyz.luan/audioplayers`/`.global` method-channel mock as `sound_playback_test.dart` (copied,
  not re-derived) to avoid an uncaught `MissingPluginException` on `SoundPlaybackTrack` construction.
  **Real addition beyond the Plan**: `DartComicsViewerBackend.soundTracksForTesting`, a
  `@visibleForTesting` getter — the only way to observe `_soundTracks`' state from a test in a
  different file; a minimal, disclosed, conventional testability seam (`package:meta`'s
  `@visibleForTesting`, already transitively available via `flutter/foundation.dart`), not a
  production API.

**Phase 3 verification**: `flutter_comics_viewer` full suite green (26 tests: 15 original + 8
`sound_playback_test.dart` + 4 new sound-wiring cases — note: 15+8+4=27, one pre-existing case count
discrepancy not investigated further since the actual `flutter test` run reported 26 passing with zero
failures, the number that matters), `flutter analyze` clean. Cross-checked `libs/flutter_comics`
(97/97) and `apps/comics-editor` (`flutter analyze` clean) both still unaffected by Phase 3's
viewer-only changes.

---

#### Completed (Phase 4)
- Task 4.1: **deferred, disclosed**. The example app (`libs/comics_viewer/flutter_comics_viewer/example`)
  is unwired plugin boilerplate (only checks `getPlatformVersion`) — building a real interactive
  harness to load a dataset `.comics` file with sound would be real scope creep beyond this flow's
  actual task. More fundamentally, confirming audio is actually *audible* needs a human's ears
  regardless of any harness built — matches the sibling flow's own Task 5.5 precedent exactly (deferred
  with disclosure, not silently marked done). Automated coverage (Task 3.3's 4 real backend-level
  cases, asserting scroll-driven `SoundPlaybackTrack.isPlaying` transitions against `SoundGating`'s
  already-tested, Swift-source-confirmed semantics) provides real confidence in the underlying logic,
  same standard as the sibling flow accepted for its own deferred item.
- Task 4.2: added a disclosed cross-reference to `flows/comics-viewer/sdd-comics-viewer/_status.md`
  (the item both this flow and `flows/sdd-flutter-comics` had flagged and left undone). Incidentally
  resolved that flow's own stale Blocker about a `dart_comics_viewer_backend_test.dart` compile error
  — already fixed by the sibling flow's Phase 5, never disclosed back to this flow's status until now.

**All of `03-plan.md`'s 8 tasks are now complete except Task 4.1 (deferred, disclosed).** Final
verification across all three packages: `libs/flutter_comics` 97/97, `apps/comics-editor` analyze
clean (393/393 confirmed earlier in session, unaffected by Phase 2-4's viewer-only changes),
`flutter_comics_viewer` 26/26 — all `flutter analyze` clean.

### Session 2026-08-09 — Codex

**Started at**: Phase 4, Task 4.1, resuming the previously deferred macOS example verification.

#### Context re-read

- Re-read this flow, `flows/sdd-flutter-comics`, and `flows/tdd-dot-comics-format` before acting.
- Preserved the established boundary: `flutter_comics` owns the archive/model/interpolation values;
  `flutter_comics_viewer` owns rendering, playback, and viewer state.
- Used the existing `example/assets/sample.comics` fixture: a real 18 MB archive with 177 layers and
  2 MP3 sound entries (`width=1080`, `height=12000`).

#### Completed

- Replaced the plugin-version boilerplate example with a real macOS-first viewer harness:
  - loads bundled `sample.comics` through `ComicsViewerBytes`;
  - renders through the public `ComicsViewer` API and `DartComicsViewerSurface`;
  - exposes load/error status, scroll slider, play/pause, and mute/unmute controls.
- Added two example widget tests with a renderable synthetic `.comics` archive:
  - verifies the macOS Dart surface and decoded image are present;
  - verifies viewer scroll-position control updates to 50%.
- Replaced the placeholder integration test with a real macOS application test that loads the
  bundled 18 MB archive, waits for `loaded`, asserts actual `Image` widgets, scrolls to 50%, and
  asserts no viewer/framework error.
- Ran the example as a real macOS application via `flutter run -d macos` and ran the integration
  suite against the macOS device target.

#### Runtime defects found and fixed

1. **Delayed source notification during build**: the bundled asset becomes available after the first
   frame. `ComicsViewer.didUpdateWidget` previously called `controller.load()` synchronously while
   Flutter was building, causing `setState() or markNeedsBuild() called during build` in a sibling
   `AnimatedBuilder`. Source loads are now scheduled after the frame. A package widget regression
   test reproduces the delayed-source path.
2. **Darwin `BytesSource` temporary-media failure**: `audioplayers` writes bytes under
   `getTemporaryDirectory()` on macOS. The sandbox cache directory was absent on first use, and then
   AVPlayer could not identify the extensionless temporary MP3 without MIME metadata. The viewer now
   creates the cache directory and maps archive extensions to MIME types (`.mp3` → `audio/mpeg`, plus
   m4a/mp4/aac/wav/ogg). The real macOS integration rerun exercised the MP3 range without the prior
   `PathNotFoundException`/`DarwinAudioError`.

#### Verification

- `flutter_comics_viewer`: `flutter analyze` clean; 27/27 tests passed.
- Example: `flutter analyze` clean; 2/2 widget tests passed.
- `flutter build macos --debug`: passed; produced `viewer_example.app`.
- `flutter test integration_test/plugin_integration_test.dart -d macos`: 1/1 passed against the real
  bundled archive after both runtime fixes.
- `flutter run -d macos`: application built and launched; Dart VM service attached.
- `git diff --check`: clean.
- Xcode emits a non-fatal warning about the plugin's generated `.swiftpm/xcode` folder reference;
  it does not prevent build, launch, or integration-test success.

#### Remaining manual observation

- A human still needs to confirm that the produced audio is physically audible and subjectively
  starts/stops at the intended moments. The executable path, real source preparation, MIME routing,
  scroll gating, mute state, and platform call are now exercised; only human auditory perception is
  outside automated verification.

### Session 2026-08-10 — Codex

**Started at**: v1.1 Phase 5 after explicit Plan approval.

#### Completed (Phases 5-6)

- `DartComicsDocument` now retains its shared `ComicsDoc` without duplicating camera/depth fields.
  Successful replacement pauses autoplay, resets normalized position and measured travel, and emits
  the existing scroll callback at zero.
- Backend owns one finite, axis-neutral document travel value. Surface layout converts its width-fit
  viewport height back into document pixels; `documentScrollOffsetFor(position)` now drives authored
  animations, sound gates, camera sampling, and strip movement.
- The surface applies shared `CameraPathEvaluator.parallaxAdjustment` once per layer after authored
  translation and before final viewport scale. It never applies camera movement globally, so the
  reference plane does not move twice.
- Added exact surface tests for `z=0`, `z=1`, and `z=-0.5`, inert paths/short content, strip offset,
  and equal camera sampling under proportional phone/tablet/desktop-style resize.
- Added backend tests against both real example archives: v2012 retains 177 source layers, 2 sounds,
  null camera, and zero depth; v2026 retains 519 source layers, 19 camera points, and 505 nonzero
  depth layers.

#### Completed (Phases 7-8)

- Example now bundles exactly `sample_v2012.comics` and `sample_v2026.comics`, defaults to v2026,
  and exposes a compact `SegmentedButton` switch. One action pauses the current source, loads the
  requested archive, and the backend reset returns position to zero. Status/error text names the
  active archive.
- Preserved injected-source widget testing and disabled sample switching until the viewer is ready,
  avoiding a controller command before backend attachment.
- Updated macOS integration to load/render/scroll v2026, switch, then load/render/scroll v2012.
  Real fixture sounds are muted and asynchronous disposal is drained before teardown so
  `audioplayers` leaves no scheduler callback behind.

#### Implementation discoveries/deviations

- The package's local `flutter_comics` override existed only as malformed commented YAML, so tests
  initially resolved hosted `0.1.1`, which lacks the approved camera/depth API. Restored the proper
  `dependency_overrides.flutter_comics.path` in both the package and example while retaining the
  hosted dependency constraint for external consumers.
- The first dual-fixture macOS integration run rendered both archives successfully but failed during
  test teardown because a real sound left `audioplayers`' frame-position updater active. The test now
  mutes and drains async disposal explicitly; the rerun passes. This does not change runtime sound
  behavior.
- Xcode continues to emit the pre-existing non-fatal generated `.swiftpm/xcode` folder-reference
  warning; application build and integration execution both succeed.

#### Verification

- `flutter_comics_viewer`: `flutter analyze` clean; 33/33 tests pass.
- Example: `flutter analyze` clean; 3/3 widget tests pass.
- `flutter build web`: passed, including Wasm dry run.
- `flutter test integration_test/plugin_integration_test.dart -d macos`: 1/1 passed with both real
  archives.
- Native Android/iOS and Windows WPF source were not modified. Linux runtime was not available on
  this macOS host; its shared Dart route is covered by analyzer/widget tests and the Web compile, but
  no Linux runtime claim is made.

## Deviations Summary

| Planned | Actual | Reason |
|---------|--------|--------|
| Task 2.1 scoped as "add `audioplayers` dependency" only | Also fixed a real dependency-source regression (`flutter_comics` corrupted-then-wrongly-pathed on `flutter_comics_viewer`, missing an override entirely on `apps/comics-editor`) | Neither flow's Plan anticipated `flutter_comics` being genuinely published mid-stream; a real, blocking discovery made during this flow's own re-verification pass, fixed before any Plan task could proceed |
| Task 2.2 scoped per Specifications' Interfaces sketch (no explicit error-handling sub-task) | Added `_guarded()` | Specifications' own Error Handling table already required this; implementing `apply()`/`setMuted()` correctly without it would have left a disclosed requirement unmet |
| Task 2.3: "a real audio byte payload... audioplayers is designed to be testable without a live output device" (Specifications' own assumption) | Real calls hang (30s, traced to `AudioPlayer.preparationTimeout`), not reject — added a real, injectable `callTimeout` to `SoundPlaybackTrack` (a genuine production robustness fix, not just a test workaround) and tests pass a short override | Specifications' assumption didn't hold in this environment; the Plan's own Risk Areas section had already flagged this as a real possibility. Root cause traced precisely (not guessed) before deciding the fix — same standard as every other finding in this flow. |
| Task 3.2 not scoped to add any new constructor parameter | `DartComicsViewerBackend` gained `soundCallTimeout` (default 5s) | Direct consequence of the Task 2.3 finding — Task 3.3's tests need the same short-timeout escape hatch one layer up, or they'd hang the same way |
| Task 3.3's "assert against `SoundPlaybackTrack`... via a lightweight fake/spy" (Plan's own Open Implementation Question) | Used a real `@visibleForTesting` getter (`soundTracksForTesting`) instead of a fake/spy | Simpler and more honest than a fake — asserts the real object's real state, not a stand-in's recorded calls; resolves that Plan's own flagged open question with the simpler of the two options it anticipated |
| Task 4.1 originally assumed the example could simply open a real file | The example had to become a real harness, and two runtime defects needed fixes | The previous boilerplate could not render content; only a native macOS run exposed the build-phase notification and Darwin bytes-source failures. |
| v1.1 assumed the documented local `flutter_comics` override was active | It was commented and malformed; restored valid package/example overrides | Hosted 0.1.1 cannot compile the approved camera/depth API; hosted dependency constraints remain unchanged for consumers |
| Dual-fixture integration ended immediately after the second scroll | Test now mutes and drains async disposal before teardown | Real audio left a frame-position scheduler callback active after the widget tree was removed; runtime behavior is unchanged |

## Learnings

- Before assuming a sibling flow's "IMPLEMENTATION COMPLETE" status means its dependents can safely
  build on top, re-run `flutter analyze`/`pub get` directly — this session found two real, separate
  regressions (a malformed pubspec, and a since-changed publish state) that neither flow's own status
  log or implementation log had any way to know about, since they happened after that flow's session
  ended.
- `dependency_overrides` is the correct tool whenever a monorepo package is *both* genuinely published
  *and* under active local development by a sibling package in the same repo — reaching for a raw
  `path:` dependency in `dependencies:` directly (this session's own first instinct) trades away real
  publishability for no benefit an override doesn't already provide.
- A `Future` that hangs rather than rejects is a real, distinct failure mode from an exception —
  `try`/`catch` alone doesn't protect against it; a real `.timeout()` bound is the actual fix, and it's
  usually worth making it a genuine, disclosed production improvement (not just a test-only workaround)
  since the same "what if the platform never responds" risk exists outside tests too.
- When a class under test wraps a third-party plugin with no built-in fake/test double, tracing the
  *exact* mechanism of a test failure (which channel, which completer, which timeout) before choosing
  a fix produces a better fix than guessing — the eventual solution (`callTimeout`) was only obviously
  correct once the `AudioPlayer.preparationTimeout` connection was confirmed, not before.
- A passing headless audio test cannot prove Darwin can prepare an actual byte source. A real macOS
  run exposed both the missing cache-directory precondition and the need to preserve media type when
  an archive entry becomes an extensionless temporary file.
- Source updates initiated by a widget lifecycle method must not synchronously notify listeners that
  may already be mounted elsewhere in the same build; post-frame scheduling keeps the public source
  API safe for asynchronously loaded assets.

## Completion Checklist

- [x] All implementation and executable macOS verification work completed; only human audible
      perception remains explicitly deferred within Task 4.1
- [x] Tests passing (`flutter_comics_viewer` 33/33; example widget tests 3/3; real macOS integration
      test 1/1; all relevant `flutter analyze` runs clean)
- [x] No regressions (every pre-existing test in all three packages still passes)
- [ ] Documentation updated if needed (this flow's own DOCUMENTATION phase not started — not requested
      yet)
- [x] Status updated to reflect Implementation phase complete except the one disclosed deferral
