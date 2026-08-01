# Implementation Log: comics-editor-ai-uiux

> Started: 2026-08-01
> Plan: [04-plan.md](04-plan.md)

## Progress Tracker

| Task | Status | Notes |
|------|--------|-------|
| 1.1 infer_segmenter.py refactor | Done | `infer_regions_with_crops` added, 2 new tests |
| 1.2 segment_image.py CLI | Done | Built with anticipated-failure handling from the start |
| 1.3 Failure-path coverage | Done | Folded into Task 1.2's implementation + tests |
| 2.1 cutting_client.dart contract | Done | |
| 2.2 StubCuttingClient | Done | 4 canned regions, one per kind |
| 2.3 MultimodalPaths | Done | |
| 2.4 ProcessCuttingClient | Done | Real subprocess + cancel, tested end-to-end |
| 3.1 CuttingSession + triggerCutting | Done | Includes cancelCutting |
| 3.2 acceptRegion | Done | Verified via real save/reopen round trip |
| 3.3 reject/reclassify/adjustRegionBbox | Done | Plus `unrejectRegion` (per 02-visual.md) |
| 3.4 insertIntoLibrary | Done | |
| 4.1 cutting_canvas.dart | Done | Trigger/running/failure/results states combined into one file |
| 4.2 cutting_review_card.dart | Done | |
| 4.3 cutting_region_rail.dart | Done | |
| 4.4 Trigger/running/stale/failure states | Done | Built as part of 4.1; stale-banner deferred, see Discoveries |
| 5.1-5.2 Library tab | Done | |
| 6.1 EditorMode.cutting + top-bar segment | Done | Real overflow regression found + fixed, see log |
| 6.2 Mobile disabled state | Done | Compact-row icon, not a 3-way segmented control -- see Deviations |
| 7.1 Full test suite pass | Done | 193/194 Dart + 108/108 Python, 1 pre-existing unrelated failure |
| 7.2 Real end-to-end verification | Done | Real subprocess + real checkpoint, full accept/save/reopen |
| 7.3 Cross-device check | Done (adapted) | DartIoCore round-trip test, not a literal device — see log |
| 7.4 Full state-coverage walkthrough | Done (adapted) | Automated widget-test coverage, not manual — see log |

## Session Log

### Session 2026-08-01 - Claude

**Started at**: Phase 1, Task 1.1
**Context**: Requirements/Visual/Specifications/Plan all approved this session; starting
Implementation from scratch.

#### Completed

- **Task 1.1**: `infer_regions_with_crops(model, image_bgr, device)` added to
  `apps/comics-ai/comics-multimodal/scripts/infer_segmenter.py` — rescales `infer_regions`'
  TRAIN_SIZE (256×256) bboxes back to the real image's pixel dimensions and returns each region's
  rectangular RGB crop. Verified with a non-square (300×600) synthetic image specifically, per the
  Plan's own risk note (a square test image would hide an x/y swap bug).
  - Files: `apps/comics-ai/comics-multimodal/scripts/infer_segmenter.py` (modify),
    `apps/comics-ai/comics-multimodal/tests/test_infer_segmenter.py` (2 new tests)
  - Verified by: `.venv/bin/python -m pytest tests/test_infer_segmenter.py -v` — 6/6 passed

- **Task 1.2 + 1.3** (built together): `apps/comics-ai/comics-multimodal/scripts/segment_image.py`
  created — new single-image NDJSON CLI (`routing` → `progress`×3 → `success`/`failure`). Anticipated
  failures (`model_checkpoint_not_found`, `image_not_readable`) emit a clean event + exit 0;
  genuinely unanticipated exceptions are deliberately left uncaught (crash + non-zero exit + no
  stdout event), which the Dart client maps to `process_error` — see 03-specifications.md's
  Interfaces section for the rationale.
  - Files: `apps/comics-ai/comics-multimodal/scripts/segment_image.py` (create),
    `apps/comics-ai/comics-multimodal/tests/test_segment_image.py` (create, 5 tests)
  - Verified by: `.venv/bin/python -m pytest tests/test_segment_image.py -v` — 5/5 passed,
    including a real subprocess CLI invocation against a real photo
    (`dataset/.../comics_book_lowcamera/20260731_153113.jpg`) and the real trained checkpoint
  - Full Python suite re-run after these changes: **108/108 passed** (up from 101 at the end of
    `sdd-comics-ai-multimodal`), no regressions.

- **Task 2.1**: `apps/comics-editor/lib/src/ai/cutting_client.dart` created —
  `MultimodalCuttingClient` abstract contract, `CuttingEvent` sealed hierarchy
  (`RoutingDecided`/`Progress`/`Success`/`Failure`), `DetectedRegion` (`kind`/`confidence`/`bbox`/
  `cropPng`). `cropPng`, not `maskPng`, per 03-specifications.md's disclosed rename.

- **Task 2.2**: `apps/comics-editor/lib/src/ai/stub_cutting_client.dart` created — deterministic
  fake with 4 default canned regions (one per kind: background/character/balloon/art), mirroring
  `StubBalloonAiClient`'s shape.
  - Files: `lib/src/ai/stub_cutting_client.dart` (create), `test/cutting_client_test.dart` (create,
    6 tests)
  - Verified by: `flutter test test/cutting_client_test.dart` — 6/6 passed

- **Task 2.3**: `apps/comics-editor/lib/src/ai/multimodal_paths.dart` created —
  `resolveCheckoutRoot`/`resolvePython`/`resolveScriptsDir`/`resolveLibraryDir`, mirroring
  `CoreClient.resolveBinary()`'s env-var-override + upward-search pattern.
  - Files: `lib/src/ai/multimodal_paths.dart` (create), `test/multimodal_paths_test.dart` (create,
    4 tests)
  - Verified by: `flutter test test/multimodal_paths_test.dart` — 4/4 passed, including finding
    the real `comics-multimodal` checkout and its `.venv` interpreter from this repo

- **Task 2.4**: `apps/comics-editor/lib/src/ai/process_cutting_client.dart` created — real
  subprocess client. `parseCuttingEventLine` exposed top-level (not private) for pure unit testing
  without spawning a process. `ProcessCuttingClient` takes optional `pythonResolver`/
  `scriptsDirResolver` constructor overrides (small testability seam beyond what Specifications/
  Plan literally specified — needed because `Platform.environment` can't be mutated from within a
  running Dart test process, so the `python_not_found` path couldn't otherwise be exercised
  deterministically).
  - Files: `lib/src/ai/process_cutting_client.dart` (create), `test/process_cutting_client_test.dart`
    (create, 11 tests)
  - Verified by: `flutter test test/process_cutting_client_test.dart` — 11/11 passed, including a
    real end-to-end subprocess spawn against the real `segment_image.py` + trained checkpoint + a
    real photo from `dataset/`, and a real cancel-mid-run test
  - Full Dart suite re-run: 147/148 passed. The one failure
    (`test/dataset_backward_compat_test.dart`) is **pre-existing and unrelated** — see Discoveries.

#### Deviations from Plan

- Added constructor-injectable `pythonResolver`/`scriptsDirResolver` to `ProcessCuttingClient`
  (Task 2.4) — not in Specifications/Plan, needed purely for deterministic testing of the
  `python_not_found` path (see above).
- Tasks 1.2 and 1.3 were implemented together in one pass rather than sequentially — the
  anticipated-failure handling Task 1.3 calls for was cheap enough to build directly into Task
  1.2's first draft rather than as a separate follow-up pass.

#### Discoveries

- **Pre-existing, unrelated test failure**: `test/dataset_backward_compat_test.dart`'s sanity check
  expects `dataset/`'s top level to directly contain ≥20 `.comics` files
  (`datasetDir.listSync()`, non-recursive). The real files live nested under
  `dataset/boranko/mahabharata/book1/comics_interactive/` (27 files, confirmed via `find`) — the
  same dataset-reorg-to-nested-layout issue `sdd-comics-ai-multimodal`'s implementation log already
  noted as breaking 2 of `comics-ai-baloons`'s own tests. Not touched by anything in this flow
  (no changes to `dart_io_core.dart`, `models_mapping.dart`, or dataset paths) — pre-existing,
  disclosed, not fixed (out of scope for this flow, same call made for the `comics-ai-baloons`
  instance of this issue).

- **Task 3.1**: `CuttingSession`/`PendingRegion`/`RegionStatus` classes + `triggerCutting`/
  `cancelCutting` added to `controller.dart`. `CuttingSession.completed` is an explicit flag, not
  inferred from `regions.isEmpty` — an initial draft's inference would have misread a legitimate
  zero-region Success as "still running" (caught before writing tests, see Discoveries).
- **Task 3.2**: `acceptRegion` — tile-writes the region crop, creates a real `EditorLayer` with
  `kind` set, positions it via a `TranslateAnim`. Verified through a **real save → reopen round
  trip** (not just in-memory state) that both `.x` and `.y` persist correctly — `EditorLayer`'s
  constructor only sets `.y` by default (matching today's `addLayer()`'s vertical-only offsets), so
  `.x` is set explicitly afterward in `acceptRegion`; the round-trip test is what actually proves
  this, not just reading the in-memory `translate` field back.
- **Task 3.3**: `rejectRegion`/`reclassifyRegion`/`adjustRegionBbox`, plus `unrejectRegion` (a small
  addition beyond the Plan's literal task list — needed to implement `02-visual.md`'s explicit
  "rejected rows stay visible/clickable, re-click returns to pending" behavior, which the Plan's
  task description didn't separately name but the approved Visual requires).
- **Task 3.4**: `insertIntoLibrary` — kind-gated (character→characters/, background→environments/,
  balloon/art→no-op, matching `build_library.py`'s own `KIND_TO_LIBRARY_DIR`), plain filesystem
  append. Added an injectable `resolveLibraryDir` field on `EditorController` (defaults to
  `MultimodalPaths.resolveLibraryDir`) — same testability reasoning as Task 2.4's resolver
  overrides, needed so tests don't write into the real shared `work/library/` directory.
  - Files: `apps/comics-editor/lib/src/ui/controller.dart` (modify),
    `apps/comics-editor/test/cutting_session_test.dart` (create, 17 tests)
  - Verified by: `flutter test test/cutting_session_test.dart` — 17/17 passed. Full suite re-run:
    165 total, same 1 pre-existing unrelated failure as before (`dataset_backward_compat_test.dart`).

#### Deviations from Plan (additional)

- `import '../ai/cutting_client.dart' as cutting;` — required alias in `controller.dart`.
  `balloon_ai_client.dart` and `cutting_client.dart` both independently define
  `RoutingDecided`/`Progress`/`Success`/`Failure` as their respective sealed event types (by
  deliberate design symmetry per Specifications), so importing both unqualified into the same file
  (which now uses both `BalloonAiClient` and `MultimodalCuttingClient`) collides. Not anticipated
  in Specifications/Plan; a compile error surfaced it immediately.
- Added `unrejectRegion` (Task 3.3) — not separately named in the Plan, but required by
  `02-visual.md`'s already-approved rejected-region behavior.

#### Discoveries (additional)

- Caught before it became a bug: an initial draft of `CuttingSession.isRunning` inferred "still
  running" from `regions.isEmpty`, which would have misclassified a legitimate zero-region Success
  as running forever. Fixed with an explicit `completed` flag before writing any tests against it,
  and added a dedicated test (`'a zero-region Success is treated as completed, not still
  running'`) so a future refactor can't silently reintroduce the same mistake.

- **Phase 4 (Tasks 4.1-4.4, built together)**: `KindChip` (in `scene_panel.dart`) made public and
  given a static `styleFor()` so Cutting mode's canvas/rail/card reuse the exact same kind→color
  mapping instead of risking a second, drifted one — this surfaced a real, pre-existing color
  conflict (see Discoveries). New: `confidence_badge.dart`, `cutting_review_card.dart`,
  `cutting_region_rail.dart`, `cutting_canvas.dart` (dispatches trigger/running/failure/results
  states). `insertLibraryItemAsLayer` also added to `controller.dart` (Task 5.2's controller half,
  built alongside since it shares `acceptRegion`'s tile-write pattern).
  - Files: `lib/src/ui/widgets/{scene_panel,confidence_badge,cutting_review_card,
    cutting_region_rail,cutting_canvas}.dart`, `lib/src/ui/controller.dart` (all modify/create);
    `test/{confidence_badge,cutting_canvas,cutting_review_card,cutting_region_rail}_test.dart`
    (create, 4+5+6+5 = 20 tests)
  - Verified by: `flutter test test/cutting_*.dart test/confidence_badge_test.dart` — 20/20
    passed. Full suite re-run: 181/182, same 1 pre-existing unrelated failure.

#### Deviations from Plan (Phase 4)

- **Simplified the "spotlight" effect**: `02-visual.md`'s high-fidelity reference dims the page
  outside the selected region with a punched-hole dark vignette (a custom clip-path painter).
  Implemented instead: the selected region gets a solid bright border + handles; others render at
  reduced opacity. Materially simpler, same practical goal (unambiguous active selection) —
  disclosed in `cutting_canvas.dart`'s own doc comment, revisit only if found genuinely ambiguous.
- **No dedicated zoom control widget** on the results canvas (Should Have, not Must Have) — pan/
  zoom wasn't wired up at all this pass; the canvas renders at fit-to-container scale only. A real
  gap vs. `02-visual.md`, not just a simplification — flagged as an Open Design follow-up.
- **Stale-source banner** (source image changed after regions generated) was not implemented —
  `CuttingSession` doesn't yet track "has the source changed" at all. Genuinely deferred, not
  simplified; Requirements lists this as Must Have (Acceptance Criterion in the stale-indicator
  edge case). Needs a follow-up task before this flow is considered feature-complete.
- Combined Tasks 4.1 and 4.4 into one file (`cutting_canvas.dart`) rather than a separate sibling
  widget — the Plan's own Open Implementation Question left this an implementation-time choice;
  the trigger/running/failure states turned out small enough not to warrant a separate file.

#### Discoveries (Phase 4)

- **Real color conflict caught before shipping**: `02-visual.md`'s high-fidelity mockup specifies
  slate `#5a7d99` for Background and teal `#2f8f7a` for Character. The already-shipped `_KindChip`
  widget (`scene_panel.dart`, live in the app's layers list since before this flow) uses **teal
  `Hs.teal500` for Background and indigo `Hs.indigo500` for Character** — prepared in advance
  during `vdd-comics-editor-jhanava` groundwork, per that file's own comments. Using the mockup's
  colors would have made the *same* `kind` value render in two different colors depending on which
  panel you're looking at. Resolved by reusing the existing `Hs.teal500`/`Hs.indigo500` tokens
  (the live, already-user-visible reality) instead of the mockup's values — a deliberate,
  disclosed override of `02-visual.md`'s color reference, not an oversight.
- **A second, more fundamental bug caught via test failures, not inspection**: none of the new
  widgets rebuild automatically on `EditorController.notifyListeners()` — correct, actually,
  because the *real app* rebuilds everything via a single root `AnimatedBuilder(animation:
  controller, ...)` in `EditorScreen.build` (`editor_screen.dart`), not per-widget subscriptions.
  Test hosts that didn't replicate this (`_host()` helpers building the widget directly under a
  bare `Scaffold`) produced tests where Accept/Reject taps appeared to silently do nothing —
  fixed by wrapping every test host in the same `ListenableBuilder(listenable: controller, ...)`
  pattern. Worth remembering for Phase 6: as long as Cutting mode's screen is mounted inside
  `EditorScreen`'s existing root `AnimatedBuilder`, no additional listening is needed anywhere.
- **Testing pitfall repeated 3x before being fixed everywhere**: `Future.delayed` inside a plain
  `testWidgets` body never fires (fake-async zone) — this is the exact hang
  `balloon_editor_card_test.dart` already documented once; still walked into it fresh in
  `cutting_canvas_test.dart` (a 10-minute real timeout was hit before diagnosing it) before
  applying the fix consistently across all three new test files. Worth calling out in case a
  future test file repeats it a 4th time: the rule is not just "use `tester.runAsync` somewhere,"
  it's "the specific `await Future.delayed(...)`/real dart:io call must execute inside an active
  `runAsync` zone" — a tap that triggers async work still needs the *tap itself* wrapped in
  `runAsync`, not just the later polling loop.

- **Phase 5 (Tasks 5.1-5.2)**: `library_browser.dart` created — directory scan (no manifest,
  folder=cluster/file-count=crop-count, matching `build_library.py`'s real output shape), search
  filter, both empty states. `LibraryBrowser` takes an injectable `resolveLibraryDir` (same
  testability seam pattern as `ProcessCuttingClient`/`EditorController.resolveLibraryDir`).
  - Files: `lib/src/ui/widgets/library_browser.dart` (create), `test/library_browser_test.dart`
    (create, 5 tests)
  - Verified by: `flutter test test/library_browser_test.dart` — 5/5 passed on first run. Full
    suite: 186/187, same 1 pre-existing failure.

- **Phase 6 (Tasks 6.1-6.2)**: `EditorMode.cutting` added to `models.dart`'s enum (now 3 values);
  `editor_screen.dart`'s mode dispatch restructured from a binary ternary to a `switch (c.mode)`
  covering all three; new `_CuttingDesktopBody` (region rail/Library tab | canvas | review card,
  mirroring `_LetteringDesktopBody`'s three-pane shape). Compact/touch row gets a new
  `_CuttingModeIcon` (Task 6.2) that switches into Cutting mode for real on desktop (checked via
  `Platform.isIOS||isAndroid`, matching `createComicsCore()`'s own capability check — not
  `FormFactor`, which is about screen width, not what device this actually is) or shows a SnackBar
  explanation on iOS/Android.
  - Files: `lib/src/ui/models.dart`, `lib/src/ui/screens/editor_screen.dart`,
    `lib/src/ui/widgets/top_bar.dart` (all modify); `test/cutting_mode_switch_test.dart`,
    `test/cutting_desktop_body_test.dart` (create, 4+2 tests)
  - Verified by: both new test files passed. **Full suite regression found and fixed**: adding the
    3rd `HsSegmented` option pushed the desktop top bar's Row into a real 6.8px overflow at
    1568px width, breaking 6 pre-existing tests (`kind_field_test.dart`,
    `lettering_desktop_test.dart` ×5) that render the top bar incidentally. Fixed by using a
    shorter "Cut" label specifically in the segmented control (not `EditorMode.cutting.label`,
    "Cutting", still used elsewhere e.g. tooltips) — recovers well more than the needed margin
    without touching `HsSegmented`'s shared padding (also used by the Lang picker) or unrelated Row
    spacing. Full suite re-run after the fix: 192/193, same 1 pre-existing unrelated failure.
  - Also confirmed via a throwaway reproduction: a separate, **pre-existing** `timeline.dart`
    overflow (5214px, `Column` in the docked Edit-mode timeline) reproduces with zero Cutting-mode
    code involved, at a viewport size no existing test happened to use before. Not touched, not
    fixed — genuinely unrelated, disclosed rather than silently worked around.

#### Deviations from Plan (Phase 6)

- **Mobile disabled state is one icon, not a 3-way segmented control**: `02-visual.md`'s
  high-fidelity reference shows the full `[Edit][Lettering][Cutting]` segmented switch on iPad
  with the third option grayed (popover on tap) and an inline note on iPhone. The real compact/
  touch row in `top_bar.dart` uses a single binary icon-button toggle for Edit/Lettering, not a
  segmented control at all — a documented, pre-existing space constraint at tablet width (adding
  even the 2-option switch there was already flagged as overflowing). Implemented instead: one
  additional icon next to the existing toggle; both tablet and phone get the same SnackBar
  explanation on tap, not a popover-vs-inline-note visual distinction. Disclosed in
  `_CuttingModeIcon`'s own doc comment.
- **Desktop-capability check, not screen-width check**: the disabled/enabled split for Cutting is
  `Platform.isIOS || Platform.isAndroid`, not `FormFactor` — a narrow/resized desktop window still
  gets real Cutting functionality via `_CuttingModeIcon`, matching Requirements' "desktop" framing
  (not "wide desktop"). This wasn't explicit in `02-visual.md`, which conflated the two given its
  screens were all either clearly-desktop-wide or clearly-mobile.

**Ended at**: Phase 6 complete (Tasks 6.1-6.2). Two real gaps carried forward from Phase 4, still
not fixed: (1) no zoom control on the results canvas, (2) no stale-source-changed detection/
banner. Starting Phase 7 (final testing & polish) next.
**Handoff notes**: `EditorController` now exposes everything Cutting mode's UI needs. Any future
widget hosting `CuttingCanvas`/`CuttingReviewCard`/`CuttingRegionRail`/`LibraryBrowser` standalone
(tests, Storybook-style previews) must wrap it in a `ListenableBuilder`/`AnimatedBuilder` listening
to the controller, or mutations will appear to silently no-op in the UI (state is still correct
underneath — only rendering is stale). Also: adding any further width to the desktop top bar's Row
should be checked against a real narrow-desktop viewport test, not assumed safe — this file is
tighter on horizontal space than it looks.

- **Phase 7 (Tasks 7.1-7.4)**:
  - **7.1**: Full suite re-run clean: 193/194 Dart (1 pre-existing, unrelated,
    `dataset_backward_compat_test.dart`), 108/108 Python.
  - **7.2**: `test/cutting_real_end_to_end_test.dart` — real `ProcessCuttingClient` (not
    `StubCuttingClient`) spawning the real `segment_image.py`, against the real trained checkpoint
    and the sample fixture's own real stitched artwork as the source image. Accepts every returned
    region, saves, reopens, confirms every kind survived. Passed in ~4s against the real
    checkpoint — the strongest single confirmation in this flow that the full chain (subprocess →
    NDJSON parsing → tile write → layer creation → save → reopen) genuinely works, not just against
    stubs.
  - **7.3**: No real iOS/Android device or simulator is available in this environment — a literal
    "cut on macOS, open on a real iPad build" walkthrough could not be performed, and is disclosed
    as not done rather than claimed. Adapted verification instead:
    `test/cutting_cross_device_test.dart` cuts and accepts real regions via the desktop
    `CoreClient` path, saves, then reopens that exact file through a directly-constructed
    `DartIoCore` session (the real code path `createComicsCore()` selects on iOS/Android) and
    confirms both the `kind`-tagged layers and their actual tile files survive. This verifies the
    concrete, falsifiable claim behind "layers a desktop cut produced appear normally on
    mobile" — the file format and parsing logic, not literally the mobile UI/OS.
    Hit the **exact same `runAsync` mistake a 4th time** while writing this test (a direct
    `await mobileCore.call('openComics', ...)` outside `runAsync`, hanging for a real 10-minute
    timeout before being caught and fixed) — see Learnings below; this pattern needs a better
    guard than "remember every time."
  - **7.4**: No interactive device/simulator available for a manual click-through either. Adapted:
    every state named in `02-visual.md` has automated widget-test coverage instead (trigger/empty,
    running, results, failure retryable/non-retryable, Library tab empty/populated/filtered, mode
    switch, mobile SnackBar explanation) — see the Phase 4-6 task entries above for exactly which
    test file covers which state. Two states are *not* covered because they were never built: the
    stale-source banner and the zoom control (both already disclosed as Phase 4 gaps).

#### Deviations from Plan (Phase 7)

- Tasks 7.3 and 7.4 were adapted from "real device" / "manual walkthrough" to automated,
  environment-appropriate equivalents, since no iOS/Android device or simulator was available in
  this session. The adaptations are real, meaningful verifications of the same underlying claims
  (cross-device file-format compatibility; full state coverage) — not skipped, but not literally
  what the Plan described either. Flagged explicitly rather than silently marking the Plan's tasks
  "done" as originally scoped.

## Learnings (additional, Phases 4-7)

- The single-root-`AnimatedBuilder` rebuild architecture (`EditorScreen.build`) is a real,
  load-bearing convention every new widget must be tested against — a widget that works perfectly
  in the real app can appear completely non-functional in an isolated test that doesn't replicate
  that wrapping. Worth documenting once, here, so it isn't rediscovered by a 4th test file the way
  the `Future.delayed`-needs-`runAsync` lesson was rediscovered a 3rd time before this session
  applied it consistently.
- Adding a UI element (a 3rd mode segment) that seems purely additive can still cause a real,
  measurable regression (a 6.8px overflow) in a shared, already-tight layout. The fix was cheap
  once found, but it was only found because the full test suite was re-run after the change rather
  than just the new tests — a good argument for always re-running the *whole* suite after any
  change to shared chrome (top bar, navigation), not just the tests for the new feature.
- Real end-to-end tests (7.2, and the earlier Python CLI test) caught nothing new by this point —
  a positive signal that the unit/integration tests along the way were already accurate, not a
  wasted step. Worth keeping as a final gate regardless, since it's cheap (~4s) relative to the
  confidence it buys.
- **The `runAsync` mistake recurred a 4th time** (Task 7.3), after already being caught and
  documented 3 times earlier in this same session (Phase 4). Each time the fix was correct once
  found, but "remember to wrap real dart:io/timer calls in `runAsync`" clearly isn't a reliable
  enough rule to hold in working memory across a long session — any new Cutting-mode test file
  should specifically grep its own body for bare `await <something real>` outside a `runAsync`
  block before running it the first time, rather than discovering it via a 10-minute timeout.

---

### Session 2026-08-01 (continued) - Claude

**Started at**: Follow-up task, requested after Implementation was reported complete.
**Context**: User asked to build the one disclosed gap from the completion report: the
stale-source-changed detection/banner (Requirements Must Have, not delivered in the first pass).

#### Completed

- **Stale-source detection**: `CuttingSession` gained a fingerprint (`sourceFileRef`/`sourceWidth`/
  `sourceHeight`, captured at trigger time from the source layer's tile-template filename +
  `imageDimensions` -- an in-memory raw-JSON read, not a disk stitch) and a `stale` flag.
  `EditorController.refreshCuttingStaleness()` compares the fingerprint against the source layer's
  *current* state; called from `_ResultsCanvasState` via a post-frame callback on every rebuild
  (cheap, since it's in-memory-only). `dismissCuttingStale()` clears the flag.
  - Disclosed simplification (same category as others in this flow): this detects the layer being
    replaced/resized/deleted, not an in-place same-size pixel change to the same tile file — full
    byte-for-byte comparison would need a disk re-stitch on every check.
  - Files: `lib/src/ui/controller.dart` (modify: `CuttingSession`, `triggerCutting`,
    `refreshCuttingStaleness`, `dismissCuttingStale`), `lib/src/ui/widgets/cutting_canvas.dart`
    (modify: generalized `_stitchLayerBytes` shared by trigger and Re-run, new `_StaleBanner`
    widget, staleness-check scheduling in `_ResultsCanvasState`)
  - Verified by: `test/cutting_stale_test.dart` (6 tests, controller-level: fresh/changed/deleted/
    no-op cases) + `test/cutting_stale_banner_test.dart` (2 tests, banner visibility + Dismiss).
    Full suite re-run: 202/203, same 1 pre-existing unrelated failure.

#### Discoveries

- **A real bug caught by the banner's own Dismiss test, not by inspection**: the first
  implementation of `dismissCuttingStale()` only cleared the `stale` flag without updating the
  fingerprint. Since staleness is re-checked on every rebuild (including the rebuild the dismiss
  action itself triggers via `notifyListeners()`), the very next check immediately compared against
  the *original* fingerprint again and re-flagged the same already-acknowledged change — Dismiss
  visually did nothing. Fixed by re-baselining the fingerprint to the layer's current state as part
  of dismissing; a fresh/newly-introduced change after that point still correctly re-flags.

**Ended at**: Stale-detection follow-up complete.

#### Completed (zoom control follow-up, same session)

- **Results canvas zoom control**: `_ResultsCanvasState` gained a local `TransformationController`
  (not shared with `EditorController.canvasViewport`, which is specifically the Edit-mode canvas's)
  wrapping the region-overlay `Stack` in an `InteractiveViewer` (`panEnabled: true, scaleEnabled:
  false` — pinch/trackpad zoom intentionally off in favor of explicit +/- buttons). New
  `_CuttingZoomControl` widget mirrors `canvas_view.dart`'s `_ZoomControl` exactly (−/percentage/+/
  Fit), bottom-left per `02-visual.md`. Region overlay position math is unaffected — it already
  operated in the fixed-size child's own coordinate space, independent of any ancestor zoom
  transform, and Flutter's gesture delivery already accounts for ancestor transforms in reported
  drag deltas — confirmed by re-running the full existing region/resize-handle test suite
  unchanged and green.
  - Precedent check before building, not after: `canvas_view.dart`'s own Edit-mode canvas already
    nests a `GestureDetector(onPanUpdate: ...)` (layer drag) inside an `InteractiveViewer` in this
    exact codebase/Flutter version — confirms the pattern this follow-up depends on (drag handles
    coexisting with pan/zoom) isn't hypothetical, it's already shipping.
  - Files: `lib/src/ui/widgets/cutting_canvas.dart` (modify: zoom state/constants, `InteractiveViewer`
    wrapping, new `_CuttingZoomControl`), `test/cutting_zoom_control_test.dart` (create, 4 tests:
    starts at 100%, +/−/Fit, 400% cap)
  - Verified by: `flutter test test/cutting_zoom_control_test.dart` — 4/4 passed, including an
    exact-percentage check (125% → 156%, confirming the compounding zoom-step math, not just "some
    number changed"). Full suite re-run: 205/206, same 1 pre-existing unrelated failure.

**Ended at**: Both follow-ups complete. Every Requirements Must Have and Should Have item named in
this flow's own documentation is now delivered — no known gaps remain.

## Deviations Summary

| Planned | Actual | Reason |
|---------|--------|--------|
| `ProcessCuttingClient` uses `MultimodalPaths` directly | Constructor-injectable resolver overrides, defaulting to `MultimodalPaths` | Testability — `Platform.environment` can't be mutated mid-process to test the not-found path otherwise |
| `02-visual.md`'s slate/teal Background/Character chip colors | Reused already-shipped `Hs.teal500`/`Hs.indigo500` | The mockup's colors conflicted with colors already live in the app's layers list |
| `02-visual.md`'s 3-way segmented switch with grayed Cutting on mobile | One extra icon in the existing compact binary toggle, SnackBar explanation | Real compact-row space constraint predates this flow; no segmented control exists there at all |
| Plan Task 7.3/7.4: real device / manual walkthrough | Automated equivalents (`DartIoCore` round trip; widget-test state coverage) | No iOS/Android device or simulator available in this environment |

## Learnings

- The "verify with a non-square test image" mitigation from the Plan's Risk Assessment (Task 1.1)
  was worth calling out explicitly — it's an easy check to skip and an easy bug to miss with only
  square fixtures.
- Reusing a real photo file's bytes instead of hand-typed base64 PNG literals in Dart tests avoided
  a real mistake: an initial draft's hand-typed base64 strings decoded as valid base64 but were
  corrupt PNGs (bad CRC, caught via a quick `cv2.imdecode` sanity check) — would have silently
  exercised the `image_not_readable` failure path instead of a real success path without that check.
- The single-root-`AnimatedBuilder` rebuild architecture is load-bearing for every new widget's
  tests, and the `runAsync`-for-real-async-work rule needed re-discovering four separate times in
  this session despite being documented after the first — see the Phase 4/7 entries above.
- A "compute derived state on every rebuild" pattern (staleness re-checking) needs to be paired
  with "acknowledging" it (Dismiss) also updating the baseline it's compared against — otherwise
  the acknowledgment is silently overwritten on the very next rebuild. Caught by a test, not by
  inspection; worth remembering as a general shape of bug for any future "flag + dismiss" feature.

## Completion Checklist

- [x] All tasks completed — both disclosed gaps from the original completion report (stale-banner
      Must Have, zoom control Should Have) are now closed as requested follow-ups
- [x] Tests passing (205/206 Dart including the real end-to-end, cross-device, stale-detection, and
      zoom-control tests; 108/108 Python; the 1 Dart failure is pre-existing/unrelated to this flow)
- [x] No regressions (the one regression found — top-bar overflow — was fixed, not just noted; the
      stale-detection follow-up's own dismiss-doesn't-stick bug was also fixed, not shipped)
- [ ] Documentation updated if needed (06-readme.md not yet written — Documentation phase not
      started; ask the user whether it's wanted before starting it, per this repo's SDD/VDD
      convention of treating Documentation as an explicit, separate phase)
- [ ] Status updated to COMPLETE (pending user review of this implementation)
