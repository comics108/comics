# Requirements: Flutter Comics Library

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-19

## Problem Statement

The current .comics file rendering implementation exists only in platform-specific native code (Java for Android and Swift for iOS). This creates several problems:

1. **Code Duplication**: Two separate implementations (Java and Swift) must be maintained in parallel
2. **Inconsistency Risk**: Rendering behavior can diverge between platforms
3. **Maintenance Burden**: Bug fixes and features must be implemented twice
4. **No Flutter Support**: Cannot render .comics files in Flutter applications without platform channels

The goal is to create a unified Flutter plugin library that encapsulates all .comics rendering logic in a single, cross-platform implementation with native rendering performance.

## User Stories

### Primary

**As a** Flutter application developer
**I want** to render .comics files in my Flutter app
**So that** I can display animated, layered comics content without implementing platform-specific native code

**As a** mobile app maintainer
**I want** a single implementation of comics rendering logic
**So that** I can fix bugs and add features once instead of maintaining separate Java and Swift codebases

### Secondary

**As a** content creator
**I want** consistent rendering across Android and iOS
**So that** my .comics files look identical on all platforms

**As a** developer
**I want** to migrate existing Java/Swift rendering code to Flutter
**So that** I can preserve proven, production-tested rendering behavior

## Acceptance Criteria

### Must Have

1. **Given** a valid .comics file (ZIP archive with data.json and assets)
   **When** the Flutter widget is provided the file path
   **Then** it renders all layers with correct positioning, transformations, and animations

2. **Given** user scrolls through the comics
   **When** scroll position changes
   **Then** animations (translate, rotate, scale, alpha) are interpolated correctly using cubic easing

3. **Given** comics contains large images
   **When** rendering
   **Then** images are loaded as tiles (512x512) at appropriate zoom levels (1.0, 0.5, 0.25, 0.125)

4. **Given** comics contains sounds
   **When** scroll position enters sound animation range
   **Then** audio plays synchronized with scroll position

5. **Given** comics rendering is active
   **When** user zooms and pans
   **Then** view transformations work correctly with matrix calculations

6. **Given** existing Java implementation in `apps/mahabharata-mobile-java-v2012`
   **When** migrating code
   **Then** all data models (Comics, Layer, Image, Sound, Animation classes) are faithfully ported to Dart

7. **Given** existing Swift implementation in `apps/mahabharata-mobile-swift-v2012`
   **When** comparing rendering behavior
   **Then** Flutter implementation produces visually identical output

8. **Given** comics files from production apps
   **When** loading into Flutter widget
   **Then** all files render without errors (backward compatibility)

### Should Have

1. **Image caching**: Memory and disk caching for loaded tiles
2. **Loading states**: Placeholder display while images load
3. **Preview mode**: Toggle preview layers on/off
4. **Error handling**: Graceful handling of malformed .comics files
5. **Performance optimization**: Lazy loading/unloading of off-screen tiles

### Won't Have (This Iteration)

1. **Comics editing**: This library is render-only; editing functionality stays in `comics-editor-csharp-v2012`
2. **Backend integration**: No server communication; file loading only
3. **Download management**: File acquisition is handled by consuming app
4. **Analytics**: Event tracking is responsibility of consuming app
5. **UI controls**: No built-in zoom/pan controls (consuming app provides)

## Constraints

- **Technical**:
  - Must work on both Android (API 21+) and iOS (13.0+)
  - Must preserve exact rendering behavior from Java/Swift implementations
  - Plugin structure: platform channels for native file I/O, Dart for rendering logic
  - Package name: `net.nativemind.comics`

- **Performance**:
  - Tile loading must complete within 100ms for visible tiles
  - Animation frame rate must maintain 60fps during scroll
  - Memory usage must not exceed 200MB for typical comics files

- **Platform**:
  - Flutter SDK >= 3.3.0
  - Dart SDK >= 3.12.2
  - Support for Flutter's method channel pattern

- **Dependencies**:
  - Must handle ZIP archives (.comics file format)
  - Must parse JSON (data.json schema)
  - Must support PNG image tiles
  - Must support MP3/OGG audio files

## File Format Specification

### .comics File Structure
```
archive.comics (ZIP format)
├── data.json           # Comics metadata and animations
├── layers/             # Layer images and tiles
│   ├── layer1.png      # Full image (optional)
│   ├── layer1_1000_0_0.png  # Tiles: {zoom}_{col}_{row}
│   ├── layer1_1000_0_1.png
│   └── ...
└── sounds/             # Audio files
    ├── ambient.mp3
    └── effect.ogg
```

### data.json Schema
```json
{
  "width": 1080,           // Comics viewport width
  "height": 15000,         // Total scrollable height
  "layers": [
    {
      "preview": false,    // Is this a preview-only layer?
      "images": [{
        "file": "layer1.png",
        "width": 1080,
        "height": 1920,
        "popup": "popup.png"  // Optional popup image
      }],
      "animations": [
        {
          "type": "translate",
          "start": 0,        // Scroll position start
          "end": 1000,       // Scroll position end
          "x": 0,            // X offset
          "y": 100           // Y offset
        },
        {
          "type": "rotate",
          "start": 500,
          "end": 1500,
          "angle": 45,       // Degrees
          "pivotX": 0.5,     // Pivot point (0-1)
          "pivotY": 0.5
        },
        {
          "type": "scale",
          "start": 1000,
          "end": 2000,
          "scaleX": 1.5,
          "scaleY": 1.5,
          "pivotX": 0.5,
          "pivotY": 0.5
        },
        {
          "type": "alpha",
          "start": 1500,
          "end": 2500,
          "alpha": 0.5       // Transparency (0-1)
        }
      ]
    }
  ],
  "sounds": [
    {
      "file": "ambient.mp3",
      "animations": [
        {
          "type": "sound",
          "start": 0,        // Scroll position to trigger
          "end": 5000        // Scroll position to end
        }
      ]
    }
  ]
}
```

## Data Model Requirements

Must implement these classes from Java/Swift implementations:

### Core Models
1. **Comics** - Main container
   - Properties: width, height, layers[], sounds[]
   - Methods: prepare(), process(scrollOffset), hasPreview(), cancelLayerTasks()

2. **Layer** - Visual layer with animations
   - Properties: preview, images[], animations[], matrix, alpha, inverse
   - Methods: prepare(), buildMatrixAndAlpha(scroll), buildInverse(), getImage()

3. **Image** - Image resource descriptor
   - Properties: file, width, height, popup
   - Methods: isEmpty(), hasPopup()

4. **Sound** - Audio playback controller
   - Properties: file, animations[], volume, looping
   - Methods: prepare(), process(scroll), play(), pause(), stop(), release()

### Animation Models
5. **Anim** (base class) - start, end, type
6. **TranslateAnim** - x, y translation
7. **RotateAnim** - angle, pivotX, pivotY rotation
8. **ScaleAnim** - scaleX, scaleY, pivotX, pivotY scaling
9. **AlphaAnim** - alpha transparency
10. **SoundAnim** - sound trigger points
11. **LayerAnim** - unused/reserved

### File Handling
12. **ComicsDescriptor** - ZIP file handler
    - Methods: getData(), getSound(), getImage()

## Rendering Requirements

### LayersView Widget
- Display multiple layers in correct Z-order
- Apply matrix transformations (translate, rotate, scale)
- Apply alpha blending
- Handle scroll-based animation updates
- Support zoom and pan gestures
- Implement hit testing with alpha transparency

### TileImageView Widget
- Load images as 512x512 tiles
- Support multiple zoom levels: 1.0 (full), 0.5, 0.25, 0.125
- Lazy load visible tiles only
- Unload off-screen tiles to conserve memory
- Show placeholders while loading
- Handle tile naming: `{imageName}_{zoom}_{col}_{row}.png`

### Animation Pipeline
1. Parse animations from JSON and sort by start position
2. For current scroll position, find active animations
3. Calculate interpolation factor: `t = (scroll - start) / (end - start)`
4. Apply cubic easing: `t = t * t * (3.0 - 2.0 * t)`
5. Interpolate values and build transformation matrix
6. Apply matrix to layer rendering

## Open Questions

- [x] Should we use platform channels for ZIP extraction or pure Dart libraries?
  - **Decision**: Use Dart `archive` package for ZIP handling to minimize platform channel overhead

- [x] How should we handle different image formats (PNG, JPEG)?
  - **Decision**: Support PNG only initially (matches current implementation)

- [ ] What's the strategy for sound playback - platform channels or Flutter audio plugins?
  - **To Decide**: Evaluate audioplayers vs just_audio vs platform channels

- [ ] Should tile caching use Flutter's image cache or custom implementation?
  - **To Decide**: Test performance of both approaches

- [ ] How do we handle memory pressure on low-end devices?
  - **To Decide**: Define tile eviction strategy and memory limits

## References

- Legacy Java implementation: `apps/mahabharata-mobile-java-v2012/app/src/main/java/com/fulldome/mahabharata/`
  - Core models: `model/visual/`
  - Controls: `controls/LayersView.java`, `controls/TileImageView.java`
  - Utils: `utils/ImageManager.java`

- Legacy Swift implementation: `apps/mahabharata-mobile-swift-v2012/Mahabharata/`
  - Models: `Model/DataClasses/Visual/`
  - Views: `Views/Tiles/TileImageView.swift`

- Comics Editor (reference only, not migrating): `comics-editor-csharp-v2012/`

- Backend (reference only): `comics-backend-aspnet-v2012/`

- Flutter plugin structure: `libs/flutter_comics/`

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [any conditions or clarifications]
