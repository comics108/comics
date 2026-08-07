# Status: tdd-dot-lottie-format

## Current Phase

TESTS

## Phase Status

DRAFTED, AWAITING APPROVAL — forked out of `tdd-dot-comics-format/02-tests.md`'s "Part 0" discovery
(2026-08-07), after Anton confirmed this really is a distinct format (Lottie/Bodymovin) and renamed
the fixtures accordingly (`samples/sample_v2026.comics`→`sample.lottie`,
`dataset/mahabharata/boranko/mahabharata-dot-comics_v2026`→`mahabharata-dot-lottie`). Revised same
day: Anton pointed out the vendored Lottie engine is also in `legacy/mahabharata-mobile-swift-v2012`
(not just the 2026 copy), which changes the history significantly — see Discoveries. Also answered
two direct questions: how Lottie was used in legacy v2012 Java (it wasn't, at all), and whether
`.lottie ↔ .comics` conversion is feasible via simple math (yes one direction, conditionally the
other — grounded in real keyframe inspection, not general knowledge).

## Last Updated

2026-08-07 by Claude

## Blockers

- Tests-phase completeness is genuinely capped until Requirements' Open Questions are answered —
  most consequentially whether this is a committed direction (which determines whether L1-L7 in
  `02-tests.md` are worth turning into real, maintained automated tests) and how frame/time
  addressing reconciles with scroll-driven reading (which gates any rendering-behavior test case at
  all, not just implementation of one).
- **Resolved, 2026-08-07 (in a sibling flow)**: the precomp-nesting question this flow raised (does
  `.comics` need a grouping concept to represent Lottie's nested compositions) has been answered —
  see `flows/comics-editor/tdd-dot-lottie-import-export/01-requirements.md`'s Precomp Handling
  decision and `flows/comics-editor/vdd-comics-editor-systematization-uiux`'s new Layer Grouping
  section/`02-visual.md`. Not re-litigated here; this flow's own scope stays research-only.
- **L6 RESOLVED, NEGATIVELY (2026-08-07)**: ran the real check across all 7 chapters (per
  `flows/tdd-dot-comics-format`'s animation-inventory investigation, cross-referenced back here).
  `ASHES.json`'s simple structure does NOT generalize — masks (1/7), null layers (1/7), solid
  layers (1/7), and layer parenting (5/7, up to 64% of one file's layers) are all real. The
  conversion-feasibility conclusion in `01-requirements.md` is corrected accordingly. L7 (easing
  handle consistency across all 7 files) remains open but is now lower priority.

## Progress

- [x] Requirements drafted (2026-08-07) — v1.0, extracted + corrected from
      `tdd-dot-comics-format`'s Part 0
- [x] Requirements revised (2026-08-07) — v1.1: corrected the v2012-vs-v2026 Lottie history, added
      the "Lottie in Android v2012" answer and the conversion-feasibility analysis
- [ ] Requirements approved
- [x] Tests drafted (2026-08-07) — v0.1, 5 schema/inventory-level cases (L1-L5)
- [x] Tests revised (2026-08-07) — added L6/L7 (do the other 6 chapters generalize the
      "simple content" finding), rendering-behavior cases still explicitly not yet possible
- [x] Tests revised again (2026-08-07) — L6 resolved negatively (masks/null/solid/parenting
      confirmed real, across 5-7 of 7 files); `01-requirements.md`'s conversion-feasibility
      conclusion corrected to match
- [ ] Tests approved
- [ ] Specifications drafted
- [ ] Plan drafted
- [ ] Implementation started

## Discoveries (2026-08-07, second pass)

1. **Corrected history**: the vendored, unused `LOT*` Lottie engine is not a 2026 addition — it's
   present, byte-identically, in `legacy/mahabharata-mobile-swift-v2012` too, and equally unused
   there. This has been dead, copy-forwarded code since 2012, across at least two app generations.
2. **The one real Lottie usage (the "now playing" equalizer icon, `AnimationView(name:
   "equalizer")`, a 14×14px animation) also dates to 2012**, using a separate mechanism (the modern
   `lottie-ios` CocoaPod) from the dead vendored engine.
3. **Android has never had Lottie, in any generation** — re-confirmed directly against
   `legacy/mahabharata-mobile-java-v2012` (zero source/Gradle references), matching the
   already-established v2026 Android finding.
4. **Conversion feasibility, grounded in real data — for `ASHES.json` specifically.**
   `ASHES.json`'s 101 layers are 100% Lottie image type (`ty:2`) — zero shapes/masks/text — and
   position/scale keyframes consistently use After Effects' default "Easy Ease" bezier handles
   (`{0.833,0.833}`/`{0.167,0.167}`), not arbitrary curves. This makes `.comics → .lottie`
   straightforwardly mechanical for this file, and would make `.lottie → .comics` conditionally
   simple if all content matched.
5. **CORRECTION (2026-08-07): does NOT generalize.** Checked all 7 real chapters directly: `THE
   CHASE` has 6 masked layers; `SVAYAMWARA` has a null layer; `THE BROKEN TUSK` has a solid layer
   **and** 190/295 layers (64%) using Lottie's `parent` field (transform-relative-to-another-layer)
   — a real character rig (named parts like "голова"/head, "руки сложен"/folded arms parented
   together), not a flat image stack. 5 of 7 files use `parent` at all. `.comics` has zero
   parent-relative-transform concept. The already-decided "bake absolute values at import time"
   mechanism (for precomp children) needs to generalize to arbitrary parent chains — a real,
   larger task than originally scoped. Full table in
   `flows/tdd-dot-comics-format/01-requirements.md`.

## Context Notes

- **Why this is its own flow, not a section of `tdd-dot-comics-format`**: Lottie is not a version
  of `.comics` — it's an unrelated container/animation format from a different pipeline. Keeping it
  inside the `.comics` flow blurred two separate compatibility stories (see `01-requirements.md`'s
  Origin section).
- **The naming correction matters for anyone reading old context**: earlier in this research
  (2026-08-07, same day), this content was investigated under the mistaken belief it was
  `sample_v2026.comics` (i.e., a newer version of the classic `.comics` schema). Anton corrected
  this immediately — it's genuinely Lottie, and the fixtures were renamed to reflect that
  (`.lottie` extension, `mahabharata-dot-lottie` directory name, not `_v2026`). All paths in this
  flow's docs use the corrected names.
- **A real, non-obvious finding preserved here**: `apps/mahabharata-mobile-swift-v2026` has a
  complete, real, vendored Lottie rendering engine that's never actually instantiated anywhere in
  the app's own code — added/staged, not integrated. This alone is worth surfacing to whoever owns
  that app, independent of anything else in this flow.

## Fork History

- Forked from: `flows/tdd-dot-comics-format/02-tests.md` ("Part 0") on 2026-08-07
- Reason: Anton confirmed the discovery was a genuinely separate format (Lottie), not a `.comics`
  version, and asked for it to be extracted into its own dedicated flow
- Changes: all path references corrected from the original (mislabeled) `sample_v2026.comics`/
  `mahabharata-dot-comics_v2026` names to the renamed `sample.lottie`/`mahabharata-dot-lottie`;
  re-verified directly against the renamed locations, not assumed unchanged

## Next Actions

1. Anton reviews `01-requirements.md`/`02-tests.md` — in particular the 7 Open Questions, none of
   which were assumed answered.
2. Run a quick script (per L6/L7's design implication) checking the other 6 real produced
   chapters' layer types and easing handles, to confirm or narrow the conversion-feasibility
   conclusion before treating it as general.
3. Confirm with whoever owns the Swift app (2012 and/or 2026 copy) whether the vendored Lottie
   engine integration is in progress elsewhere, or genuinely not started, and why it's been carried
   forward unused since 2012.
4. On direction from Anton: either proceed toward Specifications (if Lottie is a committed
   direction worth building test infrastructure for, possibly including a real `.comics ↔ .lottie`
   converter) or park this flow as a reference document (if exploratory), matching how
   `tdd-dot-comics-format` itself was once parked as a consolidation-only doc before being
   reactivated.
