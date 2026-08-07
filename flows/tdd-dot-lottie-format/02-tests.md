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

**L6 (new, 2026-08-07) — A real Lottie content file's layers are all image type (`ty:2`), with no shapes/masks/text, for every produced chapter — not just the one already checked**
- Given: each of the 7 real produced chapters' `<codename>.json`
- When: every layer (including inside nested composition assets) is checked for `ty`
- Then: `ASHES.json` confirmed 100% `ty:2` (101/101 layers, 0 masks) — **not yet confirmed for the
  other 6 chapters**. This is the load-bearing assumption behind Requirements' "conversion is
  simple" conclusion — if even one other chapter uses shape layers/masks/text, that conclusion
  narrows to "true for at least one file," not "true for this content pipeline in general"
- Design implication: this is the single highest-value next check for this flow — a generic script
  (count layer `ty` values across all `assets[].layers` and root `layers`) answers it directly, no
  player needed

**L7 (new, 2026-08-07) — Position/scale keyframes across a real file consistently use the same bezier easing handles (Easy Ease), not arbitrary per-keyframe curves**
- Given: every keyframe in `ASHES.json`'s `p`/`s`/`r`/`o` properties across all layers
- When: each keyframe's `i`/`o` bezier handle values are collected
- Then: confirmed for the keyframes sampled (`i:{x:0.833,y:0.833}, o:{x:0.167,y:0.167}` — After
  Effects' "Easy Ease" default) — **not yet confirmed exhaustively for every keyframe in the file,
  nor for the other 6 chapters**. A file using a mix of Easy Ease and custom/linear/hold curves
  would need per-keyframe curve-matching logic for `.lottie → .comics` conversion, not one fixed
  approximation — a real complexity increase Requirements' current answer doesn't yet account for
- Design implication: same script as L6 can also tally distinct `(i,o)` handle pairs seen; a single
  dominant pair across the whole file supports the "simple" conclusion, a wide spread would not

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
- [ ] L6/L7 — do the other 6 real produced chapters stay within the same simple (image-layer-only,
      uniform-Easy-Ease) subset as `ASHES.json`? Directly gates whether the conversion-feasibility
      conclusion in `01-requirements.md` generalizes or was only ever true for one sampled file.

---

## Approval

- [ ] Reviewed by:
- [ ] Approved on:
- [ ] Notes:
