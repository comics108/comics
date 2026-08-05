# Status: sdd-comics-editor-dot-comics

## Current Phase

IMPLEMENTATION (in progress)

## Last Updated

2026-08-05 by Codex

## Blockers

- None.

## Progress

- [x] Requirements drafted
- [x] Requirements approved
- [x] Specifications drafted
- [x] Specifications approved
- [x] Plan drafted
- [x] Plan approved
- [x] Implementation started
- [ ] Implementation complete

## Context Notes

- The installed `$sdd` skill was unavailable, so the repository-local `flows/sdd.md` process is the authoritative fallback.
- The user requested the exact flow identifier `sdd-comics-editor-dot-comics`.
- Requirements were explicitly approved by the user on 2026-08-05.
- Specifications were explicitly approved by the user on 2026-08-05.
- Plan was explicitly approved by the user on 2026-08-05.
- Baseline `widget_test.dart` + `dart_io_core_test.dart`: 5 tests passed before feature code changes.
- Supported native Flutter targets are Android, iOS/iPadOS, macOS, Windows, and Linux; this repository currently has no web target.
- Android and iOS already contain partial `.comics` declarations, but no native-to-Dart incoming-file delivery exists.
- Windows and Linux runners already forward ordinary launch arguments to the Dart entrypoint, but `main()` currently accepts none and does not open a passed document.
- The specification uses one Dart `DocumentOpenCoordinator`; Android/iOS/macOS expose consume-once native queues through `net.nativemind.comics_editor/document_open`.
- Android and Apple external inputs are copied into application-private `.comics` cache files before Dart receives a path.
- Android registration uses only `application/vnd.nativemind.comics`; a broad `*/*` filter would violate the approved requirement not to claim unrelated files.
- Windows registration is per-user under HKCU and Linux metadata installs under XDG per-user data directories; neither helper changes the user's explicit default.
- The plan implements and verifies the shared Dart coordinator before touching platform producers, then treats each platform as an isolated rollback unit.
- Automated registration tests use PowerShell dry-run and a temporary Linux `XDG_DATA_HOME`; they never modify the user's live file associations.
- Association means registering Comics Editor as a capable handler while respecting explicit operating-system default-app choices.
- `.puzzle`, browser/PWA support, Windows/Linux single-instance coordination, release publication, and forced default takeover are explicitly out of scope.
- No application source code was changed in this phase.

## Next Action

Implement Task 1.1: focused `DocumentOpenCoordinator` contract tests, then the shared Dart pipeline.

## Fork History

- None; this is a new flow.
