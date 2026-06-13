# Data Model

## Core Decision

The application uses a missing-sticker-centered data model.

The user does not need to track every owned sticker individually.

Instead, for each country, the user marks only missing sticker numbers.

All non-missing stickers are automatically considered owned.

This matches the real album workflow and keeps the app simple.

---

## Static Album Data

Static album data is bundled with the app as local JSON.

This data does not change during normal app usage.

### Country

swift struct Country: Identifiable, Codable, Hashable {     let id: String     let code: String     let name: String     let page: Int     let group: String     let stickerCount: Int } 

Example:

json {   "id": "tur",   "code": "TUR",   "name": "Turkey",   "page": 38,   "group": "D",   "stickerCount": 20 } 

---

## Generated Sticker Data

Individual sticker records do not need to be stored in JSON.

They are generated at runtime from country data.

Example:

text TUR 1 TUR 2 ... TUR 20 

Sticker display format:

text TUR 01 ENG 07 GER 20 

---

## User Album State

User-specific album progress is stored locally.

### CountryMissingState

swift struct CountryMissingState {     let countryCode: String     var missingNumbers: [Int] } 

Example:

json {   "countryCode": "TUR",   "missingNumbers": [4, 17, 19, 20] } 

---

## Album Setup Logic

During setup:

1. User selects a country.
2. App displays sticker numbers from 1 to stickerCount.
3. User selects only missing stickers.
4. App stores selected numbers as missing.
5. All other numbers are considered owned.

---

## Computed Sticker Status

A sticker is missing when:

text stickerNumber exists in missingNumbers for that country 

A sticker is owned when:

text stickerNumber does not exist in missingNumbers for that country 

---

## Computed Metrics

The app calculates:

- Total countries
- Total stickers
- Total missing stickers
- Total owned stickers
- Completion percentage

### Formula

text totalStickers = sum(country.stickerCount) missingStickers = sum(all missingNumbers.count) ownedStickers = totalStickers - missingStickers completionPercentage = ownedStickers / totalStickers 

---

## Search Logic

Search must support:

- Country code
- Country name
- Sticker code

Examples:

text TUR Turkey TUR 04 GER 20 

Search result should display:

- Country name
- Country code
- Album page
- Sticker number, if applicable
- Missing or owned status

---

## Persistence

Use:

- Local JSON for static country data
- SwiftData for user album state
- UserDefaults for simple flags

Do not use:

- Supabase
- Firebase
- Cloud database
- Backend API