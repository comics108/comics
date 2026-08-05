# Implementation Plan: Automatic `.comics` File Association

> Version: 1.0  
> Status: APPROVED  
> Last Updated: 2026-08-05  
> Specifications: [02-specifications.md](./02-specifications.md) (APPROVED)

## Summary

Implementation proceeds from the shared, host-testable Dart contract outward.
First, tests establish queue ordering, argument filtering, and failure behavior;
then the coordinator is wired into the existing app. Android, iOS, and macOS
are added as independent native producers of the same consume-once channel.
Windows and Linux registration metadata come after document delivery works,
because their runners already forward entrypoint arguments. The final phase
adds CI-visible metadata checks and executes all build gates available on the
current host.

Application source changes begin only after explicit `plan approved` approval.
Implementation will follow the repository SDD rule of introducing and running
one focused test/check at a time, recording each completed checkpoint and any
deviation in `04-implementation-log.md`.

## Scope Guardrails

- Modify only `apps/comics-editor` and this flow's artifacts.
- Preserve all unrelated dirty/untracked work in the shared worktree.
- Do not alter the `.comics` archive schema or implement a second parser.
- Do not add `.puzzle`, browser/PWA, Windows/Linux single-instance, publishing,
  signing, notarization, or forced-default behavior.
- Do not introduce a third-party deep-link/file-association dependency.
- Do not execute registration/unregistration helpers against the user's live OS
  during automated verification.

## Task Breakdown

### Phase 0: Baseline and Implementation Log

#### Task 0.1 — Capture the baseline

- **Description**: Re-read the approved requirements/specifications, record the
  initial dirty-worktree state, and run the smallest existing regression set
  before editing application code. Create the implementation log from the SDD
  template with the approved plan task IDs.
- **Files**:
  - `flows/sdd-comics-editor-dot-comics/04-implementation-log.md` — Create.
  - `flows/sdd-comics-editor-dot-comics/_status.md` — Modify.
- **Dependencies**: Plan approval.
- **Verification**:
  - `flutter test test/widget_test.dart test/dart_io_core_test.dart` passes.
  - Baseline failures, if any, are recorded before feature edits.
- **Complexity**: Low.
- **Rollback**: Remove only the new implementation log/status entries.

### Phase 1: Shared Dart Open Pipeline

#### Task 1.1 — Add coordinator contract tests

- **Description**: Add focused tests using a fake native source and fake opener.
  Establish filtering, case-insensitive `.comics`, path fidelity, sequential
  ordering, repeated later opens, transport errors, continuation after failure,
  cold-start drain, notification drain, and disposal semantics. Each behavior
  is added and run individually before the next is introduced.
- **Files**:
  - `apps/comics-editor/test/document_open_coordinator_test.dart` — Create.
- **Dependencies**: Task 0.1.
- **Verification**: The new tests initially fail for the missing contract in the
  expected way; unrelated existing tests remain green.
- **Complexity**: Medium.
- **Rollback**: Remove the isolated test file.

#### Task 1.2 — Implement the coordinator and channel adapter

- **Description**: Implement `PendingDocument`, `PendingDocumentSource`, the
  production method-channel adapter, and `DocumentOpenCoordinator`. Install the
  Dart handler before the initial native drain, serialize every request through
  one Future chain, accept only readable regular `.comics` files, ignore
  unrelated desktop arguments, and continue after failures. Use channel
  `net.nativemind.comics_editor/document_open` with
  `takePendingDocuments`/`documentsAvailable` exactly as specified.
- **Files**:
  - `apps/comics-editor/lib/src/document_open/document_open_coordinator.dart` — Create.
- **Dependencies**: Task 1.1.
- **Verification**:
  - Run `flutter test test/document_open_coordinator_test.dart` after each
    newly satisfied behavior.
  - `flutter analyze` has no new diagnostics.
- **Complexity**: Medium.
- **Rollback**: Remove the new Dart module; no existing app behavior changes yet.

#### Task 1.3 — Add controller transport-error seam

- **Description**: Add `reportExternalOpenError(String)` to set the existing
  `coreError` and notify listeners. Add one test proving it reports without
  clearing/replacing an already active document.
- **Files**:
  - `apps/comics-editor/lib/src/ui/controller.dart` — Modify.
  - `apps/comics-editor/test/document_open_coordinator_test.dart` — Modify, or
    `test/controller_image_bytes_test.dart` — Modify if that fixture is the
    smaller focused home for the active-document invariant.
- **Dependencies**: Task 1.2.
- **Verification**: Focused controller/coordinator test passes.
- **Complexity**: Low.
- **Rollback**: Remove the narrow method and its test only.

#### Task 1.4 — Wire entrypoint and app lifecycle

- **Description**: Change `main` to accept `List<String> args`; make
  `ComicsEditorApp` accept immutable initial arguments; let app state own the
  controller and coordinator; start after handler installation without blocking
  the first frame; dispose coordinator before controller. Preserve the existing
  const zero-argument constructor for tests/normal launches where possible.
- **Files**:
  - `apps/comics-editor/lib/main.dart` — Modify.
  - `apps/comics-editor/test/widget_test.dart` — Modify.
- **Dependencies**: Tasks 1.2–1.3.
- **Verification**:
  - Existing zero-argument widget smoke remains green.
  - Add a widget-level test proving normal launch remains on current behavior.
  - `flutter test test/document_open_coordinator_test.dart test/widget_test.dart`.
- **Complexity**: Medium.
- **Rollback**: Restore the prior entrypoint/app ownership; coordinator remains
  isolated and unused.

#### Phase 1 Checkpoint

- `flutter analyze` passes.
- Focused coordinator and widget tests pass.
- A host invocation with a temporary valid `.comics` path reaches the existing
  opener in a test; no native runner changes are needed for this checkpoint.

### Phase 2: Android Registration and Delivery

#### Task 2.1 — Add pure queue/filter tests

- **Description**: Introduce JVM unit tests for consume-once queue order,
  `.comics` display-name filtering, and error entries. Keep Android framework IO
  outside the pure broker so these tests do not require a device or Robolectric.
- **Files**:
  - `apps/comics-editor/android/app/src/test/kotlin/net/nativemind/comics/editor/DocumentOpenBrokerTest.kt` — Create.
  - `apps/comics-editor/android/app/build.gradle.kts` — Modify only if a Kotlin/JUnit
    test dependency is not already supplied by the project toolchain.
- **Dependencies**: Phase 1 checkpoint.
- **Verification**: `./gradlew testDebugUnitTest` runs the new tests; expected
  missing-class failure occurs before implementation.
- **Complexity**: Low.
- **Rollback**: Remove test and any isolated test dependency.

#### Task 2.2 — Implement Android broker and private copier

- **Description**: Add a synchronized in-memory broker and URI copier. The copier
  resolves the content display name, accepts only `.comics`, streams to a UUID
  `.part` in `cacheDir/incoming-comics`, renames to `.comics`, closes streams,
  deletes partials on failure, and can prune completed files older than seven
  days while excluding pending entries.
- **Files**:
  - `apps/comics-editor/android/app/src/main/kotlin/net/nativemind/comics/editor/DocumentOpenBroker.kt` — Create.
  - `apps/comics-editor/android/app/src/main/kotlin/net/nativemind/comics/editor/IncomingDocumentCopier.kt` — Create.
- **Dependencies**: Task 2.1.
- **Verification**:
  - `./gradlew testDebugUnitTest` passes after each broker behavior.
  - Kotlin compile is clean through the Android build task.
- **Complexity**: Medium.
- **Rollback**: Remove the two unused native helpers.

#### Task 2.3 — Connect `MainActivity` cold/warm lifecycle

- **Description**: Configure the channel in `configureFlutterEngine`, implement
  atomic `takePendingDocuments`, inspect the launch intent once, override
  `onNewIntent` with `setIntent`, enqueue before notification, and retain entries
  when the Dart handler is absent. Guard against processing the identical launch
  intent twice during initial setup.
- **Files**:
  - `apps/comics-editor/android/app/src/main/kotlin/net/nativemind/comics/editor/MainActivity.kt` — Modify.
- **Dependencies**: Task 2.2.
- **Verification**:
  - JVM broker tests pass.
  - `flutter build apk --debug` passes.
  - If an emulator/device is available, use `adb shell am start` for a cold and
    warm smoke request and record the exact result.
- **Complexity**: Medium.
- **Rollback**: Restore `MainActivity` to the basic Flutter activity; helpers
  become unused and can be removed independently.

#### Task 2.4 — Narrow Android association metadata

- **Description**: Replace the broad `*/*` `.comics`/`.puzzle` filter with a
  Comics-only `ACTION_VIEW` filter using
  `application/vnd.nativemind.comics` and content/file schemes. Do not advertise
  generic archives or add Puzzle association behavior.
- **Files**:
  - `apps/comics-editor/android/app/src/main/AndroidManifest.xml` — Modify.
  - `apps/comics-editor/test/file_association_metadata_test.dart` — Create with
    the first cross-platform contract assertion.
- **Dependencies**: Task 2.3.
- **Verification**:
  - Metadata test proves the dedicated MIME exists and `*/*` is absent from the
    association filter.
  - `flutter build apk --debug` passes.
- **Complexity**: Low.
- **Rollback**: Revert the one manifest filter; app continues to launch normally.

#### Phase 2 Checkpoint

- Coordinator/widget tests and Android JVM tests pass.
- Debug APK builds.
- Android source contains one native producer and no parser.

### Phase 3: Apple Registration and Delivery

#### Task 3.1 — Add iOS broker tests

- **Description**: Replace the placeholder Runner test with focused tests for
  consume-once queue order and retained entries before channel attachment. Keep
  URL coordination/copying separate from the pure broker.
- **Files**:
  - `apps/comics-editor/ios/RunnerTests/RunnerTests.swift` — Modify.
  - `apps/comics-editor/ios/Runner.xcodeproj/project.pbxproj` — Modify only for
    source/test target membership required by the new broker file.
- **Dependencies**: Phase 1 checkpoint; independent of Android.
- **Verification**: The focused Xcode test initially fails because the broker is
  missing.
- **Complexity**: Low.
- **Rollback**: Restore placeholder test/project references.

#### Task 3.2 — Implement iOS broker, copier, and channel

- **Description**: Add the shared broker and coordinated security-scoped private
  copier. Build the channel from the implicit engine bridge's application
  registrar. Queue path/error maps, clear only on Dart drain, and send advisory
  notifications only after enqueue.
- **Files**:
  - `apps/comics-editor/ios/Runner/DocumentOpenBroker.swift` — Create.
  - `apps/comics-editor/ios/Runner/AppDelegate.swift` — Modify.
  - `apps/comics-editor/ios/Runner.xcodeproj/project.pbxproj` — Modify.
- **Dependencies**: Task 3.1.
- **Verification**:
  - Run the focused RunnerTests on an available iOS simulator.
  - `flutter build ios --debug --no-codesign` passes.
- **Complexity**: Medium.
- **Rollback**: Restore app delegate/project references and remove broker file.

#### Task 3.3 — Connect iOS scene cold/warm callbacks

- **Description**: Consume cold `connectionOptions.urlContexts` and warm
  `openURLContexts`, forward lifecycle calls to `super`, reject non-file and
  non-Comics URLs, and prevent duplicate cold handling.
- **Files**:
  - `apps/comics-editor/ios/Runner/SceneDelegate.swift` — Modify.
  - `apps/comics-editor/ios/RunnerTests/RunnerTests.swift` — Modify with a
    focused filtering/queue test where lifecycle construction permits.
- **Dependencies**: Task 3.2.
- **Verification**:
  - Focused RunnerTests pass.
  - iOS no-codesign build passes.
  - Simulator Files/share cold/warm smoke is recorded when available.
- **Complexity**: Medium.
- **Rollback**: Restore empty SceneDelegate; ordinary app startup remains intact.

#### Task 3.4 — Correct iOS document metadata

- **Description**: Keep only the Comics UTI in the association declaration
  touched by this flow, preserve `LSSupportsOpeningDocumentsInPlace`, and leave
  in-app `.puzzle` support unchanged.
- **Files**:
  - `apps/comics-editor/ios/Runner/Info.plist` — Modify.
  - `apps/comics-editor/test/file_association_metadata_test.dart` — Modify.
- **Dependencies**: Task 3.3.
- **Verification**:
  - `plutil -lint ios/Runner/Info.plist` passes.
  - Metadata test finds `net.nativemind.comics`/`comics` and no Puzzle entry in
    the external association declaration.
- **Complexity**: Low.
- **Rollback**: Revert plist only; delivery code becomes dormant.

#### Task 3.5 — Add macOS broker tests and implementation

- **Description**: Add the consume-once broker/copy helper and replace the
  placeholder macOS Runner test with queue tests. Copy coordinated
  security-scoped URLs to cache with `.part` cleanup and UUID `.comics` names.
- **Files**:
  - `apps/comics-editor/macos/Runner/DocumentOpenBroker.swift` — Create.
  - `apps/comics-editor/macos/RunnerTests/RunnerTests.swift` — Modify.
  - `apps/comics-editor/macos/Runner.xcodeproj/project.pbxproj` — Modify.
- **Dependencies**: Phase 1 checkpoint; may follow Task 3.2 to reuse proven
  conceptual behavior, but no source code is shared across Apple targets.
- **Verification**: Focused macOS RunnerTests pass.
- **Complexity**: Medium.
- **Rollback**: Remove broker and restore project/test files.

#### Task 3.6 — Connect macOS AppKit lifecycle and channel

- **Description**: Handle `application(_:openFiles:)`, enqueue/copy before
  notifying, reply success/failure to AppKit, activate the existing window, and
  attach the channel from `MainFlutterWindow` while preserving generated plugin
  registration.
- **Files**:
  - `apps/comics-editor/macos/Runner/AppDelegate.swift` — Modify.
  - `apps/comics-editor/macos/Runner/MainFlutterWindow.swift` — Modify.
- **Dependencies**: Task 3.5.
- **Verification**:
  - macOS RunnerTests pass.
  - `flutter build macos --debug` passes.
  - Finder cold and warm opens of a filename with spaces/non-ASCII are manually
    checked against `samples/sample_v2026.comics` or a safe copy.
- **Complexity**: Medium.
- **Rollback**: Restore delegates/window; normal window launch is preserved.

#### Task 3.7 — Add macOS document metadata

- **Description**: Export/advertise the dedicated Comics UTI with
  `LSHandlerRank=Alternate`. Preserve sandbox entitlements unchanged.
- **Files**:
  - `apps/comics-editor/macos/Runner/Info.plist` — Modify.
  - `apps/comics-editor/test/file_association_metadata_test.dart` — Modify.
- **Dependencies**: Task 3.6.
- **Verification**:
  - `plutil -lint macos/Runner/Info.plist` passes.
  - Built app's `Contents/Info.plist` contains the type.
  - Metadata test verifies Alternate rank and no unrelated archive extension.
- **Complexity**: Low.
- **Rollback**: Revert plist; app bundle no longer advertises the type.

#### Phase 3 Checkpoint

- iOS and macOS focused native tests/builds pass where destinations exist.
- Dart metadata/coordinator/widget tests pass.
- Cold/warm manual results and unavailable device limitations are logged.

### Phase 4: Windows and Linux Installed-Package Integration

#### Task 4.1 — Add Windows registration contract tests

- **Description**: Extend the Dart metadata test to require the exact ProgID,
  HKCU-only roots, quoted executable/document arguments, OpenWith/capabilities,
  and absence of `UserChoice` writes. Tests read scripts as artifacts and do
  not touch the live registry.
- **Files**:
  - `apps/comics-editor/test/file_association_metadata_test.dart` — Modify.
- **Dependencies**: Phase 1 checkpoint.
- **Verification**: Focused metadata test fails only because scripts are absent.
- **Complexity**: Low.
- **Rollback**: Remove Windows-only assertions.

#### Task 4.2 — Create Windows per-user helpers

- **Description**: Add register/unregister PowerShell helpers for
  `NativeMind.ComicsEditor.comics`. Registration requires and validates an
  absolute executable path, writes only the specified HKCU OpenWith, ProgID,
  capabilities, and RegisteredApplications entries, quotes command arguments,
  and notifies Explorer. Unregistration removes only owned entries/values and
  leaves defaults/UserChoice untouched. Add `-WhatIf`/dry-run behavior for safe
  verification.
- **Files**:
  - `apps/comics-editor/windows/packaging/Register-ComicsFileAssociation.ps1` — Create.
  - `apps/comics-editor/windows/packaging/Unregister-ComicsFileAssociation.ps1` — Create.
  - `apps/comics-editor/windows/packaging/README.md` — Create with installer handoff and safe usage.
- **Dependencies**: Task 4.1.
- **Verification**:
  - Metadata test passes.
  - On Windows CI, PowerShell parses both scripts and runs registration in
    `-WhatIf` mode only.
  - `flutter build windows --debug` passes on a Windows host/CI.
- **Complexity**: Medium.
- **Rollback**: Remove `windows/packaging`; runner argument delivery remains.

#### Task 4.3 — Add Linux MIME/desktop contract tests

- **Description**: Extend metadata tests for application ID, dedicated MIME,
  `*.comics` glob, one `%f`, no broad archive MIME, and no default-setting
  command in install helpers.
- **Files**:
  - `apps/comics-editor/test/file_association_metadata_test.dart` — Modify.
- **Dependencies**: Phase 1 checkpoint.
- **Verification**: Focused metadata test fails only because metadata/helpers
  are absent.
- **Complexity**: Low.
- **Rollback**: Remove Linux-only assertions.

#### Task 4.4 — Create Linux metadata and per-user helpers

- **Description**: Add the freedesktop MIME XML, desktop-entry template, and
  install/uninstall helpers. Helpers resolve XDG per-user directories, validate
  the executable, substitute its absolute path safely into `Exec`, refresh
  caches only when utilities exist, and never call `xdg-mime default`. Update
  the runner application ID to `net.nativemind.comics.editor`.
- **Files**:
  - `apps/comics-editor/linux/packaging/net.nativemind.comics.editor.xml` — Create.
  - `apps/comics-editor/linux/packaging/net.nativemind.comics.editor.desktop.in` — Create.
  - `apps/comics-editor/linux/packaging/install-user.sh` — Create.
  - `apps/comics-editor/linux/packaging/uninstall-user.sh` — Create.
  - `apps/comics-editor/linux/packaging/README.md` — Create.
  - `apps/comics-editor/linux/CMakeLists.txt` — Modify application ID only.
- **Dependencies**: Task 4.3.
- **Verification**:
  - Metadata test passes.
  - `bash -n` passes for both helpers.
  - `desktop-file-validate` and MIME XML validation pass when installed.
  - Helpers are tested against a temporary `XDG_DATA_HOME`, never the user's
    actual data directory; install then uninstall leaves the temp root clean.
  - `flutter build linux --debug` passes on Linux CI/host.
- **Complexity**: Medium.
- **Rollback**: Remove packaging directory and restore the prior CMake app ID.

#### Task 4.5 — Extend CI-safe checks

- **Description**: Add the two pure Dart tests to the fast/analyze and relevant
  platform test lists. Add Windows script parse/WhatIf and Linux metadata/shell
  validation steps without installing live associations. Keep native device
  smoke tests manual.
- **Files**:
  - `apps/comics-editor/.github/workflows/build.yml` — Modify.
  - `apps/comics-editor/.github/workflows/docker-build.yml` — Modify only if its
    explicitly enumerated test set must include the new pure Dart tests.
- **Dependencies**: Tasks 1.4, 2.4, 3.4, 3.7, 4.2, 4.4.
- **Verification**:
  - YAML parses.
  - Local commands mirror CI commands.
  - No CI step writes the host's real file-association state.
- **Complexity**: Low.
- **Rollback**: Revert workflow-only changes; feature code remains testable locally.

#### Phase 4 Checkpoint

- Windows/Linux helpers pass artifact and temporary-root/dry-run tests.
- Registration metadata identifies Comics Editor as a candidate only.
- Desktop launch arguments still reach the shared Dart coordinator without
  native parser/channel duplication.

### Phase 5: Regression, Builds, and Handoff

#### Task 5.1 — Run focused tests in dependency order

- **Description**: Run each focused suite separately so a failure is attributable
  before the full suite.
- **Dependencies**: Phases 1–4.
- **Verification order**:
  1. `flutter test test/document_open_coordinator_test.dart`.
  2. `flutter test test/file_association_metadata_test.dart`.
  3. `flutter test test/widget_test.dart`.
  4. Android JVM tests.
  5. iOS/macOS RunnerTests where destinations are available.
- **Files**: Implementation log/status only.
- **Complexity**: Low.
- **Rollback**: Not applicable; diagnostic task.

#### Task 5.2 — Run analysis and full regressions

- **Description**: Format only touched Dart files, run `flutter analyze`, then
  the full Flutter suite. Do not bulk-format unrelated user work.
- **Dependencies**: Task 5.1.
- **Verification**:
  - `dart format --output=none --set-exit-if-changed` on touched Dart files.
  - `flutter analyze`.
  - `flutter test` on macOS host; platform-specific enumerated subsets elsewhere.
- **Files**: Implementation log/status only.
- **Complexity**: Medium due to existing large suite.
- **Rollback**: Fix only feature-caused failures; record unrelated baseline failures.

#### Task 5.3 — Run platform build matrix

- **Description**: Build every platform available locally and record CI-only
  checks accurately. No signing, store upload, or live registration occurs.
- **Dependencies**: Task 5.2.
- **Verification**:
  - Android debug/release build as supported by the installed toolchain.
  - iOS simulator/no-codesign build.
  - macOS build and bundle plist inspection.
  - Windows build in Windows CI.
  - Linux build in Linux CI/container.
- **Files**: Implementation log/status only.
- **Complexity**: Medium.
- **Rollback**: Not applicable; build artifacts are ignored/generated.

#### Task 5.4 — Manual acceptance and final SDD handoff

- **Description**: Execute available cold/warm/path-fidelity/invalid-input
  scenarios, list those requiring real devices or other operating systems, and
  update the implementation log/status with evidence, deviations, and remaining
  manual checks. Mark implementation complete only when all code/build gates
  pass and any unavailable runtime checks are clearly classified rather than
  represented as passed.
- **Dependencies**: Task 5.3.
- **Files**:
  - `flows/sdd-comics-editor-dot-comics/04-implementation-log.md` — Modify.
  - `flows/sdd-comics-editor-dot-comics/_status.md` — Modify.
- **Verification**: Every acceptance criterion maps to automated evidence or a
  named pending manual platform check.
- **Complexity**: Medium.
- **Rollback**: Documentation-only changes can be corrected independently.

## Dependency Graph

```text
0.1
 └─> 1.1 -> 1.2 -> 1.3 -> 1.4 -> shared Dart checkpoint
                              ├─> 2.1 -> 2.2 -> 2.3 -> 2.4 (Android)
                              ├─> 3.1 -> 3.2 -> 3.3 -> 3.4 (iOS)
                              ├─> 3.5 -> 3.6 -> 3.7       (macOS)
                              ├─> 4.1 -> 4.2              (Windows)
                              └─> 4.3 -> 4.4              (Linux)

2.4 + 3.4 + 3.7 + 4.2 + 4.4 -> 4.5 -> 5.1 -> 5.2 -> 5.3 -> 5.4
```

Android, iOS, macOS, Windows, and Linux branches may be implemented independently
after Phase 1, but only one branch is edited at a time in the shared worktree.

## Test-to-Requirement Matrix

| Requirement / acceptance | Primary evidence |
|---|---|
| FR-1, FR-2, FR-9 | Metadata artifact tests, plist/manifest validation, Windows dry-run, Linux temporary XDG install. |
| FR-3, AC-1/3/4/5/6 | Coordinator cold-start tests, platform builds, available manual cold-open smokes. |
| FR-4, AC-2/3/4 | Native consume-once queue tests and available warm-open smokes. |
| FR-5, AC-7 | Coordinator Unicode/space tests, native private-copy checks, manual path-fidelity smoke. |
| FR-6, AC-8 | Missing/unreadable/invalid tests and active-document preservation test. |
| FR-7 | Fake opener assertion plus source review that native runners contain no parser. |
| FR-8, AC-9 | Existing widget/core/full regression suites and zero-argument launch test. |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation / gate |
|---|---|---|---|
| Flutter 3.44 implicit-engine/scene lifecycle differs from older templates | Medium | High | Use installed engine headers as authority; compile iOS after each delegate change; always forward `super`. |
| Native notification races Dart startup | Medium | High | Consume-once queue plus mandatory startup drain; broker tests before lifecycle wiring. |
| Apple sandbox URL becomes unreadable before core opens it | Medium | High | Coordinated private copy while security scope is active; Dart receives only completed local copy. |
| Android provider reports only generic MIME | High | Medium | Keep dedicated MIME to satisfy non-overclaiming requirement; document in-app Open fallback and test with compatible provider. |
| External-open failure replaces active editor state | Low | High | Controller invariant test before native work; only successful `openPath` changes active document. |
| Windows quoting creates command injection/broken spaced paths | Medium | High | Exact registry contract test and PowerShell dry-run; quote executable and `%1` separately. |
| Registration helper changes a user's current default | Low | High | Never write extension default/UserChoice or call `xdg-mime default`; artifact assertions and temporary-root/dry-run tests. |
| New Swift/Kotlin files are omitted from build targets | Medium | Medium | Explicit project/Gradle compile checkpoint immediately after each file addition. |
| Full suite exposes unrelated dirty-worktree failures | Medium | Medium | Capture baseline first, preserve unrelated changes, distinguish feature-caused failures in log. |
| Platform/device unavailable locally | High | Medium | Compile/no-codesign gates locally; record exact manual/CI checks without claiming success. |

## Rollback Strategy

Rollback is platform-isolated:

1. Remove Dart app wiring and coordinator; restore zero-argument `main`. Existing
   in-app Open remains authoritative and unchanged.
2. Restore Android `MainActivity`/manifest and remove broker/copier/tests.
3. Restore Apple delegates/plists/project references and remove broker files/tests;
   entitlements remain untouched.
4. Remove Windows/Linux packaging directories and restore Linux application ID.
   Unregistration helpers can remove only app-owned installed metadata if a
   human previously ran the registration helpers.
5. Revert CI additions independently.

No rollback step modifies `.comics` documents, application data, OS defaults,
or unrelated worktree files.

## Implementation Checkpoints

- [ ] Baseline captured and implementation log created.
- [ ] Shared Dart coordinator tests and normal-launch regression pass.
- [ ] Android queue, manifest, and APK build pass.
- [ ] iOS queue, plist, and no-codesign build pass.
- [ ] macOS queue, plist, build, and available Finder smoke pass.
- [ ] Windows registration dry-run/artifact checks pass on Windows CI.
- [ ] Linux temporary-XDG install/artifact checks pass on Linux CI.
- [ ] Analyze, formatting check, focused tests, and full available suite pass.
- [ ] SDD implementation log contains evidence and explicit deferred manual checks.

## Open Implementation Questions

None. If a platform API signature or installed-tool limitation conflicts with
the approved specification during implementation, stop that platform branch,
record the evidence in the implementation log, and request approval before any
architectural deviation.

## Approval

- [x] Reviewed by the user.
- [x] Approved on: 2026-08-05.
- [x] Notes: `plan approved`.
