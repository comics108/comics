# Specifications: comics-editor-ai-bhagavadgita-generator

> Version: 0.10 (2026-08-11, APPROVED by direct implementation instruction): autonomous-review
> addendum derived from Requirements v0.9. It supersedes every mandatory-human gate in v0.9 while
> retaining optional immutable human overrides.

> Version: 0.9 (2026-08-10, APPROVED): production asset-first specification derived from approved
> Requirements v0.8. Retains implemented Phases 1-9 as regression infrastructure, supersedes the
> unapproved v0.7 direct panorama/U-Net/positioner/heuristic-animation design, and defines the
> production asset refinery, gold evaluation, story-beat coverage, controlled generation, exact
> lettering, composition, review, and release contracts. v0.9 adds the content-verified semantic
> source-scope gate for Gita Dhyanam and chapter-5 PSD material discussed with Anton.
> Status: APPROVED — Anton: "$sdd resume ... Сохрани обсужденные детали и заапрувь" (2026-08-10)
> Last Updated: 2026-08-10
> Requirements: [01-requirements.md](./01-requirements.md) (v0.9 APPROVED)

## Autonomous Review Contract (v0.10, superseding)

Release states are now `fixture → draft → candidate → machine_verified_release`. `release` remains
an accepted backward-compatible alias for the last state. Promotion requires all six review
dimensions from versioned automated reviewers with input/output/checkpoint hashes; no human decision
is required. A reviewer may abstain, and abstention blocks promotion rather than inventing evidence.

Mask acceptance has two paths:

1. `native_alpha`: PSD/source alpha with checksum, reversible coordinates, non-empty coverage,
   non-rectangularity and boundary checks;
2. `automated_consensus`: panorama output from at least two independent method families among
   instance model, edge/matting, paired-registration, and foreground optimization. Two checkpoints
   trained from the same box-shaped labels count as one family. Default acceptance requires mask
   agreement IoU ≥ 0.85, boundary F1 ≥ 0.75, coverage in `(0.01, 0.95)`, rectangularity `< 0.98`,
   valid provenance, and a source-disjoint split.

Identity/style uses calibrated ensemble confidence and abstains below threshold. Cultural/editorial
verification is source-citation/scope/entity-rule consistency and is stored as
`machine_verified`, never “human approved”. Lettering requires exact normalized source equality and
independent OCR. Runtime/art-direction use deterministic geometry, viewport, collision, continuity,
palette/style, and artifact detectors. Optional human overrides append history but never unblock a
missing automated contract.

## Overview

Extend the existing Python application at
`apps/comics-ai/comics-ai-bhagavadgita-generator/` that reads the Bhagavad Gita CSV/PSD dataset,
normalizes the Russian edition into 18 canonical chapters, optionally derives a grounded local-LLM
storyboard, renders every source sloka into a readable continuous-strip card, packages one valid
`.comics` archive per chapter, and validates/reports the complete set under `work/bhagavadgita/`.

The implemented text-card path remains deterministic and source-grounded, but is now explicitly a
format/fidelity regression path. Production completion is owned by the asset-first pipeline below;
text cards cannot satisfy production visual or release gates.

## Architectural Decisions

1. **One canonical edition per production set**: use Russian `BookId=1`; the six-edition join is
   normalized in the loader but only the Russian rows are rendered in this iteration.
2. **One file per chapter**: exactly 18 continuous-scroll archives named by two-digit chapter order.
3. **Source text is authoritative**: every sloka becomes a rendered card in source order. AI output
   is additive and visually labeled as a synopsis, never substituted for a verse.
4. **Deterministic path is the release gate**: missing Ollama, invalid model JSON, unavailable PSD
   support, or absent audio cannot prevent the 18-file production run.
5. **External provenance, compatible archive**: detailed provenance lives in `manifest.json` and
   per-chapter intermediate JSON. `data.json` stays within the currently proven format surface.
6. **Atomic chapter publication**: render/package into a chapter staging directory, validate it,
   then replace the final `.comics` file atomically.
7. **Reuse by contract, not import accident**: small stable primitives may be extracted/reused from
   existing AI apps, but the generator does not reach into another app's gitignored `work/` output
   or depend on Mahabharata-specific paths.

## System Context

```text
dataset/bhagavadgita (read-only)
        │
        v
  Dataset loader ───> CanonicalChapter[18] ───> source checkpoints
        │                         │
        │                         ├──> optional Ollama storyboard ──┐
        │                         └──> deterministic synopsis ──────┤
        │                                                          v
        └──> optional chapter-5 PSD composite ─────────────> ChapterPlan
                                                                   │
                                                                   v
                                             HTML/browser card renderer
                                                                   │ PNG cards
                                                                   v
                                                layout + 512px tiling
                                                                   │
                                                                   v
                                                       .comics packager
                                                                   │
                                      ┌────────────────────────────┴────────┐
                                      v                                     v
                              archive validator                     editor-loader test
                                      │                                     │
                                      └──────────> manifest/report <─────────┘
```

## Repository Layout

Tracked source:

```text
apps/comics-ai/comics-ai-bhagavadgita-generator/
├── README.md
├── requirements.txt
├── scripts/
│   ├── models.py
│   ├── load_dataset.py
│   ├── build_storyboard.py
│   ├── import_psd.py
│   ├── render_cards.py
│   ├── layout_chapter.py
│   ├── tile_assets.py
│   ├── package_comics.py
│   ├── validate_output.py
│   ├── report.py
│   └── pipeline.py
└── tests/
```

Generated output:

```text
work/bhagavadgita/
├── chapter-01.comics
├── ...
├── chapter-18.comics
├── manifest.json
├── report.md
└── intermediate/
    ├── run-config.json
    └── chapter-XX/
        ├── source.json
        ├── storyboard.json
        ├── plan.json
        ├── validation.json
        └── rendered/
```

Temporary atomic-build directories live below `work/bhagavadgita/.staging/` and are retained on
failure for diagnosis but excluded from successful coverage counts.

## Canonical Data Model

### Source records

```python
@dataclass(frozen=True)
class SlokaSource:
    id: int
    chapter_id: int
    order: int
    name: str
    sanskrit: str
    transcription: str
    translation_ru: str
    comment_ru: str
    audio_ref: str
    sanskrit_audio_ref: str

@dataclass(frozen=True)
class CanonicalChapter:
    book_id: int
    chapter_id: int
    order: int
    title: str
    slokas: tuple[SlokaSource, ...]
```

CSV parsing rules:

- `db_books.csv` and `db_chapters.csv` use comma delimiters;
- `Gita_Slokas.csv` and `Gita_Vocabularies.csv` use semicolon delimiters;
- decode as UTF-8 with optional BOM (`utf-8-sig`);
- IDs and order fields must parse as positive integers;
- filter chapters to `BookId == 1`, then join `Gita_Slokas.ChapterId` to `db_chapters.Id`;
- sort chapters and slokas by numeric `Order`, using `Id` only as a deterministic tie-breaker;
- reject missing or duplicate chapter orders, duplicate sloka orders within a chapter, and empty
  Sanskrit/transcription/translation fields;
- assert the discovered set is exactly chapter orders 1–18 and the production set contains 663
  slokas. These are dataset-integrity checks, not hardcoded discovery logic.

All populated source fields, including commentary and unresolved audio references, are retained in
`source.json`. The rendered baseline shows the verse label, Sanskrit, transcription, and Russian
translation. Commentary remains available for review/provenance but is not rendered by default,
because it would dominate the visual document and is not required to preserve every sloka.

### Grounded storyboard

```python
@dataclass(frozen=True)
class StoryScene:
    scene_id: str
    title: str
    summary_ru: str
    source_sloka_orders: tuple[int, ...]
    characters: tuple[str, ...]
    location: str | None
    visual_prompt: str | None

@dataclass(frozen=True)
class ChapterStoryboard:
    schema_version: int
    mode: Literal["ollama", "deterministic"]
    model: str | None
    prompt_version: str
    chapter_summary_ru: str | None
    scenes: tuple[StoryScene, ...]
    warnings: tuple[str, ...]
    raw_model_output: str | None
```

The default local model is `qwen2.5-coder:32b`, reusing the model selected by real comparison in
`sdd-comics-ai-script-context`. Model selection remains configurable.

For long chapters, the builder chunks ordered Russian translations by a configurable token/character
budget, asks for grounded scene candidates per chunk, then performs a final merge. Each scene must
cite one or more existing sloka orders. A validator rejects:

- unknown chapter/sloka references;
- duplicate scene IDs;
- an empty or non-JSON response;
- text labeled as a quotation that is not an exact normalized substring of the cited source;
- a scene with no citations.

The raw model response, model name, prompt hash, and validation warnings are persisted. When Ollama
is unavailable, times out, or fails validation, the builder emits `mode="deterministic"`: no
synthetic summary, and ordered scene groups based only on contiguous sloka ranges. This is a normal
degraded mode, not a failed chapter.

`visual_prompt` is review metadata in this iteration. It is not sent to an external image service
and never implies that generated raster art exists.

## Chapter Plan and Visual Design

### Canvas

- width: `1080` px;
- vertical continuous strip;
- outer horizontal margin: `72` px;
- content width: `936` px;
- vertical gap between cards: `32` px;
- top/bottom safe area: `72` px;
- height: calculated from all laid-out assets, never guessed in advance;
- maximum height guard: fail the chapter with an actionable error before packaging if the computed
  height exceeds the safe 32-bit coordinate range.

### Layer sequence

1. chapter background (`kind="background"`), a deterministic generated texture/color field;
2. chapter title card (`kind="art"`), including chapter number and exact dataset title;
3. optional AI synopsis cards (`kind="art"`), visibly labeled `AI synopsis — draft` and carrying
   source-order citations in the rendered text;
4. optional chapter-5 PSD composite panels (`kind="art"`) when successfully imported;
5. one source verse card per `SlokaSource` (`kind="balloon"`) in exact order.

The use of `balloon` for verse cards intentionally reuses the existing text-content kind and its
alpha/scale animation precedent without claiming that each card is a speech balloon.

### Card rendering

Render semantic HTML to transparent/full-card PNG using headless Chromium/Playwright and bundled
Noto fonts, following `comics-ai-baloons`' proven complex-script renderer. The browser provides
Devanagari shaping, Cyrillic, Unicode normalization, and line wrapping consistently.

Each verse card contains:

- `Chapter.Order` + `Sloka.Order` label;
- exact `Text` (Sanskrit);
- exact `Transcription`;
- exact Russian `Translation`;
- a small source marker `book:chapter:sloka` derived from IDs.

Text is HTML-escaped. No source field may be interpreted as markup. Font sizes have documented
minimums; cards grow vertically rather than shrinking below the minimum or clipping content.
Rendered pixel bounds are measured and recorded in `plan.json`.

### Deterministic visual fallback

The theme derives colors and ornaments from the chapter order using a fixed palette and fixed seed.
It never needs network access or generated artwork. The result must remain readable in both the
editor canvas and current viewers.

### Chapter-5 PSD adapter

`import_psd.py` attempts read-only compositing of the three PSD inputs via `psd-tools`. Each
successful composite is resized to content width while preserving aspect ratio and inserted as an
`art` panel. Failure, excessive memory demand, or unavailable PSD support records a warning and
continues with the deterministic baseline. Original PSD files are never rewritten and extracted
composites live only under `work/bhagavadgita/intermediate/chapter-05/`.

## `.comics` Packaging Contract

Every final archive contains:

```text
data.json
layers/<asset-stem>_1000_<column>_<row>.png
```

Every raster layer is tiled into clipped 512×512 PNG tiles using the convention already proven by
`comics-ai-baloons` and `comics-ai-multimodal`:

```text
<asset-stem>_{scale1000}_{column}_{row}.png
```

The corresponding `data.json` layer uses:

```json
{
  "images": [
    {},
    {"file": "asset_{0}_{1}_{2}.png", "width": 936, "height": 640},
    {}
  ],
  "animations": [
    {
      "$type": "Comics.Editor.Models.TranslateAnim, Comics.Editor",
      "x": 72,
      "y": 1234
    }
  ],
  "kind": "balloon"
}
```

Format rules:

- `data.json` root contains integer `width`, integer `height`, `layers`, and empty `sounds`;
- image template paths are relative to `layers/` in the archive and contain no traversal segments;
- **Correction (2026-08-06, verified against real code and a real dataset file, not previously
  checked)**: the original draft put the rendered Russian card in image slot **0** and left 1/2
  empty. That is backwards. `apps/comics-editor/native/Comics.Editor/Models/Cultures.cs`'s real
  enum is `{En=0, Ru=1, Hi=2}`, and `Layer.GetImage` (`Layer.cs:55-59`) looks up
  `Images[CulturesHelper.All.IndexOf(culture)]` — pure positional lookup, no content inspection.
  A real dataset file's own balloon layer confirms this in practice: slot 0 is literally
  `"Text eng..."`, slot 1 is `"Text ru..."`, slot 2 is `{}` (spot-checked directly, not assumed).
  Putting Russian in slot 0 would make every current viewer/editor label it "English" while
  displaying Russian text — a silent semantic-labeling bug, not a crash, so it would have passed
  every structural/pixel validation check in this document without being caught. **Fixed here**:
  Russian goes in slot **1** (matching `Ru`'s real index); slot 0 (`En`) stays empty, same
  precedent as this dataset's existing files leaving `Hi` (slot 2) empty when no Hindi content
  exists yet — an empty slot for a missing language is already a normal, supported state, not a
  new pattern. Verified `GetImage`'s fallback (`Images[index]` if populated, else literally
  `Images.FirstOrDefault()` — the list's first element unconditionally, **not** "first populated
  slot") against this exact layout by simulating it directly: `GetImage(En)` → empty slot 0 (no
  English content, correctly renders nothing); `GetImage(Ru)` → slot 1, the real Russian card;
  `GetImage(Hi)` → falls back to `FirstOrDefault()` = slot 0 = empty (correctly renders nothing,
  not a stray Russian fallback). All three cases behave correctly with no residual risk;
- every layer has an explicit static `TranslateAnim` with integer `x`/`y`;
- no scale/alpha animation is required for baseline validity. An optional enrichment pass may add
  the proven balloon fade/grow-in pattern only after round-trip tests show no compatibility drift;
- no sounds are written because the referenced media is absent;
- ZIP entry order is deterministic (`data.json`, then lexically sorted tiles) and timestamps are
  normalized so identical inputs/configuration produce identical archive bytes and SHA-256 hashes;
- packaging first writes a staging file, validates it, then atomically replaces the final path.

**Note (2026-08-09)**: a Lottie camera-path/per-layer z-depth extraction design was drafted here and
then **extracted into its own flow**, `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-lottie/`, per
Anton's explicit instruction — see that flow for the full specification, not duplicated here.

## Production Asset-First Architecture (v0.8)

### Release levels

Every chapter and composition has one of four non-overlapping levels:

| Level | Meaning | May be called production? |
|---|---|---|
| `fixture` | Existing text-card/format regression artifact | No |
| `draft` | Incomplete/reviewable visual output with explicit gaps | No |
| `candidate` | Some automated dimensions still abstain or fail | No |
| `machine_verified_release` / `release` | Immutable artifact with every automated dimension passing | Yes |

The existing `work/bhagavadgita/chapter_*.comics` files remain `fixture`. Packaging or opening a
file successfully never promotes its release level.

### Component topology

```text
dataset/bhagavadgita (read-only)
        │
        ├── SourceInventory ── NativeSourceAdapters (PSD/PDF/Lottie/.comics/text)
        │                              │
        │                              ▼
        ├────────────────────── AssetStore + AssetGraph
        │                              │
        ├── AnnotationStore ── GoldDatasetBuilder ── ModelEvaluationRegistry
        │                              │
        ├── StoryBeatBuilder ── CoverageResolver
        │                              │
        ├── ActionRunner (local / external providers) ── CandidateStore
        │                              │
        ├── LetteringEngine ── CompositionEngine ── ReviewRegistry
        │                              │
        └────────────────────── ReleaseCompiler ── `.comics` validators/viewers
```

All generated state lives below `work/bhagavadgita/production/`. Tracked implementation remains
inside `apps/comics-ai/comics-ai-bhagavadgita-generator/`. Existing Phase 1-9 modules may be called
through adapters but their output formats are not the canonical production state.

### Work directory contract

```text
work/bhagavadgita/production/
├── inventory.json
├── sources/<source-id>/metadata.json
├── assets/<asset-id>/<version>/
│   ├── metadata.json
│   ├── rgba.png                 # when raster visual content exists
│   ├── mask.png                 # L/8-bit bitmap mask when separable
│   ├── contour.json             # optional derivative, never sole ground truth
│   └── preview.webp
├── entities/entities.json
├── annotations/<dataset-version>/
├── models/<model-id>/<version>/
├── evaluations/<evaluation-id>/report.json
├── story/chapter_<NN>/beats.json
├── story/chapter_<NN>/coverage.json
├── actions/<action-id>/action.json
├── candidates/<candidate-id>/
├── reviews/reviews.jsonl
├── compositions/chapter_<NN>/<version>/
└── releases/chapter_<NN>/<release-id>/
```

Paths are implementation details referenced through stable IDs. Metadata never relies on a path as
identity. Writes use staging + validation + atomic rename; immutable versions are never overwritten.

## Canonical Production Data Model

### `SourceRecord`

```python
@dataclass(frozen=True)
class SourceRecord:
    id: str
    kind: Literal[
        "structured_text", "manuscript", "psd", "pdf", "raster", "lottie",
        "audio", "comics", "font", "lettering_sample", "palette", "editorial_note"
    ]
    relative_path: str
    sha256: str
    byte_size: int
    media_type: str
    metadata: dict[str, JsonValue]
    semantic_scope_id: str
    parent_source_id: str | None = None
```

Inventory walks only configured source roots, records checksums and media facts, and never modifies
source files. Derived files are new `AssetVersion`s, not `SourceRecord` mutations.

`semantic_scope_id` resolves to an immutable reviewed record:

```python
@dataclass(frozen=True)
class SourceSemanticScope:
    id: str
    work: Literal["bhagavad_gita", "gita_dhyanam", "unclassified"]
    scope: Literal[
        "canonical_chapter", "canonical_verse_range", "standalone_prologue",
        "source_component", "unclassified"
    ]
    chapter_orders: tuple[int, ...]
    verse_ranges: tuple[tuple[int, int, int], ...]  # chapter, first verse, last verse
    mapping_state: Literal["confirmed", "inferred", "unmapped", "not_applicable"]
    evidence: tuple[str, ...]
    reviewer: str | None
```

Canonical chapter coverage accepts only `work="bhagavad_gita"` with a matching confirmed chapter
or verse-range scope. Standalone devotional material may be a separate release or reviewed style/
motion reference, but cannot be counted as a canonical chapter merely because a directory, cover,
or production layer contains a number.

### `Asset` and `AssetVersion`

```python
@dataclass
class Asset:
    id: str
    canonical_entity_ids: list[str]
    semantic_kind: Literal[
        "background", "environment", "character", "animal", "prop", "vehicle",
        "architecture", "fx", "ornament", "balloon", "caption", "lettering", "art"
    ]
    versions: list["AssetVersion"]

@dataclass(frozen=True)
class AssetVersion:
    version: int
    source_id: str
    source_region: tuple[int, int, int, int] | None
    rgba_file: str | None
    bitmap_mask_file: str | None
    contour_file: str | None
    width: int
    height: int
    art_stage: Literal["thumbnail", "sketch", "ink", "flat", "shaded", "final"]
    style_tags: tuple[str, ...]
    palette: tuple[str, ...]
    pose: str | None
    expression: str | None
    costume: str | None
    view: str | None
    allowed_transformations: tuple[str, ...]
    lineage: "Lineage"
    metrics: dict[str, float]
    review_state: Literal["proposed", "accepted", "rejected", "superseded"]
```

For separable foreground kinds, `rgba_file` and `bitmap_mask_file` are mandatory before acceptance.
The mask uses the asset canvas, 0 outside/255 inside with optional soft alpha retained separately in
RGBA. A contour is a compact derivative and may not replace the bitmap mask.

### Identity and classification links

`Entity` stores canonical ID, type, names/aliases/languages, iconographic attributes, and review
state. `AssetEntityLink` stores asset version, entity, role, confidence, method/model, and review.
Model proposals never mutate canonical identity directly. Merge/split creates auditable link/entity
revisions; rejected links remain in history.

### `StoryBeat` and `CoverageItem`

```python
@dataclass(frozen=True)
class StoryBeat:
    id: str
    chapter_order: int
    order: int
    title: str
    source_sloka_ids: tuple[int, ...]
    source_quote_ids: tuple[int, ...]
    synopsis: str
    required_entities: tuple[str, ...]
    required_actions: tuple[str, ...]
    required_location: str | None
    required_shots: tuple[str, ...]
    review_state: str

@dataclass
class CoverageItem:
    beat_id: str
    requirement: str
    state: Literal[
        "accepted_source", "reusable", "transformable", "generation_required",
        "waiting_for_review", "blocked", "rejected"
    ]
    asset_version_ids: list[str]
    proposed_action_ids: list[str]
```

Every chapter has at least six accepted beats by default. A project-level exception must name the
chapter, rationale, reviewer, and replacement quality criterion; it cannot silently lower the gate.

### `ModelAction`, `Candidate`, and lineage

Actions are immutable typed requests. Required fields: ID, action type, input source/asset versions,
constraints, expected output contract, provider/model/version, configuration, prompt/template hash
when applicable, authorization/budget record, and idempotency fingerprint. Supported action types
cover extraction/refinement, classification/retrieval, restoration, colourization, generation/edit,
lettering style, composition, animation/camera, and QA.

Each result is a separate `Candidate`; reruns do not overwrite older candidates. `Lineage` records
all input checksums, action ID, code revision, model/checkpoint, prompt/configuration, environment,
timestamp, cost/usage, and reviewer decisions.

### Reviews and release manifest

Review dimensions are independent:

- `technical`: files, masks, metrics, reproducibility;
- `identity_style`: character/iconography/style/palette consistency;
- `art_direction`: composition and visual finish;
- `lettering`: exactness, shaping, readability;
- `cultural_editorial`: chapter mapping and religious/narrative correctness;
- `runtime`: editor/viewer/device behavior.

Changing or superseding an upstream source, asset version, text, action, or composition invalidates
all dependent approvals through graph traversal. A release manifest contains exact accepted IDs,
checksums, gate results, and reviewer decisions and is immutable after creation.

## Source Recovery Adapters

### Semantic classification gate

Classification happens before assets enter story-beat coverage. The initial verified scope registry
contains:

| Source | Verified semantic scope |
|---|---|
| `bhagavadgita_lottie/unzip/1/` | `gita_dhyanam` / `standalone_prologue`; all 9 traditional stanzas in RU and EN; no canonical chapter mapping |
| `drawing/app_BG._chiba5.psd` | `bhagavad_gita` / `canonical_verse_range`; chapter 5, verses 5.14-5.29, confirmed from 15 sequential balloon/caption groups |
| `drawing/5_1.psd` | `bhagavad_gita` / `source_component`; component reproduced inside `app_BG._chiba5.psd`, attached to its chapter-5 parent scope |
| `drawing/5_2.psd` | `bhagavad_gita` / `source_component`; component reproduced inside `app_BG._chiba5.psd`, attached to its chapter-5 parent scope |

The registry records content evidence, not just these conclusions. Tests must fail if `unzip/1` is
assigned to chapter 1, if `S3_B1_C1` is treated as canonical numbering, or if `5_1`/`5_2` suffixes
are interpreted as verse numbers. Any future inferred mapping remains non-release until the
`cultural_editorial` review dimension confirms it.

### PSD adapter

`psd-tools` walks groups and pixel layers, preserving hierarchy, visibility, blend mode, opacity,
bbox, and alpha. Each meaningful pixel layer becomes a proposed asset with RGBA and a bitmap mask
derived from alpha. Groups remain graph relationships, not flattened assets unless explicitly
requested. Tiny/noise layers are retained in inventory but may be rejected by review; names such as
`Generative Fill` are provenance signals, not semantic labels.

The known real checkpoints are recorded: `5_1.psd` has 5 descendants/1 group, `5_2.psd` 32/6, and
`app_BG._chiba5.psd` 419/92. `app_BG._chiba5.psd` contains 15 sequential text groups covering
canonical verses 5.14-5.29; `5_1.psd` and `5_2.psd` are structurally reproduced as component groups
inside it. Inventory tests assert counts/checksums, parent/component relationships, and semantic
scope without modifying the files.

### PDF panorama adapter

Embedded images are extracted directly with Poppler tooling where possible rather than re-rendered
through a page canvas. The adapter records original dimensions/DPI/color profile. Production
processing uses overlapping multi-scale windows with global coordinates; it never creates a single
93k-wide in-memory RGBA copy unless a measured memory guard allows it.

Cross-window candidate instances are merged by mask overlap, embedding similarity, and global
geometry. Conflicts remain review candidates. The output is an instance mask/asset proposal, not a
fixed rectangle-grid slice.

### B&W/colour registration adapter

All 6 colour pages are matched against 12 B&W pages using global perceptual candidates followed by
local feature/geometry registration and mandatory human confirmation. Confirmed pairs produce
aligned crops plus an occlusion/invalid-pixel mask. Page number equality is never assumed.

### Lottie and `.comics` adapters

The Lottie adapter consumes the separate approved from-Lottie flow's verified parser contract and
recovers referenced images, transforms, timing, hierarchy, and audio/translation provenance. The
current `unzip/1` package is explicitly tagged as standalone Gita Dhyanam containing all 9 RU/EN
stanzas, not chapter 1 and not any other canonical chapter. Lottie asset-array order is not stanza
order. The adapter does not import unverified ad hoc camera formulas as gold truth.

The `.comics` adapter reconstructs tiled layers and imports transforms/animations/text slots as
training/reference evidence. Format/runtime fixtures are tagged separately from production-approved
art so existing output cannot contaminate release labels.

## Gold Annotation and Model Competition

### Gold v1 dataset

Before model promotion, Gold v1 must contain:

- at least 120 accepted foreground instances;
- at least 4 source-disjoint compositions: minimum 2 PSD-derived compositions and 2 panorama pages;
- at least 30 held-out instances from a composition absent from training;
- semantic kinds and canonical identity labels for all principal-character instances in the gold
  subset;
- corrected bitmap masks at source resolution or a documented review resolution with reversible
  mapping to source coordinates;
- reviewer identity and acceptance timestamp for every gold annotation.

PSD alpha creates proposed gold masks but still needs semantic/instance review. Box-shaped labels
and the current discarded connected-component masks are bootstrap data, never gold by default.

### Split policy

Train/validation/test split keys are source composition and narrative scene, not crop/tile. Adjacent
windows from one panorama cannot cross splits. Mahabharata support data is tagged as a separate
domain and no Gita evaluation claim may be computed from it.

### Segmenter promotion defaults

A compact local candidate is compared with the current U-Net connected-component path and any
licensed alternative under equal gold data/budget. Default promotion gates:

- mask IoU ≥ 0.75 on held-out accepted instances;
- boundary F1 ≥ 0.70;
- instance recall ≥ 0.85 at IoU 0.5;
- duplicate-instance rate after cross-window merge ≤ 3%;
- semantic-kind macro F1 not worse than the best baseline;
- zero release-blocking mask failures in human review of the golden chapters.

These are minimum defaults, not promises that a named architecture will pass. The model/framework
license must be approved for the intended production use. Apple MPS is the preferred local training
device; CPU fallback is required for deterministic smoke inference, not equal training speed.

### Other model gates

- Identity retrieval: principal-character top-1 ≥ 0.90 on the accepted gold subset, with uncertain
  results routed to review.
- Colourization: ink-edge preservation F1 ≥ 0.95 on held-out registered pairs, invalid-region mask
  excluded; palette error and human identity/iconography review must pass.
- Lettering: normalized authoritative string equals OCR/readback result on the test corpus; any
  mismatch is release-blocking regardless of visual score.
- Positioning/animation: compare rule/model/manual candidates on the same golden compositions;
  existing learned positioner and heuristic animation receive no privileged status.

Evaluation reports are immutable and include dataset version, split manifest, checkpoint hash,
environment, metrics, failures, and reviewer outcome.

## Story, Coverage, and Golden Chapters

`StoryBeatBuilder` creates a deterministic source-cited baseline from chapter/sloka structure and may
add a local-LLM candidate. LLM output is never authoritative text and every beat must cite source
row IDs. Review can edit beats while retaining original candidates.

Coverage resolution searches accepted source assets first, then reusable assets, then proposes
allowed transformations, and only then creates generation-required tasks. It ranks by entity,
action, location, art stage, style, palette, view, and provenance. Similarity alone cannot confirm a
chapter mapping or character identity.

Chapters 1 and 11 are golden pilots because current visual review suggests the strongest source
mappings (B&W page 2 and page 12 respectively). This is still a hypothesis until cultural/editorial
review accepts each mapping. If either mapping is rejected, the pilot chapter remains the same but
coverage records that source as rejected and fills the resulting explicit gaps through the normal
pipeline.

Expansion beyond the two pilots is blocked until both have:

- ≥6 accepted story beats;
- all foreground assets mask-accepted;
- all principal entities identity/style-approved;
- exact lettering approved;
- composition/art-direction/cultural review approved;
- `.comics` validation and real target-device opening approved.

## Transformation and Generation Providers

### Provider interface

```python
class ActionProvider(Protocol):
    def capabilities(self) -> ProviderCapabilities: ...
    def plan(self, action: ModelAction) -> ActionPlan: ...
    def execute(self, action: ModelAction, authorization: Authorization) -> list[Candidate]: ...
```

`plan` is side-effect-free and reports prerequisites, expected outputs, estimated resources/cost,
external uploads, and unsupported constraints. `execute` refuses missing/expired authorization.
Providers write only to action staging and never accept/promote their own candidates.

### `gpt-image-2` provider

The separate flow remains the source of API-specific prompting/caching/cost details. This pipeline
uses it for explicit actions such as masked repair, outpaint, missing pose/view/expression, sketch
polish, or a missing coverage asset. Default candidate count is 4 when supported and authorized;
the provider may return fewer with a disclosed reason.

Reference upload permission is source-specific. Paid-call permission is action-specific and bound to
a maximum cost. The provider stores no credential and produces no release asset directly. Prompts
request no baked textual lettering; any incidental generated text is rejected or removed before
asset acceptance.

### Local colourization

Colourization conditions on registered ink/line art and an approved palette/reference pack. Output
is decomposed where feasible into ink, flats, shadows, and highlights; at minimum it preserves the
original ink as a separate immutable source-derived asset. Anatomical, facial, costume, or
iconographic drift is a rejection, not a creative variant.

## Exact Lettering Contract

The lettering pipeline separates semantic text from style:

```text
authoritative string
  → Unicode normalization + script/language metadata
  → HarfBuzz-compatible shaping and line breaking
  → exact glyph/stroke bitmap mask
  → optional learned hand-lettering texture/distortion
  → composite into accepted TextRegion
  → OCR/readback + visual review
```

An existing balloon's safe interior bitmap mask and erased-text mask are retained rather than
collapsed/discarded. `TextRegion` defaults to bitmap-mask truth with optional simplified polygon.
When no balloon exists, a separate candidate task selects an approved template or creates a reviewed
shape; the engine never silently inserts a generic balloon.

OCR equality compares normalized text while retaining punctuation/script-specific rules. OCR is a
guard, not a source of authoritative replacement text. Complex scripts require shaping-capable
rendering; plain Pillow text drawing is insufficient.

## Composition, Animation, and Camera

The vertical strip is composed from accepted story beats/assets. `CompositionCandidate` stores
viewport width, canvas dimensions, placements, masks, transforms, z-order/depth, beat order,
lettering, animations, camera proposal, method lineage, and quality results.

Candidate sources may be deterministic rules, learned models, Lottie evidence, manual templates, or
human edits. All candidates pass bounds, overlap/occlusion, mask edge, reading order, viewport, and
runtime checks. Human edits create a new version; they do not destroy model evidence.

`cameraPath` and animations are optional until supported consistently by target readers. Their
absence cannot block a visually complete static composition; invalid/unsupported animation cannot
be silently packaged. The separate Lottie flow may provide evidence after its own verification.

## Review State Machine

```text
proposed → in_review → accepted
                    ↘ rejected
accepted → superseded       # dependency changed or better version accepted
accepted → revoked          # explicit reviewer decision
```

Acceptance records dimension, actor, timestamp, reason, and exact object version. Required review
dimensions are configurable but golden releases require all six dimensions defined above. Any
upstream version change traverses dependencies and marks affected downstream approvals/release
candidates stale; immutable prior releases remain historically valid but are not silently rebuilt.

## Production Validation and Release

Automated release checks include:

- source and lineage checksum completeness;
- accepted mask presence, dimensions, alpha agreement, boundary/halo checks;
- duplicate/seam/cross-window merge checks;
- identity/style/palette consistency and unresolved-cluster checks;
- story-beat count/order/source citations and coverage closure;
- exact lettering, shaping, contrast/readability, and no unreviewed generated text;
- composition bounds, overlap/occlusion policy, reading order, viewport snapshots;
- `.comics` schema, path safety, tile reconstruction, slot mapping, checksum and archive integrity;
- current editor/viewer loader tests and a real open on each release-target device class.

The compiler consumes only accepted immutable versions and writes to release staging. A failed gate
leaves a report and no production release. A successful release contains `.comics`, manifest,
validation report, review summary, thumbnails, and checksums, then is atomically published inside
`work/bhagavadgita/production/releases/`.

## Production Dependencies and Isolation

- Core metadata/orchestration: Python standard library plus the existing app's typed dataclasses and
  JSON/ZIP/checksum infrastructure.
- Raster/source adapters: Pillow, `psd-tools`, Poppler commands already present, and OpenCV where
  registration/mask processing is required.
- Local ML: isolated torch/vision environment with Apple MPS support and CPU smoke inference.
  Architecture/framework packages are optional plugins selected only after license/evaluation.
- Embeddings/indexing: provider-neutral interface; concrete local model and vector index are a Plan
  checkpoint, with raw embeddings versioned and rebuildable.
- Lettering: shaping-capable renderer (HarfBuzz/Pango or equivalent) and existing browser renderer
  only where it proves exact complex-script behavior; Playwright screenshots are not visual art.
- External image generation: isolated provider adapter owned by the separate `gpt-image-2` flow;
  absent credentials/authority leave actions blocked, never downgraded to an implicit paid call.
- Review tooling: file/JSON review manifests are the minimum implementation; editor/backend UI may
  consume the same contract but is not required to define truth.

Each heavy adapter runs behind a subprocess/provider boundary so a missing dependency or model crash
fails only its action and cannot corrupt the asset graph. Dependency availability is reported by a
capabilities command before orchestration.

## Cross-Flow Backend TDD Contract

The future backend must expose equivalent resource/state behavior from
`flows/comics-backend/tdd-comics-backend-endpoints-v2026-ai/01-requirements.md` v0.3. During this SDD
flow, every new production behavior contributes a case to that TDD's cases-first backlog:

- native-source recovery precedes flattening;
- bbox-only foreground asset cannot be accepted;
- source/scene-disjoint model evaluation and promotion;
- beat coverage prevents generation when accepted lower-tier art exists;
- paid/upload authorization and idempotent multi-candidate generation;
- exact lettering failure blocks release;
- upstream revision invalidates dependent approvals;
- format-valid draft cannot become production release;
- job cancellation/restart/retry preserves lineage and avoids duplicate paid calls.

Per `flows/tdd.md`, these cases are written to `02-tests.md` only after that TDD's Requirements v0.3
receive their own explicit approval; they are not silently treated as approved Specifications here.

## Requirements Traceability (v0.8 production addition)

| Requirement | Specification ownership |
|---|---|
| MH11 source recovery | Source Recovery Adapters; `SourceRecord`/lineage |
| MH12 canonical asset graph/masks | `Asset`/`AssetVersion`; Work directory contract |
| MH13 local segmentation evaluation | Gold Annotation and Model Competition |
| MH14 identity/type/style catalogue | Identity and classification links |
| MH15 sketch-to-colour | B&W/colour registration; local colourization; model gates |
| MH16 story-beat coverage | `StoryBeat`/`CoverageItem`; Story, Coverage, and Golden Chapters |
| MH17 golden chapters | Golden Chapters scale-out gate |
| MH18 ≥6 visual beats | Story-beat schema and configurable exception contract |
| MH19 exact lettering | Exact Lettering Contract; lettering promotion gate |
| MH20 controlled generation | Provider interface; `gpt-image-2` provider; Candidate/Lineage |
| MH21 model competition | Gold datasets, split policy, promotion defaults |
| MH22 production QA/review | Review State Machine; Production Validation and Release |
| MH23 honest release status | Release levels and immutable release manifest |
| Semantic source correctness | `SourceSemanticScope`; classification gate; cultural/editorial review |

## SUPERSEDED: Panoramic PDF Source — direct AI Cutting/Positioning/Animation draft

Answers Requirements' new Must-Haves 11-13, and Anton's direct request for a rendering plan for all
18 chapters "включая camera и z-depth". Source: `dataset/bhagavadgita/vaishnav/drawing/
All_Black-n-White.pdf` (12 pages) and `All_Coloured.pdf` (6 pages), real findings in Requirements'
new section above.

**Revision history on this section**: a first draft (2026-08-09, same day) proposed
`scrollType: horizontal` to preserve the panorama's native orientation untouched. Anton explicitly
rejected this: *"Нет, используем везде именно vertical-scroll comic strip, арт дан в виде драфта,
нужно его скомпоновать правильно и нарезать с учетом ИИ и обученной модели"* — the panorama pages are
**draft/source material**, not final layers; the format stays the standard, universally-working
vertical-scroll `.comics` convention everywhere, and getting from draft panorama to final vertical
page is real AI work (cutting, arranging, animating), not a schema choice. Anton then further
sharpened this: *"Это только драфты не упрощай себе задачу, нарезать нужно именно моделью а не
прямоугольниками, срасставить и анимировать нужно тоже моделью которая предобучена на реальных
данных mahabharata"* — cutting, arranging, and animating must each go through the real trained
models this repo already has (not a hand-rolled bbox-grid heuristic), and arranging/animating
specifically the ones **pretrained on real Mahabharata data**. This section is a full rewrite under
that constraint, not a patch.

### Architecture decision: vertical-scroll strip, draft panorama → AI cut → AI arrange → AI animate

The pipeline has four real stages, each explicitly required to go through an existing, already-
trained/calibrated model from this repo rather than new bespoke heuristics:

1. **Render** the panorama page to a raster image (`pdftoppm`, unchanged from the withdrawn draft).
2. **Cut**: segment the panorama into individual figures/elements using `comics-ai-multimodal`'s real
   trained segmenter, not manual rectangle slicing.
3. **Arrange**: lay the cut regions out into a vertical reading order/position using
   `comics-ai-positioning`'s real trained positioner (residual model on top of its calibrated
   baseline), reusing the exact model this repo already trained on real Mahabharata ground truth.
4. **Animate**: assign reveal animations (and derive `cameraPath`) using `comics-ai-animations`'
   Mahabharata-ground-truth-calibrated reveal model, not a from-scratch density heuristic.

Each stage below documents the real tool being reused, its real interface, and — honestly, per this
flow's own established disclosure standard — the real limitations found while inspecting it, since
"use the model" does not mean these models are free of known gaps.

### Stage 1 — Cutting: `comics-ai-multimodal`'s trained segmenter, tiled over the panorama

**Real tool, confirmed by direct inspection this session**: `apps/comics-ai/comics-ai-multimodal/
scripts/infer_segmenter.py` — `load_model()` loads a real trained `UNetBaseline` checkpoint at
`work/comics-ai-multimodal/models/unet_baseline.pt`; `infer_regions()` runs real per-pixel semantic
segmentation (softmax → argmax over `dataset.KIND_TO_LABEL` classes → per-class
`cv2.connectedComponents` → bbox per component, `MIN_REGION_AREA=200`). `segment_image.py` wraps this
as a real single-ad-hoc-image entry point (`run(image_path, checkpoint_path, device)`, NDJSON
event protocol), already built and used by the Dart editor's own Cutting mode — the correct,
already-existing tool to call rather than re-implementing region proposal.

**Real, disclosed limitation on "not rectangles"**: the segmenter's own training data has **no
per-pixel mask ground truth** — confirmed by reading `segmenter_models/maskrcnn.py`'s own docstring
("Ground truth is rectangle-only everywhere in this pipeline... a documented approximation, not an
oversight"). The U-Net path (the only one with a wired inference script) does produce a genuine
per-pixel class map internally, and the *proposal* of where a region is comes from real pixel
classification + connected components (not a hand-drawn rectangle grid) — but the artifact each
region resolves to downstream is still an axis-aligned bbox crop, because that's what every
consumer of `CutRegion`/`infer_regions_with_crops` expects today. A second checkpoint exists —
`work/comics-ai-multimodal/models/maskrcnn.pt`, trained via `train_segmenter.py` on
`segmenter_models/maskrcnn.py` (torchvision Mask R-CNN, real instance masks architecturally) — but
**has no wired inference script anywhere in this repo today** (`infer_segmenter.py` only ever loads
`UNetBaseline`), and its own mask supervision was the same box-shaped ground truth, so it would not
actually yield pixel-accurate irregular cutouts even if wired up. **Conclusion, stated plainly**: the
real model-driven region *proposal* (which pixels belong to which figure, via real learned pixel
classification) satisfies "not a hand-written rectangle heuristic," but pixel-accurate non-rectangular
*cutout edges* are not available from any currently-wired model in this repo — achieving that would
need new work (new mask ground truth, and wiring `maskrcnn.pt` for inference), out of scope here
unless Anton wants it added as a separate task.

**Real technical adaptation needed — tiling**: `infer_regions` resizes its whole input to a fixed
`TRAIN_SIZE = (256, 256)` before inference. A panorama page up to ~93,524px wide fed in directly would
collapse to a useless 256px-wide smear — nothing like the model's real training distribution (single
already-reasonably-sized page photos). `import_panorama.py`'s cutting step must instead **slide a
window across the panorama** (real window size TBD by experiment against the model's real training
image scale — Plan task, not decided here), call `infer_regions_with_crops` per window, map each
window-local bbox back to panorama-global coordinates, and **deduplicate regions that straddle window
boundaries** (a real, open problem — flagged below, not solved by assumption).

**Real, carried-forward domain-shift risk** (already flagged in this flow's own Existing AI Flow
Audit table): the segmenter was trained on `DEFAULT_LOWCAMERA_DIR` — photographed Mahabharata comic
pages — not dense hand-drawn Bhagavad Gita panorama line art. Region proposals here are a real,
unverified transfer; the manifest must disclose this per chapter (extends Must-Have 13).

### Stage 2 — Arranging: `comics-ai-positioning`'s trained residual model

**Real tool, confirmed by direct inspection**: `apps/comics-ai/comics-ai-positioning/scripts/
infer_positioner.py` — `load_model()` loads a real trained artifact, confirmed present on disk at
`work/comics-ai-positioning/positioner_model.joblib`; `position_page_with_model()` runs
`baseline_position.position_page()` first, then adds a learned per-region y-residual
(`final_y = baseline_y + predicted_residual`) from a model trained on real Mahabharata ground truth
(`positioning_bridge.py` reads `work/canvas/*.gt.json` and `work/alignment.jsonl`, materialized from
`comics-multimodal`'s real aligned Mahabharata pages). This is the real "model pretrained on real
Mahabharata data" Anton asked for arranging.

Each panorama page's cut `CutRegion`s become that page's `RegionFeatures` input (`kind`,
`local_bbox`, `reading_order_index` — reading order derived from the regions' real horizontal
position in the panorama, left-to-right, which is the panorama's own real narrative sequence per
every page visually reviewed so far) and `position_page_with_model` returns real per-region
`(x, y)` placement for a normal vertical `.comics` canvas.

**Real, disclosed finding this flow must not paper over**: `sdd-comics-ai-positioning`'s own
`_status.md` records that this exact learned model was evaluated honestly against its own calibrated
baseline and **did not beat it** ("Phase 5 (learned model) built and evaluated for real — does not
beat baseline, even after a refit"). Per Anton's explicit instruction we use the learned model anyway
(not the baseline it lost to) — a real, disclosed deviation from that sibling flow's own
recommendation, made on Anton's direct call, not silently presented as though the model were proven
superior. The manifest/report must carry this caveat forward per chapter that used it.

### Stage 3 — Animating and `cameraPath`: `comics-ai-animations`' Mahabharata-calibrated reveal model

**Real tool, confirmed by direct inspection**: `apps/comics-ai/comics-ai-animations/scripts/
baseline_transform.py`'s `propose_reveal(kind, stats)`, calibrated by `transform_stats.py` against
real ground-truth transform statistics mined from real Mahabharata episodes (`build_transform_pairs.py`
→ `transforms_bridge.py`, which bridges live into `comics-multimodal`'s `resting_position.
resolve_reveal_animation`). **Honest caveat**: unlike the positioner, this repo has **no trained
model with learned weights** for animation — only this real, ground-truth-calibrated statistical
baseline (occurrence/duration stats per `kind`, evaluated file-wise held-out in `evaluate_transforms.
py`). It is the closest, and only, real artifact in this repo matching "model pretrained on real
Mahabharata data" for animation, so it is what gets reused here — stated plainly as calibrated
statistics, not literally trained weights, so the manifest doesn't overclaim.

For each vertically-arranged region, `propose_reveal(region.kind, stats)` yields real per-property
reveal proposals (occurs-or-not, direction where applicable, duration) which map directly onto
`.comics` `TranslateAnim`/`AlphaAnim` keyframes at that region's arranged `(x, y)`.

`cameraPath` is then derived from the same real per-region reveal timing/order (not raw panorama
pixel-column density, which only made sense over the untouched horizontal source): a virtual vertical
pan whose speed is inversely proportional to local reveal density (more regions revealing/animating
in a given vertical span ⇒ camera lingers there ⇒ more scroll distance allotted), built the same way
the withdrawn draft's density algorithm worked, just over the vertically-arranged layout's real region
positions instead of raw pixel columns — same chained `{start, end, x, y}` `cameraPath` schema shape,
now with real `y` motion instead of the withdrawn draft's `y: 0`-only pan.

### Stage 4 — Recomposition: reuse `layout_chapter.py`, not a new layout engine

The arranged, animated regions become ordinary `.comics` layers assembled the same way
`layout_chapter.py` already assembles a chapter's vertical strip today (Phase 3) — this stage adds no
new layout code, only a new *source* of layers (AI-cut/arranged panorama regions instead of
Chromium-rendered verse cards) feeding the same existing assembly path.

### Z-depth — now core, not an enrichment tier

Because every chapter using this source now goes through real per-region extraction (Stage 1) as the
baseline, not an optional add-on, non-uniform per-layer `zDepth` is available for every such chapter,
not gated behind a separate enrichment decision. **Heuristic unchanged from the withdrawn draft**:
`zDepth` derived from each region's own size and vertical position in the *arranged* layout — larger
and/or lower-positioned regions read as nearer (lower/negative `zDepth`), smaller/higher regions read
as farther (higher/positive `zDepth`) — still a real, disclosed heuristic approximation, not verified
against the artist's actual intended depth (Open Design Question, unchanged).

### Extraction pipeline

```python
# scripts/import_panorama.py -- NEW

def render_pdf_page(pdf_path: Path, page: int, dpi: int) -> Image:
    """Unchanged from the withdrawn draft -- shells out to pdftoppm (poppler, already installed)."""

@dataclass(frozen=True)
class ChapterMapping:
    chapter_order: int          # 1-18
    pdf: str                    # "black_and_white" | "coloured"
    page: int                   # 1-indexed real PDF page
    confidence: str             # "confirmed" | "inferred" | "unmapped"

CHAPTER_MAPPING: list[ChapterMapping] = [
    # Unchanged from the withdrawn draft -- only 2 real, visually-grounded entries; the rest remain
    # "unmapped" pending Plan's chapter-mapping-resolution task (below), not invented here.
    ChapterMapping(chapter_order=1, pdf="black_and_white", page=2, confidence="inferred"),
    ChapterMapping(chapter_order=11, pdf="black_and_white", page=12, confidence="inferred"),
]

def cut_panorama_regions(image: Image, tile_width: int, tile_overlap: int) -> list[CutRegion]:
    """Slides a window across the panorama, calls comics-ai-multimodal's infer_regions_with_crops
    per window (real trained UNetBaseline), maps window-local bboxes to panorama-global coordinates,
    and deduplicates regions straddling window boundaries. See Stage 1 above -- tile_width/overlap
    and the dedup strategy are real, unresolved Plan-level parameters, not assumed here."""

def arrange_regions_vertically(regions: list[CutRegion]) -> list[PositionProposal]:
    """Calls comics-ai-positioning's real infer_positioner.position_page_with_model against the cut
    regions, reading_order_index derived from each region's original horizontal panorama position.
    See Stage 2 above."""

def animate_arranged_regions(regions: list[PositionProposal]) -> list[dict]:
    """Calls comics-ai-animations' baseline_transform.propose_reveal per region kind, mapping the
    result onto TranslateAnim/AlphaAnim keyframes at the region's arranged position. See Stage 3."""

def build_camera_path_from_reveal_density(animated_regions: list[dict], document_scroll_height: int) -> list[dict]:
    """See Stage 3 -- same principle as the withdrawn draft's pixel-density algorithm, now driven by
    arranged-region reveal density over the vertical layout instead of raw horizontal pixel columns."""

def derive_layer_z_depth(region_bbox: tuple[int, int, int, int], layout_size: tuple[int, int]) -> float:
    """See "Z-depth -- now core, not an enrichment tier" above."""
```

### Chapter-mapping resolution — disclosed, not guessed

Unchanged from the withdrawn draft: `CHAPTER_MAPPING` ships with only the 2 real, visually-grounded
entries found in Requirements — not a complete, invented 18-entry table. Resolving the rest is real,
separate Plan work (full manual/Anton-reviewed pass, or a local-Ollama-assisted visual-similarity
pass per `sdd-comics-ai-script-context`'s precedent) — still an Open Design Question, not decided
here. `confidence` must carry through to the manifest verbatim per chapter (Must-Have 13);
`"confirmed"` only ever set by explicit human review.

### Data Models

```json
{
  "width": 1080,
  "height": 1920,
  "layers": [
    {
      "images": [{}, {"file": "ch01_region_014.png", "width": 812, "height": 1104}, {}],
      "animations": [{"$type": "Comics.Editor.Models.TranslateAnim, Comics.Editor", "x": 0, "y": 640}],
      "zDepth": -0.3,
      "kind": "character"
    },
    {
      "images": [{}, {"file": "ch01_region_015.png", "width": 340, "height": 288}, {}],
      "animations": [{"$type": "Comics.Editor.Models.TranslateAnim, Comics.Editor", "x": 0, "y": 1310}],
      "zDepth": 0.6,
      "kind": "art"
    }
  ],
  "cameraPath": [
    {"start": 0, "end": 640, "x": 0, "y": 640},
    {"start": 640, "end": 1310, "x": 0, "y": 1310}
  ],
  "sounds": []
}
```

`scrollType` is intentionally **absent** (defaults to `"vertical"`, per `tdd-dot-comics-format`) —
this is the whole point of the correction: no new, unimplemented reader capability is required.
`width`/`height` follow the existing chapter canvas convention (Specifications' existing Canvas
section), unaffected by this addition. `cameraPath` now carries real, non-zero `y` motion (unlike the
withdrawn draft's X-only pan), matching a genuinely vertical document.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| A chapter has no confirmed or inferred page mapping | Most chapters, per the real 2-of-18 finding above | Falls back to today's deterministic text-forward Chromium-rendered card path unchanged — Must-Have 11's own explicit requirement |
| Cut regions from adjacent tiling windows overlap/duplicate the same figure | Expected for any figure that straddles a tile boundary, given the panorama's real width vs. the segmenter's fixed input size | Must be deduplicated before arranging (real, open Plan-level problem — not solved by assumption here) |
| The segmenter finds zero regions on a page (domain-shift failure, not just low confidence) | Real, disclosed possibility given the unverified Mahabharata→Gita transfer | Chapter falls back to the deterministic text-forward path, same as an unmapped chapter — not a hard pipeline failure |
| The positioning model's residual pushes a region off-canvas or overlapping another | Not yet observed for this source (never run against panorama-derived regions) | Needs a real bounds/overlap clamp — analogous to `baseline_position.py`'s own existing bounds handling — flagged for Plan, not assumed safe |
| Rendering a page at production DPI produces an excessively large raster (pages up to ~108in wide) | Real, confirmed risk given real file sizes already observed (up to 622MB for the 12-page PDF) | Needs a real memory/tile-count bound, analogous to the chapter-5 PSD adapter's own handled-failure mode — not yet measured for this source, flagged for Plan |

### Testing Strategy

- [ ] Unit: `render_pdf_page` against a small real crop/test fixture (not the full 622MB file)
- [ ] Unit: `cut_panorama_regions`'s tiling + dedup against a synthetic multi-tile image with a known
      figure straddling a tile boundary, asserting it yields one region, not two
- [ ] Unit: `arrange_regions_vertically` against a small known set of `CutRegion`s, asserting output
      matches direct calls into `comics-ai-positioning`'s own `position_page_with_model`
- [ ] Unit: `animate_arranged_regions` against known region kinds, asserting output matches direct
      calls into `comics-ai-animations`' own `propose_reveal`
- [ ] Unit: `build_camera_path_from_reveal_density` against synthetic arranged regions with known
      reveal density, asserting the remapped curve concentrates scroll distance in dense spans
- [ ] Unit: `derive_layer_z_depth` against known bbox/position combinations
- [ ] Integration: end-to-end render of the one confirmed-plausible chapter (Chapter 1, page 2) once
      `CHAPTER_MAPPING`'s entries are upgraded from `"inferred"` to real
- [ ] Manifest/report: assert disclosed-confidence text, domain-shift caveat, and the positioning
      model's own "did not beat baseline" caveat all appear for every affected chapter (Must-Have 13)

### Open Design Questions

- [ ] Manual vs. Ollama-assisted chapter-mapping resolution — not decided.
- [ ] Tiling window size/overlap for Stage 1 cutting, and the region-dedup strategy across tile
      boundaries — real, unresolved engineering parameters, not decided here.
- [ ] Production rendering DPI and the resulting tile-count/memory bound — not yet measured.
- [ ] Whether wiring up `maskrcnn.pt` for real inference (currently unwired anywhere in this repo)
      is worth doing to get closer to true non-rectangular cutouts, given its own mask supervision
      was also box-shaped — a real scope call for Anton, not decided here.
- [ ] Whether `cameraPath`'s reveal-density derivation should also directly inform per-region
      `zDepth` (regions the camera lingers on could plausibly also be "foreground") — a real,
      unexplored connection between the two mechanisms, not assumed.

## Legacy Phases 1-9 Regression Contract

Everything from this heading through the pre-v0.8 Manifest/CLI/validation/dependency sections below
documents the already-implemented deterministic fixture pipeline. It remains authoritative for
regression behavior only. Statements such as “text-forward output is sufficient,” “no segmentation
dependencies,” or “never upload” do **not** define production release behavior and are superseded by
the v0.8 architecture, provider authorization, mask, review, and release gates above.

## Manifest Contract

`manifest.json` uses a versioned root:

```json
{
  "schema_version": 1,
  "dataset_fingerprint": "sha256:...",
  "config_fingerprint": "sha256:...",
  "book_id": 1,
  "language": "ru",
  "expected_chapters": 18,
  "expected_slokas": 663,
  "chapters": []
}
```

Each chapter entry records:

- chapter order, dataset chapter ID, exact title, and source sloka count;
- source-record ID/order range;
- output path, byte size, SHA-256, layer count, width, and height;
- storyboard mode/model/prompt hash;
- PSD inputs used, if any;
- audio references omitted count;
- structural, pixel, and editor-loader validation states;
- warnings and failure details.

A chapter counts toward coverage only when `status="valid"`, its file exists, its hash matches, and
all required structural/pixel checks pass. A stale file from an earlier run never counts when its
dataset/config fingerprints differ.

## Pipeline CLI

Primary commands:

```text
python scripts/pipeline.py --chapter 1 [--no-ai] [--no-psd] [--force]
python scripts/pipeline.py --all [--no-ai] [--no-psd] [--force]
python scripts/validate_output.py --all
```

Behavior:

- exactly one of `--chapter N` or `--all` is required;
- `--chapter` is the smoke/debug path and writes the same production format;
- `--no-ai` selects deterministic storyboard mode explicitly;
- `--no-psd` skips the optional adapter explicitly;
- an unchanged, already-valid chapter may be reused unless `--force` is set;
- the batch continues after an individual chapter failure and returns non-zero if final valid
  coverage is less than 18;
- logs never print full comments/source text by default; they report IDs/counts and safe summaries;
- the final CLI summary prints `valid/expected`, failed chapter orders, and manifest/report paths.

## Validation Strategy

### Dataset checkpoint

- 6 books;
- 108 chapter rows;
- 18 unique logical orders;
- Russian `BookId=1` has 18 chapters and 663 slokas;
- every rendered field is non-empty and ordered uniquely.

### Structural archive validation

For every chapter:

- ZIP opens and contains exactly one `data.json`;
- JSON parses as UTF-8 and required root fields have valid types/ranges;
- at least 1 background + 1 title + expected number of verse layers exists;
- number and order of verse assets equals the source sloka count;
- every declared tiled image can be fully reconstructed at its declared dimensions;
- no undeclared/missing tile, unsafe path, duplicate ZIP member, or case-collision exists;
- every layer's translated resting rectangle fits the canvas horizontally and vertically;
- `sounds` is empty and no absent audio path leaks into the archive;
- rendered text images are non-empty and have non-transparent pixels;
- **every layer's `images[]` has its Russian content at index 1 (`Ru`), not index 0 (`En`)** —
  added 2026-08-06 per the real slot-index correction above; a regression test should assert this
  directly on real generated output, not just on the packager's internal data model, since a future
  refactor could silently reintroduce the original index-0 mistake.

### Source fidelity validation

- emitted source checkpoints round-trip exact strings and IDs from CSV;
- card metadata and visual text are generated from those immutable records;
- AI citations refer only to source orders in the same chapter;
- a normalized OCR/text extraction check may be used as a warning signal, but source fidelity is
  primarily guaranteed before rasterization and by renderer snapshot/hash tests, not by trusting
  OCR as an exact oracle.

### Current application validation

Add a focused Flutter test under `apps/comics-editor/test/` that discovers generated files when the
fixture directory is present, opens all 18 through `DartIoCore`, and verifies dimensions/layer
counts/no missing assets. If generated fixtures are absent, the repository-wide test may skip with
an explicit message; the production-run verification command must point it at
`work/bhagavadgita/`, where skipping is not accepted.

At least one chapter is additionally exercised through the current viewer integration available in
the workspace. If no viewer exposes a headless open contract, an editor open plus a documented
manual viewer launch is required; structural validation alone does not satisfy the Requirements.

### Test layers

- unit: CSV parsing, joins, ordering, source integrity, chunking, AI JSON validation, deterministic
  fallback, text escaping, layout, tiling, manifest fingerprints;
- property/parameterized: tile grids and long/multilingual card sizes;
- integration: one synthetic miniature chapter through render → package → reopen;
- real smoke: dataset chapter 1 with `--no-ai --no-psd`;
- production: all 18 chapters, then manifest and editor-loader validation.

## Idempotency and Resumability

The dataset fingerprint hashes the relevant CSV/PSD file contents and paths. The config fingerprint
hashes renderer theme/version, font hashes, storyboard prompt/model settings, canvas constants, and
packager schema version.

Each stage writes an output envelope containing input fingerprints. A stage is reusable only when
its envelope matches current inputs. Chapter-level locks prevent two processes from publishing the
same chapter concurrently. Interrupted `.staging` content is never counted as output and may be
reused only after its own checks pass.

## Failure Handling

| Failure | Result |
|---|---|
| Missing/malformed required CSV | Stop before generation; no final files replaced |
| Chapter/sloka count mismatch | Stop at dataset checkpoint and report exact mismatch |
| Ollama missing/timeout/invalid output | Warning; deterministic storyboard fallback |
| PSD decoder/import failure | Warning on chapter 5; deterministic visual fallback |
| Missing audio media | Expected warning/accounting; `sounds=[]` |
| Card text cannot fit minimum font | Grow card; if safety limit reached, fail only that chapter |
| Tile/package validation fails | Preserve staging diagnostics; do not replace final chapter |
| One chapter fails in `--all` | Continue remaining chapters; final command exits non-zero |
| Existing valid matching output | Reuse and record `reused=true` unless `--force` |
| Existing stale/corrupt output | Regenerate atomically; never count stale file as valid |

## Dependencies

Runtime Python dependencies are intentionally narrower than the full multimodal stack:

- Pillow for RGBA composition/PNG encoding;
- Playwright + bundled Chromium for text shaping/rendering;
- `psd-tools` for optional chapter-5 compositing;
- standard-library CSV/JSON/ZIP/hash/process modules;
- Ollama HTTP/CLI access is optional at runtime.

Heavy torch/opencv segmentation dependencies are not required: there are no source page images to
segment for 17 chapters. Existing tiling/package logic should be reused or extracted without
pulling in the entire multimodal runtime.

## Security and Data Safety

- resolve all input paths under the configured dataset root and all writes under the output root;
- reject archive paths containing absolute paths, `..`, or platform separators inconsistent with
  ZIP paths;
- HTML-escape every source/model string before browser rendering;
- never execute model-produced text, markup, commands, or paths;
- use fixed local templates and fonts; no remote URLs in renderer HTML;
- use bounded Ollama timeouts and bounded chapter/card dimensions;
- never delete or rewrite dataset files;
- never upload dataset text or generated output.

## Compatibility and Rollback

The generator is additive: tracked changes are confined to the new app, focused reusable helper
changes/tests when necessary, and this SDD flow. Generated work is confined to
`work/bhagavadgita/`.

Rollback consists of removing the new generator source and generated output; no `.comics` schema
migration or existing application data migration is introduced. If an optional animation or PSD
enrichment causes compatibility trouble, disabling that adapter returns to the deterministic
baseline without changing source ingestion or chapter cardinality.

## Specification Acceptance Checklist

- [x] Exactly 18 logical chapters are the production target.
- [x] Russian `BookId=1` and all 663 slokas are the source baseline.
- [x] One continuous-scroll `.comics` file is produced per chapter.
- [x] Deterministic text-forward output is retained only as a fixture/draft regression fallback.
- [x] AI summaries are optional, labeled, cited, and never replace source verses.
- [x] Native PSD/PDF/Lottie/`.comics` recovery precedes flattened-image fallback.
- [x] Content-verified semantic scopes prevent Gita Dhyanam/package numbering from being mistaken
      for a canonical chapter and identify the chapter-5 PSD range/components explicitly.
- [x] Canonical source, asset, entity, story-beat, coverage, action, candidate, review, composition,
      evaluation, and release models are defined.
- [x] True bitmap-mask acceptance and source/scene-disjoint Gold v1 evaluation are defined.
- [x] Segmenter, identity, colourization, lettering, positioning, and animation promotion gates are
      defined without hardcoding a model winner.
- [x] Story-beat coverage and golden chapters 1+11 are defined as scale-out gates.
- [x] Provider-neutral local/external action contract, cost/upload authorization, candidate review,
      and immutable lineage are defined.
- [x] Exact multilingual lettering and retained TextRegion mask contracts are defined.
- [x] Automated and six-dimensional human production review/release gates are defined.
- [x] Fixture, draft, candidate, and production release levels are distinct.
- [x] Cross-flow backend TDD cases are enumerated as a backlog pending that flow's own Requirements
      approval.
- [x] Specifications reviewed and approved by user (2026-08-06, "specs approved") — v0.2 baseline.
- [x] Lottie camera-path/per-layer z-depth extraction design (v0.3-v0.4) was drafted and approved
      here 2026-08-09, then **extracted into its own flow** per Anton's explicit instruction — see
      `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-lottie/02-specifications.md` for the full
      content and its own approval record.
- [x] v0.7 direct panorama cut/arrange/animate draft explicitly superseded and marked historical.
- [x] v0.9 production asset-first Specifications reviewed and approved by Anton on 2026-08-10
      (`"Сохрани обсужденные детали и заапрувь"`).
