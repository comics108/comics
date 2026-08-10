# Status: sdd-flutter-comics

## Current Phase

IMPLEMENTATION COMPLETE — camera path + z-depth Requirements/Specifications and Plan v1.1 are
approved; Phase 6 is implemented and verified. The v0.3 implementation remains complete (14/15
tasks; Task 5.5 deferred).

## Phase Status

Requirements v0.4 APPROVED; Specifications v0.4 APPROVED; Plan v1.1 APPROVED; Phase 6 IMPLEMENTED

## Last Updated

2026-08-10 by Codex

## Blockers

- The v0.3 baseline has no blocker. Task 5.5 (manual verification on a real device/simulator)
  remains deferred, per `04-implementation-log.md`; automated coverage confirms the underlying fix.
- Real, unactioned cross-flow item: add the disclosed cross-reference to `flows/comics-viewer/
  sdd-comics-viewer`'s own `_status.md` (Phase 5 modified `dart_comics_viewer_backend.dart`/
  `_surface.dart`, files that flow owns).
- **New, real consequence found during Implementation, not anticipated at Specifications time**:
  `flutter_comics_viewer` is a genuinely *published* pub.dev package; its new local `path:`
  dependency on `flutter_comics` means it can't be republished until `flutter_comics` is published
  too (or the dependency is swapped to hosted/git at publish time) — `publish_to: 'none'` was added
  with a disclosing comment, but the underlying publishability question is unresolved and belongs to
  whoever owns this package's release process (`sdd-comics-editor-build`/`-publish`'s domain, or a
  new decision for Anton).

## Progress

- [x] v0.4 camera/z-depth Requirements addendum approved (2026-08-09)
- [x] v0.4 camera/z-depth Specifications addendum approved (2026-08-09)
- [x] v1.1 camera/z-depth Plan addendum drafted (2026-08-09)
- [x] v1.1 fixture verification corrected to treat `sample_v2012.comics` as the full mandatory
      classic-format compatibility case per `tdd-dot-comics-format`, not merely an inert camera case
      (2026-08-09)
- [x] v1.1 camera/z-depth Plan addendum approved (2026-08-10)
- [x] Phase 6 camera/depth model, reader, evaluator, editor round-trip, and fixture verification
      implemented (2026-08-10): `libs/flutter_comics` 106/106; `apps/comics-editor` 396/396 with 3
      expected skips; both analyzers clean.

- [x] Codebase analysis done (2026-08-08) — read `apps/comics-editor/lib/src/ui/models.dart` +
      `lib/src/bridge/models_mapping.dart`, `libs/comics_viewer/flutter_comics_viewer/lib/src/
      dart_comics_viewer_backend.dart` + `dart_comics_viewer_surface.dart` + `comics_viewer.dart`,
      cataloged the 4 format-touching test files, read the prior stale `sdd-flutter-comics-viewer`
      flow and the active `sdd-comics-viewer` flow for context. See `01-requirements.md`'s own
      "Codebase Analysis" section for the full findings.
- [x] **Full flow survey done (2026-08-08)** — read EVERY flow under `flows/` (Anton: "Прочитай
      каждый sdd, vdd, tdd флоу"), verified every candidate file's actual `import` statements
      directly rather than assuming (via grep + direct reads, not just flow-doc claims). Found: the
      3 Lottie files + `keyframe_interpolator.dart` are portable and in scope (missed in the original
      analysis because `tdd-dot-lottie-import-export` wasn't cataloged); 2 of the 3 originally-listed
      test-file move candidates actually test logic that stays in `apps/comics-editor` (a real error
      in v0.1, corrected in v0.2); `sdd-flutter-comics-viewer-dart` is a hard, already-drafted
      downstream dependent, not just a related flow. Full results folded into `01-requirements.md`'s
      new Addendum + `02-specifications.md`'s corrected Affected Systems table and new Interaction
      Interface section.
- [x] Requirements drafted (2026-08-08) — v0.1, revised to v0.2 (Lottie scope + survey), then v0.3
      same day (`.puzzle` decided unconditionally; architecture-boundary re-verification with the
      concrete `lottie_export.dart`→`KeyframeInterpolator` dependency as proof)
- [x] Requirements approved (2026-08-08) — by Anton Dodonov ("specs and reqs approved")
- [x] Specifications drafted (2026-08-08) — v0.1, revised to v0.2 (Lottie scope + survey, corrected
      test-file placement, resolved the interpolator-location Open Design Question), then v0.3 same
      day (`.puzzle` DECIDED not just recommended; architecture-boundary verification section added)
- [x] Specifications approved (2026-08-08) — by Anton Dodonov ("specs and reqs approved")
- [x] Plan drafted (2026-08-08) — v1.0, see `03-plan.md`: 5 phases, 15 tasks. Encodes 2 standing
      execution constraints from Anton directly this session into every Move task: filesystem
      relocation only (no `git mv`/any git command — Anton does git by hand) and byte-identical
      content (never reconstructed from memory).
- [x] Plan approved (2026-08-08) — by Anton Dodonov
- [x] Implementation started (2026-08-08) — Phase 1, Task 1.1
- [x] Implementation complete (2026-08-08) — 14/15 tasks; Task 5.5 (manual device verification)
      deferred, disclosed, not blocking. `libs/flutter_comics` created (model + interpolator +
      Lottie import/export + new `ComicsArchiveReader`, 87/87 tests); `apps/comics-editor` migrated
      (403/403 tests, 3 skipped); `flutter_comics_viewer` rewritten to consume the shared library,
      its own duplicate model deleted (15/15 tests). See `04-implementation-log.md` for full detail,
      including 2 real gaps found beyond the original Plan (`canvas_view.dart`,
      `keyframe_interpolator_test.dart`) and the `flutter_comics_viewer` publishability consequence.

## Context Notes

- **Central finding**: `apps/comics-editor`'s model (`ComicsDoc`/`EditorLayer`/`Anim`/etc.) is the
  schema-complete source of truth, but its serializer (`models_mapping.dart`) is NOT a portable ZIP
  reader/writer — it merges into raw JSON a native Windows core already produced (FFI-coupled, per
  `flows/comics-editor/sdd-comics-editor-ffi`). The only currently-real, portable, pure-Dart `.comics`
  ZIP reader is `flutter_comics_viewer`'s `DartComicsViewerBackend`, but it has its OWN smaller,
  schema-incomplete duplicate model (missing `solidColor`/`mask`/`kind`/`parentId`/`groupId`/
  `Anim.basis`/`scrollType`/`preferredOrientation`/viewport-size — everything `tdd-dot-comics-format`
  has added). This flow moves the rich model + writes a new portable reader generalized from the
  viewer's existing working ZIP-open logic, eliminating both gaps at once.
- **v0.2 addition**: the exact same portability gap exists a second time for `.lottie` — the real
  Lottie parsing/import/export code (`lottie_mapping.dart`/`lottie_import.dart`/`lottie_export.dart`,
  built by `flows/comics-editor/tdd-dot-lottie-import-export`, IMPLEMENTATION-complete,
  480/480 tests) and the keyframe interpolator (`keyframe_interpolator.dart`, built by
  `vdd-comics-editor-scroll`, extended by `tdd-dot-comics-format`) are ALL confirmed portable (no
  `dart:io`, no FFI, no `EditorController` coupling — checked directly) and now move alongside the
  `.comics` model. Only the UI glue around them (`lottie_import_dialog.dart`, `EditorController`'s
  Lottie methods) stays behind, since that's genuinely `file_picker`/tempFolder-coupled.
- This flow is a **hard prerequisite** for `flows/comics-viewer/sdd-flutter-comics-viewer-dart`
  (confirmed by reading that flow's own Requirements directly: it states it's blocked on this flow
  reaching at least Plan-approved, and its Acceptance Criterion #4 requires deleting
  `DartViewerAnim`/`DartViewerLayer`/`DartComicsDocument` in favor of this library's model). That
  flow also defers its own interpolator-location question to this flow — resolved here in v0.2.
- Also touches files owned by the actively-worked `flows/comics-viewer/sdd-comics-viewer` — cross-
  reference added there is still pending (do when Plan is approved, not yet urgent at Requirements/
  Specifications stage).
- **Prior art found**: `flows/_archive/sdd-flutter-puzzle-viewer` (archived) already planned a
  `flutter_puzzle` library depending on a `flutter_comics` one for exactly this purpose — confirms
  the package name/shape has real precedent beyond just the editor+current viewer, informing the
  public API's genericity even though no active flow claims that third dependency today.
- **v0.3**: `.puzzle` is now DECIDED (not just recommended) — moves unconditionally with `models.dart`
  (Anton confirmed directly: "работу с .puzzle тоже перемести сюда"; code-checked: it's one enum
  value + `ComicsDoc.scale`, no separate class hierarchy, nothing to split even if desired). Also
  re-verified, per Anton's direct request, that the rendering-vs-format boundary holds: rendering
  (widgets/canvas/gestures/tile-LOD/sound playback/viewer controller-state) stays entirely in
  `flutter_comics_viewer`; `flutter_comics` owns the file/model/interpolation-values/import-export.
  Found the concrete reason `KeyframeInterpolator` specifically must live in `flutter_comics` (not
  just "feels right"): `lottie_export.dart` already has a hard, shipped dependency on it — keeping it
  in `flutter_comics_viewer` would force a backwards library→plugin dependency or a duplicate copy.
  `dart_comics_viewer_backend.dart`'s own duplicate model is deleted, confirming "не будет двойного
  кода" once this flow lands — `flutter_comics_viewer` will have exactly one `.comics` parser
  (`ComicsArchiveReader`, from the shared library) in its whole dependency graph.
- Real open questions carried to Plan (see both docs' own Open Questions, several resolved/corrected
  across v0.2/v0.3): write support scope (proposed read-only; `DartIoCore` already has a real but
  disk-oriented Dart ZIP writer, noted as a future reference algorithm, not adopted now), editor-only
  `EditorLayer` fields (proposed: move as-is, don't split the class), `language_registry.dart`
  coupling (narrowed to just `imageSlotFor`'s parameter type, 2 candidate fixes not yet chosen),
  exact package pubspec shape (Flutter vs. plain Dart package), whether
  `EditorMode`/`EditorWorkspace`/`PropertiesTab` move with the file, and the
  `archive_io.dart`→`archive.dart` import narrowing in `lottie_mapping.dart`. Both the cubic-ease-out
  interpolator's location AND `.puzzle`'s scope are now **resolved/decided**, not just leaning.

## Fork History

N/A — new flow. Supersedes/absorbs the shared-library half of
`flows/comics-viewer/sdd-flutter-comics-viewer`'s original (stale, never-implemented) scope; see that
flow's own `_status.md` for the disclosed note.

## Next Actions

1. Downstream `flows/comics-viewer/sdd-flutter-comics-viewer-dart` v0.2 Specifications await
   approval; viewer rendering remains intentionally unimplemented until that gate passes.
2. Task 5.5 from the v0.3 baseline: manual verification on a real device/simulator (open a real dataset `.comics` file
   with `solidColor`/`mask` set in the macOS-targeted `flutter_comics_viewer` example app, confirm
   those fields survive parsing) — the only undone item.
3. Add the disclosed cross-reference to `flows/comics-viewer/sdd-comics-viewer`'s own `_status.md`
   (`dart_comics_viewer_backend.dart`/`_surface.dart`, files that flow owns, were modified here).
4. Anton/whoever owns release process should decide how to resolve `flutter_comics_viewer`'s new
   publishability gap (`publish_to: 'none'` — can't go back to pub.dev until `flutter_comics` is
   also published, or the dependency is swapped at publish time).
5. `flows/comics-viewer/sdd-flutter-comics-viewer-dart` can now proceed to its own Plan — this flow
   is fully implemented, not just Plan-approved; no interpolator-location coordination needed
   (resolved, delivered).
6. This flow's own DOCUMENTATION phase (client-facing readme) hasn't been requested yet.
