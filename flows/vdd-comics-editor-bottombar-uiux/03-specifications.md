# Specifications: comics-editor-bottombar-uiux

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-08-05
> Requirements: [01-requirements.md](01-requirements.md)
> Visuals: [02-visual.md](02-visual.md)
> Target product version: `3.2.1`

## Overview

This change keeps the current responsive Editor shell and adds a review-only
Viewer workspace, `Selection / Document` Properties tabs, slider-first numeric
editing, the approved phone bottom bar, dynamic artwork languages, New Document
format/orientation cards, and eye/eye-off layer visibility.

The implementation is split between the Flutter editor and
`libs/comics_viewer/flutter_comics_viewer`. Android/iOS retain native viewer
surfaces, Windows uses a WPF-backed child surface inside the Flutter window, and
macOS/Linux/Web use the plugin's Dart renderer when the platform can provide a
preview snapshot. A platform/build that cannot supply a renderer must return a
typed unsupported state; it must not leak the plugin's current red diagnostic
text into product UI.

No editor document schema migration is introduced. Existing absent
`scrollType` resolves to vertical. The disabled horizontal and landscape cards
do not write new fields.

## Verified Current-State Findings

1. `EditorScreen` already owns the approved breakpoints and layouts, but the
   phone dock is currently `Scene / Properties / New / Open`.
2. Desktop/tablet directly compose `ScenePanel | CanvasView | PropertiesPanel`
   and Timeline; no workspace-level Editor/Viewer state exists.
3. `ScenePanel` currently owns Width/Height/Convert and uses `HsToggle` for
   visibility.
4. `PropertiesPanel` is selection-only, uses fixed `Lang` segments for ordinary
   artwork, and uses plain `NumberField` text inputs. `BalloonEditorCard`
   already contains the better used-languages-plus-Add pattern.
5. Controller mutations already use `EditHistory`, but slider-frequency calls
   would currently create one undo entry per update. `editAnim` also clamps
   Alpha to `0…1` in the widget, unlike v2.8 persistence behavior.
6. `flutter_comics_viewer.ComicsViewer` currently creates Android/iOS platform
   views only. macOS/Linux/Windows registrations are generated stubs.
7. Native mobile PlatformViews use instance channels named
   `flutter_comics_viewer_<viewId>`, while `ComicsViewerController` currently
   sends commands on a global `flutter_comics_viewer` channel. This must be
   corrected before editor integration.
8. Viewer loading accepts a `.comics` file path, while unsaved editor state is
   held in `EditorController`/`CoreDocument`. Loading the last saved path would
   therefore show stale data.
9. Windows currently replaces the whole Flutter editor with `WpfEditorView` and
   opens the v2.8 WPF `MainWindow`. The existing hostfxr bridge accepts only
   argument-free `create`/`dispose` calls and does not embed a child viewer.

## Architecture

```text
EditorController
  ├─ document + selection + history
  ├─ EditorWorkspaceState (editor/viewer, active Properties tab)
  └─ ViewerPreviewCoordinator
       ├─ creates immutable preview revision from current document
       ├─ owns ComicsViewerController and typed ViewerState
       └─ synchronizes normalized position/language/sound/preview

EditorScreen
  ├─ Editor workspace (existing responsive shell)
  └─ ViewerSurface
       ├─ Flutter controls/status chrome
       ├─ flutter_comics_viewer.ComicsViewer
       └─ Flutter PositionSelector on the right (vertical scroll type)

flutter_comics_viewer
  ├─ Android backend (native PlatformView)
  ├─ iOS backend (native PlatformView)
  ├─ Windows backend (WPF child HWND hosted by Flutter window)
  └─ Dart backend (macOS/Linux/Web)
```

The position selector is deliberately outside the native/WPF render rectangle.
This avoids PlatformView/HWND z-order problems and gives Flutter ownership of
semantics, keyboard input, safe-area spacing, and the future axis switch.

## Editor State Model

Add view-only state; none of these values are serialized into `.comics`:

```dart
enum EditorWorkspace { editor, viewer }
enum PropertiesTab { selection, document }
enum ContentScrollType { vertical, horizontal }

sealed class ViewerState {
  const ViewerState();
  // idle, loading, loaded, refreshing, empty, error, unsupported
}
```

`EditorController` owns:

- `workspace`, default `EditorWorkspace.editor`;
- `propertiesTab`, default `PropertiesTab.selection`;
- current Viewer position normalized to `0.0…1.0`;
- Viewer sound/preview/play state;
- `ViewerPreviewCoordinator` lifecycle;
- per-document Viewer state, reset only when another document opens;
- valid numeric drafts keyed by document/selection/animation/field identity.

Selection, selected animation, Properties tab, panel scroll offsets, language,
and current Viewer position survive Editor ↔ Viewer transitions. Opening or
creating another document cancels pending preview work, resets Viewer to
loading/idle, clears selection-specific drafts, and restores Properties to
`Selection`.

`ContentScrollType` is read from preserved raw JSON when present. Missing,
null, or unknown values resolve to `vertical` for current rendering without
rewriting the raw field. An explicitly horizontal document returns a typed
unsupported/disabled Viewer state in this iteration because the horizontal
engine remains disabled.

## Viewer Preview Snapshot

Viewer never reads the last saved document path directly after an edit.
`ViewerPreviewCoordinator` produces an immutable preview revision:

1. Capture the current `ComicsDoc` and preserved `CoreDocument.raw` at revision
   `N`; merge with `comicsToCore` without mutating `document.path`.
2. Package `data.json` plus the current `tempFolder/layers` and `sounds` assets
   into an app-cache preview archive. For a new empty document without a core
   session, create an archive containing its merged `data.json`; missing
   referenced assets produce the normal Viewer error state.
3. Load that revision into `ComicsViewer`. Only after `onLoaded(N)` may the
   coordinator delete revision `N-1`.
4. A valid document edit while Viewer is active is debounced by 250 ms. The last
   successfully rendered revision remains visible beneath `Refreshing`.
5. Generation tokens discard late load/error callbacks from superseded
   revisions. Preview generation must not update the save path, dirty state,
   selection, history, or recent-files list.
6. Temporary archives are deleted on document close/coordinator dispose. A
   failed deletion is cleanup telemetry only, not a user-visible load failure.

For Web, the same snapshot contract may return bytes instead of a local path.
The viewer source contract therefore supports both path and bytes:

```dart
sealed class ComicsViewerSource {
  const ComicsViewerSource();
}
final class ComicsViewerPath extends ComicsViewerSource { String path; }
final class ComicsViewerBytes extends ComicsViewerSource {
  Uint8List bytes;
  String revisionKey;
}
```

## `flutter_comics_viewer` Contract

`ComicsViewer` remains the public widget. Its controller becomes
instance-scoped and attaches to the concrete view/backend during creation.

Required public behavior:

- `load(source)` and `reload(source)`;
- `play()`, `pause()`, `setSoundEnabled()`, `togglePreview()`;
- `setLanguageIndex()` using stable registry slot indices;
- `setScrollPosition(double normalized)` with finite clamping at the transport
  boundary only;
- callbacks/listenable state for loaded, error, playing, and scroll changed;
- idempotent `dispose()` owned by the editor's `ViewerPreviewCoordinator`.

For Android/iOS, attach the controller to
`flutter_comics_viewer_<viewId>` in `onPlatformViewCreated`; native callbacks
return through that same channel. The obsolete global command path must not be
used for instance operations. Multiple viewer widgets in tests or future
windows must not control each other.

Native and Dart backends expose position as normalized document progress:

```text
0.0 = document start
1.0 = maximum scroll extent / document end
```

The backend is the source of truth while the user scrolls rendered content.
The Flutter selector is the source while its thumb is dragged. Echoed values
within `1e-4` of the last sent value are ignored to prevent feedback loops.

## Platform Backends

| Platform | Backend | Required result |
|---|---|---|
| Android | Existing native PlatformView, corrected per-view channel | Loaded Viewer with scroll callbacks and controls |
| iOS | Existing native PlatformView, corrected per-view channel | Same contract as Android |
| Windows | WPF viewer hosted as a child HWND inside the Flutter window | Same Flutter shell; no WPF top-level editor window |
| macOS | Dart `ComicsViewer` renderer | Review-only loaded Viewer from snapshot |
| Linux | Dart `ComicsViewer` renderer | Review-only loaded Viewer from snapshot |
| Web | Dart renderer from `ComicsViewerBytes` where file/core support exists | Loaded Viewer or typed unsupported state |

The Dart backend parses the same archive/data model and uses the already-ported
scroll interpolation rules. It renders layers in document order, respects the
selected language slot with slot-0 fallback, preview-mode filtering,
translate/rotate/scale/alpha animation values, and scroll-driven sound gating
where audio is supported. It is not an editor Canvas and exposes no selection
handles.

### Windows WPF host

`main.dart` always builds `EditorScope -> EditorScreen`, including Windows.
The `Platform.isWindows ? WpfEditorView()` root branch is removed.

Replace the current whole-editor bridge behavior with a Viewer host:

- C# creates a WPF `HwndSource`/child host containing only the existing comics
  render control, never `MainWindow`.
- C++ receives and serializes method arguments instead of forwarding null.
- Required calls: `create(parentHwnd, bounds, dpi)`, `load(path)`,
  `setBounds(bounds, dpi)`, `setVisible(bool)`, `setPosition(double)`,
  `setLanguage(int)`, `setSoundEnabled(bool)`, `setPreview(bool)`, and
  `dispose()`.
- Bounds are the content rectangle only; Flutter reserves the right-side
  selector rail, top controls, and status overlays outside the child HWND.
- Move/resize/DPI changes update bounds after layout; Viewer exit hides the
  child synchronously before Flutter reveals Editor panes.
- Tab focus can enter and leave the WPF child; disposing or switching documents
  must not leave an orphan child window or STA dispatcher.
- Host initialization/load failures map to `ViewerState.error` or
  `ViewerState.unsupported`; they never replace the Flutter shell.

## Responsive Workspace Composition

### Phone (`<=600`)

- `_PhoneDock` becomes exactly `Scene / Viewer / Properties`.
- `New` and `Open` are removed only from this dock and remain in TopBar.
- `Viewer` opens `ViewerSheet` at the existing `.85` height factor.
- `ScenePanelSheet` uses `ScenePanel(showSettings: false)`.
- Viewer sheet dismissal is restricted to header/grip/back so vertical native
  gestures do not dismiss it accidentally.
- Closing a sheet restores focus to its dock destination.

### Tablet (`601–1024`) and desktop (`>=1025`)

- Add an `Editor / Viewer` workspace switch above the central workspace.
- Editor uses the existing pane dimensions and Timeline composition unchanged.
- Viewer replaces the entire editing body under TopBar; Scene, Properties, and
  Timeline are not built as interactive/semantics-visible descendants.
- Preserve the Editor subtree with keyed/page-storage state so switching back
  restores panel positions and field state without selecting a new object.
- No tablet/desktop bottom navigation or navigation rail is added.

Lettering and Cutting remain outside this flow. Entering Viewer from Edit is
supported; existing mode restrictions and mode UI remain unchanged.

## Viewer Position Selector

For current/default `vertical` scroll type:

- visible rail: 4 logical pixels;
- interaction width: 44 on touch, at least 32 on desktop;
- rail is inset inside safe content bounds along the right edge;
- top label/start = `0`, bottom = `end`;
- the selected target device's visible interval is shown as a filled band with two boundaries and
  a compact start–end percentage; it replaces the former point thumb;
- tap jumps once; drag updates continuously;
- Up/Down adjusts by the platform accessibility step and Home/End reaches the
  endpoints;
- semantics label is `Viewer visible range`, with device, start/end value, and
  increase/decrease actions;
- loading/empty/error/unsupported states expose no active selector.

Viewport portrait/landscape geometry never changes its axis. A horizontal
bottom selector is not instantiated in this iteration.

## Properties Information Architecture

`PropertiesPanel` becomes a tab host ordered `Selection`, `Document`, `General`.

### Selection

- No selection: concise `Select a layer or sound in Scene` hint.
- Layer: current Kind, dynamic artwork languages, File, Popup, Preview, and
  animation controls.
- Balloon/caption: reuse `BalloonEditorCard`; no duplicate fixed language row.
- Sound: File and Sound Start/End animation controls.
- Animation cards retain type chips/add/delete actions and show every v2.8
  numeric value applicable to that type.

### Document

- Width, Height, and existing Convert action move from Scene.
- Puzzle adds view Scale with default `0.5`, range `0.125…1.0`, step `0.05`,
  keyboard large step `0.1`.
- Document remains available when Selection has no object.

### General

- Target viewport is independent of the host editor window and not persisted in `.comics`.
- Built-in profiles are iPad `768×1024` (default) and iPhone `390×844`.
- Show exact dimensions, aspect ratio, and calculated visible Vertical-scroll document height.
- The selected profile controls the right-edge Viewer viewport band.

`ScenePanel.showSettings` defaults to false after migration; the old settings
card must not appear in any responsive Scene surface.

## Dynamic Languages

Extend `LanguageInfo` with `active` (JSON default `true`). Registry order stays
load-bearing; `en/ru/hi` remain indices `0/1/2`.

Use one shared `UsedLanguageTabs` implementation for ordinary artwork and
balloon/caption artwork:

- used languages are derived from non-empty image/popup/text slots;
- sort by stable registry index;
- include used inactive/unknown historical slots when display metadata exists;
- `+ Add` lists active, unused registry languages only;
- deactivation never removes/reorders a registry item or an `Images[]` slot;
- selecting an unused language alone does not write document data.

The fixed `HsSegmented<Lang>` path is removed from Properties. Existing
controller `Lang` may remain temporarily for legacy TopBar compatibility, but
Viewer and Properties convert the selected code through `LanguageRegistry` and
send the stable slot index.

## Slider-First Numeric Control

Replace `NumberField` usage in Properties/Document with
`NumericPropertyControl`. It receives field metadata, current value, validation,
and transaction callbacks.

| Field | Exact validation | Presentation range | Step |
|---|---|---|---|
| Width | integer `>0` | `1…4096` | `1` |
| Height | integer `>0` | `1…100000` | `1` |
| Puzzle Scale | finite `0.125…1.0` | `0.125…1.0` | `0.05` |
| Start / End | any integer | `0…max(document.height, 600)` | `1` |
| Translate X | any finite number | `-document.width…document.width` | `1` |
| Translate Y | any finite number | `-document.height…document.height` | `1` |
| Center X / Y | any finite number | `-1…2` | `0.01` |
| Angle | any finite number | `-360…360` | `1` |
| Scale X / Y | any finite number | `-4…4` | `0.01` |
| Alpha | any finite number | `0…1` | `0.01` |

Presentation ranges are not persistence constraints. A real value outside a
range remains unchanged, pins the thumb to the corresponding edge, and shows
an overflow marker. Exact editing exposes and accepts the real value. In
particular, remove the current Alpha `.clamp(0, 1)`.

Desktop always shows a compact editable input beside the slider. Touch shows a
compact value; one tap replaces it inline with a focused input, selects all,
and requests a signed decimal/integer keyboard as appropriate.

Commit rules:

- slider `onChangeStart` begins one history transaction;
- slider updates preview the value and notify listeners without committing
  additional history entries;
- `onChangeEnd` commits once; cancel restores the initial snapshot;
- exact text is a local draft; Enter/Done commits one valid value;
- Escape/system cancel restores the last valid value;
- invalid/partial text never calls a controller mutation and is announced;
- blur commits valid text and restores invalid text;
- selection/document changes resolve the active draft before changing scope.

## Layer Visibility

Replace layer-row `HsToggle` with an icon button:

- visible: `Icons.visibility`, action `Hide layer <name>`;
- hidden: `Icons.visibility_off`, action `Show layer <name>`;
- 32 minimum desktop target, 44 touch target;
- row stays selectable; only row content is de-emphasized;
- call existing `toggleVisible(i)` so history/save behavior is unchanged;
- no visibility control is rendered in Viewer.

Like legacy v2.8 `LayerViewModel.IsVisible`, this is Editor view state rather
than a `.comics` `Layer` field. It hides the layer from editable Canvas only,
is not added to `data.json`, and does not remove the layer from a Viewer preview
snapshot.

## New Document Dialog

Keep `DocType { comics, puzzle }`; do not add a selectable horizontal enum in
this iteration.

- Content cards: selected `Vertical-scroll comic strip`, disabled
  `Horizontal-scroll comic strip`, selectable `Puzzle`.
- Orientation group: selected `Portrait`, disabled `Landscape`.
- Disabled cards have lock icon, text, semantics `disabled`, and no pointer or
  keyboard callback; opacity alone is insufficient.
- `Create` maps vertical to existing `DocType.comics` and Puzzle to
  `DocType.puzzle`.
- No `scrollType` or device-orientation field is written solely by this dialog.

## Error and Loading States

`ViewerState` maps to product UI:

- `loading`: spinner + `Preparing preview…`, controls disabled;
- `refreshing`: last successful content + non-blocking banner;
- `loaded`: controls, renderer, right selector;
- `empty`: `Nothing to preview yet`, `Open Scene` on phone/Editor return action
  on wider layouts;
- `error`: concise message, Retry, Show details;
- `unsupported`: `Viewer is unavailable on this build`; Editor remains usable.

Error details may contain backend diagnostics but must not expose stack traces
in the primary state. Retry rebuilds the current revision, not the last saved
file.

## File Impact

### Flutter editor

- Modify `lib/main.dart`: common Flutter shell on Windows.
- Modify `lib/src/ui/models.dart`: view enums/scroll fallback as described.
- Modify `lib/src/ui/controller.dart`: workspace, Properties state, preview
  coordinator hooks, transaction-safe numeric mutations.
- Modify `lib/src/ui/screens/editor_screen.dart`: phone dock/sheets and wide
  Editor/Viewer composition.
- Modify `lib/src/ui/widgets/properties_panel.dart`: tabs and complete fields.
- Modify `lib/src/ui/widgets/scene_panel.dart`: remove settings card; eye icons.
- Modify `lib/src/ui/widgets/dialogs.dart`: approved New Document cards.
- Modify `lib/src/i18n/language_registry.dart` and `assets/languages.json`:
  active flag with stable ordering.
- Create `lib/src/ui/widgets/viewer_surface.dart`.
- Create `lib/src/ui/widgets/numeric_property_control.dart`.
- Create `lib/src/ui/widgets/used_language_tabs.dart` or extract the existing
  Balloon implementation into that shared widget.
- Create `lib/src/viewer/viewer_preview_coordinator.dart` and snapshot helper.
- Add path dependency on `../../../libs/comics_viewer/flutter_comics_viewer`.

### Viewer package

- Correct `ComicsViewerController` instance attachment and callbacks.
- Extend `ComicsViewer` source API for path/bytes and typed capability/error.
- Correct Android/iOS channel/callback lifecycle.
- Add Dart archive renderer for macOS/Linux/Web.
- Replace the Windows generated stub with the WPF-backed host contract.

### Windows host

- Remove the full-editor root route and `ShowMainWindow` behavior.
- Refactor `windows/editor_plugin`/`native/Comics.Editor.Flutter` into a
  viewer-only child host or move the host into the viewer plugin, but retain a
  single native registration/hostfxr bootstrap path.
- Update CMake/package publication for the WPF viewer payload.

## Testing and Verification

### Flutter unit/widget tests

- phone dock order is exactly Scene/Viewer/Properties; New/Open absent;
- Scene/Properties/Viewer sheets retain selection and focus return;
- tablet/desktop Editor pane geometry remains and Viewer hides editing panes;
- Properties tab order/content for none/layer/balloon/sound/puzzle;
- every numeric field metadata, valid/invalid/cancel/overflow behavior;
- one undo entry per slider gesture and exact commit;
- Alpha exact values outside `0…1` round-trip unchanged;
- used/active/inactive language ordering and stable slots;
- visibility icons, semantics, history, hidden-row selection;
- New Document defaults and disabled horizontal/landscape semantics;
- Viewer state transitions, stale revision suppression, and refresh retention;
- vertical selector right-edge axis, keyboard/semantics, and normalized sync;
- breakpoint transitions at 600/601/1024/1025 and 200% text.

### Viewer package tests

- two controller/widget instances use isolated channels;
- native callback and command round-trip for Android/iOS;
- normalized position clamping/echo suppression;
- Dart renderer archive parsing, language fallback, transforms, alpha,
  preview-mode filtering, and malformed/missing assets;
- typed unsupported state rather than diagnostic widget text.

### Windows verification

- Flutter editor is the only top-level window;
- child WPF viewer loads, resizes, handles DPI, hides before Editor returns,
  restores focus, and disposes without orphan HWND/thread;
- missing .NET/runtime/payload produces Viewer error while Editor stays usable.

### Visual verification sizes

Verify against the approved HTML reference at `1440×920`, `1240×864`, and
`400×844`, plus boundary widths and phone landscape. These are test viewports,
not breakpoint replacements.

## Acceptance Traceability

| Requirements | Specification areas |
|---|---|
| 1, 6, 7 | Responsive composition, state model |
| 2, 8 | Viewer contract, preview snapshot, platform backends, states |
| 3, 4, 9, 10 | Properties IA, numeric control, data preservation |
| 5, 16 | Numeric transactions and validation |
| 11, 12 | Dynamic languages |
| 13–15 | New Document dialog and scroll fallback |
| 17 | Viewer review-only composition |
| 18 | Layer visibility |
| 19, 20 | Position selector and normalized axis contract |

## Explicit Non-Changes

- No horizontal renderer or bottom selector.
- No enabled Landscape target.
- No new animation type or changed interpolation math.
- No Properties or selection handles inside Viewer.
- No tablet/desktop bottom navigation.
- No new document schema migration just to store current defaults.
- No physical language deletion/reordering.
- No separate WPF editor window.
- No implementation work begins before this specification and the subsequent
  implementation plan receive explicit approval.

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-08-05
- [x] Notes: Explicitly approved in conversation.
