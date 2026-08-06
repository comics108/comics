# Implementation Plan: comics-editor-scroll

> Version: 1.2
> Status: APPROVED
> Last Updated: 2026-08-05
> Specifications: [03-specifications.md](03-specifications.md)

## Summary

Five phases, ordered so each is independently verifiable before the next depends on it: (1) fix the
pre-existing `end`-default bug first, since it's a self-contained correctness fix unrelated to
everything else; (2) build and wire the interpolation engine against `canvasViewport`'s existing
pan value (works even before the canvas layout changes, since `InteractiveViewer` already produces
a pan value today); (3) change the canvas's fit/scroll behavior, which is the visually disruptive
part and needs empirical `boundaryMargin`/zoom-invariance tuning; (4) add sound, last, since it's
the one new external dependency (an audio package) with the most platform-specific risk; (5)
integration-test against real `.comics` files and close out the two Open Design Questions.

The tasks below implement only the current/default Vertical-scroll comic strip. Horizontal-scroll
is a future mode and is deliberately not introduced by this plan. The implementation remains a
valid vertical specialization of `03-specifications.md`'s axis contract.

## Task Breakdown

### Phase 1: Fix the pre-existing `end`-default bug

#### Task 1.1: `models_mapping.dart`/`models.dart` — `end` default `200` → `0`
- **Description**: `_animFromJson`'s absent-`end` fallback (line 68) and `_animToJson`'s
  omit-comparison (line 111) both move from `200` to `0`, changed together (per the file's own
  existing comment on why they must match). `models.dart`'s `Anim` constructor default follows
  automatically (`models.dart:58`); `EditorLayer`'s seed call (`models.dart:100`) needs no direct
  change.
- **Files**:
  - `apps/comics-editor/lib/src/bridge/models_mapping.dart` — Modify (lines 68, 111)
  - `apps/comics-editor/lib/src/ui/models.dart` — Modify (line 58, constructor default)
- **Dependencies**: None
- **Verification**: Unit test — an `Anim` JSON blob with no `end` key parses to `end == 0` in
  memory; re-serializing that same in-memory `Anim` (untouched) omits `end` again (round-trip,
  tested together as Specifications' Testing Strategy requires)
- **Complexity**: Low

### Phase 2: Interpolation engine

#### Task 2.1: `KeyframeInterpolator` — translate only
- **Description**: Port `Anim.cs`'s `FindNearest<T>`/`Factor`/`Interpolate<T>` for
  `AnimType.translate` first (simplest shape, no pivot). Establishes the shared
  `_findNearest`/`_factor` helpers the other three types reuse in Task 2.2.
- **Files**: `apps/comics-editor/lib/src/ui/anim/keyframe_interpolator.dart` — Create
- **Dependencies**: None (pure function of `List<Anim>` + a `double currentTime`, no controller/UI
  wiring yet)
- **Verification**: Unit tests per Specifications' Testing Strategy — cubic ease-out formula, the
  before-any/mid-range/past-all cases, `curr.end==curr.start` guard, no-translate-anims fallback to
  the passed-in static `Offset`
- **Complexity**: Medium

#### Task 2.2: `KeyframeInterpolator` — scale, rotate, alpha
- **Description**: Extend with `scaleAt`/`rotateAt`/`alphaAt`, reusing Task 2.1's shared helpers.
  Each gets its own resting-default test (scale→(1,1), alpha→1, rotate→(0, pivot 0.5/0.5)).
- **Files**: same file as 2.1 — Modify
- **Dependencies**: Task 2.1
- **Verification**: Unit tests, one set per type, mirroring 2.1's
- **Complexity**: Low (mechanical repetition of an already-proven shape)

#### Task 2.3: `controller.dart` — replace `playhead` with `currentTime`
- **Description**: Remove `playhead`/`setPlayhead`/`totalFrames`. Add `currentTime` getter derived
  from `canvasViewport`'s current pan position (initial version can use today's existing canvas
  layout/scale — this task does NOT depend on Phase 3's layout change, since `InteractiveViewer`
  already produces a real pan value regardless of how `_Page` is sized). Update `addAnim`/`addSound`
  (lines 940-945, 963-974) to read `currentTime` instead of `playhead`.
- **Files**: `apps/comics-editor/lib/src/ui/controller.dart` — Modify
- **Dependencies**: None directly, but pairs naturally with Task 2.4
- **Verification**: Unit/widget test — `addAnim` stamps `start` from a known `canvasViewport` pan
  position, not a hardcoded `playhead` value; confirm no remaining references to the removed fields
  (compile-time check doubles as verification here)
- **Complexity**: Medium (touches an existing, referenced field — check `timeline.dart` for any
  `playhead` reads that need to switch to `currentTime` too, since Requirements said not to change
  its *visual form*, not that it can keep reading a now-deleted field)

#### Task 2.4: Wire `_LayerItem` to `KeyframeInterpolator`
- **Description**: `canvas_view.dart`'s `_LayerItem` renders `KeyframeInterpolator`'s computed
  translate/scale/rotate/alpha instead of the static `l.translate`/implicit identity values, using
  `currentTime` from Task 2.3.
- **Files**: `apps/comics-editor/lib/src/ui/widgets/canvas_view.dart` — Modify
- **Dependencies**: Tasks 2.1, 2.2, 2.3
- **Verification**: Widget test — a layer with a known translate `Anim` renders at the expected
  interpolated position for a given `canvasViewport` pan value
- **Complexity**: Medium

### Phase 3: Canvas layout — fit-width, real scrolling

#### Task 3.1: `_Stage`/`_Page` sizing — fit-width instead of fit-whole-document
- **Description**: Replace `pageH = maxH; pageW = pageH * aspect` with `pageW = maxW; pageH = pageW
  / aspect` (`canvas_view.dart:37-51`) — the document renders at its real proportional height,
  taller than the viewport for any real document.
- **Files**: `apps/comics-editor/lib/src/ui/widgets/canvas_view.dart` — Modify
- **Dependencies**: None (independent of Phase 2, but tested together in practice since both touch
  the same file)
- **Verification**: Widget test confirming `_Page`'s rendered size for a known `doc.width`/`height`
  and viewport size; manual check that the canvas no longer shrinks tall documents to fit
- **Complexity**: Low

#### Task 3.2: `InteractiveViewer.boundaryMargin` tuning
- **Description**: Resolve Open Design Question 2 empirically — confirm panning can reach the full
  real document height (top to bottom) without being clamped short, now that `_Page` is real-height
  instead of shrunk-to-fit.
- **Files**: same file as 3.1 — Modify
- **Dependencies**: Task 3.1
- **Verification**: Manual — open a real tall `.comics` file, pan to the very bottom, confirm it's
  reachable; widget test asserting the effective scrollable range covers the full document height
- **Complexity**: Low

#### Task 3.3: Pin down `currentTime`'s zoom-invariant formula
- **Description**: Resolve Open Design Question 1 empirically — confirm `currentTime` (from Task
  2.3) reads the same real document-pixel value at a fixed document position regardless of zoom
  level, now that the real layout (Task 3.1) is in place. Adjust the division-by-`k`-and-zoom-scale
  math from Specifications' Data Flow if the empirical test disagrees with the first-pass formula.
- **Files**: `apps/comics-editor/lib/src/ui/controller.dart` — Modify (refines Task 2.3's getter)
- **Dependencies**: Tasks 2.3, 3.1
- **Verification**: The zoom-invariance integration test from Specifications' Testing Strategy —
  pan to a fixed position, zoom in/out, confirm `currentTime` is unchanged
- **Complexity**: Medium (the one genuinely open piece of math in this plan)

### Phase 4: Sound

#### Task 4.1: Add `audioplayers` dependency
- **Description**: Add to `pubspec.yaml`, confirm it builds on all five targeted platforms
  (`android/ios/linux/macos/windows`).
- **Files**: `apps/comics-editor/pubspec.yaml` — Modify
- **Dependencies**: None
- **Verification**: `flutter pub get` succeeds; app still builds/runs on at least the primary dev
  platform
- **Complexity**: Low

#### Task 4.2: `SoundPlayer` — gating logic
- **Description**: Port `SoundAnim.FindCurrent`'s point/range, direction-sensitive gating
  (Specifications' Interfaces). Gating logic is pure and testable without any real audio playback —
  separate the decision ("should this be playing/looping/stopped right now") from the
  `audioplayers` call itself.
- **Files**: `apps/comics-editor/lib/src/ui/audio/sound_player.dart` — Create
- **Dependencies**: Task 4.1
- **Verification**: Unit tests per Specifications — downward-crossing point-trigger fires, upward
  does not; a range starts/stops exactly at its boundaries
- **Complexity**: Medium

#### Task 4.3: Wire `SoundPlayer` per `EditorSound`
- **Description**: Call `evaluate` on every `currentTime` change (mirrors
  `ComicsViewModel.Scroll`'s per-tick `sound.Scroll()`).
- **Files**: `apps/comics-editor/lib/src/ui/controller.dart` — Modify
- **Dependencies**: Tasks 2.3, 4.2
- **Verification**: Manual — pan through a real sound cue's range, confirm playback
- **Complexity**: Low

### Phase 5: Integration & closeout

#### Task 5.1: Real-file integration test
- **Description**: Open a real `.comics` file from `dataset/.../comics_interactive/`, pan through
  its full height, confirm computed transforms at sample points match hand-calculation against the
  file's raw `Anim` data.
- **Files**: new test file under `apps/comics-editor/test/`
- **Dependencies**: Phases 1-3 complete
- **Verification**: Test passes; any mismatch is a real bug to fix before calling this flow done,
  not a spec ambiguity (Requirements already resolved the units question)
- **Complexity**: Medium

#### Task 5.2: Manual verification pass
- **Description**: Full manual checklist from Specifications' Testing Strategy — author a new
  animation and pan through it; open several real `dataset/` files and confirm resting layers place
  instantly (Task 1.1's fix); confirm sound plays/loops/stops correctly and point-triggers respect
  direction.
- **Files**: None (manual)
- **Dependencies**: All prior tasks
- **Verification**: Anton (or Claude, reporting explicitly what was and wasn't checked, per this
  repo's convention of not claiming UI verification without actually running it) confirms each item
- **Complexity**: Low

## Dependency Graph

```
Task 1.1 (end-default fix, independent)

Task 2.1 ─→ Task 2.2 ─→ Task 2.3 ─┬─→ Task 2.4
                                   │
Task 3.1 ─────────────────────────┼─→ Task 3.2
                                   │
                                   └─→ Task 3.3 (needs 2.3 AND 3.1)

Task 4.1 ─→ Task 4.2 ─→ Task 4.3 (needs 2.3)

(2.4, 3.2, 3.3, 4.3) ─→ Task 5.1 ─→ Task 5.2
```

## File Change Summary

| File | Action | Reason |
|------|--------|--------|
| `apps/comics-editor/lib/src/bridge/models_mapping.dart` | Modify | `end` default fix (Task 1.1) |
| `apps/comics-editor/lib/src/ui/models.dart` | Modify | `Anim` constructor default follows Task 1.1 |
| `apps/comics-editor/lib/src/ui/anim/keyframe_interpolator.dart` | Create | Ported interpolation engine (Tasks 2.1-2.2) |
| `apps/comics-editor/lib/src/ui/controller.dart` | Modify | `playhead`→`currentTime`, `SoundPlayer` wiring (Tasks 2.3, 3.3, 4.3) |
| `apps/comics-editor/lib/src/ui/widgets/canvas_view.dart` | Modify | Interpolated rendering (2.4), fit-width layout (3.1-3.2) |
| `apps/comics-editor/lib/src/ui/audio/sound_player.dart` | Create | Sound gating (4.2) |
| `apps/comics-editor/pubspec.yaml` | Modify | `audioplayers` dependency (4.1) |
| `apps/comics-editor/lib/src/ui/widgets/timeline.dart` | **None** | Explicitly untouched per Requirements |

## Future Horizontal Follow-up — not part of this plan

A separate approved flow must, at minimum:

1. add an explicit persisted scroll type with missing-value → vertical compatibility;
2. fit the document by height and derive progress from normalized X translation;
3. move the Viewer selector to the bottom edge while preserving its normalized semantics;
4. keep device orientation independent from the strip direction;
5. validate keyframe/sound behavior using the same axis-neutral logical `currentTime` contract.

No task above should be reinterpreted as implementing or enabling Horizontal-scroll now.

## Phase 6: Target viewport range — added 2026-08-05

### Task 6.1: Move fixed device dimensions from timeline ownership

- Add app-level `DeviceProfile` values for iPad `768×1024` and iPhone `390×844`.
- Keep selection out of `.comics`; default the editor session to iPad.
- Mark the old timeline ownership as relocated rather than maintaining duplicate implementations.

### Task 6.2: Add Properties → General

- Extend tab order to Selection, Document, General.
- Show target chooser, exact dimensions/aspect ratio, calculated visible document height, and an
  explanation that the target is independent of the editor's host device.

### Task 6.3: Replace Viewer point with viewport band

- Calculate the vertical device extent from document width and selected profile ratio.
- Center/fit the actual Viewer surface to the selected device aspect ratio, independent of host
  desktop/mobile dimensions.
- Draw two boundaries plus a filled band on the existing right-edge rail.
- Preserve tap, drag, keyboard, and semantics control with travel-aware position conversion.

### Task 6.4: Verification

- Unit-test device screenful math.
- Widget-test tab order/profile switching, visible-range semantics, and one-action rail input.
- Re-run existing Viewer, vertical interpolation, currentTime, canvas layout, and boundary tests.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| `currentTime`'s zoom-invariant formula is wrong on first attempt | Medium | Medium | Isolated to Task 3.3, caught by its own dedicated integration test before Phase 5 |
| `audioplayers` has platform-specific issues (esp. Linux) | Medium | Low | Isolated to Phase 4; gating logic (4.2) is tested independently of real playback |
| Fixing the `end`-default bug changes real files' rendered appearance unexpectedly | Low | Medium | Task 5.2's manual pass explicitly checks this against real `dataset/` files before calling the flow done |
| `timeline.dart` secretly reads the soon-to-be-removed `playhead` somewhere not yet found | Medium | Low | Task 2.3 explicitly calls out checking for this; compile errors will surface any missed reference |

## Rollback Strategy

Each phase is independently revertable (separate files/methods, no shared migration step):

1. Phase 1 (data fix) can be reverted alone — no other phase depends on it structurally, only on
   its correctness for real files.
2. Phases 2-4 are additive (new files) plus localized modifications to `controller.dart`/
   `canvas_view.dart` — revert via normal git history if a phase needs backing out.
3. No data migration exists to roll back — the `.comics` format itself is unchanged throughout.

## Checkpoints

After each phase, verify:

- [ ] All new/modified unit and widget tests pass
- [ ] No new analyzer warnings
- [ ] Behavior matches `03-specifications.md`'s Behavior Specifications section

## Open Implementation Questions

- [ ] Exact `currentTime` zoom-invariance formula (Task 3.3) — the one piece of math this plan
      doesn't pre-solve, by design (Specifications flagged it as needing empirical verification).
- [ ] `audioplayers` version pin and any Linux-specific setup — resolved during Task 4.1, not here.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-02
- [x] Notes: Approved as drafted.
- [x] Direction audit requested by Anton on 2026-08-05; future-horizontal prerequisites recorded,
      with no change to the approved vertical implementation tasks.
- [x] Phase 6 requested directly by Anton on 2026-08-05; target dimensions are moved from Timeline
      to General and the Viewer selector becomes a selected-device range.
