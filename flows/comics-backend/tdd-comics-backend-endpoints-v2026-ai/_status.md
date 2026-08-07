# Status: tdd-comics-backend-endpoints-v2026-ai

## Current Phase

REQUIREMENTS

## Phase Status

DRAFTING — v0.2. Four foundational decisions made via discussion (art-strategy priority order,
async-job execution model, real-routes-now implementation scope, generic multi-book/artist-tool
scope). Acceptance criteria and a narrower Open Questions list written. Not yet approved.

## Last Updated

2026-08-07 by Claude (four foundational open questions resolved via AskUserQuestion; requirements
revised to v0.2 with concrete Must/Should/Won't-Have acceptance criteria; 5 narrower open questions
remain)

## Blockers

- Requirements not yet approved. Five narrower open questions remain in `01-requirements.md` (auth
  model, real Python-invocation mechanism, Category E default-balloon-shape behavior, job
  persistence model, minimum metadata for a brand-new no-dataset book) — none block moving to the
  TESTS phase's cases-first enumeration, but should be flagged again before Specifications commits
  to an architecture.

## Progress

- [x] Requirements drafted (v0.1)
- [x] Four foundational decisions made via discussion (v0.2): art-strategy priority, async-job
      execution model, real-routes-now implementation scope, generic multi-book/artist-tool scope
- [x] Concrete Must/Should/Won't-Have acceptance criteria written
- [ ] Requirements approved
- [ ] Tests (cases-first behavioral analysis) drafted
- [ ] Tests approved
- [ ] Specifications drafted
- [ ] Specifications approved
- [ ] Plan drafted
- [ ] Plan approved
- [ ] Implementation started
- [ ] Implementation complete
- [ ] Documentation drafted
- [ ] Documentation approved

## Context Notes

- Triggered by real feedback on `sdd-comics-ai-bhagavadgita-generator`'s completed output: text-only
  cards, real art only for chapter 5 (existing PSDs). Anton wants art density closer to the real
  `bhagavadgita_lottie` reference and explicitly does not want a Chromium-screenshot-only approach.
- Real inventory this session found 6 built comics-ai capabilities (multimodal/cutting,
  positioning, script-context, baloons, animations, bhagavadgita-generator) plus 1 unapproved draft
  (`gpt-image-2`) that is the only one targeting *new* art generation.
- This repo's real `v2026`/`v2026-admin` OpenAPI yamls are both paired with real, working Express
  routes (confirmed: `quotes.js` implements exactly what `v2026-admin.yaml` documents, served live
  via `swagger-ui-express`) — so "just a yaml" would be a deliberate scope departure, flagged as an
  open question rather than assumed.

## Fork History

- None; this is a new flow.

## Next Actions

1. Discuss the Open Questions in `01-requirements.md` with Anton (asked via AskUserQuestion this
   turn for the highest-leverage ones: art-strategy priority, execution model, Implementation
   scope, book scope).
2. Revise Requirements per his answers.
3. Get explicit "requirements approved" before moving to the TESTS phase (cases-first exhaustive
   behavioral enumeration per endpoint category).
