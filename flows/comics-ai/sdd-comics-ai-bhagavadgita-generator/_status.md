# Status: sdd-comics-editor-ai-bhagavadgita-generator

## Current Phase

Phases 1-9: IMPLEMENTATION — functionally complete (see below, unchanged from 2026-08-07).
**Phase 10 (2026-08-09, REWRITTEN same day): REQUIREMENTS/SPECIFICATIONS/PLAN DRAFTED v2, awaiting
approval** — Panoramic PDF Source rendering for all 18 chapters, now standard vertical-scroll
everywhere with AI cutting (`comics-ai-multimodal`), AI arranging (`comics-ai-positioning`), and AI
animating (`comics-ai-animations`) as the core mechanism, per-layer `zDepth`, and a reveal-density-
derived `cameraPath`. Real PDF inspection done (see below); chapter mapping mostly unresolved
(2 of 18).

## NEW (2026-08-09): Panoramic PDF Source inspected — real findings, new rendering plan drafted

Per Anton's direct instruction, inspected `dataset/bhagavadgita/vaishnav/drawing/
All_Black-n-White.pdf` (12 pages, 622MB) and `All_Coloured.pdf` (6 pages, 95MB) via `pdfinfo`/
`pdftoppm` (poppler, already installed) — both contain **real, rich, continuous hand-drawn
panoramic illustrations**, wide/horizontal orientation (~7.4-8× wider than tall), no embedded
text/labels. Visually reviewed 4 of 12 B&W pages directly: page 1 (broad "cast" panorama), page 2
(two armies + central chariot — plausible match to Chapter 1 "Осмотр Армий"), page 3 (radiant/
temple scene), page 12 (cosmic multi-faced figure — plausible match to Chapter 11 "Созерцание
вселенского образа"). `All_Coloured.pdf` reuses B&W compositions (confirmed non-trivial page
correspondence: color page 2 = B&W page 3, not page 2). **This directly corrects the original
"art only exists for chapter 5" premise** — real art exists for potentially many more chapters,
pending full page review.

**New rendering design drafted, then corrected same day**: an initial draft (per Anton's "новый план
как отрисовать .comics v2026 для всех 18 глав включая camera и z-depth" ask) proposed keeping the
panorama's native horizontal orientation via `.comics`' `scrollType: horizontal` field. **Anton
explicitly rejected this**: *"Нет, используем везде именно vertical-scroll comic strip, арт дан в
виде драфта, нужно его скомпоновать правильно и нарезать с учетом ИИ и обученной модели"*, then
sharpened further: *"нарезать нужно именно моделью а не прямоугольниками, срасставить и анимировать
нужно тоже моделью которая предобучена на реальных данных mahabharata."* The design was rewritten
end-to-end around three already-existing, real trained/calibrated models found by direct inspection
this session:
- **Cutting** — `comics-ai-multimodal`'s trained `UNetBaseline` segmenter (`infer_segmenter.py`/
  `segment_image.py`, real checkpoint at `work/comics-ai-multimodal/models/unet_baseline.pt`), tiled
  across the panorama (fixed 256×256 input vs. pages up to ~93,524px wide — real, unresolved tiling/
  dedup engineering). **Disclosed limitation**: a second checkpoint, `maskrcnn.pt`, exists but has no
  wired inference path anywhere in this repo, and both models' training used box-shaped mask
  supervision (no true per-pixel ground truth exists) — so cutting is real model-driven region
  *proposal*, not pixel-accurate non-rectangular cutout edges.
- **Arranging** — `comics-ai-positioning`'s trained residual model (`infer_positioner.py`, real
  checkpoint at `work/comics-ai-positioning/positioner_model.joblib`, trained on real Mahabharata
  ground truth). **Disclosed finding, not papered over**: that flow's own `_status.md` records this
  exact model did NOT beat its own calibrated baseline in held-out evaluation — used here anyway per
  Anton's explicit instruction, not presented as proven-superior.
- **Animating + `cameraPath`** — `comics-ai-animations`' Mahabharata-ground-truth-calibrated
  `propose_reveal` baseline (`baseline_transform.py`) — the closest real artifact to "model
  pretrained on Mahabharata data" this repo has for animation (no learned-weights model exists here,
  only real calibrated statistics). `cameraPath` re-derived from reveal density over the vertically
  arranged layout (same lingering principle as before, now with real non-zero `y` motion).
Domain-shift risk (all three tools trained/calibrated on Mahabharata, not Gita art) is carried
forward as a real, disclosed, unverified risk. Full detail in `01-requirements.md` v0.6,
`02-specifications.md` v0.7, `03-plan.md` v0.6 (Phase 10 rewritten, 8 tasks 10.1-10.8).

## EXTRACTED (2026-08-09): Lottie camera-path / per-layer z-depth extraction

This flow briefly held (v0.2-v0.3 of `01-requirements.md`/v0.3-v0.4 of `02-specifications.md`/v0.2-
v0.3 of `03-plan.md`, all APPROVED same-day, 2026-08-09) a real addition: extracting camera-path and
per-layer z-depth from a real, previously-unaudited Lottie source in the dataset
(`dataset/bhagavadgita/vaishnav/bhagavadgita_lottie/`) and exporting it into `.comics` v2026. Per
Anton's explicit follow-up instruction ("Вынеси в отдельный sdd, из прошлого sdd удали"), **that
content has been moved into its own flow**: `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-lottie/`
— see that flow's own `_status.md` for current progress (Requirements/Specifications/Plan approved,
Implementation not yet started, real `cameraPath` coordinates already computed ad hoc for all 3
scenes). Nothing about that work is duplicated here anymore.

## Phase Status

`02-specifications.md` v0.2 **APPROVED**. `03-plan.md` v0.1 **APPROVED**. All 9 Plan phases (16
tasks) implemented and verified with real, passing tests: 85/85 Python tests (`pytest`) + 19/19
Dart tests (`flutter test`), plus one real full production run.

**Task 9.1 (real production run) result — Requirements' Must-Have 1, checked for real, not
assumed**: `python scripts/pipeline.py --all` produced **18/18 chapters `status="valid"`** in
`work/bhagavadgita/`, orders exactly `[1..18]`, no duplicates, **663/663 total slokas**, run time
111.9s. Chapter 5 correctly got all 3 real chapter-5 PSD panels composited in. Chapter 12 was
correctly `reused` (unchanged) from an earlier run, a real production-scale proof of the
idempotency contract. Task 9.2 re-ran the real Dart editor-open test against all 18 files (19/19
passing) and a full visual inspection of chapter 5's stitched-together real output confirmed
genuinely correct rendering (Cyrillic text, PSD art with transparency, correct verse ordering).

Full task-by-task detail (files, real test counts, real visual spot-checks) is in
`04-implementation-log.md`.

## Last Updated

2026-08-09 by Claude (Panoramic PDF Source inspected, new Phase 10 Requirements/Specifications/Plan
drafted for all-18-chapter rendering with camera path + z-depth, then rewritten same day after Anton
rejected the horizontal-scroll draft in favor of vertical-scroll + AI cut/arrange/animate via
comics-ai-multimodal/comics-ai-positioning/comics-ai-animations, still awaiting approval; Lottie work
extracted to its own flow; Phases 1-9 unchanged since 2026-08-07)

## Blockers

- **Phase 10 (Panoramic PDF Source) drafted v2, awaiting approval, not yet started**: real PDF
  inspection is done (see above); `01-requirements.md` v0.6, `02-specifications.md` v0.7,
  `03-plan.md` v0.6 all await approval. Real, disclosed risks carried into the Plan itself: only
  4 of 12 B&W pages visually reviewed so far (Task 10.1 is the first Implementation step, closing
  this); chapter mapping stands at 2 of 18 confirmed-plausible; production-scale PDF rendering
  (pages up to ~108in wide) has not been measured, only low-DPI previews; the segmenter's tiling/
  cross-tile dedup for a panorama this wide is a real, unsolved engineering problem; domain-shift
  accuracy is unverified for all three reused models (segmenter, positioner, reveal baseline — all
  trained/calibrated on Mahabharata, not Gita art); the positioning model is known, by its own
  flow's evaluation, not to beat its calibrated baseline, used anyway per Anton's instruction.
  Independent of the item below — Phase 10 doesn't touch Phases 1-9's own working output.
- **One manual verification step is still outstanding**: Specifications/Requirements ask for,
  beyond the real automated Dart test against all 18 real files (done, passing), "a documented
  manual open in the actual Comics Editor app" — i.e. actually launching the real macOS GUI app
  and visually confirming a rendered chapter with human eyes. Not attempted: it would open a
  visible window on Anton's real desktop, which felt like something to check in about rather than
  do unilaterally. Needs either Anton doing this himself (open
  `work/bhagavadgita/chapter_05.comics` — the most feature-complete one — in the running Comics
  Editor app once) or his explicit go-ahead for Claude to launch `flutter run -d macos` here.
  Everything else in Requirements' Must-Have 10 is satisfied by the real Dart test.
- A background research agent for Task 7.2 failed mid-run on an unrelated API session-limit error
  (not a real finding) before the task was retried directly and completed successfully — no
  lasting effect, noted here only so a future session doesn't misread the failure as a real
  blocker.

## Progress

- [x] New flow created
- [x] Dataset chapter count and source coverage measured
- [x] Existing AI-related SDD/VDD flows audited
- [x] Cross-flow gaps documented
- [x] Requirements drafted
- [x] Requirements approved (2026-08-05)
- [x] Specifications drafted
- [x] Specifications independently verified against real code/data (2026-08-06) — v0.2, one real
      bug found and fixed (image-slot language index)
- [x] Specifications approved (2026-08-06, "specs approved")
- [x] Plan drafted (2026-08-06) — v0.1, 9 phases, real environment checks (Playwright/Chromium
      confirmed working; psd-tools environment finding corrected by Anton — real install found)
- [x] Plan approved (2026-08-06, "plan approved")
- [x] Implementation started (2026-08-06)
- [x] Phase 1 (dataset loading + canonical model) — real 18-chapter/663-sloka load, tested
- [x] Phase 2.1 (deterministic storyboard) — tested; Task 2.2 (Ollama) deferred, non-blocking
- [x] Phase 3 (card rendering + deterministic theme) — tested, real visual spot-check passed
- [x] Phase 4 (chapter-5 PSD adapter) — tested; all 3 real PSDs composite successfully
- [x] Phase 5 (layout engine + tiling) — tested against a real 38-asset chapter
- [x] Phase 6 (archive packager, corrected Russian-slot placement) — tested end-to-end
- [x] Task 7.1 (structural/fidelity validation) — tested, real+failing fixtures per check
- [x] Task 7.2 (editor/viewer validation) — automated Dart test done and passing; manual GUI
      launch still outstanding (see Blockers)
- [x] Task 8.1 (manifest/report) — tested end-to-end
- [x] Task 8.2 (pipeline CLI, resumability, idempotency) — real smoke run + real reuse proof
- [x] At least 18 chapter `.comics` files generated (18/18 real, all `status="valid"`,
      `work/bhagavadgita/manifest.json`)
- [x] Task 9.1 (full production run) — real, 18/18 valid, 663/663 slokas, no duplicates/gaps
- [x] Task 9.2 (completion proof) — real Dart test against all 18 files (19/19 passing) + real
      visual inspection of chapter 5
- [ ] Implementation complete — blocked only on the manual GUI-launch verification (see Blockers);
      everything generatable/testable by Claude without opening a GUI window is done
- [x] Lottie camera-path/z-depth work (drafted+approved here 2026-08-09) extracted to
      `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-lottie/` — see that flow's own Progress
- [x] **NEW (2026-08-09)**: Panoramic PDF Source inspected directly (`pdfinfo`/`pdftoppm`, real page
      counts/dimensions/visual review of 4/12 pages) — corrects the "art only for chapter 5" premise
- [x] Phase 10 (Panoramic PDF Source) Requirements drafted (v0.5) and Specifications drafted (v0.6)
      — `scrollType: horizontal` architecture decision, density-derived `cameraPath` algorithm,
      chapter-mapping-confidence design
- [x] Phase 10 Plan drafted (v0.5) — 6 tasks (10.1-10.6)
- [x] **REWRITTEN (2026-08-09, same day)**: Anton explicitly rejected the `scrollType: horizontal`
      design ("используем везде именно vertical-scroll comic strip... нарезать нужно именно моделью
      а не прямоугольниками, срасставить и анимировать нужно тоже моделью") — Requirements revised to
      v0.6 (Must-Have 12 rewritten), Specifications revised to v0.7 (full "Panoramic PDF Source"
      section rewritten around real trained/calibrated models: `comics-ai-multimodal` for cutting,
      `comics-ai-positioning` for arranging, `comics-ai-animations` for animating), Plan revised to
      v0.6 (Phase 10 grown from 6 tasks to 8: 10.1-10.8)
- [ ] Phase 10 Requirements/Specifications/Plan approval — awaiting Anton
- [ ] Phase 10 Implementation — not started; Task 10.1 (full page review) is next

## Context Notes

- The current dataset has exactly 18 logical chapters, represented six times across six books/
  editions (`db_chapters.csv`: 108 rows).
- Russian `BookId=1` has 663 slokas; all inspected content fields are populated for every Russian
  row.
- Audio path columns are populated, but no audio media exists in `dataset/bhagavadgita/`.
- ~~Three PSD files are the only visual assets and appear to cover chapter 5 only.~~ **Corrected
  (2026-08-09)**: two additional, much larger PDF files (`All_Black-n-White.pdf`,
  `All_Coloured.pdf`) in the same `vaishnav/drawing/` directory contain real, rich, hand-drawn
  panoramic art — confirmed covering at least Chapter 1 and plausibly Chapter 11 so far, likely
  more once the remaining pages are reviewed (Phase 10 Task 10.1).
- Existing AI flows form useful stages but no text-to-comics orchestrator/storyboard/asset-generation
  bridge exists.
- A separate parallel flow, `sdd-comics-editor-ai-bhagavadgita-gpt-image-2`, owns optional external
  `gpt-image-2` artwork generation so this baseline stays local, deterministic, and cost-independent.
- `sdd-comics-ai-animations` has internal naming drift: its status/requirements and README call the
  capability “transformations”, while the tracked flow/app directory is named “animations”.
- Fresh `.comics` creation is technically proven by the multimodal package writer, but every new
  output must still pass the current editor/viewer loader because format compatibility work has
  unresolved items.
- `dataset/bhagavadgita/` must remain read-only; all generated artifacts go under
  `work/bhagavadgita/`.
- The repository already had extensive unrelated dirty/untracked changes before this flow; they are
  not part of this work and must be preserved.

## Next Action

Two independent tracks now:

1. **Phases 1-9 (18-chapter Must-Have path)**: one item remains — **Anton (or Claude, with explicit
   go-ahead) manually opens one generated chapter — recommend
   `work/bhagavadgita/chapter_05.comics`, the most feature-complete — in the running desktop Comics
   Editor app** to close out Requirements' Must-Have 10's literal "manual viewer launch" clause.
   Everything else is done and verified.
2. **Phase 10 (Panoramic PDF Source, rewritten 2026-08-09 to vertical-scroll + AI cut/arrange/
   animate)**: Anton reviews/approves `01-requirements.md` v0.6, `02-specifications.md` v0.7,
   `03-plan.md` v0.6. On approval, Task 10.1 (full page-by-page review of both PDFs, only 4/12 done
   so far) is the real next step, before any extraction code is written.

The Lottie camera-path/z-depth work's own next action (Task 1.1) now lives in
`flows/comics-ai/sdd-comics-ai-bhagavadgita-from-lottie/_status.md`, not here.

Optional, non-blocking follow-ups noted in the Plan but out of the Must-Have path: Task 2.2
(Ollama-backed storyboard enrichment), and the still-separately-unresolved YOLO11-seg/AGPL
licensing question in `sdd-comics-ai-multimodal` (Anton's own call, tracked there).

## Fork History

- None; this is a new flow. (The Lottie camera-path/z-depth work was extracted OUT of this flow into
  `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-lottie/` on 2026-08-09 — see that flow's own Fork
  History.)
