---
name: verify
description: Run the full JetLog quality gate — server Vitest tests, server lint, client Vitest tests, client lint and type-build — and report a single pass/fail verdict with failures explained. Use before opening or updating a phase PR, or whenever asked "do the tests pass" / "is it green".
---

Run the whole gate even if an early step fails — the user wants the complete picture, not the first error.

## Steps

1. **Server tests:** `cd server && npm test`.
   - Unit tests must pass with no prerequisites.
   - Integration tests need compose Postgres. If they fail with connection errors, check `docker ps` for the `jetlog-pg` container; if it's down, report them as *skipped (pg not running — start with /db-reset)*, not as failures.
2. **Server lint:** `cd server && npm run lint` (eslint + prettier check).
3. **Client tests:** `cd client && npm test` (Vitest, unit — the pure `lib/` modules; no DB, always safe).
4. **Client lint:** `cd client && npm run lint`.
5. **Client typecheck:** `cd client && npm run build` — the `tsc -b` step is the client's only typecheck; a Vite build error counts as a failure too.

## Report format

One line per step: ✅ / ❌ / ⏭️ skipped, with counts (e.g. "27 tests, 27 passed"). Then, only for failures: the failing test/file, the actual error, and which agent owns the fix (server → ts-backend-senior, client → react-frontend-senior). End with a single verdict: **ready for PR** or **not ready**.

Do not fix anything from this skill — verification only.
