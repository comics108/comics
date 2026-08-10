# Status: sdd-flutter-comics-viewer-dart

## Current Phase

IMPLEMENTATION COMPLETE — the canonical document-scroll coordinate, camera-path/z-depth rendering,
v2012 compatibility, dual real-example behavior, and cross-platform automated verification are
implemented. The v0.3 sound baseline remains complete; only its separate human audible-perception
sign-off remains deferred.

## Phase Status

v0.3 BASELINE IMPLEMENTED; v0.5/v1.1 IMPLEMENTATION COMPLETE

## Last Updated

2026-08-10 by Codex

## Blockers

- The prior sound scope has no blocking engineering issue. Only a human listener's audible
  confirmation remains outside automation.

## Progress

- [x] Camera/depth code and both supplied archives inspected (2026-08-09)
- [x] Verified `example/assets/sample_v2012.comics` is byte-identical to the authoritative
      `samples/sample_v2012.comics` and uses the classic v2012-compatible format (2026-08-09)
- [x] Verified v2026 fixture has 19 camera points and 505 nonzero depth layers (2026-08-09)
- [x] v0.5 v2012 compatibility + camera/depth + dual-example Requirements drafted (2026-08-09)
- [x] v0.5 Requirements approved (2026-08-10)
- [x] v0.5 Specifications drafted (2026-08-10)
- [x] Existing viewer regression gate attempted after the shared change (2026-08-10): Dart sources
      remain compatible and 27/27 package tests pass, but package analysis reports the known stale
      `sample.comics` asset entry; the v0.2 example task owns that correction after approval.
- [x] v0.5 Specifications approved (2026-08-10)
- [x] v1.1 Plan drafted (2026-08-10)
- [x] v1.1 Plan approved (2026-08-10)
- [x] v0.5 implementation started (2026-08-10)
- [x] Phases 5-6 canonical coordinate and camera/depth rendering complete (2026-08-10)
- [x] Phase 7 dual-fixture example and macOS integration complete (2026-08-10)
- [x] Phase 8 verification complete (2026-08-10): package 33/33, example 3/3, analyzers clean,
      Web build passed, macOS dual-fixture integration 1/1.

- [x] Codebase analysis done (2026-08-08) — confirmed real, working scaffolding already exists;
      confirmed cubic-ease-out formula match; initially catalogued 4 candidate gaps (sound, tile-LOD,
      gestures, popup) — 3 of the 4 later corrected away, see below.
- [x] Re-verified (2026-08-08) after `flows/sdd-flutter-comics` reached Implementation complete —
      duplicate-model gap resolved (`RenderedLayer` + `ComicsArchiveReader` + shared
      `KeyframeInterpolator`). **Found and fixed a real regression**: `flutter_comics_viewer/
      pubspec.yaml`'s `flutter_comics` dependency was corrupted (malformed YAML nesting), breaking
      `flutter pub get`. Fixed; all three packages clean (15/15 in `flutter_comics_viewer`).
- [x] **Major correction (2026-08-08)**: while grounding the tile-LOD/gesture Acceptance Criteria in
      the actual source before writing Specifications, found `ImageScrollView.swift:113-119`
      ("`For comics mode zoomScale is fixed`" — `minimumZoomScale == maximumZoomScale`), confirmed
      `diff`-identical in the CURRENT, actively-shipped `libs/comics_viewer/comics-viewer-ios`, not
      just the 2012 archive. Pinch-zoom/tile-LOD have never been real `.comics` features on any
      reference platform — they belong to puzzle mode, a different content type sharing the same
      `TileImageView`/`ZoomFrameLayout` classes generically. Flagged to Anton via AskUserQuestion
      before proceeding (this reversed 2 of the just-approved v0.2 Must-Have criteria). Anton
      confirmed the redirect: match current v2026 UI/runtime behavior and don't touch native code.
      The later v0.5 correction restores mandatory v2012 **file-format** compatibility without
      restoring obsolete v2012-only UI scope. Same pass found `popup` is parsed but never acted on by either current reference
      renderer's interaction code either — dropped on the same evidence standard. Real remaining
      scope: **sound playback only**. See `01-requirements.md` v0.3 for full detail.
- [x] Requirements drafted (2026-08-08) — v0.1, revised v0.2 (dependency resolved), revised v0.3
      (major correction above)
- [x] Requirements approved (2026-08-08) — by Anton Dodonov ("reqs are approved" on v0.2's premise,
      then the v0.3 correction was directly authorized via his own redirect answer resolving the
      AskUserQuestion — treated as approval of the corrected scope, not re-asked a third time)
- [x] Specifications drafted (2026-08-08) — v0.1, see `02-specifications.md`. Central finding: a
      THIRD independent implementation of the exact same sound-gating logic already exists
      (`apps/comics-editor`'s `SoundGating`, ported from the C# WPF editor's `SoundAnim.FindCurrent`)
      — agrees byte-for-byte with the Swift-derived semantics in Requirements. It's already pure/
      portable (operates only on shared `List<Anim>`) and moves into `libs/flutter_comics`, same
      pattern as `KeyframeInterpolator`. Resolved the sound-backend Open Question: `audioplayers`
      (already pinned `^6.8.1` in `apps/comics-editor`, confirmed to support `BytesSource` for the
      viewer's in-memory-archive case, vs. `DeviceFileSource` for the editor's disk-extracted case).
- [x] Specifications approved (2026-08-08) — by Anton Dodonov ("specs approved")
- [x] Plan drafted (2026-08-08) — v1.0, see `03-plan.md`: 4 phases, 8 tasks. Phase 1 moves
      `SoundGating`/`SoundAction` into `libs/flutter_comics`; Phase 2 builds `flutter_comics_viewer`'s
      new `BytesSource`-based `SoundPlaybackTrack` (independent of Phase 1, can interleave); Phase 3
      wires both together into `DartComicsViewerBackend`; Phase 4 is manual verification + the
      still-outstanding `sdd-comics-viewer` cross-reference. Same standing execution constraints as
      the sibling flow's Plan (filesystem-only moves, no git commands, byte-identical content).
- [x] Plan approved (2026-08-08) — by Anton Dodonov
- [x] Implementation started (2026-08-08) — Phase 1, Task 1.1
- [x] Implementation complete (2026-08-08) — 7/8 tasks; Task 4.1 (manual device verification) deferred,
      disclosed, not blocking. `libs/flutter_comics` gained `sound_gating.dart` (moved from
      `apps/comics-editor`, 97/97 tests); `flutter_comics_viewer` gained real sound playback
      (`SoundPlaybackTrack`, `_evaluateSounds`, real `setSoundEnabled`/`setMuted`/`dispose`, 26/26
      tests). See `04-implementation-log.md` for full detail, including 2 real regressions found and
      fixed along the way (a corrupted `flutter_comics_viewer` pubspec dependency, and a missing
      `dependency_overrides` on `apps/comics-editor` after `flutter_comics` was genuinely published to
      pub.dev mid-flow) and the real `AudioPlayer` timeout mechanism traced and fixed
      (`SoundPlaybackTrack.callTimeout`).
- [x] macOS example/runtime verification continued (2026-08-09) — at verification time the example
      loaded the then-bundled 18 MB `sample.comics` (177 layers, 2 MP3 sounds), rendered through
      `DartComicsViewerSurface`, and provides status/scroll/play/mute controls. Added 2 example widget
      tests and 1 real macOS device-target integration test. `flutter build macos --debug`, integration
      test, and `flutter run -d macos` all succeeded. The run exposed and fixed delayed-source
      notification-during-build and Darwin BytesSource cache/MIME failures. Package suite is now
      27/27; example widget suite 2/2; macOS integration 1/1; analysis clean. Anton has since replaced
      that asset with `sample_v2012.comics` and `sample_v2026.comics`; adapting the example/tests is
      explicitly part of the new v0.5 scope and has not been implemented before its SDD gates.

## Context Notes

- **This flow is NOT a green-field port.** A real, functioning pure-Dart `.comics` renderer for
  macOS/Linux/Web already exists inside `libs/comics_viewer/flutter_comics_viewer` (built by the
  active `flows/comics-viewer/sdd-comics-viewer` flow), and — after `flows/sdd-flutter-comics` —
  already consumes the correct, schema-complete shared model. The sound baseline is implemented;
  the approved v0.5 continuation adds v2012 fixture compatibility verification, camera/depth
  rendering, a corrected shared scroll coordinate, and two-example switching. Earlier suspected
  tile-LOD, gestures, and popup scope remains excluded on direct reference-code evidence.
- **Source-of-truth refinement**: current `comics-viewer-ios`/`-android` remains the UI/runtime
  reference and native code stays read-only. `tdd-dot-comics-format` plus the real
  `sample_v2012.comics` is simultaneously authoritative for mandatory v2012 file-format,
  interpolation, and sound compatibility; v2026 fields are additive defaults, not a separate format.
- **Supersedes** `flows/comics-viewer/sdd-flutter-comics-viewer/` (superseding note in that flow's own
  `_status.md`).
- Modifies files also owned by the active `flows/comics-viewer/sdd-comics-viewer` flow — cross-flow
  coordination note added there (Task 4.2), which also incidentally resolved that flow's own stale
  Blocker about a compile error the sibling flow had already fixed without disclosing back.

## Fork History

N/A — new flow. Supersedes the rendering-implementation half of
`flows/comics-viewer/sdd-flutter-comics-viewer`'s original scope.

## Next Actions

1. Human auditory sign-off only: listen to the already-working macOS example and confirm subjective
   audible start/stop/mute behavior. The example wiring, real archive rendering, platform audio-source
   preparation, scrolling, and automated macOS runtime checks are complete.
2. Android sound parity (`comics-viewer-android`'s `SoundManager.java`/`SoundAnim.java`) remains a
   real, non-blocking Open Design Question, unchanged since Specifications.
3. This flow's own DOCUMENTATION phase (client-facing readme) hasn't been requested yet.
