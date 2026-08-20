# Visual Mockups: comics-editor-preview-uiux

> Version: 0.1
> Status: APPROVED (2026-08-12, "visual approved")
> Last Updated: 2026-08-12
> Requirements: [01-requirements.md](01-requirements.md) (v0.2, APPROVED)

## Overview

All mockups are the existing `CanvasView` (`apps/comics-editor/lib/src/ui/widgets/canvas_view.dart`)
stage, unchanged in overall structure — only the layer-rendering content and the bottom-right control
cluster change. `_ZoomControl` stays bottom-left, unchanged. The bottom-right corner currently holds
one control (`_PreviewToggle`, per-element); this flow adds a second, adjacent control for the
canvas-wide toggle, per the approved "canvas-local corner" placement decision.

Placeholder rendering (`HatchSwatch`: solid color fill + diagonal hatch lines + layer name label) is
drawn literally with a fill character + `///` hatch marks below. Real-content rendering is drawn as a
framed box labeled `REAL: <asset>` to distinguish it from the placeholder without implying an actual
image renderer for this ASCII format.

### Elements

| Symbol | Meaning |
|--------|---------|
| `[####]` `///` | `HatchSwatch` placeholder (today's existing rendering, unchanged) |
| `[REAL: x]` | Real image content (`Layer.images`) — the new rendering path |
| `( Preview )` | Per-element toggle, `_PreviewToggle`, enabled only when a layer is selected |
| `( All )` | New canvas-wide toggle, always enabled |
| `●` / `○` | Toggle filled = on, hollow = off |
| `[sel]` | Selected-layer border (existing, unchanged) |

---

## Screen: Canvas — Default State (both toggles off, nothing selected)

Every layer renders exactly as today — no behavior change, confirms Must-Have 4.

```text
+--------------------------------------------------------------------+
|                                                                     |
|   +----------------+                                               |
|   | [#####] Sky    |                                               |
|   | ///////////    |                                               |
|   +----------------+                                               |
|                                                                     |
|          +------------------+                                      |
|          | [#####] Chariot  |                                      |
|          | ///////////      |                                      |
|          +------------------+                                      |
|                                                                     |
|                    +----------------+                               |
|                    | [#####] Krishna|                               |
|                    | ///////////    |                               |
|                    +----------------+                               |
|                                                                     |
| [ - zoom + ]                              ○ Preview   ○ All        |
+--------------------------------------------------------------------+
```

---

## Screen: Canvas — One Layer Selected, Per-Element Preview OFF

Selecting a layer enables `( Preview )` (today's existing selection-gated behavior, unchanged) but it
still renders as a placeholder until toggled on.

```text
+--------------------------------------------------------------------+
|                                                                     |
|   +----------------+                                               |
|   | [#####] Sky    |                                               |
|   | ///////////    |                                               |
|   +----------------+                                               |
|                                                                     |
|         [sel]======[sel]                                            |
|         # [#####] Chariot  #                                        |
|         # ///////////      #   <- selected, still placeholder       |
|         [sel]======[sel]                                            |
|                                                                     |
|                    +----------------+                               |
|                    | [#####] Krishna|                               |
|                    | ///////////    |                               |
|                    +----------------+                               |
|                                                                     |
| [ - zoom + ]                              ○ Preview   ○ All        |
|                                              ^ now enabled           |
|                                              (a layer is selected)  |
+--------------------------------------------------------------------+
```

---

## Screen: Canvas — Per-Element Preview ON for the Selected Layer

Toggling `( Preview )` flips that one layer's `Layer.preview` to `true` — only it shows real content;
every other layer is untouched (Must-Have 2, Must-Have 5 keeps the same transform/position).

```text
+--------------------------------------------------------------------+
|                                                                     |
|   +----------------+                                               |
|   | [#####] Sky    |                                               |
|   | ///////////    |                                               |
|   +----------------+                                               |
|                                                                     |
|         [sel]===============[sel]                                   |
|         # [REAL: chariot.png] #                                     |
|         # (real art, in place, |                                    |
|         #  same size/rotation) #                                    |
|         [sel]===============[sel]                                   |
|                                                                     |
|                    +----------------+                               |
|                    | [#####] Krishna|                               |
|                    | ///////////    |                               |
|                    +----------------+                               |
|                                                                     |
| [ - zoom + ]                              ● Preview   ○ All        |
+--------------------------------------------------------------------+
```

---

## Screen: Canvas — Canvas-Wide Preview ON (`All`), No Selection

Toggling `( All )` shows real content everywhere, independent of any per-element flag or selection.
No layer needs to be selected for this to work (Must-Have 3).

```text
+--------------------------------------------------------------------+
|                                                                     |
|   +----------------+                                               |
|   | [REAL: sky.png] |                                              |
|   +----------------+                                               |
|                                                                     |
|          +------------------+                                      |
|          | [REAL: chariot.png]                                     |
|          +------------------+                                      |
|                                                                     |
|                    +----------------+                               |
|                    | [REAL: krishna.png]                            |
|                    +----------------+                               |
|                                                                     |
| [ - zoom + ]                              ○ Preview   ● All        |
+--------------------------------------------------------------------+
```

---

## Screen: Canvas — Canvas-Wide ON + One Layer's Own Preview Also ON

Demonstrates the approved OR semantics: turning `All` off later drops back to exactly this state
(Chariot still real, because its own flag is independently `true`), not back to the fully-placeholder
default. No visual difference is needed between "real because of its own flag" and "real because of
`All`" — Requirements' Should-Have (distinct toggle affordance) is satisfied by the toggle cluster
itself, not per-layer markers.

```text
+--------------------------------------------------------------------+
|                                                                     |
|   +----------------+                                               |
|   | [REAL: sky.png] |            <- real only because All is on    |
|   +----------------+                                               |
|                                                                     |
|          +------------------+                                      |
|          | [REAL: chariot.png]    <- real for BOTH reasons (own     |
|          +------------------+        flag AND All) -- same visual   |
|                                                                     |
|                    +----------------+                               |
|                    | [REAL: krishna.png]  <- real only because of   |
|                    +----------------+         All                  |
|                                                                     |
| [ - zoom + ]                              ● Preview   ● All        |
+--------------------------------------------------------------------+
```

### After turning `All` back off (Chariot was individually toggled on earlier)

```text
+--------------------------------------------------------------------+
|                                                                     |
|   +----------------+                                               |
|   | [#####] Sky    |            <- back to placeholder (no own flag)|
|   | ///////////    |                                               |
|   +----------------+                                               |
|                                                                     |
|          +------------------+                                      |
|          | [REAL: chariot.png]   <- stays real (its own flag is     |
|          +------------------+        still true, untouched by All) |
|                                                                     |
|                    +----------------+                               |
|                    | [#####] Krishna|                               |
|                    | ///////////    |                               |
|                    +----------------+                               |
|                                                                     |
| [ - zoom + ]                              ● Preview   ○ All        |
+--------------------------------------------------------------------+
```

---

## Screen: Canvas — Preview Requested but No Real Image Asset

Per the approved "silent fallback" decision: a layer with preview requested (its own flag, or via
`All`) but an empty/missing `LayerImage.file` renders identically to the placeholder-off state — no
badge, no broken-image icon, indistinguishable from a layer that simply has preview off.

```text
+--------------------------------------------------------------------+
|                                                                     |
|                    +----------------+                               |
|                    | [#####] Untitled Layer                         |
|                    | ///////////    |    <- preview requested, but  |
|                    +----------------+        no LayerImage.file --  |
|                                               falls back silently   |
|                                                                     |
| [ - zoom + ]                              ○ Preview   ● All        |
+--------------------------------------------------------------------+
```

---

## Component: Bottom-Right Toggle Cluster

Replaces today's single `_PreviewToggle` widget with a two-toggle group. `Preview` keeps its existing
enabled/disabled-by-selection behavior; `All` is always enabled.

```text
+------------------------+
|  ○ Preview   ○ All     |   <- both off (default)
+------------------------+

+------------------------+
|  ( disabled ) ○ All    |   <- no layer selected: Preview greyed out,
+------------------------+      exactly like today; All always usable

+------------------------+
|  ● Preview   ○ All     |   <- selected layer's own preview on
+------------------------+

+------------------------+
|  ○ Preview   ● All     |   <- canvas-wide on
+------------------------+
```

---

## Flow: Toggling Preview

```text
[All layers placeholder] --(select a layer)--> [Preview enabled for that layer]
        |                                                |
        |                                     (toggle Preview on)
        |                                                v
        |                                [Selected layer -> real; rest placeholder]
        |                                                |
        |                                     (toggle Preview off)
        |                                                v
        |<---------------------------------[Selected layer -> placeholder again]
        |
(toggle All on, any time, no selection needed)
        v
[Every layer -> real, regardless of selection/per-element flags]
        |
(toggle All off)
        v
[Exactly the per-element state from before All was toggled on -- no data lost]
```

---

## Notes

- No new visual language for "this layer is real because of `All`" vs. "because of its own flag" —
  Requirements' Should-Have is satisfied at the toggle-cluster level (you can see `All`'s state), not
  per-layer. If this turns out to be confusing in practice, a per-layer indicator can be a fast-follow,
  not blocking this flow.
- The `[sel]` selection border (existing behavior, `primary ? Hs.blue500 : ...`) is unchanged and
  applies identically whether a layer is showing placeholder or real content — selection and preview
  are orthogonal, confirmed by the existing code (`_LayerItem` already separates `selected`/`primary`
  from any preview-related state).
- Missing-asset fallback (last screen above) intentionally looks identical to "preview off" — this
  was Anton's approved choice over a distinct broken-image indicator; noted here so it isn't mistaken
  for an oversight during Specifications/Implementation review.
- Puzzle-mode canvas is not mocked here — per Requirements' Open Question, whether `_LayerItem` is
  shared with Puzzle mode is still an unconfirmed codebase fact, to be resolved in Specifications
  before deciding if Puzzle needs its own mockup.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-08-12 ("visual approved")
- [ ] Notes:
