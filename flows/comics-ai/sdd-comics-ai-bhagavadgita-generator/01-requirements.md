# Requirements: comics-editor-ai-bhagavadgita-generator

> Version: 0.9 (2026-08-11, APPROVED by direct instruction): fully autonomous production. Anton
> explicitly required that human participation must not be necessary. This addendum supersedes
> every older mandatory-human-review clause below. Manual review remains optional and auditable,
> never a release dependency. Automated approval must remain honest: it reports
> `machine_verified`, never claims human theological/editorial endorsement, and fails closed when
> independent evidence is insufficient.

> Version: 0.8 (2026-08-09, APPROVED): production-art pivot approved as the desired vision by Anton
> ("Утверждено именно твое видение"). Replaces v0.6's direct panorama → existing U-Net bbox →
> known-underperforming positioner → heuristic animation proposal with an asset-first production
> pipeline: source recovery, bitmap masks/matting, identity/style graph, story-beat coverage,
> transformation/generation of explicit gaps, exact lettering, art-direction gates, and only then
> `.comics` compilation. Phases 1-9 remain implemented and unchanged; their text-card output is a
> format/fidelity baseline, not accepted as the final production-art result.
> Status: v0.8 APPROVED on 2026-08-09 (`reqs approved`)
> Last Updated: 2026-08-11 (mandatory human participation removed by direct instruction)

## Autonomous Release Addendum (v0.9, superseding)

- Every technical, identity/style, art-direction, lettering, cultural/editorial, and runtime gate
  must have a deterministic or independently reproducible automated reviewer.
- Native PSD alpha may be accepted after source-integrity, non-empty/non-rectangular mask, boundary,
  and provenance checks. Panorama masks require consensus from at least two genuinely different
  methods; the box-supervised U-Net/Mask R-CNN pair alone is not independent gold evidence.
- Gold records store reviewer pipeline/version, input/checkpoint hashes, metrics, and evidence.
  Missing evidence fails closed; `reviewer="human"` placeholders are forbidden.
- Cultural/editorial automation verifies canonical source citations, chapter/verse scope, named
  entity rules, and contradiction checks. It is labelled machine verification, not theological
  authority.
- Exact lettering is gated by normalized authoritative-string equality plus independent OCR/readback.
- Optional human corrections create new immutable decisions but are not required for candidate,
  release, model promotion, golden chapters, or all-18 expansion.

## Origin

The user requested a new SDD flow that generates a set of `.comics` files in
`work/bhagavadgita/` from `dataset/bhagavadgita/`, audits all existing AI-related flows, and records
the gaps between those flows and a real text-to-comics result. The minimum delivery criterion is at
least one `.comics` file for every Bhagavad Gita chapter represented by the dataset.

The repository-local `flows/sdd.md` process is authoritative for this flow because the named `$sdd`
skill is not installed in the current session. This document is Requirements only; specifications,
plan, implementation, and generation remain gated by their explicit approvals.

## Dataset Findings

The chapter count is not an estimate: the dataset contains **18 logical chapters**.

- `db_books.csv`: 6 editions/translations (Russian, three English editions, German, Spanish).
- `db_chapters.csv`: 108 rows = 6 books × the same 18 chapter orders.
- `Gita_Slokas.csv`: 3,979 edition-specific sloka rows.
- Russian edition (`BookId=1`, initials `ШМ`): **663 slokas**, with `Text`, `Transcription`,
  `Translation`, `Comment`, `Audio`, and `AudioSanskrit` populated for every row.
- `Gita_Vocabularies.csv`: 16,933 vocabulary rows.
- `db_quoutes.csv`: 116 quote rows.
- The dataset contains no actual audio media despite populated audio-path fields.
- The first-audited editable visual sources were three large PSDs under `vaishnav/drawing/`:
  `5_1.psd`, `5_2.psd`, and `app_BG._chiba5.psd`. Later inspection found the panorama PDFs and the
  Bodymovin package described below, so filenames alone are not a complete source inventory.
- `dataset/bhagavadgita/` is an immutable input. It must never be modified by the generator.

The 18 Russian chapter titles, in dataset order, are:

1. Осмотр Армий
2. Душа в мире материи
3. Йога деятельности
4. Йога обретения духовного знания
5. Деятельность в отречении
6. Медитативная йога
7. Постижение Абсолюта и Его энергий
8. Достижение высшей Реальности
9. Тайное сокровище преданности
10. Величие и красота Господа
11. Созерцание вселенского образа
12. Йога преданности
13. Подчиненное и господствующее начала
14. Три гуны материального мира
15. Высшая Личность
16. Божественные и демонические качества
17. Три вида веры
18. Йога освобождения

**Note (2026-08-09)**: a real Bodymovin source also exists in the dataset
(`dataset/bhagavadgita/vaishnav/bhagavadgita_bodymovin/`), investigated and specified here 2026-08-09
then **extracted into its own flow**, `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-bodymovin/`, per
Anton's explicit instruction — see that flow for the full findings (camera-path/z-depth extraction),
not duplicated here.

### Semantic source classification (verified 2026-08-10)

Direct inspection of the source content, including every RU/EN raster text overlay and the editable
PSD text layers, establishes the following classifications. Folder/file numbering is production
metadata and must never be interpreted as scripture chapter/verse numbering without content
evidence:

- `bhagavadgita_bodymovin/unzip/1/` is **not Bhagavad Gita chapter 1**. It is the complete standalone
  **Gita Dhyanam** prologue/meditation: all 9 traditional invocatory stanzas are present in both RU
  and EN overlay Bodymovins. The source title's `Mediation` spelling, directory `1`, and cover token
  `S3_B1_C1` are package/course identifiers, not canonical chapter semantics. Its art/timing may be
  reused as reviewed style or motion evidence, but its text and scenes cannot satisfy coverage for
  any of the 18 canonical chapters.
- `vaishnav/drawing/app_BG._chiba5.psd` is confirmed canonical **Bhagavad Gita chapter 5**, covering
  verses **5.14-5.29** in 15 sequential English balloon/caption groups (the coupled 5.27-5.28
  passage shares one group). This is not Gita Dhyanam and not chapter 1.
- `5_1.psd` and `5_2.psd` are production art components reproduced inside
  `app_BG._chiba5.psd`; their suffixes are not reliable verse identifiers and they are not separate
  chapter documents.

Every native source therefore needs an explicit reviewed semantic scope (`work`, canonical chapter
and verse range where applicable, standalone/prologue/component status, mapping confidence, and
evidence). An unreviewed filename-derived mapping is a release-blocking provenance error.

## Panoramic PDF Source (NEW, 2026-08-09) — corrects the original "art only exists for chapter 5" premise

Anton, after reviewing this flow's already-implemented Phase 3 (Chromium/Playwright-rendered verse
cards): "твое решение по рендерингу из Chromium было в корне не верно, нужно было использовать
ассеты из psd в dataset/bhagavadgita/vaishnav/drawing" — scoped to all 18 chapters, not just
chapter 5 — followed by a direct instruction to inspect two large, previously-unaudited PDFs in that
same directory and record real findings here before proposing a new rendering plan.

**Real inspection, via `pdfinfo`/`pdftoppm` (poppler, already installed — no new dependency) and
direct visual review of rendered page previews, not assumed from filenames**:

| File | Pages | Page size (pts) | File size |
|---|---|---|---|
| `All_Black-n-White.pdf` | 12 | 7793.64 × 1048.68 (≈108.2″ × 14.6″) | 622,199,467 bytes |
| `All_Coloured.pdf` | 6 | 7143.6 × 968.64 (≈99.2″ × 13.5″) | 95,382,886 bytes |

- **No embedded text anywhere** (`pdftotext` on every page returns empty) — no chapter labels,
  titles, or captions to key off of. Any chapter mapping has to come from visual content or an
  external source, not the PDF's own metadata.
- **Each page is one continuous, densely-packed hand-drawn illustrated frieze** — not a grid of
  discrete panels, not a cover/placeholder. Real, rich linework (ink-drawing style) filling the
  entire page width, packed with dozens of distinct mythological figures per page (deities, warriors,
  animals, architecture). This is genuinely the same caliber of hand-drawn artwork the Bodymovin
  investigation referenced ("отрисованной вручную художниками"), not limited to chapter 5.
- **Pages are visually distinct from each other**, not repeats or variations of one composition —
  direct visual review of pages 1, 2, 3, and 12 found four clearly different scenes:
  - Page 1: a broad "cast" panorama (many named/recognizable figures, sun/moon imagery at the edges)
    — plausibly an introductory/title panorama, not tied to one specific chapter.
  - Page 2: two massed armies (elephants, chariots, cavalry) facing off with a central chariot scene
    — a strong, plausible visual match to Chapter 1's real title, "Осмотр Армий" ("Survey of the
    Armies") — Krishna and Arjuna's chariot between the two armies is the chapter's defining scene.
  - Page 3: radiant sun/halo imagery, temple/city architecture, a standing pale figure, warriors —
    a plausible but less certain match to one of the early chapters.
  - Page 12: a cosmic, multi-faced/many-eyed composite figure — a strong, plausible visual match to
    Chapter 11's real title, "Созерцание вселенского образа" ("Vision of the Universal Form"), the
    Gita's famous cosmic-vision chapter.
  - These are **visual inferences from direct review, not confirmed against any label, caption, or
    external source** — flagged as a real, unresolved mapping question below, not asserted as fact.
- **`All_Coloured.pdf` is a colored subset of the same compositions as `All_Black-n-White.pdf`**, not
  independent content — direct visual comparison confirmed `All_Coloured.pdf` page 1 reproduces the
  exact same composition as `All_Black-n-White.pdf` page 1 (same figures, same layout, full color),
  and `All_Coloured.pdf` page 2 reproduces `All_Black-n-White.pdf` page 3's composition. **This
  means the two files' page numbers are NOT in simple 1:1 correspondence** (color page 2 matches
  B&W page 3, not B&W page 2) — the exact mapping between all 6 colored pages and their 12 B&W
  counterparts is not fully confirmed by this pass, flagged as a real open question, not guessed.
- **Orientation is wide/horizontal** (width roughly 7.4–8× the height), the opposite of `.comics`'
  established vertical-scroll convention (per `flows/tdd-dot-comics-format`'s confirmed "vertical
  continuous strip" default). Using this art faithfully, in its native orientation, is a real
  architectural question — see `02-specifications.md`'s new section for the design.

**Real, disclosed limitation on this pass**: only 4 of 12 B&W pages were visually reviewed (1, 2, 3,
12); the remaining 8 were not inspected in this pass. A full page-by-page review, and a real attempt
to confirm the 12 (or 6) pages against the 18 known chapter titles, is real, not-yet-done work — see
Open Questions and the new Plan phase.

## Production Visual Pipeline Pivot (NEW, 2026-08-09, approved vision)

The production unit is an **asset with provenance**, not a rectangle and not a final `.comics`
layer. `.comics` is the last compiler backend after art recovery, transformation, generation,
composition, lettering, review, and quality control. The pipeline must prefer source recovery over
generation:

1. extract an existing source layer when one exists;
2. segment/matte an object from a flattened bitmap when no source layer exists;
3. reconstruct or transform a source-grounded asset when it is incomplete;
4. generate a new asset only for an explicit, measured coverage gap.

The real source inventory already includes more structure than v0.6 used:

- structured chapter/sloka/translation/commentary/vocabulary/quote records;
- three PSDs with real hierarchy and per-layer alpha (`5_1.psd`: 5 descendants/1 group;
  `5_2.psd`: 32 descendants/6 groups; `app_BG._chiba5.psd`: 419 descendants/92 groups);
- 12 B&W and 6 coloured panoramic raster compositions, including six potential paired
  line-art/colour supervision examples after geometric registration;
- a Bodymovin package with source assets, transforms/timing, music, and RU/EN translations;
- existing Bhagavad Gita `.comics` as format baselines and Mahabharata `.comics`/AI outputs as
  external training/evaluation evidence, never as automatic proof of Gita-domain quality.

The canonical intermediate representation must preserve, where available: source URI/checksum,
source coordinates, RGBA pixels, bitmap mask, optional vector contour, semantic kind, canonical
entity/character identity, pose/expression/costume, art stage (sketch/ink/flats/shaded/final), style
and palette descriptors, scene/chapter candidates, depth/occlusion hints, allowed transformations,
model/prompt lineage, review state, and quality metrics.

The required model-action catalogue is broader than segmentation:

- source extraction, normalization, registration, deduplication, OCR, and provenance capture;
- instance/semantic segmentation, alpha matting, contour refinement, cross-tile instance merging;
- object/character/type/style classification, visual retrieval, identity clustering, and manual
  merge/split correction;
- de-overlap, background reconstruction, inpainting, scan cleanup, line extraction, and upscale;
- sketch cleanup/inking, paired line-art colourization, palette transfer, flats/shadows/highlights;
- reference-conditioned generation/editing for explicit missing assets, including the parallel
  `gpt-image-2` flow, with candidates and approval rather than silent automatic inclusion;
- story-beat extraction/mapping, shot planning, vertical-strip composition, z-order/depth, camera,
  and animation proposals;
- balloon/text-region recovery, exact multilingual shaping, deterministic glyph masks, learned
  hand-lettering style, and OCR/exact-text verification;
- automated visual/runtime QA followed by human art-direction and cultural/editorial approval.

The current model artifacts are candidates, not mandated winners. In particular, v0.6's U-Net
discards its connected-component mask and persists only a bbox; its mask supervision is
box-shaped; the learned positioner is documented as 55% worse than its rule baseline on the later
held-out evaluation; and `comics-ai-animations` contains calibrated heuristics rather than learned
weights. Each may propose or bootstrap labels, but no one of them is allowed to bypass a production
quality gate.

Compact instance segmentation is expected to be trainable locally on the attached Apple M4 Max
GPU. PSD alpha is the first high-quality mask source; panorama pseudo-labels must be corrected;
train/validation/test splits must be by source composition or scene, never random adjacent tiles.
The production cut result is RGBA + bitmap mask (and optionally a contour), not a bbox crop.

The 18-chapter mapping is defined through **story beats**, not one panorama page per chapter. Each
chapter receives a coverage matrix of required beats/entities/locations/actions against recovered,
transformable, and missing assets. Two golden chapters (1 and 11, the strongest currently plausible
source mappings) must prove the complete artistic pipeline before expansion to all 18 chapters.

## Existing AI Flow Audit

| Flow | Proven capability | Reusable here | Gap for Bhagavad Gita generation |
|---|---|---|---|
| `sdd-comics-ai-multimodal` | Existing page/photo → cut, kind-tagged regions, library, fresh `.comics` package | Fresh ZIP/package writer, tiling, region taxonomy, reporting conventions | Requires source imagery; does not convert scripture text into scenes or create missing artwork |
| `sdd-comics-ai-script-context` | Local Ollama text → structured characters, props, locations, actions; 27/27 Mahabharata episodes | Local-model invocation, structured output, provenance/raw-output convention | Extracts entities from already-selected episode text; no chapter summarization, scene segmentation, dialogue assignment, or storyboard generation |
| `sdd-comics-ai-positioning` | Rule baseline places already-cut regions; learned model was worse | Kind-aware spacing/placement baseline and honest evaluation pattern | Mahabharata-calibrated, expects regions, has no text→layout bridge, and cannot guarantee quality under Bhagavad Gita domain shift |
| `sdd-comics-ai-animations` | Kind-calibrated reveal transforms; full cut→position→transform demo | Alpha/scale reveal defaults and transform schema | Still expects pre-existing regions; translate/rotate direction is unsupported. Naming drifts internally between “animations” and “transformations” |
| `sdd-comics-ai-baloons` | OCR, matching, erasing, multilingual text rendering, re-tiling, packaging for existing balloon layers | Text rasterization/shaping and language handling | Cannot invent balloon shapes or assign new chapter text to newly planned panels; depends on existing balloons/source archives |
| `vdd-comics-editor-ai-uiux` | Human review UI for cutting results and library insertion | Never-silent-auto-apply and review-state patterns | Interactive single-document correction, not unattended 18-chapter batch generation; no generator UI |
| `vdd-comics-editor-systematization-uiux` | Requirements seed for variant taxonomy | Future character/action taxonomy | Not approved or implemented; net-new in-style character generation is explicitly absent |
| `sdd-comics-editor-questions` | Cross-flow AI research and unresolved questions | Prior evidence and traceability | Research index, not an executable generator |

**Cross-flow sync note, added 2026-08-06 (Claude, per Anton's request)**: `sdd-comics-ai-multimodal`'s
cutting/segmentation model choice (Task 4.1) was reopened the same day — the shipped baseline
computes a real per-instance mask internally but discards it before writing `regions.jsonl` (bbox
only), and a from-scratch-trained YOLO11-seg family (YOLO11m-seg mobile / YOLO11l-seg,
YOLO11x-seg server-desktop) is under evaluation as a mask-preserving replacement, with an
Ultralytics AGPL licensing question left open for Anton. See `sdd-comics-ai-multimodal/03-plan.md`'s
"Revision, 2026-08-06" note and `_status.md`'s Blockers. **Relevance here is indirect and
non-blocking**: this flow's Must-Have path (deterministic text-forward rendering) never invokes
segmentation at all — there is no photographed source page to cut for 17 of 18 chapters. It would
only matter if a future enrichment pass tried to extract discrete figure/character regions from the
chapter-5 PSD composite (not in this flow's current Should-Have scope) or from the Bhagavad Gita
`vaishnav/drawing/` art more broadly if more PSD/photo source material is added later.

The `.comics` format is also covered by `tdd-dot-comics-format` and current editor code. This is not
an AI flow, but it is a hard compatibility dependency. The multimodal package writer proves that a
fresh archive can be built from scratch (`data.json` plus tiled `layers/`), while the format TDD
still records unresolved cross-viewer/default-value compatibility gaps. Generated files therefore
need direct validation in current editor/viewer code, not merely a successful ZIP write.

## Consolidated Gap Statement

No existing flow owns an end-to-end **chapter text → grounded storyboard → visual assets → layout →
animations → validated `.comics`** pipeline. The missing capabilities are:

1. A Bhagavad Gita CSV loader that normalizes six editions into 18 logical chapters and preserves
   source row IDs/order.
2. Faithful chapter decomposition into pages/scenes/panels, including speaker/dialogue assignment.
3. A grounding policy that prevents an LLM from silently adding theological claims or quotations
   absent from the source.
4. A visual strategy for the 17 chapters with no artwork and a verified PSD import/export strategy
   for chapter 5.
5. New balloon/card construction; the current balloon flow only edits existing shapes.
6. A bridge that turns a storyboard into the region inputs expected by positioning and animation.
7. Domain-specific quality checks: existing layout/animation baselines were calibrated on a
   different Mahabharata corpus.
8. Batch orchestration, resumability, per-chapter manifest/provenance, validation, and honest
   partial-failure reporting.
9. A defined handling policy for audio references whose media files are absent.
10. A review path for generated narrative/visual content; current editor AI review covers cutting,
    not chapter synthesis.

## Problem Statement

The repository has several individually proven AI-assisted stages, but there is no composition
layer that can consume this dataset and produce a complete, trustworthy set of Bhagavad Gita
`.comics` documents. A direct attempt to chain the existing stages would fail before cutting,
because most chapters contain text but no page imagery or regions. A new generator must fill that
composition gap while reusing proven packaging, text rendering, layout, animation, and validation
contracts where they actually apply.

## User Stories

### Primary

**As a** comics content producer
**I want** a resumable generator that turns the Bhagavad Gita dataset into at least one valid
`.comics` document per logical chapter
**So that** all 18 chapters can be opened, reviewed, and iterated in Comics Editor from a concrete
generated baseline rather than remaining disconnected CSV/PSD source material.

### Secondary

- **As a** theological/content reviewer, **I want** every rendered verse, quotation, summary, and
  generated scene to retain exact source provenance, **so that** hallucinations and mistranslations
  can be detected.
- **As a** pipeline maintainer, **I want** deterministic chapter discovery, resumable stages, and a
  manifest of successes/failures, **so that** one failed chapter never silently reduces coverage.
- **As a** visual corrector, **I want** generated documents to use the existing layer kinds and
  standard `.comics` structure, **so that** the current editor/viewers can inspect and refine them.
- **As a** maintainer of the existing AI stack, **I want** reused and newly-added stages identified
  explicitly, **so that** this flow does not falsely claim that a prior model solves text-to-comics.

## Acceptance Criteria

### Must Have

1. **18-chapter coverage**: Given the current dataset, when the production run completes, then
   `work/bhagavadgita/` contains at least one non-empty `.comics` file for every logical chapter
   order 1 through 18, with no duplicate order standing in for a missing chapter.
2. **Valid documents**: Every output is a readable ZIP containing valid `data.json` and all assets
   it references; it opens through the current repository `.comics` loader without parse or
   missing-file errors and has positive canvas dimensions and at least one visible layer.
3. **Grounded content**: Every chapter file contains its dataset title and source-grounded chapter
   content. Any AI-produced summary, scene description, or dialogue is distinguishable from
   verbatim source text and links back to the input book/chapter/sloka IDs used to produce it.
4. **Complete source accounting**: A machine-readable manifest records all 18 chapters, selected
   edition/language, input row counts, output paths, checksums, validation results, generation mode,
   model/prompt versions when AI is used, and explicit warnings/failures.
5. **No silent fabrication**: If a stage cannot ground a statement or generate/import an asset, it
   uses a disclosed deterministic fallback or marks the item for review; it must not invent a
   quotation or silently claim unavailable artwork/audio came from the dataset.
6. **Read-only source**: No file below `dataset/bhagavadgita/` is created, modified, renamed, or
   deleted. All generated and intermediate material stays below `work/bhagavadgita/` (except
   tracked generator source/tests and SDD artifacts).
7. **Resumable and idempotent**: Re-running the generator with unchanged inputs/configuration does
   not create duplicate chapters or corrupt prior outputs. A failed chapter can be regenerated
   independently.
8. **Deterministic chapter mapping**: The generator derives 18 logical chapters from dataset
   relationships (`BookId`, chapter `Order`, and `ChapterId`), not filenames or a hardcoded guessed
   total.
9. **Format-safe reuse**: Reused positioning/animation/balloon rules are adapted through explicit
   interfaces and verified on generated output; Mahabharata metrics are not presented as Bhagavad
   Gita quality evidence.
10. **Real completion proof**: The final implementation report lists all 18 output files and their
    validation status, and includes at least one real editor/viewer open test rather than relying
    only on unit tests of the generator.
11. **Asset-first source recovery**: PSD hierarchy/alpha, Bodymovin assets/transforms, paired PDF
    compositions, and existing `.comics` layers are extracted before flattened-image segmentation
    or generation is attempted. The manifest records why each lower-fidelity fallback was used.
12. **Canonical asset graph**: every accepted visual asset has stable identity, provenance,
    semantic/art-stage metadata, review state, and a recoverable RGBA image plus true bitmap mask
    whenever it is a separable foreground object. Bboxes alone do not satisfy this criterion.
13. **Local segmentation training and evaluation**: a compact instance-segmentation candidate is
    trained/evaluated locally from PSD alpha, automated-consensus panorama labels, and explicitly separated
    Mahabharata support data. Data splits are source/scene-disjoint. A model ships only after
    beating the current U-Net/bbox path on mask, boundary, and independent automated visual metrics.
14. **Identity/type/style catalogue**: recovered regions can be grouped and corrected by canonical
    character/entity, object kind, scene/location, pose/expression/costume, and art stage/style.
    Automatic clustering remains reviewable; uncertain clusters are not silently merged.
15. **Paired sketch-to-colour pipeline**: the six coloured panorama pages are registered to their
    B&W counterparts where matches exist, producing paired training/evaluation crops. Colourization
    preserves ink geometry and canonical character palettes; generated anatomy/iconography changes
    are rejected.
16. **Explicit story-beat coverage**: each chapter is decomposed into required visual beats, and a
    coverage matrix records source assets, reusable assets, required transformations, missing
    generation, and approval. A page filename or a guessed one-page-per-chapter mapping is never the
    narrative model.
17. **Golden-chapter gate**: chapters 1 and 11 are developed first as complete production pilots.
    Expansion to all 18 starts only after both pass visual, narrative, lettering, format, device,
    and all six versioned automated review dimensions.
18. **Production visual density**: every final chapter has at least six approved visual beats in a
    coherent vertical-scroll composition. A text card, title card, or unprocessed panorama does not
    count as a visual beat for this gate.
19. **Exact production lettering**: balloon/caption geometry is retained as polygon or bitmap mask;
    multilingual text is deterministically shaped from authoritative strings before any learned
    hand-lettering texture/style is applied. Final lettering passes exact-string/OCR and automated
    readability/layout checks; an image model may not invent final word images unchecked.
20. **Controlled generative gap filling**: local generators and `gpt-image-2` are used only for
    explicit missing/repair/variant tasks with approved references and masks. Multiple candidates,
    identity/style ranking, input/output hashes, model/prompt lineage, and automated arbitration are
    required before a generated asset becomes release-eligible.
21. **Model competition, not forced reuse**: existing U-Net, Mask R-CNN, positioning, and animation
    artifacts may bootstrap/propose output, but known-underperforming or domain-shifted models are
    never mandatory. Rule, learned, and generative alternatives are evaluated against the same gold
    set; the best verified result wins, with optional human override recorded.
22. **Production QA and art-direction**: release candidates have automated checks for mask edges,
    halos, cross-tile duplicates, seams, overlap, ink preservation, identity/style consistency,
    exact lettering, viewport readability, archive validity, and runtime opening. Every chapter also
    requires recorded machine visual/cultural/editorial verification with source-cited evidence.
23. **Honest release status**: the existing 18 format-valid files remain useful regression fixtures
    but are not labelled production art. A chapter becomes production-complete only after all
    applicable gates above pass; partial progress is reported as such.

### Should Have

- Preserve all 663 Russian slokas in the chapter set, even when an AI-generated visual summary uses
  only a representative subset as foreground dialogue/captions.
- Render Sanskrit text/transcription alongside Russian translation in a reviewable, readable form.
- Preserve editable ink/flats/shadows/highlights as separate derived assets where source or model
  output makes this practical.
- Rank generative candidates automatically by identity/style/palette similarity before review.
- Reuse Bodymovin timing/camera/depth evidence through its separate approved flow without coupling the
  production path to unverified ad hoc formulas.
- Support local and external generation providers behind the same asset-task/review contract.
- Produce a human-readable report summarizing chapter coverage, source use, fallbacks, AI warnings,
  and visual/format validation.
- Provide asset, golden-chapter, selected-chapter, and all-18 execution modes.

### Won't Have (This Iteration)

- Training a foundation image model from scratch. Compact segmentation, classification,
  colourization, ranking, and style-transfer models are in scope.
- One-shot text-to-full-chapter generation with no source recovery, intermediate assets, or review.
- Treating existing bboxes, heuristic layouts, or model confidence as equivalent to art approval.
- Treating absent audio files as available merely because CSV paths are populated; audio embedding
  is out unless real media is provided or independently generated and clearly labeled.
- Modifying existing Mahabharata training data, model outputs, or generated libraries.
- Publishing generated comics, changing app-store assets, or uploading artifacts outside the local
  workspace.
- Uploading PSD/PDF/reference art or making paid API calls without separate explicit authorization.
- Claiming human theological/editorial approval from automated metrics. Autonomous output is
  explicitly labelled machine-verified and retains its source-citation evidence.

## Constraints

- **Output root**: `work/bhagavadgita/`.
- **Input root**: `dataset/bhagavadgita/`, read-only.
- **Chapter cardinality**: exactly 18 logical chapters in the current dataset.
- **Compatibility**: use the current `.comics` schema and 512px tiling conventions; avoid depending
  on unimplemented forward-looking schema fields.
- **AI execution**: prefer local execution for training, indexing, segmentation, colourization, and
  text understanding. External image generation remains separately authorized, cached, and audited.
- **Local hardware**: Apple M4 Max, 40-core GPU/Metal 4; compact model candidates must support a
  practical local training/inference path or provide a justified alternative.
- **Licensing**: model/framework licensing is a release gate. No production dependency is adopted
  merely because a checkpoint can be trained locally.
- **Cultural fidelity**: preserve diacritics, Sanskrit/Cyrillic Unicode, source order, and explicit
  provenance. Generated paraphrase must never be formatted as a verbatim verse.
- **Dirty worktree**: unrelated existing changes in the repository must be preserved.

## Production Requirement Defaults (Requirements approved)

1. **Primary edition**: Russian `BookId=1` for the first production set; other editions remain
   available as source/reference but do not multiply the deliverable to 108 files.
2. **Content strategy**: preserve all 663 Russian slokas in the 18 outputs; AI may additionally
   produce a clearly labeled chapter synopsis/storyboard and select representative lines for visual
   panels.
3. **Visual strategy**: build a reusable asset refinery and story-beat coverage matrix; complete
   chapters 1 and 11 as golden production pilots; then expand the accepted pipeline to all 18.
4. **Audio strategy**: record missing-media warnings and omit sounds from the package until actual
   media exists.
5. **Review strategy**: source text remains authoritative; every derived/generated visual asset and
   every final chapter has explicit review state and provenance.
6. **Generation strategy**: `gpt-image-2` and local generative tools fill explicit asset gaps; they
   do not replace source extraction or emit unchecked final lettering.
7. **Release strategy**: format validity is necessary but insufficient; production status requires
   automated visual QA, real-device opening, and human art-direction/cultural review.

## Open Questions

- [x] **Proposed defaults approved (2026-08-05)**: Russian-first, all 663 slokas preserved, and a
      text-forward fallback for chapters without artwork.
- [x] **Document granularity resolved by approval of the recommended default (2026-08-05)**: one
      continuous-scroll `.comics` document per logical chapter.
- [x] **Raster-art scope superseded (2026-08-09)**: Anton approved the asset-first production-art
      vision. Source recovery remains first priority; controlled AI generation of measured gaps is
      now part of the production path rather than optional decoration.
- [ ] **NEW (2026-08-09)**: which of the 12 `All_Black-n-White.pdf` pages (and 6 `All_Coloured.pdf`
      pages) correspond to which of the 18 known chapters, if any beyond the two plausible visual
      matches found (page 2 → Chapter 1, page 12 → Chapter 11)? Not resolved — 8 of 12 B&W pages
      weren't even visually reviewed in this pass. Real next step, not guessed.
- [ ] **NEW (2026-08-09)**: exact page-to-page correspondence between `All_Coloured.pdf`'s 6 pages
      and their `All_Black-n-White.pdf` counterparts — confirmed non-trivial (color page 2 matches
      B&W page 3, not page 2), full mapping not confirmed.
- [x] **RESOLVED (2026-08-09)**: horizontal-orientation rendering approach — an initial draft chose
      `.comics`' not-yet-implemented `scrollType: horizontal`; Anton explicitly rejected this in
      favor of the standard vertical-scroll convention everywhere, with the panorama treated as
      draft/source material to be AI-cut, AI-arranged, and AI-animated into a normal vertical strip.
      See `02-specifications.md`'s rewritten "Panoramic PDF Source" section.
- [ ] **Golden chapter beat count**: six approved visual beats/chapter is the proposed production
      floor; Specifications must define whether chapter-specific exceptions are allowed.
- [ ] **Segmentation implementation/license**: compare compact local instance-segmentation
      candidates after the license gate; do not hardcode YOLO11 or assume Ultralytics Enterprise.
- [ ] **Gold annotation budget**: Specifications must set the minimum manually corrected panorama
      masks and identity labels needed before a fair model comparison.
- [ ] **`gpt-image-2` authority**: separate paid-call and source-upload permission remains required
      even after this flow's Requirements are approved.

## References

- `flows/sdd.md`
- `flows/sdd-comics-ai-multimodal/`
- `flows/sdd-comics-ai-script-context/`
- `flows/sdd-comics-ai-positioning/`
- `flows/sdd-comics-ai-animations/`
- `flows/sdd-comics-ai-baloons/`
- `flows/vdd-comics-editor-ai-uiux/`
- `flows/vdd-comics-editor-systematization-uiux/`
- `flows/sdd-comics-editor-questions/`
- `flows/tdd-dot-comics-format/`
- `apps/comics-ai/comics-ai-multimodal/scripts/package.py`
- `dataset/bhagavadgita/`
- `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-bodymovin/` — the extracted Bodymovin camera-path/
  z-depth flow (2026-08-09), see that flow's own docs for the real Bodymovin-source findings
- `dataset/bhagavadgita/vaishnav/drawing/All_Black-n-White.pdf`, `All_Coloured.pdf` — the real
  panorama PDFs inspected directly for this addition (2026-08-09)

## Approval

- [x] Reviewed by user
- [x] Requirements approved on 2026-08-05 (`requirements approved`) — v0.1 baseline
- [x] v0.4 (2026-08-09): the Bodymovin camera-path/z-depth addition (v0.2-v0.3) was approved same-day
      ("reqs,specs and plan approved"), then extracted into its own flow per Anton's explicit
      instruction — see `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-bodymovin/` for that content's
      own approval record, carried over unchanged.
- [x] v0.6 panorama cut/arrange/animate draft rejected/superseded by the later production-art pivot;
      it must not be implemented as written.
- [x] v0.8 production vision approved on 2026-08-09 ("Утверждено именно твое видение"). This records
      the architectural direction and authorizes drafting these revised Requirements.
- [x] v0.8 Requirements formally approved on 2026-08-09 (`reqs approved`).
