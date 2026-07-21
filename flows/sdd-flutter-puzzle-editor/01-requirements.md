# Requirements: Flutter Puzzle Editor Plugin Refactoring

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-19

## Problem Statement

The current `flutter_puzzle_editor` plugin has an unclear separation of concerns between the core editor functionality and UI/parameter controls. The native C# handler in `Comics.Editor` (which also handles puzzle editing) provides the core editing canvas, but UI elements for managing parameters, adding images, and other controls are mixed with the plugin code instead of being in the example app.

This makes it difficult to:
- Understand what is the core plugin functionality vs. demo/example code
- Reuse the plugin in different contexts with different UIs
- Maintain and evolve the editor independently from UI implementations

## User Stories

### Primary

**As a** Flutter developer using the puzzle editor plugin
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

3. **Given** the C# native handler in `native/Comics.Editor/` (shared with comics editor)
   **When** integrated with Flutter
   **Then** the FFI binding should properly connect Dart to C# puzzle editor functionality

4. **Given** the current functionality
   **When** refactoring is complete
   **Then** all existing features should work exactly as before (no feature changes)

5. **Given** the refactored structure
   **When** a developer looks at the code
   **Then** the file organization should clearly separate core plugin from example UI

### Should Have

- Clear documentation in README explaining the refactored structure
- Comments indicating which parts connect to C# native handler
- Example app that demonstrates all puzzle editor capabilities

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
- **Shared Native**: The C# handler is shared with comics editor, so changes must not break comics functionality

## Open Questions

- [x] Are there any dependencies between the puzzle editor UI and the core widget that might complicate separation?
- [x] Should we rename the package from "editor" to "flutter_puzzle_editor" in pubspec.yaml?
- [x] Are there specific naming conventions for the puzzle editor widget class?
- [x] What specific UI elements need to be moved to example/?
- [x] How does the puzzle editor functionality differ from comics editor in the shared C# handler?

## References

- Existing reference apps: `apps/mahabharata-mobile-java-v2012` and `apps/mahabharata-mobile-swift-v2012`
- These apps use viewer components (not editors) for displaying content
- C# Editor location: `libs/flutter_puzzle_editor/native/Comics.Editor/` (shared handler)
- Web reference (not needed): `libs/flutter_puzzle_editor/native/Comics.Web/`
- Related plugin: `libs/flutter_comics_editor` (similar refactoring pattern)

## Context Notes

The Puzzle Editor is the main working canvas/field in the plugin. Designers use it to create interactive puzzle content. The refactoring should follow the same pattern as the comics editor refactoring, maintaining a clear separation between editing (this plugin) and viewing (separate plugin if it exists).

Note: The puzzle editor shares the same C# native handler codebase with the comics editor, so the FFI bindings need to call the appropriate puzzle-specific methods in the shared handler.

---

## Approval

- [ ] Reviewed by: Anton
- [ ] Approved on: [pending]
- [ ] Notes: [awaiting review]
