# Implementation Plan: comics-ai-bhagavadgita-generator

> Version: 0.1
> Status: DRAFT
> Last Updated: 2026-08-06
> Specifications: [02-specifications.md](./02-specifications.md) (v0.2, **APPROVED** 2026-08-06)

## Note on drafting order

This Plan was drafted per Anton's explicit `resume comics-ai/sdd-comics-ai-bhagavadgita-generator
plan` instruction, moments before his separate, real "specs approved" message landed for
`02-specifications.md` v0.2. No conflict: Specifications didn't change between drafting this Plan
and that approval, so this document's content is unaffected — noted here only so the timing isn't
confusing when read back later. This Plan itself still awaits its own explicit "plan approved."

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

## Dependency Graph

```
1.1 -> 1.2 ─┬─> 2.1 -> 2.2 ─┐
            ├─> 3.1 -> 3.2 ─┼─> 5.1 -> 5.2 -> 6.1 -> 7.1 ─┬─> 8.1 ─┐
            └─────────────────┘                            │        ├─> 8.2 -> 9.1 ─┬─> 9.2
                                                              7.2 ────┘                │
                                                    (needs 6.1's real output) ─────────┘
4.1 (independent) ─────────────────────────────────> feeds into 5.1 for chapter 5 only
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

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Scripts run under the wrong Python interpreter can't find `psd-tools` (real mistake this Plan itself made once, corrected by Anton) | Medium | Low | Confirmed `psd-tools` 1.17.4 is real and importable under `/opt/homebrew/bin/python3.14`; Task 4.1's tooling/venv setup must target that interpreter (or an equivalent one with `psd-tools` installed), not assume any `python3` resolves it. Specifications' graceful-fallback path still exists as a safety net for environments that genuinely lack it. |
| Devanagari/Cyrillic text shaping renders incorrectly in a way automated pixel checks don't catch | Medium | Medium | Real visual spot-check of at least a few rendered cards required in Task 3.1's verification, not just "non-empty pixels" — automated checks alone are insufficient for shaping correctness, per this repo's own established lesson from `comics-ai-baloons` |
| The image-slot fix (Task 6.1) regresses if someone edits the packager later without re-reading this Plan/Specifications | Low | High (silent semantic corruption, not a crash — same character as the original bug) | Task 7.1's dedicated regression test is the real guard, not just code comments |
| Task 7.2 (Flutter/Dart editor test) requires real cross-app coordination this Plan's author has less direct visibility into than the Python side | Medium | Medium | Budget real time for this task specifically; do not treat it as a formality — Requirements' Must-Have 10 explicitly requires a *real* editor/viewer open, not a simulated one |
| Large chapter-5 PSDs (up to 264MB, 4127×26421px, confirmed via real header inspection) could exceed reasonable memory during compositing | Medium | Low (Should-Have, non-blocking) | Task 4.1's own fallback path already treats "excessive memory demand" as an expected, handled failure mode |

## Rollback Strategy

Entirely new app (`apps/comics-ai/comics-ai-bhagavadgita-generator/`) plus generated output under
`work/bhagavadgita/` (gitignored) plus one new Dart test file. Rollback is deleting the new app
directory and the new test file; no existing app's code is modified, no `.comics` schema migration
is introduced, `dataset/bhagavadgita/` is never written to.

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

- [ ] Reviewed by: Anton Dodonov
- [ ] Approved on: [date]
- [ ] Notes:
