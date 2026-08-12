# Implementation Plan: dot-comics-format v2026 schema additions

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-08-07
> Requirements: [01-requirements.md](01-requirements.md)
> Specifications: [03-specifications.md](03-specifications.md)
> Visual: [04-visual.md](04-visual.md)

## Summary

Six additive, backward-compatible schema/UI items were decided in Requirements/Specifications/
Visual and are now approved. This plan breaks each into concrete tasks against the real
`apps/comics-editor` codebase (`lib/src/ui/models.dart`, `lib/src/bridge/models_mapping.dart`,
`lib/src/ui/controller.dart`, `lib/src/ui/widgets/dialogs.dart`, `scene_panel.dart`,
`properties_panel.dart`, `canvas_view.dart`), sequenced so foundational pieces (`Layer.Id`, the
JSON round-trip pattern) land before anything that depends on them.

Every item follows the same backward-compat shape already proven for `Kind`/`Style`/
`Translations`/`GroupId`: a new nullable/defaulted field, absent → today's exact behavior, no
reader ever required to understand it.

Each Open Design Question carried forward from Specifications (field names not yet
Anton-confirmed verbatim, `Layer.Id` generation scheme, orphan policy, `ParentId`/`GroupId`
relationship, `solidColor`/`Images[]` precedence, time-basis units) gets its own task to resolve
during implementation — not deferred silently.

## Task Breakdown

### Phase 1: Foundation — `Layer.Id` and the JSON round-trip pattern

Everything else (`ParentId`, and any future cross-layer reference) needs stable layer identity
first. Doing this phase alone, before anything reads/writes it, keeps the diff reviewable.

#### Task 1.1: Add `EditorLayer.id` (stable identity)
- **Description**: Add a `String id` field to `EditorLayer` (`models.dart:105`), generated once at
  construction, never reassigned, preserved across `clone()`. Resolves the open "generation scheme"
  question: use `package:uuid`'s v4 (already idiomatic Flutter; no existing dependency conflict
  expected — verify in `pubspec.yaml` during implementation) rather than sequential ints, since
  sequential ids require a document-wide counter that must itself survive undo/redo/merge, which
  uuid avoids entirely.
- **Files**:
  - `lib/src/ui/models.dart` — `EditorLayer` constructor (`:106`), `clone()` (`:161`)
  - `pubspec.yaml` — add `uuid` dependency if not already present
- **Dependencies**: None
- **Verification**: New layer gets a non-empty id; `clone()` produces a *new* id (a clone is a
  distinct layer, not the same identity) — add a unit test asserting `original.id != clone().id`.
- **Complexity**: Low

#### Task 1.2: Persist `Layer.Id` in JSON (additive)
- **Description**: Add `id` to `_layerToJson`'s output and read it back in `comicsFromCore`
  (`models_mapping.dart` — the layer read/write loop around `:188`). Old files have no `id` key —
  on read, absent → generate a fresh one at load time (never persisted-then-missing, since old
  readers never look for it and old writers never wrote it).
- **Files**: `lib/src/bridge/models_mapping.dart`
- **Dependencies**: Task 1.1
- **Verification**: Round-trip test — save, reload, `id` unchanged; open a real v2012/v2.8 sample
  (`dataset_backward_compat_test.dart`'s existing fixtures), confirm it still opens with no error
  and every layer gets *some* id.
- **Complexity**: Low

### Phase 2: `scrollType` and `preferredOrientation`

Both already have complete, real (if disabled) UI in `dialogs.dart:39-114` — this phase is purely
about wiring existing UI to a new data field, per `04-visual.md` Screen 1's "Design implication for
Plan," plus the one real UI gap (`preferredOrientation`'s third "Auto" tile doesn't exist yet).

#### Task 2.1: Add `ComicsDoc.scrollType` and `ComicsDoc.preferredOrientation`
- **Description**: Add `enum ScrollType { vertical, horizontal }` (default `vertical`) and
  `enum PreferredOrientation { portrait, landscape, auto }` (default `portrait`) per
  `03-specifications.md`'s Interfaces block. Add both as fields on `ComicsDoc` (`models.dart:190`),
  included in `clone()` (`:211`).
- **Files**: `lib/src/ui/models.dart`
- **Dependencies**: None (independent of Phase 1)
- **Verification**: New `ComicsDoc()` defaults to `vertical`/`portrait`; `clone()` preserves both.
- **Complexity**: Low

#### Task 2.2: Persist both fields in JSON (additive)
- **Description**: Add `scrollType`/`preferredOrientation` string keys to `comicsToCore`
  (`models_mapping.dart:262`) and read them back in `comicsFromCore` (`:149`), absent → the enum
  defaults from 2.1.
- **Files**: `lib/src/bridge/models_mapping.dart`
- **Dependencies**: Task 2.1
- **Verification**: Round-trip test for both fields, all value combinations; confirm every existing
  real sample file still opens with the correct implicit defaults (vertical/portrait).
- **Complexity**: Low

#### Task 2.3: Wire the New Document dialog's existing tiles to real state
- **Description**: `dialogs.dart:39-61`'s `_TypeCard`s — enable the "Horizontal-scroll comic strip"
  card (`selected`/`enabled`/`onTap`, currently hardcoded `false`/`false`/no-op per
  `04-visual.md` Screen 1), have it set a new `ScrollType` local alongside `choice`
  (`dialogs.dart:17`), and write it into the created `ComicsDoc` at `newDoc()`
  (`controller.dart:539`). Enable the Portrait tile's `onTap` (`dialogs.dart:92-100`, currently
  permanently `selected: true` with nothing to toggle) to actually flip a local
  `PreferredOrientation` value.
- **Files**: `lib/src/ui/widgets/dialogs.dart`, `lib/src/ui/controller.dart`
- **Dependencies**: Tasks 2.1, 2.2
- **Verification**: Manual — create a doc with each scrollType/orientation combination, confirm the
  saved file's JSON matches the selected tiles.
- **Complexity**: Medium

#### Task 2.4: Add the missing third "Auto" tile for `preferredOrientation`
- **Description**: `dialogs.dart:92-114`'s DEVICE ORIENTATION section currently draws exactly two
  `_OptionTile`s (Portrait, Landscape) — `04-visual.md` Screen 1 flags this as a real gap, not just
  a wiring gap: a third tile needs to be added to the row, not merely enabled. Decide layout (3
  tiles fit the same row width as before, or wrap) during implementation.
- **Files**: `lib/src/ui/widgets/dialogs.dart`
- **Dependencies**: Task 2.3
- **Verification**: All three tiles visible, mutually exclusive selection, "Auto" reachable and
  persists as `PreferredOrientation.auto`.
- **Complexity**: Medium

### Phase 3: `Layer.ParentId` and organizational layers

#### Task 3.1: Add `EditorLayer.parentId` and the organizational `Kind`
- **Description**: Add nullable `String? parentId` to `EditorLayer`, referencing another layer's
  `id` (Task 1.1). Resolve the open "exact organizational `Kind` string" question — use
  `"organizational"` (matches this flow's own documents and `04-visual.md`'s proposed `KindChip`
  entry; no reason to diverge at implementation time). Resolve the open orphan-policy question per
  `03-specifications.md`'s stated leaning: on parent deletion, clear `parentId`, keep the child's
  last-resolved absolute position (no re-computation, no cascade delete).
- **Files**: `lib/src/ui/models.dart`
- **Dependencies**: Task 1.1
- **Verification**: Unit tests — setting/clearing `parentId`; deleting a parent leaves children's
  `translate` unchanged and `parentId` cleared; cycle prevention (a layer cannot become its own
  ancestor) rejected at the setter/controller level, not silently accepted.
- **Complexity**: Medium

#### Task 3.2: Persist `parentId` and organizational `Kind` in JSON (additive)
- **Description**: Same pattern as Task 1.2/2.2.
- **Files**: `lib/src/bridge/models_mapping.dart`
- **Dependencies**: Task 3.1, Task 1.2 (needs `id` round-tripping first so `parentId` references
  resolve)
- **Verification**: Round-trip test with a 3-level parent chain (mirrors `THE BROKEN TUSK`'s real
  голова → руки сложен → предплечье structure).
- **Complexity**: Low

#### Task 3.3: Layers panel — hierarchical display and "Set parent..." interaction
- **Description**: Build `04-visual.md` Screen 3's indented hierarchy in `_LayersSection`/
  `_LayerRow` (`scene_panel.dart:106-220`), plus the right-click/long-press "Set parent..."/"Clear
  parent" context menu (cycle-excluding picker). **Before writing this**, resolve the open
  `ParentId`-vs-`GroupId` relationship question (flagged in every document so far) — recommend
  deciding definitively here rather than shipping two parallel, potentially-conflicting hierarchy UIs:
  either (a) `GroupId` stays for flat precomp-import grouping only and `ParentId` drives real
  indentation, both visible but for different purposes (Screen 3's current framing), or (b) merge
  by treating a `GroupId` group as a synthetic organizational-layer parent. Pick (a) unless
  implementation reveals the two UIs visually clash in the same panel — (a) requires no changes to
  the already-approved `GroupId` mockups in the sibling flow, (b) does.
- **Files**: `lib/src/ui/widgets/scene_panel.dart`, `lib/src/ui/controller.dart` (cycle-checking
  logic)
- **Dependencies**: Tasks 3.1, 3.2
- **Verification**: Manual — build a 3-level hierarchy, confirm indentation, confirm cycle attempts
  are rejected with a clear message, confirm collapse/expand works per member.
- **Complexity**: High

#### Task 3.4: Canvas — dragging a parent moves children live
- **Description**: Per `03-specifications.md`'s Behavior Specification and `04-visual.md` Screen
  3's Canvas behavior note — extend the existing drag-end logic (same mechanism `GroupId`'s
  move-as-rigid-unit already uses, per the sibling flow's `02-visual.md`) to also apply to
  `parentId` chains.
- **Files**: `lib/src/ui/widgets/canvas_view.dart`, `lib/src/ui/controller.dart`
- **Dependencies**: Task 3.3
- **Verification**: Manual — drag "голова," confirm "руки сложен" and "предплечье" move with it by
  the same `(dx,dy)`.
- **Complexity**: Medium

#### Task 3.5: `[+]` add-layer menu split
- **Description**: `scene_panel.dart:115`'s single-action `[+]` (`onTap: c.addLayer`) becomes a
  small menu: "Image layer" (today's existing `addLayer` behavior, unchanged) vs. "Organizational
  anchor" (creates a layer with `Kind: "organizational"`, no `Images[]` content, per `04-visual.md`
  Screen 2).
- **Files**: `lib/src/ui/widgets/scene_panel.dart`, `lib/src/ui/controller.dart`
- **Dependencies**: Task 3.1
- **Verification**: Manual — each menu entry creates the right layer shape; organizational layers
  render as the dashed-border placeholder row, not a broken/missing thumbnail.
- **Complexity**: Low

### Phase 4: `Layer.Mask` / `Layer.SolidColor`

#### Task 4.1: Add `EditorLayer.solidColor` and `EditorLayer.mask`
- **Description**: Add nullable `String? solidColor` (hex, mirrors Bodymovin's `sc`) and a `LayerMask?
  mask` (small class: `shape` enum `rect|polygon|bitmap`, plus shape-specific fields — start with
  `rect` only, since all 6 real masks found are rectangles; `polygon`/`bitmap` fields can be added
  additively later without a migration). Resolve the open `solidColor`/`Images[]` precedence
  question: `solidColor`, when set, takes precedence and `Images[]` is ignored for rendering (never
  cleared — so switching back from solid-to-image loses nothing) — mirrors how `kind`/`style`
  already coexist with unused fields today.
- **Files**: `lib/src/ui/models.dart`
- **Dependencies**: None (independent of Phases 1-3)
- **Verification**: Unit test — layer with both `solidColor` and populated `Images[]` renders as
  the solid color; clearing `solidColor` reveals the untouched `Images[]` content.
- **Complexity**: Low

#### Task 4.2: Persist `solidColor`/`mask` in JSON (additive)
- **Files**: `lib/src/bridge/models_mapping.dart`
- **Dependencies**: Task 4.1
- **Verification**: Round-trip test; confirm `THE BROKEN TUSK`'s real solid layer
  (`sc:"#ffffff", sw:720, sh:27326`) imports and re-exports with the same color once
  `tdd-dot-bodymovin-import-export` consumes this field (cross-flow dependency, not blocking this task
  itself).
- **Complexity**: Low

#### Task 4.3: Solid-color layer creation + Properties panel MASK section
- **Description**: `04-visual.md` Screen 4 — add "Solid color layer" as the `[+]` menu's third entry
  (extends Task 3.5's menu), opens a standard color picker. Add the Properties panel's MASK section
  (None/Rectangle/Polygon/Bitmap radio), reusing `canvas_view.dart`'s existing `_WithHandles`
  component for the rectangle-mask drag/resize overlay rather than building a new one.
- **Files**: `lib/src/ui/widgets/scene_panel.dart`, `lib/src/ui/widgets/properties_panel.dart`,
  `lib/src/ui/widgets/canvas_view.dart`
- **Dependencies**: Tasks 4.1, 4.2, 3.5
- **Verification**: Manual — create a solid layer, confirm swatch row rendering per Screen 4; add a
  rectangle mask to an existing layer, confirm the canvas overlay matches selection-handle behavior.
- **Complexity**: Medium

### Phase 5: `Anim.basis` (scroll vs. time)

This phase has the most open sub-questions (field shape, time units, start/loop semantics,
composition rule) — deliberately sequenced last so Phases 1-4 (all fully decided) aren't blocked
waiting on them.

#### Task 5.1: Resolve remaining `Anim.basis` open questions
- **Description**: Before writing code, settle: (a) field shape — a per-`Anim` nullable enum
  `AnimBasis { scroll, time }` (default `scroll`, matching `04-visual.md` Screen 5's radio control
  exactly) rather than a per-layer or per-document flag, since the leg-swing motivating case needs
  *some* anims on a layer to stay scroll-driven while others (or the same anim across a
  loop) are time-driven; (b) time units — milliseconds (matches Flutter's own `Duration` API more
  directly than frames, avoids needing a separate frame-rate constant); (c) loop semantics for a
  time-based anim once `start`/`end` (now ms) are reached — loop by default (a swinging leg that
  stops after one swing isn't the motivating case), single-shot as an explicit opt-in field, not
  yet named — pick `loop: bool = true` at implementation time (d) composition rule — scroll and
  time dimensions never combine on the same `Anim` (an `Anim` is one or the other, not blended);
  cross-dimension composition only happens at the `EditorLayer` level (some anims scroll-driven,
  others time-driven, applied independently and summed like today's existing multi-anim transform
  composition already works). (e) which reader implements it first — `apps/comics-editor` (the
  editor itself, needed to author it) before any mobile viewer.
- **Files**: None (design-only task; document the resolution in this file or a short addendum)
- **Dependencies**: None
- **Verification**: N/A — decision task. Update `03-specifications.md`'s Open Design Questions to
  check these off once resolved, so the design record stays accurate.
- **Complexity**: Low (decision effort, not code)

#### Task 5.2: Add `Anim.basis`, `Anim.loop`
- **Description**: Per Task 5.1's resolution. Add fields to `Anim` (`models.dart:62`), included in
  `clone()` (`:85`). Existing `start`/`end` stay frame/scroll-pixel semantics when `basis == scroll`
  (zero behavior change); reinterpreted as milliseconds only when `basis == time`.
- **Files**: `lib/src/ui/models.dart`
- **Dependencies**: Task 5.1
- **Verification**: Unit test — default `Anim` has `basis == scroll`, unchanged behavior; explicit
  `time` basis anim round-trips through `clone()` correctly.
- **Complexity**: Low

#### Task 5.3: Persist `Anim.basis`/`loop` in JSON (additive)
- **Files**: `lib/src/bridge/models_mapping.dart` (`_animFromJson:65`, `_animToJson:80`)
- **Dependencies**: Task 5.2
- **Verification**: Round-trip test; confirm every real existing sample (all historically
  scroll-only) round-trips with `basis` absent → defaults to `scroll`, output JSON unchanged
  byte-for-byte from before this change (no spurious new keys written for the default case, unless
  the team prefers always-explicit — decide during 5.1/5.2, note the choice in code comments only
  if non-obvious).
- **Complexity**: Low

#### Task 5.4: New time-driven evaluation path in the interpolator
- **Description**: `keyframe_interpolator.dart` currently only evaluates anims against scroll
  position. Add a second, time-driven evaluation path (wall-clock elapsed time, honoring `loop`),
  composed independently alongside the existing scroll-driven path per Task 5.1(d)'s rule.
- **Files**: `lib/src/ui/anim/keyframe_interpolator.dart`
- **Dependencies**: Task 5.2
- **Verification**: New test — a layer with one scroll-driven Translate and one time-driven Alpha:
  scrolling changes position but not opacity-over-time; time passing (simulated clock) changes
  opacity independent of scroll position.
- **Complexity**: High

#### Task 5.5: Properties panel — "Driven by" control per Anim
- **Description**: `04-visual.md` Screen 5 — extend each `_AddChip`-created Anim editor
  (`properties_panel.dart:513-536`) with the Scroll/Time radio and unit-appropriate Start/End
  labels.
- **Files**: `lib/src/ui/widgets/properties_panel.dart`
- **Dependencies**: Tasks 5.2, 5.4
- **Verification**: Manual — toggle basis on an existing anim, confirm label changes, confirm
  canvas preview reflects the new evaluation path from Task 5.4.
- **Complexity**: Medium

## Dependency Graph

```
Phase 1 (Layer.Id) ─────────────┬──────────────→ Phase 3 (ParentId, 3.1-3.5)
                                 │
Phase 2 (scrollType/orient) ────┼── independent, no dependency on Phase 1
                                 │
Phase 4 (Mask/SolidColor) ──────┼── independent, no dependency on Phase 1
                                 │
Phase 5 (Anim.basis) ───────────┴── independent, no dependency on Phase 1
                                    (5.1 design task blocks 5.2 → 5.3 → 5.4 → 5.5 internally)
```

Phases 2, 4, and 5 have no dependency on each other or on Phase 1 — they can proceed in parallel if
more than one implementer is available. Phase 3 is the only phase gated on Phase 1.

## File Change Summary

| File | Action | Reason |
|------|--------|--------|
| `lib/src/ui/models.dart` | Modify (additive) | `EditorLayer.id`/`parentId`/`solidColor`/`mask`; `ComicsDoc.scrollType`/`preferredOrientation`; `Anim.basis`/`loop` |
| `lib/src/bridge/models_mapping.dart` | Modify (additive) | JSON round-trip for every field above |
| `lib/src/ui/controller.dart` | Modify (additive) | `newDoc()` writes new dialog selections; cycle-checking for `parentId`; `[+]` menu split |
| `lib/src/ui/widgets/dialogs.dart` | Modify | Wire existing tiles to state; add third "Auto" orientation tile |
| `lib/src/ui/widgets/scene_panel.dart` | Modify | Hierarchical layer display, organizational-layer row, `KindChip` entry, `[+]` menu |
| `lib/src/ui/widgets/properties_panel.dart` | Modify | MASK section; "Driven by" control |
| `lib/src/ui/widgets/canvas_view.dart` | Modify | Parent-drag-moves-children; reuse `_WithHandles` for rectangle mask |
| `lib/src/ui/anim/keyframe_interpolator.dart` | Modify (new code path) | Time-driven evaluation alongside existing scroll-driven path |
| `pubspec.yaml` | Modify | Add `uuid` dependency if not already present |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| `ParentId`/`GroupId` relationship (Task 3.3) turns out to need real UI merging, not just coexistence | Medium | Medium | Decided to try coexistence (option a) first; sibling flow's approved `GroupId` mockups stay untouched either way |
| Time-basis unit/loop decisions (Task 5.1) get revisited after real content is authored, requiring a schema tweak | Medium | Low | All new fields are additive/nullable by construction — a second additive tweak costs nothing extra for old readers |
| `keyframe_interpolator.dart`'s new time-driven path (Task 5.4) interacts badly with undo/redo snapshotting (`ComicsDoc.clone()`) | Low | Medium | `Anim.clone()` already covers new fields via Task 5.2's plan; add an explicit undo/redo test for a time-driven anim |
| Cycle prevention in `parentId` (Task 3.1/3.3) has an edge case missed (e.g. self-parenting via an intermediate rename) | Low | Medium | Cover with a dedicated unit test enumerating: direct self-parent, 2-hop cycle, 3-hop cycle (matches `THE BROKEN TUSK`'s real depth) |

## Rollback Strategy

Every field is additive and independently reversible — if any phase needs reverting:

1. Revert that phase's `models.dart`/`models_mapping.dart` changes; since old readers already
   ignore unknown keys, no data migration is needed even for files already saved with the new
   field.
2. Revert the corresponding UI changes.
3. No cross-phase rollback dependency exists except Phase 3 on Phase 1 (reverting Phase 1 requires
   reverting Phase 3 first).

## Checkpoints

After each phase, verify:

- [ ] All existing tests pass, including `dataset_backward_compat_test.dart` against every real
      v2012/v2.8/v2026 sample file
- [ ] No new warnings/errors
- [ ] Behavior matches `03-specifications.md`; UI matches `04-visual.md`
- [ ] Every new field round-trips through JSON and through `clone()` (undo/redo)

## Implementation Notes & Corrections (disclosed, not silent deviations)

Found while actually writing the code — each is a real correction to this plan's own text, kept
here rather than silently reflected only in the diff:

- **Task 1.1's `clone()` design was backwards.** The plan said `clone()` should generate a *new*
  id ("a distinct layer, not the same identity"). Grounding this against the real call sites
  (`edit_history.dart`, `controller.dart:290/305/317`) found `EditorLayer.clone()` is only ever
  used by `ComicsDoc.clone()` for undo/redo snapshots — never a "duplicate layer" feature. A
  snapshot must represent the *same* document, so `clone()` **preserves** `id`, it does not
  generate a new one. Caught before Task 3.1 (`parentId`) could build on the wrong assumption —
  had it shipped as originally planned, every undo/redo would have silently reassigned every
  layer's id and broken any `parentId` reference. Fixed in `models.dart`, test corrected in
  `test/models_test.dart`.
- **Task 3.1's proposed `KindChip` color, `Hs.gray300`, doesn't exist** in the real theme
  (`theme.dart` only defines 50/100/150/200/400/500/600/700/800) — used the real `Hs.gray600`
  instead, still visually distinct from the `Art` fallback's `gray500`.
- **Task 4.3's/Screen 4's "dashed border"** for the organizational-layer placeholder isn't
  buildable with stock Flutter `Border` (only `none`/`solid` styles exist, dashed needs a custom
  painter) — used a solid muted border instead; same "not real artwork" signal, no new painter
  written for one placeholder.
- **`04-visual.md` Screen 2's "editable label"** for organizational layers was not built as
  originally sketched — no layer in this app has a rename UI today (verified: zero `TextField`/
  rename affordance anywhere in `scene_panel.dart`), so adding one only for organizational layers
  would be a scope increase disproportionate to this task. The name is set once at creation
  (`anchor_N`) and displayed as plain text, identical to every other layer today. Flagged here as a
  deliberate narrowing, not an oversight — revisit if Anton wants real layer renaming as its own
  feature.
- **Task 3.4's "same mechanism `GroupId` already uses"** turned out not to exist in real code —
  `GroupId` is still an unimplemented sibling-flow design (`vdd-comics-editor-systematization-
  uiux`), not shipped. Implemented independently instead: `EditorController.dragSelected` recurses
  over `parentId` children (and their own descendants) applying the same delta, with no `GroupId`
  mechanism to share.
- **Task 2.3 under-scoped which orientation tile(s) to enable.** Its own text said only "enable the
  Portrait tile's `onTap`," but a permanently-disabled Landscape tile would leave the user unable to
  ever actually select landscape — inconsistent with `04-visual.md`'s own "same three steps as
  `scrollType`" framing (which enables *both* Vertical and Horizontal cards, not just one).
  Implemented as: both Portrait and Landscape become real, mutually-exclusive tap targets in Task
  2.3, with Auto added alongside in Task 2.4 — 3 live tiles, not "1 enabled + 1 added."
- **A pre-existing test encoded the old disabled-tiles state as intentional documentation**
  (`test/bottombar_viewer_properties_test.dart`, `'new document defaults and future options stay
  explicit'` — asserted 2 lock icons and a no-op tap on the Horizontal-scroll card). Updated rather
  than deleted, since this phase's entire point was changing that exact behavior; renamed to `'new
  document dialog options are real and wired to the created doc'` and re-pointed at the new,
  intended assertions (0 lock icons, `doc.scrollType`/`doc.preferredOrientation` reflect the tiles
  tapped).
- The Horizontal-scroll `_TypeCard`'s subtitle was rewritten from "Planned for a future version." to
  disclose the real scope of this phase: it sets `ComicsDoc.scrollType` for real, but canvas/viewer
  playback direction itself is unchanged (still vertical-only) — the same "signals intent, no full
  engine commitment" framing `04-visual.md` Screen 1 already established, made explicit in the UI
  copy itself rather than only in this document.
- **Task 4.3's "a standard color picker, no new component needed" assumed one exists** — checked
  `pubspec.yaml`/`pubspec.lock`: no color-picker package is present. Adding a new dependency for one
  dialog is a bigger call than this task warrants, so a small in-house preset-swatch-grid + hex-field
  dialog was built instead (`showSolidColorPicker` in `dialogs.dart`) — complete and real, not a
  half-built "hex only" fallback.
- **Task 4.3's MASK section shows Polygon/Bitmap as locked options**, not hidden — consistent with
  the disabled-tile precedent from Phase 2 (Horizontal-scroll/Landscape before they were wired), since
  no point-editor or file-picker exists for those two shapes yet and building one wasn't in scope.
- **Task 4.3's canvas rectangle-mask editing was narrowed from "reuse `_WithHandles` for drag-resize"
  to numeric Properties-panel fields only.** Investigating `_WithHandles` found it's a purely visual
  decoration (8 static resize-dot corners + rotate stem) with zero drag logic of its own — the actual
  drag math lives in `canvas_view.dart`'s `GestureDetector.onPanUpdate` for the *whole layer's*
  transform, not a sub-rectangle within it. Building real 8-handle drag-resize for an independent
  mask rect is a separate, nontrivial gesture-handling feature; four `NumericPropertyControl` fields
  (X/Y/W/H) give a complete, fully-working way to author a rect mask without it — canvas drag-to-resize
  is a disclosed, real gap for a future task, not a silently half-built feature.
- **Two pre-existing widget tests broke, not from a behavior regression but from the new MASK
  section's own `DropdownButton<String?>`** making `find.byType(DropdownButton<String?>)`
  ambiguous (`kind_field_test.dart`, `properties_panel_balloon_test.dart` both tapped "the"
  dropdown assuming there was only one). Fixed by targeting `.first` (KIND renders before MASK in
  `_LayerEditor`'s list) rather than by avoiding the MASK section's design.
- **Task 5.4's composition rule needed a real refinement, not just a literal reading of "summed."**
  Task 5.1(d)'s own text said scroll/time contributions are "applied independently and summed" —
  but scale/alpha are inherently multiplicative quantities (a scale factor of 0 would zero out the
  layer; summing two alphas can exceed 1). Implemented as: translate/rotate.angle *sum* (additive
  quantities), scale/alpha *multiply* (multiplicative quantities) — both choices make "zero
  time-basis anims of this type" the operation's identity element (0 for sum, 1 for product), which
  is *why* every document with none is byte-identical to before this feature, not a coincidence.
  Pivot (never eased in either dimension) has no natural sum/product; ties break toward whichever
  dimension has an active `curr` segment, preferring scroll — a disclosed, not-otherwise-specified
  choice, not a finding from real data (no real content has ever used two simultaneous pivots).
- **A live-ticking wall-clock source was attempted for Task 5.4 and reverted.** Wiring
  `EditorController` with a periodic `Timer` (so a time-basis anim would visibly animate in the
  running app without user interaction) violated `flutter_test`'s strict no-pending-timer-after-
  dispose invariant and broke ~78 unrelated tests across the suite. Reverted; `KeyframeInterpolator`
  correctly accepts and composes an explicit `wallClockMs` parameter (tested via injected/simulated
  values, matching Task 5.4's own verification bar exactly), but nothing in this codebase currently
  passes it a real, ticking value — a time-basis anim is real and correct but renders "frozen" at
  `wallClockMs=0` in the actual app today. Wiring a live, lifecycle-safe clock (e.g. a widget-scoped
  `AnimationController` with real vsync, started only by whichever widget renders a layer that
  actually has a time-basis anim) is a genuine, disclosed follow-up, not a silently dropped feature.
- **Task 5.5's initial `_DrivenByOption` row overflowed** in the narrower Properties-panel layout
  used by the iPad-landscape lettering-tablet view (`lettering_tablet_test.dart`, caught by 2 real
  `RenderFlex overflowed` errors, not by golden-image diffing) — the label `Text` had no `Expanded`
  wrapper. Fixed by wrapping it in `Expanded`+`TextOverflow.ellipsis`, same pattern already used
  throughout the rest of this codebase's rows.
- **Task 5.5's time-basis Start/End field bounds (0-60000ms) were invented**, not derived from any
  real content or specification -- `03-specifications.md` left the exact time unit/range genuinely
  open. 60 seconds was picked as a reasonable authoring ceiling for a UI numeric field, not a hard
  format limit (the underlying `int` field has no such constraint) -- flagged here since it's a
  concrete number nobody asked for specifically.

## Open Implementation Questions

- [ ] Task 3.3's `ParentId`/`GroupId` coexistence decision — recommended (option a) here, but not
      yet Anton-confirmed; flag for explicit sign-off before starting Phase 3's UI work.
- [ ] Task 5.1's five sub-decisions (field shape, units, loop semantics, composition rule, reader
      order) — recommendations given here, not yet Anton-confirmed; flag before starting Phase 5.
- [ ] Whether Phases 2/4/5 actually get parallelized across multiple implementers or run
      sequentially — a staffing decision, not a technical one.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-07
- [x] Notes: Approved as drafted. The two flagged Open Implementation Questions (Task 3.3's
      `ParentId`/`GroupId` coexistence choice, Task 5.1's five `Anim.basis` sub-decisions) were not
      separately re-confirmed — their stated recommendations stand as the working assumption for
      Implementation unless revisited.
