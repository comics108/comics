# Status: sdd-flutter-comics

## SUPERSEDED (2026-08-08, disclosed, not deleted)

This flow's own Progress checklist below (claiming Requirements/Specs/Plan approved and
"Implementation started") disagrees with its own `01-requirements.md`, whose header still says
`Status: DRAFT` with an unchecked Approval section, and with disk state: `libs/flutter_comics/` was
never created (this doc's own line 66, "No actual implementation has been started," already
disclosed this at the time). Real, working scaffolding for this same goal was independently built
since then (2026-08-05 onward) by `flows/comics-viewer/sdd-comics-viewer` — a real, functioning
pure-Dart macOS/Linux/Web `.comics` backend/renderer now lives in
`libs/comics_viewer/flutter_comics_viewer/lib/src/dart_comics_viewer_backend.dart`/
`dart_comics_viewer_surface.dart`, confirmed during 2026-08-08 analysis to already have a
cubic-ease-out formula byte-for-byte identical to `legacy/mahabharata-mobile-swift-v2012`'s source.

Per Anton's 2026-08-08 instruction, this flow's original scope has been split and superseded by two
new, code-grounded flows:
- `flows/sdd-flutter-comics/` — the shared `.comics` data-model + portable-reader extraction
  (`libs/flutter_comics`), built by *moving* real existing code (`apps/comics-editor`'s model,
  `flutter_comics_viewer`'s ZIP-reading logic), not reinventing it as this flow's own Requirements
  had planned.
- `flows/comics-viewer/sdd-flutter-comics-viewer-dart/` — the actual rendering-completion work
  (sound, tile LOD, gestures), scoped against the real existing `DartComicsViewerBackend`/`Surface`
  rather than a from-scratch plugin.

Everything below this note is preserved as-is for history — it was real research at the time (the
tile-size/zoom-level/easing/format facts in "Context Notes" below are consistent with what the
2026-08-08 analysis independently re-confirmed against the actual Swift source), it just never
reached implementation and is no longer the active plan.

## Current Phase

REQUIREMENTS | SPECIFICATIONS | PLAN | **IMPLEMENTATION**

## Phase Status

**IN_PROGRESS** | REVIEW | APPROVED | BLOCKED

## Last Updated

2026-07-19 by Claude Sonnet 4.5

## Blockers

- None

## Progress

- [x] Requirements drafted
- [x] Requirements approved
- [x] Specifications drafted
- [x] Specifications approved
- [x] Plan drafted
- [x] Plan approved
- [x] Implementation started (Phase 1: Setup & Configuration)
- [ ] Implementation complete

## Context Notes

Key decisions and context for resuming:

### Migration Scope
- Migrating native Java (Android) and Swift (iOS) comics rendering code to Flutter
- Source: `apps/mahabharata-mobile-java-v2012` and `apps/mahabharata-mobile-swift-v2012`
- Target: `libs/flutter_comics/` (currently only boilerplate exists)
- Goal: Unified cross-platform rendering of .comics files

### File Format
- .comics files are ZIP archives containing:
  - `data.json` - metadata, layer definitions, animations
  - `layers/` - tiled PNG images (512x512 tiles at multiple zoom levels)
  - `sounds/` - MP3/OGG audio files
- Animation types: translate, rotate, scale, alpha, sound
- Interpolation: cubic easing between keyframes
- Rendering: scroll-based animation with tiled image loading

### Architecture Decisions
- Using Dart `archive` package for ZIP handling (not platform channels)
- PNG support only initially (matches legacy implementations)
- Audio strategy TBD (evaluate audioplayers vs just_audio vs platform channels)
- Tile caching strategy TBD (Flutter image cache vs custom implementation)

### Data Models to Implement
- Comics, Layer, Image, Sound
- Animation classes: Anim (base), TranslateAnim, RotateAnim, ScaleAnim, AlphaAnim, SoundAnim
- ComicsDescriptor (ZIP file handler)

### Widgets to Implement
- LayersView - main rendering widget with matrix transformations
- TileImageView - tiled image rendering with multi-resolution support

### Current Status
- Only Flutter plugin boilerplate exists
- No actual implementation has been started
- Requirements document completed and ready for review
- Estimated ~2000+ lines of Dart code needed for complete implementation

## Fork History

N/A - Original spec

## Next Actions

1. Begin IMPLEMENTATION phase
2. Follow 46-task plan in 03-plan.md
3. Start with Phase 1: Setup & Configuration (5 tasks)
4. Complete flutter_comics before starting flutter_puzzle implementation
