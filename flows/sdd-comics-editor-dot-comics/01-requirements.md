# Requirements: Automatic `.comics` File Association

> Version: 1.0  
> Status: APPROVED  
> Last Updated: 2026-08-05

## Problem Statement

Comics Editor can open a document through its own **Open** command, but an installed application does not yet provide a complete cross-platform contract for opening `.comics` files from the operating system. Android and iOS already contain partial file-type declarations, but the selected document is not delivered to `EditorController.openPath`. macOS, Windows, and Linux do not yet have complete registration metadata and launch handling.

Users should be able to select or double-click a `.comics` document in the platform file manager and have Comics Editor open that document automatically, with behavior that feels native to each supported operating system.

## Scope

### Supported application targets

- Android phones and tablets.
- iPhone and iPad.
- macOS desktop.
- Windows desktop using the Flutter application and its native Windows runner.
- Linux desktop environments that support freedesktop MIME and `.desktop` registration.

The repository currently has no Flutter web target. Browser file handling is therefore outside this flow; it can be specified separately if a web application is added.

## User Stories

### Primary

**As a** Comics Editor user  
**I want** the installed application to be offered for `.comics` documents  
**So that** I can open a comic directly from Files, Finder, Explorer, or my Linux file manager.

**As a** user opening a `.comics` document  
**I want** the selected document to become the active editor document  
**So that** opening it from the operating system behaves like the existing in-app **Open** action.

### Secondary

**As a** user who has chosen another default application  
**I want** Comics Editor to respect that operating-system preference  
**So that** installing or launching Comics Editor does not silently take over my files.

**As a** user opening a document through a mobile content provider  
**I want** Comics Editor to retain reliable access to the selected data  
**So that** cloud-backed and shared `.comics` documents open just like local files.

## Functional Requirements

### FR-1 — File type declaration

Each supported platform must declare Comics Editor as an application capable of opening the `.comics` extension. The declaration must use a Comics-specific document type/MIME identifier where the platform supports one and must not claim unrelated archive or binary files.

### FR-2 — Respect operating-system ownership

Registration must make Comics Editor available as an opener and may make it the default only through normal operating-system installation/default-app rules. The application must not overwrite an explicit user choice or bypass Windows, Apple, Android, or desktop-environment consent mechanisms.

### FR-3 — Cold-start opening

When Comics Editor is not running and is launched with one `.comics` document, it must initialize normally and open that document through the same controller behavior used by the in-app **Open** command.

### FR-4 — Already-running application

Where the operating system delivers a second open request to the running process (Android, iOS/iPadOS, and macOS), Comics Editor must handle it without requiring an application restart. Desktop systems that launch a separate process may open the document in that new process unless a later single-instance feature defines different behavior.

### FR-5 — URI and sandbox handling

- Android `content://` and `file://` inputs must be accepted when provided by the operating system.
- Apple security-scoped or externally provided document URLs must be handled without relying on permanent unrestricted access to the source URL.
- Desktop command-line paths may be absolute or platform-native paths and may contain spaces or non-ASCII characters.
- Any temporary/private copy must preserve the complete bytes of the source and use a `.comics` filename.

### FR-6 — Validation and failure behavior

Only `.comics` documents belong to this association flow. A missing, unreadable, unsupported, or malformed document must leave the application usable and surface the existing editor error state instead of crashing or presenting an empty document as successfully loaded.

### FR-7 — One authoritative Dart entry point

All platform launch mechanisms must converge on one Dart-side document-open coordinator, which delegates actual parsing and editor state changes to `EditorController.openPath`. Platform runners must not implement a separate `.comics` parser.

### FR-8 — Existing in-app workflows remain intact

The existing **New**, **Open**, save, editor, properties, Scene, and Viewer behavior must remain unchanged when the application is launched normally. This flow must not add `.puzzle` association behavior or redesign the editor UI.

### FR-9 — Installed-package integration

- macOS/iOS declarations must be included in the signed application bundle.
- Windows registration must be available to a per-user installation or packaged application without requiring administrator rights merely to open `.comics` files.
- Linux builds must ship MIME and desktop-entry metadata suitable for installation and MIME database discovery.
- Android declarations must be part of the release manifest and work with common document providers.

## Acceptance Criteria

### AC-1 — Android cold start

**Given** Comics Editor is installed and not running  
**When** the user opens a `.comics` document from a compatible Android document provider  
**Then** Comics Editor is offered as an opener, launches, and loads that document.

### AC-2 — Android warm delivery

**Given** Comics Editor is already running  
**When** Android delivers another `.comics` view intent  
**Then** the running activity receives the request and loads the selected document once.

### AC-3 — iPhone and iPad

**Given** a `.comics` document is visible in Files or a share source  
**When** the user chooses Comics Editor  
**Then** the app opens the document on cold or warm launch, including through the configured scene lifecycle.

### AC-4 — macOS

**Given** Comics Editor is installed in an application location known to Launch Services  
**When** the user chooses it for or double-clicks a `.comics` document  
**Then** Finder identifies the document type and the app loads the requested file whether it was stopped or already running.

### AC-5 — Windows

**Given** Comics Editor is installed or registered for the current user  
**When** the user chooses Comics Editor for a `.comics` document and opens it in Explorer  
**Then** Windows invokes the Flutter executable with the document path and that process loads the file; an existing explicit Windows default-app choice is not forcibly replaced.

### AC-6 — Linux

**Given** the packaged desktop metadata has been installed and MIME caches updated by the package/install process  
**When** the user opens a `.comics` document in a compliant file manager  
**Then** Comics Editor is listed for the dedicated Comics MIME type and loads the selected path.

### AC-7 — Path fidelity

**Given** a valid `.comics` filename contains spaces or non-ASCII characters  
**When** it is opened from any supported platform  
**Then** the exact intended document bytes reach the existing editor loader and load successfully.

### AC-8 — Invalid input safety

**Given** the operating system sends a missing, unreadable, or invalid `.comics` document  
**When** Comics Editor handles the request  
**Then** the app remains responsive, does not crash, and exposes the load failure through existing error handling.

### AC-9 — Regression safety

**Given** Comics Editor is launched without a document  
**When** startup completes  
**Then** the current welcome/editor behavior and all existing tests remain valid.

## Constraints

- Preserve the existing `.comics` archive format and `EditorController.openPath` behavior.
- Preserve all unrelated uncommitted work in the editor repository.
- Use platform-native registration mechanisms; do not introduce a third-party deep-link package unless specifications prove it necessary.
- Do not require elevated privileges for normal per-user Windows registration.
- Do not force a default application where the operating system reserves that decision for the user.
- Keep platform channels limited to resolving/delivering a local readable document; parsing stays in Dart/editor core.

## Non-Goals

- `.puzzle` file association.
- A new web build or browser PWA file-handler manifest.
- Single-instance process coordination for Windows or Linux.
- Changing the `.comics` schema, migration rules, renderer, or editor layout.
- Publishing, signing, notarizing, store submission, or changing a user's current system-wide default application.
- Editing a document in place in external/cloud storage; this flow guarantees opening, not write-back permissions to the original provider URL.

## Open Questions

None required for the requirements phase. The platform-specific registration and lifecycle mechanisms, including the exact Windows per-user registration location and Linux install destinations, will be selected in specifications.

## Approval

- Approved by the user on 2026-08-05.
