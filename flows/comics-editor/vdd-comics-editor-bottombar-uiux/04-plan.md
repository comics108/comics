# Implementation Plan: comics-editor-bottombar-uiux

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-08-05
> Specifications: [03-specifications.md](03-specifications.md)
> Target product version: `3.2.1`

## Delivery Strategy

Implement from contracts inward: viewer source/controller isolation first,
platform renderers second, editor state/snapshot integration third, then
Properties and responsive UI. Each task starts with focused tests where the
platform permits automation. The existing Editor remains usable after every
mergeable task; Windows never temporarily falls back to opening the old WPF
editor window.

No task below starts until this plan is explicitly approved.

## Working-Tree Safety

- `apps/comics-editor` and `libs/comics_viewer/flutter_comics_viewer` are nested
  repositories. Inspect their status before every implementation group.
- Preserve all pre-existing/user-owned modifications. The known intended
  pre-plan editor changes are `pubspec.yaml` and `lib/src/app_version.dart` for
  version `3.2.1`.
- Do not restore or modify the deleted
  `libs/comics_editor/flutter_comics_editor` gitlink.
- Keep root flow/design changes separate from nested product-repository changes
  in verification summaries.

## Task 1 — Viewer Package Contract and Instance Isolation

### 1.1 Add failing contract tests

In `libs/comics_viewer/flutter_comics_viewer/test/` add cases for:

- path and byte sources;
- typed loading/loaded/error/unsupported state;
- two simultaneous controllers with isolated commands/callbacks;
- normalized position bounds and echo suppression;
- idempotent ownership/disposal.

### 1.2 Refactor public API

- Add `ComicsViewerSource` path/bytes variants.
- Make `ComicsViewerController` listenable/typed and attach it to one backend
  instance at a time.
- Retain source-compatible convenience methods where safe; document intentional
  API changes.
- Replace the product-facing red unsupported widget with typed capability state.

### 1.3 Bind per-view mobile channels

- Android/iOS attach `flutter_comics_viewer_<viewId>` after PlatformView
  creation.
- Route scroll/load/error callbacks through the same instance channel.
- Add native/plugin tests proving two views cannot cross-control.

### Exit criteria

- Dart viewer tests pass.
- Android/iOS plugin tests pass where SDKs are available.
- No global instance channel is used for viewer commands.

## Task 2 — Cross-Platform Viewer Rendering

### 2.1 Extract shared Dart archive/render model

- Parse `.comics` path/bytes sources and `data.json` without depending on the
  editor package.
- Resolve stable language slots with slot-0 fallback.
- Port/reuse the approved interpolation behavior for translate, rotate, scale,
  alpha, preview filtering, and sound ranges.
- Treat malformed/missing assets as typed load errors.

### 2.2 Implement Dart backend

- macOS/Linux render the review-only strip from a path snapshot.
- Web renders from bytes where editor/core capability exists; otherwise returns
  typed unsupported.
- No selection handles or editor interactions.

### 2.3 Verify renderer behavior

- Archive fixtures cover layered images, languages, preview flags, all
  animation types, sound gating, and long vertical documents.
- Position is normalized consistently across Dart, Android, and iOS.

### Exit criteria

- Dart backend fixture tests pass on host desktop and web test target where
  available.
- Unsupported is a state, not a renderer exception/diagnostic widget.

## Task 3 — Windows Flutter Shell and WPF Viewer Host

### 3.1 Remove whole-editor routing

- Change `apps/comics-editor/lib/main.dart` so Windows uses
  `EditorScope -> EditorScreen` like other desktop platforms.
- Delete runtime use of `WpfEditorView`; retain source temporarily only if
  required during the bridge migration, then remove dead code/tests.

### 3.2 Refactor native bridge to viewer-only host

- Replace `EditorHost.ShowMainWindow` with a child WPF viewer host.
- Add argument serialization in `windows/editor_plugin` or migrate the bridge
  into the Windows viewer plugin, keeping one registration path.
- Implement create/load/bounds/visibility/position/language/sound/preview/
  dispose methods from Specifications 1.0.
- Reserve Flutter chrome/position-selector geometry outside the WPF child HWND.

### 3.3 Windows lifecycle verification

- Verify one top-level Flutter window, child resizing, DPI changes, focus
  traversal, Editor/Viewer switching, document switching, and shutdown.
- Verify missing .NET/runtime/payload returns a Viewer state without hiding the
  Flutter editor.
- Update CMake and Windows packaging/CI payload publication.

### Exit criteria

- Windows build succeeds on a Windows runner.
- No WPF `MainWindow` opens.
- Native child/thread/HWND is disposed cleanly.

## Task 4 — Editor Workspace and Preview Snapshot State

### 4.1 Add state-model tests

- Editor/Viewer transition preservation;
- Properties tab and selection persistence;
- new/open document reset rules;
- stale preview revision suppression;
- refresh retains the last successful revision.

### 4.2 Add view-only state

- Add `EditorWorkspace`, `PropertiesTab`, content-scroll fallback, and typed
  Viewer state.
- Keep missing/unknown `scrollType` vertical without rewriting raw JSON.
- Explicit horizontal input becomes unsupported/disabled this iteration.

### 4.3 Implement preview snapshot service

- Build immutable cache archives from current `ComicsDoc`, preserved raw JSON,
  and working assets.
- Support path/bytes output, revision tokens, 250 ms refresh debounce, atomic
  replacement, and cleanup.
- Never change save path/history/selection/recent files.

### 4.4 Integrate viewer coordinator

- Own one `ComicsViewerController` per EditorController/document session.
- Synchronize position, language slot, playback, sound, preview, load/error.
- Dispose on controller shutdown and reset on another document.

### Exit criteria

- Snapshot/coordinator tests pass, including edits not saved to the source path.
- Viewer never loads stale saved content after a valid edit.

## Task 5 — Transaction-Safe Slider-First Numeric Controls

### 5.1 Define metadata and tests

- Encode the approved exact validation, presentation ranges, and steps for all
  document/puzzle/animation fields.
- Test invalid partial text, cancel/blur/commit, overflow, signed decimals,
  touch one-tap focus, and desktop keyboard behavior.

### 5.2 Implement `NumericPropertyControl`

- Desktop: slider plus continuously visible compact editable value.
- Touch: slider plus value that becomes a selected focused input in one tap.
- Wrap at narrow widths/200% text without nested scrolling.
- Add semantics/error announcements and overflow indication.

### 5.3 Add edit transactions

- One history snapshot per complete slider gesture or exact commit.
- Live slider updates notify/render without creating history per tick.
- Cancel restores initial value.
- Remove Alpha persistence clamp; keep `0…1` only as presentation range.

### Exit criteria

- Numeric widget/controller tests pass.
- Undo/redo proves exactly one entry per gesture.
- Valid legacy out-of-range values round-trip unchanged.

## Task 6 — Properties Tabs and Complete Inventory

### 6.1 Add Properties state tests

Cover no selection, layer, balloon/caption, sound, every animation type,
Document, and Puzzle.

### 6.2 Build tab host

- `Selection` first, `Document` second.
- Selection retains existing Kind/artwork/Preview/animation behavior.
- Document receives Width/Height/Convert and conditional Puzzle Scale.
- No-selection Selection shows the approved hint; Document stays reachable.

### 6.3 Move canvas settings

- Remove the Canvas settings card from every Scene surface.
- Reuse existing controller/history routes for Width/Height/Scale.
- Preserve Convert's existing command behavior; do not invent conversion logic.

### 6.4 Complete numeric cards

Wire Start/End and all Translate/Rotate/Scale/Alpha/Sound fields through the new
numeric control and transaction API.

### Exit criteria

- Full v2.8 inventory tests pass for each selection type.
- Scene never duplicates Width/Height/Convert.

## Task 7 — Dynamic Used-Language Tabs

### 7.1 Extend registry safely

- Add optional `active` with default true.
- Assert en/ru/hi stable indices 0/1/2.
- Test inactive used entries, active picker filtering, and no slot shifts.

### 7.2 Extract shared language UI

- Reuse/extract Balloon `used + Add` behavior for ordinary layer artwork.
- Remove fixed `HsSegmented<Lang>` from Properties.
- Searchable picker lists active unused languages; selecting alone does not
  mutate document data.

### Exit criteria

- Dynamic registry tests pass with more/fewer than three active languages.
- Older inactive language content stays visible/editable and round-trips.

## Task 8 — Responsive Editor/Viewer UI

### 8.1 Phone dock and sheets

- Test and implement exactly `Scene / Viewer / Properties` in that order.
- Remove New/Open from bottom only.
- Add 85%-height Viewer sheet, safe areas, focus trap/return, and grip-only
  drag dismissal behavior.

### 8.2 Tablet/desktop workspace

- Add keyboard-reachable `Editor / Viewer` switch.
- Editor retains existing pane sizes and Timeline.
- Viewer hides Scene/Properties/Timeline semantics and uses the full workspace.
- Restore Editor subtree state on return.

### 8.3 Viewer surface/states

- Flutter controls and typed loading/refreshing/loaded/empty/error/unsupported
  states.
- Retry current revision; Show details; Open Scene/return-to-Editor recovery.
- No Properties or visibility controls in Viewer.

### Exit criteria

- Responsive widget tests pass at all boundary widths.
- Navigation/state/focus behavior matches Visual 1.8.

## Task 9 — Right-Edge Viewer Position Selector

### 9.1 Implement and unit-test selector

- Vertical rail along the right edge only.
- 44 touch / 32 desktop interaction target with narrow visual rail.
- Tap/drag, normalized synchronization, percentage bubble, start/end labels,
  keyboard Home/End and accessibility actions.
- No active selector in non-loaded states.

### 9.2 Integrate across backends

- Keep rail outside Android/iOS PlatformView and Windows child HWND bounds.
- Verify device/window orientation never moves it to the bottom.
- Do not instantiate future horizontal selector.

### Exit criteria

- Phone/tablet/desktop selector tests and semantics pass.
- Native/Dart scroll and Flutter thumb remain synchronized without loops.

## Task 10 — Layer Visibility and New Document UI

### 10.1 Eye/eye-off

- Replace `HsToggle` in layer rows on all responsive Scene surfaces.
- Verify semantics, touch sizes, hidden-row selection, Editor-only Canvas
  hiding, and one history entry.
- Do not serialize visibility or alter Viewer snapshot contents.

### 10.2 New Document cards

- Default selected Vertical-scroll comic strip + Portrait.
- Horizontal-scroll comic strip + Landscape visible, locked, and non-selectable.
- Puzzle remains selectable.
- Create maps only to existing `DocType.comics`/`puzzle`; no new default fields
  are persisted.

### Exit criteria

- Widget and semantics tests cover pointer, keyboard, and disabled states.

## Task 11 — Integrated Regression and Visual Verification

### 11.1 Automated suites

Run and fix:

- `dart format --output=none --set-exit-if-changed lib test`;
- `flutter analyze`;
- complete editor `flutter test`;
- complete viewer package `flutter test`;
- available Android/iOS native plugin tests;
- web tests/build where supported;
- Windows build/tests on Windows runner.

### 11.2 Visual verification

Compare representative states with
`Comics Editor Bottombar Devices v2.dc.html` at:

- desktop `1440×920`;
- iPad frame `1240×864`;
- phone `400×844`;
- breakpoint widths `600/601/1024/1025`;
- phone landscape, keyboard visible, 200% text;
- Viewer loading/refresh/error/unsupported and vertical selector positions.

Record screenshots/findings in `05-implementation-log.md`. Any material visual
departure returns to the Visual approval gate before it is retained.

### 11.3 Data regression

- Open/save representative legacy v2.8 and current v3 documents.
- Confirm unknown JSON fields, image dimensions, language slots, animation
  values including out-of-range Alpha/negative Start, and absent scrollType are
  preserved.

### Exit criteria

- Required automated suites pass or have an explicitly approved platform
  limitation.
- No regression in existing Editor/Lettering/Cutting workflows.
- Version remains `3.2.1+1` with UI fallback `3.2.1`.

## Task Dependencies

```text
1 Viewer contract
├─> 2 Dart/mobile backends ───────────────┐
└─> 3 Windows backend ────────────────────┤
                                          v
4 Editor state + preview snapshot ──> 8 Viewer UI ──> 9 selector

5 Numeric control ──> 6 Properties
7 Languages ─────────> 6 Properties

6 Properties ──┐
8 Viewer UI ───┼─> 10 final shell details ──> 11 integrated verification
9 Selector ────┘
```

Tasks 2, 3, 5, and 7 may proceed independently after Task 1 where their stated
dependencies permit, but shared files must be reconciled before Task 8.

## Completion Definition

- All Must Have acceptance criteria trace to passing tests or documented
  platform verification.
- Approved responsive geometry and review-only Viewer behavior match Visual
  1.8.
- Windows uses Flutter shell + embedded WPF Viewer, never a separate editor.
- macOS/Linux/Web have a functional Dart Viewer where supported and a typed
  product state otherwise.
- Numeric/property/language data round-trips without legacy loss.
- `05-implementation-log.md` contains commands, outcomes, screenshots/findings,
  and any approved deviations.
- `06-readme.md` is drafted only after implementation verification, then routed
  through its own documentation approval gate.

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-08-05
- [x] Notes: Explicitly approved in conversation.
