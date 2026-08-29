# Requirements: sdd-flutter-comics — shared `.comics` format library

> Version: 0.4
> Status: APPROVED
> Last Updated: 2026-08-09

## Origin

Anton, while starting `flows/comics-viewer/sdd-flutter-comics-viewer-dart` (a new Dart/Flutter
comics viewer for platforms beyond Android/iOS, macOS-first): "необходимо вынести общую часть из
comics-editor и comics-viewer обрабатывающую чтение и запись формата .comics. Именно переместить
файлы, а не изобретать с нуля... в новую библиотеку `libs/flutter_comics`... сделай отдельный sdd
sdd-flutter-comics, в нем сразу пропиши requirements и спецификации, но только после того как
сделаешь анализ кодовой базы. Так же вынеси туда тесты с этим связанные (именно перемести из тех
флоу сюда)." Requirements and Specifications are drafted together per that instruction, after the
codebase analysis below. The original documents and the v0.4 camera/depth addendum are approved;
the next gate is the v0.4 Plan addendum.

## Codebase Analysis (done before drafting, per instruction)

**Two independent, non-identical places currently touch `.comics` read/write in Dart:**

### 1. `apps/comics-editor/lib/src/ui/models.dart` (395 lines) + `apps/comics-editor/lib/src/bridge/models_mapping.dart` (533 lines)

This is the richer, more current data model — `ComicsDoc`, `EditorLayer`, `Anim`
(`AnimType`/`AnimBasis`), `LayerMask`, `TextRegion`, `LayerImage`, `EditorSound`, `RecentFile`, plus
the `ScrollType`/`PreferredOrientation`/`preferredViewportWidth`/`Height` document fields — i.e. the
real, up-to-date shape of `flows/tdd-dot-comics-format`'s decisions (`GroupId`, `ParentId`,
`solidColor`, `mask`, `kind`, `style`, `id` are all real fields on `EditorLayer` today, not just
requirements-doc proposals).

**Critical architectural fact, not obvious from the file names alone**: `models_mapping.dart` is
**not** a general-purpose `.comics` ZIP reader/writer. Its own doc comment says it plainly: it
converts between the *native core's* already-decoded raw JSON (`CoreDocument.raw`, produced by a
Windows-hosted native process reached via `apps/comics-editor/lib/src/bridge/` — the FFI bridge
`flows/comics-editor/sdd-comics-editor-ffi` built) and the UI's `ComicsDoc`/`EditorLayer` view
models — and, because the UI models don't represent every format field (e.g. per-image
`width`/`height`), the original raw JSON is kept alongside the document and *merged* back on save
(`comicsToCore`'s `_mergeLayer`/`_mergeImage`/`_mergeSound`), so fields the UI never touches survive
round-tripping. **The actual ZIP-archive opening/decoding and the actual file-write-back happen in
the native core, not in this Dart code.** `comicsFromCore`/`comicsToCore` never touch a ZIP archive
or the filesystem directly — they take/return a `Map<String, dynamic>` that something else already
produced/will persist.

### 2. `libs/comics_viewer/flutter_comics_viewer/lib/src/dart_comics_viewer_backend.dart` (383 lines)

This is the **only currently-real, portable, pure-Dart `.comics` ZIP+JSON reader** in the repo —
`DartComicsViewerBackend.load()` opens the archive directly with the `archive` package
(`ZipDecoder().decodeBytes(bytes)`), finds `data.json`, JSON-decodes it, and walks `raw['layers']`
itself. It defines its **own**, much smaller, renderer-only model classes — `DartViewerAnimType`,
`DartViewerAnim`, `DartViewerTile`, `DartViewerLayer`, `DartComicsDocument` — that duplicate only a
subset of what `EditorLayer`/`Anim`/`ComicsDoc` already model (translate/rotate/scale/alpha/sound,
`width`/`height`, tile file lookup) and know **nothing** about `solidColor`, `mask`, `kind`, `style`,
`parentId`, `groupId`, `id`, `scrollType`, `preferredOrientation`, `preferredViewportWidth`/`Height`,
or `Anim.basis` — every schema field the editor's model already has. Its own animation-type detection
even redundantly re-derives the `$type` discriminator logic that `models_mapping.dart` already has
(`_animTypeFromDollarType`/`_dollarTypeFromAnimType`), independently and slightly differently (string
`.contains('Rotate')` matching vs. an exact switch on the full `$type` string).

This backend already renders on macOS, Linux, and Web today (`comics_viewer.dart:55-59` routes those
platforms to it) via `DartComicsViewerSurface`. Windows uses a third, unrelated approach
(`WindowsComicsViewerBackend` — a method-channel bridge to a native WPF child window hosted by
Comics Editor itself, not a Dart-side parser at all). Android/iOS use the native
`comics-viewer-android`/`comics-viewer-ios` libraries via platform views.

### 3. Existing tests touching `.comics` format parsing (candidates to physically move, per instruction)

| File | Covers |
|---|---|
| `apps/comics-editor/test/models_test.dart` | `ComicsDoc`/`EditorLayer`/`Anim` model behavior (clone, defaults, id/parentId) |
| `apps/comics-editor/test/models_mapping_test.dart` | `comicsFromCore`/`comicsToCore` raw-JSON merge round-tripping |
| `apps/comics-editor/test/dataset_backward_compat_test.dart` | Opens every real dataset `.comics`/`.puzzle` file against the model — **this one DOES read real files off disk**, closest thing to a real-format-fixture test on the editor side |
| `libs/comics_viewer/flutter_comics_viewer/test/dart_comics_viewer_backend_test.dart` | `DartComicsViewerBackend.load()` — builds a synthetic ZIP in-memory, asserts tiled-bytes/language/preview-filtering/dimension parsing |

`comics_viewer_controller_test.dart`, `comics_viewer_method_channel_test.dart`,
`comics_viewer_widget_test.dart` (the other three files in `flutter_comics_viewer/test/`) test
controller/method-channel/widget plumbing, not format parsing — **not** candidates to move.

### 4. Prior art already in the repo (must be reconciled, not silently duplicated)

- `flows/comics-viewer/sdd-flutter-comics-viewer/` — a prior flow (drafted 2026-07-19) whose own
  `_status.md` is internally titled "sdd-flutter-comics" and already targets `libs/flutter_comics/`
  for a migrated Java/Swift-v2012-derived rendering library. Its `_status.md` claims Requirements/
  Specs/Plan approved and "Implementation started (Phase 1: Setup & Configuration)," but
  `01-requirements.md`'s own header still says `Status: DRAFT` with an unchecked Approval section,
  and **nothing was ever created on disk at `libs/flutter_comics/`** — the two records disagree, and
  disk state confirms nothing shipped. That flow's scope (a *full rendering* plugin: `LayersView`,
  `TileImageView`, tile LOD, audio playback, gestures) is broader than this flow's scope (format
  read/write only) — see "Relationship to sibling flows" below for how the two are being separated
  now.
- `flows/comics-viewer/sdd-comics-viewer/` — the actively-worked, IN_PROGRESS flow (`_status.md`
  last touched 2026-08-05 "by Codex") that is the real origin of `flutter_comics_viewer`'s current
  Dart backend/Windows-bridge code (its own Phase 4/5 cover "Flutter Wrapper"/"React Native
  Wrapper"). This flow's extraction work will modify files that flow owns — flagged as a real
  cross-flow dependency, not assumed away.

## Addendum (v0.2, 2026-08-08): Bodymovin import/export scope + full flow survey

Anton: "Прочитай каждый sdd, vdd, tdd флоу и проведи глубокий анализ. Дай интерфейс взаимодействия и
полный список файлов который будешь перемещать. Так же включи в перемещение все связанное с bodymovin и
импортом/экспортом" — read every flow, give the interaction interface and full file list, and
explicitly include everything Bodymovin-related in the move.

**Every flow in `flows/` was read** (not just the ones already cited). Full survey results, including
exact file paths, statuses, and cross-references, are folded into this document and
`02-specifications.md` below. Two genuinely new things came out of this pass:

1. **`apps/comics-editor/lib/src/bridge/bodymovin_mapping.dart`, `.../lib/src/ui/bodymovin/bodymovin_import.dart`,
   `.../lib/src/ui/bodymovin/bodymovin_export.dart`, and `.../lib/src/ui/anim/keyframe_interpolator.dart` are
   now in scope for the move** — all four were checked directly against their real `import` statements
   and confirmed portable (no `dart:io`, no FFI, no `EditorController`/`file_picker` coupling). They
   were missed in v0.1 because `flows/comics-editor/tdd-dot-bodymovin-import-export` (which created the
   three Bodymovin files) wasn't in the original codebase analysis, and `keyframe_interpolator.dart` is
   the exact real answer to v0.1's own "where does DartViewerLayer's interpolation math end up" framing
   — it already exists, is already the tested, correct cubic-ease-out formula, and is already portable.
2. **`flows/comics-viewer/sdd-flutter-comics-viewer-dart` is a real, already-drafted, hard *downstream*
   dependent of this flow**, not just a sibling — its own Requirements state this flow must reach at
   least Plan-approved before its Plan can lock in interfaces, and its Acceptance Criterion #4 requires
   deleting `DartViewerAnim`/`DartViewerLayer`/`DartComicsDocument` in favor of this library's model.
   This flow should be sequenced (and communicated) as a genuine prerequisite, not just "related work."

### New User Story

**As** the author of `flows/comics-editor/tdd-dot-bodymovin-import-export` (`.Bodymovin` import/export, now
IMPLEMENTATION-complete in `apps/comics-editor`)
**I want** the portable Bodymovin parsing/import/export logic and the keyframe interpolator moved into
`libs/flutter_comics` alongside the `.comics` model
**So that** any future Dart-based consumer (the viewer, a future macOS-native editor) gets real
`.Bodymovin` import/export and correct animation playback for free, instead of a third duplicate.

New/revised acceptance criteria for this addendum are now numbered #7-9 in the main
"## Acceptance Criteria" → "Must Have" list below, alongside the original #1-6 (kept together in one
place rather than split across two document sections). `.puzzle`'s own criterion is #2 (revised) and
#10's worth of content is folded into #2/#3 rather than a separate number, since it's really just a
clarification of what "the model" includes.

## Relationship to other flows (full survey, 2026-08-08)

Every flow under `flows/` was read for this pass. Summary of the ones with real bearing on this
flow's scope (full per-flow detail is in the survey notes kept alongside this session):

- **`flows/comics-editor/tdd-dot-bodymovin-import-export`** (IMPLEMENTATION complete, 480/480 tests) —
  created the three Bodymovin files above and the `.comics` schema fields they depend on
  (`EditorLayer.groupId`, `.textRegion`/`TextRegion`, `ComicsDoc.preferredViewportWidth`/`Height`).
  Not cited in v0.1's codebase analysis; now the direct source of the Bodymovin move-candidates.
- **`flows/comics-editor/vdd-comics-editor-scroll`** — created `keyframe_interpolator.dart` (scroll-
  basis). **`flows/tdd-dot-comics-format`** — extended it with time-basis composition, and added most
  of the schema fields currently on `EditorLayer`/`ComicsDoc` (`id`, `parentId`, `kind`, `scrollType`,
  `preferredOrientation`, `solidColor`, `mask`, `Anim.basis`/`.loop`). **`flows/comics-editor/
  vdd-comics-editor-uiux-lettering`** added `kind`/`style`/`translations`. All three are IMPLEMENTATION
  complete and are why the model being moved is schema-complete — this flow moves their combined
  output, not any one of their individual deltas.
- **`flows/comics-viewer/sdd-flutter-comics-viewer-dart`** (REQUIREMENTS, drafting) — a **hard
  downstream dependent**: its own Requirements state it's blocked on this flow reaching at least
  Plan-approved, and its Acceptance Criterion #4 requires deleting `flutter_comics_viewer`'s current
  duplicate model (`DartViewerAnim`/`DartViewerLayer`/`DartComicsDocument`) in favor of this library's.
  It also defers its own interpolator-location question to whichever of the two flows' Plans lands
  first — resolved here (see Acceptance Criterion #8).
- **`flows/comics-viewer/sdd-comics-viewer`** (IMPLEMENTATION, in progress) — owns
  `flutter_comics_viewer`'s current Dart backend (`dart_comics_viewer_backend.dart`/`_surface.dart`),
  the files this flow's Plan will modify. A real cross-flow dependency, not yet actioned (add a note to
  that flow's own `_status.md` once this flow's Plan is approved).
- **`flows/comics-viewer/sdd-flutter-comics-viewer`** (no `-dart` suffix) — stale, superseded, already
  disclosed as split into this flow + `sdd-flutter-comics-viewer-dart`. No action needed.
- **`flows/_archive/sdd-flutter-puzzle-viewer`** — an older, archived flow for a `flutter_puzzle`
  library that explicitly planned to *depend on* a `flutter_comics` library for rendering `.comics`
  content inside puzzle pieces. Confirms real prior intent for this exact package name/shape, and is a
  reason to keep the public API consumer-agnostic (not editor- or single-viewer-specific) even though
  no active flow currently claims that dependency.
- **`flows/comics-editor/sdd-comics-ai-baloons`** (a `comics-ai` flow, Python) — proposed the
  `Layer.TextRegion` schema field explicitly designed to map onto Bodymovin's vector-mask model; already
  implemented for real by `tdd-dot-bodymovin-import-export`, so no separate action needed here beyond
  confirming `TextRegion` is included in the model move (it is — it's a class in `models.dart`).
- All `flows/comics-ai/*` and `flows/comics-backend/*` flows are Python/Node backend or AI-pipeline
  work that reads `.comics` output or the native C# model as read-only ground truth — none touch, move,
  or need updating for this flow's Dart-side extraction.

## Addendum (v0.3, 2026-08-08): `.puzzle` decided; architecture-boundary re-verification

Anton: "Кстати, работу с .puzzle тоже перемести сюда... Давай еще раз убедимся, что рендеринг логика
именно в flutter_comics_viewer, а во flutter_comics — работа с самим файлом его представлениями, и так
же импортами и экспортами. flutter_comics_viewer тоже будет использовать работу с .comics файлом
именно отсюда и не будет двойного кода" — move `.puzzle` here too; re-confirm rendering logic lives in
`flutter_comics_viewer` while `flutter_comics` handles the file itself, its representations, and
import/export; `flutter_comics_viewer` must use this library's `.comics` handling, not a duplicate.

### `.puzzle` — DECIDED, no longer an Open Question

Checked directly (grep across `models.dart`/`models_mapping.dart`): `.puzzle` has **no separate class
hierarchy at all** — it's exactly one `DocType.puzzle` enum value plus `ComicsDoc.scale` ("puzzle zoom
(0.125..1)"), sharing every other class (`EditorLayer`, `Anim`, etc.) with `.comics`. The only other
`.puzzle`-aware line in the whole codebase is `models_mapping.dart`'s
`isPuzzle = name.endsWith('.puzzle')` filename sniff inside `comicsFromCore` — which stays in
`apps/comics-editor` anyway (that file doesn't move, per Acceptance Criterion #5). **Moving
`models.dart` as one file, already Acceptance Criterion #2's plan, already moves 100% of the real
`.puzzle` logic that exists.** This resolves v0.1's Open Question — Requirements now states this as
decided, not leaning: `DocType.puzzle` and `ComicsDoc.scale` move with the rest of `models.dart`,
unconditionally.

Also checked: none of the three archived puzzle-editor/viewer flows
(`flows/_archive/sdd-flutter-puzzle-editor-ffi`, `-pview`, `-viewer`) ever produced real code on disk
(confirmed archived/abandoned in the earlier survey) — there is no separate `.puzzle`-format parsing
logic anywhere else in the repo to fold in. `flutter_comics_viewer` itself has zero `.puzzle`-related
code today (grep confirms) — `.puzzle` support only exists inside `apps/comics-editor` as an *editing*
feature today, not a viewer one; that doesn't change here.

### Architecture boundary — re-verified, with one concrete reason it must hold

**Rendering logic (widgets, canvas painting, gestures, tile-LOD, sound *playback*, the
viewer's own controller/state) stays entirely in `flutter_comics_viewer`.** None of the following move
or get touched by this flow beyond their one `.comics`-model import-path fixup:
`comics_viewer_controller.dart`, `comics_viewer_state.dart`, `comics_viewer_source.dart`,
`comics_viewer.dart`, `dart_comics_viewer_surface.dart` (the widget that actually paints layers), the
Windows PlatformView bridge, `source_bytes*.dart`. `dart_comics_viewer_backend.dart` is the one file
that changes *internally* (deletes its own duplicate model, calls the shared reader) — but it doesn't
become part of `flutter_comics`, it stays a `flutter_comics_viewer` file that *depends on* the library.

**`flutter_comics` handles the file itself, its representations, and import/export — confirmed, with
one concrete dependency that makes this non-negotiable, not just a style preference**: `bodymovin_export
.dart` (explicitly named by Anton as import/export work that belongs here) **already has a real, hard,
shipped dependency on `KeyframeInterpolator`** — `_localPositionAt`/`_sceneMemberToBodymovin` call
`KeyframeInterpolator.translateAt` to sample a layer's true absolute position at export time (checked
directly: `bodymovin_export.dart`'s own `import '../anim/keyframe_interpolator.dart'`). If the
interpolator stayed in `flutter_comics_viewer` instead, one of two bad things would happen: either
`flutter_comics` (the format/import-export library) would need to depend on
`flutter_comics_viewer` (the rendering *plugin*, pulling in platform channels/widgets a headless
import/export consumer has no use for) — backwards from every other dependency arrow in this design —
or `bodymovin_export.dart` would need its own second copy of the interpolation formula, recreating the
exact kind of duplication this whole flow exists to eliminate. `KeyframeInterpolator` itself is a pure
`List<Anim>` → position/scale/rotation/alpha **value** function — it computes what a layer's current
*representation* is at a given scroll/time position, it does not paint anything, subscribe to
gestures, or touch a canvas. That's why it correctly belongs to "the file's own representations," not
to "rendering," even though its only real-world consumer today happens to be a renderer.

**No duplicate `.comics` parsing code**: confirmed by design (Specifications' Affected Systems table)
— `dart_comics_viewer_backend.dart`'s own `DartViewerAnimType`/`DartViewerAnim`/`DartViewerTile`/
`DartViewerLayer`/`DartComicsDocument` are **deleted**, not kept alongside the shared model. Once this
flow lands, `flutter_comics_viewer` has exactly one `.comics` parser in its entire dependency graph —
`ComicsArchiveReader`, from `flutter_comics` — matching Anton's explicit "не будет двойного кода."

### Incidental finding, not changing the plan: `DartIoCore` already has a real Dart ZIP writer

While re-checking the write-support Open Question, `apps/comics-editor/lib/src/bridge/
dart_io_core.dart` (the iOS-only, non-native-core fallback, per `sdd-comics-editor-v2.9-android-ios`)
turned out to already implement a *real, working* `.comics`/`.puzzle` ZIP writer in pure Dart
(`_saveComics`/`_zipWorkTo`, via `package:archive`'s `ZipFileEncoder`) — not just the read path. It's
disk/temp-folder-oriented (`dart:io` `Directory`/`File`, plus `path_provider` for
`getApplicationSupportDirectory`) rather than the in-memory bytes-in/bytes-out shape
`ComicsArchiveReader` needs, and it's tightly coupled to `DartIoCore`'s own `ComicsCore` protocol
(`ping`/`openComics`/`saveComics`/`exportPackage`) — so it does **not** move, and the read-only
recommendation for `ComicsArchiveReader` still stands for now. Noted here only because it's the
concrete algorithm to adapt if/when real Dart-side `.comics` *writing* is ever needed by
`flutter_comics` — not invented from scratch, should this become a real requirement later.

## Addendum (v0.4, 2026-08-09): shared camera-path and z-depth support

The implemented v0.3 library predates the now-concrete camera contract: its current
`EditorLayer` has no `zDepth`, `ComicsDoc` has no `cameraPath`, and `ComicsArchiveReader` parses
neither. `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-bodymovin` now supplies a real producer and
real non-uniform source data; `flows/tdd-dot-comics-format` v0.11/v0.8 defines the portable schema
and response math. The shared model must adopt that contract so editor/viewer code does not create
new duplicate camera models or platform-specific formulas.

The boundary stays the same as v0.3: `flutter_comics` owns persisted types, tolerant parsing and
canonicalization, cloning, camera-path sampling/interpolation, and depth normalization/response
primitives. `flutter_comics_viewer` owns active/inert traversal selection and the total render
composition; `apps/comics-editor` owns editing UI and its native-core merge/save bridge. Final
format semantics are defined only by `flows/tdd-dot-comics-format/03-specifications.md`.

### New User Stories

**As** a viewer/editor implementer, **I want** `CameraPath`, `CameraKeyframe`, and `zDepth` in the
shared model and public package API, **so that** each platform does not invent its own schema or
parallax convention.

**As** a reader of legacy content, **I want** an absent/inert camera path to preserve ordinary
traversal and absent depth to normalize like explicit zero, **so that** upgrading
`flutter_comics` preserves existing documents.

**As** an import pipeline, **I want** one deterministic camera sampler and depth-response function,
**so that** a Bodymovin-derived path can be validated before any viewer UI is involved.

### v0.4 Acceptance Criteria (additional Must Haves)

10. **Given** a `.comics` root with `cameraPath` and layers with `zDepth`, **when**
    `ComicsArchiveReader` reads it, **then** the full typed values survive parsing and cloning;
    fewer than two valid canonical camera positions are inert, and absent/explicit-zero depth
    normalize identically.
11. **Given** valid camera points and any valid depth (`zDepth > -1`), **when** the shared evaluator
    is called at a scroll coordinate, **then** it returns the sampling/interpolation and normalized
    depth-response primitives required by `tdd-dot-comics-format/03-specifications.md`, without
    widgets, platform channels, device pixels, or orientation APIs.
12. **Given** invalid depth (`<= -1` or non-finite), unordered/duplicate camera points, or malformed
    point values, **when** the portable reader/evaluator handles them, **then** it follows the
    format's tolerant normalization/fallback rules and never produces `NaN`/infinite transforms.
13. **Given** the editor's native-core merge path, **when** a camera/depth document is opened,
    edited, cloned/undo-redone, and saved, **then** `cameraPath` and every layer's `zDepth` are
    preserved; this addendum may extend mapping for the new fields but must not redesign ZIP/FFI I/O.
14. **Given** phone, tablet, desktop, and Web consumers at the same document scroll coordinate,
    **when** they use `flutter_comics`'s evaluator, **then** they receive the same document-space
    camera sample and normalized depth response. Final composition and viewport scaling remain the
    rendering surface's responsibility under the canonical format specification.

### v0.4 Scope Boundary

- Included: shared types, clone behavior, portable read support, editor bridge round-trip, public
  exports, canonicalization, sampling/interpolation, depth-response primitives, and automated
  contract tests.
- Excluded: applying the result in a viewer widget, editor controls/visualization for camera/depth,
  reconstructing a path from Bodymovin, and changing platform orientation/scroll UX. Those belong to
  their respective viewer, VDD, and importer flows.

## Problem Statement

`.comics` format read/write logic is split across two Dart codebases that don't share a model:
`apps/comics-editor` has the schema-complete model but no portable ZIP reader (it depends on a
Windows-only native core for that); `flutter_comics_viewer` has the only portable ZIP reader but a
schema-incomplete, duplicate model. Every schema addition (this repo adds one every few days per
`flows/tdd-dot-comics-format`'s history) currently has to be manually re-applied to
`flutter_comics_viewer`'s parser to avoid silently dropping data for any viewer that isn't backed by
the native core — nothing enforces this today, and evidence above shows it has already drifted
(`solidColor`/`mask`/`kind`/etc. are all absent from the viewer's parser).

## User Stories

**As** the developer maintaining `tdd-dot-comics-format`'s schema decisions
**I want** one Dart model + one portable reader/writer for `.comics`
**So that** a new field only needs to be added once, and every consumer (editor UI, any Dart-based
viewer) sees it automatically instead of silently ignoring it.

**As** the author of `flows/comics-viewer/sdd-flutter-comics-viewer-dart` (new cross-platform Dart
viewer, macOS-first)
**I want** a real, standalone, portable `.comics` ZIP+JSON reader with the FULL schema (not the
current renderer-only subset)
**So that** the new viewer can render `solidColor`/`mask`/`kind`-aware content and doesn't need its
own third copy of the model.

**As** the maintainer of `apps/comics-editor`
**I want** `models.dart`'s data classes moved, not copied, into the shared library
**So that** the editor's own model stays the single source of truth it already is today, just
relocated — no behavior change to the editor's native-core-backed save/load path.

## Acceptance Criteria

### Must Have

1. **Given** `libs/flutter_comics` after this work, **when** its `pubspec.yaml` is inspected,
   **then** it is a standalone Dart (not necessarily Flutter-plugin) package with no dependency on
   `apps/comics-editor`'s native-core FFI bridge — the shared library must not require a Windows
   native process to function, since `flutter_comics_viewer` needs it on macOS/Linux/Web too.
2. **Given** `EditorLayer`/`Anim`/`ComicsDoc`/`LayerMask`/`TextRegion`/etc. (`DocType.puzzle` and
   `ComicsDoc.scale` included, unconditionally — v0.3 decided this, not just `.comics`-only classes),
   **when** they are moved into `libs/flutter_comics`, **then** they are moved (relocated + `import`
   paths updated), not rewritten from scratch — per Anton's explicit "именно переместить файлы, а не
   изобретать с нуля."
3. **Given** the test files cataloged in `02-specifications.md`'s Affected Systems table, **when**
   this flow's Plan executes, **then** exactly the ones confirmed portable by their own real imports
   move into `libs/flutter_comics/test/` (updated only for import paths, continue passing); the ones
   confirmed to test logic that stays in `apps/comics-editor` (`models_mapping_test.dart`,
   `dataset_backward_compat_test.dart`, `bodymovin_controller_test.dart`) stay there too — moving them
   would make the shared library depend backwards on the app.
4. **Given** `flutter_comics_viewer`'s `DartComicsViewerBackend`, **when** this work completes,
   **then** it consumes the shared library's model/reader instead of its own
   `DartViewerAnim`/`DartViewerLayer`/`DartComicsDocument` classes — the duplicate parsing logic is
   deleted, not kept alongside the shared one, and `KeyframeInterpolator` (also relocated, criterion
   #8) is called directly instead of `DartViewerLayer`'s own separate copy of the same formula.
5. **Given** `apps/comics-editor`'s existing native-core-backed save/load flow, **when** the model
   classes move to `libs/flutter_comics`, **then** `comicsFromCore`/`comicsToCore`'s raw-JSON-merge
   behavior is unchanged — this flow relocates the data model, it does not redesign the editor's FFI
   integration.
6. **Given** a real `.comics` file exercising every current schema field (`solidColor`, `mask`,
   `kind`, `style`, `parentId`, `groupId`, `scrollType`, `preferredOrientation`,
   `preferredViewportWidth`/`Height`, `Anim.basis`), **when** it's opened through the shared
   library's own ZIP+JSON reader (the new, portable one — see Open Questions), **then** every field
   round-trips, unlike today's `flutter_comics_viewer` parser which silently drops all of them.
7. **Given** `apps/comics-editor/lib/src/bridge/bodymovin_mapping.dart`,
   `.../lib/src/ui/bodymovin/bodymovin_import.dart`, `.../lib/src/ui/bodymovin/bodymovin_export.dart`, **when**
   they move into `libs/flutter_comics`, **then** they move as-is — `bodymovin_import_dialog.dart` and
   `EditorController`'s Bodymovin methods do **not** move (`file_picker`/tempFolder-coupled UI glue, not
   portable format logic; would violate criterion #1).
8. **Given** `apps/comics-editor/lib/src/ui/anim/keyframe_interpolator.dart`, **when** it moves into
   `libs/flutter_comics`, **then** it resolves both this flow's own interpolator-location question
   and `sdd-flutter-comics-viewer-dart`'s deferred one — and, per the v0.3 Addendum's concrete
   dependency check, it is architecturally required here anyway, since `bodymovin_export.dart` already
   depends on it and moving it to `flutter_comics_viewer` instead would create a backwards
   library→plugin dependency or a duplicate copy.
9. **Given** `apps/comics-editor/test/models_mapping_test.dart` and
   `.../dataset_backward_compat_test.dart`, **when** this flow's Plan executes, **then** they stay in
   `apps/comics-editor/test/` (correcting Specifications v0.1's original relocation proposal) — both
   test `models_mapping.dart`'s logic, which per criterion #5 stays in `apps/comics-editor` unchanged.

### Should Have

- A single shared library `pubspec.yaml` version/SDK constraint compatible with both consumers'
  current constraints (`apps/comics-editor`: `sdk: ^3.12.2`; confirm `flutter_comics_viewer`'s
  matches — both observed identical during analysis).
- Existing `dataset_backward_compat_test.dart`-style real-file coverage extended to also exercise the
  new portable reader against the same real dataset files, not just the editor's raw-JSON-merge path.

### Won't Have (This Iteration)

- No change to `apps/comics-editor`'s native-core FFI architecture itself (`sdd-comics-editor-ffi`'s
  domain) — this flow only relocates the Dart-side data model that architecture already produces/
  consumes.
- No change to rendering logic (`LayersView`/`TileImageView`-equivalent widgets, tile LOD, gestures,
  sound playback) — that's `sdd-flutter-comics-viewer-dart`'s scope, which will *depend on* this
  library's model/reader once it exists. **Revised in v0.2**: the interpolation *math itself*
  (`KeyframeInterpolator` — pure `List<Anim>` → position/scale/rotation/alpha evaluation, no
  widgets/gestures involved) does move here (Acceptance Criterion #8) — it's exactly as portable and
  shared as the model it operates on; only the widgets/surface that *call* it stay with the viewer.
- No decision here about `flows/comics-viewer/sdd-flutter-comics-viewer/`'s (the stale prior flow)
  own disposition beyond disclosure — see that flow's own `_status.md` for the note added alongside
  this work.

## Constraints

- **Must move, not reinvent**: per Anton's explicit instruction, the data model classes and their
  associated tests must be relocated (git `mv`-equivalent + import fixups), not rewritten from a
  blank file. The one genuinely NEW piece of code this flow needs — a portable ZIP+JSON
  reader/writer for the *full* model (see Open Questions) — should itself be adapted/generalized from
  `DartComicsViewerBackend.load()`'s already-working `archive`-based logic, not invented independently
  either.
- **No native-core dependency**: the shared library must be usable from a pure-Dart/Flutter context
  with no platform channel, no Windows-only process — this is the whole reason
  `flutter_comics_viewer` couldn't just depend on `apps/comics-editor`'s existing mapping code
  directly.
- **Backward compatibility**: every real dataset `.comics`/`.puzzle` file must continue to open
  identically through both consumers after the move (verified by the relocated
  `dataset_backward_compat_test.dart` plus the existing `dart_comics_viewer_backend_test.dart`,
  updated to assert against the full model instead of the minimal one).

## Open Questions

- [ ] **Does the shared library need its own portable ZIP+JSON writer (save), or read-only?**
  `apps/comics-editor` saves via the native core (`comicsToCore` merges into raw JSON the core then
  persists); `flutter_comics_viewer` today never saves at all (it's a viewer, read-only). If nothing
  needs standalone Dart-side *writing* of a `.comics` ZIP yet, the shared library's new portable
  reader could be read-only for now, with `comicsToCore`'s merge-based writer staying in
  `apps/comics-editor` as-is (it's inherently coupled to the native-core round-trip, not something to
  generalize). Leaning read-only-for-now, but flagging since it changes scope.
- [x] **RESOLVED (v0.3)** — `ComicsDoc.DocType.puzzle`: moves with the rest of `models.dart`,
  unconditionally. Confirmed by Anton directly ("работу с .puzzle тоже перемести сюда") and by code
  inspection: `.puzzle` is one enum value + one shared field (`ComicsDoc.scale`), not a separate class
  hierarchy — there is nothing to split out even if someone wanted to. See v0.3 Addendum above.
- [ ] **Editor-only fields inside `EditorLayer`** (`visible`, `size` "fraction of page width, for the
  placeholder swatch", `swatch` `Color`) are in-memory UI state, not part of the persisted `.comics`
  JSON. Do these move too (simplest, matches "move the whole class," but leaks editor-UI concepts
  into a shared library `flutter_comics_viewer` doesn't need), or does the move require first
  splitting `EditorLayer` into a persisted-data class + an editor-only wrapper? The former is less
  work and matches "move files, don't reinvent"; the latter is architecturally cleaner. Flagging for
  Specifications to resolve with a concrete recommendation.
- [ ] Package name/location: `libs/flutter_comics` (exact name Anton specified) — Dart package name
  inside `pubspec.yaml` (`flutter_comics`?) needs confirming doesn't collide with anything on pub.dev
  given `publish_to: 'none'` conventions already used by sibling packages.
- [ ] **NEW (v0.2)**: `models.dart` also defines `EditorMode`, `EditorWorkspace`, `PropertiesTab` —
  pure editor-UI-state enums (their own doc comments say "never persisted"), unlike `ScrollType`/
  `PreferredOrientation` which ARE persisted format fields. Do these move with the rest of the file
  (consistent with the "move the whole file, don't split" principle already applied to `.puzzle` and
  `EditorLayer`'s `visible`/`size`/`swatch`), or get left behind in `apps/comics-editor` since no
  format concern needs them? Leaning toward moving them too, for the same consistency reason — but
  unlike `visible`/`size`/`swatch` (which are still fields *on* the persisted `EditorLayer` class),
  these are three entirely standalone top-level enums with zero relationship to any persisted type,
  so leaving them behind costs nothing and keeps the shared library's public surface smaller. Flagging
  for Specifications to resolve with a concrete recommendation, same as the `EditorLayer` fields were.
- [ ] **NEW (v0.2)**: `EditorLayer.imageSlotFor(String langCode, LanguageRegistry registry)` takes a
  concrete `LanguageRegistry` parameter from `apps/comics-editor/lib/src/i18n/language_registry.dart`,
  which uses `package:flutter/services.dart`'s `rootBundle` (asset-bundle-coupled, requires a running
  Flutter app with the editor's own bundled assets) — checked directly, confirmed this is the one real
  place `models.dart`'s `import '../i18n/language_registry.dart'` (flagged as unresolved in v0.1's Edge
  Cases) is used. This method cannot move as-is without dragging that asset dependency into the shared
  library. Two candidate resolutions, neither implemented yet: (a) leave `imageSlotFor` behind as an
  `extension EditorLayerLanguageSlot on EditorLayer` defined in `apps/comics-editor`, so `EditorLayer`
  itself moves clean and only this one convenience method stays put; (b) change the shared method's
  own signature to take a plain `int Function(String) indexFor` callback instead of the concrete
  `LanguageRegistry` type, decoupling it without relocating it. (a) is less invasive (zero signature
  change for existing callers); flagging for Specifications to pick one.

## References

- `apps/comics-editor/lib/src/ui/models.dart`, `apps/comics-editor/lib/src/bridge/models_mapping.dart`,
  `apps/comics-editor/lib/src/ui/anim/keyframe_interpolator.dart`
- `apps/comics-editor/lib/src/bridge/bodymovin_mapping.dart`, `.../lib/src/ui/bodymovin/bodymovin_import.dart`,
  `.../bodymovin_export.dart` (NEW in v0.2 — see Addendum above)
- `libs/comics_viewer/flutter_comics_viewer/lib/src/dart_comics_viewer_backend.dart`,
  `dart_comics_viewer_surface.dart`, `comics_viewer.dart`
- `flows/tdd-dot-comics-format/` — the schema decisions this library must stay synced with going
  forward (whoever adds a new field should now only need to touch this library)
- `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-bodymovin/` — v0.4's real producer/source of
  non-uniform depth and reconstructed camera-path fixtures
- `flows/comics-editor/tdd-dot-bodymovin-import-export/` — NEW in v0.2: the flow that created the Bodymovin
  files now in scope, and the schema fields (`groupId`/`textRegion`/`preferredViewportWidth`/`Height`)
  they depend on
- `flows/comics-editor/vdd-comics-editor-scroll/` — NEW in v0.2: created `keyframe_interpolator.dart`
- `flows/comics-viewer/sdd-flutter-comics-viewer-dart/` — NEW in v0.2: a hard downstream dependent,
  blocked on this flow reaching Plan-approved (see Addendum above)
- `flows/comics-viewer/sdd-flutter-comics-viewer/` — prior, overlapping, stale flow (see its
  `_status.md` for the disclosed relationship)
- `flows/comics-viewer/sdd-comics-viewer/` — active flow that built the current
  `flutter_comics_viewer` Dart backend this flow will refactor
- `flows/comics-editor/sdd-comics-editor-ffi/` — owns the native-core bridge this flow's relocated
  model must keep working with, unchanged
- `flows/_archive/sdd-flutter-puzzle-viewer/` — NEW in v0.2: stale but real prior art for a
  `flutter_puzzle` library depending on `flutter_comics`; informs keeping the public API generic

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-08
- [x] Notes: Approved as drafted (v0.3) — v0.1's original content plus the v0.2 (Bodymovin/interpolator
      scope, full flow survey) and v0.3 (`.puzzle` decided, architecture-boundary verification)
      addenda all approved together ("specs and reqs approved").

### v0.4 review gate

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-09
- [x] Notes: v0.4 is a camera/z-depth extension only. Requirements and Specifications are approved;
      implementation still requires a separately approved Plan addendum.
