# Status: sdd-flutter-comics-viewer-dart

## Current Phase

IMPLEMENTATION — complete (7/8 tasks; Task 4.1 manual verification deferred). DOCUMENTATION phase not
started.

## Phase Status

APPROVED

## Last Updated

2026-08-08 by Claude

## Blockers

- None blocking. Task 4.1 (manual audible verification on a real device) remains — deferred, not
  blocking, matching `flows/sdd-flutter-comics`'s own Task 5.5 precedent exactly; automated coverage
  (4 real backend-level sound-wiring tests) already confirms the underlying logic works.

## Progress

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
      confirmed the redirect: match v2026 (current reference libs), not v2012; don't touch native
      code. Same pass found `popup` is parsed but never acted on by either current reference
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

## Context Notes

- **This flow is NOT a green-field port.** A real, functioning pure-Dart `.comics` renderer for
  macOS/Linux/Web already exists inside `libs/comics_viewer/flutter_comics_viewer` (built by the
  active `flows/comics-viewer/sdd-comics-viewer` flow), and — after `flows/sdd-flutter-comics` —
  already consumes the correct, schema-complete shared model. This flow's entire remaining real scope
  is **adding sound playback** (background-loop + one-shot, scroll-gated, matching
  `comics-viewer-ios`'s `playSoundsByOffset`) — everything else originally suspected (tile-LOD,
  gestures, popups) was corrected away with direct evidence, not assumed away.
- **Source-of-truth pivot**: primary reference is now the CURRENT `libs/comics_viewer/comics-viewer-ios`
  (confirmed `diff`-identical to `legacy/mahabharata-mobile-swift-v2012` on every point checked so
  far), not the legacy v2012 app directly — per Anton's explicit redirect. Native code
  (`comics-viewer-ios`/`-android`) is read-only reference, not to be modified by this flow.
- **Supersedes** `flows/comics-viewer/sdd-flutter-comics-viewer/` (superseding note in that flow's own
  `_status.md`).
- Modifies files also owned by the active `flows/comics-viewer/sdd-comics-viewer` flow — cross-flow
  coordination note added there (Task 4.2), which also incidentally resolved that flow's own stale
  Blocker about a compile error the sibling flow had already fixed without disclosing back.

## Fork History

N/A — new flow. Supersedes the rendering-implementation half of
`flows/comics-viewer/sdd-flutter-comics-viewer`'s original scope.

## Next Actions

1. Task 4.1: manual verification on a real device/simulator — open a real dataset `.comics` file with
   sound in the macOS-targeted `flutter_comics_viewer` example app (needs the example wired to load a
   real file first, which it isn't today) and confirm audible playback/mute behavior. The only undone
   item.
2. Android sound parity (`comics-viewer-android`'s `SoundManager.java`/`SoundAnim.java`) remains a
   real, non-blocking Open Design Question, unchanged since Specifications.
3. This flow's own DOCUMENTATION phase (client-facing readme) hasn't been requested yet.
