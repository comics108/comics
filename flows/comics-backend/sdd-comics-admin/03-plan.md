# Implementation Plan: Comics Admin Panel

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-19

## Overview

Transform `comics_admin` from bhagavadgita admin to Comics admin in 6 phases:
1. Foundation (colors, config, LocalizedText)
2. Data Models (Season, Episode, Puzzle, Piece, Music, Quote)
3. API Client & Providers
4. Screens - Core (Episodes, Seasons)
5. Screens - Extended (Puzzles, Pieces, Music, Quotes, Notifications)
6. Cleanup & Polish

## Phase 1: Foundation

### Task 1.1: Update Design Colors
**File**: `lib/core/constants/colors.dart`
**Action**: MODIFY
**Changes**:
```dart
// Replace all colors with VPN Client Pro palette
primary: Color(0xFF00C6FB)
primaryDark: Color(0xFF005BEA)
background: Color(0xFFF8F9FA)
surface: Color(0xFFFFFFFF)
textPrimary: Color(0xFF303F49)
textSecondary: Color(0xFF5C6771)
border: Color(0x1A9CB2C2)  // rgba(156,178,194,0.1)
// Add gradient colors
gradientStart: Color(0xFF00C6FB)
gradientEnd: Color(0xFF005BEA)
```
**Test**: Visual inspection in mock mode

### Task 1.2: Create LocalizedText Model
**File**: `lib/data/models/localized_text.dart`
**Action**: CREATE
**Content**:
- `LocalizedText` class with en/ru/hi fields
- `fromJson`, `toJson` methods
- `get(String culture)` helper
- `isEmpty` getter
**Test**: Unit test for serialization

### Task 1.3: Update App Config
**File**: `lib/core/config/app_config.dart`
**Action**: VERIFY (already correct)
- Confirm `getEnvironmentFromCredentials` handles dev/local/maket
**Test**: Login with each credential type

### Task 1.4: Update Env Config
**File**: `lib/core/config/env_config.dart`
**Action**: MODIFY
**Changes**:
```dart
// Update URLs for Comics backend
static const prodUrl = 'https://app.mbharata.com/api/v2026/admin';
static const devUrl = 'https://dev.mbharata.com/api/v2026/admin';
static const localUrl = 'http://localhost:3000/api/v2026/admin';
```

## Phase 2: Data Models

### Task 2.1: Create Season Model
**File**: `lib/data/models/season_model.dart`
**Action**: CREATE
**Content**: `Season`, `SeasonInput` classes per spec
**Depends on**: Task 1.2 (LocalizedText)

### Task 2.2: Create Episode Model
**File**: `lib/data/models/episode_model.dart`
**Action**: CREATE
**Content**: `Episode`, `EpisodeInput` classes per spec
**Depends on**: Task 1.2

### Task 2.3: Create Puzzle Model
**File**: `lib/data/models/puzzle_model.dart`
**Action**: CREATE
**Content**: `Puzzle`, `PuzzleInput` classes per spec
**Depends on**: Task 1.2

### Task 2.4: Create Piece Model
**File**: `lib/data/models/piece_model.dart`
**Action**: CREATE
**Content**: `Piece`, `PieceInput` classes per spec

### Task 2.5: Create Music Model
**File**: `lib/data/models/music_model.dart`
**Action**: CREATE
**Content**: `Music`, `MusicInput` classes per spec
**Depends on**: Task 1.2

### Task 2.6: Update Quote Model
**File**: `lib/data/models/quote_model.dart`
**Action**: MODIFY
**Changes**:
- Replace `languageId`, `author`, `text`, `isDay` with:
- `LocalizedText text`, `LocalizedText image`, `DateTime? publishDate`, `QuoteStatus status`
**Depends on**: Task 1.2

### Task 2.7: Create Notification Model
**File**: `lib/data/models/notification_model.dart`
**Action**: CREATE
**Content**: `NotificationInput`, `NotificationResult` classes
**Depends on**: Task 1.2

### Task 2.8: Delete Old Models
**Files**:
- `lib/data/models/language_model.dart` - DELETE
- `lib/data/models/book_model.dart` - DELETE
- `lib/data/models/chapter_model.dart` - DELETE
- `lib/data/models/sloka_model.dart` - DELETE
**Action**: DELETE

## Phase 3: API Client & Providers

### Task 3.1: Rewrite API Client
**File**: `lib/data/api/admin_api_client.dart`
**Action**: MODIFY (full rewrite)
**Changes**:
- Remove: Languages, Books, Chapters, Slokas, Import methods
- Add: Seasons, Episodes, Puzzles, Pieces, Music, Notifications methods
- Update: Quotes methods (status filter, publish endpoint)
- Keep: Auth, Devices, Files methods
**Depends on**: Phase 2 (all models)

### Task 3.2: Update Data Providers
**File**: `lib/presentation/providers/data_providers.dart`
**Action**: MODIFY
**Changes**:
- Remove: languagesProvider, booksProvider, chaptersProvider, slokasProvider
- Add: seasonsProvider, episodesProvider, puzzlesProvider, piecesProvider, musicProvider
- Update: quotesProvider (with status filter)
**Depends on**: Task 3.1

### Task 3.3: Update Mock Data
**File**: `lib/data/mock/mock_data.dart`
**Action**: MODIFY (full rewrite)
**Changes**:
- Remove: languages, books, chapters, slokas
- Add: seasons, episodes, puzzles, pieces, music
- Update: quotes (with LocalizedText, publishDate)
**Depends on**: Phase 2

## Phase 4: Screens - Core

### Task 4.1: Update Localization - Menu & Common
**Files**:
- `lib/core/l10n/app_localizations.dart`
- `lib/core/l10n/app_localizations_en.dart`
- `lib/core/l10n/app_localizations_ru.dart`
**Action**: MODIFY
**Changes**:
- Remove: Books, Chapters, Slokas, Languages, Import keys
- Add: Episodes, Seasons, Puzzles, Pieces, Music, Notifications keys
- Add: Language tabs (langEn, langRu, langHi)

### Task 4.2: Update Router
**File**: `lib/presentation/router/app_router.dart`
**Action**: MODIFY
**Changes**:
- Initial location: `/episodes`
- Remove: /books, /chapters, /slokas, /languages, /import routes
- Add: /episodes, /seasons, /puzzles, /pieces, /music, /notifications routes
**Depends on**: Screens exist

### Task 4.3: Update Sidebar
**File**: `lib/presentation/widgets/sidebar.dart`
**Action**: MODIFY
**Changes**: Update menu items per spec
**Depends on**: Task 4.1 (localization)

### Task 4.4: Update Main Layout
**File**: `lib/presentation/widgets/main_layout.dart`
**Action**: MODIFY
**Changes**:
- Update header color to primary gradient
- Update app title
- Remove window buttons (optional, web doesn't need them)
**Depends on**: Task 1.1 (colors)

### Task 4.5: Create Episodes Screen
**File**: `lib/presentation/screens/episodes_screen.dart`
**Action**: CREATE
**Content**:
- Season dropdown filter
- Drag-sortable table
- Add Episode button
**Depends on**: Task 3.2 (providers), Task 4.1 (l10n)

### Task 4.6: Create Episode Form Screen
**File**: `lib/presentation/screens/episode_form_screen.dart`
**Action**: CREATE
**Content**:
- Localized name tabs
- Image/file uploads
- Date, version, product fields
**Depends on**: Task 4.5

### Task 4.7: Create Seasons Screen
**File**: `lib/presentation/screens/seasons_screen.dart`
**Action**: CREATE
**Content**:
- Drag-sortable list
- Add Season button
**Depends on**: Task 3.2

### Task 4.8: Create Season Form Screen
**File**: `lib/presentation/screens/season_form_screen.dart`
**Action**: CREATE
**Depends on**: Task 4.7

### Task 4.9: Delete Old Core Screens
**Files**:
- `lib/presentation/screens/books_screen.dart` - DELETE
- `lib/presentation/screens/chapters_screen.dart` - DELETE
- `lib/presentation/screens/slokas_screen.dart` - DELETE
- `lib/presentation/screens/sloka_form_screen.dart` - DELETE
- `lib/presentation/screens/languages_screen.dart` - DELETE
- `lib/presentation/screens/import_screen.dart` - DELETE
**Action**: DELETE
**Depends on**: Tasks 4.5-4.8 (new screens created)

## Phase 5: Screens - Extended

### Task 5.1: Create Puzzles Screen
**File**: `lib/presentation/screens/puzzles_screen.dart`
**Action**: CREATE

### Task 5.2: Create Puzzle Form Screen
**File**: `lib/presentation/screens/puzzle_form_screen.dart`
**Action**: CREATE

### Task 5.3: Create Pieces Screen
**File**: `lib/presentation/screens/pieces_screen.dart`
**Action**: CREATE
**Content**:
- Puzzle dropdown filter
- Visual grid preview
- Pieces list

### Task 5.4: Create Piece Form Screen
**File**: `lib/presentation/screens/piece_form_screen.dart`
**Action**: CREATE

### Task 5.5: Create Music Screen
**File**: `lib/presentation/screens/music_screen.dart`
**Action**: CREATE

### Task 5.6: Create Music Form Screen
**File**: `lib/presentation/screens/music_form_screen.dart`
**Action**: CREATE

### Task 5.7: Update Quotes Screen
**File**: `lib/presentation/screens/quotes_screen.dart`
**Action**: MODIFY
**Changes**:
- Add status filter tabs (All/Scheduled/Published)
- Update table columns
- Add Publish Now action

### Task 5.8: Create Quote Form Screen
**File**: `lib/presentation/screens/quote_form_screen.dart`
**Action**: CREATE
**Content**:
- Localized text tabs
- Localized image uploads
- Publish date picker

### Task 5.9: Create Notifications Screen
**File**: `lib/presentation/screens/notifications_screen.dart`
**Action**: CREATE
**Content**:
- Localized title/body tabs
- Platform selector
- Send button

### Task 5.10: Update Devices Screen
**File**: `lib/presentation/screens/devices_screen.dart`
**Action**: MODIFY (minor)
- Remove quote-of-day push button (moved to Notifications)
- Keep device stats and list

## Phase 6: Cleanup & Polish

### Task 6.1: Create Localized Text Input Widget
**File**: `lib/presentation/widgets/localized_text_input.dart`
**Action**: CREATE
**Content**: Reusable widget with EN/RU/HI tabs

### Task 6.2: Update Admin Form Dialog
**File**: `lib/presentation/widgets/admin_form_dialog.dart`
**Action**: MODIFY
- Support for localized text inputs
- Update styling to VPN Client Pro

### Task 6.3: Add Primary Gradient Button
**File**: `lib/presentation/widgets/admin_button.dart`
**Action**: MODIFY
- Add gradient variant for primary actions

### Task 6.4: Final Router Configuration
**File**: `lib/presentation/router/app_router.dart`
**Action**: MODIFY
- Ensure all routes work
- Add redirect from `/` to `/episodes`

### Task 6.5: Build & Verify
**Action**: RUN `flutter build web`
- Fix any compilation errors
- Test mock mode login

### Task 6.6: Update Package Name (Optional)
**File**: `pubspec.yaml`
**Action**: VERIFY
- Ensure name is `comics_admin` (not `bhagavadgita_admin`)

## Dependency Graph

```
Phase 1 (Foundation)
├── 1.1 Colors
├── 1.2 LocalizedText ─────────────────┐
├── 1.3 App Config                     │
└── 1.4 Env Config                     │
                                       │
Phase 2 (Models) ◄─────────────────────┘
├── 2.1 Season ◄── 1.2
├── 2.2 Episode ◄── 1.2
├── 2.3 Puzzle ◄── 1.2
├── 2.4 Piece
├── 2.5 Music ◄── 1.2
├── 2.6 Quote ◄── 1.2
├── 2.7 Notification ◄── 1.2
└── 2.8 Delete Old Models
                    │
Phase 3 (API) ◄─────┘
├── 3.1 API Client ◄── Phase 2
├── 3.2 Providers ◄── 3.1
└── 3.3 Mock Data ◄── Phase 2
                    │
Phase 4 (Core Screens) ◄────┘
├── 4.1 Localization
├── 4.2 Router ◄── 4.5-4.8
├── 4.3 Sidebar ◄── 4.1
├── 4.4 Main Layout ◄── 1.1
├── 4.5 Episodes Screen ◄── 3.2, 4.1
├── 4.6 Episode Form ◄── 4.5
├── 4.7 Seasons Screen ◄── 3.2
├── 4.8 Season Form ◄── 4.7
└── 4.9 Delete Old Screens ◄── 4.5-4.8
                    │
Phase 5 (Extended Screens) ◄────┘
├── 5.1-5.10 (remaining screens)
                    │
Phase 6 (Cleanup) ◄─┘
├── 6.1-6.6 Polish tasks
└── 6.5 Build & Verify
```

## Rollback Plan

If issues are discovered:
1. Git stash/branch current changes
2. Identify failing phase
3. Revert to last working state
4. Fix and re-apply

## Estimates

| Phase | Tasks | Complexity |
|-------|-------|------------|
| 1. Foundation | 4 | Low |
| 2. Models | 8 | Low-Medium |
| 3. API & Providers | 3 | Medium |
| 4. Core Screens | 9 | Medium-High |
| 5. Extended Screens | 10 | Medium |
| 6. Cleanup | 6 | Low |
| **Total** | **40** | |

---

## Approval

- [ ] Reviewed by:
- [ ] Approved on:
- [ ] Notes:
