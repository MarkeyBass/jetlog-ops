---
name: demo
description: Bring up the full JetLog demo (Postgres + API + operator UI) with one docker compose command, wait for health, and hand the user a smoke-test script with a real fixture barcode. Use for "run the demo", "start the app", "show it to the partner".
---

The demo stack is the root `docker-compose.yml`: `pg` (Postgres 18.6, commented out by default: uncomment it for a local demo) → `api` (migrates on start; no published port) → `web` (nginx, port 3000, the only way in: it passes `/api` to `api` inside Docker).

## Steps

1. `docker compose up --build -d` from the repo root. First build takes a few minutes — that's normal.
2. Wait for the API through nginx: poll `http://localhost:3000/api/health` (curl, up to ~90s; the api container migrates before listening). If it never comes up, show `docker compose logs api --tail 50` and stop. On an empty database, seed it and make an admin (`docker compose run --rm api npm run db:seed`, then `docker compose run --rm api npm run user:create-admin -- --username admin`, which asks the user for the password).
3. Confirm the UI answers on `http://localhost:3000` and tell the user to open it.
4. Hand the user a smoke script:
   - First pick the station's lounge in the header (`A` is seeded) — scanning is blocked until one is set.
   - **Open the date window first** — the fixtures fly on 7 Jan and the global rules admit only today ±2 days (Israel), so otherwise they're denied `FLIGHT_TOO_*`. Setting both limits to `183` admits any date (the year is the one nearest today); logged in as the admin, set **Days before the flight** and **Days after the flight** to `183` in **Global rules**, and put them back to `2` after the demo.
   - Paste the **first** `rawBarcode` from `server/tests/fixtures/barcodes.json` into the scan input, press Enter → expect **APPROVED**, rule `EY-#-#-LA-#-#`.
   - Scan it **again** → expect **DENIED — ALREADY_ENTERED** (dedup proof).
   - Approve a scan with guests, add a guest with another EY fixture → guest appears indented under the host in the entries table (the billing-attribution money shot).

## Teardown

- `docker compose down` keeps the data volume; `docker compose down -v` resets it — needed to re-demo the same barcodes, since dedup will deny them otherwise. Ask before using `-v` if there might be entries worth keeping.

If port 3000/5432 is already taken, `docker-compose.dev.yml`'s standalone `jetlog-pg` is the usual culprit — `docker compose -f docker-compose.dev.yml down` first.
