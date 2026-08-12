# Visual Mockups: Comics Editor Camera Path + Z-Depth UI/UX

> Version: 0.3
> Status: APPROVED
> Last Updated: 2026-08-10
> Requirements: [01-requirements.md](01-requirements.md) (v0.1, APPROVED)

## Overview

Camera/depth authoring is added to the existing Editor shell without creating a new workspace:

```text
General   = target device and dimensions (existing responsibility)
Selection = selected layer, including its optical Z-Depth
Document  = document-wide Camera Path
Canvas    = live authored result at the current target-device viewport range
Viewer    = clean result only; no camera/depth authoring overlay
```

The design uses two coordinated camera surfaces rather than forcing one control to do two jobs:

- the right-side vertical scroll rail shows **where** camera keyframes occur in the comic;
- the Document Camera Path list and compact XY pad show **what** the selected point contains.

This keeps spatial navigation one action while retaining precise, familiar numeric editing. It also
preserves the already-approved viewport-range band: camera diamonds occupy a separate outer lane and
never replace or obscure the selected-device viewport band.

## Visual Decisions Proposed for Approval

These resolve Requirements' five open questions for this visual draft:

1. **Both rail and list**: rail is the spatial shortcut; Document list is the authoritative editor.
2. **Add without a jump**: `Add at current position` captures current document scroll and the
   currently sampled camera XY, then selects the new row for immediate adjustment.
3. **Depth soft range**: slider covers `-0.9 … 4`, snaps gently at `0`, and labels Near / Reference /
   Far. Exact entry accepts any valid finite `zDepth > -1`; an out-of-slider valid value displays as
   a `Custom` edge state rather than being silently clamped.
4. **Mixed selection is explicit**: show `Mixed`; no slider drag applies until the user chooses
   `Set depth for N layers`.
5. **Overlay is contextual**: camera markers/reticle appear by default while Document → Camera Path
   is active. An eye button hides them for the current editing session; Viewer never shows them.
6. **Multi-selection is first-class**: Scene and Canvas share one ID-based selection; desktop uses
   familiar modifiers, touch uses a clear selection mode, and compatible group actions commit once.

## Shared Visual Language

| Element | Meaning | Interaction |
|---|---|---|
| `┃` with capped band | selected target-device visible range | drag/tap scrolls Canvas |
| `◇` | unselected camera keyframe | tap selects and scrolls it into the viewport |
| `◆` | selected camera keyframe | drag vertically changes position; list/XY pad edits values |
| `⊕` | current sampled camera position/reticle | display only on Canvas; drag is not introduced |
| `0` tick | reference depth | slider snaps gently; reset returns exactly zero |
| `eye / eye-off` | authoring overlay or layer visibility | established visibility language |

Color reinforces state but is never the only signal. Selected camera points use a filled diamond,
reference depth has a labeled tick, hidden content uses both eye-off and reduced emphasis.

## Desktop — Editor, Document → Camera Path

Representative wide layout; existing responsive breakpoints and panel proportions remain unchanged.

```text
┌──── Scene ────┬──────────────────── EDIT CANVAS ───────────────────┬── Properties ──────┐
│ LAYERS        │ target: iPad 768×1024                     CAM [eye]│ General|Selection|  │
│ [eye] bg      │  ┌──────────────────────────────────────────┬────┬─┤ Document           │
│ [eye] hero    │  │                                          │START│◇│───────────────────│
│ [eye] mist    │  │          vertical comic content          │    │ ││ CAMERA PATH       │
│               │  │                                          │┏━━┓│◆││ [eye] Overlay on  │
│               │  │                    ⊕ camera sample        │┃  ┃│ ││                   │
│               │  │                                          │┗━━┛│◇││ ◆  4200  24  -16 │
│               │  │                                          │ 38%│ ││ ◇  6800  80   12 │
│               │  │                                          │    │◇││ ◇ 10400 120   40 │
│               │  └──────────────────────────────────────────┴─END┴─┤                   │
│ SOUNDS        │                                                     │ [＋ Add at current]│
│               │                                                     │ [× Delete] [Reset] │
├───────────────┴─────────────────────────────────────────────────────┴───────────────────┤
│ TIMELINE — existing animations; camera path is not moved into Timeline                 │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### Rail lanes

```text
content edge       viewport lane      camera lane
     │                  ┃                  ◇
     │               ┏━━┻━━┓               ◆  selected
     │               ┃ iPad┃               ◇
     │               ┗━━┳━━┛               ◇
     │                  ┃
```

- The viewport band retains its existing scroll behavior and represents the General target device.
- Camera diamonds are offset outward so the two controls remain individually hittable.
- Selecting a diamond scrolls enough to reveal its document position and selects the matching list
  row. It does not change the point's XY value.
- Dragging a diamond vertically changes its document position and scrolls the Canvas in sync. A
  brief value bubble (`6,800 px`) appears during drag.
- If two points meet, commit uses the existing deterministic last-point-wins rule; before release,
  the moving point shows a collision notch and local explanation.

## Desktop — Selected Camera Point

```text
┌─ CAMERA PATH ─────────────────────────────────────┐
│ [eye] Show camera overlay                         │
│                                                  │
│ Point 2 of 3                         [× Delete]   │
│ Scroll position   [───●──────────] [ 6800 px ]   │
│                                                  │
│ CAMERA OFFSET                                    │
│              Y -                                 │
│        ┌──────────────────┐                      │
│     X- │        ·         │ X+                   │
│        │      ◆ selected  │                      │
│        │        + origin  │                      │
│        └──────────────────┘                      │
│              Y +                                 │
│ X  [────●──────────────] [ 80 px ]               │
│ Y  [─────────●─────────] [ 12 px ]               │
│                                                  │
│ [Set to current sample]          [Reset XY to 0] │
└──────────────────────────────────────────────────┘
```

- Desktop numbers are always visible beside sliders and are directly editable.
- The XY pad is a compact two-dimensional adjustment aid, not a new 3D viewport. Dragging its filled
  point updates X/Y; sliders and fields stay synchronized.
- `Set to current sample` is useful after moving to another scroll position: it prevents a camera
  jump by adopting the currently evaluated XY.
- Editing position reorders the list immediately while keeping the same point selected.
- The Canvas reticle is display-only, avoiding conflict with layer selection and transform handles.

## Desktop — Selection → Z-Depth

```text
┌─ Properties ─────────────────────────────────────┐
│ General | Selection | Document                   │
├──────────────────────────────────────────────────┤
│ hero.png                              [eye]       │
│                                                  │
│ Z-DEPTH                                         │
│ Near                 Reference               Far │
│ -0.9 ├──────●──────────┼──────────────────────┤4 │
│                         0                        │
│ Depth                                      [-0.50]│
│ Motion response                              2.00×│
│                                                  │
│ Moves faster than the reference plane.           │
│ [Reset to Reference (0)]                          │
└──────────────────────────────────────────────────┘
```

Three examples use the same control:

```text
Near       z=-0.50   response 2.00×   "moves faster than reference"
Reference  z= 0.00   response 1.00×   "authored motion, no adjustment"
Far        z= 1.00   response 0.50×   "moves slower than reference"
```

- The response readout makes the otherwise abstract coefficient understandable; it is derived from
  the shared formula and is not another editable value.
- Slider movement previews immediately and creates one undoable edit when the gesture ends, rather
  than one history item per pointer update.
- The reference tick and label keep `0` discoverable; reset sets exactly `0`.
- A valid exact value outside the soft slider range is preserved:

```text
│ Far                 slider at edge ▶  [ 12.00 ]  │
│ Custom exact value · response 0.077×              │
```

## Desktop — Multi-Selection

Scene, Canvas, and Selection Properties show the same selection. One layer is the **primary** layer:
it owns transform handles, the range anchor for Shift selection, and any single-value field that
cannot be meaningfully mixed. Every other selected layer has a quieter selected outline.

```text
┌─ LAYERS ─────────────────────────────────────────┐
│ 3 selected                    [All ▾] [↑] [↓] [×]│
│                                                  │
│ [✓] [eye] [Art] hero       PRIMARY         [⋮]  │
│ [✓] [eye] [Art] mist       selected        [⋮]  │
│ [ ] [eye] [Bln] dialogue                    [⋮]  │
│ [✓] [eye] [Art] background selected        [⋮]  │
│                                                  │
│ [Show] [Hide]                 [Clear selection]  │
└──────────────────────────────────────────────────┘

Canvas
┌──────────────────────────────────────────────────┐
│ ┌──────── hero · primary handles ──────────────┐ │
│ └──────────────────────────────────────────────┘ │
│       ┌ ┄ ┄ mist · selected ┄ ┄ ┐               │
│       └ ┄ ┄ ┄ ┄ ┄ ┄ ┄ ┄ ┄ ┄ ┄ ┄ ┘               │
│                  ┌ ┄ background · selected ┄ ┐   │
│                  └ ┄ ┄ ┄ ┄ ┄ ┄ ┄ ┄ ┄ ┄ ┄ ┄ ┄ ┘   │
└──────────────────────────────────────────────────┘
```

The eye column remains per-layer and never doubles as selection. In a multi-selection, group
visibility uses explicit **Show** and **Hide** actions rather than an ambiguous toggle when values
are mixed. `⋮` owns Set/Clear Parent on touch; desktop right-click retains the same context menu.

### Familiar selection behavior

| Platform/input | Interaction | Result |
|---|---|---|
| Desktop/Web Scene | click | replace selection; clicked layer becomes primary |
| Desktop/Web Scene | `Ctrl/Cmd` + click | toggle one layer; most recently added becomes primary |
| Desktop/Web Scene | `Shift` + click | select contiguous visible Scene rows from primary anchor |
| Desktop/Web Canvas | click | replace selection |
| Desktop/Web Canvas | `Ctrl/Cmd` + click | toggle hit layer without clearing others |
| Desktop/Web | `Ctrl/Cmd+A` | select all currently selectable layers |
| Desktop/Web | Escape | collapse multi-selection to its primary layer |
| Touch Scene/Canvas | long press a layer | enter selection mode with that layer primary |
| Touch in selection mode | tap layer/row | toggle membership; last added becomes primary |
| Touch selection header | All / Invert / Clear | explicit selection set operation |

Shift range follows the visible hierarchy order so collapsed descendants are not selected
invisibly. `Select all` intentionally includes all selectable document layers; the menu labels this
scope. `Invert visible` affects visible Scene rows only. Hidden-by-eye layers are still selectable;
collapsed hierarchy rows are the only rows excluded from a visible range/inversion.

### Mixed Z-Depth

No depth is overwritten merely by opening Properties.

```text
┌─ Z-DEPTH · 3 layers ─────────────────────────────┐
│ Values                                      Mixed│
│ Near ├───────────────┼────────────────────────┤Far│  disabled preview
│                                                  │
│ hero     -0.50    mist  0.00    bg  1.00         │
│                                                  │
│ [Set depth for 3 layers]   [Reset all to 0]      │
└──────────────────────────────────────────────────┘
```

`Set depth for 3 layers` explicitly enters common-value mode and focuses the numeric field. Reset is
also explicit and names its scope. Relative multi-edit is not introduced in this iteration.

After `Set depth…`, the normal slider and exact input appear. Its first valid preview applies the
same absolute value to all selected layers, and the whole gesture commits as one Undo step. If every
selected layer already shares one value, the normal slider is immediately active and names its
scope: `Depth · 3 layers`.

### Group action bar

Only operations with deterministic meaning are exposed:

```text
3 selected  [Show] [Hide] [Move ↑] [Move ↓] [Delete…]
             └ visibility ┘  stacking order   one confirmation
```

- Canvas drag moves all selected layers by one shared document-space delta and commits once.
- When both a parent and its descendant are selected, the descendant moves once: selected roots
  receive the delta and existing parent propagation handles selected descendants.
- Move Up/Down moves the selected rows as a stable block by one legal stacking step, preserving
  relative order and hierarchy. If no legal step exists, the button is disabled.
- Delete names the count and requires confirmation for two or more layers. It uses the existing
  orphan policy for surviving children and is one Undo step.
- Parent assignment, Kind, artwork/language fields, animation editing, and other heterogeneous
  layer fields remain primary-layer-only. They are not given unsafe batch semantics in this flow.

### Phone selection mode

```text
┌──────────────────────────────────────┐
│ 3 selected             [All ▾] [Done]│
├──────────────────────────────────────┤
│ [✓] [eye] hero       Primary     [⋮] │
│ [✓] [eye] mist                   [⋮] │
│ [ ] [eye] dialogue               [⋮] │
│ [✓] [eye] background             [⋮] │
├──────────────────────────────────────┤
│ [Show] [Hide] [Depth] [Move] [Delete]│
└──────────────────────────────────────┘
```

Long press is the single entry gesture. Once active, taps only toggle selection, preventing an
accidental open/drag. `Done` leaves selection mode while retaining the primary layer as the ordinary
single selection. Destructive Delete is never the default/focused action.

### Usability recommendations included in this Visual

- Preserve a primary selection instead of displaying an ownerless set; this keeps handles,
  keyboard focus, Timeline, and non-batch Properties predictable.
- Use explicit Show/Hide and Set/Reset Depth for mixed values; a tri-state toggle is compact but
  makes the resulting value harder to predict.
- Keep selection mode transient and out of `.comics`; this avoids new persistent group semantics.
- Show the affected count in every batch label and confirmation.
- Keep Parent/Kind/animation batch editing out until each operation has an independently reviewed
  conflict policy.

## Tablet — Compact Three-Pane Editor

Tablet keeps the existing panes; only density changes. Camera list precedes the XY pad and can
collapse it when vertical space is limited.

```text
┌─Scene─┬──────────── Edit Canvas ───────────┬──── Properties ────┐
│layers │                              ┏━┓ ◆ │ Gen | Sel | Doc    │
│       │ comic                        ┃ ┃ ◇ │ CAMERA PATH        │
│       │                         ⊕    ┗━┛ ◇ │ ◆ 4200  24 -16    │
│       │                                  ◇ │ ◇ 6800  80  12    │
│       │                                    │ [+ Current]        │
│       │                                    │ [XY pad ▾]         │
│       │                                    │ X [──●──] [80]     │
│       │                                    │ Y [───●─] [12]     │
└───────┴────────────────────────────────────┴────────────────────┘
```

Touch targets are at least 44 logical pixels. The rail keeps separate viewport and camera lanes.

## Phone — Selection Properties Sheet

Phone keeps the slider as the fastest common adjustment. The numeric pill opens precise editing in
one tap.

```text
┌──────────────────────────────────────┐
│                 ───                  │
│ Properties                      [×]  │
│ General | Selection | Document       │
├──────────────────────────────────────┤
│ hero.png                        [eye] │
│                                      │
│ Z-DEPTH                              │
│ Near          Reference          Far │
│ -0.9 ├────●──────┼───────────────┤ 4 │
│                                      │
│ Depth                         [-0.50] │  <- one tap for precision
│ Motion response                 2.00× │
│ Moves faster than reference.          │
│                                      │
│ [ Reset to Reference ]               │
└──────────────────────────────────────┘
```

### Phone precise value — one action

Tapping `[-0.50]` directly opens the numeric editor and focuses the decimal keyboard. There is no
intermediate menu.

```text
┌──────────────────────────────────────┐
│ Exact Z-Depth                        │
│ Value  [ -0.50________________ ]     │
│ Valid: greater than -1               │
│                                      │
│ [Reference 0]       [Cancel] [Apply] │
├──────────────────────────────────────┤
│             numeric keyboard         │
└──────────────────────────────────────┘
```

The editor retains the previous valid value until Apply succeeds. Swipe-to-dismiss is equivalent to
Cancel, not implicit Apply.

## Phone — Document Camera Path Sheet

The list is primary in the sheet; the same camera diamonds remain visible on the Canvas rail only
when the sheet is closed. A miniature rail inside each row preserves spatial context while editing.

```text
┌──────────────────────────────────────┐
│                 ───                  │
│ Properties                      [×]  │
│ General | Selection | Document       │
├──────────────────────────────────────┤
│ CAMERA PATH              [eye] shown │
│                                      │
│ ◆ Point 1     4,200 px               │
│   X 24 px · Y -16 px            [>]  │
│ ◇ Point 2     6,800 px               │
│   X 80 px · Y 12 px             [>]  │
│ ◇ Point 3    10,400 px               │
│   X 120 px · Y 40 px            [>]  │
│                                      │
│ [＋ Add at current position]         │
│                                      │
│ Anchor + one point creates motion.   │
└──────────────────────────────────────┘
```

Opening a row replaces the list body with one focused point editor; Back returns to the list without
closing Properties:

```text
│ [<] Camera point 2             [×]   │
│ Position                 [ 6800 px ] │
│ [──────────────●────────────────]    │
│                                      │
│ XY OFFSET                            │
│       ┌──────────────────────┐       │
│       │        ◆             │       │
│       │        + origin      │       │
│       └──────────────────────┘       │
│ X [──────●────────────] [ 80 ]       │
│ Y [────────●──────────] [ 12 ]       │
│                                      │
│ [Set current sample] [Reset XY]      │
```

Numeric pills for Position/X/Y each open their precise editor directly in one tap.

## Canvas Overlay States

### Camera Path absent

```text
Document > Camera Path
┌──────────────────────────────────────┐
│            (camera path icon)        │
│ No camera motion                     │
│ Layers keep their authored movement. │
│                                      │
│ [＋ Add anchor at current position]  │
└──────────────────────────────────────┘

Canvas rail: viewport band only; no empty camera lane is drawn.
```

### One point — anchor only

```text
│ ◆ Anchor  4,200 px · X 0 · Y 0       │
│                                      │
│ One point anchors the path but does  │
│ not create camera movement yet.      │
│ [＋ Add second point at current]      │
```

### Active path, overlay hidden

```text
│ CAMERA PATH              [eye-off] hidden │
│ 3 points · effect still renders           │
│ Camera authoring guides are hidden only.  │
```

Eye-off hides diamonds, XY pad reticle, and camera hints; it never disables the effect or removes
data. This distinction is stated in text and semantics.

### Legacy v2012 / inert document

Identical to the absent-path state. Selection Z-Depth shows Reference `0`. No badge, warning, or
automatic migration prompt appears.

### Hidden or non-renderable selected layer

```text
│ [eye-off] mist.png · Hidden             │
│ Z-DEPTH  1.00 · Far                     │
│ Preview unavailable while layer hidden. │
│ [Show layer]                            │
```

For organizational-only layers:

```text
│ anchor-rig · Organizational             │
│ Z-Depth has no visible content to move. │
│ [Reset to 0]                            │
```

The value remains editable for round-trip fidelity, but the UI never claims a visible preview.

## Validation and Collision States

### Invalid precise Z-Depth

```text
│ Value  [ -1.20________________ ]         │
│ ! Enter a finite value greater than -1. │
│                         [Apply disabled] │
```

### Invalid camera number

```text
│ Position [ NaN________________ ]         │
│ ! Enter a finite document-pixel value.  │
│                         [Apply disabled] │
```

### Duplicate camera position

During drag/edit, the existing point is not silently displaced:

```text
│ Position [ 6800 px ]                     │
│ ! Point 2 already uses this position.    │
│ Saving here replaces that point.         │
│                         [Cancel] [Replace]│
```

`Replace` is the explicit UI expression of the format's deterministic last-point-wins rule. Undo
restores both points and their prior order.

## Viewer Mode — Clean Result

Viewer renders the same camera/depth effect, but editing panels and camera guides are absent.

### Desktop/tablet

```text
┌────────────────────────── VIEWER ──────────────────────────┬──────┐
│ rendered vertical comic with camera/depth                  │START │
│                                                           │ ┏━━┓ │
│ no Scene / Properties / Timeline                          │ ┃  ┃ │
│ no camera diamonds, reticle, XY pad, or depth controls     │ ┗━━┛ │
│                                                           │ END  │
└───────────────────────────────────────────────────────────┴──────┘
```

### Phone

```text
┌──────────────────────────────┬─────┐
│ Viewer result                │START│
│ camera/depth rendered        │ ┏━┓ │
│ no authoring overlay         │ ┃ ┃ │
│                              │ ┗━┛ │
└──────────────────────────────┴─────┘
```

The right rail retains only the selected-device viewport range. Future horizontal-scroll would
rotate both viewport and camera-position lanes to the bottom edge, but remains disabled and is not
implemented by this Visual.

## Interaction Flows

### Add camera movement without a jump

```text
[Scroll Edit Canvas to story beat]
                ↓
[Document > Camera Path > Add at current]
                ↓ captures current scroll + sampled XY
[New point selected; no visible jump]
                ↓
[Drag XY pad / sliders or enter exact X/Y]
                ↓
[Canvas previews camera/depth immediately]
                ↓
[Undo] restores prior path in one step
```

### Set selected layer depth

```text
[Select visual layer]
        ↓
[Properties > Selection > Z-Depth]
        ↓
[Drag slider] ────────────────┐
        or                    ├─→ [Live Canvas preview]
[Tap value → exact editor] ───┘
        ↓ gesture/apply commits one history edit
[Viewer] shows result without authoring chrome
```

### Navigate between path points

```text
[Tap rail diamond] ↔ [matching Document row selected]
        ↓
[Canvas scrolls point into selected-device viewport]
        ↓
[Edit position / X / Y]
        ↓
[rail, list, reticle, and preview update together]
```

### Select and edit several layers

```text
[Click/long-press primary layer]
                ↓
[Modifier-click or selection-mode taps add layers]
                ↓ Scene + Canvas show one shared set and primary
        ┌───────┴───────────┐
[Selection > Z-Depth]   [Group action bar]
        ↓                   ↓
[Mixed → Set depth]    [Show/Hide/Move/Delete]
        └───────┬───────────┘
                ↓ one explicit action/gesture = one Undo step
[Undo] restores values, transforms/order, or deleted layers together
```

## Keyboard, Touch, and Accessibility

- Desktop/Web: Tab reaches overlay eye, point rows, Add/Delete, sliders, and numeric fields in visual
  order. Arrow keys nudge sliders; Shift+Arrow uses the larger step. Enter commits precise edits;
  Escape restores the prior value.
- Touch: every actionable row, diamond hit area, button, and numeric pill is at least 44 logical
  pixels even when the visible mark is smaller.
- Screen readers announce `Camera point 2, position 6800 pixels, X 80, Y 12, selected` and
  `Z-Depth -0.5, Near, motion response 2 times`.
- Near/Reference/Far and selected/unselected/hidden states never rely only on hue.
- Slider preview remains responsive while persistence/history commits at gesture end.
- Multi-selected rows announce selected state and the primary row additionally announces `Primary`.
  Group actions announce their scope, for example `Hide 3 selected layers`.
- Focus returns to the primary row after a batch action; Delete moves it to the nearest surviving
  row, preventing keyboard/screen-reader focus loss.

## Visual Scope Guardrails

- Timeline remains the animation editor; camera keyframes do not appear as new Timeline animation
  rows in this iteration.
- Scene continues to own layer selection/visibility; Z-Depth does not add a second layer list.
- Selection is shared with Canvas and Selection Properties, but remains transient editor state.
- Multi-selection adds only deterministic Show/Hide, depth, translate, stable Up/Down, and Delete.
  It does not introduce persistent named groups, marquee/lasso, or bulk Parent/Kind/animation edits.
- General continues to own target device dimensions; Camera Path never infers dimensions from the
  host desktop/phone.
- Camera overlay controls are editing guides only. Eye-off does not alter saved data or Viewer output.
- No camera rotation, zoom, focal length, perspective grid, 3D axis gizmo, or depth-layer reordering
  is represented.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-10
- [x] Notes: v0.2 was approved on 2026-08-10. v0.3 approval adds the requested
      first-class multi-selection and deterministic group-action addendum.
