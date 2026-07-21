# Specifications: Comics Backend Admin API v2026

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-19

## Overview

Implement admin API endpoints for `comics_admin` Flutter panel in `apps/comics-backend/node`.

## Architecture

### File Structure

```
apps/comics-backend/node/src/
├── routes/
│   └── v2026/
│       ├── index.js              # UPDATE: Mount admin routes
│       └── admin/
│           ├── index.js          # NEW: Admin router
│           ├── auth.js           # NEW: Login
│           ├── seasons.js        # NEW: Seasons CRUD
│           ├── episodes.js       # NEW: Episodes CRUD
│           ├── puzzles.js        # NEW: Puzzles CRUD
│           ├── pieces.js         # NEW: Pieces CRUD
│           ├── music.js          # NEW: Music CRUD
│           ├── quotes.js         # NEW: Quotes CRUD
│           ├── devices.js        # NEW: Device stats
│           ├── notifications.js  # NEW: Push notifications
│           └── files.js          # NEW: File uploads
├── middleware/
│   └── adminAuth.js              # NEW: JWT verification
├── services/
│   ├── tokenService.js           # NEW: Localized tokens CRUD
│   └── pushService.js            # NEW: FCM push
└── docs/
    └── v2026-admin.yaml          # UPDATE: OpenAPI spec
```

### Response Format

**Success**:
```javascript
function adminSuccess(res, data, pagination = null) {
  const response = { success: true, data };
  if (pagination) response.pagination = pagination;
  res.json(response);
}
```

**Error**:
```javascript
function adminError(res, message, statusCode = 400) {
  res.status(statusCode).json({
    success: false,
    error: message,
    data: null
  });
}
```

---

## Token Service (Localized Text)

### Creating Localized Content

When creating an entity with localized text:

```javascript
// tokenService.js
async function createToken(key, localizedText) {
  const supabase = getSupabase();

  // 1. Create token record
  const { data: token, error } = await supabase
    .from('tokens')
    .insert({ key })
    .select('id')
    .single();

  if (error) throw error;

  // 2. Insert localized values
  const localizations = Object.entries(localizedText).map(([culture, text]) => ({
    id: token.id,
    culture,
    text
  }));

  await supabase.from('tokens_localized').insert(localizations);

  return token.id;
}

async function updateToken(tokenId, localizedText) {
  const supabase = getSupabase();

  // Upsert each localization
  for (const [culture, text] of Object.entries(localizedText)) {
    await supabase
      .from('tokens_localized')
      .upsert({ id: tokenId, culture, text });
  }
}

async function getLocalizedText(tokenId) {
  const supabase = getSupabase();
  const { data } = await supabase
    .from('tokens_localized')
    .select('culture, text')
    .eq('id', tokenId);

  return data.reduce((acc, row) => {
    acc[row.culture] = row.text;
    return acc;
  }, {});
}
```

---

## Endpoint Specifications

### POST /api/v2026/admin/auth/login

**Request**:
```json
{
  "email": "admin@example.com",
  "password": "secret"
}
```

**Logic**: Use Supabase Auth
```javascript
const { data, error } = await supabase.auth.signInWithPassword({
  email, password
});
```

**Response**:
```json
{
  "success": true,
  "data": {
    "token": "jwt-token-here",
    "user": {
      "id": "uuid",
      "email": "admin@example.com"
    }
  }
}
```

---

### Seasons Endpoints

#### GET /api/v2026/admin/seasons

**Query**:
```sql
SELECT s.id, s.image, s.product, s.order, s.name_token_id,
       (SELECT COUNT(*) FROM episodes WHERE season_id = s.id) as episodes_count
FROM seasons s
ORDER BY s.order;
```

**Transform**: Fetch localized names via tokenService

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": { "en": "Season 1", "ru": "Сезон 1", "hi": "सीज़न 1" },
      "image": "seasons/s1.jpg",
      "product": "com.fulldome.season1",
      "order": 1,
      "episodesCount": 12
    }
  ]
}
```

#### POST /api/v2026/admin/seasons

**Request**:
```json
{
  "name": { "en": "Season 1", "ru": "Сезон 1", "hi": "सीज़न 1" },
  "image": "seasons/s1.jpg",
  "product": "com.fulldome.season1",
  "order": 1
}
```

**Logic**:
```javascript
// 1. Create name token
const nameTokenId = await tokenService.createToken('season_name', body.name);

// 2. Insert season
const { data: season } = await supabase
  .from('seasons')
  .insert({
    name_token_id: nameTokenId,
    image: body.image,
    product: body.product,
    order: body.order || (await getNextOrder('seasons'))
  })
  .select()
  .single();
```

#### PUT /api/v2026/admin/seasons/:id

**Request**: Same as POST (partial updates allowed)

**Logic**:
```javascript
// 1. If name provided, update token
if (body.name) {
  const { name_token_id } = await fetchById('seasons', id);
  await tokenService.updateToken(name_token_id, body.name);
}

// 2. Update season fields (excluding name)
await supabase
  .from('seasons')
  .update({ image: body.image, product: body.product, order: body.order })
  .eq('id', id);
```

#### DELETE /api/v2026/admin/seasons/:id

**Logic** (cascade delete):
```javascript
// 1. Delete all episodes in season
await supabase.from('episodes').delete().eq('season_id', id);

// 2. Delete season (token cleanup via DB trigger or manual)
await supabase.from('seasons').delete().eq('id', id);
```

#### PUT /api/v2026/admin/seasons/reorder

**Request**:
```json
{
  "order": [3, 1, 2]  // Season IDs in new order
}
```

**Logic**:
```javascript
for (let i = 0; i < order.length; i++) {
  await supabase
    .from('seasons')
    .update({ order: i + 1 })
    .eq('id', order[i]);
}
```

---

### Episodes Endpoints

#### GET /api/v2026/admin/episodes

**Query params**: `seasonId` (required)

**Query**:
```sql
SELECT e.* FROM episodes e
WHERE e.season_id = :seasonId
ORDER BY e.order;
```

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": 101,
      "seasonId": 1,
      "name": { "en": "Episode 1", "ru": "Эпизод 1", "hi": "एपिसोड 1" },
      "image": "episodes/e101.jpg",
      "file": "episodes/e101.cbz",
      "version": 1,
      "product": null,
      "date": "2026-07-19",
      "order": 1
    }
  ]
}
```

#### POST /api/v2026/admin/episodes

**Request**:
```json
{
  "seasonId": 1,
  "name": { "en": "Episode 1", "ru": "Эпизод 1", "hi": "एपिसोड 1" },
  "image": "episodes/e101.jpg",
  "file": "episodes/e101.cbz",
  "version": 1,
  "product": null,
  "date": "2026-07-19",
  "order": 1
}
```

---

### Puzzles Endpoints

#### GET /api/v2026/admin/puzzles

**Query**:
```sql
SELECT p.*, (SELECT COUNT(*) FROM pieces WHERE puzzle_id = p.id) as pieces_count
FROM puzzles p
ORDER BY p.order;
```

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": { "en": "Krishna Puzzle", "ru": "Пазл Кришна", "hi": "कृष्ण पहेली" },
      "width": 3,
      "height": 4,
      "order": 1,
      "piecesCount": 12
    }
  ]
}
```

---

### Pieces Endpoints

#### GET /api/v2026/admin/pieces

**Query params**: `puzzleId` (required)

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "puzzleId": 1,
      "x": 0,
      "y": 0,
      "width": 1,
      "height": 1,
      "file": "puzzles/p1_0_0.cbz",
      "version": 1,
      "date": "2026-07-19",
      "order": 1
    }
  ]
}
```

---

### Music Endpoints

#### GET /api/v2026/admin/music

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": { "en": "Opening Theme", "ru": "Вступительная тема", "hi": "ओपनिंग थीम" },
      "author": { "en": "Composer A", "ru": "Композитор А", "hi": "संगीतकार ए" },
      "file": "music/track1.mp3",
      "order": 1
    }
  ]
}
```

---

### Quotes Endpoints

#### GET /api/v2026/admin/quotes

**Query params**: `status` (all | scheduled | published)

**Logic**:
```javascript
let query = supabase.from('quotes').select('*');

if (status === 'published') {
  query = query.or('publish_date.is.null,publish_date.lte.now()');
} else if (status === 'scheduled') {
  query = query.gt('publish_date', new Date().toISOString());
}
```

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "text": { "en": "Quote text", "ru": "Текст цитаты", "hi": "उद्धरण पाठ" },
      "image": { "en": "quotes/q1_en.jpg", "ru": "quotes/q1_ru.jpg", "hi": "quotes/q1_hi.jpg" },
      "publishDate": "2026-07-25T00:00:00Z",
      "status": "scheduled"
    }
  ]
}
```

#### PUT /api/v2026/admin/quotes/:id/publish

**Logic**: Set `publish_date = NOW()` to publish immediately.

---

### Devices Endpoints

#### GET /api/v2026/admin/devices

**Query params**: `platform` (ios | android), `page`, `limit`

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "platform": "ios",
      "osVersion": "17.0",
      "model": "iPhone 15",
      "appVersion": "2.0.0",
      "culture": "ru",
      "pushToken": "apns-token...",
      "lastModified": "2026-07-19T10:00:00Z"
    }
  ],
  "pagination": { "page": 1, "limit": 50, "total": 1234 }
}
```

#### GET /api/v2026/admin/devices/stats

**Query**:
```sql
SELECT
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE last_modified > NOW() - INTERVAL '30 days') as active_30_days,
  COUNT(*) FILTER (WHERE platform = 'android') as android,
  COUNT(*) FILTER (WHERE platform = 'ios') as ios
FROM devices;
```

**Response**:
```json
{
  "success": true,
  "data": {
    "total": 8542,
    "active30days": 2156,
    "byPlatform": { "android": 4500, "ios": 4042 }
  }
}
```

---

### Notifications Endpoint

#### POST /api/v2026/admin/notifications/send

**Request**:
```json
{
  "title": { "en": "New Episode!", "ru": "Новый эпизод!", "hi": "नया एपिसोड!" },
  "body": { "en": "Check it out", "ru": "Посмотрите", "hi": "इसे देखें" },
  "platform": "all"
}
```

**Logic** (`pushService.js`):
```javascript
// 1. Fetch device tokens by platform
const devices = await getDevicesWithPushTokens(platform);

// 2. Group by culture for localized messages
const byculture = groupBy(devices, 'culture');

// 3. Send via FCM (batch)
for (const [culture, devs] of Object.entries(byCulture)) {
  const message = {
    notification: {
      title: body.title[culture] || body.title.en,
      body: body.body[culture] || body.body.en
    },
    tokens: devs.map(d => d.push_token)
  };
  await admin.messaging().sendEachForMulticast(message);
}
```

**Response**:
```json
{
  "success": true,
  "data": { "sent": 1500, "failed": 23 }
}
```

---

### Files Endpoint

#### POST /api/v2026/admin/files/upload

**Request**: `multipart/form-data` with `file` and optional `folder`

**Logic**:
```javascript
// Using Supabase Storage
const filename = `${Date.now()}-${file.originalname}`;
const path = `${folder}/${filename}`;

const { data, error } = await supabase.storage
  .from('comics')
  .upload(path, file.buffer, {
    contentType: file.mimetype
  });
```

**Response**:
```json
{
  "success": true,
  "data": {
    "url": "seasons/1721347200-cover.jpg",
    "filename": "1721347200-cover.jpg"
  }
}
```

---

## Authentication Middleware

```javascript
// middleware/adminAuth.js
async function adminAuth(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');

  if (!token) {
    return adminError(res, 'Unauthorized', 401);
  }

  const { data: { user }, error } = await supabase.auth.getUser(token);

  if (error || !user) {
    return adminError(res, 'Invalid token', 401);
  }

  req.user = user;
  next();
}
```

---

## Validation

Using express-validator or Joi for request validation:

```javascript
const createSeasonSchema = Joi.object({
  name: Joi.object({
    en: Joi.string().required(),
    ru: Joi.string().allow(''),
    hi: Joi.string().allow('')
  }).required(),
  image: Joi.string().allow(null),
  product: Joi.string().allow(null),
  order: Joi.number().integer().min(1)
});
```

---

## Error Codes

| HTTP | Error | Description |
|------|-------|-------------|
| 400 | Validation error | Invalid request body |
| 401 | Unauthorized | Missing or invalid token |
| 404 | Not found | Resource doesn't exist |
| 409 | Conflict | Duplicate resource |
| 500 | Internal error | Server error |

---

## Approval

- [ ] Reviewed by: User
- [ ] Approved on:
- [ ] Notes:
