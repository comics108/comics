# Test Cases: dot-comics-format

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-08-02
> Requirements: [01-requirements.md](01-requirements.md)

## Overview

Two deliverables, per Anton's request: (1) a catalog of every existing automated test anywhere in
this repo that touches the `.comics` format, so this doesn't get re-derived blind; (2) cases-first
behavioral analysis (Given/When/Then) for `.comics` format correctness across three legacy v2012
codebases, the v2.8/2026 editors, and four v2026 viewer implementations — covering format/
orientation defaults, device screen orientation, animation-type history, and layer classification.
Produced by three parallel research passes (v2012 legacy, a full flow sweep + test catalog, and the
three non-Android v2026 viewers), plus direct first-principles verification of one finding that
contradicted an existing code comment (see Bugs, B1).

**Everything below is cited to real file:line locations, not inferred.** Where a claim could not be
verified, that's stated explicitly rather than assumed.

---

**Note (2026-08-07): a suspected "v2026 format change" here was actually a different, unrelated
format (Lottie), now split out.** While comparing samples, a file then-named `sample_v2026.comics`
turned out to be genuine Lottie/Bodymovin JSON, not an extension of this flow's classic
`Comics.Editor.Models` schema. Anton confirmed this and renamed the fixtures (`sample.lottie`,
`mahabharata-dot-lottie`) to stop implying it was a `.comics` version. That entire investigation —
container shape, the Lottie schema details, the vendored-but-unused iOS Lottie engine found in
`apps/mahabharata-mobile-swift-v2026`, and the 7-of-43-produced episode comparison — now lives in
its own flow: **`flows/tdd-dot-lottie-format/`**. Nothing in Parts 1-3 below was affected by this
confusion — they were always scoped to the classic lineage only, and remain accurate as originally
researched. See that flow if Lottie/`.lottie` content is what you're looking for.

---

**A real v2012-shaped sample exists**: `samples/sample_v2012.comics` (Anton pointed to this directly
— none of the research agents knew it existed, since no 2012 test fixtures were found anywhere in
the repo proper). Inspected directly for this document: standard zip (`data.json` + `layers/*.png`,
same `_1000_col_row.png` tiling convention as current files), top-level shape exactly
`{width, height, layers, sounds}` (`width=1080, height=12000`, no orientation field — direct
confirmation, not inference), 177 layers / 2 sounds, anim type distribution `TranslateAnim:307,
RotateAnim:155, ScaleAnim:32, AlphaAnim:30` (**zero `SoundAnim` inside any `Layer.animations`** —
direct real-file confirmation of the B2/E3 invariant), no `kind`/`style`/`translations`/`preview`
keys anywhere, `$type` strings identical to current files
(`"Comics.Editor.Models.TranslateAnim, Comics.Editor"`, etc.), `SoundAnim` entries carry an explicit
`"type": 4` while `TranslateAnim` entries omit `type` entirely (matches the documented
`DefaultValueHandling.Ignore`-on-enum-default behavior). Two `TranslateAnim`s tied on implicit
`Start=0` appear in this file too (layer `023_{0}_{1}_{2}.png`), same real pattern as the 2026
dataset file used in `vdd-comics-editor-vertical-scroll`'s Task 5.1 — confirms that stable-sort fix
matters for the whole format's history, not just modern content. **New finding, not previously
known**: one real `SoundAnim` has `start: -38` (negative) — a genuine real-world case worth its own
test (Category A6 below). This file changes Test Case A5's status from "needs new tooling to obtain
a 2012 sample" to "the sample already exists, ready to use directly."

---

## Part 1 — Existing Test Coverage Catalog

### Dart/Flutter — `apps/comics-editor/test/` — 49 files, ≈260 cases

The only test suite in the entire repo with real, substantial `.comics`-format coverage. Grouped by
what they exercise (file → what it covers → approx. case count):

**Data model / serialization**
- `models_mapping_test.dart` → `kind`/`style`/`translations` round-trip, legacy-layer byte-identity → 6
- `dataset_backward_compat_test.dart` → opens every real `.comics` file in `dataset/`, no crash, resave fixed-point → 2
- `temp_folder_test.dart` → `tempFolder` threading through both cores → 3
- `tile_writer_test.dart` → 512px tiling matches `FileManager.cs`/`ImageMagick.cs` → 12
- `image_slot_test.dart` → `Images[]` slot resolution via `LanguageRegistry` → 6
- `controller_image_bytes_test.dart`, `image_picker_test.dart` → real image byte round-trip → 3, 4
- `kind_field_test.dart`, `kind_chip_test.dart` → kind dropdown/chip rendering → 4, 3
- `language_registry_test.dart` → dynamic language list from `assets/languages.json` → 5

**Animation/timeline (scroll-position-driven `Anim` model)**
- `keyframe_interpolator_test.dart` → Dart port of `Anim.cs`'s `FindNearest`/`Factor`/`Interpolate` → 14
- `real_file_interpolation_test.dart` → real file, hand-derived interpolation check → 1
- `sound_gating_test.dart` → port of `SoundAnim.FindCurrent`/`SoundViewModel.Scroll` → 10
- `current_time_test.dart` → `currentTime` (pan-derived, replaces `playhead`) → 5
- `canvas_view_interpolation_test.dart`, `canvas_layout_test.dart`, `canvas_boundary_test.dart` → rendering/layout/pan → 2, 2, 1
- `edit_history_test.dart`, `controller_undo_redo_test.dart` → undo/redo → 11, 9

**Lettering/balloon, Cutting/segmentation, core/bridge plumbing** (real format interaction, but
feature-UI-focused rather than format-correctness-focused): `balloon_ai_client_test.dart`,
`balloon_editor_card_test.dart`, `balloon_rail_test.dart`, `balloon_stepper_test.dart`,
`properties_panel_balloon_test.dart`, `mode_switch_test.dart`, `lettering_{desktop,phone,tablet}_test.dart`,
`cutting_client_test.dart`, `cutting_canvas_test.dart`, `cutting_session_test.dart`,
`cutting_region_rail_test.dart`, `cutting_review_card_test.dart`, `cutting_mode_switch_test.dart`,
`cutting_stale{,_banner}_test.dart`, `cutting_zoom_control_test.dart`, `cutting_desktop_body_test.dart`,
`cutting_cross_device_test.dart`, `cutting_real_end_to_end_test.dart`, `process_cutting_client_test.dart`,
`multimodal_paths_test.dart`, `library_browser_test.dart`, `core_client_test.dart`, `ffi_core_test.dart`,
`dart_io_core_test.dart`, `widget_test.dart`, `confidence_badge_test.dart`, `app_version_test.dart` —
roughly 140 more cases across these, not itemized here since they test features built *on* the
format, not the format's own correctness.

### Python — `apps/comics-ai/comics-ai-baloons/tests/` — 19 files, ≈78 cases

`test_comics_io.py` (zip round-trip fidelity), `test_layout.py`, `test_discover.py` (structural
balloon detection: 2+ populated same-size image slots), `test_extract.py`, `test_erase.py`,
`test_classify.py`, `test_match.py`, `test_ocr.py`, `test_csv_loader.py`, `test_languages.py`
(Cultures-order match against the editor enum), `test_render_{latin,shaped,handlettered}.py`,
`test_lettering_features.py`, `test_tiling.py` (512px grid vs. known-good sample), `test_package.py`,
`test_pipeline.py`, `test_report.py`.

### Python — `apps/comics-ai/comics-multimodal/tests/` — 20 files, ≈124 cases

`test_resting_position.py` — **directly exercises real `$type`-discriminated Anim JSON** pulled
verbatim from real dataset files (crossfade/rotate/scale/no-alpha/empty-list/out-of-order-keyframes
cases) → 10. `test_kind_heuristic.py` (kind inference across all real dataset files) → 5.
`test_render_canvas.py` (layer ordering, alpha-0 exclusion, real dimension match) → 3.
`test_baloons_bridge.py`, `test_route_balloons.py`, `test_dataset.py`, `test_detect_panels.py`,
`test_align_photo.py`, `test_augment.py`, `test_build_library.py`, `test_package.py` (packages a
photo into a valid, reopenable `.comics` file), plus segmentation-model tests
(`test_infer_segmenter.py`, `test_maskrcnn.py`, `test_unet_baseline.py`, `test_train_segmenter.py`,
`test_train_maskrcnn_smoke.py`, `test_segment_image.py`) and eval/reporting tests
(`test_evaluate.py`, `test_unmatched_candidates.py`, `test_report.py`).

### Confirmed ZERO automated tests exist in:

- `libs/comics_viewer/comics-viewer-android/` — no test source set populated at all.
- `libs/comics_viewer/comics-viewer-ios/` — has an empty `Tests/ComicsViewerTests/` target
  declared in `Package.swift:20-22` but **zero source files**, not even committed to git. Compiles
  standalone via SwiftPM, so tests *could* be written here today.
- `libs/comics_viewer/flutter_comics_viewer/` — only leftover `flutter create --template=plugin`
  boilerplate tests (`getPlatformVersion()`), zero comics-related coverage.
- `libs/comics_viewer/react-native-comics-viewer/` — `src/__tests__/index.test.tsx` is a literal
  `it.todo('write a test')` placeholder.
- `apps/comics-editor/native/Comics.Editor/` (the real C# WPF editor, all subprojects) — no test
  projects exist.
- `legacy/comics-editor-v2.8/` — no tests.
- `legacy/mahabharata-mobile-java-v2012/` — no `test`/`androidTest` source directories exist.
- `legacy/mahabharata-mobile-swift-v2012/` — no XCTest target exists.
- `legacy/comics-admin-v2012/` — only generic ASP.NET Web API "HelpPage" scaffolding matches "Test"
  in the filename; unrelated to comics data.

**Implication**: any legacy-compatibility or multi-viewer-parity test case defined below has **no
existing fixture/oracle to reuse** on the legacy or non-Android-viewer side — these need to be
authored from scratch, informed by the exact algorithms cited in Part 2.

---

## Part 2 — Background Facts (from the flow sweep, condensed; full citations in the research —
available on request, kept out of this doc to stay readable)

- **No orientation/axis flag has ever existed in the format, at any generation.** `Comics`/`ComicsDoc`
  has always been just `{width, height, layers, sounds}` — confirmed in 2012 Java (`Comics.java:18-
  19`), 2012 Swift (`Comics.swift:13-14`), v2.8 (`Comics.cs:17,19`), and current
  (`models.dart:189-190`). The format was never explicit about orientation; every generation's
  *implementation* (scroll axis, default canvas proportions taller than wide) is vertical-only by
  convention, not by a stored flag.
- **`comics-admin-v2012` is not an original/earlier editor.** It has no `Layer`/`Anim`/`Sound`/
  `Comics` model classes at all — it's a CMS that stores the whole comic as an opaque uploaded
  archive blob, and its own "Editor" folder literally just bundles a downloadable `ComicsEditor_2.8.zip`.
- **Animation types (translate/rotate/scale/alpha/sound) have existed unchanged since 2012**, with
  identical field shapes on Java and Swift, and are byte-identical between legacy v2.8 and current
  `apps/comics-editor/native/Comics.Editor/Models/` (confirmed via `diff -rq`) **except for one
  addition**: `Layer.Kind`/`Style`/`Translations` (`vdd-comics-editor-uiux-lettering`, additive
  strings/dict, no schema migration needed since Newtonsoft's `MissingMemberHandling` defaults to
  Ignore). This is the **only** model-layer schema change in the project's entire history.
- **No looping or wall-clock-time-driven animation concept exists anywhere, in any generation.**
  `Anim.Factor(scroll)`/`interpolate(scrollOffset:)` is a one-shot cubic ease-out
  `(fraction-1)^3+1` between two scroll-position bounds, in Java, Swift, and C#, unchanged since
  2012. Sound's "looping" is real-time playback state gated by scroll-range membership, not a stored
  keyframe/format concept, on every platform.
- **Both 2012 reader apps lock the comic-reading screen to portrait**: Android
  `AndroidManifest.xml` (`ComicsActivity android:screenOrientation="portrait"`), iOS `Info.plist`
  (`UISupportedInterfaceOrientations` = portrait only, portrait-upside-down added for iPad). Neither
  app, nor v2.8, nor the current v2026 mobile viewer branches on device orientation at all — width
  is always normalized to viewport, height always scrolls, regardless of device shape or rotation.
  **Landscape support for actually viewing a comic does not exist anywhere in this codebase today**,
  2012 or 2026 — confirmed absent even in the modern multi-platform viewers (Part 3).
- **`Layer.Kind`/classification is confirmed 2026-only** — neither 2012 platform nor v2.8 has any
  kind/type/role field; every layer was always a generic, untyped visual element.
- Real dataset geometry: 27 `.comics` files, canvas heights **12,000–100,900px** (not a uniform
  ~33,000px as an earlier flow's single sampled file suggested), 86–297 regions/layers per file, 825
  multi-language balloon layers total (cross-confirmed independently by two different flows'
  counts).

---

## Part 3 — v2026 Multi-Platform Viewer Compatibility Matrix

| Viewer | Own parsing/animation engine? | Algorithm match to Android baseline | 5 anim types | JSON schema handling | Landscape | Tests |
|---|---|---|---|---|---|---|
| `comics-viewer-android` (reference) | Yes | — | Yes | Correct | Portrait-only (app-level) | None |
| `comics-viewer-ios` | Yes, real (`Sources/ComicsViewer/`) | **Identical** — same cubic `(t-1)^3+1`, same keyframe-pair walk, same default-absence-means-0 semantics | Yes | Correct, verified line-by-line | Portrait-only | **None** (empty test target, but compiles standalone — testable today) |
| `flutter_comics_viewer` | No — `PlatformView` wrapper delegating to the real Android/iOS libs | Inherited, not reimplemented | Yes (inherited) | Inherited (correct) | Not enforced by the plugin itself; bundled example app defaults to Flutter-template landscape-permitted | Boilerplate-only, 0 comics tests |
| `react-native-comics-viewer` | No — native-view wrapper delegating to the same libs (vendored `.aar`/pod) | Inherited, not reimplemented | Yes (inherited) | Inherited (correct) | Portrait-only, explicit in bundled example | `it.todo(...)` placeholder only |

**Practical implication**: only `comics-viewer-ios` is a genuine second implementation worth
independent format-compatibility test cases today. Flutter/RN packages are thin bridges — the
appropriate test cases for them are bridge-contract tests (argument marshalling, event callbacks),
not format-parsing tests, since they have no parsing code of their own to diverge.

**RN-specific known gap, not a format bug but must not be mistaken for one**: `src/index.tsx:114-
154` — `getScrollPosition()` always returns `0`; `isPlaying`/`duration`/`currentPosition` are
hardcoded stubs (`false`/`0`/`0`), explicitly commented as unimplemented. Any bridge-contract test
for RN must treat these four accessors as known-broken.

---

## Part 4 — Confirmed Bugs Found During This Research (not test cases — concrete defects)

These surfaced *from* the cases-first analysis below, not the other way around — listed here first
since they're actionable findings, then referenced from the relevant test cases.

### B1 — `models_mapping.dart`'s `scaleX`/`scaleY`/`alpha` JSON defaults are wrong (same bug class as the `end` bug Task 1.1 already fixed)

**Verified directly against source, not inferred**: `legacy/comics-editor-v2.8/Comics.Editor/Models/
{ScaleAnim,AlphaAnim,PivotAnim}.cs` have **no `[DefaultValue]` attributes** on `ScaleX`/`ScaleY`/
`Alpha`/`PivotX`/`PivotY` — confirmed by direct grep of each file. This means Newtonsoft's
`DefaultValueHandling.Ignore` (`Extensions.SerializerSettings`) omits these fields from JSON exactly
when their value is C#'s implicit `default(double) == 0`, never `1`.

`ScaleAnim.Init()`/`AlphaAnim.Init()` (which set `ScaleX=ScaleY=1`/`Alpha=1`) are called **only**
from `Anim.FindNearest`'s synthetic-fallback-instance path (`prev = new T(); prev.Init();`, used
when a layer has zero anims of that type) — **never during normal JSON deserialization of a real
anim object**, which just does `new ScaleAnim()` (fields at C#'s plain `0` default) and overwrites
whatever keys are actually present in the JSON. An earlier flow's own code comment
(`models_mapping.dart:122-133`, from `vdd-comics-editor-uiux-lettering` Task 7.1) asserts the
opposite — "deserialization leaves it at... the C# object's `Init()`-assigned value of 1" — **this
reasoning is incorrect**, confirmed by reading `ScaleAnim.cs`'s actual field declarations (`private
double _scaleX;` with no initializer) and `Init()`'s real call site.

**Current Dart behavior** (`models_mapping.dart:72-73,76`):
```dart
anim.scaleX = _asDouble(json['scaleX'], 1);   // should default to 0
anim.scaleY = _asDouble(json['scaleY'], 1);   // should default to 0
anim.alpha = _asDouble(json['alpha'], 1);     // should default to 0
```
`pivotX`/`pivotY` (`models_mapping.dart:74-75`, `_asDouble(json['pivotX'])`, default `0`) are
**correct** — no bug there.

**Real-world impact, assessed not assumed**: for `scaleX`/`scaleY`, low — there's no
automatic-seeding pattern for `ScaleAnim` the way `Layer.Create` seeds a zero-value `TranslateAnim`,
so a real `ScaleAnim` with a genuinely-absent `scaleX` key (true value `0`, i.e. a "shrink to
nothing" keyframe) would be unusual authored content. For `alpha`, **higher** — `alpha=0` (fully
invisible, e.g. a fade-out's endpoint) is a plausible, ordinary thing to author, so a real file could
plausibly trigger this today, currently misread as `alpha=1` (visible) instead of `0` (invisible).
**Not yet fixed** — flagged for a decision, not silently patched mid-TDD-flow. See Test Case E4.

### B2 — Android's `LayerAnimTypeAdapter` excludes `SOUND` from its type-dispatch map; Swift's equivalent does not

`libs/comics_viewer/comics-viewer-android/.../model/LayerAnimTypeAdapter.java:21-26,34` only
registers TRANSLATE/ROTATE/SCALE/ALPHA in its `TYPES` map (correct today, since `SoundAnim` is never
nested inside a `Layer.animations` array in real data — it only ever appears inside
`Sound.animations`) but would throw `RuntimeException("Unknown class: SOUND")` if it ever were.
Swift's `AnimWrapper` (`Anim.swift:21-45`, both in `mahabharata-mobile-swift-v2012` and
`comics-viewer-ios`) handles all 5 cases generically and would silently succeed in the same
hypothetical case. Not a bug in current real-data usage (the case never occurs), but a latent
cross-platform inconsistency worth an explicit test asserting the *documented* invariant ("a
`SoundAnim` never appears in `Layer.animations`") rather than leaving each platform to behave
differently by accident if that invariant is ever violated.

### B3 — Swift's own commented, unfixed interpolation edge case

`legacy/mahabharata-mobile-swift-v2012/.../Anim.swift:96` has a developer comment reading `//ERROR:
0 is not transformed into 0` on the cubic-ease-out line — a self-acknowledged, never-fixed bug in
the 2012 Swift interpolation math (a fraction of exactly `0` apparently doesn't cubic-ease back to
exactly `0`). Not yet independently re-verified by this research pass (the agent found and quoted
the comment but did not re-derive whether `pow(0-1,3)+1` really deviates from `0` — it doesn't:
`(-1)^3+1 = -1+1 = 0` exactly, so this specific formula is fine at `fraction=0`; the comment may
refer to a floating-point precision edge case, or predate a fix, or refer to a different code path
not fully identified). **Flagged as needing a closer look, not asserted as a live bug** — see Test
Case E5.

---

## Part 5 — Cases-First Behavioral Analysis

### Category A — Legacy v2012 reader compatibility

**A1 — Real `.comics` file, all 5 anim types, opens without error on both 2012 platforms' data model**
- Given: a real `.comics` file's `data.json`, deserialized against the 2012 Java `Comics`/`Layer`/
  `Anim` classes and the 2012 Swift equivalents
- When: parsed
- Then: no exception; every `Layer.animations` entry resolves to one of TRANSLATE/ROTATE/SCALE/ALPHA
  (never SOUND, per B2's documented invariant); every `Sound.animations` entry resolves to
  `SoundAnim`
- Design implication: a compatibility test harness needs either a real 2012 build target or a
  faithful re-implementation of the 2012 deserialization rules to test against, since no 2012 test
  infra exists to reuse (Part 1)

**A2 — Cubic ease-out interpolation produces identical output across Java 2012 / Swift 2012 / C# v2.8 / current Dart, for the same input**
- Given: the same `(prevValue, currValue, currentTime, currStart, currEnd)` tuple
- When: each platform's own interpolation function is evaluated
- Then: all four produce the same result within floating-point tolerance (Java/C# use
  `float`/`double` mixed, Swift uses `Double` throughout, Dart uses `double` — precision-boundary
  test needed, not just formula-shape equality)
- Edge case: `currentTime` exactly at `currStart` (fraction=0) and exactly at `currEnd` (fraction=1)
  — confirm all four platforms agree these are exact, not near-miss due to floating point

**A3 — A layer with zero `TranslateAnim`s (malformed/hand-edited data) falls back to each platform's own resting default, and the four defaults agree**
- Given: a `Layer` with an empty `animations` array (translate type absent entirely)
- When: rendered at any scroll position
- Then: Java/Swift/C# all render at `(x=0, y=0)` (no `Init()` call happens for translate — it has no
  override); confirm current Dart's `KeyframeInterpolator.translateAt`'s fallback-to-layer's-static-
  translate behavior is a **deliberate, documented deviation** (per `03-specifications.md` in
  `vdd-comics-editor-vertical-scroll`), not an accidental mismatch — this is Won't-Have-parity by
  design, but must be labeled as such, not silently assumed identical

**A4 — Sound point-trigger (Start==End) plays once and does not replay on backward scroll, identically on Java 2012 / Swift 2012 / current Dart**
- Given: a `SoundAnim` with `Start==End==3000`
- When: scroll crosses 3000 downward, then later crosses back upward past 3000
- Then: plays exactly once (on the downward crossing), never on the upward crossing, on all three
  platforms — Dart already has this exact case tested (`sound_gating_test.dart`); Java/Swift 2012
  have no automated test for it (Part 1) despite having the identical `SoundAnim.FindCurrent`-
  equivalent logic (`Sound.java:98-112`, `ImageScrollView.swift:271-316`)

**A5 — Real v2012-shaped sample opens, resolves every layer's resting position, cross-checked hand-derived against the real JSON**
- Given: `samples/sample_v2012.comics` (a real sample, pointed to directly by Anton — 177 layers, 2
  sounds, `width=1080, height=12000`), parsed against 2012 Java/Swift model classes (current Dart's
  equivalent parsing is already covered in spirit by `real_file_interpolation_test.dart` using a
  different, 2026-dataset file)
- When: opened and each layer's resting translate/rotate/scale/alpha values computed at a few sample
  scroll positions
- Then: hand-derive expected values from the real JSON (same method as
  `vdd-comics-editor-vertical-scroll`'s Task 5.1) and confirm the 2012 Java/Swift algorithms produce
  them — **this specific cross-platform check does not exist today and would need a small standalone
  harness to actually run the 2012 Java/Swift parsing code** (neither 2012 app has a test target),
  but the sample file itself is no longer a blocker — it exists and has already been inspected
  directly for this document (see the note above Category A)

**A6 (new, from the real sample) — A `SoundAnim` with a negative `Start` (`start=-38`, confirmed real
in `samples/sample_v2012.comics`) is handled identically (no crash, no special-case branch needed)
by every platform's numeric comparison-based `FindCurrent`/gating logic**
- Given: `SoundAnim{start: -38, end: 7377}` and a `currentTime`/scroll sequence that starts below
  zero and crosses upward through the range
- When: evaluated by `SoundAnim.FindCurrent`-equivalent logic on any platform (all of it is plain
  numeric comparison — `start <= scroll && end >= scroll`, no assumption that `start >= 0` anywhere
  in any implementation read during this research)
- Then: works correctly with no special handling required — algebraically negative `start` doesn't
  break the comparison-based logic on any platform; this is a confirmation case, not a known bug,
  but worth an explicit test since it's a real value nobody had previously verified against

### Category B — Format/orientation selection defaults

**B1 — No `.comics` file specifies an orientation; default behavior across all implementations is vertical continuous strip**
- Given: any real `.comics` file (all 27 in `dataset/` confirmed to have no orientation field)
- When: opened by any of the 6 real implementations (2012 Java/Swift, v2.8, current editor, Android/
  iOS v2026 viewers)
- Then: all six render/scroll it as a vertical strip (width fit to viewport, height scrolled) — this
  is **implementation convention, not schema enforcement**; a test case here can only assert "every
  real implementation happens to agree," not "the format requires it"
- Design implication: if a genuinely horizontal ("century-old comic strip") document were ever
  authored (wide, short canvas, e.g. `width=10000, height=1080`), **no implementation has ever been
  tested against this shape** — Test Case B2 below defines what SHOULD happen, since nothing
  currently prevents someone from setting `width > height` today

**B2 — A hypothetical wide/short document (width > height) — schema decision made; engine work not yet built**
- Given: a `.comics` file with `width=10000, height=1080` (deliberately horizontal proportions)
- When: opened by any current implementation
- Then: **schema decision made (2026-08-02, Anton)** — the format gets an explicit **`scrollType`
  field** (proposed name, not yet confirmed verbatim: `"scrollType": "vertical" | "horizontal"` at
  the document root, alongside `width`/`height`), rather than inferring it from `width`/`height`'s
  relative magnitude. **Renamed from an earlier draft's `orientation`** — Anton clarified this must
  be a distinct concept/field from *device* orientation (see the independence principle below), so
  reusing the word "orientation" for both was a naming mistake, corrected here. **When the field is
  absent, it defaults to `"vertical"`, specifically for v2012 compatibility** — every real file that
  exists today (all 27 dataset files, every 2012/v2.8/2026-authored document,
  `samples/sample_v2012.comics`) has no such field and must keep behaving exactly as it does now,
  unchanged. This is a genuinely additive, non-breaking schema change: old readers that don't know
  the field simply never see it (Newtonsoft/Gson/`Decodable` all ignore unknown keys, per Category
  D3), and old files simply fall through to the same default every implementation already assumes
  today.
- **Engine work is still NOT built anywhere** — no implementation (2012, v2.8, current editor,
  Android/iOS viewers) yet reads or acts on this field, since it doesn't exist in any real file yet;
  defining the schema now is forward-preparation, not a claim that horizontal scrolling works today.
  See Test Case B4 for the concrete default-behavior assertion this decision implies.
- **UI-level decision (2026-08-02, Anton)**: the New Document dialog
  (`apps/comics-editor/lib/src/ui/widgets/dialogs.dart:17-50`, currently a two-option chooser —
  Comics vs. Puzzle, `DocType.comics`/`DocType.puzzle`) should show a **third option, labeled
  "century-old comic strip (horizontal infinity scroll)", visible but disabled** — signaling the
  direction is real and planned without committing to the engine work above yet. This is a UI/UX
  task, not a format/schema change on its own — see Test Case B3.

**B4 (new) — Absent `scrollType` field defaults to `"vertical"`, on every real file, old or new**
- Given: (a) any of the 27 real dataset files, (b) `samples/sample_v2012.comics`, (c) a freshly
  authored file from today's editor (which doesn't write this field yet, since the UI option is
  disabled) — none of which have a `scrollType` key
- When: parsed by any implementation that has been taught about the new field
- Then: all resolve to `scrollType = "vertical"`, producing byte-identical behavior to before the
  field existed — this is the specific regression guard that makes B2's schema addition provably
  non-breaking, not just assumed safe
- Design implication: whichever implementation is first taught to read this field (almost certainly
  the Flutter editor, since that's where the UI option lives) needs this exact default wired in from
  day one, with a test proving old real files are unaffected — matches the same discipline already
  used for the `end`/`scaleX`/`alpha` JSON-absence-default bugs found elsewhere in this document

**B5 (new) — `scrollType` (content axis) and device screen orientation (portrait/landscape) are independent parameters — neither implies or constrains the other**
- **Explicit principle, stated by Anton (2026-08-02)**: `scrollType` (`"vertical"|"horizontal"`,
  a `.comics`-format/content property) and device orientation (`portrait`|`landscape`, a
  reader-app/platform-level property — see Category C) must be modeled as two separate,
  independent axes, not coupled or inferred from each other.
- Given: any combination of `scrollType` × device orientation — vertical-content-on-portrait-device
  (today's only real-world case), vertical-content-on-landscape-device, horizontal-content-on-
  portrait-device, horizontal-content-on-landscape-device
- When: a reader app decides how to render/scroll a document
- Then: the decision must consult `scrollType` alone for "which axis does content scroll," and the
  device/OS orientation lock alone for "which way can the user hold the device" — **no
  implementation may hardcode an assumption that vertical-scroll requires portrait, or that
  horizontal-scroll requires landscape**, even though today's real apps happen to only ever exercise
  vertical+portrait (Category C1/C2) and that pairing will likely remain the common/recommended one
  in practice
- Design implication: neither the format schema nor any reader's config should ever derive one from
  the other (e.g. no "if `scrollType == horizontal` then force landscape" shortcut) — they're stored
  and read from genuinely separate places: `scrollType` lives in `data.json`; device orientation
  lives in platform config (`AndroidManifest.xml`'s `screenOrientation`, iOS `Info.plist`'s
  `UISupportedInterfaceOrientations`, Flutter's `SystemChrome.setPreferredOrientations`) and is
  never part of the `.comics` format at all, on any platform, in any generation checked

**B3 (new) — New Document dialog shows the horizontal-strip option as visible-but-disabled**
- Given: the New Document dialog (`dialogs.dart`)
- When: rendered
- Then: a third choice appears alongside Comics/Puzzle, labeled "century-old comic strip (horizontal
  infinity scroll)", rendered in a disabled/non-selectable visual state (matching whatever this
  app's existing disabled-control convention is — needs checking against `theme.dart`); tapping it
  does nothing (no `DocType` change, no `choice` state update); it does NOT appear in `DocType`
  (`models.dart:8`, `enum DocType { comics, puzzle }`) since no backing engine support exists yet —
  this is a pure UI affordance, not a new document type
- Design implication: this is a small, well-scoped Flutter UI change (add a third `_TypeCard`-style
  option, disabled), independent of the engine-level B2 question — belongs in its own
  Requirements→...→Implementation flow (or a quick addition to an active UI-facing flow), not this
  TDD flow's own scope, which only defines what "correct" looks like for the format/tests
  themselves. Flagging the boundary explicitly so this doesn't get built inside a TDD-Tests document
  by accident.

### Category C — Device screen orientation (portrait/landscape)

**C1 — Comic-reading screens are locked to portrait on both 2012 apps and are never tested for landscape**
- Given: `ComicsActivity` (Android 2012), the iOS 2012 app's comic view controller
- When: device is rotated to landscape
- Then: **cannot physically happen** — both platforms declare portrait-only for the comic-reading
  screen (manifest/plist level), so landscape rendering of a comic has literally never been
  exercised on 2012. This is a "the case doesn't exist" case, not a "the case passes" case — worth
  stating explicitly so a future test author doesn't assume landscape support was ever validated.

**C2 — v2026 landscape support does not exist in any viewer implementation checked**
- Given: any of the 4 v2026 viewers (android/ios/flutter/react-native)
- When: checked for explicit landscape enablement
- Then: none of the 4 declare or implement landscape comic-viewing; Flutter's bundled example app
  *permits* landscape only via unmodified template scaffolding (not a deliberate comics-viewing
  decision, per Part 3); RN's bundled example explicitly locks portrait. **The premise that "v2026
  supports landscape" (from the original request) is not yet true anywhere in this codebase** —
  flagged as a gap between stated intent and actual implementation, not something to write a passing
  test for today. If landscape support is a real, wanted v2026 feature, it needs its own
  Requirements→Specifications→Plan flow; this TDD flow can only define what "correct" would look
  like once that's designed (see Open Design Questions).

### Category D — Animation-type / kind-classification version history

**D1 — Real files authored under v2.8 or earlier never have a `Layer.Kind` value; files touched by the lettering flow onward may**
- Given: any of the 27 real dataset files
- When: checked for `Layer.Kind`
- Then: `dataset_backward_compat_test.dart` already asserts this for the whole dataset ("no layer in
  any of these pre-existing files has kind/style/translations set") — this is real, existing
  coverage, correctly labeled a Must-Have regression guard (a future accidental default-value change
  must not silently start writing `kind` onto legacy layers)

**D2 — All 5 base animation types (translate/rotate/scale/alpha/sound) round-trip identically whether the source file was authored in 2012-era tooling or the current editor**
- Given: a real anim entry using only fields available since 2012 (no `kind`/`style`/`translations`
  involved)
- When: opened and re-saved by the current editor
- Then: output is structurally equivalent (same fields, same values) to what 2012-era tooling would
  have produced for the same logical animation — this is implicitly covered by `diff -rq` showing
  the model files byte-identical since 2012/v2.8 (a structural guarantee), but **no test explicitly
  asserts this at the JSON level** — worth a dedicated round-trip test opening a real pre-lettering-
  era file and confirming the anim-related keys are unchanged after a save cycle (distinct from
  `dataset_backward_compat_test.dart`, which checks kind/style/translations specifically, not the
  base 5 anim types' own field stability)

**D3 — No loop/repeat field exists in any generation; a hand-crafted JSON with an invented `"loop": true` key is silently ignored (not an error), on every real implementation**
- Given: a `.comics` file with an anim entry containing an extra, non-schema `"loop": true` key
- When: parsed by Newtonsoft (C#), Gson (Android Java), `Decodable` (Swift)
- Then: all three ignore the unknown key silently (Newtonsoft: `MissingMemberHandling` defaults to
  Ignore; Gson: unknown JSON fields are ignored by default; Swift `Decodable`: unless
  `CodingKeys`-restricted with a custom strict decoder, unknown keys are ignored) — worth an explicit
  test confirming this rather than assuming it, since a strict decoder configuration would silently
  break on real files if ever introduced by mistake

### Category E — The confirmed bugs, as explicit test cases

**E1 (covers B1)** — Given a `ScaleAnim` JSON entry with no `scaleX`/`scaleY` keys, when parsed by
`models_mapping.dart`'s `_animFromJson`, then the result should be `scaleX=0, scaleY=0` (matching
C#'s true serialization convention) — **currently fails**, returns `1, 1`. Companion write-side case:
given an in-memory `Anim` with `scaleX=0`, when serialized, the `scaleX` key should be omitted
(matches `put()`'s existing 0-comparison, already correct on the write side) — write side is fine,
only the read side needs the fix.

**E2 (covers B1)** — Given an `AlphaAnim` JSON entry with no `alpha` key, when parsed, then the
result should be `alpha=0` (fully invisible) — **currently fails**, returns `1` (fully visible).
Higher real-world relevance than E1 per Part 4's assessment.

**E3 (covers B2)** — Given a hand-crafted `Layer.animations` array containing a `SoundAnim`-typed
entry (type ordinal 4) nested where only TRANSLATE/ROTATE/SCALE/ALPHA are expected, when parsed by
Android's `LayerAnimTypeAdapter`, then it throws `RuntimeException("Unknown class: SOUND")`; the
same input parsed by Swift's `AnimWrapper` decodes successfully into a `SoundAnim`. **This
divergence is real but currently unreachable from any real file** (the invariant "SoundAnim never
appears in Layer.animations" holds in all 27 real files) — the test case exists to *document and
guard* that invariant, catching it immediately if any future authoring path ever violates it,
rather than to fix a live bug.

**E4** — Given `Anim.swift:96`'s commented edge case, when `fraction=0` is passed through
`transformToCubic`, then verify algebraically and empirically that `pow(0-1,3)+1 == 0` exactly (this
research pass's own math check says yes) — if a real discrepancy is later found (e.g. a genuine
floating-point precision issue on-device, not reproducible via simple algebra), document the exact
input that triggers it; if not reproducible, downgrade this from "flagged bug" to "resolved,
stale comment" in Part 4.

### Category F — v2026 multi-platform viewer parity (see Part 3's matrix for the summary)

**F1** — Given the real `2a5e3303ba8c42e3ba395dad794164a7.comics` sample already used in
`comics-multimodal`'s `test_resting_position.py` fixtures, when parsed by `comics-viewer-ios`'s
`Sources/ComicsViewer` package (which has zero existing tests despite compiling standalone), then
its computed transforms at several scroll positions should match `comics-viewer-android`'s output
for the same input — **this test does not exist and should be the first one written for
`comics-viewer-ios`**, since it's the only non-Android viewer with real, independent parsing logic.

**F2** — Given `flutter_comics_viewer`/`react-native-comics-viewer`'s bridge methods
(`loadComics`, `setScrollPosition`, `play`/`pause`), when invoked from Dart/JS, then the correct
native method is called with the correct arguments — a channel-marshalling contract test, not a
format-parsing test (neither package has parsing logic of its own to test).

**F3** — Given RN's four stubbed accessors (`getScrollPosition`, `isPlaying`, `duration`,
`currentPosition`), when called, then confirm they return their documented stub values (`0`/
`false`/`0`/`0`) — a regression guard so a future real implementation is a deliberate, tested change,
not an accidental one; must NOT be mistaken for a format-compatibility test, since it's testing a
known limitation, not correctness.

---

## Completeness Check

- [x] All requirements have behaviors — every Acceptance Criterion area from `01-requirements.md`
      (legacy compatibility, format defaults, device orientation, animation history, kind
      classification, multi-platform parity) has at least one case above.
- [x] Edge cases identified — floating-point precision (A2), malformed/zero-anim layers (A3),
      direction-sensitive sound triggers (A4), unknown-key tolerance (D3), the two real bugs (E1/E2),
      a latent cross-platform divergence (E3).
- [x] Error scenarios defined — Android's `RuntimeException` case (E3), the currently-undefined
      wide/short document behavior (B2, explicitly left open rather than invented).
- [x] Design implications extracted — B2 and C2 both surface real, unresolved design questions
      rather than papering over them with an assumed answer.

## Open Design Questions (surfaced by this cases-first pass, need Anton's direction)

- [x] **B2 (UI half)**: **decided (2026-08-02)** — New Document dialog gets a third, visible-but-
      disabled "century-old comic strip (horizontal infinity scroll)" option (Test Case B3). Signals
      intent without committing to engine work.
- [x] **B2 (schema half)**: **decided (2026-08-02)** — yes, an explicit `scrollType` field
      (proposed name/values, not yet confirmed verbatim: `"vertical"`/`"horizontal"`; deliberately
      NOT named "orientation" — see B5, that word is reserved for device screen orientation, a
      separate independent concept). Absent → defaults to `"vertical"`, specifically so every
      v2012-through-2026 real file keeps behaving unchanged (Test Case B4). Still **not implemented
      anywhere** — this is the schema's intended shape, not a claim that any reader/writer has been
      taught about it yet. That implementation work (who writes it, who reads it, what "horizontal
      scroll" actually does once read) is a real, separate, not-yet-scoped follow-on — likely its
      own Requirements→Specifications→Plan flow
      once the disabled UI option is ever meant to become enabled.
- [x] **B5**: **decided (2026-08-02)** — `scrollType` (content) and device orientation
      (portrait/landscape) are independent parameters, never coupled or inferred from one another,
      even though vertical+portrait is the only pairing any real implementation exercises today.
- [x] **(2026-08-07) The Lottie/"ASHES.json" discovery is not this flow's concern anymore** —
      confirmed a genuinely separate format, extracted to `flows/tdd-dot-lottie-format/` per
      Anton's request. Its own open questions (is it a committed direction, how frame/time
      addressing reconciles with scroll-driven reading, where the vendored-but-unused
      `mahabharata-mobile-swift-v2026` Lottie engine fits) live there now, not here.
- [ ] **C2**: is landscape comic-viewing a real, wanted v2026 feature anywhere, or was that premise
      from the original request aspirational/mistaken? Nothing in this codebase implements it today.
- [ ] **B1 (bug)**: fix `scaleX`/`scaleY`/`alpha`'s JSON-absence defaults now (a small, isolated
      change, same shape as Task 1.1's `end` fix in `vdd-comics-editor-vertical-scroll`), or record
      it here and let a future flow handle it? Given `alpha=0` is a plausible real authored value,
      leaning toward fixing soon, but not done unilaterally here.
- [ ] **E3**: worth adding an explicit guard/assertion for the SoundAnim-never-in-Layer.animations
      invariant somewhere in the Dart codebase (since Dart's own `Anim` class is flat and doesn't
      have this platform-specific type-dispatch restriction at all — worth checking whether Dart's
      own parsing would even notice if this invariant were ever violated), or leave it purely as
      documentation?
- [ ] Should this flow proceed to a formal Specifications/Plan/Implementation phase (writing the
      actual new test files for A1-A5, F1, E1-E2 etc.), or does cataloging + cases-first analysis
      satisfy what Anton actually wanted from this flow? Not assumed — ask.

---

## Approval

- [ ] Reviewed by:
- [ ] Approved on:
- [ ] Notes:
