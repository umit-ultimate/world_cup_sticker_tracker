# Agent Instructions

Read and follow this file before making any change.

This project is a personal iOS application for managing a Panini World Cup 2026 sticker album.

The goal is to deliver a simple, reliable, offline app quickly.

---

## Required Documents

Before implementing any feature, read the following documents in this order:

1. docs/PRODUCT.md
2. docs/ROADMAP.md
3. docs/DATA_MODEL.md
4. docs/TECH_STACK.md
5. docs/IMPLEMENTATION_RULES.md
6. docs/WORLD_CUP_2026_DATA.md

If a task conflicts with these documents, stop and explain the conflict before changing code.

---

## Development Principles

- Deliver working software quickly.
- Prefer the smallest working solution.
- Keep the app simple.
- Prefer native iOS solutions.
- Prefer maintainability over cleverness.
- Avoid unnecessary abstractions.
- Avoid premature optimization.
- Do not introduce features that are not explicitly requested.

---

## Technical Constraints

Use:

- Swift
- SwiftUI
- SwiftData
- UserDefaults
- Local JSON
- Apple native frameworks

Do not add:

- Backend
- Supabase
- Firebase
- CloudKit
- Authentication
- Networking
- Analytics
- Push notifications
- Third-party dependencies
- OCR or camera unless explicitly requested

---

## Data Rules

Static album data must come from bundled local JSON.

User album state must be local-only.

Current state model is missing-sticker-centered:

- Store missing sticker numbers per country.
- Do not store every owned sticker individually.
- All non-missing stickers are considered owned.

Backup files must use the existing JSON format unless explicitly changed.

---

## Safety Rules

Never delete or overwrite user album data unless the task explicitly says so.

Before any destructive action:

1. Create a backup if possible.
2. Ask for confirmation in the UI if the action is user-facing.
3. Make the destructive action visually clear.

Reset is destructive.

Edit Album must not be destructive.

Do not reintroduce Redo Setup behavior that clears album state automatically.

---

## UI Rules

Keep the UI simple and practical.

Primary screens:

- Dashboard
- Missing
- Check

Do not add new tabs unless explicitly requested.

Prioritize fast real-world use over visual polish.

---

## Implementation Rules

Before coding:

1. Inspect the relevant existing files.
2. Make a short implementation plan.
3. Apply minimal changes.

After coding:

1. Build the project if possible.
2. Summarize changed files.
3. Explain validation steps.
4. Mention assumptions or limitations.

---

## Current Product Priorities

1. Preserve user-entered album data.
2. Make backup/export/import reliable.
3. Make missing sticker lookup fast.
4. Make sticker checking fast.
5. Add OCR only in a later phase.