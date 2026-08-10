# Implementation Plan: sdd-flutter-comics — shared `.comics` format library

> Version: 1.1 (camera-path/z-depth addendum)
> Status: BASELINE AND v1.1 ADDENDUM APPROVED AND IMPLEMENTED
> Last Updated: 2026-08-10
> Specifications: [02-specifications.md](02-specifications.md) (v0.4, APPROVED)

## Summary

Relocates the `.comics`/`.puzzle` data model, the keyframe interpolator, and the portable Lottie
parsing/import/export code from `apps/comics-editor` into a new standalone package
`libs/flutter_comics`, then rewrites `flutter_comics_viewer`'s Dart backend to consume it instead of
its own duplicate model. The implemented v1.0 baseline has five phases. The v1.1 addendum adds a
sixth, independently gated phase for the approved camera/depth contract. Each phase is independently
verifiable (full test suite green) before the next starts — matching this repo's "one test at a
time" discipline and Specifications' own Migration/Rollout section.

**Two standing execution constraints, from Anton directly this session, apply to every "Move" task
below**: files are relocated via a plain local filesystem operation (read the existing file's exact
bytes, write them at the new path, delete the old path) — **never** `git mv`/`git add`/`git rm`/any
other git command (Anton does git by hand), and **never** reconstructed/retyped from memory — the
content at the destination must be byte-identical to the source before any import-path edit is
applied on top.

## Task Breakdown

### Phase 1: Package skeleton + model/interpolator relocation

#### Task 1.1: Create `libs/flutter_comics` package skeleton
- **Description**: `pubspec.yaml` (Flutter package, not plain Dart — per Specifications' resolved
  Open Design Question: `models.dart`/`lottie_import.dart` use `package:flutter/widgets.dart` for
  `Offset`/`Color`, and "move, don't reinvent" means keeping that dependency rather than swapping to
  a Flutter-free geometry type), `analysis_options.yaml` (matching `apps/comics-editor`'s), `README
  .md` stub, `.gitignore`. `publish_to: 'none'`. `environment: sdk: ^3.12.2`, `flutter: sdk: flutter`.
  Dependencies: `archive: ^4.0.9`, `uuid: ^4.6.0` (both versions matched from `apps/comics-editor`'s
  own `pubspec.yaml`, for consistency — same versions already proven to work together in this repo).
- **Files**:
  - `libs/flutter_comics/pubspec.yaml` — Create
  - `libs/flutter_comics/analysis_options.yaml` — Create
  - `libs/flutter_comics/lib/flutter_comics.dart` — Create (export surface, empty exports for now —
    populated as each source file lands in later tasks)
- **Dependencies**: None
- **Verification**: `flutter pub get` succeeds inside `libs/flutter_comics`.
- **Complexity**: Low

#### Task 1.2: Move `models.dart`, decoupling `imageSlotFor`
- **Description**: Relocate `apps/comics-editor/lib/src/ui/models.dart` to
  `libs/flutter_comics/lib/src/models.dart` verbatim (filesystem move, per the standing constraint
  above). Then two small, real edits on top of the moved content (not a rewrite — surgical cuts):
  (a) remove `EditorMode`/`EditorWorkspace`/`PropertiesTab` (+ `EditorModeLabel` extension +
  `kEditorModes` const) — per Specifications' resolved Open Question, these are pure editor-UI-state,
  never persisted, zero relationship to any type this library models; (b) remove the `imageSlotFor`
  method body from inside `EditorLayer` (keep everything else on the class unchanged) — its
  `LanguageRegistry` parameter type is `rootBundle`-coupled, confirmed the one real reason
  `models.dart` imported `../i18n/language_registry.dart` at all. Drop that import entirely once (b)
  is done. `EditorLayer.clone()` is unaffected (it never called `imageSlotFor`).
- **Files**:
  - `apps/comics-editor/lib/src/ui/models.dart` → `libs/flutter_comics/lib/src/models.dart` — Move,
    then edit (remove the 3 enums + their extension/const, remove `imageSlotFor`'s body + the
    `language_registry.dart` import)
  - `libs/flutter_comics/lib/flutter_comics.dart` — Modify (add `export 'src/models.dart';`)
- **Dependencies**: Task 1.1
- **Verification**: `libs/flutter_comics` compiles (`flutter analyze`) with `models.dart` in place.
  Not yet tested here — `models_test.dart` moves in Task 2.1, since it needs the package's own test
  harness set up first.
- **Complexity**: Medium (two real, deliberate cuts inside an otherwise-verbatim move; must not touch
  anything else in the file)

#### Task 1.3: Re-home `EditorMode`/`EditorWorkspace`/`PropertiesTab` in `apps/comics-editor`
- **Description**: The 3 enums cut out in Task 1.2 need a new home in the app (they're still used
  throughout — `controller.dart`, `top_bar.dart`, etc.). Create one new small file holding exactly
  what was removed, verbatim (moved, not retyped) from the original `models.dart` content.
- **Files**:
  - `apps/comics-editor/lib/src/ui/editor_mode.dart` — Create (contains `EditorMode`,
    `EditorModeLabel` extension, `kEditorModes`, `EditorWorkspace`, `PropertiesTab` — moved verbatim
    from the pre-edit `models.dart`)
- **Dependencies**: Task 1.2
- **Verification**: Deferred to Task 2.2's editor-wide import fixup pass (this file alone doesn't
  compile in isolation until its callers' imports are updated).
- **Complexity**: Low

#### Task 1.4: Re-home `EditorLayer.imageSlotFor` as an extension in `apps/comics-editor`
- **Description**: Add back the exact method body cut out in Task 1.2, as
  `extension EditorLayerLanguageSlot on EditorLayer` in `language_registry.dart` (the file that
  already owns `LanguageRegistry` — the natural home for the one place `EditorLayer` and
  `LanguageRegistry` meet). Zero behavior change for existing callers (`controller.dart`'s
  `setImageFile`/`setImagePopup`, `layer.imageSlotFor(langCode, registry)` call syntax is identical
  for an extension method).
- **Files**:
  - `apps/comics-editor/lib/src/i18n/language_registry.dart` — Modify (add the extension, add
    `import 'package:flutter_comics/flutter_comics.dart';` for `EditorLayer`/`LayerImage`)
- **Dependencies**: Task 1.2
- **Verification**: Deferred to Task 2.2 (needs `EditorLayer` importable from the package first).
- **Complexity**: Low

#### Task 1.5: Move `keyframe_interpolator.dart`
- **Description**: Relocate verbatim (filesystem move, unedited — confirmed portable as-is: only
  `dart:ui` + `models.dart`).
- **Files**:
  - `apps/comics-editor/lib/src/ui/anim/keyframe_interpolator.dart` →
    `libs/flutter_comics/lib/src/keyframe_interpolator.dart` — Move (only its own
    `import '../models.dart'` line changes, to `import 'models.dart';` matching the new relative
    location)
  - `libs/flutter_comics/lib/flutter_comics.dart` — Modify (add export)
- **Dependencies**: Task 1.2
- **Verification**: `flutter analyze` clean in `libs/flutter_comics`.
- **Complexity**: Low

### Phase 2: Editor-side import fixups (model + interpolator), verify editor suite green

#### Task 2.1: Move `models_test.dart`; update `apps/comics-editor`'s import graph
- **Description**: Move the one test file confirmed clean (only imports `dart:ui`/`flutter_test`/
  `models.dart`) into `libs/flutter_comics/test/`. Then update every real importer identified in
  Specifications' Affected Systems table: the 15 `lib/` files that import `models.dart` directly
  (`keyframe_interpolator.dart` already handled in 1.5; `sound_player.dart`, `controller.dart`,
  `edit_history.dart`, `lottie_export.dart`, `lottie_import.dart`, `editor_screen.dart`,
  `balloon_editor_card.dart`, `balloon_rail.dart`, `dialogs.dart`, `properties_panel.dart`,
  `scene_panel.dart`, `timeline.dart`, `top_bar.dart`, `viewer_workspace.dart`) get
  `import '../ui/models.dart'`-style lines replaced with
  `import 'package:flutter_comics/flutter_comics.dart';` (`lottie_import.dart`/`lottie_export.dart`
  get their own dedicated move in Phase 3 instead — skip them here, they'll need this same fix
  applied at that point). The 3 files that additionally import `models_mapping.dart` directly
  (`controller.dart`, `balloon_editor_card.dart`, `cutting_canvas.dart`) are unaffected by this task
  (that import path doesn't change — `models_mapping.dart` isn't moving). Every caller of
  `EditorMode`/`EditorWorkspace`/`PropertiesTab` additionally needs
  `import '../editor_mode.dart';` (or the correct relative path) added.
- **Files**:
  - `apps/comics-editor/test/models_test.dart` → `libs/flutter_comics/test/models_test.dart` — Move
  - `apps/comics-editor/lib/src/ui/audio/sound_player.dart`,
    `.../ui/controller.dart`, `.../ui/edit_history.dart`, `.../ui/screens/editor_screen.dart`,
    `.../ui/widgets/balloon_editor_card.dart`, `.../ui/widgets/balloon_rail.dart`,
    `.../ui/widgets/dialogs.dart`, `.../ui/widgets/properties_panel.dart`,
    `.../ui/widgets/scene_panel.dart`, `.../ui/widgets/timeline.dart`,
    `.../ui/widgets/top_bar.dart`, `.../ui/widgets/viewer_workspace.dart` — Modify (import path only)
  - `apps/comics-editor/lib/src/bridge/models_mapping.dart` — Modify (its own
    `import '../ui/models.dart';` → `import 'package:flutter_comics/flutter_comics.dart';`;
    `comicsFromCore`/`comicsToCore` logic itself untouched)
  - `apps/comics-editor/pubspec.yaml` — Modify (add
    `flutter_comics: path: ../../libs/flutter_comics`)
- **Dependencies**: Tasks 1.2, 1.3, 1.4, 1.5
- **Verification**: `libs/flutter_comics/test/models_test.dart` passes standalone. `flutter analyze`
  clean in `apps/comics-editor`.
- **Complexity**: Medium (mechanical, but 12+ files touched — go one file at a time, per this repo's
  own testing discipline, not one giant diff)

#### Task 2.2: Fix up the ~47 test files referencing `models.dart`/`models_mapping.dart`
- **Description**: `apps/comics-editor/test/` has 47 files importing `models.dart` and/or
  `models_mapping.dart` (grep-confirmed). Each needs its `models.dart` import switched to the package
  import; imports of `models_mapping.dart` stay as-is (unmoved). This is the task that actually
  proves Task 2.1 didn't break anything — run the full suite after, not file-by-file guessing.
- **Files**: All 47 files under `apps/comics-editor/test/` referencing either import (exact list
  produced by `grep -rl "models\.dart\|models_mapping\.dart" test --include="*.dart"` at task-start
  time, not hand-enumerated here since the set may have grown since this Plan was written) — Modify
  (import path only, mechanical)
- **Dependencies**: Task 2.1
- **Verification**: `flutter test` in `apps/comics-editor` — full suite green, zero regressions
  (baseline: 480/480 passing before this Plan started, 3 skipped for monorepo-only fixtures).
- **Complexity**: Medium (mechanical volume, not logic — a single careful find/replace pass per file,
  verified by the full suite, not per-file manual reasoning)

### Phase 3: Lottie files + their tests, editor Lottie-UI import fixups, verify editor suite green

#### Task 3.1: Move the 3 Lottie files
- **Description**: Relocate verbatim. `lottie_mapping.dart` gets one real edit on top of the move:
  `import 'package:archive/archive_io.dart';` → `import 'package:archive/archive.dart';` (confirmed
  by grep: only `Archive`/`ZipDecoder`/`ArchiveFile`/`ZipEncoder` are used, none of `archive_io.dart`'s
  extra file-based IO helpers — the narrower import is genuinely more portable, per Specifications).
  `lottie_import.dart`/`lottie_export.dart` move with no internal edits beyond their own relative
  imports of each other and of `models.dart`/`keyframe_interpolator.dart`, which change to match
  their new sibling location inside `libs/flutter_comics/lib/src/lottie/`.
- **Files**:
  - `apps/comics-editor/lib/src/bridge/lottie_mapping.dart` →
    `libs/flutter_comics/lib/src/lottie/lottie_mapping.dart` — Move + one import edit
    (`archive_io.dart` → `archive.dart`)
  - `apps/comics-editor/lib/src/ui/lottie/lottie_import.dart` →
    `libs/flutter_comics/lib/src/lottie/lottie_import.dart` — Move (relative imports updated to match
    new location: `'../../bridge/lottie_mapping.dart'` → `'lottie_mapping.dart'`,
    `'../models.dart'` → `'../models.dart'` [unchanged shape, one directory up])
  - `apps/comics-editor/lib/src/ui/lottie/lottie_export.dart` →
    `libs/flutter_comics/lib/src/lottie/lottie_export.dart` — Move (same relative-import fixups, plus
    `'../anim/keyframe_interpolator.dart'` → `'../keyframe_interpolator.dart'`)
  - `libs/flutter_comics/lib/flutter_comics.dart` — Modify (add 3 exports)
- **Dependencies**: Task 1.5 (needs `keyframe_interpolator.dart` already in place)
- **Verification**: `flutter analyze` clean in `libs/flutter_comics`.
- **Complexity**: Medium (real import-path edits, but no logic changes — must not touch anything
  beyond import lines)

#### Task 3.2: Move the 4 clean Lottie test files
- **Description**: `lottie_mapping_test.dart`, `lottie_import_test.dart`, `lottie_export_test.dart`,
  `lottie_commit_import_test.dart` — confirmed by their actual imports to depend only on the 3 files
  just moved plus `models.dart`. `lottie_roundtrip_test.dart` is **not** in this task — it has the one
  contingent dependency on `comics_reader.dart` (Task 4.3 covers it).
- **Files**:
  - `apps/comics-editor/test/lottie_mapping_test.dart`,
    `.../lottie_import_test.dart`, `.../lottie_export_test.dart`,
    `.../lottie_commit_import_test.dart` → `libs/flutter_comics/test/` — Move (import paths updated
    to the package + relative `lottie/` location, assertions unchanged)
- **Dependencies**: Task 3.1
- **Verification**: All 4 pass standalone inside `libs/flutter_comics`.
- **Complexity**: Low

#### Task 3.3: Fix up `apps/comics-editor`'s Lottie-UI import paths
- **Description**: `lottie_import_dialog.dart` and `controller.dart`'s Lottie methods
  (`pickLottieToImport`/`setLottieImportMode`/`setLottieScrollSpeed`/`setLottieEasingChoice`/
  `cancelLottieImport`/`commitLottieImport`/`exportLottieWithDialog`) do **not** move (confirmed
  `file_picker`/`EditorScope`/tempFolder-coupled) — only their
  `import '../lottie/lottie_import.dart'`/`import '../../bridge/lottie_mapping.dart'`-style lines
  change to the package import. `lottie_controller_test.dart` gets the same treatment (stays, import
  path only).
- **Files**:
  - `apps/comics-editor/lib/src/ui/widgets/lottie_import_dialog.dart`,
    `.../ui/controller.dart` — Modify (import path only)
  - `apps/comics-editor/test/lottie_controller_test.dart` — Modify (import path only)
- **Dependencies**: Task 3.1
- **Verification**: `flutter test` in `apps/comics-editor` — full suite green again.
- **Complexity**: Low

### Phase 4: `comics_reader.dart` (NEW) + its test; move the contingent round-trip test

#### Task 4.1: Write `ComicsArchiveReader`
- **Description**: New file, per Specifications' Interfaces section — `readBytes(Uint8List)`/
  `readFile(String path)`, generalized from `DartComicsViewerBackend.load()`'s real, already-working
  ZIP-open logic (locate `data.json`, decode, walk `raw['layers']`) but populating the **full**
  `ComicsDoc`/`EditorLayer` model. Reuses `models_mapping.dart`'s existing per-field JSON parsing
  helpers as the basis for each field (`_animFromJson`/`_maskFromJson`/`_textRegionFromJson`/etc. —
  adapted to work directly off a freshly-ZIP-decoded raw map instead of the native-core's raw map;
  same shape, different origin, per Specifications' Data Models section). Read-only (Specifications'
  decided scope). Throws `FormatException` on missing `data.json` (matches
  `DartComicsViewerBackend`'s existing behavior, not weakened).
- **Files**:
  - `libs/flutter_comics/lib/src/comics_reader.dart` — Create
  - `libs/flutter_comics/lib/flutter_comics.dart` — Modify (add export)
- **Dependencies**: Task 1.2 (needs the moved model)
- **Verification**: Deferred to Task 4.2.
- **Complexity**: High (the one genuinely new piece of logic in this whole Plan — needs care to
  cover every schema field, not just the 5 `DartComicsViewerBackend` currently handles)

#### Task 4.2: `comics_reader_test.dart`
- **Description**: New test — round-trips a synthetic in-memory `.comics` archive covering every
  current schema field (`solidColor`, `mask`, `kind`, `style`, `parentId`, `groupId`, `scrollType`,
  `preferredOrientation`, `preferredViewportWidth`/`Height`, `Anim.basis`, `TextRegion`), not just the
  five fields `dart_comics_viewer_backend_test.dart` covered before this flow.
- **Files**: `libs/flutter_comics/test/comics_reader_test.dart` — Create
- **Dependencies**: Task 4.1
- **Verification**: Test itself passes.
- **Complexity**: Medium

#### Task 4.3: Move `lottie_roundtrip_test.dart`, rewriting its one contingent dependency
- **Description**: G3's fixture-prep step currently calls `comicsFromCore` (from
  `models_mapping.dart`, which stays in `apps/comics-editor`) to parse the real
  `sample_v2012.comics_unzip/data.json` fixture. Rewrite that one step to use
  `ComicsArchiveReader.readBytes` instead (now that it exists) — the fixture is a real ZIP-unzipped
  directory already on disk in `samples/`, so this needs the directory's `data.json` re-zipped
  in-memory first (or `ComicsArchiveReader` gains a convenience for an already-decoded raw map — real
  design decision to make when writing this task, not pre-decided here). Once that one dependency is
  gone, move the file; everything else in it (G6, E1) already only depends on the 3 Lottie files +
  `models.dart`/`keyframe_interpolator.dart`, already moved.
- **Files**:
  - `apps/comics-editor/test/lottie_roundtrip_test.dart` → `libs/flutter_comics/test/
    lottie_roundtrip_test.dart` — Move + one real rewrite (G3's fixture-prep step only)
- **Dependencies**: Task 4.1, Task 3.2
- **Verification**: All 3 cases (G3/G6/E1) pass inside `libs/flutter_comics`.
- **Complexity**: Medium

#### Task 4.4: Editor-side backward-compat re-verification
- **Description**: `dataset_backward_compat_test.dart` and `models_mapping_test.dart` stay in
  `apps/comics-editor/test/` (Specifications' correction) — confirm both still pass with only their
  transitive `models.dart` import now resolving through the package. This is the checkpoint that
  proves the "stays, doesn't move" decision was actually correct, not just argued.
- **Files**: None changed (verification-only task)
- **Dependencies**: Task 2.2
- **Verification**: `flutter test` in `apps/comics-editor` — full suite green, including these two by
  name.
- **Complexity**: Low

### Phase 5: `flutter_comics_viewer` rewrite

#### Task 5.1: Add the `flutter_comics` path dependency
- **Files**: `libs/comics_viewer/flutter_comics_viewer/pubspec.yaml` — Modify (add
  `flutter_comics: path: ../../flutter_comics`)
- **Dependencies**: Task 4.1 (viewer needs `ComicsArchiveReader` to exist)
- **Verification**: `flutter pub get` succeeds.
- **Complexity**: Low

#### Task 5.2: Rewrite `dart_comics_viewer_backend.dart`
- **Description**: Delete `DartViewerAnimType`/`DartViewerAnim`/`DartViewerTile`/`DartViewerLayer`/
  `DartComicsDocument` and the file's own `_parseAnimation`/`_rebuild` parsing logic entirely. Replace
  `load()`'s body with `ComicsArchiveReader.readBytes`/`.readFile`. The class's own public
  `ComicsViewerBackend` interface (`comics_viewer_backend.dart`) is unchanged — same method
  signatures, different internals.
- **Files**: `libs/comics_viewer/flutter_comics_viewer/lib/src/dart_comics_viewer_backend.dart` —
  Modify (rewrite internals; not a move, this file doesn't relocate)
- **Dependencies**: Task 5.1
- **Verification**: Deferred to Task 5.4 (needs the surface updated to compile together).
- **Complexity**: High (real logic deletion + rewiring, the riskiest task in this Plan for silent
  behavior drift — needs the extended `dart_comics_viewer_backend_test.dart` from Task 5.4 to catch
  regressions)

#### Task 5.3: Rewrite `dart_comics_viewer_surface.dart`
- **Description**: Field access updated from the deleted `DartViewerLayer` shape to the shared
  `EditorLayer`/`Anim` shape (e.g. `EditorLayer.anims` vs. the old `DartViewerLayer.animations`).
  Interpolation calls switch from `DartViewerLayer`'s own `translateAt`/`scaleAt`/`rotateAt`/
  `alphaAt` to the shared `KeyframeInterpolator`'s same-named static methods, operating on
  `EditorLayer.anims` directly.
- **Files**: `libs/comics_viewer/flutter_comics_viewer/lib/src/dart_comics_viewer_surface.dart` —
  Modify (rewrite internals; not a move)
- **Dependencies**: Task 5.2
- **Verification**: Deferred to Task 5.4.
- **Complexity**: Medium

#### Task 5.4: Move + extend `dart_comics_viewer_backend_test.dart`
- **Description**: Relocate into `libs/flutter_comics/test/`? **No** — per the same backwards-
  dependency logic already applied to `apps/comics-editor`'s tests, this test exercises
  `flutter_comics_viewer`'s OWN backend/surface (a `flutter_comics_viewer`-specific consumer concern,
  not a `flutter_comics` format concern) — it **stays** in
  `libs/comics_viewer/flutter_comics_viewer/test/`, rewritten (not moved) to assert against the full
  model's fields instead of the deleted minimal `DartViewer*` types, and extended to cover the
  previously-dropped fields (`solidColor`/`mask`/`kind`/etc. — the concrete, testable proof this whole
  flow fixed the real drift found during Requirements' analysis).
- **Files**: `libs/comics_viewer/flutter_comics_viewer/test/dart_comics_viewer_backend_test.dart` —
  Modify (rewritten in place, not moved — corrects an ambiguity in Specifications' original phrasing,
  which said "relocates"; it does not, by the same logic as Task 5.4's own header)
- **Dependencies**: Tasks 5.2, 5.3
- **Verification**: This test file's own suite passes; full `flutter_comics_viewer` suite green.
- **Complexity**: Medium

#### Task 5.5: Manual verification
- **Description**: Per Specifications' Manual Verification checklist — open a real dataset `.comics`
  file with `solidColor`/`mask` set in the macOS-targeted `flutter_comics_viewer` example app,
  before/after, confirm those fields survive parsing post-rewrite (rendering support for them is out
  of scope — `sdd-flutter-comics-viewer-dart`'s concern).
- **Files**: None
- **Dependencies**: Task 5.4
- **Verification**: Manual, by Anton or Claude with real device/simulator access.
- **Complexity**: Low

## Dependency Graph

```
1.1 ─→ 1.2 ─┬─→ 1.3 ─┐
            ├─→ 1.4 ─┤
            └─→ 1.5 ─┴─→ 2.1 ─→ 2.2 ─┬─→ 3.1 ─┬─→ 3.2 ─┐
                                     │        └─→ 4.1 ─┬─→ 4.2
                                     └─→ 3.3            ├─→ 4.3 (needs 3.2 too)
                                                         └─→ 5.1 ─→ 5.2 ─→ 5.3 ─→ 5.4 ─→ 5.5
                                     2.2 ─→ 4.4 (parallel checkpoint, no further deps)
```

Phases 1-2 are strictly sequential (each later task needs the model already in place and importable).
Phase 3 (Lottie) and Phase 4's `comics_reader.dart` (Task 4.1) can proceed in parallel once Phase 2 is
green, since neither depends on the other directly — but Task 4.3 (the contingent round-trip test)
needs BOTH Task 3.2 and Task 4.1 done. Phase 5 needs Task 4.1 (the new reader) but not Phase 3's
Lottie files specifically (the viewer doesn't consume Lottie import/export today).

## File Change Summary

| File | Action | Reason |
|------|--------|--------|
| `libs/flutter_comics/pubspec.yaml`, `analysis_options.yaml`, `lib/flutter_comics.dart` | Create | New package skeleton |
| `libs/flutter_comics/lib/src/models.dart` | Move (from `apps/comics-editor`) + 2 surgical cuts | The relocated `.comics`/`.puzzle` model, minus editor-UI-only enums and the `LanguageRegistry`-coupled method |
| `libs/flutter_comics/lib/src/keyframe_interpolator.dart` | Move | Portable interpolation math; `lottie_export.dart` depends on it, forcing this location |
| `libs/flutter_comics/lib/src/lottie/lottie_mapping.dart` | Move + 1 import edit | Portable `.lottie` ZIP+JSON; `archive_io.dart`→`archive.dart` for genuine Web-safety |
| `libs/flutter_comics/lib/src/lottie/lottie_import.dart`, `lottie_export.dart` | Move | Portable Lottie import/export logic |
| `libs/flutter_comics/lib/src/comics_reader.dart` | Create | NEW — the portable `.comics`/`.puzzle` reader neither existing codebase had in full-schema form |
| `libs/flutter_comics/test/models_test.dart`, `lottie_mapping_test.dart`, `lottie_import_test.dart`, `lottie_export_test.dart`, `lottie_commit_import_test.dart`, `lottie_roundtrip_test.dart` (contingent rewrite), `comics_reader_test.dart` (new) | Move / Create | Tests confirmed to exercise only relocated/new logic |
| `apps/comics-editor/lib/src/ui/editor_mode.dart` | Create | New home for the 3 enums cut from `models.dart` |
| `apps/comics-editor/lib/src/i18n/language_registry.dart` | Modify | Gains the `imageSlotFor` extension cut from `models.dart` |
| `apps/comics-editor/lib/src/bridge/models_mapping.dart` | Modify | Import path only; `comicsFromCore`/`comicsToCore` unchanged |
| `apps/comics-editor/lib/**` (12 files) + `apps/comics-editor/test/**` (47 files) | Modify | Import path updates only |
| `apps/comics-editor/lib/src/ui/widgets/lottie_import_dialog.dart`, `.../ui/controller.dart` | Modify | Import path only; Lottie UI/tempFolder glue stays |
| `apps/comics-editor/test/models_mapping_test.dart`, `dataset_backward_compat_test.dart`, `lottie_controller_test.dart` | Modify (stay, corrected from a naive full-relocation reading) | Test logic that stays in `apps/comics-editor` |
| `libs/comics_viewer/flutter_comics_viewer/pubspec.yaml` | Modify | Add `flutter_comics` path dependency |
| `libs/comics_viewer/flutter_comics_viewer/lib/src/dart_comics_viewer_backend.dart`, `dart_comics_viewer_surface.dart` | Modify (rewrite internals, not moved) | Delete duplicate model, consume shared model + reader + interpolator |
| `libs/comics_viewer/flutter_comics_viewer/test/dart_comics_viewer_backend_test.dart` | Modify (rewrite in place, not moved) | Asserts against the full model; extended for previously-dropped fields |

## v1.1 Addendum Task Breakdown

### Phase 6: Camera-path and z-depth shared contract (v1.1 addendum)

This phase is additive to the completed v1.0 work. It implements only the already-approved v0.4
Requirements/Specifications; applying the result to pixels remains the downstream viewer flow's
responsibility.

#### Task 6.1: Add the typed camera/depth model and clone behavior

- **Description**: Add `CameraKeyframe`, `CameraPath`, `ComicsDoc.cameraPath`, and
  `EditorLayer.zDepth` exactly as specified. Extend clone operations so a document clone owns a
  distinct point list and every layer retains its normalized depth.
- **Files**:
  - `libs/flutter_comics/lib/src/models.dart` — Modify
  - `libs/flutter_comics/test/models_test.dart` — Modify
- **Dependencies**: Completed v1.0 model extraction.
- **Verification**: defaults are inert; deep-clone mutation cannot affect the source; positive and
  valid negative depth survive cloning.
- **Complexity**: Low

#### Task 6.2: Parse and normalize `cameraPath`/`zDepth`

- **Description**: Extend the one portable reader. Drop malformed camera points, stable-sort by
  integer `position`, collapse duplicates last-one-wins, and normalize invalid/non-finite or
  `<= -1` depth to `0`. Do not add a second parser in the viewer.
- **Files**:
  - `libs/flutter_comics/lib/src/comics_reader.dart` — Modify
  - `libs/flutter_comics/test/comics_reader_test.dart` — Modify
- **Dependencies**: Task 6.1
- **Verification**: synthetic absent/zero/valid/malformed cases; direct contract read of the two
  repository fixtures at `libs/comics_viewer/flutter_comics_viewer/example/assets/` proves
  `sample_v2012.comics` is byte-identical to the authoritative `samples/` fixture and its complete
  classic root/layer/image/animation/sound shape parses with all additive defaults, while
  `sample_v2026.comics` yields 19 canonical camera points plus its non-uniform depths. Neither large
  archive is copied into another package.
- **Complexity**: Medium

#### Task 6.3: Implement and export the pure camera evaluator

- **Description**: Add `CameraPathEvaluator.sample`, `responseForDepth`, and
  `parallaxAdjustment`. Use the existing cubic-ease-out convention, endpoint holds, finite-output
  guards, and the exact `1 / (1 + z)` response. This code returns document-space values only: no
  widgets, viewport/device math, global scene translation, or platform branching.
- **Files**:
  - `libs/flutter_comics/lib/src/camera_path.dart` — Create
  - `libs/flutter_comics/lib/flutter_comics.dart` — Modify
  - `libs/flutter_comics/test/camera_path_test.dart` — Create
- **Dependencies**: Tasks 6.1-6.2
- **Verification**: exact endpoints, cubic midpoint, before/after holds, `z=0`, `z=1`, `z=-0.5`,
  invalid depth, path shorter than two points, and non-finite-output protection.
- **Complexity**: Medium

#### Task 6.4: Preserve camera/depth through the editor bridge

- **Description**: Extend only the existing raw-JSON mapping/merge path. Read normalized values,
  write canonical increasing camera points, preserve nonzero depths, and keep all unknown raw keys.
  Do not redesign the native core, ZIP I/O, or editor UI.
- **Files**:
  - `apps/comics-editor/lib/src/bridge/models_mapping.dart` — Modify
  - `apps/comics-editor/test/models_mapping_test.dart` — Modify
- **Dependencies**: Tasks 6.1-6.2
- **Verification**: open→clone/undo-shaped clone→merge/save round-trip preserves the path and every
  nonzero depth while legacy input remains behaviorally inert.
- **Complexity**: Medium

#### Task 6.5: Cross-package regression gate and handoff

- **Description**: Run shared-library and editor suites, analyzer, and formatter. Record the exact
  public evaluator contract for the downstream Dart viewer Plan; do not implement viewer painting
  under this task.
- **Files**:
  - `flows/sdd-flutter-comics/04-implementation-log.md` — Modify during implementation
  - `flows/sdd-flutter-comics/_status.md` — Modify during implementation
- **Dependencies**: Tasks 6.1-6.4
- **Verification**: `flutter test` and `flutter analyze` in `libs/flutter_comics`; affected editor
  tests and full editor regression suite green; `dart format --output=none --set-exit-if-changed`
  for touched Dart files.
- **Complexity**: Low

**Phase 6 checkpoint**: the shared package can parse the full v2012-compatible fixture and parse,
clone, sample, and evaluate the v2026 camera/depth fixture; it still owns no rendering or viewport
policy.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| `comics_reader.dart` (Task 4.1) misses a schema field `DartComicsViewerBackend` never handled, silently reintroducing a smaller version of the exact drift this flow fixes | Medium | Medium | Task 4.2's test explicitly covers every current field by name, not just the 5 legacy ones; `dataset_backward_compat_test.dart` (Task 4.4) provides a second, real-file check |
| Task 5.2/5.3's rewrite of `dart_comics_viewer_backend.dart`/`_surface.dart` introduces a silent rendering regression (wrong field mapping, e.g. `EditorLayer.anims` ordering vs. the old `DartViewerLayer.animations`) | Medium | High | Task 5.4's extended test + Task 5.5's manual verification against a real dataset file with every field set; these files are owned by the actively-worked `sdd-comics-viewer` flow too — coordinate before merging (see Requirements' cross-flow note) |
| Task 1.2's two surgical cuts (enums, `imageSlotFor`) accidentally remove or alter something else in `models.dart` during the edit | Low | High | `flutter analyze` immediately after each cut, before moving to the next task; the moved file's line count minus the two removed blocks should match exactly |
| The `~47` test files in Task 2.2 turn out to be a stale count by the time this task actually runs (more may have been added) | Low | Low | Task 2.2 re-greps at task-start time rather than trusting this Plan's snapshot number |

## Rollback Strategy

Every move in this Plan is a plain filesystem relocation with no git operations performed by Claude
— Anton's own git workflow (not this Plan) is the actual safety net; if a phase needs reverting,
that's a manual git operation on his side, not a step this Plan prescribes. Within a session, each
phase is checkpointed by a full green test suite before the next starts, so a bad phase is caught
immediately rather than compounding.

## Checkpoints

After each phase, verify:

- [ ] Phase 1: `libs/flutter_comics` compiles (`flutter analyze` clean)
- [ ] Phase 2: `apps/comics-editor`'s full suite green (480/480 baseline, 3 skipped)
- [ ] Phase 3: `apps/comics-editor`'s full suite green again; `libs/flutter_comics`'s Lottie tests
      pass standalone
- [ ] Phase 4: `libs/flutter_comics`'s full suite green (including the moved round-trip test);
      `apps/comics-editor`'s `dataset_backward_compat_test.dart`/`models_mapping_test.dart` still pass
- [ ] Phase 5: `flutter_comics_viewer`'s full suite green; manual verification done
- [x] Phase 6: camera/depth model, parser, evaluator, and editor round-trip tests green; both new
      example archives parsed according to their contracts

## Open Implementation Questions

- [ ] Task 4.3's exact mechanism for feeding `sample_v2012.comics_unzip`'s already-unzipped
      `data.json` through `ComicsArchiveReader.readBytes` (which expects zip bytes, not an
      already-decoded map) — re-zip the fixture directory in-memory at test time, or give
      `ComicsArchiveReader` a second entry point for an already-parsed raw map? Real decision at
      implementation time, not pre-decided here.
- [ ] Exact wording/scope of `libs/flutter_comics/README.md` — not blocking, can be minimal at
      Task 1.1 and filled in properly during this flow's own DOCUMENTATION phase later.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-08
- [x] Notes: v1.0 approved as drafted and implemented through Phase 5.

### v1.1 camera/depth addendum gate

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-10
- [x] Notes: Implements the already-approved Requirements/Specifications v0.4. Phase 6 completed
      after explicit approval; viewer painting remains gated by its own v0.2 Specifications.
