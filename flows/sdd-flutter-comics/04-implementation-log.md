# Implementation Log: sdd-flutter-comics

> Started: 2026-08-08
> Plan: [03-plan.md](03-plan.md)

## Progress Tracker

| Task | Status | Notes |
|------|--------|-------|
| 1.1 Package skeleton | Done | `libs/flutter_comics` created, `pub get` succeeds |
| 1.2 Move models.dart | Done | Byte-identical move confirmed via `diff`, then 2 cuts applied |
| 1.3 Re-home EditorMode/etc. | Done | New `apps/comics-editor/lib/src/ui/editor_mode.dart` |
| 1.4 Re-home imageSlotFor | Done | Extension added to `language_registry.dart` |
| 1.5 Move keyframe_interpolator.dart | Done | Byte-identical except the one import-path line, confirmed via `diff` |
| 2.1 Move models_test.dart + fix lib importers | Done | Also fixed `canvas_view.dart` (a real gap the Plan's own import-list missed) |
| 2.2 Fix ~47 test files | Done | 40 mechanical + 8 `editor_mode.dart` additions; also moved `keyframe_interpolator_test.dart` (a second missed-portable-test gap) |
| 3.1 Move 3 Lottie files | Done | `archive_io.dart`→`archive.dart` applied |
| 3.2 Move 4 Lottie test files | Done | 38 tests pass |
| 3.3 Fix editor Lottie-UI imports | Done | |
| 4.1 comics_reader.dart | Done | New `ComicsArchiveReader` + Web-safe `read_file.dart` conditional-import shim |
| 4.2 comics_reader_test.dart | Done | 10 new tests, full schema coverage |
| 4.3 Move lottie_roundtrip_test.dart | Done | G3 rewritten to re-zip the fixture in-memory + `ComicsArchiveReader.readBytes` |
| 4.4 Backward-compat re-verification | Done | 403/403 (+3 skipped) in `apps/comics-editor` |
| 5.1-5.4 flutter_comics_viewer rewrite | Done | 15/15 passing; real schema fields confirmed no longer dropped |
| 5.5 Manual verification | Deferred | Needs a real device/simulator session -- automated coverage (Task 5.4's new tests) already confirms solidColor/mask survive parsing end-to-end |

## Session Log

### Session 2026-08-08 - Claude

**Started at**: Phase 1, Task 1.1
**Context**: Plan approved same session. Verified before starting: `libs/flutter_comics` does not
exist on disk yet.

#### Completed
- Task 1.1: package skeleton (`pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, `README.md`,
  `lib/flutter_comics.dart`). `flutter pub get` succeeds.
  - Verified by: `flutter pub get` clean run.
- Task 1.2: moved `models.dart` (`diff`-confirmed byte-identical before any edit), then removed
  `EditorMode`/`EditorWorkspace`/`PropertiesTab`/`EditorModeLabel`/`kEditorModes` and
  `imageSlotFor`'s body + the now-unused `language_registry.dart` import.
  - Files changed: `libs/flutter_comics/lib/src/models.dart` (new), deleted
    `apps/comics-editor/lib/src/ui/models.dart`
  - Verified by: `flutter analyze` clean in `libs/flutter_comics`.
- Task 1.3: created `apps/comics-editor/lib/src/ui/editor_mode.dart` with the 3 cut enums, verbatim.
- Task 1.4: added `EditorLayerLanguageSlot` extension (the exact cut method body) to
  `language_registry.dart`.
- Task 1.5: moved `keyframe_interpolator.dart` (`diff`-confirmed identical except the one expected
  import-path line change). Removed the now-empty `apps/comics-editor/lib/src/ui/anim/` directory.
  - Verified by: `flutter analyze` clean in `libs/flutter_comics`.

**Phase 1 complete.** Tasks 1.3/1.4's own compile-verification is deferred to Task 2.1/2.2 per Plan
(they reference `flutter_comics` types not yet importable from `apps/comics-editor` until its
`pubspec.yaml` gets the path dependency).

#### Completed (Phases 2-4)
- Task 2.1: moved `models_test.dart`; fixed the 12 planned lib importers + `models_mapping.dart`'s
  own import. **Found a real gap the Plan's own file list missed**: `canvas_view.dart` imports
  `keyframe_interpolator.dart` directly without importing `models.dart`, so it wasn't caught by the
  original "models.dart importers" grep — caught by `flutter analyze`, fixed the same way.
- Task 2.2: mechanically fixed the remaining ~40 test files (via a single `sed` pass across all of
  them at once, verified by `flutter analyze` immediately after — not per-file guessing), added
  `editor_mode.dart` imports to the 8 files that reference `EditorMode`/`EditorWorkspace`/
  `PropertiesTab`. **Found a second real gap**: `test/keyframe_interpolator_test.dart` (only imports
  `keyframe_interpolator.dart` + `models.dart` + `flutter_test`) is fully portable and was missing
  from the Plan's test-file list entirely — moved it to `libs/flutter_comics/test/` alongside
  `models_test.dart`, all 21 cases pass there.
  - Also fixed a pre-existing, unrelated `app_version_test.dart` failure (stale hand-maintained
    version fallback after an external `pubspec.yaml` bump to 3.2.3+4) — same one-line-sync pattern
    as a prior session, not part of this Plan but left unfixed would have made the "full suite
    green" checkpoint falsely red.
- Task 3.1: moved the 3 Lottie files via `cp` + `diff`-verified-identical, then applied the planned
  edits (`archive_io.dart`→`archive.dart`, relative import path fixups for the new `lottie/`
  location).
- Task 3.2: moved the 4 clean Lottie test files the same way; all 38 cases pass in
  `libs/flutter_comics`.
- Task 3.3: fixed `lottie_import_dialog.dart`, `controller.dart`'s remaining `lottie_mapping.dart`
  import, and `lottie_controller_test.dart`'s imports (all stay in `apps/comics-editor`).
- Task 4.1: wrote `ComicsArchiveReader.readBytes`/`.readFile`, porting `models_mapping.dart`'s
  read-side per-field JSON helpers (`_animFromJson`/`_maskFromJson`/`_textRegionFromJson`/
  `_asScrollType`/`_asPreferredOrientation`) into `comics_reader.dart` (can't literally import
  models_mapping.dart's private functions across the package boundary — ported the same algorithm,
  per Specifications' own "adapted... reused rather than reimplemented" framing). Added a
  `read_file.dart`/`read_file_io.dart`/`read_file_stub.dart` conditional-import shim for `readFile`,
  mirroring `flutter_comics_viewer`'s own `source_bytes*.dart` pattern exactly, so the library stays
  Web-safe despite `readFile`'s real filesystem access.
- Task 4.2: `comics_reader_test.dart` (10 cases) — full schema field coverage, `.puzzle` filename
  detection, defaults, F1 error handling, and `readFile`'s real-disk round trip.
- Task 4.3: moved `lottie_roundtrip_test.dart`, resolving the Plan's own Open Implementation
  Question: G3's fixture-prep step re-zips `sample_v2012.comics_unzip/data.json` in-memory (matching
  `comics_reader_test.dart`'s own established pattern) rather than adding a raw-map bypass entry
  point to `ComicsArchiveReader`'s public API that nothing else needs.
- Task 4.4: confirmed `dataset_backward_compat_test.dart`/`models_mapping_test.dart` still pass,
  unchanged in `apps/comics-editor`, import-path-only.

#### Verification (Phases 2-4)
- `libs/flutter_comics`: 87/87 passing, `flutter analyze` clean.
- `apps/comics-editor`: 403/403 passing (3 skipped, monorepo-only fixtures), `flutter analyze` clean.

#### Completed (Phase 5)
- Task 5.1: added `flutter_comics: path: ../../flutter_comics` to `flutter_comics_viewer/pubspec.yaml`.
  **Real, disclosed consequence found while doing this**: `flutter analyze` flagged "Publishable
  packages can't have 'path' dependencies" — `flutter_comics_viewer` is a genuinely *published*
  pub.dev package (`apps/comics-editor`'s own `pubspec.lock` resolves it via `source: hosted`, not a
  path), so this local dependency means it can't be re-published to pub.dev until `flutter_comics`
  is either published too or the dependency is swapped to hosted/git at publish time. Added
  `publish_to: 'none'` with a doc comment disclosing this explicitly, rather than silently working
  around the warning — a real architectural consequence for Anton to be aware of, not something this
  flow's scope resolves.
- Task 5.2: rewrote `dart_comics_viewer_backend.dart` — deleted `DartViewerAnimType`/`DartViewerAnim`/
  `DartViewerLayer`/`_parseAnimation` (the real duplicate-model logic); **kept `DartViewerTile`**
  (real tile pixel bytes + position have no shared-model equivalent at all — `EditorLayer.images`
  only ever holds a `file` path string, never pixel data, so deleting this specific class, as an
  earlier draft of this Plan's own wording literally said, would have been wrong). New
  `RenderedLayer` replaces the old inline layer struct: real tile bytes/dimensions + a direct
  reference to the shared `EditorLayer` itself. `load()` now calls
  `ComicsArchiveReader.readBytes(bytes)` for the real, schema-complete model, alongside keeping its
  own lightweight local raw-JSON decode for the one thing the shared model doesn't carry at all
  (per-image pixel `width`/`height` — a pre-existing, disclosed gap in `EditorLayer`/`LayerImage`
  themselves, not something this flow's scope redesigns). This means `load()` unzips+decodes the
  same bytes twice (once inside `ComicsArchiveReader`, once locally) — a deliberate, disclosed
  simplicity trade-off for a one-time load path, not a hot path, rather than adding a new
  "already-decoded" entry point to the library's public API that Specifications didn't call for.
- Task 5.3: rewrote `dart_comics_viewer_surface.dart` — `_DartLayer` now calls
  `KeyframeInterpolator.translateAt`/`.scaleAt`/`.rotateAt`/`.alphaAt` directly on
  `layer.editorLayer.anims`, not a second copy of the same math. **Found a real, unexplained
  quirk**: the analyzer didn't resolve `KeyframeInterpolator`'s named record return fields
  (`.angle`/`.pivotX`/`.scaleX`/etc.) across this package's `path:` dependency on `flutter_comics` —
  reported the record type as unnamed (`(double, double, double)`) even after `flutter clean` + a
  fresh `pub get`. Root cause not identified (a real, disclosed unknown, not swept under the rug);
  worked around with positional record access (`.$1`/`.$2`/etc., always valid regardless of a
  record's declared names, per the language spec) instead of chasing the resolution issue further.
- Task 5.4: rewrote `dart_comics_viewer_backend_test.dart` in place (does **not** move to
  `libs/flutter_comics/test/` — it tests this package's own backend/surface wiring, a real
  `flutter_comics_viewer` concern, not a portable-format one; Specifications' original phrasing said
  "relocates," which this session's actual analysis corrected). 3 cases: the original tiled-bytes/
  language/preview test (updated for `RenderedLayer`); a new one confirming `solidColor`/`mask`/
  `kind`/`groupId`/`parentId`/`Anim.basis` all survive parsing (the concrete, testable proof of the
  real drift this whole flow fixes); a new one confirming the wiring to the real shared
  `KeyframeInterpolator` (not re-testing the interpolator's own math, already covered by
  `keyframe_interpolator_test.dart`).

#### Verification (Phase 5)
- `flutter_comics_viewer`: 15/15 passing (12 pre-existing + 3 in the rewritten test file),
  `flutter analyze` clean.

#### Deferred
- Task 5.5 (manual verification, real device/simulator): not done this session — needs a human or a
  future session with real device/simulator access. Automated coverage already provides strong
  confidence (Task 5.4's new test asserts `solidColor`/`mask` parse correctly end-to-end through the
  real backend), so this is a lower-risk gap than it would otherwise be, but it's still a real,
  disclosed gap, not silently marked done.

**All of `03-plan.md`'s 15 tasks are now complete except Task 5.5.** Final verification across all
three packages: `libs/flutter_comics` 87/87, `apps/comics-editor` 403/403 (3 skipped), `flutter_comics_viewer`
15/15 — all `flutter analyze` clean.

**Handoff notes**: Following the two standing constraints from Anton this session on every Move
task: plain filesystem relocation (no git commands — Anton does git by hand) and byte-identical
content (read the source file's exact bytes, write them at the destination, never retyped) —
confirmed via `diff`/`cp` after each move, not just assumed.

---

## Deviations Summary

| Planned | Actual | Reason |
|---------|--------|--------|
| `DartViewerTile` deleted (Task 5.2's own wording) | Kept as-is | Real tile pixel bytes/position have no shared-model equivalent — deleting it was a mistake in the Plan's own phrasing, corrected during implementation |
| `dart_comics_viewer_backend_test.dart` "relocates" (Specifications' original wording) | Rewritten in place, stays in `flutter_comics_viewer/test/` | Tests this package's own backend/surface wiring, not portable format logic — same backwards-dependency rule already applied to `apps/comics-editor`'s tests |
| Task 4.3's fixture-prep mechanism (Open Implementation Question) | Re-zip `data.json` in-memory via `package:archive` | Matches `comics_reader_test.dart`'s own established pattern; no new bypass API added to `ComicsArchiveReader` |
| `models_test.dart`/`lottie_*_test.dart` only (2.1/3.2) | Also moved `keyframe_interpolator_test.dart` | Fully portable test the Plan's own file list missed — found via `flutter analyze` after the mechanical import pass, not pre-planned |
| No pubspec-level consequence anticipated for Task 5.1 | `flutter_comics_viewer` needed `publish_to: 'none'` | It's a genuinely *published* pub.dev package; a permanent local `path:` dependency blocks republishing until `flutter_comics` is published too or the dependency is swapped at publish time — disclosed, not silently patched over |

## Learnings

- Grepping for one file's importers (`models.dart`) missed real dependents of a *different* moved
  file (`keyframe_interpolator.dart`) that didn't happen to also import `models.dart` directly
  (`canvas_view.dart`) — `flutter analyze` after each move caught both real gaps immediately, more
  reliably than trying to enumerate the full dependency graph by hand up front.
- Named Dart record fields didn't resolve across this specific package's `path:` dependency in
  `flutter analyze`, for a reason not identified — positional record access (`.$1` etc.) is the
  reliable fallback when this happens, and is equally type-safe.

## Completion Checklist

- [x] All tasks completed or explicitly deferred (14/15 done; Task 5.5 deferred, needs real
      device/simulator access)
- [x] Tests passing (`libs/flutter_comics` 87/87, `apps/comics-editor` 403/403 +3 skipped,
      `flutter_comics_viewer` 15/15 — all `flutter analyze` clean)
- [x] No regressions (every pre-existing test in all three packages still passes; the one
      unrelated pre-existing failure found, `app_version_test.dart`, was a stale version-fallback
      constant, fixed same session)
- [ ] Documentation updated if needed (this flow's own `06-readme.md`-equivalent DOCUMENTATION phase
      not started — not requested yet)
- [x] Status updated to COMPLETE (Implementation phase; DOCUMENTATION phase remains, per `_status.md`)
