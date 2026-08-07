# Specifications: dot-lottie-import-export

> Version: 1.2 (2026-08-07: superseding update — `.comics` v2026 now has a real `Layer.ParentId`
> mechanism; the correction below's "bake and discard" plan is upgraded to "map directly onto
> ParentId." Not yet approved, so amended directly.)
> Status: DRAFT
> Last Updated: 2026-08-07
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
  .lottie file --> LottieDocument (lottie_mapping.dart, pure parse)
                        |
                        v
                  ImportPreview (lottie_import.dart)
                  -- per-layer: clean | flagged(reason) | grouped(with N members)
                  -- pending choices: timeBaseRatio, easingPrecision
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
     -> lottie_import.buildPreview(LottieDocument) -> ImportPreview
        (walks LottieDocument.layers; ty:2 => clean; ty:4/5/mask-bearing => flagged;
         ty:0 precomp => resolve nested comp asset's layers, tag with one new groupId)
     -> user sets ImportPreview.timeBaseRatio, .easingPrecision (or accepts defaults)
     -> user commits -> lottie_import.commit(preview, doc)
        (for each clean/grouped layer: create EditorLayer; for each animated property (p/r/s/o):
         create Anim entries, frame numbers divided by timeBaseRatio -> start/end;
         easing handles -> either matched via curve-fit (exact) or passed through as Easy-Ease
         equivalent (approximation) -- both currently produce .comics's one fixed cubic ease-out
         per Test B3's finding, so this choice is real but not yet observably different in output)

Export: doc -> lottie_export.build(doc, timeBaseRatio, easingPrecision)
     -> for each EditorLayer: one Lottie ty:2 layer; each Anim range -> one keyframe pair,
        frame numbers = start/end * timeBaseRatio; groupId-sharing layers -> one shared precomp
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
// lib/src/ui/lottie/lottie_import.dart
enum LayerPreviewStatus { clean, flagged, missingAsset }

class LayerPreview {
  LayerPreview(this.sourceLayer, this.status, {this.reason, this.groupId, this.groupName});
  final LottieLayer sourceLayer;
  final LayerPreviewStatus status;
  final String? reason;       // populated when flagged/missingAsset (Test A2, F2)
  final String? groupId;      // shared across a precomp's resolved member layers (Test A3)
  final String? groupName;    // the precomp's own `nm`, shown as "(from precomp '<name>')"
}

enum TimeBaseChoice { identity, custom }
enum EasingChoice { exactCubicFit, easyEaseApproximation }

/// The review screen's whole data model (Category A + B). Built once per
/// picked file; mutated only by the two choice setters until commit()/cancel().
class ImportPreview {
  ImportPreview(this.document, this.layers);
  final LottieDocument document;
  final List<LayerPreview> layers;
  TimeBaseChoice timeBase = TimeBaseChoice.identity; // Requirements' recommended default (Test B1)
  double? customRatio; // required when timeBase == custom (Test B2)
  EasingChoice easing = EasingChoice.easyEaseApproximation; // matches real-content convention

  int get cleanCount => layers.where((l) => l.status == LayerPreviewStatus.clean).length;
  int get flaggedCount => layers.length - cleanCount;

  /// Builds the preview from a parsed document -- pure, no side effects,
  /// callable independently of any UI (Tests A1-A3, F2).
  static ImportPreview build(LottieDocument document);
}

/// Applies [preview]'s current choices, mutating [doc]. No-op-safe to never
/// call (Test A4 -- cancel just discards the ImportPreview object).
void commitImport(ImportPreview preview, ComicsDoc doc);
```

```dart
// lib/src/ui/lottie/lottie_export.dart
LottieDocument buildLottieExport(ComicsDoc doc,
    {required TimeBaseChoice timeBase, double? customRatio, required EasingChoice easing});
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

### Error Handling

| Error | Cause | Response |
|-------|-------|----------|
| Invalid/non-Lottie JSON | Corrupt file or wrong format entirely | `parseLottieDocument` throws before any preview UI renders (Test F1) |
| Missing required top-level keys | Malformed Lottie | Same as above — a single validation path, not two |
| Missing referenced asset | Broken `.lottie` package | Per-layer `missingAsset` status (Test F2), rest of file still imports |

## Dependencies

### Requires

- Approved `01-requirements.md` (v0.2) and `02-tests.md` (v1.0) — done.
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
      all-unsupported input produces 0 clean (A2 edge case)
- [ ] `commitImport`: identity ratio (B1) and custom ratio (B2) produce correctly-scaled `Anim`
      start/end, consistently across every property type on every layer (B2's specific concern)
- [ ] `buildLottieExport`: `groupId`-sharing layers produce one precomp, not N roots (D2);
      `TextRegion.shape=="polygon"` produces a real `masksProperties` entry (D3)

### Integration Tests

- [ ] Real-file round-trip (E1): import `samples/sample.lottie` → export → re-import → compare
      rendered transforms at sampled scroll positions within tolerance
- [ ] F2 against a deliberately-broken copy of a real sample (one asset file removed)

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
| `ImportPreview` + `TimeBaseChoice`/`EasingChoice` | A1, B1, B2, B3 |
| `commitImport` | A1, A3, A4, B1, B2 |
| `EditorLayer.groupId` | A3, D2 |
| `EditorLayer.textRegion` / `TextRegion` | C1, C2, D3 |
| `buildLottieExport` | D1, D2, D3 |
| Round-trip behavioral equivalence | E1 |
| New menu entries (not the existing Export button) | (Requirements' UI-entry-point decision; no dedicated Test Case beyond A1's "picked via Import from .lottie" premise) |

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

---

## Approval

- [ ] Reviewed by:
- [ ] Approved on:
- [ ] Notes:
