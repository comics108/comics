# Requirements: comics-editor-ai-uiux

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-08-01

## Problem Statement

`sdd-comics-ai-multimodal` (just completed) built and verified a Python pipeline
(`apps/comics-ai/comics-multimodal/`) that takes a real camera photo of the printed book and
auto-produces: page/panel-aligned content matches, kind-tagged cut regions (background / character /
balloon / art) with confidence scores, a clustered character/environment library, and packaged
`.comics` output. It works — but only from the command line, run by hand, with no review step: its
output is either accepted wholesale or not used at all.

`apps/comics-editor` today has exactly one AI-assisted, human-reviewed workflow: balloons
(`BalloonEditorCard` / `BalloonAiClient`, shipped in `vdd-comics-editor-uiux-lettering`) — per-language
generate/regenerate, a stale-output indicator, and a never-silent-auto-apply rule. Every other content
kind (background, character, art) has no review surface at all: the layers list can *display* a kind
chip (`_KindChip`) for them, but there is no editing surface behind it. There is also no library
browser for the pipeline's clustered character/environment output, and no connection whatsoever
between the editor (Dart/C#) and the Python pipeline (torch/opencv/tesseract) — they are fully
disconnected today.

This flow closes that gap: let a human corrector trigger the multimodal cutting pipeline from inside
the editor, review its proposed regions for every content kind (not just balloons), accept/reject/fix
them into real layers, and browse the auto-built character/environment library — extending the
lettering flow's proven review-and-correct pattern rather than inventing a new one.

## User Stories

### Primary

**As a** human corrector using the comics editor
**I want** to trigger the multimodal cutting pipeline on a source image and review its proposed
regions (background, character, balloon, art) — accepting, rejecting, reclassifying, or adjusting
each one before it becomes a real layer
**So that** I can turn a photo into a corrected `.comics` page inside the app, without running the
Python CLI by hand or trusting the model's raw output uninspected

### Secondary

- **As a** corrector working through a batch of pages
  **I want** to see a confidence score per region and act on high-confidence ones quickly (e.g.
  bulk-accept above a threshold) while giving low-confidence ones closer attention
  **So that** review time scales with how much the model actually got wrong, not with page count

- **As a** corrector building `.comics` pages from recurring content
  **I want** to browse the pipeline's clustered character/environment library and drop a
  previously-recognized item straight onto a page as a layer
  **So that** I don't have to re-cut a character or background that's already been identified in an
  earlier page

- **As a** desktop user (Windows / macOS / Linux)
  **I want** the pipeline to run as a real local process with visible progress, not a fake/simulated
  step
  **So that** the corrector workflow reflects the pipeline's actual, already-verified behavior

- **As a** mobile user
  **I want** the same triggering/reviewing UI to at least be present and honest about its limits
  **So that** the feature doesn't silently pretend to work on a platform where the heavy pipeline
  can't run yet, and I'm not confused about why nothing happens

- **As the product owner**
  **I want** the client-side contract for triggering a "cut" designed so a future server-backed,
  metered/subscription path can be slotted in later without changing the UI or the corrector's
  workflow
  **So that** mobile/server support and monetization can be built later as a separate, focused
  effort, on top of a contract that already anticipates them

## Acceptance Criteria

### Must Have

1. **Given** a source image already staged in the editor (e.g. an imported page)
   **When** the corrector triggers "Cut / Segment" on desktop (Windows, macOS, or Linux)
   **Then** the app invokes the real `apps/comics-ai/comics-multimodal` pipeline as a local process
   against that image and streams back real progress and real `DetectedRegion`s (kind, mask/bbox,
   confidence) — using the `MultimodalCuttingClient` contract designed in `sdd-comics-ai-multimodal`
   Specifications, actually implemented this time (not a stub)

2. **Given** returned regions of any kind (background / character / balloon / art)
   **When** the corrector reviews them
   **Then** each region can be accepted, rejected, reclassified to a different kind, and have its
   bounding box adjusted, via a review surface that follows the shipped `BalloonEditorCard` pattern
   (one shared, kind-aware surface — see Open Questions) including a stale-output indicator if the
   source image changes after regions were generated

3. **Given** an accepted region
   **When** the corrector confirms it
   **Then** a real `Layer` is created or updated in the open document with the correct `Kind` and
   actual image content — wired through real plumbing (not a placeholder image, not a no-op)

4. **Given** the pipeline's clustered library output (`work/library/characters/*`,
   `work/library/environments/*`)
   **When** the corrector opens a library browser
   **Then** they can see the clustered items (with a thumbnail and cluster/seed name) and insert a
   chosen one onto the current page as a new layer

5. **Given** the editor running on a platform with no usable local Python pipeline (mobile today)
   **When** the corrector triggers "Cut / Segment"
   **Then** the app does not crash, silently no-op, or fake success — it clearly communicates that
   this path isn't available yet on this platform (exact UX: disabled control vs. explicit message —
   see Open Questions), consistent with this iteration's disclosed scope

6. **Given** an existing `.comics` document with layers that predate this feature
   **When** it's opened after this feature ships
   **Then** nothing about existing layers or documents changes — this is purely an additive
   authoring workflow, not a data-model migration

### Should Have

- A visual overlay of proposed region boxes/masks on top of the source image before acceptance,
  rather than reviewing regions as a disconnected list
- Per-kind confidence-threshold controls and a bulk "accept all above threshold" action
- Library search/filter by cluster/seed name
- Reusing a region's confidence score to pre-sort or visually flag likely-wrong regions first

### Won't Have (This Iteration)

- **A real deployed backend/server that runs the pipeline for non-desktop clients.** Confirmed by
  research: no such service exists anywhere in this repo today. `apps/comics-backend` is an unrelated
  Node/Express + Supabase content API (books/chapters/quotes) with no AI/generation endpoints, and
  isn't called from the editor. Building and deploying a pipeline-serving backend is out of scope;
  this flow designs the client contract *against* one, following the exact precedent set by
  `BalloonAiClient` (contract-only, `StubBalloonAiClient` as the only implementation).
- **A real on-device ML runtime.** Confirmed: no tflite/onnxruntime/coreml/mediapipe dependency
  exists in `pubspec.yaml` or the native projects today. On-device inference on mobile is out of
  scope; mobile gets the honest "not available yet" path from Acceptance Criterion 5.
- **Any subscription, billing, or token/credit system.** Confirmed: no billing/IAP/payment code
  exists anywhere in the repo today. This flow may leave a seam in the client contract for a future
  metering hook (e.g. a `reason`/`quota` field already present in `RoutingDecided`-style events) but
  will not implement payments, limits, or purchases.
- **Photo import/rectification (page detection, perspective correction) inside the editor.** The
  pipeline's own `rectify.py`/`detect_panels.py` stages assume a raw camera photo; this flow assumes
  the corrector already has a page-cropped source image to hand to the cutting client (confirm in
  Open Questions).
- **Quality correction or net-new generation** (`sdd-comics-ai-multimodal` Phase 10/beyond) — this
  flow is scoped to reviewing/correcting the already-built cutting/segmentation output, not extending
  the pipeline's own capabilities.
- **Redesigning unrelated parts of the editor UI** — scoped to the new cutting/review/library
  surfaces only, following the lettering flow's own precedent of not restyling the whole app.

## Constraints

- **Technical**: The only currently-real invocation path is desktop shelling out to
  `apps/comics-ai/comics-multimodal/scripts/pipeline.py` as a local subprocess — it has a working,
  resumable CLI already. There is no packaged/frozen executable; this assumes a Python environment
  with the pipeline's dependencies (torch, opencv, tesseract, etc.) is present alongside the desktop
  app for this iteration.
- **Technical**: All new layer content must go through the existing additive `Layer.Kind` / `Style` /
  `Translations` model from `vdd-comics-editor-uiux-lettering` — no parallel/competing data model for
  cut regions.
- **Technical**: The review surface should reuse the `BalloonEditorCard`/`BalloonAiClient` shape
  (abstract client, `Stream` of routing/progress/success/failure events, never-silent-auto-apply) so
  corrector muscle memory transfers between balloon and cutting workflows.
- **Platform**: Mobile (`DartIoCore`) has no path to run the Python pipeline locally. Must degrade
  honestly per Acceptance Criterion 5, not regress existing mobile functionality.
- **Dependencies**: Depends on `sdd-comics-ai-multimodal`'s completed pipeline (specifically
  `pipeline.py`'s segmentation/regions/library stages) and on `vdd-comics-editor-uiux-lettering`'s
  `Layer.Kind`/`BalloonEditorCard`/`BalloonAiClient` as the pattern to extend, not replace.

## Open Questions

- [ ] **Desktop subprocess packaging**: invoke a Python environment assumed already present
      (dev-machine style), or address bundling/packaging the pipeline's heavy dependencies
      (torch/opencv/tesseract) with the app? Recommend assuming a present environment for this
      iteration and flagging packaging as an explicit follow-on — confirm before Specifications.
- [ ] **One shared review card vs. per-kind cards**: a single `CuttingReviewCard` parameterized by
      kind (background/character/balloon/art), or bespoke cards per kind given they differ in shape
      (a background region behaves differently from a balloon region)? Recommend one shared,
      kind-aware card for consistency with the corrector's existing balloon muscle memory — confirm
      in Visual phase.
- [ ] **Library browser placement**: a new dedicated panel/screen, or a tab inside the existing
      properties panel? Confirm in Visual phase.
- [ ] **Source image intake**: is bringing a raw photo into the editor (as a stageable "source image"
      ready for cutting) in scope for this flow, or does it assume the image already arrives
      pre-cropped/rectified via some existing import path? Recommend treating rectification as a
      separate, later concern and assuming a pre-cropped page image is already importable — confirm.
- [ ] **Mobile "not available" UX**: disable/hide the Cut/Segment control on mobile with a tooltip
      (e.g. "Desktop only for now"), or show it and fail with an explicit in-app message when tapped?
      Recommend disabling with messaging — more honest than a stub placeholder — confirm.
- [ ] **Region confidence surfacing**: numeric score, a three-tier (low/medium/high) badge, or a
      purely visual cue (e.g. border opacity)? Confirm in Visual phase.

## References

- `apps/comics-ai/comics-multimodal/scripts/pipeline.py` — the real, completed pipeline this flow
  invokes (10 stages, resumable, real regions/library output verified against real photos)
- `flows/sdd-comics-ai-multimodal/02-specifications.md` — the "Editor Integration Contract"
  (`MultimodalCuttingClient`, `CuttingEvent`, `DetectedRegion`) this flow implements for real on
  desktop
- `apps/comics-editor/lib/src/ai/balloon_ai_client.dart`,
  `apps/comics-editor/lib/src/ai/stub_balloon_ai_client.dart` — the exact contract-only/stub-only
  precedent this flow follows for the routing/mobile gap
- `apps/comics-editor/lib/src/ui/controller.dart` — where `BalloonAiClient` is wired up; the
  equivalent wiring point for a new cutting client
- `flows/vdd-comics-editor-uiux-lettering/` — shipped precedent flow (`BalloonEditorCard`, `Layer.Kind`
  additive model, `_KindChip`)
- `flows/vdd-comics-editor-jhanava/` — content-kind taxonomy and difficulty gradient (draft, unshipped)
- `apps/comics-backend/node/` — confirmed unrelated (Bhagavad-Gita content API, no AI endpoints, no
  connection to the editor)

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-01
- [x] Notes: Approved as-is, including the disclosed scope narrowing (real desktop invocation + full
      review UI this iteration; backend/on-device-runtime/billing deferred as future work). The six
      Open Questions are intentionally left unresolved rather than blocking approval — to be resolved
      during Visual phase.
