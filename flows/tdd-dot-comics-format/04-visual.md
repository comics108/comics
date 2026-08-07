# Visual: apps/comics-editor UI for the new `.comics` v2026 schema additions

> Version: 1.1
> Status: APPROVED
> Last Updated: 2026-08-07
> Requirements: [01-requirements.md](01-requirements.md)
> Specifications: [03-specifications.md](03-specifications.md)

## Overview

TDD's own template has no dedicated Visual phase — this document is added per Anton's explicit
request, ahead of Plan, so the editor-UI shape for each newly-decided schema addition is settled
before Plan breaks it into tasks. Covers: `scrollType`/device orientation (New Document dialog),
organizational layers, `Layer.ParentId`, `Layer.Mask`/`Layer.SolidColor`, and the `Anim.basis`
(scroll-vs-time) authoring control.

**A real, important correction found while grounding this document**: the New Document dialog's
UI for `scrollType` and device orientation is **already implemented in real code** —
`apps/comics-editor/lib/src/ui/widgets/dialogs.dart:39-114` — not merely a documented intention as
earlier status notes said. See Screen 1 below for exact citations. Everything else in this
document (organizational layers, `ParentId`, `Mask`/`SolidColor`, `Anim.basis`) is genuinely new —
no existing UI for any of them.

---

## Screen 1: New Document dialog — ALREADY BUILT, not a proposal

`dialogs.dart`'s `showNewDialog` (lines 15-120) already has both pieces this flow's `scrollType`/
device-orientation decision called for, matching the "visible but disabled, signals intent without
engine commitment" design exactly:

```
+----------------------------------------------------------------+
|  New document                                                    |
+----------------------------------------------------------------+
|  DOCUMENT TYPE                                                   |
|  +-------------------+  +-------------------+  +---------------+ |
|  | [x] Vertical-      |  | [ ] Horizontal-    |  | [ ] Puzzle    | |
|  |     scroll comic   |  |     scroll comic   |  |               | |
|  |     strip          |  |     strip          |  |               | |
|  |     Default ·      |  |     Planned for a  |  |     Zoomable  | |
|  |     infinite        |  |     future version |  |     board of  | |
|  |     vertical        |  |     (disabled)     |  |     pieces    | |
|  |     reading flow    |  |                    |  |               | |
|  +-------------------+  +-------------------+  +---------------+ |
|                                                                    |
|  DEVICE ORIENTATION                                               |
|  +----------------------+  +----------------------+               |
|  | [x] (icon) Portrait   |  | [ ] (icon) Landscape  |               |
|  |     (selected, only    |  |     (disabled)        |               |
|  |      option today)     |  |                       |               |
|  +----------------------+  +----------------------+               |
|                                                                    |
|                                          [Cancel]  [Create]        |
+----------------------------------------------------------------+
```

### What's real vs. what's still missing

- **Real**: `_TypeCard` for "Horizontal-scroll comic strip" (`dialogs.dart:54-61`) —
  `selected: false, enabled: false, onTap: () {}`, subtitle "Planned for a future version." Real
  "DEVICE ORIENTATION" section (`dialogs.dart:92-114`) — Portrait `selected: true, enabled: true`;
  Landscape `selected: false, enabled: false`. Both exactly match this flow's decided UI shape.
- **Still missing** (confirmed by grep — zero hits): **no backing data field for either.**
  `ComicsDoc` has no `scrollType` field; the dialog's `choice` variable is still only
  `DocType.comics | DocType.puzzle` (`dialogs.dart:17`) — selecting "Vertical-scroll comic strip"
  sets `choice = DocType.comics` (`:52`), same as before this whole investigation started. The
  Portrait/Landscape tiles are **hardcoded, not wired to any state at all** — no `onTap` even
  exists on `_OptionTile` for the enabled Portrait tile (it's permanently `selected: true`,
  there's nothing to toggle since Landscape is disabled). **This is real, cosmetic-only staging** —
  exactly the intended "signal intent, no engine commitment" outcome, now confirmed precisely, not
  assumed.

### Design implication for Plan

Wiring `scrollType` for real means: (1) add `ComicsDoc.scrollType` (per `03-specifications.md`),
(2) change `choice`'s type or add a parallel `ScrollType` local, (3) write the field on `newDoc()`.

**CORRECTED (2026-08-07)**: this note originally said the device-orientation tiles staying
non-interactive was "correct, not a bug," reasoning that device orientation would never be a
`.comics` field. **Anton has since decided otherwise** — device orientation becomes a real
`preferredOrientation` field on `ComicsDoc` too (`03-specifications.md`), with a **third value,
`"auto"`**, that the current 2-tile UI (Portrait/Landscape only) has no way to represent at all.
Wiring this for real now means the same three steps as `scrollType` above, **plus a third tile**
("Auto") that doesn't exist in the real dialog yet — a slightly bigger UI change than originally
scoped, not just wiring two already-drawn tiles to state.

---

## Screen 2: Layers panel — organizational layers (new)

Extends the real `_LayersSection`/`_LayerRow` (`scene_panel.dart:106-220`) and `KindChip`
(`scene_panel.dart:221-...`, real chip styles: `Bln`/violet, `Cap`/amber, `Bg`/teal, `Chr`/indigo,
`Snd`/coral, fallback `Art`/gray).

```
+--------------------------------------+
| LAYERS                    [+v][^][v] |     <- [+] becomes a small menu:
+--------------------------------------+        "Image layer" | "Organizational anchor"
|  o  background_sky.png        [Bg]   |
|  o  hero_pose_03.png          [Chr]  |
|  o  ---- (no thumbnail) ----   [Org] |     <- organizational layer: no image slots,
|       "Character rig anchor"          |        shown with a distinct placeholder row
|  o  balloon_hero_01.png       [Bln]  |        (dashed border, muted icon, editable label)
+--------------------------------------+
```

### New `KindChip` entry (proposed, following the exact existing pattern)

```dart
'organizational' => ('Org', Hs.gray300, Icons.account_tree_outlined),
```

### Notes

- An organizational layer's row has no thumbnail (nothing to show) — replaced with a muted
  dashed-border placeholder and its `name` as an editable label, since it exists purely to be
  referenced (as a `ParentId` target) or to organize, not to display.
- The `[+]` add-layer button needs a small menu now (today it's a single-action icon,
  `scene_panel.dart:115`, `onTap: c.addLayer` with no choice) — the second option creates a layer
  with `Kind: "organizational"` and no image content at all.

---

## Screen 3: Layers panel — `Layer.ParentId` (new, distinct from `GroupId`)

**Important distinction from `vdd-comics-editor-systematization-uiux/02-visual.md`'s existing
`GroupId` mockups**: that document shows a **flat**, symmetric "Group 1 (3)" collapse — good for
precomp-flattening, but has no way to show *who is parented to whom*. `ParentId` needs a real
**hierarchy** (indentation, matching `THE BROKEN TUSK`'s real up-to-64%-parented rig), not a flat
group tag. Whether these two visual languages coexist or `ParentId`'s hierarchy subsumes `GroupId`
entirely is still an open design question (per `03-specifications.md`) — both are sketched here so
Plan can pick.

```
+--------------------------------------+
| LAYERS                    [+v][^][v] |
+--------------------------------------+
|  o  background_sky.png               |
|  o  v голова (head)            [Chr] |   <- parent, expand triangle since it has children
|       o    руки сложен (arms)  [Chr] |   <- indented = parented to "голова"
|         o    предплечье (forearm)    |   <- further indented = parented to "руки сложен"
|                                 [Chr]|      (matches THE BROKEN TUSK's real 3-level structure)
|  o  balloon_hero_01.png        [Bln] |
+--------------------------------------+
```

### Interaction: setting a parent

```
Right-click / long-press a layer row -> context menu:
  "Set parent..." -> a picker listing every OTHER layer in the document (excluding itself and
                     anything already a descendant of it, to prevent cycles per the Edge Case
                     already specified) -> selecting one sets ParentId, row re-indents live
  "Clear parent"  -> only shown if parentId is already set
```

### Canvas behavior

Per `03-specifications.md`'s Behavior Specification: dragging "голова" on canvas should move
"руки сложен" and "предплечье" with it live, exactly like the existing `GroupId` move-together
behavior already mocked in the sibling flow — the two features may end up sharing one drag
implementation once the `ParentId`-vs-`GroupId` relationship question is resolved.

---

## Screen 4: New layer types — `Layer.SolidColor` and `Layer.Mask`

### Creating a solid-color layer

```
[+] menu (same one Screen 2 extended) gains a third entry: "Solid color layer"
  -> opens a color picker (standard, no new component needed)
  -> creates a layer with `solidColor` set, no Images[] populated
  -> appears in LAYERS with a filled color swatch instead of a thumbnail:
       o  [########] "White Solid 1"          [Bg]   <- swatch shows the actual color
```

### Adding a mask to any existing layer

```
Properties panel (right pane), for the selected layer, gains a new section:

+----------------------------------------+
| MASK                                    |
+----------------------------------------+
| ( ) None (default)                      |
| (o) Rectangle    [x: __] [y: __]        |
|                  [w: __] [h: __]        |
| ( ) Polygon      [Edit points on canvas]|
| ( ) Bitmap mask  [Choose file...]       |
+----------------------------------------+
```

### Canvas behavior

Selecting "Rectangle" (the common case — all 6 real masks found are exactly this) shows a
draggable/resizable rectangle overlay on the canvas, the same interaction language as the existing
selection-handle rectangle (`_WithHandles` in `canvas_view.dart`) — reusing that component rather
than inventing a new one.

---

## Screen 5: Properties panel — `Anim.basis` (scroll vs. time)

Extends the real `+ Translate`/`+ Rotate`/`+ Scale`/`+ Alpha`/`+ Sound cue` chips
(`properties_panel.dart:513-536`, via `_AddChip`).

```
Today (real, unchanged):
  [+ Translate]  [+ Rotate]  [+ Scale]  [+ Alpha]  [+ Sound cue]

Proposed: each chip's resulting Anim editor gains one new control, not the chips themselves:

+----------------------------------------+
| TRANSLATE                               |
+----------------------------------------+
| Driven by:  (o) Scroll position         |    <- default, matches every existing Anim
|             ( ) Time (wall-clock)        |
| Start: [____]  End: [____]              |       <- label changes based on the radio:
|   (scroll-pixels, if Scroll selected)    |          "scroll-pixels" or "milliseconds"/"frames"
|   (ms, if Time selected)                 |          per 03-specifications.md's still-open
+----------------------------------------+          units question
```

### Notes

- Defaults to "Scroll position" for every new anim — matches `Anim.basis`'s own default, zero
  behavior change unless the author explicitly switches it.
- The exact unit for time-based `start`/`end` (ms vs. frames) is still an open question in
  `03-specifications.md` — this mockup shows both possibilities in the label, not a final choice.

---

## Notes

- No empty/loading/error states apply to any of these — all are synchronous, local editor
  interactions, no network/async involved.
- Screen 1 is the only "mockup" in this document that's actually a description of shipped code,
  included specifically to correct the earlier assumption that it was unbuilt.
- Screens 2-5 are genuinely new UI, none of it built yet — grounded in real existing component
  patterns (`KindChip`, `_AddChip`, `_WithHandles`, the `[+]` add-layer button) so they extend
  rather than reinvent the editor's existing visual language.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-07
- [x] Notes: Approved after confirming compatibility with
      `flows/comics-editor/vdd-comics-editor-systematization-uiux/02-visual.md` — Screen 3's
      `ParentId` hierarchy mockup cites that document's existing flat `GroupId` mockups accurately
      (no contradiction, no naming collision), proposes a genuinely distinct hierarchical visual
      alongside them, and explicitly leaves the `ParentId`-vs-`GroupId` coexistence question open
      for Plan rather than silently deciding it. Screens 1/2/4/5 have no overlap with the sibling
      flow at all.
