# Requirements: comics-backend-endpoints-v2026-ai

> Version: 0.3 (production asset-first rewrite, 2026-08-09)
> Status: DRAFT — awaiting explicit `requirements approved`
> Last Updated: 2026-08-09 by Codex

## Origin and Product Direction

This flow exposes the comics AI production system through the real v2026 backend. It follows the
approved production vision in
`flows/comics-ai/sdd-comics-ai-bhagavadgita-generator/01-requirements.md` v0.8.

The backend is not a thin HTTP wrapper around “generate an image” or around the existing six Python
CLIs. It is the durable production control plane for:

```text
raw sources
  → source recovery and immutable provenance
  → asset extraction / masks / matting
  → identity, type, style, and art-stage catalogue
  → story beats and coverage gaps
  → reuse / transform / generate explicit gaps
  → exact lettering / composition / animation
  → review and quality gates
  → release-eligible .comics compilation
```

`.comics` is the final compiler target. The primary backend resource is a versioned, reviewable
asset graph, not a bbox and not a generated chapter image.

## Confirmed Decisions

1. **Asset-first priority**: use an original editable source layer first; then a recovered/matted
   bitmap asset; then transform/reconstruct a source-grounded asset; then generate an explicit gap.
   A deterministic text card remains a diagnostic/draft fallback but can never make a chapter
   production-eligible.
2. **Generic scope**: the API supports any new book and any new artist, including projects with raw
   manuscript/art only and no pre-existing CSV schema.
3. **Async mutations**: ingestion, extraction, model actions, composition, validation, packaging,
   and orchestration use durable asynchronous jobs. Read-only catalogue/coverage/status endpoints
   may return synchronously.
4. **Real implementation target**: future implementation must pair OpenAPI paths with working
   Express routes and real workers, following the existing v2026 backend convention. A YAML-only
   contract is not completion.
5. **Human authority**: model confidence is not approval. Assets, cluster corrections, generated
   candidates, golden chapters, and releases have explicit review state and an auditable human
   decision.
6. **Provider-neutral model actions**: local models and external providers such as `gpt-image-2`
   use the same task/candidate/provenance/review contract. Paid calls and source uploads require
   separate explicit authority.
7. **Production truth**: structural `.comics` validity is necessary but insufficient. Release
   eligibility also requires visual, identity/style, lettering, device, and editorial gates.

## Problem Statement

The repository contains useful but disconnected AI applications for script context, cutting,
positioning, balloon rendering, transformations/animation, deterministic chapter generation, and a
draft external image-generation path. Their current outputs and interfaces are incompatible as a
production system:

- segmentation persists bboxes while discarding computed masks;
- existing PSD/Lottie structure is not represented as reusable backend assets;
- characters, objects, art styles, poses, and art stages lack canonical identities;
- chapter-to-art mapping is treated as file/page matching instead of story-beat coverage;
- the learned positioner is known to underperform its rule baseline on held-out data;
- animation is largely calibrated heuristics, not a trained model;
- lettering geometry/masks are computed in places and then discarded;
- external generation lacks a unified backend task, budget, upload, candidate, and review surface;
- an archive can be valid while remaining visually unsuitable for production.

The backend needs durable resources and endpoints that make every one of these states observable,
versioned, composable, reviewable, resumable, and safe.

## Users

- **Producer / art director**: creates projects, sees coverage gaps, approves assets and releases.
- **Artist / letterer**: uploads sources, corrects masks/identity clusters, reviews transformations.
- **Automation client**: submits idempotent jobs and consumes typed results without knowing CLI
  locations or Python environments.
- **ML engineer**: registers datasets/models/evaluations and compares candidates on a gold set.
- **Cost/security owner**: controls external-provider budgets, source-upload permission, and audit.
- **Editor/viewer client**: obtains only release-eligible or explicitly labelled draft `.comics`.

## Required Resource Model

The API must expose stable identifiers and versioned relationships for at least:

- `Project`: owner, policy, default language, release gates, provider permissions.
- `Book`: title, source language, optional edition/author/artist metadata.
- `SourceItem`: immutable uploaded/imported manuscript, CSV, PSD, PDF, image, Lottie, audio,
  `.comics`, font/lettering sample, palette, character sheet, storyboard, or editorial note.
- `SourceRevision`: checksum, media metadata, storage reference, parser result, lineage.
- `Asset`: recoverable RGBA/blob representation, source coordinates, bitmap mask, optional contour,
  semantic kind, art stage, palette/style descriptors, quality and review state.
- `Entity`: canonical character/object/location identity and aliases.
- `AssetEntityLink`: identity, pose, expression, costume, view, attributes, confidence, review.
- `Scene` and `StoryBeat`: source-grounded narrative unit with required entities/actions/location.
- `CoverageItem`: beat requirement mapped to accepted, transformable, missing, or rejected assets.
- `ModelAction`: typed operation and immutable inputs/configuration/provider policy.
- `Candidate`: one output of a model action with metrics, lineage, cost, and review state.
- `TextRegion`: exact source string, language, shaping metadata, polygon/bitmap region, render state.
- `Composition`: ordered placements, transforms, z-order/depth, camera and animation proposals.
- `ReviewDecision`: actor, role, decision, reason, timestamp, compared candidate versions.
- `ModelArtifact`, `DatasetVersion`, and `EvaluationRun`: reproducible ML provenance and gates.
- `Job`: durable state/progress/events/result/error/idempotency/cost/cancellation metadata.
- `Release`: immutable manifest tying accepted inputs/assets/text/composition/model lineage to a
  validated `.comics` artifact.

Blob payloads must live in configured object/file storage. API JSON carries metadata and signed or
internal storage references, not multi-hundred-megabyte base64 documents.

## Required Endpoint Categories

Exact paths are deliberately deferred to Tests and Specifications; these categories are required
behavioral surfaces.

### A. Projects, Books, and Policy

Create/read/update production projects and books; configure languages, roles, quality gates,
external-provider permissions, budgets, and whether draft artifacts may be downloaded.

Minimum new-book input is project, title, primary language, and at least one real `SourceItem`.
Missing author/edition/chapter structure is allowed and may be derived later; missing title,
language, project, or all source material is rejected.

### B. Source Ingestion and Inspection

Register local/imported sources or upload supported files; compute checksums; deduplicate; inspect
media; parse structure where available; retain immutable provenance. Native PSD/Lottie/`.comics`
layers and alpha must be recoverable before any flattened-image fallback is proposed.

Supported source classes must include structured text, plain manuscript, PSD, PDF, raster image,
Lottie, audio, existing `.comics`, fonts/lettering references, palettes, and editorial metadata.

### C. Asset Extraction and Restoration

Create assets from native layers or flattened media. Actions include layer extraction,
registration, OCR, instance/semantic segmentation, bitmap-mask refinement, alpha matting,
cross-tile merge, de-overlap, inpainting, background reconstruction, scan cleanup, line extraction,
and upscale.

The accepted result for a separable foreground asset is RGBA + bitmap mask and provenance. A bbox
may be returned as an index/preview but cannot be the only production representation.

### D. Asset Catalogue, Identity, Type, and Style

Search, tag, classify, cluster, merge, and split assets by semantic kind, canonical entity,
character aliases, pose, expression, costume, view, object/location, scene, art stage, style,
palette, depth, and permitted transformations. Automatic cluster changes remain proposals until
approved; rejected/uncertain links remain visible.

### E. Narrative, Story Beats, and Coverage

Derive or author chapter/scene/story-beat graphs from structured or raw text, with source citations.
For every beat, expose required entities/actions/locations and coverage state: accepted source,
reusable, transformable, generation-required, blocked, or rejected. The API never assumes one
panorama/PDF page equals one chapter.

### F. Model Actions and Transformations

Submit typed, provider-neutral actions including segmentation, matting, classification, retrieval,
identity ranking, sketch cleanup/inking, paired colourization, palette transfer, inpaint/outpaint,
pose/expression/view variants, lettering style, layout, animation, camera, and visual QA.

Every action declares immutable input versions, expected output type, constraints, provider/model,
budget policy, seed/config when supported, and required approval gate. Multiple candidates remain
separate versions; no “latest output wins” mutation is allowed.

### G. External Generative Gap Filling

Preview cost/authority and then, only when explicitly authorized, submit generation/edit actions
such as `gpt-image-2` for a specific `CoverageItem`. Reference images, masks, prompts, model snapshot,
input/output hashes, usage/cost, and provider response metadata are recorded. Credentials and raw
secrets are never returned or logged.

Generation must not be called when accepted source/reusable/transformable coverage already satisfies
the task unless a human explicitly requests an alternative candidate. Generated candidates never
become accepted assets without review. Final textual lettering may not be delegated unchecked to an
image generator.

### H. Lettering and Balloons

Recover or create reviewed balloon/text-region geometry; erase prior text when authorized; shape
the exact authoritative string; render multilingual/RTL/CJK/Indic text; optionally apply a learned
hand-lettering texture to deterministic glyph masks; run exact-text/OCR/readability validation.

When no balloon exists, the API creates a balloon-design task or selects a reviewed template. It
must not silently insert an arbitrary default shape.

### I. Composition, Camera, and Animation

Create versioned vertical-strip composition candidates from accepted assets and story beats. Layout,
z-order/depth, camera, and animation may be proposed by models/rules but must disclose the method and
evaluation status. Known-underperforming models are never mandatory. Human corrections create a new
version and remain reproducible.

### J. Review and Approval

List review queues; compare candidates; approve, reject, request correction, merge/split identity
clusters, and revoke approval when an upstream dependency changes. Separate roles are required for
ML/technical review, art direction, lettering, and cultural/editorial review. Self-approval policy is
project-configurable but always audited.

### K. Evaluation and Model Registry

Register dataset/model versions and evaluation runs; maintain source/scene-disjoint splits; compare
candidate models/rules on the same gold set. Metrics include mask IoU/boundary quality, identity
retrieval, style/palette similarity, ink preservation, exact lettering, layout/runtime checks, and
human ratings. A model is deployable only when its configured gates pass.

### L. Packaging, Validation, and Release

Compile accepted compositions into `.comics`; validate schema, referenced assets, tile integrity,
text fidelity, visual QA, target viewport/device opening, and release approvals. Draft export may be
allowed by policy and must be watermarked/labelled in metadata. Only an immutable `Release` passing
all project gates is production-eligible.

### M. Durable Jobs and Orchestration

Submit, inspect, list, cancel, retry, and subscribe to jobs. A book/chapter orchestration job chains
the required stages based on coverage and policy, continues unrelated work after an isolated
failure, and reports per-item status. Jobs and events survive backend restarts.

## Acceptance Criteria

### Must Have

1. A project with only raw manuscript and/or art can be ingested without a pre-existing CSV schema,
   while a request with no real source material is rejected without fabricated placeholders.
2. Native PSD/Lottie/`.comics` structure is extracted before flattened-image segmentation and the
   chosen fallback reason is recorded.
3. Every accepted foreground asset has versioned provenance and a recoverable bitmap mask/RGBA
   representation; bbox-only output cannot pass the asset acceptance gate.
4. Asset/entity/type/style clusters are searchable and human-correctable without deleting rejected
   or uncertain model proposals.
5. Story beats expose a per-beat coverage matrix; unresolved art is an explicit gap, not silently
   replaced by an unrelated page or generated image.
6. Model actions are immutable and reproducible from versioned inputs/configuration. Their outputs
   are candidates until an authorized review decision accepts one.
7. External generation requires project permission, per-action authorization, available budget, and
   any required source-upload permission. Dry-run performs no paid call and uploads no source.
8. Generation is skipped when accepted lower-tier coverage exists unless an authorized human asks
   for alternatives; cost, model, prompt/reference lineage, and hashes are retained.
9. Lettering uses the authoritative string and retained text-region geometry, supports complex
   scripts, and must pass exact-text/OCR plus human readability review.
10. Composition candidates remain vertical-scroll, versioned, and editable; layout/animation model
    provenance and known evaluation limitations are visible.
11. Existing weak models may propose candidates but cannot be hardwired as winners. Model/rule
    promotion requires a common gold-set evaluation plus configured human gate.
12. A structurally valid `.comics` that lacks visual/lettering/editorial approvals is downloadable
    only as a policy-labelled draft and cannot receive production release status.
13. Every production release is immutable and traces to exact source, asset, text, composition,
    model/action, review, validation, and checksum versions.
14. Every mutating/compute endpoint returns or references a durable job whose state distinguishes at
    least `queued`, `running`, `waiting_for_authorization`, `waiting_for_review`, `succeeded`,
    `failed`, `cancelled`, and `superseded`.
15. Job retries and repeated submissions with the same idempotency key do not duplicate paid calls,
    assets, candidates, or releases. Jobs/events/results survive server restart.
16. Cancellation stops future work and paid calls where possible, preserves completed lineage, and
    reports whether an already-started provider request could not be cancelled.
17. Batch orchestration isolates failures by chapter/beat/action and continues independent items;
    the terminal report lists every success, failure, block, review wait, and fallback.
18. Every implemented route has a matching OpenAPI contract and real Express/worker behavior; schema
    examples and error codes match observed implementation.
19. Dataset source locations remain read-only. Uploaded sources, derived assets, temporary work, and
    releases use separately configured writable storage with explicit retention policy.
20. Auth is internal bearer/scoped-role based. Paid generation, provider policy, review, model
    promotion, and release endpoints require distinct permissions and write audit events.

### Should Have

- Signed resumable uploads and range-aware download for very large PSD/PDF sources.
- Webhook or event-stream delivery in addition to polling, with signed callbacks and replay.
- Visual thumbnails/contact sheets and side-by-side mask/candidate/release comparison data.
- Bulk review and bulk metadata correction with per-item atomic results.
- Coverage queries by project/book/chapter/entity/style/art-stage/review state.
- Provider quotas, per-project monthly budgets, and estimated-vs-actual cost reports.
- Golden-project templates such as chapters 1 and 11 for production-pipeline qualification.
- Explicit mobile/server model tiers without coupling the API schema to one framework/model family.

### Won't Have (This Iteration)

- A public consumer endpoint that can trigger training, paid generation, or unpublished-source
  access.
- One-shot full-book generation that bypasses asset, coverage, candidate, review, or release gates.
- Training a foundation image model from scratch.
- Automatically accepting generated art, cluster merges, inferred religious identities, or final
  lettering solely from model confidence.
- Treating deterministic text cards as production artwork; they remain draft/regression output.
- Publishing to stores/CDNs or modifying original datasets as a side effect of release creation.
- Embedding framework-specific concepts such as YOLO11 directly in durable public API resources.

## Security, Safety, and Operational Constraints

- Internal bearer authentication with scoped roles is required; backend deployment/network policy
  may add stronger isolation but cannot replace application authorization.
- Durable job/resource metadata must use persistent storage. In-memory-only history is insufficient.
- Worker invocation mechanism is a Specifications decision derived from failure/concurrency tests;
  requirements only demand isolation, durability, cancellation, resource limits, and auditability.
- Source blobs may contain confidential/unpublished art. External upload is denied by default and
  requires source-specific authority, not only provider API access.
- Provider credentials live in server-side secret storage and are never persisted in job payloads,
  logs, manifests, callbacks, or OpenAPI examples.
- Uploads need media/type/size validation, safe archive extraction, path traversal protection,
  malware/content scanning hooks, quotas, and configurable retention/deletion.
- Dataset/model licenses and generated-asset rights are recorded and can block model promotion or
  release. A locally trainable model is not automatically legally deployable.
- All destructive actions are soft-delete/tombstone or create a new revision; immutable source and
  release lineage cannot be overwritten.
- Cost-creating calls require an idempotency key and a recorded authorization decision immediately
  before dispatch.

## Resolved Former Open Questions

- **Authentication**: internal bearer auth with scoped roles and audit, not an unauthenticated or
  generic public route.
- **Job persistence**: durable storage; restart survival is required.
- **New-book minimum metadata**: project, title, primary language, and at least one real source.
- **Missing balloon**: create a reviewable balloon-design/template task; no silent arbitrary shape.
- **Text fallback**: allowed as an explicitly labelled draft, never production eligibility.
- **Segmentation format**: production assets require retained masks; bbox-only is insufficient.
- **Specific model family**: not fixed in Requirements; candidates compete after licensing and
  evaluation gates.

## Open Questions for Tests / Specifications

- Exact REST path hierarchy and whether jobs are top-level, nested, or both discoverable ways.
- Persistent store, queue, worker isolation, heartbeat/lease, retry, and process invocation design.
- Signed upload protocol and concrete maximum source sizes/types.
- Review-role separation defaults and approval invalidation propagation rules.
- Minimum gold-mask/identity/lettering dataset sizes and exact promotion thresholds.
- Whether six visual beats is a global production floor or a project policy default.
- Draft watermark/metadata representation and production release signature format.
- Webhook/event-stream transport and delivery guarantees.

These questions must be answered from cases-first behavior in `02-tests.md`, then encoded in
`03-specifications.md`; they do not authorize skipping the TDD TESTS phase.

## References

- `flows/tdd.md`
- `flows/comics-ai/sdd-comics-ai-bhagavadgita-generator/01-requirements.md` v0.8
- `flows/comics-ai/sdd-comics-ai-multimodal/`
- `flows/comics-ai/sdd-comics-ai-positioning/`
- `flows/comics-ai/sdd-comics-ai-story-script/`
- `flows/comics-ai/sdd-comics-ai-baloons/`
- `flows/comics-ai/sdd-comics-ai-animations/`
- `flows/comics-ai/sdd-comics-ai-gpt-image-2/`
- `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-lottie/`
- `apps/comics-backend/node/src/docs/v2026-admin.yaml`
- `apps/comics-backend/node/src/routes/v2026/admin/`

## Approval

- [x] Production asset-first direction selected by Anton on 2026-08-09.
- [ ] Requirements v0.3 reviewed.
- [ ] Requirements v0.3 approved with explicit `requirements approved`.
