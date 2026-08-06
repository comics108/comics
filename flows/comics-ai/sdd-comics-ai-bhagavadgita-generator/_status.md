# Status: sdd-comics-editor-ai-bhagavadgita-generator

## Current Phase

SPECIFICATIONS (awaiting review)

## Phase Status

DRAFTED — requirements approved; `02-specifications.md` drafted and awaiting explicit approval.

## Last Updated

2026-08-05 by Codex

## Blockers

- User approval of `02-specifications.md`.

## Progress

- [x] New flow created
- [x] Dataset chapter count and source coverage measured
- [x] Existing AI-related SDD/VDD flows audited
- [x] Cross-flow gaps documented
- [x] Requirements drafted
- [x] Requirements approved (2026-08-05)
- [x] Specifications drafted
- [ ] Specifications approved
- [ ] Plan drafted
- [ ] Plan approved
- [ ] Implementation started
- [ ] At least 18 chapter `.comics` files generated
- [ ] Implementation complete

## Context Notes

- The current dataset has exactly 18 logical chapters, represented six times across six books/
  editions (`db_chapters.csv`: 108 rows).
- Russian `BookId=1` has 663 slokas; all inspected content fields are populated for every Russian
  row.
- Audio path columns are populated, but no audio media exists in `dataset/bhagavadgita/`.
- Three PSD files are the only visual assets and appear to cover chapter 5 only.
- Existing AI flows form useful stages but no text-to-comics orchestrator/storyboard/asset-generation
  bridge exists.
- A separate parallel flow, `sdd-comics-editor-ai-bhagavadgita-gpt-image-2`, owns optional external
  `gpt-image-2` artwork generation so this baseline stays local, deterministic, and cost-independent.
- `sdd-comics-ai-animations` has internal naming drift: its status/requirements and README call the
  capability “transformations”, while the tracked flow/app directory is named “animations”.
- Fresh `.comics` creation is technically proven by the multimodal package writer, but every new
  output must still pass the current editor/viewer loader because format compatibility work has
  unresolved items.
- `dataset/bhagavadgita/` must remain read-only; all generated artifacts go under
  `work/bhagavadgita/`.
- The repository already had extensive unrelated dirty/untracked changes before this flow; they are
  not part of this work and must be preserved.

## Next Action

User reviews `02-specifications.md` and explicitly says `specs approved`. Then draft
`03-plan.md` without implementing the generator yet.

## Fork History

- None; this is a new flow.
