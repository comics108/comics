# Requirements: comics-editor-ai-bhagavadgita-generator

> Version: 0.6 (2026-08-09, DRAFT, revises v0.5): real inspection of the two previously-unaudited
> PDFs (`All_Black-n-White.pdf`, `All_Coloured.pdf`) found in `dataset/bhagavadgita/vaishnav/
> drawing/`, per Anton's explicit request — see new "Panoramic PDF Source" section below and
> `02-specifications.md`. This is real, rich, hand-drawn artwork covering far more than chapter 5,
> materially changing the visual-strategy picture this flow's v0.1 Requirements were built on. New
> Must-Haves 11-13 below; Must-Have 12 revised in v0.6 after Anton rejected the v0.5 draft's
> horizontal-scroll premise in favor of standard vertical-scroll + AI-cut/arrange/animate. v0.4's
> extraction note is unchanged.
> Status: v0.4 APPROVED; v0.6 addition DRAFT
> Last Updated: 2026-08-09

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
- The only visual source files are three large PSDs under `vaishnav/drawing/`: `5_1.psd`,
  `5_2.psd`, and `app_BG._chiba5.psd`. Their names indicate chapter-5 material; no source artwork
  for the other 17 chapters is present.
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

**Note (2026-08-09)**: a real Lottie source also exists in the dataset
(`dataset/bhagavadgita/vaishnav/bhagavadgita_lottie/`), investigated and specified here 2026-08-09
then **extracted into its own flow**, `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-lottie/`, per
Anton's explicit instruction — see that flow for the full findings (camera-path/z-depth extraction),
not duplicated here.

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
  animals, architecture). This is genuinely the same caliber of hand-drawn artwork the Lottie
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
11. **Panoramic PDF art used where a real chapter mapping is confirmed (NEW, 2026-08-09)**: for
    every chapter whose corresponding panorama page is confirmed (by visual review, cross-check, or
    Anton's direct input — see Open Questions), that chapter's primary visual content comes from the
    real hand-drawn panorama, not a synthetic Chromium-rendered text card. Chapters without a
    confirmed mapping keep today's deterministic text-forward fallback — this criterion does not
    require guessing a mapping that isn't real.
12. **Correct AI-assisted composition into the standard vertical strip, not naive cropping/rotation
    (REVISED, 2026-08-09)**: the panorama pages are draft/source material, not a final layer —
    output stays the standard, universally-working vertical-scroll `.comics` convention (no
    unimplemented `scrollType`). Getting from panorama draft to final vertical page must go through
    real, already-trained/calibrated models this repo has (cutting via `comics-ai-multimodal`'s
    trained segmenter, arranging via `comics-ai-positioning`'s trained positioner, animating via
    `comics-ai-animations`' Mahabharata-calibrated reveal model) — not a hand-written rectangle-grid
    slice, and not a naive crop/rotate of the whole page. Per Anton's explicit correction
    ("используем везде именно vertical-scroll comic strip... нарезать нужно именно моделью а не
    прямоугольниками, срасставить и анимировать нужно тоже моделью"); see `02-specifications.md`'s
    rewritten "Panoramic PDF Source" section for the real tools, their real interfaces, and honestly
    disclosed limitations (domain-shift risk, the positioning model's own documented failure to beat
    its baseline, and the segmenters' rectangle-only mask supervision).
13. **Disclosed limitation on chapter-mapping confidence (NEW, 2026-08-09)**: the manifest/report
    states, per chapter, whether its panorama source was a confirmed match, an inferred/unconfirmed
    match, or absent (deterministic fallback used) — never silently presents an inferred guess as
    equivalent to a confirmed one.

### Should Have

- Preserve all 663 Russian slokas in the chapter set, even when an AI-generated visual summary uses
  only a representative subset as foreground dialogue/captions.
- Render Sanskrit text/transcription alongside Russian translation in a reviewable, readable form.
- Use the three PSD files (and, per the new Panoramic PDF Source section, the two panorama PDFs) to
  enrich chapters when a reliable extraction path is available, while keeping this non-blocking for
  any chapter where source art can't be reliably identified or extracted.
- Reuse the existing kind vocabulary (`background`, `character`, `balloon`, `art`) and established
  alpha/scale reveal behavior where it improves the document without compromising compatibility.
- Produce a human-readable report summarizing chapter coverage, source use, fallbacks, AI warnings,
  and visual/format validation.
- Provide a fast smoke mode for one selected chapter and a production mode for all 18 chapters.

### Won't Have (This Iteration)

- Training a new foundation image model or promising hand-drawn, publication-ready artwork for
  chapters where no real source art (PSD or panorama PDF) can be confirmed.
- Treating absent audio files as available merely because CSV paths are populated; audio embedding
  is out unless real media is provided or independently generated and clearly labeled.
- Modifying existing Mahabharata training data, model outputs, or generated libraries.
- Building a new editor batch-generation UI before the CLI/batch pipeline produces and validates
  the required 18 files.
- Publishing generated comics, changing app-store assets, or uploading artifacts outside the local
  workspace.
- Claiming theological/editorial approval of AI summaries; this flow produces reviewable drafts.

## Constraints

- **Output root**: `work/bhagavadgita/`.
- **Input root**: `dataset/bhagavadgita/`, read-only.
- **Chapter cardinality**: exactly 18 logical chapters in the current dataset.
- **Compatibility**: use the current `.comics` schema and 512px tiling conventions; avoid depending
  on unimplemented forward-looking schema fields.
- **AI execution**: prefer the existing local Ollama precedent for text understanding. No paid API
  or external publishing is assumed by these requirements.
- **Cultural fidelity**: preserve diacritics, Sanskrit/Cyrillic Unicode, source order, and explicit
  provenance. Generated paraphrase must never be formatted as a verbatim verse.
- **Dirty worktree**: unrelated existing changes in the repository must be preserved.

## Proposed Requirement Defaults (Awaiting Approval)

These defaults make the acceptance criterion achievable without pretending the missing art exists:

1. **Primary edition**: Russian `BookId=1` for the first production set; other editions remain
   available as source/reference but do not multiply the deliverable to 108 files.
2. **Content strategy**: preserve all 663 Russian slokas in the 18 outputs; AI may additionally
   produce a clearly labeled chapter synopsis/storyboard and select representative lines for visual
   panels.
3. **Visual strategy**: first guarantee 18 valid, readable, text-forward illustrated documents with
   deterministic visual fallbacks. Enrich chapter 5 from PSD artwork if technically reliable;
   net-new generative artwork for chapters 1–4 and 6–18 is an optional enhancement, not the
   completion gate.
4. **Audio strategy**: record missing-media warnings and omit sounds from the package until actual
   media exists.
5. **Review strategy**: generated summaries/storyboards remain drafts with provenance and warnings;
   source verse text remains the authoritative content.

## Open Questions

- [x] **Proposed defaults approved (2026-08-05)**: Russian-first, all 663 slokas preserved, and a
      text-forward fallback for chapters without artwork.
- [x] **Document granularity resolved by approval of the recommended default (2026-08-05)**: one
      continuous-scroll `.comics` document per logical chapter.
- [x] **Raster-art scope resolved by approval of the defaults (2026-08-05)**: net-new AI raster art
      is optional enrichment, not required in this iteration. Source-grounded typography and
      chapter-5 PSD enrichment are the scoped visual baseline.
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
- [ ] **NEW (2026-08-09)**: tiling window size/overlap for running `comics-ai-multimodal`'s
      segmenter (fixed 256×256 input) across a panorama up to ~93,524px wide, and the strategy for
      deduplicating regions that straddle tile boundaries — real, open engineering parameters, not
      decided in Specifications.
- [ ] **NEW (2026-08-09)**: whether wiring up the existing-but-unused `maskrcnn.pt` checkpoint for
      real inference is worth doing to get closer to true non-rectangular cutouts, given its own
      training used the same box-shaped mask supervision as the U-Net baseline — a real scope call
      for Anton, not decided here.

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
- `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-lottie/` — the extracted Lottie camera-path/
  z-depth flow (2026-08-09), see that flow's own docs for the real Lottie-source findings
- `dataset/bhagavadgita/vaishnav/drawing/All_Black-n-White.pdf`, `All_Coloured.pdf` — the real
  panorama PDFs inspected directly for this addition (2026-08-09)

## Approval

- [x] Reviewed by user
- [x] Requirements approved on 2026-08-05 (`requirements approved`) — v0.1 baseline
- [x] v0.4 (2026-08-09): the Lottie camera-path/z-depth addition (v0.2-v0.3) was approved same-day
      ("reqs,specs and plan approved"), then extracted into its own flow per Anton's explicit
      instruction — see `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-lottie/` for that content's
      own approval record, carried over unchanged.
- [ ] v0.5 (2026-08-09, Panoramic PDF Source) — awaiting approval. Real, disclosed limitations: only
      4 of 12 B&W pages visually reviewed; chapter-mapping mostly unconfirmed (2 plausible matches
      out of 18); horizontal-orientation rendering approach not yet decided (see
      `02-specifications.md`).
