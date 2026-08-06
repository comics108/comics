# Requirements: comics-editor-ai-bhagavadgita-gpt-image-2

> Version: 0.1
> Status: DRAFT — awaiting approval
> Last Updated: 2026-08-05

## Origin

The user requested a second, parallel flow for working with `gpt-image-2` alongside
`sdd-comics-editor-ai-bhagavadgita-generator`.

This flow owns external AI raster-art generation and its quality/cost/privacy controls. The primary
generator remains the authoritative, deterministic path to 18 source-grounded `.comics` files and
must never be blocked by this flow.

Current OpenAI documentation was checked on 2026-08-05. It describes `gpt-image-2` as the current
state-of-the-art OpenAI image generation/editing model, with text and image input, image output,
generation and edit endpoints, flexible sizes, and high-fidelity image inputs. It also publishes a
pinnable `gpt-image-2-2026-04-21` snapshot. Free-tier use is not supported, and the model does not
support fine-tuning, structured outputs, or streaming. These facts shape the requirements below;
exact request parameters remain a Specifications concern.

## Relationship to the Primary Flow

```text
sdd-comics-editor-ai-bhagavadgita-generator
  source.json + storyboard.json + deterministic .comics
                         │
                         │ read-only contract
                         v
sdd-comics-editor-ai-bhagavadgita-gpt-image-2
  style bible → prompts → generated assets → review → enriched .comics variants
```

- The primary flow owns dataset parsing, all 663 Russian slokas, grounded storyboard contracts,
  typography, tiling, packaging, archive validation, and baseline files.
- This flow consumes those versioned intermediates and adds generated `art`/`background` assets.
- It does not modify or overwrite baseline output. Enriched artifacts use a separate output root:
  `work/bhagavadgita-gpt-image-2/`.
- Either flow can be specified, planned, tested, and resumed independently.

## Problem Statement

The Bhagavad Gita dataset has visual material only for chapter 5. The primary generator can still
produce a complete text-forward 18-chapter set, but it cannot supply original visual storytelling
for the other 17 chapters. Existing local AI flows segment/recompose existing art and explicitly do
not generate net-new images.

This flow evaluates and operationalizes `gpt-image-2` as the missing artwork stage while preventing
three common failure modes: uncontrolled paid API spend, unapproved upload of local artwork, and
visually impressive but textually ungrounded or culturally inconsistent scenes.

## User Stories

### Primary

**As a** comics producer
**I want** a reviewable `gpt-image-2` pipeline that creates source-grounded Bhagavad Gita artwork
for every chapter and integrates accepted assets into `.comics` variants
**So that** the complete text-forward set can be enriched with coherent visual storytelling without
compromising its source fidelity or baseline availability.

### Secondary

- **As a** cost owner, **I want** dry-run estimates, a hard request/image budget, caching, and an
  approval checkpoint before paid calls, **so that** a batch cannot spend unexpectedly.
- **As a** cultural/content reviewer, **I want** every prompt and image linked to exact chapter/
  sloka sources and marked as AI-generated, **so that** invented content is visible and correctable.
- **As a** visual corrector, **I want** character/style reference sheets and variant review, **so
  that** Krishna, Arjuna, and recurring visual motifs do not drift arbitrarily across chapters.
- **As a** security owner, **I want** API credentials and uploaded reference assets handled
  explicitly, **so that** secrets are never committed and local PSD artwork is never sent without
  authorization.

## Acceptance Criteria

### Must Have

1. **Separate enriched set**: Given 18 valid baseline chapter files and matching primary-flow
   intermediates, when this pipeline completes, then
   `work/bhagavadgita-gpt-image-2/` contains 18 valid enriched `.comics` variants without modifying
   any baseline file.
2. **Minimum visual coverage**: Every enriched chapter contains at least one accepted, unique
   `gpt-image-2` hero/scene illustration tied to that chapter. Reusing one generated image across
   multiple chapters does not satisfy coverage.
3. **Grounded prompts**: Every generation request records the chapter, cited sloka orders, prompt
   template version, final prompt, model/snapshot, reference-image hashes, and intended layer kind.
   A request with no valid same-chapter citations is rejected before reaching the API.
4. **No generated scripture text**: Generated images contain no requested lettering, verse text,
   Sanskrit glyphs, labels, or speech balloons. All readable text continues to be rendered by the
   primary deterministic typography pipeline.
5. **Human acceptance gate**: Raw generated assets are never silently inserted into final enriched
   `.comics`. Each asset has an explicit `accepted`, `rejected`, or `pending` review state; only
   accepted assets are packaged.
6. **Cost gate**: Before any paid batch, a dry run reports planned request count, image count,
   configured quality/size, and an estimated maximum cost using current configured pricing data.
   Requirements/spec/plan approval alone does **not** authorize paid API calls; an explicit run
   approval and hard budget are required.
7. **Credential safety**: The API key is read from an environment/secret provider, never stored in
   source, prompts, manifests, logs, archives, or generated metadata. Missing credentials fail
   before any request.
8. **Reference-upload safety**: No PSD, extracted composite, character crop, or other local image is
   uploaded until the user explicitly approves which reference assets may leave the workstation.
   Text-only generation remains possible without that permission.
9. **Reproducible provenance**: Production uses the pinned snapshot
   `gpt-image-2-2026-04-21` unless a later explicit SDD revision changes it. Because image synthesis
   is nondeterministic, reproducibility means immutable request/response provenance and cached
   accepted bytes, not a promise that reruns create identical pixels.
10. **Resumable/idempotent operation**: A request fingerprint prevents duplicate paid calls for an
    already successful asset. Retries are bounded and only transient failures are retried
    automatically.
11. **Honest API failures**: Moderation blocks, refusals, rate limits, timeouts, malformed responses,
    and exhausted budget are recorded per asset. They never produce placeholder data presented as
    model output and never damage already accepted files.
12. **Validated integration**: All 18 enriched outputs pass the same archive/tile/editor-loader
    checks as the primary set; the final report distinguishes generated, accepted, rejected,
    fallback, and missing assets.

### Should Have

- A chapter-5 pilot that compares text-only generation against explicitly approved PSD-referenced
  generation before choosing the production style strategy.
- A reusable, versioned style bible covering palette, medium, clothing, iconography, prohibited
  motifs, composition, and “no text in image”.
- Approved character reference sheets for recurring figures, used as image inputs/edit references
  where the model/API supports them.
- Two or more candidate variants for the pilot scene, with review notes explaining selection.
- Automated visual QA warnings for unexpected text, wrong aspect ratio, blank/corrupt output,
  near-duplicates, and gross palette/style drift.
- Request pacing that respects account rate limits and records observed latency/usage.
- Ability to regenerate a single rejected asset without regenerating its entire chapter.

### Won't Have (This Iteration)

- Fine-tuning `gpt-image-2`; the official model does not support fine-tuning.
- Silent, fully autonomous publication of generated religious imagery.
- Using model-rendered text as authoritative scripture content.
- Uploading all three large PSDs by default.
- Replacing the primary flow's deterministic chapter generation or its 18-file completion gate.
- Generating hundreds of verse-level images before the chapter-level pilot establishes quality and
  cost. The initial target is one accepted hero/scene image per chapter.
- Committing generated binary assets to source control or uploading them to external storage.

## Constraints

- **Model**: explicit target `gpt-image-2`; production snapshot
  `gpt-image-2-2026-04-21`.
- **External service**: network access, an eligible paid OpenAI API project, and an API key are
  required for real generation.
- **Cost**: no uncapped mode. Every paid run has request-count and monetary ceilings and stops
  before exceeding either.
- **Data boundary**: source text sent to the API is minimized to the cited scene context. Comments,
  unrelated chapters, credentials, filesystem paths, and private metadata are excluded.
- **Output root**: `work/bhagavadgita-gpt-image-2/`; primary `work/bhagavadgita/` is read-only input.
- **Source dataset**: `dataset/bhagavadgita/` remains read-only.
- **Fidelity**: imagery is an interpretive draft and must be labeled as AI-generated in external
  manifest/report metadata.
- **No false determinism**: request fingerprints cache outputs but do not imply seeded/pixel-stable
  generation unless the live API explicitly documents such a control in Specifications.

## Proposed Defaults (Awaiting Approval)

1. Start with a **chapter-5 pilot**, because it is the only chapter with local visual references.
2. Generate **two candidate hero images** for the pilot, but make no paid call until a dry-run cost
   and explicit run approval are supplied.
3. Use **text-only prompts first**; compare PSD-referenced edits only after explicit reference-upload
   approval.
4. After pilot review, generate **one accepted hero/scene illustration per each of 18 chapters**;
   verse-level/panel-level expansion becomes a later scope increase.
5. Keep all scripture lettering outside generated images and composite it with the primary flow's
   deterministic renderer.
6. Use the pinned model snapshot for production and retain the alias only for manual experiments.

## Open Questions

- [ ] Approve the six defaults above.
- [ ] May chapter-5 PSD composites or crops be uploaded to OpenAI as image references, or must the
      first iteration remain text-only?
- [ ] What hard budget should apply to the chapter-5 pilot and later 18-chapter production run?
      This must be resolved before Implementation performs paid calls, not necessarily before
      drafting Specifications/Plan.
- [ ] Who performs visual/cultural acceptance of generated Krishna/Arjuna imagery before packaging?
      Until named, the user is the acceptance authority.

## Parallel-Flow Boundaries

| Concern | Primary generator | This flow |
|---|---|---|
| CSV normalization / 18 chapters / 663 slokas | Owns | Consumes |
| Grounded storyboard schema | Owns | Consumes and validates citations |
| Deterministic text cards | Owns | Reuses unchanged |
| Baseline `.comics` completion | Owns | Never blocks |
| External OpenAI API | No dependency | Owns |
| Raster prompt/style/reference strategy | Metadata only | Owns |
| Paid-call budgeting and caching | N/A | Owns |
| Human image review | Not required for baseline | Required |
| Enriched `.comics` variants | No | Owns |

## References

- `flows/sdd-comics-editor-ai-bhagavadgita-generator/`
- `flows/sdd-comics-ai-script-context/`
- `flows/sdd-comics-ai-multimodal/`
- `flows/vdd-comics-editor-ai-uiux/`
- `dataset/bhagavadgita/vaishnav/drawing/`
- [Official GPT Image 2 model page](https://developers.openai.com/api/docs/models/gpt-image-2)
- [Official OpenAI models catalog](https://developers.openai.com/api/docs/models)

## Approval

- [ ] Reviewed by user
- [ ] Requirements approved
