# Roadmap

## Phase 1 - MVP Foundation

Goal: Create a usable offline iOS app for managing a Panini World Cup 2026 album.

### Phase 1A - Static Album Catalog

Completed

- Bundled local JSON catalog
- Country model
- Album catalog loader
- Dynamic sticker generation
- Country and sticker statistics

### Phase 1B - Album Setup Wizard

Completed

- Country-by-country setup flow
- Missing sticker selection
- Persist missing stickers locally
- Edit existing album setup

### Phase 1C - Dashboard

Completed

Display:

- Total stickers
- Owned stickers
- Missing stickers
- Completion percentage

### Phase 1D - Missing Stickers

Completed

- Group missing stickers by country
- Show country page information
- Fast review of missing stickers

### Phase 1E - Search & Check

Completed

Search by:

- Sticker code
- Country code
- Country name

Display:

- Country
- Page
- Sticker status
- Needed / Not Needed

### Phase 1F - Backup & Recovery

Completed

- Export backup
- Share backup
- Import backup
- Recovery from backup
- Validation of imported data
- Safety backup before destructive actions

---

## Phase 2 - Daily Usage Optimization

Goal: Make everyday album maintenance extremely fast.

### Phase 2A - Mark Sticker As Found

Completed

- Mark missing sticker as found from Check screen
- Mark missing sticker as found from Missing screen
- Automatic backup update
- Automatic dashboard refresh

### Phase 2B - Bulk Found Update

Planned

Goal:

Process newly opened sticker packs quickly.

Features:

- Paste multiple sticker codes
- Preview valid stickers
- Detect invalid stickers
- Detect already owned stickers
- Apply updates in bulk
- Automatic backup update

Example:

TUR 04
GER 06
ENG 12
JPN 03

### Phase 2C - UX Improvements

Backlog

Possible improvements:

- Country filters
- Country sorting
- Most missing countries
- Progress by country
- Better statistics
- Timestamped backups

---

## Phase 3 - Live OCR Scanner

Goal: Detect needed stickers directly from physical stickers.

### Phase 3A - Live Single Sticker Scanner

Planned

Features:

- Live camera feed
- Scan sticker back side
- Detect country code and sticker number
- Parse formats such as:
  - TUR 04
  - GER 17
  - AUT 20
- Match against missing list
- Show Needed / Not Needed
- Sound notification
- Haptic feedback
- Duplicate scan cooldown

Workflow:

1. User points camera at sticker back side.
2. App detects sticker code.
3. App checks album status.
4. App immediately indicates whether the sticker is needed.

### Phase 3B - Live Multi Sticker Scanner

Planned

Features:

- Detect multiple stickers in camera view
- Show all detected codes
- Highlight needed stickers
- Real-time updates

### Phase 3C - Scanner Assisted Update

Planned

Features:

- Mark found stickers directly from scanner results
- Bulk update from scanner session
- Optional confirmation flow

---

## Phase 4 - Advanced Recognition

Backlog

### Phase 4A - Album Page Recognition

Goal:

Detect missing stickers directly from album pages.

Features:

- Scan album pages
- Detect empty slots
- Suggest album updates

This phase is experimental and not required for normal app usage.

### Phase 4B - Front Side Sticker Recognition

Goal:

Identify stickers using the sticker front side.

Features:

- Player recognition
- Team recognition
- Mapping player to sticker code

This phase is significantly more complex than back-side OCR and has lower priority.