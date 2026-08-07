# Specifications: comics-editor-ai-bhagavadgita-generator

> Version: 0.2 (Claude, 2026-08-06): corrected a real image-slot/language-index bug found by
> checking `.comics` Packaging Contract against the actual `Cultures` enum and a real dataset
> file — Russian moved from slot 0 to slot 1 (see that section for the full verified finding).
> Everything else independently spot-checked (root JSON keys, tile filename convention, layer
> JSON shape) matched Codex's original draft exactly against real code/data.
> Status: APPROVED (2026-08-06, Anton — "specs approved")
> Last Updated: 2026-08-06
> Requirements: [01-requirements.md](./01-requirements.md)

## Overview

Create a new Python application at
`apps/comics-ai/comics-ai-bhagavadgita-generator/` that reads the Bhagavad Gita CSV/PSD dataset,
normalizes the Russian edition into 18 canonical chapters, optionally derives a grounded local-LLM
storyboard, renders every source sloka into a readable continuous-strip card, packages one valid
`.comics` archive per chapter, and validates/reports the complete set under `work/bhagavadgita/`.

The completion path is deliberately independent of LLM and PSD availability. AI enrichment and
chapter-5 artwork may improve the output, but deterministic source-grounded rendering must always
be capable of producing all 18 valid documents.

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
- [x] Deterministic text-forward output is sufficient for completion.
- [x] AI summaries are optional, labeled, cited, and never replace source verses.
- [x] PSD and audio fallback behavior is explicit.
- [x] Output, manifest, packaging, validation, and resumability contracts are defined.
- [x] Specifications reviewed and approved by user (2026-08-06, "specs approved").
