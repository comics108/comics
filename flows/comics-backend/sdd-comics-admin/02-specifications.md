# Specifications: Comics Admin Panel

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-19

## Overview

Transform existing `comics_admin` (bhagavadgita admin clone) into Comics Admin panel by:
1. Replacing data models (Books→Seasons, Chapters→Episodes, etc.)
2. Updating API client for Comics endpoints
3. Adapting UI to VPN Client Pro design system
4. Adding new screens (Puzzles, Pieces, Music, Notifications)

## Architecture Mapping

### Entity Mapping: Bhagavadgita → Comics

| Bhagavadgita | Comics | Notes |
|--------------|--------|-------|
| Language | - | Remove (use LocalizedText instead) |
| Book | Season | Similar hierarchy |
| Chapter | Episode | Child of Season |
| Sloka | - | Remove |
| Quote | Quote | Keep, add scheduled publishing |
| Device | Device | Keep as-is |
| - | Puzzle | New entity |
| - | Piece | New entity, child of Puzzle |
| - | Music | New entity |
| Import (XML) | - | Remove |

### Route Mapping

| Current Route | New Route | Screen |
|--------------|-----------|--------|
| /books | /episodes | EpisodesScreen (default) |
| /chapters | /seasons | SeasonsScreen |
| /slokas | /puzzles | PuzzlesScreen |
| /slokas/:id | /puzzles/:id | PuzzleFormScreen |
| - | /pieces | PiecesScreen |
| /quotes | /quotes | QuotesScreen |
| /languages | /music | MusicScreen |
| /import | /notifications | NotificationsScreen |
| /devices | /devices | DevicesScreen |

## Design System Changes

### Current (Bhagavadgita)
```
Primary: #FF5252 (red)
Background: #F0F0F2
Sidebar: #F9F9F9
```

### New (VPN Client Pro from mockup)
```
Background: #F8F9FA
Surface: #FFFFFF (white cards, radius 10px, soft shadow)
Primary gradient: #00C6FB → #005BEA (for active nav, primary buttons)
Primary solid: #00C6FB
Text primary: #303F49
Text secondary: #5C6771
Border: rgba(156, 178, 194, 0.1) (hairline)
Font: Inter
```

## Data Models

### LocalizedText (shared)
```dart
class LocalizedText {
  final String? en;
  final String? ru;
  final String? hi;

  const LocalizedText({this.en, this.ru, this.hi});

  factory LocalizedText.fromJson(Map<String, dynamic>? json);
  Map<String, dynamic> toJson();
  String get(String culture); // Returns text for culture
}
```

### Season (replaces Book)
```dart
class Season {
  final int id;
  final LocalizedText name;
  final String? image;
  final String? product;
  final int order;
  final int episodesCount;
}

class SeasonInput {
  final LocalizedText name;
  final String? image;
  final String? product;
  final int? order;
}
```

### Episode (replaces Chapter)
```dart
class Episode {
  final int id;
  final int seasonId;
  final LocalizedText name;
  final String? image;
  final String? file;  // .cbz file
  final int version;
  final String? product;
  final DateTime date;
  final int order;
}

class EpisodeInput {
  final int seasonId;
  final LocalizedText name;
  final String? image;
  final String? file;
  final int? version;
  final String? product;
  final DateTime? date;
  final int? order;
}
```

### Puzzle (new)
```dart
class Puzzle {
  final int id;
  final LocalizedText name;
  final int width;
  final int height;
  final int order;
  final int piecesCount;
}

class PuzzleInput {
  final LocalizedText name;
  final int width;
  final int height;
  final int? order;
}
```

### Piece (new)
```dart
class Piece {
  final int id;
  final int puzzleId;
  final int x;
  final int y;
  final int width;
  final int height;
  final String? file;
  final int version;
  final DateTime date;
  final int order;
}

class PieceInput {
  final int puzzleId;
  final int x;
  final int y;
  final int width;
  final int height;
  final String? file;
  final int? version;
  final DateTime? date;
  final int? order;
}
```

### Quote (modified)
```dart
class Quote {
  final int id;
  final LocalizedText text;
  final LocalizedText image;  // image URLs per language
  final DateTime? publishDate;
  final QuoteStatus status;  // published, scheduled
}

enum QuoteStatus { published, scheduled }

class QuoteInput {
  final LocalizedText text;
  final LocalizedText image;
  final DateTime? publishDate;
}
```

### Music (new)
```dart
class Music {
  final int id;
  final LocalizedText name;
  final LocalizedText author;
  final String? file;
  final int order;
}

class MusicInput {
  final LocalizedText name;
  final LocalizedText author;
  final String? file;
  final int? order;
}
```

### NotificationInput (new)
```dart
class NotificationInput {
  final LocalizedText title;
  final LocalizedText body;
  final String platform; // all, ios, android
}

class NotificationResult {
  final int sent;
  final int failed;
}
```

## File Changes

### DELETE (bhagavadgita-specific)
```
lib/data/models/language_model.dart
lib/data/models/book_model.dart
lib/data/models/chapter_model.dart
lib/data/models/sloka_model.dart
lib/presentation/screens/languages_screen.dart
lib/presentation/screens/books_screen.dart
lib/presentation/screens/chapters_screen.dart
lib/presentation/screens/slokas_screen.dart
lib/presentation/screens/sloka_form_screen.dart
lib/presentation/screens/import_screen.dart
```

### CREATE (comics-specific)
```
lib/data/models/localized_text.dart
lib/data/models/season_model.dart
lib/data/models/episode_model.dart
lib/data/models/puzzle_model.dart
lib/data/models/piece_model.dart
lib/data/models/music_model.dart
lib/data/models/notification_model.dart
lib/presentation/screens/episodes_screen.dart
lib/presentation/screens/episode_form_screen.dart
lib/presentation/screens/seasons_screen.dart
lib/presentation/screens/season_form_screen.dart
lib/presentation/screens/puzzles_screen.dart
lib/presentation/screens/puzzle_form_screen.dart
lib/presentation/screens/pieces_screen.dart
lib/presentation/screens/piece_form_screen.dart
lib/presentation/screens/music_screen.dart
lib/presentation/screens/music_form_screen.dart
lib/presentation/screens/notifications_screen.dart
```

### MODIFY
```
lib/core/constants/colors.dart          # VPN Client Pro colors
lib/core/l10n/app_localizations.dart    # Comics-specific strings
lib/core/l10n/app_localizations_en.dart
lib/core/l10n/app_localizations_ru.dart
lib/data/api/admin_api_client.dart      # Comics API methods
lib/data/mock/mock_data.dart            # Comics mock data
lib/data/models/quote_model.dart        # Add LocalizedText, publishDate
lib/presentation/router/app_router.dart  # Comics routes
lib/presentation/widgets/sidebar.dart    # Comics menu items
lib/presentation/widgets/main_layout.dart # VPN Client Pro header
lib/presentation/providers/data_providers.dart # Comics providers
lib/presentation/screens/quotes_screen.dart # Scheduled publishing UI
lib/presentation/screens/devices_screen.dart # Keep mostly as-is
```

## API Client Specification

### AdminApiClient Methods

```dart
class AdminApiClient {
  // Auth (keep)
  Future<ApiResponse<Map<String, dynamic>>> login(String email, String password);

  // Seasons (new)
  Future<List<Season>> getSeasons();
  Future<Season> getSeason(int id);
  Future<Season> createSeason(SeasonInput input);
  Future<Season> updateSeason(int id, SeasonInput input);
  Future<void> deleteSeason(int id);
  Future<void> reorderSeasons(List<int> order);

  // Episodes (new)
  Future<PaginatedResponse<Episode>> getEpisodes({int? seasonId, int page, int limit});
  Future<Episode> getEpisode(int id);
  Future<Episode> createEpisode(EpisodeInput input);
  Future<Episode> updateEpisode(int id, EpisodeInput input);
  Future<void> deleteEpisode(int id);
  Future<void> reorderEpisodes(int seasonId, List<int> order);

  // Puzzles (new)
  Future<List<Puzzle>> getPuzzles();
  Future<Puzzle> getPuzzle(int id);
  Future<Puzzle> createPuzzle(PuzzleInput input);
  Future<Puzzle> updatePuzzle(int id, PuzzleInput input);
  Future<void> deletePuzzle(int id);
  Future<void> reorderPuzzles(List<int> order);

  // Pieces (new)
  Future<List<Piece>> getPieces(int puzzleId);
  Future<Piece> getPiece(int id);
  Future<Piece> createPiece(PieceInput input);
  Future<Piece> updatePiece(int id, PieceInput input);
  Future<void> deletePiece(int id);
  Future<void> reorderPieces(int puzzleId, List<int> order);

  // Quotes (modified)
  Future<PaginatedResponse<Quote>> getQuotes({QuoteStatus? status, int page, int limit});
  Future<Quote> getQuote(int id);
  Future<Quote> createQuote(QuoteInput input);
  Future<Quote> updateQuote(int id, QuoteInput input);
  Future<void> deleteQuote(int id);
  Future<void> publishQuote(int id);

  // Music (new)
  Future<List<Music>> getMusic();
  Future<Music> getMusicTrack(int id);
  Future<Music> createMusic(MusicInput input);
  Future<Music> updateMusic(int id, MusicInput input);
  Future<void> deleteMusic(int id);
  Future<void> reorderMusic(List<int> order);

  // Notifications (new)
  Future<NotificationResult> sendNotification(NotificationInput input);

  // Devices (keep)
  Future<PaginatedResponse<Device>> getDevices({...});
  Future<DeviceStats> getDeviceStats();

  // Files (keep)
  Future<String> uploadFile(PlatformFile file, {String folder});
}
```

## Screen Specifications

### N2 - Episodes Screen (default landing page)
- Season dropdown filter (default: first season)
- Drag-sortable table with columns: Image, Name, Date, Version, Actions
- Add Episode button (primary gradient)
- Click row → Episode form

### N3 - Episode Form Screen
- Localized name fields (tabs: EN / RU / HI)
- Image upload with preview
- Episode file (.cbz) upload
- Date picker
- Version number input
- Product ID input
- Save button (primary gradient), Cancel button

### N5 - Seasons Screen
- Drag-sortable list: Image, Name, Product, Episodes count, Actions
- Add Season button

### N6 - Season Form
- Localized name fields
- Image upload
- Product ID input

### N7 - Puzzles Screen
- Drag-sortable list: Name, Grid size (W×H), Pieces count, Actions
- Add Puzzle button

### N8 - Puzzle Form
- Localized name fields
- Width, Height inputs
- Order input

### N9 - Pieces Screen
- Puzzle dropdown filter
- Visual grid preview (shows piece positions)
- List below: Position (x,y), Size (w×h), Status, Actions
- Add Piece button

### N10 - Piece Form
- Position (x, y) inputs
- Size (width, height) inputs
- Image upload
- Version, Date inputs

### N11 - Quotes Screen
- Status filter tabs: All / Scheduled / Published
- List: Text preview, Status badge, Publish date, Actions
- Add Quote button

### N12 - Quote Form
- Localized text (tabs)
- Localized images (tabs with upload per language)
- Publish date picker (optional, for scheduling)

### N13 - Music Screen
- Drag-sortable list: Name, Author, File status, Actions
- Add Music button

### N14 - Music Form
- Localized name fields
- Localized author fields
- Audio file upload

### N4 - Notifications Screen
- Localized title fields
- Localized body fields
- Platform selector: All / iOS / Android
- Send button
- Recent notifications log (optional)

## Sidebar Menu Structure

```dart
// New menu items (in order)
_MenuItem(label: l10n.menuEpisodes, path: '/episodes'),
_MenuItem(label: l10n.menuSeasons, path: '/seasons'),
_MenuItem(label: l10n.menuPuzzles, path: '/puzzles'),
_MenuItem(label: l10n.menuPieces, path: '/pieces'),
_MenuItem(label: l10n.menuQuotes, path: '/quotes'),
_MenuItem(label: l10n.menuMusic, path: '/music'),
_MenuItem(label: l10n.menuNotifications, path: '/notifications'),
_MenuItem(label: l10n.menuDevices, path: '/devices'),
```

## Localization Keys (new)

```dart
// Menu
String get menuEpisodes;
String get menuSeasons;
String get menuPuzzles;
String get menuPieces;
String get menuMusic;
String get menuNotifications;

// Seasons
String get seasonName;
String get seasonImage;
String get seasonProduct;
String get addSeason;
String get editSeason;
String get deleteSeasonConfirm;

// Episodes
String get episodeName;
String get episodeImage;
String get episodeFile;
String get episodeDate;
String get episodeVersion;
String get episodeProduct;
String get addEpisode;
String get editEpisode;
String get deleteEpisodeConfirm;
String get selectSeason;

// Puzzles
String get puzzleName;
String get puzzleWidth;
String get puzzleHeight;
String get puzzleGridSize;
String get addPuzzle;
String get editPuzzle;
String get deletePuzzleConfirm;

// Pieces
String get piecePosX;
String get piecePosY;
String get pieceWidth;
String get pieceHeight;
String get pieceFile;
String get pieceVersion;
String get addPiece;
String get editPiece;
String get deletePieceConfirm;
String get selectPuzzle;

// Music
String get musicName;
String get musicAuthor;
String get musicFile;
String get addMusic;
String get editMusic;
String get deleteMusicConfirm;

// Notifications
String get notificationTitle;
String get notificationBody;
String get notificationPlatform;
String get notificationPlatformAll;
String get notificationPlatformIos;
String get notificationPlatformAndroid;
String get sendNotification;
String get notificationSent;

// Quotes (new)
String get quoteImage;
String get quotePublishDate;
String get quoteStatusPublished;
String get quoteStatusScheduled;
String get publishNow;

// Localization tabs
String get langEn;
String get langRu;
String get langHi;
```

## Mock Data Structure

```dart
class MockData {
  static final seasons = [...];      // 3-4 seasons
  static final episodes = [...];     // 5-6 episodes per season
  static final puzzles = [...];      // 2-3 puzzles
  static final pieces = [...];       // Grid pieces for each puzzle
  static final quotes = [...];       // Mix of published/scheduled
  static final music = [...];        // 3-4 tracks
  static final devices = [...];      // Keep existing
}
```

## Edge Cases

1. **Empty Season**: Show "No episodes" message, allow adding
2. **Empty Puzzle**: Show empty grid, allow adding pieces
3. **Scheduled Quote**: Show "Scheduled for DATE" badge, allow publishing now
4. **File Upload Error**: Show error toast, keep form state
5. **Drag Reorder Failure**: Revert to original order, show error
6. **Delete with Children**: Confirm cascade deletion (Season→Episodes, Puzzle→Pieces)

## Dependencies

- `dio` - HTTP client
- `flutter_riverpod` - State management
- `go_router` - Navigation
- `file_picker` - File selection
- `desktop_drop` - Drag & drop uploads
- `intl` - Date formatting

## Testing Strategy

1. **Unit Tests**: Model serialization, LocalizedText
2. **Widget Tests**: Form validation, drag-drop
3. **Integration Tests**: CRUD flows in mock mode

---

## Approval

- [ ] Reviewed by:
- [ ] Approved on:
- [ ] Notes:
