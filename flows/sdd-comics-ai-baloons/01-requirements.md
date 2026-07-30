# Requirements: comics-ai-baloons

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-07-30

## Problem Statement

`dataset/*.comics` files (zip archives with `data.json` + `layers/*.png`) contain speech-balloon
layers. Today, every balloon asset already has its text baked permanently into the raster image,
per language, and only 1-2 languages (`en`/`ru`, inconsistently) exist per balloon. Adding a new
language, correcting a translation, or reusing a balloon shape with different text currently
requires an artist to redraw the balloon from scratch.

`dataset/Translation - Mahabharata Book 1.csv` (added alongside this request) contains
translations of the comic's dialogue/captions into **~20 languages** (en, ru, uk, th, zh, ko, kn,
es, fr, pt, ja, tr, vi, hi, ta, mr, bn, ne, he, ar), keyed by a global `P<page>_<bubble>` id (e.g.
`P1_001`). The user has confirmed: **the success criterion for this SDD flow is to augment the
`.comics` files with rendered balloons for every language present in this CSV**, wherever a
balloon can be confidently matched to a CSV row.

We want an AI-assisted pipeline that:

1. **Detects** every balloon/text layer in a `.comics` file, robustly, despite highly inconsistent
   naming conventions (see Dataset Findings).
2. **Matches** each detected balloon to its corresponding row in the translation CSV, tolerating
   version drift between the CSV and this dataset (see Dataset Findings) — and **skips + logs**
   (does not guess) when a confident match can't be made.
3. **Classifies** each balloon's existing lettering as machine-set (uniform font) vs. hand-lettered
   (artist-drawn, expressive) — hand-lettered balloons are valuable and must not be silently
   overwritten with generic font rendering (see Hand Lettering, below).
4. **Erases** existing baked-in text from a balloon, recovering an "empty" balloon.
5. **Inserts** the matched CSV text, per target language, back into the empty balloon — via layout
   mode (font + coordinates) for machine-set balloons, and via a dedicated hand-lettering-aware
   approach for balloons classified as hand-lettered (see Hand Lettering, below). Freehand mode
   (no selectable font) remains an additional track explored in parallel per prior direction.
6. **Outputs** new, complete `.comics` files (original content + newly rendered per-language
   balloons) into a working directory — **`dataset/` is read-only input and must never be
   modified** — plus a machine-readable report of what was matched/rendered vs. skipped and why.

### Working directory

All scripts, extracted/derived data, models, and output `.comics` files for this feature live under
**`apps/comics-ai-baloons/`** (mirrors the `apps/comics-editor-v2.9` naming convention):

- `apps/comics-ai-baloons/scripts/` — tooling (survey, extraction, matching, rendering, packaging)
- `apps/comics-ai-baloons/work/` — gitignored scratch: extracted assets, intermediate data,
  generated `.comics` output, reports
- `dataset/` is treated as **read-only** source input for the entire feature — never written to.

### Dataset findings (from investigation)

- **No empty-balloon asset exists anywhere.** Every language variant of a balloon is a flattened
  raster (outline + tail + baked-in text). Empty balloons must be synthesized (e.g. from agreement
  between two language variants of the same balloon, or via inpainting) — this was already
  established in the prior round of requirements and still holds.
- **Balloon-layer naming is inconsistent across the 27 `.comics` files.** Surveying all of them
  (`apps/comics-ai-baloons/work/survey.json`, script at
  `apps/comics-ai-baloons/scripts/survey_dataset.py`) found at least 8 distinct filename
  conventions in active use, spanning 2017-2022: `b12_en_...`, `B10_en_...`, `b_10_EN_...`,
  `babl_14_ru_...`, `text eng_01_...`, `Text_eng001_...`, `text_en_001_...`,
  `eng 00007_...` (no prefix at all). Language-code casing/length is also inconsistent
  (`en`/`EN`/`eng`/`RU`/`rus`...). A naive `b<N>_<lang>` regex misses balloons in **8 of the 27
  files** entirely.
- **Reliable balloon detection is structural, not filename-based.** In `data.json`, every layer
  entry has an `images[]` array; a balloon/text layer is one where **2 or more image slots are
  non-empty and share the same declared width/height** (one raster per language). Pure-art layers
  have exactly one populated image slot. This held true across every naming convention found.
- **Some image slots carry no language token in the filename at all** (e.g. two slots named just
  `00011_...` / `00001_...` in one file, with no `eng`/`ru` anywhere). Language for these must be
  inferred another way (candidate: OCR + script/alphabet detection, Latin vs Cyrillic — sufficient
  today since only `en`/`ru` are actually present in the dataset's existing renders) or skipped per
  the user's "skip + log" decision if inference isn't confident.
- **Tiling**: large balloon images are split into multiple PNG tiles per `data.json`'s filename
  template (`{0}_{1}_{2}` = zoom/col/row or similar) and must be stitched/re-tiled by any tooling.
- **CSV-to-balloon alignment is not a simple index lookup.** The CSV's `P<page>_<bubble>` ids are
  *global page numbers* across the whole book; the 27 `.comics` files are opaque hashed filenames
  with their own **locally-scoped** balloon numbering — there is no direct mapping table between
  the two. Per the user: the CSV may not even be from the exact same version as this dataset
  (possible phrase-level corrections, possible shifts in numbering). **Matching must be
  content-based** (e.g. OCR the baked-in `en`/`ru` text of a balloon, fuzzy-match against the CSV's
  `en`/`ru` columns), not purely sequence/index-based, and must degrade to "skip + log" rather than
  force a low-confidence match.

### Hand lettering

Per the user: some balloons in the dataset likely contain genuine **hand lettering** — organic,
artist-drawn text (as opposed to a uniform digitally-set display font, which is what was observed
in the samples inspected so far, e.g. `b1_eng` in one file: uniform caps, evenly spaced). Hand
lettering is called out because it carries meaning beyond the words: different characters can have
different handwriting; size/slant/weight of the letters convey emotion; the lettering is composed
as part of the artwork rather than a separate mechanical layer. Original hand-lettered pages are
valued by collectors for this reason — so this pipeline must not blindly flatten that expressive
signal into a generic font.

Per user decision, this pipeline must:

- **Automatically classify** each detected balloon as hand-lettered vs. machine-set font (a
  detection/classification subtask — approach TBD in Specifications, likely a mix of heuristics —
  e.g. per-glyph shape/stroke-width variance, inconsistency between the balloon's own multiple
  language renders — and/or a small trained classifier).
- **Pursue a dedicated approach for hand-lettered balloons**, separate from the layout-mode
  font-substitution path used for machine-set balloons — i.e. a distinct model/track specifically
  for reproducing hand-lettered style, not just tagging-and-skipping. (This is in addition to, not
  instead of, logging/flagging them.)

## User Stories

### Primary

**As a** comics editor/producer
**I want** every balloon in `dataset/*.comics` that can be confidently matched to the translation
CSV to be rendered with that text, in every language the CSV provides, respecting whether the
balloon was originally hand-lettered or machine-set
**So that** the comic can be localized into ~20 languages without an artist manually redrawing
every balloon, while preserving the artistic character of hand-lettered balloons

### Secondary

- **As a** pipeline maintainer, **I want** a CLI/batch script plus a clear match/skip report
  **so that** I can see exactly which balloons were rendered, in which languages, and which were
  skipped and why (no CSV match, ambiguous language, low confidence, etc.), without ever touching
  `dataset/`.
- **As a** future comics-editor user (`apps/comics-editor-v2.9`), **I want** this capability
  eventually exposed inside the editor **so that** I don't need to leave the tool to relocalize a
  balloon. (Out of scope for this iteration's implementation, but must not be architecturally
  precluded.)

## Acceptance Criteria

### Must Have

1. **Given** all 27 `.comics` files in `dataset/`
   **When** the pipeline runs
   **Then** it detects balloon/text layers structurally (via `data.json` multi-image-slot layers),
   correctly handling all filename conventions found in the survey — not just `b<N>_<lang>`

2. **Given** a detected balloon and the translation CSV
   **When** the matcher runs
   **Then** it either (a) finds a confident content-based match to a CSV row and proceeds, or
   (b) skips the balloon and logs the reason — it never fabricates a guessed match

3. **Given** a balloon successfully matched to a CSV row
   **When** the pipeline processes it
   **Then** it is classified as hand-lettered or machine-set, text is erased from the existing
   render(s), and new renders are produced **for every language present in that CSV row** using the
   mode appropriate to its classification

4. **Given** the full pipeline run over `dataset/`
   **When** it completes
   **Then** new, complete `.comics` files (original content plus newly rendered per-language
   balloon layers, with `data.json` updated accordingly) are written to
   `apps/comics-ai-baloons/work/`, `dataset/` is untouched, and a report enumerates every balloon's
   outcome (rendered + languages, or skipped + reason)

### Should Have

- Both human visual review **and** an automated/quantitative metric per balloon/language
- A separate freehand (no-selectable-font) rendering track explored in parallel, per prior
  direction, independent of the hand-lettering-specific track
- Layout-mode font selection built as a pluggable step (future: auto-picked from balloon examples)

### Won't Have (This Iteration)

- Integration into `apps/comics-editor-v2.9` itself — standalone pipeline only this iteration
- Modifying anything under `dataset/`
- A production-grade, artist-indistinguishable hand-lettering model — best-effort this iteration
- Automatic font matching/selection from balloon lettering examples for machine-set balloons
  (deferred, see below)
- Support for brand-new balloon shapes that don't already exist in `dataset/` (deferred, see below)

### Deferred (Explicitly Tracked, Not Silently Dropped)

1. **Arbitrary new balloon input** (not from `dataset/`) — deferred from the prior round; still
   deferred. Revisit if cheap during implementation.
2. **Automatic font matching** for machine-set balloons — deferred; keep the font step pluggable.
3. **Best-effort (non-skip) matching mode** — this iteration always skips + logs on low-confidence
   CSV/language matches per user decision; a future "best guess anyway" mode is not built now but
   could be added later without redesign.

## Constraints

- **Technical**: `dataset/` is read-only; all output goes to `apps/comics-ai-baloons/work/`.
  Balloon detection must be structural (`data.json`), not filename-regex-based. CSV-to-balloon
  matching must be content-based (OCR + fuzzy text match), not index-based.
- **Language coverage**: all ~20 languages in the CSV are in scope for this iteration (user
  decision — not phased). This includes RTL scripts (he, ar), CJK (zh, ja, ko — different
  line-wrapping rules, need CJK-covering fonts), and Indic scripts (hi, ta, mr, bn, ne, kn — complex
  glyph shaping/conjuncts). Plain raster text-drawing (e.g. PIL alone) is unlikely to correctly
  shape RTL/Indic text — a proper text-shaping approach (e.g. HarfBuzz/Pango, or headless-browser
  HTML/CSS rendering) needs to be selected in Specifications. This is a significant technical risk
  to size honestly in the Plan phase.
- **Data volume**: 27 `.comics` files; balloon count and hand-lettered proportion still being
  established via survey.
- **Performance**: not yet critical — offline batch pipeline.
- **Platform**: offline script/pipeline this iteration; future integration into
  `apps/comics-editor-v2.9` must not be precluded.
- **Dependencies**: none blocking.

## Open Questions

Resolved during this round of elicitation (kept for traceability):

- [x] **Unmatched/ambiguous balloons** → skip + log, never guess.
- [x] **Hand-lettered balloons** → auto-classify, and pursue a dedicated model/approach for them
      (not just flag-and-skip).
- [x] **Output location** → new `.comics` files under `apps/comics-ai-baloons/work/`; `dataset/`
      untouched.
- [x] **Language scope** → all ~20 CSV languages is the success criterion for this iteration.

Carried over from the prior round, still open — to resolve in Specifications:

- [ ] **Freehand mode fidelity bar** / **hand-lettering track fidelity bar**: what counts as an
      acceptable result for the two non-layout tracks?
- [ ] **Automated metric definition(s)**: exact metric(s) — OCR round-trip per language,
      reconstruction-error for erase mode, etc.
- [ ] **Layout-mode font candidate(s)**: which font(s) to use per script (Latin/Cyrillic font
      likely already identifiable from samples; CJK/Indic/RTL fonts need sourcing — one font
      typically can't cover all 20 languages).

New from this round — to resolve in Specifications:

- [ ] **Text-shaping approach** for RTL/CJK/Indic rendering (HarfBuzz/Pango bindings vs. headless
      browser rendering vs. another approach).
- [ ] **OCR engine/approach** for reading baked-in `en`/`ru` text (needed both for CSV matching and
      for language inference on un-tagged image slots).
- [ ] **Hand-lettering classifier approach**: heuristic vs. small trained model; what
      signal(s) to use.
- [ ] **CSV fuzzy-match confidence threshold**: how to decide "confident enough to proceed" vs.
      "skip + log" — needs a concrete scoring approach.

## References

- `dataset/*.comics` — source data, read-only (zip: `data.json` + `layers/*.png`)
- `dataset/Translation - Mahabharata Book 1.csv` — translations, ~20 languages, keyed by
  `P<page>_<bubble>`
- `apps/comics-ai-baloons/work/survey.json` — full per-file balloon-layer survey (generated by
  `apps/comics-ai-baloons/scripts/survey_dataset.py`)
- Future integration target: `apps/comics-editor-v2.9`

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-07-30
- [x] Notes: Approved as-is (v0.3 content, promoted to 1.0). Several implementation-shaped
      questions were intentionally left open for Specifications rather than blocking approval —
      see "Open Questions" above.
