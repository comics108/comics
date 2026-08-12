# Implementation Plan: comics-ai-bhagavadgita-generator

> Version: 0.8 (2026-08-11, APPROVED by direct implementation instruction): all mandatory human
> gates are replaced by fail-closed automated reviewers defined in Requirements v0.9 and
> Specifications v0.10. Human review is optional and never on the critical path.

> Version: 0.7 (2026-08-10, APPROVED): replacement production asset-first Plan derived from approved
> Specifications v0.9. Phases 1-9 remain implemented regression infrastructure. The v0.6 direct
> panorama/U-Net-bbox/known-underperforming-positioner/heuristic-animation Phase 10 remains
> historical and MUST NOT be implemented. Active production work is defined below as Phases 10-13.
> Status: APPROVED — explicit `plan approved` received 2026-08-10; implementation may proceed
> Last Updated: 2026-08-10
> Specifications: [02-specifications.md](./02-specifications.md) (v0.10 APPROVED)

## Note on drafting order

This Plan was drafted per Anton's explicit `resume comics-ai/sdd-comics-ai-bhagavadgita-generator
plan` instruction, moments before his separate, real "specs approved" message landed for
`02-specifications.md` v0.2. No conflict: Specifications didn't change between drafting this Plan
and that approval, so this document's content is unaffected — noted here only so the timing isn't
confusing when read back later. This Plan received its own explicit `plan approved` on 2026-08-10.

## Summary

Nine phases, ordered by real dependency, matching Specifications' own Repository Layout and System
Context diagram: dataset loading → storyboard (deterministic, optional Ollama) → card rendering →
chapter-5 PSD enrichment → layout/tiling → `.comics` packaging → validation → CLI orchestration →
real production run and real verification. The Must-Have completion path (Phases 1, 2's
deterministic branch, 3, 5, 6, 7, 8, 9) never depends on Ollama or `psd-tools` — both checked this
session and handled as optional, gracefully-degrading enrichments, consistent with Requirements'
"deterministic path is the release gate" decision.

**Real environment facts checked before estimating complexity** (2026-08-06, this session):
Playwright is installed in `apps/comics-ai/comics-ai-baloons/.venv` and its bundled Chromium
launches successfully — the card-rendering stage (the riskiest new component) is de-risked, not
speculative. **Correction, same day**: `psd-tools` was first checked against the wrong Python
interpreters (`python3` and `comics-ai-baloons`'s own `.venv`, neither of which had it) and reported
as absent. Anton pointed at the real one: `/opt/homebrew/bin/python3.14` (whose `sys.path` includes
`/Users/anton/Library/Python/3.14/lib/python/site-packages`, a user-site install) has
**`psd-tools` 1.17.4, confirmed importable** by direct check. The chapter-5 PSD adapter (Task 4.1)
is therefore de-risked too, not just the deterministic fallback — real compositing against the
actual PSDs should be attempted for real during Implementation, not assumed to degrade to warning-
only. Both corrections are reflected in Task 4.1 and Risk Assessment below.

The active replacement adds four production phases after that implemented baseline: canonical
source/asset infrastructure; gold data and model competition; story/action/lettering; and golden
chapter composition/release. Each implementation task starts with a failing focused test. Backend
behavioral cases are queued into the related TDD flow, but cannot be written into its `02-tests.md`
until that flow's own Requirements v0.3 are explicitly approved.

## Task Breakdown

### Phase 1: Dataset Loading and Canonical Model

#### Task 1.1: Canonical data model
- **Description**: `SlokaSource`/`CanonicalChapter` frozen dataclasses exactly as specified
  (Specifications' "Canonical Data Model" section).
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/models.py` - Create
- **Dependencies**: None
- **Verification**: unit tests constructing both dataclasses and asserting frozen/immutable
- **Complexity**: Low

#### Task 1.2: CSV loader and dataset-integrity checkpoint
- **Description**: Parse `db_books.csv`/`db_chapters.csv` (comma) and `Gita_Slokas.csv`
  (semicolon, `utf-8-sig`), filter to `BookId==1`, join `ChapterId`→`db_chapters.Id`, sort by
  numeric `Order` (Id as tie-breaker only), reject missing/duplicate orders and empty required
  fields. Assert exactly chapter orders 1-18 and exactly 663 slokas — dataset-integrity checks per
  Specifications, not hardcoded discovery.
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/load_dataset.py` - Create
- **Dependencies**: Task 1.1
- **Verification**: unit tests on small fixture CSVs (malformed rows, duplicate orders, empty
  fields all correctly rejected); one real integration test against the actual
  `dataset/bhagavadgita/spiritual_text/*.csv` files asserting the exact 18/663 checkpoint
- **Complexity**: Medium (real-world CSV quirks — BOM, embedded newlines in quoted fields already
  observed this session in `db_quoutes.csv` — need careful `csv` module usage, not manual splitting)

### Phase 2: Storyboard

#### Task 2.1: Deterministic storyboard (no AI)
- **Description**: `StoryScene`/`ChapterStoryboard` dataclasses; the deterministic fallback mode —
  groups contiguous sloka ranges into scenes with no synthetic summary text, `mode="deterministic"`.
  This is the Must-Have path's actual storyboard source.
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/build_storyboard.py` - Create
- **Dependencies**: Task 1.2
- **Verification**: unit test — a known chapter's slokas produce a deterministic, citation-complete
  scene grouping with zero AI involvement
- **Complexity**: Low

#### Task 2.2: Ollama-backed storyboard (optional enrichment)
- **Description**: Chunked per-chapter prompting of `qwen2.5-coder:32b` (reusing
  `sdd-comics-ai-script-context`'s real model choice/precedent), citation validation (reject
  unknown chapter/sloka references, duplicate scene IDs, non-JSON, uncited quotations), raw output
  + prompt hash persistence. Falls back to Task 2.1's deterministic mode on any failure/timeout —
  never blocks the batch.
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/build_storyboard.py` - Modify
- **Dependencies**: Task 2.1
- **Verification**: unit tests against canned model-output strings (well-formed, malformed,
  uncited-quotation, unknown-reference cases — same canned-string testing pattern
  `sdd-comics-ai-script-context`'s `extract_scene.py` already established); one real, marked-slow
  live Ollama call as an integration test, matching that flow's own precedent
- **Complexity**: Medium

### Phase 3: Card Rendering

#### Task 3.1: HTML templates and renderer
- **Description**: Semantic HTML → transparent/full-card PNG via headless Chromium/Playwright,
  bundled Noto fonts, following `comics-ai-baloons`'s `render_shaped.py` pattern directly (real,
  proven precedent — confirmed this session that Playwright + its Chromium binary both work in this
  environment). Verse cards show label, Sanskrit, transcription, Russian translation, source marker;
  all source/model text is HTML-escaped, no markup interpretation.
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/render_cards.py` - Create
- **Dependencies**: Task 1.2 (real sloka records to render)
- **Verification**: unit tests on HTML-escaping/text-wrapping logic; one real rendering test
  producing an actual PNG from a real sloka record and asserting non-empty/non-transparent pixels
  (per Specifications' structural validation) and correct measured dimensions
- **Complexity**: Medium-High (real multi-script text — Devanagari + Cyrillic — shaping correctness
  needs actual visual verification, not just "it rendered without crashing")

#### Task 3.2: Deterministic visual theme
- **Description**: Fixed-seed palette/ornament derivation from chapter order; chapter background,
  title card, and (if present) AI-synopsis card visuals.
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/render_cards.py` - Modify
- **Dependencies**: Task 3.1
- **Verification**: unit test — same chapter order always produces the same theme (deterministic,
  no network/randomness)
- **Complexity**: Low

### Phase 4: Chapter-5 PSD Adapter (Should Have, non-blocking)

#### Task 4.1: PSD composite import
- **Description**: Read-only compositing of the three real chapter-5 PSDs via `psd-tools`, resized
  to content width preserving aspect ratio, inserted as `art` panels. Any failure (missing package,
  decode error, excessive memory) records a warning and the pipeline continues on the deterministic
  baseline — per Specifications, this must never block the 18-chapter Must-Have run.
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/import_psd.py` - Create
- **Dependencies**: None (independent of Phases 1-3, only chapter 5's plan consumes it)
- **Verification**: unit test with `psd-tools` mocked/absent asserting the graceful-warning path
  (still needed — real environments running this pipeline elsewhere may genuinely lack it, even
  though this one doesn't); **a real compositing attempt against the actual three PSD files, using
  `/opt/homebrew/bin/python3.14` where `psd-tools` 1.17.4 is confirmed installed** (corrected
  2026-08-06 — originally mischecked against the wrong interpreter, see Summary)
- **Complexity**: Medium (real files are large — up to 264MB, 4127×26421px per this session's real
  `struct`-level header inspection — memory-bounded streaming/downscaling needs real testing, not
  assumed safe)

### Phase 5: Chapter Layout and Tiling

#### Task 5.1: Layout engine
- **Description**: Vertical continuous-strip layout per Specifications' exact canvas constants
  (1080px width, 72px margins, 32px gaps, computed height with a 32-bit coordinate safety guard).
  Assembles the real layer sequence (background → title → optional AI synopsis → optional PSD
  panels → one verse card per sloka in order).
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/layout_chapter.py` - Create
- **Dependencies**: Tasks 2.1/2.2 (storyboard), 3.1/3.2 (cards), 4.1 (optional PSD panels)
- **Verification**: unit tests on layout math (gap accumulation, safety-guard triggering on an
  artificially huge chapter); real test against chapter 1's actual sloka count producing a plausible
  total height
- **Complexity**: Medium

#### Task 5.2: 512px tiling
- **Description**: Reuse the proven `<stem>_1000_<col>_<row>.png` tiling convention — verified this
  session against a real dataset file's actual tile filenames, byte-for-byte matching Specifications'
  stated contract. Extract as a small shared helper rather than reimplementing, if
  `comics-ai-baloons`'s or `comics-ai-multimodal`'s tiling code can be imported without pulling in
  their heavier dependencies (torch/opencv) — per Specifications' "reuse by contract, not import
  accident" principle; write a fresh, minimal implementation otherwise.
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/tile_assets.py` - Create
- **Dependencies**: Task 5.1
- **Verification**: unit test — a known-size image tiles into the exact expected grid and
  reconstructs byte-identical to the source when stitched back
- **Complexity**: Low-Medium

### Phase 6: `.comics` Packaging

#### Task 6.1: Archive packager
- **Description**: Build `data.json` + `layers/*.png` per the corrected contract (v0.2): **Russian
  content in `images[1]` (the real `Ru` index), `images[0]`/`images[2]` empty** — this was a real
  bug in Specifications v0.1 found and fixed this session (backwards slot assignment vs. the actual
  `Cultures` enum), not a hypothetical edge case. Every layer gets an explicit static
  `TranslateAnim`. Deterministic ZIP entry order/timestamps for reproducible hashes. Staging-then-
  atomic-replace write pattern.
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/package_comics.py` - Create
- **Dependencies**: Task 5.2
- **Verification**: unit tests on the ZIP structure/determinism; **a dedicated regression test
  asserting Russian content lands at `images[1]`, not `images[0]`** (Specifications' own explicitly
  added Structural archive validation item, added alongside the fix — must not silently regress);
  one real round-trip test opening a generated archive back through this app's own reader
- **Complexity**: Medium

### Phase 7: Validation

#### Task 7.1: Structural and source-fidelity validation
- **Description**: All checks in Specifications' "Structural archive validation" and "Source
  fidelity validation" sections — ZIP/JSON well-formedness, layer/tile counts, path safety, the
  new slot-index regression check, source-string round-tripping, AI-citation scope checks.
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/validate_output.py` - Create
- **Dependencies**: Task 6.1
- **Verification**: unit tests per check, each with both a passing and a real failing fixture (not
  only happy-path); real run against Task 6.1's own real output
- **Complexity**: Medium-High (many discrete checks; each needs its own real failure-case test to
  be trustworthy, per this repo's established testing discipline)

#### Task 7.2: Current-application (editor/viewer) validation
- **Description**: A focused Flutter test under `apps/comics-editor/test/` that opens generated
  chapter files through `DartIoCore` when `work/bhagavadgita/` fixtures are present, checking
  dimensions/layer counts/no missing assets — and, separately, one real manual/viewer-launch
  verification per Requirements' Must-Have 10 ("real completion proof... at least one real
  editor/viewer open test rather than relying only on unit tests of the generator").
- **Files**:
  - `apps/comics-editor/test/bhagavadgita_generator_test.dart` (exact path TBD at Implementation) - Create
- **Dependencies**: Task 6.1 (needs real generated files to open)
- **Verification**: this task's own real Dart test run, plus a documented manual open in the actual
  Comics Editor app for at least one generated chapter
- **Complexity**: Medium (touches a different app/language than the rest of this Plan; real
  cross-repo coordination, not just Python)

### Phase 8: Orchestration and Reporting

#### Task 8.1: Manifest and report
- **Description**: `manifest.json` (schema-versioned, per-chapter provenance/validation/hash
  records) and `report.md` (human-readable coverage summary).
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/report.py` - Create
- **Dependencies**: Task 7.1
- **Verification**: unit test on manifest schema/fingerprint computation; real run producing a real
  manifest against Task 6.1's real output
- **Complexity**: Low-Medium

#### Task 8.2: Pipeline CLI, resumability, idempotency
- **Description**: `pipeline.py`'s `--chapter N`/`--all`/`--no-ai`/`--no-psd`/`--force` CLI;
  dataset/config fingerprinting; chapter-level staging locks; continue-after-failure batch
  semantics; non-zero exit when coverage < 18.
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/pipeline.py` - Create
- **Dependencies**: Tasks 1.2, 2.1/2.2, 3.1/3.2, 4.1, 5.1/5.2, 6.1, 7.1, 8.1
- **Verification**: unit tests on fingerprint-based reuse/invalidation logic; a real run with
  `--chapter 1 --no-ai --no-psd` (the fast smoke path) verifying a real valid single-chapter output
  end to end
- **Complexity**: Medium-High (this is the integration point for every prior phase — real
  end-to-end behavior here is what actually matters, not just unit-level correctness of each part)

### Phase 9: Real Production Run and Verification

#### Task 9.1: Full 18-chapter production run
- **Description**: `python scripts/pipeline.py --all`, real execution against the real dataset,
  writing all 18 `.comics` files, `manifest.json`, `report.md` under `work/bhagavadgita/`.
- **Files**: None (execution only)
- **Dependencies**: Task 8.2
- **Verification**: `manifest.json` shows `status="valid"` for all 18 chapter orders 1-18, no
  duplicates, no missing orders — this is Requirements' Must-Have 1, checked for real, not assumed
- **Complexity**: Low (mechanical, once Phases 1-8 are real and tested — but this is where any
  latent integration bug actually surfaces, so budget real debugging time, not zero)

#### Task 9.2: Real completion proof
- **Description**: Run Task 7.2's editor/viewer validation for real against the Task 9.1 output;
  write the final implementation-report entry listing all 18 files and their validation status per
  Requirements' Must-Have 10.
- **Files**:
  - `flows/comics-ai/sdd-comics-ai-bhagavadgita-generator/04-implementation-log.md` - Modify
- **Dependencies**: Task 9.1, Task 7.2
- **Verification**: this task's own real output — the completion report itself, cross-checked
  against the real manifest, not written from memory of what should have happened
- **Complexity**: Low

**Note (2026-08-09)**: a Phase 10 (Bodymovin camera-path/per-layer z-depth extraction) was drafted here
and then **extracted into its own flow**, `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-bodymovin/`,
per Anton's explicit instruction — see that flow's own Plan for the full content, not duplicated here.

### SUPERSEDED Phase 10: direct panorama AI Cut/Arrange/Animate
### Historical draft only; do not implement

**Revision note**: v1 of this Phase (6 tasks: 10.1-10.6, "Horizontal Scroll, Camera Path, Z-Depth")
planned a `scrollType: horizontal` document with an optional Should-Have figure-extraction enrichment
tier. Anton explicitly rejected the horizontal-scroll premise and required AI-model-driven cutting/
arranging/animating as the *core* path, not an optional enrichment — see `02-specifications.md`'s
rewritten "Panoramic PDF Source" section. Tasks 10.1-10.2 (research/mapping) are unchanged; Tasks
10.3-10.6 are replaced by the 8-task sequence below.

#### Task 10.1: Full page-by-page visual review of both PDFs
- **Description**: Requirements' own real finding disclosed only 4 of 12 `All_Black-n-White.pdf`
  pages were visually reviewed (1, 2, 3, 12), with only 2 plausible chapter matches found. Before any
  extraction code is written, review the remaining 8 pages (and confirm the `All_Coloured.pdf`
  page-correspondence, only partially confirmed: color page 2 = B&W page 3) — real, low-cost work
  (render low-DPI previews via `pdftoppm`, already proven this session) that directly determines how
  much of Must-Have 11 (panorama art used where a mapping is confirmed) is actually achievable.
- **Files**: None (research task; may update `01-requirements.md`'s own findings table with
  confirmed results)
- **Dependencies**: None
- **Verification**: this task's own real output — an updated, more complete page-to-content
  inventory, not assumed complete from the 4-page sample
- **Complexity**: Low (mechanical review, already proven fast via low-DPI `pdftoppm` previews)

#### Task 10.2: Chapter-mapping resolution
- **Description**: Using Task 10.1's inventory, resolve as many of the 18 chapters as real evidence
  allows — either Anton's direct review (upgrading entries to `"confirmed"`) or a local-Ollama-
  assisted visual/thematic matching pass (`"inferred"`, per Specifications' Open Design Question —
  exact method decided here, not before). Chapters with no real match stay `"unmapped"` and keep
  today's deterministic fallback (Must-Have 11).
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/import_panorama.py` — Create
    (`CHAPTER_MAPPING` table)
- **Dependencies**: Task 10.1
- **Verification**: every `CHAPTER_MAPPING` entry has a real, cited reason (visual description or
  Anton's direct word) for its `confidence` value — no entry invented to fill out the table
- **Complexity**: Medium (real judgment calls, not mechanical)

#### Task 10.3: `import_panorama.py` — page rendering only
- **Description**: Implement `render_pdf_page` (shells out to `pdftoppm`, already confirmed
  installed and working this session). Real DPI/memory bound needs measuring against at least one
  real page at production scale before committing to a default (Specifications' own flagged Open
  Design Question). No tiling/camera-path logic here — that moves to Tasks 10.6/10.7 below, over the
  *arranged* vertical layout rather than the raw panorama.
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/import_panorama.py` — Modify (adds to
    Task 10.2's file)
- **Dependencies**: Task 10.2
- **Verification**: a real render of at least one confirmed/inferred chapter's real PDF page, checked
  for reasonable output size, not assumed safe
- **Complexity**: High (the real unknown is production-scale memory behavior on pages up to ~108in
  wide — not proven at any real scale yet, only at low-DPI preview resolution)

#### Task 10.4: Cutting — tiled inference against `comics-ai-multimodal`'s trained segmenter + region dedup
- **Description**: Implement `cut_panorama_regions`: slide a window across the rendered panorama
  (window size/overlap determined by real experiment against the segmenter's actual training-image
  scale — not assumed), call `comics-ai-multimodal/scripts/infer_segmenter.py`'s real
  `infer_regions_with_crops` per window (reusing that module directly, same import-bridge convention
  `comics-ai-positioning`/`comics-ai-animations` already use for `comics-multimodal`), map window-
  local bboxes to panorama-global coordinates, and deduplicate regions straddling window boundaries
  (real open problem — an IoU-based merge across adjacent windows is the natural first approach, not
  assumed sufficient without real testing against actual multi-window output). Domain-shift risk
  (Mahabharata-photo-trained model against Gita hand-drawn line art) is real and unverified — this
  task's own verification must include a real visual spot-check, not just "did it return regions."
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/import_panorama.py` — Modify
- **Dependencies**: Task 10.3
- **Verification**: unit test for the dedup logic against a synthetic multi-tile figure-straddling
  case; real cutting output for at least one confirmed/inferred chapter's page, visually spot-checked
  against the source panorama for plausibility (not assumed correct just because it ran)
- **Complexity**: High (tiling-window calibration and cross-tile dedup are both real, unresolved
  engineering problems; domain-shift accuracy is unverified)

#### Task 10.5: Arranging — `comics-ai-positioning`'s trained positioner
- **Description**: Implement `arrange_regions_vertically`: feed Task 10.4's `CutRegion`s (kind,
  global bbox, reading-order index derived from real horizontal panorama position) into
  `comics-ai-positioning/scripts/infer_positioner.py`'s real `position_page_with_model` (backed by
  the real trained `work/comics-ai-positioning/positioner_model.joblib`), reusing that module
  directly rather than reimplementing its logic. Must carry forward, in code comments and the
  manifest (Task 10.8), that flow's own documented finding that this learned model did not beat its
  own calibrated baseline in held-out evaluation — used here on Anton's explicit instruction, not
  because it's proven superior.
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/import_panorama.py` — Modify
- **Dependencies**: Task 10.4
- **Verification**: unit test comparing this function's output against a direct call into
  `comics-ai-positioning`'s own `position_page_with_model` for the same input, confirming no
  divergence introduced by the adapter layer; a real bounds/overlap check on at least one chapter's
  real arranged output
- **Complexity**: Medium (real cross-app integration, but the model/logic itself is already built and
  proven elsewhere — the new work is the adapter, plus a real off-canvas/overlap bounds clamp per
  Specifications' Edge Cases, not yet proven safe for panorama-derived region shapes/sizes)

#### Task 10.6: Animating + `cameraPath` — `comics-ai-animations`' Mahabharata-calibrated reveal model
- **Description**: Implement `animate_arranged_regions` (calls `comics-ai-animations/scripts/
  baseline_transform.py`'s real `propose_reveal(kind, stats)` per arranged region, mapping results to
  `TranslateAnim`/`AlphaAnim` keyframes) and `build_camera_path_from_reveal_density` (same density-
  lingering principle as the withdrawn draft, now driven by real per-region reveal timing/position
  over the vertical layout, emitting real non-zero `y` motion).
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/import_panorama.py` — Modify
- **Dependencies**: Task 10.5
- **Verification**: unit test for `animate_arranged_regions` against known region kinds, asserting
  output matches direct calls into `comics-ai-animations`' own `propose_reveal`; unit test for
  `build_camera_path_from_reveal_density` against synthetic arranged regions with known reveal
  density, asserting the remapped curve concentrates scroll distance in dense spans
- **Complexity**: Medium (real cross-app integration, model/logic already built and proven elsewhere;
  the density-to-cameraPath remapping is new but structurally identical to the withdrawn draft's
  already-designed algorithm, just re-pointed at a different input)

#### Task 10.7: Extend `package_comics.py` for AI-arranged layers + per-layer `zDepth` + document-root `cameraPath`
- **Description**: `build_data_json` needs to accept the arranged/animated/z-depth-tagged regions
  from Tasks 10.4-10.6 as ordinary layers (no `scrollType` parameter needed — vertical is the
  existing default) plus the same document-root `cameraPath` list shape the sibling Bodymovin flow
  already specified for its own `package_comics.py` extension — **reuse that same extension, not
  duplicate it**. Coordinate with `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-bodymovin`'s own Task
  1.4 if both are implemented — whichever lands first should leave the `cameraPath`-writing code in a
  shape the other can reuse directly.
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/package_comics.py` — Modify
- **Dependencies**: Task 10.6
- **Verification**: existing Phase 6 tests (18-chapter static-placement path) unchanged and still
  green; new tests for per-layer `zDepth` and document-root `cameraPath` output on a real
  panorama-sourced chapter
- **Complexity**: Medium (mostly plumbing, once the sibling flow's own equivalent extension exists to
  coordinate with — real risk if both flows implement divergent shapes independently)

#### Task 10.8: Manifest/report disclosure (mapping confidence + domain-shift + positioning-model caveats)
- **Description**: Per Must-Have 13, every affected chapter's manifest/report entry states: its
  `CHAPTER_MAPPING` confidence value verbatim; the segmenter's unverified Mahabharata→Gita
  domain-shift risk; and the positioning model's own documented "did not beat its calibrated
  baseline" finding, carried forward rather than silently presented as proven-superior. Three
  distinct disclosures, all real, none optional.
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/report.py` — Modify
- **Dependencies**: Task 10.7
- **Verification**: real generated report inspected for all three disclosure texts, for a real
  chapter exercising each mapping case (confirmed, inferred, unmapped)
- **Complexity**: Low

### ACTIVE Replacement Phase 10: Semantic Source Inventory and Asset Graph

#### Task 10.1: Production models and versioned stores
- **Status**: COMPLETE (2026-08-10) — implemented test-first; see `04-implementation-log.md`.
- **Description**: Add `SourceRecord`, `SourceSemanticScope`, `Asset`, `AssetVersion`, lineage,
  review, and immutable version-store primitives exactly as specified. Enforce staging, validation,
  atomic rename, and source-root read-only boundaries.
- **Files**: `scripts/production_models.py`, `scripts/production_store.py`, focused tests — Create.
- **Dependencies**: Implemented Phase 1 models only.
- **Verification**: start with one failing test for immutable version creation and one for forbidden
  source-root writes; run the focused test after each smallest implementation step.
- **Complexity**: Medium.

#### Task 10.2: Source inventory and semantic-scope gate
- **Status**: COMPLETE (2026-08-10) — real 24-source inventory generated; filename-only mapping
  rejection and read-only/determinism verified; see `04-implementation-log.md`.
- **Description**: Inventory native sources with hashes/media facts and a reviewed scope registry.
  Seed the verified facts: Bodymovin `unzip/1` = standalone 9-stanza Gita Dhyanam; `app_BG._chiba5.psd`
  = chapter 5 verses 5.14-5.29; `5_1.psd`/`5_2.psd` = its source components. Reject filename-only
  chapter inference.
- **Files**: `scripts/inventory_sources.py`, scope fixture/registry, tests — Create.
- **Dependencies**: Task 10.1.
- **Verification**: failing-first tests explicitly reject `unzip/1 -> chapter 1`, `S3_B1_C1` as
  canonical numbering, and `5_1`/`5_2` as verse identifiers; real inventory leaves dataset hashes
  unchanged.
- **Complexity**: Medium.

#### Task 10.3: Native PSD/PDF/Bodymovin/`.comics` recovery adapters
- **Status**: COMPLETE (2026-08-11) — all four native adapters verified against real sources;
  5/5 focused and 106/106 full tests pass; see `04-implementation-log.md`.
- **Description**: Recover native hierarchy, RGBA, masks, transforms, text/audio provenance, and
  component links before flattened fallback. Reuse the separate Bodymovin flow's parser contract while
  treating camera/depth as evidence rather than gold truth.
- **Files**: `scripts/adapters/{psd,pdf,bodymovin,comics}.py`, tests — Create; shared parser imports only
  through stable adapters.
- **Dependencies**: Task 10.2.
- **Verification**: real-source tests assert PSD descendant/group checkpoints, 15 chapter-5 text
  groups, 9 RU/EN Dhyanam overlays, and recovered bitmap masks for separable alpha layers.
- **Complexity**: High.

#### Task 10.4: Asset graph, identity proposals, review and invalidation
- **Status**: COMPLETE (2026-08-11) — append-only identity/entity history, immutable graph/review
  snapshots, transitive approval invalidation, and mask acceptance gate; 4/4 focused and 110/110
  full tests pass; see `04-implementation-log.md`.
- **Description**: Persist asset/entity links, candidate revisions, merge/split decisions, and graph
  invalidation of dependent approvals without mutating historical releases.
- **Files**: `scripts/asset_graph.py`, `scripts/reviews.py`, tests — Create.
- **Dependencies**: Task 10.3.
- **Verification**: failing-first graph tests for uncertain identity, merge/split history, upstream
  invalidation, and rejection of bbox-only foreground acceptance.
- **Complexity**: High.

### ACTIVE Replacement Phase 11: Gold Data and Model Competition

#### Task 11.1: Gold v1 annotation/evaluation dataset
- **Status**: COMPLETE (2026-08-11) — immutable `gold-v1-2026-08-11` contains 130 artifact-verified
  true masks across 5 source-disjoint compositions (90 PSD train + 40 panorama test); 121/121 full
  tests pass. Unresolved panorama identity is explicitly non-principal and not identity Gold.
- **Description**: Build the specified minimum 120 accepted foreground instances across at least
  four source-disjoint compositions, including 30 held-out instances. Store true masks, semantic/
  principal-identity labels, reversible source coordinates, and versioned automated decisions.
- **Files**: `scripts/build_gold_dataset.py`, annotation manifests/tools/tests — Create.
- **Dependencies**: Task 10.4 and autonomous mask-review consensus; no human gate.
- **Verification**: split-leakage, mask-shape, count, provenance, and automated-review tests; no
  box-shaped bootstrap label silently enters gold.
- **Complexity**: High.

#### Task 11.2: Compact local segmenter competition
- **Status**: COMPLETE (2026-08-11) — bbox fill, classical ink, legacy U-Net, legacy Mask R-CNN,
  and a newly trained compact binary U-Net were benchmarked on the same 40 held-out instances.
  None passed; immutable decision is `no_candidate_promoted`, so production cutting stays blocked
  instead of silently retaining a failing checkpoint.
- **Description**: Benchmark current U-Net/bbox and wired Mask R-CNN candidates, shortlist
  license-compatible compact instance segmenters, train viable candidates locally on M4 Max, and
  promote only a candidate beating baselines on mask/boundary plus automated artifact metrics.
- **Files**: `scripts/train_segmenter.py`, `scripts/evaluate_segmenter.py`, model/evaluation records,
  tests — Create.
- **Dependencies**: Task 11.1.
- **Verification**: reproducible source-disjoint evaluation report; licensing and visual-review
  gates remain explicit and fail closed even if no candidate is promoted.
- **Complexity**: High.

#### Task 11.3: Identity/style retrieval and classification
- **Status**: COMPLETE (2026-08-11) — 130 deterministic visual descriptors and palette/style
  proposals plus 130 top-5 retrieval rankings published. Canonical identity and semantic-model
  promotion abstained because Gold lacks principal identity labels and class-complete train data;
  similarity produced zero silent identity merges. 128/128 tests pass.
- **Description**: Produce reviewable entity/kind/style/palette/pose/expression/costume proposals;
  similarity may rank but never confirm canonical identity.
- **Files**: `scripts/classify_assets.py`, `scripts/retrieve_assets.py`, tests — Create.
- **Dependencies**: Tasks 10.4 and 11.1.
- **Verification**: gold macro-F1/retrieval metrics, calibrated uncertainty and abstention tests.
- **Complexity**: High.

#### Task 11.4: B&W/colour registration and colourization
- **Status**: COMPLETE (2026-08-11) — six unique high-margin ORB/RANSAC registrations, 24 paired
  crops, and invalid masks published. Registered edge F1 is 0.975-0.992. Deterministic and compact
  learned colourizers preserved ink but failed held-out palette error, so neither was promoted.
  132/132 tests pass.
- **Description**: Resolve and review six coloured-to-B&W page matches, register geometry, create
  paired crops/invalid masks, compare deterministic palette transfer and learned colourization,
  rejecting line/anatomy/iconography drift.
- **Files**: `scripts/register_panorama_pairs.py`, `scripts/colourize_assets.py`, tests — Create.
- **Dependencies**: Tasks 10.3 and 11.1.
- **Verification**: automatically verified mapping table, registration error thresholds,
  ink-preservation metrics, held-out evaluation, and artifact gate.
- **Complexity**: High.

### ACTIVE Replacement Phase 12: Story Coverage, Actions, and Exact Lettering

#### Task 12.1: Story beats and coverage for golden chapters 1 and 11
- **Status**: COMPLETE (2026-08-11) — six beats per golden chapter cover every source sloka exactly
  once. Published prose is exact cited source text and visual requirements remain empty rather than
  invented. Coverage resolves all 12 visual gaps as local `generation_required`; inferred panorama
  mappings and Gita Dhyanam cannot satisfy canonical coverage. 137/137 tests pass.
- **Description**: Build at least six grounded, reviewed beats per golden chapter and resolve every
  entity/action/location/shot requirement to accepted source, reuse, transform, explicit generation
  gap, or blocker. Gita Dhyanam cannot count toward canonical chapter coverage.
- **Files**: `scripts/build_story_beats.py`, `scripts/resolve_coverage.py`, tests — Create.
- **Dependencies**: Tasks 10.4 and 11.3.
- **Verification**: citation completeness, deterministic ordering, minimum-beat/exception gate, and
  paid-generation suppression whenever a lower-tier accepted asset satisfies coverage.
- **Complexity**: High.

#### Task 12.2: Provider-neutral action/candidate runner
- **Status**: COMPLETE (2026-08-11) — immutable fingerprinted requests, action-bound authorization,
  paid-budget/reference-upload denial, proposed-only candidates, lineage, local execution, cached
  replay, and disabled-by-default `gpt-image-2` adapter implemented. Real run: 12 actions, 24 plan
  candidates, 12/12 replay cache hits, zero external calls/cost. 142/142 tests pass.
- **Description**: Implement immutable local/external action requests, idempotency, candidate
  versions, authorization/budget/upload records, and cached retries. `gpt-image-2` stays disabled
  without explicit paid-call/reference-upload authority.
- **Files**: `scripts/action_runner.py`, provider interfaces/local provider/gpt-image-2 adapter,
  tests — Create.
- **Dependencies**: Tasks 10.4 and 12.1.
- **Verification**: no duplicate candidate/paid call on retry, denied upload/budget paths, lineage
  completeness, and multiple-candidate review behavior using fakes unless separately authorized.
- **Complexity**: High.

#### Task 12.3: Exact multilingual lettering
- **Status**: COMPLETE (2026-08-11) — published a 267-entry authoritative corpus for chapters 1 and
  11 (89 slokas × RU/EN/Sanskrit), with dynamic EN/RU runtime slots and Sanskrit retained as a
  separate authoritative content role rather than inventing a Hindi slot. Deterministic Chromium
  shaping retains region/glyph/RGBA masks, gates fit/collision/readability, and requires normalized
  exact Tesseract readback. Six real fixtures fit without collisions; 3 passed and 3 were correctly
  rejected only for exact OCR mismatch. Production release remains blocked until real accepted
  balloon/caption masks replace proof regions and all OCR gates pass. 146/146 tests pass.
- **Description**: Retain balloon/caption bitmap masks, shape authoritative RU/EN/Sanskrit strings
  deterministically, apply learned style only after glyph-mask creation, and block promotion on
  normalized exact-string/OCR/readability failure.
- **Files**: `scripts/lettering.py`, text-region models, renderer adapters, tests — Create/Modify.
- **Dependencies**: Tasks 10.3 and 12.1.
- **Verification**: exact strings, slot/language mapping, mask retention, complex shaping, overflow,
  OCR mismatch, deterministic readability, collision, and viewport fixtures.
- **Complexity**: High.

### ACTIVE Replacement Phase 13: Golden Composition and Release

#### Task 13.1: Vertical composition, depth, camera and animation candidates
- **Status**: COMPLETE (2026-08-11) — deterministic rule and optional learned-positioner candidates
  share one vertical/portrait contract, retain editable RGBA/mask references, preserve beat order,
  and gate bounds, overlap, depth, camera, and runtime packaging structure. Heuristic animation and
  camera/depth remain `proposed`, explicitly not artist intent. The real golden summary emits zero
  candidates and remains blocked because chapters 1 and 11 each have zero accepted coverage assets
  and six missing beats. Immutable summary SHA-256
  `49a0f926c351e9b8b5f5bd49af699bb6314d4ce1b69ff31a55d981bfd5e6f7b0`; 149/149 tests pass.
- **Description**: Compose accepted golden-chapter assets into coherent vertical strips, preserve
  editable layers, compare rule/learned proposals, and emit format-compliant camera/z-depth using
  shared contracts. No heuristic is promoted as artist intent without review.
- **Files**: `scripts/compose_production.py`, packager adapter, tests — Create/Modify.
- **Dependencies**: Tasks 11.2-11.4 and 12.1-12.3.
- **Verification**: overlap/seam/bounds/read-order tests plus real viewer comparison on chapter 1
  and 11 candidates.
- **Complexity**: High.

#### Task 13.2: QA, review registry and immutable release compiler
- **Status**: COMPLETE (2026-08-12) — a six-dimension immutable gate compiler now requires complete
  unique decisions, checksummed release artifacts, and all-approved state; reject, abstain, stale,
  missing dimension, or missing artifact blocks publication. Dependency hash drift marks prior
  approvals stale. Real golden validation records technical/art-direction/lettering rejected and
  identity-style/cultural-editorial/runtime abstained, emits no archive, and has SHA-256
  `0890850121df3fd7a2e9176dcbd3aa4e992664bbcf85789b6478c08e9373dab2`; 153/153 tests pass.
- **Description**: Implement automated mask/halo/seam/identity/style/lettering/archive/runtime gates,
  six independent automated review dimensions, release-level state machine, immutable manifest, and
  dependency invalidation.
- **Files**: `scripts/validate_production.py`, `scripts/release.py`, report/CLI/tests — Create/Modify.
- **Dependencies**: Task 13.1.
- **Verification**: format-valid draft cannot become release; every missing/abstaining automated gate blocks;
  historical release stays immutable after upstream revision; editor/viewer/device opens are real.
- **Complexity**: High.

#### Task 13.3: Golden chapter production run and scale-out decision
- **Status**: COMPLETE (2026-08-12) — immutable proof verifies 13 production manifests and both
  golden chapters. Each chapter has six grounded beats but 0 accepted coverage assets, six
  generation gaps, and 0 composition candidates; lettering remains 3/6; six review dimensions are
  3 rejected + 3 abstained. Golden release and all-18 scale-out are therefore blocked. The proof
  contains a five-step autonomous remediation order and explicitly requires no human participation.
  SHA-256 `70a451c20c0bc7208730dedec6ee1ac1737937be3965d4ff915ff36f0f09e780`;
  154/154 tests pass.
- **Description**: Generate machine-reviewed candidates for chapters 1 and 11, record all gaps and
  metrics, and run automated art-direction/cultural/editorial verification. Only after both become `release` is
  an all-18 scale-out Plan amendment allowed.
- **Files**: `work/bhagavadgita/production/**`, `04-implementation-log.md` — Generate/Modify.
- **Dependencies**: Task 13.2 automated reviewers.
- **Verification**: real immutable release manifests and device opens for both chapters; otherwise
  report precise candidate/blocker state without claiming production completion.
- **Complexity**: High.

### Cross-flow TDD synchronization

At each task above, add the corresponding case to the incoming backlog of
`comics-backend/tdd-comics-backend-endpoints-v2026-ai`. Do not create/modify that flow's
`02-tests.md` until its Requirements v0.3 receive their own explicit `requirements approved`; this
Plan cannot bypass another flow's TDD gate.

## Dependency Graph

```
1.1 -> 1.2 ─┬─> 2.1 -> 2.2 ─┐
            ├─> 3.1 -> 3.2 ─┼─> 5.1 -> 5.2 -> 6.1 -> 7.1 ─┬─> 8.1 ─┐
            └─────────────────┘                            │        ├─> 8.2 -> 9.1 ─┬─> 9.2
                                                              7.2 ────┘                │
                                                    (needs 6.1's real output) ─────────┘
4.1 (independent) ─────────────────────────────────> feeds into 5.1 for chapter 5 only

ACTIVE:
10.1 -> 10.2 -> 10.3 -> 10.4 -> 11.1 -> 11.2 ─┐
                              ├──────> 11.3 ─────┼─> 12.1 -> 12.2 ─┐
                              └──────> 11.4 ─────┤          12.3 ─┼─> 13.1 -> 13.2 -> 13.3
                                                └─────────────────┘

The historical v0.6 Tasks 10.1-10.8 above are excluded from this graph and MUST NOT execute.
```

## File Change Summary

| File | Action | Reason |
|---|---|---|
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/models.py` | Create | Canonical dataclasses (Task 1.1) |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/load_dataset.py` | Create | CSV loader + integrity checkpoint (Task 1.2) |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/build_storyboard.py` | Create | Deterministic + Ollama storyboard (Tasks 2.1-2.2) |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/render_cards.py` | Create | HTML/Playwright card rendering + theme (Tasks 3.1-3.2) |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/import_psd.py` | Create | Chapter-5 PSD adapter (Task 4.1) |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/layout_chapter.py` | Create | Canvas layout (Task 5.1) |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/tile_assets.py` | Create | 512px tiling (Task 5.2) |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/package_comics.py` | Create | `.comics` archive writer, corrected slot layout (Task 6.1) |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/validate_output.py` | Create | Structural/fidelity validation (Task 7.1) |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/report.py` | Create | Manifest + report (Task 8.1) |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/pipeline.py` | Create | CLI orchestration (Task 8.2) |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/tests/*` | Create | Unit/integration tests per task above |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/README.md` | Create | Per Specifications' Repository Layout |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/requirements.txt` | Create | Pillow, Playwright, psd-tools, pytest |
| `apps/comics-editor/test/bhagavadgita_generator_test.dart` | Create | Real editor-loader validation (Task 7.2) |
| `work/bhagavadgita/*.comics`, `manifest.json`, `report.md` | Create (gitignored) | Real pipeline output |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/import_panorama.py` | Create (NEW, 2026-08-09, v2) | Panorama page rendering, chapter mapping, AI cutting (`comics-ai-multimodal`), AI arranging (`comics-ai-positioning`), AI animating + reveal-density `cameraPath` (`comics-ai-animations`) (Tasks 10.2-10.6) |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/package_comics.py` | Modify (NEW, 2026-08-09, v2) | Per-layer `zDepth` + document-root `cameraPath` for AI-arranged vertical layers (Task 10.7), coordinated with the sibling Bodymovin flow's own extension |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/report.py` | Modify (NEW, 2026-08-09, v2) | Mapping-confidence + domain-shift + positioning-model-caveat disclosure (Task 10.8) |

*(The Bodymovin camera-path/z-depth extraction's own file changes now live in
`flows/comics-ai/sdd-comics-ai-bhagavadgita-from-bodymovin/03-plan.md` — extracted 2026-08-09, not
duplicated here. Note that flow's own Plan does still modify `package_comics.py`/`pipeline.py`/
`report.py` from this app, a real cross-flow file-ownership fact disclosed in both flows' status
docs.)*

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Scripts run under the wrong Python interpreter can't find `psd-tools` (real mistake this Plan itself made once, corrected by Anton) | Medium | Low | Confirmed `psd-tools` 1.17.4 is real and importable under `/opt/homebrew/bin/python3.14`; Task 4.1's tooling/venv setup must target that interpreter (or an equivalent one with `psd-tools` installed), not assume any `python3` resolves it. Specifications' graceful-fallback path still exists as a safety net for environments that genuinely lack it. |
| Devanagari/Cyrillic text shaping renders incorrectly in a way automated pixel checks don't catch | Medium | Medium | Real visual spot-check of at least a few rendered cards required in Task 3.1's verification, not just "non-empty pixels" — automated checks alone are insufficient for shaping correctness, per this repo's own established lesson from `comics-ai-baloons` |
| The image-slot fix (Task 6.1) regresses if someone edits the packager later without re-reading this Plan/Specifications | Low | High (silent semantic corruption, not a crash — same character as the original bug) | Task 7.1's dedicated regression test is the real guard, not just code comments |
| Task 7.2 (Flutter/Dart editor test) requires real cross-app coordination this Plan's author has less direct visibility into than the Python side | Medium | Medium | Budget real time for this task specifically; do not treat it as a formality — Requirements' Must-Have 10 explicitly requires a *real* editor/viewer open, not a simulated one |
| Large chapter-5 PSDs (up to 264MB, 4127×26421px, confirmed via real header inspection) could exceed reasonable memory during compositing | Medium | Low (Should-Have, non-blocking) | Task 4.1's own fallback path already treats "excessive memory demand" as an expected, handled failure mode |
| **(NEW, 2026-08-09)** Panorama pages up to ~108in wide (confirmed real page size) produce excessively large rasters at production DPI | Medium — not yet measured at real scale, only low-DPI previews so far | High (Task 10.3 specifically; could make chapters practically unusable) | Task 10.3 requires a real, measured DPI/memory bound before committing to a default — not assumed safe by analogy to the PSD case |
| **(NEW, 2026-08-09, v2)** The segmenter's fixed 256×256 input requires tiling a panorama up to ~93,524px wide; cross-tile region dedup is a real, unsolved problem | High — inherent to combining a fixed-input-size model with this source's real dimensions | High (Task 10.4; wrong dedup produces duplicate/split figures throughout every panorama-sourced chapter) | Task 10.4's own unit test targets exactly this case (synthetic figure straddling a tile boundary); real visual spot-check required before trusting output at scale |
| **(NEW, 2026-08-09, v2)** Segmenter, positioner, and reveal-baseline were all trained/calibrated on Mahabharata data, not Bhagavad Gita hand-drawn panorama art — domain-shift accuracy is unverified for all three stages | Medium-High — a real, disclosed, carried-forward risk from this flow's own Existing AI Flow Audit table | Medium-High (could produce visually wrong cuts/placement/timing without any pipeline-level failure signal) | Task 10.8's manifest disclosure is the mitigation for transparency; Tasks 10.4-10.6 each require a real visual spot-check against source panorama as part of verification, not just "the model returned output" |
| **(NEW, 2026-08-09, v2)** `comics-ai-positioning`'s learned model is reused per Anton's explicit instruction despite that flow's own held-out evaluation showing it did not beat its calibrated baseline | Certain — confirmed via that flow's own `_status.md`, not speculative | Low-Medium (a real, disclosed quality tradeoff, not a bug) | Task 10.8's manifest disclosure carries this caveat forward per chapter; not silently presented as though the model were proven superior |
| **(NEW, 2026-08-09)** Chapter-mapping resolution (Task 10.2) yields far fewer than 18 confirmed/inferred chapters, undermining "redesign for all 18 chapters" as originally framed | Medium — only 2/18 found in this session's limited 4-page review | Medium | Task 10.1 (full page review) runs first specifically to reduce this risk before committing engineering effort; Must-Have 11's own design (confirmed mappings only, deterministic fallback otherwise) means a low mapping count degrades gracefully rather than blocking the whole Phase |

## Rollback Strategy

Entirely new app (`apps/comics-ai/comics-ai-bhagavadgita-generator/`) plus generated output under
`work/bhagavadgita/` (gitignored) plus one new Dart test file. Rollback is deleting the new app
directory and the new test file; no existing app's code is modified, no `.comics` schema migration
is introduced, `dataset/bhagavadgita/` is never written to.

**Phase 10 addition (2026-08-09, v2)**: rollback is deleting `import_panorama.py` and reverting the
backward-compatible additions to `package_comics.py`/`report.py` — chapters without a confirmed/
inferred mapping are entirely unaffected either way (they never leave the deterministic path), so
rollback or not, only the (currently 2 of 18) mapped chapters' output changes. No `.comics` schema
change is introduced by this Phase's v2 design (per-layer `zDepth` and document-root `cameraPath`
are both already-additive fields decided elsewhere); rollback never needs to un-write a `scrollType`
value since v2 no longer writes one.

## Checkpoints

After each phase, verify:

- [ ] All unit tests for that phase's tasks pass
- [ ] Any task marked with a "real"/integration verification step has actually been run against
      real data, not just unit-tested in isolation
- [ ] No regression in `apps/comics-ai/comics-ai-baloons`'s own test suite if any of its code/
      conventions were reused (per Specifications' "reuse by contract" principle)

## Open Implementation Questions

- [ ] Exact reuse mechanism for Task 5.2's tiling (import a shared helper vs. a fresh minimal
      implementation) — decide once actually attempting Task 5.2, based on whether
      `comics-ai-baloons`'s tiling code is cleanly importable without its heavier dependencies.
- [ ] Task 7.2's exact Dart test file path and harness — needs a real look at
      `apps/comics-editor/test/`'s existing structure at Implementation time, not guessed here.
- [x] **Resolved**: `psd-tools` is already installed (1.17.4, confirmed under
      `/opt/homebrew/bin/python3.14`) — Task 4.1 should attempt real compositing directly, not defer
      to the fallback path by default. The fallback path still needs its own unit test (mocked/
      absent case), but that's a robustness test now, not the expected real-run outcome.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-06 (`_status.md` records "plan approved") — v0.1, Phases 1-9. This
      section's own checkboxes were never updated at the time, corrected here rather than left
      stale.
- [x] Notes: the Bodymovin camera-path/z-depth extraction Phase (v0.2-v0.3, "Phase 10") was drafted and
      approved here 2026-08-09, then **extracted into its own flow** per Anton's explicit
      instruction — see `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-bodymovin/03-plan.md` for that
      content's own Plan and approval record.
- [x] v0.6 Phase 10 was never approved and is now explicitly superseded by Requirements v0.8. Its
      tasks remain historical evidence only and must not be executed.
- [x] Replacement Plan v0.7 drafted from approved Specifications v0.9 on 2026-08-10.
- [x] Replacement Plan v0.7 explicitly approved with `plan approved` on 2026-08-10.
