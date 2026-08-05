# Status: vdd-comics-editor-bottombar-uiux

## Current Phase

VISUAL

## Phase Status

REVIEW

## Last Updated

2026-08-05 by Codex

## Blockers

- None; the visual draft is awaiting explicit user approval.

## Progress

- [x] Requirements drafted
- [x] Requirements approved (2026-08-05, explicit user approval)
- [x] Visuals drafted (2026-08-05)
- [ ] Visuals approved
- [ ] Specifications drafted
- [ ] Specifications approved
- [ ] Plan drafted
- [ ] Plan approved
- [ ] Implementation started
- [ ] Implementation complete
- [ ] Documentation drafted
- [ ] Documentation approved

## Evidence

- Current phone bottom launcher inspected in
  `apps/comics-editor/lib/src/ui/screens/editor_screen.dart`.
- Current `ScenePanel`, `PropertiesPanel`, timeline, responsive breakpoints, and
  editor model/controller surfaces inspected.
- Legacy v2.8 numeric/property controls inventoried from
  `legacy/comics-editor-v2.8/Comics.Editor/Controls/*.xaml`.
- Existing `libs/comics_viewer/flutter_comics_viewer` API and platform behavior
  inspected; it currently renders an unsupported message outside Android/iOS
  at widget level.
- Working tree already contains a deleted gitlink at
  `libs/comics_editor/flutter_comics_editor`; it was not restored or modified.
- `02-visual.md` now covers phone/tablet/desktop/Windows layouts; Viewer
  loading/success/empty/error/unsupported/disabled states; Properties selection
  variants and numeric validation; focus, keyboard, large-text, safe-area, and
  navigation transitions.
- Visual version 1.1 records the complete v2.8 numeric inventory: document
  dimensions, Puzzle Scale, Start/End, every animation-specific field, defaults,
  ranges/steps, creation behavior, and non-editable internal numeric values.
- Visual version 1.2 removes the fixed three-language assumption and records
  dynamic used-language tabs, Add/Manage states, append-only slot stability,
  and soft deactivate/reactivate behavior.
- Visual version 1.3 adds the independent content-scroll/device-orientation
  groups from `tdd-dot-comics-format`: `Vertical-scroll comic strip` + portrait are
  defaults; horizontal infinity scroll + landscape are visible but disabled;
  Puzzle remains available.
- Visual version 1.4 uses `design/comics-editor-v3.1.0-maket` as its visual
  reference and adds slider-first precise numeric editing, a focused read-only
  Viewer with Properties/editing panes hidden, and cross-platform eye/eye-off
  layer visibility.
- Visual version 1.5 keeps exact numbers continuously editable beside sliders
  on desktop and defines a single-tap inline exact-entry transition on
  phone/touch-tablet.
- Visual version 1.6 places the current `Vertical-scroll comic strip` Viewer
  position selector along the right edge on every platform. The bottom-edge
  variant is reserved for the future disabled horizontal document type, and
  device orientation does not choose the selector axis.
- Visual version 1.7 corrects the canonical default document-type label to
  `Vertical-scroll comic strip`; no interaction or layout behavior changes.
- Visual version 1.8 records `Comics Editor Bottombar Devices v2.dc.html` as the
  primary cross-device visual reference while preserving existing responsive
  breakpoints.

## Context Notes

- User explicitly requested no speculative UI inventions without approval.
- Anton confirmed on 2026-08-05 that the intended component is
  `flutter_comics_viewer` (the earlier name was likely a typo).
- Anton confirmed on 2026-08-05 that Windows moves to the common Flutter shell
  with WPF used for the Windows native Viewer integration.
- Anton confirmed on 2026-08-05 that Properties should use tabs ordered
  `Selection / Document`.
- Anton confirmed on 2026-08-05 that `Scene` remains available for Layers/Sounds
  and `Viewer` is added as a separate bottom-bar button.
- Anton confirmed on 2026-08-05 that duplicate `New` and `Open` actions are
  removed from the phone bottom bar and remain in the existing top bar; the
  bottom destinations are `Scene / Viewer / Properties`.
- Anton confirmed on 2026-08-05 that the current responsive adaptation is
  already convenient and must be preserved; no desktop/tablet shell redesign.
- Anton requested on 2026-08-05 that the visual artifact show and save the full
  v2.8 numeric field/value list; Visual 1.1 incorporates it.
- Anton requested on 2026-08-05 that the visual artifact reflect the earlier
  dynamic-language decision; Visual 1.2 incorporates it.
- Anton requested on 2026-08-05 that the visual artifact restore the previously
  decided vertical/portrait defaults and disabled horizontal/landscape choices;
  Visual 1.3 incorporates them as independent groups.
- Anton requested on 2026-08-05 that Visual follow the v3.1.0 maket while
  refining numeric sliders/exact input, Viewer review mode, and layer visibility;
  Visual 1.4 incorporates these additions.
- Anton refined numeric interaction on 2026-08-05: desktop inputs are always
  editable beside sliders; touch exact editing is one tap with immediate focus,
  selection, and numeric keyboard. Visual 1.5 incorporates it.
- Anton clarified on 2026-08-05 that the Viewer position selector shown at the
  bottom represented a future horizontal infinity-scroll comic. The current
  default `Vertical-scroll comic strip` must use the same control rotated to
  the right edge. This direct clarification is the source of truth; Visual 1.6
  incorporates it consistently across platforms.
- Anton corrected the exact default type wording on 2026-08-05 to
  `Vertical-scroll comic strip`; Visual 1.7 incorporates the terminology.
- Anton supplied `Comics Editor Bottombar Devices v2.dc.html` on 2026-08-05 as
  a visual reference. Source inspection confirms its desktop, iPad, iPhone,
  New Document, Viewer-state, numeric, and layer-visibility compositions align
  with the approved requirements and Visual 1.7. Visual 1.8 records it as the
  primary device reference; no new breakpoint or behavior is inferred.
- Proposed usability improvements may be documented as `Should Have`, but any
  material visual/behavioral addition returns to the relevant approval gate.
- `new` was interpreted as VDD `start` for the safe normalized name
  `comics-editor-bottombar-uiux`; destination is
  `flows/vdd-comics-editor-bottombar-uiux/`.

## Fork History

- None; this is a new flow.

## Next Actions

1. Obtain explicit visual approval.
2. After approval, inspect affected implementation interfaces in detail and
   draft `03-specifications.md`.
