# Specifications: dot-lottie-import-export

> Version: 1.3 (2026-08-08: NEW — Export/Import Modes, Full Canvas vs. Playback Viewport, per
> `01-requirements.md` v0.3/`02-tests.md` v1.1's addition. Still DRAFT throughout, so amended
> directly rather than as a disclosed-correction callout like the v1.2 note below.)
> Status: APPROVED
> Last Updated: 2026-08-08
> Requirements: [01-requirements.md](01-requirements.md)
> Tests: [02-tests.md](02-tests.md)

## CORRECTION (2026-08-07) — Precomp Handling must generalize to arbitrary layer parenting, not just precomp children

While documenting the full `.comics` animation-type/Lottie-coverage inventory in
`flows/tdd-dot-comics-format`, all 7 real produced Lottie chapters were inspected directly (this
flow's own drafting had only reasoned from `ASHES.json`, per `tdd-dot-lottie-format`'s original,
now-corrected conversion-feasibility claim). Result: **Lottie's `parent` field (one layer's
transform expressed relative to another layer's, independent of precomp nesting) is used in 5 of
7 real chapters, and in `THE BROKEN TUSK` specifically, 190 of 295 layers (64%) use it** — a real
character rig built from named anatomical parts ("голова"/head, "руки сложен"/folded arms,
"предплечье"/forearm, confirmed real layer names) parented to each other, not a flat stack of
independent layers. The same chapter also has 1 real solid-color layer (`ty:1`); `THE CHASE` has 6
real masked layers; `SVAYAMWARA` has 1 real null/organizational layer (`ty:3`) — none of which this
Specifications draft's Won't-Have ("no shape/mask/text Lottie support") accounted for as *already
affecting real, already-produced content*, as opposed to a hypothetical future risk.

**UPDATE (2026-08-07, supersedes the paragraph below)**: `flows/tdd-dot-comics-format` has since
decided a real, persisted `Layer.ParentId` mechanism for `.comics` v2026 (hierarchical, editor-side
live-relative positioning, backward-compatible via the same "always persist resolved absolute
values" pattern already used for `GroupId`), plus a new `Layer.Id` (stable identity — a real
prerequisite) and a new organizational/non-content `Kind` value (the `SVAYAMWARA` null-layer case).
**This flow's import path should map Lottie's `parent` field directly onto `Layer.ParentId`**, not
bake-and-discard it — a better outcome, since the hierarchy survives into `.comics` and becomes
real, live-editable structure in the editor, not just a one-time-flattened import artifact. See
`flows/tdd-dot-comics-format/03-specifications.md`'s new "`Layer.ParentId` & Organizational Layers"
section for the full design this flow should target.

*(Original correction text, preserved for history, now superseded by the above)*: "`ImportPreview
.build`'s precomp-resolution step and `commitImport`'s `groupId`-baking behavior must generalize to
resolving each layer's full `parent` chain" — still directionally correct, but the fix is now
"map onto `ParentId`," not "bake into an absolute value with the hierarchy discarded." Masks
(`THE CHASE`) remain out of scope per the existing Won't-Have, but that exclusion now knowingly
drops real content from at least one real chapter — worth Anton's explicit re-confirmation, not a
silent carry-forward. See the Traceability Matrix and Open Design Questions at the end for how this
changes A3/D2's scope.

## Overview

Adds Lottie (`.lottie`, real Bodymovin JSON) import and export to `apps/comics-editor`. Import is a
review/triage step (parse → per-layer preview with clean/flagged status → two user choices
(time-base ratio, easing precision) → explicit commit); export is a simpler one-shot conversion.
Two new additive `EditorLayer` fields (`GroupId`, `TextRegion`) carry grouping (precomp- **and**
general-parenting-derived, per the correction above) and lettering-region data through both
directions. Every interface/data model below traces to a specific Test Case in `02-tests.md` — see
the Traceability Matrix at the end.

**NEW (2026-08-08)**: both directions now take an explicit `ExportImportMode` — **Full Canvas**
(the whole tall canvas, identity time-basis, today's existing assumptions, just named) or
**Playback Viewport** (a viewport-sized composition, scenes take turns sweeping past it at an
assumed constant scroll speed, per-layer motion composed as scroll-basis + time-basis `Anim`s).
See `01-requirements.md`'s Export/Import Modes section for the real byte-level grounding
(`samples/sample_v2012.comics_unzip` for Full Canvas, `samples/sample_playback_viewport
.lottie_unzip` for Playback Viewport) and `02-tests.md`'s Category G for the behavioral cases.
Playback Viewport mode's scroll+time composition is not a new mechanism this flow invents — it
directly reuses `apps/comics-editor`'s already-shipped `Anim.basis`/`ComicsDoc.scrollType`
(`flows/tdd-dot-comics-format`'s Plan, Phases 2 and 5).

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `apps/comics-editor/lib/src/ui/models.dart` | Modify | Add `EditorLayer.groupId` (String?) and `EditorLayer.textRegion` (TextRegion?) |
| `apps/comics-editor/lib/src/bridge/models_mapping.dart` | Modify | `_animFromJson`/`_animToJson`-equivalent additive read/write for the two new fields |
| `apps/comics-editor/lib/src/bridge/lottie_mapping.dart` (new) | Create | Lottie JSON ↔ an intermediate `LottieDocument` model — parsing/writing, independent of `.comics` |
| `apps/comics-editor/lib/src/ui/lottie/lottie_import.dart` (new) | Create | `LottieDocument` → `ImportPreview` (per-layer clean/flagged status, grouping) → commit → mutates `ComicsDoc` |
| `apps/comics-editor/lib/src/ui/lottie/lottie_export.dart` (new) | Create | `ComicsDoc` → `LottieDocument` → JSON |
| `apps/comics-editor/lib/src/ui/widgets/lottie_import_dialog.dart` (new) | Create | The review screen (Category A) + two choice controls (Category B) |
| `apps/comics-editor/lib/src/ui/widgets/top_bar.dart` or `dialogs.dart` | Modify | New "Import from .lottie" / "Export to .lottie" menu entries — not a repurposing of the existing Export button (`top_bar.dart:240-243`, confirmed a different, existing `.comics`-to-`.comics` mechanism) |
| `apps/comics-editor/lib/src/ui/anim/keyframe_interpolator.dart` | None | Consumed, not modified — imported `Anim`s must already be valid input to the existing interpolator, not a parallel engine |

## Architecture

### Component Diagram

```
Import direction:
  .lottie file --> [mode: fullCanvas | playbackViewport, chosen or detected] --> LottieDocument
                    (lottie_mapping.dart, pure parse)
                        |
                        v
                  ImportPreview (lottie_import.dart)
                  -- per-layer: clean | flagged(reason) | grouped(with N members) | scened(index)
                  -- pending choices: easingPrecision (both modes); scrollSpeed (playbackViewport
                     only -- fullCanvas mode skips this choice entirely, per Test G1)
                        |
                        v
              [Review screen UI -- user adjusts choices, sees flags]
                        |
                   commit()                cancel() --> no-op (A4)
                        |
                        v
              ComicsDoc mutation: N EditorLayers, Anims, groupId tags, TextRegions

Export direction:
  ComicsDoc --> LottieDocument (lottie_export.dart, deterministic, no user review step)
                        |
                        v
                  .lottie file (JSON, zipped alongside referenced image assets)
```

### Data Flow

```
Import: file picked -> lottie_mapping.parse(bytes) -> LottieDocument
     -> user (or auto-detect, per Open Design Question) picks ExportImportMode
     -> lottie_import.buildPreview(LottieDocument, mode) -> ImportPreview

     [mode == fullCanvas]
        (walks LottieDocument.layers; ty:2 => clean; ty:4/5/mask-bearing => flagged;
         ty:0 precomp => resolve nested comp asset's layers, tag with one new groupId;
         frame numbers used AS-IS as .comics scroll-pixel start/end -- identity, no ratio,
         no scroll-speed prompt at all, per Test G1/G2)

     [mode == playbackViewport]
        (walks LottieDocument.layers looking for the real root-sweep shape confirmed in
         samples/sample_playback_viewport.lottie_unzip: root-level ty:0 layers, each with
         exactly one position keyframe pair spanning most of that layer's own ip/op range --
         each such root layer becomes one "scene"; the sweep's total pixel distance / duration,
         combined with the user-supplied or file-derived scroll speed, produces that scene's
         .comics scroll-position range; each scene's own child layers' local keyframes import as
         scroll-basis Anims by default (heuristic (a), Test G5) -- NOT YET split into a real
         time-basis overlay; that split is Requirements' still-open heuristic (b)/(c))

     -> user sets ImportPreview.easingPrecision (or accepts default); timeBaseRatio only applies/
        appears at all in playbackViewport mode (fullCanvas mode has no such dialog, per G1)
     -> user commits -> lottie_import.commit(preview, doc)
        (for each clean/grouped/scened layer: create EditorLayer; for each animated property
         (p/r/s/o): create Anim entries per the mode-specific frame->scroll-pixel mapping above;
         easing handles -> either matched via curve-fit (exact) or passed through as Easy-Ease
         equivalent (approximation) -- both currently produce .comics's one fixed cubic ease-out
         per Test B3's finding, so this choice is real but not yet observably different in output)

Export: doc -> lottie_export.build(doc, mode, timeBaseRatio, easingPrecision)

     [mode == fullCanvas]
        (composition w/h = doc.width/doc.height; frame numbers = start/end directly, no ratio,
         per Test G1)

     [mode == playbackViewport]
        (composition w/h = the supplied viewport size; DECIDED 2026-08-08 -- the canvas is
         partitioned into scenes as sequential ComicsDoc.preferredViewportHeight-tall bands (the
         new tdd-dot-comics-format field, default 1600), since .comics has no scene concept of its
         own at all -- confirmed by direct inspection of samples/sample_v2012.comics_unzip/data.json,
         whose only top-level keys are width/height/layers/sounds, no scene marker of any kind; each
         band becomes one precomp with one root-level position keyframe pair sweeping it past the
         viewport at the supplied/detected constant scroll speed; each layer's scroll-basis Anim
         contributes to that sweep's baseline, any time-basis Anim composes on top per
         KeyframeInterpolator's already-shipped composition rule, unchanged, just consumed here)

     -> for each EditorLayer: one Lottie ty:2 layer; groupId-sharing layers -> one shared precomp
        asset instead of N independent root layers; TextRegion (shape:polygon) -> masksProperties
     -> JSON encode + zip alongside referenced image assets -> .lottie file
```

## Interfaces

### New Interfaces

```dart
// lib/src/bridge/lottie_mapping.dart
/// Minimal Lottie/Bodymovin JSON model -- only what this flow's Test Cases need
/// (image layers, precomps, position/rotation/scale/opacity keyframes, vector
/// masks). Deliberately does not model shape/text/gradient/repeater content --
/// those are represented only as [LottieLayer.unsupportedReason], per Test A2.
class LottieDocument {
  LottieDocument({required this.width, required this.height, required this.frameRate,
      required this.inPoint, required this.outPoint, required this.layers, required this.assets});
  final int width, height;
  final double frameRate, inPoint, outPoint;
  final List<LottieLayer> layers;
  final List<LottieAsset> assets; // includes precomp assets (id + nested layers) and image assets
}

class LottieLayer {
  // ty: 2=image (supported), 0=precomp (supported, resolved via LottieDocument.assets),
  // 1=solid/3=null/4=shape/5=text/other=unsupported (Test A2) -- `unsupportedReason` is non-null
  // exactly when ty is not 2 or 0, or when ty==2 but a mask/effect this flow doesn't model is
  // present. CORRECTED 2026-08-07: ty:1 (solid) and ty:3 (null) are now explicitly named here,
  // not lumped into "other" -- both are confirmed present in real content (THE BROKEN TUSK,
  // SVAYAMWARA respectively), so their unsupported-reason strings need to be specific and
  // legible in the review screen, not a generic "unsupported layer type."
  final int type;
  final String name;
  final String? refId; // for precomp layers, references LottieDocument.assets' id
  final int? parent; // CORRECTED 2026-08-07, UPDATED 2026-08-07: Lottie's `parent` field (index of
                      // another layer in the SAME composition this layer's transform is relative
                      // to) -- confirmed real, in 5/7 chapters, up to 64% of layers in one. Maps
                      // directly onto the new `EditorLayer.parentId` (see
                      // tdd-dot-comics-format/03-specifications.md) on import -- NOT baked into an
                      // absolute-only value with the relationship discarded. Distinct from
                      // `refId`'s precomp-asset relationship, which is a different, narrower kind
                      // of nesting (still needs its own resolution, but now also produces
                      // `parentId` tags for its resolved children, not just a `groupId`).
  final String? unsupportedReason;
  final LottieTransform transform; // p/r/s/o, each either a static value or a keyframe list
  final LottieMask? mask; // vector path, for Test C2/D3 -- confirmed real in THE CHASE (6 layers)
}

/// Parses raw bytes into [LottieDocument]. Throws a typed exception (not a
/// generic FormatException) on missing required top-level keys, per Test F1 --
/// callers use the exception type to short-circuit before ever building a
/// preview/review screen.
LottieDocument parseLottieDocument(Uint8List zipBytes);

/// The inverse -- builds a real, zippable Lottie file from a document.
Uint8List writeLottieDocument(LottieDocument doc, {required List<AssetFile> assetFiles});
```

```dart
// lib/src/ui/lottie/lottie_import.dart (NEW enum 2026-08-08, per 01-requirements.md's
// Export/Import Modes section -- grounded in samples/sample_v2012.comics_unzip (fullCanvas) and
// samples/sample_playback_viewport.lottie_unzip (playbackViewport))
enum ExportImportMode { fullCanvas, playbackViewport }

enum LayerPreviewStatus { clean, flagged, missingAsset }

class LayerPreview {
  LayerPreview(this.sourceLayer, this.status,
      {this.reason, this.groupId, this.groupName, this.sceneIndex});
  final LottieLayer sourceLayer;
  final LayerPreviewStatus status;
  final String? reason;       // populated when flagged/missingAsset (Test A2, F2)
  final String? groupId;      // shared across a precomp's resolved member layers (Test A3)
  final String? groupName;    // the precomp's own `nm`, shown as "(from precomp '<name>')"
  final int? sceneIndex;      // NEW: which recovered scene (root-sweep precomp) this layer
                               // belongs to -- only set when mode == playbackViewport (Test G4/G5);
                               // null in fullCanvas mode, where there's no scene concept at all
}

enum EasingChoice { exactCubicFit, easyEaseApproximation }

/// The review screen's whole data model (Category A + B + G). [mode] is
/// chosen before the preview is built, not after -- it changes how layers
/// are classified in the first place (Test G1 vs G4/G5), not just how the
/// resulting Anims get scaled.
class ImportPreview {
  ImportPreview(this.document, this.mode, this.layers);
  final LottieDocument document;
  final ExportImportMode mode;
  final List<LayerPreview> layers;

  /// Pixels-per-frame. Only meaningful, and only ever shown in the review
  /// screen, when [mode] == playbackViewport (Test G4/G6) -- Full Canvas
  /// mode is always identity and has no such dialog at all (Test G1/G2).
  /// DECIDED 2026-08-08, grounded in exact computation on real data:
  /// [ImportPreview.build] auto-derives this from the detected root-sweep
  /// keyframes' own position-delta/frame-delta (confirmed real content
  /// authors close to one consistent speed across scenes -- ASHES.json's
  /// two real sweeps compute to 149.49 and 150.00 px/sec, 0.34% apart) and
  /// pre-fills it here, still user-editable, never silently un-overridable.
  /// A file with no detectable sweep shape leaves this null, requiring a
  /// plain user-entered value instead.
  double? scrollSpeed;

  EasingChoice easing = EasingChoice.easyEaseApproximation; // matches real-content convention,
                                                             // applies in both modes equally

  int get cleanCount => layers.where((l) => l.status == LayerPreviewStatus.clean).length;
  int get flaggedCount => layers.length - cleanCount;

  /// Builds the preview from a parsed document -- pure, no side effects,
  /// callable independently of any UI (Tests A1-A3, F2, G1-G2). In
  /// playbackViewport mode, looks for the real root-sweep shape confirmed in
  /// `samples/sample_playback_viewport.lottie_unzip` (root-level ty:0 layers
  /// each with one position keyframe pair spanning most of their own ip/op
  /// range) to assign `sceneIndex` AND to auto-populate [scrollSpeed] (per
  /// its own doc comment); a file with no such structure produces zero
  /// scenes, which the review screen should treat as its own flagged state
  /// (Open Design Question, not yet specified precisely).
  static ImportPreview build(LottieDocument document, ExportImportMode mode);
}

/// Applies [preview]'s current choices, mutating [doc]. No-op-safe to never
/// call (Test A4 -- cancel just discards the ImportPreview object). In
/// playbackViewport mode, every child layer's own local keyframes import as
/// scroll-basis Anims by default (heuristic (a), Test G5) -- this function
/// does not yet produce any Anim.basis == time output, even though
/// ComicsDoc/EditorLayer already support it.
void commitImport(ImportPreview preview, ComicsDoc doc);
```

```dart
// lib/src/ui/lottie/lottie_export.dart
LottieDocument buildLottieExport(
  ComicsDoc doc,
  ExportImportMode mode, {
  // Required when mode == playbackViewport (Test G4); ignored for fullCanvas
  // (Test G1, which has no scroll-speed/viewport-size concept at all).
  double? scrollSpeed,
  int? viewportWidth,
  int? viewportHeight,
  required EasingChoice easing,
});
```

### Modified Interfaces

- `EditorLayer` (`models.dart`): add `String? groupId` and `TextRegion? textRegion` — both
  nullable, additive, default `null` (today's status quo for every existing layer, matching every
  prior schema addition's backward-compat shape).
- `models_mapping.dart`'s `_layerFromJson`/`_layerToJson`-equivalent functions: read/write the two
  new keys the same additive way `kind`/`style`/`translations` already are, per
  `tdd-dot-comics-format`'s already-documented pattern — omit when null, never write a default.

## Data Models

### New Types

```dart
// lib/src/ui/models.dart
class TextRegion {
  TextRegion({required this.shape, this.rect, this.points, this.maskFile, this.isHandLettered});
  final String shape; // "rect" | "polygon" | "mask"
  final Rect? rect;          // shape == "rect"
  final List<Offset>? points; // shape == "polygon"
  final String? maskFile;     // shape == "mask" -- reference to a bitmap alongside layer tiles
  final bool? isHandLettered; // relationship to Layer.style == "hand_lettered" -- deferred
                               // Requirements question, not resolved by this Specifications pass
}
```

### Schema Changes

Two new optional `Layer` keys in `data.json`: `groupId` (string) and `textRegion` (object, shape
above). Both omitted from JSON when absent — v2012/v2.8 readers that have never heard of either key
render every existing and newly-saved-without-them file exactly as today, per `tdd-dot-comics-format`
and `tdd-dot-lottie-import-export/01-requirements.md`'s already-established backward-compat
mechanism (no re-derivation needed here, just applied).

## Behavior Specifications

### Happy Path

**Import** (Test A1): pick file → parse → build all-clean `ImportPreview` → user accepts default
choices (identity time-base, Easy Ease) → commit → N new `EditorLayer`s appear in the canvas/layers
panel, fully editable by existing tooling (drag, `KeyframeInterpolator`-driven playback).

**Export** (Test D1): open document → "Export to .lottie" → choose time-base/easing (or accept
defaults) → one `.lottie` file written, valid per a generic Lottie schema check.

### Edge Cases

| Case | Test | Expected Behavior |
|------|------|-------------------|
| All layers unsupported | A2 | 0 clean / N flagged; commit produces an empty (or near-empty) document — flag this as its own warning state in the review screen, not a silent success |
| Precomp nesting | A3 | One grouped preview entry, not N unrelated rows; commit tags real `EditorLayer`s with a shared `groupId` |
| Cancel | A4 | Zero document mutation |
| Missing asset file | F2 | Per-layer flag (`LayerPreviewStatus.missingAsset`), not a fatal whole-file error |
| Raster `TextRegion` on export | D3 | **Unresolved** — no Lottie raster-mask equivalent exists; Open Design Question, not guessed |
| Wrong mode for the file's real shape | G7 | No crash; produces a visibly-wrong-but-not-broken document (e.g. a viewport-shaped file imported as fullCanvas turns its 2 scene-sweep precomps into 2 giant document-wide-motion layers) — whether to detect and warn is an Open Design Question |
| Zero recovered scenes in playbackViewport mode | (new, not yet a Test Case) | A Lottie file with no root-sweep-shaped layers at all, imported in playbackViewport mode — should probably be its own flagged/warning state (mirrors A2's all-unsupported case), not specified precisely yet |

### Error Handling

| Error | Cause | Response |
|-------|-------|----------|
| Invalid/non-Lottie JSON | Corrupt file or wrong format entirely | `parseLottieDocument` throws before any preview UI renders (Test F1) |
| Missing required top-level keys | Malformed Lottie | Same as above — a single validation path, not two |
| Missing referenced asset | Broken `.lottie` package | Per-layer `missingAsset` status (Test F2), rest of file still imports |

## Dependencies

### Requires

- Approved `01-requirements.md` (v0.2 baseline; v0.3's Export/Import Modes addition pending
  re-review) and `02-tests.md` (v1.0 baseline; v1.1's Category G addition pending re-review).
- The `Layer.GroupId` design from `flows/comics-editor/vdd-comics-editor-systematization-uiux`
  (Layer Grouping section) — this flow's `groupId` field is that same design, not a second,
  independent one.
- The `Layer.TextRegion` design from this flow's own `01-requirements.md` — same relationship.

### Blocks

- Nothing outside this flow. `flows/comics-ai/sdd-comics-ai-baloons`'s new follow-on task
  (persisting real `TextRegion` data from balloon content) is independent — this flow's export path
  (D3) just needs to handle whatever shape of `TextRegion` eventually shows up, decided or not.

## Integration Points

### External Systems

None — Lottie is a public JSON format with no SDK/network dependency; parsing/writing is plain JSON
manipulation, no third-party Lottie library needed for this scope (this flow never *renders*
Lottie, only converts to/from `.comics`).

### Internal Systems

`models.dart`, `models_mapping.dart` (modify); new `lottie_mapping.dart`, `lottie_import.dart`,
`lottie_export.dart`, `lottie_import_dialog.dart`; `top_bar.dart`/`dialogs.dart` (new menu entries).

## Testing Strategy

### Unit Tests

- [ ] `parseLottieDocument`: valid file parses (A1); missing top-level keys throws (F1); each
      `LottieLayer.type` maps to the right supported/unsupported classification (A2)
- [ ] `ImportPreview.build`: precomp resolution produces correctly-grouped `LayerPreview`s (A3);
      all-unsupported input produces 0 clean (A2 edge case); **fullCanvas mode** uses frame numbers
      directly, no ratio, no scroll-speed field populated (G1/G2); **playbackViewport mode**
      correctly detects the real root-sweep shape and assigns `sceneIndex` (G4/G5)
- [ ] `commitImport`: identity ratio (B1) and custom ratio (B2) produce correctly-scaled `Anim`
      start/end, consistently across every property type on every layer (B2's specific concern);
      **playbackViewport mode**'s per-layer local keyframes import as scroll-basis (not time-basis)
      Anims per heuristic (a) (G5)
- [ ] `buildLottieExport`: `groupId`-sharing layers produce one precomp, not N roots (D2);
      `TextRegion.shape=="polygon"` produces a real `masksProperties` entry (D3); **fullCanvas
      mode** produces a canvas-sized composition with no scroll-speed dependency (G1);
      **playbackViewport mode** produces a viewport-sized composition with one root-sweep precomp
      per scene (G4)

### Integration Tests

- [ ] Real-file round-trip (E1): import `samples/sample.lottie` → export → re-import → compare
      rendered transforms at sampled scroll positions within tolerance
- [ ] F2 against a deliberately-broken copy of a real sample (one asset file removed)
- [ ] **Full Canvas round-trip (G3, CORRECTED 2026-08-08)**: fixture prep — export
      `samples/sample_v2012.comics_unzip` to `.lottie` (fullCanvas) once to produce a real
      Full-Canvas-shaped `.lottie` file; the round-trip test itself then runs
      `.lottie` → import (fullCanvas) → export (fullCanvas) → `.lottie`, comparing rendered
      transforms — same direction as G6, not the reverse (an earlier draft had this round-tripping
      `.comics → .lottie → .comics`, which Anton corrected)
- [ ] **Playback Viewport round-trip (G6)**: `samples/sample_playback_viewport.lottie_unzip` →
      import (playbackViewport) → export (playbackViewport) → compare
- [ ] **Wrong-mode import (G7)**: `samples/sample_playback_viewport.lottie_unzip` imported in
      fullCanvas mode — confirm no crash, document the actually-produced (wrong but defined) shape

### Manual Verification

- [ ] Review screen renders real flagged/clean states legibly for a real mixed-content file
- [ ] Choice dialogs (time-base, easing) are discoverable and their effect is visible after commit

## Migration / Rollout

No migration for existing `.comics` files (both new keys are optional/additive). This is a new
capability, not a behavior change to anything existing — no rollout risk beyond normal new-feature
risk.

## Traceability Matrix

| Spec element | Test Case(s) |
|---|---|
| `LottieDocument`/`parseLottieDocument` | A1, A2, F1 |
| `LayerPreviewStatus`/`LayerPreview` | A1, A2, A3, F2 |
| `ImportPreview` + `EasingChoice` | A1, B1, B2, B3 |
| `commitImport` | A1, A3, A4, B1, B2 |
| `EditorLayer.groupId` | A3, D2 |
| `EditorLayer.textRegion` / `TextRegion` | C1, C2, D3 |
| `buildLottieExport` | D1, D2, D3 |
| Round-trip behavioral equivalence | E1 |
| New menu entries (not the existing Export button) | (Requirements' UI-entry-point decision; no dedicated Test Case beyond A1's "picked via Import from .lottie" premise) |
| `ExportImportMode` (NEW 2026-08-08) | G1, G2, G4, G7 |
| `ImportPreview.scrollSpeed`/`LayerPreview.sceneIndex` (NEW) | G4, G5, G6 |
| Full Canvas round-trip (real fixture) | G3 |
| Playback Viewport round-trip (real fixture) | G6 |

## Open Design Questions

- [ ] D3's raster-`TextRegion`-to-Lottie-export gap — carried forward from `02-tests.md`, still
      unresolved: skip with a disclosed limitation, or lossy rasterize/vectorize?
- [ ] The 2 deferred Requirements-level Text Region questions (`isHandLettered`/`Style`
      relationship, coordinate space) still block finalizing `TextRegion`'s exact shape above —
      the struct in "New Types" is a reasonable working shape, not a final one.
- [ ] Whether the review screen (Category A) and the two choice controls (Category B) are one
      combined dialog or sequential steps — affects `lottie_import_dialog.dart`'s own internal
      structure, not the data model above, deferred to Plan.
- [x] **Does `ImportPreview.build`'s grouping logic resolve `parent` chains generically? — DECIDED
      (2026-08-07)**: yes, via the new `Layer.ParentId` mechanism (`tdd-dot-comics-format
      /03-specifications.md`), any layer, any depth — not baked-and-discarded, mapped directly.
      `EditorLayer.id`/`.parentId` (new, per that flow) replace this flow's own `groupId`-only
      design for the parenting case specifically; `groupId` may still be relevant for the simpler,
      non-hierarchical precomp-flattening case (open question below).
- [ ] **(new, 2026-08-07)** Does the mask exclusion (Won't-Have) get re-confirmed knowing it drops
      real content (`THE CHASE`'s 6 masked layers) today, or does mask support get pulled into
      scope given it's not hypothetical? Not decided — flagged explicitly rather than silently kept
      as originally scoped.
- [ ] **(new, 2026-08-07)** How should the review screen (Category A) represent a deeply-parented
      layer chain (e.g. `THE BROKEN TUSK`'s up-to-64%-parented rig)? A3's mockup-equivalent assumed
      one shallow precomp-to-group mapping — a multi-level parent chain may need a different
      visualization (nested tree rows?) not yet designed.
- [x] **(new, 2026-08-08) DECIDED (2026-08-08)** Exact scene-boundary convention for Playback
      Viewport export: **sequential `ComicsDoc.preferredViewportHeight`-tall bands** (the new
      `tdd-dot-comics-format` field, default 1600) — `.comics` has no scene concept of its own to use
      instead, confirmed by direct inspection of `samples/sample_v2012.comics_unzip/data.json`'s real
      top-level keys (`width`/`height`/`layers`/`sounds` only, no scene marker of any kind). This is
      the same reasoning that motivated adding `preferredViewportHeight` to the format in the first
      place — the two additions were designed to fit together, not independently.
- [ ] **(new, 2026-08-08)** `ImportPreview.build`'s scroll/time classification heuristic for
      playbackViewport mode — ships as heuristic (a) (everything scroll-basis, per
      `01-requirements.md`) for now; (b)/(c) are real, undesigned improvements, not silently
      abandoned.
- [x] **(new, 2026-08-08) DECIDED (2026-08-08)**, grounded in exact computation: `ImportPreview
      .scrollSpeed` **is auto-derived when the root-sweep shape is detected**, shown pre-filled and
      editable, never silently applied. `ASHES.json`'s two real root sweeps compute to 149.49 and
      150.00 px/sec respectively — within 0.34% of each other, real evidence the file was authored
      against one consistent speed. A file with no such sweep structure (or opened in the wrong
      mode) has nothing to derive from and falls back to a plain user-entered value. See
      `01-requirements.md`'s equivalent entry for the full computation.
- [x] **(new, 2026-08-08) DECIDED (2026-08-08)** Mode selection UI: **auto-detect with override**,
      not a cold blank choice. Detection heuristic: a composition whose `w`/`h` are phone-viewport-
      shaped (roughly device-screen-sized, not `sample_v2012.comics_unzip`'s real ~38:1
      width:height ratio) **and** whose root-level layers show the confirmed real sweep shape (one
      dominant position-keyframe pair spanning most of that layer's own `ip`/`op` range) suggests
      Playback Viewport; a composition sized like the canvas itself with no such sweep suggests Full
      Canvas. The review screen shows the detected mode explicitly and lets the user override it —
      the same "signal, don't silently assume" principle Джанава's UI/UX vision already established
      for this exact review screen (`01-requirements.md`'s UI entry point decision).

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-08
- [x] Notes: Approved as drafted (v1.3), including the Export/Import Modes addition and its 3
      same-day resolutions (scene-boundary convention, scroll-speed auto-derivation,
      mode-selection UI). This approval also confirms `01-requirements.md` v0.3's and
      `02-tests.md` v1.1's Category G addition, which this document derives from directly (same
      feature, same session) — both were left "pending re-review" pending this approval, not
      separately re-confirmed. 6 Open Design Questions remain genuinely open, carried forward to
      Plan rather than blocking approval: D3's raster-mask export gap, the 2 deferred Text Region
      sub-questions, the review-screen-vs-choice-dialogs UI-structure question, whether the mask
      exclusion gets re-confirmed, how the review screen represents a deeply-parented layer chain,
      and G5's scroll/time classification heuristic (ships as "everything scroll-basis" for now).
