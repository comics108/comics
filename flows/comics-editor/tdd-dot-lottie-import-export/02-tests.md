# Test Cases: dot-lottie-import-export

> Version: 1.1 (2026-08-08: NEW Category G added to already-approved v1.0 — Export/Import Modes,
> per `01-requirements.md` v0.3's addition. Disclosed addition, not a silent rewrite.)
> Status: APPROVED (v1.0 baseline; Category G approved 2026-08-08 via `03-specifications.md`'s
> approval, which derives from and confirms it)
> Last Updated: 2026-08-08
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

## Category G — Export/Import Modes: Full Canvas vs. Playback Viewport (NEW, 2026-08-08)

Anchored on two real fixtures, per Anton's direct instruction: `samples/sample_v2012.comics_unzip`
(real 1080×41500 `.comics`, ground truth for Full Canvas) and `samples/sample_playback_viewport
.lottie_unzip` (real 720×1600 Lottie with confirmed root-level scene-sweep precomps, ground truth
for Playback Viewport). See `01-requirements.md`'s new Export/Import Modes section for the byte-
level findings these cases build on.

**G1 — Full Canvas export produces a canvas-sized composition, identity time-basis, no scroll-speed dialog**
- Given: a `.comics` document shaped like `sample_v2012.comics_unzip` (a tall canvas, layers at
  fixed absolute Y positions)
- When: exported in Full Canvas mode
- Then: the output Lottie composition's `w`/`h` equal the `.comics` canvas size (not a viewport);
  every keyframe's frame number equals the source `Anim.start`/`end` directly (identity, no ratio
  applied); no scroll-speed prompt appears at all — Full Canvas mode has no such concept

**G2 — Full Canvas import assumes fixed, non-moving scene placement, no root-sweep structure expected**
- Given: a Lottie file with flat image/precomp layers at static (non-swept) positions — the shape
  `sample_v2012.comics_unzip` would have if it were Lottie instead of `.comics`
- When: imported in Full Canvas mode
- Then: each layer's frame numbers become `.comics` scroll-pixel `start`/`end` directly (identity);
  resulting `EditorLayer`s sit at fixed absolute positions on a (now-tall) canvas — no "scene sweeps
  past a viewport" interpretation is applied, even if the source happened to contain one (Full
  Canvas mode doesn't look for it)

**G3 — Full Canvas round-trip using the real v2012 sample as ground truth (CORRECTED 2026-08-08, Anton: "из .lottie в .comics затем в .lottie")**
- **Fixture prep** (one-time, not part of the round-trip itself): `samples/sample_v2012.comics_unzip`
  (real, trusted `.comics` content) is exported to `.lottie` (Full Canvas mode) once, to produce a
  real Full-Canvas-shaped `.lottie` file — no such file exists in `samples/` directly, since this
  fixture is a `.comics` sample, not a `.lottie` one. That derived file becomes the actual
  round-trip anchor from here on.
- Given: the derived Full-Canvas-shaped `.lottie` file from fixture prep
- When: imported into `.comics` (Full Canvas mode), then re-exported to `.lottie` (Full Canvas mode)
- Then: rendered layer transforms at sampled scroll positions match the original within tolerance —
  **the round-trip direction is `.lottie → .comics → .lottie`, matching G6's own direction exactly**
  (both modes' round-trips start and end in Lottie, for consistency — this corrects an earlier draft
  of this case that had Full Canvas round-tripping the opposite way, `.comics → .lottie → .comics`,
  which Anton explicitly flagged as wrong)

**G4 — Playback Viewport export produces a viewport-sized composition with a root-level scene sweep, requires a real scroll-speed value**
- Given: a `.comics` document open for export, `scrollType == vertical` (today's only real value)
- When: the user picks Playback Viewport mode and supplies (or accepts a default) constant
  scroll-speed value
- Then: the output composition's `w`/`h` equal the *viewport* size (not the full canvas); the canvas
  is partitioned into scenes as sequential `ComicsDoc.preferredViewportHeight`-tall bands (DECIDED
  2026-08-08 — `.comics` has no scene concept of its own, confirmed by direct inspection); each band
  becomes its own precomp with exactly one root-level position keyframe pair sweeping that scene
  past the fixed viewport, timed per the supplied speed — matching `ASHES.json`'s real "All
  Objects1"/"All Objects2" structure exactly

**G5 — Playback Viewport import: scroll/time classification defaults to all-scroll-basis (Requirements' heuristic (a), the safe first-ship default)**
- Given: `samples/sample_playback_viewport.lottie_unzip` (real content — confirmed real per-layer
  local `p`-keyframe wiggles distinct from the root sweep, per Requirements' byte-level findings)
- When: imported in Playback Viewport mode
- Then: every child layer's own local keyframes import as ordinary scroll-basis `Anim`s (today's
  exact existing behavior) — this import path does **not** yet produce any real `Anim.basis ==
  time` anims, even though `apps/comics-editor` already supports them (`tdd-dot-comics-format`'s
  Plan Phase 5, shipped). This case exists specifically to pin down heuristic (a)'s actual behavior
  so a future heuristic (b)/(c) change has a clear "before" to diff against, not an assumed one.

**G6 — Playback Viewport round-trip using the real ASHES-based sample as ground truth**
- Given: `samples/sample_playback_viewport.lottie_unzip`
- When: imported (Playback Viewport mode; scroll speed auto-derived from the file's own root sweeps
  — DECIDED 2026-08-08, computed to 149.49/150.00 px/sec for its two real scenes, 0.34% apart) then
  exported back (Playback Viewport mode, same speed)
- Then: rendered layer transforms at sampled scroll positions match the original within tolerance —
  the second of the two real, concrete round-trip fixtures Anton named directly

**G7 — Wrong-mode import produces a visibly wrong, not silently-broken, result**
- Given: `samples/sample_playback_viewport.lottie_unzip` (a real viewport-shaped file)
- When: imported in Full Canvas mode (the wrong mode for this file's real shape)
- Then: no crash — but the 2 root-level precomp layers ("All Objects1"/"All Objects2") become 2
  giant top-level `EditorLayer`-groups whose own position keyframes (the ~24000px sweep) are now
  uninterpreted absolute motion across the *whole* document, not a per-scene viewport sweep,
  producing a document that scrolls in a way that clearly doesn't match the original intent
- Design implication / Open Design Question: should the review screen actively detect this
  mismatch (the auto-detect option from `01-requirements.md`'s new Open Questions) and warn before
  commit, or is choosing the right mode entirely on the user, with wrong-mode import treated as
  ordinary "garbage in, garbage out"? Not decided.

## Completeness Check

- [x] All requirements have behaviors — every Acceptance Criterion and every resolved Open Question
      in `01-requirements.md` has at least one case above, including the new v0.3 Export/Import
      Modes addition (Category G, 2026-08-08).
- [x] Edge cases identified — all-unsupported-content (A2), cancel-leaves-no-trace (A4), the
      mask-vs-polygon source distinction (C2), TextRegion-mask-has-no-Lottie-equivalent (D3),
      wrong-mode import (G7).
- [x] Error scenarios defined — F1/F2, plus A2's per-layer (not whole-file) flagging.
- [x] Design implications extracted — most cases include one; the review screen's data-model
      requirement (grouping must survive parse→review→commit) is the most structurally significant;
      Category G's scroll/time classification heuristic (G5) is the most significant new one.

## Open Design Questions

- [ ] D3's edge case: what happens when exporting a raster (`shape: "mask"`) `TextRegion` to
      Lottie, which has no raster mask concept at all? Skip with a disclosed limitation, or
      rasterize/vectorize as a lossy approximation? Not decided.
- [ ] The 2 deferred Requirements-level Text Region questions (`isHandLettered`/`Style` relationship,
      coordinate space) still gate exactly how Categories C/D's cases get implemented, even though
      they don't block writing the cases themselves.
- [ ] Whether A1's "review screen" and B1-B3's "choice dialogs" are one combined screen or separate
      sequential steps — a UI-layout decision for Specifications, not resolved here.
- [x] **(new, 2026-08-08) DECIDED**: G1-G7's "scene boundary" convention for Playback Viewport
      export is sequential `ComicsDoc.preferredViewportHeight`-tall bands (the new
      `tdd-dot-comics-format` field) — `.comics` has no scene concept of its own (confirmed by
      direct inspection of `sample_v2012.comics_unzip/data.json`'s real keys). Affects G4 directly.
- [ ] **(new, 2026-08-08)** G5's scroll/time classification heuristic — still just "(a), the safe
      default," per Requirements. (b)/(c) remain real, undesigned improvements.
- [x] **(new, 2026-08-08) DECIDED**: G7's wrong-mode-import question — auto-detect-with-override,
      not silent trust. Detection: viewport-shaped `w`/`h` + the confirmed real root-sweep
      keyframe shape suggests Playback Viewport; canvas-shaped with no sweep suggests Full Canvas;
      either way the review screen shows the detection and lets the user override it.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-07 (v1.0 baseline, Categories A-F)
- [x] Notes: v1.0 approved as drafted, including the 3 original Open Design Questions carried
      forward unresolved into Specifications.
- [x] **v1.1 addition (2026-08-08, Category G) — approved 2026-08-08.** G6/G4's scene-boundary and
      scroll-speed questions resolved same-day with real evidence (see `03-specifications.md`'s
      Open Design Questions). G5's scroll/time classification heuristic remains genuinely open,
      carried forward to Plan.
