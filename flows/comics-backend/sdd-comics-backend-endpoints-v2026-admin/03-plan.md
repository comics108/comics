# Implementation Plan: Comics Backend Admin API v2026

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-19

## Overview

Implement admin API endpoints for `comics_admin`. Total: ~18 files to create/modify.

## Task Breakdown

### Phase 1: Foundation

#### Task 1.1: Create tokenService.js
- **File**: `src/services/tokenService.js`
- **Action**: CREATE
- **Content**:
  - `createToken(key, localizedText)` - create token + localizations
  - `updateToken(tokenId, localizedText)` - update/upsert localizations
  - `deleteToken(tokenId)` - cleanup token and localizations
  - `getLocalizedText(tokenId)` - get all cultures for token
- **Complexity**: Medium
- **Dependencies**: None

#### Task 1.2: Create adminAuth middleware
- **File**: `src/middleware/adminAuth.js`
- **Action**: CREATE
- **Content**:
  - Verify JWT Bearer token via Supabase Auth
  - Attach user to request
  - Return 401 if invalid
- **Complexity**: Low
- **Dependencies**: None

#### Task 1.3: Create admin response utilities
- **File**: `src/utils/adminResponse.js`
- **Action**: CREATE
- **Content**:
  - `adminSuccess(res, data, pagination?)`
  - `adminError(res, message, statusCode)`
- **Complexity**: Low
- **Dependencies**: None

---

### Phase 2: Admin Routes

#### Task 2.1: Create admin router index
- **File**: `src/routes/v2026/admin/index.js`
- **Action**: CREATE
- **Content**:
  - Import all admin route modules
  - Apply adminAuth middleware to all routes except /auth
  - Export router
- **Complexity**: Low
- **Dependencies**: Task 1.2

#### Task 2.2: Create auth.js
- **File**: `src/routes/v2026/admin/auth.js`
- **Action**: CREATE
- **Content**:
  - `POST /auth/login` - Supabase signInWithPassword
- **Complexity**: Low
- **Dependencies**: Task 1.3

#### Task 2.3: Create seasons.js
- **File**: `src/routes/v2026/admin/seasons.js`
- **Action**: CREATE
- **Content**:
  - `GET /seasons` - list with episodesCount
  - `POST /seasons` - create with token
  - `GET /seasons/:id` - single season
  - `PUT /seasons/:id` - update
  - `DELETE /seasons/:id` - cascade delete
  - `PUT /seasons/reorder` - batch update order
- **Complexity**: High
- **Dependencies**: Tasks 1.1, 1.3

#### Task 2.4: Create episodes.js
- **File**: `src/routes/v2026/admin/episodes.js`
- **Action**: CREATE
- **Content**:
  - `GET /episodes?seasonId=X` - list for season
  - `POST /episodes` - create with token
  - `GET /episodes/:id` - single episode
  - `PUT /episodes/:id` - update
  - `DELETE /episodes/:id` - delete
  - `PUT /episodes/reorder` - batch update order within season
- **Complexity**: High
- **Dependencies**: Tasks 1.1, 1.3

#### Task 2.5: Create puzzles.js
- **File**: `src/routes/v2026/admin/puzzles.js`
- **Action**: CREATE
- **Content**:
  - `GET /puzzles` - list with piecesCount
  - `POST /puzzles` - create with token
  - `GET /puzzles/:id` - single puzzle
  - `PUT /puzzles/:id` - update
  - `DELETE /puzzles/:id` - cascade delete pieces
  - `PUT /puzzles/reorder` - batch update order
- **Complexity**: High
- **Dependencies**: Tasks 1.1, 1.3

#### Task 2.6: Create pieces.js
- **File**: `src/routes/v2026/admin/pieces.js`
- **Action**: CREATE
- **Content**:
  - `GET /pieces?puzzleId=X` - list for puzzle
  - `POST /pieces` - create piece
  - `GET /pieces/:id` - single piece
  - `PUT /pieces/:id` - update
  - `DELETE /pieces/:id` - delete
  - `PUT /pieces/reorder` - batch update order within puzzle
- **Complexity**: Medium
- **Dependencies**: Task 1.3

#### Task 2.7: Create music.js
- **File**: `src/routes/v2026/admin/music.js`
- **Action**: CREATE
- **Content**:
  - `GET /music` - list all
  - `POST /music` - create with name/author tokens
  - `GET /music/:id` - single track
  - `PUT /music/:id` - update
  - `DELETE /music/:id` - delete
  - `PUT /music/reorder` - batch update order
- **Complexity**: High
- **Dependencies**: Tasks 1.1, 1.3

#### Task 2.8: Create quotes.js
- **File**: `src/routes/v2026/admin/quotes.js`
- **Action**: CREATE
- **Content**:
  - `GET /quotes?status=X` - list with filter
  - `POST /quotes` - create with text/image tokens
  - `GET /quotes/:id` - single quote
  - `PUT /quotes/:id` - update
  - `DELETE /quotes/:id` - delete
  - `PUT /quotes/:id/publish` - set publish_date = now
- **Complexity**: High
- **Dependencies**: Tasks 1.1, 1.3

#### Task 2.9: Create devices.js
- **File**: `src/routes/v2026/admin/devices.js`
- **Action**: CREATE
- **Content**:
  - `GET /devices?platform=X` - paginated list
  - `GET /devices/stats` - aggregate stats
- **Complexity**: Medium
- **Dependencies**: Task 1.3

#### Task 2.10: Create notifications.js
- **File**: `src/routes/v2026/admin/notifications.js`
- **Action**: CREATE
- **Content**:
  - `POST /notifications/send` - send push to devices
- **Complexity**: High (FCM integration)
- **Dependencies**: Task 1.3

#### Task 2.11: Create files.js
- **File**: `src/routes/v2026/admin/files.js`
- **Action**: CREATE
- **Content**:
  - `POST /files/upload` - multipart upload to Supabase Storage
- **Complexity**: Medium
- **Dependencies**: Task 1.3

---

### Phase 3: Integration

#### Task 3.1: Update v2026/index.js
- **File**: `src/routes/v2026/index.js`
- **Action**: UPDATE
- **Changes**:
  - Import admin router
  - Mount at `/admin`
- **Complexity**: Low
- **Dependencies**: Task 2.1

#### Task 3.2: Update main index.js
- **File**: `src/index.js`
- **Action**: UPDATE
- **Changes**:
  - Update console log messages for Comics
- **Complexity**: Low
- **Dependencies**: None

---

### Phase 4: Push Service (Optional - can stub initially)

#### Task 4.1: Create pushService.js
- **File**: `src/services/pushService.js`
- **Action**: CREATE
- **Content**:
  - `sendPushNotification(title, body, platform)` - FCM multicast
  - Requires Firebase Admin SDK setup
- **Complexity**: High
- **Dependencies**: Firebase credentials

---

### Phase 5: Documentation

#### Task 5.1: Update v2026-admin.yaml
- **File**: `src/docs/v2026-admin.yaml`
- **Action**: UPDATE
- **Changes**:
  - Already has Comics structure (from sdd-comics-admin)
  - Verify matches implementation
- **Complexity**: Low
- **Dependencies**: All Phase 2 tasks

---

## File Changes Summary

| Action | File | Description |
|--------|------|-------------|
| CREATE | `services/tokenService.js` | Localized text management |
| CREATE | `services/pushService.js` | FCM push notifications |
| CREATE | `middleware/adminAuth.js` | JWT auth middleware |
| CREATE | `utils/adminResponse.js` | Response helpers |
| CREATE | `routes/v2026/admin/index.js` | Admin router |
| CREATE | `routes/v2026/admin/auth.js` | Login |
| CREATE | `routes/v2026/admin/seasons.js` | Seasons CRUD |
| CREATE | `routes/v2026/admin/episodes.js` | Episodes CRUD |
| CREATE | `routes/v2026/admin/puzzles.js` | Puzzles CRUD |
| CREATE | `routes/v2026/admin/pieces.js` | Pieces CRUD |
| CREATE | `routes/v2026/admin/music.js` | Music CRUD |
| CREATE | `routes/v2026/admin/quotes.js` | Quotes CRUD |
| CREATE | `routes/v2026/admin/devices.js` | Device stats |
| CREATE | `routes/v2026/admin/notifications.js` | Push send |
| CREATE | `routes/v2026/admin/files.js` | File upload |
| UPDATE | `routes/v2026/index.js` | Mount admin router |
| UPDATE | `index.js` | Console messages |
| UPDATE | `docs/v2026-admin.yaml` | Verify OpenAPI spec |

---

## Execution Order

Recommended order for implementation:

1. **Foundation** (Tasks 1.1-1.3) - Must be first
2. **Auth** (Task 2.2) - Login needed for testing
3. **Seasons + Episodes** (Tasks 2.3-2.4) - Core content
4. **Puzzles + Pieces** (Tasks 2.5-2.6) - Secondary content
5. **Music** (Task 2.7) - Simple entity
6. **Quotes** (Task 2.8) - With scheduling
7. **Devices** (Task 2.9) - Read-only
8. **Files** (Task 2.11) - Upload support
9. **Notifications** (Task 2.10) - Can stub initially
10. **Integration** (Tasks 3.1-3.2)

---

## Testing Strategy

```bash
# 1. Login
TOKEN=$(curl -s -X POST http://localhost:3000/api/v2026/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@test.com","password":"secret"}' | jq -r '.data.token')

# 2. List seasons
curl http://localhost:3000/api/v2026/admin/seasons \
  -H "Authorization: Bearer $TOKEN"

# 3. Create season
curl -X POST http://localhost:3000/api/v2026/admin/seasons \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":{"en":"Season 1","ru":"Сезон 1"},"order":1}'

# 4. Upload file
curl -X POST http://localhost:3000/api/v2026/admin/files/upload \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@cover.jpg" \
  -F "folder=seasons"
```

---

## Rollback Plan

1. Routes are additive - existing v2026 routes unaffected
2. Git revert if issues arise
3. Can disable admin routes by commenting mount in v2026/index.js

---

## Approval

- [ ] Reviewed by: User
- [ ] Approved on:
- [ ] Notes:
