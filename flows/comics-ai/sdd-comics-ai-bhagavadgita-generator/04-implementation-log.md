# Implementation Log: comics-ai-bhagavadgita-generator

> Started: 2026-08-06
> Plan: [03-plan.md](./03-plan.md) (Phases 1-9 v0.1 and replacement production v0.7, APPROVED)

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
| 10.1 production models/version store | Done | 4/4 focused tests passing; immutable publish, validation cleanup, source-root boundary |
| 10.2 source inventory/semantic gate | Done | 5/5 focused; real 24-source deterministic inventory; full suite 101/101 passing |
| 10.3 native recovery adapters | Done | 5/5 focused real-source checkpoints; full suite 106/106 passing |
| 10.4 asset graph/reviews/invalidation | Done | 4/4 focused; immutable snapshots and transitive invalidation; full suite 110/110 passing |
| 11.1 Gold v1 dataset | Done | immutable manifest: 130 verified masks, 5 compositions, 40 held out; 121/121 full tests |
| 11.2 segmenter competition | Done — none promoted | 5 approaches, immutable fail-closed summary; 125/125 full tests |
| 11.3 identity/style retrieval | Done — identity abstained | 130 descriptors + top-5 rankings, zero identity merges; 128/128 full tests |
| 11.4 registration/colourization | Done — no colourizer promoted | 6 registrations, 24 paired crops; 132/132 full tests |
| 12.1 story beats/coverage | Done — 12 local gaps explicit | 6 beats/chapter, exact citations/full coverage; 137/137 full tests |
| 12.2 action/candidate runner | Done | 12 actions, 24 proposals, replay fully cached, zero paid/external calls; 142/142 tests |
| 12.3 exact multilingual lettering | Done — production release blocked | 267 authoritative entries; six real fixtures, 3 accepted/3 exact-OCR rejected; 146/146 tests |
| 13.1 vertical composition/depth/camera | Done — no production candidates | Shared proposed-only rule/learned contract; real chapters 1/11 have 0 accepted assets; 149/149 tests |
| 13.2 QA/release compiler | Done — release blocked | Six immutable dimensions: 3 rejected, 3 abstained; no archive published; 153/153 tests |
| 13.3 golden run/scale decision | Done — scale-out blocked | 13-manifest proof, two golden chapters, ordered autonomous remediation; 154/154 tests |

## Session Log

### Session 2026-08-10 - Codex

**Started at**: replacement production Plan v0.7 approval; Phase 10, Task 10.1

#### Completed

- **Task 10.1**: created `scripts/production_models.py` with the approved `SourceRecord`,
  `SourceSemanticScope`, `Asset`, `AssetVersion`, `Lineage`, and independent `ReviewDecision`
  records plus structural provenance validation.
- Created `scripts/production_store.py`: versions are written below `.staging`, optionally
  validated there, and atomically renamed to `<namespace>/<object-id>/<version>`; an existing
  version raises and is never overwritten. Configured source roots are resolved and rejected as
  write targets before staging is created. Failed validation removes staging and never publishes.
- Test-first evidence: observed import failure before each new module existed and the expected
  constructor failure before the source-root guard existed; final focused suite is **4/4 passing**
  (`test_production_models.py`, `test_production_store.py`).
- Full application regression suite: **94 passed, 2 failed**. Both failures are pre-existing
  real-fixture tests (`test_import_lottie.py`, `test_pipeline.py`) whose expected
  `dataset/.../unzip/1/.../Mediation of the Bhagavat Gita.json` file is absent in the current
  working tree. Task 10.1 focused tests pass and none of its code is on those failing paths.

**Ended at**: Task 10.1 complete; Task 10.2 is next.

#### Continued — Task 10.2

- Added `scripts/inventory_sources.py` with an explicit reviewed `SourceScopeRegistry`; it does no
  numeric filename inference. Both the historical `unzip/1` path and the current real
  `vaishnav/bhagavadgita/lottie_unzip/...` path resolve to standalone nine-stanza Gita Dhyanam and
  therefore zero canonical chapters. `app_BG._chiba5.psd` alone maps to confirmed chapter 5 verses
  5.14-5.29; `5_1.psd` and `5_2.psd` remain non-canonical source components.
- Implemented deterministic streaming SHA-256 inventory, stable path+content IDs, byte/media facts,
  atomic JSON publication, and a source-root output guard. Unknown numbered files remain
  `unclassified/unmapped`.
- Real execution inventoried **24 sources**, **12 semantically classified**, to
  `work/bhagavadgita/production/inventory.json`. Two complete real passes produced byte-identical
  inventory documents with SHA-256
  `7eb0d371325e2882d68da3758d99c413f9951dddfb4eca779abd59fef2da3d7e`, proving source hashes did
  not change during the read-only operation. The second verification copy was removed afterward.
- The inventory exposed a genuine dataset path drift behind Task 10.1's two full-suite failures.
  Updated the stale Lottie source references in `scripts/pipeline.py` and
  `tests/test_import_lottie.py` to the current real location; semantic classification still
  explicitly excludes this material from chapter 1.
- Test-first evidence: missing-module/import failures were observed before semantic registry,
  walker, and writer implementation. Final Task 10.2 focused suite is **5/5 passing**; combined
  affected focused suite is **11/11 passing**; full application suite is **101/101 passing** in
  43.40 seconds.

**Ended at**: Tasks 10.1-10.2 complete; Task 10.3 is next.

### Session 2026-08-11 — Codex

**Started at**: approved replacement production Plan v0.7, Task 10.3 partially present in the
worktree but not runnable or recorded as complete.

#### Completed — Task 10.3

- Preserved and verified the existing native-first adapters:
  - `scripts/adapters/psd.py` walks real PSD hierarchy without eager document compositing and lazily
    recovers a selected pixel layer as RGBA plus a true alpha-derived bitmap mask;
  - `scripts/adapters/pdf.py` uses Poppler metadata to inventory embedded PDF image objects without
    rendering pages into enormous panorama canvases;
  - `scripts/adapters/lottie.py` recovers native/precomposition layers, transforms/timing,
    referenced images, RU/EN translation files, audio provenance, the reviewed Gita Dhyanam scope,
    and explicitly labels camera/depth as derived evidence rather than gold truth.
- The failing-first checkpoint was real: `tests/test_recovery_adapters.py` could not collect because
  it imported the planned but absent `adapters.comics` module. Added
  `scripts/adapters/comics.py` with:
  - safe ZIP member/path and `data.json` validation;
  - recovery of layer kind/identity/parenting/visibility, language slots, transforms/animations,
    translations, sounds, camera path, viewport hints, and z-depth;
  - the explicit evidence class `runtime_reference_unapproved`, preventing old runtime fixtures
    from becoming production-approved labels;
  - lazy reconstruction of only the requested tiled layer/slot into source-resolution RGBA, with
    bounds, metadata, template, and missing-tile failures kept explicit.
- Real-source evidence passed:
  - PSD checkpoints `5_1.psd = 5 descendants/1 group`, `5_2.psd = 32/6`, and
    `app_BG._chiba5.psd = 419/92`, including ordered `text1…text15` groups and component groups;
  - a real separable PSD layer recovered as 309×228 RGBA and a byte-identical alpha bitmap mask;
  - 12 B&W and 6 colour PDF embedded-image records recovered without page rendering;
  - Lottie recovered 514 referenced images, 9 EN + 9 RU overlays, both real audio files, native
    transforms, and standalone-prologue semantic authority;
  - `chapter_05.comics` recovered 32 layers, Russian title slot 1, Translate `(72,72)`, and stitched
    the selected 936×200 RGBA tile set.
- Verification: focused recovery suite **5/5 passed**; full generator suite **106/106 passed** in
  34.43 seconds using the flow's `.venv`.

**Ended at**: Tasks 10.1-10.3 complete; Task 10.4 (asset graph, review, and invalidation) is next.

#### Continued — Task 10.4

- Added failing contracts first in `tests/test_asset_graph_reviews.py`; the expected collection
  failure was observed before `asset_graph.py` existed.
- Added `scripts/asset_graph.py`:
  - uncertain `AssetEntityLink` proposals never mutate `Asset.canonical_entity_ids`;
  - merge/split/create `EntityRevision` records are append-only with monotonic per-entity revisions;
  - dependency edges reject cycles and resolve all transitive dependents;
  - graph snapshots persist identity links, entity revision history, and dependencies with
    exclusive-create semantics, so an earlier historical snapshot is never overwritten.
- Added `scripts/reviews.py`:
  - independent review dimensions remain separate immutable `ReviewDecision` records;
  - approval of separable foreground kinds requires both RGBA and a bitmap mask, so a bbox-only
    character/prop/etc. cannot be accepted;
  - an upstream source/version change appends invalidation decisions for every transitively
    dependent approval while retaining the original decisions;
  - immutable review-ledger snapshots round-trip the complete decision/invalidation history.
- Verification: Task 10.4 focused suite **4/4 passed**; combined production-model/store/graph suite
  **8/8 passed**; full generator suite **110/110 passed** in 34.65 seconds.

**Ended at**: active replacement Phase 10 is complete. Phase 11.1 is next and is intentionally
human-gated: Gold v1 requires at least 120 reviewed true-mask foreground annotations across four
source-disjoint compositions, including 30 held-out instances. PSD alpha may propose masks but
cannot silently self-approve them.

#### Continued — Task 11.1 tooling (human data gate remains)

- Added the failing-first `tests/test_gold_dataset.py` contracts and
  `scripts/build_gold_dataset.py`.
- `GoldAnnotation` retains asset/source composition, semantic and principal identity, true bitmap
  mask checksum, reversible source/review geometry, split, label origin, reviewer, acceptance time,
  and acceptance state. `GoldDataset` versions are immutable manifests published with
  exclusive-create semantics.
- The validator blocks release unless there are at least 120 accepted masks, four source-disjoint
  compositions (at least two PSD and two panorama), at least 30 test instances, no composition
  crossing train and held-out splits, canonical identity for every principal character, and human
  reviewer provenance. `bbox_bootstrap` is categorically rejected from Gold v1.
- Verification: focused Gold contract **3/3 passed**; full generator suite **113/113 passed** in
  34.38 seconds.
- No synthetic entries or automatic approvals were written. The actual minimum 120 mask
  corrections/reviews remain an explicit human production gate.

**Historical handoff before the autonomous revision below**: Task 11.1 tooling was ready but still
required human-reviewed annotation population under the then-current contract.

#### Autonomous-review revision — direct instruction, 2026-08-11

- Anton explicitly removed human participation as a requirement. Requirements v0.9,
  Specifications v0.10, and Plan v0.8 now supersede every mandatory-human gate; optional human
  overrides remain append-only but never block release.
- Added `scripts/automated_review.py`. Native PSD alpha can pass source-derived integrity checks;
  panorama masks require at least two independent method families, consensus IoU ≥ 0.85, boundary
  F1 ≥ 0.75, coverage `(0.01, 0.95)`, rectangularity `< 0.98`, and complete checksummed provenance.
  The locally available box-supervised U-Net and Mask R-CNN count as one family, so they cannot
  self-certify each other.
- Extended Gold records with `review_mode` and immutable automated evidence. A versioned `auto:`
  reviewer identity is mandatory; fake human reviewer placeholders are unnecessary.
- Cultural/editorial output is labelled `machine_verified`, never represented as human theological
  approval. Lettering uses authoritative-string equality plus independent OCR; the remaining review
  dimensions are automated and may abstain, which fails closed.
- Verification: autonomous-review + Gold focused suite **6/6 passed**; full generator suite
  **116/116 passed** in 34.28 seconds.

**Ended at**: no human blocker remains. Task 11.1 next generates the real 120-mask set using native
PSD alpha and independent panorama consensus; no mask is accepted merely because one box-supervised
checkpoint produced it.

#### Continued — Task 11.1 real autonomous Gold v1 release

- Added `scripts/generate_gold_candidates.py` for bounded native-alpha recovery and reversible
  panorama candidate conversion, plus `scripts/panorama_mask_worker.py` for tiled COCO instance
  proposals independently refined by edge/colour matting. The worker persists checksummed candidate
  evidence and rejects near-rectangular, low-agreement, poor-boundary, implausible-coverage, and
  full-review-window artifacts.
- Generated 90 accepted PSD masks from three real compositions (`5_2.psd`: 26,
  `app_BG._chiba5.psd`: 60, `5_1.psd`: 4) and 40 consensus masks from two held-out B&W panorama
  pages (pages 2 and 12: 20 each). Source datasets remained read-only; masks and rendered review
  evidence are under `work/bhagavadgita/production/gold-v1/`.
- Published the exclusive-create manifest
  `work/bhagavadgita/production/gold-v1/manifest.json` as dataset
  `gold-v1-2026-08-11`: **130 accepted**, **5 source-disjoint compositions**, **40 held out**.
  Manifest SHA-256 is
  `7296e79e45aff32a593031181d820c944bd7ef4df0e2fdb336bf954583f2f738`.
- Added artifact verification that reopens every accepted mask and compares its SHA-256. This
  exposed and corrected one contract defect: native PSD layers may legitimately have signed bbox
  origins outside the canvas, so reversibility now requires positive extents/scale without clipping
  signed origins.
- Panorama COCO labels are proposal evidence only. Unknown canonical identities are stored honestly
  as unresolved/non-principal generic foreground records; they cannot enter identity metrics or be
  presented as verified Krishna/Arjuna labels. Task 11.3 owns canonical identity evaluation.
- Verification: focused Gold/autonomous/generation suite **9/9 passed**; artifact verification
  passed for all 130 files; full generator suite **121/121 passed** in 34.29 seconds.

**Ended at**: Task 11.1 complete with no human dependency. Task 11.2 compact local segmenter
competition is next.

#### Continued — Task 11.2 compact local segmenter competition

- Added `scripts/gold_segmenter_data.py` to reopen the immutable manifest, reverify every mask, and
  reconstruct exact PSD or panorama review inputs with geometry checks.
- Added `scripts/evaluate_segmenter.py` with mask IoU, tolerance-aware boundary F1, recall,
  prediction coverage/rectangularity, immutable per-instance reports, checkpoint hashes, and
  fail-closed gates. Duplicate-rate and semantic macro-F1 are explicitly `null`/failing when a
  crop-only binary benchmark cannot certify them.
- Added and trained `CompactBinaryUNet` (117,681 parameters) for 20 epochs on Apple MPS. Training
  used 86 PSD masks from two source compositions and held the third composition (`psd-5-1`, four
  masks) out for internal validation. The best internal validation IoU was 0.933, but held-out
  panorama transfer was poor (IoU 0.316, boundary F1 0.204, recall 0.050), so it was rejected.
- Benchmarked five approaches on the same 40 held-out masks:
  - legacy Mask R-CNN: IoU 0.440, boundary F1 0.024, recall 0.225, 38 artifact failures;
  - legacy U-Net: IoU 0.413, boundary F1 0.056, recall 0.175, 32 artifact failures;
  - bbox fill: IoU 0.409, boundary F1 0.003, recall 0.150, 40 artifact failures;
  - compact Gold U-Net: IoU 0.316, boundary F1 0.204, recall 0.050;
  - classical ink threshold: IoU 0.298, boundary F1 0.211, recall 0.025.
- Mask R-CNN is also circular with the COCO instance family used in panorama Gold proposal
  construction, so it cannot self-promote even if its metrics improve. This bias is stored in every
  report rather than hidden.
- Published immutable
  `work/bhagavadgita/production/segmenter-competition/summary-v1.json`, SHA-256
  `378c22dbc2b56a30a0a528c95152ed2cb178255f53977b7bee44bf612c98c90e`. Decision:
  `no_candidate_promoted`; production cutting remains fail closed and old checkpoints are reference
  evidence only.
- Verification: new metric/summary tests pass; full generator suite **125/125 passed** in 35.07s.

**Ended at**: Task 11.2 complete without human participation and without unsafe promotion. Task
11.3 identity/style retrieval and classification is next.

#### Continued — Task 11.3 identity/style retrieval and classification

- Added `scripts/classify_assets.py` with deterministic mask-bounded RGB/luminance histograms,
  shape features, quantized palettes, and conservative style tags. It writes reviewable seed-label
  proposals for semantic kind/art stage/style/palette while pose, expression, costume, and canonical
  identity stay explicitly unresolved rather than guessed.
- Added `scripts/retrieve_assets.py` with normalized cosine ranking, deterministic tie-breaking,
  and top-k neighbors. Every match is marked `similarity_only`; similarity never mutates the asset
  graph, confirms identity, or triggers a merge.
- The first immutable catalog exposed an honesty defect in the draft: fixed `.99/.60` values were
  not calibrated confidence. They were removed in v2 and replaced with `seed_label_unscored` plus
  `null` confidence; v1 remains immutable historical evidence.
- Published `catalog-v2.json` with 130 proposals (127 `art`, 3 source-proposed `character`) and
  `retrieval-v2.json` with 130 top-5 query results and **0 identity merges**. Catalog SHA-256:
  `956f96b366c0dc61e7ef253dc17539df901aa022195e2d577626b774cc3bd229`; retrieval SHA-256:
  `882a0ada7a44846ed5bc1284f437c602f3d537bc559d59cf2b68c595697993df`.
- Evaluation correctly returns `abstained`, not a fabricated score: train Gold contains only
  semantic kind `art`, test adds `character`, principal-instance count is zero, and canonical
  identity count is zero. Consequently semantic macro-F1 and identity top-1 are `null`, and no
  identity/classification model is promoted.
- Verification: deterministic descriptor, non-merging retrieval, and insufficient-coverage
  abstention tests pass; full generator suite **128/128 passed** in 41.36s.

**Ended at**: Task 11.3 complete without human participation and without invented identity labels.
Task 11.4 paired B&W/colour registration and colourization is next.

#### Continued — Task 11.4 B&W/colour registration and colourization

- Extracted read-only PDF review previews under `work/` and added
  `scripts/register_panorama_pairs.py`. It evaluates all 72 colour/B&W combinations with ORB ratio
  matching plus RANSAC homography and accepts only ≥50 inliers, ≥0.75 inlier ratio, ≥3× runner-up
  margin, and a unique B&W target.
- Automatically resolved all six pairs with very high margins: colour pages `1..6` map to B&W
  pages `1,3,4,5,6,7`. Correct pairs have 139-222 inliers and 0.897-0.963 inlier ratio; alternatives
  have at most five inliers. No filename-order assumption is used.
- Published registration `manifest-v2.json` with aligned colour evidence, full invalid-region masks,
  and 24 checksummed 512px paired crops (four per source-disjoint pair). Valid coverage is
  0.942-1.000 and registered ink-edge F1 is 0.975-0.992. Manifest SHA-256:
  `2837a2c8c1c70598493cdf154228ca10fcd05efd31a9cd71e53911094bb6217a`.
- Added deterministic luminance-bin palette transfer. It keeps B&W Lab luminance and therefore
  scored edge F1 0.99987 with max luminance drift 2.95, but mean ΔE76 74.08 failed the ≤30 palette
  gate. The result was rejected rather than accepted merely for preserving linework.
- Added and trained a source-disjoint `CompactChromaUNet` (117,698 parameters, 30 MPS epochs) on
  five panorama pairs, holding `colour-06-bw-07` out. It predicts chroma only, so original B&W
  luminance/geometry cannot be regenerated. Held-out edge F1 was 0.99994 and luminance drift 0.98,
  but ΔE76 75.84 failed; no learned colourizer was promoted.
- Verification: unique/high-margin/ambiguity registration and colourizer promotion gates tested;
  outputs visually inspected; full generator suite **132/132 passed** in 42.00s.

**Ended at**: Task 11.4 complete without human participation and without unsafe colourizer
promotion. Task 12.1 grounded story beats and coverage is next.

#### Continued — Task 12.1 grounded story beats and coverage

- Added `scripts/build_story_beats.py` with Ollama structured-output support. `qwen3:latest` proposes
  six semantic range boundaries/citations per chapter; `llama3.1:latest` supplies independent
  advisory evidence. Deterministic validation requires exactly six ordered, contiguous,
  non-overlapping ranges covering every real sloka and rejects unknown/out-of-range citations.
- Initial fluent candidates exposed unreliable reviewer behavior: it rejected directly sourced
  claims and later called empty visual requirements “invented.” The gate was strengthened rather
  than relaxed: the model now controls boundaries/citation selection only; published titles are
  deterministic range labels, synopsis is exact source translation, and entity/action/location/shot
  requirements are empty. Exact citation grounding and empty requirements are proven in code;
  reviewer opinion is retained as advisory evidence and cannot contradict those facts.
- Published `beats-v1.json`: six beats for chapter 1 covering all 37 slokas and six for chapter 11
  covering all 52, each source row exactly once. SHA-256:
  `5d54104aa2d840d7163c88675f5c5cfb9359dda0c865b680099f6d83fbcd1106`.
- Added `scripts/resolve_coverage.py` with strict priority accepted source → reuse → transform →
  generation gap. B&W pages 2/12 remain disclosed `inferred/proposed` hypotheses, not accepted
  canonical coverage; Gita Dhyanam is explicitly excluded as a standalone prologue.
- Published `coverage-v1.json`: all 12 beats are `generation_required` local actions because no
  confirmed+accepted canonical visual asset exists and identity/segmenter gates remain unresolved.
  Paid/external generation is suppressed. SHA-256:
  `54d81372b3d204636d4cb35b86c4051f553233b459cc32163903ee222cf4dc92`.
- Verification: source coverage/citation/reviewer completeness, accepted-source priority,
  inferred-source exclusion, and Gita Dhyanam exclusion tests pass; full suite **137/137 passed** in
  34.50s.

**Ended at**: Task 12.1 complete without human participation or invented narrative metadata. Task
12.2 provider-neutral action/candidate runner is next.

#### Continued — Task 12.2 provider-neutral action/candidate runner

- Added `scripts/action_runner.py` with immutable typed `ModelAction`, `Authorization`, `ActionPlan`,
  `Candidate`, provider protocol, canonical idempotency fingerprint, checksummed output files, full
  `Lineage`, proposed-only candidate state, action staging, and immutable request/result records.
- Authorization is validated before provider execution: exact action/provider binding, expiry,
  paid-call permission, minimum of action/authorization budgets, reference-upload permission, and
  per-source upload allowlist. Unsupported or unauthorized operations never reach the provider.
- Retry tests exposed and fixed a real tuple/list JSON round-trip defect in immutable request
  comparison. Requests now compare by canonical JSON hash. Successful replay never re-executes;
  paid-provider crash/retry uses the immutable action fingerprint as the remote idempotency key and
  proves one remote operation despite transport retry.
- Added `LocalVisualPlanProvider`, producing two separate proposed plan candidates per gap without
  pretending they are production artwork. Added `GptImage2Provider`; it stores no credential,
  reports external upload/cost in its side-effect-free plan, and is disabled without both a client
  and runner-validated action-bound authorization.
- Real execution materialized all 12 Task 12.1 gaps into **12 immutable local actions / 24 proposed
  candidates**, with `external_calls=0` and `paid_cost_usd=0`. A second full execution produced
  **12/12 cache hits** and no duplicate candidate/provider work.
- Immutable summaries: first-run SHA-256
  `617367b71a5ff61797ead1ed02d5ae2c7cc292075d4a4336f6cf4586c83cbde5`; replay SHA-256
  `22d8ce4b751e5a52a353b6b5ebe9f3479bc52682d180241cc5d23554cfc60316`.
- Verification: five focused idempotency/fingerprint/authorization/provider tests pass; full suite
  **142/142 passed** in 34.27s.

**Ended at**: Task 12.2 complete without human participation, paid calls, or implicit uploads. Task
12.3 exact multilingual lettering is next.

#### Continued — Task 12.3 exact multilingual lettering

- Added `scripts/lettering.py` with Unicode NFC source normalization, readback whitespace
  normalization, dynamic unique runtime-language slots, deterministic shaping, input region-mask
  retention, separate glyph-mask/RGBA artifacts, binary-search fitting, and fail-closed
  fit/collision/readability gates.
- Built the real authoritative corpus from Russian BookId 1 and English BookId 2 for chapters 1 and
  11: **267 entries** = 89 slokas × RU translation, EN translation, and Sanskrit authoritative
  source. EN/RU occupy runtime slots 0/1. Sanskrit is explicitly a separate content role with no
  runtime slot; it is not mislabeled as Hindi or forced into a fixed third slot.
- Chromium shapes local vendored Noto Sans and Noto Sans Devanagari fonts. Learned lettering style
  is not applied before a verified glyph mask (`style_stage=none_after_verified_glyph_mask`).
  Tesseract 5.5.1 performs RU/EN/Sanskrit OCR and normalized exact-string equality is mandatory.
- Published immutable evidence under `work/bhagavadgita/production/lettering/`:
  `authoritative-v1.json` SHA-256
  `8360e895867bf62ab4a5b2e6b903d1d59025576fe64c2f9863b9220533a67106` and
  `fixtures-v1.json` SHA-256
  `5c583aa288cef6cfbe1e50b9efac85371069b5a358147e5dea1799d18a9952c5`.
- All six real RU/EN/Sanskrit shaping fixtures fit at 56 px with zero collision pixels. Three pass
  exact OCR. Three remain rejected because OCR loses or alters authoritative diacritics/Devanagari
  symbols. The source text is never rewritten and OCR is not weakened to manufacture acceptance.
- These six fixtures use deterministic proof region masks because no accepted production
  balloon/caption masks exist for the golden chapters yet. They verify mask preservation and the
  complete gate path but cannot promote production lettering; release state is correctly
  `blocked` until real accepted text regions exist and every exact readback passes.
- Added four focused tests covering normalization/readback, dynamic slot uniqueness and Sanskrit
  role semantics, collision/empty masks, and all 267 real corpus entries. Full regression suite:
  **146/146 passed** in 34.05s.

**Ended at**: Task 12.3 implementation complete autonomously. Production lettering remains
fail-closed on real-mask availability and 3 exact OCR mismatches. Task 13.1 vertical composition,
depth, camera, and animation candidates is next.

#### Continued — Task 13.1 vertical composition, depth, camera and animation candidates

- Added `scripts/compose_production.py` with immutable accepted-input records and proposed-only
  `CompositionCandidate`/`Placement` contracts. Non-accepted inputs, duplicate beat occupancy,
  missing RGBA/masks, invalid geometry/checksums, or invalid depth fail before composition.
- Both deterministic vertical stacking and an optional learned-positioner adapter use the same
  1080 px vertical/portrait canvas contract. They retain editable RGBA and bitmap-mask references,
  deterministic beat order, per-layer z-depth, viewport metadata, camera path, method/checkpoint
  lineage, and quality evidence. Learned offsets cannot move assets outside the canvas or reverse
  the cursor order.
- Animation proposals are explicitly `proposed_not_packaged`; depth/camera lineage says
  `candidate_only_not_artist_intent`. Synthetic adapter tests prove generated z-depth and camera
  values pass the existing `package_comics.py` contract without promoting the synthetic layers.
- Executed against the real Task 12.1 coverage manifest. Chapters 1 and 11 each still have zero
  accepted coverage assets and six unresolved beats, so the compiler truthfully emitted zero
  composition candidates and `release_state=blocked`, not a panorama/text-card substitute.
- Published `work/bhagavadgita/production/compositions/golden-summary-v1.json`, SHA-256
  `49a0f926c351e9b8b5f5bd49af699bb6314d4ce1b69ff31a55d981bfd5e6f7b0`.
- Three focused tests cover dual proposal methods/shared packager compatibility, rejection of
  unaccepted and duplicate-beat inputs, and real fail-closed golden coverage. Full suite:
  **149/149 passed** in 41.28s.

**Ended at**: Task 13.1 implementation complete autonomously; production candidates correctly
remain absent until accepted assets close all 12 beat gaps. Task 13.2 QA/review registry and
immutable release compiler is next.

#### Continued — Task 13.2 QA, review registry and immutable release compiler

- Added `scripts/release.py` with six mandatory independent dimensions: technical,
  identity/style, art direction, lettering, cultural/editorial, and runtime. A dimension can be
  `approved`, `rejected`, `abstained`, or `stale`; only six unique approvals plus actual checksummed
  artifacts can produce `release_state=accepted`.
- Missing/duplicate dimensions, empty evidence, unknown reviewers, invalid dependency hashes,
  rejected/abstaining/stale results, absent files, or an empty release artifact set fail closed.
  Upstream checksum drift converts affected approvals to `stale` without mutating historical
  reports.
- Blocked validation atomically publishes only its immutable report. An accepted path requires a
  destination and publishes through staging/rename; existing reports/releases are never
  overwritten.
- Real golden evaluation consumed the segmenter, identity/style, both colourizers, coverage,
  lettering, and composition manifests. Results: `technical=rejected` (no segmenter promoted),
  `identity_style=abstained` (identity abstained and both colourizers rejected),
  `art_direction=rejected` (no complete accepted composition), `lettering=rejected` (3/6 exact
  OCR), `cultural_editorial=abstained` (coverage open), and `runtime=abstained` (no candidate
  archive). The seventh blocker is the intentionally absent release artifact.
- Published `work/bhagavadgita/production/releases/golden-validation-v1.json`, SHA-256
  `0890850121df3fd7a2e9176dcbd3aa4e992664bbcf85789b6478c08e9373dab2`; no release directory or
  `.comics` was created.
- Four focused tests cover complete dimension/artifact requirements, dependency invalidation,
  immutable blocked publication, and the real six-dimension outcome. Full suite: **153/153
  passed** in 41.78s.

**Ended at**: Task 13.2 implementation complete autonomously and release correctly blocked. Task
13.3 golden proof, scale decision, and final implementation report is next.

#### Continued — Task 13.3 golden production proof and scale-out decision

- Added `scripts/golden_proof.py`, which requires and hashes 13 immutable artifacts spanning Gold
  v1, segmentation, identity/style, registration/colourization, beats/coverage, lettering,
  composition, and release validation. Missing input aborts proof generation.
- The proof records the required vertical/portrait target and both golden chapters. Each has six
  grounded beats, zero accepted coverage, six generation-required gaps, zero composition
  candidates, and `release_state=blocked`. Lettering is 3/6 exact OCR.
- Copied no unaccepted model proposal into a production archive. Six review dimensions remain
  exactly as Task 13.2 measured: technical/art-direction/lettering rejected and
  identity-style/cultural-editorial/runtime abstained. `scale_out_to_all_18=blocked` follows from
  those facts and cannot be overridden by a format-valid draft.
- Recorded an ordered autonomous queue: promote/replace segmentation; resolve identity and palette;
  materialize/accept all 12 beat assets; provide real text regions and reach 6/6 exact OCR; then
  compose and run editor/viewer/device validation. `human_participation_required=false`.
- Published `work/bhagavadgita/production/golden-proof-v1.json`, SHA-256
  `70a451c20c0bc7208730dedec6ee1ac1737937be3965d4ff915ff36f0f09e780`.
- One focused integration test re-hashes every listed manifest, checks both chapter states and the
  scale decision, and proves immutable publication. Full suite: **154/154 passed** in 41.52s.

**Ended at**: all approved replacement production Tasks 10.1-13.3 are implemented without human
participation. The pipeline is production-honest and reproducible; release and all-18 expansion
remain blocked until the recorded autonomous remediation queue clears every measured gate.

#### Continued — autonomous remediation iteration 1: Gold v2.1 and segmenter retry

- Added independent `border-matting` to the benchmark. On circular panorama-consensus Gold v1 it
  failed (IoU 0.392, boundary F1 0.050, recall 0.125), proving a simple paper-background rule could
  not replace production segmentation there.
- Added `audit_gold_v2.py` and derived Gold v2/v2.1 without altering accepted mask pixels. The test
  split is now one source-disjoint PSD composition with 61 native-alpha masks; panorama consensus
  stays outside metric test. Explicit source hierarchy names alone label `animal`, `character`, and
  `fx`; generic layers remain `art`. One native-alpha child of the explicitly named `krishna` PSD
  group is identity-labelled only for that layer. Gold v2.1 manifest SHA-256:
  `0c43a7bd6a85f4290df958a47efa3ec7045c47496953da15cd5261d023d3ce57`.
- Gold v2.1 readiness is `ready`: 131 accepted masks, 61 independent held-out, four semantic kinds,
  one source-explicit principal identity, and an immutable full-panorama tiled fixture. Readiness
  SHA-256: `425829baa7a5acb12277f7a55bc6dacde79bb74402e2be3147cbf4eb948800a0`.
- Border matting passes independent crop gates (IoU 0.9275, boundary F1 0.8319, recall 0.9672, zero
  artifacts), but the corrected one-to-one tiled evaluation rejects it: recall 0.275, precision
  0.2157, duplicate rate 0.3889, and 36 collapsed truth matches; it has no semantic macro F1.
  Promotion report SHA-256:
  `7f9500c5f037f6a809b3d601d91881c635290e09a5ff8fb878c7da5008c35804`.
- The tiled fixture originally used ordinary bbox IoU against padded Gold review windows and then a
  many-to-many match, producing misleading 7.5% and 100% recall readings. The final contract uses
  containment-aware matching plus maximum bipartite one-to-one assignment, precision, duplicate,
  and collapsed-instance gates. Historical diagnostic reports are retained with `pre-*` names.
- Reused the existing isolated multimodal PyTorch/MPS environment, installing nothing. Trained a
  compact binary U-Net for 30 epochs on 66 train assets with a separate four-asset validation
  composition and untouched 61-asset test. Best validation IoU was 0.8777, but independent test IoU
  fell to 0.4344 (boundary F1 0.1026, recall 0.175), so the checkpoint was rejected. Checkpoint
  SHA-256: `2c0ad9edebf7fe055b2bbb56a1bad4f9636d0f864e57214adedb3c9a86386bfb`.
- Added nine tests across independent baseline behavior, Gold v2 splitting/readiness, explicit
  identity scope, tiled component/bipartite matching, and combined non-compensating promotion
  gates. Full suite reached **162/162 passed** before the final matching-contract refinements; all
  affected focused suites pass afterward.

**Ended at**: evaluation infrastructure is no longer the blocker. Production cutting remains
fail-closed because both new candidates are rejected. Next candidate must be true instance
segmentation with semantic output and must pass full-panorama one-to-one tiled gates.

#### Continued — autonomous remediation iteration 2: Gold v2.2 true-mask Mask R-CNN

- Derived Gold v2.2 with a semantic/source-disjoint split: 81 train, 20 validation, and 30
  independent native-alpha test masks. Test is `art+animal`; train contains explicit-source
  `art+animal+character+fx`. Manifest SHA-256:
  `c9db581259c31359d44f38472fdeb1c192e805d6a4230130b130926b307b492f`.
- Added a separate Mask R-CNN adapter that feeds real bitmap masks, not the legacy bbox-filled
  approximation. The existing isolated multimodal environment supplied torch/torchvision/OpenCV;
  no packages were installed. MPS compilation did not reach a first batch after nearly seven
  minutes and was safely interrupted before publication; CPU completed epochs deterministically.
- One CPU epoch reached crop IoU 0.825/recall 1.0 but collapsed semantic output to `art`. Continued
  two normal epochs, then three deterministic inverse-frequency balanced epochs from the immutable
  checkpoint. Final loss 0.136, crop IoU 0.8544 and recall 1.0, but animal F1 remained 0 and macro
  F1 0.4828 exactly equalled the majority-`art` baseline.
- Corrected boundary evaluation for model-grid resolution: tolerance is exactly two pixels at the
  documented max-768 inference grid, scaled to each native crop. This lifted boundary F1 from an
  artificially strict 0.150 to 0.294, still far below the 0.70 gate. The pre-normalization report
  remains preserved.
- Full 8192px panorama tiled inference failed independently: recall 0.275, precision 0.2895,
  duplicate rate 0.4211, and 34 collapsed truth matches. Tiled report SHA-256:
  `d33dca6c5bcd9c53677bffcb28ce46078ee175a2d3dffc94110acbcc9f510a54`.
- Final non-compensating promotion report rejects boundary, semantic-above-majority, every-class,
  tiled recall/precision/duplicates/collapse gates. SHA-256:
  `8bbd01c05d5f3be44ac3b43619e37364adf0bb75eec773369c29ad7633b1a141`.

**Ended at**: production segmenter still not promoted. Additional epochs on the same isolated,
rare-class-starved supervision are not justified; next remediation must add independently accepted
panorama instances and rare semantic examples before retraining.

#### Continued — autonomous remediation iteration 3: independent exact-lettering audits

- Added `scripts/audit_lettering_ocr.py` and evaluated every rejected real lettering fixture with
  an independent 24-configuration Tesseract matrix (relevant language/script models, PSM 6/11,
  native and 2x scale). No configuration produced an exact authoritative string; no wordlist,
  fuzzy match, diacritic removal, or post-OCR correction was allowed. The immutable report is
  `work/bhagavadgita/production/lettering/ocr-audit-v1.json`, SHA-256
  `0c7a8fbca772b35c763b61a441ff0106a2891e7891446578ec5cfbf41e8ba89c`.
- Added a second-engine audit through Apple Vision's accurate recognizer. The Swift adapter sets
  `usesLanguageCorrection=false` and supplies no `customWords`. Transparent fixtures are composited
  on white only for OCR input; authoritative strings and rendered assets are not changed.
- Apple Vision rejected the remaining English fixture: it read `Dhrtarāstra`, `Pandu`, and
  `Kurukşetra` instead of the required fully diacritic string. Vision exposes no Sanskrit/
  Devanagari recognition language on this host, so both Sanskrit failures are explicitly
  `abstained`, never inferred from English or accepted by normalization.
- Published `work/bhagavadgita/production/lettering/vision-ocr-audit-v1.json`, SHA-256
  `f6ae4a532680669cb29f5b3a029171881269e4dae5140ac7e5b8287794180b1d`. The audit remains
  `decision=rejected` with states `[rejected, abstained, abstained]`.
- Added focused tests for the OCR matrix's no-shortcut contract and for the Vision adapter's
  accurate/no-correction/no-custom-word configuration.
- Re-ran the complete lightweight application suite after the audit: **170 passed, 2 skipped** in
  35.97s before the render-promotion additions. The two skips are the existing torch-only cases in the lightweight environment; their
  three focused tests pass separately in the established multimodal torch environment. `git diff
  --check` is clean.
- Audited the next segmentation input contract against the local environment. No independent SAM,
  SAM2, Mask2Former, Detectron2, or YOLO-seg checkpoint is locally present. The only available
  learned masks are the COCO family that participated in panorama consensus and this flow's already
  rejected U-Net/Mask R-CNN checkpoints. Reusing them as either of the two required independent
  reviewer families would be evaluation contamination, so no synthetic Gold v2.3 was published.
- Re-checked colour evidence: six geometrically registered coloured source pages and 24 paired crops
  remain valid recovered source assets, while the deterministic and learned colourizers remain
  rejected by their palette gates. The registered pages do not include the hypothesised chapter-1
  page 2 or chapter-11 page 12, so they cannot resolve either golden pilot by provenance alone.
- Continued with a bounded render-side search instead of OCR correction. Added
  `audit_lettering_render_variants.py` and evaluated 592 combinations across the three rejected
  fixtures using only the shipped Noto fonts, six weights, six sizes, relevant exact OCR engines,
  and PSM 6/11. English 1.1 and Sanskrit 11.1 remained inexact, but Sanskrit 1.1 had 44 exact rows.
  Audit SHA-256: `43fa1a9d0caa97f4188128156eb19e92366f4288c7a488952cfd9ca510e07750`.
- Extended the production renderer with an explicit, recorded variable-font weight and added
  `promote_lettering_variant.py`. Re-rendered Sanskrit 1.1 at weight 700/size 52 through the actual
  layout, bitmap-mask, and exact Tesseract gate. It passed with four independent exact audit rows;
  the immutable promotion report SHA-256 is
  `f753629c74b8f7fe5a63d26a2ba99314be70689a931a50190d9a69d508dd5ca5`.
- Exact lettering therefore improves from **3/6 to 4/6**, while aggregate `release_state` remains
  correctly `blocked`; no fuzzy acceptance or authoritative-text mutation was introduced.
- Final verification after promotion: **172 passed, 2 expected torch-only skips** in 35.53s; the
  corresponding torch-focused suite had already passed 3/3 in its established environment, and
  `git diff --check` remains clean.

**Ended at**: exact lettering remains correctly fail-closed at 4/6 after a real render-side
improvement. English 1.1 and Sanskrit 11.1 remain rejected across the bounded shipped-font search;
the next candidate must materially improve glyph rendering or use another independently capable
exact reader rather than an exemption.
Production segmentation likewise awaits genuinely independent panorama supervision; local absence
is recorded as an input limitation, not converted into a human-approval blocker.

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
