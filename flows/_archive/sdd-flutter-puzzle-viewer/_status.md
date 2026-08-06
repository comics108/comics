# Status: sdd-flutter-puzzle

## Current Phase

REQUIREMENTS | SPECIFICATIONS | **PLAN** | IMPLEMENTATION

## Phase Status

DRAFTING | REVIEW | **APPROVED** | BLOCKED

## Last Updated

2026-07-19 by Claude Sonnet 4.5

## Blockers

- Depends on flutter_comics library completion

## Progress

- [x] Requirements drafted
- [x] Requirements approved
- [x] Specifications drafted
- [x] Specifications approved
- [x] Plan drafted
- [x] Plan approved
- [ ] Implementation started
- [ ] Implementation complete

## Context Notes

Key decisions and context for resuming:

### Migration Scope
- Migrating native Java (Android) and Swift (iOS) puzzle handling code to Flutter
- Source: `apps/mahabharata-mobile-java-v2012` and `apps/mahabharata-mobile-swift-v2012`
- Target: `libs/flutter_puzzle/` (currently only boilerplate exists)
- Goal: Unified cross-platform puzzle piece management and rendering

### Dependency
- **Critical**: flutter_puzzle depends on flutter_comics library
- Puzzle pieces contain .comics content rendered via flutter_comics
- Must coordinate with sdd-flutter-comics development

### File Format
- .puzzle files are ZIP archives containing:
  - `data.json` - puzzle metadata (id, name, dimensions, pieces array)
  - `pieces/` - individual piece data (JSON + .comics files)
- Each piece has: position (x, y), dimensions, .comics file reference, version, order
- State persistence: download tracking, scroll position, preview mode per piece

### Puzzle-Specific Logic
- **Scroll mapping**: horizontal scroll → vertical comics scroll
  - Formula: `finalScroll = width * (scroll / scrollArea)`
- **Preview mode**: toggle preview layers across all pieces simultaneously
- **Sound coordination**: pause/resume/release sounds for all pieces
- **Download tracking**: monitor download state per piece with persistence

### Data Models to Implement
- Puzzle - container for pieces array
- Piece - individual puzzle piece with state
- Puzzles - singleton collection manager
- PieceState - download and playback state
- DownloadInfo - download progress tracking

### Widgets to Implement
- PieceView - wraps flutter_comics LayersView with puzzle-specific logic
- PiecesViewController (TBD) - may be in consuming app vs library

### Architecture Decisions
- State management boundaries TBD (library vs consuming app)
- Download implementation TBD (library responsibility vs app responsibility)
- PiecesViewController scope TBD (library vs consuming app)

### Current Status
- Only Flutter plugin boilerplate exists
- No actual implementation has been started
- Requirements document completed and ready for review
- Estimated ~500+ lines of Dart code needed (plus flutter_comics dependency)

## Fork History

N/A - Original spec

## Next Actions

1. **WAIT** for flutter_comics implementation to complete (dependency)
2. Once flutter_comics is done, begin IMPLEMENTATION phase
3. Follow 45-task plan in 03-plan.md
4. Start with Phase 1: Setup & Cleanup (7 tasks)
