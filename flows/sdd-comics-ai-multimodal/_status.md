# Status: sdd-comics-ai-multimodal

## Current Phase

IMPLEMENTATION

## Phase Status

IN PROGRESS

## Last Updated

2026-07-31 by Claude

## Blockers

- None. Implementation Phases 1-3 complete and verified (32/32 tests passing) — see
  `04-implementation-log.md`. Phase 4 (segmentation model training) is next.
- **Major mid-implementation revision (2026-07-31)**: Checkpoint A (Task 2.3) found the printed
  book is a conventionally paginated comic (fixed panel grids, real page numbers to 198+), not a
  crop of the tall scrolling digital canvas. Specifications and Plan both revised to v1.1 and
  re-approved: Phase 5 (photo alignment) now does per-panel OCR+content matching against
  `comics-ai-baloons`'s balloon OCR corpus instead of page-level homography against the canvas; Task
  3.2 (synthetic degradation) crops panel-shaped local clusters instead of arbitrary canvas windows.
  See `04-implementation-log.md` Session 2026-07-31 (continued 2) for full detail.

## Progress

- [x] Requirements drafted
- [x] Requirements approved
- [x] Specifications drafted
- [x] Specifications approved
- [x] Plan drafted
- [x] Plan approved
- [x] Implementation started
- [ ] Implementation complete
- [ ] Specifications approved
- [ ] Plan drafted
- [ ] Plan approved
- [ ] Implementation started
- [ ] Implementation complete
- [ ] Documentation drafted
- [ ] Documentation approved

## Context Notes

Key decisions and context for resuming:

- Working directory for all pipeline code/output: `apps/comics-ai/comics-multimodal/`
  (`dataset/` stays read-only, mirrors `apps/comics-ai/comics-ai-baloons/` convention).
- User explicitly wants the core "cutting"/segmentation model **trained from scratch**, not a
  wrapper around a third-party generative model. Off-the-shelf tools/APIs are acceptable only for
  lower-priority auxiliary tasks (quality correction, OCR).
- Explicit priority order (highest first): (1) segmentation/"cutting" model that decomposes a
  flattened page image into kind-tagged layer regions, (2) photo (low quality, from
  `comics_book_lowcamera/`) → `.comics` as the first end-to-end scenario, (3) input quality
  correction, (4) net-new image generation (lowest priority) — text→`.comics` and mixed
  drawn/text-chapter→`.comics` scenarios are deferred beyond this iteration.
- Confirmed: `comics_book_lowcamera/` photos are of the *same* pages as the existing
  `comics_interactive/*.comics` files (supervised pairs exist) — but per user decision, **no
  manual photo↔episode/page mapping will be authored**; the pipeline itself must auto-align photos
  to source content (content-based matching, no assumed frame-order/index correspondence).
- User wants eventual (not this-iteration) integration into `apps/comics-editor` with a
  human-corrector review workflow — should follow the existing `BalloonEditorCard`/
  `BalloonAiClient` pattern from `vdd-comics-editor-uiux-lettering` (per-item generate/regenerate,
  stale-output indicator, on-device/cloud routing, never silent auto-apply). Design-only this
  iteration; no editor code changes.
- Optional/non-blocking ask: package a vector (`.svg`) representation alongside `.png` for
  extracted/generated regions where feasible.
- Full research done before drafting: surveyed all `flows/sdd-*` and `flows/vdd-*` flows (two
  Explore-agent passes) plus live inspection of a sample `.comics` file's `data.json` (confirmed
  schema: `width`/`height`, `layers[].images[]` indexed by fixed `Cultures` enum `{En, Ru, Hi}`,
  typed `animations[]`) and `apps/comics-editor`'s live architecture (headless C# core over NDJSON,
  no generic plugin/import system, no timeline dimension, session-only undo/redo).
- Confirmed real example for character-library validation: episode 21 `ambas_plea` =
  `8a89f7d689fb441ea280cd782276bd7a.comics` (Princess Amba).
- `apps/comics-editor-v2.9` was renamed to `apps/comics-editor` by the user on 2026-07-31 — use the
  new path in all future work.

## Next Actions

1. Phase 4 (segmentation model): Task 4.2 baseline U-Net first (cheap, unblocks integration testing
   early), then Task 4.3 Mask R-CNN, compared at Checkpoint D — per Plan's Task 4.1 decision.
   `work/train_pairs/manifest.jsonl` (753 pairs) is ready to train against via `dataset.py`.
2. Phase 5 (revised), when reached: verify `comics-ai-baloons`'s `work/ocr.jsonl` exists/is current
   first (cross-flow dependency for panel-to-scene matching) before building `align_photo.py`.
3. Note for whoever picks this up: `comics-ai-baloons` currently has 2 failing tests of its own
   (stale `REPO_ROOT` path math + dataset reorg to a nested layout) — see
   `04-implementation-log.md` Session 2026-07-31 "Discoveries". Not this flow's problem to fix, but
   relevant if Phase 7's balloon handoff (or the new Phase 5 OCR-corpus dependency) behaves
   unexpectedly.
