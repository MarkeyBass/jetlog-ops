> **HISTORICAL — frozen, kept for the record. Do not follow or edit it.** This is the POC's six-phase plan and its decision log. Superseded by [PLAN.md](../PLAN.md); standing decisions now go in [DECISIONS.md](../DECISIONS.md) — do not append to the log below. Moved to `docs/archive/` on 2026-10-14; links inside may point at old paths.

# JetLog POC — Phase Plan & Stacked-PR Workflow

> **HISTORICAL — the POC phase plan.** All six phases are complete. The stacked-PR workflow and phase checklists below describe how the POC was built and are kept for the record. **The one part of this file that stays live is the [Decision log](#decision-log)** — it is append-only and remains the project's single log (add entries with `/decision`). For the current architecture and direction see [`HANDOFF.md`](HANDOFF.md) and [`../CLAUDE.md`](../CLAUDE.md).

**Source of truth for scope:** [POC_Architecture.md](../POC_Architecture.md). This file breaks that brief into 6 small, sequentially-stacked phases. When the two disagree, POC_Architecture.md wins — flag the conflict, don't silently pick.

**Business spec (background reading only):** [IsraJet_Lounge_Entry_Spec_v2.md](../IsraJet_Lounge_Entry_Spec_v2.md). Do not pull Phase-1 features from it into the POC — the deferred list in POC_Architecture.md §9 is binding.

**Proven logic reference:** `JetLog_v11_DEMO.xlsm` — Vlad's Excel. Relevant sheets:
- `Checkup` — real scanned EY barcodes with known expected outcomes → **test fixtures**
- `Rules` — the rule rows to seed (`EY ##LA#` etc.)
- `ConditionalFieldParsing` — the `LET` offset-walk formula for the airline user field (companyVar)
- `Samples`, `Encoding-compartment`, `Encoding-FFP` — encoding references

**Code-style reference:** `../cicada-vite-green/server` (sibling directory, JS + Mongoose). We port its *shape* to TypeScript + Drizzle/Postgres — see Conventions below. Do not copy Mongo/Mongoose, socket, Stripe, or auth code.

---

## The PR stack

Six PRs, one per phase, each branched off the previous one:

| # | Branch | Base | One-liner |
|---|--------|------|-----------|
| 1 | `feat/phase-1-scaffold` | `main` | TS Express skeleton, tooling, health endpoint, error pipeline |
| 2 | `feat/phase-2-db-drizzle` | phase-1 | docker-compose Postgres, Drizzle schema + migrations, rules seed |
| 3 | `feat/phase-3-bcbp-domain` | phase-2 | BCBP parse, companyVar, rule matcher, dedup key — pure functions + fixture tests |
| 4 | `feat/phase-4-scan-api` | phase-3 | `/api/scan`, `/api/entries`, `/api/rules`, guest flow, integration tests |
| 5 | `feat/phase-5-frontend` | phase-4 | React operator screen: scan → result → guest loop + entries table |
| 6 | `feat/phase-6-demo-polish` | phase-5 | Full compose, seed-on-up, demo README, partner handoff doc |

**Why stacked:** each PR's diff shows only its own phase (GitHub diffs against the base branch), so Mark never re-reviews earlier code.

### Rules of the stack

- Build phases **in order**. Finish a phase (tests green, PR open) before starting the next.
- Open each PR with `gh pr create --base <previous-branch>` — never base on `main` except phase 1.
- **Do not merge PRs.** Mark reviews and merges bottom-up (1 → 6). After a merge, the next PR's base is retargeted to `main` (automatic if the branch is deleted on merge, otherwise edit the PR base).
- **Change requests on an earlier PR:** fix on that branch, then rebase every higher branch in order:
  ```bash
  git checkout feat/phase-3-bcbp-domain
  git rebase feat/phase-2-db-drizzle
  git push --force-with-lease
  # repeat upward, in order
  ```
  Always `--force-with-lease`, never `--force`. After any force-push, re-verify the PR diff shows only that phase.
- Every PR body: what the phase delivers, how to run its tests, and the stack table above with the current PR marked.
- Conventional-ish commits, small and topical. No drive-by refactors of earlier phases inside a later phase's branch.

---

## Conventions (cicada shape, TypeScript idiom)

Repo layout: `server/` + `client/` at repo root (like cicada).

```
server/
  src/
    index.ts          # listen() only
    app.ts            # express app assembly (importable by tests)
    config/           # env loading (dotenv), typed config object
    routes/           # express.Router wiring only — no logic
    controllers/      # HTTP layer: validate input, call service, shape response
    services/         # business rules (scan pipeline, rule matching)
    domain/           # pure functions: bcbp parse, ruleKey, uniqKey, companyVar
    db/               # drizzle client, schema.ts, migrations/, seed.ts
    middleware/       # asyncHandler, errorHandler
    utils/            # ErrorResponse, helpers
    types/            # shared DTOs (also consumed conceptually by client)
  tests/
    unit/             # domain/ + services/ — no DB, no HTTP
    integration/      # supertest against app + real compose Postgres
    fixtures/         # barcodes.json extracted from Excel Checkup sheet
```

- **Response envelope:** `{ success: true, data }` on success; errors flow through `next(new ErrorResponse(message, statusCode))` → central `errorHandler` → `{ success: false, error }`. (Direct cicada port.)
- **Controller headers:** keep cicada's `@desc / @route / @access` comment block on every controller.
- **asyncHandler** wraps every async controller (port of cicada `middleware/async.js`).
- **Layering:** routes wire, controllers do HTTP, services own business rules and transactions, `domain/` stays pure (no I/O — this is what unit tests hit). No SQL in controllers.
- **Drizzle:** schema in `db/schema.ts` mirrors POC_Architecture.md §3 exactly (`rules`, `entries`). Migrations via `drizzle-kit generate` + committed SQL. `allowed_guests` is `integer` — that's the deliberate upgrade over Excel's text.
- **TypeScript:** `strict: true`, no `any` in domain/services (controllers may narrow `unknown` request bodies). ESM. Dev runner: `tsx watch`.
- **Tests:** Vitest + supertest. Unit tests must not need Docker; integration tests document `docker compose up pg` as a prerequisite.
- **No auth, no SSE, no queues** — POC_Architecture.md §9 deferred list is binding.

---

## Phase 1 — Scaffold (`feat/phase-1-scaffold` ← `main`)

**Goal:** a running, testable TS Express skeleton with the error pipeline in place. No DB, no domain logic.

- [ ] `server/package.json` — express, dotenv, cors, morgan; dev: typescript, tsx, vitest, supertest, eslint, prettier, drizzle deps deferred to phase 2
- [ ] `tsconfig.json` (strict, ESM, NodeNext), eslint + prettier config
- [ ] `src/app.ts` (json body, cors, morgan dev, routes mount, errorHandler last) / `src/index.ts` (listen)
- [ ] `src/config/` — dotenv load + typed `config` object (`PORT`, later `DATABASE_URL`); `.env.example`
- [ ] `middleware/asyncHandler.ts`, `middleware/errorHandler.ts`, `utils/ErrorResponse.ts` — cicada ports
- [ ] `GET /api/health` route/controller pair demonstrating the envelope
- [ ] Vitest + supertest smoke test: health returns `{ success: true, data: { status: "ok" } }`; unknown route → 404 envelope
- [ ] npm scripts: `dev`, `build`, `start`, `test`, `lint`
- [ ] Root `README.md` stub: what this is, how to run server tests

**Acceptance:** `npm run dev` serves health; `npm test` green; thrown `ErrorResponse` produces correct status + envelope.

---

## Phase 2 — Database & seed (`feat/phase-2-db-drizzle` ← phase-1)

**Goal:** Postgres up via compose, schema migrated, rules seeded from the Excel.

- [x] `docker-compose.dev.yml` — `pg` service (postgres:16, volume, healthcheck), port 5432
- [x] Drizzle: `src/db/schema.ts` with `rules` + `entries` exactly per POC_Architecture.md §3 (incl. `host_entry_id` self-reference, `uniq_key`, defaults)
- [x] `drizzle.config.ts` + first generated migration committed (`0000_bumpy_toro.sql`)
- [x] `src/db/client.ts` — lazy pg Pool + drizzle instance, driven by `DATABASE_URL`
- [x] `src/db/seed.ts` — idempotent seed (transaction: delete-all + insert). Seeds the **full** Excel `Rules` sheet (231 rows, all carriers) transcribed into `src/db/seed-data/rules.json`, generated by a script from the xlsm — not invented. See decision log.
- [x] npm scripts: `db:generate`, `db:migrate`, `db:seed`
- [x] README section: bring up pg, migrate, seed

**Acceptance:** ✅ verified — migrate → seed → `select count(*) from rules` = 231; re-running seed stays at 231 (no duplication); both tables + self-FK present. (Verified against a local Postgres 16/17 instance, as Docker image pull was unavailable in the build sandbox.)

---

## Phase 3 — BCBP domain core (`feat/phase-3-bcbp-domain` ← phase-2)

**Goal:** the proven Excel logic as pure, unit-tested TypeScript. No HTTP, no DB writes.

- [x] `tests/fixtures/barcodes.json` — 10 real EY barcodes from the xlsm `Checkup` sheet with their known outcomes (8 approved `EY ##LA#`, 2 denied `EY ####`), extracted by a script (kept out of the repo). Names were already redacted in the source; the extractor also re-pads the fixed-width name field on 2 rows the redaction had shortened (see decision log).
- [x] `src/domain/parseBoardingPass.ts` — wraps `bcbp` decode; `legs[0]` only (M2 → ignore leg 2); typed `ParsedLeg`; `origin !== 'TLV'` → non-blocking `warning`; malformed → `BoardingPassParseError`
- [x] `src/domain/companyVar.ts` — reads `leg.airlineInfo` (the `bcbp` lib exposes the airline-use field directly). Verified equal to the Excel `LET` offset-walk output on every fixture (LA/N); the offset-walk fallback was **not needed** — see decision log.
- [x] `src/domain/ruleKey.ts` — per-carrier value-set wildcard collapse → `ruleKey`; `matchRule()` over an in-memory rules list
- [x] `src/domain/uniqKey.ts` — `julianDay-carrier-flightNumber-sequenceNumber-origin`
  (julianDate later renamed to be ordinalDate)
- [x] Unit tests (29 total): all 10 fixtures reproduce parse fields + ruleKey + decision + uniqKey; M2 leg selection; M1 single leg; TLV warning (spliced); malformed throws; wildcard collapse incl. inactive-rule exclusion; uniqKey stability

**Acceptance:** ✅ all `Checkup` fixtures reproduce (`EY ##LA#` → LOUNGE ACCESS approved; `EY ####` → denied). `domain/` has no `db/` imports (rule tests use the seed JSON as an in-memory list).

---

## Phase 4 — Scan API & guest flow (`feat/phase-4-scan-api` ← phase-3)

**Goal:** the three endpoints, wired end-to-end against Postgres.

- [x] `services/rulesService.ts` — load active rules (drizzle); `listActiveRules()` DTO for the read endpoint
- [x] `services/scanService.ts` — pipeline: parse → dedup lookup (`uniq_key` + approved) → rule/guest decision → insert entry → response DTO. Guest path: `hostEntryId` → same parse/dedup, POC guest rule = same carrier as host, `is_guest = true`, linked via `host_entry_id`. Deny reasons as constants (`ALREADY_ENTERED`, `NO_MATCHING_RULE`, `GUEST_CARRIER_MISMATCH`). Denied scans are **also logged** (`approved = false`).
- [x] `services/entriesService.ts` — 50 most recent hosts, guests nested underneath
- [x] `POST /api/scan` — `{ rawBarcode, hostEntryId? }` → §5 response; input validation (400) + parse errors (400 via errorHandler) + missing host (404)
- [x] `GET /api/entries` — recent hosts, guests nested
- [x] `GET /api/rules` — active rules, read-only
- [x] Shared response DTO types in `src/types/dto.ts`
- [x] Integration tests (supertest + pg): approve, `ALREADY_ENTERED` rescan, `NO_MATCHING_RULE` deny (+logged), guest approve + host link + nesting, `GUEST_CARRIER_MISMATCH`, 404 host-not-found, 400 empty/malformed, rules listing

**Acceptance:** ✅ 37 tests green (8 integration against Postgres); verified live via curl — primary approve → guest scan → `GET /api/entries` shows the guest nested under the host via `host_entry_id` (the money shot). Non-TLV warning is covered by the Phase-3 parse unit test; all real fixtures depart TLV so there's no non-TLV integration case.

---

## Phase 5 — Operator frontend (`feat/phase-5-frontend` ← phase-4)

**Goal:** the one-screen React operator UI, three states.

- [x] `client/` — Vite + React + TS scaffold; dev proxy `/api` → server; eslint + prettier aligned with server
- [x] `api/` client module (`client.ts` + `types.ts`) mirroring server DTOs; unwraps the envelope
- [x] **Scan state:** large auto-focused input (wedge / paste / manual, Enter submits) + "use camera" toggle → `html5-qrcode` (PDF417 + QR/Aztec); both paths call the same `onSubmit`
- [x] **Result state:** APPROVED (green) / DENIED (red + reason) card — description, parsed fields, warning banner; guest-count prompt (0–N) when `allowedGuests > 0`
- [x] **Guest state:** client-state session (one `useReducer`) — "Scan guest _n_ of _N_", per-guest result, Done → back to scan
- [x] Entries table (from `GET /api/entries`), guests indented under host; refreshes after each scan
- [x] Plain readable CSS; English only; no router, no state library

**Acceptance:** ✅ verified live in-browser against the running backend + Postgres — pasted an EY fixture → APPROVED card (`EY ##LA#`, LOUNGE ACCESS) → picked 1 guest → scanned a 2nd EY pass → **guest rendered indented under the host** in the table; denied fixture → red DENIED card ("No matching entry rule", `EY ####`) and a red row in the log. No console errors. (Camera path is wired but not driven headlessly — the wedge/paste path is the prod-like one.)

---

## Phase 6 — Demo packaging (`feat/phase-6-demo-polish` ← phase-5)

**Goal:** one-command demo + reviewer handoff.

- [x] `docker-compose.yml` (full): `web` (nginx-served Vite build, proxies `/api`), `api` (migrate + seed on start), `pg`; server/client Dockerfiles + `.dockerignore` + `nginx.conf`
- [x] README: one-command demo, demo script with the exact barcodes to paste and expected result at each step, troubleshooting (ports, camera, DB race)
- [x] `docs/PARTNER_HANDOFF.md` — reviewer guide: PR stack table, review/merge order, rebase-chain instructions, conventions checklist, key product decisions, deferred list
- [ ] ~~Optional `terraform/` EC2~~ — not requested; skipped per plan (prod target is the client's own infra)

**Acceptance:** ✅ `docker compose up --build` from a clean checkout → pg healthy, api migrated + seeded 231 rules (production mode), web serves the UI on :3000 and proxies `/api`; verified a scan through the nginx proxy returns approved `EY ##LA#` LOUNGE ACCESS. Full stack built and run in the sandbox.

---

## Decision log

| Date | Decision | Why |
|---|---|---|
| 2026-07-17 | Drizzle ORM over raw pg / Knex | Mark's call — typed schema, drizzle-kit migrations |
| 2026-07-17 | 6 stacked PRs | Mark prefers reviewing small pieces |
| 2026-07-17 | Planning docs + agents committed to `main` before the build run | Phase branches all build on them; PR 1 diff stays pure scaffold |
| 2026-07-17 | Denied scans are logged as entries (`approved = false`) | Movements log should reflect attempts; cheap in POC, matches spec direction |
| 2026-07-17 | Seed data transcribed from Excel `Rules` sheet into checked-in JSON | Reviewable, re-runnable, no xlsm parsing at runtime |
| 2026-07-17 | Seed the **full** Rules sheet (231 rows, all carriers) not just EY+BA | It's all real proven data; extracted by script and self-verified (every row's columns reconstruct its `rule_key`); makes the Phase-3 matcher demonstrably correct against the whole ruleset at zero extra cost. `AllowedGuests` derived from the text `AllowedQty` (Passenger=0, +Guest=1, +NGuest=N). |
| 2026-07-17 | Drizzle bumped to `^0.45.2` / drizzle-kit `^0.31.10` | Avoids the high-severity SQLi advisory (GHSA-gpj5-g38j-94v9) in drizzle-orm <0.45.2. Remaining 4 moderate advisories are a dev-only transitive esbuild in drizzle-kit's bundled loader (not in the runtime path). |
| 2026-07-17 | companyVar read from `bcbp`'s `leg.airlineInfo`; Excel offset-walk fallback dropped | The `bcbp` library already parses the airline-use conditional field. Verified it equals the Excel `LET`-formula output on all 10 real fixtures (LA on approved, N on denied). Porting the offset walk would have added untested complexity for zero behavioral gain. A future fallback can be added if a real EY pass ever lacks `airlineInfo`. |
| 2026-07-17 | Fixtures re-pad the fixed-width name field on 2 barcodes | Manual name redaction (`******`) in the source xlsm shortened 2 rows by 1–2 chars, shifting leg-1 origin off the BCBP standard offset 30 and breaking any standards parser. A real scanner never emits this. The extractor restores the 20-char name field (leg-1 `TLV` back at offset 30); all other bytes and every expected outcome are untouched. |
| 2026-07-17 | uniqKey uses trimmed fields (`007-EY-0594-0062-TLV`) | Functionally identical to the Excel's space-padded `uniqbcbp` (`007-EY -0594 -0062 -TLV`); the fixtures assert equality after stripping the padding whitespace. |
| 2026-07-17 | Deny reason lives in the scan **response**, not on the `entries` row | Keeps the `entries` schema exactly as §3 (no `reason` column). The operator sees the reason immediately; the historical log shows `approved = false`. Adding a reason column would be a schema change for marginal log value. |
| 2026-07-17 | Missing host on a guest scan → HTTP 404, not a logged denial | `host_entry_id` is a FK; you can't log a guest entry without a valid host. A bad host id is a client error, so it returns 404 rather than writing a row. |
| 2026-07-17 | Dedup check-then-insert is not wrapped in a locking transaction | Single-operator POC (one PC, one tab); the race window is irrelevant. A real deployment would use a unique index or `SELECT … FOR UPDATE`. Noted for Phase 1 proper. |
| 2026-07-17 | `api` runs migrate + seed via its compose `command` (not a baked entrypoint) | Keeps the Dockerfile generic and the demo self-provisioning: a fresh volume is migrated + seeded on `up`. `depends_on: service_healthy` gates it on Postgres readiness. |
| 2026-07-17 | Production API image keeps dev deps (tsx) | The migrate/seed scripts run through `tsx` at container start; installing them is simpler than compiling + copying the SQL/JSON assets into `dist`. Acceptable for a disposable demo image. |
| 2026-07-17 | Terraform/EC2 step skipped | Not explicitly requested; the plan marks it optional and disposable (prod target is the client's own infra). |
| 2026-08-05 | Client state moved from a `useReducer` in `App.tsx` to a zustand store (`src/store/appStore.ts`) | Owner request. All view state + async scan/entries actions now live in one store; components subscribe with selectors, `EntriesTable` reads entries directly (no prop drilling). Post-phase-6 branch: `feat/entries-table-zustand` ← phase-6. |
| 2026-08-05 | Entries table redesigned (type chips, status pills, sticky header, count badge) | Owner request — demo polish; markup change only, same data and API. |
| 2026-08-05 | Client layered: `lib/` (pure view logic) ← `hooks/` (store wiring) ← `components/` (render only) | Owner request — separate UI from logic. Filtering/sorting/grouping moved to `lib/entriesView.ts` (no React imports, unit-testable); `useEntriesView`/`useScanFlow` bridge the zustand store; components and `App` only render. Behavior verified unchanged via headless-browser click-through. |
| 2026-08-31 | POC is over: `POC_Architecture.md` and this phase plan are **historical**; `docs/HANDOFF.md` + `CLAUDE.md` are the source of truth | The code moved well past the POC (exceptional approvals, rules editor, guest policies…); §9's deferred list no longer binds. This decision log stays live and append-only. |
| 2026-08-31 | **ORM stays Drizzle** — no Sequelize | `schema.ts` already is the one-file visible model; `drizzle-kit generate` yields Alembic/EF-style auto-generated migrations (all 3 existing were generated; only a backfill `UPDATE` was hand-added). `sync()`-style auto-DDL is unsafe near production. A switch would rewrite every query, migration, seed, and the test harness for zero feature value. |
| 2026-08-31 | **USB scanner (keyboard wedge) is the only input; camera/photo scanning is removed** | The hardware scanner is the real operator workflow; webcam PDF417 decoding was unreliable. Removal is the next agent's first task (buttons already commented out in `ScanPanel.tsx`). |
| 2026-08-31 | **One component library** for admin/RTL — decide shadcn vs MUI before building; never both | Two competing systems mean style collisions and a doubled bundle. Both handle RTL. Recommended: shadcn (Tailwind, lighter, already planned). |
| 2026-08-31 | **Deploy = docker-compose on 2 on-prem machines over VPN**, via GitHub Actions or a script | Client owns hosting. Terraform/cloud permanently off the table. |

*(Append new decisions here — with reasoning — whenever scope or approach changes.)*
