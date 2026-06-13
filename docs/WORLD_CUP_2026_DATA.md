# World Cup 2026 Album Data

## Purpose

This document describes the static album data used by the application.

The data will be converted into a bundled JSON file inside the iOS app.

The app should not ask the user to scan or enter this static album structure.

---

## Data Source

The album index page provides:

- Country code
- Country name
- Album page
- Group

Country pages show that each country uses sticker numbers from 1 to 20.

Therefore, each country can be represented with:

json {   "code": "TUR",   "name": "Turkey",   "page": 38,   "group": "D",   "stickerCount": 20 } 

---

## Sticker Numbering Rule

For each country:

text 1 to 20 

Examples:

text TUR 01 TUR 02 ... TUR 20 

text GER 01 GER 02 ... GER 20 

---

## Known Countries From Album Index

json [   { "id": "mex", "code": "MEX", "name": "Mexico", "page": 8, "group": "A", "stickerCount": 20 },   { "id": "rsa", "code": "RSA", "name": "South Africa", "page": 10, "group": "A", "stickerCount": 20 },   { "id": "kor", "code": "KOR", "name": "Korea Republic", "page": 12, "group": "A", "stickerCount": 20 },   { "id": "cze", "code": "CZE", "name": "Czechia", "page": 14, "group": "A", "stickerCount": 20 },    { "id": "can", "code": "CAN", "name": "Canada", "page": 16, "group": "B", "stickerCount": 20 },   { "id": "bih", "code": "BIH", "name": "Bosnia-Herzegovina", "page": 18, "group": "B", "stickerCount": 20 },   { "id": "qat", "code": "QAT", "name": "Qatar", "page": 20, "group": "B", "stickerCount": 20 },   { "id": "sui", "code": "SUI", "name": "Switzerland", "page": 22, "group": "B", "stickerCount": 20 },    { "id": "bra", "code": "BRA", "name": "Brazil", "page": 24, "group": "C", "stickerCount": 20 },   { "id": "mar", "code": "MAR", "name": "Morocco", "page": 26, "group": "C", "stickerCount": 20 },   { "id": "hai", "code": "HAI", "name": "Haiti", "page": 28, "group": "C", "stickerCount": 20 },   { "id": "sco", "code": "SCO", "name": "Scotland", "page": 30, "group": "C", "stickerCount": 20 },    { "id": "usa", "code": "USA", "name": "USA", "page": 32, "group": "D", "stickerCount": 20 },   { "id": "par", "code": "PAR", "name": "Paraguay", "page": 34, "group": "D", "stickerCount": 20 },   { "id": "aus", "code": "AUS", "name": "Australia", "page": 36, "group": "D", "stickerCount": 20 },   { "id": "tur", "code": "TUR", "name": "Turkey", "page": 38, "group": "D", "stickerCount": 20 },    { "id": "ger", "code": "GER", "name": "Germany", "page": 40, "group": "E", "stickerCount": 20 },   { "id": "cuw", "code": "CUW", "name": "Curaçao", "page": 42, "group": "E", "stickerCount": 20 },   { "id": "civ", "code": "CIV", "name": "Cote d’Ivoire", "page": 44, "group": "E", "stickerCount": 20 },   { "id": "ecu", "code": "ECU", "name": "Ecuador", "page": 46, "group": "E", "stickerCount": 20 },    { "id": "ned", "code": "NED", "name": "Netherlands", "page": 48, "group": "F", "stickerCount": 20 },   { "id": "jpn", "code": "JPN", "name": "Japan", "page": 50, "group": "F", "stickerCount": 20 },   { "id": "swe", "code": "SWE", "name": "Sweden", "page": 52, "group": "F", "stickerCount": 20 },   { "id": "tun", "code": "TUN", "name": "Tunisia", "page": 54, "group": "F", "stickerCount": 20 },    { "id": "bel", "code": "BEL", "name": "Belgium", "page": 58, "group": "G", "stickerCount": 20 },   { "id": "egy", "code": "EGY", "name": "Egypt", "page": 60, "group": "G", "stickerCount": 20 },   { "id": "irn", "code": "IRN", "name": "IR Iran", "page": 62, "group": "G", "stickerCount": 20 },   { "id": "nzl", "code": "NZL", "name": "New Zealand", "page": 64, "group": "G", "stickerCount": 20 },    { "id": "esp", "code": "ESP", "name": "Spain", "page": 66, "group": "H", "stickerCount": 20 },   { "id": "cpv", "code": "CPV", "name": "Cabo Verde", "page": 68, "group": "H", "stickerCount": 20 },   { "id": "ksa", "code": "KSA", "name": "Saudi Arabia", "page": 70, "group": "H", "stickerCount": 20 },   { "id": "uru", "code": "URU", "name": "Uruguay", "page": 72, "group": "H", "stickerCount": 20 },    { "id": "fra", "code": "FRA", "name": "France", "page": 74, "group": "I", "stickerCount": 20 },   { "id": "sen", "code": "SEN", "name": "Senegal", "page": 76, "group": "I", "stickerCount": 20 },   { "id": "irq", "code": "IRQ", "name": "Iraq", "page": 78, "group": "I", "stickerCount": 20 },   { "id": "nor", "code": "NOR", "name": "Norway", "page": 80, "group": "I", "stickerCount": 20 },    { "id": "arg", "code": "ARG", "name": "Argentina", "page": 82, "group": "J", "stickerCount": 20 },   { "id": "alg", "code": "ALG", "name": "Algeria", "page": 84, "group": "J", "stickerCount": 20 },   { "id": "aut", "code": "AUT", "name": "Austria", "page": 86, "group": "J", "stickerCount": 20 },   { "id": "jor", "code": "JOR", "name": "Jordan", "page": 88, "group": "J", "stickerCount": 20 },    { "id": "por", "code": "POR", "name": "Portugal", "page": 90, "group": "K", "stickerCount": 20 },   { "id": "cod", "code": "COD", "name": "Congo DR", "page": 92, "group": "K", "stickerCount": 20 },   { "id": "uzb", "code": "UZB", "name": "Uzbekistan", "page": 94, "group": "K", "stickerCount": 20 },   { "id": "col", "code": "COL", "name": "Colombia", "page": 96, "group": "K", "stickerCount": 20 },    { "id": "eng", "code": "ENG", "name": "England", "page": 98, "group": "L", "stickerCount": 20 },   { "id": "cro", "code": "CRO", "name": "Croatia", "page": 100, "group": "L", "stickerCount": 20 },   { "id": "gha", "code": "GHA", "name": "Ghana", "page": 102, "group": "L", "stickerCount": 20 },   { "id": "pan", "code": "PAN", "name": "Panama", "page": 104, "group": "L", "stickerCount": 20 } ] 

## Notes

- The album mentions that final data may depend on qualified teams and play-offs.
- If the physical album changes or later pages reveal exceptions, this file must be updated.
- Current model assumes each country has 20 stickers.