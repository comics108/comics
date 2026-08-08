# Status: tdd-dot-comics-format

## Current Phase

IMPLEMENTATION COMPLETE

## Phase Status

Requirements, Tests, Specifications, Visual, and Plan are all APPROVED (2026-08-07). **All 5 plan
phases (20 tasks) are done and tested** — see `05-plan.md`'s "Implementation Notes & Corrections"
section for 16 disclosed corrections found while building. Most consequential:
- Task 1.1's `clone()` was originally specified to generate a new id, which would have silently
  broken every `parentId` reference on every undo/redo (fixed to preserve identity instead, caught
  before Phase 3 built on it).
- Task 2.3 under-scoped orientation-tile wiring to "just Portrait" (fixed to enable Portrait+
  Landscape together).
- Task 4.3's canvas rectangle-mask editing was narrowed from real 8-handle drag-resize
  (investigated `_WithHandles`, found it's purely decorative with no drag logic of its own to
  reuse) to numeric Properties-panel fields — complete and working, without the larger unscoped
  gesture feature.
- Task 5.4's "summed" composition rule was refined per-quantity (sum for translate/rotate.angle,
  multiply for scale/alpha, since scale/alpha are multiplicative) — both choices make "no
  time-basis anims" the operation's identity element, which is *why* every pre-existing document
  renders byte-identical to before this feature.
- Task 5.4's attempted live-ticking wall-clock `Timer` in `EditorController` broke ~78 unrelated
  tests (violated `flutter_test`'s no-pending-timer invariant) and was reverted. A time-basis anim
  is real, tested, and correctly composed via an explicit `wallClockMs` parameter, but nothing
  currently feeds it a real ticking value — it renders "frozen" at 0 in the running app today. A
  genuine, disclosed follow-up: wire a lifecycle-safe live clock (e.g. a widget-scoped
  `AnimationController` with real vsync).

Final state: 419 tests passing (up from 293 at the start of this flow's implementation), 2 golden
images regenerated for intentional layout changes, zero regressions to any pre-existing real
`.comics`/`.puzzle` sample file's backward compatibility.

**NEW addition (2026-08-08), Requirements/Specifications only, not yet implemented**: a third
independent document field, `preferredViewportWidth`/`preferredViewportHeight` (default 720×1600),
added alongside `scrollType`/`preferredOrientation` per Anton's direct instruction (naming chosen
by Claude, as delegated). Motivated by `flows/comics-editor/tdd-dot-lottie-import-export`'s
Playback Viewport export/import mode — `01-requirements.md` v0.9, `03-specifications.md` v0.6, both
approved same-session (narrow, directly-dictated addition, same treatment as the earlier masks/
scrollType/orientation decisions). **Scope of this addition was explicitly Requirements+
Specifications only** — no changes made to `apps/comics-editor`'s real `ComicsDoc`/`models_mapping
.dart` (unlike `scrollType`/`preferredOrientation`, which are already implemented per Phase 2
above) — this is a forward-looking schema decision awaiting its own Plan/Implementation pass,
same pattern this format has used for every prior addition before it was actually built.

**Second NEW addition (2026-08-08), also Requirements/Specifications only, not yet implemented**:
`Layer.ZDepth`, a new optional per-layer numeric field for a parallax effect, per Anton's explicit
instruction ("добавь в .comics v2026 в reqs и specs глубину z-depth для создания эффекта паралакс.
По дефолту 0 или если не указано то 0 для совместимости с v2012"). Default `0`, with absent-key and
explicit-`0` treated identically — matches every v2012-through-2026 file's current 1:1-with-scroll
behavior exactly. `01-requirements.md` v0.10, `03-specifications.md` v0.7, both approved same-session
(same narrow, directly-dictated treatment as every prior addition in this list). The exact parallax
math (sign convention, scroll-response formula, whether it's baked at save time like `ParentId` or
applied at render time, and whether it composes through `ParentId` chains) is explicitly left open,
carried to Plan — **command scope was explicitly Requirements+Specifications only**, no code changes
to `apps/comics-editor`.

## Last Updated

2026-08-08 by Claude (added `Layer.ZDepth` parallax-depth field to Requirements/Specifications)

## Correction (2026-08-07): the "MAJOR DISCOVERY" originally logged here was a different format, now split out

A comparison of `samples/sample_v2012.comics_unzip` vs. what was then `samples/
sample_v2026.comics_unzip` surfaced content that turned out to be genuine **Lottie/Bodymovin JSON**
(Adobe After Effects' animation export format), not an extension of this flow's classic
`Comics.Editor.Models` schema — the file was mislabeled as a `.comics` version. Anton confirmed
this and renamed the fixtures (`samples/sample.lottie`, `dataset/mahabharata/boranko/
mahabharata-dot-lottie`) so they stop implying it's a `.comics` version, and asked for the whole
investigation to move to its own flow: **`flows/tdd-dot-lottie-format/`**. Everything about Lottie's
schema, the vendored-but-unused Lottie engine found in `apps/mahabharata-mobile-swift-v2026`, and
the 7-of-43-produced episode comparison now lives there. Nothing else in this flow's own research
(Parts 1-3, `02-tests.md`) was affected — that was always scoped to the classic lineage only and
remains accurate.

**Re-verified after the split (2026-08-07), per Anton's explicit request**: `.comics` v2012 is
confirmed the legacy format used by the real v2012 apps (`legacy/mahabharata-mobile-java-v2012`,
`legacy/mahabharata-mobile-swift-v2012}` — this was already established in the original 2026-08-02
research, Discoveries 1-2 below), and the current v2026 `.comics`-consuming stack
(`apps/comics-editor`, `apps/mahabharata-mobile-java-v2026` via `libs/comics_viewer/
comics-viewer-android`) remains backward compatible with it — confirmed by `diff -rq` showing the
model files byte-identical since 2012/v2.8 (only the additive `Kind`/`Style`/`Translations` fields
differ), and by `apps/comics-editor/test/dataset_backward_compat_test.dart` actually opening every
real classic-format file without error. This conclusion was never in doubt — the Lottie confusion
was a separate, unrelated file being briefly misread as if it were part of this same lineage.

## Blockers

- Waiting on Anton's direction on `02-tests.md`'s remaining Open Design Questions — most
  consequentially whether to fix the newly-found `scaleX`/`scaleY`/`alpha` JSON-default bug
  (B1/E1/E2) now or later, and whether this flow should proceed to a formal Specifications/Plan/
  Implementation phase (writing the actual new test files) or stop at cataloging + cases-first
  analysis.
- **Pending schema addition, not yet reflected in `02-tests.md`'s format facts**: a new
  `Layer.GroupId` field (purely organizational, zero rendering effect, backward-compatible with
  v2012 by construction) has been decided in
  `flows/comics-editor/vdd-comics-editor-systematization-uiux/01-requirements.md` (Layer Grouping
  section, 2026-08-07), motivated by `flows/comics-editor/tdd-dot-lottie-import-export`'s precomp-
  handling question. Once that design is approved/implemented, this flow's own consolidated format
  facts should get a new entry for it — not done yet, flagged here so it isn't lost.
- **Second pending schema addition (2026-08-07)**: a new `Layer.TextRegion` field (`shape:
  "rect"|"polygon"|"mask"`, not gated by `Kind=="balloon"` — applies to any layer, per Anton's
  explicit "text isn't only inside a balloon" clarification), decided in the same
  `tdd-dot-lottie-import-export/01-requirements.md` while resolving that flow's unsupported-
  content-policy question. Grounded in a real, confirmed gap in `comics-ai-baloons` (computes
  precise masks twice, discards both, never persists any non-rectangular geometry). Also not yet
  reflected in this flow's own format facts.
- **Third schema addition, this time directly in this flow (2026-08-07)**: scroll position and
  time become **two independent animation-driving dimensions** in v2026. `.comics` v2012
  animations were, and remain, always scroll-position-based (historical fact, unchanged). v2026
  animations are scroll-position-based **by default** (absent time-basis → today's exact behavior,
  full backward compat), but **may additionally be time-based if explicitly specified** — directly
  targets the "leg-swing" gap `vdd-comics-editor-timeline`/`vdd-comics-editor-vertical-scroll` both
  found and left unresolved (nothing lets a character keep animating, e.g. a swinging leg, while
  scroll is stationary). Added to `02-tests.md` as Test Case D4 + a Part 2 background-fact
  correction. Core decision settled; 5 real implementation-detail sub-questions remain open (exact
  field shape, time units, start/loop semantics, cross-dimension composition rule, which reader
  implements it first) — see `02-tests.md`'s Open Design Questions.
- **Escalated to `01-requirements.md`/`03-specifications.md` (2026-08-07)**: per Anton's explicit
  request, both this time-dimension decision AND a full animation-type inventory now live in the
  main Requirements/Specifications docs, not only Tests. The inventory work surfaced a **major,
  real correction**: direct inspection of all 7 real produced Lottie chapters (not just the one
  `ASHES.json` sample earlier research used) found masks (1/7), null layers (1/7), solid layers
  (1/7), and — most consequentially — **layer parenting in 5/7 files, up to 64% of layers in one
  chapter (`THE BROKEN TUSK`)**. This negatively resolves `tdd-dot-lottie-format`'s L6/L7 open
  question (does `ASHES.json`'s simple structure generalize? — **no**) and means
  `tdd-dot-lottie-import-export`'s Precomp Handling design needs to generalize from
  "precomp-children only" to "arbitrary parent chains" — flagged back to both flows.
- **Fourth schema addition (2026-08-07, per Anton's explicit follow-up — "мы же говорили про
  organizational layers и layer parenting, сохрани их в reqs и specs")**: `.comics` v2026 gains a
  real `Layer.ParentId` mechanism (hierarchical, editor-side live-relative positioning) plus a new
  `Layer.Id` (stable identity, a real prerequisite this surfaces) and a new organizational/
  non-content `Kind` value (Lottie `ty:3` null-layer equivalent). Backward compat via the same
  "always persist fully-resolved absolute `Anim` values" pattern as `GroupId` — old readers never
  need to understand `ParentId` to render correctly. This **supersedes** the earlier "just bake and
  discard the parent chain" recommendation for `tdd-dot-lottie-import-export` with a real,
  persisted mapping target. Full design in `03-specifications.md`'s new "`Layer.ParentId` &
  Organizational Layers" section. Genuinely open: `Layer.Id` generation scheme, the exact
  organizational `Kind` string, orphan policy on parent deletion, and whether `ParentId` subsumes
  or coexists with `GroupId`.
- **Fifth addition — DECIDED (2026-08-07, Anton asked directly: "могут ли masks и solid colors
  быть типами kind?", then confirmed "используем твою рекомендацию")**: answered **no** —
  `Layer.SolidColor` (hex string, mirrors Lottie's `sc`) and `Layer.Mask` (rect/polygon/mask, a
  general compositing clip, deliberately separate from the lettering-scoped `TextRegion`) are two
  new additive fields, NOT `Kind` values, since role (`Kind`) and content-source/compositing are
  orthogonal — a solid-color layer can still *be* a background; cramming that into one `Kind`
  string would lose one fact or the other. Real evidence found while checking exact field shapes:
  `THE BROKEN TUSK`'s real solid layer is `sc:"#ffffff", sw:720, sh:27326` (a full-height white
  backdrop); all 6 real masks in `THE CHASE` are static 4-vertex rectangles (`mode:"a"`, no curve
  handles) — meaning `shape:"rect"` alone already covers every real mask found. Full design in
  `03-specifications.md`'s "Masks & Solid Colors" section, now confirmed, not a recommendation.
  One remaining detail still open: `solidColor`/`Images[]` precedence if both are ever set.
- **Decided (2026-08-02), three related questions now closed**: (1) UI — New Document dialog gets a
  visible-but-disabled "century-old comic strip (horizontal infinity scroll)" option (Test Case B3).
  (2) Schema — yes, an explicit `scrollType` field (proposed name/values, not yet confirmed by
  Anton verbatim: `"vertical"`/`"horizontal"`; deliberately NOT named "orientation" — see next
  point), absent → defaults to `"vertical"` specifically for v2012-through-2026 backward
  compatibility (Test Case B4). (3) **`scrollType` (content) and device screen orientation
  (portrait/landscape) are independent parameters, never coupled or inferred from each other** (Test
  Case B5) — corrected from an earlier draft that sloppily reused "orientation" for both. Nothing
  here is implemented anywhere yet — all three are forward-looking schema/UI decisions, not claims
  that horizontal scrolling or landscape viewing work today.
- **Escalated to `01-requirements.md`/`03-specifications.md` (2026-08-07)**, per Anton's explicit
  request — this decision had only ever lived in `02-tests.md` (Test Cases B2-B5) until now. New
  dedicated sections added to both: `01-requirements.md`'s "`scrollType` vs. device orientation —
  two independent dimensions" (right after the vertical-strip-default section it directly extends)
  and `03-specifications.md`'s "`scrollType` vs. Device Orientation — Specification" (interfaces,
  schema, behavior, edge cases, testing strategy). No new facts — a faithful escalation of the
  already-decided content, not a re-derivation.
- **CORRECTION (2026-08-07, same day, Anton): device orientation is now ALSO a `.comics`-format
  field — reverses the "never in `data.json`" half of the escalation above.** New field
  `preferredOrientation` (proposed name), **three values** per Anton's follow-up —
  `"portrait" | "landscape" | "auto"` — default/backward-compat `"portrait"`. `scrollType` and
  `preferredOrientation` are now both real `.comics` fields, but remain independent — neither may
  be inferred from the other, same principle, just two content fields instead of one content field
  + one platform-only setting. **Real, disclosed correction to `01-requirements.md`/
  `03-specifications.md`'s just-written text**, not a silent overwrite — both docs now explain the
  "device orientation is platform-config-only" framing was superseded, not simply replaced without
  a trace. Also corrected `04-visual.md`'s Screen 1 note, which had explicitly (and reasonably, at
  the time) predicted the opposite conclusion.

## Progress

- [x] Requirements drafted (2026-08-01) — v0.1, consolidated verbatim from
      `vdd-comics-editor-timeline` and `sdd-comics-ai-positioning`
- [x] Requirements revised (2026-08-02) — v0.2, promoted to TDD scope, both prior Open Questions
      resolved (unit-mismatch risk closed by a sibling flow; flow sweep now done)
- [x] Requirements revised (2026-08-07) — v0.3, added the scroll-vs-time dimension decision + the
      full animation-type/Lottie-coverage inventory (with the real parenting/mask/null/solid finding)
- [x] Requirements revised (2026-08-07) — v0.6-0.8, masks/solid-colors decision, scrollType/
      preferredOrientation escalation + correction (device orientation now a real `.comics` field,
      3 values including "auto")
- [x] Requirements approved (2026-08-07) — by Anton Dodonov
- [x] Tests drafted (2026-08-02) — v1.0, see `02-tests.md` (Test D4 added 2026-08-07)
- [x] Tests approved (2026-08-07) — by Anton Dodonov (approval implicit in "specs и reqs approved,"
      since Specifications are derived from and cite these test cases directly)
- [x] Specifications drafted (2026-08-07) — v0.1-0.5, EARLY/PARTIAL: scoped to five schema/design
      items, not this flow's full Specifications phase
- [x] Specifications approved (2026-08-07) — by Anton Dodonov, v0.5, several Open Design Questions
      explicitly carried forward to Plan rather than blocking approval
- [x] Visual drafted (2026-08-07) — v1.0, `04-visual.md`, a one-off addition ahead of Plan per
      Anton's explicit request (TDD has no native Visual phase)
- [x] Visual approved (2026-08-07) — by Anton Dodonov, after confirming compatibility with
      `flows/comics-editor/vdd-comics-editor-systematization-uiux/02-visual.md`
- [x] Plan drafted (2026-08-07) — v1.0, see `05-plan.md`
- [x] Plan approved (2026-08-07) — by Anton Dodonov, recommendations on the two flagged Open
      Implementation Questions stand as working assumptions
- [x] Implementation started (2026-08-07) — Phase 1 (`Layer.Id`) done: `EditorLayer.id` (uuid v4,
      `models.dart`), JSON round-trip (`models_mapping.dart`), `uuid` promoted from transitive to
      direct `pubspec.yaml` dependency.
- [x] Phase 3 done (2026-08-07) — `EditorLayer.parentId` + `organizationalKind`, JSON round-trip,
      orphan policy on layer delete (`controller.dart:deleteSelected`), `[+]` menu split
      (`addOrganizationalLayer`), hierarchical Layers-panel rendering + collapse/expand
      (`hierarchicalLayerOrder`), cycle-safe "Set parent.../Clear parent" context menu
      (`wouldCreateParentCycle`/`setLayerParent`), canvas parent-drag-cascades-to-children
      (`dragSelected`). New test files: `test/models_test.dart`, `test/controller_parenting_test.dart`;
      extended `test/models_mapping_test.dart`, `test/controller_undo_redo_test.dart`. One golden
      image regenerated (`goldens/editor_desktop_1440x920.png`) for the intended layout shift (new
      20px collapse-triangle gutter). Full suite (386 tests) + backward-compat dataset re-run clean
      throughout.
- [x] Phase 2 done (2026-08-07) — `ComicsDoc.scrollType`/`preferredOrientation` enums+fields
      (`models.dart`), JSON round-trip (`models_mapping.dart`), New Document dialog fully wired
      (`dialogs.dart`): Vertical/Horizontal-scroll cards set `scrollType`, Portrait/Landscape/**new
      third "Auto" tile** set `preferredOrientation`, all real `_OptionTile`/`_TypeCard` taps now
      call `setState`+flow into `EditorController.newDoc`'s new optional params. One pre-existing
      test (`bottombar_viewer_properties_test.dart`) that documented the old disabled-tiles state
      updated to assert the new real behavior instead. Full suite (391 tests) clean.
- [x] Phase 4 done (2026-08-07) — `EditorLayer.solidColor`/`mask` (`LayerMask`, `models.dart`), JSON
      round-trip (`models_mapping.dart`), `[+]` menu's third entry "Solid color layer" with an
      in-house preset-swatch+hex color picker (`showSolidColorPicker`, `dialogs.dart` — no
      color-picker package exists in this project), solid-color swatch rendering in the layers list
      (`_SolidColorSwatch`), Properties panel MASK section (None/Rectangle live-editable via 4
      `NumericPropertyControl` fields; Polygon/Bitmap shown locked, matching the Phase 2
      disabled-tile precedent). Canvas drag-to-resize for the mask rect was investigated and
      explicitly deferred (see `05-plan.md`'s corrections) in favor of the numeric fields, a
      complete alternative rather than a half-built gesture handler. Fixed 2 pre-existing widget
      tests broken by dropdown-finder ambiguity (`kind_field_test.dart`,
      `properties_panel_balloon_test.dart`), regenerated 2 golden images for the new MASK section's
      layout. Full suite (404 tests) clean.
- [x] Phase 5 done (2026-08-07) — `Anim.basis`/`loop` (`models.dart`), JSON round-trip
      (`models_mapping.dart`, new keys not part of the legacy C# schema), `KeyframeInterpolator`
      rewritten to compose an independent time-basis contribution per type (sum for
      translate/rotate.angle, multiply for scale/alpha, both making "no time-basis anims" the
      operation's identity element -- zero behavior change for any pre-existing document), Properties
      panel "DRIVEN BY" radio (`_DrivenByField`) relabeling Start/End to ms when Time is selected,
      shown for every visual anim type except Sound. An attempted live-ticking wall-clock `Timer` in
      `EditorController` broke ~78 unrelated tests (flutter_test's no-pending-timer invariant) and
      was reverted -- a time-basis anim is real/correct/tested but renders frozen at wallClockMs=0
      in the running app until a lifecycle-safe live clock is wired in as a follow-up. Fixed a real
      `RenderFlex` overflow in the new control under the lettering-tablet's narrower layout. New test
      files: `test/properties_panel_anim_basis_test.dart`; extended `test/models_test.dart`,
      `test/models_mapping_test.dart`, `test/keyframe_interpolator_test.dart`. Full suite (419 tests)
      clean.
- [x] Implementation complete (2026-08-07) — all 5 phases, 20 tasks. 419 tests passing (up from 293
      before this flow's implementation began), 2 golden images regenerated for intentional layout
      changes, zero regressions to any pre-existing real `.comics`/`.puzzle` sample file.

## Context Notes

- **Purpose evolved**: started as a single authoritative reference for `.comics` format facts (SDD
  consolidation). Now a real TDD flow: catalog existing test coverage, then define compatibility
  test cases across legacy v2012 players, the v2.8/2026 editors, and 4 v2026 viewer implementations.
- **Research method**: 3 parallel background research agents (v2012 legacy codebases; a full sweep
  of every remaining SDD/VDD flow plus a repo-wide existing-test catalog; the 3 non-Android v2026
  viewers), plus direct first-principles verification of one finding.

## Research Discoveries (2026-08-02)

1. **The "maxlastscroll" premise was wrong on naming, right on substance.** No such term exists
   anywhere in 2012 code — what exists is an unrelated "resume last scroll position" bookmark
   feature. But the actual claim (2012 animation = scroll-only, no looping, no time-based) is
   correct: 2012 has the identical 5-type shape as v2.8, unchanged since.
2. **No orientation flag has ever existed in the format, at any generation** (2012 Java/Swift, v2.8,
   current). Every implementation is vertical-only by convention, never by schema enforcement — a
   hypothetical wide/short document has literally never been tested anywhere (see `02-tests.md`
   Category B2, a named open gap, not a resolved question).
3. **`comics-admin-v2012` is not an original/earlier editor** — it has zero Layer/Anim/Sound/Comics
   model classes; it's a CMS that stores comics as opaque uploaded archives and literally bundles a
   downloadable `ComicsEditor_2.8.zip` as its own "Editor" feature.
4. **A real, previously-undetected bug found via first-principles verification, contradicting an
   earlier flow's own code comment**: `models_mapping.dart`'s `scaleX`/`scaleY`/`alpha` JSON parsing
   defaults absent keys to `1`, but the real C# source has no `[DefaultValue]` attributes on those
   fields — an absent key truly means `0`. An earlier comment (`vdd-comics-editor-uiux-lettering`
   Task 7.1) argued the `1` default was correct because "deserialization leaves it at the object's
   `Init()`-assigned value" — verified this is false: `Init()` is only called by `FindNearest`'s
   synthetic-fallback path, never during normal deserialization. Same bug class as the `end`/200
   bug `vdd-comics-editor-vertical-scroll` already fixed, not yet fixed here. See `02-tests.md`
   Part 4 (B1) and Category E (E1/E2).
5. **Only `comics-viewer-ios` is a genuine second viewer implementation** — algorithmically identical
   to `comics-viewer-android` (same cubic ease-out, same keyframe walk), but has zero tests despite
   compiling standalone. `flutter_comics_viewer`/`react-native-comics-viewer` are thin bridges with
   no parsing logic of their own; RN additionally has 4 stubbed/non-functional JS accessors.
6. **Zero automated tests exist in any 2012 codebase, the C# editor, `comics-viewer-android`, or any
   of the 3 non-Android v2026 viewers.** Only `apps/comics-editor/test/` (Dart, ~260 cases) and the
   two Python AI pipelines (~200 cases combined) have real format-touching coverage.
7. **A real v2012-shaped sample exists** (`samples/sample_v2012.comics`, pointed to directly by
   Anton mid-session — none of the 3 research agents knew it existed). Inspected directly: confirms
   the no-orientation-flag finding, confirms `SoundAnim` never appears inside `Layer.animations`
   (177 real layers, only Translate/Rotate/Scale/Alpha), confirms the same Start=0-tied-anims pattern
   found in 2026 dataset files, and surfaces one new fact — a real `SoundAnim` with `start=-38`
   (negative), which every platform's plain-numeric-comparison gating logic handles fine with no
   special-casing needed. This turns Test Case A5 from "needs new tooling to get a sample" into
   "sample already exists, ready to use."

## Fork History

N/A — new flow, consolidated (not forked) from two existing flows' content per explicit user
request: "вынеси из vdd-comics-editor-timeline и sdd-comics-ai-positioning описание формата
.comics и добавь что по дефолту он vertical comic strip".

## Next Actions

1. Anton reviews `01-requirements.md` v0.1 for faithfulness to the two source flows.
2. Decide on the Open Question: extend this consolidation to the other flows known to hold real
   format facts (`sdd-comics-ai-multimodal`, `sdd-comics-ai-baloons`, `sdd-comics-editor-questions`),
   or leave this deliberately scoped to the two originally-named sources.
3. Consider adding back-references from the two source flows to this new consolidated doc (not yet
   done — mirrors the extraction pattern already used elsewhere this session, e.g.
   `sdd-comics-editor-questions` → `sdd-comics-ai-script-context`).
