# Releases

## v1.0.0 — Stable Offline Version

Status: **Current**

Scope: Everything that ships locally, with no networking, no authentication, and no external services.

### What is included

- Static album catalog (49 countries, 980 stickers, bundled JSON)
- Album setup wizard with per-country missing sticker selection
- Edit Album (non-destructive re-entry of wizard)
- Dashboard with completion gauge, total / owned / missing counters
- Missing Stickers screen grouped by country with swipe-to-found
- Check / Search screen with single sticker lookup and bulk found update
- Mark sticker as found from both Check and Missing screens
- Backup export, share, and import with validation and safety backup
- Missing stickers JSON export
- OCR Test (photo-based Vision text recognition with album catalog validation)
- Live Scanner (AVFoundation + Vision, real-time NEEDED / Not Needed overlay)
- Scan Basket (SwiftData log of scanned stickers, export/import/insight)
- OCR normalization for common character misreads (IRQ, QAT)
- FWC special section (FIFA World Cup, page 1, 20 stickers)

### Architecture constraints for v1

- All user data stays on-device (SwiftData + UserDefaults + Documents folder)
- No networking, no CloudKit, no third-party dependencies
- Missing-sticker-centered data model (`CountryMissingState` keyed by country code)
- Static album data from bundled `album_data.json`

---

## v2.0.0 — Online Trade Network

Status: **Planned — not started**

Scope: Allow users to find trade partners for duplicate and missing stickers over a network.

### Planned additions

- User account / identity (sign in with Apple or equivalent)
- CloudKit or equivalent backend for trade listings
- Trade offer flow: list your duplicates, browse others' missing lists
- Match engine: show users who need what you have and have what you need
- Notification when a trade match is found
- Trade history

### Constraints for v2 planning

- v1 local data model must remain fully functional offline
- SwiftData schema changes require a migration strategy before v2 ships
- All v1 backup files must remain importable in v2
- CloudKit integration must not break the offline-first flow (app works without network)
- No v2 code should ship in v1 builds

### Migration notes

- `CountryMissingState` and `ScanBasketItem` SwiftData models will need CloudKit-compatible attributes (no non-optional relationships, no unique constraints incompatible with CKRecord)
- A separate `UserProfile` SwiftData model will be introduced for v2
- Trade data lives in CloudKit; local album state stays in the on-device SwiftData store

### What does NOT change in v2

- All v1 features remain available
- Local-only mode is still supported (user can decline sign-in)
- Backup / export / import format is unchanged
- OCR and live scanner work without network
