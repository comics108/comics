# Implementation Log: dot-bodymovin-import-export

> Started: 2026-08-08
> Plan: [04-plan.md](04-plan.md)

## Progress Tracker

| Task | Status | Notes |
|------|--------|-------|
| 1.1 Add `EditorLayer.groupId` | Done | `models.dart` |
| 1.2 Persist `groupId` in JSON | Done | `models_mapping.dart`, omit-if-empty |
| 1.3 Add `EditorLayer.textRegion` + `TextRegion` | Done | `models.dart` |
| 1.4 Persist `textRegion` in JSON | Done | `models_mapping.dart`, omit-if-null |
| 1.5 Add `ComicsDoc.preferredViewportWidth`/`Height` | Done | `models.dart`, default 720×1600 |
| 1.6 Persist `preferredViewportWidth`/`Height` in JSON | Done | `models_mapping.dart`, always-present |
| 2.1 `BodymovinDocument`/`BodymovinLayer`/`BodymovinAsset`/`BodymovinMask`/`BodymovinTransform` | Done | `bodymovin_mapping.dart` (new) |
| 2.2 `parseBodymovinDocument` | Done | Zip via `package:archive` (matches `dart_io_core.dart`'s own pattern) |
| 2.3 `writeBodymovinDocument` | Done | Inverse; reconstructs the real `NAME_content/NAME.json` layout |
| 3.1 `ExportImportMode` + detection heuristic | Done | `bodymovin_import.dart` (new); aspect-ratio + real-sweep-shape signal |
| 3.2 `ImportPreview.build` — Full Canvas branch | Done | Precomp->groupId, parent->resolvedParent |
| 3.3 `ImportPreview.build` — Playback Viewport branch | Done | Scene detection + scrollSpeed auto-derivation |
| 4.1 `commitImport` — Full Canvas | Done | `bodymovin_import.dart`; bakes precomp offset into members |
| 4.2 `commitImport` — Playback Viewport | Done | Bakes scene sweep + scrollSpeed scaling |
| 4.3 Easing precision choice | Done (disclosure only) | Both choices converge per Test B3 -- documented, not silently ignored |
| 4.4 `TextRegion` import | Done | Bodymovin vector mask -> `TextRegion.shape:"polygon"` |
| 5.1 `buildBodymovinExport` — Full Canvas | Done | `bodymovin_export.dart` (new); identity, inverse of Task 4.1 |
| 5.2 `buildBodymovinExport` — Playback Viewport | Done | Synthesized `-scrollPixel` sweep per scene, matches `.comics`'s own render model |
| 5.3 `groupId`-sharing → shared precomp | Done | Test D2 |
| 5.4 `TextRegion` export | Done | polygon->mask; raster mask skipped with disclosed limitation (D3 default) |
| 6.1 Menu entries | Done | `top_bar.dart`, new "Bodymovin import/export" popup (desktop) + 2 items in the compact overflow menu |
| 6.2 Review screen widget | Done | `bodymovin_import_dialog.dart` (new): mode toggle, scrollSpeed/easing controls, clean/flagged counts, scrollable per-layer list, Cancel/Import |
| 6.3 Wrong-mode display | Done | Same file: banner shown when `preview.mode != detectMode(preview.document)` |
| 6.4 Real image-byte extraction | Done | `EditorController.commitBodymovinImport`; base64 data URI -> `writeTiles`, external-file-ref case disclosed/skipped |
| 7.1 E1 round-trip | Done | `test/bodymovin_roundtrip_test.dart`, real `samples/sample.Bodymovin` |
| 7.2 G3 Full Canvas round-trip | Done | Real `samples/sample_v2012.comics_unzip`, `.Bodymovin→.comics→.Bodymovin` direction |
| 7.3 G6 Playback Viewport round-trip | Done | Real `samples/sample_playback_viewport.Bodymovin_unzip` (`ASHES.json`) |
| 7.4 F1/F2 error-handling tests | Done | Already covered by Phase 2/3's own tests, confirmed not duplicated |

## Session Log

### Session 2026-08-08 - Claude

**Started at**: Phase 1, Task 1.1
**Context**: Plan approved same session. Verified before starting: zero `bodymovin_*.dart` files
existed, no `groupId`/`textRegion`/`preferredViewportWidth`/`Height` in `models.dart` — genuine
clean slate, not partial prior work.

#### Completed
- Task 1.1: `EditorLayer.groupId` (nullable `String`, default `null`, `clone()`-preserved).
  - Files changed: `lib/src/ui/models.dart`
  - Verified by: `test/models_test.dart` (default-null + clone-preserves cases)
- Task 1.2: `groupId` JSON round-trip, omit-if-empty (same pattern as `kind`/`style`/`parentId`).
  - Files changed: `lib/src/bridge/models_mapping.dart`
  - Verified by: `test/models_mapping_test.dart` (3 new cases: read, legacy-absent, write-back)
- Task 1.3: `TextRegion` class (`shape`/`rect`/`points`/`maskFile`/`isHandLettered`) +
  `EditorLayer.textRegion`. Implemented the struct exactly as `03-specifications.md` specified;
  the 2 deferred Requirements-level questions (`isHandLettered`/`Style` relationship, coordinate
  space) are flagged in the field's own doc comment, not silently resolved.
  - Files changed: `lib/src/ui/models.dart`
  - Verified by: `test/models_test.dart` (default-null + clone-deep-copies cases)
- Task 1.4: `textRegion` JSON round-trip (`_textRegionFromJson`/`_textRegionToJson`, a deliberately
  separate pair from `_maskFromJson`/`_maskToJson` despite the shared shape vocabulary — per
  Specifications, `TextRegion` and `LayerMask` are different concepts that happen to reuse the
  same shape union, not the same field under two names).
  - Files changed: `lib/src/bridge/models_mapping.dart`
  - Verified by: `test/models_mapping_test.dart` (read/legacy-absent/write-back, including
    `isHandLettered`)
- Task 1.5: `ComicsDoc.preferredViewportWidth`/`preferredViewportHeight` (default 720×1600) — the
  first real implementation of the field `tdd-dot-comics-format`'s Requirements/Specifications
  only specified on 2026-08-08; this flow is its first real consumer.
  - Files changed: `lib/src/ui/models.dart`
  - Verified by: `test/models_test.dart` (default + clone-preserves cases)
- Task 1.6: `preferredViewportWidth`/`Height` JSON round-trip, always-present once assigned (same
  treatment as `scrollType`/`preferredOrientation`, not the omit-if-null pattern — an `int` field
  is never "unset" the way a nullable string is).
  - Files changed: `lib/src/bridge/models_mapping.dart`
  - Verified by: `test/models_mapping_test.dart` (legacy-default + round-trip cases)

#### In Progress
- None — Phase 1 fully complete, all 6 tasks done and tested.

#### Deviations from Plan
- **Unrelated fix, discovered while running the full suite**: `test/app_version_test.dart` was
  failing before any of this session's changes, due to `pubspec.yaml`'s version having been bumped
  externally to `3.2.2+3` without updating `lib/src/app_version.dart`'s hand-maintained `fallback`
  constant (that file's own doc comment says to keep it in sync by hand). Fixed
  (`3.2.1` → `3.2.2`) since it's a one-line, clearly-intended sync fix per the file's own documented
  process — not part of any Plan task, but left unfixed would have made every subsequent phase's
  "full suite passes" checkpoint falsely red.

#### Discoveries
- None beyond what Requirements/Specifications already established — Phase 1 was a
  straightforward implementation of already-fully-specified fields, no new real-data findings.

- Task 2.1: `BodymovinDocument`/`BodymovinLayer`/`BodymovinAsset`/`BodymovinMask`/`BodymovinTransform`/
  `BodymovinProperty`/`BodymovinKeyframe`/`AssetFile` — minimal Bodymovin model, matching Specifications'
  "only what real content needs." **Verified `BodymovinMask`'s simplified shape against real data
  before coding it**: re-checked all 6 real masks in `THE CHASE.json` (in `dataset/`, not `samples/`)
  — confirmed again `mode:"a"`, never animated, always exactly 4 vertices, no curve handles,
  never inverted. `BodymovinMask.fromJson`-equivalent throws `BodymovinFormatException` for any shape
  outside that (animated path, curved handles) rather than silently guessing.
  - Files changed: `lib/src/bridge/bodymovin_mapping.dart` (new)
  - Verified by: `test/bodymovin_mapping_test.dart`
- Task 2.2: `parseBodymovinDocument(Uint8List zipBytes)` — unzips via `package:archive`'s `ZipDecoder`
  (same real pattern already used in `lib/src/bridge/dart_io_core.dart`'s `_openComics`, not a new
  zip-handling approach), locates the real `NAME_content/NAME.json` entry (confirmed this exact
  layout in every real sample checked), skips `__MACOSX/` zip noise. Throws
  `BodymovinFormatException` (typed, not generic `FormatException`) on missing top-level keys or a
  non-JSON content entry — Test F1.
  - Files changed: `lib/src/bridge/bodymovin_mapping.dart`
  - Verified by: `test/bodymovin_mapping_test.dart`, including a real end-to-end parse of
    `samples/sample.Bodymovin` (a real zip, not a directory fixture) and real direct-JSON parses of
    `ASHES.json`/`THE CHASE.json` (via the internally-factored pure `parseBodymovinJson`, which
    doesn't need a zip step to test against real fixtures read directly)
- Task 2.3: `writeBodymovinDocument` — the inverse, reconstructing the same `NAME_content/NAME.json`
  layout on the way out via `BodymovinDocument.contentBaseName` (captured by `parseBodymovinDocument` on
  the way in, not hardcoded) — a parse→write round-trip reproduces the same path.
  - Files changed: `lib/src/bridge/bodymovin_mapping.dart`
  - Verified by: `test/bodymovin_mapping_test.dart` (hand-built document round-trip, both static and
    animated-with-easing properties)

- Task 3.1: `ExportImportMode` + `detectMode`/`_hasSweepShape` (`lib/src/ui/bodymovin/bodymovin_import.dart`,
  new). Detection: composition aspect ratio <= 4.0 (a judgment call separating the two real
  samples' actual ratios, ~38:1 vs ~2.2:1) **and** at least one root-level layer with the confirmed
  real sweep shape (animated position spanning its own `ip`/`op` range, Y-delta larger than the
  composition's own height) -> `playbackViewport`; otherwise `fullCanvas`.
  - Files changed: `lib/src/ui/bodymovin/bodymovin_import.dart` (new)
  - Verified by: `test/bodymovin_import_test.dart` against the real `ASHES.json` (detects
    `playbackViewport`) and two hand-built counter-examples (canvas-shaped with no sweep; viewport-
    shaped but with no sweep — confirms shape alone isn't sufficient)
- Task 3.2: `LayerPreview`/`LayerPreviewStatus`/`ImportPreview.build` — Full Canvas branch. Precomp
  layers expand into their resolved members (tagged with a shared `groupId` = the precomp asset's
  own real `id`, e.g. `"comp_0"`); Bodymovin `parent` indices resolve to `LayerPreview.resolvedParent`
  within the same composition.
  - Files changed: `lib/src/ui/bodymovin/bodymovin_import.dart`
  - Verified by: `test/bodymovin_import_test.dart` (A1 all-clean, A2 mixed/all-unsupported, A3 precomp
    grouping, parent resolution, F2 missing-asset)
- Task 3.3: Playback Viewport branch — root-level sweep-shaped layers become scenes
  (`sceneIndex`-tagged resolved members); non-sweep root layers are flagged ("not a recognized
  scene"), a real, disclosed design choice for the "zero scenes"/mixed-content case (not precisely
  specified in `03-specifications.md`, resolved here rather than left ambiguous in code).
  `scrollSpeed` auto-derives as the average of every detected scene's own px/frame speed — real
  content's scenes agree closely enough (0.34% apart) that averaging is faithful, not a lossy
  compromise.
  - Files changed: `lib/src/ui/bodymovin/bodymovin_import.dart`
  - Verified by: `test/bodymovin_import_test.dart` against real `ASHES.json` (2 real scenes detected,
    `scrollSpeed` lands at the expected computed average) and a fullCanvas-shaped counter-example
    (no scenes, `scrollSpeed` correctly null)

#### Deviations from Plan (this session)
- **A real bug caught by testing, not by inspection**: `BodymovinLayer.unsupportedReason` was
  originally only computed by the JSON parser (`_layerFromJson`'s own `_unsupportedReasonFor` call)
  — any `BodymovinLayer` built directly (as several of `bodymovin_import_test.dart`'s own hand-built test
  fixtures do, and as any future caller reasonably might) silently defaulted `unsupportedReason` to
  null, i.e. "supported," regardless of its real `type`. Caught immediately by 2 failing tests (A2's
  shape-layer case, A2's all-unsupported case) the moment hand-built fixtures were exercised — fixed
  by moving the type->reason classification into `BodymovinLayer`'s own constructor as a default,
  removing the now-redundant standalone `_unsupportedReasonFor` function entirely rather than
  leaving two copies of the same logic to drift apart.
- **Small, disclosed refinement to Phase 2's `BodymovinAsset`** (Task 3.2's F2 concern required it):
  added `BodymovinAsset.fileFound` (nullable bool), populated only by `parseBodymovinDocument` (which has
  real archive access) by checking each image asset's `imagePath` against actual zip entries.
  Discovered while implementing this that **both real samples checked embed every image asset as a
  base64 data URI** (`e:1`, `p:"data:..."`) — neither references an external zip-relative file at
  all. `fileFound` treats any `data:`-prefixed path as always found; the external-file-reference
  branch is real code, covered by a hand-built test, but has no real content to verify it against —
  disclosed as an untested-by-real-data path, not silently assumed correct.
- **A disclosed addition beyond `03-specifications.md`'s literal `LayerPreview` field list**:
  `LayerPreview.resolvedParent` (a same-composition reference to another `LayerPreview`), needed to
  make Bodymovin `parent`-index resolution actually implementable without `commitImport` re-walking
  the whole `BodymovinDocument` a second time. A parent index pointing at a precomp layer (rather than
  a leaf) resolves to null — a real, disclosed gap (a precomp dissolves into N flat layers with no
  single `EditorLayer` to parent to) — not exercised by any real content found (every real root
  layer checked has `parent: None`).

- Task 4.1/4.2: `commitImport` — creates real `EditorLayer`s from clean `LayerPreview`s, two-pass
  (create, then wire `parentId` via `resolvedParent`). Bakes an enclosing precomp/scene's own
  transform into each member's keyframes by summing sampled values at the union of both curves'
  keyframe frame points (linear-sampled where a frame isn't a real keyframe of one curve --
  exact for the dominant real case, a small disclosed approximation for the less common case
  where both member and enclosing sweep are independently animated with different frame points).
  Full Canvas mode: identity frame->scroll-pixel (no ratio). Playback Viewport mode: frame*scrollSpeed.
  - Files changed: `lib/src/ui/bodymovin/bodymovin_import.dart`
  - Verified by: `test/bodymovin_commit_import_test.dart` — exact numeric checks (a hand-built
    animated-translate case, a hand-built precomp-offset-baking case), parentId wiring, and a
    real-`ASHES.json` end-to-end case confirming baked translate chains + the expected scrollSpeed
- Task 4.3: `EasingChoice` deliberately left unconsumed in `commitImport`, disclosed in a code
  comment rather than silently ignored — per Test B3's own finding, `.comics` has exactly one fixed
  interpolation formula, so both choices currently produce identical output regardless.
- Task 4.4: A Bodymovin vector mask (`BodymovinMask`) imports as `TextRegion.shape == "polygon"` (never
  `"mask"`, since Bodymovin masks are always vector — confirmed by Test C2's own reasoning).
  - Verified by: `test/bodymovin_commit_import_test.dart`

#### Discoveries (real, changed this session's scope)
- **A real architectural gap found while implementing Task 4.1, not by inspection**:
  `commitImport`'s Specifications-defined signature (`ImportPreview`, `ComicsDoc` — synchronous, no
  file-path parameter) has no way to call `lib/src/io/tile_writer.dart`'s `writeTiles`, which needs
  a real `layersDir` derived from a document's own `CoreDocument.tempFolder` — something that only
  exists once a document is actually open in the editor. **This means `commitImport` as specified
  cannot write real image pixel files** — every imported `EditorLayer.images` keeps the
  constructor's own placeholder, not real artwork, until a later, controller-level step (which does
  have real tempFolder access) extracts the real bytes (Bodymovin's real content embeds every image as
  a base64 data URI, confirmed in Phase 2) and calls `writeTiles` itself. Flagged as a new task
  (deferred to Phase 6, tracked in the task list, not silently dropped) rather than either (a)
  silently shipping an "import" that produces blank artwork with no comment, or (b) unilaterally
  changing `commitImport`'s already-approved Specifications signature to smuggle in file-I/O
  concerns it wasn't designed for.
- **A real bug caught by testing**: an early version of `commitImport` unconditionally emitted a
  Rotate/Scale/Alpha `Anim` for every imported layer, even when the source was static and at that
  property's neutral resting default (angle=0, scale=100%, opacity=100) — cluttering every imported
  layer with 3 no-op Anims it didn't need, unlike how real hand-authored `.comics` content actually
  looks (an author only adds the animations they actually use). Caught by the precomp-offset-baking
  test unexpectedly returning `Too many elements` on a `.single` lookup — fixed by only emitting
  rotate/scale/alpha when the source is genuinely animated or off its neutral default.
- **A real unit-conversion bug caught by testing**: Bodymovin's `s` (scale) is a percentage (100 ==
  100%) and `o` (opacity) is 0-100, while `.comics`'s `scaleX`/`scaleY`/`alpha` are unit fractions
  (1 == 100%/fully opaque) — an early version assigned the raw Bodymovin values directly. Fixed with
  an explicit `/100` conversion at the one point (`_animFor`) where Bodymovin values become `.comics`
  values.

- Task 5.1/5.2/5.3/5.4: `buildBodymovinExport` (both modes), `lib/src/ui/bodymovin/bodymovin_export.dart`
  (new). Full Canvas: identity, direct inverse of `commitImport`'s own baking (each `.comics` Anim
  chain -> one Bodymovin keyframe per Anim, `.end` as the frame point). Playback Viewport: partitions
  `doc.layers` into `preferredViewportHeight`-tall bands (scenes), synthesizing a `-scrollPixel`
  sweep per scene — chosen deliberately so member layers need **zero** position adjustment (their
  existing absolute-Y Anim values pass straight through unchanged), since the sweep alone
  reproduces `.comics`'s own real rendering formula (`displayedY = absoluteY - scrollPosition`),
  not an invented convention specific to export. `groupId`-sharing layers -> one shared precomp
  (D2); `TextRegion.shape=="polygon"` -> a real Bodymovin vector mask (D3); `shape=="mask"` (raster)
  is skipped with the disclosed-limitation default, not guessed at.
  - Files changed: `lib/src/ui/bodymovin/bodymovin_export.dart` (new)
  - Verified by: `test/bodymovin_export_test.dart` — exact keyframe/value checks for both modes, D1-D4
    equivalents, **and an export->re-import round-trip using this session's own `ImportPreview
    .build`/`commitImport`** (not yet the real-fixture G3/G6 integration test, which needs Phase 7's
    zip-level round-trip, but a direct functional check that export and import agree with each
    other on the same math)

#### Discoveries (this session, continued)
- **A real boundary bug caught by the round-trip test, not by inspection**: Task 5.2's own
  synthesized sweep is exactly one `preferredViewportHeight` tall by design (the minimal, correct
  choice) — but `_hasSweepShape`'s detection heuristic (Task 3.1) used a strict `> document.height`
  threshold, which real content (whose sweeps are 8-15x the viewport height) always clears
  comfortably, but this flow's *own* synthesized 1x-height sweep narrowly failed. Fixed by lowering
  the threshold to `> document.height / 2` — still far above real local-wiggle magnitudes (tens to
  hundreds of px), re-verified against the real `ASHES.json` fixture to confirm the fix didn't
  introduce a false positive there.

**Ended at (this sub-session)**: Phases 1-5 complete (24/26 original tasks, +1 new disclosed task for
deferred image extraction, +1 disclosed-only task). Phase 6 (UI) and Phase 7 (real-fixture round-trip
integration tests) not yet started.
**Handoff notes**: Full suite at 467 tests passing, `flutter analyze` clean. Both directions'
core data-mutation logic (`bodymovin_import.dart`/`bodymovin_export.dart`) are complete and tested against
each other functionally; what remains is (a) Phase 7's real-fixture, real-zip-level round-trip
tests (G3's fixture-prep-then-round-trip, G6 against the real `ASHES.json`-based sample, E1 against
`samples/sample.Bodymovin`) and (b) Phase 6's actual UI (menu entries, review screen widget) — neither
of which is wired to anything a real user can click yet. The disclosed real-image-pixel-extraction
gap (Task 6.4) still stands, symmetric now on both import and export sides.

### Session 2026-08-08 (continued) - Claude — Phase 7: real-fixture round-trip integration tests

**Started at**: Phase 7, Tasks 7.1-7.4. Wrote `test/bodymovin_roundtrip_test.dart` (G3, G6, E1) plus a
temporary, non-permanent debug script (`test/_debug_roundtrip_test.dart`, deleted once the real fix
landed — see below) to inspect real intermediate values rather than guess.

All three round-trip tests failed on the first real run, each for a genuine bug (not a test-harness
issue) in `bodymovin_export.dart`/`bodymovin_import.dart`. Fixing them required several rounds of
hypothesis → real-fixture test → inspect real intermediate values → fix, using `ASHES.json` and
`sample_v2012.comics_unzip` throughout — never trusting an assumption over what the real files
actually contained. **Five real bugs found and fixed this session**, in order:

1. **2-level precomp nesting**: `buildBodymovinExport`'s Playback Viewport branch re-grouped scene
   members by `groupId` inside the scene's own precomp, creating a redundant nested level (every
   scene member already shares one `groupId` from import) — exceeded import's 1-level nesting limit,
   failing 100% of re-imported layers as "precomp-of-precomp beyond one level." Fixed: scene members
   are flattened directly; `groupId`-based nesting only applies to Full Canvas export.
2. **Sweep double-counting**: export wrote each member's already-absolute value as its Bodymovin "own"
   position, but `commitImport` treats "own" as local and adds the sweep back — double-counting it
   on re-import. Fixed: export subtracts the sweep's own contribution (via the real
   `KeyframeInterpolator.translateAt`, not a re-implemented approximation) from each member's true
   absolute value before emitting it as "own" (`_sceneMemberToBodymovin`/`_localPositionAt`).
3. **Y-position-based scene banding**: scene membership was derived from `floor(restingY /
   viewportHeight)`, which is wrong once a sweep is baked in (absolute Y and scroll-pixel position
   aren't the same axis anymore). Fixed to group by the already-present `groupId` instead, ordered by
   ascending min resting Y.
4. **Uniform-`viewportHeight`-per-scene assumption**: `_buildPlaybackViewport` assumed every scene
   occupies exactly one `preferredViewportHeight`-tall band (`sceneIndex * viewportHeight`) — wrong:
   real scenes span far more scroll-pixel range (`ASHES.json`'s "32_1" spans scroll-pixel 9711 to
   33668, ~15 bands' worth). First fix attempt derived each scene's range from the literal min/max of
   its members' own `Anim.start`/`.end` — closer, but still wrong, because:
   - **static-layer seed artifact**: `_bakedAnims`' own single-sample path seeds every genuinely-
     static member (no real Bodymovin keyframes) with a zero-width `Anim(start:0, end:0)` placeholder.
     Counting that placeholder's `start=0` toward a scene's range dragged every scene's start down to
     0 regardless of where real motion begins. Fixed at the root: `_bakedAnims` now only defaults to
     frame 0 when there's no animated enclosing sweep to defer to — when the sweep *is* animated, a
     static member contributes nothing extra (its own frame is irrelevant to a constant value).
   - **outlier local motion**: even with that fixed, a real per-member *local* flourish well outside
     the group's shared window (`ASHES.json`'s "10_5_bg" settles into place at scroll ~1048-2845, on
     its own, well before the group's real shared sweep window of 9711-33668) still skewed a literal
     min/max. The real signal for "where does the shared sweep actually start/end" turned out to be
     *which frame the most members agree on* — confirmed against real data: dozens of members share
     the exact literal chain `[(9711,9711),(9711,33668)]`, while outliers each contribute one-off
     values that don't repeat. Fixed `_scrollRangeOf` to pick the two most-frequent distinct boundary
     values across all members (falling back to true min/max when nothing repeats).
5. **`_propertyFromAnims` dropped every `Anim.start`**: found via G3 (Full Canvas), a *different* bug
   from the Playback Viewport ones above. A real chain like `[(0,0,rest),(9607,10863,moved)]` (hold
   at rest, then ease into `moved` over a narrow window) exported as only 2 Bodymovin keyframes — one
   per `Anim.end` — turning the real held-then-eased shape into one long linear ramp across the
   *whole* `[0,10863]` range. On re-import, sampling this ramp at `t=10000` (deep inside the real
   narrow `[9607,10863]` window) landed near the ramp's far end instead of the correctly-eased
   mid-transition value. Fixed by also emitting a keyframe at each `Anim.start` (holding the
   *previous* anim's value there) whenever it's later than the last keyframe already emitted —
   reconstructs the real held segment exactly.

**Also fixed**: `test/bodymovin_roundtrip_test.dart`'s own comparison helper
(`expectRenderedTransformsMatch`) compared `a.layers[i]` to `b.layers[i]` by list index — but a
correct round trip legitimately reorders layers (scenes emit in ascending-scroll-position order;
Full Canvas separates grouped from ungrouped layers), which isn't a real bug. Fixed to match by
layer **name** instead (a `.comics` layer's identity is its name, never its list position) — this
surfaced bug 4/5 directly instead of it being masked by an unrelated wrong-layer comparison.

- Files changed: `lib/src/ui/bodymovin/bodymovin_export.dart` (`_scrollRangeOf`, `_sceneMemberToBodymovin`,
  `_buildPlaybackViewport`, `_propertyFromAnims`), `lib/src/ui/bodymovin/bodymovin_import.dart`
  (`_bakedAnims`'s `ownFrames` default), `test/bodymovin_roundtrip_test.dart` (new, name-based layer
  matching), `test/bodymovin_export_test.dart` (one existing test's assertions updated — it hardcoded
  the now-superseded uniform-band assumption).
- Verified by: all 3 real-fixture round-trip tests (G3, G6, E1) pass; full suite 470/470 (3 skipped,
  monorepo-only fixtures), `flutter analyze` clean.

**Ended at**: Phase 7 (Tasks 7.1-7.4) complete. Task 5.2 (#69, Playback Viewport export) is now
genuinely re-verified against real content, superseding its earlier "completed" mark that predated
these fixes. Phase 6 (UI: menu entries, review screen widget, wrong-mode display) and Task 6.4 (real
image-byte extraction) remain entirely unstarted — the only work left in this flow.

### Session 2026-08-08 (continued) - Claude — Phase 6: UI + real image-byte extraction

**Started at**: Phase 6, Tasks 6.1-6.4 — the last remaining phase.

#### Completed
- Task 6.4 (`commitImport`'s controller-level counterpart): `EditorController.commitBodymovinImport`
  wraps `commitImport` in one history transaction, then — only when `coreDoc?.tempFolder` is
  non-null — walks the newly-created `EditorLayer`s alongside their originating clean
  `LayerPreview`s (parallel order, confirmed from `commitImport`'s own append loop), decodes each
  source asset's base64 `data:` URI (the only shape any real `.Bodymovin` file was ever found to use,
  per Phase 2), and calls the already-shipped `writeTiles` to materialize a real tile file, pointing
  `EditorLayer.images[0].file` at it. Without a `tempFolder` (e.g. a never-saved "New Document" —
  this app has no `newComics` core call, an existing limitation every other tile-writing feature
  already shares), layers keep their constructor placeholder, matching `commitImport`'s own
  documented fallback — not a new restriction invented here. An external-file-reference source asset
  (never seen in real content) is skipped for pixel-writing rather than guessed at with unread
  bytes, disclosed in the function's own doc comment.
  - Files changed: `lib/src/ui/controller.dart` (`pickBodymovinToImport`, `setBodymovinImportMode`,
    `setBodymovinScrollSpeed`, `setBodymovinEasingChoice`, `cancelBodymovinImport`, `commitBodymovinImport`,
    `_decodeDataUri`, `exportBodymovinWithDialog`, plus `bodymovinPreview`/`bodymovinImportError` state)
  - Verified by: `test/bodymovin_controller_test.dart` (new, 10 cases) — including the real bar Task
    6.4's own Plan entry set: import a real fixture, confirm the tile file **actually exists on disk
    with real, non-empty pixel content**, not just a placeholder filename (uses a real
    `sample.comics`-backed `tempFolder` via `openPath`, matching `cutting_canvas_test.dart`'s own
    convention for getting a real core session in a test).
- Task 6.1: two new menu entries, "Import from .Bodymovin…" / "Export to .Bodymovin…" — a dedicated
  popup (desktop: a new icon next to the existing Export button; compact: two new items in the
  existing overflow menu), explicitly not a repurposing of the existing `.comics`/`.puzzle`
  Export/Save As mechanism, per the Plan's own instruction.
  - Files changed: `lib/src/ui/widgets/top_bar.dart`
- Task 6.2: `showBodymovinImportDialog`/`_BodymovinImportReviewDialog` in a new
  `lib/src/ui/widgets/bodymovin_import_dialog.dart` — a real triage screen: mode segmented control,
  scrollSpeed (Playback Viewport only, via the app's existing `NumericPropertyControl`), easing
  segmented control, live clean/flagged counts, a scrollable per-layer status list (name, clean/
  flagged/missingAsset icon+color, reason text, precomp/scene badges), and explicit Cancel/Import
  actions. A corrupt/unparseable file (Test F1) shows a dedicated error dialog instead of an empty
  preview. Also added `showBodymovinExportDialog` in the same file — deliberately much simpler (mode +
  scrollSpeed only, no per-layer list), matching `buildBodymovinExport`'s own "easy direction, no
  review needed" framing; export's mode isn't auto-detected the way import's is, since there's no
  analogous real-file signal to detect from a `ComicsDoc` — the dialog asks directly, defaulting to
  Full Canvas as the always-unambiguous choice.
  - Files changed: `lib/src/ui/widgets/bodymovin_import_dialog.dart` (new)
- Task 6.3: the wrong-mode banner — recomputes `detectMode(preview.document)` fresh on every build
  (pure, cheap) and compares it against the current `preview.mode`; shows a non-blocking amber
  warning banner when they differ (covers both an explicit user override and, implicitly, any future
  auto-detection misfire), matching Test G7's "no crash, visibly wrong, not silently broken" bar.
  Import still completes either way — never blocked.
  - Files changed: `lib/src/ui/widgets/bodymovin_import_dialog.dart`

#### Discoveries
- **`FilePicker.saveFile`'s real behavior, confirmed by reading the plugin's own platform
  implementations** (not assumed from the existing `exportWithDialog`'s desktop branch, which routes
  through the core instead and never passes `bytes` on desktop): passing `bytes:` makes the plugin
  write the file itself once the user picks a destination, on every platform (macOS/Windows/Linux
  all call `FilePickerUtils.saveBytesToFile` internally; mobile requires it). `exportBodymovinWithDialog`
  passes `bytes` unconditionally and needs no separate manual `File.writeAsBytes` step — an earlier
  draft had one, removed once this was confirmed against the package source.
- Task 6.2's per-layer review list and Task 6.3's banner are real, tested at the controller/pure-logic
  level (`ImportPreview`'s own state, `detectMode`'s comparison) per the Plan's own "Manual" bar for
  the widget layer itself — deep `pumpWidget` coverage of the dialog widget wasn't added (the review
  widget class is intentionally private to its file, matching this app's other dialogs'
  `_DialogShell`-style convention), consistent with the Plan's stated verification bar for these two
  tasks specifically.

#### Verification
- Full suite: 480/480 passing (3 skipped, monorepo-only fixtures), `flutter analyze` clean.

**Ended at**: All 7 phases complete. Every task in `04-plan.md` is done, including the two tasks
(#66/#69's Phase 6 counterpart) added or re-verified mid-flow. Nothing outstanding in this flow.

---

## Deviations Summary

| Planned | Actual | Reason |
|---------|--------|--------|
| (none yet — Phase 1 matched the plan exactly) | | |

## Learnings

- Reusing the exact `_maskFromJson`/`_maskToJson` shape (rather than trying to share code between
  `LayerMask` and `TextRegion`) kept both additions simple and independently comprehensible, at the
  cost of some duplication — consistent with this codebase's own established preference (seen
  throughout `tdd-dot-comics-format`'s Implementation) for a few similar lines over a premature
  shared abstraction between two fields that are conceptually different despite a shared shape
  vocabulary.

## Completion Checklist

- [ ] All tasks completed or explicitly deferred (6/26 done — Phase 1 only)
- [x] Tests passing (429/429, as of Phase 1's completion)
- [x] No regressions (full suite + backward-compat dataset re-run clean)
- [ ] Documentation updated if needed (README/`06-readme.md` still an unfilled template — DOCUMENTATION phase not started)
- [ ] Status updated to COMPLETE
