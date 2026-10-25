---
name: db-reset
description: Reset the dev database — start compose Postgres, run Drizzle migrations, reseed the 231 Excel rules, and verify the count. Use for "reset the db", "reseed the rules", or when integration tests / scans fail on DB state. Does NOT delete entries.
---

Dev DB runs from `docker-compose.dev.yml` (service `pg`, container `jetlog-pg`, credentials `jetlog/jetlog`, db `jetlog`, port 5432). Connection string: `postgres://jetlog:jetlog@localhost:5432/jetlog` — the server reads it from `DATABASE_URL` (see `server/.env` / `.env.example`).

## Steps

1. `docker compose -f docker-compose.dev.yml up -d pg`, then wait until `docker inspect -f "{{.State.Health.Status}}" jetlog-pg` says `healthy`.
2. Make sure `server/.env` exists with `DATABASE_URL`; if missing, copy from `.env.example` and fill the string above.
3. **Mark runs the migration himself** (agents never run `db:migrate`), so hand him `cd server && npm run db:migrate`, with a row-count check before and after. Then reseed with `cd server && npm run db:seed -- --force`.
   - The seed is guarded (`src/db/seedGuard.ts`). Without `--force` it only seeds an **empty** rules table, and it skips a non-empty one (nothing changes).
   - `--force` replaces the table in one transaction: delete everything, then insert from `src/db/seed-data/rules.json`. This drops rules added by hand.
   - It **refuses** with `NODE_ENV=production`, and on a **locked** database (`deployment_state.locked`) whatever the flags. A refusal changes nothing.
   - **Never use this skill against production**, and never try to get around a refusal. If it says "LOCKED", stop and tell Mark.
4. Verify: `docker exec jetlog-pg psql -U jetlog -d jetlog -c "select count(*) from rules;"` — must print **231**. Also report the current `entries` count.

**This skill never deletes `entries`.** It reseeds `rules` only (via `db:seed`). Wiping the movements log is a deliberate, destructive act, not part of a routine reset — if the user explicitly asks for a fresh/empty `entries` table, do it as a separate, clearly-announced manual step (`delete from entries` against the **dev** DB) and confirm first. Never bundle it into a reset.

Never edit migration files or seed JSON from this skill — schema/seed changes belong to ts-backend-senior with a generated migration.
