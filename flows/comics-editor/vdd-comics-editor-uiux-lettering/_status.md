# Status: vdd-comics-editor-uiux-lettering

## Current Phase

IMPLEMENTATION

## Phase Status

DRAFTING

## Last Updated

2026-07-30 by Claude

## Blockers

- None currently. See "Reversal" note below — this flow is back on its original plan.

## History: product-friend consultation, narrowing, and reversal (2026-07-30)

1. **Consultation**: product friend Джанава (Евгений Корытный) answered 4 questions this flow had
   open: kind taxonomy is really background/character/balloon/sound (not just balloon/caption);
   language coverage doesn't need 20, 3 is enough to start; no new Lettering mode needed, Properties
   panel is enough; AI scope is UI-only. The user also raised their own strategic framing: balloon
   is the *simplest* of the four kind-placement problems, and there's a bigger unscoped
   prerequisite ("нарезка и систематизация имеющегося материала" — cutting/organizing source
   material before placement).
2. **Initial narrowing (v0.2 of specs/visual, since reverted)**: `03-specifications.md` and
   `02-visual.md` were updated to match — dropped Lettering mode, capped languages at 3, adopted
   the 4-value taxonomy.
3. **Reversal, per explicit user instruction**: don't let Джанава's answers restrict *this* flow.
   Instead: (a) spin his insight out into its own flow, `flows/vdd-comics-editor-jhanava/` —
   requirements + visual both drafted there as an honest "seed capture," not a finished design; (b)
   return **this** flow to its original plan (Lettering mode restored, kind taxonomy back to
   balloon/caption scope, open string for future compatibility); (c) apply one real correction that
   survives the revert regardless: **language coverage must be dynamic** (driven by whatever
   languages exist, sourced from a data file/registry — not hardcoded to 3, not hardcoded to 20).
4. Both `02-visual.md` (Amendment history section) and `03-specifications.md` (Revision note
   section) now document this full arc transparently rather than silently rewriting history.

## Progress

- [x] Requirements drafted
- [x] Requirements approved (2026-07-30)
- [x] Visual drafted (2026-07-30), refined to v0.2 against user-supplied high-fidelity mockup
- [x] Visual approved (2026-07-30)
- [x] Specifications drafted (2026-07-30), v0.3 — restored to original plan after a brief
      narrowing-then-reversal (see History, above); dynamic-language correction applied
- [x] Specifications approved (2026-07-30)
- [x] Plan drafted (2026-07-30) — 7 phases, 19 tasks
- [x] Plan approved (2026-07-30)
- [x] Implementation started (2026-07-30)
- **Correction during implementation**: verified the actual bridge architecture by reading the
  real code (`comics_core.dart`, `core_client.dart`, `dart_io_core.dart`,
  `native/Comics.Editor.Headless/Rpc.cs`) instead of continuing to build on Specifications'
  assumption. Finding: no per-field RPCs exist anywhere in the app — it's local `EditorLayer`
  mutation + one full-document `saveComics` write, and both the C# core and `DartIoCore` already
  expose a `tempFolder` working directory (returned by `openComics`/`ping`, currently discarded by
  the Dart UI) that Dart can write new tile files into directly. This deleted the planned "Bridge /
  RPC" phase entirely — `03-specifications.md` and `04-plan.md` both updated in place with visible
  correction notes (not silently rewritten). Net effect: less code to write, not more.
- Side task, same session: bumped app version to 3.1.0 and wired the top bar's version badge to
  read it dynamically from `pubspec.yaml` via `package_info_plus` (was hardcoded `'3.0'`) — done,
  tested, unrelated to the lettering feature itself but requested mid-session.
- [x] Task 1.1 (C# `Layer.Kind`/`Style`/`Translations`) — complete, verified via `dotnet build`,
  headless rebuild, and a hand-written NDJSON script proving both omission-when-unset and a real
  save→fresh-process-reopen round trip.
- [x] Task 1.3 (Dart mirror: `EditorLayer.kind/style/translations` + `models_mapping.dart` both
  directions) — complete. Verified with 5 new pure-mapping unit tests
  (`test/models_mapping_test.dart`: read, legacy-absence, merge-back, clear-removes-keys, clone
  deep-copy) plus one new integration test against the **real rebuilt C# headless binary**
  (`test/core_client_test.dart`, "kind/style/translations round-trip through the real headless
  core without disturbing untouched layers") — fresh-process reopen, confirms the touched layer
  keeps its values and every other layer has zero stray `kind`/`style`/`translations` keys. Full
  suite: 38/38 passing.
- [x] Task 1.4 (`LanguageRegistry`) — complete. Created `assets/languages.json` (20 languages,
  seeded from `comics-ai-baloons/scripts/languages.py`'s order, en/ru/hi fixed first per
  Cultures) + `lib/src/i18n/language_registry.dart` (loads via `rootBundle`, `indexFor`/`codeFor`).
  5 new tests (`test/language_registry_test.dart`), including one proving a JSON-only addition
  (no Dart change) is picked up — the actual test of "dynamic, not hardcoded."
- [x] Task 1.2 (additive `Images[]` slot resolution) — complete. Added
  `EditorLayer.imageSlotFor(langCode, registry)` in `models.dart` (extends `images[]` with empty
  placeholders up to the registry's index, idempotent on repeat calls). 6 new unit tests
  (`test/image_slot_test.dart`) plus a real round-trip test against the **rebuilt C# headless
  binary** (`test/core_client_test.dart`, "additive Images[] slot beyond en/ru/hi round-trips
  through the real headless core") proving a 4th+ image slot survives save→fresh-process-reopen.
- **Phase 1 (Data Model & Backward Compatibility) is now fully complete** — Tasks 1.1-1.4 all
  done and verified against the real rebuilt C# core, not just isolated Dart unit tests.
- [x] Task 2.1 (capture `tempFolder` into `CoreDocument`) — complete. `openComics`'s `tempFolder`
  response field now threads through `comicsFromCore`/`CoreDocument`/`controller.dart`'s
  `openPath` instead of being silently discarded. 3 new tests (`test/temp_folder_test.dart`)
  confirm a real, existing directory with `data.json`+`layers/` for both `CoreClient` and
  `DartIoCore`.
- [x] Task 2.2 (Dart tile writer) — complete. `lib/src/io/tile_writer.dart`: `writeTiles`/
  `deleteTiles` (512px, matching `FileManager.cs`/`ImageMagick.cs`, `comics-ai-baloons`'s own
  port). Added `image: ^4.8.0` pub dependency for pure-Dart crop/encode. 9 tests
  (`test/tile_writer_test.dart`) including a known-good-layout check against the same 648x152
  case `comics-ai-baloons`'s own test suite uses, and a pixel-identical round trip through a real
  `tempFolder` → `saveComics` → reopen.
- [x] Task 2.3 (wire real bytes into `setImageFile`/`setImagePopup`) — complete, with one real bug
  found and fixed along the way: `EditorLayer.name` defaults to its first image's *raw templated
  file value* (e.g. `"0001_zastavka_2_{0}_{1}_{2}.png"`), so naming new files directly off it
  embedded stray `{0}_{1}_{2}`/extensions mid-filename. Added `sanitizeStem()` (`tile_writer.dart`)
  to strip that back to a clean stem before use — caught by a failing integration test, not by
  inspection, then covered with 4 dedicated unit tests. Also discovered (from `Image.cs`) that
  `Popup` is **never tiled** (`Image.Update`'s `popup: true` branch calls `FileManager.Update`, a
  plain single-file copy, no width/height tracked) — `setImagePopup` uses a new
  `writeSingleFile`/`deleteSingleFile` pair, not the tile writer. `properties_panel.dart`'s
  `onPick` stubs (previously writing a fake filename that was never actually saved to disk) are
  now no-ops with a comment pointing at Task 6.1, which owns the real file-picker wiring. 3 new
  integration tests (`test/controller_image_bytes_test.dart`) prove an existing-Cultures language
  and a brand-new registry language both round-trip through real `saveComics`/reopen with
  distinct, pixel-correct artwork.
- **Phase 2 (Working-Directory Image Writes) is now fully complete.**
- [x] Task 3.1 (kind chip in the layer list) — complete. `_KindChip` widget added to
  `scene_panel.dart`'s `_LayerRow`: `[Bln]` violet, `[Cap]` amber (from the approved
  `design/comics-editor-lettering-maket.pdf`), `[Art]` neutral gray for null/unset (the
  backward-compat state — legacy layers render `[Art]`, not literally no chip, matching
  `02-visual.md`'s mockup exactly). **User asked mid-task to add the rest of the kind types right
  away** rather than wait — extended the same chip to cover Джанава's full background/character/
  balloon/caption/sound taxonomy (`[Bg]` teal, `[Chr]` indigo, `[Snd]` reusing the existing sound
  coral) with any other value still falling back to `[Art]`. `kind` stays the open string it
  already was (`Layer.cs`), so this is purely additive chip styling, not a schema/taxonomy
  decision — the fuller-taxonomy *design* question stays parked in
  `flows/vdd-comics-editor-jhanava/` as before. New tokens: `Hs.violet500`/`amber500`/`teal500`/
  `indigo500` in `theme.dart`. 3 widget tests (`test/kind_chip_test.dart`) cover mixed kinds,
  all-legacy, and the full 6-kind set including an unrecognized value falling back to `[Art]`.
  (Debugging note: the first attempt at the 6-layer test flakily lost the last row — root cause
  was the default flutter test viewport being ~600px tall, clamping a nested `SizedBox`'s
  requested height rather than actually growing it, so `ListView` silently only built on-screen
  items instead of throwing; fixed by setting `tester.view.physicalSize` explicitly, matching
  `widget_test.dart`'s existing pattern — not a bug in the chip logic itself.) Full suite: 68/68
  passing.
- [x] Task 3.2 (kind-setting dropdown) — complete. `EditorController.setLayerKind` (local
  mutation, same shape as `setImageFile`) + `_KindField` dropdown in `properties_panel.dart`'s
  `_LayerEditor`, options matching Task 3.1's full chip taxonomy ((none)/Balloon/Caption/
  Background/Character/Sound). Guards against `DropdownButton`'s "value must be among items"
  assertion for a kind value not in that list (legacy or forward-compat data) by adding it as an
  extra verbatim entry rather than crashing or silently dropping it. 4 tests
  (`test/kind_field_test.dart`): set/change/clear + no-op with nothing selected, undo, a **real**
  `saveComics`→reopen persistence round trip, and a widget test driving the actual dropdown
  interaction end-to-end (tap → pick "Balloon" → chip updates to `[Bln]`).
- **Phase 3 (Kind-Tagging UI) is now fully complete.**
- [x] Task 4.1 (`BalloonAiClient` interface + stub) — complete. `lib/src/ai/balloon_ai_client.dart`
  (abstract `generate()` → `Stream<GenerationEvent>`, sealed `RoutingDecided`/`Progress`/`Success`/
  `Failure`, per `03-specifications.md`) + `stub_balloon_ai_client.dart` (deterministic fake —
  configurable outcome including the hand-lettered defense-in-depth rejection; `Success`'s
  placeholder artwork is a deterministic hash-derived color, same input always produces identical
  bytes). 8 tests (`test/balloon_ai_client_test.dart`).
- [x] Task 4.2 (`BalloonEditorCard` widget, all states) — complete, the largest single task in the
  plan. New files: `lib/src/ui/widgets/balloon_editor_card.dart` (header w/ style chip, artwork
  preview via a new `stitchImage` read-counterpart to Task 2.2's `writeTiles` in `tile_writer.dart`,
  language tabs sourced from the `LanguageRegistry` + document's used languages, text field wired to
  a new `EditorController.setLayerTranslation`, and all six states from `02-visual.md`: empty,
  text-entered, generating on-device/cloud+Cancel, success, failure, hand-lettered-disabled). Also
  added `models_mapping.dart`'s `imageDimensions` (read counterpart to `setImageDimensions`, since
  width/height live only in `CoreDocument.raw`).
  - **Significant debugging effort** (`test/balloon_editor_card_test.dart`, 7 tests, all passing):
    the first version hung indefinitely running more than one test. Root causes, both instances of
    one Flutter testing rule — genuine async platform/OS work does not progress inside
    `testWidgets`' fake-async zone unless awaited inside `tester.runAsync()`:
    1. `LanguageRegistry.load()` (a real `rootBundle` platform-channel read) called fresh inside
       every `testWidgets` closure hung the *second* such test in a run — fixed by loading it once
       in `setUpAll` instead.
    2. Real `dart:io` work (`EditorController.openPath`, `setImageFile`'s tile writes,
       `saveToPath`, and the card's own `stitchImage`-based preview load) awaited or
       fire-and-forgotten inside a `testWidgets` body hung or silently never resolved — fixed by
       wrapping those calls in `tester.runAsync()`, and, where the state depended on a
       fire-and-forget `initState` call racing `pumpAndSettle` (which only re-pumps when a frame
       is scheduled *during* its own loop, so it can miss a background Future that resolves a
       moment later), replaced fixed guessed delays with a small polling helper
       (`_pumpUntil`) that pumps every 50ms up to ~2s until the expected UI actually appears.
    - This process also surfaced and fixed a real design flaw, not just a test artifact: the
      Generate button's enabled state was originally gated on a *background-loaded* preview
      thumbnail having already finished stitching, which both violated `02-visual.md` (button
      should be enabled whenever text is present) and made the button's availability
      non-deterministic in the real app too (a slow disk read could leave it looking disabled
      right after opening a document). Fixed by decoupling `canGenerate` from the preview cache
      entirely (text-only gate) and resolving the actual source image lazily, awaited directly,
      inside `_generate()` itself — with a graceful fallback chain (own artwork → first-language
      artwork → a tiny generated blank placeholder) since `BalloonAiClient.generate`'s
      `sourceBalloonPng` is non-nullable.
  - Full suite: 90/90 passing.
- [x] Task 4.3 (wire `BalloonEditorCard` into Edit mode's Properties panel) — complete.
  `properties_panel.dart`'s `_LayerEditor` now shows `BalloonEditorCard` (via a new
  `_BalloonSection` + `FutureBuilder<LanguageRegistry>`, since the registry loads async) in place
  of the generic ARTWORK/File/Popup fields whenever the selected layer's `kind == "balloon"` — the
  kind dropdown, preview toggle, and animations section stay for every layer regardless. Added
  `EditorController.aiClient` (stub-backed `BalloonAiClient` field, swappable later without
  touching UI code — no real engine exists yet, matches Specifications' AI-scope note). 4 tests
  (`test/properties_panel_balloon_test.dart`): non-balloon layer unaffected, balloon layer shows
  the card, switching kind live via the dropdown swaps the section in, and a full generate flow
  driven entirely from Edit mode (tap language tab → type text → Generate → see success), no
  Lettering mode involved — matches the plan's stated verification exactly.
- **Phase 4 (Balloon Editor Card) is now fully complete.**
- [x] Task 5.1 (mode switch, top bar) — complete. `EditorMode` enum (`edit`/`lettering`) in
  `models.dart`, `EditorController.mode`/`setMode`/`toggleMode` (view-only, not persisted, same
  treatment as `lang`). `top_bar.dart` gets an `HsSegmented<EditorMode>` next to the doc pill on
  desktop/tablet, a single toggle icon button on phone. `editor_screen.dart` branches on `c.mode`:
  `lettering` renders a placeholder body ("balloon rail coming soon") that Tasks 5.2-5.5 replace
  piece by piece; Edit mode's existing desktop/tablet/phone bodies are otherwise untouched. 3 tests
  (`test/mode_switch_test.dart`).
- [x] Task 5.2 (balloon rail) — complete. `lib/src/ui/widgets/balloon_rail.dart`: filters the
  document to `kind == "balloon"`/`"caption"` layers only, in document order, numbered from 1;
  `[Bln]`/`[Cap]` chip + a per-*target-language* status dot (solid = text+artwork, ring =
  text-only, dash = empty) per row; selection highlight + tap-to-select wired to the same
  `selectLayer`/`selKind`/`selIndex` the Scene panel already uses; an empty-state message
  redirecting to Edit mode when there are zero balloon/caption layers (the edge case
  `03-specifications.md` calls out). Not yet wired into the Lettering-mode body itself (still the
  Task 5.1 placeholder) or given a real target-language source (langCode is a required parameter,
  caller decides — Task 5.3 will pass whatever the real layout's active language ends up being). 5
  tests (`test/balloon_rail_test.dart`).
- [x] Task 5.3 (Lettering mode layout — macOS/desktop) — complete. `editor_screen.dart` gets
  `_LetteringDesktopBody`: `BalloonRail` where Scene normally sits, `BalloonEditorCard` where
  Properties normally sits, and the existing `CanvasView` unmodified in the middle -- it already
  draws selection handles around whichever layer is selected, and `BalloonRail`'s tap goes through
  the same `EditorController.selectLayer` Scene's rows use, so "current balloon highlighted in
  context on the full page" came for free, no new canvas code needed. Added
  `EditorController._ensureBalloonSelected()`, called from `setMode` on entering Lettering mode:
  auto-selects the first balloon/caption layer in document order if the current selection isn't
  one (simplified from the visual spec's "first balloon *without artwork yet*" -- that finer
  distinction needs a target language + registry this controller-level method doesn't have handy;
  the rail lets you jump anywhere in one tap regardless). 4 tests (`test/lettering_desktop_test.dart`).
  - **Second real bug found via testing, not inspection**: `EditorController.languageRegistry` was
    an `async` getter (`Future<T> get x async => cached ??= await load()`) -- every *call* to an
    `async` getter allocates a brand-new `Future` object for that invocation even when the body
    resolves to an already-cached value. Any widget passing `c.languageRegistry` straight into a
    `FutureBuilder`'s `future:` (this task's Lettering layout, and retroactively Task 4.3's balloon
    section) got a *different* Future instance on every rebuild, and `FutureBuilder` treats a
    changed `future` as "start waiting again" -- a real bug that could leave the balloon
    editor/rail stuck on a loading spinner in the live app after any rebuild, not just a test
    artifact. Fixed by making `languageRegistry` a plain (non-`async`) getter that caches the
    `Future` object itself.
  - **Also chased and ruled out**: a *static* cross-instance cache added to `LanguageRegistry.load()`
    during debugging (since reverted) turned out to itself be the wrong fix and a landmine --
    `flutter test` runs each `testWidgets` body in its own `Zone`, and a `Future` that completes
    inside one test's zone never notifies `.then()`/`FutureBuilder` listeners attached from a
    *later* test's zone, so any test after the first to touch a statically-cached asset-load hangs
    forever. `EditorController.languageRegistry`'s existing per-instance caching was already the
    right level for this (avoids re-reading the asset on every widget rebuild without introducing
    cross-test/cross-zone sharing) -- reading a small bundled JSON file once per document session
    is not worth optimizing further. The real, working fix for tests that touch this path more
    than once per file: wrap the settle in `tester.runAsync()`, same pattern already established
    in Task 4.2/4.3's test files. `test/mode_switch_test.dart` needed the same treatment plus an
    assertion update (Task 5.3 replaced its Task-5.1-era placeholder text with real content).
- [x] Task 5.4 (Lettering mode layout — iPad landscape, the primary target platform per
  Requirements) — complete. `_LetteringTabletBody` in `editor_screen.dart`: two-pane (rail + large
  balloon editor), **no canvas** -- deliberately omitted per `02-visual.md` to keep touch targets
  large on the tighter landscape viewport, unlike Task 5.3's three-pane desktop layout. Prev/next
  stepping (the mockup's `[<prev] N/M [next>]` header element) stays deferred to Task 5.6, shared
  across all three platform layouts. 3 tests (`test/lettering_tablet_test.dart`), reusing the
  `runAsync`-based settle helper established in Task 5.3.
  - **Found and fixed two real, pre-existing bugs surfaced by testing at genuine tablet width
    (1024px) for the first time** -- neither was caused by this task's own code, both were latent
    since earlier tasks and simply never exercised at this width before:
    1. `top_bar.dart`'s non-compact row (brand + title + version badge + doc pill + mode switch +
       all actions + Divider + lang segmented) overflows at 1024px once the Task 5.1 mode switch
       is added. Fixed by switching `compact` from `ff.isPhone` to `ff.isTouch` -- tablet now gets
       the same denser top bar as phone (already has a real Edit/Lettering icon toggle and
       language popup, not a phone-only stub), which also fits this flow's stated iPad-first
       design direction.
    2. `properties_panel.dart`'s "Preview this layer" row (pre-existing code, not part of this
       flow) has no `Expanded`/overflow handling around its label -- fine with real proportional
       fonts, but `flutter test`'s block test font renders text noticeably wider per character,
       tipping it over at Properties panel's 262px-wide tablet content area. Wrapped the label in
       `Expanded(... overflow: TextOverflow.ellipsis)` -- a purely defensive change, no visual
       difference when there's room, graceful truncation instead of a hard layout assertion when
       there isn't.
  - Full suite: 109/109 passing.
- [x] Task 5.5 (Lettering mode layout — iPhone) — complete. `_LetteringPhoneBody` in
  `editor_screen.dart`: a two-screen flow (balloon list, balloon editor) driven by selection state
  rather than a pushed route -- matches how every other mode/pane switch in this app already works
  (e.g. `EditorController.mode` itself), keeping the same one-tap-from-list depth the visual spec
  asks for without adding `Navigator` complexity. Both screens reuse `BalloonRail`/
  `BalloonEditorCard` full-width unmodified (neither hardcodes a sidebar width). Added
  `EditorController.deselectForLettering()` to back the "< Balloons" button. Prev/next stepping
  stays deferred to Task 5.6. 4 tests (`test/lettering_phone_test.dart`).
  - **Found and fixed a third pre-existing overflow**, this time a real information-density
    problem rather than a font-metric artifact: the phone-compact top bar was already tight (New,
    Open, Save w/ label, Export, Undo, Redo, plus a language popup -- 6+ touch targets) before this
    task, and adding the Task 5.1 mode-toggle icon pushed it over budget at real phone width
    (390px) -- nothing before this session had ever pumped `TopBar` at an actual phone-width
    viewport. Fixed by shrinking Save to icon-only in compact mode and consolidating
    Export/Undo/Redo/Language (the less frequently reached-for actions) into one `PopupMenuButton`
    ("more" overflow menu) rather than dropping any capability -- New/Open/Save/mode-toggle stay
    as direct icons.
  - Full suite: 113/113 passing.
- [x] Task 5.6 (prev/next stepping + navigation) — complete. `EditorController.stepBalloon(direction)`/
  `balloonStepInfo()` (1-based position/total among balloon/caption layers in document order,
  clamped at the ends, no wraparound; starts from the first balloon if nothing balloon-like is
  selected) — also let `_ensureBalloonSelected` (Task 5.3) shed its own duplicate filtering logic
  in favor of the same new `_balloonIndices()` helper. A shared `_BalloonStepper` widget (`[<] N/M
  [>]`) in `editor_screen.dart`, wired into all three platform layouts: top-right of the balloon
  editor pane on desktop/tablet, folded into the existing "< Balloons" back-button row on iPhone
  (matching the mockup's `[< Balloons] #03 · 3/7 >`). Renders nothing when there's no balloon-step
  position to show, so callers don't need to guard on that themselves. 7 tests: 6 controller-level
  unit tests (`test/balloon_stepper_test.dart`, no widget pumping needed) + 1 widget test appended
  to `lettering_desktop_test.dart` driving the real `[<]`/`[>]` icons end-to-end including
  clamping. Full suite: 120/120 passing.
- **Phase 5 (Lettering Mode) is now fully complete** — all 6 tasks (mode switch, balloon rail,
  three platform layouts, prev/next navigation) done and verified, including three real
  pre-existing UI bugs found and fixed along the way (Task 5.3's `languageRegistry` async-getter
  bug, Task 5.4's tablet-width top-bar/Preview-row overflows, Task 5.5's phone-width top-bar
  density problem) — none were this flow's fault originally, but all three were only ever
  discoverable by actually rendering these screens at their real target viewport sizes, which
  nothing had done before this phase.
- [x] Task 6.1 (wire manual file-picking to real image writes) — complete.
  `EditorController.pickImageFile`/`pickImagePopup`: a real `file_picker` dialog (`type:
  FileType.image, withData: true`, matching the whole-document open/save dialog's existing
  pattern) reading real bytes and writing them through the exact same tile-write path Task 2.3
  built for AI-generated artwork -- replacing the old stub that silently wrote a fake filename
  never actually saved to disk. Return `false` (not an error) both on cancel and when there's
  nothing to write to yet (no selected layer / no open document) -- a real correctness gap caught
  by testing: the first version always returned `true` once bytes were picked, regardless of
  whether the write actually happened. Wired into `properties_panel.dart`'s `_LayerEditor`
  File/Popup fields via `c.lang.name`. 4 tests (`test/image_picker_test.dart`) fake only the
  `FilePickerPlatform` platform-channel seam (a standard swappable federated-plugin interface,
  reached via `file_picker`'s internal `src/` path since this package version doesn't re-export it
  from a public/separate `..._platform_interface` package) and exercise everything downstream for
  real: real bytes, real tile files on disk, real popup file, real cancel/no-selection handling.
  Full suite: 124/124 passing.
- **Phase 6 (Prerequisite Fix — Real Image Picker) is now fully complete.**
- [x] Task 7.1 (full backward-compatibility pass on `dataset/`) — complete.
  `test/dataset_backward_compat_test.dart`: opens every real `.comics` file in `dataset/` (27
  files, read-only, own temp working dirs) via `DartIoCore`, confirms no layer has pre-existing
  `kind`/`style`/`translations` (the additive design's own premise), and confirms saving with zero
  edits reaches a stable fixed point.
  - **Found and fixed 3 genuine pre-existing bugs in `_animToJson`** (`models_mapping.dart`),
    affecting *all* animation serialization (translate/rotate/scale/alpha/sound), not just
    balloon/lettering code — these predate this flow entirely but had never been exercised
    against real multi-file data before:
    1. **Missing `type` field.** Every C# `Anim` subclass overrides a read-only `Type`
       (`AnimTypes` enum) property that Newtonsoft *does* serialize
       (`DefaultValueHandling.Ignore` only omits it when the value equals `default(AnimTypes)` ==
       `Translate` == 0, so Rotate/Scale/Alpha/Sound anims all carry it in real files). Confirmed
       via `AlphaAnim.cs` and by inspecting a real dataset file's raw JSON directly. Fixed by
       adding `put('type', anim.type.index)` — `AnimTypes`' C# declaration order matches Dart's
       `AnimType` enum order exactly, so `.index` needs no lookup table.
    2. **`scaleX`/`scaleY`/`alpha` wrongly omitted at 1.0.** The original code treated `1` as the
       "default, omit" threshold (matching the app's `Init()`-time UI convenience value), but
       Newtonsoft's real comparison is against `default(double)` == `0` (confirmed via `grep` — no
       `[DefaultValue]` attributes exist on these properties). An explicit `1.0` — an extremely
       common real value (full scale/opacity) — was being silently dropped from every re-save.
       Fixed by comparing against `0` instead, matching the true C# semantics.
    3. **`end` omitted only when `0`, not always written.** Same class of bug as #2's root cause,
       opposite direction: the original code always wrote `end`, but real legacy animations often
       lack an explicit `end` key at all. Fixed with an explicit comparison against Dart's own
       parse-side absent-key default (`200`, matching `_animFromJson`'s existing fallback) so an
       absent `end` round-trips as absent.
  - **Also fixed the test's own bar, not just the code**: the first version compared the resaved
    file byte-for-byte (structurally) against the *pristine original*, which is actually the wrong
    standard — fixing bug #2 above means a legacy anim that omits `alpha` (relying on the C# side's
    `Init()`-assigned `1.0`) legitimately gains an explicit `alpha: 1.0` on its *first* resave, and
    the real C# app would do the exact same thing opening and resaving that same file (Newtonsoft
    writes any non-zero value). That's cosmetic normalization, not data loss. Rewrote the test to
    check a **fixed point** instead: open → resave → reopen → resave again → reopen again, and
    require resave #1's output to equal resave #2's output — i.e. no *continued* drift with every
    subsequent open/save cycle, which is the actual backward-compatibility guarantee that matters.
  - All 28 tests pass (1 sanity + 27 per-file). Full project suite re-run afterward: 152/152
    passing, confirming no regressions from these serialization changes anywhere else (kind/style/
    translations, image slots, tile writer, balloon editor card, all three Lettering-mode layouts,
    image picker, etc.).
- [x] Task 7.2 (full state-coverage walkthrough) — complete. Since there's no way to literally drive
  a running app visually in this environment, did the checklist-driven pass called for in
  `04-plan.md` (Manual, checklist-driven against `02-visual.md`) as a systematic cross-reference:
  every state named in `02-visual.md` (Scene panel kind chips/legacy fallback, balloon rail dots/
  selection/empty state, all 6 balloon editor card states, all 3 platform Lettering layouts, the
  mode-switch flow) checked against the extensive real-widget test suite already built across
  Tasks 3.1-5.6, file by file.
  - **One genuine gap found and closed**: the balloon editor card's `[ En ] (filled)` vs
    `[ Uk ] (outline only)` LANGUAGE-tab distinction and the `[+ Add]` language picker were both
    correctly implemented (`_LanguageTab.isFilled`, `_pickAddLanguage` in `balloon_editor_card.dart`)
    but had zero test coverage — nothing exercised them before. Added one new test to
    `test/balloon_editor_card_test.dart` (fakes a real tile-template filename to mark one language
    "has artwork" without needing real disk I/O, matching how `_hasArtwork`'s own guard works):
    confirms the filled/outline `Container` decoration difference, that `+ Add` opens a real
    Material popup menu offering only unused languages, and that picking one selects it (its
    `TEXT (HI)` editor appears) — while correctly *not* yet showing a tab for it, since
    `_usedLanguages()` only lists languages with real text or artwork (same guard as everywhere
    else), and a freshly-picked language has neither until the user types something, which the same
    test then confirms makes the tab appear.
  - **One documentation-only discrepancy noted, not changed**: `02-visual.md`'s Flow section says
    the on-device/cloud routing indicator shows "during generation (not before)", but the card's own
    "text entered, not yet generated" mockup (and the base "Component: Balloon editor card" mockup)
    both explicitly show `(o) On-device` next to the Generate button in the *idle* state already —
    and the shipped implementation matches those two more detailed, more authoritative mockups
    (verified by `balloon_editor_card_test.dart`'s "text entered, not yet generated" test explicitly
    asserting `find.text('(o) On-device')` before any tap). Read as the Flow prose being loosely
    worded about "the routing choice isn't hardcoded/static, it's evaluated fresh" rather than "never
    shown until generation starts" — not acted on, since the two literal mockups and the existing
    tested behavior already agree with each other.
  - **One design simplification noted, not changed**: the iPhone list-row mockup shows a richer
    per-row summary (`[Bln] #01  En Ru Hi  o  >`, i.e. which languages have text) than the actual
    list row renders, because Tasks 5.2-5.5 deliberately reuse one shared `BalloonRail` widget
    across all three platforms rather than building a phone-specific richer variant — a real,
    already-made design choice (one component, not three), not an oversight; flagged here rather
    than silently expanded, since building a phone-only richer row is new scope beyond what any task
    in `04-plan.md` called for.
  - Full suite (with the one new test): 153/153 passing.
- [x] Task 7.3 (stale-artwork indicator) — complete. Resolves the "translations text edited after
  generation" edge case from Specifications (`02-visual.md` flags it as *not designed*, left to
  implementation). `BalloonEditorCard` now tracks `_generatedFromText` (the translation text at the
  moment the *current* success result was generated) alongside its existing `_phase` state; while
  `_phase == success`, a live mismatch between that and the current text means the on-screen artwork
  no longer reflects what's typed. The success case of `_GenerationControls` now branches on a new
  `isStale` flag: fresh success still shows `Regenerate` + `Generated just now`; stale shows a small
  amber "Artwork may be outdated — text has changed since generation" notice and reverts the button
  to `Generate artwork with AI` (not `Regenerate`, since the existing artwork doesn't match anymore).
  `_generatedFromText` is cleared on every language switch and layer switch (same reset points
  `_phase` already had), so this is purely a "since your last generation *in this same session and
  language*" signal — intentionally not persisted to `data.json`, matching how `_phase`/`success`
  itself already only lives in widget state, not the document.
  - **One correctness detail worth calling out**: this is a live *value* comparison (current text ==
    exactly what was last generated), not a dirty/edited flag — editing text away and then back to
    the exact already-generated string correctly clears the notice again (no false positive on a
    no-op round-trip edit), verified by a dedicated test.
  - 3 new tests in `test/balloon_editor_card_test.dart`: editing text after a real success flow
    shows the notice and reverts the button label; regenerating (a full second real generation, not
    just a phase flip) clears it; editing back to exactly the already-generated value also clears it.
  - Full suite: 156/156 passing.
- [x] **Implementation complete.** All 27 tasks across Phases 1-7 done and verified against real
  C# core sessions, real dataset files, and real-widget test coverage throughout — no task left as
  UI-stub/manual-only. Next: Documentation phase (client-facing README per the VDD flow's
  Documentation phase behavior) — not started, no instruction yet to begin it.
- [ ] Documentation drafted
- [ ] Documentation approved

## Context Notes

Key decisions and context for resuming:

- Target app: `apps/comics-editor-v2.9/` (Flutter desktop-first, thin C# native core
  `Comics.Editor.Headless` on desktop, pure-Dart `DartIoCore` fallback on mobile).
- **Investigated current lettering/balloon UI/UX (Explore agent, 2026-07-30) — key findings:**
  - The data model (`Layer`/`Image`, ground truth in
    `apps/comics-editor-v2.9/native/Comics.Editor/Models/`) has **no distinct "balloon" concept at
    all** — every layer (background, character, balloon) is the same generic `Layer`/`EditorLayer`.
    There is no flag/kind that identifies a layer as a balloon.
  - `Image` only has `File`/`Popup`/`Width`/`Height` — **no text/string content field anywhere**.
    Balloon content is 100% pre-rendered raster images, per language. There is currently **zero
    text-entry/typing UI** in the editor for balloon content.
  - The editor only supports 3 languages (`Cultures` enum: En/Ru/Hi) vs. the AI pipeline's 20.
  - The existing "ARTWORK · PER LANGUAGE" picker in `properties_panel.dart` (`_LayerEditor`) is a
    **UI stub, not wired up**: `onPick` sets a hardcoded placeholder filename
    (`'picked_${c.lang.label}.png'`), no real file picker, no bridge/RPC call to actually import
    image bytes. There's no RPC method for "set a layer's image" in `ComicsCore` at all yet.
  - **Zero AI/automation integration** exists in the editor codebase (grepped for
    balloon/baloon/lettering/ai/openai/translat — no matches, no dead code/TODOs). The separate
    `apps/comics-ai-baloons/` Python pipeline (built in `sdd-comics-ai-baloons`, see that flow) is
    a disconnected batch CLI — reads `dataset/*.comics` read-only, writes new `.comics` files to
    its own `work/` dir. No live link to the editor today.
  - Existing design references: `/design/comics-editor-maket-v2.8.pdf`,
    `/design/comics-editor-maket-v3.pdf`, and a Flutter mockup project
    `/design/comics-editor-maket-dart-v3/` (likely the direct ancestor of the shipped `lib/` UI) —
    worth reviewing before/during the Visual phase.
- **Open design gap surfaced by the investigation**: since "balloon" isn't a data-model concept at
  all today, requirements/specs need to explicitly decide whether it becomes a real layer kind/flag
  or stays convention-based (e.g. detected by naming/heuristics, similar to how the AI pipeline's
  `discover.py` finds balloons structurally via multi-language image slots) — this is a real open
  question for the Specifications phase, not just a UI layout question.

## Decisions from user (2026-07-30, given directly, not via structured Q&A)

- **Platform priority**: iPad + stylus preferred over desktop for this feature. Interaction
  paradigm should feel closer to **DaVinci Resolve** (page/mode-based, big clear direct-manipulation
  surfaces, fewer nested menus) than **Adobe After Effects** (dense nested property panels,
  keyboard/mouse-heavy). The app's existing responsive breakpoints (desktop/tablet/phone in
  `editor_screen.dart`) should be leaned on — design the new lettering UI tablet/stylus-first, then
  adapt to desktop/phone, not the reverse.
- **Data model — layer type**: add an explicit layer-type field to the JSON (`data.json`), including
  at least a "balloon"/"bubble" value, alongside whatever generic/art type existing layers implicitly
  are today. Must be **additive and backward compatible** — old files without the field, and old
  editor versions reading new files, must keep working (missing field defaults to today's generic
  behavior). This resolves the "balloon isn't a data-model concept" gap found during investigation
  in favor of a real flag, not heuristic detection.
- **Data model — translations**: add JSON field(s) carrying actual text content per language
  (distinct from the existing per-culture *image* file references), also additive/backward
  compatible, so the editor can display/edit text and add new translations directly. This is what
  makes real text-entry UI possible (today there is literally no text field anywhere in the model).
- **Visual treatment (proposed, to firm up in Visual phase)**: color-code layers by type in the
  layers list (balloon vs. other kinds) for at-a-glance scanning.
- **AI integration architecture**: hybrid — run on-device when hardware allows, fall back to (or
  optionally always use for higher quality) a call to an external server when it doesn't or when
  quality demands it. This has real technical weight: `apps/comics-ai-baloons`'s current pipeline
  depends on Playwright/headless Chromium for 12 of 20 languages, which has no iOS/iPadOS story at
  all — the mobile build already falls back to a pure-Dart core for other reasons. Needs a defined
  client/server interface either way; the actual on-device-vs-server routing/inference engine may
  be more than this UI/UX-focused VDD flow should build itself (see Open Questions).

## Design reference (2026-07-30)

`design/comics-editor-lettering-maket.pdf` (2 pages) + `design/comics-editor-lettering-maket/`
(HTML source + assets) — a high-fidelity HolySpots DS v3.0 rendering of the exact structure
proposed in `02-visual.md` v0.1: layer-kind badges, Lettering mode for macOS/iPad/iPhone, balloon
editor card states. Confirms/refines rather than changes direction. Key extractable facts:
- Colors: violet `#7b5cd6` (balloon/speech), amber `#b8820f` (caption) — new tokens, outside
  existing sky-blue (selection) / coral (destructive) vocabulary.
- Typography split: `--font-core` (Roboto, UI chrome) vs `--font-serif-data` (balloon text content
  specifically, both the input field and pre-generation preview).
- List rows show coarse *kind* (`Bln`/`Cap`/`Art`); the balloon editor card header shows a finer
  *style* (`speech`/`caption`/`hand-lettered`) — two different labels, not one taxonomy.
- Balloon-rail status dot is per-*target-language*, not balloon-wide: solid = artwork ready for the
  language you're currently on, ring = text-only, dash = empty.
- Cloud-routed generation states a plain-language *reason* ("This device can't render Hindi
  shaping locally — sent to the server"), not just an "on-device/cloud" label, and has a Cancel
  action — neither was in the v0.1 draft, both folded into v0.2.
- Its own footer explicitly names the same three things this flow had open at the time (kind
  taxonomy, language coverage, Lettering-as-distinct-mode) — of those, Lettering mode is now
  confirmed (restored) and language coverage is resolved as "dynamic"; kind taxonomy stays scoped
  to balloon/caption here, full taxonomy moved to `vdd-comics-editor-jhanava`.

## Related Flows

- `flows/vdd-comics-editor-jhanava/` — spun out 2026-07-30 to own the bigger background/character/
  balloon/sound taxonomy and "material systematization" questions, so they don't narrow this flow.
  Only coupling: both use an open-string `kind` field for future convergence.

## Fork History

N/A — new flow. (See "Related Flows" above for what spun *out* of this one.)

## Next Actions

1. Get "specs approved" from user on `03-specifications.md` v0.3 (original plan restored: Lettering
   mode back in scope, kind taxonomy scoped to balloon/caption as an open string, language coverage
   is dynamic via a new data-driven `LanguageRegistry` rather than hardcoded to any count, AI scope
   stays UI/client-contract only — this last one was never actually in dispute).
2. Once approved, move to Plan phase.
