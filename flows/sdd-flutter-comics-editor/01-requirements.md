# Requirements: Flutter Comics Editor Plugin Refactoring

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-19

## Problem Statement

The current `flutter_comics_editor` plugin has an unclear separation of concerns between the core editor functionality and UI/parameter controls. The native C# handler in `Comics.Editor` provides the core editing canvas, but UI elements for managing parameters, adding images, and other controls are mixed with the plugin code instead of being in the example app.

This makes it difficult to:
- Understand what is the core plugin functionality vs. demo/example code
- Reuse the plugin in different contexts with different UIs
- Maintain and evolve the editor independently from UI implementations

## User Stories

### Primary

**As a** Flutter developer using the comics editor plugin
**I want** a clean separation between the core editor widget and UI controls
**So that** I can integrate the editor canvas into my own app with custom UI

**As a** plugin maintainer
**I want** all UI demo elements in the example folder
**So that** the plugin lib folder contains only the core editor functionality

**As a** developer exploring the plugin
**I want** the example app to showcase all editor features
**So that** I can understand how to use the plugin effectively

## Acceptance Criteria

### Must Have

1. **Given** the plugin library code
   **When** examining `lib/` folder
   **Then** it should contain only the core editor widget and FFI bindings to C# native handler

2. **Given** UI controls for parameters, image addition, etc.
   **When** these are needed for demonstration
   **Then** they should be located in `example/lib/` folder

3. **Given** the C# native handler in `native/Comics.Editor/`
   **When** integrated with Flutter
   **Then** the FFI binding should properly connect Dart to C# editor functionality

4. **Given** the current functionality
   **When** refactoring is complete
   **Then** all existing features should work exactly as before (no feature changes)

5. **Given** the refactored structure
   **When** a developer looks at the code
   **Then** the file organization should clearly separate core plugin from example UI

### Should Have

- Clear documentation in README explaining the refactored structure
- Comments indicating which parts connect to C# native handler
- Example app that demonstrates all editor capabilities

### Won't Have (This Iteration)

- New editor features or functionality
- Changes to the C# native handler code
- Performance optimizations
- API changes to the editor interface
- Changes to Comics.Web (it's for reference only)

## Constraints

- **Technical**: Must maintain FFI connection to existing C# native handler in `native/Comics.Editor/`
- **Compatibility**: All existing functionality must work exactly as it does now
- **Structure**: Only file reorganization - no algorithmic or feature changes
- **Platform**: Must continue to support the same platforms (Windows, macOS, Linux via FFI)
- **Dependencies**: The `native/Comics.Web/` folder should be kept for reference but is not needed for the plugin

## Open Questions

- [x] Are there any dependencies between the editor UI and the core widget that might complicate separation?
- [x] Should we rename the package from "editor" to "flutter_comics_editor" in pubspec.yaml?
- [x] Are there specific naming conventions for the editor widget class?
- [x] What specific UI elements need to be moved to example/?

## References

- Existing reference apps: `apps/mahabharata-mobile-java-v2012` and `apps/mahabharata-mobile-swift-v2012`
- These apps use `flutter_comics_viewer` (not editor) for displaying content
- C# Editor location: `libs/flutter_comics_editor/native/Comics.Editor/`
- Web reference (not needed): `libs/flutter_comics_editor/native/Comics.Web/`

## Context Notes

The Comics Editor is the main working canvas/field in the plugin. Designers use it to create interactive comics content which is then displayed by the viewer component in end-user apps. The refactoring should maintain this clear separation between editing (this plugin) and viewing (separate plugin).

---

## Approval

- [ ] Reviewed by: Anton
- [ ] Approved on: [pending]
- [ ] Notes: [awaiting review]
