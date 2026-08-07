# Status: tdd-dot-comics-format

## Current Phase

TESTS

## Phase Status

DRAFTED, AWAITING APPROVAL — promoted 2026-08-02 from the parked `sdd-comics-editor-fromat-dot-
comics` reference consolidation into a real, active TDD flow, per Anton's explicit request.
`02-tests.md` v1.0 drafted: existing-test catalog (Part 1), background facts from a full flow sweep
(Part 2), a v2026 multi-platform viewer compatibility matrix (Part 3), three confirmed bugs (Part 4),
and cases-first behavioral analysis across 6 categories (Part 5).

## Last Updated

2026-08-02 by Claude

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

## Progress

- [x] Requirements drafted (2026-08-01) — v0.1, consolidated verbatim from
      `vdd-comics-editor-timeline` and `sdd-comics-ai-positioning`
- [x] Requirements revised (2026-08-02) — v0.2, promoted to TDD scope, both prior Open Questions
      resolved (unit-mismatch risk closed by a sibling flow; flow sweep now done)
- [ ] Requirements approved
- [x] Tests drafted (2026-08-02) — v1.0, see `02-tests.md`
- [ ] Tests approved
- [ ] Specifications drafted
- [ ] Plan drafted
- [ ] Implementation started

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
