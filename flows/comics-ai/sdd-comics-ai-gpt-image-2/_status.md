# Status: sdd-comics-editor-ai-bhagavadgita-gpt-image-2

## Current Phase

REQUIREMENTS (awaiting review)

## Phase Status

DRAFTED — parallel external-artwork flow created; awaiting explicit requirements approval.

## Last Updated

2026-08-05 by Codex

## Blockers

- User approval of `01-requirements.md` and proposed pilot defaults.
- A monetary budget and explicit paid-run authorization are required before Implementation may call
  the API; requirements/specification work can continue without them.
- Explicit permission is required before any local PSD/composite/crop is uploaded as an image
  reference.

## Progress

- [x] Parallel flow created
- [x] Current official `gpt-image-2` capability/model identity checked
- [x] Relationship to deterministic primary flow defined
- [x] Requirements drafted
- [ ] Requirements approved
- [ ] Specifications drafted
- [ ] Specifications approved
- [ ] Plan drafted
- [ ] Plan approved
- [ ] Chapter-5 dry run approved
- [ ] Chapter-5 pilot generated and reviewed
- [ ] 18 enriched chapter variants generated
- [ ] Implementation complete

## Context Notes

- The primary flow remains the source-grounded, cost-independent completion path.
- This flow writes only under `work/bhagavadgita-gpt-image-2/` and treats
  `work/bhagavadgita/` as read-only input.
- Official documentation checked 2026-08-05: `gpt-image-2` supports image generation/editing with
  text/image input and image output; snapshot `gpt-image-2-2026-04-21` exists; free tier,
  fine-tuning, structured outputs, and streaming are not supported.
- The OpenAI Developer Docs MCP server was added to the local Codex configuration during research;
  a Codex restart may be needed before its tools appear in this session.
- Requirements approval does not authorize paid API calls or reference-image uploads.

## Next Action

User reviews `01-requirements.md`, resolves/accepts the proposed defaults, and explicitly says
`requirements approved` for this flow. Specifications then define the exact API, prompt, caching,
review, and enriched-packaging contracts without making paid calls.

## Fork History

- Parallel extension of `sdd-comics-editor-ai-bhagavadgita-generator`; not a replacement or fork of
  its deterministic completion path.
