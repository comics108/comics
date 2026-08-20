# Status: sdd-comics-editor-ai-bhagavadgita-generator

## Current Phase

Phases 1-9: IMPLEMENTATION — functionally complete and retained as format/source-fidelity regression
fixtures, not accepted as final production artwork.

**Production-art pivot: IMPLEMENTATION (Plan v0.7 APPROVED).** Anton approved the asset-first Requirements
v0.8 on 2026-08-09 (`reqs approved`) and approved Specifications v0.9 on 2026-08-10
(`"Сохрани обсужденные детали и заапрувь"`). The old direct panorama
cut/arrange/animate Phase 10 and its Specifications/Plan are explicitly superseded and must not be
implemented. Revised Requirements now define source recovery, true bitmap masks/matting,
identity/style asset graph, story-beat coverage, paired sketch colourization, controlled local and
`gpt-image-2` gap filling, exact lettering, golden chapters 1+11, and production art-direction gates.
Revised Specifications and replacement Plan v0.8 are approved. Active replacement Phase 10
(Tasks 10.1-10.4), Tasks 11.1-11.4, and Tasks 12.1-12.3 are complete. No segmenter, identity
classifier, or colourizer passed promotion, so those production paths remain fail closed. The
lettering implementation is complete, while production lettering remains fail closed until accepted
real text-region masks exist and every exact OCR gate passes. Task 13.1 vertical composition is also
implemented and correctly emits no real candidates because both golden chapters have zero accepted
coverage assets. Task 13.2 QA/release state machine is implemented and the real golden validation
is blocked across all six independently recorded dimensions; no release archive was emitted. Task
13.3 is complete with a 13-manifest reproducible proof bundle and an autonomous five-action
remediation queue. Replacement production Plan v0.8 implementation is complete. The first
post-plan remediation iteration produced evaluation-ready Gold v2.1 and evaluated two new
segmenter paths plus a true-mask semantic Mask R-CNN; none passed production gates. Two independent
exact-lettering audits initially failed to improve the real 3/6 result. A subsequent bounded search
over shipped-font size/weight variants found and production-verified a Sanskrit 1.1 candidate,
improving lettering to 4/6; English 1.1 and Sanskrit 11.1 remain exact failures. Golden release and all-18
scale-out correctly remain blocked by measured quality gates, not human participation.
The improvement now propagates through immutable `fixtures-v2`, validation v3, and golden proof v3.
Identity v3 also resolves exactly one Krishna asset from explicit PSD hierarchy while retaining 130
abstentions and zero similarity merges.
Independent panorama remediation now has official SAM ViT-B plus a separate multiscale pixel-graph
reviewer. Strict IoU≥0.80 initially found nine agreements, but visual source-context QA showed all
were local fragments rather than complete instances. The corrected completeness gate accepts 0/30;
the nine diagnostic pairs are retained as rejected evidence.
Six registered author-colour/B&W source pairs and SAM sparse/dense/crop-refined configurations were
then exhausted under completeness, source-ink, boundary, and border gates. Every numeric survivor
was a fragment, background, border-truncated, or compound region on context review; accepted
independent supervision remains 0/30.

## NEW (2026-08-10): Semantic source scopes verified and saved

- `bhagavadgita_bodymovin/unzip/1/` is the complete 9-stanza Gita Dhyanam standalone prologue in RU/EN,
  not canonical chapter 1. Directory `1` and `S3_B1_C1` are production/package identifiers.
- `app_BG._chiba5.psd` is canonical Bhagavad Gita chapter 5, verses 5.14-5.29, represented by 15
  sequential balloon/caption groups.
- `5_1.psd` and `5_2.psd` are production components reproduced inside the chapter-5 PSD; suffixes
  must not be inferred as verse identifiers.
- Specifications v0.9 now require immutable `SourceSemanticScope` records and reject filename-only
  chapter mapping before story-beat coverage or release.

## NEW (2026-08-09): Production asset-first vision recorded

- `.comics` is the final compiler target; the canonical intermediate is a reviewed asset graph.
- PSD alpha/hierarchy and Bodymovin assets are recovered before flattened-image segmentation.
- A compact local instance segmenter may be trained on the Apple M4 Max, but must output and retain
  RGBA + bitmap masks, use source-disjoint evaluation, and beat the current bbox path.
- Visual narrative maps chapters to 6+ story beats, not one PDF page to one chapter.
- Chapters 1 and 11 are the golden production pilots before scaling to all 18.
- The separate `gpt-image-2` path becomes one provider for explicit missing/repair/variant asset
  tasks, never unchecked one-shot chapter art or final lettering.

## HISTORICAL / SUPERSEDED (2026-08-09): Panoramic PDF Source direct-rendering draft

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

## EXTRACTED (2026-08-09): Bodymovin camera-path / per-layer z-depth extraction

This flow briefly held (v0.2-v0.3 of `01-requirements.md`/v0.3-v0.4 of `02-specifications.md`/v0.2-
v0.3 of `03-plan.md`, all APPROVED same-day, 2026-08-09) a real addition: extracting camera-path and
per-layer z-depth from a real, previously-unaudited Bodymovin source in the dataset
(`dataset/bhagavadgita/vaishnav/bhagavadgita_bodymovin/`) and exporting it into `.comics` v2026. Per
Anton's explicit follow-up instruction ("Вынеси в отдельный sdd, из прошлого sdd удали"), **that
content has been moved into its own flow**: `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-bodymovin/`
— that flow is now IMPLEMENTATION COMPLETE: it added the standalone `--bodymovin-source` pipeline and
extended this flow's `package_comics.py`/`pipeline.py`/`report.py` backward-compatibly; all 92 tests
pass and the 18-chapter path remains unchanged. See its `_status.md` for the verified output details.
Nothing about that work is duplicated here anymore.

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

2026-08-20 by Antigravity (Phase 14 v3: clarified that Miw lettering is her own story text
(lettering_mode: embedded_artist_text, not Gita slokas); Gita slokas 2.62-2.65 used as semantic
priors for object classifier + animation mood via story-script pipeline (SceneExtraction/Ollama);
boranko dataset used for segmenter + animation proposer fine-tuning. Task 14.1 updated to include
story-script run on Gita slokas. Plan v0.9 fully updated in 03-plan.md.)


## Blockers

- None requiring human participation. Requirements v0.9 / Specifications v0.10 replace all manual
  gates with fail-closed automated reviewers. Paid/external generation remains optional; the local
  deterministic path must complete without it.
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
- [x] Bodymovin camera-path/z-depth work (drafted+approved here 2026-08-09) extracted to
      `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-bodymovin/` — see that flow's own Progress
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
- [x] **SUPERSEDED (2026-08-09)**: direct panorama → existing cut/arrange/animate Phase 10 rejected
      in favor of the production asset-first vision; its v0.7 Specifications/v0.6 Plan retained only
      as historical evidence and marked MUST NOT implement
- [x] Production asset-first vision approved by Anton and saved in Requirements v0.8
- [x] Requirements v0.8 formally approved on 2026-08-09 (`reqs approved`)
- [x] Replacement production Specifications v0.8 drafted
- [x] Replacement production Specifications v0.9 approved (2026-08-10)
- [x] Replacement production Plan v0.7 drafted
- [x] Replacement production Plan v0.7 approved (2026-08-10, `plan approved`)
- [x] Production Task 10.1 — canonical production models, immutable validated version store, and
      source-root write boundary; 4/4 focused tests pass
- [x] Production Task 10.2 — source inventory and semantic-scope gate; 5/5 focused tests, real
      24-source deterministic inventory, stale Bodymovin fixture path corrected, 101/101 full tests
- [x] Production Task 10.3 — native PSD/PDF/Bodymovin/`.comics` recovery adapters; real hierarchy,
      mask, embedded-image, translation/audio, slot/transform/tile checkpoints; 5/5 focused and
      106/106 full tests
- [x] Production Task 10.4 — asset graph, uncertain identity proposals, append-only merge/split
      revisions, immutable graph/review snapshots, transitive invalidation, and bbox-only
      foreground rejection; 4/4 focused and 110/110 full tests
- [x] Production Task 11.1 — immutable Gold v1 dataset generated and artifact-verified: 90
      native-alpha PSD masks plus 40 two-family panorama consensus masks, 130 total across 5
      source-disjoint compositions, 40 held out; 121/121 full tests
- [x] Production Task 11.2 — five segmenter approaches benchmarked and ranked; compact 117,681-
      parameter U-Net trained source-disjoint on MPS; no candidate passed mask/boundary/recall and
      complete promotion gates, so no model promoted; immutable summary; 125/125 full tests
- [x] Production Task 11.3 — deterministic descriptor/palette/style proposals and top-5 retrieval
      for 130 assets; no automatic identity merge; evaluation explicitly abstains because train
      kind coverage and canonical principal identity coverage are insufficient; 128/128 tests
- [x] Production Task 11.4 — all 6 colour panoramas uniquely registered to B&W pages with 24 paired
      crops and invalid masks; edge F1 0.975-0.992; deterministic and compact learned colourizers
      preserve ink but fail palette ΔE gates, so neither promoted; 132/132 tests
- [x] Production Task 12.1 — 12 source-grounded beats for chapters 1 and 11, exact citation/full
      coverage validation, independent local-model advisory evidence, and coverage matrix; all 12
      unresolved visual gaps routed to local actions, no paid generation; 137/137 tests
- [x] Production Task 12.2 — immutable provider-neutral runner, action fingerprinting,
      authorization/budget/upload gates, crash-safe provider idempotency contract, local provider,
      disabled-by-default gpt-image-2 adapter; 12 actions/24 proposals, replay 12/12 cached; 142/142
- [x] Production Task 12.3 — deterministic authoritative RU/EN/Sanskrit corpus, dynamic runtime
      language slots, retained region/glyph masks, complex-script shaping, layout/collision gates,
      and normalized exact OCR readback; six real fixtures, 3 accepted/3 fail-closed; 146/146 tests
- [x] Production Task 13.1 — vertical/portrait rule and learned-positioner candidate contracts,
      editable RGBA/mask references, deterministic beat order, bounds/overlap gates, proposed-only
      z-depth/camera/animation and shared packager proof; real chapters 1/11 remain 0-candidate
      blocked because all 12 beats lack accepted assets; 149/149 tests
- [x] Production Task 13.2 — immutable six-dimension gate report, missing/duplicate dimension and
      artifact rejection, upstream-hash stale invalidation, atomic accepted-only publication; real
      validation has 3 rejected/3 abstained dimensions plus missing archive, so emits report only;
      153/153 tests
- [x] Production Task 13.3 — reproducible golden proof over 13 checksummed manifests, per-chapter
      coverage/composition readiness, six-dimension outcome and ordered autonomous remediation;
      golden release and all-18 scale-out correctly blocked; 154/154 tests
- [x] Remediation 1 — Gold v2.1 independent evaluation: 131 masks, 61 native-alpha held-out,
      semantic diversity only from explicit PSD groups, one layer-scoped Krishna identity, and a
      full-panorama bipartite tiled fixture; evaluation infrastructure ready
- [x] Remediation 1 — border-matting and compact Gold v2.1 U-Net evaluated and rejected. Border
      matting crop IoU/F1/recall = 0.927/0.832/0.967 but tiled recall/precision = 0.275/0.216,
      duplicates 0.389, 36 collapsed matches, no semantic macro F1. U-Net independent test IoU
      0.434 despite best validation IoU 0.878
- [x] Remediation 2 — Gold v2.2 semantic/source split plus true-bitmap-mask Mask R-CNN. Six CPU
      epochs (last three inverse-frequency balanced) improve crop IoU to 0.854 and recall to 1.0,
      but normalized boundary F1 is 0.294, animal F1 stays 0, tiled recall/precision are
      0.275/0.289, duplicate rate 0.421, and 34 truth instances collapse; candidate rejected
- [x] Remediation 3 — independent exact-lettering audits. Tesseract's 24 relevant language/PSM/
      scale configurations produce 0 exact matches on the three rejected fixtures. Apple Vision
      accurate/no-correction rejects the remaining English fixture and explicitly abstains on two
      unsupported Sanskrit fixtures; no fuzzy, wordlist, or diacritic shortcut is accepted
- [x] Remediation 3 render variants — 592 bounded shipped-font weight/size/OCR combinations find
      44 exact rows for Sanskrit 1.1. The actual renderer independently reproduces and promotes its
      weight-700/size-52 candidate; lettering improves from 3/6 to 4/6 while release stays blocked
- [x] Remediation 3 verification — final suite 172 passed, 2 expected torch-only skips in the lightweight app
      environment; all 3 skipped-scope torch tests pass in the established multimodal environment;
      `git diff --check` clean
- [x] Next-input audit — no independent panorama segmenter/checkpoint is locally present; existing
      COCO-consensus and flow-trained models are contamination or already rejected, so Gold v2.3 is
      not fabricated. Six registered colour pages remain valid recovered source evidence but cover
      neither golden pilot's hypothesised B&W page 2/12
- [x] Remediation 4 — immutable canonical evidence chain updated: lettering fixtures v2 records
      4/6; validation/proof v3 consume it without rewriting v1. Another 730 font/alignment attempts
      and all 1,716 Sanskrit word-preserving line-layout OCR attempts fail for the remaining strings
- [x] Remediation 4 — identity v3 resolves exactly one Krishna asset from explicit PSD parent-group
      provenance across its v1→v2 lineage; 130 remain abstained and similarity identity merges stay 0
- [x] Remediation 4 verification — 182 passed, 2 expected torch-only skips; `git diff --check` clean
- [x] Remediation 5 — local visual-plan candidates confirmed non-art; local Moondream panorama
      mapping audit abstains due unreliable extreme-aspect/crop descriptions
- [x] Remediation 5 — official Apache-2.0 SAM ViT-B reviewer (84 masks) plus independent
      multiscale Felzenszwalb reviewer (4,864 regions); strict one-to-one IoU≥0.80 finds 9 local
      agreements, but source-context QA rejects all as incomplete fragments. Corrected complete-
      instance count 0/30; Gold v2.3 not published
- [x] Remediation 5 verification — 186 passed, 2 expected torch-only skips; torch reviewer suite
      4/4 passed; `git diff --check` clean
- [x] Remediation 6 — context QA corrected all 9 original agreements to fragments; six additional
      author-colour/B&W paired compositions tested with sparse/dense/crop-refined SAM, region IoU,
      B&W boundary, source-ink, completeness, and border gates; final accepted supervision 0/30
- [x] Remediation 6 — machine-readable summary forbids threshold lowering, fragment/background/
      border promotion, repeated SAM parameter search, and contaminated COCO reuse; next input is a
      newly licensed object-level reviewer family with non-overlapping training lineage
- [x] Remediation 6 verification — 191 passed, 2 expected torch-only skips; reviewer torch suite
      9/9 passed; `git diff --check` clean
- [ ] **⭐ Phase 14 (2026-08-20 v3 — HIGHEST PRIORITY)**: Boranko fine-tuning → Miw object segmentation + animations + multilingual lettering → `.comics`
  - [ ] Task 14.0 — boranko dataset audit: index layers/ PNGs, parse ASHES.json Lottie keyframes
  - [ ] Task 14.1 — inspect `sinuan_comics_2.62-2.65-vertical.png`, emit `source_scope.json` + `scene_priors.json` (story-script on Gita 2.62-2.65)
  - [ ] Task 14.2 — fine-tune UNetBaseline segmenter on boranko object layers (MPS, strict IoU/boundary gates)
  - [ ] Task 14.3 — fine-tune animation proposer on boranko Lottie keyframes (GradientBoosting/MLP)
  - [ ] Task 14.4 — object-level segmentation of Miw PNG → RGBA objects per panel
  - [ ] Task 14.5 — map panels + objects to slokas 2.62-2.65
  - [ ] Task 14.6 — generate per-object animations (Lottie JSON skeletons, cameraPath)
  - [ ] Task 14.7 — assemble full layered `work/bhagavadgita/miw/chapter_2_miw.comics`
  - [ ] Task 14.8 — validate, register in manifest
  - [ ] Task 14.9 — multilingual lettering localization: OCR RU → translate EN/TH/ZH/HI/BN via Ollama → render with complex-script shaping → `chapter_2_miw_localized.comics`

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
- Bodymovin `unzip/1` is Gita Dhyanam and cannot count toward canonical chapter coverage; the editable
  PSD with balloons is chapter 5 verses 5.14-5.29. These are explicit semantic scopes in approved
  Specifications v0.9, not filename assumptions.
- The repository already had extensive unrelated dirty/untracked changes before this flow; they are
  not part of this work and must be preserved.

## Next Action

**⭐ HIGHEST PRIORITY (2026-08-20)**: Implement Phase 14 — Miw Artist Source → `.comics`.

Artist **Miw** (Sinuan) has delivered a real hand-drawn vertical strip comic with Russian lettering
at `dataset/bhagavadgita/miw/drawing/sinuan_comics_2.62-2.65-vertical.png` (Bhagavad Gita 2.62-2.65,
chapter 2). This is already a finished production artwork with layout and lettering — no AI generation,
no segmentation of panoramas needed. Execute Tasks 14.1→14.5 in order:

1. **Task 14.1** — inspect PNG, emit `work/bhagavadgita/miw/source_scope.json`
2. **Task 14.2** — detect panel boundaries, save crops to `work/bhagavadgita/miw/panels/`
3. **Task 14.3** — map panels to slokas 2.62-2.65 from canonical CSV
4. **Task 14.4** — package as `work/bhagavadgita/miw/chapter_2_miw.comics`
5. **Task 14.5** — validate and register in manifest

After Phase 14 is complete: continue panorama supervision remediation (Phases 10-13 remediation
queue — next input is a newly licensed object-level reviewer family with non-overlapping training
lineage, as noted in Remediation 6 machine-readable summary).



## Fork History

- None; this is a new flow. (The Bodymovin camera-path/z-depth work was extracted OUT of this flow into
  `flows/comics-ai/sdd-comics-ai-bhagavadgita-from-bodymovin/` on 2026-08-09 — see that flow's own Fork
  History.)
