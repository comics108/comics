# Requirements: Flutter Puzzle Library

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-19

## Problem Statement

The current .puzzle file handling and puzzle piece rendering implementation exists only in platform-specific native code (Java for Android and Swift for iOS). Similar to the comics rendering challenge, this creates:

1. **Code Duplication**: Two separate puzzle implementations must be maintained
2. **Dependency on Comics**: Puzzle pieces contain .comics content, requiring both puzzle AND comics native code
3. **Complex State Management**: Puzzle state, piece downloads, and progress tracking are implemented twice
4. **No Flutter Support**: Cannot display puzzle interfaces in Flutter apps

The goal is to create a Flutter plugin library that handles .puzzle files, manages puzzle piece state, and renders pieces (leveraging the flutter_comics library for piece content rendering).

## User Stories

### Primary

**As a** Flutter application developer
**I want** to display interactive puzzles with downloadable pieces
**So that** users can explore puzzle content without implementing complex native code

**As a** puzzle content creator
**I want** consistent puzzle behavior across Android and iOS
**So that** my puzzle files work identically on all platforms

### Secondary

**As a** mobile app user
**I want** to see puzzle pieces laid out in a grid
**So that** I can browse and interact with puzzle content

**As a** developer
**I want** puzzle pieces to automatically render their .comics content
**So that** I don't have to manually coordinate comics rendering for each piece

## Acceptance Criteria

### Must Have

1. **Given** a valid .puzzle file (ZIP archive with puzzle metadata and pieces)
   **When** the Flutter widget loads the file
   **Then** it parses puzzle structure (id, name, dimensions, piece array)

2. **Given** a puzzle with multiple pieces
   **When** rendering the puzzle
   **Then** pieces are displayed in correct 2D grid layout based on x, y, width, height properties

3. **Given** a puzzle piece contains a .comics file reference
   **When** the piece is rendered
   **Then** the flutter_comics library renders the piece content

4. **Given** user scrolls horizontally across puzzle pieces
   **When** scroll position changes
   **Then** piece scroll position is calculated correctly: `finalScroll = width * (scroll / scrollArea)`

5. **Given** puzzle piece has download state tracking
   **When** piece is downloaded
   **Then** state is persisted (loadedVersion, savedFile, downloadInfo)

6. **Given** puzzle has preview layers
   **When** preview mode is toggled
   **Then** all piece preview layers show/hide simultaneously

7. **Given** existing Java implementation in `apps/mahabharata-mobile-java-v2012`
   **When** migrating code
   **Then** all puzzle models (Puzzle, Piece, Puzzles, PieceState) are faithfully ported to Dart

8. **Given** existing Swift implementation in `apps/mahabharata-mobile-swift-v2012`
   **When** comparing puzzle behavior
   **Then** Flutter implementation produces identical layout and interaction

### Should Have

1. **State persistence**: Save/load puzzle progress to JSON
2. **Download tracking**: Monitor download progress per piece
3. **Sound coordination**: Pause/resume/release sounds across all pieces
4. **Memory management**: Efficient loading/unloading of piece content
5. **Touch interaction**: Handle piece selection and navigation

### Won't Have (This Iteration)

1. **Puzzle editing**: This library is display-only; puzzle creation stays in backend/editor tools
2. **Download implementation**: Actual file downloading is handled by consuming app
3. **Backend integration**: No server communication; file loading only
4. **Analytics**: Event tracking is responsibility of consuming app
5. **UI controls**: No built-in navigation UI (consuming app provides)

## Constraints

- **Technical**:
  - Must work on both Android (API 21+) and iOS (13.0+)
  - Must depend on flutter_comics library for piece content rendering
  - Plugin structure: platform channels for native file I/O, Dart for puzzle logic
  - Package name: `net.nativemind.puzzle`

- **Performance**:
  - Puzzle loading must complete within 200ms
  - Piece layout calculations must complete within 50ms
  - Support puzzles with up to 100 pieces

- **Platform**:
  - Flutter SDK >= 3.3.0
  - Dart SDK >= 3.12.2
  - Dependency: flutter_comics library

- **Dependencies**:
  - Must handle ZIP archives (.puzzle file format)
  - Must parse JSON (puzzle metadata and state files)
  - Must integrate with flutter_comics for piece rendering

## File Format Specification

### .puzzle File Structure
```
archive.puzzle (ZIP format)
├── data.json           # Puzzle metadata
└── pieces/             # Piece data
    ├── piece1.json     # Piece metadata
    ├── piece1.comics   # Piece content (comics file)
    ├── piece2.json
    ├── piece2.comics
    └── ...
```

### data.json Schema (Puzzle)
```json
{
  "id": "mahabharata-s01",
  "name": "Mahabharata Season 1",
  "width": 1080,          // Grid cell width
  "height": 1920,         // Grid cell height
  "order": 0,             // Display order
  "pieces": [
    {
      "id": "piece-001",
      "x": 0,             // Grid X position
      "y": 0,             // Grid Y position
      "width": 1080,      // Piece width
      "height": 1920,     // Piece height
      "file": "piece1.comics",
      "version": 1,       // Content version
      "date": "2024-01-15",
      "order": 0          // Piece order in grid
    }
  ]
}
```

### Piece State JSON (persisted locally)
```json
{
  "pieceId": "piece-001",
  "loadedVersion": 1,
  "savedFile": "/path/to/piece1.comics",
  "currentScroll": 0,
  "showPreview": false,
  "downloadInfo": {
    "id": "download-123",
    "downloadedBytes": 1024000,
    "totalBytes": 2048000
  }
}
```

## Data Model Requirements

Must implement these classes from Java/Swift implementations:

### Core Models

1. **Puzzle** - Puzzle container
   - Properties: id, name, width, height, order, pieces[]
   - Methods: getPiece(id), contains(pieceId), delete(), toggleSounds(), pauseSounds(), resumeSounds(), releaseSounds()

2. **Piece** - Individual puzzle piece
   - Properties: id, x, y, width, height, file, version, date, order
   - State: comics (Comics instance), currentScroll, showPreview, downloadInfo
   - Methods: download(), completeDownload(), delete(), isDownloaded()

3. **Puzzles** - Collection manager (singleton)
   - Properties: puzzles[] (map of Puzzle instances)
   - Methods: update(), save(), load(), getPuzzle(id), getPiece(puzzleId, pieceId), queryDownloads()

4. **PieceState** - Download and playback state
   - Properties: loadedVersion, savedFile, currentScroll, showPreview, downloadInfo
   - Methods: serialize(), deserialize()

5. **DownloadInfo** - Download tracking
   - Properties: id, downloadedBytes, totalBytes
   - Methods: getProgress()

## Widget Requirements

### PieceView Widget
- Extends/wraps the flutter_comics LayersView
- Displays a single puzzle piece
- Manages preview mode toggle
- Calculates scroll position based on horizontal position
- Formula: `percent = scroll / scrollArea; finalScroll = width * percent`
- Handles piece-specific state (currentScroll, showPreview)

### PiecesViewController Widget (optional, may be in consuming app)
- Positions pieces in 2D grid layout
- Manages touch/drag interactions
- Coordinates zoom across all pieces
- Handles piece selection and navigation

## Puzzle-Specific Logic

### Scroll Mapping
Puzzles use horizontal scroll to control vertical comics scroll within pieces:
```dart
double calculatePieceScroll(double horizontalScroll, double scrollArea, double pieceWidth) {
  double percent = horizontalScroll / scrollArea;
  return pieceWidth * percent;
}
```

### State Persistence
- Save puzzle state to JSON on app pause/exit
- Load puzzle state on app resume/launch
- Track piece download progress
- Persist current scroll position per piece

### Sound Coordination
- `toggleSounds()`: Toggle sound on/off for all pieces
- `pauseSounds()`: Pause all piece sounds
- `resumeSounds()`: Resume all piece sounds
- `releaseSounds()`: Release all audio resources

### Download Management Integration
- Track download state per piece
- Update downloadInfo as download progresses
- Trigger piece load when download completes
- Handle download failures gracefully

## Relationship with flutter_comics

The puzzle library **depends on** the flutter_comics library:

```
┌─────────────────┐
│  Puzzle Widget  │
└────────┬────────┘
         │
         ├─ Loads .puzzle file
         ├─ Parses puzzle/piece metadata
         ├─ Manages piece layout
         │
         v
┌─────────────────┐
│   PieceView     │
└────────┬────────┘
         │
         ├─ Maps horizontal scroll to vertical
         ├─ Toggles preview mode
         │
         v
┌─────────────────┐
│ Comics Widget   │  (from flutter_comics library)
└─────────────────┘
         │
         └─ Renders .comics content
```

## Open Questions

- [ ] Should puzzle state be managed by the library or exposed to consuming app?
  - **To Decide**: Define state management boundaries

- [ ] How should we handle piece downloads - library responsibility or app responsibility?
  - **To Decide**: Clarify download integration pattern

- [ ] Should PiecesViewController be part of the library or consuming app?
  - **To Decide**: Define library scope for puzzle layout

- [ ] How do we handle puzzle updates when pieces are added/removed?
  - **To Decide**: Define update strategy and migration path

## References

- **Dependency**: flutter_comics library (`libs/flutter_comics/`)

- Legacy Java implementation: `apps/mahabharata-mobile-java-v2012/app/src/main/java/com/fulldome/mahabharata/`
  - Puzzle models: `model/puzzle/`
  - Puzzle screens: `screens/PuzzleActivity.java`, `screens/PiecesViewController.java`
  - Puzzle controls: `controls/PieceView.java`

- Legacy Swift implementation: `apps/mahabharata-mobile-swift-v2012/Mahabharata/`
  - Puzzle models: `Model/DataClasses/`
  - Puzzle views: `Views/Puzzle/`

- Flutter plugin structure: `libs/flutter_puzzle/`

- Comics Editor (reference only): `comics-editor-csharp-v2012/`

- Backend (reference only): `comics-backend-aspnet-v2012/`

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [any conditions or clarifications]
