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
  groups from `tdd-dot-comics-format`: vertical infinity scroll + portrait are
  defaults; horizontal infinity scroll + landscape are visible but disabled;
  Puzzle remains available.

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
