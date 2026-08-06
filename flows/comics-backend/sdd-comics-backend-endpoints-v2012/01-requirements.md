# Requirements: Comics Backend Mobile API v2012

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-19

## Problem Statement

The `apps/comics-backend` currently contains bhagavadgita API endpoints (Languages, Books, Chapters, Quotes). These need to be replaced with Comics-specific endpoints for the mobile apps:
- `apps/mahabharata-mobile-swift-v2012` (iOS)
- `apps/mahabharata-mobile-java-v2012` (Android)

The mobile apps expect specific v2012 API format with endpoints for Seasons, Episodes, Puzzles, Music, Quotes, and device management.

## User Stories

### Primary

**As a** mobile app user
**I want** to browse seasons, episodes, puzzles, and music
**So that** I can enjoy the Comics content on my iOS/Android device

**As a** mobile app
**I want** to register device and receive push notifications
**So that** users can be notified about new content

### Secondary

**As a** mobile app
**I want** to check subscription status
**So that** I can unlock premium content

## Required Endpoints

Based on analysis of `DataService.java` and mobile app models:

### Data Endpoints (POST /api/Data/*)

| Endpoint | Description | Response Format |
|----------|-------------|-----------------|
| `POST /api/Data/Seasons` | Get all seasons with nested episodes | `{code: 0, msg: "", data: [...]}` |
| `POST /api/Data/Subscriptions` | Get subscription products | `{code: 0, msg: "", data: [...]}` |
| `POST /api/Data/Puzzles` | Get all puzzles with nested pieces | `{code: 0, msg: "", data: [...]}` |
| `POST /api/Data/Quotes` | Get random quote | `{code: 0, msg: "", data: {...}}` |
| `POST /api/Data/Music` | Get all music tracks | `{code: 0, msg: "", data: [...]}` |

### Auth Endpoints (POST /api/Auth/*)

| Endpoint | Description | Request Body |
|----------|-------------|--------------|
| `POST /api/Auth/UpdateDevice` | Register/update device | `{deviceId, localTime}` |
| `POST /api/Auth/UpdatePushToken` | Update push notification token | `{token}` |

## Data Models

### Season
```json
{
  "id": 1,
  "order": 1,
  "name": "Season 1\\nThe Beginning",
  "image": "/Files/seasons/s1.jpg",
  "product": "com.fulldome.mahabharata.season1",
  "episodes": [...]
}
```

### Episode
```json
{
  "id": 101,
  "name": "Episode 1",
  "image": "/Files/episodes/e101.jpg",
  "file": "/Files/episodes/e101.cbz",
  "version": 1,
  "product": "com.fulldome.mahabharata.e101",
  "date": 1721347200,
  "order": 1
}
```

### Puzzle
```json
{
  "id": 1,
  "name": "Krishna Puzzle",
  "width": 3,
  "height": 4,
  "order": 1,
  "pieces": [...]
}
```

### Piece
```json
{
  "id": 1,
  "x": 0,
  "y": 0,
  "width": 1,
  "height": 1,
  "file": "/Files/puzzles/p1_0_0.cbz",
  "version": 1,
  "date": 1721347200,
  "order": 1
}
```

### Music
```json
{
  "id": 1,
  "name": "Opening Theme",
  "author": "Composer Name",
  "file": "/Files/music/track1.mp3"
}
```

### Quote
```json
{
  "id": 1,
  "name": "Quote text here",
  "image": "/Files/quotes/q1.jpg",
  "order": 1
}
```

## Acceptance Criteria

### Must Have

1. **Given** mobile app starts
   **When** app calls `POST /api/Data/Seasons`
   **Then** returns seasons with nested episodes, localized by Accept-Language header

2. **Given** mobile app opens puzzles section
   **When** app calls `POST /api/Data/Puzzles`
   **Then** returns all puzzles with nested pieces

3. **Given** mobile app opens music section
   **When** app calls `POST /api/Data/Music`
   **Then** returns all music tracks

4. **Given** mobile app opens quotes section
   **When** app calls `POST /api/Data/Quotes`
   **Then** returns random published quote

5. **Given** mobile app registers device
   **When** app calls `POST /api/Auth/UpdateDevice`
   **Then** device is registered/updated in database

6. **Given** mobile app receives FCM/APNS token
   **When** app calls `POST /api/Auth/UpdatePushToken`
   **Then** push token is saved for the device

### Should Have

- Localization via Accept-Language header (en, ru, hi)
- Image URLs resolved to full paths (prefix with HOST)
- Caching headers for static data

### Won't Have (This Iteration)

- In-app purchase verification (handled client-side)
- File streaming endpoints (handled by storage service)

## Constraints

- **Response Format**: Must match v2012 format `{code: 0/1, msg: "", data: ...}`
- **Database**: Supabase (postgres) with schema from `db/comics_schema.sql`
- **Localization**: Use tokens_localized table for multilingual text
- **Compatibility**: Must work with existing mobile apps without changes

## Open Questions

- [x] What languages are supported? → en, ru, hi (based on mobile app localization)
- [x] What is the file URL prefix? → Files served from `/Files/` path via legacyStorage routes

## References

- Mobile app DataService: `apps/mahabharata-mobile-java-v2012/app/src/main/java/com/fulldome/mahabharata/server/DataService.java`
- DB Schema: `db/comics_schema.sql`
- Existing backend: `apps/comics-backend/node/`

---

## Approval

- [ ] Reviewed by: User
- [ ] Approved on:
- [ ] Notes:
