# Test Cases: dot-lottie-import-export

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-08-07
> Requirements: [01-requirements.md](01-requirements.md)

## Overview

Cases-first behavioral analysis for `apps/comics-editor`'s new Lottie import/export capability, per
`01-requirements.md` (v0.2, approved). Organized around the decisions already made there: import is
a **review/triage step** (Джанава-informed), not a silent one-shot conversion; export is a simpler
one-shot action; two real choices (time-base ratio, easing precision) are **user-facing dialogs**,
not silent defaults; round-trip fidelity is **behaviorally equivalent**, not byte-exact; and the new
`TextRegion`/`GroupId` schema fields participate in both directions.

---

## Category A — Import: the review screen (happy path and triage states)

**A1 — A simple, fully-supported `.lottie` file shows an all-clean review screen**
- Given: a `.lottie` file whose every layer is Lottie image type (`ty:2`), no shapes/masks/text
- When: the user picks it via "Import from .lottie"
- Then: the review screen shows N layers, all marked "converts cleanly," no flagged items; the
  time-base-ratio and easing-precision choices are presented (Category C/D); committing the import
  creates one `EditorLayer` per Lottie image layer with translate/rotate/scale/alpha `Anim`s
- Design implication: the review screen needs a per-layer status list (clean/flagged), not just an
  aggregate "N layers found" — matches Джанава's "review states matter" principle from
  `01-requirements.md`

**A2 — A `.lottie` file containing an unsupported layer type shows it flagged, not silently dropped or crashed on**
- Given: a `.lottie` file with a mix of image layers (`ty:2`) and one shape layer (`ty:4`)
- When: imported
- Then: the review screen shows the image layers as clean, the shape layer explicitly flagged
  ("unsupported: shape layer — will be skipped" or similar), with a running "N clean / M flagged"
  count; committing imports only the clean layers, the shape layer is never silently turned into
  something else
- Edge case: a file that is *entirely* unsupported content (e.g. all shape layers) — review screen
  shows 0 clean / N flagged; committing produces an empty or near-empty document, which itself
  should probably be a distinct warning state, not a silent success

**A3 — A `.lottie` file with a precomp layer (nested composition) shows it as one importable group, not flattened without a trace**
- Given: a `.lottie` file with a root precomp layer (`ty:0`) referencing a nested comp asset of 3
  image layers (matches the real `ASHES.json` shape)
- When: imported
- Then: the review screen shows this as "3 layers (from precomp '&lt;name&gt;')" — one collapsible
  group entry, not 3 unrelated rows; committing produces 3 `EditorLayer`s tagged with a shared new
  `GroupId`, each with the precomp's own transform baked into its individual keyframes (per
  Requirements' Precomp Handling decision)
- Design implication: the review screen's data model needs to represent grouping *before* commit,
  not just after — the group relationship has to survive from Lottie parse through to the review
  UI through to the final `EditorLayer`/`GroupId` assignment

**A4 — Cancelling at the review screen leaves the document untouched**
- Given: any `.lottie` file, review screen shown
- When: the user cancels instead of committing
- Then: no `EditorLayer`s are created, no document mutation occurs, no partial/half-imported state
  — matches this app's existing cancel-is-silent-and-clean convention (e.g. the existing Export
  dialog's own cancel behavior, `top_bar.dart:284`)

## Category B — Import: the two user-facing choice dialogs

**B1 — Time-base ratio: the "as-is/identity" option produces 1 frame = 1 scroll-unit**
- Given: a `.lottie` file with a keyframe at frame 100
- When: the user picks "as-is" in the ratio dialog and commits
- Then: the resulting `Anim.start`/`end` uses `100` directly (no rescaling) — matches Requirements'
  reasoning that some source content may never have had a real scroll concept in mind, so identity
  is a real, not just a mathematically-convenient, choice

**B2 — Time-base ratio: a custom numeric ratio rescales consistently across every keyframe in the file**
- Given: the same file, user enters a custom ratio (e.g. "2 scroll-px per frame")
- When: committed
- Then: every keyframe's frame number is multiplied by the same ratio — no per-layer or per-property
  inconsistency; this is the case most likely to reveal an implementation bug (a ratio applied to
  some keyframes but not others, e.g. missing one property type)

**B3 — Easing precision: "exact cubic fit" vs. "Easy Ease approximation" produce different, both-valid output for the same input**
- Given: a Lottie keyframe pair using AE's standard Easy Ease handles (`i:{0.833,0.833},
  o:{0.167,0.167}`, the real-content-observed default)
- When: importing with "exact cubic fit" chosen vs. importing the same file with "Easy Ease
  approximation" chosen
- Then: both produce valid `.comics` `Anim` data (the format only has one fixed cubic ease-out, so
  in practice both choices may converge to the same result for *this specific* easing input — the
  meaningful difference shows up in Category G, the export direction, where the tool has real
  freedom to choose bezier handles); this case exists to confirm the dialog's choice is genuinely
  wired through, not a no-op UI element

## Category C — Import: TextRegion (interaction with the new schema field)

**C1 — Real sampled Lottie content has no text layers and no masks — TextRegion is not populated from Lottie import today**
- Given: `samples/sample.lottie` (real content, confirmed zero `ty:5` text layers, zero masks —
  `tdd-dot-lottie-format`'s own finding)
- When: imported
- Then: no `EditorLayer` gets a `TextRegion` from this import — this is expected, not a gap; Lottie
  import populating `TextRegion` would require either a Lottie mask (vector path) on a layer, which
  real content doesn't use, or some other signal this flow doesn't yet define
- Design implication: `TextRegion` import support may simply not be exercised by any real file
  today — worth stating explicitly so a future test author doesn't assume it's been validated
  against real data when it hasn't

**C2 — A hypothetical `.lottie` layer with a vector mask maps to `TextRegion.shape == "polygon"` on import**
- Given: a hand-crafted `.lottie` file with an image layer carrying a `masksProperties` vector path
- When: imported
- Then: the mask's bezier path becomes a `TextRegion` with `shape: "polygon"` (Lottie masks are
  always vector, never raster — per `tdd-dot-lottie-format`'s own finding — so `shape: "mask"`
  should never be the result of a Lottie import, only ever of the `comics-ai-baloons` pipeline's
  own raster-mask path)
- Design implication: `TextRegion.shape == "mask"` and `shape == "polygon"` may have genuinely
  different *sources* in practice (comics-ai-baloons vs. Lottie import respectively) even though
  they're the same field — worth documenting, not just implementing generically

## Category D — Export: happy path and TextRegion/GroupId round-trip

**D1 — A plain `.comics` layer with translate/alpha `Anim`s exports to a Lottie image layer with equivalent keyframes**
- Given: an `EditorLayer` with a `TranslateAnim` (start=0,end=200) and an `AlphaAnim` (start=0,
  end=100)
- When: exported to `.lottie` (any chosen easing precision)
- Then: the output is valid Lottie JSON with one `ty:2` layer, a `p` (position) keyframe pair and an
  `o` (opacity) keyframe pair, frame numbers derived from the chosen time-base ratio (Category B)

**D2 — Layers sharing a `GroupId` export as one precomp, inverse of import's Category A3**
- Given: 3 `EditorLayer`s sharing the same `GroupId`
- When: exported
- Then: the output nests those 3 image layers inside one precomp asset, referenced by one root
  layer — round-tripping A3's structure, not flattening it back out into 3 unrelated top-level
  layers

**D3 — A layer with a `TextRegion` exports its geometry as a real Lottie mask when `shape` is polygon-compatible**
- Given: an `EditorLayer` with `TextRegion.shape == "polygon"`
- When: exported
- Then: the polygon becomes a real Lottie `masksProperties` vector path on that layer's export —
  this is the "genuine added benefit" `01-requirements.md` already identified (polygon regions map
  directly onto Lottie's native mask model)
- Edge case: `TextRegion.shape == "mask"` (raster) has no direct Lottie equiv4alent — needs a
  decision (not made yet): skip the mask on export with a disclosed limitation, or rasterize-then-
  vectorize as a lossy approximation. **Not yet answered — flagging, not guessing.**

## Category E — Round-trip (behavioral equivalence, per Requirements' decision)

**E1 — Import → export → re-import produces the same rendered result at sampled scroll positions, not necessarily the same bytes**
- Given: a real `.lottie` file, imported then immediately exported then re-imported
- When: comparing the two imported documents' rendered layer transforms at several sample
  scroll/time positions
- Then: transforms match within a small numeric tolerance (accounting for the easing-approximation
  step, per Requirements) — the two `.lottie` files themselves are **not** expected to be
  byte-identical (different easing handle encodings are an accepted, disclosed lossy step, not a
  bug)

## Category F — Error handling

**F1 — A `.lottie` file that isn't valid JSON, or is valid JSON missing required top-level keys, is rejected with a clear message before the review screen even renders**
- Given: a corrupt or non-Lottie JSON file
- When: picked via "Import from .lottie"
- Then: a clear error, no partial review screen, no crash — matches `tdd-dot-lottie-format`'s own
  Test Case L1 (a generic Lottie-schema-key check is sufficient, no custom parser needed for this
  check specifically)

**F2 — A `.lottie` file referencing an asset file that doesn't exist (broken `assets[].p` path) is flagged per-layer, not a fatal whole-file error**
- Given: a `.lottie` file (unzipped alongside its assets) where one image asset's file is missing
- When: imported
- Then: that specific layer is flagged in the review screen (Category A2's mechanism extends to
  this case too — "unsupported"/"broken" are both review-screen flag states, not different code
  paths), other layers still import cleanly

## Completeness Check

- [x] All requirements have behaviors — every Acceptance Criterion and every resolved Open Question
      in `01-requirements.md` has at least one case above.
- [x] Edge cases identified — all-unsupported-content (A2), cancel-leaves-no-trace (A4), the
      mask-vs-polygon source distinction (C2), TextRegion-mask-has-no-Lottie-equivalent (D3).
- [x] Error scenarios defined — F1/F2, plus A2's per-layer (not whole-file) flagging.
- [x] Design implications extracted — most cases include one; the review screen's data-model
      requirement (grouping must survive parse→review→commit) is the most structurally significant.

## Open Design Questions

- [ ] D3's edge case: what happens when exporting a raster (`shape: "mask"`) `TextRegion` to
      Lottie, which has no raster mask concept at all? Skip with a disclosed limitation, or
      rasterize/vectorize as a lossy approximation? Not decided.
- [ ] The 2 deferred Requirements-level Text Region questions (`isHandLettered`/`Style` relationship,
      coordinate space) still gate exactly how Categories C/D's cases get implemented, even though
      they don't block writing the cases themselves.
- [ ] Whether A1's "review screen" and B1-B3's "choice dialogs" are one combined screen or separate
      sequential steps — a UI-layout decision for Specifications, not resolved here.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-07
- [x] Notes: Approved as drafted, including the 3 Open Design Questions carried forward
      unresolved into Specifications.
