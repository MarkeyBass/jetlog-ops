---
name: scan-fixture
description: Fire a known EY fixture barcode at the live POST /api/scan and diff the response against its expected outcome from the Excel Checkup sheet. Use for "test a scan", "try a barcode", "is the API behaving", or smoke-checking after backend changes. Argument: fixture index (0-based), or "all".
---

Fixtures live in `server/tests/fixtures/barcodes.json` — real EY scans with known expected outcomes (`carrier`, `compartment`, `companyVar`, `ruleKey`, `approved`, …). $ARGUMENTS selects which one (default: `0`).

## Steps

1. **Find the API.** `curl http://localhost:8000/api/health` — port 8000 covers both the compose demo and the default dev server. If down, ask nothing: start the dev path yourself (`/db-reset` steps for pg, then `cd server && npm run dev` in the background) or tell the user to run `/demo`, whichever fits the session.
2. **Beware the date window.** Every fixture flies on 7 Jan; the global scan rules admit only today ±2 days (Israel), so on any other day each fixture comes back `FLIGHT_TOO_LONG_AGO` / `FLIGHT_TOO_FAR_AHEAD` — correct behavior, not a bug. To test the rule outcome, ask the user before widening it: `PATCH /api/global-rules/max_days_before_departure` and `…/max_days_after_departure` with `{ "value": "183" }` (the year is the one nearest today, so 183 admits any date), and restore `2` afterwards. Read `GET /api/global-rules` first and restore what was there.
3. **Beware dedup.** A fixture that was already approved today will return `DENIED — ALREADY_ENTERED` on re-scan. That is correct behavior, not a bug. If the goal is to re-test the rule outcome, clearing entries first is a deliberate, destructive step (`delete from entries` against the dev DB) — do it only with the user's explicit OK, and say so.
4. **Scan.** For each selected fixture: `POST /api/scan` with JSON body `{ "rawBarcode": "<exact string from the json>", "loungeId": <id> }` — `loungeId` is required: the id of an ACTIVE lounge, taken from `GET /api/lounges` (lounge `A`, seeded by migration `0008`, is normally id 1). Send the string byte-for-byte — BCBP is offset-sensitive; do not trim or re-wrap it.
5. **Compare.** Unwrap the `{ success, data }` envelope and diff the response against the fixture's `expected` block: `approved`, `ruleKey`, `carrier`, `compartment`, `companyVar`, plus `reasons` (an array of every reason, in the order pinned in `server/src/domain/denyReasons.ts`) when denied.

## Report

A table: fixture # | expected approved/ruleKey | actual | match?. Mismatches (other than an expected-approval turning into `ALREADY_ENTERED` or a `FLIGHT_TOO_*` denial outside the window) are findings for ts-backend-senior — report them, don't fix from here.
