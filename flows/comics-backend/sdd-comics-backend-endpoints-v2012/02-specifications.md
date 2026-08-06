# Specifications: Comics Backend Mobile API v2012

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-19

## Overview

Replace bhagavadgita v2012 routes with Comics-specific endpoints in `apps/comics-backend/node`.

## Architecture

### File Structure

```
apps/comics-backend/node/src/
├── routes/
│   └── v2012/
│       ├── index.js          # UPDATE: Mount comics routes
│       ├── seasons.js        # NEW: Seasons with episodes
│       ├── puzzles.js        # NEW: Puzzles with pieces
│       ├── music.js          # NEW: Music tracks
│       ├── quotes.js         # UPDATE: Comics quotes
│       ├── auth.js           # NEW: Device registration
│       ├── languages.js      # DELETE (not needed)
│       ├── books.js          # DELETE (bhagavadgita)
│       └── chapters.js       # DELETE (bhagavadgita)
├── transformers/
│   └── v2012/
│       ├── seasonTransformer.js   # NEW
│       ├── puzzleTransformer.js   # NEW
│       ├── musicTransformer.js    # NEW
│       └── quoteTransformer.js    # UPDATE
└── docs/
    └── v2012.yaml            # UPDATE: OpenAPI spec
```

### Database Tables Used

| Table | Purpose |
|-------|---------|
| seasons | Season records |
| episodes | Episode records (FK: season_id) |
| tokens | Localized text keys |
| tokens_localized | Localized text values (culture: en/ru/hi) |
| puzzles | Puzzle records |
| pieces | Piece records (FK: puzzle_id) |
| music | Music track records |
| quotes | Quote records |
| devices | Device registrations |

## Endpoint Specifications

### POST /api/Data/Seasons

**Purpose**: Get all seasons with nested episodes, localized by Accept-Language.

**Request**:
```
POST /api/Data/Seasons
Accept-Language: ru
```

**Query Logic**:
```sql
-- 1. Fetch all seasons ordered by 'order'
SELECT s.*, t.text as name
FROM seasons s
JOIN tokens_localized t ON t.id = s.name_token_id AND t.culture = :lang
ORDER BY s.order;

-- 2. Fetch all episodes ordered by season_id, order
SELECT e.*, t.text as name
FROM episodes e
JOIN tokens_localized t ON t.id = e.name_token_id AND t.culture = :lang
ORDER BY e.season_id, e.order;

-- 3. Nest episodes into seasons (in code)
```

**Response**:
```json
{
  "code": 0,
  "msg": "",
  "data": [
    {
      "id": 1,
      "order": 1,
      "name": "Сезон 1\\nНачало",
      "image": "/Files/seasons/s1.jpg",
      "product": "com.fulldome.mahabharata.season1",
      "episodes": [
        {
          "id": 101,
          "name": "Эпизод 1",
          "image": "/Files/episodes/e101.jpg",
          "file": "/Files/episodes/e101.cbz",
          "version": 1,
          "product": null,
          "date": 1721347200,
          "order": 1
        }
      ]
    }
  ]
}
```

**Transformer** (`seasonTransformer.js`):
```javascript
function transformSeasons(seasons, episodes, lang) {
  const episodesBySeasonId = groupBy(episodes, 'season_id');

  return seasons.map(s => ({
    id: s.id,
    order: s.order,
    name: s.name, // Already localized from join
    image: s.image ? `/Files/${s.image}` : null,
    product: s.product || null,
    episodes: (episodesBySeasonId[s.id] || []).map(e => ({
      id: e.id,
      name: e.name,
      image: e.image ? `/Files/${e.image}` : null,
      file: e.file ? `/Files/${e.file}` : null,
      version: e.version,
      product: e.product || null,
      date: Math.floor(new Date(e.date).getTime() / 1000),
      order: e.order
    }))
  }));
}
```

---

### POST /api/Data/Puzzles

**Purpose**: Get all puzzles with nested pieces.

**Request**:
```
POST /api/Data/Puzzles
Accept-Language: en
```

**Query Logic**:
```sql
-- 1. Fetch all puzzles
SELECT p.*, t.text as name
FROM puzzles p
JOIN tokens_localized t ON t.id = p.name_token_id AND t.culture = :lang
ORDER BY p.order;

-- 2. Fetch all pieces
SELECT * FROM pieces ORDER BY puzzle_id, "order";

-- 3. Nest pieces into puzzles (in code)
```

**Response**:
```json
{
  "code": 0,
  "msg": "",
  "data": [
    {
      "id": 1,
      "name": "Krishna Puzzle",
      "width": 3,
      "height": 4,
      "order": 1,
      "pieces": [
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
      ]
    }
  ]
}
```

---

### POST /api/Data/Music

**Purpose**: Get all music tracks.

**Request**:
```
POST /api/Data/Music
Accept-Language: hi
```

**Query Logic**:
```sql
SELECT m.id, m.file, m.order,
       tn.text as name,
       ta.text as author
FROM music m
JOIN tokens_localized tn ON tn.id = m.name_token_id AND tn.culture = :lang
JOIN tokens_localized ta ON ta.id = m.author_token_id AND ta.culture = :lang
ORDER BY m.order;
```

**Response**:
```json
{
  "code": 0,
  "msg": "",
  "data": [
    {
      "id": 1,
      "name": "ओपनिंग थीम",
      "author": "संगीतकार ए",
      "file": "/Files/music/track1.mp3"
    }
  ]
}
```

---

### POST /api/Data/Quotes

**Purpose**: Get random published quote.

**Request**:
```
POST /api/Data/Quotes
Accept-Language: ru
```

**Query Logic**:
```sql
SELECT q.id, q.order,
       tn.text as name,
       ti.text as image
FROM quotes q
JOIN tokens_localized tn ON tn.id = q.name_token_id AND tn.culture = :lang
JOIN tokens_localized ti ON ti.id = q.image_token_id AND ti.culture = :lang
WHERE q.publish_date IS NULL OR q.publish_date <= NOW()
ORDER BY RANDOM()
LIMIT 1;
```

**Response** (note: single object in data, not array):
```json
{
  "code": 0,
  "msg": "",
  "data": {
    "id": 1,
    "name": "Цитата дня здесь",
    "image": "/Files/quotes/q1_ru.jpg",
    "order": 1
  }
}
```

---

### POST /api/Data/Subscriptions

**Purpose**: Get subscription products for in-app purchases.

**Query Logic**:
```sql
-- Collect all products from seasons and episodes
SELECT DISTINCT product FROM seasons WHERE product IS NOT NULL
UNION
SELECT DISTINCT product FROM episodes WHERE product IS NOT NULL;
```

**Response**:
```json
{
  "code": 0,
  "msg": "",
  "data": [
    "com.fulldome.mahabharata.season1",
    "com.fulldome.mahabharata.e101"
  ]
}
```

---

### POST /api/Auth/UpdateDevice

**Purpose**: Register or update device info.

**Request Body**:
```json
{
  "deviceId": "abc123",
  "localTime": 1721347200
}
```

**Headers**:
- `User-Agent`: Contains platform (iOS/Android), OS version, app version, model

**Query Logic**:
```sql
INSERT INTO devices (device_id, platform, os_version, model, app_version, timezone_offset, culture, last_modified)
VALUES (:deviceId, :platform, :osVersion, :model, :appVersion, :timezoneOffset, :culture, NOW())
ON CONFLICT (device_id) DO UPDATE
SET platform = :platform,
    os_version = :osVersion,
    model = :model,
    app_version = :appVersion,
    timezone_offset = :timezoneOffset,
    culture = :culture,
    last_modified = NOW()
RETURNING id;
```

**Response**:
```json
{
  "code": 0,
  "msg": "",
  "data": {
    "token": "device-uuid-here"
  }
}
```

---

### POST /api/Auth/UpdatePushToken

**Purpose**: Save FCM/APNs push token for device.

**Request Body**:
```json
{
  "token": "fcm-or-apns-token-here"
}
```

**Headers**:
- Requires device token from UpdateDevice (or device_id cookie)

**Query Logic**:
```sql
UPDATE devices
SET push_token = :token, last_modified = NOW()
WHERE id = :deviceId;
```

**Response**:
```json
{
  "code": 0,
  "msg": "",
  "data": null
}
```

---

## Language Resolution

**Middleware** (`middleware/language.js`):
1. Parse `Accept-Language` header
2. Match against supported: `en`, `ru`, `hi`
3. Default to `en` if not matched
4. Set `req.lang` for route handlers

---

## Response Utilities

**v2012Response** (`utils/response.js`):
```javascript
function v2012Response(res, data) {
  res.json({ code: 0, msg: '', data });
}

function v2012Error(res, message, statusCode = 500) {
  res.status(statusCode).json({ code: 1, msg: message, data: null });
}
```

---

## OpenAPI Update

Update `src/docs/v2012.yaml`:
- Remove: Languages, Books, Chapters
- Add: Seasons, Episodes, Puzzles, Pieces, Music, Quotes, Auth

---

## Error Handling

| Scenario | Code | Message |
|----------|------|---------|
| Success | 0 | "" |
| Database error | 1 | "Database error" |
| Not found | 1 | "Not found" |
| Validation error | 1 | Field-specific message |

---

## Testing

Manual testing via Swagger UI at `/api-docs` or curl:
```bash
curl -X POST http://localhost:3000/api/Data/Seasons \
  -H "Accept-Language: ru"
```

---

## Approval

- [ ] Reviewed by: User
- [ ] Approved on:
- [ ] Notes:
