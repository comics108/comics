# Implementation Plan: flutter-comics-viewer-example-build

> Version: 1.1  
> Status: APPROVED  
> Last Updated: 2026-08-05  
> Specifications: [02-specifications.md](02-specifications.md)

## Scope and Preconditions

Implementation boundary is the nested repository
`libs/comics_viewer/flutter_comics_viewer`. SDD artifacts remain in the outer
repository under `flows/sdd-flutter-comics-viewer-example-build/`.

Before editing:

- capture `git status --short` in both repositories;
- preserve the existing user-owned untracked `example/android/build/`;
- confirm `.github/workflows/build.yml` and `publish.yml` baselines so the final
  diff can prove they were not modified;
- verify whether `flutter`, `pwsh`, and an Actions YAML validator such as
  `actionlint` are locally available; missing optional validators are recorded,
  not installed implicitly.

## Ordered Tasks

### 1. Implement the POSIX local build wrapper

Create `tool/build-example.sh`.

Atomic changes:

1. Enable strict shell failure handling.
2. Resolve script directory, repository root and `example` directory without
   relying on caller working directory.
3. Implement usage and exact target validation for `android`, `ios`, `linux`,
   `macos`, `web`, and `all`.
4. Detect Linux versus macOS and map supported targets and deterministic `all`
   order from the specification.
5. Check `flutter` before dependency resolution.
6. Check the expected sibling `comics-viewer-android` path before any Android
   build and print remediation without cloning it.
7. Run one `flutter pub get` per invocation, then the approved direct Flutter
   command for each selected target.
8. Mark the file executable in git.

Verification after this task:

- `bash -n tool/build-example.sh`;
- no-argument and unknown-target invocations fail and print usage;
- an explicitly unsupported host target fails before Flutter build;
- invocation from outside repository root still resolves paths correctly,
  using a non-building validation path where possible.

### 2. Implement the PowerShell local build wrapper

Create `tool/build-example.ps1` with behavior equivalent to the POSIX wrapper
for Windows.

Atomic changes:

1. Declare and validate the required target parameter.
2. Resolve repository/example paths from `$PSScriptRoot`.
3. Support `android`, `windows`, `web`, and ordered `all` on Windows; reject
   iOS/Linux/macOS with a host-specific diagnostic.
4. Check `flutter`, Android sibling layout, dependency resolution and command
   exit codes explicitly.
5. Avoid cleanup, repository mutation, implicit checkout and shell-specific
   assumptions not available in PowerShell 7.

Verification after this task:

- parse the script with the PowerShell parser when `pwsh` is available;
- no-argument, unknown-target and unsupported-target cases return nonzero;
- if `pwsh` is unavailable on the implementation host, record that limitation
  and validate command/path symmetry by review against the POSIX wrapper.

### 3. Replace the generated example README with build documentation

Modify `example/README.md`.

The document will include:

1. repository layout and Android sibling checkout tree;
2. pinned Flutter/Dart requirement and per-platform prerequisites;
3. wrapper usage from repository root;
4. host-to-target matrix and `all` behavior;
5. all six direct commands from `example/`;
6. exact or architecture-parameterized output paths;
7. iOS unsigned simulator limitation and absence of signing/notarization;
8. network dependencies, including SwiftPM `comics-viewer-ios` branch `main`;
9. validation commands and the explicitly deferred integration test;
10. relationship to the separate GitHub Actions workflow and artifacts.

Verification after this task:

- compare every documented command, mode, target and path against both wrappers
  and the approved specification;
- check Markdown structure and links manually; run an existing Markdown checker
  only if one is already configured in the repository.

### 4. Create the workflow skeleton and validation job

Create `.github/workflows/example-build.yml`.

Atomic changes:

1. Add approved push, tag, pull request and `workflow_dispatch` triggers.
2. Add read-only contents permissions and concurrency cancellation.
3. Define a shared `FLUTTER_VERSION: 3.44.6` environment value where valid
   without obscuring individual job behavior.
4. Add `validate-example` on `ubuntu-24.04` using checkout v4 and cached
   `subosito/flutter-action@v2`.
5. Run `flutter pub get`, scoped format check, scoped analyze and
   `flutter test test` from `example/` as separate named steps.

Verification after this task:

- inspect YAML parsing and trigger structure;
- confirm no `integration_test` command or publish permission is present;
- locally run the four validation commands from `example/`.

### 5. Add Android and Apple platform jobs

Extend `example-build.yml` with independent jobs.

#### Android

1. Checkout the plugin under `flutter_comics_viewer`.
2. Checkout `comics108/comics-viewer-android` as the required sibling.
3. Configure Flutter 3.44.6 caching and JDK 17 Zulu with Gradle cache.
4. Build the release APK from `flutter_comics_viewer/example`.
5. Upload `app-release.apk` as
   `viewer-example-android-release-apk`, retention 14 days, missing files fatal.

#### iOS

1. Use `macos-15`, Flutter 3.44.6 and Xcode 16.
2. Build unsigned debug simulator app.
3. Archive `Runner.app` with a native macOS archive tool.
4. Upload `viewer-example-ios-simulator-debug` with 14-day retention.

#### macOS

1. Use `macos-15`, Flutter 3.44.6 and Xcode 16.
2. Build release macOS app.
3. Archive `viewer_example.app` while preserving bundle metadata.
4. Upload `viewer-example-macos-release` with 14-day retention.

Verification after this task:

- confirm Android relative path resolves exactly to the sibling checkout;
- confirm Apple archive steps fail if the expected `.app` is absent;
- confirm jobs have no `needs: validate-example`, signing secrets or publish
  steps.

### 6. Add Linux, Windows and Web platform jobs

Extend `example-build.yml` with the remaining independent jobs.

#### Linux

1. Use `ubuntu-24.04`.
2. Install only the documented Flutter Linux desktop build packages.
3. Build release Linux bundle.
4. Resolve the runner architecture output and upload the complete bundle as
   `viewer-example-linux-x64-release`.

#### Windows

1. Use `windows-latest` and the runner-provided Visual Studio workload.
2. Build release Windows app from `example`.
3. Upload the complete Release directory as
   `viewer-example-windows-x64-release`.

#### Web

1. Use `ubuntu-24.04`.
2. Build release Web bundle.
3. Upload complete `build/web` as `viewer-example-web-release`.

All uploads use `actions/upload-artifact@v4`, `retention-days: 14` and
`if-no-files-found: error`.

Verification after this task:

- confirm all platform jobs are independent;
- confirm each build output and upload path share the correct checkout prefix;
- confirm directory artifacts include all runtime support files;
- count exactly seven jobs and six upload-artifact steps.

### 7. Run local validation and feasible builds

From `libs/comics_viewer/flutter_comics_viewer/example`:

1. verify Flutter reports version `3.44.6`; if not, stop before claiming build
   parity and record the mismatch;
2. run `flutter pub get`;
3. run `dart format --output=none --set-exit-if-changed lib test`;
4. run `flutter analyze lib test`;
5. run `flutter test test`;
6. run the Web release build through the POSIX wrapper;
7. on the current macOS host, run macOS release and iOS simulator builds through
   the wrapper when Xcode 16 and required network dependencies are available;
8. run Android only if the expected sibling checkout, Android SDK and JDK 17 are
   present; do not create or relocate external repositories to force it.

Linux and Windows native compilation cannot be proven on macOS; their final
verification is delegated to the corresponding GitHub runners and is reported
as pending until Actions executes.

### 8. Validate workflow and review the final diff

1. Parse `example-build.yml` with `actionlint` when available; otherwise use an
   available YAML parser and manual GitHub Actions schema review.
2. Re-run shell and PowerShell syntax checks.
3. Check `git diff --check` in both repository contexts.
4. Review the nested repository diff for unintended generated files, lockfiles,
   secrets, signing settings or modifications to existing workflows.
5. Confirm `example/android/build/` remains untouched and untracked.
6. Record every command, result, skipped host-only check and deviation in
   `04-implementation-log.md`.

## Dependency Order

```text
baseline → POSIX wrapper ─┐
                         ├→ README → local verification
baseline → PS wrapper ───┘
baseline → workflow validation → mobile/Apple jobs ─┐
                                                    ├→ workflow validation
baseline → workflow validation → desktop/Web jobs ─┘
local + workflow verification → final diff review → implementation log
```

README follows wrapper behavior so documentation is checked against actual
entry points. Platform jobs follow the workflow skeleton so triggers, permissions
and toolchain policy are established once before repetition.

## Requirement Traceability

| Requirement area | Plan tasks |
|---|---|
| Local reproducible commands and diagnostics | 1, 2, 3, 7 |
| Six native-appropriate CI builds | 4, 5, 6, 8 |
| Android sibling checkout | 1, 2, 3, 5, 7 |
| Unsigned iOS verification | 3, 5, 7 |
| Stable artifacts and retention | 5, 6, 8 |
| Preserve package/publish gates | baseline, 4, 8 |
| Documentation and limitations | 3, 7 |
| Pinned Flutter and scoped tests | 3, 4, 7 |

## Rollback and Safety

- The three new implementation files can be removed independently to roll back
  workflow or wrapper entry points; README changes can be reverted separately.
- No schema/data migration, secret rotation, release, deployment or external
  state mutation is required.
- Build outputs remain ignored and are never added intentionally.
- No cleanup command targets `example/android/build/` or another existing
  user-owned directory.
- Existing workflows are immutable for this plan; any need to alter them is a
  material deviation requiring specification and plan re-approval.

---

## Approval

- [x] Reviewed by: user
- [x] Approved on: 2026-08-05
- [x] Notes: User explicitly replied `plan approved`; implementation may proceed
  in the documented order.
