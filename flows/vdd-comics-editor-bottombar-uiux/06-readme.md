# Comics Editor Viewer and Properties Navigation

> Client-Facing Documentation  
> Status: DRAFT — AWAITING APPROVAL
> Last Updated: 2026-08-05  
> Product Version: 3.2.1

Comics Editor 3.2.1 keeps the existing responsive editor and adds a dedicated
review workspace. On phones the bottom bar is now `Scene / Viewer /
Properties`; New and Open remain in the top menu. On tablet and desktop,
`Editor / Viewer` switches the central workspace without moving existing panes.

Viewer is review-only. Scene, Properties, and Timeline are hidden while it is
open. Vertical-scroll comics use a position control along the right edge.
Android and iOS use native viewers, macOS/Linux/Web use the shared Dart renderer
where supported, and Windows keeps the Flutter shell while hosting only the WPF
comics surface as a child view.

Properties has two tabs in this order:

1. `Selection` — selected layer/sound artwork, preview, and animations.
2. `Document` — Width, Height, Puzzle Scale when applicable, and Convert.

All legacy numeric animation properties are present: Start, End, Translate X/Y,
Rotate Center X/Y and Angle, Scale Center X/Y and Scale X/Y, Alpha, plus Sound
Start/End. Desktop shows an editable exact number beside each slider. Touch
devices open exact inline editing with one tap. Values outside a slider's
convenient range remain preserved.

Artwork and lettering languages are dynamic. Existing used languages remain
as tabs; Add opens a searchable list of active unused languages. Deactivating a
catalog language does not shift its stored slot or hide older content.

Layer visibility uses eye/eye-off controls on every editor layout. New
documents default to `Vertical-scroll comic strip` and Portrait. `Horizontal
infinity scroll comic strip` and Landscape are shown but disabled for now;
Puzzle remains available.
