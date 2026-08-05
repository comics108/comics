# Visual Mockups: comics-editor-bottombar-uiux

> Version: 1.7
> Status: REVIEW  
> Last Updated: 2026-08-05  
> Requirements: [01-requirements.md](01-requirements.md)

## Overview

This design preserves the current responsive Editor shell. It adds a dedicated
Viewer surface and reorganizes Properties without moving existing desktop or
tablet panes while Editor is active. Viewer intentionally hides editing panes
to become a focused review surface.

Visual styling, density, panel proportions, typography, and color hierarchy use
`design/comics-editor-v3.1.0-maket` as the reference. The additions below amend
that reference where explicitly requested.

The shared information model is:

```text
Scene       = select and manage Layers / Sounds in Editor
Editor      = editable workspace containing the existing CanvasView
Viewer      = review-only rendered result through flutter_comics_viewer
Properties  = Selection tab first, Document tab second
Timeline    = existing animation timeline
```

`New` and `Open` remain in the existing top bar on every layout. They are not
duplicated in phone bottom navigation.

## Responsive Layout Map

| Viewport | Existing shell retained | Focused addition |
|---|---|---|
| Phone `<=600` | Canvas + compact Timeline + bottom-sheet launchers | Bottom bar becomes `Scene / Viewer / Properties`; Viewer opens the same modal-sheet pattern |
| Tablet `601–1024` | Narrow `Scene | Canvas | Properties` + expandable Timeline in Editor | Workspace switch gets `Editor / Viewer`; Viewer hides editing panes/tabs |
| Desktop `>=1025` | `Scene | Canvas | Properties` + docked Timeline in Editor | Same `Editor / Viewer` switch; Viewer becomes a focused review surface |
| Windows desktop | Same Flutter desktop shell | `Viewer` tab hosts the WPF-backed implementation of `flutter_comics_viewer`; never opens a separate WPF window |

## Screen: New Document — Format and Orientation Defaults

The existing New dialog keeps `Puzzle` and makes the two independent choices
explicit: content scroll type and target device orientation. Disabled future
options are informative, not interactive.

### Desktop/tablet

```text
+--------------------------------------------------------------------------+
| New document                                                        [x]  |
+--------------------------------------------------------------------------+
| CONTENT TYPE                                                            |
|                                                                          |
| +----------------------+ +----------------------+ +--------------------+ |
| | [selected]           | | [disabled]           | |                    | |
| | Vertical infinity    | | Horizontal infinity  | | Puzzle             | |
| | scroll comic strip   | | scroll comic strip   | |                    | |
| |                      | |                      | | Zoomable board of  | |
| | Continuous vertical  | | Continuous horizontal| | draggable pieces. | |
| | strip.               | | strip.               | |                    | |
| | Default              | | Coming later         | |                    | |
| +----------------------+ +----------------------+ +--------------------+ |
|                                                                          |
| DEVICE ORIENTATION                                                       |
| +------------------------------+ +-------------------------------------+ |
| | [selected] Portrait          | | [disabled] Landscape                | |
| | Default                      | | Coming later                        | |
| +------------------------------+ +-------------------------------------+ |
|                                                                          |
| Scroll direction and device orientation are independent settings.        |
|                                                   [Cancel] [Create]       |
+--------------------------------------------------------------------------+
```

### Phone

Cards stack in a single scroll surface; defaults and disabled states remain
visible without horizontal scrolling.

```text
+--------------------------------------+
| New document                    [x]   |
|                                      |
| CONTENT TYPE                         |
| +----------------------------------+ |
| | [selected] Vertical infinity    | |
| | scroll comic strip · Default    | |
| +----------------------------------+ |
| +----------------------------------+ |
| | [disabled] Horizontal infinity  | |
| | scroll comic strip · Coming later| |
| +----------------------------------+ |
| +----------------------------------+ |
| | Puzzle                           | |
| +----------------------------------+ |
|                                      |
| DEVICE ORIENTATION                   |
| +----------------------------------+ |
| | [selected] Portrait · Default    | |
| +----------------------------------+ |
| +----------------------------------+ |
| | [disabled] Landscape            | |
| | Coming later                     | |
| +----------------------------------+ |
|                                      |
| [Cancel]                    [Create] |
+--------------------------------------+
```

### Selection and disabled semantics

- On entry, `Vertical-scroll comic strip` and `Portrait` are selected.
- `Puzzle` remains selectable. If Puzzle is selected, orientation stays a
  separate device-target choice rather than being inferred from document type.
- Horizontal and Landscape remain in focus/semantics reading order so their
  existence and disabled reason are discoverable, but they cannot receive an
  activation action or change dialog state.
- Disabled cards use reduced emphasis plus a lock/disabled indicator and text;
  opacity alone is insufficient.
- `Create` produces today's supported vertical/portrait behavior. The absent
  `scrollType` field continues to mean vertical for legacy compatibility.
- The UI never automatically pairs vertical with portrait or horizontal with
  landscape; the current defaults happen to be vertical + portrait, but the
  two groups are modeled independently.

## Screen: Phone — Canvas (Default)

The main screen remains the existing editable Canvas and compact Timeline. The
bottom bar now contains only three persistent destinations.

```text
+--------------------------------------+
| [logo] episode.comics  [+][open][save][...] |
+--------------------------------------+
|                                      |
|                                      |
|         EXISTING EDIT CANVAS         |
|          selection handles           |
|                                      |
|                                      |
+--------------------------------------+
| (play) frame 120  [====|=====]       |  compact Timeline
+--------------------------------------+
| [layers]      [play]       [tune]    |
|  Scene        Viewer      Properties |
|  active                               |
+--------------------------------------+
|             safe area                |
+--------------------------------------+
```

### Phone bottom bar behavior

- Equal-width destinations in fixed order: `Scene`, `Viewer`, `Properties`.
- Minimum target height: 44 logical pixels plus safe-area padding.
- Icon and text are both visible; active state uses icon/text color plus an
  indicator, never color alone.
- Opening a destination uses the existing modal bottom-sheet model. Closing it
  returns to Canvas without changing the current layer/sound/animation.
- `New` and `Open` remain the existing top-bar icons.

## Screen: Phone — Scene Sheet

Canvas size is moved out of Scene and into `Properties > Document`. Scene keeps
its existing responsibility and gains the vertical space formerly occupied by
the Canvas card.

```text
+--------------------------------------+
|                 ----                 |  grip
| Scene                           [x]   |
+--------------------------------------+
| LAYERS                  [+][up][dn][x]|
| [eye]     [Bln] speech-01.png          |
| [eye]     [Art] character-02.png sel.  |
| [eye-off] [Bg ] background.png         |
|                                      |
|                                      |
+--------------------------------------+
| SOUNDS                     [+][mute][x]|
| [snd] narration-01.mp3                |
+--------------------------------------+
```

Empty Scene state:

```text
| LAYERS                       [+] |
| No layers yet                    |
|                                  |
| SOUNDS                       [+] |
| No sounds                        |
```

### Layer visibility — all platforms

```text
Visible layer: [eye]     character-02.png
Hidden layer:  [eye-off] background.png    (row content de-emphasized)
```

- Replace the switch-like visibility control with Material-style
  `visibility` / `visibility_off` icons everywhere a layer row appears.
- Desktop target is at least 32px; touch layouts use at least 44px.
- Tooltip/semantic action reads `Hide layer <name>` or `Show layer <name>`.
- The hidden row remains present and selectable in Editor; only its Canvas
  rendering is hidden.
- Viewer is review-only, so no visibility toggle is exposed there.
- Eye state uses icon shape plus row opacity; color is not the only signal.

## Screen: Phone — Viewer Sheet

Viewer follows the existing 85%-height sheet pattern so the global shell does
not change. The native viewer owns the large content area; Flutter chrome stays
compact and outside the PlatformView.

```text
+--------------------------------------+
|                 ----                 |
| Viewer                          [x]   |
| [play/pause] [sound] [preview]        |  compact controls
+--------------------------------------+
|                                   0  |
|     flutter_comics_viewer          | |
|     native rendered content        | |
|                                  42%o|  position thumb
|                                    | |
|                                    | |
|                                 end  |
+--------------------------------------+
```

### Viewer interactions

- Viewer uses the current shared language selection. The language control is
  data-driven: it shows document-used languages plus active
  `LanguageRegistry` entries, never a fixed three-value enum.
- `play/pause`, sound, and preview controls map to existing
  `ComicsViewerController` capabilities. They are not new rendering behavior.
- Drag/scroll gestures inside the viewer belong to the PlatformView. Sheet
  dismissal is restricted to the grip/header area so vertical viewer gestures
  do not accidentally close it.
- For the current/default `Vertical-scroll comic strip`, the position
  selector is inset along the right edge: top is document start, bottom is
  document end, and the thumb follows the shared scroll/animation position.
  The narrow visible rail sits inside a 44px touch target and the platform safe
  area, so it remains usable without colliding with system edge gestures.
- Tapping the rail jumps to that position; dragging the thumb scrubs
  continuously. The adjacent compact percentage appears at/near the thumb and
  does not create a second bottom control.
- Closing/reopening preserves viewer position while the document remains open.
- A document edit triggers a non-blocking refresh state; selection in Scene and
  active Properties tab remain unchanged.

## Viewer States — All Platforms

### Loading / refreshing

```text
+--------------------------------------+
| Viewer                               |
+--------------------------------------+
|                                      |
|             (spinner)                |
|          Preparing preview…          |
|                                      |
+--------------------------------------+
```

During refresh after a valid edit, the last successfully rendered frame may
remain visible under a small progress banner instead of flashing blank:

```text
| [ Updating preview… ]                |
| last successful rendered content     |
```

### Loaded / success

```text
| [pause] [sound on] [preview off]   0  |
| rendered content                  |  |
|                                42%o  |
|                                   |  |
|                                 end  |
```

### Position selector orientation by document scroll type

Current, enabled `Vertical-scroll comic strip`:

```text
+-----------------------------+
| rendered content          0 |
|                           | |
|                        42%o |  <- right-edge vertical selector
|                           | |
|                         end |
+-----------------------------+
```

Future horizontal infinity scroll, shown here only to record the mapping:

```text
+-----------------------------+
| rendered content            |
|                             |
|                             |
| 0 -----------o--------- end |  <- bottom-edge selector
+-----------------------------+
```

- The second layout is not rendered while `Horizontal infinity scroll comic
  strip` remains disabled.
- `scrollType` alone selects the control axis. Portrait/landscape device or
  window geometry never rotates the selector.
- A missing legacy `scrollType` resolves to vertical, therefore uses the
  right-edge layout.
- Loading, empty, error, and unsupported states do not show an active selector.

### Empty document

```text
+--------------------------------------+
|              [image icon]            |
| Nothing to preview yet               |
| Add a layer in Scene.                |
|            [Open Scene]              |
+--------------------------------------+
```

### No open/loadable document

```text
+--------------------------------------+
|              [file icon]             |
| Open a comics document to use Viewer |
|             [Open file]              |
+--------------------------------------+
```

`Open file` invokes the existing Open dialog; it is a recovery action inside an
empty state, not a duplicate persistent navigation item.

### Load error

```text
+--------------------------------------+
|                [!]                   |
| Preview could not be loaded          |
| <short actionable error summary>     |
|        [Retry]  [Show details]       |
+--------------------------------------+
```

Details are selectable/copyable and remain collapsed by default.

### Backend unavailable / unsupported runtime

```text
+--------------------------------------+
|                [!]                   |
| Viewer is unavailable on this build  |
| The editor is still available.       |
|             [Show details]           |
+--------------------------------------+
```

The rest of the editor remains usable. This is a fallback state, not the
intended result for an approved supported target.

### Controls disabled while loading

```text
| [play disabled] [sound disabled] [preview disabled] |
| Preparing preview…                                |
```

Disabled controls retain readable labels/tooltips and do not disappear.

## Screen: Phone — Properties Sheet

`Selection` is first and is the initial tab on first entry. The last active tab
is remembered for the open document.

```text
+--------------------------------------+
|                 ----                 |
| Properties                      [x]   |
+--------------------------------------+
| [ Selection ]      Document          |
| =================                    |
|                                      |
| selected artwork layer               |
| [swatch] character-02.png      LAYER |
|                                      |
| Kind        [Character          v]   |
| ARTWORK · PER LANGUAGE               |
| [ English ] [ Українська ] [ + Add ] |
| File   [character-02.png] [...]       |
| Popup  [— none —       ] [...]       |
| [x] Preview this layer               |
|                                      |
| ANIMATIONS                           |
| [Translate] [Rotate] [+ Scale] ...   |
| +----------------------------------+ |
| | Translate                      x | |
| | Start |---o-------|  0           | |
| | End   |-------o---|  240         | |
| | X     |----o------|  0           | |
| | Y     |------o----|  128         | |
| +----------------------------------+ |
|                                      |
+--------------------------------------+
| keyboard/safe area; content scrolls  |
+--------------------------------------+
```

### Properties > Selection — no selection

```text
| [ Selection ]      Document          |
|                                      |
|            [cursor icon]             |
| Select a layer or sound in Scene     |
| to edit its properties.              |
|             [Open Scene]             |
```

### Properties > Document

```text
| Selection        [ Document ]        |
|                    ==========        |
| CANVAS                               |
| Width  |------o------|  1080         |
| Height |---------o---|  1920         |
| [Convert artwork to canvas size]     |
|                                      |
| Changing canvas size affects the     |
| document, not only the selected layer|
```

Width/Height/Convert are moved here and are not duplicated in Scene.

## Dynamic Language Controls

The labels below are examples of runtime registry/document data, not a fixed
set. A document may show one, three, twenty, or more languages.

### Localized artwork / balloon language row

```text
| LANGUAGE                             |
| [English] [Українська] [ไทย]         |
| [+ Add] [Manage]                     |
```

- Used languages come first in stable registry order.
- `[+ Add]` opens a searchable picker containing active registry languages not
  yet used by the current object/document.
- A horizontally constrained phone row wraps chips; it never compresses names
  into unreadable two-letter-only labels.
- The selected language is indicated by fill, border, and semantics.

### Add language picker

```text
+--------------------------------------+
| Add language                    [x]   |
| [ Search by name or ISO code…      ] |
|                                      |
| Bengali                    বাংলা     |
| Hebrew                     עברית     |
| Japanese                   日本語    |
| Marathi                    मराठी      |
|                                      |
| Language not listed? [+ Add custom]  |
+--------------------------------------+
```

Adding a custom language appends a new registry entry. It never inserts before
or between existing entries.

### Manage available languages

```text
+--------------------------------------+
| Manage languages               [x]   |
| Stable slots are never reordered.    |
|                                      |
| 0  English      [active]  [protected]|
| 1  Russian      [active]  [protected]|
| 2  Hindi        [active]  [protected]|
| 3  Ukrainian    [active]             |
| 4  Thai         [inactive]           |
| ...                                  |
|                         [+ Add]       |
+--------------------------------------+
```

- “Remove” means mark inactive/hide from future `[+ Add]` choices; the row and
  slot remain in the registry.
- Existing documents using an inactive language still show it in their used
  language row, with an `Inactive` badge and normal editing access.
- Reactivating restores it to `[+ Add]` choices.
- No drag-to-reorder and no hard-delete action are offered.

### Existing document uses an inactive language

```text
| [English] [ไทย · Inactive] [+ Add]   |
| Thai content remains visible/editable|
```

This prevents language-list maintenance from corrupting localized `Images[]`
slot mappings.

### Properties > Document — Puzzle

Puzzle documents show the same Canvas section plus the legacy view-only Scale
control. The range and steps are visible through semantics/tooltips; the current
value is also shown numerically so keyboard users are not forced to use only a
slider.

```text
| Selection        [ Document ]        |
|                    ==========        |
| CANVAS                               |
| Width  |------o------|  1080         |
| Height |---------o---|  2160         |
| [Convert artwork to canvas size]     |
|                                      |
| PUZZLE VIEW                          |
| Zoom / Scale                         |
| 0.125  |--------o----------|  1.0    |
|                    [ 0.50 ]          |
| Small step 0.05 · Large step 0.10    |
```

- Default: `0.5`.
- Minimum: `0.125`.
- Maximum: `1.0`.
- Small keyboard/step change: `0.05`.
- Large keyboard/page change: `0.1`.
- The control appears only for puzzle documents and changes the view scale,
  not serialized document dimensions.

## Properties > Selection Variants

### Generic artwork layer

```text
| Header: swatch + layer name + LAYER  |
| Kind                                 |
| Dynamic used-language tabs + Add     |
| Artwork per language: File / Popup   |
| Preview toggle                       |
| Animations list/add/delete           |
| Selected animation fields            |
```

### Balloon/caption layer

```text
| Header: balloon name + BALLOON       |
| Kind / Style                         |
| Dynamic used-language tabs + Add     |
| Balloon text                         |
| Rendered artwork fields/actions      |
| Preview toggle                       |
| Animations list/add/delete           |
| Selected animation fields            |
```

Existing `BalloonEditorCard` content is reused rather than redesigned.

### Sound

```text
| Header: [sound] narration.mp3 SOUND  |
| SOUND FILE                           |
| File [narration.mp3] [...]           |
| ANIMATIONS                           |
| [Sound] [+ Sound cue]                |
| +----------------------------------+ |
| | Sound                           x | |
| | Start |--o---------|  20          | |
| | End   |--------o---|  180         | |
| +----------------------------------+ |
```

## Complete Numeric Property Inventory from v2.8

This is the complete set of user-editable numeric controls represented by the
v2.8 XAML. Every applicable field appears in Properties; shared `Start`/`End`
are repeated in each selected animation card because only one animation is
edited at a time.

| Scope/type | Visible fields | Data type | Legacy initial/default | Enforced legacy range |
|---|---|---|---|---|
| Comics document | `Width`, `Height` | `int` | new document `1080`, `2160` | none |
| Puzzle view | `Scale` | `double` slider | `0.5` | `0.125–1.0`; steps `0.05/0.1` |
| Every animation | `Start`, `End` | `int` | CLR default `0`, `0` | none |
| Translate | `X`, `Y` | `int` | `0`, `0` | none |
| Rotate | `Center X`, `Center Y`, `Angle` | `double` | resting pivot `0.5`, `0.5`; angle `0` | none |
| Scale | `Center X`, `Center Y`, `Scale X`, `Scale Y` | `double` | resting pivot `0.5`, `0.5`; scale `1`, `1` | none |
| Alpha | `Alpha` | `double` | resting alpha `1` | none; v2.8 did not clamp to `0–1` |
| Sound cue | no extra fields beyond `Start`, `End` | — | initial cue of a newly imported sound: `Start == End == current Scroll`; subsequently added cue: `End = Start + 200` | — |

### Selected Translate animation — complete card

```text
| ANIMATIONS                           |
| [Translate] [Rotate] [Scale] [Alpha] |
| [+ Translate] [+ Rotate] ...         |
| +----------------------------------+ |
| | Translate                      x | |
| | Start |--o---------|  0           | |  int
| | End   |-------o----|  200         | |  int
| | X     |-----o------|  0           | |  int
| | Y     |-----o------|  0           | |  int
| +----------------------------------+ |
```

For a layer created at the current scroll position, its initial Translate has
`Y = integer current Scroll`; `Start` and `End` otherwise use CLR default `0`
until authored.

### Selected Rotate animation — complete card

```text
| +----------------------------------+ |
| | Rotate                         x | |
| | Start    |--o-------|  0         | |  int
| | End      |------o---|  200       | |  int
| | Center X |-----o----|  0.50      | |  double
| | Center Y |-----o----|  0.50      | |  double
| | Angle    |-----o----|  0.0       | |  double
| +----------------------------------+ |
```

`Angle` has no forced `0–360` normalization in v2.8. Negative and multi-turn
values remain representable.

### Selected Scale animation — complete card

```text
| +----------------------------------+ |
| | Scale                          x | |
| | Start    |--o-------|  0         | |  int
| | End      |------o---|  200       | |  int
| | Center X |-----o----|  0.50      | |  double
| | Center Y |-----o----|  0.50      | |  double
| | Scale X  |-----o----|  1.00      | |  double
| | Scale Y  |-----o----|  1.00      | |  double
| +----------------------------------+ |
```

The UI does not invent a positive-only restriction because v2.8 did not enforce
one; negative scale remains capable of representing a flip.

### Selected Alpha animation — complete card

```text
| +----------------------------------+ |
| | Alpha                          x | |
| | Start |--o---------|  0           | |  int
| | End   |-------o----|  200         | |  int
| | Alpha |----------o-|  1.00        | |  double
| +----------------------------------+ |
```

The visual may explain the usual `0–1` meaning, but validation must not silently
clamp legacy out-of-range data unless a later approved specification explicitly
adds migration behavior.

### Selected Sound cue — complete card

```text
| +----------------------------------+ |
| | Sound                          x | |
| | Start |-----o------|  120         | |  int
| | End   |-----o------|  120         | |  int
| +----------------------------------+ |
```

`Start == End` is valid and means a one-shot cue. A range (`Start < End`) means
looping behavior in v2.8; therefore equality must not be treated as a validation
error.

### New animation numeric behavior inherited from v2.8

```text
new animation Start = max(current Scroll, previous same-type End + 1)
new animation End   = Start + 200
new Sound cue       = Start + 200 through the generic Add path
newly created sound = Start == End == integer current Scroll
```

These are creation behaviors, not additional visible fields. Existing saved
values always take precedence over defaults.

### Narrow/large-text field wrapping

On very narrow or large-text layouts, each two-field row wraps into full-width
fields without changing order:

```text
Start     |--------o-----------|   0
End       |-------------o------|   200
Center X  |----------o---------|   0.50
Center Y  |----------o---------|   0.50
```

Labels never truncate into ambiguity.

## Numeric Values Present in Data but Not Editable Fields in v2.8

For completeness, these numeric values exist in the editor/model but were not
shown as editable Properties. They remain excluded from the new visible form so
the redesign does not invent controls:

| Value | Type | Role | Visual treatment |
|---|---|---|---|
| `Image.Width` | `int` | Imported asset pixel width, filled during image update | Not shown as an editable field |
| `Image.Height` | `int` | Imported asset pixel height | Not shown as an editable field |
| `ComicsViewModel.Scroll` | `double` | Current scroll/time position | Represented by Canvas/Timeline in Editor and the axis-matched position selector in Viewer; not Properties |
| animation interpolation `Factor(scroll)` | `double` | Derived easing value | Never shown |
| derived `Pivot` point | `Point(PivotX, PivotY)` | Rendering convenience | Edited only through Center X/Y |

Layout constants such as XAML control widths, margins, thumbnail sizes, and the
window's `1300 × 850` initial size are presentation implementation values, not
document/property fields, and are intentionally not added to Properties.

## Slider-First Numeric Control

The v3.1 reference's panel density is retained, but persistent numeric text
boxes are paired with a compact slider/scrubber row. Exact values stay adjacent
to their slider but use platform-appropriate interaction.

### Desktop — always-visible editable number

```text
| X          |--------o-----------| [ 128 ] |
|                                      ^    |
|                         compact editable input|
```

- Drag the track/thumb for the common adjustment path.
- Click directly into `[128]` or reach it with Tab to type an exact value; there
  is no separate reveal/edit mode on desktop.
- Enter commits; Escape restores the last valid value; blur follows the same
  validation rule.
- Arrow keys adjust by the normal step; Shift+Arrow uses the coarse step and
  Alt/Option+Arrow uses the fine step where the field supports decimals.
- The input is visually compact so sliders remain primary, but its border and
  text remain continuously visible.

### Phone and touch-tablet — one-tap exact entry

Resting:

```text
| X          |--------o-----------|  128 |
```

One tap on `128` performs the complete transition:

```text
tap 128
   -> | X    |--------o-----------| [128|] |
   -> value selected
   -> numeric keyboard opens
```

- No pencil button, long-press, double-tap, secondary dialog, or nested sheet.
- The control remains inline and scrolls above the keyboard.
- Done/Enter commits and collapses; system Back/Cancel restores the last valid
  value and collapses.
- Tapping/dragging the slider never opens the keyboard.
- Tap is chosen instead of swipe because swipe already belongs to the slider
  and tap remains keyboard/screen-reader equivalent.

### Touch layout with limited width

If slider plus value cannot fit beside each other, the value stays one tap away
directly below the same labeled control—not in another screen:

```text
| Center X                             |
| |-------------o------------------|   |
|                              0.50    |
```

### Contextual range and legacy overflow

```text
| Angle   <overflow |o------------------|  720.0 |
```

- The slider's convenient presentation range is contextual and will be
  specified per property later; it is not a new persistence constraint.
- A loaded/exact value outside that range remains unchanged, the thumb pins to
  the relevant edge, and an overflow marker is shown.
- Opening exact entry always exposes the real value. No silent clamping.

## Numeric Field States

### Focused valid draft

Desktop:

```text
| Width                                |
| |---------o----------| [ 1080| ]    |  blue focus border
```

Phone/touch after one tap uses the same focused inline field and immediately
opens the numeric keyboard.

### Invalid partial value

```text
| Width                                |
| |---------o----------| [ -    ] !   |  error border + icon
| Enter a whole number greater than 0. |
```

- Invalid text remains a local draft and is not written to the document.
- Leaving the field restores the last valid value unless the user corrects it.
- Error text is announced to assistive technology.
- Valid commits use the existing edit-history path and are undoable.

### Successful commit

```text
| Width                                |
| |-----------o--------|   1200       |
| Preview: Updating…                   |
```

No success toast is shown for every numeric edit; the updated value and Viewer
refresh are sufficient feedback.

## Screen: Tablet — Editor

```text
+--------------------------------------------------------------+
| existing compact TopBar: new / open / save / modes / more    |
+-------------+---------------------------+--------------------+
| Scene       | [ Editor ]  Viewer        | Properties         |
| Layers      | ==========                | [Selection] Document|
| Sounds      |                           |                    |
|             | existing edit CanvasView  | selected values    |
|             |                           | scroll             |
+-------------+---------------------------+--------------------+
| existing expandable Timeline                       [expand]   |
+--------------------------------------------------------------+
```

### Tablet — Viewer review state

```text
| [ Editor ] [ Viewer ]                                        |
|            ==========                                        |
|                                                           0  |
|               flutter_comics_viewer                       |  |
|               review-only rendered result              42%o  |
|                                                          |   |
|                                                        end   |
```

- Scene, Properties (`Selection / Document`), and editing Timeline are hidden
  while Viewer is active; Viewer uses the available workspace.
- Returning to Editor restores the existing narrow three-pane layout and
  expandable Timeline exactly as it was.
- No navigation rail or tablet bottom bar is added.

## Screen: Desktop/macOS/Linux/Web — Editor

```text
+--------------------------------------------------------------------------------+
| existing TopBar: document / mode / New / Open / Save / Undo / dynamic language  |
+------------------+----------------------------------------+----------------------+
| Scene            | [ Editor ]  Viewer                    | Properties           |
| Layers           | ==========                            | [Selection] Document |
|                  |                                       |                      |
| Sounds           | existing editable CanvasView          | selected values      |
|                  |                                       |                      |
+------------------+----------------------------------------+----------------------+
| existing docked Timeline                                                        |
+--------------------------------------------------------------------------------+
```

### Desktop — Viewer review state

```text
+--------------------------------------------------------------------------------+
| existing TopBar                                                                 |
+--------------------------------------------------------------------------------+
|                         [ Editor ] [ Viewer ]                                    |
|                                    ==========                                    |
| [play/pause] [sound] [preview]                                                   |
|                                                                             0  |
|                         flutter_comics_viewer                                |  |
|                         review-only result                              42%o  |
|                                                                           |    |
|                                                                         end    |
+--------------------------------------------------------------------------------+
```

- The workspace switch is keyboard reachable and does not alter stored
  selection.
- Scene, Properties tabs/content, and editing Timeline are hidden in Viewer;
  there is no empty inspector and no misleading disabled editing form.
- Viewer expands into the editing panes' space for focused review.
- The vertical document position selector stays inset along the right edge on
  desktop too; its compact value remains next to the thumb. It does not move to
  the bottom when the window becomes wide or landscape-shaped.
- Returning to Editor restores Scene, Canvas, Properties, Timeline, selection,
  active Properties tab, and their scroll state.
- No desktop bottom bar is introduced.
- On a narrow resized desktop window, the existing responsive breakpoint—not
  OS identity—continues to choose tablet/phone geometry.

## Screen: Windows Desktop

The visual structure is identical to the desktop mockup above. The only
platform-specific difference is inside the Viewer content rectangle:

```text
Flutter TopBar / Editor-Viewer workspace switch
                    |
                    +--> Viewer tab
                           |
                           +--> WPF-backed native viewer surface
```

- WPF does not create a second top-level editor window.
- Flutter owns the workspace switch, controls, loading/error overlays, sizing,
  and focus return.
- WPF owns native rendered content and its internal pointer interaction.

## Keyboard, Focus, and Assistive Technology

### Desktop/tablet keyboard order

```text
TopBar
  -> Editor / Viewer workspace switch
  -> if Editor: Scene -> Canvas -> Selection / Document -> fields -> Timeline
  -> if Viewer: Viewer controls -> position selector -> native rendered content
```

- Arrow keys move between sibling tabs; Enter/Space activates.
- The position selector exposes the semantic label `Viewer position`, its
  current value, and increase/decrease actions. On keyboard platforms,
  Up/Down moves through the vertical document and Home/End reaches document
  start/end; focus is visibly indicated without widening the visual rail.
- Tab enters the active tab panel, never hidden tab content.
- Switching Editor/Viewer or Selection/Document returns focus to the activated
  tab; it does not unexpectedly jump into the PlatformView.
- Existing Ctrl+Z / Ctrl+Shift+Z behavior remains unchanged.

### Phone focus order

```text
TopBar -> Canvas -> compact Timeline -> Scene -> Viewer -> Properties
```

When a sheet opens, focus is trapped within it until Close/back/dismiss. Closing
returns focus to the bottom button that opened it.

## Large Text, Keyboard, and Orientation

### Phone with software keyboard

```text
+--------------------------------------+
| Properties: Selection / Document     |
| scrollable fields                    |
| focused numeric field + error        |
+--------------------------------------+
| software keyboard                    |
+--------------------------------------+
```

- The focused field scrolls above the keyboard.
- The sheet does not nest an independently scrolling form inside another
  vertical form scroller.
- Phone landscape retains the same three bottom destinations; labels remain
  visible unless the approved accessibility text scale requires a documented
  fallback to a taller bar.

### 200% text / narrow Properties pane

Two-column numeric rows wrap to single-column rows. Tab labels remain text,
not icon-only. Content scrolls; headers and controls do not overlap.

## Navigation and State Transitions

```text
[Phone Canvas]
   |-- Scene ------> [Scene sheet] ------ close/back ------|
   |-- Viewer -----> [Viewer sheet] ----- close/back ------|--> [Phone Canvas]
   |-- Properties -> [Properties sheet] - close/back ------|

[Tablet/Desktop Editor] <--workspace switch--> [Viewer review]
        editing panes hidden; selection/state preserved in both directions

[Properties Selection] <--tab--> [Properties Document]
        draft/scroll state preserved while document remains open
```

Opening a different document resets selection-specific state safely, returns
Properties to `Selection`, and puts Viewer into Loading before Loaded/Error.

## Explicit Non-Changes

- No bottom navigation on tablet/desktop.
- No rearrangement of `Scene | center workspace | Properties | Timeline`.
- No duplication of New/Open in the phone bottom bar.
- No removal of Scene, Layers, Sounds, current CanvasView, or Timeline.
- No new animation types or numeric properties.
- No separate WPF editor window on Windows.
- No fixed three-language assumption in Properties or Viewer.
- No physical deletion/reordering of registry entries or shifting of language
  image-slot indices.
- No functional horizontal-scroll engine or landscape viewer support yet;
  those choices are visible but disabled.
- No coupling between comic-strip scroll direction and device orientation.
- No bottom-edge Viewer position selector for the current/default
  `Vertical-scroll comic strip`. That orientation is reserved for the future,
  disabled horizontal infinity-scroll type.
- No Properties tabs or layer/property editing while Viewer is active.

## Approval

- [ ] Reviewed by: Anton
- [ ] Approved on: —
- [ ] Notes: Awaiting explicit visual approval before specifications.
