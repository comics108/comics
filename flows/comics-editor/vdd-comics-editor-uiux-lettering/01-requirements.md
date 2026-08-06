# Requirements: comics-editor-uiux-lettering

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-07-30

## Problem Statement

`apps/comics-editor-v2.9` (the Flutter comics editor) has no concept of "lettering" at all today.
Investigation found:

- The data model has **no "balloon" layer type** — every layer (background, character, balloon) is
  the same generic `Layer`. Nothing marks a layer as a balloon.
- The data model has **no text field anywhere** — balloon content is 100% pre-rendered raster
  images, per language. There is zero text-entry UI in the app.
- The existing "per-language artwork" picker in the properties panel is a **UI stub**: it doesn't
  open a real file picker or call into the backend, just sets a hardcoded placeholder filename.
- The editor only models 3 languages (`Cultures` enum: En/Ru/Hi).
- `apps/comics-ai-baloons` (a separate, already-built Python pipeline — erase balloon text, render
  new-language text via layout/font rendering or headless-browser shaping for complex scripts) has
  **zero connection** to the editor. It's a disconnected batch CLI.

Together this means a letterer/localizer today cannot type text, cannot see which layers are
balloons, cannot add a new language's translation, and cannot use the AI pipeline without leaving
the app entirely and running a separate CLI tool by hand. This flow closes that gap: give balloons
a real identity in the data model and UI, give the editor an actual text-entry/translation surface,
and connect it to AI-assisted balloon generation — designed primarily for **iPad + stylus**, with
an interaction feel closer to **DaVinci Resolve** (page-based, big direct-manipulation surfaces,
shallow menus) than **Adobe After Effects** (dense nested property panels).

## User Stories

### Primary

**As a** letterer/localizer using the comics editor
**I want** to select a balloon, see and edit its text per language, and trigger AI-assisted
artwork generation for a translation directly in the app
**So that** I don't need to leave the editor or run a separate command-line pipeline to letter or
relocalize a balloon

### Secondary

- **As an** editor user scanning a page's layer list
  **I want** balloon layers visually distinguished from art/background/other layers
  **So that** I can find and navigate lettering work at a glance, without opening each layer

- **As a** localizer adding a new language
  **I want** to add translation text for a language a balloon doesn't have yet, and generate its
  artwork on demand
  **So that** new languages don't require a full separate batch pipeline run

- **As an** iPad + stylus user
  **I want** the lettering workflow to use large, direct-manipulation controls with shallow
  navigation (tap a balloon, edit text, generate — not a chain of nested panels)
  **So that** the workflow feels natural on tablet, not like a desktop compositing tool shrunk down

- **As a** maintainer of existing `.comics` files and older app builds
  **I want** all data-model changes (layer type, translation text) to be additive
  **So that** existing files keep opening correctly in this and older editor versions, and old
  files keep working in the new version

## Acceptance Criteria

### Must Have

1. **Given** a `.comics` layer with a new `kind`/type marker of "balloon" in `data.json`
   **When** the file is opened in the editor
   **Then** the editor recognizes it as a balloon and treats it distinctly from other layer kinds
   (at minimum: visually distinguished in the layers list)

2. **Given** an existing `.comics` file with no `kind`/translation fields (today's format)
   **When** opened in the updated editor
   **Then** it loads and behaves exactly as it does today — no crash, no data loss, layers without
   an explicit kind behave as generic/art layers

3. **Given** a `.comics` file saved by the updated editor with the new fields
   **When** opened by an older editor version that doesn't know about them
   **Then** it does not crash and does not lose the unrecognized fields on a subsequent save
   (round-trip safe)

4. **Given** a balloon layer is selected
   **When** the user opens its editor surface
   **Then** they see the text content for each language that has one, and can add/edit text for
   any language

5. **Given** a balloon with text entered/edited for a language
   **When** the user triggers AI generation for that language
   **Then** the app produces balloon artwork (erase existing content if any + render the new text)
   and updates that language's image slot for the layer

6. **Given** AI generation is triggered on a device that can't (or shouldn't, for quality reasons)
   run it locally
   **When** generation runs
   **Then** the request is routed to an external service instead of failing or blocking the user

### Should Have

- Color-coding (or another lightweight visual marker) for layer kind in the layers list, per the
  user's suggestion — to be confirmed as color vs. icon vs. both in the Visual phase
- A canvas-level visual indicator that a selected/hovered layer is a balloon
- Large touch/stylus-friendly controls and shallow navigation depth specifically for the new
  lettering surfaces (tablet-first design, adapted down to desktop/phone — not the reverse)
- Exposing more of the AI pipeline's ~20-language set in the editor's language picker, beyond
  today's fixed 3-culture enum (exact scope TBD, see Open Questions)

### Won't Have (This Iteration)

- Redesigning the entire editor's UX to be iPad/DaVinci-style — scoped to the new
  lettering/balloon surfaces only
- Full on-device ML runtime engineering (model packaging, hardware-capability benchmarking) — this
  flow defines the client-side contract/UI; see Open Questions on where the engine work itself lives
- Expanding the `Cultures` enum to all ~20 languages throughout the *entire* app (translations
  data may support more languages than the app's other language-dependent features do — scope TBD)
- Real-time multi-user collaborative lettering
- Any UI for hand-lettered/artist-style generation (Track 6b in `comics-ai-baloons` is
  intentionally flag-only, not an automated feature — no UI is needed for something that doesn't
  auto-generate)

## Constraints

- **Technical**: All data-model changes must be additive/backward-compatible JSON (new optional
  fields, sensible defaults when absent) in both the C# native core
  (`native/Comics.Editor/Models/`, the source of truth for `data.json` serialization) and its
  Flutter mirror (`lib/src/ui/models.dart` + `models_mapping.dart`).
- **Technical**: `apps/comics-ai-baloons`'s current erase/layout/render logic is Python +
  OpenCV/Pillow/Playwright (headless Chromium) — none of that runs on iOS/iPadOS. Some form of
  client/server split is required for AI generation on tablet; local-only execution can't cover the
  full language/script set as currently built.
- **Platform**: Primary design target is iPad + stylus. Must not regress existing desktop
  (Windows/macOS/Linux) or phone support — the app's existing responsive breakpoints
  (`editor_screen.dart`) should be extended, not replaced.
- **Dependencies**: Depends on `apps/comics-ai-baloons`'s erase/layout/render algorithms as the
  reference implementation for whatever AI engine (on-device and/or server) ends up serving
  generation requests from the editor.

## Open Questions

- [ ] **Translation data shape**: a language-code-keyed dictionary on the layer (sparse, matches
      the AI pipeline's CSV structure, not bound to the fixed 3-slot `Images` array), or text
      attached per existing image slot? Recommend the former — confirm before Specifications.
- [ ] **Layer-kind taxonomy**: just `balloon` vs. everything else, or a fuller set (e.g.
      `balloon`/`caption`/`background`/`character`/`sfx`, echoing the AI pipeline CSV's own
      `speech`/`caption` distinction)?
- [ ] **Scope boundary of the AI engine work**: does *this* VDD flow build the actual
      on-device-vs-server routing and inference integration, or define the UI + a client
      interface/contract against a stubbed or minimal backend, leaving the real engine
      (hardware-capability detection, model packaging, server API) to a separate follow-on flow?
      Recommend the latter — this flow is UI/UX-scoped by its own name — but confirm.
- [ ] **What is "the server"?**: extend `apps/comics-ai-baloons` into a callable HTTP service, or
      build a new dedicated inference backend? Affects the API contract this flow needs to design
      against.
- [ ] **Properties-panel image-picker stub**: AI-generated output has to land in a layer's image
      slot through *some* real mechanism (today there's no working file-set path or bridge RPC for
      this at all). Is fixing that plumbing in scope here as a prerequisite, or tracked separately?
- [ ] **Language coverage in the UI**: expose all ~20 `comics-ai-baloons` languages in the editor,
      or a smaller curated set for this iteration?
- [ ] **Existing design references**: `/design/comics-editor-maket-v2.8.pdf`,
      `/design/comics-editor-maket-v3.pdf`, `/design/comics-editor-maket-dart-v3/` — do any of
      these already cover lettering/balloon UI this flow should align with, or are they unrelated
      groundwork safe to ignore?

## References

- `apps/comics-editor-v2.9/` — target app (Flutter, desktop-first today; C# native core
  `Comics.Editor.Headless` on desktop, pure-Dart `DartIoCore` on mobile)
- `apps/comics-editor-v2.9/native/Comics.Editor/Models/{Layer,Image,Cultures}.cs` — data model
  ground truth
- `apps/comics-editor-v2.9/lib/src/ui/widgets/properties_panel.dart` — existing (stub) per-language
  artwork picker
- `apps/comics-ai-baloons/` — AI pipeline (erase/layout/render_latin/render_shaped), built in
  `flows/sdd-comics-ai-baloons/`
- `/design/comics-editor-maket-v2.8.pdf`, `/design/comics-editor-maket-v3.pdf`,
  `/design/comics-editor-maket-dart-v3/` — existing design references, relevance TBD

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-07-30
- [x] Notes: Approved as-is. The 7 Open Questions above are intentionally left unresolved rather
      than blocking approval — expected to be resolved during Visual/Specifications review.
