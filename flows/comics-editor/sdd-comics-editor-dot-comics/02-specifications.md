# Specifications: Automatic `.comics` File Association

> Version: 1.0  
> Status: APPROVED  
> Last Updated: 2026-08-05  
> Requirements: [01-requirements.md](./01-requirements.md)

## Overview

Comics Editor will register the dedicated `.comics` document type on Android,
iOS/iPadOS, macOS, Windows, and Linux. Every operating-system launch mechanism
will end at a single Dart `DocumentOpenCoordinator`, which validates and
serializes requests before delegating document parsing and editor mutation to
the existing `EditorController.openPath` method.

The implementation uses Flutter entrypoint arguments for Windows and Linux and
a small application-owned method channel for Android and Apple lifecycle
callbacks. Android content URIs and Apple external/security-scoped URLs are
copied byte-for-byte into an application-private file ending in `.comics`
before their paths cross into Dart. No third-party deep-link or file-association
package is introduced.

## Current-State Findings

- `apps/comics-editor/lib/main.dart` currently has a zero-argument `main()` and
  constructs `EditorController` inside `ComicsEditorApp`.
- `EditorController.openPath(String)` is the authoritative load operation. It
  already catches loader exceptions, sets `coreError`, notifies listeners, and
  returns `false` on failure.
- Android has a broad `*/*` view filter for `.comics` and `.puzzle`, but
  `MainActivity` does not deliver either the initial intent or `onNewIntent` to
  Dart.
- iOS declares both document types and uses the iOS 13 scene lifecycle, but its
  empty `SceneDelegate` does not consume cold- or warm-launch document URLs.
- macOS has sandbox user-selected read/write entitlement but no document type
  declaration and no `application(_:openFiles:)` handling.
- The Windows runner already forwards Unicode command-line arguments to the
  Dart entrypoint.
- The Linux runner already forwards command-line arguments to Dart and is
  configured `G_APPLICATION_NON_UNIQUE`; it has no MIME package or desktop
  entry.
- There is no repository-owned Windows or Linux installer today. This flow
  therefore supplies per-user registration/install helpers and package-ready
  metadata without adding release publication.

## Affected Systems

| System | Impact | Responsibility |
|---|---|---|
| Dart application entrypoint | Modify | Accept native desktop arguments and pass them into the app. |
| Dart document-open coordinator | Create | Normalize, validate, queue, and serialize all external open requests. |
| `EditorController` | Modify | Expose a narrow method for transport/validation errors that uses the existing `coreError` state. |
| Android manifest | Modify | Advertise only the dedicated Comics MIME type. |
| Android `MainActivity` | Modify | Copy accepted URIs and queue cold/warm requests for Dart. |
| iOS Info.plist | Modify | Restrict the flow's document declaration to the Comics UTI. |
| iOS app/scene delegates | Modify | Receive cold/warm document URLs, make private copies, and queue them. |
| macOS Info.plist | Modify | Export and advertise the Comics UTI. |
| macOS app/window delegates | Modify | Receive Finder opens, make private copies, and expose the queue channel. |
| Windows registration metadata | Create | Define per-user ProgID, OpenWith, capabilities, icon, and quoted command. |
| Linux MIME/desktop metadata | Create | Define MIME glob and a `%f` desktop action. |
| Windows/Linux install helpers | Create | Install/remove association metadata for the current user without elevation. |
| Tests | Create/modify | Cover coordinator ordering, filtering, failure behavior, and native contracts. |

## Architecture

### Component Diagram

```text
Android VIEW intent ─┐
iOS scene URL ───────┼─> native private-copy/queue ─> MethodChannel ─┐
macOS openFiles ─────┘                                               │
                                                                    v
Windows argv ───────────────────────────────────────────────> DocumentOpenCoordinator
Linux argv ─────────────────────────────────────────────────>   │
                                                                │ serialized
                                                                v
                                                    EditorController.openPath
                                                                │
                                                                v
                                                   existing core + editor state
```

### Design Invariants

1. Only `EditorController.openPath` parses or activates a document.
2. A native request is removed from its pending queue only when Dart drains it.
3. Native notifications are advisory; Dart always drains the queue during
   initialization, so a notification sent before the handler exists cannot
   lose a cold-start request.
4. Dart processes requests sequentially. Concurrent opens must never race to
   replace `coreDoc`, `doc`, selection, or viewport state.
5. Transport validation is case-insensitive for the final `.comics` extension.
   Archive validity remains the core loader's responsibility.
6. This feature neither writes association defaults nor parses `.puzzle`.

## Dart Interfaces

### `DocumentOpenCoordinator`

Create `apps/comics-editor/lib/src/document_open/document_open_coordinator.dart`:

```dart
typedef DocumentPathOpener = Future<bool> Function(String path);
typedef OpenErrorReporter = void Function(String message);

abstract interface class PendingDocumentSource {
  Future<List<PendingDocument>> takePendingDocuments();
  void setDocumentsAvailableHandler(Future<void> Function() handler);
  void dispose();
}

final class PendingDocument {
  const PendingDocument.path(this.path) : error = null;
  const PendingDocument.error(this.error) : path = null;

  final String? path;
  final String? error;
}

final class DocumentOpenCoordinator {
  DocumentOpenCoordinator({
    required DocumentPathOpener openPath,
    required OpenErrorReporter reportError,
    required PendingDocumentSource nativeSource,
  });

  Future<void> start(List<String> entrypointArguments);
  Future<void> drainNativeQueue();
  Future<void> enqueuePaths(Iterable<String> paths);
  Future<void> dispose();
}
```

Behavior:

- `start` installs the native notification handler first, enqueues eligible
  desktop arguments, and drains the native queue.
- Only arguments whose final path component ends in `.comics`, ignoring case,
  are treated as documents. Flutter/tool flags and unrelated values are ignored.
- Each path is converted to an absolute path where possible, checked for an
  existing readable regular file, then passed to `openPath`.
- Entries already returned by a single native drain are processed once and in
  delivery order. The coordinator does not permanently deduplicate paths: a
  later deliberate request for the same document is valid.
- All public enqueue/drain operations append to one Future chain. One failed
  request reports its error and the chain continues with the next request.
- If several documents arrive in one event, they open sequentially and the last
  successfully opened document becomes active.
- `dispose` removes the channel handler and prevents queued work from touching
  a disposed controller.

### Controller Integration

Add this narrow method to `EditorController`:

```dart
void reportExternalOpenError(String message) {
  coreError = message;
  notifyListeners();
}
```

The method is only for errors that happen before `openPath`, such as an
unreadable URI or failed private copy. Loader errors continue to be produced by
`openPath` itself.

### App Lifecycle

- Change the entrypoint to `Future<void> main(List<String> args)`.
- `ComicsEditorApp` accepts an immutable `initialArguments` list.
- `_ComicsEditorAppState` owns both the controller and coordinator.
- `initState` starts the coordinator without blocking the first Flutter frame.
- `dispose` disposes the coordinator before the controller.
- A normal launch passes an empty list and preserves current welcome/editor
  behavior.

## Native Queue Channel

### Contract

Channel name:

```text
net.nativemind.comics_editor/document_open
```

Native method callable by Dart:

| Method | Result |
|---|---|
| `takePendingDocuments` | A list of maps. Each map contains exactly one of `path` or `error`. Reading atomically clears those entries. |

Dart method callable by native:

| Method | Arguments | Meaning |
|---|---|---|
| `documentsAvailable` | none | Advisory signal telling Dart to drain the native queue. |

Rules:

- Queue access occurs on each platform's UI/main thread.
- Native code enqueues before invoking `documentsAvailable`.
- A missing channel or failed notification does not clear the queue.
- All copied filenames end in `.comics`; a UUID prevents collisions.
- Error strings are user-readable summaries and must not include document
  contents.

## Platform Specifications

### Android

#### Registration

Replace the current broad mixed filter with a Comics-only `ACTION_VIEW` filter:

- schemes: `content` and `file`;
- category: `DEFAULT` (and `BROWSABLE` only if required by verified Android
  behavior; file-manager opens do not depend on browser deep links);
- MIME: `application/vnd.nativemind.comics`;
- do not use `*/*`, `application/zip`, or `application/octet-stream` because
  they claim unrelated files;
- do not add `.puzzle` to the new filter.

Android content-provider routing is MIME-based, not a dependable filename
extension filter. Therefore AC-1's "compatible provider" means a provider that
reports `application/vnd.nativemind.comics` for `.comics` content. Providers
that report only a generic MIME type may require the user to choose the file
through the existing in-app Open picker; broadening the association is not an
acceptable workaround.

#### Delivery

`MainActivity` will:

1. create the method channel in `configureFlutterEngine`;
2. inspect the launch intent after engine configuration;
3. override `onNewIntent`, call `setIntent(intent)`, and inspect the new intent;
4. accept only `ACTION_VIEW` with a `content` or `file` URI and a `.comics`
   display name/path;
5. use `ContentResolver.openInputStream` for content URIs and ordinary file IO
   for file URIs;
6. copy bytes to `<cacheDir>/incoming-comics/<uuid>.comics` using a temporary
   `.part` file followed by an atomic rename where supported;
7. enqueue the private path or a transport error and notify Dart.

The copy closes all streams and does not depend on persistable URI permission.
Stale private copies older than seven days may be pruned at startup; current
pending files are excluded. Mobile save behavior already redirects an implicit
Save to `DocumentsStore`, so opening a private copy will not overwrite a cloud
provider source.

### iOS and iPadOS

#### Registration

- Keep/export UTI `net.nativemind.comics`, conforming to `public.data` and
  `public.archive`, with filename extension `comics`.
- `CFBundleDocumentTypes` lists the Comics UTI as an importable document type.
- Remove `.puzzle` from the document-type entry touched by this flow; existing
  in-app `.puzzle` Open behavior remains unchanged.
- Keep `LSSupportsOpeningDocumentsInPlace`; the implementation nevertheless
  makes a private copy because write-back to an external provider is out of
  scope.

#### Delivery

- `SceneDelegate.scene(_:willConnectTo:options:)` consumes
  `connectionOptions.urlContexts` for cold launch and still calls `super`.
- `SceneDelegate.scene(_:openURLContexts:)` consumes warm requests and still
  calls `super` so Flutter/plugin lifecycle forwarding remains intact.
- A shared application broker owns the pending queue. The app delegate creates
  the method channel from the implicit engine bridge's application registrar.
- For each file URL, native code calls `startAccessingSecurityScopedResource`,
  coordinates reading with `NSFileCoordinator`, copies to
  `<Caches>/incoming-comics/<uuid>.comics`, and balances access with
  `stopAccessingSecurityScopedResource` when access was granted.
- Non-file URLs and non-`.comics` filenames produce a queued error rather than
  being passed to Dart.

### macOS

#### Registration

- Add the same exported UTI `net.nativemind.comics` and a Comics-only
  `CFBundleDocumentTypes` entry to the signed app bundle.
- Use `LSHandlerRank=Alternate`. This advertises capability without claiming
  ownership over a user's explicit default application.
- Preserve the current app-sandbox and user-selected read/write entitlements.

#### Delivery

- Override `AppDelegate.application(_:openFiles:)` for cold and warm Finder
  delivery and reply through `NSApplication.reply(toOpenOrPrint:)`.
- A shared broker queues requests before a Flutter window/channel exists.
- `MainFlutterWindow.awakeFromNib` creates the method channel using its
  `FlutterViewController.engine.binaryMessenger` and attaches it to the broker.
- Each external URL is security-scoped/coordinated and copied to the app's
  caches directory using the same atomic private-copy rule as iOS.
- The app acknowledges success to AppKit when at least one eligible request was
  queued; otherwise it reports failure and queues a readable transport error.
- Warm requests activate the existing window; no additional window is created.

### Windows

#### Launch Delivery

No C++ channel is required. The existing runner uses
`GetCommandLineArguments()` and `set_dart_entrypoint_arguments`, which preserves
Unicode arguments and argument boundaries. The Dart coordinator consumes the
quoted `%1` path.

#### Per-user Registration

Use ProgID `NativeMind.ComicsEditor.comics` and install these current-user
registry entries:

```text
HKCU\Software\Classes\.comics\OpenWithProgids
  NativeMind.ComicsEditor.comics = ""

HKCU\Software\Classes\NativeMind.ComicsEditor.comics
  (Default) = "Comics Document"
  DefaultIcon\(Default) = "<absolute-exe-path>,0"
  shell\open\command\(Default) = "\"<absolute-exe-path>\" \"%1\""

HKCU\Software\NativeMind\ComicsEditor\Capabilities
  ApplicationName = "Comics Editor"
  ApplicationDescription = "Create and edit Comics documents"
  FileAssociations\.comics = "NativeMind.ComicsEditor.comics"

HKCU\Software\RegisteredApplications
  Comics Editor = "Software\NativeMind\ComicsEditor\Capabilities"
```

A repository-owned PowerShell registration helper accepts the absolute installed
executable path, writes only these keys, and notifies the shell that associations
changed. Its uninstall counterpart removes only values/keys owned by this app
and never writes the `.comics` default value or `UserChoice`. Neither helper
requires administrator rights. An eventual installer may call these helpers,
but installer creation/publication is not part of this flow.

### Linux

#### Metadata

Provide package-ready files using the stable application ID
`net.nativemind.comics.editor`:

`net.nativemind.comics.editor.xml`:

```xml
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/vnd.nativemind.comics">
    <comment>Comics Document</comment>
    <glob pattern="*.comics"/>
  </mime-type>
</mime-info>
```

`net.nativemind.comics.editor.desktop` contains at minimum:

```ini
[Desktop Entry]
Type=Application
Name=Comics Editor
Exec=comics_editor %f
Icon=net.nativemind.comics.editor
Terminal=false
MimeType=application/vnd.nativemind.comics;
Categories=Graphics;
StartupWMClass=net.nativemind.comics.editor
```

Update CMake `APPLICATION_ID` from the template value
`com.example.comics_editor` to `net.nativemind.comics.editor`.

#### Per-user Installation

A repository-owned install helper places the desktop file under
`${XDG_DATA_HOME:-$HOME/.local/share}/applications` and the MIME package under
`${XDG_DATA_HOME:-$HOME/.local/share}/mime/packages`, substitutes the installed
executable's absolute path into `Exec`, and invokes
`update-mime-database`/`update-desktop-database` when available. It registers
the app as a candidate only; it does not call `xdg-mime default`.

The uninstall helper removes only those two app-owned files and refreshes the
caches when the tools exist. Packaging systems may install equivalent files
under `/usr/share`; system-package creation is out of scope.

## Data and Persistence

- No `.comics` schema or editor data-model changes occur.
- The native pending queue is process-memory only.
- Android/iOS/macOS private copies live below application cache storage, retain
  the complete source bytes, and always use `.comics` suffixes.
- A failed partial copy is deleted. Completed private copies are retained for
  the active session and can be pruned when older than seven days.
- Native queues contain only a private path or error message, never raw bytes.
- Windows/Linux paths are not copied and retain their original absolute path.

## Detailed Behavior

### Cold Start

1. The OS chooses Comics Editor through its registered document capability.
2. Native startup captures the document before or while Flutter initializes.
3. Android/Apple native code copies and queues the document; Windows/Linux pass
   it as one entrypoint argument.
4. Flutter renders normally while the coordinator begins draining.
5. The coordinator validates the local path and awaits `openPath`.
6. On success, the existing controller resets workspace/selection/viewport and
   exposes the loaded document.

### Warm Delivery

1. Android `onNewIntent`, iOS scene open, or macOS `openFiles` receives the new
   request.
2. Native code completes its private copy before enqueueing.
3. The advisory channel notification triggers a drain.
4. The coordinator waits for any current open to finish, then calls `openPath`
   exactly once for the dequeued entry.

Windows and Linux may start a separate process per the approved non-goal; each
new process follows the cold-start path.

### Edge Cases

| Case | Expected behavior |
|---|---|
| No document argument | App starts exactly as it does today. |
| Path contains spaces/non-ASCII | Argument boundaries and native strings are preserved; exact file bytes load. |
| Uppercase `.COMICS` | Accepted after case-insensitive extension validation. |
| Missing/unreadable desktop path | Coordinator reports `coreError`; app remains usable. |
| Invalid archive with valid extension | `openPath` returns false and exposes the existing core error. |
| Android generic MIME only | App is not broadly advertised; user can use in-app Open. |
| Android URI has no `.comics` display name | Rejected and reported, even if MIME was delivered accidentally. |
| Apple security scope denied | Coordinated copy is attempted if readable; otherwise a transport error is reported. |
| Notification arrives before Dart handler | Queue remains intact and is drained by coordinator startup. |
| Two warm requests arrive quickly | Private copies queue in arrival order and opens execute serially. |
| Same path opened later again | Treated as a new explicit request. |
| Native partial copy | `.part` file is removed and no path entry is queued. |
| `.puzzle` sent externally | Ignored/rejected by this flow; in-app `.puzzle` Open remains available. |

## Error Handling

| Layer | Failure | Response |
|---|---|---|
| Registration | Metadata absent/not installed | App remains functional; manual verification fails clearly. |
| Native input | Wrong scheme/type/extension | Queue a concise error or reject without invoking the parser. |
| Native copy | Permission, I/O, or storage failure | Remove partial output and queue an error. |
| Channel | Flutter handler unavailable | Retain queue for the next Dart drain. |
| Dart validation | Missing, directory, or unreadable path | Call `reportExternalOpenError`; continue queue. |
| Core loading | Malformed/unsupported archive | Existing `openPath` error behavior; continue queue. |

The app must never replace a successfully active document with an empty document
after an external-open failure.

## Testing Strategy

### Dart Unit and Widget Tests

- Coordinator filters non-`.comics` arguments and accepts case variants.
- Paths containing spaces and non-ASCII characters arrive unchanged.
- Initial arguments and native entries converge on the same opener callback.
- Multiple opens are serialized in arrival order.
- One failed open does not prevent the next queued open.
- A repeated path in a later event opens again.
- Native transport errors use `reportExternalOpenError` and do not call
  `openPath`.
- Disposing the app removes the method handler and does not use a disposed
  controller.
- A normal zero-argument app launch preserves existing widget behavior.

### Native/Metadata Contract Tests

- Android manifest contains the dedicated MIME and no broad `*/*` association.
- Android JVM/Robolectric or extracted helper tests verify URI filtering,
  private-copy suffix, and initial/warm queue behavior where the toolchain
  permits.
- Plist tests verify one Comics UTI on iOS/macOS and no new Puzzle association.
- Swift helper tests, where runnable, verify copy validation and consume-once
  queue semantics.
- Windows script tests target a temporary registry test subtree or validate the
  generated entries without changing the user's live association.
- Linux metadata passes `desktop-file-validate` and MIME XML validation when
  those tools are installed.

### Build Verification

- `flutter analyze`.
- Relevant Dart tests, followed by the full Flutter test suite.
- Android debug build.
- iOS simulator compile/build.
- macOS build and available runner tests.
- Windows and Linux builds in their supported host/CI environments; when the
  current macOS host cannot execute them, record the limitation rather than
  claiming runtime verification.

### Manual Acceptance Matrix

For every available platform:

1. Install/register the built app using normal platform mechanisms.
2. Verify Comics Editor appears for `valid name 漫画.comics`.
3. Cold-open the file and compare loaded content with in-app Open.
4. On Android/iOS/macOS, open another document while the app runs and verify it
   becomes active once.
5. Try missing and malformed files and verify a visible existing error state
   with no crash.
6. Confirm a pre-existing explicit default app is not overwritten.
7. Confirm an unrelated ZIP/archive is not advertised as a Comics document.

## Security and Privacy

- No external file contents are logged or sent over the network.
- Private copies use application-private cache directories and collision-safe
  names.
- File handles and Apple security-scope access are held for the shortest copy
  interval and always released.
- Registration helpers are scoped to the current user and app-owned entries.
- Executable and document paths are quoted independently in Windows commands;
  Linux desktop `Exec` uses one `%f` field code.

## Rollout and Compatibility

- There is no application-data migration.
- Removing the feature consists of removing registration metadata/keys and the
  native delivery code; existing `.comics` documents are untouched.
- Existing users may need to choose Comics Editor once through their operating
  system if another default already exists.
- Existing in-app New/Open/Save, including `.puzzle`, is preserved.

## Requirements Traceability

| Requirement | Specification coverage |
|---|---|
| FR-1, FR-2 | Platform registration sections and non-defaulting install rules. |
| FR-3 | Cold-start flow and entrypoint/native queue integration. |
| FR-4 | Warm native callbacks and serialized queue; desktop separate-process rule. |
| FR-5 | Native private copy, Unicode argv, security-scope handling. |
| FR-6 | Validation, error table, and unchanged active-document rule. |
| FR-7 | `DocumentOpenCoordinator` to `EditorController.openPath`. |
| FR-8 | Empty launch behavior, `.puzzle` exclusion, regression tests. |
| FR-9 | Bundle metadata and per-user Windows/Linux registration helpers. |
| AC-1–AC-9 | Manual matrix plus Dart/native/build test sections. |

## Open Design Questions

None. Exact filenames and task ordering will be enumerated in the implementation
plan after specification approval.

## Approval

- [x] Reviewed by the user.
- [x] Approved on: 2026-08-05.
- [x] Notes: `specs approved`.
