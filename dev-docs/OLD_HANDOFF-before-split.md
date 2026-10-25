# JetLog — Handoff & Continuation Brief

**For:** the next Claude Code agent picking this up, and Mark while he studies the system.
**Status:** the POC is done and demoed. The codebase is now the real JetLog application, moving toward production on IsraJet's on-prem machines. This document is the **current source of truth** for how the system is built and where it's going. `POC_Architecture.md` and `docs/POC_PHASES.md` are historical (the latter's decision log stays live).

---

## 1. The system as it is → see `docs/ARCHITECTURE.md`

**[docs/ARCHITECTURE.md](ARCHITECTURE.md) is the single source of truth for how the system is built** — the request lifecycle of one scan, the module dependency rules, the data model with its invariants, the API contract, the client state model, and the extension points. It is written from the code and kept current with it (see its maintenance contract). This handoff no longer duplicates that; read ARCHITECTURE.md first, then use §2–§5 below for the *why*, the study path, the decisions in force, and the forward task plan.

The one-line shape: `ScanPanel` → `POST /api/scan` → `controllers/scan` → `scanService.processScan` (parse → dedup → rule/guest decision → log every scan) → PostgreSQL (`rules` + `entries`) → `ScanResponse` → `ResultCard`. Two side paths: exceptional approval (`POST /api/scan/exception`) and the rules editor (`/api/rules` CRUD).

---

## 2. How to study it (for Mark)

**Read the current code as the source of truth, bottom-up. Use git history as a targeted teaching aid, not a replay** — the code diverged a lot from the POC plan (exceptional approvals, rules editor, guest policy, `isValidBcbp`, the Zustand rewrite all came after), so a chronological replay teaches versions that no longer exist. The exception: the backend domain/pipeline barely changed since Phase 3–4, so `git show 0303e59` and `git show 00c7e0e` are still a gentle, test-backed intro.

**The path:**
1. **Orient:** `CLAUDE.md`, this file, then the **decision log** in `docs/POC_PHASES.md` (the "why").
2. **Domain first** (no I/O to distract you): `domain/types.ts` → `parseBoardingPass.ts` → `companyVar.ts` → `validateBcbp.ts` → `ruleKey.ts` → `uniqKey.ts` → `guestPolicy.ts` → `approvers.ts`. **Read each with its test open** (`server/tests/unit/`) — the test is the spec.
3. **Services:** `db/schema.ts`, then `scanService.ts` (the spine), `rulesService.ts`, `entriesService.ts`, `exceptionApprovalService.ts`.
4. **HTTP:** `app.ts` → `middleware/` → `controllers/` → `routes/`.
5. **Client:** `api/` → `store/appStore.ts` → `App.tsx` → components; `lib/entriesView.ts` is the pattern to imitate.

**The one exercise that teaches everything:** trace fixture 0 end to end — `ScanPanel` → `api.scan` → `POST /api/scan` → `controllers/scan` → `scanService.processScan` → `parseBoardingPass` → `matchRule` → insert → `ResultCard`.

**Interactive tools (they're skills):** `/decode-barcode <string>` (field-by-field parse) · `/why-rule <fixture|ruleKey>` (walks the wildcard-collapse, shows which rule fired) · `/scan-fixture 0` (fires a real barcode at the API) · `/demo`. `npm test` in `server/` is unit-only and **safe**.

**History as an index** — `git log --oneline --reverse` on `feature/edit-rules`; `git show <hash>` shows one feature with its tests and reasoning:
| Commit | What |
|---|---|
| `d3c1793`→`5e05fda` | POC phases 1–6 (scaffold, DB, domain, API, UI, compose) |
| `497ff4e`, `d458242`, `1402091`, `c6c7346` | Zustand rewrite, camera lifecycle/photo path (to be removed) |
| `504e6e1` | virtual `isValidBcbp`, invalid-scan handling, details modal |
| `88ad0e9` | exceptional approval |
| `ec2e97f` | **test-DB guard** (`TEST_DATABASE_URL`) |
| `726dac1`, `b477726`, `7bc6fc6`, `c0b696f` | guest policy column → rules CRUD → enforcement → rules editor UI |
| `214171f` | the real fix for the rules-table divider (`display:flex` on a `<td>`) |
| `64fa5fb` | rules CSV export |

---

## 3. Decisions in force (don't relitigate without a `/decision` entry)

**This is the living decision log.** New standing decisions are appended here as a row (prefix the *why* with the date, `**YYYY-MM-DD.** …`); one-off deferrals go to §5. POC_PHASES's decision log is frozen and historical — do not add to it. When this handoff is archived, this section travels into its successor.

| Decision | Why |
|---|---|
| **Drizzle stays; no Sequelize** | `schema.ts` already *is* the visible model. `drizzle-kit generate` gives Alembic/EF-style auto-generated migrations (all 3 existing migrations were generated; only a backfill `UPDATE` was hand-added). Auto-`sync()` DDL is unsafe near production. Switching = rewrite every query, migrations, seed, test harness for zero feature value. |
| **USB scanner is the only input; camera/photo scanning removed** | Hardware scanner is the real operator workflow; webcam PDF417 decode was unreliable. |
| **One component library — pick shadcn or MUI before the admin work; never both** | Competing systems → style collisions, doubled bundle. Both handle RTL. Recommended: shadcn (Tailwind, lighter, already planned). |
| **Component library = shadcn + Tailwind (not MUI)** | **2026-09-27.** Mark's call, settling the row above. shadcn/Tailwind is where the industry is now, is lighter and more flexible for a token-driven restyle (the coming client redesign), and is far friendlier to agent-driven UI work; MUI is heavier and older. Mark has shipped both — no strong contest. |
| **On-prem deploy: docker-compose on 2 machines over VPN; GH Actions or a script** | Client owns hosting. Terraform/cloud permanently off the table. |
| **Guest policy is one enum (ANY/SAME_CARRIER/SAME_FLIGHT), not two booleans** | It's a strictness hierarchy (same flight ⊃ same carrier); one value can't express an invalid combo. Existing rules were backfilled to `SAME_CARRIER` to preserve prior behavior. |
| **Rule uniqueness = `rule_key` among ACTIVE rules** | Two active rules with one key match the same scan ambiguously. Stronger than "all fields identical". |
| **Rules are deactivated, never hard-deleted** | Keeps history; matching already ignores inactive. |
| **Every scan is logged; deny reason lives in the response, not the row** | Movements log records attempts without a schema column for reason. |
| **Approvers + guest policies are hardcoded allowlists (for now)** | Trivial to move to DB-managed enums via the admin panel later. |
| **Broken scans are stored, flagged by a virtual `isValidBcbp`** | Nothing is rejected or dropped; the UI hides garbage instead. |
| **Guest policy: `ANY` is a first-class value, not null; snapshotted onto the host entry at admission** | **2026-09-22.** Refines the earlier "null = ANY" convention. `rules.guest_policy` is `NOT NULL DEFAULT 'ANY'` and the `GuestPolicy` vocabulary (in `domain/types.ts`) is the closed set `ANY`/`SAME_CARRIER`/`SAME_FLIGHT` — one honest vocabulary shared by `rules` and the host-entry snapshot, instead of `null` on rules but an `'ANY'` sentinel on entries. Task 8 copies the matched rule's policy onto the host `entries` row so a mid-session rule edit can't change an already-admitted host's guests; a no-snapshot host (no-rule/exceptional) defaults to `SAME_CARRIER`. The live `getActiveRuleByKey` lookup was removed (pre-production, no legacy rows to support). Migration `0006`. |
| **Postgres pinned to 17 across dev, demo, and CI (was 16)** | **2026-09-22.** Mark's call during task 10 (CI). CI's Postgres must match what dev/prod actually run or the integration suite tests the wrong engine; pre-production is the free window to choose the version we'll live with. 17 buys a longer support runway (~2029 vs 16's ~2028) at ~zero migration cost — no production data yet, and JetLog uses nothing version-specific (plain Drizzle/SQL + one partial unique index). Stopped at 17, not 18/19, to stay on a mature, well-worn major for on-prem. CI runner pinned to `ubuntu-24.04`; the on-prem **host** OS is deferred to task 18 (containers abstract it — Ubuntu 24.04 LTS vs Debian stable, to track IsraJet ops). Applying the bump to an existing dev volume needs a volume recreate (PG16 data dirs aren't 17-compatible) — dump/restore or drop + re-migrate + reseed. |
| **Approvers → DB table (task 12); guest policies stay strings, not tabled** | **2026-09-27.** Mark's calls while building task 12, refining the task-12 plan. `approvers` becomes a table (`name` **globally unique**, `kind` `internal`/`external`, `company`, `active`) with **full CRUD** endpoints (not read-only). Deactivate never hard-deletes; re-adding a removed name **reactivates** that row (no duplicates); history is safe because `entries.approver_name` is a text snapshot, not an FK. The hardcoded `domain/approvers.ts` allowlist is deleted; `exceptionApprovalService` validates against the ACTIVE table. **Guest policies deliberately stay a closed string vocabulary in `domain/` (behavior in `domain/guestPolicy.ts`), NOT a DB table** — refines the original task-12 "both move to DB"; tabling guest policies is deferred indefinitely. Approvers seeded via `seedApprovers` (non-destructive upsert), not the migration; integration tests run serial (`--no-file-parallelism`) since they share one DB. |
| **Client store split into slices (still ONE store); async actions follow fixed invariants; store changes get tests via `store-test-writer`** | **2026-09-29.** Mark asked for the store to be refactored, hardened and tested after task 12 grew it to ~350 lines / four features. Uses Zustand's slices pattern — one `useAppStore`, one state object, but a file per feature (`store/slices/`) and typed slice interfaces (`store/types.ts`) — so the "one store" rule holds while each feature is readable and testable alone. The refactor also closed real races: double-submit of a scan (a second post would come back `ALREADY_ENTERED`), scan responses applied after a reset, overlapping list loads finishing out of order, and failures that were written to the store but never rendered. Those guarantees are written down (ARCHITECTURE §6) and pinned by store tests that run without React (`makeStore()` over `zustand/vanilla`, API mocked). A dedicated `store-test-writer` agent owns those tests so every future store change ships with coverage. |
| **Multi-lounge (task 13): `lounges` table with a unique, editable `code` (FK target of `entries.lounge`, `ON UPDATE CASCADE`), non-unique `name`, optional `description`; one lounge `A` seeded by migration `0008`; `lounge` required on every scan/exception (400, no default); a lounges management page + `POST`/`PATCH /api/lounges`; server-side entries lounge filter; rules stay global** | **2026-09-30.** Mark's calls while building task 13. The real lounge codes don't matter yet — seed just `A` and let the admin rename/add the rest, so the code must be editable; the FK cascades a re-code onto logged entries instead of orphaning them. Only `code` is unique (it is the identity); Mark declined a unique `name`. The seed lives in the migration, not `db:seed` like approvers, because the new FK needs a target in every database (dev, CI, test DBs). `lounge` is required with no fallback: a scan logged against the wrong lounge corrupts the per-lounge billing proof, so an unset station is blocked in the client and a missing/unknown/inactive lounge is a 400 before anything is logged. The management page is scope added beyond the original task-13 plan (it moves into the admin panel with task 16). The entries filter is server-side because the log is capped at the 50 most recent hosts — a client-side filter would starve a quiet lounge. Per-lounge rules stay parked (§5). Pre-production, so no production-data care: the dev DB's hardcoded `'C'` entries were pointed at `A` by hand before migrating. |
| **Mark runs `db:generate` / `db:migrate` himself; every task is built server-first, then client, with a review stop after each** | **2026-10-04.** Mark's call after task 13, where the agent ran the migration itself. Migrations change his database, so he runs both commands and sees their output; the agent edits `schema.ts`, hand-adds any seed/backfill to the generated SQL, and hands him the commands with a before/after row-count check. Building the server and stopping for his review before any client code means the API shape is settled — and studied by Mark — before UI is built on it, instead of reviewing one large mixed diff at the end. Written into `CLAUDE.md` (safety rules + workflow), HANDOFF §4/§6, and both senior agents' ground rules. |
| **Foreign keys reference the surrogate `id`, never a code; lounges are code-only (no `name`)** | **2026-10-05.** Mark's call while planning task 14's clubs, superseding the "FK on `lounges.code`, `ON UPDATE CASCADE`" part of the task-13 row above. A code is an editable label; pointing an FK at it is non-standard and confuses future devs and agents, and a code change would rewrite every referencing row in the ever-growing `entries` table. With the FK on `id`, a code change touches only its own row and the entries list joins the current code for display. Migration `0009` moves `entries.lounge` → `entries.lounge_id → lounges.id` (backfilled from each entry's code) and drops `lounges.name` (the code is the identifier, as it will be for clubs). The API follows: stations send `loungeId`, and `GET /api/entries` filters by `?loungeId=`. Shipped as its own PR before task 14, which builds clubs by id from the start. |
| **Clubs (task 14): one global `clubs` table (unique editable `code`, `description`, `active`, resized image stored in the row); "ask first, log once" — `POST /api/scan/club-options` logs nothing, then one scan with the pick; only clubs an ACTIVE rule for that pass uses are offered/accepted; rules and entries reference clubs by id (`rules.club_id` NULL = any club or none, `entries.club_id` NULL = club-less passenger); the Excel's `Guest` club is retired; the FF-tier half of task 14 is dropped** | **2026-10-05.** Mark's calls planning task 14. A second scan call can't carry the pick (an approved first scan makes it `ALREADY_ENTERED`), and rewriting a logged entry loses the decision — so the server is asked first and one entry is logged with full information. Clubs are global codes (Gold is one row across airlines); a pass is offered only clubs that build a real rule key with its other dimensions, so a pick is never a guaranteed denial. A club-less passenger is stored as NULL so a future club-specific discount can tell members apart. The `Guest` club existed only because the Excel had no guest management — JetLog has `is_guest` + `host_entry_id` — so its 40 rules name no club and are inactive (kept, never deleted; their keys now equal some active keys, which is allowed for inactive rules). Images live in Postgres, not on disk or object storage: ~100 images of ~10–30 KB, backed up by `pg_dump`, nothing to sync between the two on-prem machines, nothing to rename on a code change. `rules.json` keeps Vlad's readable codes and `seedRules` maps them to ids. No seeded rule uses the `frequentFlyer` dimension (BA's `1`/`2` are `companyVar`, from the barcode), so there is no tier to pick. |
| **Seed guard + go-live lock (task 19):** a pure `decideSeed` (`db/seedGuard.ts`) decides, in order: locked → refuse · empty `rules` → seed · no `--force` → quiet skip (exit 0) · `NODE_ENV=production` → refuse even with `--force` · else replace. A refusal or skip writes nothing. It runs in the `db:seed` command **and** inside `seedRules`' transaction, and `seedRules(db, { force })` makes every caller say whether it may replace. The lock is a one-row `deployment_state` table **in the database** (migrations `0011` + `0012`; its one row starts unlocked), set once by `npm run db:lock -- --confirm <db>`, with **no unlock script** (manual SQL in DEPLOY.md). Every destructive path must check it. | **2026-10-11.** Mark's calls. Planning task 19 turned up three facts that ruled out a plain "never seed in production" guard. (1) A new production database still needs its first seed. (2) The commands run from Mark's laptop through an SSH tunnel, where `NODE_ENV` is `development`, so an env-var guard would never have protected production. Only a fact stored with the data holds whichever machine runs the command. (3) The demo compose runs with `NODE_ENV=production` and seeds on every start. A non-empty table without `--force` is therefore a quiet skip, not an error, so a restart still boots and the demo compose is unchanged. Mark asked for the guard in the function too, not only the command, so that a direct `seedRules` call can't wipe production. The integration tests still reseed with `force: true`, because `jetlog_test` is never locked. Until go-live Mark must be free to wipe, reseed or recreate the production database. After go-live nothing run from any machine may do so, and undoing that takes a deliberate manual step that has no shortcut in code. |
| **One compose file per VM; the DB VM runs Postgres only** (`deploy/db/docker-compose.db.yml` on SQL.Layam 192.168.1.1: exact `postgres:17.11` tag, `restart: unless-stopped`, `.env.prod` root/600 not in git, bind-mounted `pgdata`, log rotation, no `initdb` mount). The app VM (APP.Layam 192.168.0.1, task 18) runs `api` + `web` with no `pg`. Port 5432 is published on 192.168.1.1, and only 192.168.0.1 is allowed, via the `DOCKER-USER` iptables rule (IT owns it). Postgres accepts any address with the password. Mark's SSH tunnel starts on the VM, so the rule doesn't touch it. The native Postgres 16 is dumped, then purged. Production runs **migrate only**, seeded once into an empty database. Backups belong to IsraJet's DBA. | **2026-10-11.** Mark's calls, refining the on-prem deploy row above and replacing task 18's single `docker-compose.prod.yml`. The database and the app live on separate VMs, so each machine's file describes only what runs there, and the app VM stays stateless (club images are in Postgres). Because the API connects over the network, Postgres can't be bound to localhost. Docker-published ports get around `ufw`, which is why the firewall rule sits in `DOCKER-USER`. Postgres itself accepts any address with the password, so access is managed by IT (firewall) and the DBA (roles): a new client such as Power BI is one firewall rule plus one `CREATE ROLE`. The native Postgres 16 holds 5432 and is the wrong major version (17 is pinned, see above). It is pre-production, so it's dumped and replaced. Backups are the DBA's job. DEPLOY.md records what they need: VM snapshots alone aren't enough, so a nightly `pg_dump` copied off the VM plus one rehearsed restore. The Ubuntu upgrade is kept out of this task (a separate agent, done first). Runbook: [docs/DEPLOY.md](DEPLOY.md). |
| **IsraJet's requests become tasks 20–25 and go before 15–18:** global scan rules (departure airport, ±2-day window) · rules per lounge (rule keys spell club and lounge **ids**) · rules CSV import (add-only, all-or-nothing) + bulk **deactivate** · modify an existing scan **in place** within 48 h (move lounge with revalidation, add guests, rescan, exceptional approval) · filtered scans export (one row per entry) · entries pagination. One branch and PR each, and each planned with Mark before any code. | **2026-10-13.** Mark relayed IsraJet's list after task 19 and answered the first round of design questions (recorded in each task's "Decided" list). They are what the client needs for real operation, so they come ahead of the planned large tasks. Three of them change decisions in force, and each gets its own `/decision` when built. Task 21 reverses "rules stay global" and stops club re-codes from rewriting rule keys. Task 23 edits logged entries in place, against the task-14 reasoning "rewriting a logged entry loses the decision"; Mark: no audit trail is needed yet, and it can be added if IsraJet asks. Task 20's global rules are rows tied one-to-one to code, so only a migration adds one. Bulk removal in task 22 is a deactivate, so "rules are never hard-deleted" stands. |
| **Task 20 refinements:** the flight-date window places the pass's day of the year in last, this or next year, **whichever is nearest today in Israel**, not in the year `bcbp` resolves (this overrides the "Decided" line on `bcbp`'s date; the stored `entries.flight_date` stays `bcbp`'s). A pass with no usable date is denied with a fourth reason, **`FLIGHT_DATE_UNKNOWN`**, and a missing origin fails the airport check. The hardcoded **"First leg does not depart TLV" warning is removed** from the parser and `ScanResponse`. Global rules are edited **one key per request** (`PATCH /api/global-rules/:key { value }`). A global failure wins over every other deny reason, `ALREADY_ENTERED` included. `club-options` offers no clubs to a pass that fails one, and a missing or invalid `global_rules` row **fails closed** (500). | **2026-10-13.** Mark's calls when planning task 20's build. The task's "Decided" list assumed `bcbp` resolves the year across New Year. It does that only when the pass carries an issuance date (a flight before issuance rolls to the next year). Without one it takes the current UTC year, so on 31 Dec a 1 Jan pass would come out 364 days ago and be denied, which is exactly the case the task meant to allow. Picking the nearest year agrees with `bcbp` whenever `bcbp` is right. A pass with no date can't be placed in any window, and folding it into "too long ago" or "too far ahead" would mislead the operator, so it gets its own reason. The TLV warning predates the configurable airport list, could contradict it (for example after `ETM` is added), and is now a real denial, so keeping both would only confuse. A single-key PATCH matches `PATCH /api/rules/:id` and `/api/lounges/:id`. No rule's validity depends on another's today, so a multi-key, all-or-nothing update would buy nothing; one can be added if a cross-key rule ever appears. Failing closed means a broken table stops scans visibly instead of quietly admitting every pass. |
| **Every deny reason is reported and stored (task 26)**, reversing "deny reason lives in the response, not on the row" (the earlier row above and `CLAUDE.md`'s governing decisions). Every check runs and nothing short-circuits. The reasons follow **one pinned order** (`DENY_REASON_ORDER` in `domain/denyReasons.ts`, held by a unit test), are stored as **`entries.deny_reasons text[]`** (null = none recorded) and returned as **`reasons: DenyReason[]`** (replacing `reason`). `approved` alone decides. The club picker comes last; **`CLUB_REQUIRED`** replaces `NO_MATCHING_RULE` only when the club is the sole failure, and a club is accepted only if the picker would offer it. Bad requests still log nothing. No backfill. | **2026-10-14.** Mark's calls (planned 2026-10-13, recorded in task 26). The desk saw only the first failure: a JFK pass outside the window showed only the airport. The reason also vanished once the result card closed, so the details modal, the log and the task-24 export couldn't say why a pass was denied. A pinned constant, rather than the order the checks happen to run in, keeps the list stable as checks are added. A `text[]` instead of a comma string needs no conversion helper, and the export can filter with `= ANY(deny_reasons)`. Old rows stay null: the rules have changed since, so recomputing them would invent history. It is built right after task 20, so that tasks 21 and 23 write every reason from the start. An in-place exceptional approval (task 23) keeps the reasons as the record of what was overridden. |
| **Rules per lounge (task 21)**, reversing "rules stay global" (the task-13 row). `rules.lounge_id` is nullable: **NULL = all lounges**, and every existing and seeded rule is NULL, so today's behaviour is unchanged. A scan uses **its station's own lounge rules first, then the all-lounges rules**; a lounge where no rule applies denies. **Rule keys spell ids** and separate their parts with `-` (`carrier-compartment-ff-companyVar-<club id\|#>-<lounge id\|#>`). The key is stored when a rule is written; a **`ruleKeyReadable`** spells it with the current codes on every read and is never stored. A club or lounge re-code rewrites nothing. `club-options` takes the station's `loungeId`. `rules.json` gains `lounge` and drops `ruleKey`. | **2026-10-14.** Mark's calls planning task 21. IsraJet needs each lounge to admit by its own rules, while most rules stay the same everywhere. A nullable lounge expresses "everywhere" in one row instead of a copy per lounge, and backfilling to NULL changes nothing on migration day. Matching a lounge's own rules before the all-lounges ones, instead of collapsing the lounge like the other parts, keeps a lounge's own rules from hiding the all-lounges ones for the same carrier. A lounge with no applicable rule denies rather than admitting everyone: Mark weighed an open fallback, then chose denial as simpler and safer for the billing proof. Ids make a key stable under re-codes: the old club re-code had to rewrite keys and check for collisions. Mark asked that the readable form be computed rather than stored, so it can never drift. The `-` separator keeps ids from running together, and no dimension may contain it. The seed derives the key, so `rules.json` no longer carries a second copy of it. |

---

## 4. The task plan (in order — small first, large last)

**How every task runs.** One task = one branch off `staging` = one focused commit. **Server first, then client, with a review stop after each:** build the server side (schema → services/controllers/endpoints + tests), stop and hand it to Mark to check; only then build the client side and hand that to Mark to check. Run `/verify` (server tests + both lints + client build), then **stop and hand it to Mark for review. Commit only after Mark says so.** Stage only your own files — Mark keeps WIP in the tree. Never run integration tests against a live DB (`npm test` is unit-only; `npm run test:integration` needs a dedicated `TEST_DATABASE_URL`). For any schema change: edit `schema.ts`, then give Mark the commands — **he runs `npm run db:generate` and `npm run db:migrate` himself; agents never run them**. Review the generated SQL (hand-add any seed/backfill), check row counts before/after his migrate, and keep `seed-data/rules.json` in sync. Log any scope/approach decision with `/decision` (it appends to §3 above). **New features ship with tests that prove them — pure domain logic written test-first, new endpoints/services covered by an integration test, client `lib/` unit-tested** (this is for new work, not a rebuild of what exists). When a change touches the architecture — the module dependency rules, the request lifecycle, the data model or its invariants, the API contract, the client state model, or the extension points — update [docs/ARCHITECTURE.md](ARCHITECTURE.md) in the **same commit** (it is the source of truth; a routine change that only follows the existing patterns does not need an edit there). Update `CLAUDE.md` too when a task changes how the system works.

Tasks 1–9 are small and mechanical; 10–14 are medium features; 15–18 are the large ones and depend on the earlier ones as noted. Task 19 (appended later) is a small safety guard that can land any time — numbered last only to avoid renumbering the rest. **Tasks 20–25 are IsraJet's requests (2026-10-13) and come next, before 15–18** (see §3). With task 26 (every deny reason, combined and stored; Mark, 2026-10-13) the order is: 20 → 26 → 21 → 22 → 23, with 24 → 25 at any point after 20. Task 27 (exceptional approval for a guest) is still to be planned. Each is its own branch and PR, and **each starts with a plan agreed with Mark** (its open questions answered) before any code.

---

### 1. Domain cleanup — resolve the review TODOs (small)
**Why:** Mark left `TODO` review comments in the domain while studying it; each was discussed and decided. This commit lands the decisions and removes the comments. No behavior change.
**Touch:** `server/src/domain/{parseBoardingPass,types,guestPolicy,approvers,uniqKey,companyVar}.ts`, `server/src/services/exceptionApprovalService.ts`, `server/src/types/dto.ts`, `server/src/utils/ErrorResponse.ts`, `client/src/api/types.ts`, tests under `server/tests/unit/`.
**Steps (each maps to a TODO):**
1. **`julianDay` → `ordinalDate`** (`parseBoardingPass.ts` function + the `ParsedLeg.julianDay` field in `types.ts` + `uniqKey.ts` + tests). Put this in its doc-comment: a boarding pass stores the flight date as the ISO 8601 *ordinal date* — the day of the year, `001`–`366`, no year (`"007"` = 7 Jan). It is one of the five parts of the dedup key, matching Vlad's Excel; it is recomputed from the `Date` the `bcbp` lib resolved so there is one source of truth, and zero-padded to 3 digits to match the barcode format. Update the flow diagram in §1 of this file (`julianDay-carrier-…` → `ordinalDate-carrier-…`).
2. **`leg` → `firstLeg`** on `ParsedBoardingPass` (`types.ts`) and every reader: `parseBoardingPass.ts`, `scanService.ts`, `exceptionApprovalService.ts`, `validateBcbp.ts`, tests. Keep the doc-comment explaining that Israel is always the first leg and leg 2 of an M2 pass is ignored.
3. **Guest-policy magic strings** (`guestPolicy.ts`): define an object-enum, the same pattern `DenyReason` already uses in `dto.ts` — `export const GuestPolicyValue = { SAME_CARRIER: 'SAME_CARRIER', SAME_FLIGHT: 'SAME_FLIGHT' } as const;` — derive `GUEST_POLICIES` and the `GuestPolicy` type from it, and replace every string literal in `normalizeGuestPolicy`, `guestSatisfiesPolicy`, and the error message in `rulesService.ts` with the enum members. Mirror the union in `client/src/api/types.ts`. Keep the existing `rulesEditing.test.ts` green (it is the spec).
4. **`isGuestPolicy` predicate must be honest** (`guestPolicy.ts`): the function returns `true` for `null`, `undefined`, and `''`, so its type predicate must say so. Change the signature to `value is GuestPolicy | null | '' | undefined`. Rationale: a type predicate that claims a narrower type than the function actually accepts is a typing bug — after the guard TypeScript would believe `''` is impossible.
5. **`dto.ts` `guestPolicy` field**: type it `GuestPolicy | null` (import the type from `domain/guestPolicy.ts`; a `dto → domain` import is fine, the reverse is not).
6. **Remove `Object.setPrototypeOf(this, …prototype)`** from both `ErrorResponse` (`utils/ErrorResponse.ts`) and `BoardingPassParseError` (`domain/types.ts`). It was only needed when compiling to ES5; this project targets ES2022 where native class extension makes `instanceof` correct. The error handler relies on `instanceof`; the existing 400/404 envelope tests prove it still works.
7. **`MAX` → `MAX_CHARS`** in `exceptionApprovalService.ts`. These are character limits matching the `varchar(100/50)` columns; better still, read the three lengths from one exported constants object that `schema.ts` also uses for the `varchar` lengths, so validator and column cannot drift.
8. **Tighten the two long lead comments** in `uniqKey.ts` and `companyVar.ts`: first sentence states the *need* plainly ("Dedup key: one approved entry per passenger per flight"; "companyVar is the airline's lounge code; the library exposes it as `airlineInfo`"), then keep the Excel-provenance paragraph — it is the proof of correctness and the most valuable comment in each file.
9. **Approvers**: leave the code as is; the array is already the single source (everything checks it via `isApprover`). Replace the TODO with a one-line pointer: `// Moves to a DB table in task 12; the client's hand-copy in client/src/lib/approvers.ts goes away then.`
10. **Decline and delete these TODOs** (decisions already made; do not implement): renaming `ScanDimensions` → `RuleKey` (it is the *input*, the key is the output string), renaming `RuleLike` → `Rule` (`Rule` already exists as the Drizzle row type in `schema.ts` and would collide), adding an HTTP status code to `BoardingPassParseError` (the domain is HTTP-agnostic; the 400 mapping lives in `errorHandler.ts`, which is the correct boundary), moving errors to an `errors/` folder (defensible either way; not worth a commit).
11. Remove every remaining `TODO` from this pass. Only action-TODOs with a pointer may stay in code.
**Done when:** `/verify` green, unit test count unchanged or higher, `grep -rn "TODO" server/src` shows only the approvers pointer and the multi-lounge TODO in `scanService.ts`.

### 2. Frequent flyer — store what the barcode actually carries (small)
**Why:** Vlad's Excel records a `FrequentFlyer` column (`EY`, `LY`, or empty) per scan; today the app stores nothing (`frequentFlyer: ''` on scanned entries and `null` on exceptional ones — the data is inconsistent). The barcode's conditional section carries the **frequent-flyer airline designator and member number**, and `bcbp` exposes them as `leg.frequentFlyerAirlineDesignator` and `leg.frequentFlyerNumber` (see `node_modules/bcbp/dist/index.esm.d.ts`). We must store the designator exactly as the Excel does. Rule matching already tolerates the value (the EY rules collapse it to `#`).
**Touch:** `domain/parseBoardingPass.ts`, `domain/types.ts`, `domain/ruleKey.ts` (the `collapse` helper), `db/schema.ts` + a new migration, `services/scanService.ts`, `services/exceptionApprovalService.ts`, `services/entriesService.ts`, `types/dto.ts`, `client/src/api/types.ts`, the details modal, `tests/fixtures/barcodes.json`, unit tests.
**Steps:**
1. **Verify the parser first.** Run `/decode-barcode` (or a scratch `tsx` script) on this real pass and confirm both fields populate: `M2GIDRON/ORI          E7NTNLU TLVAUHEY 0594 007J002A0015 34A>5180 O6007BEY              2A60755242827580    EY 500099197404        NLA…` → designator `EY`, number `500099197404`. Then on `M1MEIR.GILSHLOMO      E7T3PKJ TLVAUHEY 0598 007J001C0076 34A<5180 W6007BEY              2A60755243741200 EY LY 397004                NLA` → designator `LY` (an El Al member on an EY flight — the designator is *not* always the carrier). If the library does not populate them for a real pass, stop and report before continuing.
2. In `normalizeLeg`: `frequentFlyer: (leg.frequentFlyerAirlineDesignator ?? '').trim() || null` and a new `frequentFlyerNumber: (leg.frequentFlyerNumber ?? '').trim() || null`. Change `ParsedLeg.frequentFlyer` to `string | null` and add `frequentFlyerNumber: string | null`.
3. **Null-clean rule:** absent → `null`, never `''`. Fix `collapse()` in `ruleKey.ts` to treat `null` like an empty value (wildcard), and wherever a `ScanDimensions` is built from a leg pass `leg.frequentFlyer ?? ''`.
4. **Schema:** add `entries.frequent_flyer_number text` (nullable) — additive migration. Keep the existing `frequent_flyer` column for the designator (it matches the Excel column). Migrate with the row-count check.
5. Write both fields in `scanService` and `exceptionApprovalService` (`null` when no barcode). Expose both on `EntryDto` and the client mirror; show them in `EntryDetailsModal`.
6. **Fixtures/tests:** the Checkup-sheet fixtures' `expected.frequentFlyer` currently holds the Excel value (`EY`, `LY`, or `''`); update `fixtures.test.ts` to assert `parsed.firstLeg.frequentFlyer` equals it (mapping `''` → `null`). Add the GIDRON pass as a fixture via `/new-fixture` so the designator+number path is covered by a real barcode.
7. Update §1 of this file (the invariants bullet already states the intent) and `CLAUDE.md`.
**Done when:** the two real passes above decode to `EY`/`500099197404` and `LY`/`397004`; scanning them stores those values; a no-FF pass stores `null` (not `''`); `/verify` green.

### 3. Remove camera / photo scanning (small)
**Why:** the USB scanner (keyboard wedge) is the only input (decision in force). The camera code is dead weight and ~120 KB of bundle.
**Touch:** delete `client/src/components/CameraScanner.tsx` and `client/src/lib/barcodeCapture.ts`; in `ScanPanel.tsx` remove the `cameraOn`/`readingPhoto` state, the hidden file `<input>`, the `scanPhoto` handler, the camera branch, and the two commented-out buttons; `npm uninstall html5-qrcode` in `client/`; drop `.camera-region` from `styles.css`; update the `ScanPanel` doc-comment (it still describes the photo path).
**Done when:** `grep -rn "html5-qrcode\|CameraScanner\|barcodeCapture" client/` is empty, `client/package.json` no longer lists it, the scan input + Manual-approval button still work (drive it in the browser), bundle size drops, `/verify` green.

### 4. Refresh `.claude/agents/react-frontend-senior.md` (small)
**Why:** its ground rules still say "no admin, no router, POC §6 binding, html5-qrcode" — every one of those is now false and would mislead delegated work.
**Steps:** rewrite the *Ground rules* and *The screen* sections to match `CLAUDE.md`: the app has an operator view and a rules-editor view (view switch in the store), Zustand is the one store, the input is the USB scanner only, the component library is whatever task 9 chose (or "TBD, see HANDOFF task 9" until then), admin/RTL work is in scope. Keep the `.claude/feedbacks/` convention and the "stay in `client/`" rule. Check `ts-backend-senior.md` for the same staleness (it references the phase plan).
**Done when:** nothing in either agent file contradicts `CLAUDE.md`.

### 5. Write `docs/ARCHITECTURE.md` from the code (small, high value)
**Why:** learning-by-documenting — it validates this handoff against reality and becomes the durable reference once this file's "current state" section is superseded.
**Steps:** read the code (not this file) layer by layer per §2 and write: the request lifecycle of one scan, the module dependency rules (what may import what), the data model with the invariants, the API contract, the client state model, and an "extension points" section (how to add a rule dimension, an endpoint, a store slice). Where it disagrees with this file, **the code wins** — fix this file too.
**Done when:** Mark can answer "where would I add X?" from it alone.

### 6. Upgrade Express 4 → 5 (small)
**Why:** Express 4 does not catch rejected Promises from async controllers (`asyncHandler` exists for that). Express 5 does. Node is already `>=20`.
**Touch:** `server/package.json` (+ lockfile), `@types/express` (needs v5 types), optionally drop `asyncHandler` from controllers, `docs/ARCHITECTURE.md`, §6 convention in this file.
**Steps:**
1. Bump `express` to `^5` and matching types.
2. Keep `errorHandler` and `notFound`. `asyncHandler` may be removed after tests pass.
3. Unparsed `req.body` is `undefined` in v5 (was `{}`). Existing `typeof body !== 'object' || body === null` checks already cover that.
4. `/verify` + `npm run test:integration` (dedicated `TEST_DATABASE_URL`). Confirm `/api/rules/:id` and `/api/scan/exception` still match.
**Done when:** `express` is v5, tests green, docs match whether `asyncHandler` was kept or removed.

### 7. Dedup at the database level (small)
**Why:** dedup is check-then-insert with no lock — two scanners could both approve the same pass. A partial unique index makes the DB the referee.
**Steps:** migration adding `CREATE UNIQUE INDEX entries_one_approved_per_uniq_key ON entries (uniq_key) WHERE approved = true AND uniq_key IS NOT NULL;`. In `scanService`, wrap the insert so a unique-violation (`pg` error code `23505` on that index) is converted to the existing `ALREADY_ENTERED` denial (log the denied row as usual). Keep the pre-check as a fast path. Before migrating, check the live data for existing duplicates (`select uniq_key, count(*) from entries where approved group by 1 having count(*)>1`) and report them to Mark rather than guessing.
**Done when:** an integration test proves two concurrent approvals of the same pass yield exactly one `approved = true` row; `/verify` green.

### 8. Snapshot the guest policy onto the host entry (small)
**Why:** a guest's policy is resolved *live* from the host's `rule_key` (`getActiveRuleByKey`), so editing that rule mid-session changes the outcome for guests already being scanned.
**Steps:** add `entries.guest_policy text` (nullable, additive); when a host is approved, copy the matched rule's `guest_policy` onto its entry; in the guest path read `host.guestPolicy` and fall back to the live lookup only when it is `null` (pre-existing rows). Show it in the details modal.
**Done when:** editing a rule after a host scan does not change that host's guest outcome (unit test on the service with a fake DB, or integration test).

### 9. Client test runner (small)
**Why:** `lib/entriesView.ts`, `lib/rulesCsv.ts`, `lib/approvers.ts` are pure and untested.
**Steps:** add Vitest to `client/` (`npm i -D vitest`, a `client/vitest.config.ts` with `environment: 'node'` for `lib/`, `"test": "vitest run"`), write tests for `buildEntriesView` (filter/sort/group incl. the "host kept as context row when only a guest matches" case), `rulesToCsv` (quoting, BOM-less content, column order), and `isApprover`. Add `cd client && npm test` to the `/verify` skill.
**Done when:** `/verify` runs client tests and they pass.

### 10. Continuous integration (medium)
**Why:** `/verify` is manual; nothing stops a red commit.
**Steps:** `.github/workflows/ci.yml` on push/PR: Node 22, `npm ci` in both packages, server lint + unit tests, client lint + build + tests, **and** the server integration suite against a `postgres:16` service container with `TEST_DATABASE_URL` pointing at it (never at a real DB). Cache `node_modules`. Badge in the README.
**Done when:** a PR shows the gate; a deliberately failing test blocks it.

### 11. Adopt shadcn + Tailwind — the UI foundation (small)
**Why:** every UI effort ahead (admin panel, the client-requested redesign, Hebrew/RTL) needs one component system in place first. This task **only establishes the foundation** — it is deliberately NOT the redesign. The big visual/flow overhaul is a separate handoff (see "Next handoff" at the bottom). Doing this thin-and-first means all later UI is built once, on the right system, instead of migrated twice. Decision in force: **shadcn + Tailwind, not MUI** (§3).
**Steps:**
1. Install Tailwind + shadcn: Vite plugin, `components.json`, the `@/` path alias. Preflight reset is expected to shift plain-CSS styling — plan for it in step 4.
2. Define the **theme-token layer** (Tailwind config + CSS variables). This is the payoff: "make it look like the legacy desktop app" later becomes largely a token change, not a per-component rewrite.
3. Adopt a **thin app-level wrapper** pattern around shadcn primitives (one touch-point per widget), so a future restyle or version bump has a single place to change.
4. **Prove it on one real component:** a `Button` primitive **plus** `EntryDetailsModal` migrated onto shadcn `Dialog` (Dialog is the hardest primitive — overlay/Esc/focus — so one real migration validates the setup). Keep the store-driven open/close semantics. Regression-check the operator + rules screens against the preflight reset.
5. **Explicitly deferred to the UI-redesign handoff:** the other two modals (`ExceptionForm`, `RuleForm`), the visual redesign to match the legacy app, the changed flows, and Hebrew/RTL (task 17). Do not start them here. The `lib/` (pure) → `hooks/` (wiring) → `components/` (render) split stays intact so presentation swaps never touch logic.
**Done when:** Tailwind + shadcn installed with tokens + the wrapper pattern; `Button` and `EntryDetailsModal` run on shadcn; no visual regressions on the operator + rules screens; `/verify` green.

### 12. Approvers and guest policies as database tables (medium) — prerequisite for the admin panel
**Why:** both are hardcoded allowlists (`domain/approvers.ts`, `domain/guestPolicy.ts`) with a hand-copied list in the client. The admin panel must manage them.
**Steps:** tables `approvers (id, name, kind: 'internal'|'external', company, active)` and `guest_policies (code, label, active)` with migrations that seed today's four approvers and two policies; `GET /api/approvers` + `GET /api/guest-policies` (+ create/update/deactivate for the admin panel later); `exceptionApprovalService` validates against the table instead of the array; `rulesService` validates `guest_policy` against the table; the client fetches both lists on load into the store and deletes `client/src/lib/approvers.ts`. Keep `guestSatisfiesPolicy` keyed on the two known codes (they carry behavior); unknown codes are rejected at write time. Note the design nuance Mark raised: approvers include *external-company contacts*, hence the `kind` and `company` columns.
**Done when:** adding an approver by SQL makes it appear in the exception form without a deploy; the hardcoded arrays are gone.

### 13. Multi-lounge (medium)
**Why:** `lounge` is hardcoded `'C'` (`scanService.ts` TODO). IsraJet starts with 2 lounges, later 4.
**Built** — see the 2026-09-30 row in §3 for how it landed (one seeded lounge `A`, editable codes, a lounges management page).
**Steps:** `lounges (code, name, active)` table seeded with the real codes (get them from Mark); each station selects its lounge once (persist in the store + `localStorage`) and sends `lounge` with every scan/exception; `entries.lounge` becomes an FK; the entries table gets a lounge column and filter; rules are global for now (per-lounge rules are a later decision — log it if it comes up).
**Done when:** two browser tabs set to different lounges produce entries tagged accordingly and the table filters by lounge.

### 14. Club selection at scan time (medium)
**Built** — see the 2026-10-05 clubs row in §3 for how it landed (global clubs table with images, "ask first, log once", clubs by id, Guest club retired, FF tier dropped).
**Why:** the loyalty *tier* / `club` is not in the barcode, so `club`-keyed rules (e.g. `EY ##LAGold`) can never match from a bare scan.
**Steps:** decide the flow with Mark first: after a scan, when the matched carrier has any active rule with a non-`#` `club`, show a popup listing that carrier's club values (derive them from the rules table — the same value-set logic `ruleKey.ts` uses) plus "none"; the operator's choice is sent as a second call (`POST /api/scan` with `{ rawBarcode, club }`) or as a re-evaluation of the just-created entry — choose the simpler and log it. Store the chosen club on the entry. The `frequent_flyer` *tier* dimension (BA's `1`/`2`) is the same problem and can share the popup. This will require a migration, changes to the scan service, a UI modal, and more.
**Done when:** scanning an EY pass and choosing "Gold" matches `EY ##LAGold`; choosing "none" behaves exactly as today.

### 15. Authentication, roles, and the station model (large) — prerequisite for 16
**Why:** everything is public. Production needs operators, managers, and admins, and a per-station login.
**Steps:** decide the identity source with Mark (local users table vs the client's SSO — on-prem suggests local first); `users (id, username, password_hash, role, active)` with bcrypt/argon2; login endpoint issuing an httpOnly-cookie session or JWT; `requireAuth` / `requireRole` middleware; roles `operator` (scan, exceptions), `manager` (+ rules, approvers), `admin` (+ users); record `user_id` on entries (who scanned) and on exceptional approvals (who logged it — distinct from `approver_name`, who authorized it). Client: login screen, role-aware navigation, 401 handling in `api/client.ts`.
**Done when:** an unauthenticated request to any `/api/*` except `/health` and login is 401; an operator cannot reach the rules editor; every new entry records who created it.

### 16. Admin panel (large) — after 11, 12, 15
**Why:** the client asked for a proper admin area: users/roles, approvers, guest policies, lounges, and the existing rules editor.
**Steps:** a routed admin area (this is the point at which adding `react-router` is justified — log the decision; the operator screen stays a single view), sections for users, approvers, guest policies, lounges, and rules (move `RulesPage`/`RuleForm` here), all built on the task-11 component library. Server: the create/update/deactivate endpoints from task 12 plus users CRUD behind `requireRole('admin')`. When `schema.ts` passes ~5 tables, split it into `db/schema/*.ts` with an index re-export (keep `drizzle.config.ts` pointing at the folder) and switch the `entries` self-reference to the table-level `foreignKey()` helper for readability.
**Done when:** an admin can manage every list above without touching SQL; operators never see it.

### 17. Hebrew and RTL (large) — after 11
**Why:** the operators work in Hebrew.
**Steps:** an i18n layer (`i18next` + `react-i18next`, JSON catalogs for `he` and `en`, language in the store + `localStorage`); every user-visible string moved to the catalogs (grep the components — there are ~80); `<html dir="rtl" lang="he">` driven by the language; the component library's RTL mode (shadcn: logical CSS properties + `tailwindcss-rtl` or the `rtl:` variant; MUI: `stylis-plugin-rtl` cache); mirror the layout (tables, the guest indent, chips); keep barcodes, rule keys, flight numbers, and dates LTR inside RTL text (`dir="ltr"` / `unicode-bidi: isolate` on those cells). Get the Hebrew strings from Mark; do not machine-translate operator-facing text.
**Done when:** the full operator flow and the rules editor read correctly in Hebrew RTL, with codes still LTR; English still works.

### 18. Deployment to the on-prem machines (large) — after 10 and 15
**Why:** two on-prem machines behind a VPN; the client owns hosting. No Terraform, no cloud.
**Steps:** **one compose file per VM** (task 19 decision). The DB VM's `deploy/db/docker-compose.db.yml` (Postgres only) already exists. This task adds the app VM's `deploy/app/docker-compose.app.yml`: `api` + `web` only, **no `pg`** (the app VM is stateless; club images live in Postgres), `DATABASE_URL` → `192.168.1.1:5432` from an env file **not** in git, pinned image tags, `restart: unless-stopped`, log rotation, nginx serving the client build and proxying `/api`. It **retires the demo `docker-compose.yml` on APP.Layam**: its own `pg` container and its seed on every start must go. Also give the API a non-superuser database role instead of the `POSTGRES_USER` superuser; a `deploy.sh` (or a GH Actions job over the VPN via a self-hosted runner) that builds images, pushes/loads them on the target, runs `db:migrate` **before** switching traffic, and can roll back to the previous tag; backups belong to IsraJet's DBA (`docs/DEPLOY.md` §Backups states what is needed: a nightly `pg_dump` copied off the DB VM and one rehearsed restore); a smoke check after deploy (`/api/health` + one `/scan-fixture`). Document the runbook in `docs/DEPLOY.md`.
**Done when:** a fresh app VM goes from zero to serving with one command; a rollback is one command.

### 19. Guard `db:seed` against production (small — can land any time)
**Why:** `seedRules` (`server/src/db/seed.ts`) does an **unconditional `delete from rules` + reinsert** in one transaction. Run against a real database it wipes the rules table (and any operator edits). Seeding prod by accident must be impossible — this is exactly the "can't happen in production" class of risk (it's also the mechanism behind the dev-data reset we traced during task 6).
**Touch:** `server/src/db/seed.ts` (a guard, possibly shared with any future destructive script), a unit test; note it in `/db-reset` and `docs/DEPLOY.md` (task 18).
**Steps:** refuse to run when `NODE_ENV === 'production'` — throw a clear error and touch nothing. Optionally also refuse when the `rules` table is already non-empty unless an explicit override (a `--force` flag) is passed, so a mis-pointed dev run can't silently clobber real data either. Keep dev/CI/integration seeding working (they rely on delete-all + reseed against throwaway DBs). Confirm prod deploy (task 18) runs **migrate-only**, never seed.
**Done when:** `NODE_ENV=production npm run db:seed` refuses with a clear message and leaves the table untouched; dev/CI seeding still works; a unit test covers the refusal.
**Built (2026-10-11), extended by Mark's decisions (§3):**
- A pure `decideSeed` in `db/seedGuard.ts`. It runs in the `db:seed` command and again inside `seedRules`' transaction.
- `--force`, and an in-database **go-live lock** (`deployment_state`, migrations `0011` + `0012`, set by `npm run db:lock`). There is no unlock script.
- The production **DB VM** setup: `deploy/db/` and the runbook in [docs/DEPLOY.md](DEPLOY.md).

### 20. Global scan rules: departure airport and a ±2-day window (small–medium) — IsraJet request, next up
**Why:** IsraJet (2026-10-13). Today a pass from any airport, on any date, can be admitted. Only passengers departing from an allowed airport (TLV), with a flight within 2 days of today, should be admitted.

**Decided (Mark, 2026-10-13):**
- A `global_rules` table, managed by the admin, applies to every scan in every lounge (per-lounge may come later). Each row is a key with a **string** value, and each key is wired to its own code path. **Rows are added only by a migration that ships with the code reading them.** The admin edits values, never keys.
- The three seeded rows:
  - `departure_airports = TLV`: one IATA code, or several separated by commas.
  - `max_days_before_departure = 2`
  - `max_days_after_departure = 2`
- **The window counts days, not hours.** The barcode carries only the flight date, so "2 days" is counted from today's date in both directions. This approximation is accepted.
- **A failure denies the scan** (logged like any denied scan), with **its own deny reason for each rule**: wrong departure airport · flight too far ahead · flight too long ago. An **exceptional approval overrides it**, as it already skips the rules.
- **Values are validated per key in the application**, when the admin saves:
  - the two `max_days_*` must be positive integers;
  - `departure_airports` must be one or more 3-letter codes, separated by commas.
- **"Today" is Israel time** (`Asia/Jerusalem`). **The window edges are inclusive**: a flight exactly 2 days away is allowed.
- **The rules also apply to guest scans** (each guest carries their own boarding pass).
- **The flight date is the one the `bcbp` library resolves** from the day-of-year, so the window works across New Year (on 30–31 Dec, a 1 Jan flight is allowed). *Method replaced (2026-10-13, §3):* the goal stands, but the window uses the year nearest today, because `bcbp` only gets New Year right when the pass carries an issuance date.

**Touch:**
- `schema.ts` + a migration that creates the table and seeds the three rows.
- A pure `domain/` check, written test-first: (pass, rules, today) → ok, or which rule failed. It runs in `scanService` before rule matching.
- The three new deny reasons in `dto.ts` and the client mirror.
- `GET`/`PATCH /api/global-rules` with per-key validation, and a small admin view to edit the values.

**Still open:** none.

**Done when:**
- A non-TLV pass and an out-of-window pass are each denied with their own reason.
- An exceptional approval still admits them.
- The admin can edit the values, and invalid values are rejected.
- The domain check is unit-tested at the window edges.

### 21. Rules per lounge (medium) — after 26
**Why:** IsraJet (2026-10-13). Each lounge needs its own rules. This **reverses** "rules stay global" (the task-13 row in §3), so it gets a `/decision` when it's built.

**Decided (Mark, 2026-10-13/14):**
- `rules.lounge_id` → `lounges.id` (an FK by id, per §3), **nullable: NULL = the rule applies to every lounge** ("all lounges", `#` in the key).
- **The rule key spells ids, not codes, and separates every part with `-`**, so ids can't run together: carrier · compartment · FF · companyVar · club id (`#` = any club or none) · lounge id (`#` = all lounges). Today's `AF J##Platinum` becomes `AF-J-#-#-<club id>-#`.
- **The key is still stored** (`rules.rule_key`), computed once when a rule is written (editor save, seed, migration). Matching and the "no two ACTIVE rules share a key" check read it, so there is no runtime cost.
- **A club or lounge re-code rewrites no key**, since the key holds ids, which never change. The old rewrite and its rename-collision check go away.
- **A readable key, `ruleKeyReadable`, is computed on every read and never stored**: the same key with the current codes, e.g. `EY-#-#-LA-Gold-A`. `RuleDto`, `EntryDto` and the scan response carry it, and people see it: the editor, the log, the CSV and `/why-rule`.
- **Entries keep the key they were logged with.** Older entries hold the old format (`EY ##LA#`), and their label is that key as it is, since a key built from a scan can't be recomputed reliably.
- **Matching order:** the station's own lounge rules first (wildcard-collapse over that lounge's rules only), then the "all lounges" rules as a fallback. So a lounge-specific rule always wins. `club-options` works the same way, and now needs the station's `loungeId`.
- **A lounge where no active rule applies** (none of its own, and no "all lounges" rule) **denies every pass**, with `NO_MATCHING_RULE`, as today.
- **The migration and the seed set every existing rule to NULL ("all lounges")**, which keeps today's behaviour exactly. This replaces the earlier plan to assign every rule to lounge `A`.
- **`rules.json`:** each row gains `lounge` (a lounge code, or `#` for all lounges; all `#` today). `club` stays the readable code. The `ruleKey` field is dropped, because the seed derives it.
- **Each rule names one lounge or all of them.** A rule for lounges A and B only is two rows, differing in `lounge_id`.
- The dashboard shows rules per lounge: a lounge filter and a lounge field in the rules editor.

**Touch:**
- `schema.ts` + a migration: add `lounge_id` (nullable, no backfill needed), and recompute every `rule_key` from ids. Check row counts.
- `domain/ruleKey.ts` (key building, the lounge fallback, `clubOptions`, the readable label), written test-first.
- `rulesService`: the lounge on a rule; reject `-` in a dimension. `clubsService`: drop the key rewrite.
- `scanService`: match with the station's lounge; `club-options` takes `loungeId`.
- `rules.json` / `seedRules`; `entriesService` and `rulesService` compute `ruleKeyReadable`.
- `/why-rule` and every key shown to people.

**Still open:** none.
**Check while building:** that no dimension value (carrier, compartment, FF, companyVar) can itself contain `-`.

**Done when:**
- A scan uses its station's lounge rules first, then the "all lounges" rules.
- The editor lists and filters rules by lounge.
- No key changes when a club or lounge is re-coded, and labels show the new code at once.
- Existing data is migrated with row counts checked.

### 22. Rules CSV import + bulk deactivate (medium) — after 21
**Why:** IsraJet (2026-10-13). Rules can be exported but not imported. Copying lounge A's rules to lounge B means exporting from A and importing into B.

**Decided (Mark, 2026-10-13):**
- **The import only adds; it never overwrites.** A row is skipped when an **active** rule with the same `rule_key` exists. That is enough, because the key now includes the club id and lounge id.
- **All or nothing:** every row is validated first. If any row is invalid, nothing is saved, and the admin sees the invalid rows. The save is one transaction.
- **A preview before saving:** N new, M skipped (already exist), K invalid (listed).
- **The CSV carries both the ids and the readable codes** for club and lounge, so a file exported from one lounge can be imported into another.
- Removing rules = **bulk deactivate** (never hard-delete; the §3 decision stands), with Gmail-style checkboxes and select-all in the rules list.
- **The admin picks the target lounge at import**, and it overrides the file's lounge columns.
- **Ids are the authority, not codes.** A club id that doesn't exist in the target database, or an id whose code disagrees with the file, is an invalid row: the import aborts and shows it. Before importing rules into another database, copy its clubs and lounges first, exactly as they are. This is worked out in detail when building.
- **If an identical rule exists but is inactive, it is reactivated instead of recreated.** The preview counts it as "reactivated".
- **The dashboard gets bulk reactivate** next to bulk deactivate, using the same checkboxes.

**Touch:**
- A pure CSV parse/validate module, written test-first.
- `POST /api/rules/import`: a preview (dry run) and a commit step, re-validated in the transaction.
- A bulk deactivate endpoint.
- The export gains the id and code columns.
- In the rules list: checkboxes, select-all and the bulk action.
- Integration tests.

**Still open:** none.

**Done when:**
- Exporting lounge A and importing into lounge B adds exactly the missing rules.
- Re-importing the same file adds nothing.
- One invalid row aborts the whole import and is shown to the admin.
- Bulk deactivate works on a selection.

### 23. Modify an existing scan: move lounge, add guests, rescan, exceptional approval (medium–large) — after 21
**Why:** IsraJet (2026-10-13). A passenger scanned into lounge A may be sent to B because A is full. Staff must be able to change the lounge, add guests if allowed, rescan a crumpled barcode, or turn the entry into an exceptional approval.

**Decided (Mark, 2026-10-13):**
- **Modify the existing entry in place; keep no audit trail for now.** It can be added if IsraJet asks.
  - This changes the task-14 reasoning ("rewriting a logged entry loses the decision"), so it gets a `/decision` when it's built.
- **Moving the host to another lounge revalidates the host against that lounge's rules, and revalidates its admitted guests too.**
- **An exceptional approval** is available as one of the modifications. It skips the rules, as it does today.
- **A rescan replaces the failed or garbage scan of the same person**, instead of creating a duplicate entry.
- **Modifications are allowed only within 48 hours of the entry's creation.** The limit is a new `global_rules` row (`max_hours_to_modify_entry = 48`), added by this task's migration, per task 20's rule.
- **This absorbs the old §5 item "Retry / recovery for already-scanned visitors and guests"** (raised by Mark, 2026-10-06). Today every guest result, approved *or denied*, uses up one of the host's slots (`guest.results.length` counts toward `guest.total`). A denied slot can't be re-scanned, and a visitor scanned again gets `ALREADY_ENTERED` with no way back to their entry. This task fixes both: retry a denied guest slot, and reopen an admitted host to add guests.
- **An in-place exceptional approval keeps the entry's stored deny reasons** (Mark, 2026-10-14; see task 26), as the record of what was overridden.
- **A guest who fails revalidation on a host move:** the host still moves; the guest is left behind or denied, and the operator can admit that guest by exceptional approval.
- **Club on a move: the club picker is asked again**, then every validation runs. If the target lounge's rules don't pass, an exceptional approval is offered.
- **A rescan that turns out to be a different person or flight** (a different dedup key, or one already approved elsewhere) **is refused.** The operator sees the reason and a suggested way out, for example modifying that other entry if it's still inside the 48-hour window.
- **A guest-slot retry overwrites the denied guest's entry** (in place, like every modification).
- **Anyone at a station may modify until auth (task 15)**, then it becomes a role permission.

**Touch:**
- Endpoints on an entry: move lounge, add guests, rescan, exceptional approval.
- Services reuse the scan pipeline: global rules (task 20), rule match against the target lounge, guest policy, dedup.
- An entries-table action and a modal.
- Store slice changes, which go through `store-test-writer`.

**Still open:** none.

**Done when:**
- A move to a lounge whose rules deny the pass is refused, unless approved as an exception.
- An allowed move revalidates the guests.
- Guests can be added up to the policy.
- A rescan fixes a bad scan without double-counting.
- Modifying after 48 hours is refused.

### 24. Export scans with combined filters (medium)
**Why:** IsraJet (2026-10-13). Billing and reporting need scan exports filtered by several parameters, alone or together.

**Decided (Mark, 2026-10-13):**
- Filters combine with AND, and each filter can take several values: clubs, airlines, class (compartment), frequent flyer, a **flight-date range**, and a **separate scan-time range** (`created_at`).
- **One row per entry.** Guests are rows of their own, carrying `host_entry_id`.
- **Excel-friendly CSV** (UTF-8 with BOM, so Hebrew works later). Wherever `lounge_id` or `club_id` appear, add the code next to it, for readability only.
- On-screen pagination is **task 25**, not this one.
- **Frequent flyer is filtered both ways:** by airline designator (`EY`, `LY`, …) and by has / has none.
- **Every relevant value is a filter**, passed as query parameters. That includes lounge, approved/denied and exceptional; the full list is settled while building.
- **Times in the file are Israel local time** (`Asia/Jerusalem`).
- **A row cap exists but is very large.** The number is set in the plan, so that a normal billing export never hits it.

**Touch:**
- `GET /api/entries/export`, not capped at 50 like the live log.
- A pure filter-parse/validation module, written test-first.
- Indexes for the common filters, if the query plans need them.
- A filter panel with a download button.
- Integration tests on the filter combinations.

**Still open:** none.

**Done when:**
- Any combination of filters exports exactly the matching rows.
- The file opens correctly in Excel.
- The common filters are index-backed.

### 25. Entries pagination with the export's filters (medium) — after 24
**Why:** `GET /api/entries` returns only the 50 most recent hosts (`RECENT_LIMIT` in `entriesService.ts`), so older or quieter data can't be browsed. This was the §5 "Entries pagination" item.
**Shape:** the on-screen entries table pages through the server and reuses task 24's filter set and filter module, so the screen and the export always agree.
**Still open:** cursor or page-number paging; page size; whether the live operator view keeps its "recent 50" behaviour alongside a paged admin view.
**Done when:** any filter combination can be paged through on screen, with the same rows the export would contain.

### 26. Every deny reason, combined and stored on the entry (small–medium) — right after 20, before 21
**Why:** Mark (2026-10-13), after task 20. A scan reports only the **first** reason it fails, because the scan pipeline is an if/else chain that stops at the first denial. A JFK pass that is also out of the window shows only `DEPARTURE_AIRPORT_NOT_ALLOWED`. The person at the desk should see every reason at once. The reasons are also lost once the result card closes: they live only in the scan response, so the entry's details, the log and the export (task 24) can't show why a pass was denied. This **reverses** the decision "deny reason lives in the response, not on the row" (§3, and the governing decisions in `CLAUDE.md`), so it gets a `/decision` when it's built.

**When:** right after task 20, before 21. Tasks 21 and 23 then write every reason from the start, so nothing has to be retrofitted onto their checks.

**Decided (Mark, 2026-10-13):**
- **Every check runs, and every failure is reported together.** Nothing short-circuits: `ALREADY_ENTERED` and the guest mismatches are checked and listed even after a global rule has failed.
- **The order is fixed by one ordered constant in `domain/`**, not by the order in which the checks run, and a unit test pins it:
  `DEPARTURE_AIRPORT_NOT_ALLOWED`, `FLIGHT_DATE_UNKNOWN`, `FLIGHT_TOO_FAR_AHEAD`, `FLIGHT_TOO_LONG_AGO`, `ALREADY_ENTERED`, `GUEST_CARRIER_MISMATCH`, `GUEST_FLIGHT_MISMATCH`, `NO_MATCHING_RULE`, `CLUB_REQUIRED`.
- **`approved` stays the single flag:** one or more reasons means denied.
- **Guests:** the global rules apply to them (departure airport, date window), and so do the guest-policy checks. `NO_MATCHING_RULE` never applies to a guest.
- **A guest can fail both guest checks:** under `SAME_FLIGHT`, a guest on another carrier is both `GUEST_CARRIER_MISMATCH` and `GUEST_FLIGHT_MISMATCH` (today only the second is reported).
- **`FLIGHT_DATE_UNKNOWN` stands alone**, without the two window reasons: a pass with no date can't be placed in the window.
- **Bad requests stay rejected and log nothing** (400/404): an unknown or inactive lounge, a club that doesn't apply, a missing host, an unreadable barcode. They are bad input, not a judgement of the passenger.
- **Storage:** `entries.deny_reasons` as a Postgres **`text[]`**, nullable. Null means no reasons were recorded: an approved scan, or a row recorded before this task. There is no string↔array helper. Task 24's export can filter with `= ANY(deny_reasons)`.
- **In the app it is always `reasons: DenyReason[]`**, an empty array when approved: in the services, in `ScanResponse` (replacing `reason`), in `EntryDto`, and in the client.
- **Existing denied rows stay null:** no backfill and no recomputing. A denied row with null reasons shows **"reason not recorded"** in the details modal, the log and the export.
- **The concurrent-scan race:** the losing scan gets `ALREADY_ENTERED` and **keeps its other reasons**. In practice it has none, since only an approved scan can lose that race, but the rule holds if that changes.
- **An exceptional approval leaves the denied entry it overrides untouched, reasons included.** Its own new entry is approved and carries everything the exceptional approval needs (approver, notes, order number, service company).
- **A rescan or revalidation re-runs the checks and rewrites the reasons** (task 23's modifications).
- **An in-place exceptional approval keeps the reasons** (task 23): when it turns a denied entry into an approved one, the stored `deny_reasons` stay as the record of what was overridden. So an approved entry normally has no reasons, but an exceptionally approved one may. `approved` alone decides admitted or not.
- **The club picker comes last.** `POST /api/scan/club-options` first runs every other check: the global rules, `ALREADY_ENTERED`, and the rest. It offers the picker only if all of them pass. If any fails, it returns "no picker", and the client goes straight to `POST /api/scan`, which logs the denial with all its reasons. In this pre-check, **a pass with club options counts the rule check as passed**.
- **A new reason, `CLUB_REQUIRED`** ("This pass is admitted only with a club card"). It applies on the final `POST /api/scan` when the pass had club options, the operator picked None, and no club-less rule matches. **It is shown and stored only when every other check passes**: the scan fails on the club alone, so `CLUB_REQUIRED` is always the only reason. It is reported instead of `NO_MATCHING_RULE`, never with it.
- **Shown everywhere:** the denied card lists every reason, the details modal shows the stored reasons, and the task-24 export gains the column. **The entries table itself does not show them**: only the details modal does.
- **The reasons live in two places: in the database (`entries.deny_reasons`) and in the API response (`reasons`).**

**Touch:**
- `schema.ts`: `entries.deny_reasons text[]`. Mark runs `db:generate` / `db:migrate`; no backfill.
- `domain/`: the ordered reason constant and the collecting logic, written test-first. The test pins the order.
- `scanService`: collect every reason instead of picking the first. `getClubOptions` runs the other checks before offering the picker. Add `CLUB_REQUIRED`.
- `ScanResponse` (`reason` → `reasons: DenyReason[]`) and `EntryDto` (`reasons: DenyReason[]`), server and client mirror.
- Client: the denied card lists every reason; the details modal and the log show the stored reasons, or "reason not recorded". The store changes go through `store-test-writer`.
- Docs, when it's built: ARCHITECTURE and CLAUDE.md (the reversed invariant), DEPLOY.md (the migration), and a `/decision` entry.

**Still open:** none.

**Done when:**
- A pass that fails several checks is denied with all of them, in the pinned order. The API returns them as an array, and the entry stores the same array.
- The club picker appears only for a pass that passes every other check, and picking None where a club is needed gives `CLUB_REQUIRED` as the only reason.
- The denied card and the entry details show every reason, or "reason not recorded" for older rows.
- A bad request still logs nothing.
- The collecting logic and the order are unit-tested.

### 27. Exceptional approval for a guest — to be planned
**Why:** Mark (2026-10-13). There is no way yet to admit a guest by exceptional approval: today it exists only for a primary passenger. (Task 23 already mentions it for a guest who fails revalidation on a host move.)

**Decided:** not yet. To be planned with Mark.

**Touch:** to be settled in the plan.

**Still open:** the whole task. To settle when it's planned: where it sits in the order, how the guest is linked to the host, and whether the guest uses up one of the host's slots.

**Done when:** to be settled in the plan.

---

## 5. Not scheduled (parking lot)

Items deliberately **not** in the plan. Add them only via a `/decision`.
- Code-splitting the client bundle — re-measure after task 3; likely unnecessary.
- Drizzle 1.0 — currently a release candidate. It adds a built-in `bytea` (we use a 3-line `customType` for `clubs.image`; the generated SQL is identical) and changes drizzle-kit's migration handling. Upgrade as its own task, on its own branch, once 1.0 is stable — not mixed into feature work.
- Reporting beyond the rules CSV and the filtered scans export (task 24) — wait for the admin panel and real usage.
- **"Admitted only in lounge …" as a deny reason** (Mark, 2026-10-14, after task 21). When no rule matches at the station's lounge but the pass would match a rule in other lounges, report a new reason (e.g. `OTHER_LOUNGE_ONLY`, "Admitted only in lounges A, VIP") instead of `NO_MATCHING_RULE`. Decided: **the entry stores only the reason code** (and its own `lounge_id`, as today), never the lounge list; the list's current codes are **recomputed whenever the entry is shown**, so a re-code never leaves a stale name. **Shown during the scan, to the operator** (Mark, 2026-10-14): the denied card says where the pass *would* be admitted, so the operator can tell the customer, e.g. "Not admitted in VIP — admitted in lounges A, B". Still open: where it sits in `DENY_REASON_ORDER`; whether the scan response carries the lounge list (the card needs it at scan time); and how the card words it. Decided (Mark, 2026-10-14): "admitted elsewhere" **counts clubs as well as lounges** (a lounge that admits the pass only with a club card is listed, saying which club), and the list is **shown even when another reason also fails** (e.g. `ALREADY_ENTERED`).
- SSE / realtime, offline mode, capacity, MALAM/ERP/BI integrations — from the original POC deferral; still deferred.
- Exceptional approval *as a guest* — a product question that was raised and explicitly **not** requested; do not build it.
- Retries for scan / guest-scan API calls — client-side retry/backoff on transient (VPN) failures. Deferred to the next handoff: `POST /api/scan` is not idempotent, so a naive retry can double-log a denied scan; it wants the DB dedup index (task 7) as the backstop, deployment (task 18) for real failure signal to tune the policy, and an idempotency key alongside auth (task 15).
- Enforced branch protection / required status checks — GitHub does **not** enforce rulesets or classic branch protection on a *private* repo under the current Free personal plan (the ruleset page says so outright). So the task-10 CI is **advisory**: PRs show pass/fail and the badge tracks `staging`, but nothing hard-blocks a red merge — it's discipline until enforcement is available. To get it enforced, move the repo into a GitHub **org on the Team plan** (the natural home as the team grows — aligns with auth/roles task 15, admin panel 16, deploy 18) or a personal **Pro** plan if it covers private-repo branch protection. Do **not** make the repo public to get it free — it's IsraJet's proprietary system. Revisit before production.

---

## 6. How to work here

- **Dev:** `docker compose -f docker-compose.dev.yml up -d` (Postgres) · `server`: `cp .env.example .env`, `npm run db:migrate && npm run db:seed`, `npm run dev` (8000) · `client`: `npm run dev` (3000, proxies `/api`). Full demo: `docker compose up --build` (or `/demo`).
- **Schema change:** edit `schema.ts` → Mark runs `npm run db:generate` → review the SQL (add backfills by hand) → Mark runs `npm run db:migrate` **with a row-count check before/after** (agents hand him the commands; they never run them). Keep `seed-data/rules.json` in sync if rules gain a column.
- **Tests:** `npm test` (unit, safe) · `npm run test:integration` (needs `TEST_DATABASE_URL` → a throwaway DB, e.g. `jetlog_test`; refuses to run against `DATABASE_URL`).
- **Gate before a PR:** `/verify` (server tests + both lints + client build).
- **Branches:** `main` (docs) · `staging` (demo-safe snapshot) · `feature/*` off `staging`. Small topical commits with descriptive messages.
- **Conventions to keep:** the envelope; `@desc/@route/@access` header on every controller; controllers are plain `async` handlers (Express 5 forwards rejected promises to `errorHandler`); `domain/` stays pure; client `lib/` stays React-free.
- **Never:** run integration tests against a live DB; delete data you didn't create; commit Mark's WIP; introduce a second state store, ORM, or component library.

---

## 7. Next handoff — the UI redesign (not started)

After this plan's tasks are done, the next handoff is a **UI redesign**, driven by IsraJet's requests: make the app resemble their **legacy desktop application** (screenshots on file with Mark), **Hebrew / RTL**, and **changed operator flows**. This is a product redesign, not plumbing — large, design-led, iterative on client feedback — so it gets its own document (a fresh `docs/` handoff; this file may be dated and marked finished/legacy at that point). It **absorbs** the work task 11 deliberately defers: the remaining modal migrations, the visual overhaul, the new flows, and **task 17 (Hebrew/RTL)** — build each redesigned screen RTL-ready from the start rather than mirroring later. It builds entirely on the shadcn + Tailwind foundation from task 11, screen by screen, on bounded PRs (a good fit for `react-frontend-senior` with screenshots in hand). **Not to be started until the current plan is complete and Mark opens that handoff.**

---

*Written 2026-08-31 at the handoff from the POC build agent. When something here stops matching the code, fix this file — it's the contract the next agent trusts.*
