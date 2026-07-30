# Implementation Log: comics-editor-v2.9-fixes2

> Started: 2026-07-25
> Plan: [03-plan.md](03-plan.md)

## Progress Tracker

| Task | Status | Notes |
|------|--------|-------|
| C.1 Convert() comment | Done | `dotnet build` clean |
| D.1 EditHistory class | Done | |
| D.2 EditorController integration | Done | Deviation — snapshot strategy changed, see below |
| D.3 canvas_view.dart gesture wiring | Done | |
| D.4 Ctrl+Z/Ctrl+Shift+Z shortcuts | Done | |
| D.5 TopBar Undo/Redo buttons | Done | |
| D.6 Tests | Done | 20 new tests, all green; `flutter analyze` clean |
| D.7 Manual verification | Not Started | Needs interactive GUI session (agent can't do this in sandbox) |
| A.1 hostfxr_bootstrap | Done | Written, unverifiable on macOS (needs MSVC/Windows) |
| A.2 NativeExports.cs | Done | `dotnet build` clean |
| A.3 editor_plugin.cpp wiring | Done | Written, unverifiable on macOS |
| A.4 CMake re-enable + copy | Done | Written, unverifiable on macOS |
| A.5 wpf_editor_view.dart dispose() | Done | `flutter analyze` clean, also fixed stale C++/CLI references in comments/UI text |
| A.6 Real Windows CI verification | Not Started | User-driven — needs commit/push + a `build-windows` run |
| B.1 Real Linux CI diagnostics | Not Started | User-driven |

## Session Log

### Session 2026-07-25 — Claude (Track C + Track D)

**Started at**: Plan approved, all 4 tracks (A/B/C/D) ready for implementation.
**Context**: Independent tracks — started with C (trivial) and D (fully self-verifiable on macOS via `flutter analyze`/`flutter test`, no CI dependency), deferring A (needs real Windows CI) and B (needs user to trigger a real CI run first, Task B.1).

#### Completed
- **Track C**: `native/Comics.Editor/ViewModel/ComicsViewModel.cs` — replaced `// TODO remove convert functionality` with the descriptive comment from specs. Verified: `dotnet build native/Comics.slnx -c Release` — 0 errors, same 50 pre-existing warnings as before.
- **Track D** (all tasks D.1–D.6):
  - `lib/src/ui/edit_history.dart` (new) — `EditHistory` class, snapshot stack over `ComicsDoc` (not `Map<String,dynamic>`/comicsToCore — see Deviations).
  - `lib/src/ui/models.dart` — added `clone()` to `Anim`, `LayerImage`, `EditorLayer`, `EditorSound`, `ComicsDoc` (deep copy, clears the constructor's auto-seeded default images/anims before copying real ones).
  - `lib/src/ui/controller.dart` — `EditHistory _history`, `canUndo`/`canRedo`, `undo()`/`redo()`, `_beginHistory()`/`_commitHistory()` helpers, `beginGestureHistory()`/`commitGestureHistory()` public wrappers for continuous gestures. Wrapped 13 discrete mutators (`setCanvasSize`, `setScale`, `addLayer`, `moveLayer`, `deleteSelected`, `toggleVisible`, `togglePreview`, `setImageFile`, `setImagePopup`, `addSound`, `moveSound`, `addAnim`, `deleteAnim`, `editAnim`) — snapshot placed AFTER each method's existing early-return guards, so no-op calls (e.g. `moveLayer` at a list boundary) don't create phantom history entries. `dragSelected` left untouched (gesture-driven, handled externally). `newDoc()`/`openRecent()` now also reset `coreDoc = null` (see Deviations) and call `_history.clear()`.
  - `lib/src/ui/widgets/canvas_view.dart` — `onPanStart` now also calls `beginGestureHistory()`; added `onPanEnd` calling `commitGestureHistory()`.
  - `lib/src/ui/screens/editor_screen.dart` — `UndoIntent`/`RedoIntent`, wrapped the `Scaffold` in `Shortcuts`/`Actions` for Ctrl+Z/Ctrl+Shift+Z.
  - `lib/src/ui/widgets/top_bar.dart` — two `HsIconButton`s (undo/redo icons), `onTap` null when `canUndo`/`canRedo` is false.
  - `test/edit_history_test.dart` (new) — 11 unit tests: begin/commit/undo/redo semantics, empty-stack behavior, redo-stack clearing, `clear()`, and `ComicsDoc.clone()` snapshot-independence (mutate original after cloning, assert clone unaffected — both top-level fields and nested layer images/anims).
  - `test/controller_undo_redo_test.dart` (new) — 9 integration tests via `EditorController`: addLayer/undo/redo round-trip, multi-step undo, empty-history no-op, redo-stack clearing on new action, `deleteSelected` undo, `moveLayer` boundary no-op producing no phantom entry, `newDoc()` clearing history from a prior document, gesture-style one-entry-per-drag via `beginGestureHistory`/`commitGestureHistory`.
- Verified by: `flutter analyze` (whole project) — 0 issues. `flutter test test/edit_history_test.dart test/controller_undo_redo_test.dart` — 20/20 passed. `flutter test test/widget_test.dart test/dart_io_core_test.dart` — 4/4 passed (no regression). (`core_client_test.dart`/`ffi_core_test.dart` not re-run — untouched by these changes, spin up real processes/AOT and take longer; not exercised by this session.)

#### In Progress
- Track A (Windows hostfxr interop) and Track B (Linux ping CI crash) — not started this session, see Progress Tracker.

#### Deviations from Plan

1. **Snapshot strategy: `ComicsDoc.clone()` instead of `comicsToCore`/`comicsFromCore` JSON round-trip.** Specs assumed every open document has a backing `CoreDocument` (`coreDoc`), so snapshotting could go through `comicsToCore(coreDoc!)`. Reading `controller.dart` at implementation time showed `newDoc()`/`openRecent()` create a `ComicsDoc` directly and never set `coreDoc` — it stays whatever it was before (or null). `comicsToCore(coreDoc!)` would either NPE (if null) or, worse, silently operate on a **stale** `CoreDocument` left over from a previously-open real file (see next point). Switched to a direct deep-clone of `ComicsDoc` (new `clone()` methods on the model classes in `models.dart`), which works identically whether or not `coreDoc` exists, and — as a side benefit — doesn't depend on `comicsToCore`'s save-fidelity merge/`comicsFromCore`'s reconstruction heuristics (e.g. deriving a layer's display name from its first image file), which are designed for round-tripping to disk, not for being the source of truth on every undo/redo.
2. **Related fix, required for (1) to be correct**: `newDoc()`/`openRecent()` now also set `coreDoc = null`. This was a **latent pre-existing bug**, not something introduced by this work: previously, calling `newDoc()` after having a real file open via `openPath()` left `coreDoc` pointing at the *old* file's `CoreDocument` — meaning `saveToPath()`/`exportWithDialog()` (which read `coreDoc`, not `doc`, and use `comicsToCore(document)`) would silently save/export the wrong (stale) document's content. This surfaced only because `undo()`/`redo()` needed to correctly decide whether to reconstruct a `CoreDocument` (`if (cd != null) coreDoc = CoreDocument(snapshot, cd.raw, cd.path)`) — with the stale `coreDoc` bug in place, undo on a brand-new document would have wrapped the snapshot in the *previous* document's `raw`/`path`. Fixing this null-reset was necessary for D's correctness, not optional scope creep.
3. **`_withHistory(void Function())` helper (as sketched in specs) was not used as originally written.** A single closure-wrapping helper that unconditionally calls `beginTransaction`/mutate/`commitTransaction` would create a history entry even when a method's own early-return guard fires (e.g. `moveLayer` at a list boundary, `deleteAnim` with nothing selected) — every one of those guards would otherwise get bypassed by wrapping the *entire* method body. Instead, each of the 13 wrapped mutators keeps its existing guards verbatim, with `_beginHistory()`/`_commitHistory()` calls inserted individually around just the mutating statements, after the guards. Verified directly by a test (`moveLayer no-op at boundary does not create a history entry`).

#### Discoveries
- `EditorLayer`'s constructor auto-seeds default `images` (one per `kLangs`) and one default translate `Anim` — `EditorLayer.clone()` must clear both lists before copying the real ones, or clones end up with duplicated/wrong defaults prepended.
- `Shortcuts`/`Actions` (Flutter) correctly defers to a focused `TextField`'s own built-in undo — confirmed by design (Flutter's action-dispatch walks from the focused widget outward, so `EditableText`'s own Ctrl+Z binding, registered closer to focus, wins over this screen-level `Shortcuts`) — not yet manually verified interactively (see D.7).

**Ended at**: Track C and Track D fully implemented, `flutter analyze`/relevant `flutter test` green. Track A and B not started.
**Handoff notes**:
1. Track D.7 (manual interactive verification — Ctrl+Z/Ctrl+Shift+Z in a running app, drag-undo-as-one-step, disabled button states) still needs a human on a real device/desktop; not possible in this sandboxed session (no GUI automation permissions — same limitation noted in `sdd-comics-editor-v2.9-fixes1`).
2. Next up: Track A (write hostfxr/C++/C# code, cannot verify build locally — needs real Windows CI) or Track B (needs user to trigger `build-linux`/`tool/docker-build.sh linux` first, Task B.1, before any fix can be designed).

---

### Session 2026-07-25 (continued) — Claude (Track A)

**Started at**: Track A (Windows hostfxr/nethost interop), tasks A.1–A.5.
**Context**: Continuing directly after Track C/D in the same session; user asked to keep going rather than wait on D.7/B.1 (both user-driven).

#### Completed
- `windows/editor_plugin/hostfxr_bootstrap.h`/`.cpp` (new) — hand-declared hostfxr ABI (`hostfxr_initialize_for_runtime_config`/`hostfxr_get_runtime_delegate`/`hostfxr_close`, `load_assembly_and_get_function_pointer` delegate signature) rather than pulling in the `Microsoft.NETCore.DotNetAppHost` NuGet package's headers (this is a plain CMake C++ project, no natural PackageReference support). `ResolveHostFxrPath()` walks `DOTNET_ROOT` (or `C:\Program Files\dotnet` default) + `host\fxr\<highest version>`. `EnsureHostInitialized()` is lazy/idempotent, caches the two resolved delegates (`HandleMethodCall`/`FreeResultString`) in file-local statics. Closes the hostfxr context handle right after obtaining the delegate (matches Microsoft's own native hosting sample — the runtime stays loaded regardless).
- `native/Comics.Editor.Flutter/NativeExports.cs` (new) — `[UnmanagedCallersOnly]` `HandleMethodCall(IntPtr, IntPtr) -> IntPtr` (UTF-16 marshaling via `Marshal.PtrToStringUni`/`StringToHGlobalUni`) wrapping the existing `MethodChannelHandler.HandleMethodCall`, plus `FreeResultString(IntPtr)`. Extra `catch` around the existing handler as a last-resort guard against an unhandled exception crossing the native boundary (which would crash the whole process).
- `windows/editor_plugin/editor_plugin.cpp` — replaced the `not_implemented` stub: `HandleMethodCall` now calls `EnsureHostInitialized()` (→ `result->Error("interop_init_failed", ...)` on failure) then `CallHandleMethodCall()`, with small local UTF-8↔UTF-16 conversion helpers (`Utf8ToWide`/`WideToUtf8`, via `MultiByteToWideChar`/`WideCharToMultiByte`) and a minimal `IsErrorResult()` check (literal `{"error"` prefix — safe here since both ends of this JSON protocol are ours, not parsing untrusted input).
- `windows/editor_plugin/CMakeLists.txt` — added `hostfxr_bootstrap.cpp` to the `add_library` sources (would otherwise silently not compile in); re-enabled (uncommented) the `editor_plugin_csharp` custom target, now that there's a real consumer of the published DLL. Comment rewritten with the full history (disabled in `sdd-comics-editor-build` for lack of a consumer, MSB1008 root cause still unconfirmed if it recurs).
- `windows/runner/CMakeLists.txt` — added a `POST_BUILD` `add_custom_command` (`copy_directory` from `${CMAKE_BINARY_DIR}/dotnet` to `$<TARGET_FILE_DIR:${BINARY_NAME}>/dotnet`) — the gap found during Specifications (published DLL was landing in the build tree, not the packaged app).
- `lib/src/bridge/wpf_editor_view.dart` — `dispose()` override, fire-and-forget `invokeMethod('dispose')` (only if `_nativeAvailable`, since a no-op dispose call is harmless but pointless otherwise). Also updated now-stale doc comments/catch-block comments/fallback UI text that referenced the abandoned "C++/CLI-слой" approach (see `editor_plugin.h`'s own comment, which already called this an alternative "вариант B" not taken) and instructions to "собрать" a layer that's now built-in — replaced with accurate text (hostfxr, and that a visible fallback now most likely means missing .NET runtime or an old build).
- Verified by: `dotnet build native/Comics.Editor.Flutter/Comics.Editor.Flutter.csproj` (NativeExports.cs compiles clean on macOS — plain C#, no Windows-specific API). `flutter analyze` (whole project) — 0 issues. `flutter test test/widget_test.dart test/dart_io_core_test.dart test/edit_history_test.dart test/controller_undo_redo_test.dart` — 24/24 passed. **The C++ (`hostfxr_bootstrap.cpp`/`editor_plugin.cpp`) and CMake changes are NOT verified** — they need Windows headers (`<windows.h>`) and the MSVC/CMake toolchain from `windows-2025-vs2026`, unavailable on this macOS agent. Real verification is Task A.6 (real `build-windows` CI run).

#### Discoveries
- `README.md` has no "Windows" section at all, despite `wpf_editor_view.dart`'s fallback UI text (before this session's edit, and still today) telling the user to look there — a pre-existing gap, not introduced by this work. Left as-is: out of scope for Track A (which is about the interop code, not authoring new user docs) — flagging here rather than silently expanding scope.

#### Deviations from Plan
- None beyond what Specifications already anticipated — A.1–A.5 were implemented essentially as designed. The plan's Task A.1 already flagged this as "High" complexity risk precisely because the hostfxr ABI has to be hand-declared without local compiler feedback.

**Ended at**: Track A code complete (A.1–A.5), pending real Windows CI verification (A.6).
**Handoff notes**: After the user commits/pushes and runs `build-windows`, watch specifically for: (1) whether `hostfxr_bootstrap.cpp` compiles cleanly under MSVC (hand-declared ABI, never compiler-checked here), (2) whether the re-enabled `editor_plugin_csharp` custom target still hits the old MSB1008 issue (unlikely now that we know the `<Command>` itself was always syntactically fine, but the underlying MSBuild/CMake interaction on this toolset was never actually explained), (3) whether the `POST_BUILD copy_directory` step in `runner/CMakeLists.txt` runs at the right time relative to `editor_plugin_csharp` (dependency is implicit via `editor_plugin`'s own dependency on the custom target — should be fine, but this exact ordering was never exercised before).

---

## Deviations Summary

| Planned | Actual | Reason |
|---------|--------|--------|
| Undo snapshots via `comicsToCore`/`comicsFromCore` (JSON, requires `coreDoc`) | Direct `ComicsDoc.clone()` deep-copy, independent of `coreDoc` | `newDoc()`/`openRecent()` don't set `coreDoc` — discovered at implementation time, not caught in Specifications |
| Generic `_withHistory(fn)` wrapping whole mutator bodies | Per-method `_beginHistory()`/`_commitHistory()` inserted after existing guards | Avoids phantom history entries for methods with early-return no-op guards |

## Learnings

- Re-reading the actual mutation methods line-by-line at Implementation time (not just at Specifications time) surfaced two things Specifications missed: the `coreDoc`-can-be-null case, and how many of the ~15 mutators have real early-return guards that a naive generic wrapper would have bypassed. Worth budgeting for this level of re-verification on any future track that touches a class this size, rather than trusting a Specifications-time read to be complete.

## Completion Checklist

- [x] Track C completed
- [x] Track D completed (except D.7 manual verification — needs a human)
- [ ] Track A completed (code done, A.6 real Windows CI verification pending)
- [ ] Track B completed (not started, waiting on B.1 real diagnostics)
- [x] Tests passing (for completed tracks)
- [x] No regressions (verified: widget_test.dart, dart_io_core_test.dart)
- [x] Documentation updated (this log)
- [ ] Status updated to COMPLETE (not yet — A/B remain)
