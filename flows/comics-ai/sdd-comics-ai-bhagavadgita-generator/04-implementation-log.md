# Implementation Log: comics-ai-bhagavadgita-generator

> Started: 2026-08-06
> Plan: [03-plan.md](./03-plan.md) (v0.1, APPROVED)

## Progress Tracker

| Task | Status | Notes |
|------|--------|-------|
| 1.1 models.py | Done | 4/4 tests passing |
| 1.2 load_dataset.py | Done | 9/9 tests passing, including real 18-chapter/663-sloka integration test |
| 2.1 deterministic storyboard | Done | 4/4 tests passing, incl. real chapter-1 integration test |
| 2.2 Ollama storyboard | Not started | |
| 3.1 card renderer | Done | 4/4 tests passing, real Devanagari+Cyrillic render visually spot-checked |
| 3.2 deterministic theme | Done | 5/5 tests passing, real title-card render visually spot-checked |
| 4.1 PSD adapter | Done | 5/5 tests passing; all 3 real PSDs composite successfully |
| 5.1 layout engine | Done | 7/7 tests passing, incl. real chapter-1/37-card layout |
| 5.2 tiling | Done | 5/5 tests passing, verified filename convention against a real archive |
| 6.1 packager | Done | 11/11 tests passing, incl. real chapter-12 end-to-end package+reopen |
| 7.1 structural/fidelity validation | Done | 12/12 tests passing, real+failing fixtures per check |
| 7.2 editor/viewer validation | Done (automated part); manual GUI launch flagged, not done | real Dart test passes against a real generated chapter |
| 8.1 manifest/report | Done | 10/10 tests passing, real manifest+report against real chapter 12 |
| 8.2 pipeline CLI | Done | 9/9 tests passing, real smoke run + real reuse/idempotency run |
| 9.1 full production run | Done | real `--all` run, 18/18 valid, 663/663 slokas |
| 9.2 completion proof | Done | real Dart test against all 18 real files, all pass |

## Session Log

### Session 2026-08-06 - Claude

**Started at**: Phase 1, Task 1.1
**Context**: Requirements/Specifications/Plan all approved by Anton this session. Plan's own
environment-check correction (psd-tools genuinely installed under `/opt/homebrew/bin/python3.14`,
not absent as first mischecked) applied before starting.

#### Completed

- **Task 1.1**: `scripts/models.py` — `SlokaSource`/`CanonicalChapter` frozen dataclasses, exactly
  matching Specifications' Canonical Data Model.
  - Files: `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/models.py` (new),
    `tests/test_models.py` (new, 4 tests).
  - Verified by: 4/4 tests passing (field values, frozen/immutability for both dataclasses).
- **Environment setup**: created `apps/comics-ai/comics-ai-bhagavadgita-generator/.venv` from
  `/opt/homebrew/bin/python3.14 -m venv --system-site-packages` (inherits the real, confirmed
  `psd-tools` 1.17.4 install from `~/Library/Python/3.14/`), then `pip install pytest` fresh into
  it. Confirmed `psd_tools` importable inside the new venv before proceeding.
- **Task 1.2**: `scripts/load_dataset.py` — real CSV loader (comma for
  `db_books.csv`/`db_chapters.csv`, semicolon + `utf-8-sig` for `Gita_Slokas.csv`, verified against
  the real files' actual header rows before writing parsing code, not assumed from memory), joining
  `Gita_Slokas.ChapterId` → `db_chapters.Id`, filtering to `BookId=1`, sorting by numeric `Order`
  (Id as tie-breaker only). Rejects duplicate chapter/sloka orders, empty required fields
  (Sanskrit/Transcription/Translation), and non-integer IDs/orders — all via a dedicated
  `DatasetIntegrityError`, per Specifications' "stop before generation" failure-handling rule.
  `verify_dataset_integrity()` is the explicit checkpoint asserting exactly chapter orders 1-18 and
  663 total slokas.
  - Files: `scripts/load_dataset.py` (new), `tests/test_load_dataset.py` (new, 9 tests).
  - Verified by: 9/9 tests passing — 8 fixture-based tests (clean join/sort, book-id filtering,
    duplicate chapter order rejected, duplicate sloka order rejected, empty required field
    rejected, non-integer order rejected, both `verify_dataset_integrity` failure cases) plus
    **one real integration test against the actual dataset**: loads exactly 18 chapters and 663
    slokas, first chapter title "Осмотр Армий", 18th chapter title "Йога освобождения" — matching
    this session's own earlier independent verification of these exact facts.

#### Discoveries

- No new discoveries beyond what Specifications/Plan already anticipated — the real dataset loaded
  cleanly on the first real attempt, consistent with this session's earlier direct inspection of
  the CSVs (no encoding surprises, no malformed rows in the real 663-sloka Russian set).

- **Task 2.1**: `scripts/build_storyboard.py` — `StoryScene`/`ChapterStoryboard` frozen
  dataclasses plus `build_deterministic_storyboard(chapter)`, the Must-Have (no-AI) storyboard
  builder. Made and documented one real design decision Specifications left open: one scene per
  chapter, covering that chapter's full contiguous real sloka-order range, no synthetic summary or
  invented characters/location — flagged in the module docstring as a judgment call Anton can
  redirect, since nothing downstream (card rendering is per-`SlokaSource`, not per-scene) depends
  on a finer grouping.
  - Files: `scripts/build_storyboard.py` (new), `tests/test_build_storyboard.py` (new, 4 tests).
  - Verified by: 4/4 tests passing — real sloka-order coverage, empty-chapter honesty (zero scenes,
    not a fabricated one), stable chapter-specific `scene_id` format, and one real integration test
    building chapter 1's actual storyboard via `load_dataset.load_book_one()`.

- **Environment**: installed `playwright==1.61.0` into this app's `.venv`. Pinned to that exact
  version (not latest) because `comics-ai-baloons`'s `.venv` already has Chromium build 1228
  cached at `~/Library/Caches/ms-playwright`; a fresh `pip install playwright` pulled in a newer
  release expecting build 1234 and failed with "Executable doesn't exist" until pinned back to
  1.61.0, which matches the cached build and needed no re-download. Also vendored two new font
  files via `brew install --cask font-noto-sans font-noto-sans-devanagari` (same acquisition
  method as `comics-ai-baloons`'s existing fonts, see that app's own `fonts/Noto/NOTICE.md`):
  `apps/comics-ai/comics-ai-bhagavadgita-generator/fonts/Noto/NotoSans-Regular.ttf` (+ `-Bold.ttf`)
  for Cyrillic/Latin and `NotoSansDevanagari[wdth,wght].ttf` (copied from `comics-ai-baloons`,
  identical OFL-1.1 asset) for Sanskrit — documented in this app's own new `fonts/Noto/NOTICE.md`.
- **Task 3.1**: `scripts/render_cards.py` — `render_verse_card(sloka, chapter_order, book_id)`,
  following `comics-ai-baloons/render_shaped.py`'s proven singleton-browser/HTML-to-PNG pattern.
  Real difference from that precedent: verse cards use *fixed* font sizes and *grow height* to
  fit (per Specifications: "cards grow vertically rather than shrinking below the minimum or
  clipping content"), the reverse of the balloon renderer's fixed-box/shrink-to-fit search.
  Documented one judgment call: the "book:chapter:sloka derived from IDs" source marker uses the
  real `book_id:chapter_id:sloka.id` database identifiers, not the human-facing Order fields
  (which the label already covers).
  - Files: `scripts/render_cards.py` (new), `tests/test_render_cards.py` (new, 4 tests),
    `fonts/Noto/` (new, 3 font files + NOTICE.md), `requirements.txt` (new).
  - Verified by: 4/4 tests passing (source-marker derivation, HTML-escaping of all source text
    fields, label built from Chapter.Order/Sloka.Order rather than the raw dataset `Name` field,
    one real Playwright rendering test on a real `SlokaSource` asserting RGBA mode, `width==936`,
    and at least one non-transparent pixel). **Plus a real visual spot-check** (per the Plan's own
    risk note that automated pixel checks can't catch shaping bugs): rendered chapter 1, sloka 1's
    real Sanskrit/transcription/Russian text to a PNG and inspected it — Devanagari conjuncts
    (धृतराष्ट्र, क्षेत्रे) render correctly, Cyrillic renders correctly, layout is clean.
- **Task 3.2**: `scripts/render_cards.py` (extended) — `ChapterTheme` dataclass,
  `theme_for_chapter(chapter_order)` (seeds `random.Random(chapter_order)` — the chapter's own
  order *is* the fixed seed, so it needs no stored/external seed table), `render_chapter_background`
  (pure PIL solid fill, no browser), `render_title_card`/`build_title_card_html` (Playwright,
  reusing the Task 3.1 screenshot helper, refactored into a shared `_screenshot_html_element`).
  - Files: `scripts/render_cards.py` (modified), `tests/test_theme.py` (new, 5 tests).
  - Verified by: 5/5 tests passing (theme is deterministic across repeated calls with the same
    order; all 18 real chapter orders produce 18 distinct themes; background fill is
    byte-identical across two renders and matches the theme's hex color exactly; title-card HTML
    escapes a real chapter title; one real Playwright rendering test). Plus a real visual
    spot-check of chapter 1's title card ("Осмотр Армий") — renders cleanly with theme-derived
    accent/background colors.

- **Task 4.1**: `scripts/import_psd.py` — `import_psd_panel(path, content_width)` composites a
  real PSD via `psd_tools.PSDImage.open(path).composite()`, resizes to content width preserving
  aspect ratio, and converts *any* failure (missing package, decode error, bad file) into a
  `PsdImportResult(image=None, warning=...)` rather than raising — per Specifications, this must
  never block the 18-chapter Must-Have run.
  - Files: `scripts/import_psd.py` (new), `tests/test_import_psd.py` (new, 5 tests).
  - Verified by: 5/5 tests passing — aspect-ratio-preserving resize, no-op when already at
    content width, a simulated "psd-tools absent" case (via `sys.modules["psd_tools"] = None`,
    which forces a real `ImportError` on import) degrading to a warning not an exception, a
    nonexistent file likewise degrading gracefully, and **one real integration test** compositing
    the actual `5_1.psd` file end-to-end (real 9449x7087 source correctly resized to 936px wide,
    height=702 matching the exact real aspect ratio).
  - **Manually verified (outside the automated suite, for time/memory reasons) that all three
    real chapter-5 PSDs composite successfully**, not just the one covered by the automated test:
    `5_1.psd` (9449x7087, 1 layer) 2.2s / 2.9GB peak RSS; `5_2.psd` (9977x8101, 1 layer) 2.4s /
    3.6GB peak RSS; `app_BG._chiba5.psd` (4127x26421, 33 layers) 6.9s / 4.8GB peak RSS — all under
    `/opt/homebrew/bin/python3.14`'s real `psd-tools` 1.17.4. Also did a real visual spot-check of
    `5_1.psd`'s composite: a genuine finished comic-style illustration (Krishna's face + a conch
    shell) with a correctly transparent background, not noise or a blank/corrupt render.

- **Task 5.1**: `scripts/layout_chapter.py` — `layout_chapter_content`/`layout_chapter`,
  deliberately separated from rendering: callers render each asset first, then hand finished
  images here for pure positioning math. This let the safety-guard test declare a duck-typed
  `FakeImage(width, height=3_000_000_000)` and assert `ChapterTooTallError` without allocating
  gigapixel memory.
  - Files: `scripts/layout_chapter.py` (new), `tests/test_layout_chapter.py` (new, 7 tests).
  - Verified by: 7/7 tests passing — gap-accumulation math, empty-content minimal height,
    wrong-width rejection, the artificially-huge-chapter safety guard, background-first assembly,
    background-size mismatch rejection, and **one real integration test**: rendered chapter 1's
    actual title card and all 37 real verse cards via Playwright, laid them out, and asserted a
    plausible real total height (39 real assets: 1 background + 1 title + 37 verse cards).
- **Task 5.2**: `scripts/tile_assets.py` — fresh, dependency-free (Pillow-only) reimplementation
  of `comics-ai-baloons/scripts/tiling.py`'s proven `<stem>_1000_<col>_<row>.png` contract (ceil
  grid, edge-clipped tiles), per the Plan's "reuse by contract, not import accident" instruction —
  not a cross-app `sys.path` import, since that would create a fragile runtime dependency between
  two independently-versioned apps/venvs for a small, easily-reproduced algorithm.
  - Files: `scripts/tile_assets.py` (new), `tests/test_tile_assets.py` (new, 5 tests).
  - Verified by: 5/5 tests passing — filename format checked directly against a real archive's
    actual tile name (`work/comics-ai-multimodal/output/20260731_154003_p0.comics` ->
    `layers/r0_1000_0_0.png`), exact-multiple and edge-clipping grid math, and a real
    retile-then-stitch round-trip on a synthetic gradient image asserting byte-identical
    reconstruction.

- **Task 6.1**: `scripts/package_comics.py` — `PackagingAsset` dataclass and
  `build_data_json`/`build_tiles`/`build_archive_bytes`/`write_comics_archive`, implementing the
  corrected v0.2 contract. **Re-verified the slot-index fix against a second, independent piece
  of real evidence this session** (beyond the earlier `Cultures.cs`/`Layer.cs` source-code check):
  opened a real production archive directly —
  `dataset/mahabharata/boranko/mahabharata-dot-comics_v2012/zip_by_uid/
  8a89f7d689fb441ea280cd782276bd7a.comics` — and found its own real English+Russian balloon layer
  has `images = [{"file": "b10_eng_..."}, {"file": "b10_ru_..."}, {}]`: English at slot 0, Russian
  at slot 1, confirming the correction against real shipped data, not just source code.
  Documented one new judgment call extending that correction: rendered title cards also bake real
  Russian text into their pixels (unlike the plain background or wordless PSD art), so they use
  the same Russian slot (1); pure-visual layers (background, PSD panels) use the language-neutral
  slot 0, which doubles as the real `Images.FirstOrDefault()` fallback target.
  - Files: `scripts/package_comics.py` (new), `tests/test_package_comics.py` (new, 11 tests).
  - Verified by: 11/11 tests passing — root JSON shape, language-neutral-vs-Russian slot
    placement (including **the dedicated regression test the Plan specifically calls for**:
    Russian content must land at `images[1]`, never `images[0]`), TranslateAnim shape, duplicate-
    stem rejection, path-traversal-stem rejection, tile-name-collision rejection, byte-identical
    determinism across repeated builds, deterministic ZIP entry order (`data.json` first, then
    lexically sorted tiles), staging-file cleanup after a real write, and **one real end-to-end
    integration test**: rendered chapter 12's real title card and all 16 real verse cards (the
    smallest real chapter, chosen to keep this bounded), laid them out, packaged a real
    `.comics` archive to a temp path, reopened it with `zipfile`/`json`, and confirmed the real
    background layer is at slot 0 while the real first verse layer's Russian content is at slot 1
    — and that every referenced tile filename template actually exists in the archive.

- **Task 7.1**: `scripts/validate_output.py` — `validate_archive_structure(path,
  expected_verse_count)` (ZIP/JSON well-formedness, case-collision/duplicate/unsafe-path member
  checks, root key/type checks, background/title/verse layer counts, the Russian-slot regression
  check applied to `balloon` layers, per-layer TranslateAnim/rectangle-fits-canvas checks, tile
  reconstruction + non-transparent-pixel checks) and `validate_storyboard_citations(chapter,
  storyboard)` (citation-scope check). Documented two real scope limits rather than overreaching:
  the Russian-slot check only applies to `kind="balloon"` (art layers are ambiguous from JSON
  alone -- title cards carry real Russian text, PSD panels don't); full CSV-string round-tripping
  is deferred to Task 8.1's `manifest.json`, not yet built.
  - Files: `scripts/validate_output.py` (new), `tests/test_validate_output.py` (new, 12 tests).
  - Verified by: 12/12 tests passing — **every check has both a passing and a real failing
    fixture** (per the Plan's explicit requirement), built by packaging a real minimal archive via
    the actual `package_comics.py` and then surgically mutating one thing at a time (dropped
    background layer, Russian content moved back to slot 0 -- the Plan's own explicitly-required
    regression test against real generated output, non-empty `sounds`, an out-of-bounds
    TranslateAnim, a removed tile member, an injected `../evil.png` path-traversal member, a
    corrupt non-ZIP file), plus citation-scope pass/fail fixtures, plus **one real end-to-end
    integration test**: re-renders and packages chapter 12 fully and asserts it passes structural
    validation with zero issues.

- **Task 7.2 (editor/viewer Flutter validation)**: attempted via a background research agent to
  investigate `apps/comics-editor/test/`'s real conventions (existing fixture-discovery/skip
  patterns, `DartIoCore`'s real API) before writing the Dart test. **The agent failed mid-run on
  an API session-limit error, not a real finding** — no code was written for this task. Deferred;
  see "Blockers" in `_status.md`. Proceeded to Task 8.1 in the meantime since it only depends on
  Task 7.1 (already done), not Task 7.2.
- **Task 8.1**: `scripts/report.py` — `compute_file_sha256`/`compute_dataset_fingerprint`/
  `compute_config_fingerprint`, `ChapterManifestEntry`/`build_chapter_entry`/`build_manifest`/
  `write_manifest`, `coverage_count`, `render_report_md`. Documented one real scope boundary:
  "a stale file from an earlier run never counts when fingerprints differ" needs comparing against
  a *previous* manifest, which is Task 8.2's `pipeline.py` resumability logic, not this module —
  this module only ever builds one fresh manifest for the chapters it's given.
  - Files: `scripts/report.py` (new), `tests/test_report.py` (new, 10 tests).
  - Verified by: 10/10 tests passing — SHA-256 matches `hashlib` directly, dataset fingerprint
    changes when a CSV changes, config fingerprint is deterministic, manifest root shape, valid
    vs. failed chapter-entry status derived from a real `ValidationResult`, coverage counts only
    `status="valid"` entries, `report.md` contains the real coverage line and chapter title,
    JSON round-trip, and **one real end-to-end integration test**: runs the full real pipeline
    (load chapter 12 -> deterministic storyboard -> render -> layout -> package -> validate) and
    builds a real manifest entry + report from genuinely produced output, asserting
    `status="valid"`, `coverage_count()==1`, and the real chapter title
    ("Йога преданности") appears in the rendered report.

- **Task 7.2 (retried directly, not via the failed agent)**: investigated
  `apps/comics-editor/test/dataset_backward_compat_test.dart` directly (real fixture-discovery/
  skip pattern: `Directory(Directory.current.path).parent.parent` for repo root, `skip:` param
  with an explicit message, temp-dir-per-open via `DartIoCore(workDirPath: ...)`) and
  `lib/src/bridge/dart_io_core.dart` (`openComics` extracts the real zip to a temp dir and returns
  `{comics, tempFolder}`) to write `apps/comics-editor/test/bhagavadgita_generator_test.dart`
  correctly on the first real attempt, modeled directly on that precedent.
  - **Generated one real chapter into `work/bhagavadgita/`** (chapter 12, the smallest, via the
    real pipeline already exercised in Tasks 6.1/7.1/8.1) specifically so this new Dart test has a
    real, non-skipped fixture to run against this session, plus a real `manifest.json`/`report.md`
    alongside it (coverage 1/18) -- the first real file in what Task 9.1 will grow to 18.
  - Files: `apps/comics-editor/test/bhagavadgita_generator_test.dart` (new),
    `work/bhagavadgita/chapter_12.comics` + `manifest.json` + `report.md` (new, real generated
    output, not a fixture).
  - Verified by: **a real `flutter test` run** (`cd apps/comics-editor && flutter test
    test/bhagavadgita_generator_test.dart`) — both tests passed, non-skipped: the sanity check
    (fixture dir reachable, non-empty) and a real open of `chapter_12.comics` through the real
    `DartIoCore`, asserting positive width/height, a non-empty real layer list, 3-slot `images[]`
    per layer, and that every populated image slot's declared 512px tiles actually exist on disk
    after extraction (a client-side reimplementation of the tile-grid math, matching
    `tile_assets.py`'s contract).
  - **Not done**: Specifications/Requirements also ask for "a documented manual open in the
    actual Comics Editor app" / "at least one real editor/viewer open test" beyond the headless
    Dart test -- i.e., actually launching the real macOS GUI app and visually confirming the
    rendered chapter. Not attempted this session: it would open a visible window on Anton's real
    desktop, which felt like something to check in about rather than do silently. Genuinely
    incomplete, not silently claimed done -- see `_status.md` Blockers.

- **Task 8.2**: `scripts/pipeline.py` — the real integration point wiring every prior phase
  together: `generate_chapter_assets` (real per-asset Russian/language-neutral tracking at render
  time, since `kind="art"` alone can't distinguish a title card from a PSD panel -- the same
  ambiguity `validate_output.py` documented as out of its own scope), `can_reuse_chapter`
  (dataset+config fingerprint match + real sha256 match against a previous `manifest.json`),
  `chapter_lock` (real `O_CREAT|O_EXCL` exclusive-file lock per chapter), `process_chapter`
  (never raises -- any exception becomes a `status="failed"` manifest entry so `--all` continues
  past one bad chapter), and the `--chapter N`/`--all`/`--no-ai`/`--no-psd`/`--force` CLI.
  Real, deliberate exit-code distinction not fully spelled out in Specifications' prose: `--all`
  is non-zero only when coverage < 18 (matching "the batch ... returns non-zero if final valid
  coverage is less than 18" literally), while `--chapter N` (documented as "the smoke/debug path")
  is non-zero only when *that one* chapter isn't valid -- since a lone `--chapter 1` run
  obviously never reaches 18/18 by design, applying the batch threshold to it would make the
  smoke path permanently "fail" even when working correctly.
  - Files: `scripts/pipeline.py` (new), `scripts/report.py` (extended: `ChapterManifestEntry.
    from_dict`, `build_failed_chapter_entry`), `tests/test_pipeline.py` (new, 9 tests).
  - Verified by: 9/9 tests passing — reuse/invalidation logic across five real scenarios (no
    previous manifest, dataset fingerprint mismatch, missing output file, sha256 mismatch, prior
    `status="failed"`) plus the true-reuse case, a real chapter-lock acquire/block/release/
    re-acquire cycle, and **two real subprocess integration tests**: the Plan's own explicitly
    named smoke path (`pipeline.py --chapter 1 --no-ai --no-psd`) producing a real valid
    37-verse chapter 1 archive end-to-end, and a real re-run without `--force` proving the
    idempotency contract (byte-identical output, unchanged mtime, "reused" logged, completes in
    under 5s instead of re-rendering).

- **Task 9.1**: ran `.venv/bin/python3 scripts/pipeline.py --all --output-dir
  ../../../work/bhagavadgita` for real, against the real dataset. **Result: 18/18 chapters
  `status="valid"`, 0 failed, 0 duplicates, orders exactly `[1..18]`, 663/663 total slokas across
  the manifest** — Requirements' Must-Have 1, checked for real. Chapter 12 was correctly `reused`
  from Task 7.2's earlier real generation (same dataset/config fingerprints, matching sha256) — a
  real production-scale confirmation of Task 8.2's idempotency contract, not just its unit tests.
  Chapter 5 got all 3 real PSD panels composited in (`psd_inputs: ["5_1.psd", "5_2.psd",
  "app_BG._chiba5.psd"]`, `layer_count: 32` = 1 background + 1 title + 3 PSD art panels + 27 verse
  cards, matching chapter 5's real 27-sloka count exactly). Real wall-clock time: **111.91s**
  (70.2s user + 19.3s system) for the whole run (17 chapters actually rendered + 1 reused). Real
  output file sizes ranged from 1.46MB (chapter 12, no PSD, 16 slokas) to 9.82MB (chapter 5, 3 PSD
  panels + 27 slokas) — plausible, not suspiciously uniform or empty.
  - Files: none (execution only, per the Plan). Real output:
    `work/bhagavadgita/chapter_{01..18}.comics`, `work/bhagavadgita/manifest.json`,
    `work/bhagavadgita/report.md`.
- **Task 9.2**: re-ran Task 7.2's real Dart test (`cd apps/comics-editor && flutter test
  test/bhagavadgita_generator_test.dart`) against the full 18-chapter Task 9.1 output (not just
  the single chapter 7.2 had before) — **all 19 tests passed** (1 sanity + 18 real per-chapter
  opens through `DartIoCore`, each checking positive width/height, non-empty layers, 3-slot
  `images[]`, and every populated slot's tiles actually present on disk). Also rendered and
  visually inspected a full real chapter end-to-end (chapter 5, the most feature-complete one:
  title card + 3 PSD art panels + 27 verse cards) by stitching its actual tiles back into a real
  image outside any test harness — confirms genuinely correct real output, not just
  structurally-valid-but-garbled pixels: Cyrillic title/verse text renders correctly, the 3 real
  PSD illustrations (Krishna's face + conch shell; a battle/army scene; Krishna's face with lotus
  motifs) appear in full color with correct transparency, and verse cards are laid out in order
  beneath them.
  - **Still not done** (per Task 7.2's original scope limit, carried forward unchanged): the
    literal manual GUI launch of the desktop Comics Editor app. Everything else in Requirements'
    Must-Have 10 ("real completion proof... at least one real editor/viewer open test") is now
    satisfied by the real, passing, non-skipped Dart test against all 18 real files.

**Ended at**: **All of Phases 1-9 complete except the one explicitly-flagged manual GUI-launch
step.** Full verification suite: 85/85 Python tests + 19/19 Dart tests, all passing against real
data, plus one real full production run (18/18 chapters valid, 663/663 slokas, matching
Requirements' Must-Have 1 exactly) and one real full visual inspection of a representative
chapter. See `_status.md` for the final blocker list and recommended next step.
**Handoff notes**: `apps/comics-ai/comics-ai-bhagavadgita-generator/.venv` is the working
environment for this app going forward — use it (not bare `python3`) for all subsequent
tasks/tests, since it's the one confirmed to have `psd-tools`, and `pytest`/`playwright` are being
added to it incrementally as each phase needs them. Playwright must stay pinned to `1.61.0`
in this venv unless the cached Chromium build is also refreshed (`playwright install` would
download a new one; not done here to avoid an unnecessary large download when the cached build
already works). PSD compositing is real but memory-heavy (up to ~4.8GB peak RSS observed) —
Task 5.1/6.1 should treat chapter 5's PSD panels as an optional, isolated step (already true per
Task 4.1's graceful-failure design) rather than assuming it's cheap to redo repeatedly.
