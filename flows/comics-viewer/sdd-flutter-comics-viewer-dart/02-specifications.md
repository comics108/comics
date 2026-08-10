# Specifications: sdd-flutter-comics-viewer-dart — sound, v2012 compatibility, camera, and depth

> Version: 0.2 (camera/depth and v2012 compatibility addendum)
> Status: SOUND BASELINE IMPLEMENTED; v0.2 ADDENDUM APPROVED
> Last Updated: 2026-08-10
> Requirements: [01-requirements.md](01-requirements.md) (v0.5, APPROVED)

## Overview

Add real sound playback to `DartComicsViewerBackend` (macOS/Linux/Web), matching the current
`comics-viewer-ios`'s confirmed `playSoundsByOffset` semantics — one-shot and looping-range sounds,
gated by scroll position, respecting a mute/enabled toggle. **A third, independent implementation of
the exact same gating logic already exists in this monorepo and must be reused, not reinvented**:
`apps/comics-editor/lib/src/ui/audio/sound_player.dart`'s `SoundGating` (ported from
`legacy/comics-editor-v2.8/Comics.Editor`'s `SoundAnim.FindCurrent`) implements byte-for-byte the same
one-shot/range/no-replay-on-scroll-up rules independently derived from the Swift source in
Requirements — a third source agreeing with the other two. `SoundGating` is already pure and portable
(operates only on the shared `List<Anim>`, no `apps/comics-editor`-specific coupling) and moves into
`libs/flutter_comics`, the same pattern already used for `KeyframeInterpolator`.

## v0.2 Addendum: v2012 Compatibility + Camera Path + Z-Depth

The approved shared-library Plan has now delivered `CameraPath`, `CameraKeyframe`,
`EditorLayer.zDepth`, and `CameraPathEvaluator`. This viewer addendum consumes those types; it does
not parse or reimplement their JSON/math.

### Affected Systems

| System | Change |
|--------|--------|
| `lib/src/dart_comics_viewer_backend.dart` | Retain the source `ComicsDoc` on `DartComicsDocument`; own the measured document scroll travel; evaluate sounds from the same document-space offset used by rendering; reset position when a new archive loads |
| `lib/src/dart_comics_viewer_surface.dart` | Convert viewport constraints to document-space travel; apply one shared camera-depth adjustment after authored translation and before viewport scaling |
| `test/dart_comics_viewer_backend_test.dart` | v2012 defaults, v2026 camera/depth propagation, scroll-coordinate and sound-coordinate tests |
| `test/dart_comics_viewer_surface_test.dart` | Exact zero/far/near `Positioned` offsets and resize invariance |
| `example/lib/main.dart` | Replace the stale singular sample path with a two-value sample selector; v2026 default, v2012 selectable in one action |
| `example/pubspec.yaml` | Bundle `sample_v2012.comics` and `sample_v2026.comics`, no nonexistent `sample.comics` |
| `example/test/widget_test.dart` | Verify label, one-action switch, reset, and synthetic camera/depth rendering |
| `example/integration_test/plugin_integration_test.dart` | Real macOS load/render/scroll smoke for both supplied archives |

Native Android/iOS sources and the Windows WPF route are unchanged by this addendum.

### Data and ownership

`RenderedLayer.editorLayer` already points at the shared `EditorLayer`, so `zDepth` needs no viewer
wrapper field. `DartComicsDocument` gains an optional source-document reference without breaking its
existing public constructor shape:

```dart
@immutable
class DartComicsDocument {
  const DartComicsDocument({
    required this.width,
    required this.height,
    required this.layers,
    this.sourceDocument,
  });

  final double width;
  final double height;
  final List<RenderedLayer> layers;
  final ComicsDoc? sourceDocument; // backend always sets; null is legacy/manual inert fallback
}
```

The backend remains the only archive owner. `_rebuild()` passes its already-parsed `_comicsDoc`
into `sourceDocument`; the surface reads `sourceDocument?.cameraPath`. No second JSON peek is added
for either camera or depth.

### One canonical document-space scroll coordinate

The normalized public controller position remains `[0,1]`. Layout converts it to the actual visible
document offset:

```text
scale = viewportWidthPx / documentWidth
viewportHeightDoc = viewportHeightPx / scale
scrollTravelDoc = max(0, documentHeight - viewportHeightDoc)
documentScrollOffset = normalizedPosition * scrollTravelDoc
screenStripOffsetY = -documentScrollOffset * scale
```

`DartComicsViewerBackend` gains these internal/public-for-surface operations:

```dart
double _documentScrollTravel = 0;

void updateDocumentScrollTravel(double value) {
  _documentScrollTravel = value.isFinite && value > 0 ? value : 0;
  // No notify and no sound trigger: layout itself is not a user scroll event.
}

double documentScrollOffsetFor(double normalizedPosition) =>
    normalizedPosition.clamp(0.0, 1.0) * _documentScrollTravel;
```

During `LayoutBuilder`, the surface computes `scrollTravelDoc`, updates the backend synchronously
without notifying, and then uses `documentScrollOffsetFor(backend.position)`. Subsequent controller
scroll/autoplay events and `_evaluateSounds` use that same stored conversion. Before the first layout,
travel is zero; this is preferable to firing sound at a guessed coordinate. A viewport resize updates
travel but does not itself replay point sounds or enter/leave ranges; the next actual position event
uses the new coordinate.

This replaces both current `position * document.height` usages. It matches
`tdd-dot-comics-format`'s raw document-pixel scroll domain and the native viewer's
`contentOffset / zoomScale` semantics. The API name is axis-neutral so a future horizontal surface
can supply width travel without introducing different camera math.

### Layer composition

For each rendered layer:

```dart
final authored = KeyframeInterpolator.translateAt(
  layer.editorLayer.anims,
  documentScrollOffset,
  layer.editorLayer.translate,
);
final parallax = CameraPathEvaluator.parallaxAdjustment(
  document.sourceDocument?.cameraPath,
  documentScrollOffset,
  layer.editorLayer.zDepth,
);
final effective = authored + parallax;

// Existing rotate/scale/alpha composition remains unchanged.
Positioned(left: effective.dx * scale, top: effective.dy * scale, ...);
```

The whole strip still receives only `-documentScrollOffset * scale`. `cameraPath` is never applied
as an additional strip/global transform: the importer already persisted reference-plane motion in
layer animations, and adding `C(s)` globally would double it. Parent metadata is likewise not
resolved here because persisted animations are already absolute; each visual layer receives only
its own `zDepth` adjustment once.

### v2012 format behavior

The two byte-identical authoritative v2012 fixtures are read through the same
`ComicsArchiveReader`. Their absent additive fields resolve as:

```text
scrollType=vertical
preferredOrientation=portrait
preferredViewport=720x1600 (metadata default; actual viewer viewport still comes from constraints)
Anim.basis=scroll
cameraPath=null
zDepth=0
```

Consequently the camera adjustment is exactly zero for all 177 layers. The four visual animation
types continue through `KeyframeInterpolator`; the two sound entries continue through
`SoundGating`, including the real negative range start. This is one current reader/surface path,
not a `if (v2012)` compatibility renderer.

### Example interaction

The example defines `enum SampleVersion { v2012, v2026 }` and a single compact
`SegmentedButton<SampleVersion>` labeled `v2012`/`v2026`. Selection defaults to v2026. Each segment
maps directly to its same-named asset; selection loads new bytes with the asset path as
`revisionKey`, pauses playback, and the backend's `load()` resets position to `0` before notifying.
Status text always contains the active filename. No file picker or persistent preference is added.

### Error and edge handling

| Case | Result |
|------|--------|
| no/empty/one-point camera path | shared evaluator returns zero parallax |
| invalid depth/path data | shared reader/evaluator normalization; viewer never sees a non-finite adjustment |
| viewport wider/taller than content | travel clamps to zero; strip, animations, sound, and camera evaluate at zero |
| resize at nonzero normalized position | recompute the one document offset; no accumulated transform and no resize-triggered sound |
| source document absent on manually-created `DartComicsDocument` | inert camera fallback, preserving constructor compatibility |
| switching example while playing | pause, load, reset to zero; old archive sound tracks are disposed by existing load logic |
| positive/negative/zero depth | shared response applied once; final device-pixel multiplication happens afterward |

### Testing strategy

- Backend unit: the real v2012 archive parses 177 layers/2 sounds with all depths zero and null path;
  real v2026 parses 519 layers/19 camera points/505 nonzero depths.
- Coordinate unit: 50% position with a known viewport produces 50% of document scroll travel, not
  50% of full document height; `_evaluateSounds` receives those same before/after values.
- Surface widget: a synthetic path plus `z=0`, `z=1`, and `z=-0.5` layers yields exact expected
  `Positioned.left/top` values after scaling; camera is not applied globally.
- Resize widget: the same document-space target under phone/tablet/desktop constraints has equal
  shared camera/parallax values and only final pixel scale differs.
- Example widget: v2026 is selected initially; one tap switches to v2012, updates label/source, and
  resets position.
- macOS integration: each real asset loads, renders at least one image, reaches a nonzero position,
  and reports no viewer error. Audible subjective sign-off remains the pre-existing deferred sound
  item, not a new camera blocker.

### Rollout

The viewer change depends on the just-completed shared Phase 6 and must use its local package version
during implementation. No migration is needed. v2012 behavior is guarded first, then v2026 camera
rendering is added, then the example switches to the two real fixtures. A failure can be isolated by
reverting the surface/backend consumption while leaving the additive shared parser/model intact.

The original v0.1 sound sections below are retained as the implementation record. Wherever they
describe `position * document.height`, this v0.2 addendum supersedes that coordinate with
`documentScrollOffsetFor(position)` as defined above; camera, visual animation, and sound must share
that one value.

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `libs/flutter_comics/lib/src/sound_gating.dart` (new) | Create | `SoundGating`/`SoundAction`, moved verbatim from `apps/comics-editor/lib/src/ui/audio/sound_player.dart` |
| `libs/flutter_comics/test/sound_gating_test.dart` (new) | Create (moved) | Relocated from `apps/comics-editor/test/sound_gating_test.dart` |
| `libs/flutter_comics/lib/flutter_comics.dart` | Modify | Export `sound_gating.dart` |
| `apps/comics-editor/lib/src/ui/audio/sound_player.dart` | Modify | Deletes its own `SoundAction`/`SoundGating` definitions, imports them from `package:flutter_comics/flutter_comics.dart` instead; `SoundPlayer` (the `audioplayers`/`DeviceFileSource` half) is UNCHANGED — it's editor-specific (real extracted files on disk via the native core), not portable |
| `libs/comics_viewer/flutter_comics_viewer/pubspec.yaml` | Modify | Add `audioplayers: ^6.8.1` (same version already pinned in `apps/comics-editor`, for consistency) |
| `libs/comics_viewer/flutter_comics_viewer/lib/src/dart_comics_viewer_backend.dart` | Modify | New sound-bytes extraction in `_rebuild()`/`load()`; new `_evaluateSounds()` hook called from `play()`'s timer tick and `setScrollPosition()`; `setSoundEnabled`/`setMuted` become real; `dispose()` disposes sound players |
| `libs/comics_viewer/flutter_comics_viewer/lib/src/sound_playback.dart` (new) | Create | `BytesSource`-based per-sound player wrapper, the viewer-side counterpart to `SoundPlayer` (which uses `DeviceFileSource` — not reusable as-is, since the viewer only ever has in-memory ZIP bytes, never an extracted file path) |
| `libs/comics_viewer/flutter_comics_viewer/test/dart_comics_viewer_backend_test.dart` | Modify | New test cases for sound-triggering at the right scroll positions |
| `libs/comics_viewer/flutter_comics_viewer/test/sound_playback_test.dart` (new) | Create | Unit tests for the new `BytesSource`-based wrapper |

**Not touched**: `comics-viewer-ios`/`comics-viewer-android` (native, read-only reference per
Requirements' explicit constraint), `WindowsComicsViewerBackend` (separate, working approach, out of
scope), any `.comics` schema (`flows/tdd-dot-comics-format`'s domain).

## Architecture

### Component Diagram

```
libs/flutter_comics (shared, portable)
├── models.dart            EditorSound { file, anims: List<Anim> }, Anim { type, start, end }
├── keyframe_interpolator.dart   (existing, unrelated to sound)
└── sound_gating.dart (NEW)      SoundGating.decide({soundAnims, prevTime, currentTime,
                                    currentlyPlaying}) -> SoundAction {none, playOnce,
                                    startLooping, stop}
        ^                                          ^
        | package:flutter_comics/flutter_comics.dart
        |                                          |
apps/comics-editor                        flutter_comics_viewer
  sound_player.dart:                        sound_playback.dart (NEW):
    SoundPlayer wraps AudioPlayer,            SoundPlaybackTrack wraps AudioPlayer,
    plays via DeviceFileSource(path)          plays via BytesSource(bytes) -- the sound file's
    (real files, extracted by the             raw bytes read directly from the in-memory ZIP
    native core to a temp folder)              archive (flutter_comics_viewer never extracts to
                                                disk, unlike the editor's native-core-backed path)
```

### Data Flow

```
DartComicsViewerBackend.load():
  ComicsArchiveReader.readBytes(bytes) -> ComicsDoc.sounds: List<EditorSound>  (ALREADY parsed today,
    confirmed by reading comics_reader.dart:228-235 -- just never consumed by this backend until now)
  for each EditorSound: archive.findFile('sounds/${sound.file}') -> raw bytes, kept alongside a new
    SoundPlaybackTrack(bytes) per sound (lazy: only created if the archive actually has the file)

Every position change (play()'s Timer.periodic tick, or setScrollPosition()):
  previousTime = _position(before) * document.height   -- same "time" coordinate space
  currentTime  = _position(after)  * document.height       DartComicsViewerSurface already uses for
                                                             KeyframeInterpolator (position * height)
  for each (EditorSound, SoundPlaybackTrack) pair:
    action = SoundGating.decide(soundAnims: sound.anims, prevTime: previousTime,
                                 currentTime: currentTime, currentlyPlaying: track.isPlaying)
    track.apply(action)   -- playOnce / startLooping / stop / none

setSoundEnabled(false) / setMuted(true):
  pause every currently-playing SoundPlaybackTrack (NOT stop -- SoundGating's own `currentlyPlaying`
  bookkeeping must stay true, matching Swift's per-player `isMuted` toggle rather than a hard stop, so
  unmuting resumes instead of spuriously re-triggering a one-shot sound)
setSoundEnabled(true) / setMuted(false):
  resume every track that SoundGating currently considers playing
```

## Interfaces

### New Interfaces

```dart
// libs/flutter_comics/lib/src/sound_gating.dart -- moved verbatim from
// apps/comics-editor/lib/src/ui/audio/sound_player.dart, zero logic changes.
enum SoundAction { none, playOnce, startLooping, stop }

class SoundGating {
  SoundGating._();
  static SoundAction decide({
    required List<Anim> soundAnims,
    required double prevTime,
    required double currentTime,
    required bool currentlyPlaying,
  });
  // _findCurrent stays private/unchanged: matches a genuine range (start <= currentTime <= end) or
  // a point (start == end) crossed while scrolling DOWNWARD specifically -- scrolling back up past
  // a point-trigger does not replay it. Confirmed identical to comics-viewer-ios's
  // playSoundsByOffset (Requirements' Acceptance Criteria 1-2).
}
```

```dart
// libs/comics_viewer/flutter_comics_viewer/lib/src/sound_playback.dart -- NEW
// Viewer-side counterpart to apps/comics-editor's SoundPlayer, using BytesSource instead of
// DeviceFileSource since this package only ever has in-memory archive bytes.
class SoundPlaybackTrack {
  SoundPlaybackTrack(this.bytes);
  final Uint8List bytes;
  final AudioPlayer _player = AudioPlayer();
  bool get isPlaying;   // this class's own bookkeeping, not asked from _player every tick --
                         // see "muting pauses, doesn't stop" in Data Flow above
  bool _mutedWhilePlaying = false;

  Future<void> apply(SoundAction action);  // playOnce -> _player.play(BytesSource(bytes)); loop=false
                                            // startLooping -> _player.play(BytesSource(bytes)),
                                            //   _player.setReleaseMode(ReleaseMode.loop)
                                            // stop -> _player.stop()
                                            // none -> no-op
  Future<void> setMuted(bool muted);       // true: pause() if isPlaying, remember to resume;
                                            // false: resume() if it was muted-while-playing
  Future<void> dispose() => _player.dispose();
}
```

### Modified Interfaces

```dart
// libs/comics_viewer/flutter_comics_viewer/lib/src/dart_comics_viewer_backend.dart
final class DartComicsViewerBackend extends ChangeNotifier implements ComicsViewerBackend {
  // NEW internal state:
  final Map<EditorSound, SoundPlaybackTrack> _soundTracks = {};
  bool _soundEnabled = true;
  bool _muted = false;
  bool get _effectivelyMuted => !_soundEnabled || _muted;

  // load()/_rebuild(): after building `document`, also populate _soundTracks from
  // comicsDoc.sounds + archive.findFile('sounds/${sound.file}') -- skip silently (no _onError call)
  // if a referenced sound file is missing from the archive, matching this format's established
  // tolerant-of-missing-sub-resource convention (see Edge Cases).

  // NEW private method, called from BOTH play()'s Timer.periodic tick and setScrollPosition(),
  // right after _position is updated:
  Future<void> _evaluateSounds(double previousPosition, double newPosition) async { ... }

  @override
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    for (final track in _soundTracks.values) { await track.setMuted(_effectivelyMuted); }
  }

  @override
  Future<void> setMuted(bool muted) async {
    _muted = muted;
    for (final track in _soundTracks.values) { await track.setMuted(_effectivelyMuted); }
  }

  @override
  Future<void> dispose() async {
    // ...existing timer cancel...
    for (final track in _soundTracks.values) { await track.dispose(); }
    super.dispose();
  }
}
```

## Data Models

### New Types

`SoundAction` (moved), `SoundPlaybackTrack` (new) — both listed under Interfaces above. No `.comics`
schema changes — `EditorSound`/`Anim` already carry everything needed (confirmed:
`comics_reader.dart:228-235` already parses `ComicsDoc.sounds` fully today).

### Schema Changes

None.

## Behavior Specifications

### Happy Path

1. `load()` populates `document` (unchanged) and, additionally, `_soundTracks` — one
   `SoundPlaybackTrack` per `EditorSound` whose file exists in the archive.
2. User scrolls (or `play()`'s autoplay timer advances `_position`). `_evaluateSounds` computes
   `previousTime`/`currentTime` in the same `position * document.height` coordinate space the surface
   already uses for `KeyframeInterpolator`, and calls `SoundGating.decide` once per `EditorSound`.
3. A one-shot `SoundAnim` (`start == end`) crossed downward → `playOnce`: `SoundPlaybackTrack.apply`
   plays it once, no loop.
4. A range `SoundAnim` (`start < end`) entered → `startLooping`; left → `stop`.
5. `setSoundEnabled(false)`/`setMuted(true)` pause all active tracks without losing `SoundGating`'s
   `currentlyPlaying` bookkeeping; re-enabling resumes them from where they left off — no spurious
   re-triggering of a one-shot sound that already played.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| Sound file referenced in `data.json` but missing from the archive | Malformed/corrupt `.comics` file | Skip that sound silently at load time (no `SoundPlaybackTrack` created for it) — matches this format's established tolerant-of-missing-sub-resource convention, not a hard load error |
| `setScrollPosition` called with a large jump (e.g. dragging a scrollbar far, or opening a document already mid-scroll) | Real, common interaction | `SoundGating.decide`'s existing range/point logic already handles this correctly (confirmed by the moved, already-tested `SoundGating`) — a large downward jump across a one-shot point still triggers it once; a large upward jump does not retrigger anything |
| Two or more sounds active simultaneously (real `.comics` files can have multiple `Sound` entries) | Real content, e.g. ambient background + a foreground effect | Each `EditorSound` has its own independent `SoundPlaybackTrack` — no shared state, both play/stop independently, matching Swift's per-sound iteration in `playSoundsByOffset` |
| `setLanguageIndex`/`togglePreview` trigger `_rebuild()` while sounds are playing | Real interaction (language switch mid-read) | `_rebuild()` currently only rebuilds `document` (visual layers) — sound tracks/state must NOT be torn down and rebuilt on every `_rebuild()` call (language/preview changes don't affect `comicsDoc.sounds`), or currently-playing sound would audibly restart on every language toggle. `_soundTracks` population should happen once at `load()` time, not inside `_rebuild()`. |
| `dispose()` called while sounds are playing | Widget removed from tree mid-playback | Every `SoundPlaybackTrack` must be disposed (stops playback + releases the underlying `AudioPlayer`), not just the scroll `Timer` — a real, disclosed gap in the CURRENT `dispose()` this flow must close |
| Web platform's audio-autoplay restrictions | `DartComicsViewerBackend` also serves `kIsWeb` (`comics_viewer.dart:57`) | Browsers commonly block audio playback before a user gesture — `audioplayers`' Web backend surfaces this as a rejected `play()` future; this flow's implementation should not crash on that rejection (catch and treat as "sound blocked, will retry on next user-gesture-adjacent call"), but a full resolution may need product input — flagged in Open Design Questions, not silently ignored |

### Error Handling

| Error | Cause | Response |
|-------|-------|----------|
| `AudioPlayer.play()` throws/rejects (missing codec, Web autoplay block, etc.) | Platform/browser limitation | Caught, does not propagate to `_onError` (a per-sound playback hiccup shouldn't be treated the same as a load-time archive error) — logged via `debugPrint` or similar, not silently swallowed without any trace |

## Dependencies

### Requires

- `flows/sdd-flutter-comics` — IMPLEMENTATION COMPLETE, `ComicsDoc.sounds`/`EditorSound`/`Anim` already
  available via `ComicsArchiveReader`. This flow's own small addition (`sound_gating.dart`) touches
  that package again — a disclosed, additive touch, not a re-opening of its whole scope.
- `audioplayers: ^6.8.1` — already a proven dependency elsewhere in this monorepo
  (`apps/comics-editor`), not a new/unvetted package choice.

### Blocks

- Nothing currently depends on this flow.

## Integration Points

### Internal Systems

- `flows/comics-viewer/sdd-comics-viewer` owns `flutter_comics_viewer` — this flow's changes need the
  same disclosed cross-reference that flow's own Blockers list already flags as outstanding (adding it
  is this flow's responsibility now, not deferred again).
- `apps/comics-editor`'s `sound_player.dart` — modified (import source only), verified via its
  existing test suite staying green.

## Testing Strategy

### Unit Tests

- [ ] `libs/flutter_comics/test/sound_gating_test.dart` (relocated) — unchanged assertions, new import
- [ ] `libs/comics_viewer/flutter_comics_viewer/test/sound_playback_test.dart` (new) — `SoundPlaybackTrack.apply`'s
      four `SoundAction` cases against a real (small, synthetic/silent) audio byte payload; `setMuted`
      pause/resume bookkeeping
- [ ] `dart_comics_viewer_backend_test.dart` (extended) — a synthetic archive with a one-shot sound and
      a range sound; scripted `setScrollPosition` calls assert playback state transitions at the
      correct positions (mirrors Requirements' Acceptance Criteria 1-2 directly)

### Integration Tests

- [ ] A real dataset `.comics` file with `SoundAnim`s, opened through `DartComicsViewerBackend`,
      scrolled programmatically end-to-end — asserts no exceptions and that sound state transitions
      happen at the file's real, known `SoundAnim` positions

### Manual Verification

- [ ] Open a real dataset `.comics` file with sound on macOS, confirm audible playback/stop at the
      right scroll positions and correct mute behavior — per Requirements' Acceptance Criterion 6's
      "written but never run" lesson, this should actually be done, not just automated-tested, before
      calling this flow complete

## Migration / Rollout

Single-shot, not phased: (1) move `SoundGating`/`SoundAction` + its test into `libs/flutter_comics`,
verify `apps/comics-editor` still green; (2) add `audioplayers` dependency + write
`sound_playback.dart` + its test in `flutter_comics_viewer`; (3) wire `_evaluateSounds`/
`setSoundEnabled`/`setMuted`/`dispose` into `dart_comics_viewer_backend.dart`, extend its test file;
(4) manual verification per above. Each step independently verifiable, matching this repo's
established "one test at a time" discipline.

## Open Design Questions

- [ ] **Web autoplay-restriction handling**: exact retry/recovery UX when a browser blocks
      `AudioPlayer.play()` before a user gesture — not designed here beyond "don't crash," a real
      product-facing decision if Web sound quality matters as much as macOS.
- [ ] **Mute-while-playing semantics**: this spec's "pause, don't stop, resume on unmute" design is a
      reasonable reading of Swift's single `isMuted` toggle line (`ImageScrollView.swift`'s
      `playSound`), but that's the only place mute-while-playing is even mentioned in the source —
      worth Anton's confirmation this matches intended behavior, not just the most plausible reading.
- [ ] **Android sound parity**: `comics-viewer-android`'s `SoundManager.java`/`SoundAnim.java` haven't
      been read in the same depth as Swift's equivalent — if Linux (which shares this Dart backend)
      needs to match Android's specific behavior rather than iOS's, that comparison is still open. Not
      blocking, since Requirements' priority is macOS and the iOS-derived design is the best-evidenced
      one available.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-10
- [x] Notes: v0.1 sound behavior is already implemented. This gate covers only the v0.2
      compatibility/camera/depth/example addendum.
