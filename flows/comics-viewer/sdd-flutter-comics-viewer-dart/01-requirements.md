# Requirements: sdd-flutter-comics-viewer-dart — cross-platform Dart `.comics` viewer (macOS-first)

> Version: 0.3 (2026-08-08: **major correction, supersedes v0.2's already-approved AC #2/#3** — direct
> evidence from the CURRENT, actively-shipped `libs/comics_viewer/comics-viewer-ios` shows `.comics`
> viewing has always been fixed-zoom-to-content-width, with pinch-zoom/tile-LOD real only for a
> different, unrelated content type (puzzle). Anton confirmed the redirect: match v2026 (the current
> native reference libraries), not v2012; don't touch native code. Tile-LOD and pinch-zoom gestures are
> dropped from scope — they were never a real `.comics` feature on any reference platform, current or
> historical. Popup-image handling is also found unreferenced in either reference app's interaction
> code and dropped from scope on the same evidence standard. Real remaining scope: sound playback.)
> Status: DRAFT
> Last Updated: 2026-08-08

## Origin

Anton: "Добавь реализацию для устройств помимо существующей нативки comics-viewer-ios и
comics-viewer-android для просмотра и на остальных операционных устройствах помимо android и ios...
За источник истины возьми реализацию рендеринг именно в `legacy/mahabharata-mobile-swift-v2012`,
поскольку важно сейчас на дарт сделать поддержку на macos. Так же следующий источник истины —
`legacy/mahabharata-mobile-java-v2012`."

**Correction/redirect (2026-08-08, after v0.2's tile-LOD/gesture premise was found to be a misread —
see "Codebase Analysis" below)**: Anton, in response: "flutter_comics_viewer на dart будет работать
именно с v2026, обратная совместимость dart части с v2012 не нужна. Нативную часть не трогай в рамках
этого скоупа." — the Dart viewer targets v2026 (current) behavior specifically; no need for the Dart
side to preserve v2012-specific behavior; don't touch the native `comics-viewer-ios`/`comics-viewer-android`
code within this flow's scope (read-only reference only). This **reinforces** rather than contradicts
the tile-LOD/gesture finding: the current v2026 `comics-viewer-ios` has the byte-identical
fixed-zoom code as the 2012 original, so "match v2026" and "match 2012" agree on this specific point.
`legacy/mahabharata-mobile-swift-v2012`/`-java-v2012` remain useful as historical/supporting evidence
(e.g. the sound-gating logic below, confirmed identical in both eras) but are no longer the literal
compatibility target.

## Codebase Analysis (done before drafting; revised 2026-08-08 after the zoom/popup correction)

**This is not a green-field port — real, working scaffolding for exactly this already exists** and
must be the starting point, not bypassed:

- `libs/comics_viewer/flutter_comics_viewer` already declares plugin classes for all six Flutter
  platforms (`pubspec.yaml`: android/ios/linux/macos/windows/web) and already routes **macOS, Linux,
  and Web** through a real, working pure-Dart backend + rendering surface —
  `DartComicsViewerBackend`/`DartComicsViewerSurface`
  (`lib/src/dart_comics_viewer_backend.dart`/`dart_comics_viewer_surface.dart`), wired up in
  `comics_viewer.dart:55-59,151-154`. Windows routes through a *different*, non-Dart approach
  (`WindowsComicsViewerBackend`, a method-channel bridge to a native WPF child window hosted by
  Comics Editor — out of scope here, already solved differently). Android/iOS use the existing native
  `comics-viewer-android`/`comics-viewer-ios` platform views, unaffected by this flow.
- `DartComicsViewerBackend` genuinely opens `.comics` ZIP archives itself (now via the shared
  `libs/flutter_comics` package's `ComicsArchiveReader`, per `flows/sdd-flutter-comics` — see below),
  decodes `data.json`, walks layers, and interpolates translate/rotate/scale/alpha keyframes with a
  real cubic-ease-out formula via the shared `KeyframeInterpolator` — **verified against
  `legacy/mahabharata-mobile-swift-v2012/Mahabharata/Model/DataClasses/Visual/Animations/Anim.swift:97-99`
  (`transformToCubic`): `pow(fraction - 1, 3) + 1`, byte-for-byte identical to the shared
  `KeyframeInterpolator`'s own cubic factor.** Confirmed identical in the CURRENT
  `libs/comics_viewer/comics-viewer-ios`'s copy of the same file too (`diff` clean) — this is a real,
  confirmed match on both the historical and current reference, not an assumption.
- `DartComicsViewerSurface` genuinely renders: scroll-position-driven `Transform.translate` for the
  page, per-layer `Transform` (rotate+scale about a pivot) + `Opacity`, tiles composited via
  `Stack`/`Positioned`/`Image.memory`. This is real, functioning rendering, not a stub.

### The tile-LOD/pinch-zoom "gap" was a misread — corrected, not a real gap

v0.2 (and its already-approved AC #2/#3) claimed `DartComicsViewerSurface`'s lack of pinch-zoom and
`DartComicsViewerBackend`'s hardcoded full-resolution (`'1000'`) tile selection were real gaps against
Swift's `TileImageView`, which appeared (from `tileName(for:)` and nearby commented-out code) to
support 4 real zoom levels. **Direct re-reading of the surrounding, previously-unread code in the same
file, plus the actual `ImageScrollView` call site, shows this was wrong**:

- `ImageScrollView.swift:113-119` (identical in `legacy/mahabharata-mobile-swift-v2012` AND the
  currently-shipped `libs/comics_viewer/comics-viewer-ios`, confirmed via `diff`):
  ```swift
  //For comics mode zoomScale is fixed
  ...
  let zoomScale = realContentWidth / CGFloat(comics.width)
  self.minimumZoomScale = zoomScale
  self.maximumZoomScale = zoomScale
  self.zoomScale = zoomScale
  ```
  `minimumZoomScale == maximumZoomScale` — **pinch-to-zoom is structurally impossible for `.comics`
  content** in both the 2012 legacy app and the current, actively-shipped iOS reference viewer. There
  is no "zoomed out" state to select a lower-resolution tile for.
- `TileImageView.swift`'s own top-of-file comments explain why the class *looks* like it supports
  variable zoom: `let scale: CGFloat = 1.0 // at least for comix this is always true` and
  `tiledLayer.levelsOfDetail = 1 // at least for comix this is always true` — the class is shared with
  a different content type (puzzle) where zoom *is* real; the `Int(scale * 1000)` naming and the
  commented-out multi-level `Tile` struct below it are that shared class's generic capability, never
  exercised with anything but `scale == 1.0` for `.comics` specifically.
- `DartComicsViewerSurface`'s existing `scale = constraints.maxWidth / document.width`
  (`dart_comics_viewer_surface.dart:23`) is **already the exact same fixed-width-fit formula** as
  Swift's `zoomScale = realContentWidth / comics.width` — the current Dart implementation was already
  correct, not missing a feature.
- Java's `LayersView`/`TileImageView` (`legacy/mahabharata-mobile-java-v2012`, and the current
  `libs/comics_viewer/comics-viewer-android`) take a generic `zoomEnabled: boolean` constructor
  parameter and a real `ScaleGestureDetector`-backed `ZoomFrameLayout` — the underlying capability is
  real, generic infrastructure shared with puzzle mode, consistent with the Swift finding. **Not fully
  pinned down**: the exact call site passing `zoomEnabled=false` for `.comics` specifically wasn't
  located in this pass (Android's comics-viewing call site lives in the consuming app, not this
  library) — flagged as a minor remaining gap in rigor, not a live open question, since the iOS
  evidence (both 2012 and current 2026) is independently dispositive and Anton's "match v2026, don't
  touch native" redirect makes chasing this further low-value.

**Conclusion**: tile-LOD and pinch-zoom gestures are **not real features to port** — building them
would make the Dart viewer diverge from every real reference implementation, current and historical,
not converge with it.

### Popup-image handling — same conclusion, found on the same pass

`Image.popup`/`Layer.popup` are real, parsed model fields on **both** current reference apps
(`comics-viewer-ios`'s `Image.swift`/`Layer.swift`, `comics-viewer-android`'s `Image.java`/`Layer.java`)
— but grepping for `popup`/`Popup` across every `View`/`ViewController`/interaction file in
`comics-viewer-ios` and `comics-viewer-android` returns **zero results outside the model classes
themselves**. The field is parsed but never displayed, tapped, or otherwise acted on by either current
reference renderer. Same standard as the zoom finding: not a real, exercised feature — dropped from
scope, not deferred as an "unresolved gap."

### Sound — the one real, confirmed, still-open gap

| Gap | Evidence | Source of truth detail |
|---|---|---|
| **No sound playback at all** | `DartComicsViewerBackend.setSoundEnabled`/`setMuted` are empty no-op overrides (re-confirmed present in current code, `:246,249`); `SoundAnim`s are parsed but never acted on | `ImageScrollView.swift:271-346` (`playSoundsByOffset`), confirmed byte-identical between `legacy/mahabharata-mobile-swift-v2012` and the current `libs/comics_viewer/comics-viewer-ios` (`diff` clean) — checks every `SoundAnim` against current scroll offset on every scroll tick, distinguishes two real cases by `start == end` vs. `start < end` (see Acceptance Criteria for the exact semantics), starts/stops an `AVAudioSession`-backed player, respects a global mute (`Settings.shared.soundOff`) |

~~Its own minimal, duplicate model~~ **RESOLVED (2026-08-08)** — re-verified directly against current
code, not just `flows/sdd-flutter-comics`'s own log: `dart_comics_viewer_backend.dart` imports
`package:flutter_comics/flutter_comics.dart`, calls `ComicsArchiveReader.readBytes(bytes)` (`:129`)
for a real `ComicsDoc`, and a new `RenderedLayer` (`:33`) wraps real tile pixel bytes + a direct
`EditorLayer` reference — `DartViewerAnimType`/`DartViewerAnim`/`DartViewerLayer`/`DartComicsDocument`
are gone. `dart_comics_viewer_surface.dart` calls `KeyframeInterpolator.translateAt`/`.scaleAt`/
`.rotateAt`/`.alphaAt` (`:73-76`) directly on `layer.editorLayer.anims` — no second interpolation
implementation. See "Relationship to sibling flows" below.

**Also found and fixed while re-verifying (2026-08-08, not part of either flow's original scope)**:
`flutter_comics_viewer/pubspec.yaml`'s `flutter_comics` dependency had been corrupted — nested inside
the `flutter:` SDK-dependency block with a stray `^0.1.0+2` version constraint instead of its own
top-level `path: ../../flutter_comics` entry (which `pubspec.lock` still correctly recorded). `flutter
pub get` failed outright ("A dependency may only have one source"). Fixed by restoring the `path:`
form; `flutter pub get`/`analyze`/`test` all clean afterward (15/15 passing) across all three affected
packages.

## Relationship to sibling/prior flows (must be disclosed, not silently duplicated)

- **`flows/sdd-flutter-comics`** — **IMPLEMENTATION COMPLETE (2026-08-08)**. `libs/flutter_comics`
  exists for real: `ComicsDoc`/`EditorLayer`/`Anim`/`LayerMask`/`TextRegion` (the full schema,
  including `.puzzle`), `KeyframeInterpolator` (moved verbatim), the portable `.lottie` import/export
  code, and `ComicsArchiveReader` — 87/87 tests passing. `flutter_comics_viewer` consumes it directly
  — 15/15 tests passing (re-verified). **This flow's blocker is resolved**: this flow's remaining real
  work (sound) builds on the current, real shared types. The one deferred item from that flow (Task
  5.5, manual real-device verification) doesn't block this flow.
- **`flows/comics-viewer/sdd-flutter-comics-viewer/`** (prior, stale, superseded flow, drafted
  2026-07-19): see its own `_status.md` for the disclosed superseding note. Not relevant to this
  revision beyond that.
- **`flows/comics-viewer/sdd-comics-viewer/`** (active, `_status.md` last touched 2026-08-05 "by
  Codex"): the real origin of `DartComicsViewerBackend`/`DartComicsViewerSurface`/
  `WindowsComicsViewerBackend`. This flow's sound work modifies files that flow owns — coordination
  still needed (see Constraints), still an unactioned real item per `flows/sdd-flutter-comics`'s own
  Blockers.

## Problem Statement

`.comics` viewing today requires native Android or iOS code (or, on Windows, embedding the WPF
editor's own render surface). There is no supported way to view a `.comics` file on macOS, Linux, or
in a browser through a *complete* renderer — `flutter_comics_viewer`'s existing Dart backend for those
platforms is real, already schema-complete (per `flows/sdd-flutter-comics`), and already faithful to
the current v2026 reference apps' actual behavior (fixed-width scaling, cubic-ease-out interpolation —
both confirmed, not assumed) — but it's silent: no sound plays, even though every real `.comics` file
with `SoundAnim`s expects it to. macOS support is the immediate priority.

## User Stories

**As a** Mac user
**I want** to open and read a `.comics` file with sound, matching the mobile reading experience
**So that** I'm not limited to Android/iOS to hear this content, not just see it.

**As** Anton, validating fidelity
**I want** the sound-gating logic traced to a specific line in the current `comics-viewer-ios`
reference (confirmed identical to the historical Swift v2012 source), not reimplemented from general
knowledge
**So that** the Dart port is provably faithful to what the app actually does today, not a plausible
guess.

## Acceptance Criteria

### Must Have

1. **Given** a real `.comics` file with a one-shot sound animation (`SoundAnim.start == end`), **when**
   the reader scrolls downward past that scroll position for the first time, **then** the sound plays
   once (no loop) — and does NOT replay if the reader scrolls back up past the same position and down
   again a second time within the same session (matches `previousContentOffset`-gated, not
   re-triggerable, per `ImageScrollView.swift:284-293`).
2. **Given** a real `.comics` file with a range/background sound animation (`start < end`), **when**
   the scroll position enters `[start, end]`, **then** the sound starts looping; **when** it leaves
   that range, **then** the sound stops — re-entering the range restarts it (matches
   `ImageScrollView.swift:296-311`'s `isPlaying`-flag-gated start/stop, `loop: animation.start !=
   animation.end`).
3. **Given** the viewer's mute/sound-enabled state, **when** `setSoundEnabled`/`setMuted` are called
   (already-existing `ComicsViewerBackend` interface methods, currently no-ops), **then** they actually
   gate playback — matching Swift's global `Settings.shared.soundOff` check gating the entire
   `playSoundsByOffset` call.
4. **Given** `flows/sdd-flutter-comics`'s delivered shared model/reader/interpolator, **when** this
   flow's sound work is built, **then** it's built directly against those real types — already
   satisfied/inherited, verified by keeping the 15/15 `flutter_comics_viewer` suite green throughout,
   not re-done here.
5. **Given** the cubic-ease-out interpolation and fixed-width scaling already confirmed correct,
   **when** this flow's Plan executes, **then** both are preserved exactly — no "improvement" away from
   their confirmed-faithful state.
6. **Given** a real dataset `.comics` file with sound, **when** opened on macOS before and after this
   flow, **then** sound audibly plays/stops correctly in the "after" state — acceptance is a real run
   (or, at minimum, an automated test asserting the real playback-triggering calls fire at the right
   scroll positions), not just a code review, per the `sdd-comics-viewer` Phase 4 lesson that "written
   but never run" isn't sufficient evidence.

### Should Have

- Linux and Web get the same sound fix "for free" where they share `DartComicsViewerBackend` with
  macOS (they currently do) — not a separate must-have since Anton's stated priority is macOS
  specifically, and Web's audio APIs/autoplay restrictions may need their own handling not required on
  macOS/Linux — flagged, not solved here.

### Won't Have (This Iteration)

- **Pinch-zoom and zoom-level tile LOD** — confirmed NOT a real `.comics` feature on any reference
  platform, current (`comics-viewer-ios`/`-android`) or historical (`legacy/mahabharata-mobile-*-v2012`)
  — see "Codebase Analysis" above. Building this would be a genuine new enhancement beyond what any
  reference app has ever done for `.comics`, not a port — explicitly out of scope unless Anton asks for
  it as new functionality in a future flow.
- **Popup-image handling** — same standard: the `popup` field is parsed but never acted on by either
  current reference renderer's interaction code. Not a real gap.
- Windows: already has a separate, working approach (`WindowsComicsViewerBackend`) — out of scope.
- Android/iOS: unaffected, already have real native implementations.
- Any change to `.comics` format/schema itself — that's `flows/tdd-dot-comics-format`'s domain.
- **Modifying native `comics-viewer-ios`/`comics-viewer-android` source** — per Anton's explicit
  "Нативную часть не трогай" — these are read-only reference for this flow, not files to edit.
- A from-scratch rewrite of `DartComicsViewerBackend`/`Surface` — this flow extends existing real code.

## Constraints

- **Source of truth, corrected 2026-08-08 per Anton's explicit redirect**: the CURRENT, actively-shipped
  `libs/comics_viewer/comics-viewer-ios` (primary, macOS priority) and `libs/comics_viewer/
  comics-viewer-android` (secondary) — i.e. v2026 behavior — not `legacy/mahabharata-mobile-*-v2012`.
  The legacy v2012 sources remain useful supporting/historical evidence (and, for every point checked
  so far, agree exactly with the current libraries), but are no longer the compatibility target in
  their own right, and no v2012-specific behavior needs preserving if it differs from v2026.
- **Native code is read-only reference, not editable**: per Anton's explicit instruction, this flow
  must not modify `libs/comics_viewer/comics-viewer-ios`/`comics-viewer-android` — only read them to
  ground the Dart port's behavior.
- **Must build on existing code, not replace it wholesale**: `DartComicsViewerBackend`/
  `DartComicsViewerSurface` already exist, already work, and their core interpolation/scaling math is
  already confirmed faithful — this flow's job is adding real sound playback, not a parallel rewrite.
- **Cross-flow coordination**: changes land inside `libs/comics_viewer/flutter_comics_viewer`, which
  `flows/comics-viewer/sdd-comics-viewer` also actively owns — that flow's `_status.md` should get a
  cross-reference once this flow's Plan is approved (a real, still-unactioned item carried over from
  `flows/sdd-flutter-comics`'s own Blockers too).
- **`legacy/mahabharata-mobile-swift-v2012` includes a large vendored Lottie-iOS pod** — investigation
  must stay scoped to the real app paths, not Lottie internals (unchanged from v0.1/v0.2).

## Open Questions

- [ ] **Sound backend choice**: platform channel (native `AVAudioPlayer`-equivalent via macOS Swift
      plugin — `libs/comics_viewer/flutter_comics_viewer/macos/flutter_comics_viewer/Sources/.../
      ViewerPlugin.swift` already exists as a registration point) vs. a pure-Dart audio package
      (`audioplayers`/`just_audio`). Not decided — real tradeoff between platform-native fidelity and
      staying dependency-light/portable uniformly across macOS+Linux+Web, which all share
      `DartComicsViewerBackend`. Needs Anton's input at Specifications time, or a recommendation there
      grounded in what's actually available/maintained.
- [x] ~~Tile-LOD/pinch-zoom scope~~ — **RESOLVED (2026-08-08)**: not a real feature, dropped. See
      "Codebase Analysis."
- [x] ~~Popup-image behavior~~ — **RESOLVED (2026-08-08)**: not a real feature (parsed but never acted
      on by either current reference renderer), dropped.
- [x] ~~Java v2012 diff pass~~ / ~~`comics-viewer-android`/`comics-viewer-ios` divergence check~~ —
      **SUPERSEDED (2026-08-08)** by Anton's "match v2026" redirect: the mandate is now to match the
      current reference libraries directly, not to resolve whether they diverged from 2012 — moot for
      this flow's purposes. `comics-viewer-android`'s exact `.comics`-mode `zoomEnabled` call site
      remains unlocated, but is now irrelevant since zoom is out of scope entirely.
- [x] ~~`libs/flutter_comics` interpolation-code placement~~ — **RESOLVED by `sdd-flutter-comics`
      directly (2026-08-08)**: `KeyframeInterpolator` lives in `libs/flutter_comics`. This flow's sound
      work has no interpolation-placement question of its own (sound is a gate/trigger, not an
      interpolated value).

## References

- `libs/comics_viewer/comics-viewer-ios/Mahabharata/Views/Tiles/ImageScrollView.swift` (current,
  primary reference — confirmed `diff`-identical to `legacy/mahabharata-mobile-swift-v2012`'s copy):
  `:113-119` (fixed zoomScale, the corrected finding), `:271-346` (`playSoundsByOffset`, the real
  sound-gating logic this flow ports)
- `legacy/mahabharata-mobile-swift-v2012/Mahabharata/Model/DataClasses/Visual/Animations/Anim.swift`
  (confirmed cubic-ease-out formula, historical corroboration), `Views/Tiles/TileImageView.swift`
  (source of the corrected tile-LOD finding — the class's own comments explain the puzzle-only zoom
  capability)
- `libs/comics_viewer/comics-viewer-android` — secondary current reference; `LayersView.java`/
  `TileImageView.java`/`ZoomFrameLayout.java` (`zoomEnabled` architecture, corroborates the Swift
  finding structurally); `SoundManager.java`/`SoundAnim.java` (Android sound equivalent, not yet read
  in the same depth as Swift's — real work for Specifications if Android parity is wanted)
- `libs/comics_viewer/flutter_comics_viewer/lib/src/dart_comics_viewer_backend.dart`,
  `dart_comics_viewer_surface.dart`, `comics_viewer.dart` — the existing real implementation this flow
  extends
- `flows/sdd-flutter-comics/01-requirements.md`, `02-specifications.md`, `04-implementation-log.md`
  (all APPROVED/complete) — the shared-library dependency this flow's work now builds on directly
- `flows/comics-viewer/sdd-flutter-comics-viewer/` — superseded prior flow
- `flows/comics-viewer/sdd-comics-viewer/` — active flow owning files this flow will also modify

---

## Approval

- [ ] Reviewed by: Anton Dodonov
- [ ] Approved on:
- [ ] Notes: v0.1's premise was approved, then v0.2 revised for the resolved dependency; **this v0.3
      is a substantive correction** (removes 2 of the original Must-Have criteria on new evidence) and
      needs fresh approval, not an extension of the earlier approval.
