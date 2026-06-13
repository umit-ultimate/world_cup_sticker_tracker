# Technical Stack

## Project Type

Personal iOS application for managing a Panini World Cup 2026 sticker album.

The application is not intended for:

- App Store publication
- Commercial usage
- Multi-user usage
- Enterprise-level scalability

---

## Platform

- iOS only

No Android, web, or desktop support is planned.

---

## Primary Development Approach

The project will be developed using vibe coding with:

- Claude
- Codex
- Antigravity

The user is not expected to manually implement most of the code.

Therefore, technical choices should prioritize:

- Simplicity
- Native iOS compatibility
- Low maintenance
- Fast delivery
- Minimal dependency risk

---

## UI Framework

- SwiftUI

Reasons:

- Native iOS framework
- Simple for small personal apps
- Good fit for fast screen development
- Works well with Apple OCR and camera features later

---

## Language

- Swift

---

## Architecture

- Lightweight MVVM

Rules:

- Keep ViewModels small.
- Avoid unnecessary abstraction.
- Do not introduce Clean Architecture, VIPER, Redux, TCA, or complex modular architecture.
- Prefer simple folders and direct implementation.

---

## Local Data Strategy

### Static Album Data

Use local JSON files for fixed album data.

Examples:

- Countries
- Country codes
- Album page numbers
- Sticker ranges
- Sticker metadata

Static JSON should be bundled with the application.

### User Album State

Use SwiftData for user-managed data.

Examples:

- Missing stickers
- Owned stickers
- Album setup completion state
- Quick check history
- OCR scan results in future phases

### Simple Settings

Use UserDefaults for simple app-level settings.

Examples:

- First launch completed
- Last opened screen
- Last selected country

---

## Persistence Decision

The application must work fully offline.

Use:

- Local JSON for static album data
- SwiftData for user album state
- UserDefaults for simple settings

Do not use:

- Supabase
- Firebase
- CloudKit
- REST APIs
- External database services

---

## Backend

None.

No backend service should be introduced unless explicitly requested later.

---

## Authentication

None.

No login, registration, user account, or session management.

---

## Cloud Sync

None.

No multi-device synchronization in the MVP.

---

## OCR Strategy

OCR is planned for a future phase.

Preferred OCR technology:

- Apple Vision Framework

OCR should be introduced only after the core manual workflow is working.

OCR phases:

1. Single sticker code recognition
2. Multiple sticker recognition from one image
3. Album page recognition

Do not implement OCR in Phase 1.

---

## Camera

Camera support is planned only for OCR-related future phases.

Do not add camera permissions or camera screens in Phase 1 unless explicitly requested.

---

## Networking

None.

The application must not depend on internet access.

---

## Third-Party Libraries

Avoid third-party libraries unless there is a clear and immediate benefit.

Prefer Apple native frameworks.

Allowed by default:

- SwiftUI
- SwiftData
- Vision
- AVFoundation
- Foundation

Avoid by default:

- Firebase
- Supabase
- Realm
- SQLite wrappers
- Analytics SDKs
- UI component libraries
- Networking libraries

---

## Data Ownership

All user data must stay on the device.

No data should be uploaded, synced, or shared externally.

---

## Testing Scope

Testing should be lightweight.

Recommended:

- Unit tests for album progress calculation
- Unit tests for missing sticker logic
- Unit tests for search and matching logic

Not required initially:

- UI automation
- Snapshot testing
- Performance testing

---

## Build Target

Use the latest stable iOS version supported by the user's local Xcode installation.

Avoid adopting very new APIs unless necessary.

---

## Development Priority

1. Working local app
2. Correct album and sticker data
3. Fast missing sticker workflow
4. Fast search and quick check
5. OCR later

---

## Explicit Non-Goals

Do not implement:

- Backend
- Supabase
- Firebase
- Authentication
- Cloud sync
- Push notifications
- Analytics
- Trading features
- Social sharing
- App Store monetization
- Complex architecture