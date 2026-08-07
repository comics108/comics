# Visual Mockups: comics-editor-systematization-uiux

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-08-07

## Scope note

This document covers **only** the "Layer Grouping" topic added to `01-requirements.md` on
2026-08-07 — the layers-panel UI for grouping layers within a `.comics` document. It does **not**
cover the original character-variant-tagging topic (still blocked on a real Джанава session, not
yet at Visual phase). See `01-requirements.md`'s "Scope note" for why this flow now holds two
unrelated topics.

## Screen: Layers panel — before grouping (today's real UI)

`scene_panel.dart`'s `_LayersSection`/`_LayerRow` — a flat list, matching the real current
implementation exactly (`+`/reorder buttons already exist; nothing below is invented UI chrome):

```
+--------------------------------------+
| LAYERS                    [+] [^][v] |
+--------------------------------------+
|  o  background_sky.png               |
|  o  32_1.png                         |
|  o  32_3.png                         |
|  o  32_4_bg.png                      |
|  o  balloon_hero_01.png       [Bln]  |
+--------------------------------------+
```

## Screen: multi-select → Group action

```
+--------------------------------------+
| LAYERS                    [+] [^][v] |
+--------------------------------------+
|  o  background_sky.png               |
|  [x] 32_1.png            <-- selected|
|  [x] 32_3.png            <-- selected|
|  [x] 32_4_bg.png         <-- selected|
|  o  balloon_hero_01.png       [Bln]  |
+--------------------------------------+
|  3 selected      [Group]  [Cancel]   |
+--------------------------------------+
```

## Screen: Layers panel — after grouping (collapsed, the default state)

```
+--------------------------------------+
| LAYERS                    [+] [^][v] |
+--------------------------------------+
|  o  background_sky.png               |
|  o  > Group 1 (3)                    |  <- collapsed, expand triangle
|  o  balloon_hero_01.png       [Bln]  |
+--------------------------------------+
```

### Elements

| Symbol | Meaning |
|--------|---------|
| `o` | Visibility toggle (existing) |
| `[x]` | Multi-select checkbox state (new, appears in a "select mode") |
| `>` / `v` | Collapsed / expanded group disclosure triangle (new) |
| `(3)` | Member count shown on the collapsed group row (new) |
| `[Bln]` | Existing kind chip (balloon), unrelated to grouping, shown for contrast |

## Screen: Layers panel — group expanded

```
+--------------------------------------+
| LAYERS                    [+] [^][v] |
+--------------------------------------+
|  o  background_sky.png               |
|  o  v Group 1 (3)                    |  <- expanded
|       o  32_1.png                    |  <- indented, member row
|       o  32_3.png                    |
|       o  32_4_bg.png                 |
|  o  balloon_hero_01.png       [Bln]  |
+--------------------------------------+
```

## Flow: dragging a grouped layer on canvas moves the whole group

```
Canvas, Group 1 collapsed in panel but all 3 members visible/selectable on canvas:

  before drag                          after dragging any member by (dx,dy)
  +----------------+                   +----------------+
  |    [32_1]      |                   |                |
  |  [32_4_bg]     |     -- drag -->   |      [32_1]    |
  |    [32_3]      |                   |    [32_4_bg]   |
  |                |                   |      [32_3]    |
  +----------------+                   +----------------+
  (relative positions          (same relative positions,
   among the 3 members)         all shifted by the same
                                 (dx,dy) -- group moves as
                                 one rigid unit)
```

Per `01-requirements.md`'s Acceptance Criterion 3, this is achieved by applying `(dx,dy)` to *each
member's own keyframes* at drag-end (the same mechanism ordinary multi-select drag already uses
today) — not by introducing a separate group-level transform. A saved file looks, to any reader,
exactly like three independently-positioned layers that happen to have moved together — because
that's literally what happened.

## Component: Lottie import producing a pre-populated group

```
Importing a .lottie file whose root has a precomp layer named "Character_Ashes"
referencing 3 nested image layers:

  Import result in the layers panel:

  +--------------------------------------+
  | LAYERS                    [+] [^][v] |
  +--------------------------------------+
  |  o  v Character_Ashes (3)            |  <- group name inherited from
  |       o  32_1.png                    |     the precomp's own `nm` field
  |       o  32_3.png                    |     (Open Question: confirmed default,
  |       o  32_4_bg.png                 |     not yet decided as final policy)
  +--------------------------------------+
```

Each member layer's keyframes are already the *baked, absolute* values (precomp transform ×
child's own local transform, pre-multiplied at import time) — the group here exists purely so the
user can still see and manage "these 3 layers came from one precomp," not because rendering needs
it.

## Notes

- No new screen/navigation flow — this is entirely within the existing Scene panel's Layers
  section. No empty/loading/error states apply (a purely local, synchronous UI operation, no
  network/async involved).
- Deliberately did not mock up nested groups (group-of-groups) or a group-rename UI — both tied to
  Open Questions in `01-requirements.md` not yet decided.

---

## Approval

- [ ] Reviewed by:
- [ ] Approved on:
- [ ] Notes:
