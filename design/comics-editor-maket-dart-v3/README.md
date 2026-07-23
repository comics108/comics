# Comics Editor 3.0 — Flutter

Adaptive recreation of the WPF Comics Editor, styled with the **HolySpots Design System**
(sky-blue accent, cloud canvas, Roboto, coral for destructive actions). Same functionality
as v2.8 — no new features — reorganized as a calm, timeline-driven workspace that runs on
**iPhone / Android phones, iPad / Android tablets, and Windows / macOS / Linux desktop**.

## Run

This package ships `lib/` + `pubspec.yaml`. Generate the platform runners once, then run:

```bash
cd flutter/comics_editor
flutter create .            # adds android/ ios/ macos/ windows/ linux/ web/ runners
flutter pub get
flutter run                 # pick a device: -d chrome | macos | windows | linux | <phone>
```

> Requires Flutter 3.10+ (Dart 3). No third-party packages — pure Flutter SDK.
> Roboto is bundled by Flutter on most targets; drop the real font into `assets/` and
> declare it in `pubspec.yaml` if you have the licensed original.

## Adaptive layout (`src/responsive.dart`)

| Form factor | Breakpoint | Layout |
|-------------|-----------|--------|
| Phone | ≤ 600 dp | Canvas full-bleed + compact timeline; **Scene** & **Properties** open as bottom sheets from a dock; language via popup |
| Tablet (iPad) | 601–1024 dp | Scene ∣ Canvas ∣ Properties split; timeline is a compact strip that expands; 44 px touch targets |
| Desktop | ≥ 1025 dp | Scene (300) ∣ Canvas ∣ Properties (330) with the full docked timeline; hover states |

## Functionality parity with v2.8

- **File**: New ▸ Comics / Puzzle, Open (recent list), Save (`controller.dart`, `dialogs.dart`)
- **Language**: En / Ru / Hi — switches which localized artwork slot the Layer editor shows
- **Canvas settings**: Width / Height + Convert
- **Layers**: add · move up/down · delete · per-layer visibility toggle · select
- **Sounds**: add · move · delete · global Mute
- **Layer editor**: per-language File + Popup, Preview flag, animations
- **Animations**: add Translate / Rotate / Scale / Alpha (Sound cue for sounds), delete,
  edit params; every anim shares Start / End
- **Canvas**: drag the selected layer (Translate), 8 resize handles + rotate stem, puzzle
  Scale zoom (0.125–1×), Fit
- **Timeline**: track per layer/sound, animation bars span Start→End, draggable playhead

## Structure

```
lib/
  main.dart                     app + EditorScope (InheritedNotifier state)
  src/
    theme.dart                  HolySpots tokens (colors, radii, motion, type)
    models.dart                 Doc / Layer / Sound / Anim / Lang / AnimType
    controller.dart             EditorController (ChangeNotifier) + sample scene
    responsive.dart             FormFactor breakpoints
    screens/editor_screen.dart  adaptive shell (desktop / tablet / phone)
    widgets/
      common.dart               HsButton, HsIconButton, HsSegmented, HsToggle, NumberField…
      top_bar.dart              brand, doc pill, actions, language
      scene_panel.dart          canvas settings + Layers + Sounds
      canvas_view.dart          stage, drag, handles, zoom, preview
      properties_panel.dart     layer / sound editors + anim param cards
      timeline.dart             docked + compact timeline
      dialogs.dart              New / Open / duplicate-file error
```

State is a single `EditorController extends ChangeNotifier`, shared via `EditorScope`
(`InheritedNotifier`) and rebuilt with `AnimatedBuilder` — no external state package.

## Notes / caveats

- Artwork is drawn as hatched placeholders (`HatchSwatch`) — wire real image loading into
  `LayerImage.file` when integrating.
- Save/Convert show confirmation toasts (no real file IO / ImageMagick pipeline here).
- On-canvas rotate/scale handles are drawn and the Translate drag is live; wiring the
  rotate/scale *gestures* to their anim params is the natural next step.
