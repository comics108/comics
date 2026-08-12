# Implementation Plan: dot-bodymovin-import-export

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-08-08
> Specifications: [03-specifications.md](03-specifications.md) (v1.3, APPROVED)

## Summary

Adds real `.Bodymovin` import/export to `apps/comics-editor`, in two modes (Full Canvas, Playback
Viewport, per Specifications' `ExportImportMode`). Verified before writing this plan: **nothing is
implemented yet** — `apps/comics-editor` has zero `bodymovin_*.dart` files, and `EditorLayer.groupId`/
`.textRegion`/`ComicsDoc.preferredViewportWidth`/`Height` don't exist in `models.dart` either
(checked directly). This is a clean-slate build, not an extension of partial work.

Sequenced so the `.comics`-side schema prerequisites (Phase 1) land first, then pure Bodymovin JSON
I/O (Phase 2, no `.comics` coupling at all — independently testable), then the mode-aware import
pipeline (Phases 3-4), then export (Phase 5), then UI (Phase 6), then real-fixture round-trip
integration tests (Phase 7) last, since those need every earlier phase working together.

Reuses `EditorLayer.id`/`.parentId`, `ComicsDoc.scrollType`/`.preferredOrientation`, and
`Anim.basis`/`.loop` directly — all already shipped in `apps/comics-editor`
(`flows/tdd-dot-comics-format`'s Plan, Phases 1/2/3/5). This flow does not reinvent any of them.

## Task Breakdown

### Phase 1: `.comics` schema prerequisites not yet in code

#### Task 1.1: Add `EditorLayer.groupId`
- **Description**: Nullable `String? groupId` on `EditorLayer` — flat, symmetric "these layers
  belong together" tag (distinct from `.parentId`'s hierarchy; per Specifications' still-open
  question, may end up subsumed by `parentId` for the precomp case, but is specified as its own
  field for now). Default `null`, included in `clone()`.
- **Files**: `lib/src/ui/models.dart`
- **Dependencies**: None
- **Verification**: Unit test — new layer has `groupId == null`; `clone()` preserves it.
- **Complexity**: Low

#### Task 1.2: Persist `groupId` in JSON (additive, omit-if-null)
- **Files**: `lib/src/bridge/models_mapping.dart`
- **Dependencies**: Task 1.1
- **Verification**: Round-trip test, same omit-if-absent pattern as `kind`/`style`/`parentId`.
- **Complexity**: Low

#### Task 1.3: Add `EditorLayer.textRegion` + `TextRegion` class
- **Description**: Per Specifications' `TextRegion` interface (`shape: "rect"|"polygon"|"mask"`,
  `rect`/`points`/`maskFile`, `isHandLettered`). The 2 deferred Requirements-level sub-questions
  (`isHandLettered`/`Style` relationship, coordinate space) are still open — implement the struct
  as specified, layer-local coordinates (Specifications' stated leaning), and flag both open
  questions in code comments rather than silently picking an answer.
- **Files**: `lib/src/ui/models.dart`
- **Dependencies**: None
- **Verification**: Unit test — new layer has `textRegion == null`; `clone()` deep-copies it
  (mirrors `LayerMask`'s own clone pattern from `tdd-dot-comics-format` Task 4.1).
- **Complexity**: Low

#### Task 1.4: Persist `textRegion` in JSON (additive, omit-if-null)
- **Files**: `lib/src/bridge/models_mapping.dart`
- **Dependencies**: Task 1.3
- **Verification**: Round-trip test for each shape variant (rect/polygon/mask).
- **Complexity**: Low

#### Task 1.5: Add `ComicsDoc.preferredViewportWidth`/`preferredViewportHeight`
- **Description**: Per `tdd-dot-comics-format`'s already-approved Requirements/Specifications
  addition (2026-08-08) — `int preferredViewportWidth = 720`, `int preferredViewportHeight = 1600`.
  This flow is the first real consumer (Playback Viewport mode's default viewport size, and the
  scene-boundary convention for export), so it's the natural place to actually implement the field
  `tdd-dot-comics-format` only specified.
- **Files**: `lib/src/ui/models.dart`
- **Dependencies**: None
- **Verification**: Unit test — new doc defaults to 720×1600; `clone()` preserves custom values.
- **Complexity**: Low

#### Task 1.6: Persist `preferredViewportWidth`/`Height` in JSON (always-present, per
  `tdd-dot-comics-format`'s own decided pattern for this field — same treatment as `scrollType`)
- **Files**: `lib/src/bridge/models_mapping.dart`
- **Dependencies**: Task 1.5
- **Verification**: Round-trip test; confirm every real dataset file still opens with the 720×1600
  defaults (no existing file has these keys).
- **Complexity**: Low

### Phase 2: Pure Bodymovin JSON model + parse/write (no `.comics` coupling)

#### Task 2.1: `BodymovinDocument`/`BodymovinLayer`/`BodymovinAsset`/`BodymovinMask`/`BodymovinTransform` classes
- **Description**: Per Specifications' Interfaces block. Deliberately minimal — only what real
  content and this flow's Test Cases need (image/precomp/solid/null layer types, `parent` field,
  vector masks, p/r/s/o transform keyframes). Shape/text/gradient/repeater layers are represented
  only via `BodymovinLayer.unsupportedReason`, never modeled structurally.
- **Files**: `lib/src/bridge/bodymovin_mapping.dart` (new)
- **Dependencies**: None
- **Verification**: Unit tests constructing each class directly (no file I/O yet).
- **Complexity**: Medium

#### Task 2.2: `parseBodymovinDocument(Uint8List zipBytes)`
- **Description**: Unzips, validates required top-level keys, maps to `BodymovinDocument`. Throws a
  typed exception (not generic `FormatException`) on invalid/missing keys — Test F1.
  `BodymovinLayer.type` classification: `ty:2`→image (clean), `ty:0`→precomp (clean, resolved via
  `assets`), `ty:1`/`ty:3`→solid/null (named `unsupportedReason`, not lumped into "other," per
  Specifications' correction — real content has both), everything else→unsupported.
- **Files**: `lib/src/bridge/bodymovin_mapping.dart`
- **Dependencies**: Task 2.1
- **Verification**: Parse `samples/sample.Bodymovin` directly (real file, no `.comics` involved) —
  confirm layer count/types match direct JSON inspection done during Requirements/Specifications
  research. Parse a corrupted copy — confirm the typed exception (Test F1).
- **Complexity**: Medium

#### Task 2.3: `writeBodymovinDocument(BodymovinDocument doc, {required List<AssetFile> assetFiles})`
- **Description**: The inverse — builds real, zippable Bodymovin bytes.
- **Files**: `lib/src/bridge/bodymovin_mapping.dart`
- **Dependencies**: Task 2.1
- **Verification**: Write then re-parse (Task 2.2) — round-trips to an equal `BodymovinDocument`.
- **Complexity**: Medium

### Phase 3: Mode detection + `ImportPreview` (import classification, no mutation yet)

#### Task 3.1: `ExportImportMode` enum + detection heuristic
- **Description**: Per Specifications' DECIDED (2026-08-08) auto-detect-with-override: a
  composition whose `w`/`h` are phone-viewport-shaped **and** whose root-level layers show the
  confirmed real sweep shape (one dominant position-keyframe pair spanning most of that layer's own
  `ip`/`op`) suggests `playbackViewport`; canvas-shaped with no such sweep suggests `fullCanvas`.
  Returns a detected mode, never silently applied without the caller being able to override it.
- **Files**: `lib/src/ui/bodymovin/bodymovin_import.dart` (new)
- **Dependencies**: Task 2.1
- **Verification**: Unit test against `samples/sample_playback_viewport.Bodymovin_unzip`'s real
  `ASHES.json` (detects `playbackViewport`) and a hand-built fullCanvas-shaped fixture (detects
  `fullCanvas`).
- **Complexity**: Medium

#### Task 3.2: `LayerPreview`/`LayerPreviewStatus` + `ImportPreview.build` — Full Canvas branch
- **Description**: Per Specifications. `ty:2`→clean; `ty:0` precomp→resolved via `assets`, member
  layers tagged with a shared `groupId` (Task 1.1); Bodymovin `parent` field→resolved via the new
  `EditorLayer.parentId` mechanism (already shipped, `tdd-dot-comics-format` Phase 3) — **not**
  baked-and-discarded, mapped directly, any depth. Frame numbers used as-is (identity), no ratio.
- **Files**: `lib/src/ui/bodymovin/bodymovin_import.dart`
- **Dependencies**: Tasks 1.1, 3.1
- **Verification**: Tests A1 (all-clean), A2 (mixed clean/flagged), A3 (precomp→group), F2 (missing
  asset→flagged, not fatal), G1/G2 (identity time-base, no scroll-speed field populated).
- **Complexity**: High (the parenting/grouping resolution is the most structurally significant part
  of this whole flow, per Specifications' own note)

#### Task 3.3: `ImportPreview.build` — Playback Viewport branch (scene detection + scroll-speed)
- **Description**: Detects root-level sweep-shaped layers (Task 3.1's signal, applied per-layer
  here) as scenes, assigns `LayerPreview.sceneIndex` to each scene's resolved children. Auto-derives
  `ImportPreview.scrollSpeed` from the sweep's own position-delta/frame-delta — per Specifications'
  DECIDED resolution, computed exactly the way `ASHES.json`'s two real scenes were checked by hand
  (149.49/150.00 px/sec). Pre-fills, does not silently apply without the review screen showing it.
- **Files**: `lib/src/ui/bodymovin/bodymovin_import.dart`
- **Dependencies**: Task 3.2
- **Verification**: Test G4/G5 against the real `ASHES.json` — confirm detected `scrollSpeed` lands
  within the same tolerance as the hand-computed values; confirm zero scenes detected on a
  fullCanvas-shaped file produces its own flagged/warning state, not a silent empty result.
- **Complexity**: High

### Phase 4: `commitImport` (mutates `ComicsDoc`)

#### Task 4.1: `commitImport` — Full Canvas mode
- **Description**: For each clean/grouped `LayerPreview`: create `EditorLayer` (with `.id`,
  `.parentId`, `.groupId` as resolved by Phase 3); for each animated property (p/r/s/o), create
  `Anim` entries with `start`/`end` = frame numbers directly (`AnimBasis.scroll`, today's existing
  default — zero new anim-basis work needed here).
- **Files**: `lib/src/ui/bodymovin/bodymovin_import.dart`
- **Dependencies**: Task 3.2
- **Verification**: Test A1 (clean import produces correct `EditorLayer`s/`Anim`s), A3 (grouped
  layers share `groupId`, each with fully-baked absolute keyframes), A4 (cancel — never call this
  function — zero mutation by construction, no separate guard needed).
- **Complexity**: Medium

#### Task 4.2: `commitImport` — Playback Viewport mode
- **Description**: Each scene's recovered scroll-position range becomes ordinary scroll-basis
  `Anim`s (mirrors Full Canvas mode's own absolute-position model, within one scene); every child
  layer's own local keyframes import as scroll-basis `Anim`s by default — heuristic (a), the
  Requirements-decided safe-first-ship default. **Does not** produce any `AnimBasis.time` output
  yet, even though `Anim.basis` already exists in the model — Test G5 exists specifically to pin
  this down.
- **Files**: `lib/src/ui/bodymovin/bodymovin_import.dart`
- **Dependencies**: Tasks 3.3, 4.1
- **Verification**: Test G5 (all-scroll-basis, no time-basis anims created), B2 (custom-ratio-
  equivalent scaling consistency, now scoped to `scrollSpeed`), G6's import half (feeds the
  round-trip test in Phase 7).
- **Complexity**: High

#### Task 4.3: Easing precision choice (`EasingChoice`)
- **Description**: `exactCubicFit` vs. `easyEaseApproximation` — per Test B3's own finding, both
  currently converge to `.comics`'s one fixed cubic ease-out for AE's standard Easy Ease handles, so
  this choice is real and wired through but not yet observably different in output for typical
  content. Applies identically in both modes.
- **Files**: `lib/src/ui/bodymovin/bodymovin_import.dart`
- **Dependencies**: Task 2.1
- **Verification**: Test B3 — both choices produce valid, currently-equal `Anim` easing for the
  real Easy Ease case; add a synthetic non-Easy-Ease bezier case to confirm the two choices
  genuinely diverge when the input curve isn't already a close match (not exercised by real content
  today, per Requirements, but the code path should still be distinguishable in a contrived test).
- **Complexity**: Medium

#### Task 4.4: `TextRegion` import (Bodymovin vector mask → polygon)
- **Description**: A Bodymovin layer's `masksProperties` vector path → `TextRegion(shape: "polygon")`.
  Per Test C2: Bodymovin masks are always vector, never raster, so Bodymovin import should never produce
  `TextRegion.shape == "mask"` — only `comics-ai-baloons`'s own raster path does that (out of scope
  here, tracked in that flow's own follow-on task).
- **Files**: `lib/src/ui/bodymovin/bodymovin_import.dart`
- **Dependencies**: Tasks 1.3, 2.1
- **Verification**: Test C1 (real content has zero masks — confirms this path is simply never
  exercised by real data today, not a silent gap); Test C2 (hand-crafted mask-bearing file →
  correct polygon).
- **Complexity**: Medium

### Phase 5: `buildBodymovinExport`

#### Task 5.1: `buildBodymovinExport` — Full Canvas mode
- **Description**: Composition `w`/`h` = `doc.width`/`doc.height`; each `EditorLayer` → one `ty:2`
  layer; frame numbers = `Anim.start`/`end` directly, no ratio.
- **Files**: `lib/src/ui/bodymovin/bodymovin_export.dart` (new)
- **Dependencies**: Task 2.1
- **Verification**: Test G1, D1.
- **Complexity**: Medium

#### Task 5.2: `buildBodymovinExport` — Playback Viewport mode (scene partitioning + sweep synthesis)
- **Description**: Per Specifications' DECIDED scene-boundary convention: partition the canvas into
  sequential `ComicsDoc.preferredViewportHeight`-tall bands (Task 1.5). Each band → one precomp with
  exactly one root-level position keyframe pair sweeping it past the viewport at the supplied/
  detected constant scroll speed — matching `ASHES.json`'s real "All Objects1"/"All Objects2" shape.
  Each layer's scroll-basis `Anim` contributes to the sweep's baseline; any time-basis `Anim`
  composes on top via `KeyframeInterpolator`'s already-shipped rule, unchanged, just consumed here.
- **Files**: `lib/src/ui/bodymovin/bodymovin_export.dart`
- **Dependencies**: Tasks 1.5, 1.6, 5.1
- **Verification**: Test G4 — confirm output composition is viewport-sized, scenes match the band
  convention, sweep keyframes match the supplied speed.
- **Complexity**: High

#### Task 5.3: `groupId`-sharing layers → one shared precomp (both modes)
- **Files**: `lib/src/ui/bodymovin/bodymovin_export.dart`
- **Dependencies**: Tasks 1.1, 5.1
- **Verification**: Test D2.
- **Complexity**: Medium

#### Task 5.4: `TextRegion` export (`shape: "polygon"` → `masksProperties`)
- **Description**: The "genuine added benefit" Requirements identified — polygon regions map
  directly onto Bodymovin's native mask model. `shape: "mask"` (raster) has **no direct Bodymovin
  equivalent** — per Open Design Question D3, still unresolved: skip with a disclosed limitation
  (recommended default, simplest, no lossy step invented without Anton's sign-off) vs.
  rasterize/vectorize. **Implement the skip-with-limitation behavior now**; do not build the lossy
  rasterize/vectorize path speculatively — that's real, separate scope pending D3's resolution.
- **Files**: `lib/src/ui/bodymovin/bodymovin_export.dart`
- **Dependencies**: Tasks 1.3, 1.4, 5.1
- **Verification**: Test D3 (polygon case); a new test confirming `shape:"mask"` export produces a
  disclosed-limitation result (e.g. a logged/returned warning), not a crash or silent data loss.
- **Complexity**: Medium

### Phase 6: Review screen UI + menu entries

#### Task 6.1: "Import from .Bodymovin" / "Export to .Bodymovin" menu entries
- **Description**: New entries in `top_bar.dart` or `dialogs.dart` — explicitly **not** a
  repurposing of the existing Export button (`top_bar.dart:240-243`, confirmed a different,
  existing `.comics`-to-`.comics` mechanism).
- **Files**: `lib/src/ui/widgets/top_bar.dart` or `dialogs.dart`
- **Dependencies**: None (can be stubbed ahead of Phases 3-5 landing, wired last)
- **Verification**: Manual — menu entries visible, route to the new dialog/file picker.
- **Complexity**: Low

#### Task 6.2: Review screen widget (Category A/B/G UI)
- **Description**: Per Джанава-informed UI entry-point decision — a real triage screen, not a
  silent one-shot conversion. Shows: detected `ExportImportMode` (with override, Task 3.1); per-
  layer clean/flagged/grouped/scened status; `scrollSpeed` (playbackViewport only, pre-filled per
  Task 3.3, editable); `EasingChoice`; running clean/flagged counts; explicit "commit import" vs.
  "cancel" actions (Test A4 — cancel must be a true no-op).
- **Files**: `lib/src/ui/widgets/bodymovin_import_dialog.dart` (new)
- **Dependencies**: Tasks 3.1, 3.2, 3.3, 4.3
- **Verification**: Manual — real mixed-content file shows legible flagged/clean states; Test A1
  end-to-end through the actual widget (not just the underlying `ImportPreview` model).
- **Complexity**: High

#### Task 6.3: Wrong-mode display (Test G7)
- **Description**: When the detected mode differs from what the user picks (override case), or a
  fullCanvas-mode import produces obviously-scene-shaped root layers, surface this rather than
  silently proceeding — per Test G7's "no crash, visibly wrong, not silently broken" bar. Exact UI
  treatment (a warning banner? blocking confirmation?) not fully specified — build the simplest
  version (a visible warning banner, non-blocking) and revisit if this proves insufficient.
- **Files**: `lib/src/ui/widgets/bodymovin_import_dialog.dart`
- **Dependencies**: Task 6.2
- **Verification**: Test G7 — import `sample_playback_viewport.Bodymovin_unzip` in fullCanvas mode,
  confirm the warning appears and the import still completes (not blocked).
- **Complexity**: Medium

#### Task 6.4: Real image-byte extraction for imported layers (NEW, disclosed during Task 4.1)
- **Description**: `commitImport` (Phase 4, done) creates real `EditorLayer`s but leaves `images`
  as the constructor's own placeholder — it has no access to a document's real
  `CoreDocument.tempFolder`, which `lib/src/io/tile_writer.dart`'s `writeTiles` needs to write real
  pixel files. This task closes that gap at the controller level, which *does* have real
  tempFolder access once a document is open: after `commitImport` runs, walk `preview.layers`
  (still available, same order `doc.layers` was appended in) alongside `preview.document.assets`,
  decode each clean layer's source asset (real content: always a base64 data URI, per Phase 2's
  finding — `data:image/...;base64,<payload>`; the external-file-reference branch has no real
  content to exercise but should still be handled, reading the bytes from the already-unzipped
  archive rather than a data URI), and call `writeTiles` to materialize a real tile file, then set
  the resulting `EditorLayer.images[0].file` to the returned `TiledImage.fileTemplate`.
- **Files**: `lib/src/ui/controller.dart` (the real caller with `tempFolder` access), possibly a
  new small helper in `bodymovin_import.dart` for the base64-decode step
- **Dependencies**: Task 6.1 (needs a real open-document context to call this against), Phase 4
- **Verification**: New test — import a real fixture, confirm at least one imported layer's image
  file actually exists on disk with real, non-empty pixel content (not just a placeholder
  filename); confirm the canvas actually renders real artwork, not blank layers, for a manually
  imported file.
- **Complexity**: Medium

### Phase 7: Round-trip integration tests (real fixtures)

#### Task 7.1: E1 — `samples/sample.Bodymovin` round-trip
- **Description**: Import → export → re-import → compare rendered transforms at sampled scroll
  positions within tolerance.
- **Files**: `test/bodymovin_roundtrip_test.dart` (new)
- **Dependencies**: Phases 3-5 complete
- **Verification**: Test E1 itself.
- **Complexity**: Medium

#### Task 7.2: G3 — Full Canvas round-trip (fixture prep + corrected direction)
- **Description**: One-time fixture prep — export `samples/sample_v2012.comics_unzip` to `.Bodymovin`
  (fullCanvas mode) to produce a real Full-Canvas-shaped `.Bodymovin` file. The round-trip test itself
  then runs `.Bodymovin → .comics → .Bodymovin` against that derived file — **not**
  `.comics → .Bodymovin → .comics`, per Anton's direct correction (2026-08-08).
- **Files**: `test/bodymovin_roundtrip_test.dart`
- **Dependencies**: Task 7.1's harness, Phases 3-5
- **Verification**: Test G3 itself.
- **Complexity**: Medium

#### Task 7.3: G6 — Playback Viewport round-trip (real ASHES-based sample)
- **Description**: `samples/sample_playback_viewport.Bodymovin_unzip` → import (playbackViewport,
  auto-derived scroll speed) → export back (same speed) → compare.
- **Files**: `test/bodymovin_roundtrip_test.dart`
- **Dependencies**: Task 7.1's harness, Phases 3-5
- **Verification**: Test G6 itself.
- **Complexity**: Medium

#### Task 7.4: F1/F2 error-handling tests
- **Description**: Corrupt/non-Bodymovin JSON rejected before any preview UI renders (F1); a
  deliberately-broken copy of a real sample (one asset removed) flags that layer, not a fatal
  whole-file error (F2).
- **Files**: `test/bodymovin_import_test.dart` (new)
- **Dependencies**: Task 2.2
- **Verification**: F1/F2 themselves.
- **Complexity**: Low

## Dependency Graph

```
Phase 1 (schema prereqs) ──────────┬──→ Phase 3 (mode detection + ImportPreview) ──→ Phase 4 (commitImport)
                                    │                                                      │
Phase 2 (pure Bodymovin I/O) ─────────┴──→ Phase 5 (buildBodymovinExport) ←────────────────────┘
                                                        │
                                              Phase 6 (UI) ←── Phases 3/4/5
                                                        │
                                              Phase 7 (round-trip integration) ←── Phases 3/4/5 complete
```

Phase 1 and Phase 2 have no dependency on each other and can proceed in parallel. Phase 6 (UI) can
be scaffolded early (Task 6.1) but its real content (6.2/6.3) needs Phases 3/4 done. Phase 7 is
last by construction — it exercises the whole pipeline end-to-end against real fixtures.

## File Change Summary

| File | Action | Reason |
|------|--------|--------|
| `lib/src/ui/models.dart` | Modify | `EditorLayer.groupId`/`.textRegion`, `TextRegion` class, `ComicsDoc.preferredViewportWidth`/`Height` |
| `lib/src/bridge/models_mapping.dart` | Modify | JSON round-trip for all fields above |
| `lib/src/bridge/bodymovin_mapping.dart` | Create | `BodymovinDocument` model + parse/write |
| `lib/src/ui/bodymovin/bodymovin_import.dart` | Create | `ExportImportMode`, `ImportPreview`, `commitImport` |
| `lib/src/ui/bodymovin/bodymovin_export.dart` | Create | `buildBodymovinExport`, both modes |
| `lib/src/ui/widgets/bodymovin_import_dialog.dart` | Create | The review screen |
| `lib/src/ui/widgets/top_bar.dart` or `dialogs.dart` | Modify | New menu entries |
| `test/bodymovin_roundtrip_test.dart`, `test/bodymovin_import_test.dart` | Create | Integration/error-handling tests |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Scene-detection heuristic (Task 3.1/3.3) misfires on real content shaped differently from `ASHES.json` | Medium | Medium | Only 2 real Playback-Viewport-shaped files exist to validate against (both from the same source pipeline) — ship the detected-mode-with-override UI (Task 3.1/6.2) so a misdetection is always correctable, never a hard failure |
| `groupId` vs. `parentId` relationship (still an open Specifications question) causes duplicate/ conflicting grouping UI once `vdd-comics-editor-systematization-uiux`'s own `GroupId` design is eventually built | Medium | Medium | This flow's `groupId` usage (precomp-flattening) and `tdd-dot-comics-format`'s `ParentId` (hierarchy) already coexist by design in `03-specifications.md` — no new risk introduced here, same open question carried forward |
| Easing precision choice (Task 4.3) has no real content that currently distinguishes it — risk of under-testing a code path that "looks done" but never diverges | Low | Low | Task 4.3 explicitly adds a synthetic non-Easy-Ease test case specifically to force the two choices to diverge in test, not just real-content parity |
| `TextRegion.shape == "mask"` export gap (Task 5.4, D3) shipped as skip-with-limitation without Anton's explicit sign-off on that specific choice | Medium | Low | Disclosed directly in this plan and in Task 5.4's own description — not silently decided; flagged for Anton to override before/during Implementation if a different choice is preferred |

## Rollback Strategy

Every new field (Phase 1) is additive/nullable — reverting them costs nothing for old readers, same
as every prior schema addition in this format's history. Phases 2-7 are entirely new files/menu
entries with no modification to any existing rendering/interpolation path (`KeyframeInterpolator` is
explicitly "consumed, not modified" per Specifications) — reverting any phase means deleting its new
files and menu entries, with zero risk to existing `.comics`/`.puzzle` functionality.

## Checkpoints

After each phase, verify:

- [ ] All tests pass, including the full existing `apps/comics-editor` suite (419 tests as of
      `tdd-dot-comics-format`'s last Implementation checkpoint) — this flow must not regress it
- [ ] No new warnings/errors (`flutter analyze` clean)
- [ ] Behavior matches `03-specifications.md`; real-fixture round-trips (Phase 7) pass within
      tolerance

## Open Implementation Questions

- [ ] G5's scroll/time classification heuristic for Playback Viewport import — ships as heuristic
      (a) (Task 4.2, everything scroll-basis); (b)/(c) are real, deliberately deferred improvements.
- [ ] D3's raster-`TextRegion` export gap — Task 5.4 implements skip-with-limitation as the default;
      not yet Anton-confirmed as the final choice over lossy rasterize/vectorize.
- [ ] The 2 deferred Text Region sub-questions (`isHandLettered`/`Style` relationship, coordinate
      space) — Task 1.3 implements the struct as specified either way, but the exact semantics of
      these two fields may need revisiting once resolved.
- [ ] Whether the mask exclusion (Won't-Have) gets re-confirmed now that it's known to drop real
      content (`THE CHASE`'s 6 masked layers) — not addressed by any task above; masks remain
      out of scope for this plan pending that re-confirmation.
- [ ] Deeply-parented layer chain review-screen visualization (Task 6.2's exact tree/indent UI for
      `THE BROKEN TUSK`-depth chains) — build the shallow case first (matches `ASHES.json`'s real
      structure, which has no deep parenting), revisit if/when a real deeply-parented Bodymovin file
      needs importing.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-08
- [x] Notes: Approved as drafted. The 6 Open Implementation Questions stand as their stated
      shipped-default behaviors (heuristic (a) for G5, skip-with-limitation for D3, etc.) unless
      revisited during Implementation.
