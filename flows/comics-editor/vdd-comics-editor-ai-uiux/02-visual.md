# Visual Mockups: comics-editor-ai-uiux

> Version: 1.1
> Status: APPROVED
> Last Updated: 2026-08-01

## High-fidelity companion reference

`design/comics-editor-v3.1.0-maket/Comics Editor Cutting Devices.dc.html` (+
`design/comics-editor-v3.1.0-cutting.pdf`), HolySpots DS v3.1 tokens, added 2026-08-01, is a
pixel-level rendering of this same structure — macOS results screen, iPad landscape disabled state,
iPhone disabled state. It confirms the ASCII structure below with no structural disagreements, and
adds concrete details this doc now treats as authoritative:

- **Exact new chip colors** (both sit outside the existing sky-blue/coral/violet/amber vocabulary,
  same rule the lettering flow used when it added violet/amber): **slate `#5a7d99`** for Background,
  **teal `#2f8f7a`** for Character. Balloon keeps the shipped violet `#7b5cd6`; Art keeps the shipped
  neutral gray — no new colors needed for those two.
- **Exact confidence badge tokens**: high (≥85%) = bg `#e3f2e6` / text `#1f7a33` (green); medium
  (50–84%) = bg `#f7ecd4` / text `#8a6207` (amber); low (<50%) = bg `#fde4dc` / text `#c04a26`
  (coral). Percentage text is always rendered inside the badge, never color-only.
- **Top-bar status summary**: the results screen's header shows a running tally — `"12 regions · 9
  pending · 2 accepted · 1 rejected"` — not in the original draft below, adopted as a Must Have
  detail since it's cheap and gives the corrector orientation without scanning the whole rail.
- **Accept/reject are icon indicators on the rail row**, not text tags: a small filled blue
  circle+checkmark for accepted, a filled gray circle+X for rejected (row also dims and the region
  number gets a strikethrough). Refines the plain `[OK]` / `[X]` placeholders below.
- **The routing/source indicator (`(o) Local process · source: page-014-photo`) is persistent**,
  bottom-right of the canvas, for the whole time a page is open in Cutting mode — not only during
  the Running state. The corrector should always be able to see which source image and which
  process mode produced what's on screen.
- **Selected region gets a spotlight treatment**: an 4000px-spread dark box-shadow around the
  selected box dims the rest of the page, in addition to the 8 resize handles — makes the active
  region unambiguous even with 12 overlapping boxes on screen.
- **Canvas shows all proposed regions simultaneously** (not just the selected one), each outlined in
  its kind's color at reduced opacity, with the selected region full-opacity + spotlighted. Confirms
  the approach below rather than changing it.
- **New clarified behavior — cross-device layer sync**: the iPad disabled-state popover reads
  *"Cutting requires the desktop app for now — the AI pipeline doesn't run on this device yet.
  Regions cut on your Mac appear here as normal layers."* This confirms an assumption worth making
  explicit: **Cutting mode produces ordinary `Layer`s in the `.comics` document** — any device that
  can open the document (including iPad/iPhone in Edit mode) sees the resulting layers normally, via
  the existing document-open path, with no live-sync feature needed. Only the *act of triggering a
  new cut* is desktop-only; reviewing/using already-cut layers is universal. The iPad Edit-mode mock
  shows exactly this: a layers list with `Bg`/`Chr`/`Bln`/`Art` chips already set on layers a Mac
  produced.
- **iPhone shows the explanation as an inline note under the switch**, not a popover (screen too
  narrow) — same message, different presentation, confirming Requirements Acceptance Criterion 5's
  "clearly communicates... exact UX ... see Open Questions" resolves to inline-note-on-tap for phone,
  popover-on-tap for tablet/desktop.
- A small zoom control (`− 72% +`) bottom-left of the canvas — minor, not previously specified;
  adopted as a Should Have, standard for any region-overlay canvas.

## Overview

Follows the same navigation pattern already shipped for lettering
(`flows/vdd-comics-editor-uiux-lettering/`): a **mode switch** in the top bar next to the document
name. Today that switch is `[Edit | Lettering]`; this flow adds a third mode: `[Edit | Lettering |
Cutting]`. Cutting mode reuses the same two/three-pane shape as Lettering mode (a filtered rail on
the left, a review surface on the right, canvas in the middle on desktop) so corrector muscle memory
transfers directly — same reason the lettering flow gave for its own layout.

This document resolves the six Open Questions left open in `01-requirements.md`, as concrete design
decisions (not re-asked a second time), following the precedent `vdd-comics-editor-uiux-lettering`
set of deciding in Visual/Specifications rather than blocking approval on them:

1. **Shared review card, not per-kind cards** — one `CuttingReviewCard`, parameterized by kind. The
   four kinds mostly differ in default aspect ratio and which actions make sense (e.g. "insert to
   library" only applies to character/background), not in overall shape.
2. **Library browser is a tab inside Cutting mode**, not a separate screen/panel — it's part of the
   same corrector workflow (pull an existing character instead of re-cutting one).
3. **Source image intake assumes a pre-cropped page image already exists** as an importable layer/
   asset in the document (e.g. the corrector has already dragged in the page photo). Rectification
   (page detection, perspective correction) is out of scope — noted as a visible limitation on the
   trigger screen itself, not hidden.
4. **Mobile**: the "Cutting" mode switch itself is disabled (grayed out, not hidden) with an inline
   note, rather than entering the mode and failing on trigger. Disabled-but-visible teaches the
   corrector the feature exists without a broken/faked interaction.
5. **Confidence display**: a color-coded percentage badge (never color alone — text always present),
   reusing the same "color + label together" accessibility rule the lettering flow already
   established for kind chips.
6. **Bounding-box adjustment** reuses the canvas's existing layer-selection resize handles — a
   pending region is presented on-canvas exactly like a draft layer selection, so there's no new
   interaction to learn.

---

## Screen: Cutting mode — trigger / empty state (Desktop)

Entered via the new `[Cutting]` mode switch. Before anything has been cut, this is what the
corrector sees.

```
+--------------------------------------------------------------------------------+
|  Comics Editor 3.0   page-014.comics   [Edit | Lettering | Cutting]            |
+------------------+---------------------------------------+---------------------+
| SOURCE            |                                       |  Cutting           |
|                    |                                       |                     |
| (o) page-014-photo |         (full page canvas,            |  No regions yet.    |
|     [Set as source]|          source image shown as-is,     |                     |
|                    |          no overlay yet)               |  [ Cut / Segment ]  |
| i  Rectification   |                                       |                     |
|    (perspective     |                                       |  Runs the           |
|    correction) is   |                                       |  multimodal cutting |
|    not done here —  |                                       |  pipeline on the    |
|    import an        |                                       |  source image and   |
|    already-cropped  |                                       |  proposes regions   |
|    page image.      |                                       |  for review.        |
+------------------+---------------------------------------+---------------------+
```

### Elements

| Symbol | Meaning |
|--------|---------|
| `(o)` | Selected source image/layer to run cutting against |
| `[Set as source]` | Pick a different layer/imported image as the cutting input |
| `i` | Inline informational note (limitation), not an error |
| `[ Cut / Segment ]` | Primary action — triggers the pipeline |

---

## Screen: Cutting mode — running

```
+------------------+---------------------------------------+---------------------+
| SOURCE            |                                       |  Cutting            |
| (o) page-014-photo|         (source image, dimmed          |                     |
|                    |          slightly during run)          |  Running...         |
|                    |                                       |  [=======>      ]   |
|                    |                                       |                     |
|                    |                                       |  (@) Local process  |
|                    |                                       |  Segmenting page... |
|                    |                                       |                     |
|                    |                                       |  [ Cancel ]         |
+------------------+---------------------------------------+---------------------+
```

Mirrors the lettering flow's Generating state: a visible routing indicator (`(@) Local process` on
desktop — there is no cloud path this iteration, see Requirements Won't Have) and progress, with a
Cancel escape hatch, not a blocking spinner with no way out.

### Progress stages shown (matches `pipeline.py`'s real stages)

```
Segmenting page...  ->  Matching regions...  ->  Finalizing...
```

---

## Screen: Cutting mode — results (Desktop, primary screen)

```
+--------------------------------------------------------------------------------+
|  Comics Editor 3.0   page-014.comics   [Edit | Lettering | Cutting]            |
+------------------+---------------------------------------+---------------------+
| REGIONS (12)      |                                       |  Region #04         |
|  Library          |    (full page canvas, all 12          |  [Character]  92%   |
|                    |     proposed regions shown as          |                     |
| [Bg]  #01   96%    |     outlined boxes over the source     | +-----------------+ |
| [Bg]  #02   88%    |     image; #04 selected/highlighted    | |                 | |
| [Chr] #03   91%    |     with resize handles)               | |  (region crop   | |
| [Chr] #04 * 92%    |                                       | |   preview)      | |
| [Bln] #05   99%    |                                       | |                 | |
| [Bln] #06   97%    |                                       | +-----------------+ |
| [Art] #07   64%    |                                       |                     |
| ...                |                                       |  Kind: [Character v]|
|                    |                                       |                     |
| [ Accept all >90% ]|                                       |  [Accept] [Reject]  |
+------------------+---------------------------------------+---------------------+
```

### Elements

| Symbol | Meaning | Exact token |
|--------|---------|-------------|
| `[Bg]` | Background kind chip | slate `#5a7d99` |
| `[Chr]` | Character kind chip | teal `#2f8f7a` |
| `[Bln]` | Balloon kind chip (shared with Lettering) | violet `#7b5cd6` |
| `[Art]` | Art/other kind chip (catch-all default) | neutral gray (`--gray-100`) |
| `92%` | Confidence badge — see color coding below | — |
| `*` | Currently selected region (spotlighted + resize handles on canvas) | — |
| `[ Accept all >90% ]` | Bulk-accept action, threshold adjustable (Should Have) | — |
| `[Kind: v]` | Reclassify dropdown — change a region's kind before accepting | — |

Slate and teal are new additions to the DS palette, same rule as violet/amber were when the
lettering flow added them: outside the sky-blue (selection) / coral (destructive) vocabulary.

### Confidence badge color coding (color + text always together)

```
92%  green  bg #e3f2e6 / text #1f7a33   (>= 85%  "high")
64%  amber  bg #f7ecd4 / text #8a6207   (50-84%  "medium")
31%  coral  bg #fde4dc / text #c04a26   (< 50%   "low")
```
Reuses the DS's existing coral = "needs attention" association from destructive/error actions —
here repurposed as "low confidence, look closely," not an error, but same visual weight for
scanning quickly. Text percentage is always shown; color is never the only signal.

### Header status summary

```
|  page-014.comics   [Edit | Lettering | Cutting]   12 regions · 9 pending · 2 accepted · 1 rejected |
```
Always visible while regions exist for the current page — gives orientation without scrolling the
rail.

### States

#### Region selected, adjusting boundary

```
|    (canvas: region #04's box shown full-opacity with 8      |
|     resize handles + a dark spotlight dimming the rest of    |
|     the page; other 11 regions still visible at reduced      |
|     opacity, each in their own kind color; identical drag/    |
|     resize interaction to selecting a layer already on the    |
|     page)                                                     |
```
No new drag/resize interaction — a pending region behaves exactly like selecting an existing layer.
All proposed regions stay visible (not just the selected one) so the corrector sees overlap/gaps at
a glance; the spotlight makes the active one unambiguous.

#### Region accepted

```
| [Chr] #04 * 92%  (v) |     <- filled blue circle+checkmark; region becomes a real layer
```

#### Region rejected

```
| [Art] #07   64%  (x) |     <- filled gray circle+X, row dims, number struck through; no layer
                                 created, removable from list
```

#### Persistent routing/source indicator (bottom-right of canvas, always visible in Cutting mode)

```
|                                          (o) Local process · source: page-014-photo |
```
Not just shown while running — stays visible the whole time a page is open in Cutting mode so the
corrector always knows which source image and which process mode produced what's on screen.

#### Stale (source image changed after regions were generated)

```
+--------------------------------------------------------------------------------+
|  ! Source image changed since these regions were generated.                     |
|    Re-run cutting to refresh, or continue reviewing stale results.              |
|    [ Re-run ]                                                        [ Dismiss ]|
+--------------------------------------------------------------------------------+
```
Same stale-output pattern as `BalloonEditorCard` — never silently invalidates or silently keeps
showing outdated results without telling the corrector.

#### Failure

```
|  ! Cutting failed.                                          |
|    Local pipeline process exited with an error.             |
|    [ Retry ]   [ View details ]                              |
```

---

## Screen: Cutting mode — Library tab

Second tab within Cutting mode (alongside "Regions"), for browsing the pipeline's already-clustered
character/environment output.

```
+--------------------------------------------------------------------------------+
|  Comics Editor 3.0   page-014.comics   [Edit | Lettering | Cutting]            |
+------------------+---------------------------------------+---------------------+
| [Regions] Library |                                       |                     |
|                    |         (full page canvas,             |  amba               |
| Search: [amba___] |          unaffected by library          |  character · 11     |
|                    |          browsing until an item is      |  crops              |
| CHARACTERS         |          inserted)                     |                     |
|  * amba (11)       |                                       | +-----------------+ |
|    bhishma (6)     |                                       | |  (thumbnail)     | |
|    parashurama (4) |                                       | +-----------------+ |
|                    |                                       |                     |
| ENVIRONMENTS       |                                       |  [ Insert as layer ]|
|  palace-hall (9)   |                                       |                     |
|  forest-path (5)   |                                       |                     |
+------------------+---------------------------------------+---------------------+
```

### Elements

| Symbol | Meaning |
|--------|---------|
| `amba (11)` | Cluster/seed name + crop count, from `work/library/characters/amba/` |
| `[ Insert as layer ]` | Adds the selected library item onto the current page as a new layer |

### States

#### Empty search result

```
| Search: [xyz_____]|
|                    |
|  No characters or  |
|  environments match|
|  "xyz".            |
```

#### Library not yet built (pipeline never run for this project)

```
| CHARACTERS         |
|  (none yet)         |
|                     |
|  i Library builds up|
|    as you run       |
|    Cutting on pages.|
```

---

## Screen: Cutting mode — Mobile (disabled state)

Mode switch itself is disabled, not entered-then-blocked.

```
+---------------------------+
| page-014.comics           |
| [Edit] [Lettering] [Cutting]|
|                     ^grayed |
+---------------------------+
| (tap on grayed Cutting)    |
|                             |
|  i Cutting requires the     |
|    desktop app for now —    |
|    the AI pipeline doesn't  |
|    run on this device yet.  |
|    Regions cut on your Mac  |
|    appear here as normal    |
|    layers.                  |
+---------------------------+
```

Tapping the disabled switch still shows an explanation (not just an inert grayed-out label with no
feedback) — same "don't fake it, don't stay silent" principle as Requirements Acceptance Criterion
5. The second sentence matters: it clarifies that only *triggering* a cut is desktop-only —
*viewing* layers a Mac already produced works normally on any device via the ordinary document-open
path, no special sync feature needed. On iPad this is a popover anchored to the switch; on iPhone
(narrower) it's an inline note under the switch instead.

---

## Flow: Cutting a page end-to-end

```
[Edit mode] --(tap "Cutting", top bar, desktop only)--> [Cutting: trigger/empty]
     ^                                                          |
     |                                              (pick source, tap Cut/Segment)
     |                                                          v
     |                                                 [Cutting: running]
     |                                                    /            \
     |                                              success          failure
     |                                                  |                |
     |                                                  v                v
     |                                        [Cutting: results]   [Error, Retry]
     |                                                  |
     |                                  (per region: accept / reject / reclassify / adjust)
     |                                                  |
     |                                                  v
     |                                    [Regions confirmed -> real Layers created]
     |                                                  |
     +--------------------(tap "Edit", top bar)---------+

Alternate path (no cutting needed):
[Cutting: any state] --(tap "Library" tab)--> [Cutting: Library] --(Insert as layer)--> [Layer added]
```

### Step-by-Step

1. **Enter Cutting mode**: desktop only; mobile shows the disabled state above.
2. **Pick a source image**: an already-imported, already-cropped page image/layer — no
   rectification step here (Requirements Won't Have).
3. **Trigger Cut/Segment**: real local subprocess invocation of `pipeline.py`'s segmentation stage;
   progress and routing indicator shown throughout; Cancel available.
4. **Review results**: per-region accept/reject/reclassify/adjust-boundary, using the shared
   `CuttingReviewCard` and on-canvas resize handles; bulk-accept by confidence threshold available.
5. **Confirm**: accepted regions become real `Layer`s in the document with correct `Kind`, wired
   through real image-content plumbing (Requirements Acceptance Criterion 3) — not placeholders.
6. **Or, skip cutting entirely**: switch to the Library tab and insert an already-known
   character/environment directly.
7. **Return to Edit mode**: newly created layers appear in the normal layers list like any other
   layer, with their kind chip already set.

---

## Component: CuttingReviewCard (shared, kind-parameterized)

The reusable core of the right-hand pane above — one component instance per selected region,
parameterized by `kind` (background / character / balloon / art), analogous to `BalloonEditorCard`.

```
+--------------------------------------------------+
|  Region #04                    [Character]  92%   |   <- kind chip + confidence badge
+--------------------------------------------------+
|  (region crop preview, on-canvas box shows        |
|   resize handles when this card is active)        |
+--------------------------------------------------+
|  Kind:  [ Character v ]                           |   <- reclassify dropdown, all 4 kinds
|                                                    |
|  [ Insert into library ]   (character/bg only)     |   <- kind-conditional action
|                                                    |
|  [ Accept ]              [ Reject ]                |
+--------------------------------------------------+
```

Kind-conditional differences (same card, different affordances shown):
- **Character / Background**: shows `[ Insert into library ]` — accepting also offers adding to the
  clustered library for reuse on future pages.
  Note: "Insert into library" is different from Library tab's "Insert as layer" — this direction adds
  a *newly accepted region* into the library; the Library tab's action pulls an *existing* library
  item onto the page. Two directions of the same shelf.
- **Balloon**: no library action; instead offers a shortcut `[ Open in Lettering ]` since an
  accepted balloon region immediately becomes editable in the existing lettering workflow.
- **Art**: no library action, no reclassify-restriction (Art is the catch-all/default kind already).

---

## Notes

- Reuses established DS vocabulary rather than inventing new ones: kind chips (same family as
  layers-list `[Bln]`/`[Cap]`/`[Bg]`/`[Chr]`/`[Art]` from the lettering flow), coral for
  "needs attention" (low confidence), the mode-switch top-bar pattern, and the
  routing-indicator/stale-indicator/never-silent-auto-apply rules from `BalloonAiClient`.
- No iPad/iPhone-specific *Cutting* layout is designed here — Requirements scopes triggering a cut
  to desktop only this iteration (mobile gets the disabled-switch screen only). **Reviewing/using
  already-cut layers is not mobile-scoped out** — per the high-fidelity reference's clarified
  behavior, layers produced by a desktop cut are ordinary document layers and appear normally in
  Edit mode on any platform, no special sync path needed.
- Bulk "Accept all >N%" is a Should Have (per Requirements) — shown here because it's cheap to
  design alongside the per-region flow, not because it's committed for this iteration.
- The Library tab intentionally lives *inside* Cutting mode rather than as a fully separate feature
  — it's part of the same "don't re-cut what's already known" corrector story.
- `design/comics-editor-v3.1.0-maket/Comics Editor Cutting Devices.dc.html` +
  `design/comics-editor-v3.1.0-cutting.pdf` (added 2026-08-01) is now the authoritative pixel-level
  reference for exact colors/spacing/iconography; this document stays the structural/state-coverage
  record and cross-references it rather than duplicating every visual detail, same convention the
  lettering flow used for its own high-fidelity companion.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-01
- [x] Notes: Approved as-is, including the high-fidelity companion mockup's refinements (exact chip
      colors, confidence tokens, persistent routing indicator, cross-device layer-sync
      clarification).
