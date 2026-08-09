# Status: tdd-comics-backend-endpoints-v2026-ai

## Current Phase

REQUIREMENTS

## Phase Status

DRAFTING — Requirements v0.3 rewritten around the approved production asset-first vision. Awaiting
explicit `requirements approved`. Tests and Specifications do not yet exist and were deliberately
not invented out of phase: `flows/tdd.md` requires exhaustive cases-first `02-tests.md` plus
`tests approved` before `03-specifications.md` may be derived.

## Last Updated

2026-08-09 by Codex

## What Changed in v0.3

- Replaced the old “wrap existing AI CLIs” framing with a durable production control plane.
- Made source recovery, immutable provenance, RGBA/bitmap masks, asset identity/type/style/art-stage
  catalogue, story-beat coverage, transformations, controlled generation, exact lettering,
  composition, review, model evaluation, and immutable release first-class API requirements.
- Reclassified deterministic text cards as draft/regression output, never production art.
- Made external generation provider-neutral and gated by upload permission, budget, idempotency,
  candidate review, and immutable lineage.
- Closed former product questions: scoped internal bearer auth, durable jobs, minimum new-book
  metadata, no silent default balloon, no bbox-only accepted asset, no hardcoded YOLO family.
- Expanded job states for authorization/review waits, cancellation, supersession, restart survival,
  and duplicate paid-call prevention.
- Defined format-valid vs. production-release-eligible as separate states.

## Blockers

- Requirements v0.3 need explicit user approval.
- After approval, the next mandatory artifact is `02-tests.md`, not Specifications. Cases must cover
  endpoint behavior, state transitions, authorization, race/idempotency, worker failure/restart,
  upload safety, budget/provider failures, review invalidation, model promotion, packaging, and
  release gating.

## Progress

- [x] Requirements v0.1 drafted
- [x] Foundational v0.2 discussion decisions recorded
- [x] Production asset-first direction approved upstream by Anton
- [x] Requirements rewritten as v0.3 for the production control plane
- [ ] Requirements v0.3 approved
- [ ] Tests (cases-first behavioral analysis) drafted
- [ ] Tests approved
- [ ] Specifications derived from approved tests
- [ ] Specifications approved
- [ ] Plan drafted
- [ ] Plan approved
- [ ] Implementation started
- [ ] Implementation complete
- [ ] Documentation drafted
- [ ] Documentation approved

## Context Notes

- The upstream Gita flow's 18 archives are useful schema/runtime regression fixtures but are not
  proof of production-art quality.
- Existing U-Net, Mask R-CNN, positioning, and animation artifacts are proposal candidates only;
  backend contracts must not encode them as winners.
- The backend must support very large source files and native structure (PSD/PDF/Lottie/`.comics`)
  without moving blobs through JSON/base64.
- Original datasets remain read-only; uploads/derivatives/releases require separately configured
  storage and retention.
- `gpt-image-2` paid calls and reference uploads remain separately authorized even after this TDD
  flow is approved.

## Incoming Cross-Flow Test Backlog (2026-08-09)

The approved Gita Requirements and draft production Specifications introduced the following
mandatory behavioral cases. They are queued here now and will be expanded into full
Given/When/Then/design-implication entries in `02-tests.md` immediately after this TDD's own
Requirements approval:

1. Native PSD/Lottie/`.comics` recovery is attempted before flattening/segmentation.
2. A foreground asset with bbox only cannot transition to `accepted`.
3. Model promotion rejects crop/tile leakage across source/scene-disjoint splits.
4. Accepted source/reusable/transformable coverage prevents an automatic paid generation call.
5. Generation authorization is source-upload-, action-, budget-, and idempotency-bound; retries do
   not duplicate provider calls or candidates.
6. A lettering OCR/exact-string mismatch blocks candidate/release promotion.
7. Changing an upstream source/asset/text/action version invalidates dependent approvals and leaves
   immutable historical releases unchanged.
8. A structurally valid `.comics` lacking visual/editorial gates remains a labelled draft.
9. Job cancellation/restart/retry preserves completed lineage and reports non-cancellable in-flight
   provider work honestly.
10. Golden-chapter scale-out remains blocked until mask, identity/style, lettering, art-direction,
    cultural/editorial, runtime, and minimum-story-beat gates all pass.

## Next Action

User reviews `01-requirements.md` v0.3 and says `requirements approved`. Codex then creates
`02-tests.md` with exhaustive Given/When/Then cases and design implications. Only after explicit
`tests approved` will `03-specifications.md` be created.

## Fork History

- None; v0.3 is an in-place requirements iteration, not a fork.
