# Implementation Plan: comics-editor-ai-uiux

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-08-01
> Specifications: [03-specifications.md](03-specifications.md)

## Summary

Seven phases, ordered so the riskiest/most novel piece (the new Python single-image CLI) lands
first and is fully tested standalone before any Dart code depends on it, mirroring the lettering
flow's own risk-ordering logic. A `StubCuttingClient` (Phase 2) unblocks all UI work (Phases 4-6)
without waiting on the real subprocess integration (Phase 2's `ProcessCuttingClient`) to be fully
debugged — same reasoning the lettering flow used for `StubBalloonAiClient`. `EditorController`
state/mutations (Phase 3) come before UI so the UI tasks have real methods to call, not
placeholders. Confirmed by Specifications: **no C#/schema changes and no new RPC anywhere in this
plan** — every native-side task the lettering flow needed is already done; this flow only adds new
Dart files/methods plus one new Python script.

## Task Breakdown

### Phase 1: Python — Single-Image Segmentation CLI

#### Task 1.1: Refactor `infer_segmenter.py` to expose a reusable, crop-producing function
- **Description**: Extract `infer_regions_with_crops(model, image_bgr, device)` from the existing
  `infer_regions()` — same connected-components logic, but (a) rescales each region's bbox from
  `TRAIN_SIZE` (256×256) back to `image_bgr`'s real dimensions, and (b) also returns each region's
  rectangular crop (`image_bgr` sliced by the *rescaled* bbox, not the resized one) alongside
  kind/confidence/bbox. Existing `infer_regions()`/`infer_all()`/`regions.jsonl`'s batch schema stay
  unchanged — this is an additive sibling function, not a breaking change to the batch pipeline
  (Specifications Finding 5/6).
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/infer_segmenter.py` - Modify
- **Dependencies**: None
- **Verification**: Unit test — feed a known synthetic image + a fixed model checkpoint, confirm
  returned bboxes are in the *input* image's coordinate space (not 256×256), and each crop's pixel
  dimensions match its bbox
- **Complexity**: Medium (coordinate-rescaling math is easy to get subtly wrong — verify against a
  non-square test image specifically, since a square test image can hide an x/y or w/h swap bug)

#### Task 1.2: `segment_image.py` — new single-image CLI + NDJSON protocol
- **Description**: New script per Specifications' Interfaces section: loads
  `work/models/unet_baseline.pt`, reads one image path, calls `infer_regions_with_crops`, prints
  NDJSON events (`routing` → `progress`* → `success`/`failure`) to stdout, base64-encodes each
  region's crop into `crop_png_base64`. `routing` always reports `on_device: true` this iteration
  (no server path exists).
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/segment_image.py` - Create
- **Dependencies**: Task 1.1
- **Verification**: CLI test — run against a real photo from
  `dataset/.../comics_book_lowcamera/` with the real trained checkpoint, confirm stdout is valid
  NDJSON ending in a `success` event with ≥1 region, and each `crop_png_base64` decodes to a valid
  PNG matching its `bbox`'s dimensions
- **Complexity**: Medium

#### Task 1.3: Failure-path coverage
- **Description**: Missing checkpoint (`model_checkpoint_not_found`), unreadable/corrupt image
  file, and unhandled-exception-as-`process_error` (non-zero exit, no structured `failure` event —
  the Dart side must handle this case too, but the *script* should still try to emit a `failure`
  line before a controlled non-zero exit wherever the error is anticipated).
- **Files**:
  - `apps/comics-ai/comics-multimodal/scripts/segment_image.py` - Modify
- **Dependencies**: Task 1.2
- **Verification**: Unit tests for each failure path (missing checkpoint, missing image, corrupt
  image bytes)
- **Complexity**: Low

### Phase 2: Dart — Cutting Client Contract

#### Task 2.1: `MultimodalCuttingClient` contract + `DetectedRegion`/`CuttingEvent` types
- **Description**: The abstract interface and sealed event/data classes from Specifications'
  Interfaces section (`cropPng`, not `maskPng` — the disclosed rename).
- **Files**:
  - `apps/comics-editor/lib/src/ai/cutting_client.dart` - Create
- **Dependencies**: None
- **Verification**: Compiles; no behavior to test yet (pure types)
- **Complexity**: Low

#### Task 2.2: `StubCuttingClient`
- **Description**: Deterministic fake mirroring `StubBalloonAiClient`'s shape — configurable outcome
  (success with N canned regions / various failures), no randomness, so manual walkthroughs and
  tests are reproducible. Unblocks Phases 4-6 without the real subprocess.
- **Files**:
  - `apps/comics-editor/lib/src/ai/stub_cutting_client.dart` - Create
- **Dependencies**: Task 2.1
- **Verification**: Unit test — stub emits the expected event sequence for each configured outcome
- **Complexity**: Low

#### Task 2.3: `MultimodalPaths` discovery
- **Description**: Env-var-override + upward-directory-search resolver for the Python interpreter,
  `comics-multimodal/scripts` dir, and `work/library` dir — mirrors
  `CoreClient.resolveBinary()`'s exact search pattern (env var first, then up to 6 parent
  directories from CWD).
- **Files**:
  - `apps/comics-editor/lib/src/ai/multimodal_paths.dart` - Create
- **Dependencies**: None
- **Verification**: Unit test — env var override wins when set; upward search finds a real
  `apps/comics-ai/comics-multimodal` checkout when run from a subdirectory of this repo; returns
  null (not a throw) when nothing is found
- **Complexity**: Low

#### Task 2.4: `ProcessCuttingClient` (real desktop implementation)
- **Description**: Spawns `segment_image.py` via `dart:io Process.start` using `MultimodalPaths`,
  writes `sourceImageBytes` to a temp file, parses NDJSON stdout lines into `CuttingEvent`s
  (base64-decoding `crop_png_base64` into `DetectedRegion.cropPng`), maps a non-zero exit with no
  structured `failure` line to `Failure(reason: "process_error", retryable: true)` (mirrors
  `CoreClient._onExit`'s stderr-tail pattern). Supports cancellation via `Process.kill()`.
- **Files**:
  - `apps/comics-editor/lib/src/ai/process_cutting_client.dart` - Create
- **Dependencies**: Task 2.1, Task 2.3
- **Verification**: Integration test against the **real** `segment_image.py` (Phase 1) with a real
  checkpoint + real photo — at least one full success run, one missing-checkpoint failure, one
  cancel-mid-run
- **Complexity**: Medium (subprocess/stream-parsing edge cases — partial lines, interleaved
  stderr — same category of risk `CoreClient` already solved once; reuse its line-buffering
  approach rather than re-deriving it)

### Phase 3: EditorController — Cutting State & Mutations

#### Task 3.1: `CuttingSession`/`PendingRegion` state + `triggerCutting`
- **Description**: New controller state holding the in-progress session (source bytes/layer index,
  regions with pending/accepted/rejected status), and the method that starts a
  `MultimodalCuttingClient.segment()` stream and updates state as events arrive.
- **Files**:
  - `apps/comics-editor/lib/src/ui/controller.dart` - Modify
- **Dependencies**: Task 2.1 (needs the client contract; can build against `StubCuttingClient` from
  Task 2.2 immediately, real client wired in later)
- **Verification**: Unit test — drive with `StubCuttingClient`, confirm `CuttingSession` populates
  correctly through routing/progress/success and through a failure path
- **Complexity**: Medium

#### Task 3.2: `acceptRegion` — the region-to-layer path
- **Description**: The core new-plumbing task per Specifications' Data Flow: `writeTiles` the
  region's `cropPng` into `tempFolder/layers/` (identical call shape to `setImageFile`'s Task-2.3
  pattern from the lettering flow), create a new `EditorLayer` with `kind` set from the region, add
  a `TranslateAnim` at `sourceLayer.translate + region.bbox.origin` (Specifications Finding 4 — no
  `size`/scale math needed), add it to `doc.layers`, wrap in `_beginHistory()/_commitHistory()`.
- **Files**:
  - `apps/comics-editor/lib/src/ui/controller.dart` - Modify
- **Dependencies**: Task 3.1
- **Verification**: Integration test — accept a stub-provided region, `saveComics`, reopen, confirm
  the new layer exists with correct `kind` and correct on-disk tile files; confirm position math
  against a known `sourceLayer.translate` + known bbox
- **Complexity**: Medium

#### Task 3.3: `rejectRegion` / `reclassifyRegion` / `adjustRegionBbox`
- **Description**: The remaining `CuttingSession`-only mutations (no tile writes, no layer created)
  — reject marks status, reclassify changes `PendingRegion.region.kind` pre-accept, adjustBbox
  updates the region's rect from a canvas resize-handle drag.
- **Files**:
  - `apps/comics-editor/lib/src/ui/controller.dart` - Modify
- **Dependencies**: Task 3.1
- **Verification**: Unit tests for each — confirm no filesystem writes occur, `notifyListeners()`
  fires, state updates correctly
- **Complexity**: Low

#### Task 3.4: `insertIntoLibrary`
- **Description**: Writes an accepted (or any pending) region's `cropPng` into
  `work/library/<kindDir>/<name>/<generated-filename>.png` via `MultimodalPaths.resolveLibraryDir()`
  — plain filesystem append, `name` from a corrector-typed field (the small addition to
  `02-visual.md`'s card noted in Specifications' Open Design Questions), defaulting to
  `"unclustered"`.
- **Files**:
  - `apps/comics-editor/lib/src/ui/controller.dart` - Modify
- **Dependencies**: Task 2.3
- **Verification**: Integration test — insert into a fresh name (creates the directory) and into an
  existing name (appends without disturbing existing files)
- **Complexity**: Low

### Phase 4: Cutting Mode UI — Canvas & Review Card

#### Task 4.1: `cutting_canvas.dart` — bespoke real-pixel canvas
- **Description**: New widget (Specifications Finding 3: does **not** modify or extend
  `canvas_view.dart`, which stays swatch-only for every other layer kind). Decodes
  `sourceImageBytes`, draws it at native resolution, overlays one box per region colored by kind at
  reduced opacity, the selected region full-opacity with a dark spotlight (per `02-visual.md`'s
  high-fidelity reference) and 8 resize handles that call `adjustRegionBbox` on drag. Includes the
  bottom-left zoom control and the persistent bottom-right routing/source indicator.
- **Files**:
  - `apps/comics-editor/lib/src/ui/widgets/cutting_canvas.dart` - Create
- **Dependencies**: Task 3.1, Task 3.3
- **Verification**: Manual, against `02-visual.md`'s macOS results screen and the high-fidelity
  mockup, using `StubCuttingClient`'s canned regions
- **Complexity**: High (custom paint/hit-testing for 8 resize handles + multi-region overlay
  rendering is the most novel UI work in this plan — closest precedent is
  `canvas_view.dart`'s existing `_WithHandles`, reusable for handle *shape*, not its
  placeholder-swatch rendering)

#### Task 4.2: `cutting_review_card.dart` — shared, kind-parameterized card
- **Description**: The component from `02-visual.md`'s Component section: header (kind chip +
  confidence badge), crop preview, kind reclassify dropdown, kind-conditional actions ("Insert into
  library" for character/background, "Open in Lettering" for balloon), Accept/Reject.
- **Files**:
  - `apps/comics-editor/lib/src/ui/widgets/cutting_review_card.dart` - Create
- **Dependencies**: Task 3.2, Task 3.3, Task 3.4
- **Verification**: Manual walkthrough of every kind + every state (pending/accepted/rejected,
  stale) against `02-visual.md`
- **Complexity**: Medium

#### Task 4.3: Region rail + header status summary + bulk accept
- **Description**: The left-hand region list (kind chip, confidence badge, accept/reject icon per
  row per the high-fidelity reference), the header's `"N regions · N pending · N accepted · N
  rejected"` summary, and the `[ Accept all >90% ]` bulk action with an adjustable threshold
  (Should Have, included here since it shares the rail's data).
- **Files**:
  - `apps/comics-editor/lib/src/ui/widgets/cutting_region_rail.dart` - Create
- **Dependencies**: Task 3.1, Task 3.2, Task 3.3
- **Verification**: Manual, against `02-visual.md`'s rail mockup and legend cards
- **Complexity**: Medium

#### Task 4.4: Trigger/empty, running, and stale/failure states
- **Description**: The screen states around the results screen: source picker + "Cut / Segment"
  button (empty), progress + routing indicator + Cancel (running), stale-source banner, failure card
  with Retry/View details.
- **Files**:
  - `apps/comics-editor/lib/src/ui/widgets/cutting_canvas.dart` - Modify (or a small sibling
    trigger-screen widget, if cleaner — decide at implementation time)
- **Dependencies**: Task 3.1, Task 2.4 (real `Failure`/`Progress` shapes to design against, though
  `StubCuttingClient` can substitute during initial building)
- **Verification**: Manual, forcing each `StubCuttingClient` outcome
- **Complexity**: Medium

### Phase 5: Library Tab

#### Task 5.1: `library_browser.dart` — directory-backed browser
- **Description**: Lists `work/library/characters/*` and `.../environments/*` via
  `MultimodalPaths.resolveLibraryDir()` — folder name = cluster name, file count = crop count, no
  manifest file (none exists, per Specifications). Search/filter by name (Should Have). Empty
  states: library dir missing entirely, and a name-filtered empty result.
- **Files**:
  - `apps/comics-editor/lib/src/ui/widgets/library_browser.dart` - Create
- **Dependencies**: Task 2.3
- **Verification**: Manual — point at a real `work/library/` produced by
  `sdd-comics-ai-multimodal`'s pipeline, confirm real clusters (e.g. `amba`) list correctly with
  correct counts
- **Complexity**: Low

#### Task 5.2: "Insert as layer" from the Library tab
- **Description**: Reads a chosen library PNG's bytes, reuses the same `writeTiles` + `EditorLayer`
  creation path as `acceptRegion` (Task 3.2), with `kind` derived from which top-level folder
  (`characters` → `"character"`, `environments` → `"background"`) and a default position (no bbox
  context here, unlike an accepted region — place at a sensible default offset, e.g. same as
  `addLayer()`'s incremental-offset convention).
- **Files**:
  - `apps/comics-editor/lib/src/ui/controller.dart` - Modify
  - `apps/comics-editor/lib/src/ui/widgets/library_browser.dart` - Modify
- **Dependencies**: Task 5.1, Task 3.2 (shares its tile-write/layer-creation logic — consider
  extracting a small shared helper if the duplication is more than a few lines)
- **Verification**: Manual + integration test — insert a real library item, confirm it round-trips
  through save/reopen
- **Complexity**: Low

### Phase 6: Mode Switch & Platform Behavior

#### Task 6.1: `EditorMode.cutting` + top-bar segment
- **Description**: Add `cutting` to the existing `EditorMode` enum and `kEditorModes` list
  (`controller.dart`), a third `HsSegmented` option in `top_bar.dart`, and the corresponding body
  branch in `editor_screen.dart`'s mode switch (alongside the existing `edit`/`lettering` branches).
- **Files**:
  - `apps/comics-editor/lib/src/ui/controller.dart` - Modify
  - `apps/comics-editor/lib/src/ui/widgets/top_bar.dart` - Modify
  - `apps/comics-editor/lib/src/ui/screens/editor_screen.dart` - Modify
- **Dependencies**: Task 4.1, Task 4.2, Task 4.3, Task 4.4, Task 5.1 (needs the mode's content to
  exist before wiring it in, though the switch itself could be stubbed earlier if useful for
  incremental manual testing)
- **Verification**: Manual — switch cycles through all three modes on desktop, Edit/Lettering
  unaffected
- **Complexity**: Low

#### Task 6.2: Mobile disabled state
- **Description**: On `Platform.isIOS || Platform.isAndroid` (the same OS-level check
  `dialogs.dart`'s `_isMobile` and `comics_core.dart`'s `createComicsCore()` already use — not
  `FormFactor`, which is about screen width, not capability), the Cutting segment renders
  grayed/disabled; tapping it shows a popover (tablet/desktop width, `FormFactor.tablet` /
  `FormFactor.desktop`) or an inline note under the switch (`FormFactor.phone`), per
  `02-visual.md`'s two mockups, with the cross-device-sync clarifying sentence from the
  high-fidelity reference.
- **Files**:
  - `apps/comics-editor/lib/src/ui/widgets/top_bar.dart` - Modify
- **Dependencies**: Task 6.1
- **Verification**: Manual, on an iOS/Android build (or simulator) — confirm popover on
  tablet-width, inline note on phone-width, and that tapping never enters a broken Cutting mode
- **Complexity**: Low

### Phase 7: Testing & Polish

#### Task 7.1: Full test suite pass
- **Description**: Run every unit/integration test from Phases 1-6 together; fix any interaction
  bugs found only when combined (e.g. `ProcessCuttingClient` + real `acceptRegion` end-to-end).
- **Files**: None (test execution)
- **Dependencies**: All prior phases
- **Verification**: All tests green
- **Complexity**: Medium

#### Task 7.2: Real end-to-end verification
- **Description**: Per this project's own established discipline (`sdd-comics-ai-multimodal`
  verified every phase against real data, not just stubs) — cut a real photo from
  `comics_book_lowcamera/` using the real trained checkpoint through the real desktop app, accept at
  least one region of each kind, save, reopen, confirm layers are correct.
- **Files**: None (manual + scripted verification)
- **Dependencies**: Task 7.1
- **Verification**: Documented in `05-implementation-log.md` with concrete before/after evidence
  (mirrors the SDD flow's own verification write-ups)
- **Complexity**: Medium

#### Task 7.3: Cross-device check
- **Description**: Cut a page on macOS/Windows/Linux, open the saved `.comics` file on an iOS/
  Android build, confirm the new layers appear normally in Edit mode (kind chips set) and the
  Cutting switch shows disabled there — the concrete test of the cross-device-sync clarification
  from `02-visual.md`'s high-fidelity reference.
- **Files**: None (manual verification)
- **Dependencies**: Task 6.2, Task 7.2
- **Verification**: Manual, both platforms
- **Complexity**: Low

#### Task 7.4: Full state-coverage walkthrough
- **Description**: Every state in `02-visual.md` (trigger/empty, running, results, stale, failure,
  Library tab empty/populated/filtered, mobile disabled popover/inline-note) against the running
  app.
- **Files**: None (manual verification)
- **Dependencies**: All prior phases
- **Verification**: Manual, checklist-driven against `02-visual.md`
- **Complexity**: Medium

## Dependency Graph

```
1.1 (infer_segmenter refactor) ──→ 1.2 (segment_image.py) ──→ 1.3 (failure paths)
                                          │
2.1 (contract types) ──┬──→ 2.2 (StubCuttingClient) ─────────────┐
                        │                                          │
                        └──→ 2.4 (ProcessCuttingClient) ←── 1.3   │  (real subprocess wiring —
                        │         ↑ (needs 2.3 too)               │   can trail Phase 4-6 UI work)
2.3 (MultimodalPaths) ──┘                                          │
        │                                                          │
        ├──────────────────────────────────────────────┐          │
        ↓                                                ↓          ↓
3.1 (CuttingSession/trigger) ←──────────────────────── 2.2 ────────┘
        │
        ├──→ 3.2 (acceptRegion) ──┬──→ 4.2 (review card) ──┐
        ├──→ 3.3 (reject/reclassify/adjust) ───────────────┼──→ 4.3 (region rail)
        └──→ 3.4 (insertIntoLibrary) ────────────────────┐ │
                                                            ↓ ↓
                                              4.1 (cutting_canvas) ──→ 4.4 (trigger/running/stale/failure)
                                                            │
5.1 (library_browser) ──→ 5.2 (insert as layer) ────────────┤
                                                            ↓
                                    6.1 (mode switch) ──→ 6.2 (mobile disabled)
                                                            │
                                    7.1 ──→ 7.2 ──→ 7.3   7.4 (all of the above)
```

(Simplified — see per-task Dependencies for the exact list. The two independent tracks — Python
[Phase 1] and Dart contract/stub [Phase 2.1-2.2] — can start in parallel; `ProcessCuttingClient`
[2.4] is the one task that genuinely bridges them and can slot in late without blocking UI work.)

## File Change Summary

| File | Action | Reason |
|------|--------|--------|
| `apps/comics-ai/comics-multimodal/scripts/infer_segmenter.py` | Modify | New `infer_regions_with_crops` (real-pixel bbox + crop export) |
| `apps/comics-ai/comics-multimodal/scripts/segment_image.py` | Create | New single-image NDJSON CLI |
| `apps/comics-editor/lib/src/ai/cutting_client.dart` | Create | Contract + event/data types |
| `apps/comics-editor/lib/src/ai/stub_cutting_client.dart` | Create | Deterministic fake |
| `apps/comics-editor/lib/src/ai/multimodal_paths.dart` | Create | Interpreter/script/library path discovery |
| `apps/comics-editor/lib/src/ai/process_cutting_client.dart` | Create | Real desktop subprocess client |
| `apps/comics-editor/lib/src/ui/controller.dart` | Modify | `CuttingSession` state, `triggerCutting`/`acceptRegion`/`rejectRegion`/`reclassifyRegion`/`adjustRegionBbox`/`insertIntoLibrary`, `EditorMode.cutting` |
| `apps/comics-editor/lib/src/ui/widgets/cutting_canvas.dart` | Create | Bespoke real-pixel region-overlay canvas |
| `apps/comics-editor/lib/src/ui/widgets/cutting_review_card.dart` | Create | Shared kind-parameterized review card |
| `apps/comics-editor/lib/src/ui/widgets/cutting_region_rail.dart` | Create | Region list + header summary + bulk accept |
| `apps/comics-editor/lib/src/ui/widgets/library_browser.dart` | Create | Library tab |
| `apps/comics-editor/lib/src/ui/widgets/top_bar.dart` | Modify | Third mode segment + mobile disabled popover/inline-note |
| `apps/comics-editor/lib/src/ui/screens/editor_screen.dart` | Modify | Cutting mode body branch |
| `native/Comics.Editor/Models/Layer.cs` | Unmodified | Already schema-ready (Specifications Finding 2) |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Bbox rescaling (Task 1.1) has a subtle coordinate-space bug (off-by-one, x/y swap, or aspect-ratio distortion since resize isn't aspect-preserving) | Medium | High (every downstream position depends on this being right) | Task 1.1's verification explicitly requires a non-square test image; Task 7.2's real end-to-end check catches any remaining drift visually |
| `cutting_canvas.dart`'s custom hit-testing for 8 resize handles across N overlapping regions is fiddly to get right (Task 4.1) | Medium | Medium | Reuse `canvas_view.dart`'s existing `_WithHandles` handle geometry/shape as a starting point rather than designing hit-testing from scratch |
| Python interpreter/environment discovery (Task 2.3) fails on the user's actual machine in ways not seen in dev testing (e.g. `python3` vs `python`, venv not activated) | Medium | Medium | `COMICS_MULTIMODAL_PYTHON` env var escape hatch mirrors `COMICS_CORE_PATH`'s existing precedent; Task 7.2 must be run on a fresh-ish environment, not just the dev machine that's had everything installed all along |
| `ProcessCuttingClient`'s NDJSON parsing chokes on interleaved stderr/partial lines (Task 2.4) | Low-Medium | Medium | `CoreClient` already solved this exact problem (line-splitting stdout, separately capturing stderr) — port its approach rather than re-deriving |
| Extending `EditorLayer`/`Layer` positioning via `TranslateAnim` (Task 3.2) breaks if a future change makes `.size`/scale load-bearing after all (Specifications Open Design Question) | Low | Low | Documented explicitly as an accepted v1 limitation; revisit only if scale ever becomes real |

## Rollback Strategy

1. Every change is additive — a new mode, new files, and `EditorLayer.kind` values the schema
   already accepts (Specifications Finding 2). Reverting is a standard `git revert`, no data
   migration in either direction.
2. If Phase 1 (Python CLI) proves harder than expected, Phases 3-6's UI work is not blocked —
   `StubCuttingClient` (Task 2.2) lets the entire corrector-facing UI be built and manually
   walked-through without the real subprocess; only Task 2.4 and the Phase 7 real-data verification
   would be deferred.
3. If Task 4.1's custom canvas proves too complex for this iteration, the whole Cutting mode can
   ship gated behind leaving `EditorMode.cutting` out of `kEditorModes` (never surfaced in the UI)
   with everything else already built and tested against the stub — not wasted work.

## Checkpoints

After each phase, verify:

- [ ] All unit/integration tests for that phase pass
- [ ] Manual verification steps for that phase are done, not skipped
- [ ] No regression in Edit mode or Lettering mode's existing functionality
- [ ] Nothing in `dataset/` was modified (read-only, per repo convention)

## Open Implementation Questions

- [ ] Exact temp-file lifecycle for `ProcessCuttingClient`'s source-image handoff to
      `segment_image.py` (Specifications Open Design Question) — decide during Task 2.4.
- [ ] Whether Task 4.4's trigger/running/stale/failure states live inside `cutting_canvas.dart` or
      a separate sibling widget — decide when starting Task 4.4, based on how large
      `cutting_canvas.dart` gets from Task 4.1.
- [ ] Whether Task 5.2's tile-write/layer-creation logic should be extracted into a shared helper
      with Task 3.2's `acceptRegion`, or left duplicated — decide once both exist and the actual
      overlap is visible.
- [ ] Exact default placement offset for Task 5.2's "insert as layer" (no bbox context available) —
      decide during implementation, following `addLayer()`'s existing incremental-offset
      convention unless that looks wrong once built.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-01
- [x] Notes: Approved as-is.
