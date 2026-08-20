# Real artwork preview on the Comics Editor canvas

The canvas can now switch between lightweight hatched placeholders and the real artwork stored in a comic.

## What changed

Two controls sit together in the bottom-right corner of the canvas:

- **Preview** shows real artwork for the currently selected layer.
- **All** shows real artwork for every layer on the canvas.

Think of `Preview` as a spotlight for one layer and `All` as turning on the lights for the whole stage.

## How to use it

1. Select a layer and turn on **Preview** to inspect only that layer's artwork.
2. Turn on **All** to inspect the whole composition with real images.
3. Turn **All** off to return to the previous per-layer choices. A layer whose own **Preview** was enabled stays enabled.

The **All** control works even when no layer is selected.

## Safe fallback

If artwork is missing, incomplete, or temporarily unavailable, the canvas keeps showing the familiar hatched placeholder. Editing remains usable and no broken-image panel interrupts the workflow.

## Session behavior

The **All** setting is a viewing convenience for the current editor session. It is not saved into the comic and does not add an undo step. Individual layer **Preview** choices keep their existing saved behavior.

## Performance

Real artwork is loaded only when one of the preview controls requests it. Panning and zooming reuse the loaded result instead of rebuilding the artwork on every movement.

## Supported documents

The same behavior applies to both comics and puzzle canvases because they share the canvas layer renderer.
