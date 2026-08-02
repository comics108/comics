# Status: vdd-comics-editor-vertical-scroll

## Current Phase

IMPLEMENTATION

## Phase Status

SUBSTANTIALLY COMPLETE — all 5 phases (13 tasks) implemented, 240/241 tests pass (the one failure
is the pre-existing, unrelated dataset-listing issue noted at the very start of Task 1.1). Two
items are genuinely outstanding and disclosed, not silently treated as done — see Blockers.

## Last Updated

2026-08-02 by Claude

## Blockers

- **Task 5.2's real interactive/audio manual verification is outstanding.** Everything automatable
  (unit tests, widget tests, a real-file integration test) passes, but visually confirming the
  running editor's behavior and confirming real sound playback both require a human actually running
  the desktop app — not something performable in this text-based session. Needs Anton (or a future
  session with real interactive/audio capability).
- **The `$tempFolder/sounds/` path convention (Task 4.3) has no real audio file anywhere in this
  repo to test end-to-end.** The convention itself is confirmed correct against legacy's real
  `FileManager.FolderSounds` constant (not guessed), but the actual file-resolution-to-playback path
  has never been exercised against a real sound file.

## Progress

- [x] Requirements drafted (2026-08-02) — v0.1
- [x] Requirements revised (2026-08-02) — v0.2, Open Questions resolved, User Stories/Acceptance
      Criteria added
- [x] Requirements approved (2026-08-02) by Anton Dodonov
- [x] Visual drafted (2026-08-02) — v1.0: canvas before/after, keyframe interpolation across three
      scroll moments, sound point/range triggering, the new-layer seed fix, and an explicit
      "what does NOT change" note for `timeline.dart`
- [x] Visual approved (2026-08-02) by Anton Dodonov
- [x] Specifications drafted (2026-08-02) — v1.0: `KeyframeInterpolator`/`SoundPlayer` interfaces,
      the fit-width canvas layout change, and a new finding (see Context Notes)
- [x] Specifications approved (2026-08-02) by Anton Dodonov
- [x] Plan drafted (2026-08-02) — v1.0: 5 phases / 13 tasks
- [x] Plan approved (2026-08-02) by Anton Dodonov
- [x] Implementation started (2026-08-02) — Task 1.1
- [x] Implementation complete (2026-08-02) — 5 phases, 13 tasks, 240/241 tests pass; Task 5.2's real
      interactive/audio manual pass explicitly outstanding (see Blockers)
- [ ] Documentation drafted
- [ ] Documentation approved

## Context Notes

- **Purpose and relationship to `vdd-comics-editor-timeline`**: that flow investigated the same
  problem space and reached Specifications with Option A1 approved, but included ideas beyond a
  literal port (device-visibility overlay, `DeviceProfile`, an opt-in-toggle rollout decision).
  Anton explicitly asked for a **new, narrower flow**: copy v2.8's vertical-scroll functionality
  **one-to-one**, using the other flow (and `sdd-comics-editor-questions`,
  `sdd-comics-editor-fromat-dot-comics`) only to locate relevant files/functions faster — not to
  inherit their design ideas. `legacy/comics-editor-v2.8` is the sole behavioral source of truth
  here, confirmed to be the real canonical v2.8 source (not a doc/description of it) via a diff
  against `apps/comics-editor/native/Comics.Editor`, which is a near-identical working copy
  (differs only in two unrelated additions, neither touching scroll/animation).
- **Two gaps, not one**: (1) the already-known missing interpolation engine (`Anim` keyframes are
  inert in Flutter), and (2) a *newly found* second gap — `canvas_view.dart` currently fits the
  *entire* document height into the viewport and free-zooms/pans on top of that, architecturally
  different from v2.8's fixed-aspect-window-scrolling-through-real-height-document model. Wiring up
  interpolation without also fixing the canvas's fit behavior wouldn't produce the asked-for
  experience.
- **Real, previously-undiscovered legacy mechanic found**: v2.8's `ScrollViewer.Height =
  ActualWidth × 1.4` (a hardcoded `ratio` resource) — the editor's own canvas viewport is a
  fixed-aspect "one screenful" window, not an incidental detail. This is a genuine legacy behavior,
  distinct from (and predating) Anton's own later multi-device-overlay idea from the sibling flow —
  in scope here as a literal port question; the multi-device idea is explicitly not.
- **Data model already anticipated this port**: current Dart `Anim`/`EditorLayer` already carry
  every field legacy's five `*Anim` subclasses need, with matching defaults (`scaleX/Y=1`,
  `alpha=1`), and `addAnim`/`addSound` already stamp `end = start + 200` exactly like legacy's
  `Anim.Add<T>`. Less new data-model work than either sibling flow anticipated — the real gaps are
  the interpolation engine itself and the canvas fit/scroll behavior.
- **Major correction identified for `vdd-comics-editor-timeline`** (2026-08-02, disclosed, not
  silent): that flow's Specifications flagged an "unresolved unit mismatch" between small
  `Anim.Start`/`End` values (~48-6000) and large document heights (16,300-100,900+) as its single
  biggest risk, deferred to an empirical test. Reading
  `legacy/comics-editor-v2.8/Comics.Editor/Models/Layer.cs`'s `Create` method and `Anim.cs`'s
  `FindNearest`/`Add` resolved this definitively: there is no mismatch and no scale factor needed.
  A keyframe range only needs to span the short window (~200px) during which one specific
  transition plays; once scroll passes it, the value holds unchanged for the rest of the document,
  however tall. Small numbers are just raw pixels near the top of the document, not scaled-down
  positions. **Not edited into that flow's own files**: mid-session it was found relocated to
  `flows/_blamed/vdd-comics-editor-timeline/` (apparently archived/superseded, not something this
  session did) — the correction is recorded here instead, pending Anton confirming whether the
  archived copy should also be touched.
- **New, more consequential finding during Specifications**: `models_mapping.dart:68`'s
  `_animFromJson` parses an absent `end` key as `200`, but legacy's Newtonsoft serializer omits
  `end` whenever its true value is `0` — exactly `Layer.Create`'s seed-anim case. This means **most
  real, already-existing `.comics` files' legacy-authored resting keyframes are silently misread as
  `end=200` today** (harmless only because nothing evaluates keyframes yet). Requirements'
  Acceptance Criterion 5 already approved "fix to match exactly" for newly-created layers; this
  generalizes the same fix to the read path, which is what actually matters for existing content.
  Fix is a coordinated three-spot change (`_animFromJson`'s fallback, `_animToJson`'s
  omit-comparison, both `200`→`0`, kept in sync per that file's own existing comment about why they
  must match; `models.dart`'s constructor default follows automatically) — see
  `03-specifications.md`'s Data Models section.

## Implementation Discoveries (2026-08-02, see 05-implementation-log.md for full detail)

- **`playhead` was NOT removed, contrary to the Specifications/Plan.** Implementation found
  `timeline.dart` deeply dependent on `playhead`/`totalFrames` as a closed 0..600 coordinate system
  — not an incidental reference. Asked Anton directly rather than guessing: he confirmed
  `addAnim`/`addSound` should still fully switch to `currentTime` (realizing Acceptance Criterion 6
  for the interpolation engine), accepting that `timeline.dart` will render newly-authored keyframes
  off-scale until its own later redesign. `playhead` is kept, untouched, now vestigial outside
  `timeline.dart` itself.
- **`InteractiveViewer`'s `constrained: true` (the untouched default) silently defeated the entire
  point of the fit-width canvas change** — documented in Flutter's own source as forcing a child to
  size itself to the viewport when true, exactly wrong for a child meant to be panned to reveal
  off-screen parts. Found via a real drag-gesture widget test (not assumed), fixed with
  `constrained: false`.
- **A real, silent correctness risk found via a real dataset file, not synthetic test data**:
  `KeyframeInterpolator`'s keyframe sort used Dart's `List.sort` (not documented as stable), while
  legacy's equivalent (`OrderBy`) is stable — and real files genuinely have multiple same-type anims
  tied on `Start=0` (the common no-explicit-start shape). Fixed by sorting on `(start,
  originalIndex)` explicitly.
- **Real production values, hand-verified**: opened
  `dataset/boranko/mahabharata/book1/comics_interactive/8a89f7d689fb441ea280cd782276bd7a.comics`
  directly, used its actual `TranslateAnim` data to hand-derive expected interpolation results —
  the implementation matched on the first run once the stable-sort fix landed.

## Fork History

N/A — new flow, not forked. Explicitly scoped narrower than `vdd-comics-editor-timeline` per
Anton's direct request; consulted three sibling flows for file/function pointers only (see Method
note in `01-requirements.md`).

## Next Actions

1. **Anton (or a future session) performs Task 5.2's real manual pass**: run the actual desktop
   editor, author a translate/alpha animation and pan through it, open a few real `dataset/` files
   and confirm resting layers place instantly (not a 200px slide-in), and confirm a real sound cue
   plays/loops/stops correctly.
2. Decide whether to move to the DOCUMENTATION phase now (client-facing README per VDD discipline)
   or treat Implementation as done pending Task 5.2's real pass first — ask rather than assume.
3. Separately, still open: what to do about `timeline.dart` itself (explicitly deferred, not
   decided) now that it's rendering off-scale for any newly-authored keyframe.
