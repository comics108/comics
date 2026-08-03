# Requirements: dot-comics-format (TDD)

> Version: 0.2 (promoted from a parked SDD reference consolidation to an active TDD flow, per
> Anton's explicit request 2026-08-02 — this file's history below predates that promotion)
> Status: DRAFT
> Last Updated: 2026-08-02

## Promotion note (2026-08-02, read this first)

This flow started as `flows/sdd-comics-editor-fromat-dot-comics` — a parked, non-build reference
consolidation (see "Origin" below for that history, preserved as-is). Anton copied it into
`flows/tdd-dot-comics-format/` and asked for it to become a real TDD flow: catalog every existing
test touching the `.comics` format, then define the test cases needed for compatibility across
**legacy v2012 players** (`legacy/mahabharata-mobile-java-v2012`, `legacy/mahabharata-mobile-swift-
v2012`), **the v2.8 desktop editor**, and **modern v2026 viewers**
(`libs/comics_viewer/{comics-viewer-android,comics-viewer-ios,flutter_comics_viewer,
react-native-comics-viewer}`) — plus new-in-2026 format concerns: format/orientation selection
defaults (vertical vs. the historically-original horizontal "comic strip"), device screen
orientation (portrait default, landscape as a 2026 addition), and the animation-type/kind-
classification version history. See `02-tests.md` for the actual cases-first deliverable — this
file's Problem Statement/scope below has been updated to match the new mandate, but the older
consolidated facts (Origin through Position Representation) remain accurate and are kept as
background.

## Origin (predates the TDD promotion — preserved for history)

Extracted from `flows/vdd-comics-editor-timeline/` and `flows/sdd-comics-ai-positioning/` on
2026-08-01, per explicit user request: both flows independently investigated real `.comics`/
`data.json` internals (from different angles — timeline/animation-driving in one, AI
recomposition/positioning in the other) and each surfaced real, code-grounded facts about the
format itself, not just their own feature. Consolidating those facts into one place, rather than
leaving format knowledge scattered and re-discoverable-at-cost across flows, per the user's
explicit request. **This is not a feature to build** — it's a reference document, the same role
`flows/sdd-comics-editor-questions/` plays for open questions.

## Problem Statement

`.comics` format knowledge has been independently rediscovered, piecemeal, by at least two flows
so far (this consolidation's two sources), each paying the investigation cost fresh because no
single authoritative description existed to check first. Left unconsolidated, a third flow would
likely re-derive the same facts a third time, or worse, act on a stale/partial understanding one
of the two sources already corrected. This flow exists to be that single reference.

## The `.comics` Format — Consolidated Description

### Default shape: a vertical comic strip, not a paginated document

**This is the fact the user explicitly asked to be stated plainly, and it's directly confirmed,
not inferred**, in `vdd-comics-editor-timeline/03-specifications.md`:

> "the real viewer is a press-and-hold, finger-attached vertical drag — the content moves 1:1 with
> the touch point, up or down, revealing new objects below or previously-drawn ones above. There is
> no separate scroll physics/abstraction layer between the gesture and content position, and —
> critically — **no built-in concept of scene or screen boundaries at all**: it's one continuous
> strip, not a sequence of pages."
> — confirmed by Anton, 2026-08-01, `vdd-comics-editor-timeline/03-specifications.md`

`sdd-comics-ai-positioning/02-specifications.md` independently confirms the same structural default
from the geometry side: "canvas `width` is bounded/page-scale, `height` is the ~33000px scroll axis"
and "pages/panels don't stack horizontally in this format, confirmed by all 27 files' geometry."
Real document heights range far beyond that one example — `vdd-comics-editor-timeline`'s own
sampled-files check found **16,300–100,900px** across several real documents, all far taller than
wide. Nothing in the data model *forbids* a wide/short or horizontal-scroll document (no axis flag
exists — see `sdd-comics-editor-questions`'s Group C investigation, not re-derived here since it's
outside this consolidation's two named sources), but every real file, both reference viewers
(v2.8 WPF, the live Android `comics-viewer-android` library), and the confirmed end-user interaction
model are all vertical-only. **Vertical continuous strip is the default and the only thing actually
built/exercised anywhere — not a hard schema constraint, but the format's real, load-bearing
convention.**

### Layer & animation model

- A `.comics` document's editable unit is the **`Layer`** — every kind of content (background,
  character, balloon, sound-adjacent visual) is the same generic `Layer` type; there is no
  layer-grouping/parent-child concept anywhere (`sdd-comics-ai-positioning/01-requirements.md`,
  verified against `apps/comics-editor/native/Comics.Editor/Models/Layer.cs`, zero `Group` matches
  repo-wide). Every layer's position is an independent `TranslateAnim.X`/`Y` int pair.
- Animation keyframes (`Anim` and its subtypes — `translate`/`rotate`/`scale`/`alpha`/`sound`, per
  `vdd-comics-editor-timeline/01-requirements.md`'s `AnimType` enum) are **driven by scroll/pan
  position, not wall-clock time** — a pure function of "how far down the strip has the reader
  scrolled," confirmed identically across three independent implementations: the original v2.8 WPF
  editor (`TranslateAnim.Interpolate(Anim, double scroll)`), the real shipping Android viewer
  library `comics-viewer-android` (`Layer.java`/`LayerAnim.java`, a same-shape Java port with an
  added easing curve), and — per `sdd-comics-ai-positioning`'s own framing — the AI recomposition
  work's target space being "one continuous Y-axis" for exactly this reason.
- **Sound is on the same single scroll value, not a separate mechanism**: `SoundAnim`'s
  `Start`/`End` is a scroll-range gate (`Sound.Create()` seeds `{Start=scroll, End=scroll}`), and
  both the legacy WPF app and the real Android viewer drive visual matrices *and* sound triggering
  off the identical scroll number in the same tick (`vdd-comics-editor-timeline/01-requirements.md`).
- `Anim.start`/`end` values are **small numbers (roughly 48–6000 observed)**, not 1:1 with document
  pixel height (which ranges 12,000–100,900px in the same sampled files). **RESOLVED (2026-08-02,
  by `vdd-comics-editor-vertical-scroll`, not by empirical testing as originally planned)**: there
  is no unit mismatch and no scale factor. `Anim.Start`/`End` are in the exact same raw-pixel
  coordinate space as scroll position — a keyframe range only needs to span the short window
  (~200px) during which one specific transition plays; once passed, the value holds unchanged for
  the rest of the document, however tall. See that flow's `01-requirements.md`, Major Finding
  point 9, and `03-specifications.md`'s corrected Investigation Note.
- Only a minority of real layers use rotation: **1146 of 4594** real layers have a `RotateAnim` at
  all (`sdd-comics-ai-positioning/01-requirements.md`, via `render_canvas.py`'s documented finding).

### Position representation (recomposition/AI-pipeline framing)

Per `sdd-comics-ai-positioning/02-specifications.md`: absolute canvas X/Y (matching
`TranslateAnim.X`/`Y`'s own representation, plain ints) is the ground-truth position shape. For
work that predicts/proposes positions rather than reading existing ones, two derived views are used
internally: **relative-to-page-anchor Y** (canvas Y minus a page's own estimated anchor, since
absolute Y depends on all of an episode's prior content) and **X predicted directly** (no anchor
issue, since panels never stack horizontally in this format). No geometric/pixel-level mapping from
a real source photo into canvas space exists or is obtainable (`comics-multimodal`'s `package.py`
design note, cited in `sdd-comics-ai-positioning/01-requirements.md`) — positioning within this
format has to be a learned/heuristic placement problem, not a coordinate transform.

## Acceptance Criteria

### Must Have

1. **Given** a future flow that needs to know a `.comics` fact already investigated by
   `vdd-comics-editor-timeline` or `sdd-comics-ai-positioning`, **when** it checks this document
   first, **then** it finds that fact here, cited back to its original source, instead of
   re-deriving it from code.
2. **Given** any fact stated in this document, **when** it's checked against the original source
   flow's own text, **then** it matches (verbatim quote or faithful paraphrase) — this document does
   not introduce new claims beyond what its two named sources already established.

### Should Have (added with the TDD promotion, 2026-08-02)

- A catalog of every existing automated test anywhere in the repo that touches the `.comics`
  format, so `02-tests.md`'s cases-first analysis builds on real existing coverage instead of
  re-deriving it blind.
- Cases-first behavioral analysis (per TDD discipline) covering: legacy v2012 compatibility,
  format/orientation defaults, device screen orientation, animation-type/kind-classification
  version history, and v2026 multi-platform viewer parity.

### Won't Have (This Iteration)

- No new code, no schema changes — `02-tests.md` defines cases; fixing any bugs the cases-first
  analysis surfaces is explicitly a separate, later decision (see `02-tests.md`'s Bugs section),
  not silently done as part of this Tests-phase pass.

## Constraints

- This document must stay a faithful extraction. If either source flow's own understanding is later
  corrected (as `vdd-comics-editor-timeline` itself already did once, mid-flow, about the mobile
  viewer's keyframe support), this document needs a matching correction, not a silent drift.

## Open Questions

- [x] Should this consolidation be extended to pull in additional real format facts from other
      flows? **Done (2026-08-02)** — a full sweep of every remaining SDD/VDD flow
      (`sdd-comics-ai-multimodal`, `sdd-comics-ai-baloons`, `sdd-comics-editor-questions`,
      `sdd-comics-editor-build`/`-publish`/`-v2.9`/`-v2.9-android-ios`/`-v2.9-fixes1`/`-fixes2`,
      `vdd-comics-editor-jhanava`, `vdd-comics-editor-uiux-lettering`, `vdd-comics-editor-ai-uiux`,
      `vdd-comics-editor-systematization-uiux`, `sdd-comics-ai-script-context`,
      `sdd-comics-ai-transformations`) is in `02-tests.md`'s References/background section, each
      with what it does and doesn't contribute to format facts.
- [x] The exact `Anim.start`/`end` ↔ document-pixel-height unit relationship — **resolved**, see the
      correction above in Layer & animation model.

## References

- `flows/vdd-comics-editor-timeline/01-requirements.md`, `03-specifications.md` — source of the
  vertical-strip-confirmed-by-Anton quote, the `Anim`/scroll-as-time model, the sound-on-same-value
  finding, the `AnimType` enum, and the unresolved `Anim.start`/`end` unit-relationship risk
- `flows/sdd-comics-ai-positioning/01-requirements.md`, `02-specifications.md` — source of the
  layer/no-grouping model, the `TranslateAnim.X`/`Y` position representation, the
  canvas-width-bounded/height-is-scroll-axis geometry fact, the RotateAnim usage statistic, and the
  no-pixel-level-source-mapping finding

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: Not seeking approval — reference consolidation, same status as
      `sdd-comics-editor-questions`.
