# Requirements: dot-comics-format (TDD)

> Version: 0.10 (2026-08-08: NEW — `Layer.ZDepth`, an optional per-layer parallax-depth field,
> default `0`, per Anton's direct instruction. See the new "`Layer.ZDepth` — parallax depth"
> subsection below.)
> Status: APPROVED
> Last Updated: 2026-08-08

## Promotion note (2026-08-02, read this first)

This flow started as `flows/sdd-comics-editor-fromat-dot-comics` — a parked, non-build reference
consolidation (see "Origin" below for that history, preserved as-is). Anton copied it into
`flows/tdd-dot-comics-format/` and asked for it to become a real TDD flow: catalog every existing
test touching the `.comics` format, then define the test cases needed for compatibility across
**legacy v2012 players** (`legacy/mahabharata-mobile-java-v2012`, `legacy/mahabharata-mobile-swift-
v2012`), **the v2.8 desktop editor**, and **modern v2026 viewers**
(`libs/comics_viewer/{comics-viewer-android,comics-viewer-ios,flutter_comics_viewer,
react-native-comics-viewer}`) — plus new-in-2026 format concerns: format/orientation selection
defaults (vertical vs. the historically-original horizontal "comic strip"), device screen
orientation (portrait default, landscape as a 2026 addition), and the animation-type/kind-
classification version history. See `02-tests.md` for the actual cases-first deliverable — this
file's Problem Statement/scope below has been updated to match the new mandate, but the older
consolidated facts (Origin through Position Representation) remain accurate and are kept as
background.

## Origin (predates the TDD promotion — preserved for history)

Extracted from `flows/vdd-comics-editor-timeline/` and `flows/sdd-comics-ai-positioning/` on
2026-08-01, per explicit user request: both flows independently investigated real `.comics`/
`data.json` internals (from different angles — timeline/animation-driving in one, AI
recomposition/positioning in the other) and each surfaced real, code-grounded facts about the
format itself, not just their own feature. Consolidating those facts into one place, rather than
leaving format knowledge scattered and re-discoverable-at-cost across flows, per the user's
explicit request. **This is not a feature to build** — it's a reference document, the same role
`flows/sdd-comics-editor-questions/` plays for open questions.

## Problem Statement

`.comics` format knowledge has been independently rediscovered, piecemeal, by at least two flows
so far (this consolidation's two sources), each paying the investigation cost fresh because no
single authoritative description existed to check first. Left unconsolidated, a third flow would
likely re-derive the same facts a third time, or worse, act on a stale/partial understanding one
of the two sources already corrected. This flow exists to be that single reference.

## The `.comics` Format — Consolidated Description

### Default shape: a vertical comic strip, not a paginated document

**This is the fact the user explicitly asked to be stated plainly, and it's directly confirmed,
not inferred**, in `vdd-comics-editor-timeline/03-specifications.md`:

> "the real viewer is a press-and-hold, finger-attached vertical drag — the content moves 1:1 with
> the touch point, up or down, revealing new objects below or previously-drawn ones above. There is
> no separate scroll physics/abstraction layer between the gesture and content position, and —
> critically — **no built-in concept of scene or screen boundaries at all**: it's one continuous
> strip, not a sequence of pages."
> — confirmed by Anton, 2026-08-01, `vdd-comics-editor-timeline/03-specifications.md`

`sdd-comics-ai-positioning/02-specifications.md` independently confirms the same structural default
from the geometry side: "canvas `width` is bounded/page-scale, `height` is the ~33000px scroll axis"
and "pages/panels don't stack horizontally in this format, confirmed by all 27 files' geometry."
Real document heights range far beyond that one example — `vdd-comics-editor-timeline`'s own
sampled-files check found **16,300–100,900px** across several real documents, all far taller than
wide. Nothing in the data model *forbids* a wide/short or horizontal-scroll document (no axis flag
exists — see `sdd-comics-editor-questions`'s Group C investigation, not re-derived here since it's
outside this consolidation's two named sources), but every real file, both reference viewers
(v2.8 WPF, the live Android `comics-viewer-android` library), and the confirmed end-user interaction
model are all vertical-only. **Vertical continuous strip is the default and the only thing actually
built/exercised anywhere — not a hard schema constraint, but the format's real, load-bearing
convention.**

### `scrollType` vs. device orientation vs. preferred viewport size — three independent dimensions (decided 2026-08-02, escalated to Requirements 2026-08-07, third axis added 2026-08-08)

Two genuinely separate axes, previously decided and recorded only in `02-tests.md` (Categories
B/C) — escalated here per Anton's explicit request that this not live only in Tests.

**Axis 1 — `scrollType` (a `.comics`-format/content property)**: does the document's content
scroll `"vertical"` or `"horizontal"`? Every real file today (all 27 dataset files, `samples/
sample_v2012.comics`, every 2012/v2.8/2026-authored document) has no such field and is vertical —
confirmed above. **Decided (2026-08-02, Anton)**: the format gets an explicit `scrollType` field
(proposed name/values, not yet confirmed verbatim: `"scrollType": "vertical" | "horizontal"` at
the document root, alongside `width`/`height`), defaulting to `"vertical"` when absent — full
backward compatibility with every v2012-through-2026 file, the same additive/ignorable-by-old-
readers pattern as every other schema change in this document. **Not implemented anywhere yet** —
no reader acts on this field today; defining it now is forward-preparation, matching this format's
established pattern of deciding a schema shape before any engine builds against it (`GroupId`/
`TextRegion`/`ParentId` were all specified the same way). A corresponding UI decision: the New
Document dialog (`apps/comics-editor/lib/src/ui/widgets/dialogs.dart:17-50`) gets a third option,
"century-old comic strip (horizontal infinity scroll)," **visible but disabled** — signaling intent
without committing to the engine work.

**Axis 2 — device screen orientation (`portrait`/`landscape`)**: which way the user holds their
device. **Historical fact, unchanged**: confirmed absent from the `.comics` format entirely, on
every platform, in every generation checked — has always lived purely in platform config
(`AndroidManifest.xml`'s `screenOrientation`, iOS `Info.plist`'s
`UISupportedInterfaceOrientations`, Flutter's `SystemChrome.setPreferredOrientations`), never in
`data.json`, and always as a static, app-wide setting (one manifest value for the whole app, not
per-document). Both 2012 reader apps lock the comic-reading screen to portrait; no v2026 viewer
implements landscape reading either (see "Layer & animation model" citations and `02-tests.md`
Category C).

**CORRECTION/DECISION (2026-08-07, Anton): device orientation becomes a `.comics`-format/content
property too — supersedes the "never in `data.json`" framing above.** Anton decided this axis
should move from being purely a static, app-wide platform setting to being a **per-document
`.comics` field**, alongside `scrollType`. Proposed name (not yet confirmed verbatim, following
the same naming discipline that already renamed `scrollType` away from the ambiguous bare
"orientation"): **`preferredOrientation`** — **three values**, per Anton's follow-up:
`"portrait" | "landscape" | "auto"` (`"auto"` meaning the document has no fixed preference — a
reader may rotate freely with the device). Absent → defaults to `"portrait"`, matching every
existing file's implicit, only-ever-exercised behavior — the same additive/backward-compatible
pattern as every other schema change in this document. This is a genuine upgrade in what the axis
*is*: no longer just "whatever the whole app's manifest says," but "what this specific document
declares it wants," which a reader *may* then use to decide its own platform-level orientation lock
dynamically (an implementation detail for Plan — the field is a declared preference on the content,
not a guarantee any given reader honors it, especially since no reader supports landscape or
auto-rotating rendering at all today).

**The independence principle still holds, refined**: `scrollType` and `preferredOrientation` are
now **both** `.comics`-format fields, but remain two **separate, independently-set** fields that
must never be coupled or inferred from one another. No implementation may hardcode
"`scrollType == horizontal` implies `preferredOrientation == landscape`" or the reverse — a
document could in principle declare any combination of the two, even an unusual one (e.g.
`scrollType:"horizontal", preferredOrientation:"portrait"`), and a reader must honor whatever each
field independently says, never derive one from the other. This mirrors the exact reasoning that
already renamed `scrollType` away from the ambiguous bare "orientation" name — keeping the two
fields distinctly named and independently read is what makes the principle enforceable in code,
not just in prose.

**Axis 3 — preferred viewport size (NEW, 2026-08-08, Anton: "дополни новым аттрибутом документа
preferd phone-viewport-sized с дефолтом 720×1600 там же где Orientation")**: how large (in pixels)
a reading viewport this document is authored/intended for — independent of both `scrollType`
(which axis scrolls) and `preferredOrientation` (which way is "up"); this axis is about *scale/
extent* of the viewing window, not direction. Motivated directly by
`flows/comics-editor/tdd-dot-lottie-import-export`'s real "Playback Viewport" Lottie export/import
mode (`01-requirements.md`'s Export/Import Modes section, 2026-08-08): that mode needs a real
viewport rectangle to compose each scene's sweep against, and `samples/sample_playback_viewport
.lottie_unzip`'s real Lottie composition is confirmed **720×1600** (checked byte-level: `w`/`h`
top-level keys) — a genuine, already-produced value, not an arbitrary round number.

**Naming (chosen by Claude, per Anton's explicit delegation — "Правильный нейминг сделай
самостоятельно")**: **`preferredViewportWidth`** / **`preferredViewportHeight`** — two flat integer
fields, not a nested `{width,height}` object. Reasoning: the document root already has flat
`width`/`height` for the canvas itself (`ComicsDoc.width`/`.height`); a nested-object convention is
used elsewhere in this format only for genuinely compound/variant shapes (`LayerMask`'s
`rect`/`points`/`maskFile` union, `TextRegion`'s equivalent) — a plain fixed pair of ints doesn't
need that, and flat fields keep this new axis visually/structurally parallel to the existing
`width`/`height` pair it's a sibling concept to, and to `preferredOrientation`'s own flat,
single-key shape. Rejected alternative: `preferredViewportSize` as one nested object — adds a level
of JSON nesting for no real benefit here, and breaks the parallel with `width`/`height`.

**Defaults**: `preferredViewportWidth` → **720**, `preferredViewportHeight` → **1600**, absent →
both defaults apply — matching the real value found in `samples/sample_playback_viewport
.lottie_unzip` exactly, and (same backward-compat reasoning as every other addition in this
document) representing today's implicit, only-ever-exercised assumption for any document that
predates this field, not a behavior change.

**Independence, same principle as Axes 1-2**: `preferredViewportWidth`/`Height` must never be
coupled to or inferred from `scrollType` or `preferredOrientation` — a document can in principle
declare any combination (e.g. `preferredOrientation:"landscape"` with a portrait-shaped
720×1600 viewport size — an unusual but not-forbidden combination), and no implementation may
hardcode a derivation between them. **Not implemented anywhere yet** in `apps/comics-editor` or any
reader — this is a forward-looking schema decision, matching this format's established pattern
(`GroupId`/`TextRegion`/`ParentId`/`scrollType`/`preferredOrientation` were all specified the same
way, engine work deferred to a later Plan). No corresponding UI decision is proposed here — unlike
`scrollType`/`preferredOrientation`, which got New Document dialog tiles
(`flows/tdd-dot-comics-format/04-visual.md` Screens/`05-plan.md` Phase 2, shipped), this field's
primary real motivation so far is the Lottie Playback Viewport export/import path specifically, not
a general editor-UI concern — whether it eventually gets its own New Document dialog control is an
open question for whoever picks up that work, not decided here.

### Layer & animation model

- A `.comics` document's editable unit is the **`Layer`** — every kind of content (background,
  character, balloon, sound-adjacent visual) is the same generic `Layer` type; there is no
  layer-grouping/parent-child concept anywhere (`sdd-comics-ai-positioning/01-requirements.md`,
  verified against `apps/comics-editor/native/Comics.Editor/Models/Layer.cs`, zero `Group` matches
  repo-wide). Every layer's position is an independent `TranslateAnim.X`/`Y` int pair.
- Animation keyframes (`Anim` and its subtypes — `translate`/`rotate`/`scale`/`alpha`/`sound`, per
  `vdd-comics-editor-timeline/01-requirements.md`'s `AnimType` enum) are **driven by scroll/pan
  position, not wall-clock time** — a pure function of "how far down the strip has the reader
  scrolled," confirmed identically across three independent implementations: the original v2.8 WPF
  editor (`TranslateAnim.Interpolate(Anim, double scroll)`), the real shipping Android viewer
  library `comics-viewer-android` (`Layer.java`/`LayerAnim.java`, a same-shape Java port with an
  added easing curve), and — per `sdd-comics-ai-positioning`'s own framing — the AI recomposition
  work's target space being "one continuous Y-axis" for exactly this reason.
- **Sound is on the same single scroll value, not a separate mechanism**: `SoundAnim`'s
  `Start`/`End` is a scroll-range gate (`Sound.Create()` seeds `{Start=scroll, End=scroll}`), and
  both the legacy WPF app and the real Android viewer drive visual matrices *and* sound triggering
  off the identical scroll number in the same tick (`vdd-comics-editor-timeline/01-requirements.md`).
- `Anim.start`/`end` values are **small numbers (roughly 48–6000 observed)**, not 1:1 with document
  pixel height (which ranges 12,000–100,900px in the same sampled files). **RESOLVED (2026-08-02,
  by `vdd-comics-editor-vertical-scroll`, not by empirical testing as originally planned)**: there
  is no unit mismatch and no scale factor. `Anim.Start`/`End` are in the exact same raw-pixel
  coordinate space as scroll position — a keyframe range only needs to span the short window
  (~200px) during which one specific transition plays; once passed, the value holds unchanged for
  the rest of the document, however tall. See that flow's `01-requirements.md`, Major Finding
  point 9, and `03-specifications.md`'s corrected Investigation Note.
- Only a minority of real layers use rotation: **1146 of 4594** real layers have a `RotateAnim` at
  all (`sdd-comics-ai-positioning/01-requirements.md`, via `render_canvas.py`'s documented finding).

### Animation driving model: scroll position and time as two independent dimensions (added 2026-08-07)

**Historical fact, unchanged**: `.comics` v2012 animations were **always** scroll-position-based —
confirmed identically across the 2012 Java reader, the 2012 Swift reader, and v2.8, all sharing the
same `Anim.Factor(scroll)`-shaped cubic ease-out with no wall-clock/time concept anywhere (see
"Layer & animation model" above and `02-tests.md` Part 2). This remains true forever for every
existing file — nothing about the past changes.

**Forward decision (Anton, 2026-08-07)**: `.comics` v2026 animations are scroll-position-based **by
default**, when no time-basis is specified — i.e. every existing file, and any new file that
doesn't opt in, behaves identically to today, full backward compatibility by construction (the
same non-breaking-additive pattern already used for `Kind`/`Style`/`Translations`/`scrollType`/
`GroupId`/`TextRegion`). **But an anim may additionally be marked time-based when explicitly
specified** — making scroll position and wall-clock time **two independent driving dimensions**,
not one replacing the other. A layer can have some properties driven by scroll (e.g. translate,
revealing as the reader scrolls) and others driven by time (e.g. rotate, looping continuously
whether or not the reader is scrolling) simultaneously.

This directly closes the "leg-swing" gap identified independently by two prior flows
(`vdd-comics-editor-timeline`'s Discoveries #3, `vdd-comics-editor-vertical-scroll`) and left
explicitly unresolved/out-of-scope by both: neither v2012 nor any v2026 code shipped to date lets a
character keep animating (e.g. a swinging leg) while the reader has stopped scrolling — every
existing keyframe is a pure function of scroll, frozen the instant scrolling stops. See `02-tests.md`
Test Case D4 for the cases-first behavioral shape of this addition, and `03-specifications.md` for
the (early, D4-scoped) schema/interface design. **Not implemented anywhere yet** — this is a
decided direction, not a claim about current behavior.

### Complete animation-type inventory, and Lottie-import coverage (added 2026-08-07)

Per Anton's request: the full, exhaustive list of every animation type `.comics` supports today,
and whether that list covers what `.lottie` import (`flows/comics-editor/tdd-dot-lottie-import-
export`) actually needs. **Answer: no — real, already-produced Lottie content uses several
features `.comics` has no representation for, confirmed against all 7 real produced chapters, not
just the one file (`ASHES.json`) earlier research sampled.** This corrects and narrows
`flows/tdd-dot-lottie-format`'s own open question (L6/L7: "does `ASHES.json`'s simple structure
generalize to the other 6 chapters?") — investigated directly for this addition, answer is **no,
it does not generalize**.

**The complete `.comics` animation-type list** (confirmed identical across 2012 Java, 2012 Swift,
v2.8 C#, and current Dart — the *only* schema change in the model's entire history is the additive
`Kind`/`Style`/`Translations`/`GroupId`/`TextRegion` layer-level fields, none of which are animation
types):

| # | Type | Fields | What it drives |
|---|------|--------|----------------|
| 1 | Translate | `x`, `y` | Layer position (absolute, per-keyframe) |
| 2 | Rotate | `angle`, `pivotX`, `pivotY` | Layer rotation about a static pivot |
| 3 | Scale | `scaleX`, `scaleY`, `pivotX`, `pivotY` | Layer scale about a static pivot |
| 4 | Alpha | `alpha` | Layer opacity |
| 5 | Sound | `start`, `end` only (a gate, no interpolated value) | Real audio playback trigger, scroll-range-gated |

Every one of these five is a pure function of one shared driving value (scroll position; see above
for the new, additional time-basis option). There is no 6th type, no per-vertex/path animation, no
color animation, no skew — confirmed by the same `diff -rq`/cross-platform enum comparison already
established in `02-tests.md` Part 2.

**Real Lottie content's actual property usage — investigated directly against all 7 real produced
chapters** (`dataset/mahabharata/boranko/mahabharata-dot-lottie/unzip/.../*_content/*.json`, not
just the one sample used in earlier research):

| Lottie feature | Found in real content? | `.comics` equivalent? | Verdict |
|---|---|---|---|
| `p` (position) | Yes, all 7 files | Translate | Covered |
| `s` (scale, 2D) | Yes, all 7 files | Scale | Covered |
| `r` (rotation, 2D) | Yes, all 7 files | Rotate | Covered |
| `o` (opacity) | Yes, all 7 files | Alpha | Covered |
| `a` (anchor point) | Present on every layer, but **always static, never animated** (0 animated anchors across all 7 files) | Rotate/Scale's static `pivotX`/`pivotY` | Covered in practice — anchor's real role here is exactly "pivot," never an independent animated track |
| `sk`/`sa` (skew, skew axis) | **No** (0/7 files) | None | Gap, but unexercised by real content |
| 3D rotation (`ddd:1`, `rx`/`ry`/`rz`) | **No** (0/7 files, all `ddd:0`) | None | Gap, but unexercised by real content — consistent with `.comics` being a flat 2D scroll strip by design |
| Shape layers (`ty:4`, vector paths/fills/strokes) | **No** (0/7 files) | None | Gap, but unexercised by real content |
| Text layers (`ty:5`) | **No** (0/7 files) | None (relies on baked images + the new `TextRegion` metadata) | Gap, but unexercised by real content |
| Effects (`ef`) | **No** (0/7 files) | None | Gap, but unexercised by real content |
| **Masks (`masksProperties`, vector paths)** | **YES — 1/7 files** (`THE CHASE`, 6 masked layers — **every single one a static, 4-vertex rectangle**, `mode:"a"`, no curve handles, never animated — confirmed by direct inspection, not organic/arbitrary shapes) | None for general layers (the new `TextRegion` mask option is scoped to lettering only, not general per-layer masking) — **decided**: a new, separate `Layer.Mask` field (see "Masks & Solid Colors" below) | **Real, confirmed gap, addressed** |
| **Null/organizational layers (`ty:3`)** | **YES — 1/7 files** (`SVAYAMWARA`, 1 null layer) | None — every `.comics` `Layer` implies a visible image reference — addressed by the new organizational `Kind` value above | **Real, confirmed gap, addressed** |
| **Solid color layers (`ty:1`)** | **YES — 1/7 files** (`THE BROKEN TUSK`, "White Solid 1": `sc:"#ffffff"`, `sw:720`, `sh:27326`) | None — no flat-color-fill layer type — **decided**: a new `Layer.SolidColor` field (see "Masks & Solid Colors" below), **not** a `Kind` value (see rationale) | **Real, confirmed gap, addressed** |
| **Layer parenting (`parent` field — one layer's transform relative to another's)** | **YES — 5/7 files**, and **heavily** in `THE BROKEN TUSK` (190 of 295 layers, 64%) | None — every `.comics` `Anim` is an absolute value; the format has zero parent-relative transform concept | **The single most consequential real gap** — affects the majority of layers in at least one real, already-produced chapter |

**Why this matters beyond a checklist**: `tdd-dot-lottie-format`'s original conversion-feasibility
conclusion ("`.comics → .lottie` is simple math; `.lottie → .comics` is simple *conditionally*, for
content staying within a simple image-layer-only subset") was based on `ASHES.json` alone and
explicitly flagged this as unconfirmed for the other 6 chapters (L6/L7). **It's now confirmed
negative for the majority of real chapters**: `THE BROKEN TUSK` alone has 64% of its layers using
parent-relative transforms — a real character rig built from many named anatomical parts (e.g.
"голова"/head, "руки сложен"/folded arms, "предплечье"/forearm — confirmed real layer names)
parented to each other, not a flat stack of independent layers. The already-decided "bake
absolute values at import time" mechanism (for precomp nesting, per
`tdd-dot-lottie-import-export/01-requirements.md`'s Precomp Handling decision) needs to
**generalize to resolving the full parent chain per layer**, not just precomp-child relationships —
a real, larger implementation task than that flow's Specifications currently scope. Masks, null
layers, and solid layers are each confirmed in at least one real file too, meaning the "no shape/
mask/text Lottie support" Won't-Have in that same flow excludes real, already-produced content, not
just hypothetical edge cases — worth Anton's explicit acknowledgment, not a silent scope gap.

### Layer parenting & organizational layers — new v2026 schema concepts (added 2026-08-07)

**Historical fact, unchanged**: `.comics` has never had a layer-grouping or parent-child concept —
every layer's position has always been an independent, absolute `TranslateAnim.X`/`Y` pair, "zero
`Group` matches repo-wide" (see "Layer & animation model" above, `sdd-comics-ai-positioning/
01-requirements.md`). This was true for every real file checked, v2012 through today.

**Forward decision (Anton, 2026-08-07)**: following directly from the real, confirmed Lottie
findings above (layer parenting in 5/7 real chapters, up to 64% of one file's layers; null/
organizational layers in 1/7), `.comics` v2026 gains two new, additive schema concepts:

1. **`Layer.ParentId`** (new, optional, nullable string) — references another layer's stable
   identity within the same document. When present, that layer's authored transform is
   **conceptually relative to its parent** during editing (move the parent, children visually
   follow — matching how Lottie's own `parent` field and every mainstream design/animation tool's
   parenting behaves), but **the file always persists each layer's fully resolved, absolute `Anim`
   keyframes** — the exact same backward-compatibility mechanism already established for `GroupId`
   ("bake absolute values, `ParentId` is editor-side/live-authoring metadata only"). A v2012 reader
   that has never heard of `ParentId` renders every layer correctly, using the same absolute values
   it always has — parenting is invisible to it, not broken by it.
2. **A new `Kind` value for organizational/non-content layers** (e.g. `"organizational"` or
   `"anchor"` — exact string not yet finalized), extending the existing **open-string** `Kind`
   field (`background`/`character`/`balloon`/`sound`/`art`, per `sdd-comics-editor-questions`) —
   no new field needed, matching that field's own design philosophy of being open-ended precisely
   so new values could be added without a schema migration. Represents Lottie's `ty:3` null-layer
   equivalent: a layer that exists purely to be a parent/organizational anchor for other layers,
   carrying no visual content of its own. **Design implication needing verification, not
   assumed**: does every current reader already skip rendering a layer with zero populated image
   slots gracefully (in which case no *rendering* change is needed, only the `Kind` label for
   editor clarity), or would an empty-image layer currently error/render a blank placeholder? Not
   yet checked against real reader code.

**Real-world motivation, restated plainly**: this isn't a speculative feature — `THE BROKEN TUSK`
(a real, already-produced chapter) is a genuine character rig built from named anatomical parts
("голова"/head, "руки сложен"/folded arms, "предплечье"/forearm) parented to each other via
Lottie's own mechanism. Without `ParentId`, importing this content into `.comics` can only ever
flatten it into independent absolute-keyframe layers with no memory of the original hierarchy —
`GroupId` alone (a flat, symmetric "these belong together" tag) cannot express *who is parented to
whom*, only *that a set of layers are related*. `ParentId` is the more fundamental mechanism this
real content actually needs.

**Prerequisite, not yet designed**: `ParentId` needs something stable to reference. `.comics`
layers currently have no explicit per-layer identity field (position in the `Layers` list is the
only implicit "identity," and it's not stable across reordering/undo). **A new `Layer.Id` (stable,
e.g. a GUID assigned at layer creation) is a real prerequisite this decision surfaces**, not
something to retrofit from list position. See `03-specifications.md` for the proposed shape.

**Relationship to `GroupId` — genuinely open, not decided**: does `ParentId` subsume `GroupId`'s
role (a shared ancestor implies grouping, so the layers panel's "collapse as one group" UI could be
derived from parent chains instead of a separate flat tag), or do the two coexist for different
cases (e.g. `GroupId` for simple, non-hierarchical precomp-flattening; `ParentId` for real,
multi-level rigs)? Not resolved here — flagged as a real design question for whoever picks up
`flows/comics-editor/tdd-dot-lottie-import-export`'s Precomp Handling work next, since that flow's
own Specifications now needs updating to know `ParentId` exists as a cleaner mapping target for
Lottie's `parent` field than baking-and-discarding.

### Masks & Solid Colors — DECIDED (2026-08-07, Anton: "используем твою рекомендацию")

Anton asked directly: should masks and solid-color layers become new `Kind` values, the same way
organizational layers just did? **Decided: no** — these answer a different question than `Kind`
already answers, and forcing them into it would create a real modeling conflict, not just a style
preference.

**The distinction**: every existing `Kind` value (`background`/`character`/`balloon`/`sound`/`art`,
plus the new `organizational`) describes a layer's **semantic role** — what it *represents* in the
comic. Masks and solid colors describe **how a layer's pixel content is produced** — orthogonal to
role entirely. A solid-color layer could just as easily *be* a background, a balloon backing, or a
transition overlay; a mask can apply to a background, a character, or anything else. If `Kind` were
`"solid"`, there would be nowhere left to record that the layer is *also*, say, a background — one
string field can't hold two independent facts at once. This is not hypothetical: `THE BROKEN
TUSK`'s real solid layer ("White Solid 1", full chapter height) is almost certainly serving as a
plain backdrop — its role is `background`-like even though its content-source is a flat fill, not a
raster image.

**Proposed alternative — two new, separate additive fields** (not `Kind` values):

- **`Layer.SolidColor`** (nullable hex color string, e.g. `"#ffffff"` — mirrors Lottie's own `sc`
  field exactly). When set, the layer renders as a flat color fill instead of a raster image;
  mutually exclusive with populated `Images[]` slots. `sw`/`sh` (Lottie's solid width/height) map
  onto the layer's own existing size representation, no new field needed there.
- **`Layer.Mask`** — same `rect`/`polygon`/`mask` shape vocabulary already designed for
  `TextRegion`, but a **genuinely separate field**: `TextRegion` answers "where does lettering go
  inside this layer," `Mask` answers "what shape is this layer's own visible content clipped to" —
  different questions, even though they happen to share a convenient shape representation.
  **Real evidence makes this cheap**: all 6 real masks found (`THE CHASE`) are static, 4-vertex
  rectangles — `shape: "rect"` alone would represent every real instance found so far; `polygon`/
  `mask` exist for future-proofing, not because real content needs them yet.

Both follow the same additive, ignorable-by-old-readers backward-compat pattern as every other
schema change in this document. **Decided, adopted as-is.** Remaining detail (exact
`solidColor`/`Images[]` precedence when both are somehow set) is still open — see Open Questions —
but the core decision (separate fields, not `Kind` values) is settled.

### `Layer.ZDepth` — parallax depth (NEW, 2026-08-08, Anton: "добавь в .comics v2026 в reqs и specs глубину z-depth для создания эффекта паралакс. По дефолту 0 или если не указано то 0 для совместимости с v2012")

A new, additive, **per-`Layer`** field (not document-level, unlike `scrollType`/`preferredOrientation`/
`preferredViewportWidth`/`Height` above) — every layer may optionally declare its own relative depth
along a notional Z axis, purely to drive a **parallax** effect: as the reader scrolls, layers further
"back" appear to move less per unit of scroll than layers further "forward," faking depth on a format
that is otherwise, and remains, a genuinely flat 2D scroll strip. This doesn't contradict the earlier
animation-inventory finding that real content never uses true 3D transforms (`ddd:1`/`rx`/`ry`/`rz` —
**0 of 7** real produced Lottie chapters) — `ZDepth` never introduces an actual 3D
transform/projection, only a per-layer scroll-response scaling.

**Decided (2026-08-08, Anton's direct instruction)**: `Layer.ZDepth`, a numeric field, **defaults to
`0`** — and, per Anton's explicit instruction, **absent-key and explicit-`0` are the same value**, not
two cases needing separate handling. `0` means "no depth offset" and must reproduce **exactly** what
every existing v2012-through-2026 layer already does today: its authored `Anim` keyframes are the full,
literal onscreen motion, moving 1:1 with scroll with no additional scaling. This is the same
additive/backward-compatible pattern as every other schema change in this document (`GroupId`/
`TextRegion`/`ParentId`/`scrollType`/`preferredOrientation`/`preferredViewportWidth`/`Height`) — old
readers that have never heard of `ZDepth` simply never see the key and render unaffected; new readers
that see it absent must behave identically to seeing it explicitly `0`.

**Relationship to the existing driving model**: per "Layer & animation model" above, every `Anim`
keyframe is already a pure function of one driving value (scroll position, or — per the 2026-08-07
decision — optionally wall-clock time). `ZDepth` does not introduce a third independent driving
dimension; it **modulates the scroll-driven dimension specifically** — a coefficient applied to how a
layer's position responds to scroll, not a new independent axis a layer's `Anim` is a function of. A
layer with a nonzero `ZDepth` and no time-basis anim remains purely scroll-driven; the depth just
changes the felt "speed" of that scroll response.

**Genuinely open, not decided here** (flagged rather than guessed, matching this format's discipline
elsewhere in this document): the exact sign convention (does positive mean "further away/slower" or
"closer/faster"?), the precise formula relating `ZDepth` to a scroll-response scaling factor, the
field's unit/range (a small bounded float like typical parallax-library "speed factors," or an
unbounded "distance" value), whether `ZDepth` composes through `Layer.ParentId` chains (does a child
inherit or add to its parent's depth, mirroring the still-open `ParentId`/`GroupId` relationship
question above?), and which reader(s) implement the actual parallax math first. See
`03-specifications.md` for the proposed interface shape and the same open questions carried into that
document's Open Design Questions.

### Position representation (recomposition/AI-pipeline framing)

Per `sdd-comics-ai-positioning/02-specifications.md`: absolute canvas X/Y (matching
`TranslateAnim.X`/`Y`'s own representation, plain ints) is the ground-truth position shape. For
work that predicts/proposes positions rather than reading existing ones, two derived views are used
internally: **relative-to-page-anchor Y** (canvas Y minus a page's own estimated anchor, since
absolute Y depends on all of an episode's prior content) and **X predicted directly** (no anchor
issue, since panels never stack horizontally in this format). No geometric/pixel-level mapping from
a real source photo into canvas space exists or is obtainable (`comics-multimodal`'s `package.py`
design note, cited in `sdd-comics-ai-positioning/01-requirements.md`) — positioning within this
format has to be a learned/heuristic placement problem, not a coordinate transform.

## Acceptance Criteria

### Must Have

1. **Given** a future flow that needs to know a `.comics` fact already investigated by
   `vdd-comics-editor-timeline` or `sdd-comics-ai-positioning`, **when** it checks this document
   first, **then** it finds that fact here, cited back to its original source, instead of
   re-deriving it from code.
2. **Given** any fact stated in this document, **when** it's checked against the original source
   flow's own text, **then** it matches (verbatim quote or faithful paraphrase) — this document does
   not introduce new claims beyond what its two named sources already established.
3. **Given** the new scroll-vs-time animation-dimension decision (2026-08-07) and the animation-type/
   Lottie-coverage inventory, **when** either is checked against real code/real files, **then** every
   claim is cited to a specific source (a real file investigated directly, or a named prior flow's
   own finding) — no claim in either new section is asserted from general knowledge alone.
4. **Given** `Layer.ParentId` and the new organizational-layer `Kind` value (2026-08-07), **when**
   either is checked, **then** the backward-compatibility mechanism matches every prior additive
   schema change exactly (absolute values always persisted; old readers ignore the new field/value
   and render unaffected) — no new field in this document ever requires an old reader to understand
   it for correct display.
5. **Given** the new `Layer.ZDepth` field (2026-08-08), **when** it is absent or explicitly `0` on any
   layer, **then** that layer's rendering is byte-identical to today's behavior for every pre-existing
   `.comics`/`.puzzle` file — no reader needs to understand `ZDepth`, and no distinction exists between
   "absent" and "explicitly `0`," to render any file correctly.

### Should Have (added with the TDD promotion, 2026-08-02)

- A catalog of every existing automated test anywhere in the repo that touches the `.comics`
  format, so `02-tests.md`'s cases-first analysis builds on real existing coverage instead of
  re-deriving it blind.
- Cases-first behavioral analysis (per TDD discipline) covering: legacy v2012 compatibility,
  format/orientation defaults, device screen orientation, animation-type/kind-classification
  version history, and v2026 multi-platform viewer parity.

### Won't Have (This Iteration)

- No new code, no schema changes — `02-tests.md` defines cases; fixing any bugs the cases-first
  analysis surfaces is explicitly a separate, later decision (see `02-tests.md`'s Bugs section),
  not silently done as part of this Tests-phase pass.

## Constraints

- This document must stay a faithful extraction. If either source flow's own understanding is later
  corrected (as `vdd-comics-editor-timeline` itself already did once, mid-flow, about the mobile
  viewer's keyframe support), this document needs a matching correction, not a silent drift.

## Open Questions

- [x] Should this consolidation be extended to pull in additional real format facts from other
      flows? **Done (2026-08-02)** — a full sweep of every remaining SDD/VDD flow
      (`sdd-comics-ai-multimodal`, `sdd-comics-ai-baloons`, `sdd-comics-editor-questions`,
      `sdd-comics-editor-build`/`-publish`/`-v2.9`/`-v2.9-android-ios`/`-v2.9-fixes1`/`-fixes2`,
      `vdd-comics-editor-jhanava`, `vdd-comics-editor-uiux-lettering`, `vdd-comics-editor-ai-uiux`,
      `vdd-comics-editor-systematization-uiux`, `sdd-comics-ai-script-context`,
      `sdd-comics-ai-transformations`) is in `02-tests.md`'s References/background section, each
      with what it does and doesn't contribute to format facts.
- [x] The exact `Anim.start`/`end` ↔ document-pixel-height unit relationship — **resolved**, see the
      correction above in Layer & animation model.
- [ ] `Layer.ZDepth`'s exact sign convention, scroll-response formula, unit/range, and whether it
      composes through `ParentId` chains — not decided, see `03-specifications.md`'s Open Design
      Questions.

## References

- `flows/vdd-comics-editor-timeline/01-requirements.md`, `03-specifications.md` — source of the
  vertical-strip-confirmed-by-Anton quote, the `Anim`/scroll-as-time model, the sound-on-same-value
  finding, the `AnimType` enum, and the unresolved `Anim.start`/`end` unit-relationship risk
- `flows/sdd-comics-ai-positioning/01-requirements.md`, `02-specifications.md` — source of the
  layer/no-grouping model, the `TranslateAnim.X`/`Y` position representation, the
  canvas-width-bounded/height-is-scroll-axis geometry fact, the RotateAnim usage statistic, and the
  no-pixel-level-source-mapping finding
- `flows/vdd-comics-editor-timeline/01-requirements.md` (Discoveries #3), `flows/comics-editor/
  vdd-comics-editor-vertical-scroll` — the "leg-swing" gap this flow's new time-basis dimension
  directly closes
- `flows/tdd-dot-lottie-format/01-requirements.md` — the original conversion-feasibility analysis
  (based on `ASHES.json` alone) that this flow's animation-inventory section corrects/narrows
- `flows/comics-editor/tdd-dot-lottie-import-export/01-requirements.md`, `03-specifications.md` —
  the Precomp Handling decision this flow's parenting finding says needs to generalize
- `dataset/mahabharata/boranko/mahabharata-dot-lottie/unzip/.../*_content/*.json` — all 7 real
  produced Lottie chapters, inspected directly (not just the one previously-sampled file) for the
  animation-inventory/coverage table

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-07 (v0.8 baseline); v0.9 (2026-08-08, `preferredViewportWidth`/`Height`)
      and v0.10 (2026-08-08, `Layer.ZDepth`) additions approved same-session — for v0.10, Anton
      directly specified the field's purpose (parallax), name (`z-depth`), and default (`0`,
      identical whether absent or explicit, for v2012 compatibility), per this document's established
      pattern of folding in narrow, directly-dictated decisions without a separate re-approval round
      (unlike the broader, still-open Export/Import Modes addition in the sibling `tdd-dot-lottie-
      import-export` flow, which was left pending re-review as a larger design space).
- [x] Notes: Approved as drafted, including all schema decisions (time-basis, `ParentId`/
      organizational layers, `Mask`/`SolidColor`, `scrollType`/`preferredOrientation`,
      `preferredViewportWidth`/`Height`, `Layer.ZDepth`) and the Lottie-coverage gap analysis. This
      supersedes the original "not seeking approval" framing — this document has grown well beyond a
      passive reference consolidation into a real set of approved schema decisions. `Layer.ZDepth`'s
      exact math (sign, formula, `ParentId` composition) is explicitly carried forward as open, same
      treatment as this document's other undecided numeric/formula details.
