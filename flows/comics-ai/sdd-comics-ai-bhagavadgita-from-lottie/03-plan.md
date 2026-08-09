# Implementation Plan: comics-ai-bhagavadgita-from-lottie

> Version: 1.1
> Status: APPROVED
> Last Updated: 2026-08-09
> Specifications: [02-specifications.md](./02-specifications.md) (APPROVED)

## Summary

Six tasks (renumbered from `sdd-comics-ai-bhagavadgita-generator`'s Phase 10, moved verbatim, not
re-derived, per Anton's explicit extraction instruction), sequenced so the unverified position-
compositing formula gets checked before any extraction code is built on it. Entirely independent of
`sdd-comics-ai-bhagavadgita-generator`'s own Phases 1-9, except reusing that flow's
`package_comics.py`, which Task 1.4 extends rather than forks.

**Standing execution constraints, carried from this session's other work**: filesystem-only moves
where applicable, no git commands (Anton does git by hand); **no installing third-party Lottie
rendering packages** (`python-lottie`, `lottie-web`, etc. — Anton's explicit instruction, 2026-08-09).

## Task Breakdown

#### Task 1.1: Verify the absolute-position compositing formula — no external renderer
- **Description**: `02-specifications.md`'s own section flags its `absolute_y(frame) =
  pan_y(frame_start) − pan_y(root_frame) + local_y(root_frame)` formula as an unverified, principled
  guess. Per Anton's explicit constraint (2026-08-09): no installing third-party Lottie rendering
  packages for this. Instead: (a) cross-check the compositing formula's *logic* against
  `flows/comics-editor/tdd-dot-lottie-import-export`'s own precomp/parent-chain resolution findings
  — that flow already investigated real Lottie parent-transform compositing in depth (its own
  Specifications' "Precomp Handling"/`Layer.ParentId` sections) and may already have a
  confirmed-correct formula this can reuse rather than re-derive; (b) use `libs/flutter_comics`'s
  existing, tested Lottie parser (`lib/src/lottie/lottie_mapping.dart`, built by that same flow,
  480/480 tests passing) to parse the real file and inspect whatever it already resolves for
  nested-layer transforms, as a second, code-grounded cross-check.
- **Files**: None (verification/research task; may produce a small throwaway script under
  `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/` if useful, not committed as pipeline
  code). Real, computed camera-path coordinates for all 3 scenes were already produced directly from
  the formula as currently specified (not gated on this task) — see `04-implementation-log.md` for
  the full values; this task confirms or corrects the formula those values depend on, after the fact.
- **Dependencies**: None
- **Verification**: this task's own real output — the formula either confirmed against
  `tdd-dot-lottie-import-export`'s/`libs/flutter_comics`'s own real findings, or corrected with a
  real, cited reason, documented in the implementation log either way
- **Complexity**: Medium

#### Task 1.2: `import_lottie.py` — frame calibration, keyframe extraction, z-depth derivation
- **Description**: Implement `scene_pan`, replace the v1.0 draft's `frame_to_scroll_y` with
  `frame_to_scroll_position` (using the real, already-verified
  `st`/`sr`-based local→root frame conversion), normalize source pan into strictly increasing
  document scroll positions via `position = panY(frameStart) - panY(rootFrame)`, then implement
  `extract_layer_motion`, `to_translate_anim_keyframes`, and `derive_z_depth` per v1.1
  Specifications. `derive_z_depth` uses the approved unitless `K=1` relation and guards invalid/
  non-finite results to neutral `0`, using Task 1.1's confirmed (or corrected) compositing formula.
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/import_lottie.py` — Create
- **Dependencies**: Task 1.1
- **Verification**: unit tests against the real file's real numbers cited in Requirements/
  Specifications (the 3 scenes' real pan tuples; the real 6-keyframe example layer's exact keyframe
  values and derived z-depth); assert every emitted animation range is increasing; add real
  division-by-zero/non-finite/`zDepth <= -1` fallback tests
- **Complexity**: Medium-High (real, non-trivial coordinate math; the richest real test fixture is
  one specific layer, so broader correctness across ~120 animated layers needs a real integration
  pass, not just that one unit test)

#### Task 1.3: Camera-reference-layer selection + `cameraPath` reconstruction
- **Description**: Implement `select_camera_reference_layer` (scale-presence > keyframe-count >
  displacement ranking, per `02-specifications.md`'s "Reconstructed Camera-Path Element") and
  `build_camera_path` as N complete `{position,x,y}` points, including the selected layer's first
  coordinate (it must not reuse the N−1 endpoint-only `TranslateAnim` representation). Update
  `derive_z_depth` to take `camera_path` as its reference instead of the raw `pan` tuple, and to pin
  the camera-reference layer itself to `zDepth = 0`. This is the direct implementation of Anton's
  refinement ("...именно эту ломанную кривую необходимо восстановить и сохранить в отдельный
  элемент — движение камеры") — the single most load-bearing piece of this flow.
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/import_lottie.py` — Modify (adds to
    Task 1.2's file)
- **Dependencies**: Task 1.2
- **Verification**: unit test confirming `select_camera_reference_layer` picks the real `comp_0`
  `ind=43` layer on the real data; unit test confirming an N-keyframe source produces N camera
  points and N layer `TranslateAnim`s (one zero-width seed + N−1 segments), sharing the same normalized positions and verified
  absolute X/Y values; integration test confirming the real `cameraPath` is NOT identical to the
  trivial 2-keyframe linear pan (Requirements' Must-Have 4's concrete proof); the no-animated-layers
  fallback (Specifications' Edge Cases table)
- **Complexity**: Medium

#### Task 1.4: Extend `package_comics.py`'s layer/asset model for keyframe lists, `zDepth`, `cameraPath`
- **Description**: `PackagingAsset`/`_layer_json` (from `sdd-comics-ai-bhagavadgita-generator`)
  currently support exactly one static `TranslateAnim` per asset (`x`, `y` only) — per
  `scripts/package_comics.py:45-67`, checked directly. Extend (not replace) this to optionally carry
  a list of `TranslateAnim`/`ScaleAnim` keyframes and an optional `zDepth`, defaulting to today's
  exact single-static-keyframe behavior when absent — a real backward-compatible change, verified by
  re-running that flow's existing Phase 6 tests unchanged. Also extend `build_data_json` to accept
  and write an optional canonical document-root `cameraPath` point list (sibling to
  `layers`/`sounds`), ordered by strictly increasing `position` with full numeric X/Y on every point.
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/package_comics.py` — Modify
- **Dependencies**: Task 1.3 (needs the real output shape to design against)
- **Verification**: `sdd-comics-ai-bhagavadgita-generator`'s existing Phase 6 tests (18-chapter
  static-placement path) unchanged and still green; new tests for the multi-keyframe + `zDepth` path
  and for `cameraPath` being written/omitted correctly at the document root; schema test rejects
  duplicate/decreasing positions and confirms the first source coordinate is retained
- **Complexity**: Medium

#### Task 1.5: Wire into a new, separate pipeline entry point
- **Description**: Per Requirements' constraint that this output doesn't count toward or replace any
  of `sdd-comics-ai-bhagavadgita-generator`'s 18 chapters, this should NOT run inside that flow's
  `pipeline.py --all` loop — a new, separate CLI entry (e.g. `pipeline.py --lottie-source` or a
  standalone script) producing one additional `.comics` file under `work/bhagavadgita/` (exact
  filename TBD — depends on Requirements' still-open chapter-mapping/scene-count questions).
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/pipeline.py` — Modify (new CLI flag)
- **Dependencies**: Task 1.4
- **Verification**: real run producing a real `.comics` file; validated through
  `sdd-comics-ai-bhagavadgita-generator`'s existing Phase 7 structural validator
  (`validate_output.py`) unchanged, plus a manual check that `zDepth` values differ across at least
  two layers (Requirements' Must-Have 2) and that `cameraPath` is present and non-trivial
  (Must-Have 4)
- **Complexity**: Low

#### Task 1.6: Manifest/report disclosure of the parallax limitation
- **Description**: Per Requirements' Must-Have 3, the manifest/report entry for this document must
  state plainly that `zDepth` is written but not yet rendered as visible parallax by any current
  `.comics` reader — a real, disclosed text addition to `report.py`'s output for this specific
  document, not a generic disclaimer applied everywhere.
- **Files**:
  - `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/report.py` — Modify
- **Dependencies**: Task 1.5
- **Verification**: real generated report inspected for the actual disclosure text
- **Complexity**: Low

## Dependency Graph

```
1.1 -> 1.2 -> 1.3 -> 1.4 -> 1.5 -> 1.6
```

## File Change Summary

| File | Action | Reason |
|---|---|---|
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/import_lottie.py` | Create | Camera-path/z-depth extraction (Tasks 1.1-1.3) |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/package_comics.py` | Modify | Extend `PackagingAsset`/`_layer_json` for keyframe lists + `zDepth` + `cameraPath` (Task 1.4), backward-compatible |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/pipeline.py` | Modify | New, separate CLI entry (Task 1.5) |
| `apps/comics-ai/comics-ai-bhagavadgita-generator/scripts/report.py` | Modify | Parallax-limitation disclosure (Task 1.6) |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Task 1.1's compositing formula turns out wrong once cross-checked | Medium — it's an unverified guess, not a confirmed derivation | High (every downstream Task 1.2-1.6 output would need redoing) | Task 1.1 is deliberately sequenced first; after correction, regenerate both historical coordinate tables and canonical point fixtures rather than hand-patching either representation |
| Source pan decreases while the shared `.comics` interpolator expects increasing scroll positions | Confirmed, not hypothetical | High if old v1.0 ranges are copied | Task 1.2 normalizes to increasing positions and tests the invariant; the old decreasing tables remain evidence only, never serialized output |
| No external Lottie renderer allowed (Anton's explicit constraint) means verification is code/logic-level, not pixel-level | N/A — a real, accepted constraint, not a risk to mitigate away | Low | A code-level/logic cross-check against `tdd-dot-lottie-import-export`/`libs/flutter_comics` is real, if less direct, verification than a pixel comparison — the residual risk is that neither source happens to confirm the exact compositing formula this flow needs, in which case it stays a disclosed open question longer, not that the task is blocked outright |
| Modifying `sdd-comics-ai-bhagavadgita-generator`'s `package_comics.py`/`pipeline.py`/`report.py` (files that flow owns) | Low | Medium (cross-flow coordination) | Task 1.4's own design requirement (default to today's exact behavior when new optional fields are absent) means that flow's existing 18-chapter output is unaffected regardless; a cross-reference note should be added to that flow's own `_status.md` once Implementation starts here, matching this session's established practice for cross-flow file ownership |

## Rollback Strategy

Deleting `import_lottie.py` and reverting the backward-compatible additions to
`package_comics.py`/`pipeline.py`/`report.py`. Task 1.4's own design requirement (default to today's
exact single-static-keyframe behavior when the new optional fields are absent) means
`sdd-comics-ai-bhagavadgita-generator`'s existing 18-chapter output is unaffected either way,
rollback or not. `dataset/bhagavadgita/` is never written to.

## Open Implementation Questions

- [ ] Exact mechanism/depth for Task 1.1's cross-check against `tdd-dot-lottie-import-export`'s
      findings and `libs/flutter_comics`'s parser — not yet attempted, real work for Implementation.
- [ ] Exact output filename(s) for Task 1.5's new CLI entry — depends on the still-open 1-file-vs-
      3-scenes question (see Requirements' Open Questions).

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-09 — approved in the parent flow as v0.3 ("reqs,specs and plan approved")
      before extraction.
- [x] Notes: v1.0 deliberately placed Task 1.1 first because compositing, camera-reference selection,
      `K`, and cross-flow adoption were open. Requirements/Specifications v1.1 have since resolved
      `K=1` and cross-flow adoption; compositing and reference-layer selection remain real risks.

### v1.1 review gate

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-09
- [x] Notes: v1.1 aligns Tasks 1.2-1.4 and their tests with the approved canonical camera/depth
      contract. Task ordering and implementation scope remain unchanged.
