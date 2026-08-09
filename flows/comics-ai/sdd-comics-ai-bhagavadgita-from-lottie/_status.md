# Status: comics-ai-bhagavadgita-from-lottie

## Current Phase

IMPLEMENTATION — not started (real ad hoc computation done outside the formal task sequence, see
below). Requirements/Specifications/Plan all APPROVED.

## Phase Status

APPROVED (all three docs, inherited from the parent flow's same-day approval, per extraction)

## Last Updated

2026-08-09 by Claude

## Blockers

- None blocking. Task 1.1 (verify the absolute-position compositing formula, no external renderer)
  is the real next step and the one with genuine open engineering risk — see Plan's own Risk
  Assessment.

## Progress

- [x] Flow extracted (2026-08-09) from `flows/comics-ai/sdd-comics-ai-bhagavadgita-generator`
      (which had this content as its v0.2-v0.3 Requirements / v0.3-v0.4 Specifications / v0.2-v0.3
      Plan additions) per Anton's explicit "Вынеси в отдельный sdd, из прошлого sdd удали"
      instruction. Content moved verbatim (renumbered, not re-derived) — see
      `01-requirements.md`/`02-specifications.md`/`03-plan.md`'s own Origin/header notes.
- [x] Requirements — inherited APPROVED status from parent flow's same-day approval
- [x] Specifications — inherited APPROVED status
- [x] Plan — inherited APPROVED status
- [x] Real `cameraPath` coordinates computed for all 3 scenes, ad hoc, ahead of the formal task
      sequence — per Anton's direct request. See `04-implementation-log.md` for full values and the
      disclosed caveat that they depend on Task 1.1's not-yet-verified compositing formula.
- [ ] Task 1.1 (verify compositing formula)
- [ ] Task 1.2 (`import_lottie.py` core)
- [ ] Task 1.3 (camera-reference selection + `cameraPath`)
- [ ] Task 1.4 (extend `package_comics.py`)
- [ ] Task 1.5 (new pipeline entry point)
- [ ] Task 1.6 (manifest/report disclosure)
- [ ] Implementation complete

## Context Notes

- This flow's implementation lives inside `apps/comics-ai/comics-ai-bhagavadgita-generator/` (the
  parent flow's own Python app) as new/modified files — it does not create a separate app. It
  produces a separate, additional `.comics` output, never counted as one of that flow's 18 chapters.
- **No third-party Lottie rendering tooling** (`python-lottie`, `lottie-web`, etc.) may be installed
  — Anton's explicit constraint. Verification reuses `flows/comics-editor/
  tdd-dot-lottie-import-export`'s findings and `libs/flutter_comics`'s existing, tested Lottie
  parser instead.
- Real, disclosed cross-flow follow-up not yet done: `flows/tdd-dot-comics-format` should formally
  adopt the `cameraPath` schema concept this flow proposes (same pattern as `Layer.ZDepth`/
  `preferredViewportWidth` before it) — not done as part of this flow.
- A separate, real critique from Anton about `sdd-comics-ai-bhagavadgita-generator`'s own Phase 3
  (Chromium-rendered verse cards vs. real PSD panorama assets) came up in the same session but is
  **out of scope for this flow** — tracked in that flow's own `_status.md`, not here.

## Fork History

- Extracted from `flows/comics-ai/sdd-comics-ai-bhagavadgita-generator` on 2026-08-09, per Anton's
  explicit instruction. That flow's own `01-requirements.md`/`02-specifications.md`/`03-plan.md`
  have had the corresponding content removed and replaced with a pointer here — see that flow's own
  `_status.md` for the disclosed removal note.

## Next Action

Begin Implementation at Task 1.1: verify the absolute-position compositing formula against
`tdd-dot-lottie-import-export`'s findings and `libs/flutter_comics`'s existing Lottie parser (no
external renderer).
