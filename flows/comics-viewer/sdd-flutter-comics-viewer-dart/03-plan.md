# Implementation Plan: sdd-flutter-comics-viewer-dart — sound playback for the Dart `.comics` viewer

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-08-08
> Specifications: [02-specifications.md](02-specifications.md) (v0.1, APPROVED)

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

- [ ] Reviewed by: Anton Dodonov
- [ ] Approved on:
- [ ] Notes:
