# Specifications: comics-ai-baloons

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-07-30
> Requirements: [01-requirements.md](01-requirements.md)

## Overview

A batch pipeline, living entirely under `apps/comics-ai-baloons/`, that reads `dataset/*.comics`
(read-only) and `dataset/Translation - Mahabharata Book 1.csv`, and for every balloon it can
confidently identify and match to a CSV row, produces new per-language balloon renders — using
font-based layout rendering for machine-set balloons and a dedicated approach for hand-lettered
ones — and writes complete, valid `.comics` files (original content + new balloon layers) to
`apps/comics-ai-baloons/work/output/`, alongside a machine-readable report of what was
rendered/skipped and why.

The schema for the new balloon layers is designed to slot directly into the *real* `.comics`
format used by `apps/comics-editor-v2.9` (verified against its C# source, not guessed), so the
output is immediately compatible with that editor today for `en`/`ru`/`hi`, and requires only a
documented, additive enum extension (no data migration) for the editor to eventually read the
other 17 languages.

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `dataset/*.comics` | **Read-only** | Never written to. Opened, parsed, tiles stitched for OCR/analysis. |
| `dataset/Translation - Mahabharata Book 1.csv` | Read-only | Source of translations, ~20 languages. |
| `apps/comics-ai-baloons/scripts/` | Create | New Python pipeline (survey already exists here). |
| `apps/comics-ai-baloons/work/` | Create (gitignored) | Extracted assets, intermediate data, OCR/match cache, final output `.comics` files, reports. |
| `apps/comics-editor-v2.9` (native C# model) | **Not modified this iteration** | Read for schema ground-truth only. A documented, additive `Cultures` enum extension is proposed as a *future* change, out of scope to actually implement here. |

## Architecture

### Component Diagram

```
dataset/*.comics ──┐
                    ├─▶ [1] Discover ──▶ [2] Extract & Stitch ──▶ [3] OCR ──▶ [4] Match to CSV
CSV translations ───┘                                                              │
                                                                                     ▼
                                                                          [5] Classify lettering
                                                                            (machine-set / hand)
                                                                                     │
                                              ┌──────────────────────────────────────┤
                                              ▼                                      ▼
                                   [6a] Erase + Layout-render                [6b] Erase + Hand-
                                     (font-based, all 20 langs)                lettering track
                                              │                                      │
                                              └──────────────────┬───────────────────┘
                                                                  ▼
                                                        [7] Re-tile & Package
                                                     (new .comics + updated data.json)
                                                                  │
                                                                  ▼
                                                   apps/comics-ai-baloons/work/output/
                                                   + apps/comics-ai-baloons/work/report.*
```

Each stage is a separate script/module with a serialized intermediate artifact in `work/`, so the
pipeline is resumable and inspectable stage-by-stage (important given OCR/matching accuracy is
inherently imperfect and needs human spot-checking during development).

### Data Flow

1. **Discover**: for each `.comics` file, parse `data.json`, find every `Layer` with ≥2 non-empty
   `Image` slots → a `BalloonLayer` record (see Data Models). No filename parsing required for
   language — index position is authoritative (0=en, 1=ru, 2=hi; see Editor Schema Ground Truth).
2. **Extract & Stitch**: for each populated image slot, extract its tiles from the zip and stitch
   into a single PNG using the reverse-engineered tiling algorithm (below).
3. **OCR**: run OCR on the stitched `en` (and `ru`, as a cross-check) image to recover the baked-in
   text string per balloon.
4. **Match to CSV**: fuzzy-match the OCR'd text against the CSV's `en`/`ru` columns to find the
   corresponding row (and therefore all its translations). Skip + log if no confident match.
5. **Classify lettering**: heuristically (see Hand Lettering Detection) tag each matched balloon as
   `machine_set` or `hand_lettered`.
6. **Erase + render**: recover an empty balloon from the existing en/ru renders, then render new
   text for every language present in the matched CSV row — via layout mode (machine-set) or the
   hand-lettering track (hand-lettered).
7. **Re-tile & Package**: slice each new render into 512px tiles, add new `Image` entries to the
   layer (positions per the language-order table), write a full copy of the `.comics` zip (original
   entries + new layer tiles + updated `data.json`) to `work/output/`.

## Editor Schema Ground Truth (from `apps/comics-editor-v2.9/native/Comics.Editor`)

This is not inferred — it's read directly from the editor's C# model classes, and independently
verified against all 27 dataset files.

### Culture → array index

```csharp
// Models/Cultures.cs
public enum Cultures { En, Ru, Hi }   // index 0, 1, 2
// Models/Layer.cs
public List<Image> Images;            // index-aligned to Cultures
```

Verified: all 825 multi-language balloon layers across the 27 files have exactly 3 image slots;
index 2 (`Hi`) is empty in all 825. **Language is determined purely by array position** — the
filename is a human-readable label only and is never parsed by the editor.

### Proposed extended ordering (this feature's contribution)

Indices 0-2 are fixed by the existing enum and must not change. Indices 3+ are **new**, proposed in
CSV column order (excluding en/ru/hi, already placed):

| Index | Lang | Index | Lang | Index | Lang |
|-------|------|-------|------|-------|------|
| 0 | en | 7 | es | 14 | ta |
| 1 | ru | 8 | fr | 15 | mr |
| 2 | hi | 9 | pt | 16 | bn |
| 3 | uk | 10 | ja | 17 | ne |
| 4 | th | 11 | tr | 18 | he |
| 5 | zh | 12 | vi | 19 | ar |
| 6 | ko | 13 | kn | | |

This table is written once to `apps/comics-ai-baloons/scripts/languages.py` (or `.json`) as the
single source of truth and used by every stage. If/when the editor's `Cultures` enum is extended to
match (future work, not this iteration), no data migration is needed — the JSON is already correct.

### Tiling algorithm (read + write)

- Tile size: 512×512px (`FileManager.TileSize`).
- Filename template: `<basename>_1000_<col>_<row>.<ext>` (the `1000` = scale × 1000; always 1000
  for comics layers, since `ComicsScales = [1.0]` — puzzle-only assets use other scales, not
  relevant here).
- `col = floor(x / 512)`, `row = floor(y / 512)`, 0-based, from `data.json`'s declared
  `Image.Width`/`Image.Height` for that slot (edge tiles are naturally clipped, not padded to 512 —
  matches ImageMagick's `-crop 512x512` behavior).
- Stitching (read): allocate a canvas of `Width`×`Height`, paste each tile at `(col*512, row*512)`.
- Re-tiling (write): crop the final rendered image into a `col`/`row` grid the same way, encode as
  32-bit PNG (avoid 1-bit-transparency palette PNGs — the editor forces `png32:` for this reason).
- Non-multi-language art layers (single image slot) are copied byte-for-byte, untouched, into the
  output archive.

### `data.json` layer shape (unchanged fields, for reference)

```json
{
  "images": [
    { "file": "b1_eng_{0}_{1}_{2}.png", "width": 648, "height": 152 },
    { "file": "b1_ru_{0}_{1}_{2}.png",  "width": 648, "height": 152 },
    {},
    { "file": "b1_hi_{0}_{1}_{2}.png",  "width": 648, "height": 152 },
    { "file": "b1_uk_{0}_{1}_{2}.png",  "width": 648, "height": 152 }
  ],
  "animations": [ /* unchanged — copied from the original layer verbatim */ ]
}
```

New `Image` entries follow the same `{file, width, height}` shape as existing ones. `animations`
are copied unmodified from the source layer (they describe motion/scale/alpha of the whole layer,
not per-language — do not touch).

## Interfaces

### New Interfaces (CLI, `apps/comics-ai-baloons/scripts/`)

```
survey_dataset.py            # already built — catalogs naming conventions per file
discover.py    <dataset dir> --out work/balloons.jsonl
extract.py     work/balloons.jsonl --out work/extracted/
ocr.py         work/extracted/ --out work/ocr.jsonl
match.py       work/ocr.jsonl <csv path> --out work/matches.jsonl
classify.py    work/matches.jsonl --out work/lettering.jsonl
render.py      work/lettering.jsonl --out work/renders/
package.py     work/renders/ --out work/output/
report.py      work/*.jsonl --out work/report.md work/report.jsonl
pipeline.py    # runs all of the above in order, resumable per-stage
```

Each stage reads the prior stage's `.jsonl` and its own cached files under `work/`, so a stage can
be re-run in isolation (e.g. re-tune the fuzzy-match threshold without re-running OCR).

### Modified Interfaces

None — `apps/comics-editor-v2.9` is not modified this iteration.

## Data Models

### `BalloonLayer` (internal, per balloon per source file)

```python
@dataclass
class BalloonLayer:
    source_file: str          # dataset/*.comics filename
    layer_index: int          # index into data.json "layers"
    slots: dict[int, ImageSlot]   # populated indices only, e.g. {0: ImageSlot(en), 1: ImageSlot(ru)}
    canvas_offset: tuple[int, int]  # from TranslateAnim, for on-page position (matching context)

@dataclass
class ImageSlot:
    lang_index: int           # 0=en, 1=ru, 2=hi, ...
    file_template: str        # e.g. "b1_eng_{0}_{1}_{2}.png"
    width: int
    height: int
```

### `OcrResult`

```python
@dataclass
class OcrResult:
    balloon: BalloonLayer
    lang_index: int           # which slot was OCR'd (0=en preferred, 1=ru fallback/cross-check)
    text: str                 # raw OCR output
    confidence: float         # OCR engine's own confidence, 0-1
```

### `MatchResult`

```python
@dataclass
class MatchResult:
    balloon: BalloonLayer
    csv_row_id: str | None    # e.g. "P45_004", or None if unmatched
    match_score: float        # 0-1 fuzzy-match confidence
    matched_on: str           # "en" | "ru"
    status: Literal["matched", "skipped_no_match", "skipped_ambiguous", "skipped_low_confidence"]
    reason: str                # human-readable, goes straight into the report
```

### `LetteringClass`

```python
@dataclass
class LetteringClass:
    balloon: BalloonLayer
    label: Literal["machine_set", "hand_lettered"]
    confidence: float
    signals: dict[str, float]  # feature values that drove the decision, for auditability
```

### Report (`work/report.jsonl`, one line per balloon)

```json
{
  "source_file": "8a89f7d689fb441ea280cd782276bd7a.comics",
  "layer_index": 174,
  "ocr_text_en": "AND AMBA TOLD PARASHURAMA ABOUT THE HARDSHIPS SHE HAD FACED WITH BHISHMA.",
  "match": {"csv_row_id": "P52_003", "score": 0.94, "matched_on": "en"},
  "lettering_class": "machine_set",
  "languages_rendered": ["hi", "uk", "th", "zh", "ko", "es", "fr", "pt", "ja", "tr", "vi", "kn", "ta", "mr", "bn", "ne", "he", "ar"],
  "languages_skipped": [],
  "status": "rendered"
}
```

Also emit a human-readable summary (`work/report.md`): totals per file, per language, per status
(rendered / skipped + reason breakdown), and a flagged list of every `hand_lettered` balloon for
manual review regardless of whether rendering was attempted.

### Schema Changes

Output `.comics` files get additive `Image` entries per multi-language layer (see language-order
table above). No fields are removed or renamed; `dataset/` itself has zero schema changes since
it's never written to.

## Behavior Specifications

### Happy Path

1. Pipeline runs over all 27 `.comics` files.
2. Each balloon is discovered structurally, OCR'd, matched to a CSV row, classified, erased, and
   re-rendered in every language present in that CSV row.
3. Output: 27 new `.comics` files under `work/output/`, each openable by
   `apps/comics-editor-v2.9` today (for en/ru/hi) and forward-compatible for the rest, plus a
   report covering every balloon's outcome.

### Pipeline Stage Details

#### [1-2] Discovery + Extraction

- Iterate `data.json["layers"]`; a layer qualifies as a `BalloonLayer` iff ≥2 of its (pre-extension,
  always ≤3) `images[]` entries have a non-empty `file`.
- For each populated slot, resolve the tile filenames (substitute `{0}={scale*1000}`, iterate
  `col`/`row` up to `ceil(width/512)`×`ceil(height/512)`), extract from the zip, stitch.
- Cache stitched PNGs in `work/extracted/<file_hash>/layer_<idx>_<lang>.png` to avoid re-extracting
  on pipeline re-runs.

#### [3] OCR

- Engine: **Tesseract** (via `pytesseract`), language packs `eng`+`rus` (the only two baked
  languages that currently exist in the dataset).
- Run on the `en` slot; also run on `ru` as an independent cross-check/fallback when `en` is
  missing (one file in the survey, `7df7d58b22c3...`, has `en` only anyway; a couple of files use
  only `ru` in some balloons per the casing survey — handle both directions).
- Store raw text + confidence in `OcrResult`; do not fail the pipeline on low OCR confidence — it
  flows into the match step's scoring instead.

#### [4] Match to CSV

- Normalize both OCR text and CSV cell text: lowercase, collapse whitespace, strip punctuation.
- Score candidates with `rapidfuzz.fuzz.token_sort_ratio` (tolerates word-order noise and minor
  phrasing corrections between CSV and dataset versions, per the user's explicit warning about
  drift) against the CSV's `en` column (primary) and `ru` column (secondary/tie-break).
- **No index/sequence-based shortcuts as a hard filter** — the user confirmed CSV `P<page>_<bubble>`
  numbering can't be trusted to line up with a given `.comics` file's local balloon order. Sequence
  position *within a file* may be used only as a soft tie-breaker between multiple high-scoring
  text candidates, never to accept a low-scoring one.
- Decision rule: accept if best score ≥ **0.75** (candidate threshold to validate empirically once
  a sample of real OCR output is seen — see Open Design Questions) *and* it beats the second-best
  candidate by a margin (avoid accepting a near-tie); otherwise `status="skipped_low_confidence"`
  or `"skipped_ambiguous"`. No match candidate at all → `"skipped_no_match"`.
- Every skip is logged with the OCR text and best-candidate score, so a human can adjudicate later.

#### [5] Classify lettering: machine-set vs. hand-lettered

Heuristic, auditable pipeline (not a black box) given the small dataset:

1. **Stroke-width consistency**: extract glyph contours from the stitched `en` (and `ru`) balloon
   text region; measure stroke-width variance. Uniform display fonts (as seen in every sample
   inspected so far) have low variance; genuine hand lettering has higher variance, including
   across characters within the same word.
2. **Baseline/slant irregularity**: fit a baseline per text line; measure deviation. Hand lettering
   wobbles; set type sits on a straight baseline.
3. **OCR confidence as a signal**: Tesseract (trained on printed text) tends to report lower
   per-character confidence on genuine hand lettering than on a clean display font — reuse the
   `OcrResult.confidence` already computed in stage 3 as a free additional feature.
4. Combine features 1-3 into a single score; threshold tuned against a small human-labeled sample
   (see below). This is intentionally simple/heuristic rather than a trained CNN given ~825
   balloons total — revisit only if the heuristic proves unreliable on a labeled sample.

**Before finalizing the threshold**: pull a stratified sample of balloons across all 27 files
(different dates/eras, since the naming-convention survey suggests different production periods
may have different lettering practices) and manually tag hand-lettered vs. machine-set to validate
the heuristic and calibrate the threshold. This labeled sample doubles as eval data for stage 6b.

#### [6a] Erase + Layout-mode render (machine-set balloons, all languages)

- **Erase**: for a balloon's `en`/`ru` pair, pixels where the two renders agree are background
  (safe to reuse); pixels where they differ are candidate text pixels in at least one — reconstruct
  via inpainting (OpenCV `cv2.inpaint`, Telea or Navier-Stokes) restricted to the disagreement
  region. Produces one empty-balloon raster per balloon.
- **Layout**: locate the balloon's text-safe interior polygon (inside the outline, excluding the
  tail) from the empty balloon's alpha/edge structure; compute 1+ line regions sized to the
  translated string's length for the target language; auto-fit font size to the region.
- **Render/shape text**:
  - Latin/Cyrillic (en, ru, uk — and es/fr/pt/tr/vi close enough to also be Latin): use a
    manually-chosen font that resembles the comic's existing display lettering (candidate to
    confirm — see Open Design Questions).
  - All other scripts (th, zh, ko, kn, ja, ta, mr, bn, ne, he, ar): plain raster text APIs (e.g.
    PIL) do not correctly shape complex scripts (Indic conjuncts/matras, Arabic/Hebrew RTL +
    joining forms, CJK line-breaking rules). **Proposed approach: headless-browser rendering** —
    render an HTML/CSS snippet (`direction: rtl` where applicable, correct `lang`/font-family) in
    headless Chromium (e.g. via Playwright), screenshot the text region, and composite onto the
    balloon. This offloads shaping/line-breaking to a mature, well-tested engine instead of
    reimplementing per-script rules. Font coverage: **Noto Sans** family (Google, OFL-licensed) —
    it's specifically built to cover every script in the CSV's language list under one consistent
    family, which also keeps styling closer to a "designed for comics" look than mismatched system
    fonts.
- Composite rendered text onto the empty balloon; this is the new per-language raster.

#### [6b] Hand-lettering track (hand-lettered balloons)

- Erase, same as 6a.
- Per user decision, this gets a **dedicated model/approach**, not layout-mode font substitution
  (which would destroy the expressive signal). Concretely: a small model trained on the erased
  empty balloon + target text → hand-lettered raster, conditioned on whatever hand-lettered
  examples exist in the dataset (volume TBD — depends on how many the classifier finds; see Open
  Design Questions, this may be too little data to train from scratch, in which case fall back to
  a style-transfer approach seeded from the balloon's own existing hand-lettered strokes, or flag
  for human artist review instead of an automated render).
- Regardless of automated output quality, every hand-lettered balloon is listed separately in
  `work/report.md` for manual review, per the "preserve collectible/expressive value" requirement.

#### [7] Re-tile & Package

- For each `BalloonLayer` with new renders: re-tile each new raster (512px grid, `png32:`
  equivalent — Pillow `im.convert("RGBA")` + explicit save, no palette mode), name tiles per the
  existing template convention (reuse the `en` slot's basename with the new language's ISO code
  substituted, to stay human-readable and consistent with existing dataset conventions).
- Add new `Image` entries to `data.json["layers"][i]["images"]` at the indices from the language
  table (extending the list past index 2 as needed). Leave existing entries and all `animations`
  untouched.
- Write a **complete copy** of the source `.comics` zip to
  `apps/comics-ai-baloons/work/output/<same_filename>.comics`: every original zip entry copied
  as-is, plus new tile PNGs, plus the modified `data.json`. Source `dataset/*.comics` is opened
  read-only throughout and never written.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| Balloon has only 1 populated language slot | Some files (per survey) | Not a multi-language balloon at all; treat as an art layer, skip silently (not an error) |
| OCR fails to extract legible text | Low-contrast/stylized balloon | `match.status = skipped_no_match`, logged with empty/garbage OCR text for human review |
| CSV row exists but is missing some language columns | Sparse CSV cells (observed — not every row has every language filled) | Render only the languages present for that row; log which were skipped as `no_translation_in_csv` (distinct reason from a matching failure) |
| Two CSV rows score similarly for one balloon | Ambiguous/duplicate phrasing | `status = skipped_ambiguous`, both candidates logged |
| Balloon classified hand-lettered but 6b can't produce a confident render | Insufficient hand-lettered training examples | Still erase + log as `hand_lettered`, but leave `languages_rendered` empty and flag prominently in `report.md` for manual/artist follow-up rather than emitting a bad automated render |
| Image slot present in JSON but its tile files are missing from the zip | Data corruption / partial export | Log and skip that specific slot's OCR/erase, don't crash the whole file's pipeline run |
| RTL language (he, ar) balloon interior is very small/narrow | Tight balloon shapes | Layout step may need to shrink font aggressively or wrap to more lines than the original; if text still doesn't fit at a legibility floor, log as `text_overflow`, skip rendering that language for that balloon rather than producing illegible output |
| Same balloon shape reused with two different CSV matches across files (e.g. common phrase "..." appearing twice) | Generic/short phrases | Use full-row match score + position tie-break (soft signal only, per Match rules above); if truly ambiguous, `skipped_ambiguous` |

### Error Handling

| Error | Cause | Response |
|-------|-------|----------|
| `.comics` zip fails to open / corrupt | Bad file in dataset | Log file-level error, skip file, continue with the rest |
| `data.json` fails to parse | Encoding/format surprise (already handled: BOM via `utf-8-sig`) | Log, skip file |
| Tesseract not installed / OCR engine unavailable | Missing system dependency | Fail fast at pipeline startup with a clear setup message (not a silent per-balloon failure) |
| Headless browser unavailable (Playwright/Chromium not installed) | Missing system dependency | Fail fast for the affected languages only; Latin/Cyrillic-only run remains possible without it |

## Dependencies

### Requires

- Python 3.x environment for the pipeline (new, under `apps/comics-ai-baloons/`)
- `Pillow` (tile stitching/re-tiling, compositing)
- `pytesseract` + system Tesseract with `eng`+`rus` language data
- `rapidfuzz` (fuzzy text matching)
- `opencv-python` (inpainting for the erase step)
- `playwright` (or equivalent headless-browser tool) + Noto Sans font family, for non-Latin/Cyrillic
  script rendering

### Blocks

- Future `apps/comics-editor-v2.9` integration (out of scope this iteration) depends on this
  pipeline's output schema being correct — hence the emphasis on verifying against the real C#
  model rather than guessing.

## Integration Points

### External Systems

None this iteration (no network calls; OCR/rendering/fonts all run locally).

### Internal Systems

- Reads `dataset/*.comics` and the translation CSV (read-only).
- Schema/tiling conventions borrowed from `apps/comics-editor-v2.9/native/Comics.Editor` (read-only
  reference, not a code dependency — this is a separate Python pipeline, not linked against the C#
  code).

## Testing Strategy

### Unit Tests

- [ ] Tiling: stitch/re-tile round-trip on a synthetic multi-tile image reproduces the original
      pixels exactly
- [ ] Layer discovery: correctly identifies balloon layers across a fixture covering each of the
      8+ naming conventions found in the survey
- [ ] Fuzzy matcher: known OCR-text/CSV-row pairs (including deliberately corrupted/corrected text)
      score above/below threshold as expected
- [ ] Language-index table: round-trips correctly (index → ISO code → index)

### Integration Tests

- [ ] Full pipeline run on a small fixture subset (2-3 `.comics` files) produces valid output
      `.comics` files that `apps/comics-editor-v2.9` can open without error (manual check)
- [ ] Report accounts for 100% of discovered balloons (every one is either rendered or has a
      logged skip reason — none silently dropped)

### Manual Verification

- [ ] Visual spot-check of rendered balloons per script family (at minimum: one Latin, one
      Cyrillic, one RTL, one CJK, one Indic language) for legibility and fit within the balloon
- [ ] Hand-lettered classification sample reviewed by a human against the heuristic's output
- [ ] Confirm at least one output `.comics` file opens correctly in `apps/comics-editor-v2.9`

## Migration / Rollout

Not applicable — this is a new, standalone pipeline producing new output files. No existing system
is migrated. Future editor integration (reading the extended language indices) is out of scope and
would be a separate, later SDD flow.

## Open Design Questions

- [ ] **CSV match confidence threshold**: 0.75 proposed above is a starting point, not validated —
      needs tuning against real OCR output from stage 3 before Plan/Implementation locks it in.
- [ ] **Layout-mode font for Latin/Cyrillic**: which specific font file to use — needs a short
      visual comparison against a handful of dataset samples.
- [ ] **Hand-lettering track feasibility**: depends entirely on how many hand-lettered balloons the
      classifier actually finds (unknown until stage 5 runs on real data) — if the count is very
      low, "dedicated model" may need to mean "style-matched manual/semi-automated process" rather
      than a trained model, and that should be decided once the real count is known, not guessed
      now.
- [ ] **Headless-browser tool choice**: Playwright vs. a lighter alternative (e.g. `wkhtmltoimage`)
      — Playwright is more actively maintained and handles modern CSS/font-shaping better, but has
      a heavier install footprint (bundles Chromium). Default to Playwright unless install size
      becomes a real constraint.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-07-30
- [x] Notes: Approved as-is. Open Design Questions (CSV match threshold, Latin/Cyrillic font pick,
      hand-lettering track feasibility, headless-browser tool choice) are intentionally left to be
      resolved empirically during Plan/Implementation rather than blocking approval.
