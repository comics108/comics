# Implementation Plan: comics-editor-uiux-lettering

> Version: 1.1
> Status: APPROVED (Phase 1/2 corrected during implementation — see note)
> Last Updated: 2026-07-30
> Specifications: [03-specifications.md](03-specifications.md)

## Correction (2026-07-30, made while starting implementation)

Phase 2 as originally written ("Bridge / RPC": 3 new RPC methods across `comics_core.dart`,
`core_client.dart`, `dart_io_core.dart`, and the native headless process) **doesn't match the real
architecture** — verified by reading the actual code, not by continuing to build on the original
Specifications assumption. `ComicsCore` is a single generic `call(method, params)`; there are no
typed per-field RPCs anywhere in the app. The real pattern: local in-memory mutation (like today's
`setImageFile`) + one full-document `saveComics` write. Image bytes go directly into a working
directory both the native core and `DartIoCore` already maintain across open→save (`tempFolder`,
returned by `openComics`/`ping` today but discarded by the Dart UI).

**Net effect: Phase 2 (RPC) is gone.** Its two real pieces of work — capturing `tempFolder`, and a
Dart-side tile writer — are folded into Phase 1. Everything downstream (kind UI, balloon editor
card, Lettering mode) still applies, just wired to local `EditorController` mutations instead of
RPC calls, which is simpler, not harder. See `03-specifications.md`'s matching correction note.

## Summary

Six phases now (Bridge/RPC folded away — see Correction above), ordered by dependency: data model +
backward-compat + the tile-writing mechanism first, since everything else uses it; then the generic
kind-tagging UI; then the reusable balloon editor component; then Lettering mode itself (which just
hosts that component in a new layout); then the prerequisite manual-file-picker fix; then testing.
The balloon editor component is deliberately built to work standalone (embeddable in the existing
Properties panel) before Lettering mode wraps it, so there's a working, testable surface well before
the biggest, riskiest UI piece (the new mode/page across 3 platform layouts) is done.

`BalloonAiClient` is built and tested against a stub throughout — no task in this plan implements
a real on-device engine or server, per Specifications' explicit scope boundary.

## Task Breakdown

### Phase 1: Data Model & Backward Compatibility

#### Task 1.1: Add `Kind`/`Style`/`Translations` to the C# `Layer` model
- **Description**: Add the three new properties to `Layer.cs`, relying on the existing
  `DefaultValueHandling.Ignore` + unset `MissingMemberHandling` serializer config (verified in
  Specifications) for backward compatibility — no new serialization logic needed, just the
  properties themselves.
- **Files**:
  - `apps/comics-editor-v2.9/native/Comics.Editor/Models/Layer.cs` - Modify
- **Dependencies**: None
- **Verification**: Unit test — serialize a `Layer` with all three unset, confirm output JSON has
  none of the three keys; deserialize a real legacy `data.json` layer, confirm no error and all
  three come back at their defaults
- **Complexity**: Low

#### Task 1.2: Additive `Images[]` extension for languages beyond the 3 `Cultures` values
- **Description**: **Pure Dart, no C# change** (corrected — `List<Image>` has no fixed size on
  either side already; `apps/comics-ai-baloons` proved this same additive-append trick works with
  zero native involvement). Resolve a `langCode` to an index: 0/1/2 for `en`/`ru`/`hi` (matching
  `Cultures`), or its position in the canonical ordered language list from Task 1.4's registry for
  anything else (`uk`=3, `th`=4, ... — a fixed, versioned-with-the-app ordering, append-only, so
  it's reconstructible from `data.json` + the shipped registry alone, no per-document bookkeeping
  needed). Appending to the registry later only ever adds new trailing indices, never reorders.
- **Files**:
  - `apps/comics-editor-v2.9/lib/src/i18n/language_registry.dart` - Modify (add
    `indexFor(langCode)`, sharing Task 1.4's data)
  - `apps/comics-editor-v2.9/lib/src/ui/models.dart` - Modify (`EditorLayer.imageSlotFor(langCode)`
    helper: existing slot, or extend `images` with empty placeholders up to the target index)
- **Dependencies**: Task 1.4
- **Verification**: Unit test — `en`/`ru`/`hi` resolve to 0/1/2; a new language resolves to its
  registry position; writing a new language twice updates the same slot, not a duplicate; the
  mapping is correct after a simulated reopen (rebuild from a fresh `EditorLayer` + the registry)
- **Complexity**: Low (downgraded from Medium — no longer touches C#, no longer needs new
  persisted state)

#### Task 1.3: Mirror new fields in Flutter (`EditorLayer` + `models_mapping.dart`)
- **Description**: Add `kind`/`style`/`translations` to `EditorLayer`; extend the explicit
  raw-JSON mapping both directions.
- **Files**:
  - `apps/comics-editor-v2.9/lib/src/ui/models.dart` - Modify
  - `apps/comics-editor-v2.9/lib/src/bridge/models_mapping.dart` - Modify
- **Dependencies**: Task 1.1
- **Verification**: Unit test round-tripping a `CoreDocument` with the new fields through the
  mapping layer
- **Complexity**: Low

#### Task 1.4: `LanguageRegistry` (data-driven language list)
- **Description**: A small config resource (JSON, bundled with the app) listing available
  language codes + display names, seeded from `apps/comics-ai-baloons/scripts/languages.py`'s
  table (copy the list, not a code dependency on that Python project). A `LanguageRegistry` Dart
  class loads it; `availableLanguages()` returns the full list, and callers combine that with
  "languages already used in this document" to build `[+ Add]` options.
- **Files**:
  - `apps/comics-editor-v2.9/lib/src/i18n/language_registry.dart` - Create
  - `apps/comics-editor-v2.9/assets/languages.json` (or similar) - Create
- **Dependencies**: None
- **Verification**: Unit test — registry loads the bundled file; adding an entry to the JSON file
  and re-running the test picks it up with no code change (this is the actual test of "dynamic,
  not hardcoded")
- **Complexity**: Low

### Phase 2: Working-Directory Image Writes (replaces the original "Bridge / RPC" phase)

#### Task 2.1: Capture `tempFolder` into `CoreDocument`
- **Description**: `openComics`'s RPC response already includes `tempFolder` (verified in both the
  C# core and `DartIoCore`); `comicsFromCore` currently reads only the `comics` key and discards
  it. Thread it through into `CoreDocument` so later tasks can find the working directory.
- **Files**:
  - `apps/comics-editor-v2.9/lib/src/bridge/models_mapping.dart` - Modify (`CoreDocument` gets a
    `tempFolder` field; `comicsFromCore` populates it)
  - `apps/comics-editor-v2.9/lib/src/ui/controller.dart` - Modify (`openPath` already has the raw
    RPC result in scope — pass it through)
- **Dependencies**: None
- **Verification**: Unit test — open the test fixture via both `CoreClient` and `DartIoCore`,
  confirm `tempFolder` is a real, existing directory containing `data.json` and a `layers/` folder
- **Complexity**: Low

#### Task 2.2: Dart tile writer (512px tiles, matching the existing convention)
- **Description**: Given a single flat image (from AI generation or a picked file) and a target
  filename stem, split into 512px tiles named `<stem>_1000_<col>_<row>.png` (the exact convention
  reverse-engineered in `apps/comics-ai-baloons/scripts/tiling.py` — reimplemented in Dart here
  since that's a separate Python project, not something this Flutter app can import), write them
  into `<tempFolder>/layers/`.
- **Files**:
  - `apps/comics-editor-v2.9/lib/src/io/tile_writer.dart` - Create
- **Dependencies**: Task 2.1
- **Verification**: Unit test — tile a known-size test image, confirm tile count/filenames match
  `apps/comics-ai-baloons`'s own tiling test expectations for the same dimensions; write into a
  real opened document's `tempFolder`, call `saveComics`, reopen, confirm the image round-trips
  pixel-identical (mirrors the round-trip test already proven in the Python pipeline)
- **Complexity**: Medium (porting tested logic to a new language/runtime, not new design)

#### Task 2.3: Wire real image bytes into `setImageFile`/`setImagePopup`
- **Description**: Replace the hardcoded placeholder in `properties_panel.dart`'s `onPick` and
  `EditorController.setImageFile`/`setImagePopup`: given real bytes (from a file pick or AI
  generation) and a target `langCode`, resolve the slot index (Task 1.2), tile-write into
  `tempFolder` (Task 2.2), update `EditorLayer.images[index]` with the new filename/width/height.
  This single change point serves both the AI-generation path (Phase 4) and the manual file-picker
  fix (Phase 6).
- **Files**:
  - `apps/comics-editor-v2.9/lib/src/ui/controller.dart` - Modify
- **Dependencies**: Task 1.2, Task 2.2
- **Verification**: Integration test — set an image for an existing-`Cultures` language and for a
  new registry language, `saveComics`, reopen, confirm both round-trip correctly with distinct,
  correct `Images` entries
- **Complexity**: Medium (downgraded from the original Task 2.3's High — no native/cross-process
  boundary to debug, it's direct filesystem access on both desktop and mobile)

### Phase 3: Kind-Tagging UI (Edit mode, applies to every layer)

#### Task 3.1: Kind chip in the layer list
- **Description**: Small chip before each layer's thumbnail — `Balloon`/`Caption`/nothing (today's
  default), color + label per `02-visual.md`.
- **Files**:
  - `apps/comics-editor-v2.9/lib/src/ui/widgets/properties_panel.dart` or wherever the layer list
    row widget actually lives (Explore agent's report referenced `_LayerEditor` in
    `properties_panel.dart` for the editor, but the layer *list* row itself may be a different
    widget — confirm exact file when starting this task) - Modify
- **Dependencies**: Task 1.3
- **Verification**: Manual — open a file with mixed kinds, confirm chips render correctly; open a
  legacy file, confirm no chips (identical to today)
- **Complexity**: Low

#### Task 3.2: Kind-setting UI
- **Description**: Resolves the Open Design Question from Specifications — a dropdown/picker in
  the properties panel's per-layer editor, offering `Balloon`/`Caption`/`(none)`. Decided here as
  a simple dropdown rather than a context menu, since it needs to be discoverable and this flow
  has no other per-layer settings surface besides the properties panel.
- **Files**:
  - `apps/comics-editor-v2.9/lib/src/ui/widgets/properties_panel.dart` - Modify
  - `apps/comics-editor-v2.9/lib/src/ui/controller.dart` - Modify (`setLayerKind` — local mutation,
    same shape as today's `setImageFile`; no RPC, per the Phase 2 correction)
- **Dependencies**: Task 1.3, Task 3.1
- **Verification**: Manual — set/change/clear a layer's kind, confirm chip updates, confirm it
  persists across save/reopen
- **Complexity**: Low

### Phase 4: Balloon Editor Card (shared component)

#### Task 4.1: `BalloonAiClient` interface + stub implementation
- **Description**: The abstract contract from Specifications, plus a fake implementation
  (deterministic delay, always succeeds or lets a test force specific `GenerationEvent`s) so every
  later task can build/test against it without a real engine.
- **Files**:
  - `apps/comics-editor-v2.9/lib/src/ai/balloon_ai_client.dart` - Create
  - `apps/comics-editor-v2.9/lib/src/ai/stub_balloon_ai_client.dart` - Create
- **Dependencies**: None
- **Verification**: Unit test — stub emits the expected event sequence for success/failure/
  hand-lettered-rejection paths
- **Complexity**: Low

#### Task 4.2: `BalloonEditorCard` widget — states
- **Description**: The reusable component from `02-visual.md`: artwork preview, language tabs
  (sourced from `LanguageRegistry` + document's existing `translations` keys), text field,
  Generate button, all card states (empty, text-entered, generating with routing indicator +
  Cancel, success, failure, hand-lettered-disabled).
- **Files**:
  - `apps/comics-editor-v2.9/lib/src/ui/widgets/balloon_editor_card.dart` - Create
- **Dependencies**: Task 1.4, Task 4.1
- **Verification**: Manual walkthrough of every state against `02-visual.md`, using the stub
  `BalloonAiClient` to force each generation outcome
- **Complexity**: High (most states, most interaction logic of any single task in this plan)

#### Task 4.3: Wire the card into Edit mode's Properties panel
- **Description**: When a layer's `kind == "balloon"`, show `BalloonEditorCard` in its properties
  editor, wired to `setLayerTranslation` (local mutation, Task 1.3) and the image-write path
  (Task 2.3) plus a real (or still-stub, depending on engine availability — doesn't block this
  task) `BalloonAiClient`.
- **Files**:
  - `apps/comics-editor-v2.9/lib/src/ui/widgets/properties_panel.dart` - Modify
- **Dependencies**: Task 4.2, Task 2.3, Task 3.2
- **Verification**: Manual — full generate flow from within Edit mode, no Lettering mode needed
- **Complexity**: Medium

### Phase 5: Lettering Mode

#### Task 5.1: Mode switch (top bar)
- **Description**: Edit/Lettering toggle in `editor_screen.dart`'s top bar, switching which
  panes/layout render.
- **Files**:
  - `apps/comics-editor-v2.9/lib/src/ui/screens/editor_screen.dart` - Modify
- **Dependencies**: None (can be built in parallel with Phase 4)
- **Verification**: Manual — toggle switches views, Edit mode content unaffected
- **Complexity**: Low

#### Task 5.2: Balloon rail
- **Description**: Filtered list of the current page's balloon/caption-kind layers, with
  per-target-language status dots (solid/ring/dash, per `02-visual.md`).
- **Files**:
  - `apps/comics-editor-v2.9/lib/src/ui/widgets/balloon_rail.dart` - Create
- **Dependencies**: Task 1.3
- **Verification**: Manual — matches `02-visual.md`'s rail mockups across the 3 status-dot states
- **Complexity**: Medium

#### Task 5.3: Lettering mode layout — macOS/desktop
- **Description**: Three-pane layout (rail | canvas-with-highlighted-balloon | editor card), per
  `02-visual.md`'s macOS mockup.
- **Files**:
  - `apps/comics-editor-v2.9/lib/src/ui/screens/editor_screen.dart` - Modify
- **Dependencies**: Task 5.1, Task 5.2, Task 4.2
- **Verification**: Manual against the macOS mockup
- **Complexity**: Medium

#### Task 5.4: Lettering mode layout — iPad landscape
- **Description**: Two-pane layout (rail + large editor card, no canvas context), 44px touch
  targets throughout, per `02-visual.md`'s iPad mockup. This is the primary target platform per
  Requirements.
- **Files**: Same as Task 5.3
- **Dependencies**: Task 5.3 (shares most of the underlying widgets, different arrangement)
- **Verification**: Manual against the iPad mockup, on an actual iPad or simulator with touch,
  not just a resized desktop window
- **Complexity**: Medium

#### Task 5.5: Lettering mode layout — iPhone
- **Description**: Two-screen flow (balloon list screen -> balloon editor screen), per
  `02-visual.md`'s iPhone mockup.
- **Files**: Same as Task 5.3
- **Dependencies**: Task 5.3
- **Verification**: Manual against the iPhone mockup
- **Complexity**: Medium

#### Task 5.6: Prev/next stepping + navigation
- **Description**: Step through balloons without leaving Lettering mode (arrows/swipe), consistent
  across all 3 platform layouts.
- **Files**: Same as Task 5.3
- **Dependencies**: Task 5.3, 5.4, 5.5
- **Verification**: Manual
- **Complexity**: Low

### Phase 6: Prerequisite Fix — Real Image Picker

#### Task 6.1: Wire manual file-picking to real image writes
- **Description**: The non-AI half of fixing the stub: a real file picker dialog for the existing
  "ARTWORK · PER LANGUAGE" section, using the same image-write path Task 2.3 built (`file_picker`
  is already a dependency, already used for whole-document open/save — just not per-layer images).
  Not strictly required for the balloon/AI flow to work (AI generation already produces bytes
  without needing a file picker), but the stub was broken for manual use too and this is the
  natural place to fix it since the write path now exists.
- **Files**:
  - `apps/comics-editor-v2.9/lib/src/ui/controller.dart` - Modify
  - `apps/comics-editor-v2.9/lib/src/ui/widgets/properties_panel.dart` - Modify (real file picker
    invocation, replacing the hardcoded placeholder)
- **Dependencies**: Task 2.3
- **Verification**: Manual — pick a real file, confirm it's written and displayed correctly
- **Complexity**: Low

### Phase 7: Testing & Polish

#### Task 7.1: Full backward-compatibility pass
- **Description**: Open every real file in `dataset/` (read-only, never write there — work on
  copies) in the updated app; confirm no crash, no visible change to any layer without an explicit
  `kind`, and re-saving produces JSON equivalent to the original for untouched layers.
- **Files**: None (test execution)
- **Dependencies**: All of Phase 1-2
- **Verification**: Automated where possible (JSON diff), manual spot-check the rest
- **Complexity**: Medium

#### Task 7.2: Full state-coverage walkthrough
- **Description**: Every state in `02-visual.md` (both the card states and the 3 platform Lettering
  mode layouts), against the running app, using the stub `BalloonAiClient` to force each outcome.
- **Files**: None (test execution)
- **Dependencies**: All of Phase 4-5
- **Verification**: Manual, checklist-driven against `02-visual.md`
- **Complexity**: Medium

#### Task 7.3: Stale-artwork indicator
- **Description**: Resolves the "translations text edited after generation" edge case from
  Specifications — not designed in `02-visual.md` at all, needs a small visual addition (e.g. a
  badge on the language tab) plus the underlying "is this text different from what was last
  generated" check.
- **Files**:
  - `apps/comics-editor-v2.9/lib/src/ui/widgets/balloon_editor_card.dart` - Modify
- **Dependencies**: Task 4.2
- **Verification**: Manual — generate, edit text, confirm indicator appears; regenerate, confirm
  it clears
- **Complexity**: Low

## Dependency Graph

```
1.1 (C# Layer fields) ──→ 1.3 (Dart mirror) ──┬──────────────────────────┐
                                                │                          │
1.4 (LanguageRegistry) ──┬─→ 1.2 (slot index)  ├─→ 3.1 ─→ 3.2             │
                          │        │            │                          │
                          │        ↓            │                          │
                          │  2.1 (tempFolder) ──┼─→ 2.2 (tile writer) ──→ 2.3 (wire real bytes)
                          │                      │                          │        │
4.1 (BalloonAiClient) ────┼──────────────────────┼─→ 4.2 (BalloonEditorCard)         │
                          │                      │        │                 │        │
                          └──────────────────────┘        ↓                 │        │
                                              4.3 (wire card into panel) ←───┴────────┤
                                                       │                              │
                                    5.1,5.2 ─→ 5.3 ─┬─→ 5.4 ─┬─→ 5.6                  │
                                                     └─→ 5.5 ─┘                       │
                                    (5.3/5.4/5.5 all depend on 4.2)                   │
                                                                                       │
                                                       6.1 (manual file picker) ←──────┘
                                                                                       
                        7.1 ← (Phase 1-2)     7.2 ← (Phase 4-5)     7.3 ← 4.2
```

(Simplified — see per-task Dependencies for the exact list; the graph's main point is that Phase 1
gates everything, `2.3` (real image writes) gates both Phase 4's generation flow and Phase 6's
file-picker fix, and Phase 4's `BalloonEditorCard` gates all of Phase 5.)

## File Change Summary

| File | Action | Reason |
|------|--------|--------|
| `native/Comics.Editor/Models/Layer.cs` | Modify | `Kind`/`Style`/`Translations` properties only — no additive-`Images[]` logic needed here (that's pure Dart, see Task 1.2's correction) |
| `lib/src/ui/models.dart` | Modify | Mirror new fields; `imageSlotFor(langCode)` helper |
| `lib/src/bridge/models_mapping.dart` | Modify | Map new fields both directions; `CoreDocument.tempFolder` |
| `lib/src/ui/controller.dart` | Modify | Local `setLayerKind`/real `setImageFile`/`setImagePopup` (no RPC) |
| `lib/src/io/tile_writer.dart` | Create | Dart port of the 512px tiling convention |
| `lib/src/bridge/dart_io_core.dart` | Modify | Mobile RPC implementation |
| `lib/src/ui/controller.dart` | Modify | Real `setImageFile`/`setImagePopup`, no more placeholder |
| `lib/src/ui/widgets/properties_panel.dart` | Modify | Kind chip, kind picker, embedded balloon editor card, real file picker |
| `lib/src/ui/screens/editor_screen.dart` | Modify | Lettering mode switch + 3 platform layouts |
| `lib/src/ui/widgets/balloon_editor_card.dart` | Create | Reusable component, all states |
| `lib/src/ui/widgets/balloon_rail.dart` | Create | Lettering mode's balloon list |
| `lib/src/ai/balloon_ai_client.dart` | Create | Contract interface |
| `lib/src/ai/stub_balloon_ai_client.dart` | Create | Test/dev implementation |
| `lib/src/i18n/language_registry.dart` | Create | Dynamic language list loader |
| `assets/languages.json` (path TBD) | Create | Language registry data, seeded from `comics-ai-baloons` |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Tile-writer (Task 2.2) porting the tiling convention from Python to Dart introduces a subtle mismatch with what the native core expects to read back | Low-Medium (downgraded — direct filesystem access now, not a native RPC boundary; the convention itself is already fully reverse-engineered and tested in `apps/comics-ai-baloons`) | Medium | Task 2.2's verification explicitly round-trips through a real `saveComics`/reopen, not just unit-testing the tiling math in isolation |
| `CoreClient` (desktop) and `DartIoCore` (mobile) `tempFolder` semantics drift (e.g. one clears it at a different point in its lifecycle than the other) | Medium | Medium | Task 2.1's verification explicitly checks both |
| iPad-specific layout (Task 5.4, the primary target platform) only gets tested on a resized desktop window instead of real touch | Medium | Medium | Task 5.4's verification explicitly calls for a real iPad or simulator with touch, not a resized window |
| `Images[]` additive-extension ordering (Task 1.2) drifts from `apps/comics-ai-baloons`'s own language ordering, producing incompatible indices if the two ever need to interoperate on the same file | Low | Low (no current requirement that they interoperate) | Task 1.4's registry data is explicitly seeded from `comics-ai-baloons/scripts/languages.py`, same order, noted in that task |
| `BalloonAiClient` real implementation never materializes (out of scope) and this whole feature ships with only a stub | Low (expected, not a bug) | N/A | This is the intended scope boundary per Specifications — the plan is designed so every other task's value doesn't depend on the real engine existing |

## Rollback Strategy

1. All new C#/Dart fields are additive; reverting is a standard `git revert` of the relevant
   commits, no data migration needed in either direction (per the verified backward-compat
   properties in Specifications).
2. If Phase 2's RPC work proves too risky mid-implementation, Phases 3-6 can't proceed (they all
   depend on it), but Phase 1's data-model work stays valid and shippable on its own (round-trips
   correctly even with no UI reading/writing it yet) — not wasted work.

## Checkpoints

After each phase, verify:

- [ ] All unit/integration tests for that phase pass
- [ ] Manual verification steps for that phase are done, not skipped
- [ ] A legacy `dataset/`-style file (copied, not the original) still opens and behaves identically
- [ ] No regression in Edit mode's existing (non-balloon) functionality

## Open Implementation Questions

- [ ] Exact mechanism for `Images[]` additive-extension reconstructibility (Task 1.2) — decide
      during implementation, not pinned in Specifications.
- [ ] Exact file/entry point for the native `Comics.Editor.Headless` RPC handler additions (Task
      2.1-2.3) — Explorer's investigation didn't map this file specifically.
- [ ] `assets/languages.json`'s exact format and build-time bundling mechanism (Task 1.4).
- [ ] Whether `BalloonEditorCard`'s embedded-in-Properties-panel form (Task 4.3) and its
      Lettering-mode form (Task 5.3-5.5) are truly the same widget instance in two containers, or
      two thin wrappers around shared internal state — implementation detail, decide when writing
      Task 4.2.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-07-30
- [x] Notes: Approved as-is.
