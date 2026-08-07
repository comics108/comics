# Status: tdd-dot-lottie-import-export

## Current Phase

SPECIFICATIONS

## Phase Status

DRAFTED, AWAITING APPROVAL — Tests approved 2026-08-07 (v1.0). `03-specifications.md` went through
two rounds same day: v1.1 (real-data investigation found Lottie `parent` field used in 5/7
chapters, up to 64% of layers in `THE BROKEN TUSK`, plus real masks/null/solid layers — Precomp
Handling needed to generalize) then **v1.2, superseding update**: `flows/tdd-dot-comics-format`
decided a real `Layer.ParentId`/`Layer.Id` mechanism for `.comics` v2026 — this flow's design now
maps Lottie's `parent` field directly onto `ParentId` instead of baking-and-discarding it. Both
rounds disclosed as corrections in the document itself, not silently absorbed.

## Last Updated

2026-08-07 by Claude

## Blockers

- Waiting on Anton's review of `03-specifications.md` — the parenting-generalization question is
  now resolved (maps onto `Layer.ParentId`, not baked-and-discarded), leaving 5 Open Design
  Questions: D3's raster-mask export gap, the 2 still-deferred Text Region sub-questions, the
  review-screen-vs-choice-dialogs UI-structure question, whether the mask exclusion gets
  re-confirmed now that it's known to drop real content, and how the review screen should represent
  a deeply-parented layer chain.

## Progress

- [x] Requirements drafted (2026-08-07) — v0.1
- [x] Requirements approved (2026-08-07) — v0.2, by Anton Dodonov, 2 sub-questions deferred
- [x] Tests drafted (2026-08-07) — v1.0, 6 categories (A-F), ~15 cases, cases-first per TDD
      discipline
- [x] Tests approved (2026-08-07) — by Anton Dodonov, 3 Open Design Questions carried forward
- [x] Specifications drafted (2026-08-07) — v1.0, full traceability matrix included
- [x] Specifications corrected (2026-08-07) — v1.1, `parent`-chain generalization + real mask/null/
      solid-layer findings disclosed, 3 new Open Design Questions
- [x] Specifications superseded (2026-08-07) — v1.2, maps onto the new `Layer.ParentId`/`Layer.Id`
      mechanism directly instead of baking-and-discarding; one Open Design Question resolved
- [ ] Specifications approved
- [ ] Plan drafted
- [ ] Implementation started

## Context Notes

- **Purpose**: a real feature build (import `.lottie` into `apps/comics-editor`, export `.comics`
  documents as `.lottie`), not a research/consolidation flow like its two siblings
  (`tdd-dot-comics-format`, `tdd-dot-lottie-format`).
- **Scope is deliberately narrow**: editor-only (no mobile viewer changes), no sound/translation
  I/O (those live outside the Lottie JSON entirely in real content), no shape/mask/text Lottie
  support (breaks the whole "simple math" premise the sibling flow established).
- **A self-caught error during drafting**: an early version of this document's Open Questions
  attributed a fabricated answer to Anton on the time-base mapping question. Caught and corrected
  before this was shown as final — that question remains genuinely open, not decided.

## Fork History

N/A — new flow, not forked. Builds directly on `flows/tdd-dot-lottie-format`'s research (cited
throughout `01-requirements.md`), per Anton's explicit request to add real import/export capability
to `apps/comics-editor`.

## Next Actions

1. Anton reviews `03-specifications.md` v1.0 — the interface designs (`LottieDocument`,
   `ImportPreview`, `commitImport`, `buildLottieExport`), the two new `EditorLayer` fields, and the
   Traceability Matrix.
2. Get "specs approved" before Plan, per standard TDD phase discipline.
