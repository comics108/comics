# Specifications: sdd-flutter-comics — shared `.comics` format library

> Version: 0.3
> Status: APPROVED
> Last Updated: 2026-08-08
> Requirements: [01-requirements.md](01-requirements.md) (v0.3, APPROVED)

## Overview

Create `libs/flutter_comics`, a standalone Dart package holding: (a) the `.comics`/`.puzzle` data
model, relocated verbatim from `apps/comics-editor/lib/src/ui/models.dart`; (b) the keyframe
interpolation math, relocated verbatim from `.../lib/src/ui/anim/keyframe_interpolator.dart`; (c) the
portable `.lottie` parsing/import/export code, relocated verbatim from `.../lib/src/bridge/
lottie_mapping.dart` + `.../lib/src/ui/lottie/lottie_import.dart`/`lottie_export.dart`; (d) a new
portable `.comics`/`.puzzle` ZIP+JSON reader, generalized from `flutter_comics_viewer`'s existing
`DartComicsViewerBackend.load()` logic to populate the full model instead of its current minimal
subset; (e) the tests that exercise (a)-(d) with no other coupling, relocated. Both
`apps/comics-editor` and `flutter_comics_viewer` then depend on this package instead of maintaining
their own copies.

**v0.2 revises v0.1** after reading every flow under `flows/` (per Anton's explicit request,
2026-08-08) and verifying every file's *actual* `import` statements directly rather than assuming.
Two changes of substance: (1) the Lottie files + interpolator are now in scope (see
`01-requirements.md`'s Addendum); (2) v0.1's test-relocation row was **wrong for 2 of 3 files** —
`models_mapping_test.dart` and `dataset_backward_compat_test.dart` both test logic that stays in
`apps/comics-editor` (`comicsFromCore`/`comicsToCore`, `DartIoCore`), so moving them would make the
shared library depend backwards on the app that depends on it. Corrected below.

## Interaction Interface

How `libs/flutter_comics` is consumed by each side, once this flow lands:

```
libs/flutter_comics (public export surface: lib/flutter_comics.dart)
├── Models        ComicsDoc, EditorLayer, Anim, AnimType, AnimBasis, LayerMask, TextRegion,
│                  LayerImage, EditorSound, ScrollType, PreferredOrientation, DocType, RecentFile,
│                  Lang, kLangs  (relocated from models.dart; EditorMode/EditorWorkspace/
│                  PropertiesTab -- pure editor-UI-state, never persisted -- are an Open Question,
│                  see below, on whether they move too or stay behind)
├── Interpolation  KeyframeInterpolator.translateAt/scaleAt/rotateAt/alphaAt(List<Anim>, ...)
│                  (relocated from keyframe_interpolator.dart, unchanged)
├── Lottie         LottieDocument/LottieLayer/LottieAsset/LottieMask/LottieTransform/
│                  LottieProperty/LottieKeyframe/LottieFormatException, parseLottieDocument/
│                  parseLottieJson/writeLottieDocument (relocated from lottie_mapping.dart);
│                  ExportImportMode/ImportPreview/LayerPreview/LayerPreviewStatus/EasingChoice/
│                  detectMode/commitImport (relocated from lottie_import.dart); buildLottieExport
│                  (relocated from lottie_export.dart)
└── Reader (NEW)   ComicsArchiveReader.readBytes/.readFile -- portable .comics/.puzzle ZIP+JSON
                   reader, generalized from DartComicsViewerBackend.load() + models_mapping.dart's
                   existing per-field JSON parsing helpers

        ^                                          ^                          ^
        | package:flutter_comics/flutter_comics.dart (pub path dependency, same for all 3)
        |                                          |                          |
apps/comics-editor                    flutter_comics_viewer          (future) libs/flutter_puzzle
                                                                       (flows/_archive/sdd-flutter-
                                                                        puzzle-viewer already assumed
                                                                        this dependency -- no active
                                                                        flow claims it today, kept in
                                                                        mind for API genericity only)

apps/comics-editor's own remaining, UNCHANGED-logic, native-core-coupled layer:
  models_mapping.dart (dart:io, CoreDocument, comicsFromCore/comicsToCore -- raw-JSON <-> shared
                        model, merges into the native core's own JSON, stays here)
  controller.dart, lottie_import_dialog.dart, tile_writer.dart, language_registry.dart
    (file_picker / EditorController / CoreDocument.tempFolder / rootBundle-coupled UI+IO glue --
     none of this is portable, none of it moves)

flutter_comics_viewer's own remaining, MODIFIED-in-place layer:
  dart_comics_viewer_backend.dart / dart_comics_viewer_surface.dart -- deletes their own duplicate
    DartViewerAnim/DartViewerLayer/DartComicsDocument model, calls ComicsArchiveReader.readBytes +
    KeyframeInterpolator directly against the now-shared EditorLayer/Anim types
```

**Read/write boundary** (per Requirements' Open Question, resolved below): `ComicsArchiveReader` is
**read-only**. Nothing needs standalone Dart-side `.comics` ZIP *writing* yet — `apps/comics-editor`
saves through the native core (`comicsToCore` merges into the core's raw JSON, which the core then
persists — an entirely different, unchanged path); `flutter_comics_viewer` never saves at all.

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `libs/flutter_comics` (new) | Create | New standalone Dart package |
| `apps/comics-editor/lib/src/ui/models.dart` | Delete (moved) | → `libs/flutter_comics/lib/src/models.dart`. `EditorLayer.imageSlotFor`'s `LanguageRegistry` coupling must be resolved first (see Requirements' new Open Question) |
| `apps/comics-editor/lib/src/ui/anim/keyframe_interpolator.dart` | Delete (moved) | → `libs/flutter_comics/lib/src/keyframe_interpolator.dart`, verbatim (only imports `dart:ui` + `models.dart`, confirmed portable) |
| `apps/comics-editor/lib/src/bridge/lottie_mapping.dart` | Delete (moved) | → `libs/flutter_comics/lib/src/lottie/lottie_mapping.dart`. Its `import 'package:archive/archive_io.dart'` should become `package:archive/archive.dart` (only `Archive`/`ZipDecoder`/`ArchiveFile`/`ZipEncoder` are used — none of `archive_io.dart`'s extra IO-file helpers — confirmed by grep; the narrower import is the more genuinely portable one for a library that must also work on Web) |
| `apps/comics-editor/lib/src/ui/lottie/lottie_import.dart` | Delete (moved) | → `libs/flutter_comics/lib/src/lottie/lottie_import.dart`, verbatim (`flutter/widgets.dart` for `Offset` + the two files above — confirmed portable, no `dart:io`/`EditorController`) |
| `apps/comics-editor/lib/src/ui/lottie/lottie_export.dart` | Delete (moved) | → `libs/flutter_comics/lib/src/lottie/lottie_export.dart`, verbatim (confirmed portable) |
| `apps/comics-editor/lib/src/bridge/models_mapping.dart` | Modify | Its `import '../ui/models.dart'` becomes `import 'package:flutter_comics/flutter_comics.dart'`; `comicsFromCore`/`comicsToCore` logic itself is UNCHANGED (still raw-JSON-merge, still lives in `apps/comics-editor` — it's coupled to the native-core bridge via `dart:io`'s `Platform.pathSeparator`, confirmed by grep, not part of the portable model) |
| `apps/comics-editor/lib/**` — 15 files import `models.dart` directly (`keyframe_interpolator.dart`, `sound_player.dart`, `controller.dart`, `edit_history.dart`, `lottie_export.dart`, `lottie_import.dart`, `editor_screen.dart`, `balloon_editor_card.dart`, `balloon_rail.dart`, `dialogs.dart`, `properties_panel.dart`, `scene_panel.dart`, `timeline.dart`, `top_bar.dart`, `viewer_workspace.dart` — exact list, verified by grep, supersedes v0.1's approximate "16 files"); 3 files import `models_mapping.dart` directly (`controller.dart`, `balloon_editor_card.dart`, `cutting_canvas.dart` — supersedes v0.1's approximate "6 files") | Modify | Import path updates only, no logic changes. The 5 files being *moved* (`models.dart`, `keyframe_interpolator.dart`, and the 3 Lottie files) drop out of this list once moved — their own former importers just get a new import path |
| `apps/comics-editor/lib/src/ui/widgets/lottie_import_dialog.dart`, `EditorController`'s Lottie methods in `controller.dart` (`pickLottieToImport`/`setLottieImportMode`/`setLottieScrollSpeed`/`setLottieEasingChoice`/`cancelLottieImport`/`commitLottieImport`/`exportLottieWithDialog`) | Modify (import path only) | **Do NOT move** — `file_picker`/`EditorScope`/`CoreDocument.tempFolder`/`writeTiles` (`dart:io`)-coupled UI glue, confirmed by reading their actual imports. Only their `import '.../lottie_import.dart'`-style paths change to the package |
| `libs/comics_viewer/flutter_comics_viewer/lib/src/dart_comics_viewer_backend.dart` | Modify (rewrite parsing internals) | Deletes `DartViewerAnimType`/`DartViewerAnim`/`DartViewerTile`/`DartViewerLayer`/`DartComicsDocument` and its own `_parseAnimation`/`_rebuild`; uses the shared package's model + new portable reader instead |
| `libs/comics_viewer/flutter_comics_viewer/lib/src/dart_comics_viewer_surface.dart` | Modify | Reads from the shared model's types instead of the deleted `DartViewer*` types (field names will differ — e.g. `EditorLayer.anims` vs. `DartViewerLayer.animations` — see Migration below); interpolation calls move from `DartViewerLayer`'s own copy to the shared `KeyframeInterpolator` |
| `libs/comics_viewer/flutter_comics_viewer/pubspec.yaml` | Modify | Add `flutter_comics` dependency (path dependency within the monorepo) |
| `apps/comics-editor/test/models_test.dart` | Delete (moved) | → `libs/flutter_comics/test/models_test.dart`. Confirmed by its actual imports: only `dart:ui` + `flutter_test` + `models.dart` — clean move |
| `apps/comics-editor/test/lottie_mapping_test.dart`, `lottie_import_test.dart`, `lottie_export_test.dart`, `lottie_commit_import_test.dart` | Delete (moved) | → `libs/flutter_comics/test/`. Confirmed by their actual imports: only `lottie_mapping.dart`/`lottie_import.dart`/`lottie_export.dart`/`models.dart` — clean move |
| `apps/comics-editor/test/lottie_roundtrip_test.dart` | Delete (moved), **contingent** | → `libs/flutter_comics/test/`, but its G3 case currently imports `models_mapping.dart` for one thing only: parsing a real `.comics` fixture (`comicsFromCore`) as its Full-Canvas-fixture-prep step. **Must be rewritten to use the new `ComicsArchiveReader` instead before it can move** — otherwise it's the one Lottie test with a real backwards dependency on `apps/comics-editor`. Sequencing note for Plan: this specific test can only move *after* `comics_reader.dart` exists |
| **`apps/comics-editor/test/models_mapping_test.dart`** | **Stays — v0.1 was wrong** | Tests `comicsFromCore`/`comicsToCore`'s raw-JSON-merge behavior, which stays in `apps/comics-editor/lib/src/bridge/models_mapping.dart` per this same table's row above. Moving this test would make `libs/flutter_comics` depend backwards on `apps/comics-editor`. Only its `import '.../models.dart'` line updates to the package path |
| **`apps/comics-editor/test/dataset_backward_compat_test.dart`** | **Stays — v0.1 was wrong** | Read directly: exercises `DartIoCore` + `comicsFromCore`/`comicsToCore`, both `apps/comics-editor`-specific (confirmed — imports `package:comics_editor/src/bridge/dart_io_core.dart` and `.../models_mapping.dart`, nothing else). Same backwards-dependency problem as above. No changes needed at all beyond whatever transitive `models.dart` type references already resolve via `models_mapping.dart`'s own updated import |
| **`apps/comics-editor/test/lottie_controller_test.dart`** | **Stays (new in v0.2)** | Tests `EditorController`'s file-picker/tempFolder-writing wiring (`commitLottieImport`, etc.) — inherently editor-specific, confirmed by its `controller.dart` import. Not a candidate; wasn't in v0.1 since this test didn't exist yet when v0.1 was drafted |
| `libs/comics_viewer/flutter_comics_viewer/test/dart_comics_viewer_backend_test.dart` | Delete (moved) | Relocates to `libs/flutter_comics/test/`, rewritten to assert against the full model's fields instead of the deleted minimal `DartViewer*` types |

## Architecture

### Component Diagram

```
Before:
  apps/comics-editor/lib/src/ui/models.dart  (rich model, no portable I/O)
       ^
       | import
  apps/comics-editor/lib/src/bridge/models_mapping.dart  (raw-JSON <-> model,
       ^                                                   native-core-coupled)
       | FFI
  [native core process -- owns real ZIP I/O for the editor]

  libs/comics_viewer/flutter_comics_viewer/lib/src/dart_comics_viewer_backend.dart
       (own minimal model + own portable ZIP+JSON reader, duplicated/incomplete)

After:
  libs/flutter_comics/lib/src/models.dart              (the same rich model, relocated)
  libs/flutter_comics/lib/src/keyframe_interpolator.dart (NEW in v0.2 -- the real cubic-ease-out
                                                            math, relocated verbatim)
  libs/flutter_comics/lib/src/lottie/lottie_mapping.dart (NEW in v0.2 -- portable .lottie ZIP+JSON,
                                                            relocated verbatim)
  libs/flutter_comics/lib/src/lottie/lottie_import.dart  (NEW in v0.2 -- ImportPreview/commitImport,
                                                            relocated verbatim)
  libs/flutter_comics/lib/src/lottie/lottie_export.dart  (NEW in v0.2 -- buildLottieExport,
                                                            relocated verbatim)
  libs/flutter_comics/lib/src/comics_reader.dart         (NEW -- portable .comics/.puzzle ZIP+JSON
                                                            reader, generalized from
                                                            dart_comics_viewer_backend's logic,
                                                            populates the full model)
       ^                                    ^
       | import                             | import
  apps/comics-editor/.../models_mapping.dart   flutter_comics_viewer/.../dart_comics_viewer_backend.dart
  (native-core raw-JSON <-> model,             (uses comics_reader.dart for real portable ZIP
   UNCHANGED logic, just new import)            opening; renders the shared model + KeyframeInterpolator
       ^                                         directly)
       | FFI
  [native core process -- unchanged]

  apps/comics-editor/.../lottie_import_dialog.dart, controller.dart's Lottie methods
  (UNCHANGED logic, just new import -- file_picker/tempFolder-coupled, stays here per
   01-requirements.md's Acceptance Criterion #7)
```

### Data Flow

```
apps/comics-editor (unchanged path): ZIP file -> native core -> raw JSON -> comicsFromCore()
    -> ComicsDoc/EditorLayer (from libs/flutter_comics) -> UI

flutter_comics_viewer (new path): ZIP bytes -> comics_reader.dart's own ZipDecoder+jsonDecode
    -> ComicsDoc/EditorLayer (from libs/flutter_comics, SAME classes editor uses)
    -> DartComicsViewerSurface renders directly from EditorLayer.anims/images, no separate
       DartViewerLayer translation step
```

## Interfaces

### New Interfaces

```dart
// libs/flutter_comics/lib/src/comics_reader.dart -- NEW, generalizes
// DartComicsViewerBackend.load()'s working ZIP-open logic to populate the FULL model
// (ComicsDoc/EditorLayer/Anim/LayerMask/TextRegion/etc.) instead of the deleted minimal subset.
class ComicsArchiveReader {
  /// Opens a `.comics`/`.puzzle` ZIP from bytes, decodes `data.json`, and returns
  /// a fully-populated [ComicsDoc] -- every field models.dart defines, not a subset.
  /// Read-only for now (see Requirements Open Question on write support).
  static Future<ComicsDoc> readBytes(Uint8List bytes);

  /// Convenience wrapper for platforms with real filesystem access
  /// (mirrors DartComicsViewerBackend's existing `readViewerPath` usage).
  static Future<ComicsDoc> readFile(String path);
}
```

```dart
// libs/flutter_comics/lib/flutter_comics.dart -- package's single public export surface
export 'src/models.dart';                 // ComicsDoc, EditorLayer, Anim, AnimType, AnimBasis,
                                           // LayerMask, TextRegion, LayerImage, EditorSound,
                                           // ScrollType, PreferredOrientation, DocType, RecentFile,
                                           // Lang, kLangs
export 'src/keyframe_interpolator.dart';  // KeyframeInterpolator (NEW in v0.2)
export 'src/lottie/lottie_mapping.dart';  // LottieDocument/LottieLayer/LottieAsset/LottieMask/
                                           // LottieTransform/LottieProperty/LottieKeyframe/
                                           // LottieFormatException, parseLottieDocument/
                                           // parseLottieJson/writeLottieDocument (NEW in v0.2)
export 'src/lottie/lottie_import.dart';   // ExportImportMode/ImportPreview/LayerPreview/
                                           // LayerPreviewStatus/EasingChoice/detectMode/
                                           // commitImport (NEW in v0.2)
export 'src/lottie/lottie_export.dart';   // buildLottieExport (NEW in v0.2)
export 'src/comics_reader.dart';          // ComicsArchiveReader (NEW)
```

### Modified Interfaces

- `apps/comics-editor/lib/src/bridge/models_mapping.dart`: only its `import` statement changes
  (`'../ui/models.dart'` → `'package:flutter_comics/flutter_comics.dart'`). `CoreDocument`,
  `comicsFromCore`, `comicsToCore`, and every private `_merge*`/`_animToJson`/`_maskToJson`/etc.
  helper are unchanged — they already operate purely in terms of the model types, which still exist
  with the same names, just imported from a different package.
- `libs/comics_viewer/flutter_comics_viewer`'s `ComicsViewerBackend` interface
  (`comics_viewer_backend.dart`) is unchanged at the abstract-interface level — `DartComicsViewerBackend`
  still implements it the same way, only its internal parsing/model types change.

## Data Models

### New Types

None beyond `ComicsArchiveReader` above — the data model types themselves are relocated, not
redesigned (per Requirements' "move, don't reinvent" constraint). `models.dart`'s existing classes
move as one file (`libs/flutter_comics/lib/src/models.dart`), `models_mapping.dart`'s helpers that
are genuinely about raw-JSON↔model conversion (not the native-core coupling) — `_animToJson`,
`_maskToJson`, `_textRegionToJson`, and their inverse parsing counterparts inside `comicsFromCore` —
are the natural basis for `comics_reader.dart`'s new per-field parsing, reused rather than
reimplemented, since they already handle every current schema field correctly (unlike
`DartComicsViewerBackend`'s parser, which only handles five of them).

### Schema Changes

None — this flow moves code, it does not change the `.comics`/`.puzzle` on-disk schema.

### Resolving Requirements' Open Question — editor-only fields on `EditorLayer`

**Recommendation**: move the whole `EditorLayer` class as-is, including `visible`/`size`/`swatch`
(editor-only UI state). Rationale: splitting it into a persisted-data class plus an editor-only
wrapper is real, non-trivial surgery across every one of the 16 files that import `models.dart` in
`apps/comics-editor` — out of proportion to what this flow is scoped to do (move files, not redesign
`EditorLayer`'s shape). `flutter_comics_viewer` simply never sets/reads those three fields; they
default harmlessly (`visible = true`, `size = 0.5`, a hardcoded `swatch` color) and cost nothing at
runtime for a viewer that ignores them. This can be revisited by a future flow if the editor-only
fields grow enough to justify the split — not blocking here.

### Resolving Requirements' Open Question — `DocType.puzzle`

**DECIDED (v0.3, confirmed directly by Anton)**: move the whole `models.dart` file, `.puzzle`
included. The alternative (splitting `.comics`-only classes out) would require duplicating
`EditorLayer`/`Anim`/`ComicsDoc` across two files/packages, which is exactly the duplication this flow
exists to eliminate — `.puzzle` isn't a separate class hierarchy, it's one `DocType` enum value plus
`ComicsDoc.scale`, sharing every other class. Checked directly (grep): no other file in the repo has
any `.puzzle`-specific format logic beyond `models_mapping.dart`'s one-line `isPuzzle` filename sniff
in `comicsFromCore`, which stays in `apps/comics-editor` anyway (that file doesn't move).

### Resolving Requirements' Open Question — write support

**Recommendation**: `ComicsArchiveReader` is read-only for this flow. No current consumer needs
standalone Dart-side ZIP writing: `apps/comics-editor` saves through the native core (unchanged path
above); `flutter_comics_viewer` is a viewer only. `sdd-flutter-comics-viewer-dart` (sibling flow) may
surface a real write need later (e.g. if a future macOS-native editor path is desired) — flagged
there, not solved speculatively here. **Note (v0.3)**: `apps/comics-editor/lib/src/bridge/
dart_io_core.dart` (the iOS fallback core) already has a real, working pure-Dart `.comics`/`.puzzle`
ZIP *writer* (`_saveComics`/`_zipWorkTo`, via `ZipFileEncoder`) — but it's disk/temp-folder-oriented
(`dart:io` + `path_provider`) and tightly coupled to `DartIoCore`'s own protocol, so it doesn't move
either; kept as a reference algorithm if real write support is ever needed here, not adopted now.

### Architecture boundary — rendering vs. format (re-verified per Anton's direct follow-up, v0.3)

**Rendering stays in `flutter_comics_viewer`; `flutter_comics` owns the file, its representations,
and import/export.** The one place this needed a concrete (not just stylistic) check: `lottie_export
.dart` calls `KeyframeInterpolator.translateAt` (confirmed via its own `import`) to sample a layer's
absolute position at export time. Since `lottie_export.dart` is unambiguously import/export logic
that belongs in `flutter_comics`, `KeyframeInterpolator` **must** live there too — otherwise
`flutter_comics` would depend on `flutter_comics_viewer` (a rendering *plugin*, backwards from every
other arrow in this design) or `lottie_export.dart` would need a second copy of the same math.
`KeyframeInterpolator` itself only computes property *values* (`List<Anim>` → position/scale/
rotation/alpha at a given point) — no widgets, no canvas, no gestures — so it fits "the file's own
representations" correctly despite its only current caller being a renderer. Confirmed nothing else
in `flutter_comics_viewer`'s own file list (`comics_viewer_controller.dart`/`_state.dart`/`_source
.dart`, `dart_comics_viewer_surface.dart`, the Windows PlatformView bridge, `source_bytes*.dart`) is
touched by this flow beyond a `.comics`-model import-path fixup — those are the real rendering layer,
untouched. Full reasoning: `01-requirements.md`'s v0.3 Addendum.

## Behavior Specifications

### Happy Path

1. `libs/flutter_comics/lib/src/models.dart` is created containing `models.dart`'s exact current
   content (file move), with only its `import '../i18n/language_registry.dart'` relative import
   needing a decision (see Edge Cases — `language_registry.dart` is editor-specific i18n, likely
   should NOT move; `models.dart`'s only use of it should be checked and probably removed/decoupled
   as part of the move, since a shared format library shouldn't depend on editor UI i18n).
2. `comics_reader.dart` is written new, reusing `models_mapping.dart`'s existing per-field JSON
   parsing helpers (adapted to work directly off a freshly-ZIP-decoded raw map instead of the
   native-core's raw map — same shape, different origin).
3. `apps/comics-editor`'s 16+6 importing files get import-path updates. `models_mapping.dart`'s own
   logic is untouched.
4. `flutter_comics_viewer`'s `dart_comics_viewer_backend.dart`/`dart_comics_viewer_surface.dart` are
   rewritten to use `ComicsArchiveReader` + the shared model directly — `DartViewerLayer.translateAt`
   /`scaleAt`/`rotateAt`/`alphaAt`'s interpolation logic (the real, working cubic-ease-out math) moves
   onto (or is called against) `EditorLayer`/`Anim` instead of the deleted `DartViewerLayer`, since
   that interpolation logic itself has no shared-model equivalent yet — it needs a new home, either
   inside `libs/flutter_comics` (if `sdd-flutter-comics-viewer-dart` also wants it) or staying in
   `flutter_comics_viewer` operating on the now-shared types. Cross-referenced to
   `sdd-flutter-comics-viewer-dart`'s own Specifications, since that flow owns the rendering/
   interpolation concern.
5. Four test files relocate; all pass unchanged in substance (import paths + type names updated
   only) except `dart_comics_viewer_backend_test.dart`, which is extended to assert the previously-
   dropped fields (`solidColor`/`mask`/`kind`/etc.) now round-trip.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| `models.dart`'s `import '../i18n/language_registry.dart'` | The file move | Must be checked: if `models.dart` only uses this for a `kLangs` constant or similar, that constant either moves too (if it's format-relevant, e.g. language ordering matches `LayerImage`'s per-language `images[]` index) or gets decoupled — a shared format library must not depend on `apps/comics-editor`'s i18n UI code. Not yet resolved which; flagged for Plan. |
| A real dataset file with `solidColor`/`mask`/`parentId` set, opened through the OLD `flutter_comics_viewer` parser (pre-this-flow) | Regression check during migration | Must render those fields once migrated — this is the concrete, testable proof the extraction fixed the real drift found during analysis |
| `flutter_comics_viewer` on Web (`kIsWeb`, per `comics_viewer.dart:57`) | Web also uses `DartComicsViewerBackend` today | `libs/flutter_comics` must not use `dart:io`/`dart:ffi` unconditionally (Web can't); `apps/comics-editor/lib/src/bridge/models_mapping.dart` already imports `dart:io` — confirm that stays in `models_mapping.dart` (editor-only, native-core-coupled) and does NOT leak into the relocated `models.dart`/new `comics_reader.dart`, which must be Web-safe |
| `apps/comics-editor` test suite, post-move | CI/local `flutter test` in `apps/comics-editor` | Must still pass with zero behavior change — this flow is a pure relocation for the editor side, verified by its existing (relocated) tests plus editor's own remaining suite |

### Error Handling

| Error | Cause | Response |
|-------|-------|----------|
| `data.json` missing from archive | Malformed/corrupt `.comics` file | `ComicsArchiveReader` throws `FormatException`, matching `DartComicsViewerBackend`'s existing behavior (preserved, not weakened) |
| Unknown `$type` discriminator on an `Anim` | Future/corrupt schema | Match `models_mapping.dart`'s existing tolerant behavior (`_animTypeFromDollarType` returns `null` → skip), not a hard crash |

## Dependencies

### Requires

- Nothing blocking — `apps/comics-editor` and `flutter_comics_viewer` both already exist and both
  already have working (if divergent) format-handling code to draw from.

### Blocks

- `flows/comics-viewer/sdd-flutter-comics-viewer-dart` — that flow's new macOS-first viewer work
  should build on `libs/flutter_comics`'s reader/model rather than extending
  `DartComicsViewerBackend`'s current duplicate one; sequencing this flow first avoids that flow
  doing throwaway work against code this flow is about to delete.

## Integration Points

### Internal Systems

- `apps/comics-editor`'s native-core FFI bridge (`sdd-comics-editor-ffi`) — consumed unchanged, only
  the Dart-side model it feeds relocates.
- `flows/comics-viewer/sdd-comics-viewer` — owns `flutter_comics_viewer`'s current Dart backend; this
  flow's changes to that package should be coordinated/disclosed there too (added to that flow's own
  `_status.md` Context Notes once Plan executes).

## Testing Strategy

### Unit Tests

- [ ] `libs/flutter_comics/test/models_test.dart` (relocated) — unchanged assertions, new import path
- [ ] `libs/flutter_comics/test/lottie_mapping_test.dart`, `lottie_import_test.dart`,
      `lottie_export_test.dart`, `lottie_commit_import_test.dart` (relocated, NEW in v0.2) —
      unchanged assertions, new import paths
- [ ] `libs/flutter_comics/test/comics_reader_test.dart` (new) — the new portable reader, round-
      tripping a synthetic in-memory archive covering every current schema field, not just the five
      `dart_comics_viewer_backend_test.dart` covered before

### Integration Tests

- [ ] `libs/flutter_comics/test/lottie_roundtrip_test.dart` (relocated, NEW in v0.2) — **contingent
      on `comics_reader.dart` existing first** (see Affected Systems above): its G3 case's fixture-
      prep step is rewritten to use `ComicsArchiveReader` instead of `comicsFromCore`
- [ ] `apps/comics-editor/test/models_mapping_test.dart`, `dataset_backward_compat_test.dart`
      (**stay in `apps/comics-editor`, corrected from v0.1** — see Affected Systems above) — re-run
      post-move with only their `models.dart` import path updated, zero behavior change expected
- [ ] `apps/comics-editor`'s full existing suite, re-run post-move, zero regressions
- [ ] `flutter_comics_viewer`'s full existing suite, re-run post-rewrite, zero regressions (beyond
      the intentional `dart_comics_viewer_backend_test.dart` extension above)

### Manual Verification

- [ ] Open a real dataset `.comics` file with `solidColor`/`mask` set in the macOS-targeted
      `flutter_comics_viewer` example app before/after this flow, confirm the "after" build no longer
      silently drops those fields (even if `sdd-flutter-comics-viewer-dart` hasn't yet added rendering
      support for them — the point here is the DATA survives parsing, not that it's drawn yet)

## Migration / Rollout

Single-shot relocation, not phased — Plan should sequence: (1) create `libs/flutter_comics` package
skeleton + move `models.dart` + `keyframe_interpolator.dart` + fix `models.dart`'s
`language_registry.dart` coupling, (2) move `models_test.dart` + update `apps/comics-editor` imports
(including `models_mapping_test.dart`/`dataset_backward_compat_test.dart`'s import-path-only fixups,
per the correction above), verify editor suite green, (3) move the 3 Lottie files +
`lottie_mapping_test.dart`/`lottie_import_test.dart`/`lottie_export_test.dart`/
`lottie_commit_import_test.dart`, update `apps/comics-editor`'s Lottie-UI imports
(`lottie_import_dialog.dart`, `controller.dart`), verify editor suite green again, (4) write
`comics_reader.dart` + its new test + move `lottie_roundtrip_test.dart` (now that
`comics_reader.dart` exists to fix its one contingent dependency), (5) rewrite
`flutter_comics_viewer`'s Dart backend/surface to consume the shared package + move/extend
`dart_comics_viewer_backend_test.dart`, verify viewer suite green. Each step should be independently
verifiable (matches this repo's established "one test at a time" discipline) rather than one large
simultaneous edit.

## Open Design Questions

- [x] **RESOLVED (v0.2)**: `KeyframeInterpolator`'s real cubic-ease-out formula (already the correct,
      tested, Swift/Java-v2012-confirmed implementation — not `DartViewerLayer`'s own separate,
      minimal copy, which gets deleted) moves into `libs/flutter_comics` alongside the model it
      operates on (`Anim`/`AnimType`/`AnimBasis`). It's a pure function of `List<Anim>` + a query
      position, with zero widget/gesture/rendering-surface involvement — exactly as portable and
      shared as the model itself, and resolving this here also resolves
      `sdd-flutter-comics-viewer-dart`'s own deferred version of the same question (see
      `01-requirements.md`'s Addendum). `flutter_comics_viewer`'s surface calls it directly instead of
      `DartViewerLayer.translateAt`/etc.
- [ ] Exact `libs/flutter_comics/pubspec.yaml` shape — plain Dart package vs. a Flutter package (the
      model classes currently import `package:flutter/widgets.dart` for `Offset`/`Color` — need to
      decide whether to keep that dependency or swap to `dart:ui` directly / a Flutter-free geometry
      type, since a "portable" library ideally shouldn't require the full Flutter SDK just for
      `Offset`). `keyframe_interpolator.dart` and `lottie_export.dart` both use plain `dart:ui`
      already (not `flutter/widgets.dart`) — only `models.dart` and `lottie_import.dart` pull in
      `flutter/widgets.dart` specifically for `Offset`/`Color`. Not resolved here — real decision for
      Plan.
- [ ] `language_registry.dart` coupling — **narrowed in v0.2**: confirmed by reading the file directly
      that the *only* real coupling is `EditorLayer.imageSlotFor`'s `LanguageRegistry` parameter type
      (`package:flutter/services.dart`'s `rootBundle`-based asset loader). See `01-requirements.md`'s
      new Open Question for the two candidate resolutions (extension method left behind vs. a plain
      callback signature) — not chosen yet, real decision for Plan.
- [ ] **NEW (v0.2)**: `EditorMode`/`EditorWorkspace`/`PropertiesTab` (pure editor-UI-state enums in
      `models.dart`, never persisted) — move with the file for consistency, or leave behind since no
      format concern touches them? See `01-requirements.md`'s new Open Question (leaning: leave
      behind, unlike the `.puzzle`/`EditorLayer`-field cases these aren't fields *on* a persisted type
      at all).
- [ ] **NEW (v0.2)**: `package:archive/archive_io.dart` → `package:archive/archive.dart` in
      `lottie_mapping.dart` — confirmed by grep that only `Archive`/`ZipDecoder`/`ArchiveFile`/
      `ZipEncoder` are used, none of `archive_io.dart`'s extra file-based IO helpers. Should switch to
      the narrower import when the file moves, for genuine Web-safety (Edge Cases already flags that
      `libs/flutter_comics` must not accidentally require `dart:io` — this is a real instance of that
      risk, found by checking the actual import, not assumed).

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-08
- [x] Notes: Approved as drafted (v0.3) — including the corrected Affected Systems table, the
      Interaction Interface section, the resolved interpolator-location question, and the `.puzzle`
      decision. Proceeding to Plan.
