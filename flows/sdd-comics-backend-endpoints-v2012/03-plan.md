# Implementation Plan: Comics Backend Mobile API v2012

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-19

## Overview

Replace bhagavadgita v2012 routes with Comics endpoints. Total: ~12 files to create/modify.

## Task Breakdown

### Phase 1: Preparation

#### Task 1.1: Create transformers directory structure
- **Files**: Create `src/transformers/v2012/` if not exists
- **Complexity**: Low
- **Dependencies**: None

#### Task 1.2: Create seasonTransformer.js
- **File**: `src/transformers/v2012/seasonTransformer.js`
- **Action**: CREATE
- **Content**:
  - `transformSeasons(seasons, episodes)` - nest episodes into seasons
  - `transformEpisode(episode)` - format single episode
- **Complexity**: Low
- **Dependencies**: None

#### Task 1.3: Create puzzleTransformer.js
- **File**: `src/transformers/v2012/puzzleTransformer.js`
- **Action**: CREATE
- **Content**:
  - `transformPuzzles(puzzles, pieces)` - nest pieces into puzzles
  - `transformPiece(piece)` - format single piece
- **Complexity**: Low
- **Dependencies**: None

#### Task 1.4: Create musicTransformer.js
- **File**: `src/transformers/v2012/musicTransformer.js`
- **Action**: CREATE
- **Content**:
  - `transformMusic(musicList)` - format music tracks
- **Complexity**: Low
- **Dependencies**: None

#### Task 1.5: Update quoteTransformer.js
- **File**: `src/transformers/v2012/quoteTransformer.js`
- **Action**: CREATE or UPDATE
- **Content**:
  - `transformQuote(quote)` - format single quote for Comics
- **Complexity**: Low
- **Dependencies**: None

---

### Phase 2: Route Handlers

#### Task 2.1: Create seasons.js route
- **File**: `src/routes/v2012/seasons.js`
- **Action**: CREATE
- **Content**:
  ```javascript
  POST /Data/Seasons
  - Fetch seasons with localized names
  - Fetch all episodes with localized names
  - Nest episodes into seasons
  - Return v2012 format response
  ```
- **Complexity**: Medium
- **Dependencies**: Task 1.2

#### Task 2.2: Create puzzles.js route
- **File**: `src/routes/v2012/puzzles.js`
- **Action**: CREATE
- **Content**:
  ```javascript
  POST /Data/Puzzles
  - Fetch puzzles with localized names
  - Fetch all pieces
  - Nest pieces into puzzles
  - Return v2012 format response
  ```
- **Complexity**: Medium
- **Dependencies**: Task 1.3

#### Task 2.3: Create music.js route
- **File**: `src/routes/v2012/music.js`
- **Action**: CREATE
- **Content**:
  ```javascript
  POST /Data/Music
  - Fetch music with localized name/author
  - Return v2012 format response
  ```
- **Complexity**: Low
- **Dependencies**: Task 1.4

#### Task 2.4: Update quotes.js route
- **File**: `src/routes/v2012/quotes.js`
- **Action**: UPDATE (replace bhagavadgita logic)
- **Content**:
  ```javascript
  POST /Data/Quotes
  - Fetch random published quote
  - Return single quote (not array)
  ```
- **Complexity**: Low
- **Dependencies**: Task 1.5

#### Task 2.5: Create subscriptions.js route
- **File**: `src/routes/v2012/subscriptions.js`
- **Action**: CREATE
- **Content**:
  ```javascript
  POST /Data/Subscriptions
  - Collect products from seasons/episodes
  - Return array of product IDs
  ```
- **Complexity**: Low
- **Dependencies**: None

#### Task 2.6: Create auth.js route
- **File**: `src/routes/v2012/auth.js`
- **Action**: CREATE
- **Content**:
  ```javascript
  POST /Auth/UpdateDevice
  - Parse User-Agent for device info
  - Upsert device record
  - Return device token

  POST /Auth/UpdatePushToken
  - Update push_token for device
  ```
- **Complexity**: Medium
- **Dependencies**: None

---

### Phase 3: Integration

#### Task 3.1: Update v2012/index.js
- **File**: `src/routes/v2012/index.js`
- **Action**: UPDATE
- **Changes**:
  - Remove: languages, books, chapters imports
  - Add: seasons, puzzles, music, subscriptions, auth imports
  - Update route mounting
- **Complexity**: Low
- **Dependencies**: Tasks 2.1-2.6

#### Task 3.2: Delete bhagavadgita routes
- **Files**:
  - DELETE `src/routes/v2012/languages.js`
  - DELETE `src/routes/v2012/books.js`
  - DELETE `src/routes/v2012/chapters.js`
- **Complexity**: Low
- **Dependencies**: Task 3.1

#### Task 3.3: Delete bhagavadgita transformers
- **Files**:
  - DELETE `src/transformers/v2012/languageTransformer.js` (if exists)
  - DELETE `src/transformers/v2012/bookTransformer.js`
  - DELETE `src/transformers/v2012/chapterTransformer.js`
- **Complexity**: Low
- **Dependencies**: Task 3.1

---

### Phase 4: Documentation

#### Task 4.1: Update v2012.yaml OpenAPI spec
- **File**: `src/docs/v2012.yaml`
- **Action**: UPDATE
- **Changes**:
  - Replace title: "Comics API v2012"
  - Remove: Languages, Books, Chapters paths/schemas
  - Add: Seasons, Episodes, Puzzles, Pieces, Music, Quotes, Auth paths/schemas
- **Complexity**: Medium
- **Dependencies**: All Phase 2 tasks

---

## File Changes Summary

| Action | File | Description |
|--------|------|-------------|
| CREATE | `transformers/v2012/seasonTransformer.js` | Season/Episode transformer |
| CREATE | `transformers/v2012/puzzleTransformer.js` | Puzzle/Piece transformer |
| CREATE | `transformers/v2012/musicTransformer.js` | Music transformer |
| CREATE | `transformers/v2012/quoteTransformer.js` | Quote transformer |
| CREATE | `routes/v2012/seasons.js` | Seasons endpoint |
| CREATE | `routes/v2012/puzzles.js` | Puzzles endpoint |
| CREATE | `routes/v2012/music.js` | Music endpoint |
| CREATE | `routes/v2012/subscriptions.js` | Subscriptions endpoint |
| CREATE | `routes/v2012/auth.js` | Device auth endpoints |
| UPDATE | `routes/v2012/quotes.js` | Comics quotes |
| UPDATE | `routes/v2012/index.js` | Route mounting |
| UPDATE | `docs/v2012.yaml` | OpenAPI spec |
| DELETE | `routes/v2012/languages.js` | Bhagavadgita |
| DELETE | `routes/v2012/books.js` | Bhagavadgita |
| DELETE | `routes/v2012/chapters.js` | Bhagavadgita |
| DELETE | `transformers/v2012/bookTransformer.js` | Bhagavadgita |
| DELETE | `transformers/v2012/chapterTransformer.js` | Bhagavadgita |

---

## Testing Strategy

1. **Unit**: Test transformers with mock data
2. **Integration**: Test each endpoint via curl/Postman
3. **E2E**: Test from mobile app simulator

```bash
# Test seasons
curl -X POST http://localhost:3000/api/Data/Seasons -H "Accept-Language: ru"

# Test puzzles
curl -X POST http://localhost:3000/api/Data/Puzzles

# Test music
curl -X POST http://localhost:3000/api/Data/Music -H "Accept-Language: hi"

# Test quotes
curl -X POST http://localhost:3000/api/Data/Quotes

# Test device registration
curl -X POST http://localhost:3000/api/Auth/UpdateDevice \
  -H "Content-Type: application/json" \
  -d '{"deviceId": "test123", "localTime": 1721347200}'
```

---

## Rollback Plan

If issues arise:
1. Revert to git commit before changes
2. Original bhagavadgita routes preserved in git history

---

## Approval

- [ ] Reviewed by: User
- [ ] Approved on:
- [ ] Notes:
