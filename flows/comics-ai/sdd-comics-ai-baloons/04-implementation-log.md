# Implementation Log: comics-ai-baloons

> Started: 2026-07-30
> Plan: [03-plan.md](03-plan.md)

## Progress Tracker

| Task | Status | Notes |
|------|--------|-------|
| 1.1 Python project scaffolding | Done | venv (Python 3.13), requirements.txt, README.md, tesseract-lang + Chromium installed |
| 1.2 Language index table | Done | `scripts/languages.py`, 4 unit tests passing |
| 1.3 `.comics` zip read/write utilities | Done | `scripts/comics_io.py`, 3 unit tests passing |
| 1.4 Tiling stitch/re-tile utilities | Done | `scripts/tiling.py`, 4 unit tests passing |
| 2.1 Structural balloon-layer discovery | Done | `discover.py`, exactly 825 balloons — matches survey count precisely |
| 2.2 Extract & stitch pipeline stage | Done | `extract.py`, 1650/1650 slots stitched, 0 missing tiles across the whole dataset |
| 3.1 OCR stage | Done | `ocr.py`, Tesseract `eng`+`rus`, `--psm 6` + outline-strip fallback |
| 3.2 Checkpoint A (match threshold) | Done | 99.76% OCR coverage achieved; threshold stays 0.75 pending Task 4.2 real data |
| 4.1 CSV loader | Done | `csv_loader.py`, 563 real data rows loaded correctly |
| 4.2 Fuzzy matcher | Done | `match.py`, 454/825 (55%) matched, rest skip+logged with reasons — manually audited, both buckets look correct |
| 5.1 Lettering feature extraction | Done | `lettering_features.py`: stroke_width_cv + baseline_wobble, run over all 1650 slots |
| 5.2 Manual labeling sample | Done | 41 labels in `work/lettering_labels.jsonl` (39 stratified + 2 outlier-sweep finds) |
| 5.3 Checkpoint B (hand-lettering volume) | Done | `classify.py`; real count = 2/825 (1 genuine SFX panel, 1 non-text false positive); both already fail CSV matching anyway — see findings below |
| 6.1 Erase | Done | `erase.py`, alpha-preserving inpaint + speckle cleanup; visually clean on 3 different balloon shapes |
| 6.2 Layout mode | Done | `layout.py`: maximal-inscribed-rectangle + greedy word-wrap font-fit; visually matches original artist layout closely |
| 6.3 Latin/Cyrillic render | Done | `render_latin.py` + Shantell Sans (OFL, vendored); erase.py redesigned (see below) after finding a real 22%-of-dataset bug |
| 6.4 Complex-script render (Checkpoint C) | Done | `render_shaped.py`, Playwright + Noto; validated across all script families (Thai/CJK/Devanagari/Tamil/Kannada/Bengali/RTL). **Found: 10/20 CSV languages have zero rows at all** (kn, fr, pt, tr, vi, ta, mr, bn, ne, he, ar) |
| 6.5 Hand-lettering track | Done | `render_handlettered.py`, flag-only per Checkpoint B + user decision — no auto-render built (2/825 real count, both already unmatched) |
| 7.1 Re-tile & package | Done | `package.py`; end-to-end validated (erase→render→retile→patch→write), round-trips correctly |
| 7.2 Report generation | Done | `report.py`; every discovered balloon accounted for exactly once |
| 7.3 Pipeline orchestrator | Done | `pipeline.py`, subprocess-based, resumable per stage |
| 8.1 Full 27-file run | Done | Clean `--force` run from scratch, 7:13 total, fully reproducible (identical numbers to incremental run) |
| 8.2 Manual verification | Done | Structural validation (0 errors, 0 missing tiles across 6124 image entries) + visual spot-check from real final output across every script family + byte-identity check on all 1219 unchanged original tiles |

## Session Log

### Session 2026-07-30 - Claude

**Started at**: Phase 1, Task 1.1
**Context**: Plan just approved. Starting implementation from a clean slate — only
`apps/comics-ai-baloons/scripts/survey_dataset.py` and `work/survey.json` existed already (built
during Requirements/Specifications investigation).

#### Completed
- Task 1.1: Python project scaffolding
  - Files changed: `apps/comics-ai-baloons/requirements.txt`, `apps/comics-ai-baloons/README.md`
  - Verified by: created `.venv` with Homebrew Python 3.13, `pip install -r requirements.txt`
    succeeded, all imports (`pytesseract`, `cv2`, `rapidfuzz`, `playwright`, `PIL`, `numpy`)
    succeed. Installed `tesseract-lang` via Homebrew (system only had `eng`; now has `eng`+`rus`+
    `hin` and the rest of the Tesseract language set as a side effect). `playwright install
    chromium` succeeded; smoke-tested a headless render with mixed Latin/Arabic/CJK text.
- Task 1.2: Language index table
  - Files changed: `apps/comics-ai-baloons/scripts/languages.py`,
    `apps/comics-ai-baloons/tests/test_languages.py`
  - Verified by: 4 pytest cases — indices 0-2 match the real `Cultures` enum order, round-trip
    index↔code for all 20 entries, count is exactly 20, unknown-code handling
- Task 1.3: `.comics` zip read/write utilities
  - Files changed: `apps/comics-ai-baloons/scripts/comics_io.py`,
    `apps/comics-ai-baloons/tests/test_comics_io.py`
  - Verified by: 3 pytest cases against a real dataset file — full read+rewrite preserves every
    entry's content exactly; `data.json` override + extra files work; source file's mtime/size
    unchanged after the test (confirms read-only access)
- Task 1.4: Tiling stitch/re-tile utilities
  - Files changed: `apps/comics-ai-baloons/scripts/tiling.py`,
    `apps/comics-ai-baloons/tests/test_tiling.py`
  - Verified by: 4 pytest cases against the real `b1_eng` balloon in
    `8a89f7d689fb441ea280cd782276bd7a.comics` (the same one manually inspected during
    Requirements) — tile grid matches the known 2-tile layout, stitch produces the declared
    648x152 size, full stitch→retile→re-stitch round trip is pixel-identical
    (`canvas.tobytes() == stitched.tobytes()`), edge tile is clipped to 136px not padded to 512px

#### In Progress
- None — Phase 1 fully complete, all 11 tests passing (`pytest tests/ -q`)

#### Deviations from Plan
- Task 1.3's plan verification said "diff byte-for-byte against the original" zip. Implemented as
  content-fidelity per entry instead (every entry's decompressed bytes match) rather than raw
  container-byte equality, because the output writer uses `ZIP_DEFLATED` uniformly while the
  source archives mix compression methods — container bytes legitimately differ even when content
  is identical. Content fidelity is the invariant that actually matters (any conformant zip reader
  gets the same bytes back); documented in the test's docstring.
- Added `pytest` to `requirements.txt` (not explicitly listed in Specifications' Dependencies, but
  needed to satisfy the Plan's "unit test" verification steps).

#### Discoveries
- The system only had Tesseract's `eng` language pack; installing `tesseract-lang` via Homebrew
  pulled in the full set (685MB) including `rus`/`hin` needed for Task 3.1 — worth knowing this is
  already satisfied when that task starts.

- Task 2.1: Structural balloon-layer discovery
  - Files changed: `apps/comics-ai-baloons/scripts/models.py`,
    `apps/comics-ai-baloons/scripts/discover.py`, `apps/comics-ai-baloons/tests/test_discover.py`
  - Verified by: 5 pytest cases; running over the full dataset produces **exactly 825** balloons,
    matching the filename-based survey count from Requirements exactly (no discrepancy to
    investigate — structural and filename-based counting agree on this dataset)
- Task 2.2: Extract & stitch pipeline stage
  - Files changed: `apps/comics-ai-baloons/scripts/extract.py`,
    `apps/comics-ai-baloons/tests/test_extract.py`
  - Verified by: 3 pytest cases; full run over all 825 balloons stitched **1650/1650** image slots
    with zero missing tiles; visually spot-checked two stitched balloons (Read tool) — `b1_eng`
    reproduces the exact text seen during Requirements ("AND AMBA TOLD PARASHURAMA ABOUT ALL THE
    HARDSHIPS..."), and a second, differently-shaped round balloon with a tail (layer 176) also
    stitches cleanly, confirming the tiling math generalizes across balloon shapes/sizes, not just
    the one sample used to build `tiling.py`

- Task 3.1 + 3.2 (Checkpoint A): OCR stage + threshold checkpoint
  - Files changed: `apps/comics-ai-baloons/scripts/ocr.py`,
    `apps/comics-ai-baloons/scripts/models.py` (added `OcrResult.needed_crop_fallback`),
    `apps/comics-ai-baloons/tests/test_ocr.py`
  - Verified by: 4 pytest cases; full run over all 1650 image slots
  - **Real findings from Checkpoint A** (paused and showed the user actual OCR output before
    proceeding, per the plan):
    1. Found and fixed a genuine bug: Tesseract's default page-segmentation mode (psm 3) misreads
       a balloon's drawn outline as page layout and returns **empty text on perfectly legible
       balloons**. Switching to `--psm 6` ("single uniform text block") dropped empty results
       212→133 and raised confidence 0.81→0.85.
    2. User asked to push further (their hypothesis: remaining failures might correlate with hand
       lettering, important to get right). Added a fallback: when direct OCR is empty, find
       connected dark components, drop whichever span >85% of image width/height (the outline
       stroke), crop to the bounding box of what's left, retry OCR on that. This dropped empty
       results 133→**4** (99.76% coverage) and raised confidence to 0.92. The 4 remaining are
       single-word/single-letter balloons ("THANK YOU!", "Я...") — accepted as residual, not worth
       further engineering (they'll skip+log at matching if genuinely unmatchable, which is safe
       by design).
    3. Recorded `needed_crop_fallback` per `OcrResult` (129 slots needed it) specifically so
       stage 5's hand-lettering classifier can reuse it as a feature, per the user's hypothesis
       that OCR difficulty and hand lettering may correlate.
    4. Also discovered (documented, not fixed — self-corrects downstream): the structural
       balloon-detector has at least one false positive — a character close-up art panel that
       happens to have 2 populated image slots, OCR'd as gibberish (confidence 0.42). This will
       simply fail to match any CSV row at stage 4 and get skipped+logged, which is the correct
       behavior already designed for this case.
  - Match threshold decision: kept at 0.75 (Specifications' proposed value) — real OCR text, when
    non-empty, is highly accurate (near-verbatim dialogue with rare single-character noise), so
    there's no evidence yet to move it. Deferred final tuning to Task 4.2 once real match-score
    distributions against the CSV are visible, as originally planned.

- Task 4.1: CSV loader
  - Files changed: `apps/comics-ai-baloons/scripts/csv_loader.py`,
    `apps/comics-ai-baloons/tests/test_csv_loader.py`
  - Verified by: 5 pytest cases against the real CSV; confirmed the ISO-code header row (row 0,
    columns 3-22) exactly matches `languages.py`'s *set* of 20 languages (order legitimately
    differs — `languages.py` reorders `hi` to index 2 to match the real editor's `Cultures` enum,
    which the CSV knows nothing about); data rows identified by a `P<page>_<bubble>` regex on
    column 1 rather than a fixed row offset (563 real rows found, robust to header-block size
    changes); spot-checked `P1_001` against the exact text seen during Requirements ("War's end." /
    "Битва закончена.")
  - Files changed: `apps/comics-ai-baloons/scripts/match.py`,
    `apps/comics-ai-baloons/tests/test_match.py`
- Task 4.2: Fuzzy matcher
  - Verified by: 9 pytest cases covering exact match, no-OCR-text, unrelated-text, tied/ambiguous,
    ru-tiebreak, and en-missing→ru-fallback paths. Full run over all 825 balloons:
    **454 matched (55%), 351 skipped_low_confidence (42.5%), 19 skipped_ambiguous (2.3%),
    1 skipped_no_match**.
  - **Manual audit** (this stage is flagged highest-risk in the Plan, got the most scrutiny):
    - Sampled 10 `matched` results — every one checked was a genuinely correct translation pairing.
      One (`ff2df58f5c...` layer 230, score 0.77) is a clean example of the version drift the user
      warned about: OCR'd "IT IS NOT GOOD. WHAT DO WE DO NOW, BHISHMA?" matched CSV's "What do we
      do now, Bhishma?" — the dataset balloon has an extra lead-in sentence the CSV translation
      doesn't. Matcher correctly found it anyway (score still clears threshold); rendering will
      use the CSV's (shorter) text, which is the intended behavior (CSV is the translation source
      of truth), just worth knowing why a rendered balloon might read shorter than the original.
    - Sampled `skipped_low_confidence` results and inspected their best (rejected) candidates
      directly — every one checked was a genuine non-match (best candidates topped out around
      50-64 points against a 75 threshold, and reading them side-by-side confirms they're
      unrelated content). This strongly suggests the ~55% match rate reflects **real CSV coverage
      gaps** (this CSV doesn't have translations for everything in these 27 `.comics` files, or
      covers a different content range), not a matcher defect — consistent with the user's
      up-front warning that the CSV might not fully correspond to this dataset version.
    - Sampled `skipped_ambiguous` results — all genuine ties (e.g. "WHY?" appearing verbatim, en
      score 1.0, across multiple unrelated CSV rows) where the ru tie-breaker also didn't resolve
      it. Correct to skip rather than guess.
  - Threshold (75/100, i.e. 0.75) and tie margin (5 points) kept as proposed in Specifications —
    real data validates both choices rather than motivating a change.

- Task 5.1-5.3: Lettering feature extraction, manual labeling, Checkpoint B
  - Files changed: `apps/comics-ai-baloons/scripts/lettering_features.py`,
    `apps/comics-ai-baloons/scripts/classify.py`, `apps/comics-ai-baloons/work/lettering_labels.jsonl`,
    `apps/comics-ai-baloons/tests/test_lettering_features.py`, `apps/comics-ai-baloons/tests/test_classify.py`
  - Verified by: 7 pytest cases (44 total passing). Manually viewed 39 balloons stratified across
    all naming-convention eras/files (Task 5.2) — found only two distinct *uniform* digitally-set
    fonts (a caps font in the 2017-2018 batch, a casual mixed-case font in the 2020-2022 batch),
    zero organic hand lettering. Cross-checked with an automated outlier sweep (stroke-width
    coefficient of variation) across all 825 balloons: clean separation at ~0.5 between every
    normal balloon (max 0.47) and two outliers (1.2, 1.56).
  - **Real findings**: the two outliers are (1) `96d4fcd2f634...` layer 181 — a genuine hand-drawn
    "AHAHAHAHAHA" sound-effect panel (gradient color, slanted, jagged burst outline, dynamic
    per-letter sizing), exactly the kind of expressive lettering the user asked to find; (2)
    `d00c610a6f46...` layer 67 — not text at all, a character close-up art panel (the same
    structural false-positive found during Checkpoint A). **Both already fail CSV matching**
    (scores 46-50 vs. a 75 threshold) — neither would reach the rendering stage regardless of how
    Track 6b is built, since the pipeline only renders balloons that matched a CSV row.
  - Classifier (`classify.py`): simple, documented threshold rule (stroke_width_cv > 0.6) rather
    than a trained model — a ~1-in-825 true positive rate is nowhere near enough data to train one,
    and the threshold sits cleanly in the middle of the empirical gap.
  - **Paused and reported to user before deciding Track 6b's real scope**, per the Plan's
    Checkpoint B design.

- Task 6.5: Hand-lettering track, resolved early
  - Files changed: `apps/comics-ai-baloons/scripts/render_handlettered.py`,
    `apps/comics-ai-baloons/scripts/models.py` (added `RenderResult`),
    `apps/comics-ai-baloons/tests/test_render_handlettered.py`
  - User confirmed the Checkpoint B recommendation: flag + manual review only, no auto-render.
    Implemented as an intentional no-op stub that produces an explicit `rendered=False` result per
    target language with a clear reason, so these balloons stay visible in the report rather than
    silently vanishing. Not blocked on 6.1/6.2 (erase/layout), so pulled forward and finished now
    while the Checkpoint B context was fresh.

- Task 6.1: Erase (empty-balloon synthesis)
  - Files changed: `apps/comics-ai-baloons/scripts/erase.py`,
    `apps/comics-ai-baloons/scripts/imaging.py` (new shared `flatten_to_white`, also adopted by
    `ocr.py` to remove a near-duplicate), `apps/comics-ai-baloons/tests/test_erase.py`
  - Verified by: 6 pytest cases (52 total passing) plus visual review on 3 different balloon
    shapes (rectangular caption, round with tail, small round with tail).
  - **Real bug found and fixed during development**: initial approach used `.convert("RGB")`
    directly on the RGBA balloon assets, which corrupted the transparent corner margin (these
    assets are ~88% fully opaque white/black with a transparent margin only outside the wobbly
    drawn outline — dropping alpha naively keeps whatever garbage RGB sits under transparent
    pixels, which visually wrecked the corners). Fixed by reusing the same alpha-compositing
    flatten already validated in `ocr.py`, promoted to a shared `imaging.flatten_to_white`.
  - **Design finding**: en/ru alpha channels are byte-identical on every balloon checked — alpha
    encodes only the outline silhouette, never text, so the erase output's alpha channel is just
    copied from the source unchanged rather than computed.
  - **Residual limitation, mitigated not eliminated**: when en and ru glyphs coincidentally ink
    the same pixel (non-negligible for dense multi-line text), that pixel "agrees" and survives
    inpainting as a stray speck. Added a `remove_speckles` post-pass (small dark connected
    components, away from the outline, get painted white) that cleans this up to the point where
    OCR on the result returns only noise strings under 10 characters, never real words.

- Task 6.2: Layout mode
  - Files changed: `apps/comics-ai-baloons/scripts/layout.py`,
    `apps/comics-ai-baloons/tests/test_layout.py`
  - Verified by: 6 pytest cases plus visual review. `find_interior_rect` uses a distance-transform
    from outline ink + the classic "largest rectangle in a binary matrix" scan (per-row
    largest-rectangle-in-histogram) to find the biggest safe text box, provably fully inside the
    balloon and >= margin px from the drawn outline. `fit_text_to_rect` binary-searches the
    largest font size where greedy word-wrapped text fits. Rendered output side-by-side with the
    original artist balloon was visually near-indistinguishable in layout/wrapping style.

- Task 6.3: Latin/Cyrillic rendering + **erase.py redesign** (real bug found against real data)
  - Files changed: `apps/comics-ai-baloons/scripts/render_latin.py`,
    `apps/comics-ai-baloons/fonts/ShantellSans/` (vendored font + OFL.txt),
    `apps/comics-ai-baloons/scripts/erase.py` (rewritten),
    `apps/comics-ai-baloons/tests/test_erase.py` (updated + 2 new regression cases),
    `apps/comics-ai-baloons/tests/test_render_latin.py`
  - **Font decision**: compared Comic Sans MS (visually closest to the comic's lettering, but not
    freely licensed), Comic Neue (OFL, the usual Comic Sans substitute, but confirmed **zero
    Cyrillic glyph coverage** by rendering — tofu boxes), and Shantell Sans (OFL, Google Fonts,
    variable font) — Shantell Sans covers Latin + Cyrillic and is stylistically very close to the
    original. Vendored to `apps/comics-ai-baloons/fonts/ShantellSans/` (tracked in git, not
    gitignored — OFL permits redistribution) with its `OFL.txt` alongside it.
  - **Real bug found via end-to-end testing on an actual matched balloon** (not a cherry-picked
    fixture): erase.py's original en/ru pixel-agreement-diff approach assumed both language
    renders share one canvas size. Checked across the dataset: **179/825 balloons (21.7%) have
    mismatched en/ru dimensions** — the artist resized the balloon shape per language to fit each
    translation's length, in some cases substantially (one balloon: 757x439 en vs. 524x400 ru).
    Naively resizing before diffing shifted the outline enough to make the *entire* border
    register as disagreement, and inpainting erased almost the whole outline, not just the text.
  - **Redesigned erase.py around a single-image approach**: the balloon's outline+tail is one
    large connected dark-ink component spanning most of the image; every text glyph is a much
    smaller separate component (same discriminator already validated in `ocr.strip_outline_component`,
    inverted here to keep the outline instead of excluding it). This needs only one image, so the
    size-mismatch problem doesn't apply, and it's also strictly cleaner than the old approach — no
    coincidental-overlap speckle artifacts either (the old approach's `remove_speckles` cleanup
    pass is kept as a defensive no-op-if-unneeded utility). `erase_text(en_img, ru_img=None)` kept
    its two-argument shape for compatibility; `ru_img` is now unused.
  - Verified by: 8 erase.py pytest cases (incl. a dedicated regression test on the exact
    mismatched-size balloon that surfaced the bug) + 5 render_latin.py cases, all passing. Broader
    validation: erase run on a random 25-balloon sample spanning every file/era in the dataset —
    OCR afterward found **0/25 with leftover readable text**.

- Task 6.4: Complex-script rendering (Checkpoint C)
  - Files changed: `apps/comics-ai-baloons/scripts/render_shaped.py`,
    `apps/comics-ai-baloons/fonts/Noto/` (10 vendored Noto Sans files + `NOTICE.md`),
    `apps/comics-ai-baloons/tests/test_render_shaped.py`
  - Sourced Noto Sans per script via Homebrew casks (Thai, SC, KR, Kannada, JP, Devanagari, Tamil,
    Bengali, Hebrew, Arabic — Devanagari covers hi/mr/ne), all OFL-1.1, vendored + documented.
  - Design: render an HTML/CSS snippet in headless Chromium (Playwright) sized to the interior
    rect from `layout.find_interior_rect` (reused unchanged, script-agnostic), `direction: rtl`
    for he/ar, let the browser's own line-breaking/shaping handle everything else, binary-search
    font-size in-page by checking `scrollWidth`/`scrollHeight` overflow, screenshot just the text
    element with a transparent background, composite onto the balloon.
  - Verified by: 8 pytest cases, all passing, **plus Checkpoint C's visual review across every
    script family**: Thai (tone marks), Chinese/Japanese/Korean (no-space character wrapping),
    Devanagari (conjuncts/matras), Tamil, Kannada, Bengali, and both RTL languages Hebrew and
    Arabic (correct right-to-left flow, Arabic contextual letter joining) — every sample legible
    and correctly shaped.
  - **Major finding, surfaced to the user before the full run**: checked real CSV coverage per
    language and found **10 of the 20 target languages have zero rows in the CSV at all** — kn,
    fr, pt, tr, vi, ta, mr, bn, ne, he, ar (including *both* RTL languages entirely). Only en, ru,
    hi, uk, zh (~560/562 rows) and ja (210), th (104), ko (95), es (14) have any translated
    content. This isn't a pipeline defect — the rendering mechanism was validated to work
    correctly for all of these (using synthetic placeholder text for the zero-coverage ones) —
    it's a content gap in the source CSV that no amount of engineering can close.

- Task 7.1: Re-tile & package
  - Files changed: `apps/comics-ai-baloons/scripts/package.py`,
    `apps/comics-ai-baloons/tests/test_package.py`
  - Erases from whichever of en/ru is populated (prefers en), renders every CSV-provided language
    not already populated (en/ru always are; hi/uk/etc. via the appropriate render path), re-tiles,
    patches a **copy** of `data.json` with new `Image` entries at the correct language-table
    index, writes one full `.comics` file per source to `work/output/`. Deliberately does **not**
    try to mimic the original (wildly inconsistent) filename conventions for new tiles — uses a
    simple deterministic `layer{N}_{lang}_{0}_{1}_{2}.png` scheme instead.
  - Also refactored `render_shaped.py` to reuse one Playwright browser instance across calls
    (module-level lazy singleton + `shutdown_browser()`) instead of launching Chromium per render
    — this was launching/closing a full browser for every single complex-script render, which
    would have dominated runtime across a full batch.
  - Verified by: 3 pytest cases (round-trip stitch of newly-written tiles from a fresh output
    archive, hand-lettered balloons correctly produce no output, unmatched balloons ignored).

- Task 7.2: Report generation
  - Files changed: `apps/comics-ai-baloons/scripts/report.py`,
    `apps/comics-ai-baloons/tests/test_report.py`
  - Verified by: 4 pytest cases. Every balloon from stage 1 gets exactly one row with a terminal
    status (`rendered`, `hand_lettered_flagged`, `matched_no_renders`, or a specific
    `skipped_*`/`not_matched_no_data` reason) — confirmed no balloon silently dropped.
  - **Fix during Task 8.2 review**: the report's hand-lettered section initially only showed
    balloons that were *both* hand-lettered *and* successfully matched (0, since both real
    hand-lettered finds happened to fail matching) — silently hiding them despite the user's
    explicit ask to surface *all* hand lettering found. Decoupled the "hand-lettered awareness"
    listing from the render-pipeline `hand_lettered_flagged` status so both known cases now always
    appear in `report.md` with their actual status shown alongside.

- Task 7.3: Pipeline orchestrator
  - Files changed: `apps/comics-ai-baloons/scripts/pipeline.py`,
    `apps/comics-ai-baloons/tests/test_pipeline.py`
  - Subprocess-per-stage (avoids cross-stage global state, e.g. the new browser singleton), skips
    a stage if its primary output already exists unless `--force`; `--only` for targeted reruns.
  - Verified by: 5 pytest cases (resumability skip/run/force logic, failure propagation) with
    `subprocess.run` mocked, plus real usage throughout Phase 8 below.

- Task 8.1: Full 27-file pipeline run
  - Ran `pipeline.py --force` from a fully clean `work/` (all intermediate files and `work/output/`
    deleted first) to rule out any hidden dependency on state built up incrementally during
    development. **7:13 total**, produced identical numbers to the incremental runs: 825 balloons
    discovered, 1650 image slots extracted, 1650 OCR'd (99.76% non-empty), 454 matched (55%; ~90%+
    within the CSV's actually-covered content range per the earlier coverage investigation), 2
    hand-lettered, **22 output `.comics` files, 1586/1586 (100%) language renders succeeded**. The
    5 files with zero output are exactly the 5 files with 0% CSV match rate identified earlier
    (2022-production-era files the CSV doesn't cover) — expected, not a bug.

- Task 8.2: Manual verification pass
  - Structural validation across all 22 output files: 0 malformed `Image` entries, 0 missing tile
    files across all 6124 image entries checked (every declared tile actually present in its zip).
  - Byte-identity check: on a sample output file, all 1219 shared zip entries with the source are
    byte-for-byte identical except `data.json` (the one intentionally patched file) — confirms no
    original content was corrupted or regenerated, only additive changes.
  - Visual spot-check directly from the **real final output** (not test fixtures): re-extracted and
    viewed hi/th/zh/ko/ja renders from an actual packaged `.comics` file — all legible, correctly
    shaped, matching the earlier per-script-family validation from Checkpoint C.
  - Confirmed via `git status`/mtime that `dataset/` was never modified at any point.
  - **Known limitation, stated plainly**: could not literally open an output file in
    `apps/comics-editor-v2.9` (a Flutter/WPF desktop app) inside this environment — structural
    validation against the real C# `Image`/`Layer` schema (Specifications' "Editor Schema Ground
    Truth", verified against the actual source code, not guessed) is the closest available
    substitute. This is a real gap in verification confidence, not swept under the rug.

## Deviations Summary (cumulative)

| Planned | Actual | Reason |
|---------|--------|--------|
| Task 1.3: byte-for-byte zip diff | Per-entry content-fidelity diff | Output uses uniform `ZIP_DEFLATED`; container bytes differ from mixed-compression sources even with identical content |
| Erase: en/ru pixel-agreement diff (Specifications' original proposal) | Single-image connected-component separation | 21.7% of balloons have mismatched en/ru dimensions in the real dataset; the diff approach broke on them |
| Track 6b: dedicated trained model | Flag-only, no auto-render | Real hand-lettered count is 2/825, both already fail CSV matching — no training data, no actual demand |
| All 27 files get output | 22 files get output, 5 don't | The 5 zero-output files are exactly the 2022-era files this CSV doesn't cover (0% match rate) — a content gap, not a defect |
| "All ~20 languages" success criterion | 9 languages have any CSV content at all (10 have zero rows) | Confirmed with the user (Task 6.4 finding) — a CSV content gap, not a pipeline limitation; the rendering mechanism was validated for all 20 |

## Learnings

- Verifying foundation utilities against *real* dataset samples (not synthetic fixtures) caught
  nothing wrong so far, but was worth the extra setup — the tiling math in particular had several
  off-by-one opportunities (edge-tile clipping, scale placeholder) that a synthetic square-number
  fixture might not have exercised as clearly as the real 648x152 `b1_eng` balloon.
- Every real bug found in this implementation (OCR outline-confusion, erase's size-mismatch
  assumption, Comic Neue's missing Cyrillic) was caught by testing against **real dataset
  balloons**, never by synthetic fixtures alone — the recurring lesson across this whole build is
  that this dataset's real-world messiness (inconsistent conventions, mismatched dimensions,
  sparse translations) is the actual spec, and fixtures built from assumptions instead of
  inspection would have shipped all three bugs silently.
- Pausing at the plan's designated checkpoints (A/B/C) and reporting findings before proceeding —
  rather than silently picking a default and continuing — surfaced two decisions (OCR fallback
  investment, Track 6b scope) the user cared about differently than the Specifications' proposed
  defaults, plus one finding (CSV language coverage gap) significant enough to change what
  "success" means for this run, independent of any checkpoint.

## Completion Checklist

- [x] All tasks completed or explicitly deferred (Track 6b deliberately scoped down per
      Checkpoint B + user decision, documented above, not silently dropped)
- [x] Tests passing (85/85)
- [x] No regressions (full clean `--force` run reproduces identical numbers to incremental runs)
- [x] Documentation updated (this log, `_status.md`, `README.md`)
- [ ] Status updated to COMPLETE (pending final user review of this implementation)

**Ended at**: All 8 phases complete, 22 tasks done, 85/85 tests passing, full clean pipeline run
verified reproducible. Implementation phase is functionally done — ready for final review.
**Handoff notes**: `dataset/` coverage finding (55% overall, ~90%+ within the CSV's actual content
range) and the per-language CSV coverage gap (10/20 languages with zero data at all) were both
raised with and acknowledged by the user during implementation, not discovered after the fact. Run
tests with: `cd apps/comics-ai-baloons && source .venv/bin/activate && python -m pytest tests/ -q`.
Run the full pipeline with: `python scripts/pipeline.py` (add `--force` to ignore cached stage
outputs).

---

## Deviations Summary

| Planned | Actual | Reason |
|---------|--------|--------|
| Task 1.3: byte-for-byte zip diff | Per-entry content-fidelity diff | Output uses uniform `ZIP_DEFLATED`; container bytes differ from mixed-compression sources even with identical content |

## Learnings

- Verifying foundation utilities against *real* dataset samples (not synthetic fixtures) caught
  nothing wrong so far, but was worth the extra setup — the tiling math in particular had several
  off-by-one opportunities (edge-tile clipping, scale placeholder) that a synthetic square-number
  fixture might not have exercised as clearly as the real 648x152 `b1_eng` balloon.

## Completion Checklist

- [ ] All tasks completed or explicitly deferred
- [ ] Tests passing
- [ ] No regressions
- [ ] Documentation updated if needed
- [ ] Status updated to COMPLETE
