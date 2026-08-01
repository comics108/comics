# Status: vdd-comics-editor-ai-uiux

## Current Phase

VISUAL

## Phase Status

DRAFTED (awaiting "visual approved")

## Last Updated

2026-08-01 by Claude

## Blockers

- Awaiting user review/approval of `02-visual.md`.
- `01-requirements.md` is APPROVED (2026-08-01), including the disclosed scope narrowing: real
  desktop subprocess invocation + full review UI for all 4 kinds (background/character/balloon/art)
  is Must Have this iteration; backend/on-device-ML-runtime/billing are explicit "Won't Have (This
  Iteration)" — confirmed via research that none of that infra exists anywhere in the repo today,
  mirroring how `BalloonAiClient` shipped as contract-only with a disclosed stub.
- `02-visual.md` resolves all 6 Requirements Open Questions as concrete design decisions (not
  re-asked): (1) one shared kind-parameterized `CuttingReviewCard`, not per-kind cards; (2) Library
  browser is a tab inside a new "Cutting" mode (third mode alongside Edit/Lettering), not a separate
  screen; (3) source image intake assumes an already-cropped page image, rectification explicitly
  out of scope and disclosed inline on the trigger screen; (4) mobile shows the Cutting mode switch
  disabled-but-visible with an explanatory tap message, never entered-then-broken; (5) confidence
  shown as a color+percentage badge (green/amber/coral, text always present); (6) bounding-box
  adjustment reuses the canvas's existing layer-resize-handle interaction, no new gesture.
- **2026-08-01 update**: user supplied a high-fidelity HTML/PDF companion mockup
  (`design/comics-editor-v3.1.0-maket/Comics Editor Cutting Devices.dc.html` +
  `design/comics-editor-v3.1.0-cutting.pdf`, HolySpots DS v3.1) confirming the ASCII structure with
  no disagreements, plus concrete pixel-level detail now folded into `02-visual.md` v1.1: exact new
  chip colors (slate `#5a7d99` Background, teal `#2f8f7a` Character; Balloon/Art reuse existing
  violet/gray), exact confidence badge tokens, a header region-count status summary, icon-based
  accept/reject indicators, a persistent (not just during-run) routing/source indicator, an
  all-regions-visible-with-spotlight canvas treatment, and — most importantly — a clarified
  behavior: **cutting-produced layers are ordinary document layers**, viewable normally on any
  platform via the existing document-open path; only *triggering* a new cut is desktop-only. This
  narrows what "mobile is out of scope" actually means in a corrector-favorable direction (worth
  surfacing to the user, it's a improvement not a regression).

## Progress

- [x] Requirements drafted
- [x] Requirements approved
- [x] Visual drafted
- [ ] Visual approved
- [ ] Specifications drafted
- [ ] Specifications approved
- [ ] Plan drafted
- [ ] Plan approved
- [ ] Implementation started
- [ ] Implementation complete
- [ ] Documentation drafted
- [ ] Documentation approved

## Context Notes

Key context carried in from prior, closely-related flows (not re-derived from scratch):

- **`sdd-comics-ai-multimodal`** (just completed, same session) built and verified an end-to-end
  Python pipeline (`apps/comics-ai/comics-multimodal/`) that takes a real camera photo of the
  printed book and produces: `work/alignment.jsonl` (page→episode matches), `work/regions.jsonl`
  (predicted `CutRegion`s: kind/confidence/bbox), `work/eval_report.jsonl`, `work/balloon_handoff
  .jsonl` (translation status lookups), `work/library/{characters,environments}/<name>/` (a
  clustered gallery), and `work/output/*.comics` (packaged, reconstructed `.comics` files). That
  flow's Specifications explicitly designed (but did NOT build) an "Editor Integration Contract"
  for exactly this follow-on work:
  ```dart
  abstract class MultimodalCuttingClient { Stream<CuttingEvent> segment(Uint8List sourceImageBytes); }
  sealed class CuttingEvent {}
  class RoutingDecided extends CuttingEvent { final bool onDevice; final String reason; }
  class Progress extends CuttingEvent { final double fraction; }
  class Success extends CuttingEvent { final List<DetectedRegion> regions; }
  class Failure extends CuttingEvent { final String reason; }
  class DetectedRegion { final String kind; final Uint8List maskPng; final Rect bbox; final double confidence; }
  ```
  plus a proposed future `CuttingReviewCard` (per-kind, analogous to the shipped
  `BalloonEditorCard`) for accept/reject/reclassify/adjust-boundary, with a stale-output indicator.
  This VDD flow is very likely that "later flow."
- **`vdd-comics-editor-uiux-lettering`** (shipped, IMPLEMENTATION COMPLETE) already built the
  precedent pattern this flow should extend: `BalloonEditorCard` (per-language tabs, Generate/
  Regenerate button, stale-output indicator when text changes after generation, on-device/cloud
  routing indicator, never-silent-auto-apply) + `BalloonAiClient` (abstract Dart interface,
  `Stream<GenerationEvent>`). Also added `Layer.Kind`/`Style`/`Translations` (additive, nullable)
  to the editor's data model, and a `_KindChip` widget in the layers list already visually supports
  the full kind taxonomy (`[Bln]`/`[Cap]`/`[Bg]`/`[Chr]`/`[Snd]`/`[Art]`), even though only
  balloon/caption have real editing surfaces built.
- **`vdd-comics-editor-jhanava`** (DRAFT, unvalidated seed capture): content-kind taxonomy
  (background/character/balloon/sound/motion-fx) and a difficulty gradient (balloon simplest,
  already solved; character moderate, NOT built; background hardest, NOT built).
- **Editor architecture constraints** (verified against live code during `sdd-comics-ai-multimodal`
  survey): `apps/comics-editor` (renamed from `comics-editor-v2.9`) is Flutter, with three
  platform variants (Windows WPF PlatformView, macOS/Linux headless C# core over NDJSON, mobile
  DartIoCore). No generic plugin/import system exists — every new content path needs bespoke
  plumbing (the lettering flow built a narrow `setLayerImage` + tile-writer path specific to
  balloons). No timeline/time dimension. Undo/redo is session-only, full-document-snapshot based.
- **Cross-language integration gap**: the pipeline is Python (torch/opencv/tesseract); the editor
  is Dart/C#. There is no existing bridge between them — this flow will need to design one
  (file-based hand-off vs. a served API vs. subprocess invocation), which is a first-class open
  question, not a given.

## Next Actions

1. Get explicit "visual approved" from the user on `02-visual.md`.
2. Once approved, move to SPECIFICATIONS phase: design the real `MultimodalCuttingClient`
   implementation (subprocess invocation of `pipeline.py`, NDJSON-or-similar event streaming to
   match the existing macOS/Linux headless-core RPC pattern), the `CuttingReviewCard` Dart widget
   and its data model, the Cutting-mode routing/state additions to `controller.dart`, and how
   accepted regions become real `Layer`s (image-content plumbing, per Requirements Acceptance
   Criterion 3 — must not repeat the old properties-panel stub-picker mistake from before the
   lettering flow fixed it).
