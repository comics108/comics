# Visual Mockups: comics-editor-uiux-lettering

> Version: 1.1
> Status: APPROVED
> Last Updated: 2026-07-30

## Amendment history (2026-07-30) — net effect: original design stands

Two rounds of change after this document's initial approval, kept here for an honest trail rather
than silently rewritten:

1. **Amended**: product-friend input initially resolved this flow's open questions, including
   dropping the "Lettering mode" page in favor of Properties-panel-only integration.
2. **Reverted**: the user judged that letting one product consultation narrow this flow's original
   scope was the wrong move — Джанава's input is real and valuable, but belongs to a *bigger*,
   separately-scoped initiative (spun out to `flows/vdd-comics-editor-jhanava/`), not as a
   constraint retrofitted onto this narrower, already-well-designed flow. **This flow returns to
   its original plan**: the "Lettering mode" screens below (macOS, iPad landscape, iPhone) and the
   "Flow: Entering and using Lettering mode" section are the active design again, not superseded.
3. **One correction carried forward regardless of the revert**: language handling must be
   **dynamic** (driven by whatever language set the data actually has), never a hardcoded count —
   neither the "existing 3" nor "all ~20" framing below should be read as a fixed number. See
   `03-specifications.md` for how this is implemented.

The Balloon editor card component remains valid either way (it was always designed to also work
embedded in the Properties panel, per its own original notes) — that flexibility is preserved, it's
just not the *only* surface anymore, matching the original plan.

## Overview

Grounded in the existing shipped design system (`design/comics-editor-maket-v3.pdf`, "HolySpots DS
v3.0" — sky-blue accent, cloud-canvas background, Roboto, coral reserved for destructive actions,
44px minimum touch targets on iPad, three-pane desktop workspace, iPad landscape split view with a
collapsible Scene rail and Properties-as-right-sheet). That mockup is the "same tools as v2.8"
baseline — it does **not** yet have balloons, text, or AI. Everything below is new, designed to
slot into that same visual language rather than replace it.

Two additions:

1. **Layer-kind badges/colors** in the existing Scene panel's layer list (small, low-risk, applies
   everywhere immediately).
2. **A new "Lettering" mode** — a dedicated, focused page (DaVinci-style page-switching, not a
   deeper properties-panel tree) for working through a page's balloons: text per language, AI
   generation, on-device/server routing. iPad-first; desktop gets the same layout in the existing
   three-pane frame.

Color proposal for layer kinds (provisional — doesn't touch the existing sky-blue/coral
vocabulary): **violet** for Balloon (speech), **amber** for Caption, existing neutral gray for
Art/Other. Shown as both a color swatch *and* a text label/icon — never color alone (accessibility).

### High-fidelity companion reference

`design/comics-editor-lettering-maket.pdf` + `design/comics-editor-lettering-maket/` (added
2026-07-30) is a pixel-level rendering of this same structure — macOS/iPad/iPhone, HolySpots DS
tokens applied — produced from this draft. Treat it as the authoritative visual reference
alongside the ASCII below; details below are updated to match it where it's more precise:

- Exact tokens: violet `#7b5cd6`, amber `#b8820f` (both new, outside the existing sky-blue/coral
  vocabulary — blue stays selection, coral stays destructive/error). UI chrome uses `--font-core`
  (Roboto); balloon text — both the input field and the rendered preview's editing-time
  representation — uses a distinct `--font-serif-data` token, keeping "your dialogue" visually
  separate from "the app's UI" even before it's generated.
- **Kind chip (list) vs. style chip (detail card) are two different labels, not one**: the layers/
  balloon-rail list rows show the coarse *kind* (`Bln`/`Cap`/`Art`); the balloon editor card's
  header chip shows a finer *style* label instead — `speech`, `caption`, or `hand-lettered` — same
  violet color family, more specific text. `hand-lettered` is a style value, not a fourth kind.
- Its own footer explicitly flags the same three things this doc's Notes already called out as
  open: the Balloon/Caption/Art taxonomy, the language set beyond En·Ru·Hi·Uk, and Lettering as a
  distinct mode. **Still open, not resolved by having a prettier mockup of the same proposal.**

---

## Screen: Scene panel — layer list with kind badges

Extends the existing LAYERS list (left pane, both desktop and iPad). Each row gets a small kind
chip before the thumbnail.

```
+------------------------------------------------+
|  LAYERS                              [+] [^][v] [x] |
+------------------------------------------------+
|  (=)  [Art]      [img] sky.png                  |
|  (=)  [Art]      [img] clouds.png               |
|  (=)  [Bln]      [img] hero_balloon_04           |   <- violet chip, selected
|  (=)  [Cap]      [img] caption_02                |   <- amber chip
|  (=)  [Art]      [img] foreground.png            |
+------------------------------------------------+
```

### Elements

| Symbol | Meaning |
|--------|---------|
| `(=)` | Visibility toggle (existing) |
| `[Bln]` | Balloon kind chip — violet fill, "Bln" label + speech-bubble glyph |
| `[Cap]` | Caption kind chip — amber fill, "Cap" label + box glyph |
| `[Art]` | Art/other kind chip — neutral gray, no glyph (today's default, unchanged behavior) |

### States

#### Legacy file (no `kind` field at all — backward-compat check)

```
|  (=)  [Art]      [img] hero.png                 |   <- every layer shows as [Art]
```
Every layer without an explicit `kind` renders exactly as today (neutral, no chip color) — visually
identical to the current shipped app. This is the acceptance criterion for "old files keep working"
made visual, not just a data-layer guarantee.

---

## Screen: Lettering mode — iPad landscape (primary target)

Reached via a new mode switch in the top bar (see Flow below), replacing the general three-pane
Edit workspace with a focused two-pane layout: a filtered **balloon rail** (left, replaces the
general Scene panel — only balloon/caption-kind layers on the current page/frame) and a **balloon
editor** (right, large, touch/stylus-first).

```
+--------------------------------------------------------------------+
|  [<- Edit]   beach.comics · Lettering        [<prev] 3/7 [next>]   |
+----------------+---------------------------------------------------+
| BALLOONS (7)   |  hero_balloon_04                       speech    |
|                |                                                   |
| [Bln] #01  o   |  +---------------------------------------------+  |
| [Bln] #02  o   |  |                                               |
| [Bln] #03  *   |  |         (balloon artwork preview)             |
| [Cap] #04  o   |  |          "AND AMBA TOLD..."                   |
| [Bln] #05  --  |  |                                               |
| [Bln] #06  --  |  +---------------------------------------------+  |
| [Cap] #07  --  |                                                   |
|                |  LANGUAGE   [ En ] [ Ru ] [ Hi ] [ Uk ] [ + Add ]  |
|                |                                                   |
|                |  TEXT (Ru)                                       |
|                |  +---------------------------------------------+  |
|                |  | И Амба рассказала Парашураме о несчастьях,   |  |
|                |  | что приключились с нею.                      |  |
|                |  +---------------------------------------------+  |
|                |                                                   |
|                |         [ Generate artwork with AI ]  (o) On-device|
|                |                                                   |
+----------------+---------------------------------------------------+
```

### Elements

| Symbol | Meaning |
|--------|---------|
| `[<prev] N/M [next>]` | Step through this page's balloons without leaving the mode |
| `o` (solid dot) | Has artwork for the *currently open/target* language specifically |
| `o` (ring/outline dot) | Has text but no generated artwork yet, for the current target language |
| `*` | Currently selected balloon |
| `--` | Empty — no text in any language yet |
| `[ En ]` (filled) | Language tab with both text *and* artwork present |
| `[ Uk ]` (outline only) | Language tab with text but no generated artwork yet |
| `[ + Add ]` | Add a new language not yet on this balloon (opens language picker) |
| `(o) On-device` | Routing indicator — see Generation states below |

The status dot is per-*target-language*, not a single balloon-wide flag — a balloon can show solid
(artwork ready) while you're looking at En and switch to ring/outline the moment you tab to a
language that only has text so far. This matters for scanning the rail quickly against whichever
language you're currently localizing.

Touch targets (language tabs, prev/next, Generate button) are >=44px per the existing DS spec.

### States

#### Empty balloon (no text in any language yet)

```
|  hero_balloon_04                                   speech     |
|                                                                |
|  +----------------------------------------------------------+ |
|  |                                                            |
|  |              (empty balloon outline preview)               |
|  |                    no text yet                             |
|  |                                                            |
|  +----------------------------------------------------------+ |
|                                                                |
|  LANGUAGE   [ + Add language ]                                |
|                                                                |
|              Add a language to start lettering this balloon.  |
```

#### Text entered, not yet generated

```
|  TEXT (Uk)                                                    |
|  +----------------------------------------------------------+ |
|  | Тестовий переклад...                                       |
|  +----------------------------------------------------------+ |
|                                                                |
|           [ Generate artwork with AI ]   (o) On-device         |
|           No artwork yet for Uk — preview shows En as fallback |
```

#### Generating (loading)

```
|           [ Generating... =====>        ]                     |
|           (o) On-device · erasing existing text                |
```
or, when routed remotely (device can't run it locally, or user/quality forced it):
```
|           [ Generating... =====>        ]                     |
|           (@) Cloud · this may take a little longer            |
|           This device can't render Hindi shaping locally —     |
|           sent to the server.                                  |
|                                                    [ Cancel ]   |
```
The on-device/cloud indicator is always visible during generation, not just an internal detail —
per the requirement that routing be transparent to the user, not silently swapped. When routed to
cloud, the reason is stated in plain language (not just "cloud" vs "on-device" as a bare label) —
the example above is language-shaping capability, but the same slot covers "quality mode" or
"network required" depending on why it routed. **Cancel is available during generation** —
included after review of the high-fidelity reference; the original draft's states didn't have an
escape hatch mid-generation, which is a real gap for anything that "may take a little longer."

#### Generation succeeded

```
|  +----------------------------------------------------------+ |
|  |                                                            |
|  |    (new balloon artwork preview, Uk text rendered)         |
|  |                                                            |
|  +----------------------------------------------------------+ |
|  [Uk] tab now filled/solid — artwork present                  |
|           [ Regenerate ]              Generated just now       |
```

#### Generation failed

```
|           ! Couldn't generate artwork for Uk.                 |
|             Text didn't fit the balloon even at minimum size.  |
|           [ Retry ]   [ Edit text ]                            |
```
(Error copy varies by cause — text_overflow vs. render error vs. network/server error for the
cloud path — exact copy is a Specifications-phase detail, not fixed here.)

#### Hand-lettered balloon (flagged, not auto-generatable)

```
|  hero_balloon_12                             hand-lettered    |
|                                                                |
|  +----------------------------------------------------------+ |
|  |         (original hand-lettered artwork preview)           |
|  +----------------------------------------------------------+ |
|                                                                |
|  ! This balloon was hand-lettered by an artist. AI generation  |
|    is disabled here — flagged for manual work instead.         |
|             [ Open in Art mode to edit manually ]              |
```
Mirrors `comics-ai-baloons`' Track 6b decision (flag, don't auto-render) — the UI must not offer a
"Generate" button for a balloon the pipeline itself refuses to touch.

---

## Screen: Lettering mode — Desktop

Same content, laid out in the existing three-pane frame (balloon rail where Scene normally sits,
balloon editor where Properties normally sits, canvas in the middle shows the current balloon
highlighted in context on the full page — useful on desktop's larger canvas, omitted on iPad's
tighter landscape layout above to keep touch targets large).

```
+--------------------------------------------------------------------------------+
|  Comics Editor 3.0   beach.comics   [Edit | Lettering]        [En][Ru][Hi][Uk]  |
+------------------+---------------------------------------+---------------------+
| BALLOONS (7)      |                                       |  hero_balloon_04    |
| [Bln] #01    o     |         (full page canvas,            |  speech              |
| [Bln] #02    o     |          current balloon               |                     |
| [Bln] #03    *     |          highlighted)                  |  (artwork preview)  |
| [Cap] #04    o     |                                       |                     |
| [Bln] #05    --    |                                       |  LANGUAGE tabs...   |
| ...                |                                       |  TEXT editor...     |
|                    |                                       |  [Generate] (o)     |
+------------------+---------------------------------------+---------------------+
```

---

## Screen: Lettering mode — iPhone

Single column, added after reviewing the high-fidelity reference (not in the original draft): the
two-pane iPad layout doesn't fit a phone width, so it splits into two full screens — a balloon
*list* screen and a balloon *editor* screen — keeping the same one-tap-from-list-to-editable
depth rather than nesting further.

```
Balloon list screen                    Balloon editor screen
+---------------------------+          +---------------------------+
| [< Edit]  Lettering  pg.1 |          | [< Balloons]   #03 · 3/7  >|
+---------------------------+          +---------------------------+
| [Bln] #01  En Ru Hi  o  > |          | hero_balloon_04  [Bln]sp. |
| [Bln] #02  En Ru     o  > |          |                            |
| [Bln] #03  Ru text  (o) > |  <- tap  | +------------------------+ |
| [Cap] #04  En Ru Hi  o  > |          | | (artwork preview,       | |
| [Bln] #05  Empty    -- > |          | |  En w/ Ru fallback)     | |
| [Bln] #06  Empty    -- > |          | +------------------------+ |
| [Cap] #07  Empty    -- > |          |                            |
+---------------------------+          | LANGUAGE [En][Ru][Hi][+Add]|
                                        | TEXT (Ru)                 |
                                        | +------------------------+ |
                                        | | И Амба рассказала...    | |
                                        | +------------------------+ |
                                        |                            |
                                        | [ Generate artwork with AI]|
                                        |   (o) Will run on-device   |
                                        +---------------------------+
```

Each list row shows a one-line status summary (which languages have text, artwork-readiness dot)
so the list itself is scannable without opening every balloon. Same prev/next stepping as iPad,
now as `<`/`>` arrows either side of the "N/M" counter in the editor screen's header.

---

## Flow: Entering and using Lettering mode

```
[Edit mode]  --(tap "Lettering" mode switch, top bar)-->  [Lettering mode: first balloon on page]
     ^                                                              |
     |                                                    (tap [next>]/[<prev], or
     |                                                     tap a balloon in the rail)
     |                                                              v
     |                                                    [Lettering mode: balloon N]
     |                                                              |
     |                                              (edit text) --> (tap Generate)
     |                                                              |
     |                                                              v
     |                                                    [Generating... state]
     |                                                          /        \
     |                                                    success        failure
     |                                                        |              |
     |                                                        v              v
     |                                              [Artwork updated]   [Error, Retry/Edit]
     |                                                              |
     +---------------------(tap "Edit", top bar)-------------------+
```

### Step-by-Step

1. **Edit mode** (today's existing workspace): user works on layout/art as before. A new mode
   switch appears in the top bar next to the document name.
2. **Enter Lettering mode**: switches the left+right panes to the balloon rail + balloon editor;
   canvas (desktop) or the balloon preview (iPad) updates to match. Lands on the first balloon with
   no artwork yet, or the first balloon overall if all are complete.
3. **Select/step through balloons**: via the rail (tap) or prev/next (keyboard arrow / swipe on
   iPad). No nested navigation — one tap from list to editable balloon.
4. **Edit text, add a language**: text field per language tab; `[+ Add]` opens a language picker
   (scope of which languages are offered ties to the Open Question on language coverage).
5. **Generate**: single button, always visible when text exists; shows the on-device/cloud routing
   indicator during generation (not before — routing is decided at generate-time based on
   current hardware/network state).
6. **Return to Edit mode**: same top-bar switch: back to the general workspace, with the balloon's
   updated artwork now visible like any other layer edit.

---

## Component: Balloon editor card

The reusable core of the right-hand pane above — same component whether hosted in Lettering mode
or (a smaller, collapsed variant) inside the existing Properties panel's per-layer editor in Edit
mode, so a user who prefers staying in Edit mode isn't blocked from doing basic lettering there too.

```
+--------------------------------------------------+
|  hero_balloon_04                       speech     |   <- style chip, violet, not "Bln"
+--------------------------------------------------+
|  (artwork preview)                                |
+--------------------------------------------------+
|  LANGUAGE   [En][Ru][Hi][Uk][+ Add]               |
|  TEXT (current language)                          |
|  +----------------------------------------------+ |
|  |                                                |
|  +----------------------------------------------+ |
|  [ Generate artwork with AI ]      (o) On-device  |
+--------------------------------------------------+
```

Note the header chip here reads the *style* value (`speech` / `caption` / `hand-lettered`), not
the list's coarse kind label (`Bln`/`Cap`/`Art`) — see High-fidelity companion reference above.

---

## Notes

- Color + label/icon together for kind chips (never color alone) — accessibility, per DS baseline
  which already uses color deliberately (coral = destructive) rather than decoratively.
- All new touch targets follow the existing 44px minimum from the DS's iPad spec.
- The on-device/cloud routing indicator is a **visible, permanent** UI element during generation,
  not a hidden implementation detail — ties to the Requirements constraint that routing be
  transparent to the user. When cloud-routed, state *why* in plain language, not just the label.
- A **Cancel** action must exist during generation — added after cross-checking the high-fidelity
  reference; anything that can be routed to "may take a little longer" needs an escape hatch.
- Hand-lettered balloons explicitly show a disabled-generation state rather than hiding the
  balloon or silently allowing a bad AI attempt — mirrors the AI pipeline's own flag-only decision
  for Track 6b. The header shows this as a *style* value (`hand-lettered`), same visual family as
  `speech`/`caption`, not a fourth top-level kind.
- Kind chip (list rows: `Bln`/`Cap`/`Art`) and style chip (balloon editor card header: `speech`/
  `caption`/`hand-lettered`) are two distinct labels at two distinct altitudes — coarse for
  scanning a list, specific once you're looking at one balloon.
- iPhone gets its own two-screen flow (list screen -> editor screen), not a cramped shrink of the
  iPad two-pane layout — added after reviewing the high-fidelity reference, which designed it
  explicitly; the original draft only covered iPad + desktop.
- `design/comics-editor-lettering-maket.pdf` + its companion folder (added 2026-07-30) is now the
  authoritative pixel-level reference for all of the above; this document stays as the structural/
  state-coverage record and cross-references it rather than duplicating every visual detail.
- **Resolution status (2026-07-30, see Amendment history at top)**: kind taxonomy stays
  Balloon/Caption/(Art as the untyped default) *for this flow's scope* — the fuller
  background/character/balloon/sound taxonomy Джанава proposed is real but belongs to
  `vdd-comics-editor-jhanava`, not retrofitted here. Language coverage in `[+ Add]` is **dynamic**
  (whatever languages the data has — En/Ru/Hi/Uk above are illustrative examples, not a fixed
  list). Lettering mode as a distinct page is **confirmed** as the design — the original ambition
  stands, after briefly being reconsidered and reverted back.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-07-30
- [x] Notes: Approved as-is. The 3 still-open items (kind taxonomy, language coverage, Lettering
      mode as a distinct page) were not resolved explicitly — Specifications will make and document
      concrete decisions rather than re-asking a third time, flagged clearly for override.
