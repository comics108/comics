# Status: sdd-comics-ai-baloons

## Current Phase

IMPLEMENTATION

## Phase Status

REVIEW

## Last Updated

2026-07-30 by Claude

## Blockers

- Waiting on user's final review of the implementation before marking complete. Two findings need
  explicit acknowledgement (already surfaced during implementation, not new): the CSV covers ~90%+
  within its actual content range but 5/27 files at 0% (different production era), and 10/20
  target languages have zero rows in the CSV at all.

## Progress

- [x] Requirements drafted
- [x] Requirements approved (2026-07-30)
- [x] Specifications drafted (2026-07-30)
- [x] Specifications approved (2026-07-30)
- [x] Plan drafted (2026-07-30)
- [x] Plan approved (2026-07-30)
- [x] Implementation started (2026-07-30)
- [x] Implementation complete (2026-07-30) — 8/8 phases, 22/22 plan tasks, 85/85 tests passing,
      full clean pipeline run verified reproducible (7:13, 22 output files, 1586/1586 renders)
- [ ] Documentation drafted
- [ ] Documentation approved

## Context Notes

Key decisions and context for resuming:

- Investigated `dataset/*.comics` files: each is a ZIP with `data.json` (layers/animations metadata) + `layers/*.png` raster assets.
- Balloon layers are named with a `b<N>` prefix (e.g. `b1_eng_{0}_{1}_{2}.png`, `b1_ru_{0}_{1}_{2}.png`). The `{0}_{1}_{2}` placeholders are tile coordinates — large balloon images are split into multiple PNG tiles that must be stitched back together per `data.json`'s declared width/height.
- Each balloon layer entry has one image variant per language (`eng`, `ru` observed) — same balloon shape/outline, different baked-in text. There is NO separate "empty balloon" or "text-only" layer in the dataset: outline + tail + text are already flattened into a single raster per language.
- This is a critical gap for the requested feature: an "empty balloon" (shape with no text) does not exist as source data today. It will need to be either (a) synthetically derived from the eng/ru pairs (e.g. by masking out the text region), (b) sourced from the original design files/PSDs if they exist outside `dataset/`, or (c) something the user already has in mind — this is an open question.
- Given the balloon shapes are hand-drawn/wobbly (not simple rounded rectangles) and dataset size is small (27 `.comics` files, few hundred balloons total, only 2 language variants each), a full generative/diffusion image model trained from scratch is likely impractical. A hybrid approach (classical CV to find the empty interior region + text layout/rendering with a matching font, possibly ML-assisted for font size/line-break decisions) may be more realistic — needs to be discussed with user during requirements/specs.

### Specifications research — editor source code findings (2026-07-30)

Found the authoritative `.comics` schema in `apps/comics-editor-v2.9/native/Comics.Editor/Models/*.cs` (C#, the actual editor's data model — `data.json`'s `$type` strings reference this assembly). Key findings, all confirmed against the real dataset:

- **`Cultures` enum** (`Models/Cultures.cs`) = `{ En=0, Ru=1, Hi=2 }`. `Layer.Images` is a `List<Image>` **index-aligned to this enum** — `GetImage(culture)` looks up `Images[CulturesHelper.All.IndexOf(culture)]`. So **language is determined by array position, not by filename** — the messy/inconsistent filenames found in the survey are cosmetic only; the ground truth is positional.
- Verified across **all 27 files, all 825 multi-language layers**: every one has exactly 3 image slots. Index 0/1 (en/ru) are populated per-balloon as expected; **index 2 (Hindi) is populated in 0 of 825 layers** — the schema already reserves a Hindi slot, it's just never been filled in. This means Hindi needs zero schema change — it's a straight fill of an existing reserved slot.
- The other 17 CSV languages (uk, th, zh, ko, kn, es, fr, pt, ja, tr, vi, ta, mr, bn, ne, he, ar) have **no reserved slot** in the current 3-culture enum. Proposed approach (in specs): append additional `Image` entries after index 2, in a fixed documented order — this is forward/backward compatible: `List<Image>` deserialization doesn't care about extra length, current editor simply won't read past index 2, and a future editor version that extends the enum in the same order would read our data with zero migration.
- **Tiling algorithm fully reverse-engineered** from `Utils/FileManager.cs` + `IWS/Utils/ImageMagick.cs`: tiles are 512×512px (`TileSize`), filename template `<name>_1000_<col>_<row>.<ext>` (the `1000` = scale×1000, always 1000 for non-puzzle comics layers since `ComicsScales = [1.0]`), `col = floor(x/512)`, `row = floor(y/512)` (from ImageMagick's `-crop 512x512` + `page.x/512`, `page.y/512` filename tiling), full canvas size from `data.json`'s declared `Image.Width`/`Image.Height`. PNGs are force-encoded 32-bit (`png32:`) to avoid 1-bit-transparency artifacts. This fully specifies both stitching (read) and re-tiling (write) for our pipeline.
- Balloon/text-layer detection = a `Layer` with ≥2 non-empty `Image` slots — now confirmed both empirically (survey) and from the source (`Layer.Create` populates all `CulturesHelper.All.Count` slots, filling only what's provided).

This means several previously-open Specifications questions are now resolved with high confidence rather than needing invention:
- Language-per-slot ambiguity → resolved (positional, not filename-based).
- Output `.comics` schema for new languages → resolved (append after index 2 in a fixed order; documented in 02-specifications.md).
- Tile read/write algorithm → resolved (512px grid, exact filename template).

### Scope expansion + decisions, round 2 (2026-07-30)

- User pointed out `dataset/Translation - Mahabharata Book 1.csv` (~20 languages, keyed by global `P<page>_<bubble>`) and reframed the success criterion: augment `.comics` files with balloon renders for **every language in the CSV**, wherever confidently matchable.
- Working directory established: **`apps/comics-ai-baloons/`** (`scripts/` for tooling, `work/` gitignored for scratch/output). `dataset/` is strictly read-only for this whole feature — never write there.
- Ran a full survey (`apps/comics-ai-baloons/scripts/survey_dataset.py` → `apps/comics-ai-baloons/work/survey.json`) of all 27 `.comics` files. Found ≥8 divergent balloon-filename conventions across the dataset (2017-2022 vintage spread); a naive `b<N>_<lang>` regex misses balloons in 8/27 files entirely. Reliable detection is **structural**: a `data.json` layer with ≥2 non-empty same-size `images[]` slots = a balloon/text layer, regardless of filename. Some slots have no language token in the filename at all.
- CSV-to-balloon mapping is **not** index-based — the CSV's global page numbers don't correspond to the 27 hashed `.comics` filenames' local balloon numbering, and the user warned the CSV may be a different version (phrase corrections, numbering shifts possible). Matching must be content-based (OCR + fuzzy text match against CSV `en`/`ru` columns).
- User decisions this round: (1) unmatched/ambiguous balloons → **skip + log**, never guess; (2) hand-lettered balloons → **auto-classify AND** build a dedicated model/approach for them, not just flag; (3) output → new `.comics` files in `apps/comics-ai-baloons/work/`, `dataset/` untouched; (4) language scope → **all ~20 CSV languages**, including RTL (he/ar), CJK (zh/ja/ko), Indic (hi/ta/mr/bn/ne/kn) — flagged as a real technical-risk area for Specs/Plan (text shaping likely needs HarfBuzz/Pango or headless-browser rendering, not plain PIL).
- Requirements doc rewritten to v0.3 reflecting all of the above; still has several open items explicitly deferred to Specifications (text-shaping approach, OCR approach, hand-lettering classifier approach, fuzzy-match confidence threshold, per-script font sourcing).

### Decisions from user (2026-07-30)

- **Empty balloons**: synthesize from `eng`/`ru` pairs (same shape, different text) rather than sourcing externally. Erase capability is itself an acceptance criterion, not just a data-prep trick.
- **Scope = both modes**: (1) freehand — model hand-letters the text directly, no selectable font; (2) layout — model outputs text-region coordinates, text rendered via a given font. Both to be pursued (user: "оба варианта").
- **Deployment**: this iteration is a standalone script/CLI against `dataset/`. Editor integration (`apps/comics-editor-v2.9`) is future work, must not be architecturally precluded.
- **Input scope**: only balloons already present in `dataset/` this iteration (erase existing text → insert different text). Arbitrary new/unseen balloon contours deferred — **write a TODO after this SDD flow completes**, and revisit mid-implementation if supporting it turns out cheap.
- **Font for layout mode**: use an existing/manually-chosen font this iteration. Automatic font matching from balloon lettering examples is deferred, but keep the font step pluggable — the future editor should auto-pick a font from examples.
- **Success metric**: both human visual review and an automated/quantitative metric (exact metric TBD in Specifications).

## Fork History

N/A — new flow.

## Next Actions

1. User reviews the implementation: `apps/comics-ai-baloons/work/report.md` (pipeline results),
   `apps/comics-ai-baloons/TODO.md` (deferred items), and ideally opens an output file from
   `apps/comics-ai-baloons/work/output/` in `apps/comics-editor-v2.9` (not done in this
   environment — see TODO.md item 6).
2. On approval, move to Documentation phase (per SDD flow) or close the flow if no further
   documentation artifact is needed beyond this log + the app's own README/TODO.
