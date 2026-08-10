# Implementation Plan: sdd-flutter-comics-viewer-dart — sound, compatibility, camera, and depth

> Version: 1.1 (v2012/v2026 camera-depth addendum)
> Status: v1.0 SOUND BASELINE AND v1.1 ADDENDUM IMPLEMENTED
> Last Updated: 2026-08-10
> Specifications: [02-specifications.md](02-specifications.md) (v0.2, APPROVED)

## Summary

Moves the already-existing, already-tested `SoundGating`/`SoundAction` (pure sound-gating logic) from
`apps/comics-editor` into `libs/flutter_comics`, then adds a new `BytesSource`-based sound player to
`flutter_comics_viewer` and wires it into `DartComicsViewerBackend`'s scroll-position updates. Four
phases, each independently verifiable before the next starts, matching Specifications' own
Migration/Rollout section and this repo's "one test at a time" discipline.

**Same two standing execution constraints as `flows/sdd-flutter-comics`'s Plan, still in force**: any
"Move" task is a plain local filesystem relocation (read the source file's exact bytes, write them at
the destination, delete the source) — never `git mv`/`git add`/`git rm`/any git command (Anton does
git by hand) — and content must be byte-identical at the destination before any import-path edit is
applied on top, never retyped from memory.

## Task Breakdown

### Phase 1: Move `SoundGating`/`SoundAction` into `libs/flutter_comics`

#### Task 1.1: Move `sound_gating.dart` (new file, split out of `sound_player.dart`)
- **Description**: `apps/comics-editor/lib/src/ui/audio/sound_player.dart` currently holds both
  `SoundAction`/`SoundGating` (pure, portable) and `SoundPlayer` (impure, `audioplayers`+
  `DeviceFileSource`-based, editor-specific) in one file. Extract the pure half verbatim into a new
  file at the destination (copy `SoundAction`'s definition + `SoundGating`'s full class body,
  byte-identical, no logic edits), then delete that content from the source file, leaving only
  `SoundPlayer` there with a new import for what it now needs from the shared package.
- **Files**:
  - `libs/flutter_comics/lib/src/sound_gating.dart` — Create (verbatim `SoundAction` + `SoundGating`
    content, only the doc comment's own file-path self-reference updated)
  - `apps/comics-editor/lib/src/ui/audio/sound_player.dart` — Modify (remove `SoundAction`/
    `SoundGating`'s definitions; `SoundPlayer` keeps its existing `import 'package:flutter_comics/
    flutter_comics.dart';` which now also brings in `SoundAction`/`SoundGating` transitively — no new
    import line needed, `SoundGating`/`SoundAction` become available exactly the way `Anim`/`AnimType`
    already are)
  - `libs/flutter_comics/lib/flutter_comics.dart` — Modify (add `export 'src/sound_gating.dart';`)
- **Dependencies**: None
- **Verification**: `flutter analyze` clean in `libs/flutter_comics`; `flutter analyze` clean in
  `apps/comics-editor` (confirms `sound_player.dart`'s remaining `SoundPlayer` class still resolves
  `SoundAction`/`SoundGating` via the transitive package export).
- **Complexity**: Low (mechanical split of an already-small, already-well-isolated file)

#### Task 1.2: Move `sound_gating_test.dart`
- **Description**: Relocate `apps/comics-editor/test/sound_gating_test.dart` to
  `libs/flutter_comics/test/sound_gating_test.dart`, byte-identical filesystem move, only its own
  import line changed to `package:flutter_comics/flutter_comics.dart`.
- **Files**:
  - `apps/comics-editor/test/sound_gating_test.dart` → `libs/flutter_comics/test/sound_gating_test.dart`
    — Move + one import-line edit
- **Dependencies**: Task 1.1
- **Verification**: `flutter test test/sound_gating_test.dart` passes in `libs/flutter_comics`; full
  `apps/comics-editor` suite re-run to confirm no regression from the file's removal there (its
  assertions covered `SoundGating` only, which no longer lives in that package, so nothing there
  should have depended on the test file itself — only on the class, which still resolves via the
  package import from Task 1.1).
- **Complexity**: Low

**Phase 1 checkpoint**: `libs/flutter_comics` test suite green (includes the newly-arrived
`sound_gating_test.dart`); `apps/comics-editor` full suite green (unaffected).

### Phase 2: `flutter_comics_viewer`'s `BytesSource`-based sound player

#### Task 2.1: Add `audioplayers` dependency
- **Description**: Add `audioplayers: ^6.8.1` to `libs/comics_viewer/flutter_comics_viewer/pubspec.yaml`
  — same version already proven in `apps/comics-editor`, not a new/unvetted choice.
- **Files**:
  - `libs/comics_viewer/flutter_comics_viewer/pubspec.yaml` — Modify (add dependency line)
- **Dependencies**: None (independent of Phase 1)
- **Verification**: `flutter pub get` succeeds in `flutter_comics_viewer`.
- **Complexity**: Low

#### Task 2.2: Write `sound_playback.dart` (`SoundPlaybackTrack`)
- **Description**: New class per Specifications' Interfaces section — wraps one `AudioPlayer`, plays
  via `BytesSource(bytes)` (not `DeviceFileSource`, since this package only ever has in-memory archive
  bytes), tracks its own `isPlaying`/muted-while-playing state (does not ask the real `AudioPlayer`
  each tick), exposes `apply(SoundAction)` and `setMuted(bool)`.
- **Files**:
  - `libs/comics_viewer/flutter_comics_viewer/lib/src/sound_playback.dart` — Create
- **Dependencies**: Task 2.1
- **Verification**: `flutter analyze` clean.
- **Complexity**: Medium (real async state machine — play/pause/resume/stop transitions, muted-while-
  playing bookkeeping — but small, single-purpose, well-specified)

#### Task 2.3: `sound_playback_test.dart`
- **Description**: Unit tests for `SoundPlaybackTrack.apply`'s four `SoundAction` cases (`playOnce`,
  `startLooping`, `stop`, `none`) and `setMuted`'s pause/resume bookkeeping, against a small synthetic/
  silent audio byte payload (no real audio hardware needed for these assertions — `audioplayers` is
  designed to be testable without a live output device in `flutter test`, matching how
  `apps/comics-editor`'s own `audioplayers`-based tests already work, if any exist there to confirm the
  pattern — check during implementation, not assumed).
- **Files**:
  - `libs/comics_viewer/flutter_comics_viewer/test/sound_playback_test.dart` — Create
- **Dependencies**: Task 2.2
- **Verification**: New test file passes.
- **Complexity**: Medium

**Phase 2 checkpoint**: `flutter_comics_viewer`'s suite green including the new
`sound_playback_test.dart`; `SoundPlaybackTrack` not yet wired into the real backend (that's Phase 3).

### Phase 3: Wire sound evaluation into `DartComicsViewerBackend`

#### Task 3.1: Extract sound bytes + build `_soundTracks` at `load()` time
- **Description**: After `_rebuild()` runs inside `load()`, iterate `comicsDoc.sounds` (already
  parsed and available, confirmed via `comics_reader.dart:228-235`); for each `EditorSound`, look up
  `archive.findFile('sounds/${sound.file}')`; if found, create a `SoundPlaybackTrack` from its bytes
  and store it keyed by the `EditorSound` instance in a new `Map<EditorSound, SoundPlaybackTrack>
  _soundTracks` field. Per Specifications' Edge Cases: this population happens ONCE at `load()` time,
  not inside `_rebuild()` — `_rebuild()` is also called by `setLanguageIndex`/`togglePreview`, neither
  of which should tear down/restart currently-playing sound.
- **Files**:
  - `libs/comics_viewer/flutter_comics_viewer/lib/src/dart_comics_viewer_backend.dart` — Modify
- **Dependencies**: Task 2.2 (needs `SoundPlaybackTrack`), Task 1.1 (needs `EditorSound`/`Anim`
  already available — already true today, unaffected by Phase 1, listed for clarity)
- **Verification**: `flutter analyze` clean; a temporary/scratch assertion (or the Task 3.3 test,
  written next) that `_soundTracks` is populated correctly for a synthetic archive with sound files.
- **Complexity**: Low

#### Task 3.2: `_evaluateSounds` + wire into `play()`/`setScrollPosition()` + real `setSoundEnabled`/`setMuted`/`dispose`
- **Description**: New private `Future<void> _evaluateSounds(double previousPosition, double
  newPosition)` computing `previousTime`/`currentTime` as `position * document.height` (matching
  `DartComicsViewerSurface`'s existing `time` formula exactly, for the same coordinate space
  `KeyframeInterpolator` already uses), then calling `SoundGating.decide` once per `(EditorSound,
  SoundPlaybackTrack)` pair and applying the resulting `SoundAction`. Called from `play()`'s
  `Timer.periodic` callback (after `_position` is updated, before/alongside `notifyListeners()`) and
  from `setScrollPosition()` (same placement). `setSoundEnabled`/`setMuted` become real: update
  `_soundEnabled`/`_muted`, call `setMuted(_effectivelyMuted)` on every track. `dispose()` disposes
  every `SoundPlaybackTrack` in addition to its existing `_timer?.cancel()`.
- **Files**:
  - `libs/comics_viewer/flutter_comics_viewer/lib/src/dart_comics_viewer_backend.dart` — Modify
- **Dependencies**: Task 3.1
- **Verification**: `flutter analyze` clean; deferred functional verification to Task 3.3.
- **Complexity**: Medium (the two call sites — timer tick and manual scroll — must both pass the
  correct previous/current position pair; must not double-evaluate or skip a tick)

#### Task 3.3: Extend `dart_comics_viewer_backend_test.dart`
- **Description**: New test cases per Specifications' Testing Strategy: a synthetic archive with one
  one-shot `SoundAnim` and one range `SoundAnim`; scripted `setScrollPosition` calls at positions
  before/at/after each, asserting the right `SoundAction`-driven state transitions occur (via a
  lightweight fake/spy on `SoundPlaybackTrack` if directly asserting real `AudioPlayer` state proves
  impractical in a widget-test environment — exact mechanism decided during implementation, matching
  how Task 5.4 of the sibling flow's Plan handled an analogous real-vs-fake tradeoff).
- **Files**:
  - `libs/comics_viewer/flutter_comics_viewer/test/dart_comics_viewer_backend_test.dart` — Modify
    (add cases, existing cases unchanged)
- **Dependencies**: Task 3.2
- **Verification**: Full `flutter_comics_viewer` suite green.
- **Complexity**: Medium

**Phase 3 checkpoint**: Full `flutter_comics_viewer` suite green (pre-existing cases + Phase 2's new
`sound_playback_test.dart` + Phase 3's extended `dart_comics_viewer_backend_test.dart`); `flutter
analyze` clean across `libs/flutter_comics`, `apps/comics-editor`, `flutter_comics_viewer`.

### Phase 4: Manual verification + cross-flow disclosure

#### Task 4.1: Manual verification on macOS
- **Description**: Open a real dataset `.comics` file with `SoundAnim`s in the macOS-targeted
  `flutter_comics_viewer` example app; confirm audible playback/stop at the correct scroll positions,
  correct mute/unmute behavior, no crash on dispose mid-playback. Per Requirements' Acceptance
  Criterion 6 and the `sdd-comics-viewer` Phase 4 lesson ("written but never run" isn't sufficient
  evidence) — this is a real run, not a code review.
- **Files**: None (verification only)
- **Dependencies**: Phase 3 checkpoint
- **Verification**: Documented in `04-implementation-log.md` with what was actually observed.
- **Complexity**: Low (mechanically), but requires real device/simulator access — may need to be
  deferred the same way the sibling flow's Task 5.5 was, if this session lacks that access. If
  deferred, disclose explicitly, same standard as that flow's own handling.

#### Task 4.2: Cross-reference `flows/comics-viewer/sdd-comics-viewer`'s `_status.md`
- **Description**: Add a disclosed note to that flow's own `_status.md` that this flow modified files
  it owns (`dart_comics_viewer_backend.dart`, `dart_comics_viewer_surface.dart` if touched, new
  `sound_playback.dart`) — the same item `flows/sdd-flutter-comics` also flagged and left undone; this
  flow should actually do it rather than deferring a third time.
- **Files**:
  - `flows/comics-viewer/sdd-comics-viewer/_status.md` — Modify (add cross-reference note)
- **Dependencies**: Phase 3 checkpoint
- **Verification**: N/A (documentation)
- **Complexity**: Low

## Dependency Graph

```
1.1 -> 1.2                          (Phase 1: SoundGating move)
2.1 -> 2.2 -> 2.3                   (Phase 2: SoundPlaybackTrack, independent of Phase 1)
(1.1, 2.2) -> 3.1 -> 3.2 -> 3.3     (Phase 3: wiring, needs both Phase 1 and Phase 2 done)
3.3 -> 4.1, 4.2                     (Phase 4: verification + disclosure, independent of each other)
```

Phases 1 and 2 have no dependency on each other and could be done in either order or interleaved;
Phase 3 needs both complete first.

## Risk Areas

- **Web autoplay restrictions** (flagged as an Open Design Question in Specifications, not resolved
  here) — Task 3.2's error handling should at minimum not crash on a rejected `play()` future, per
  Specifications' Error Handling table, even though the full UX resolution is out of scope.
- **`audioplayers` testability without real audio hardware** — Task 2.3/3.3 assume this works cleanly
  in a `flutter test` environment (no live output device); if it doesn't, those tasks may need a
  fake/mock player abstraction instead of exercising the real `AudioPlayer` — a real implementation-
  time discovery risk, flagged rather than assumed away.

## Open Implementation Questions

- [ ] Exact mechanism for Task 3.3's test assertions (real `AudioPlayer` state vs. a fake/spy) —
      decided during implementation based on what `flutter test` actually allows, per the Risk Areas
      note above.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-08
- [x] Notes: v1.0 sound plan approved and implemented; its manual audible sign-off remains deferred.

## v1.1 Addendum: v2012/v2026, Canonical Scroll Coordinate, Camera, and Depth

The shared dependency is already complete: `flutter_comics` owns parsing, normalization, cloning,
and camera/depth evaluation. This addendum only wires that contract into viewer layout, sound, and
the example application. It does not add another JSON parser, camera formula, native-platform branch,
horizontal renderer, or new interaction concept.

### Phase 5: One document-space scroll coordinate

#### Task 5.1: Retain the source document and reset safely on load

- **Description**: Add optional `ComicsDoc? sourceDocument` to `DartComicsDocument` so existing
  manually-created documents remain source-compatible while backend-created documents expose their
  shared `cameraPath`. On successful archive replacement, pause autoplay, reset `_position` to zero,
  rebuild the document with `sourceDocument: comicsDoc`, and report the reset through the existing
  scroll callback. Do not rebuild or copy camera/depth fields into viewer-specific wrappers.
- **Files**:
  - `lib/src/dart_comics_viewer_backend.dart` — Modify
  - `test/dart_comics_viewer_backend_test.dart` — Modify
- **Dependencies**: Completed `sdd-flutter-comics` Phase 6.
- **Verification**: Existing public constructor calls compile; loaded documents retain the exact
  shared `ComicsDoc`; a second load resets position/playback and replaces the prior source.
- **Complexity**: Medium

#### Task 5.2: Store measured scroll travel in the backend

- **Description**: Add finite, nonnegative `_documentScrollTravel`, a synchronous no-notify
  `updateDocumentScrollTravel(double)` for the surface, and
  `documentScrollOffsetFor(normalizedPosition)`. The conversion clamps normalized input and returns
  document-space pixels. Layout measurement itself must not trigger sounds or notifications.
- **Files**:
  - `lib/src/dart_comics_viewer_backend.dart` — Modify
  - `test/dart_comics_viewer_backend_test.dart` — Modify
- **Dependencies**: Task 5.1
- **Verification**: zero before layout; exact 0/50/100% results for known travel; negative,
  non-finite, and out-of-range inputs remain finite and clamped.
- **Complexity**: Low

#### Task 5.3: Make sound gating consume the canonical offset

- **Description**: Replace both `position * document.height` sound coordinates with
  `documentScrollOffsetFor(position)`. Keep the established one-shot/range semantics and ensure a
  viewport-travel update alone never evaluates or replays sound.
- **Files**:
  - `lib/src/dart_comics_viewer_backend.dart` — Modify
  - `test/dart_comics_viewer_backend_test.dart` — Modify
- **Dependencies**: Task 5.2
- **Verification**: a synthetic sound gate fires at its document offset according to measured
  travel rather than full document height; resize/travel changes alone produce no action.
- **Complexity**: Medium

**Phase 5 checkpoint**: backend tests pass with one axis-neutral document-space coordinate; no
rendering change has landed yet.

### Phase 6: Surface travel and per-layer camera/depth composition

#### Task 6.1: Convert vertical layout to document-space travel

- **Description**: In `LayoutBuilder`, calculate width-fit scale, viewport height in document
  pixels, and `scrollTravelDoc = max(0, document.height - viewportHeightDoc)`. Store it through Task
  5.2, use the resulting `documentScrollOffset` for the strip translation and every authored
  `KeyframeInterpolator` call. Remove the old full-height `time` and device-pixel travel split.
- **Files**:
  - `lib/src/dart_comics_viewer_surface.dart` — Modify
  - `test/dart_comics_viewer_surface_test.dart` — Create
- **Dependencies**: Phase 5 checkpoint
- **Verification**: known viewport constraints yield the specified scale/travel/strip offset;
  content shorter than the viewport stays at offset zero; resize recomputes without accumulation.
- **Complexity**: Medium

#### Task 6.2: Apply one z-depth camera adjustment per layer

- **Description**: `_DartLayer` receives the source camera path and canonical document offset. After
  authored translation, call shared `CameraPathEvaluator.parallaxAdjustment` exactly once with the
  layer's `zDepth`, add that document-space adjustment, then apply existing viewport scaling.
  Rotation, scale, alpha, tile placement, and global strip translation retain their responsibilities;
  no whole-scene camera translation or parent-transform reconstruction is added.
- **Files**:
  - `lib/src/dart_comics_viewer_surface.dart` — Modify
  - `test/dart_comics_viewer_surface_test.dart` — Modify
- **Dependencies**: Task 6.1
- **Verification**: exact `Positioned.left/top` for `z=0`, `z=1`, and `z=-0.5`; no/one-point path is
  inert; reference plane is not translated twice; all resulting values remain finite.
- **Complexity**: Medium

#### Task 6.3: Verify resize and real-format compatibility

- **Description**: Add package-level coverage showing phone/tablet/desktop constraints evaluate the
  same authored document position and differ only by final scale. Load both supplied real archives
  through the existing backend: v2012 retains 177 classic layers/2 sounds with null path and zero
  depth; v2026 retains 519 layers/19 path points/505 nonzero depth values. Large fixtures remain in
  the example asset directory and are referenced in place, not copied.
- **Files**:
  - `test/dart_comics_viewer_backend_test.dart` — Modify
  - `test/dart_comics_viewer_surface_test.dart` — Modify
- **Dependencies**: Tasks 6.1-6.2
- **Verification**: targeted fixture and widget tests pass without a separate v2012 rendering path.
- **Complexity**: Medium

**Phase 6 checkpoint**: the current vertical Dart surface renders additive v2026 camera/depth and
keeps v2012 behavior inert. Future horizontal-strip support can reuse the backend evaluator by
supplying horizontal document travel, but is not enabled here.

### Phase 7: Two-fixture example and one-action switching

#### Task 7.1: Replace the singular sample contract

- **Description**: Introduce `SampleVersion { v2012, v2026 }`, default to v2026, and map each value to
  its same-named asset. Replace the manifest's nonexistent singular entry with both files. The user
  has already removed `assets/sample.comics`; do not recreate it or copy either large fixture.
- **Files**:
  - `example/lib/main.dart` — Modify
  - `example/pubspec.yaml` — Modify
- **Dependencies**: Phase 6 checkpoint
- **Verification**: `flutter analyze` no longer reports the stale asset entry; v2026 loads by default;
  both asset paths resolve.
- **Complexity**: Low

#### Task 7.2: Add the compact sample selector and accurate state text

- **Description**: Add one `SegmentedButton<SampleVersion>` to the existing controls. One selection
  action pauses playback and loads the chosen archive; backend load resets position. Status and
  errors name the active file. Preserve test injection through `MyApp.source` and do not add a file
  picker, preference, or second navigation surface.
- **Files**:
  - `example/lib/main.dart` — Modify
  - `example/test/widget_test.dart` — Modify
- **Dependencies**: Task 7.1
- **Verification**: default selection, one-tap switch, filename, pause, reset, and injected-source
  behavior all have widget coverage.
- **Complexity**: Medium

#### Task 7.3: Exercise both real archives on macOS

- **Description**: Update the existing integration test to load/render/scroll v2026, switch once,
  then load/render/scroll v2012. Assert a Dart surface and images are present and no viewer error is
  reported. This is a runtime smoke test, not pixel-golden validation or subjective sound sign-off.
- **Files**:
  - `example/integration_test/plugin_integration_test.dart` — Modify
- **Dependencies**: Task 7.2
- **Verification**: real macOS integration test passes for both bundled fixtures.
- **Complexity**: Medium (large real archives and platform runtime)

### Phase 8: Regression, platform build evidence, and flow handoff

#### Task 8.1: Full automated regression gate

- **Description**: Format touched Dart files; run package and example analyzers/tests. Build Web to
  compile the shared Dart route used by Web/Linux/macOS without changing native iOS/Android or the
  Windows WPF backend. On this macOS host, Linux runtime execution is unavailable and must not be
  represented as performed.
- **Files**: No production changes expected.
- **Dependencies**: Phases 5-7
- **Verification**: `flutter analyze` and `flutter test` in the package; `flutter analyze` and
  `flutter test` in the example; `flutter build web`; macOS integration result from Task 7.3.
- **Complexity**: Low

#### Task 8.2: Record implementation and cross-flow ownership

- **Description**: Update this flow's implementation log/status with exact test/build counts and
  deviations. Add the already-disclosed cross-reference to `sdd-comics-viewer/_status.md`, because
  backend/surface files are shared ownership. Keep the separate deferred human audible sound check
  explicit.
- **Files**:
  - `04-implementation-log.md` — Modify
  - `_status.md` — Modify
  - `../sdd-comics-viewer/_status.md` — Modify
- **Dependencies**: Task 8.1
- **Verification**: documentation matches observed commands; no unperformed platform claim.
- **Complexity**: Low

## v1.1 Dependency Graph

```text
5.1 -> 5.2 -> 5.3 -> 6.1 -> 6.2 -> 6.3 -> 7.1 -> 7.2 -> 7.3 -> 8.1 -> 8.2
```

The sequence is deliberate: first establish the coordinate contract without visual changes, then
apply it to pixels, then expose the two real archives in the example. Each checkpoint leaves the
package testable before the next responsibility is introduced.

## v1.1 Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Camera applied globally and per layer | Double movement | Surface test asserts `z=0` has zero adjustment and the strip receives scroll only |
| Viewport resize changes animation/sound semantics | Cross-device drift or replay | One stored document travel; layout update has no notify/sound side effect; resize tests |
| Backend evaluates sound before first layout | Incorrect early gate | Initial travel is zero; tests cover pre-layout behavior |
| Large real fixtures make tests slow or memory-heavy | Flaky CI | Keep one copy in example assets, use targeted real-fixture smoke plus small synthetic math tests |
| Web/Linux behavior diverges from macOS | Platform regression | Same Dart backend/surface, Web build evidence, analyzer/widget tests; do not claim unavailable Linux runtime |

## v1.1 Rollback Strategy

Camera/depth consumption is additive. If surface wiring regresses, revert Phases 5-6 together so
sound and animation return to their prior shared coordinate; the already-compatible shared parser
and model remain intact. The example asset/selector change is independent and can be rolled back
without modifying archive contents. No native platform source or format migration is involved.

## v1.1 Checkpoints

- [x] Phase 5: backend coordinate and sound tests green
- [x] Phase 6: synthetic camera/depth, resize, and both real-format tests green
- [x] Phase 7: example widget and macOS dual-fixture integration tests green
- [x] Phase 8: analyzers, package/example tests, Web build, and flow logs complete

## v1.1 Approval Gate

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-10
- [x] Notes: v1.1 implementation authorized by explicit `plan approved`.
