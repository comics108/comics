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
- **Phase 3 (Kind-Tagging UI) is now fully complete.** Full suite: 72/72 passing. Next: Phase 4
  (Balloon Editor Card).
- [ ] Implementation complete (Phases 4-7 remain)
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
