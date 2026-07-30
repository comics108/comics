# Implementation Plan: comics-ai-baloons

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-07-30
> Specifications: [02-specifications.md](02-specifications.md)

## Summary

Build the 7-stage pipeline from Specifications as a sequence of small, independently runnable
Python scripts under `apps/comics-ai-baloons/scripts/`, each reading/writing a `.jsonl` (or cached
files) in `apps/comics-ai-baloons/work/`. Order of implementation follows the data dependency chain
exactly (discover → extract → OCR → match → classify → render → package), with three checkpoints
where we deliberately stop and look at real data before committing to the next stage's design,
because several Specifications decisions (match threshold, hand-lettering track feasibility, font
choices) were explicitly left open pending real output:

- **Checkpoint A** (after OCR, Task 3.2): look at real OCR text quality before finalizing the fuzzy
  match threshold.
- **Checkpoint B** (after classification, Task 5.3): look at how many hand-lettered balloons
  actually exist before committing to "train a model" vs. a lighter-weight approach for Track 6b.
- **Checkpoint C** (after layout-mode render on a small sample, Task 6.4): visual review across
  script families before running the full 27-file batch.

`dataset/` is read-only for every task in this plan — no task ever writes there. All new code and
data live under `apps/comics-ai-baloons/`.

## Task Breakdown

### Phase 1: Environment & Foundation

#### Task 1.1: Python project scaffolding
- **Description**: Set up `apps/comics-ai-baloons/` as a proper Python project — `pyproject.toml`
  or `requirements.txt` pinning `Pillow`, `pytesseract`, `rapidfuzz`, `opencv-python`, `playwright`,
  `numpy`; a `README.md` documenting how to run the pipeline and install system deps (Tesseract
  binary + `eng`/`rus` traineddata, Playwright's Chromium via `playwright install`).
- **Files**:
  - `apps/comics-ai-baloons/pyproject.toml` or `requirements.txt` - Create
  - `apps/comics-ai-baloons/README.md` - Create
- **Dependencies**: None
- **Verification**: `pip install -r requirements.txt` (or equivalent) succeeds in a clean venv;
  `python -c "import pytesseract, cv2, rapidfuzz, playwright"` succeeds
- **Complexity**: Low

#### Task 1.2: Language index table (single source of truth)
- **Description**: Implement the index↔ISO-code table from Specifications (`en`=0 .. `ar`=19) as a
  small, well-tested module every later stage imports.
- **Files**:
  - `apps/comics-ai-baloons/scripts/languages.py` - Create
- **Dependencies**: None
- **Verification**: unit test round-trips index→code→index for all 20 entries; asserts indices 0-2
  match the existing `Cultures` enum order (`En, Ru, Hi`) exactly, since that part is not
  negotiable (already load-bearing in the real dataset)
- **Complexity**: Low

#### Task 1.3: `.comics` zip read/write utilities
- **Description**: Thin wrapper around `zipfile` for read-only access to `dataset/*.comics`
  (`utf-8-sig` JSON decode, already known-needed) and for writing a **new** zip to
  `work/output/<name>.comics` that copies all original entries plus additions/modifications —
  never opens the source in write mode.
- **Files**:
  - `apps/comics-ai-baloons/scripts/comics_io.py` - Create
- **Dependencies**: None
- **Verification**: unit test — open a real dataset file, write it back out unmodified via the
  "copy all entries" path, diff byte-for-byte against the original
- **Complexity**: Low

#### Task 1.4: Tiling stitch/re-tile utilities
- **Description**: Implement the reverse-engineered tiling algorithm from Specifications: stitch
  (`col`/`row` tiles → single `Width`×`Height` PNG) and re-tile (single PNG → 512px tile files,
  `png32`-equivalent encoding, correct `col`/`row` clipping at edges).
- **Files**:
  - `apps/comics-ai-baloons/scripts/tiling.py` - Create
- **Dependencies**: Task 1.3 (uses the zip reader to pull tile bytes)
- **Verification**: unit test round-trip — stitch a real multi-tile balloon image from the dataset,
  re-tile it, confirm identical tile byte layout/count and pixel-identical stitched result
- **Complexity**: Medium (edge-tile clipping math is the main source of off-by-one risk)

### Phase 2: Balloon Discovery

#### Task 2.1: Structural balloon-layer discovery
- **Description**: Implement `BalloonLayer`/`ImageSlot` dataclasses and the discovery scan (`Layer`
  with ≥2 non-empty `images[]` entries) across a `.comics` file's `data.json`.
- **Files**:
  - `apps/comics-ai-baloons/scripts/discover.py` - Create
  - `apps/comics-ai-baloons/scripts/models.py` - Create (shared dataclasses used by later stages
    too: `BalloonLayer`, `ImageSlot`, `OcrResult`, `MatchResult`, `LetteringClass`)
- **Dependencies**: Task 1.2, Task 1.3
- **Verification**: run over all 27 files; total discovered balloons matches the survey's 825
  (`apps/comics-ai-baloons/work/survey.json`) exactly, or the discrepancy is explained (e.g. survey
  used a filename regex as a secondary signal — discovery here is purely structural, so it should
  be a superset if anything; investigate any mismatch, don't just accept it silently)
- **Complexity**: Low (logic already validated by hand during Specifications)

#### Task 2.2: Extract & stitch pipeline stage
- **Description**: `discover.py`'s output (`work/balloons.jsonl`) feeds an extraction stage that
  stitches every populated slot's tiles into a cached PNG.
- **Files**:
  - `apps/comics-ai-baloons/scripts/extract.py` - Create
- **Dependencies**: Task 1.4, Task 2.1
- **Verification**: spot-check a handful of stitched PNGs visually (Read tool) against what's
  already been manually inspected in Requirements/Specs (e.g. `b1_eng` from
  `8a89f7d689fb...comics` should reproduce the same balloon image seen earlier)
- **Complexity**: Low

### Phase 3: OCR

#### Task 3.1: OCR stage
- **Description**: Run Tesseract (`eng`+`rus`) over every extracted `en`/`ru` slot; store
  `OcrResult` (text + confidence) per slot.
- **Files**:
  - `apps/comics-ai-baloons/scripts/ocr.py` - Create
- **Dependencies**: Task 2.2
- **Verification**: run on the 27-file dataset; manually check ~15-20 OCR outputs against the
  actual balloon image (Read tool) across different files/eras to gauge real-world accuracy
- **Complexity**: Low (mostly plumbing — Tesseract does the work)

#### Task 3.2: **Checkpoint A** — review OCR quality, lock the match threshold
- **Description**: Before building the matcher, look at real OCR output quality/failure modes
  (garbled text, missing punctuation, case issues) to decide the fuzzy-match normalization rules
  and finalize the 0.75 threshold proposed in Specifications (raise/lower based on what real OCR
  noise looks like).
- **Files**: None (analysis task; findings recorded in this plan's Open Implementation Questions
  or directly in `match.py`'s docstring/constants in Task 4.1)
- **Dependencies**: Task 3.1
- **Verification**: documented decision (threshold value + normalization rules) with 2-3 concrete
  examples justifying it
- **Complexity**: Low

### Phase 4: CSV Matching

#### Task 4.1: CSV loader
- **Description**: Parse `dataset/Translation - Mahabharata Book 1.csv` into structured rows
  (id, type, per-language text dict), handling the header block (5 metadata rows before real data)
  and sparse cells (not every row has every language).
- **Files**:
  - `apps/comics-ai-baloons/scripts/csv_loader.py` - Create
- **Dependencies**: Task 1.2 (language table for column→index mapping)
- **Verification**: unit test — loads the real CSV, row count matches the 564 bubble rows found
  during Requirements investigation, spot-check a couple of known rows (e.g. `P1_001` = "War's
  end.")
- **Complexity**: Low

#### Task 4.2: Fuzzy matcher
- **Description**: Implement the match stage per Specifications — normalize + `rapidfuzz` scoring
  against `en`/`ru` CSV columns, threshold/margin decision rule from Checkpoint A, skip+log with
  reason on failure.
- **Files**:
  - `apps/comics-ai-baloons/scripts/match.py` - Create
- **Dependencies**: Task 3.1, Task 4.1, Task 3.2 (threshold decision)
- **Verification**: run over all 27 files; manually audit a sample of both accepted matches (are
  they actually correct?) and skipped ones (are they genuinely unmatchable, or was the threshold
  too strict?) — this is the highest-risk correctness step in the whole pipeline per the user's
  explicit warning about CSV/dataset version drift, so it gets the most scrutiny
- **Complexity**: Medium-High

### Phase 5: Lettering Classification

#### Task 5.1: Feature extraction (stroke-width variance, baseline irregularity)
- **Description**: Implement the two image-based features from Specifications on the stitched
  balloon text region.
- **Files**:
  - `apps/comics-ai-baloons/scripts/lettering_features.py` - Create
- **Dependencies**: Task 2.2
- **Complexity**: Medium (contour/baseline extraction is fiddly; keep it simple and inspectable)

#### Task 5.2: Manual labeling sample
- **Description**: Pull a stratified sample of balloons across all 27 files/eras, view them (Read
  tool) and hand-label `machine_set`/`hand_lettered`, saved as a small labeled fixture for
  calibration and later regression testing.
- **Files**:
  - `apps/comics-ai-baloons/work/lettering_labels.jsonl` - Create (gitignored, working data)
- **Dependencies**: Task 2.2
- **Verification**: sample covers every file (or a deliberate justified subset) and both suspected
  eras (2017-2018 vs. 2020-2022 naming-convention clusters, per the survey)
- **Complexity**: Low (manual, but time-bounded — this is the actual "find the hand lettering" task
  called out explicitly in Requirements)

#### Task 5.3: **Checkpoint B** — classifier calibration + hand-lettering volume decision
- **Description**: Combine Task 5.1's features (+ OCR confidence from Task 3.1) into a threshold
  calibrated against Task 5.2's labels. Report the real count of hand-lettered balloons found.
  **This count determines Track 6b's actual design** (per Specifications' explicit open question):
  a trainable-from-scratch model needs meaningfully more than a handful of examples; if the count
  is very low, fall back to flagging for manual/artist review instead of an automated render, and
  update this plan's Phase 6 tasks accordingly before starting them.
- **Files**:
  - `apps/comics-ai-baloons/scripts/classify.py` - Create
- **Dependencies**: Task 5.1, Task 5.2
- **Verification**: classifier accuracy against the held-out portion of the labeled sample;
  documented decision on Track 6b's approach
- **Complexity**: Medium

### Phase 6: Erase + Render

#### Task 6.1: Erase (empty-balloon synthesis)
- **Description**: en/ru pixel-agreement + OpenCV inpainting on the disagreement region, per
  Specifications.
- **Files**:
  - `apps/comics-ai-baloons/scripts/erase.py` - Create
- **Dependencies**: Task 2.2
- **Verification**: visual spot-check (Read tool) on several balloons — does the reconstructed
  empty balloon look plausible, no visible text ghosting?
- **Complexity**: Medium

#### Task 6.2: Layout mode — interior detection + line-region layout
- **Description**: Locate the balloon's text-safe interior polygon from the empty balloon; compute
  line regions sized to a given string's length; auto-fit font size.
- **Files**:
  - `apps/comics-ai-baloons/scripts/layout.py` - Create
- **Dependencies**: Task 6.1
- **Verification**: visual check that computed regions stay inside the balloon outline (no
  overlap with the drawn border) across a sample of balloon shapes/sizes
- **Complexity**: Medium-High (the most geometrically fiddly task in the plan)

#### Task 6.3: Text rendering — Latin/Cyrillic direct path
- **Description**: PIL-based rendering for `en`/`ru`/`uk`/`es`/`fr`/`pt`/`tr`/`vi` using the chosen
  comic-style font (font file selection is this task's first sub-step — compare 2-3 candidates
  against real dataset lettering).
- **Files**:
  - `apps/comics-ai-baloons/scripts/render_latin.py` - Create
  - `apps/comics-ai-baloons/work/fonts/` - Create (gitignored or vendored per font license — check
    license before committing font files to the repo)
- **Dependencies**: Task 6.2
- **Verification**: visual check, side-by-side with an original `en`/`ru` balloon for style
  proximity
- **Complexity**: Low-Medium

#### Task 6.4: Text rendering — headless-browser path for complex scripts
- **Description**: Playwright + Noto Sans family HTML/CSS rendering for `th`, `zh`, `ko`, `kn`,
  `ja`, `hi`, `ta`, `mr`, `bn`, `ne`, `he`, `ar` (RTL via `direction: rtl`), screenshot-compositing
  onto the balloon.
- **Files**:
  - `apps/comics-ai-baloons/scripts/render_shaped.py` - Create
  - `apps/comics-ai-baloons/work/fonts/noto/` - Create (downloaded Noto Sans family subsets;
    document source/license in README)
- **Dependencies**: Task 6.2
- **Verification**: **this is Checkpoint C** — visual review of at least one rendered sample per
  script family (Cyrillic already covered by 6.3; need one each of Thai, CJK, Devanagari-family
  Indic, Hebrew or Arabic RTL) before running the full batch
- **Complexity**: High (RTL correctness, CJK line-breaking, font fallback across 12 scripts in one
  task — the largest single risk area flagged in Specifications)

#### Task 6.5: Hand-lettering track (Track 6b)
- **Description**: Scope finalized by Checkpoint B (Task 5.3) — either a small trained
  model/style-transfer approach, or a "flag for manual review, don't auto-render" no-op that still
  produces correct report entries. **Do not start this task until Task 5.3's decision is written
  down.**
- **Files**:
  - `apps/comics-ai-baloons/scripts/render_handlettered.py` - Create
- **Dependencies**: Task 5.3, Task 6.1
- **Verification**: per whatever approach Checkpoint B lands on — either model eval against a
  held-out hand-lettered sample, or confirmation that flagged balloons appear correctly in the
  report with no fabricated render
- **Complexity**: Unknown until Checkpoint B — plan explicitly does not pre-commit an estimate

### Phase 7: Packaging & Reporting

#### Task 7.1: Re-tile + package into output `.comics`
- **Description**: Per-language re-tiling, `data.json` layer patching (append `Image` entries per
  the language table), full zip write to `work/output/`.
- **Files**:
  - `apps/comics-ai-baloons/scripts/package.py` - Create
- **Dependencies**: Task 1.4, Task 6.3, Task 6.4, Task 6.5
- **Verification**: output file opens without error in a JSON validator at minimum; ideally opened
  in `apps/comics-editor-v2.9` directly to confirm en/ru/hi still display correctly (unchanged) and
  the app doesn't choke on the extra array entries
- **Complexity**: Medium

#### Task 7.2: Report generation
- **Description**: `work/report.jsonl` + `work/report.md` per Specifications' schema — per-balloon
  outcome, per-file/per-language/per-status rollups, flagged hand-lettered list.
- **Files**:
  - `apps/comics-ai-baloons/scripts/report.py` - Create
- **Dependencies**: Task 4.2, Task 5.3, Task 7.1
- **Verification**: every balloon discovered in Task 2.1 appears exactly once in the report with a
  terminal status (rendered or a specific skip reason) — no balloon silently missing
- **Complexity**: Low

#### Task 7.3: Pipeline orchestrator
- **Description**: `pipeline.py` runs all stages in order, resumable (skips a stage if its output
  `.jsonl` already exists and is newer than its inputs, unless `--force`).
- **Files**:
  - `apps/comics-ai-baloons/scripts/pipeline.py` - Create
- **Dependencies**: All prior tasks
- **Verification**: full clean run over all 27 files completes without crashing; re-run with no
  changes is a fast no-op (resumability check)
- **Complexity**: Low-Medium

### Phase 8: Full Run & Verification

#### Task 8.1: Full 27-file pipeline run
- **Description**: Execute the complete pipeline over all of `dataset/`.
- **Files**: None (execution task)
- **Dependencies**: Task 7.3
- **Verification**: `work/output/` contains 27 new `.comics` files; `work/report.md` totals are
  sane (rendered + skipped = discovered, per file and overall)
- **Complexity**: Low (execution only — correctness already built into prior tasks)

#### Task 8.2: Manual verification pass
- **Description**: The Testing Strategy's manual checks from Specifications — visual spot-check
  per script family, hand-lettering classification review, confirm an output file opens in
  `apps/comics-editor-v2.9`.
- **Files**: None
- **Dependencies**: Task 8.1
- **Verification**: checklist in Specifications' "Manual Verification" section, all items checked
- **Complexity**: Low

## Dependency Graph

```
1.1 ─┬─→ 1.3 ─┬─→ 1.4 ─┬─→ 2.2 ─┬─→ 3.1 ─→ 3.2 ─┐
1.2 ─┘        │        │        │                ├─→ 4.2 ─┐
              └─→ 2.1 ─┘        └─→ 5.1 ─┐        │        │
                                          ├─→ 5.3 ─┼────────┤
                              5.2 ────────┘  (chk B)│        │
                                                     │        ▼
                              6.1 ←─────────────────┘   (feeds report)
                               │
                               ├─→ 6.2 ─┬─→ 6.3 ─┐
                               │        └─→ 6.4 ─┤ (chk C)
                               │                  ├─→ 7.1 ─┬─→ 7.2 ─→ 7.3 ─→ 8.1 ─→ 8.2
                               └─→ 6.5 (after 5.3)┘        │
                       4.1 ────────────────────────────────┘
```

(4.1 is CSV loading, feeds 4.2; simplified above — see per-task Dependencies for the exact list.)

## File Change Summary

| File | Action | Reason |
|------|--------|--------|
| `apps/comics-ai-baloons/pyproject.toml` / `requirements.txt` | Create | Pin pipeline dependencies |
| `apps/comics-ai-baloons/README.md` | Create | Setup + run instructions |
| `apps/comics-ai-baloons/scripts/languages.py` | Create | Canonical language↔index table |
| `apps/comics-ai-baloons/scripts/comics_io.py` | Create | Read-only zip reader / new-zip writer |
| `apps/comics-ai-baloons/scripts/tiling.py` | Create | Stitch/re-tile |
| `apps/comics-ai-baloons/scripts/models.py` | Create | Shared dataclasses |
| `apps/comics-ai-baloons/scripts/discover.py` | Create | Structural balloon discovery |
| `apps/comics-ai-baloons/scripts/extract.py` | Create | Extraction/stitch stage |
| `apps/comics-ai-baloons/scripts/ocr.py` | Create | OCR stage |
| `apps/comics-ai-baloons/scripts/csv_loader.py` | Create | Translation CSV parsing |
| `apps/comics-ai-baloons/scripts/match.py` | Create | Fuzzy CSV matching |
| `apps/comics-ai-baloons/scripts/lettering_features.py` | Create | Hand-lettering signal extraction |
| `apps/comics-ai-baloons/scripts/classify.py` | Create | Hand-lettered vs. machine-set decision |
| `apps/comics-ai-baloons/scripts/erase.py` | Create | Empty-balloon synthesis |
| `apps/comics-ai-baloons/scripts/layout.py` | Create | Text-region layout |
| `apps/comics-ai-baloons/scripts/render_latin.py` | Create | Latin/Cyrillic rendering |
| `apps/comics-ai-baloons/scripts/render_shaped.py` | Create | Complex-script rendering |
| `apps/comics-ai-baloons/scripts/render_handlettered.py` | Create | Hand-lettering track |
| `apps/comics-ai-baloons/scripts/package.py` | Create | Output `.comics` packaging |
| `apps/comics-ai-baloons/scripts/report.py` | Create | Report generation |
| `apps/comics-ai-baloons/scripts/pipeline.py` | Create | Orchestrator |
| `apps/comics-ai-baloons/work/**` | Create (gitignored) | All intermediate/output data |

No existing files are modified or deleted. `dataset/**` is never touched.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| CSV↔balloon matching produces wrong (not just missing) matches due to version drift | Medium | High — wrong translations rendered | Skip+log-first design (already in spec); Task 4.2 includes manual audit of a sample of *accepted* matches, not just skips |
| Hand-lettering track has too little data to be a real model | High | Medium — degrades to manual-review flagging, not full automation | Checkpoint B explicitly decides this before Phase 6 hand-lettering work starts; Requirements already scoped this as best-effort |
| Complex-script rendering (RTL/CJK/Indic) has subtle shaping bugs invisible without native reader | Medium-High | Medium — legibility issues in 12 of 20 languages | Checkpoint C forces visual review before full batch; flag in report rather than silently shipping bad renders |
| Output `.comics` schema assumption (additive `Images` entries) turns out to break something in the real editor | Low | Medium | Task 7.1 verification explicitly includes opening output in `apps/comics-editor-v2.9`, not just JSON validation |
| OCR accuracy too low on stylized/hand-lettered balloons to drive matching at all | Medium | Medium | Those balloons likely fail matching and get skipped+logged anyway (acceptable per Requirements — erase/render for them goes through Track 6b, which doesn't depend on OCR-based CSV matching succeeding as tightly) |
| Font licensing for the Latin/Cyrillic "comic-style" font chosen in 6.3 | Low | Low-Medium | Prefer an OFL/permissively-licensed font; document choice + license in README before vendoring |

## Rollback Strategy

Low risk by construction: no existing files are modified, `dataset/` is never written, and all
output lives under the gitignored `apps/comics-ai-baloons/work/`. Rollback is simply:

1. Delete `apps/comics-ai-baloons/work/` contents (or don't commit them — they're gitignored
   already) to discard any run's output.
2. If a script under `apps/comics-ai-baloons/scripts/` needs to be reverted, standard `git revert`/
   `git checkout` — no data-migration or external-system rollback needed.

## Checkpoints

After each phase, verify:

- [ ] All unit tests for that phase's tasks pass
- [ ] Manual/visual verification steps for that phase are done (not skipped)
- [ ] Checkpoint A/B/C decisions (where applicable) are written down before the next phase starts
- [ ] `dataset/` is unchanged (`git status` / checksum spot-check — should always be clean since
      it's not tracked as an output path anyway, but worth confirming once early on)

## Open Implementation Questions

- [ ] Exact CSV match threshold value — resolved at Checkpoint A (Task 3.2), not before
- [ ] Hand-lettering Track 6b's real approach (trained model vs. flag-only) — resolved at
      Checkpoint B (Task 5.3), not before
- [ ] Specific Latin/Cyrillic font file — resolved at the start of Task 6.3
- [ ] Whether one Noto Sans variant per script is sufficient or per-language fallback chains are
      needed — resolved during Task 6.4 / Checkpoint C

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-07-30
- [x] Notes: Approved as-is. Checkpoints A/B/C stand — do not pre-resolve their decisions before
      the checkpoint task is reached.
