# Status: vdd-comics-editor-bottombar-uiux

## Current Phase

DOCUMENTATION

## Phase Status

AWAITING_APPROVAL

## Last Updated

2026-08-05 by Codex

## Blockers

- None.

## Progress

- [x] Requirements drafted
- [x] Requirements approved (2026-08-05, explicit user approval)
- [x] Visuals drafted (2026-08-05)
- [x] Visuals approved (2026-08-05, explicit user approval)
- [x] Specifications drafted (2026-08-05)
- [x] Specifications approved (2026-08-05, explicit user approval)
- [x] Plan drafted (2026-08-05)
- [x] Plan approved (2026-08-05, explicit user approval)
- [x] Implementation started (2026-08-05)
- [x] Implementation complete (2026-08-05)
- [x] Documentation drafted (2026-08-05)
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
  defaults; Horizontal-scroll + landscape are visible but disabled;
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
- Visual version 1.8 was explicitly approved by Anton on 2026-08-05.
- Comics Editor product version was advanced from `3.2.0+1` to `3.2.1+1`;
  `AppVersion.fallback` and the approved HTML reference badge were synchronized
  to `3.2.1`.
- Specifications 1.0 map the approved UI to current Flutter/controller/core,
  mobile viewer channels, cross-platform renderer backends, and the Windows
  hostfxr/WPF child-surface constraints.
- Specifications 1.0 were explicitly approved by Anton on 2026-08-05.
- Plan 1.0 sequences viewer contracts/backends, preview snapshots, numeric and
  Properties work, responsive UI, Windows hosting, and integrated verification.
- Plan 1.0 was explicitly approved by Anton on 2026-08-05; implementation
  started with Task 1 viewer contracts and isolation tests.
- Implementation Task 1 is complete: 9 Viewer Dart tests pass, analysis is
  clean, Android compiles/tests successfully, and mobile commands/callbacks are
  bound to `flutter_comics_viewer_<viewId>` with correlated load IDs.
- Implementation Tasks 2–11 are complete on available toolchains. Editor
  analysis is clean; its complete suite passes 329 tests with 3 environment
  skips; Viewer analysis is clean and 13 tests pass; 81 real legacy documents
  pass recursive round-trip verification; three golden UI states are saved.
- Windows managed WPF payload cross-build succeeds with 0 errors. Live child
  HWND/C++ runner verification remains a Windows-runner gate and was not
  silently claimed as exercised on macOS.

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
  bottom represented a future Horizontal-scroll comic strip. The current
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

1. Review `06-readme.md`.
2. Approve documentation or request corrections.
