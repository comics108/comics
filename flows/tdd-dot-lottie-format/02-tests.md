# Test Cases: dot-lottie-format

> Version: 0.1 (seed draft — cases-first analysis is limited by design until Requirements' Open
> Questions are answered; see below)
> Status: DRAFT
> Last Updated: 2026-08-07
> Requirements: [01-requirements.md](01-requirements.md)

## Overview

Cases-first analysis for the Lottie content pipeline is genuinely constrained right now: there is
no confirmed reader anywhere in this repo (`01-requirements.md`, Verified Fact 5), so rendering-
behavior cases ("given this keyframe, when played, then this transform") can't be written against
real code the way `tdd-dot-comics-format` could against the classic lineage. What *can* be defined
now is schema-validity and content-inventory cases — real, checkable today, without a player.

## Cases

**L1 — A real Lottie content file parses as valid Lottie JSON**
- Given: `samples/sample.lottie_unzip/ASHES_content/ASHES.json`, or any of the 7 real produced
  chapters under `dataset/mahabharata/boranko/mahabharata-dot-lottie/unzip/`
- When: parsed as JSON and checked for the standard Lottie top-level keys (`v`, `fr`, `ip`, `op`,
  `w`, `h`, `layers`, `assets`)
- Then: all present, `v` matches a real Lottie/bodymovin version string, `fr` is a plausible
  framerate (e.g. 24-60), `op > ip`
- Design implication: this is checkable with a generic JSON-schema validator today, no custom
  parser needed — Lottie is a public, documented format

**L2 — Every produced chapter has all three companion folders (content/music/translations), not just some**
- Given: each of the 7 real produced chapters (Requirements Verified Fact 6)
- When: checked for `<codename>_content/<codename>.json`, `<codename>_music/`,
  `<codename>_translations/<codename>_{bn,en,hi,ru,uk}.json`
- Then: all three present, all 5 language files present under translations — a real completeness
  check on delivered content, independent of whether a player exists yet
- Edge case: confirm the codename is consistent across all three folder names for a given chapter
  (e.g. all `ASHES_*`, never a mismatch like `ASHES_content` + `RAMASCHALLENGE_music`)

**L3 — Translation JSON files are structurally parallel across all 5 languages for the same chapter**
- Given: `ASHES_translations/ASHES_{bn,en,hi,ru,uk}.json`
- When: compared structurally (not textually — content differs, structure shouldn't)
- Then: same key set/shape across all 5 — a missing key in one language's file, if it exists in
  the others, means a real content gap the source pipeline should have caught before delivery

**L4 — Precomp layers' nested `ip`/`op` stay within the root composition's own `ip`/`op` bounds**
- Given: `ASHES.json`'s root (`ip:0, op:11640`) and its first layer (a precomp, `ip:3891,
  op:13491`)
- When: checked
- Then: **currently this does NOT hold** — the precomp's own `op:13491` exceeds the root's
  `op:11640`. Not yet confirmed whether this is (a) normal/expected Lottie semantics (a precomp's
  `ip`/`op` describe its own internal trim, independent of whether the root ever actually reaches
  that point — plausible, needs confirming against the Lottie spec, not assumed), or (b) a real
  authoring inconsistency in this specific sample. **Flagged as an open finding, not a confirmed
  bug** — needs someone with real Lottie/After-Effects authoring knowledge to confirm which.

**L5 — No implementation in this repo currently crashes or misbehaves when handed a `.lottie` file (vacuous today, but worth stating)**
- Given: any current `.comics`-aware code path (`models_mapping.dart`'s `comicsFromCore`, the C#
  editor, `comics-viewer-android`)
- When: handed a `.lottie` file instead of a `.comics` file
- Then: **not yet tested** — since nothing currently accepts arbitrary file selection into these
  paths without a `.comics`/`.puzzle` extension check (`comicsFromCore`'s `name.endsWith('.puzzle')`
  branch, `models.dart`), this is likely a non-issue by construction, but worth a real test once a
  Lottie file-open path exists anywhere, so a future integration doesn't accidentally feed Lottie
  JSON into the classic parser and get a confusing silent-wrong-result instead of a clear rejection

**L6 (2026-08-07) — RESOLVED, NEGATIVELY (2026-08-07): a real Lottie content file's layers are all image type (`ty:2`), with no shapes/masks/text, for every produced chapter — not just the one already checked**
- Given: each of the 7 real produced chapters' `<codename>.json`
- When: every layer (including inside nested composition assets) is checked for `ty`, plus masks,
  null layers (`ty:3`), solid layers (`ty:1`), and the `parent` field (not originally part of this
  case, but found while running it — see below)
- Then: **`ASHES.json` alone confirmed 100% `ty:2`, but this does NOT generalize.** Checked all 7
  real chapters directly: `THE CHASE` has 6 masked layers (`masksProperties`); `SVAYAMWARA` has 1
  null layer (`ty:3`); `THE BROKEN TUSK` has 1 solid layer (`ty:1`) **and** 190 of its 295 layers
  (64%) use the `parent` field (one layer's transform relative to another's — a feature this case
  didn't originally think to check, but turned out to be the most consequential finding). 5 of 7
  files use `parent` at all (counts: 2, 0, 2, 20, 16, 20, 190). **Requirements' "conversion is
  simple" conclusion was true for `ASHES.json` alone and does not hold for this content pipeline in
  general** — most real chapters need real parent-chain resolution, not just a flat image-layer
  mapping, and one chapter needs mask handling this flow's original scope excluded. See
  `flows/tdd-dot-comics-format/01-requirements.md`'s animation-inventory section for the full table
  and the consequence for `tdd-dot-lottie-import-export`'s Precomp Handling design.
- Design implication (originally stated, now executed): the generic layer-`ty` census script was
  run for real, directly, against all 7 files — no player needed, confirmed.

**L7 (2026-08-07) — Position/scale keyframes across a real file consistently use the same bezier easing handles (Easy Ease), not arbitrary per-keyframe curves — CONFIRMED for the properties checked, not contradicted by the L6 re-investigation**
- Given: every sampled keyframe in `ASHES.json`'s `p`/`s`/`r`/`o` properties
- When: each keyframe's `i`/`o` bezier handle values are collected
- Then: confirmed for the keyframes sampled (`i:{x:0.833,y:0.833}, o:{x:0.167,y:0.167}` — After
  Effects' "Easy Ease" default). **Not re-verified exhaustively across all 7 files during the L6
  re-investigation** (that pass focused on layer/feature census, not per-keyframe easing-handle
  tallies) — still an open sub-question, narrower in scope now that L6 already establishes the
  bigger structural gap (parenting/masks) as the dominant complexity source, not easing curves.
- Design implication: same script as L6, extended to also tally `(i,o)` handle pairs — not yet run
  across all 7 files for this specific question.

## Completeness Check

- [x] All requirements have behaviors — Verified Facts 1-2 (L1), Fact 6 (L2), the translation
      expansion (L3) each have a case.
- [x] Edge cases identified — codename consistency (L2), the `ip`/`op` bounds question (L4).
- [ ] Error scenarios defined — **deliberately incomplete**: without a real reader, "what happens
      on malformed Lottie input" can't be answered against real code yet (L5 notes this explicitly
      rather than inventing an untested answer).
- [x] Design implications extracted — L1 notes a generic validator suffices; L5 notes the
      file-extension-gating that already protects against cross-format confusion today.

## Open Design Questions

Carried forward from `01-requirements.md` — repeated here since they directly gate what Tests can
even mean for this flow:

- [ ] Is this a committed direction or exploratory content? (blocks: whether to invest in L1-L4
      as real, maintained tests vs. leaving them as one-off verification notes)
- [ ] How does frame/time addressing reconcile with scroll-driven reading? (blocks: any future
      rendering-behavior test case at all)
- [ ] Is `mahabharata-mobile-swift-v2026`'s vendored engine meant to be the eventual reader? (Now
      known: the identical engine has been vendored, unused, since the 2012 Swift app too — see
      `01-requirements.md`'s correction.)
- [ ] L4's `ip`/`op` bounds question — needs a real Lottie-authoring-knowledgeable answer, not a
      guess.
- [x] **L6 — RESOLVED, NEGATIVELY (2026-08-07)**: no, the other 6 chapters do NOT stay within
      `ASHES.json`'s simple subset. Masks (1/7), null layers (1/7), solid layers (1/7), and —most
      consequentially— layer parenting (5/7, up to 64% of one file's layers) are all real,
      confirmed complications. The conversion-feasibility conclusion in `01-requirements.md` was
      only ever true for `ASHES.json` specifically; it does not generalize to this content pipeline
      as a whole. See `flows/tdd-dot-comics-format/01-requirements.md`'s animation-inventory
      section for the full table, and `flows/comics-editor/tdd-dot-lottie-import-export` for the
      consequence (Precomp Handling needs to generalize to arbitrary parent chains).
- [ ] **L7**: still open, narrower now — easing-handle consistency wasn't re-checked across all 7
      files during the L6 re-investigation (which focused on structural/layer-type census). Lower
      priority than L6's finding, since parenting/masks are the dominant complexity source now
      confirmed, not easing curves.

---

## Approval

- [ ] Reviewed by:
- [ ] Approved on:
- [ ] Notes:
