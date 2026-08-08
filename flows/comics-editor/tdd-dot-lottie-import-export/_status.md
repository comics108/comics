# Status: tdd-dot-lottie-import-export

## Current Phase

IMPLEMENTATION — complete, all 7 phases done. DOCUMENTATION phase (client-facing README) not
started; that's the only remaining phase gate in this flow's own `tdd.md` lifecycle.

## Phase Status

Requirements (v0.3), Tests (v1.1), and Specifications (v1.3) are all APPROVED (2026-08-08 — Anton's
"specs approved" for `03-specifications.md` also confirmed the two upstream documents it derives
from, per the note left in each). `04-plan.md` v1.0 drafted: 7 phases, 24 tasks. Verified before
drafting: **nothing implemented yet** — zero `lottie_*.dart` files, no `groupId`/`textRegion`/
`preferredViewportWidth`/`Height` in `models.dart` (checked directly, not assumed). Sequenced so
`.comics` schema prerequisites (Phase 1: `groupId`, `textRegion`, `preferredViewportWidth`/`Height`)
land first, then pure Lottie JSON I/O (Phase 2, independently testable), then the mode-aware import
pipeline (Phases 3-4) and export (Phase 5), then UI (Phase 6), then real-fixture round-trip
integration tests (Phase 7) last. Reuses `EditorLayer.id`/`.parentId`, `ComicsDoc.scrollType`/
`.preferredOrientation`, `Anim.basis`/`.loop` directly — all already shipped by
`tdd-dot-comics-format`'s own Plan.

Context for how Specifications got here: v1.1 (real-data investigation found Lottie `parent` field
used in 5/7 chapters, up to 64% of layers in `THE BROKEN TUSK`) → v1.2 (superseding update — maps
`parent` onto `Layer.ParentId` instead of baking-and-discarding) → **v1.3 (2026-08-08) — Export/
Import Modes**: Full Canvas vs. Playback Viewport, grounded in two real fixtures checked byte-level
(`samples/sample_v2012.comics_unzip`, `samples/sample_playback_viewport.lottie_unzip` — confirmed a
genuinely different file from `samples/sample.lottie` by content hash). Retroactively validates
`tdd-dot-comics-format`'s `Anim.basis` feature as solving a real, already-produced-content need.
3 of 4 new Open Questions this addition raised were resolved same-day with real computation (scene-
boundary convention, scroll-speed auto-derivation confirmed to 149.49/150.00 px/sec on the real
sample, mode-selection UI); G5's scroll/time classification heuristic ships as "everything
scroll-basis" for now, carried into Plan as Task 4.2's explicit scope. One correction applied
same-day: G3's Full Canvas round-trip direction was wrong in the initial draft
(`.comics → .lottie → .comics`) — corrected to `.lottie → .comics → .lottie`, matching G6.

## Last Updated

2026-08-08 by Claude

## Blockers

None for Implementation — all 7 phases are done. Still carrying forward, unaddressed by any task
(shipped as their stated defaults, not yet Anton-confirmed as final): G5's scroll/time
classification heuristic (ships as "everything scroll-basis"), D3's raster-mask export gap (ships
as skip-with-limitation), the 2 deferred Text Region sub-questions, whether the mask exclusion gets
re-confirmed (masks stay out of scope), deeply-parented layer chain review-screen visualization
(ships shallow-case-first — real content checked has no deep parenting).
Next gate: DOCUMENTATION phase (client-facing README) hasn't been started.

## Progress

- [x] Requirements drafted (2026-08-07) — v0.1
- [x] Requirements approved (2026-08-07) — v0.2, by Anton Dodonov, 2 sub-questions deferred
- [x] Requirements addition drafted (2026-08-08) — v0.3, Export/Import Modes
- [x] Requirements addition approved (2026-08-08) — via `03-specifications.md`'s approval; 2 of 3
      new Open Questions resolved same-day with real computation, 1 carried into Plan
- [x] Tests drafted (2026-08-07) — v1.0, 6 categories (A-F), ~15 cases, cases-first per TDD
      discipline
- [x] Tests approved (2026-08-07) — by Anton Dodonov, 3 Open Design Questions carried forward
- [x] Tests addition drafted (2026-08-08) — v1.1, Category G (7 cases: G1-G7)
- [x] Tests addition approved (2026-08-08) — via `03-specifications.md`'s approval
- [x] Specifications drafted (2026-08-07) — v1.0, full traceability matrix included
- [x] Specifications corrected (2026-08-07) — v1.1, `parent`-chain generalization + real mask/null/
      solid-layer findings disclosed, 3 new Open Design Questions
- [x] Specifications superseded (2026-08-07) — v1.2, maps onto the new `Layer.ParentId`/`Layer.Id`
      mechanism directly instead of baking-and-discarding; one Open Design Question resolved
- [x] Specifications extended (2026-08-08) — v1.3, `ExportImportMode` enum threaded through
      `ImportPreview`/`buildLottieExport`, mode-branched Data Flow
- [x] Specifications approved (2026-08-08) — by Anton Dodonov ("specs approved"); 6 Open Design
      Questions carried forward to Plan, none blocking
- [x] Plan drafted (2026-08-08) — v1.0, see `04-plan.md`: 7 phases, 24 tasks
- [x] Plan approved (2026-08-08) — by Anton Dodonov
- [x] Implementation started (2026-08-08) — Phase 1 (schema prerequisites) done: `EditorLayer
      .groupId`/`.textRegion` (+ `TextRegion` class), `ComicsDoc.preferredViewportWidth`/`Height`
      (default 720×1600, `tdd-dot-comics-format`'s field, first implemented here), all with JSON
      round-trip. Also fixed an unrelated pre-existing failure (`test/app_version_test.dart`, stale
      hand-maintained version-fallback constant after an external `pubspec.yaml` bump).
- [x] Phase 2 done (2026-08-08) — pure Lottie JSON model + parse/write (`lib/src/bridge
      /lottie_mapping.dart`, new): `LottieDocument`/`LottieLayer`/`LottieAsset`/`LottieMask`/
      `LottieTransform`/`LottieProperty`/`LottieKeyframe`, `parseLottieDocument`/
      `writeLottieDocument`. Re-verified `LottieMask`'s simplified real-data shape (all 6 real
      masks in `THE CHASE.json` still confirmed static 4-vertex rectangles, `mode:"a"`, no curves)
      before coding it — not assumed from memory. Uses the same `package:archive` zip pattern
      already established in `dart_io_core.dart`. Tested against real fixtures directly:
      `samples/sample.lottie` (real zip, end-to-end), `ASHES.json`/`THE CHASE.json` (real JSON,
      direct parse). New file: `test/lottie_mapping_test.dart` (10 cases).
- [x] Phase 3 done (2026-08-08) — `ExportImportMode`/`detectMode`, `LayerPreview`/
      `ImportPreview.build` for both modes (`lib/src/ui/lottie/lottie_import.dart`, new). Caught
      and fixed a real bug via testing: `LottieLayer.unsupportedReason` was only ever correctly
      computed by the JSON parser, silently defaulting to "supported" for any hand-built
      `LottieLayer` — fixed by moving the classification into the constructor itself. Added
      `LottieAsset.fileFound` (a Phase 2 refinement) after discovering both real samples embed
      every image as a base64 data URI, never an external file reference. New test file
      `test/lottie_import_test.dart` (12 cases), including real-fixture validation (`ASHES.json`:
      2 real scenes detected, `scrollSpeed` lands at the expected computed average). Full suite:
      453/453 passing, `flutter analyze` clean.
- [x] Phase 4 done (2026-08-08) — `commitImport` (both modes) + `EasingChoice`/`TextRegion` import,
      all in `lottie_import.dart`. **Found a real architectural gap while implementing this**:
      `commitImport`'s own Specifications signature has no access to a document's real
      `CoreDocument.tempFolder`, so it cannot call `tile_writer.dart`'s `writeTiles` — every
      imported layer currently gets a placeholder image, not real pixels; real extraction is a new,
      tracked, disclosed task deferred to Phase 6 (the controller/UI level, which does have
      tempFolder access), not silently skipped. Caught and fixed 2 real bugs via testing: (1) an
      early version emitted no-op Rotate/Scale/Alpha Anims at every layer's neutral default,
      cluttering output vs. real hand-authored content; (2) a unit-conversion bug (Lottie's
      0-100/percent scale vs. `.comics`'s 0-1/unit-fraction convention). New test file
      `test/lottie_commit_import_test.dart` (8 cases). Full suite: 460/460 passing, `flutter
      analyze` clean.
- [x] Phase 5 done (2026-08-08) — `buildLottieExport`, both modes (`lib/src/ui/lottie
      /lottie_export.dart`, new): Full Canvas is the direct inverse of Task 4.1's baking; Playback
      Viewport partitions the canvas into `preferredViewportHeight` bands and synthesizes a
      `-scrollPixel` sweep per scene, chosen so members need zero position adjustment (matches
      `.comics`'s own real render formula). `groupId`->shared precomp, `TextRegion`
      polygon->real Lottie mask, raster mask skipped with the disclosed D3 default. **Caught a real
      boundary bug via the export->re-import round-trip test**: Task 3.1's sweep-detection
      threshold (`> document.height`) narrowly failed to recognize this flow's own synthesized
      exactly-1x-height sweep (real content's sweeps are 8-15x height, comfortably clearing it) —
      fixed to `> height/2`, re-verified against real `ASHES.json` to confirm no false positive.
      New test file `test/lottie_export_test.dart` (7 cases, including an export->re-import
      functional round-trip). Full suite: 467/467 passing, `flutter analyze` clean. See
      `05-implementation-log.md` for full detail. Phases 6-7 remain (UI, and the real-zip-level
      fixture round-trip tests specifically).
- [x] Phase 7 done (2026-08-08) — real-fixture, real-zip-level round-trip integration tests
      (`test/lottie_roundtrip_test.dart`: G3 Full Canvas via `sample_v2012.comics_unzip`, G6
      Playback Viewport via `sample_playback_viewport.lottie_unzip`/`ASHES.json`, E1 via
      `samples/sample.lottie`). All 3 failed on first run, for 5 real bugs found and fixed in
      `lottie_export.dart`/`lottie_import.dart` (2-level precomp nesting, sweep double-counting,
      Y-position-based scene banding, a uniform-viewportHeight-per-scene assumption replaced by a
      real-data-derived range using a most-common-boundary heuristic, and `_propertyFromAnims`
      silently dropping every `Anim.start` producing a linear ramp instead of a held-then-eased
      shape) — full detail in `05-implementation-log.md`. Task 5.2 (#69) is now genuinely
      re-verified against real content. Full suite: 470/470 passing (3 skipped, monorepo-only
      fixtures), `flutter analyze` clean. Only Phase 6 (UI) and Task 6.4 (real image-byte
      extraction) remain.
- [x] Phase 6 done (2026-08-08) — UI + real image-byte extraction, the flow's last phase. New
      `lib/src/ui/widgets/lottie_import_dialog.dart` (review screen: mode override, scrollSpeed/
      easing controls, clean/flagged counts, per-layer status list, wrong-mode banner per Test G7;
      plus a separate, much simpler export dialog). New menu entries in `top_bar.dart`. New
      `EditorController` methods (`pickLottieToImport`/`setLottieImportMode`/
      `setLottieScrollSpeed`/`setLottieEasingChoice`/`cancelLottieImport`/`commitLottieImport`/
      `exportLottieWithDialog`) wire `commitImport`/`buildLottieExport` to real file-picker/
      tempFolder access. Task 6.4 (real image-byte extraction) closes the disclosed gap from Phase
      4: `commitLottieImport` decodes each clean layer's base64 `data:` URI source asset and calls
      `writeTiles` for real pixels, when a real `tempFolder` is available (falls back to
      `commitImport`'s own documented placeholder otherwise, e.g. a never-saved "New Document" —
      an existing, pre-established app limitation, not new here). New test file
      `test/lottie_controller_test.dart` (10 cases), including a real end-to-end check that an
      imported layer's tile file actually exists on disk with non-empty pixel bytes. Full suite:
      480/480 passing (3 skipped), `flutter analyze` clean.

**All 7 phases of `04-plan.md` are now complete.** Nothing outstanding in Implementation.

## Context Notes

- **Purpose**: a real feature build (import `.lottie` into `apps/comics-editor`, export `.comics`
  documents as `.lottie`), not a research/consolidation flow like its two siblings
  (`tdd-dot-comics-format`, `tdd-dot-lottie-format`).
- **Scope is deliberately narrow**: editor-only (no mobile viewer changes), no sound/translation
  I/O (those live outside the Lottie JSON entirely in real content), no shape/mask/text Lottie
  support (breaks the whole "simple math" premise the sibling flow established).
- **A self-caught error during drafting**: an early version of this document's Open Questions
  attributed a fabricated answer to Anton on the time-base mapping question. Caught and corrected
  before this was shown as final — that question remains genuinely open, not decided.

## Fork History

N/A — new flow, not forked. Builds directly on `flows/tdd-dot-lottie-format`'s research (cited
throughout `01-requirements.md`), per Anton's explicit request to add real import/export capability
to `apps/comics-editor`.

## Next Actions

Implementation is done (all 7 phases). Two things remain, neither blocking real use of the feature:

1. **Manual smoke test** of the new UI on a real device/desktop build (Task 6.2/6.3's own stated
   verification bar is "Manual" — automated coverage stopped at the controller/pure-logic level,
   per `05-implementation-log.md`'s Phase 6 session notes): pick a real `.lottie` file, confirm the
   review dialog renders legibly, commit, confirm real artwork (not blank layers) shows up on the
   canvas.
2. **DOCUMENTATION phase**: a client-facing `06-readme.md` explaining the feature in plain terms —
   not started yet, per this flow's own `tdd.md` lifecycle. Waiting on Anton to request it.
