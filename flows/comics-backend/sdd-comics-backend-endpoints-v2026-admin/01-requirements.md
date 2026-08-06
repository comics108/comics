# Requirements: Comics Admin Backend Endpoints v2026

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-19

## Problem Statement

Backend API endpoints для Comics Admin панели. Текущий файл `apps/comics-backend/node/src/docs/v2026-admin.yaml` содержит endpoints от bhagavadgita и должен быть переписан под Comics domain.

## Data Model Reference

Based on `db/comics_schema.sql`:

### Core Entities

| Entity | Fields | Relationships |
|--------|--------|---------------|
| tokens | id, key | → tokens_localized |
| tokens_localized | id, culture, text | |
| seasons | id, name_token_id, image, product, order | has many episodes |
| episodes | id, season_id, name_token_id, image, file, version, product, date, order | belongs to season |
| puzzles | id, name_token_id, width, height, order | has many pieces |
| pieces | id, puzzle_id, x, y, width, height, file, version, date, order | belongs to puzzle |
| quotes | id, name_token_id, image_token_id, publish_date | |
| music | id, name_token_id, author_token_id, file, order | |
| devices | id, platform, os_version, device_id, model, app_version, timezone_offset, culture, push_token, last_modified | |

### Cultures
- `en` - English
- `ru` - Russian
- `hi` - Hindi

## Required Endpoints

### Auth

| Method | Path | Description |
|--------|------|-------------|
| POST | /auth/login | Admin login |

### Seasons

| Method | Path | Description |
|--------|------|-------------|
| GET | /seasons | List all seasons |
| POST | /seasons | Create season |
| GET | /seasons/{id} | Get season by ID |
| PUT | /seasons/{id} | Update season |
| DELETE | /seasons/{id} | Delete season (cascade episodes) |
| PUT | /seasons/reorder | Reorder seasons |

### Episodes

| Method | Path | Description |
|--------|------|-------------|
| GET | /episodes | List episodes (filter by seasonId) |
| POST | /episodes | Create episode |
| GET | /episodes/{id} | Get episode by ID |
| PUT | /episodes/{id} | Update episode |
| DELETE | /episodes/{id} | Delete episode |
| PUT | /episodes/reorder | Reorder episodes within season |

### Puzzles

| Method | Path | Description |
|--------|------|-------------|
| GET | /puzzles | List all puzzles |
| POST | /puzzles | Create puzzle |
| GET | /puzzles/{id} | Get puzzle by ID |
| PUT | /puzzles/{id} | Update puzzle |
| DELETE | /puzzles/{id} | Delete puzzle (cascade pieces) |
| PUT | /puzzles/reorder | Reorder puzzles |

### Pieces

| Method | Path | Description |
|--------|------|-------------|
| GET | /pieces | List pieces (filter by puzzleId) |
| POST | /pieces | Create piece |
| GET | /pieces/{id} | Get piece by ID |
| PUT | /pieces/{id} | Update piece |
| DELETE | /pieces/{id} | Delete piece |
| PUT | /pieces/reorder | Reorder pieces within puzzle |

### Quotes

| Method | Path | Description |
|--------|------|-------------|
| GET | /quotes | List quotes (filter by status: all/scheduled/published) |
| POST | /quotes | Create quote |
| GET | /quotes/{id} | Get quote by ID |
| PUT | /quotes/{id} | Update quote |
| DELETE | /quotes/{id} | Delete quote |
| PUT | /quotes/{id}/publish | Publish quote now |

### Music

| Method | Path | Description |
|--------|------|-------------|
| GET | /music | List all music tracks |
| POST | /music | Create music track |
| GET | /music/{id} | Get music track by ID |
| PUT | /music/{id} | Update music track |
| DELETE | /music/{id} | Delete music track |
| PUT | /music/reorder | Reorder music tracks |

### Devices & Notifications

| Method | Path | Description |
|--------|------|-------------|
| GET | /devices | List devices (filter by platform, paginated) |
| GET | /devices/stats | Device statistics |
| POST | /notifications/send | Send push notification |

### Files

| Method | Path | Description |
|--------|------|-------------|
| POST | /files/upload | Upload file (image/audio/cbz) |

## Response Format

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100
  }
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error message",
  "data": null
}
```

## Localized Content Handling

### Creating/Updating with Localized Text

Request body includes localized fields:
```json
{
  "name": {
    "en": "Episode Title",
    "ru": "Название эпизода",
    "hi": "एपिसोड शीर्षक"
  },
  "image": "uploads/episode-1.jpg",
  "seasonId": 1,
  "order": 1
}
```

Backend creates/updates token + tokens_localized records.

### Reading Localized Content

Response includes all localizations:
```json
{
  "id": 1,
  "name": {
    "en": "Episode Title",
    "ru": "Название эпизода",
    "hi": "एपिसोड शीर्षक"
  },
  "seasonId": 1,
  "seasonName": {
    "en": "Season 1",
    "ru": "Сезон 1",
    "hi": "सीज़न 1"
  }
}
```

## Acceptance Criteria

### Must Have

1. **Given** valid admin credentials
   **When** POST /auth/login
   **Then** return JWT token

2. **Given** authenticated request
   **When** GET /seasons
   **Then** return list with localized names

3. **Given** authenticated request with reorder payload
   **When** PUT /episodes/reorder
   **Then** update order values in database

4. **Given** image file upload
   **When** POST /files/upload
   **Then** save file and return URL

5. **Given** quote with future publish_date
   **When** GET /quotes?status=scheduled
   **Then** return only scheduled quotes

### Should Have

- Pagination for all list endpoints
- Validation error messages
- Cascade delete with confirmation

### Won't Have (This Iteration)

- Rate limiting
- API versioning migration
- Webhook notifications

## Constraints

- **Technical**: Node.js backend, Supabase PostgreSQL
- **Path**: /api/v2026/admin
- **Auth**: JWT Bearer token
- **File Storage**: Local or S3-compatible

## Files to Create/Modify

1. **UPDATE**: `apps/comics-backend/node/src/docs/v2026-admin.yaml` - OpenAPI spec
2. **CREATE**: Route handlers for each entity
3. **CREATE**: Controllers for business logic
4. **CREATE**: Supabase queries

## Open Questions

- [x] Auth system: JWT (same as bhagavadgita)
- [ ] File storage location: local uploads/ or S3?
- [ ] Push notification service: Firebase FCM?

## References

- Current (bhagavadgita) spec: `apps/comics-backend/node/src/docs/v2026-admin.yaml`
- DB schema: `db/comics_schema.sql`
- Frontend requirements: `flows/sdd-comics-admin/01-requirements.md`

---

## Approval

- [ ] Reviewed by:
- [ ] Approved on:
- [ ] Notes:
