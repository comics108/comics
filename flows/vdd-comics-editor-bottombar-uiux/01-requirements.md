# Requirements: comics-editor-bottombar-uiux

> Version: 1.7
> Status: APPROVED  
> Last Updated: 2026-08-05

## Problem Statement

The current responsive editor exposes a phone-only bottom launcher with `Scene`,
`Properties`, `New`, and `Open`. `Scene` opens the layer/sound management sheet,
while the editable canvas stays behind it. This does not provide a dedicated
viewer destination in the bottom navigation, and document-level numeric
settings (`Width`, `Height`) are separated from the rest of the editable
properties.

The requested change is to retain `Scene` for layers/sounds, add a separate
`Viewer` destination hosting `flutter_comics_viewer.ComicsViewer`, and
consolidate editable properties—especially all numeric values represented by
the legacy `legacy/comics-editor-v2.8` editor—under `Properties`. Existing
responsive structure must be preserved: this is a focused addition to the
current phone/tablet/desktop layouts, not a redesign of the editor shell.

## Users and Workflows

### Primary user

A comics production editor using `apps/comics-editor` to inspect a document,
select layers or sounds, edit document/layer/animation values, and immediately
check the rendered result.

### Primary workflow

1. Open or create a comics document.
2. Select `Viewer` to inspect the editable/rendered scene.
3. Select a layer, sound, or animation from the existing selection surfaces.
4. Select `Properties` and edit the relevant document or selection values.
5. Observe the viewer/timeline update without losing selection or draft input.
6. Save through the existing editor workflow.

### Secondary workflows

- Switch repeatedly between `Viewer` and `Properties` on a phone with one tap.
- Continue using the current simultaneous Scene/Canvas/Properties presentation
  on wide viewports without relearning the workspace.
- Use keyboard, mouse, touch, and screen-reader navigation appropriate to the
  current platform.

## Source-of-Truth Property Inventory

The following inventory is derived from `legacy/comics-editor-v2.8` XAML and
must remain reachable in the new Properties information architecture. Existing
additive v3 fields (for example layer kind and balloon text/style) must not be
removed merely because they did not exist in v2.8.

### Document

- Canvas `Width` (integer)
- Canvas `Height` (integer)
- Existing `Convert` action associated with canvas size

### Puzzle view

- View `Scale` / zoom (double slider; default `0.5`, range `0.125–1.0`,
  small step `0.05`, large step `0.1`)
- This is view state from `PuzzleViewModel`, not a serialized `Comics` document
  property; it is shown only for puzzle documents.

### Layer

- Localized `File` and `Popup` asset for every supported language
- `Preview` toggle
- Existing additive fields: `Kind`; balloon/caption fields where applicable
- Layer visibility uses a consistent eye/eye-off control in every Scene/layer
  list on phone, tablet, and desktop.

### Languages

- Language count is dynamic and sourced from the existing data-driven
  `LanguageRegistry`, never presented as a fixed `En/Ru/Hi` list.
- The UI shows languages already used by the current document/object plus an
  `[+ Add]` picker for other active registry entries.
- New registry languages are appended without a Dart/C# enum change.
- Removing a language from the available list is a soft deactivate/hide: its
  stable registry slot is retained so existing `Images[]` indices do not move.
- `en`, `ru`, and `hi` retain the load-bearing slot indices `0`, `1`, and `2`.
  They and every later entry must never be physically reordered or deleted.
- A document that already uses a deactivated language continues to display and
  round-trip it; deactivation only prevents offering it for new additions.

### New document format and device orientation

- The default comics content type is `Vertical-scroll comic strip`.
- `Horizontal infinity scroll comic strip` is displayed as a separate option
  but remains disabled because no editor/viewer engine supports it yet.
- The default target device orientation is `Portrait`.
- `Landscape` is displayed as a separate orientation option but remains
  disabled because deliberate landscape viewer support is not built yet.
- Content scroll type (`vertical`/`horizontal`) and target device orientation
  (`portrait`/`landscape`) are independent groups. Selecting or enabling one
  must never infer or force the other.
- The existing `Puzzle` document type remains available and is not replaced by
  either comic-strip option.
- Existing files without a `scrollType` field resolve to `vertical`; the UI
  default must not require rewriting legacy files merely to preserve their
  current behavior.

### Numeric editing interaction

- Numeric properties are slider/scrubber-first so common adjustments can be
  made directly without keeping a grid of visually dominant text boxes open.
- On desktop, the current number is always visible as a compact editable input
  immediately beside the slider. Clicking or tabbing into it permits exact
  entry without entering another mode or opening an overlay.
- On phone and touch-tablet, the current number is a compact value control
  immediately beside/below the slider. One tap converts it inline to an exact
  input, selects the current value, focuses it, and opens the numeric keyboard;
  no second edit action or nested screen is required.
- Exact input is easy to dismiss/commit, while desktop retains keyboard arrows
  and fine/coarse modifiers.
- Slider presentation must not silently clamp valid legacy values that fall
  outside a convenient visual range; exact input remains the source of truth
  and out-of-presentation-range values get an overflow indication.
- Invalid exact-input drafts are never persisted and restore the last valid
  value on cancellation/blur according to the approved validation behavior.

### Editor versus Viewer presentation

- `Editor` is the editable workspace containing the existing Canvas, Scene,
  Properties, and Timeline.
- `Viewer` is a review-only presentation of the rendered result. Layer
  selection and property editing are unavailable there.
- While Viewer is active, the `Selection` and `Document` Properties tabs are
  hidden rather than shown disabled or empty. Editing resumes only after
  returning to Editor.
- Returning from Viewer restores the previous selection, Properties tab,
  scroll positions, and expanded exact-input state where safe.

### Viewer position selector

- For the current/default `Vertical-scroll comic strip`, the Viewer
  position selector is vertical and inset along the right edge of the rendered
  content. It must not be drawn along the bottom edge.
- The selector maps document start to the top and document end to the bottom;
  its thumb represents the same shared scroll/animation position used by the
  Viewer.
- A bottom-edge horizontal selector belongs only to the future
  `Horizontal infinity scroll comic strip`. Because that document type remains
  disabled, the horizontal selector is documented for consistency but is not
  rendered by the current working Viewer.
- Selector orientation is derived only from content `scrollType`, including the
  legacy absent-field fallback to `vertical`. It does not change when the
  device/window changes between portrait and landscape geometry.
- The same rule applies on phone, tablet, desktop, web, and the Windows
  WPF-backed Viewer surface.

### Layer animation

- Common: `Start`, `End` (integer frame positions)
- Translate: `X`, `Y`
- Rotate: `Center X`, `Center Y`, `Angle`
- Scale: `Center X`, `Center Y`, `Scale X`, `Scale Y`
- Alpha: `Alpha`

### Sound

- Sound `File`
- Sound animation `Start`, `End`

### Selection/list actions retained outside property values

- Layers: add, move up/down, delete, visibility
- Sounds: add, move up/down where supported, delete, mute
- Animations: add by type, select, delete

These actions may remain in a Layers/Sounds/Timeline surface when that is more
usable; the requirement is that editable values are consolidated under
`Properties`, not that every command must be squeezed into one form.

## Acceptance Criteria

### Must Have

1. **Given** the editor bottom navigation is visible  
   **When** the user reads its destinations  
   **Then** both `Scene` and `Viewer` are present as separate destinations,
   each with a semantically appropriate icon, tooltip/label, selected state,
   and accessible name; `Scene` continues to expose Layers/Sounds.

2. **Given** a comics document is open  
   **When** the user activates `Viewer`  
   **Then** `flutter_comics_viewer.ComicsViewer` is shown in
   a bounded, usable surface and reflects the current document.

3. **Given** the user activates `Properties`  
   **When** no layer or sound is selected  
   **Then** `Selection` is the first tab and clearly explains how to expose
   selection-specific properties, while the following `Document` tab remains
   available with `Width`, `Height`, and `Convert`.

   **And given** the open document is a puzzle  
   **Then** `Document` also exposes the legacy puzzle view Scale/Zoom control
   with its original default, range, and steps.

4. **Given** a layer, sound, or animation is selected  
   **When** `Properties` is open  
   **Then** every applicable value in the inventory above is present, grouped
   by scope, and edits use the existing controller/history/save path.

5. **Given** a numeric field is edited  
   **When** the value is committed, cancelled, invalid, out of range, or the
   selection changes  
   **Then** behavior is explicit and safe: invalid partial text is not silently
   persisted, valid changes are undoable, and focus is not unexpectedly lost.

6. **Given** the user switches among bottom destinations  
   **When** returning to Viewer or Properties  
   **Then** document selection, scroll position, language, animation selection,
   and valid uncommitted/committed field state are preserved according to the
   approved visual interaction model.

7. **Given** the app runs on phone, tablet, desktop, or web where supported  
   **When** the viewport/orientation changes  
   **Then** Viewer and Properties remain reachable without clipped controls,
   unsafe-area collisions, inaccessible hover-only actions, or nested-scroll
   traps, while the existing responsive shell remains structurally unchanged.

8. **Given** the viewer cannot initialize or has no loadable document  
   **When** Viewer is opened  
   **Then** the UI shows an intentional loading, empty, unsupported, or error
   state with a useful recovery action where one exists.

9. **Given** the Properties destination has no relevant selection  
   **When** it is displayed  
   **Then** it does not become a blank panel: document properties and a concise
   selection hint are shown.

10. **Given** legacy v2.8 and current v3 documents  
    **When** they are opened, edited, and saved  
    **Then** existing values round-trip without schema loss introduced by this
    navigation/UI change.

11. **Given** the language registry contains any number of active languages
    **When** a localized artwork/balloon language selector is displayed
    **Then** it shows the current document/object's used languages plus
    `[+ Add]`, without assuming exactly three entries.

12. **Given** a registry language is removed from the available list
    **When** older content still references its stable slot/code
    **Then** that content remains visible and editable, while the language is
    absent only from new-language choices; no `Images[]` index shifts.

13. **Given** the New Document dialog is opened
    **When** no choice has been changed
    **Then** `Vertical-scroll comic strip` and `Portrait` are visibly
    selected as defaults.

14. **Given** the New Document dialog is displayed
    **When** the user reviews future format/orientation choices
    **Then** `Horizontal infinity scroll comic strip` and `Landscape` are
    visible with an explicit unavailable/coming-later explanation and cannot be
    selected by pointer, keyboard, or assistive technology.

15. **Given** any future combination of content scroll type and device
    orientation
    **When** its behavior is eventually enabled
    **Then** these values remain independent; horizontal does not imply
    landscape and vertical does not imply portrait.

16. **Given** a numeric property is shown in Editor
    **When** the user makes an ordinary adjustment
    **Then** a slider/scrubber is the primary affordance; desktop shows a
    directly editable number beside it, while touch layouts enter precise
    numeric editing with one tap on the adjacent value.

17. **Given** Viewer is active
    **When** the rendered result is displayed
    **Then** `Selection`/`Document` and all editable property controls are
    absent, and layer rows cannot be selected or edited until Editor is active.

18. **Given** any Scene/layer list on any platform
    **When** a layer is visible or hidden
    **Then** an eye or eye-off icon communicates the state with matching
    semantics/tooltip, and toggling it follows the existing visibility/history
    behavior.

19. **Given** a `Vertical-scroll comic strip` is open, including a legacy file
    without an explicit `scrollType`
    **When** Viewer reaches its loaded state on any supported platform
    **Then** its position selector is vertical along the right edge, with start
    at the top and end at the bottom, and no bottom-edge selector is shown.

20. **Given** the viewport or target-device orientation changes
    **When** the document `scrollType` remains vertical
    **Then** the position selector remains on the right edge; orientation does
    not rotate or relocate it.

### Should Have

- Properties uses primary tabs ordered `Selection`, then `Document`. Within `Selection`,
  related values may be grouped into concise sections such as `Layer`,
  `Artwork`, and `Animation`, with the current selection scope visible.
- Numeric input affordances appropriate to platform: numeric keyboard on
  mobile and keyboard-friendly entry on desktop; steppers/scrubbing only if
  they reuse project conventions and are approved in the Visual phase.
- A compact indication in the bottom bar when Properties contains validation
  errors or unapplied invalid text.
- A minimal Viewer entry point on tablet/desktop that fits the existing central
  workspace without rearranging Scene, Properties, or Timeline.

### Won't Have (This Iteration)

- New document schema fields solely for this redesign.
- New animation types or rendering semantics absent from legacy/current models.
- A replacement design system or unrelated overhaul of top bar, Cutting mode,
  Lettering mode, file dialogs, or publishing.
- A new application shell, desktop bottom navigation, navigation rail, or
  rearrangement of the existing desktop/tablet panes.
- New speculative editing tools, gestures, or property values without an
  approved requirement/visual change.
- Silent restoration of the currently deleted
  `libs/comics_editor/flutter_comics_editor` gitlink; it is user-owned working
  tree state and will not be modified without explicit scope.
- Physical deletion or reordering of language registry entries and reuse of
  their historical `Images[]` indices.
- Horizontal-scroll authoring/rendering or landscape viewer behavior in this
  iteration; both appear only as disabled forward-looking choices.
- Property/layer editing inside Viewer.

## Platform and Responsive Constraints

- Existing breakpoints are phone `<=600`, tablet `601–1024`, desktop `>=1025`.
- The compact phone bottom bar contains only the persistent destinations
  `Scene`, `Viewer`, and `Properties`, in that order. `New` and `Open` remain in
  the existing top bar and must not be duplicated in bottom navigation.
- Preserve the current adaptation exactly at shell level:
  - phone: Canvas plus compact Timeline; bottom buttons open modal sheets;
  - tablet: narrow `Scene | Canvas | Properties` panes plus expandable Timeline;
  - desktop: persistent `Scene | Canvas | Properties` panes plus docked Timeline.
- Bottom navigation remains phone-only. Tablet/desktop receive only a minimal
  Viewer entry within the existing workspace; no new global navigation pattern
  is introduced.
- Touch targets must be at least 44 logical pixels on touch layouts.
- Keyboard traversal and shortcuts must continue working on desktop.
- Safe areas, on-screen keyboards, landscape phone height, split-screen tablet,
  and desktop window resizing must be represented in visual states.
- `apps/comics-editor/main.dart` currently routes Windows to a separate WPF host
  rather than the Flutter `EditorScreen`. This flow must move Windows to the
  common Flutter shell and integrate the Windows Viewer through WPF rather than
  retaining the separate full-screen legacy route.
- The intended component is the existing
  `libs/comics_viewer/flutter_comics_viewer` package and its `ComicsViewer`
  widget. Its current widget implementation creates a native view only on
  Android/iOS and reports other targets as unsupported; Windows/WPF and the
  approved remaining desktop/web behavior are therefore implementation scope,
  not assumed existing capability.

## Accessibility Requirements

- Bottom destinations expose selected/unselected state and meaningful semantic
  labels; icon-only meaning is insufficient.
- Focus order follows destination navigation, section heading, then controls in
  reading order.
- Every field has a persistent label, error text is announced, and color is not
  the only indicator of selection/validation.
- Viewer gestures must not make essential navigation or property editing
  unavailable to keyboard or assistive-technology users.
- Layout remains usable with large text and at least 200% desktop zoom without
  losing access to save/navigation/recovery actions.

## Content and State Requirements

The Visual phase must cover:

- Viewer: loading, loaded/success, empty document, load error, unsupported
  platform, and disabled/unavailable document states.
- Properties: no selection, layer, balloon/caption, sound, animation types,
  invalid numeric input, and successful commit.
- Navigation: first entry, tab switch, keyboard/screen-reader focus, orientation
  or breakpoint transition, and software keyboard visible.

## Open Questions

- [x] Viewer identity: use the existing
      `flutter_comics_viewer.ComicsViewer`; the original
      `flutter_comics_editor_viewer` wording was a probable typo (confirmed by
      Anton on 2026-08-05).
- [x] Responsive shell: preserve the current phone/tablet/desktop adaptation;
      bottom navigation remains phone-only and no desktop/tablet pane
      rearrangement occurs in Editor. Viewer intentionally hides editing panes
      for focused review (confirmed/refined by Anton on 2026-08-05).
- [x] Numeric inventory clarification: include the legacy puzzle view `Scale`
      control in the complete visual/property inventory; keep internal
      `Image.Width`, `Image.Height`, `Scroll`, interpolation factor, and derived
      `Pivot` documented but not invent new visible fields for values that v2.8
      did not expose (requested by Anton on 2026-08-05 after approval).
- [x] Dynamic-language clarification: language controls use document/object
      languages plus `[+ Add]`; adding appends registry entries, while removal
      is a soft deactivate that preserves stable indices and existing document
      content (requested by Anton on 2026-08-05 after approval).
- [x] New-document defaults clarification: show independent content-scroll and
      device-orientation groups; default to `Vertical-scroll comic strip` + portrait,
      keep horizontal infinity scroll + landscape visible but disabled, and
      retain Puzzle (requested by Anton on 2026-08-05 after approval; sourced
      from `tdd-dot-comics-format` Category B/C decisions).
- [x] v3.1 visual refinement: use
      `design/comics-editor-v3.1.0-maket` as the style/layout reference;
      numeric controls become slider-first with one-action exact entry; Viewer
      hides editable Properties and is review-only; eye/eye-off visibility is
      consistent across all platforms (requested by Anton on 2026-08-05).
- [x] Numeric platform refinement: desktop always shows an editable compact
      number beside each slider; phone/touch-tablet uses one-tap inline exact
      entry with immediate selection and numeric keyboard (requested by Anton
      on 2026-08-05).
- [x] Viewer position-axis clarification: for `Vertical-scroll comic strip`, rotate
      the formerly bottom-edge selector by 90 degrees and place it along the
      right edge on every platform; reserve the bottom-edge axis for the future
      horizontal document type. This direct user clarification is authoritative
      even where `vdd-comics-editor-vertical-scroll` is ambiguous (requested by
      Anton on 2026-08-05).
- [x] `Scene` remains a separate destination for Layers/Sounds; `Viewer` is an
      additional button rather than a rename/replacement (confirmed by Anton
      on 2026-08-05).
- [x] Windows: replace the separate full-screen WPF route with the Flutter
      responsive shell and use WPF for the native Windows Viewer integration
      (confirmed by Anton on 2026-08-05).
- [x] Properties information architecture: use tabs; the baseline is
      `Selection`, then `Document`, with the detailed grouping and responsive
      tab treatment to be aligned in the Visual phase (confirmed by Anton on
      2026-08-05).
- [x] Remove `New` and `Open` from the phone bottom bar because they duplicate
      commands already present in the top bar; bottom navigation contains only
      `Scene`, `Viewer`, and `Properties` (confirmed by Anton on 2026-08-05).

## References

- `apps/comics-editor/lib/src/ui/screens/editor_screen.dart`
- `apps/comics-editor/lib/src/ui/widgets/scene_panel.dart`
- `apps/comics-editor/lib/src/ui/widgets/properties_panel.dart`
- `apps/comics-editor/lib/src/ui/widgets/timeline.dart`
- `apps/comics-editor/lib/src/ui/responsive.dart`
- `apps/comics-editor/lib/main.dart`
- `legacy/comics-editor-v2.8/Comics.Editor/Controls/*.xaml`
- `libs/comics_viewer/flutter_comics_viewer/`
- `flows/sdd-flutter-comics-editor-pview/`
- `flows/tdd-dot-comics-format/`
- `flows/vdd-comics-editor-uiux-lettering/`
- `flows/vdd-comics-editor-vertical-scroll/`
- `design/comics-editor-v3.1.0-maket/`

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-08-05
- [x] Notes: Explicitly approved in conversation. Preserve the current
      responsive shell; add focused Viewer/Properties changes only. Version
      1.1 incorporates the subsequently requested complete v2.8 numeric
      inventory, including Puzzle Scale. Version 1.2 restores the previously
      established dynamic-language behavior from
      `vdd-comics-editor-uiux-lettering` and defines safe soft removal. Version
      1.3 restores the independent vertical/horizontal scroll-type and
      portrait/landscape device-orientation decisions from
      `tdd-dot-comics-format`.
      Version 1.4 adds the v3.1 reference-driven numeric, Viewer-focus, and
      layer-visibility refinements.
      Version 1.5 defines the platform-specific one-step exact-number behavior.
      Version 1.6 makes the Viewer position selector axis follow document
      `scrollType`: right edge for current/default vertical, bottom edge only
      for future horizontal.
      Version 1.7 corrects the canonical default type label to
      `Vertical-scroll comic strip`.
