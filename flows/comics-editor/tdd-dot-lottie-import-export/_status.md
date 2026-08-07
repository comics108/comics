# Status: tdd-dot-lottie-import-export

## Current Phase

TESTS

## Phase Status

STARTING — Requirements approved 2026-08-07 (v0.2), with 2 Text Region sub-questions (`
isHandLettered`/`Layer.Style` relationship, coordinate space) explicitly deferred, not blocking.
Beginning cases-first behavioral analysis.

## Last Updated

2026-08-07 by Claude

## Blockers

- None blocking Tests-phase drafting. The 2 deferred Text Region sub-questions are narrow schema
  details — cases can be written acknowledging both possible answers where relevant, without
  waiting for either to be settled.

## Progress

- [x] Requirements drafted (2026-08-07) — v0.1
- [x] Requirements approved (2026-08-07) — v0.2, by Anton Dodonov, 2 sub-questions deferred
- [x] Tests drafted (2026-08-07) — v1.0, 6 categories (A-F), ~15 cases, cases-first per TDD
      discipline
- [ ] Tests approved
- [ ] Specifications drafted
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

1. Anton reviews `02-tests.md` v1.0 — in particular the 3 new Open Design Questions it surfaced
   (raster-mask-to-Lottie export has no clean answer yet; the 2 deferred Text Region questions
   still gate implementation of Categories C/D; whether the review screen and choice dialogs are
   one screen or sequential steps).
2. Get "tests approved" before Specifications, per standard TDD phase discipline.
