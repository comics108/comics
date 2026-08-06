# Requirements: comics-editor-questions

> Version: 0.6 (adds Group C: timeline orientation / vertical-vs-horizontal scroll / device aspect
> ratio / viewer playback, from Anton, investigated against real v2.8 WPF + current Flutter/mobile
> code before being left as open questions)
> Status: DRAFT
> Last Updated: 2026-08-01

## Origin

Extracted verbatim from `flows/vdd-comics-editor-jhanava/01-requirements.md` on 2026-07-30, per
explicit user request, so that flow could keep moving without being gated by needing every open
question answered first. This is **not a feature to build** — it's a consolidated backlog of
unresolved questions about comics-editor's future scope (content-kind taxonomy, material intake,
video/motion-comic export) that surfaced while scoping that flow. Its job is to hold these
questions in one place until there's a real session with **Джанава** (Евгений Корытный) and
**Бхагаван** (whoever holds that name in this context — not yet clarified) to resolve them.

## Problem Statement

`vdd-comics-editor-jhanava` accumulated a large set of open questions from two sources: (1)
Джанава's framing of a content-kind taxonomy + material-systematization problem, and (2)
Бхагаван's `comics_video_sample` reference example of an "interactive video comic." Leaving all of
them embedded in that flow's requirements doc meant every future touch of that flow read as
"blocked on everything" rather than distinguishing "what's settled enough to sketch" from "what
genuinely needs a stakeholder's answer." This flow exists to carry the latter so the former can
proceed.

## Status Update (2026-08-01)

Since this backlog was written, two large builds landed that touch several Group A questions:
`sdd-comics-ai-multimodal` (from-scratch cutting/segmentation pipeline, IMPLEMENTATION COMPLETE) and
`vdd-comics-editor-ai-uiux` (in-editor trigger/review UI for that pipeline's output, IMPLEMENTATION
IN PROGRESS, Phases 1-3 of 4 done). **None of this constitutes an actual conversation with Джанава or
Бхагаван** — this flow's Acceptance Criteria still hold, real sessions are still needed. What changed
is that several questions now have a *de facto, engineering-committed answer* worth showing them
rather than asking blind, and a couple have real evidence (not just hypothesis) behind them. Each
question below is now tagged:

- **[ANSWERED]** — a real answer, given directly (2026-08-01, via Anton) — see each entry for exact
  wording. Not yet cross-confirmed with Джанава/Бхагаван by name, but this is a genuine answer, not
  an engineering inference — treat it as authoritative unless told otherwise.
- **[ANSWERED-IN-PRACTICE]** — a real, shipped/in-progress engineering decision already resolves
  this in one direction. Still worth a confirming conversation, but there's something concrete to
  react to now instead of an open-ended question.
- **[EVIDENCED]** — new real data/investigation narrows the unknown, without fully resolving it.
  Still needs the same conversation, but not from a blank slate.
- **[STILL OPEN]** — unchanged, no work has touched this at all.

**2026-08-01 answer, covers three questions at once** (raw material, character/background
placement difficulty, and reframes the tooling-vs-process question): the artist draws the **entire
comic by hand on paper**, laid out as traditional paneled/scened pages (matching what
`comics_book_lowcamera/`'s photos and `sdd-comics-ai-multimodal`'s Checkpoint A already found: the
printed book is a conventionally paginated comic with fixed panel grids — that finding is now
*explained*, not just observed). This gets digitized. Then it's **cut into regions** (background/
character/balloon/etc. — the material-intake step). Those regions are then **moved and
recomposed**: the final target is not the original paneled/scened book layout, but **one long
continuous vertical strip** ("лента"), matching exactly what the 27 existing `comics_interactive/*
.comics` files already are (tall ~33000px scrolling canvases) — the visual result should still read
as the same original artwork, just re-flowed into strip form. The person doing this cutting
("нарезатор") **exercises real creative judgment** turning paneled/scene-based paper art into a
single continuous ribbon — deciding transitions, spacing, and continuity across what were
originally separate panels. This is exactly the "order of magnitude harder than balloon
placement" Джанава's original framing pointed at: it's not placement in the trivial sense (paste
region at coordinates), it's **recomposition/reflow with creative decisions**, hardest for
background (continuity/matching across seams) and character (pose/position within the new flow).
**If the human cutter doesn't know how to do this, AI proposes a layout**, trained on the corpus of
what human cutters have historically produced. Concretely: the pairing `sdd-comics-ai-multimodal`
already built (photo of a paginated printed page ↔ matched region of the existing continuous-strip
`.comics` file, via its alignment/matching stage) **is exactly the (paneled input → recomposed
output) training signal this AI-assisted composition task would need** — not previously understood
as such; this reframes that pipeline's alignment data as more valuable than originally scoped for
(it was built for segmentation ground truth, but it doubles as recomposition ground truth).

### Technical Verification (2026-08-01, continued)

Anton then asked to verify three specific technical claims against real code/data, not memory. Result
— two confirmed, one corrected, one new gap surfaced:

1. **Confirmed**: `comics-editor-v2.9`/`comics-editor`'s data model has no layer-grouping concept at
   all (`Layer.cs` — grepped the whole editor for `Group`, zero matches). Each `Layer` is positioned
   independently via `TranslateAnim.X`/`Y` (plain ints, `TranslateAnim.cs:19-41`), keyframed against
   scroll position. So yes — a human "нарезатор" placing multiple cut regions to line up in the new
   continuous strip has to hand-calibrate each layer's X/Y numerically against its neighbors; there is
   no snap/constraint/group system to do this for them.
2. **Corrected**: this is *not* because of 512×512 tile fragments needing manual reassembly. Tiling is
   fully automatic and invisible to whoever places layers: `FileManager.UpdateTiles`
   (`FileManager.cs:52-79`) auto-slices any single image into 512×512 PNGs via ImageMagick on save, and
   `ImagePathConverter.TileImage` (`ImagePathConverter.cs:43-79`) auto-stitches them back into one
   image on load/render, keyed by `col`/`row` parsed from the filename. One cut region = one `Layer`
   with one image of arbitrary size; the 512px chunking is a storage/rendering implementation detail
   underneath that, not something a person manually aligns.
3. **Confirmed, but in a different codebase than expected**: the *reason* for 512×512 tiling — smooth
   rendering on weak devices — is real, but it's the end-user mobile viewer's job, not the editor's.
   `apps/mahabharata-mobile-java-v2026/.../controls/TileImageView.java`: `TILE_SIZE = 512`,
   `ZOOM_LEVELS = {1.0, 0.5, 0.25, 0.125}`, and `onDraw` explicitly skips non-visible tiles
   (`if (!tile.isVisible()) continue;`) plus draws a placeholder while a tile is still loading — a
   classic viewport-virtualized tile renderer (same idea as slippy-map tiles), so the ~33000px-tall
   strip is never loaded/rendered in full, only the visible window at the current zoom. (The C#
   editor's own `TileImage` converter, by contrast, stitches *all* tiles into one bitmap for its own
   preview — not virtualized, since it doesn't need to be for an editing surface.)
4. **New gap surfaced, then partially corrected on closer inspection**: asked whether a `texts`
   folder with actual visual descriptions of drawn content exists in `dataset/`, and whether
   `sdd-comics-ai-multimodal` used text context for ordering or character identity. No dedicated
   `texts` folder exists — `dataset/boranko/mahabharata/book1/` has exactly two text sources:
   `spiritual_text/` (prose narrative) and `Translation - Mahabharata Book 1.csv`/
   `Comics_Episodes.csv` (balloon dialogue + episode metadata). **Consequently, confirmed**:
   `sdd-comics-ai-multimodal` used neither for ordering or identity — **ordering/alignment** used
   OCR'd balloon dialogue matched against the CSV; **character identity** used a weak heuristic (an
   episode-name token as a seed candidate, e.g. `ambas_plea` → "amba", plus visual similarity
   clustering), explicitly flagged elsewhere as best-effort/generic (`sdd-comics-ai-multimodal/
   _status.md`: *"many are generic, e.g. 'the-2' through 'the-5'"*).
   **But — checked `spiritual_text/` directly for episode 21 (`21_ambas_plea`, the exact episode used
   to validate the character library) and it does contain matching, directly-usable narrative
   content**, including the character's own words: *"...permitted Amba, the eldest daughter of the
   ruler of Kasi to do as she liked... 'At heart I had chosen the king of Saubha for my husband...'"*
   — a close match to what the episode's art depicts, not generic plot summary. A few lines earlier,
   the same text also gives physical descriptions of two other named characters (Ambika/Ambalika:
   *"tall stature... complexion of molten gold... black curly hair..."*). **So the earlier framing
   ("plot, not panel content") was too pessimistic** — for at least this validated example, real,
   specific, usable grounding text already exists in `dataset/`; it was deferred by choice
   (`spiritual_text` marked read-only/unused per Requirements' explicit text→`.comics` deprioritization),
   not because the data itself is insufficient. One real limitation found in the same pass: this
   `spiritual_text` file is "Volume I., Book 1-3" only — a table-of-contents-style passage elsewhere in
   the same file explicitly says Amba's *continued* story (after this scene, through her later
   quest/rebirth as Shikhandi) is told in the Udyoga Parva (Book 5), not included here — so coverage is
   real but not necessarily complete for every episode/character arc. No text-grounded identity or
   ordering signal was used by `sdd-comics-ai-multimodal` — but, revised finding: not because none
   exists, rather because using `spiritual_text` for this was explicitly out of scope this iteration
   (it's the deferred text→`.comics` scenario). This is a real, still-open opportunity (added to
   Group A below) — likely cheaper to pursue than first thought, since usable grounding text is
   already sitting in `dataset/`, not something that needs to be sourced from Джанава first.

### Group A — Kind taxonomy & material intake (Джанава)

- [ANSWERED] What does "raw source material" actually look like today in the real production
      pipeline? **The artist hand-draws the entire comic on paper**, in traditional paneled/scened
      page layout, which is then digitized. See the 2026-08-01 answer above — this also retroactively
      explains why `sdd-comics-ai-multimodal`'s Checkpoint A found the printed book to be a
      conventionally paginated comic rather than a crop of the scrolling digital canvas: paneled
      paper *is* the source; the continuous strip is a downstream, cutting-stage transformation, not
      the original form.
- [ANSWERED] Is "cutting/systematizing material" a tooling problem or a process/workflow problem?
      **Both, but tooling is the real target, and specifically AI-assisted tooling**: the 2026-08-01
      answer describes the cutting/recomposition step as something a human specialist
      ("нарезатор") does with real creative judgment, and explicitly wants **AI to propose a
      composition when the human doesn't know how**, trained on prior human cutters' work. This
      confirms — with more precision than before — the direction `sdd-comics-ai-multimodal` /
      `vdd-comics-editor-ai-uiux` already bet on (build AI-assisted tooling, not a pure workflow
      change), and adds a concrete new capability neither flow built yet: **AI-proposed
      recomposition/layout**, not just AI-proposed region cutting.
- [EVIDENCED] What's the full kind taxonomy really, beyond Джанава's 4 examples (background,
      character, balloon, sound)? Practice has converged on: background / character / balloon /
      caption / sound / art(fallback), as an open-string `Layer.Kind`, plus a proposed-but-unbuilt 6th
      kind (motion/FX overlay) surfaced by Бхагаван's video sample (Group B). The editor's `_KindChip`
      and the multimodal pipeline's classifier both use this same set. **Still ambiguous**: whether
      "sound" means a visual layer kind (onomatopoeia/SFX lettering, which is how the chip treats it —
      a colored layer badge) or the existing audio-file Sounds list — this specific ambiguity was
      never explicitly disambiguated by anyone, just implicitly resolved one way in the UI. Worth a
      direct, narrow confirmation.
  - [ANSWERED-IN-PRACTICE] Are there examples worth looking at in `dataset/*.comics` for each kind,
        the way `apps/comics-ai-baloons` already did deep, evidence-based investigation for balloons
        specifically? Yes, and it's been done: `sdd-comics-ai-multimodal` applied the same
        structural-discovery method at scale for every kind — a verified Amba character gallery
        (`work/library/characters/amba/`, 11 crops, all traced to episode 21), reuse of
        `comics-ai-baloons`'s 825 balloon layers, and a labeled fixture set spanning all 4 original
        kinds for the segmentation model's classifier. The method reference is validated, not just
        proposed.
- [ANSWERED] What does "character placement, an order of magnitude harder than balloon" actually
      consist of? **Not pose/perspective matching in isolation — it's recomposing paneled/scened
      paper art into a single continuous vertical strip**, with creative decisions about where each
      cut character region lands in the new continuous flow (see 2026-08-01 answer above). Nothing
      built addresses this yet — `vdd-comics-editor-ai-uiux` scopes only to reviewing/correcting
      AI-*cut* regions into layers at their original bounding box, not this recomposition/reflow
      step. This is real, still-unbuilt scope, now understood rather than unknown.
- [ANSWERED] What does "background," the hardest category, actually require? Same recomposition
      problem as character placement, but harder because it also needs **visual continuity across
      what were originally separate panel seams** (lighting/color/perspective match) once panels are
      unrolled into one strip — the specific *mechanics* of that continuity (parallax? seamless
      tiling? manual retouch?) are still unstated and would be a good follow-up question, but the
      *nature* of the problem is now understood rather than a total unknown. Not built anywhere yet.
- [ANSWERED-IN-PRACTICE] Priority/sequencing: does material-systematization block character/
      background tooling entirely, or can they proceed in parallel with a rougher/manual
      systematization step for now? The actual build order already answers this the way Джанава
      predicted: material-systematization (the cutting/segmentation pipeline) was built *first*, as a
      prerequisite, and placement/review tooling (`vdd-comics-editor-ai-uiux`) is now being built *on
      top of* its output — not in parallel with a rough manual step. Real evidence his framing was
      right, though he hasn't confirmed it himself.
- [ANSWERED-IN-PRACTICE, revised 2026-08-01] **New question, then largely self-answered same day**:
      does any text source exist that could ground character identity/scene ordering beyond dialogue
      and episode-name heuristics? Initially assumed no — but a direct check of `spiritual_text/` for
      episode 21 (`21_ambas_plea`) found real, specific, directly-usable narrative prose matching that
      exact scene (Amba's own words to Bhishma), plus physical character descriptions nearby
      (Ambika/Ambalika). So **the raw material for text-grounded identity/ordering is already present
      in `dataset/` for at least this case** — `sdd-comics-ai-multimodal` simply never used it (text→
      `.comics` was explicitly deferred/lowest-priority per its Requirements, not a data gap). Real
      remaining unknowns: (a) coverage — the same file's own table of contents says Amba's later story
      continues in the Udyoga Parva (Book 5), not included in this "Book 1-3" file, so per-episode
      coverage isn't guaranteed complete; (b) whether an automatic text↔episode/page alignment (analogous
      to the existing OCR-balloon↔CSV alignment) is feasible against `spiritual_text`'s prose, which
      hasn't been attempted. Worth a follow-on technical spike before this needs a Джанава/Бхагаван
      conversation at all — it's an engineering question now, not a stakeholder one.

### Group B — Video/motion-comic example (Бхагаван's `comics_video_sample`)

**No work has touched any of Group B.** `sdd-comics-ai-multimodal`'s own requirements explicitly
list "Timeline/motion-FX authoring" as Won't-Have-This-Iteration and point back to this flow. All
four questions below are exactly as open as when they were written.

- [ ] What does "interactive" mean in "interactive video comic"? The reference sample shows a
      straight, non-interactive looping video (static panel → animated insert → static panel) built
      in CapCut — no touch/tap/branching shown. Is "interactive" loose marketing language for
      "feels alive," or is there a real interaction model (e.g. tap-to-reveal) this sample simply
      doesn't capture? Needs a direct question to Бхагаван/Джанава, not an assumption.
- [ ] Is video/timeline export (per the reference sample) meant to live *inside*
      `comics-editor-v2.9` as a new capability, or is the real job just to produce well-prepared
      static + motion assets for people to assemble in an external tool like CapCut? Materially
      different scopes.
- [ ] Where do animated overlay/FX assets (e.g. the glowing butterfly in the sample) come from —
      hand-animated, licensed/stock, or AI-generated (image-to-video)? Unknown; affects whether
      "material intake" needs to cover motion assets, not just static cut pieces.
- [ ] What's the audio track in `comics_video_sample` actually carrying (narration, music, ambient
      mic noise)? Not transcribed (no speech-to-text tooling was available in the environment where
      this was analyzed) — someone should actually listen to it before relying on any conclusion
      about audio scope.

### Group C — Timeline orientation & comic aspect ratio/scroll direction (Anton, 2026-08-01)

Raw question, verbatim intent: originally in Comics Editor 2.8, was the timeline oriented
vertically — 90° different from the current build? Maybe the original orientation was correct?
Is this related to comics having vertical infinite scroll? Can a comic have horizontal infinite
scroll instead? Different devices have different aspect ratios — how should comics correctly be
displayed and assembled for different ratios? How should they correctly be played back in the
comics viewer?

Investigated against real code before leaving any part of this as a blind question, per this
flow's own established practice:

- [EVIDENCED] Was v2.8's timeline vertical, 90° from today? **Confirmed, but not quite as a
      "rotated widget"** — v2.8 had no separate timeline widget at all. "Time" *was* the canvas's
      vertical scroll position: `ComicsControl.xaml:25` (a `ScrollViewer`) feeds
      `e.VerticalOffset` directly into `ComicsViewModel.Scroll` (`ComicsControl.xaml.cs:41-53`,
      `ComicsViewModel.cs:158`), which drives `TranslateAnim.Interpolate`'s keyframe factor
      (`TranslateAnim.cs:43-51`). The current Flutter `Timeline` widget
      (`apps/comics-editor/lib/src/ui/widgets/timeline.dart:7-9`, own comment: *"the modernization
      of the original's scroll-as-time model"*) is an explicit horizontal Gantt-style bar
      (`scrollDirection: Axis.horizontal` at line 129, playhead positioned via `left:`). So yes,
      confirmed 90°-different — from an *implicit* vertical scroll-as-time model to an *explicit*
      horizontal timeline bar, a deliberate modernization already documented in the new code's own
      comment, not an accidental rotation.
- [STILL OPEN] Was the original (implicit, vertical, scroll-is-time) model actually "more
      correct"? A real design-judgment question — the current horizontal timeline bar is more
      legible as a timeline (matches every other NLE/animation tool's convention) but visually
      decouples "where you are in time" from "where you are in the actual vertical scroll," which
      arguably the old model made viscerally obvious for free. No code investigation can resolve
      this — needs a real opinion from whoever championed the horizontal redesign.
- [ANSWERED-IN-PRACTICE] Is the vertical-scroll-as-time relationship why v2.8's timeline was
      vertical? **Yes, directly and mechanically**, not just a convention: v2.8 had no independent
      timeline concept — the vertical `ScrollViewer` *was* the time axis (see above), so a
      vertical timeline orientation was the *only* orientation that could have existed; there was
      nothing to separately choose.
- [EVIDENCED] Can a comic have horizontal infinite scroll instead of vertical? **Not modeled as
      impossible at the data layer, but assumed vertical everywhere around it** — real rework, not
      a config flip. `ComicsDoc` stores independent `width`/`height` with no axis flag
      (`apps/comics-editor/lib/src/ui/models.dart:179-190`), and `TranslateAnim`/`Anim` key on a
      scalar frame/scroll factor with both x/y offsets, agnostic to axis
      (`models.dart:57-83`, `TranslateAnim.cs:9-52`) — so nothing in the *authoring format* rules
      out a wide-and-short document. But: v2.8's `ScrollViewer` only ever exposes
      `VerticalOffset`/`ScrollToVerticalOffset` (`ComicsControl.xaml.cs:41,47,53`), the mobile
      viewer's restore/track logic is Y-only (`ComicsActivity.java:234`:
      `zoomLayout.translate(0, lastScroll * zoomLayout.getScale())`), and every real
      `.comics` file is extremely tall relative to its width — confirmed
      `8a89f7d689fb441ea280cd782276bd7a.comics`'s `data.json`: `{"width": 1080, "height": 33000}`
      (≈30.5:1). Building a horizontal-scroll comic today would mean reworking the editor's scroll
      binding and the mobile viewer's translate/fit logic, not just authoring a wide document.
- [EVIDENCED] How should comics be displayed/assembled for different device aspect ratios today?
      **Current real mechanism: fixed authoring width, scale-to-fit-width, scroll for (unbounded)
      height** — aspect ratio isn't really handled *per device* so much as normalized away on one
      axis. Editor: `canvas_view.dart`'s `_Stage` fits `doc.width`/`doc.height` into the viewport
      (`canvas_view.dart:37-51`) but the authoring model itself keeps `width` fixed (e.g. 1080) and
      only `height` grows without bound. Mobile viewer: `activity_comics.xml:15` sets
      `app:fitMode="horizontal"` on `ZoomFrameLayout`, and `ZoomFrameLayout.java:149`'s
      `FitMode.HORIZONTAL` branch computes `minScale = viewRect.width() / contentRect.width()` —
      width is normalized to the screen, tall content scrolls. **Still open**: whether this
      single-axis-fit model is actually right for every real device shape (e.g. a wide tablet or
      foldable in landscape gets a *much* shorter effective viewport per scroll-page than a phone
      does) — that's a genuine design question this evidence doesn't resolve by itself.
- [EVIDENCED] How should comics correctly play back in the comics viewer (today's actual
      behavior, as a baseline for "correctly")? Plain zoomable vertical scroll, not paged:
      `ComicsActivity.java:221` sets content size from `comics.getWidth()/getHeight()`, restores
      `lastScroll` via a Y-only translate (`ComicsActivity.java:234`), pinch-zoom via
      `ScaleGestureDetector` in `ZoomFrameLayout`, and end-of-scroll (`scrollY + extendedY ==
      contentHeight`, lines 128-131) marks the episode "read." No comment anywhere explains *why*
      vertical-only was chosen over a paged or horizontal alternative — that rationale, and whether
      "correct" playback should stay this simple model or do something more sophisticated (panel-
      by-panel paging, Ken-Burns-style guided reading, etc.), needs a real product conversation, not
      a code answer.

### Group D — Text-to-script pipeline (Джанава/anima-inspired, spun out 2026-08-01)

Anton shared a pipeline idea from Джанава (materials in `vendors/anima/`, a script DSL for a
*different*, generation-oriented production system): simplify scripture narrative into a
pseudo-script with named entities via LLM, then train "нарезатор"/"позиционер" on that
representation. A full survey of every real flow in this repo found no flow does LLM-based
narrative→structured-script conversion anywhere — genuinely new capability, not an existing gap in
disguise. Rather than let it stay a loose idea here, **spun out immediately into its own flow,
`flows/sdd-comics-ai-script-context/`**, since it's substantive enough to need its own Requirements/
Specifications/Plan rather than living as a backlog entry. See that flow for the full breakdown
(three consumer flows identified: `sdd-comics-ai-multimodal`'s character identity,
`sdd-comics-ai-positioning`'s `text_context` feature, `vdd-comics-editor-systematization-uiux`'s
variant tag) and the local-Ollama constraint Anton gave when creating it.

## Acceptance Criteria

### Must Have

"Done" for this flow means every question above has: an actual answer from a real conversation with
the relevant stakeholder(s), and a note on which downstream flow(s) — `vdd-comics-editor-jhanava`,
`vdd-comics-editor-uiux-lettering`, or a new one — the answer unblocks or reshapes. This flow doesn't
build anything itself; it closes when the backlog is empty (answered) or explicitly re-triaged.

### Won't Have (This Iteration)

- No design, mockups, or code — this is a question backlog, not a feature spec.

## Constraints

- This flow does not gate `vdd-comics-editor-jhanava`'s continued drafting. That flow proceeds using
  stated hypotheses/defaults where useful, and treats these questions as tracked-elsewhere, not as
  blockers on its own next steps.

## Open Questions

See "Consolidated Open Questions" above — this flow's entire payload is open questions, so they're
kept as the primary section rather than duplicated here.

## References

- `flows/vdd-comics-editor-jhanava/` — source flow these questions were extracted from; see its
  `01-requirements.md` (Reference Example section) and `_status.md` for full context on both
  Джанава's framing and the `comics_video_sample` analysis
- `flows/vdd-comics-editor-uiux-lettering/` — the narrower, currently-unblocked flow some of these
  answers may eventually feed back into (via the shared open-string `kind` field)
- `dataset/comics_video_sample(bad quality camera capture from phone).mov` — Бхагаван's reference
  example (Group B questions)
- `apps/comics-ai-baloons/` — method reference for investigating `dataset/*.comics` per-kind
- `apps/comics-editor/native/Comics.Editor/Models/Layer.cs`,
  `apps/comics-editor/native/Comics.Editor/Models/TranslateAnim.cs` — confirms per-layer manual X/Y
  positioning, no grouping concept
- `apps/comics-editor/native/Comics.Editor/Utils/FileManager.cs`,
  `apps/comics-editor/native/Comics.Editor/ViewModel/ImagePathConverter.cs` — confirms 512×512 tiling
  is automatic (slice on save, stitch on load), not manual
- `apps/mahabharata-mobile-java-v2026/app/src/main/java/com/fulldome/mahabharata/controls/
  TileImageView.java` — confirms 512×512 + zoom-level tiling exists for viewport-virtualized
  rendering in the end-user mobile viewer (smooth scroll/zoom on weak devices)
- `dataset/boranko/mahabharata/book1/spiritual_text/The Mahabharata, Volume I., Book 1-3 by Kisari
  Mohan Ganguli.html` — confirmed to contain real, scene-matching narrative prose (incl. direct
  speech) for episode 21 (`21_ambas_plea`); also confirmed self-declared incomplete (points to Udyoga
  Parva/Book 5 for Amba's continued story, not included in this file)
- `dataset/boranko/mahabharata/book1/comics_interactive/Comics_Episodes.csv` — episode 21 =
  `21_ambas_plea` = `8a89f7d689fb441ea280cd782276bd7a.comics`, confirming which real narrative
  passage corresponds to the validated character-library example
- `apps/comics-editor/native/Comics.Editor/Views/ComicsControl.xaml` + `.xaml.cs` — v2.8's
  `ScrollViewer`/`VerticalOffset` binding, confirming "time" was literally vertical scroll position
- `apps/comics-editor/native/Comics.Editor/ViewModel/ComicsViewModel.cs` (`Scroll` property) +
  `native/Comics.Editor/Models/TranslateAnim.cs` (`Interpolate`) — confirms scroll position drove
  animation keyframes directly, with no separate timeline concept, in v2.8
- `apps/comics-editor/lib/src/ui/widgets/timeline.dart` — current horizontal Gantt-style timeline,
  own comment explicitly frames itself as "the modernization of the original's scroll-as-time model"
- `apps/mahabharata-mobile-java-v2026/.../res/layout/activity_comics.xml`,
  `.../controls/ZoomFrameLayout.java`, `.../ComicsActivity.java` — confirm the mobile viewer's
  fixed-width/scale-to-fit/vertical-scroll model and Y-only scroll restore/tracking

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: Not seeking approval — this is a consolidated backlog awaiting a real stakeholder
      session, not a spec to sign off on.
