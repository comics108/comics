# Requirements: Comics Admin Panel

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-19

## Problem Statement

Необходима админ-панель для управления контентом приложения Comics (комиксы для детей). Существующая Flutter-админка `comics_admin` содержит код от bhagavadgita_admin и должна быть адаптирована под Comics API с сохранением архитектуры для унификации кодовых баз.

## Design Source

Макет: `/design/comics-admin-maket/Comics Admin (VPN DS).dc.html`

Визуальный стиль VPN Client Pro:
- Фон: #F8F9FA
- Карточки: белые, радиус 10px, мягкая тень
- Шрифт: Inter
- Градиент для primary actions: #00C6FB → #005BEA
- Разделение: белое пространство + hairline rgba(156,178,194,.1)

## User Stories

### Primary

**As an** Admin
**I want** to manage Comics content (seasons, episodes, puzzles, music, quotes)
**So that** users can access the latest content in the mobile app

### Secondary

**As an** Admin
**I want** to send push notifications
**So that** users are informed about new content

**As an** Admin
**I want** to preview content in mock mode without backend
**So that** I can test UI and workflow

## Screens (from mockup)

### N1 - Login
- Email/password input
- Login modes based on credentials:
  - `dev:dev` → dev backend (from .env)
  - `local:local` → local backend (from .env)
  - `maket:maket` → mock mode (no backend)
  - Other → prod backend

### N2 - Episodes List
- Filter by Season (dropdown)
- Drag-sortable list (reorder episodes)
- Columns: cover image, name, date, version, actions
- Add Episode button

### N3 - Episode Form
- Fields: name (localized en/ru/hi), image upload, episode file (.cbz) upload, date, version, product ID
- Linked to Season

### N4 - Notifications
- Send push notification form
- Title + body (localized)
- Target: all devices or specific platform

### N5 - Seasons List
- List with cover, name, product, episode count
- Drag-sortable
- Add Season button

### N6 - Season Form
- Fields: name (localized), image upload, product ID, order

### N7 - Puzzles List
- List with name, grid size (width x height), pieces count
- Drag-sortable
- Add Puzzle button

### N8 - Puzzle Form
- Fields: name (localized), width, height, order

### N9 - Pieces (Grid + List)
- Visual grid showing piece positions
- List of pieces with coordinates and status
- Add Piece button

### N10 - Piece Form
- Fields: x, y, width, height, image file, version, date, order

### N11 - Quotes List
- Status filter: All / Scheduled / Published
- Scheduled publishing (publish_date)
- List with quote text, status, publish date

### N12 - Quote Form
- Localized text (en/ru/hi)
- Localized images (en/ru/hi)
- Scheduled publish_date

### N13 - Music List
- List with name, author, file
- Drag-sortable

### N14 - Music Form
- Fields: name (localized), author (localized), audio file upload, order

### Responsive Views
- T1: iPad landscape - horizontal navigation bar
- P1-P3: Phone - cards layout, sticky save, drawer navigation

## Acceptance Criteria

### Must Have

1. **Given** admin enters valid credentials
   **When** they submit login form
   **Then** they are authenticated and redirected to Episodes list

2. **Given** admin is on Episodes list
   **When** they drag an episode row
   **Then** the order is updated via API and persisted

3. **Given** admin opens Episode form
   **When** they fill all required fields and submit
   **Then** the episode is created/updated via API

4. **Given** admin enters `maket:maket`
   **When** they login
   **Then** app loads with mock data without API calls

5. **Given** admin is editing localized content
   **When** they switch language tab
   **Then** they see/edit content for that language

6. **Given** admin uploads an image/file
   **When** upload completes
   **Then** preview is shown and URL is stored

7. **Given** admin sets publish_date for Quote
   **When** date is in future
   **Then** quote shows as "Scheduled" status

### Should Have

- Pagination for large lists
- Search/filter in lists
- Undo for drag-reorder
- Keyboard shortcuts for common actions

### Won't Have (This Iteration)

- Multi-select bulk operations
- Role-based access control
- Audit log

## Data Models (from comics_schema.sql)

### tokens + tokens_localized
- Localization system for all text content
- Cultures: en, ru, hi

### seasons
- id, name_token_id, image, product, order

### episodes
- id, season_id, name_token_id, image, file, version, product, date, order

### puzzles
- id, name_token_id, width, height, order

### pieces
- id, puzzle_id, x, y, width, height, file, version, date, order

### quotes
- id, name_token_id, image_token_id, publish_date

### music
- id, name_token_id, author_token_id, file, order

### devices
- Push notification targets

## Constraints

- **Technical**: Must maintain same Flutter architecture as bhagavadgita_admin
- **API**: Must work with v2026-admin endpoints (to be defined)
- **Platform**: Flutter Web primary, responsive for tablet/phone
- **Dependencies**: Requires backend API spec (sdd-comics-backend-endpoints-v2026-admin)

## Environment Configuration

```
# .env structure
API_URL_PROD=https://app.mbharata.com/api/v2026/admin
API_URL_DEV=https://dev.mbharata.com/api/v2026/admin
API_URL_LOCAL=http://localhost:3000/api/v2026/admin
```

Login credentials determine environment:
- `dev:dev` → API_URL_DEV
- `local:local` → API_URL_LOCAL
- `maket:maket` → Mock mode (no API)
- Other credentials → API_URL_PROD

## Open Questions

- [x] Localization languages: confirmed en, ru, hi
- [x] File storage: handled by /files/upload endpoint
- [ ] Push notification backend: same as bhagavadgita or different?

## References

- Design mockup: `/design/comics-admin-maket/Comics Admin (VPN DS).dc.html`
- DB schema: `db/comics_schema.sql`
- Current API spec: `apps/comics-backend/node/src/docs/v2026-admin.yaml`
- Reference admin: `apps/bhagavadgita_admin/`

---

## Approval

- [ ] Reviewed by:
- [ ] Approved on:
- [ ] Notes:
