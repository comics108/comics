# Requirements: Comics Editor Camera Path + Z-Depth UI/UX

> Version: 0.1
> Status: DRAFT
> Last Updated: 2026-08-10

## Problem Statement

The `.comics` model, editor bridge, and Dart viewer already understand document-level
`cameraPath` and per-layer `zDepth`, but Comics Editor has no authoring UI for them. An author can
only obtain the intended 2.5D parallax effect by editing JSON or importing prepared content, cannot
comfortably see which layers are near/reference/far, and cannot author the camera while scrolling
the real vertical comic canvas.

This flow defines an editor-native, cross-platform UI/UX for authoring and previewing those existing
fields without turning the editor into a general-purpose 3D tool or redesigning unrelated controls.

## Established Product Context

- Default document mode is `vertical-scroll comic strip`, portrait. Future horizontal-scroll and
  landscape options remain visible-but-disabled where the existing UI already exposes them.
- Edit mode and Viewer must use the same actual document-space scroll coordinate. Authoring happens
  in Editor; Viewer is result-only and does not expose Selection/Document editing panels.
- Properties order is `General / Selection / Document`.
- Desktop numerical controls show an editable value beside their slider. Phone controls keep the
  common action lightweight and open precise editing in one action.
- The format contract is already fixed: `zDepth == 0` is the reference plane, `zDepth > 0` is
  farther/slower, `-1 < zDepth < 0` is nearer/faster; `cameraPath` is XY keyed by document scroll.
- Hidden-layer visibility uses the shared eye affordance consistently across platforms.

## User Stories

### Primary

**As a comic author**, I want to set the selected layer's optical depth and see the result directly
on the scrolling canvas, so that foreground, reference, and background motion can be composed
without editing `.comics` JSON.

**As an animator**, I want to create, select, adjust, and remove camera-path keyframes at meaningful
scroll positions, so that camera motion follows the vertical reading flow.

**As a desktop and mobile editor user**, I want the same concepts and terminology on every platform,
with controls adapted to available space, so that switching devices does not require relearning the
workflow.

### Secondary

**As an author opening a v2012 document**, I want the new UI to remain visually quiet and default to
the existing result, so that legacy documents are not accidentally changed.

**As an author making an experiment**, I want camera/depth edits to participate in undo/redo and
save normally, so that exploration is safe.

## Acceptance Criteria

### Must Have

1. **Given** a visual layer is selected in Editor mode, **when** Selection properties are opened,
   **then** its `zDepth` is shown with reference/near/far meaning, a slider, and precise numeric
   editing appropriate to the platform.
2. **Given** `zDepth` is changed, **when** the canvas is at any scroll position, **then** the layer
   preview updates using the same camera/depth result as `flutter_comics_viewer` without baking the
   effect into authored animation keyframes.
3. **Given** Document properties are open, **when** the author works with Camera Path, **then** they
   can inspect all keyframes and add, select, edit, or delete a point defined by document
   `position`, `x`, and `y`.
4. **Given** a camera point is selected, **when** its position or XY values change, **then** the
   current canvas/scroll representation makes the affected location and movement understandable,
   without requiring raw JSON knowledge.
5. **Given** the document is scrolled in Edit mode, **when** a camera path and nonzero layer depths
   exist, **then** the canvas preview remains tied to the actual viewport range for the selected
   General device dimensions, not to the desktop monitor size.
6. **Given** the document has no path or every layer has depth zero, **when** it is opened and saved
   without camera/depth edits, **then** its visible behavior remains unchanged and the new UI does
   not imply that an effect is active.
7. **Given** invalid precise input (`zDepth <= -1`, non-number, non-finite, or invalid camera
   position/coordinates), **when** it is submitted, **then** the editor prevents invalid authored
   state and explains the correction locally without crashing or losing the previous valid value.
8. **Given** camera/depth values are edited, **when** Undo/Redo or Save/Reopen is used, **then** all
   values and the selected document result are preserved by the existing model/bridge contract.
9. **Given** desktop, tablet, or phone layout, **when** the same operation is performed, **then**
   terminology, value meaning, and result are consistent; only density and the precise-value
   interaction adapt.
10. **Given** Viewer mode is active, **when** the result is inspected, **then** camera/depth renders
    but authoring controls are hidden with the rest of Selection/Document editing UI.
11. **Given** a layer is hidden, organizational-only, or has no renderable content, **when** depth is
    present, **then** the UI does not pretend there is a visible parallax result and uses the
    established eye/visibility behavior rather than a second visibility mechanism.
12. **Given** camera points share or cross positions during editing, **when** the edit is committed,
    **then** the UI produces a deterministic strictly ordered path consistent with the existing
    last-point-wins format normalization.

### Should Have

- Human-readable depth cues such as `Near`, `Reference`, and `Far`, while preserving the exact
  numeric value for professional control.
- A clear but unobtrusive indication of the current camera sample and selected keyframe on the
  existing vertical scroll/navigation representation.
- Reset-to-reference for layer depth and reset/remove-path actions with normal undo behavior.
- Keyboard adjustment and accessible labels on desktop/Web; touch targets and one-action precise
  value entry on phone/tablet.
- Multi-selection behavior that cannot silently overwrite different layer depths.

### Won't Have (This Iteration)

- Perspective 3D viewport, camera rotation, zoom/focal length, depth-of-field, lighting, or a 3D
  gizmo.
- A new camera/depth file format or alternate evaluator; the approved shared model is authoritative.
- Baking parallax into layer animations or changing `ParentId` depth inheritance semantics.
- Enabling horizontal-scroll or landscape document modes; their future affordances remain disabled.
- Camera/depth editing in Viewer mode.
- Redesign of unrelated Properties, Timeline, Layers, Scene, or bottom-bar behavior.

## Constraints

- **Technical**: Reuse `ComicsDoc.cameraPath`, `EditorLayer.zDepth`, and
  `CameraPathEvaluator`; preserve editor bridge round-trip and undo/redo architecture.
- **Coordinate model**: Camera position and scroll-basis animation use document pixels and the
  selected device viewport range, not host-window pixels.
- **Compatibility**: v2012/absent fields are inert; zero depth and no path must not cause visual or
  persisted churn.
- **Platform**: Flutter editor behavior must cover macOS, Windows migration target, Linux, Web,
  Android, and iOS with responsive interaction rather than platform-specific feature differences.
- **UI consistency**: Follow the approved bottombar/Properties conventions and existing slider plus
  exact-number policy.
- **Scope ownership**: Format semantics belong to `tdd-dot-comics-format`; rendering math belongs to
  `flutter_comics`; this VDD owns editor authoring and visualization only.

## Open Questions

- [ ] Should Camera Path's primary authoring surface be a compact keyframe list in Document
      properties, an overlay on the right-side vertical scroll rail, or both with one as secondary?
- [ ] Should adding a point capture the current camera XY automatically, open a small inline editor,
      or place a draggable canvas handle immediately?
- [ ] What practical slider range and stepping should the layer-depth control expose while precise
      entry still permits the full valid `zDepth > -1` domain?
- [ ] For mixed multi-selection, should depth show `Mixed` with a relative adjustment workflow, or
      require an explicit value before applying one depth to all selected layers?
- [ ] Should the camera-path overlay be always visible when the Document tab is active, or controlled
      by a lightweight show/hide toggle remembered only for the editing session?

## References

- `flows/tdd-dot-comics-format/01-requirements.md` and `03-specifications.md`
- `flows/sdd-flutter-comics/` — implemented shared model, parser, evaluator, and editor bridge
- `flows/comics-viewer/sdd-flutter-comics-viewer-dart/` — implemented rendering/scroll contract
- `flows/comics-editor/vdd-comics-editor-bottombar-uiux/` — Properties and cross-device conventions
- `flows/comics-editor/vdd-comics-editor-scroll/` — vertical scroll/navigation behavior
- `flows/comics-editor/vdd-comics-editor-timeline/` — timeline ownership boundary
- `design/comics-editor-v3.1.0-maket/` — optional layout reference, not authority over direct user
  requirements

---

## Approval

- [ ] Reviewed by: Anton Dodonov
- [ ] Approved on:
- [ ] Notes:
