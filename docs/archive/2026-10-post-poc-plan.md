> **HISTORICAL — frozen, kept for the record. Do not follow or edit it.** This is the post-POC plan (tasks 1–32) and its study path (§2). Superseded by the UI-redesign plan, [PLAN.md](../PLAN.md), which carries over its unfinished tasks (15, 16, 18, 31) with their numbers. Task 28 was the last task finished in this plan (PR #35, 2026-10-23); task 17 is absorbed by the redesign tasks. Moved to `docs/archive/` on 2026-10-23; links inside may point at old paths.

# JetLog — Plan (post-POC)

**For:** the next Claude Code agent picking this up, and Mark while he studies the system.
**Status:** the POC is done and demoed. The codebase is now the real JetLog application, moving toward production on IsraJet's on-prem machines. This is the **current plan**: the study path, the task plan, and how to work here. How the system is built is in [ARCHITECTURE.md](ARCHITECTURE.md); the decisions in force are in [DECISIONS.md](DECISIONS.md); unscheduled ideas are in [BACKLOG.md](BACKLOG.md). The POC-era documents are in [archive/](archive/).

**This file was `docs/HANDOFF.md` until 2026-10-14**; older commits and decision rows say "HANDOFF". The current plan always lives at `docs/PLAN.md`: when this plan is finished it moves to `docs/archive/` (dated, marked HISTORICAL) and a fresh `PLAN.md` takes its place, continuing the task numbering.

---

## 1. The system as it is → see `docs/ARCHITECTURE.md`

**[docs/ARCHITECTURE.md](ARCHITECTURE.md) is the single source of truth for how the system is built** — the request lifecycle of one scan, the module dependency rules, the data model with its invariants, the API contract, the client state model, and the extension points. It is written from the code and kept current with it (see its maintenance contract). This handoff no longer duplicates that; read ARCHITECTURE.md first, then use §2–§4 below for the *why*, the study path, the decisions in force, and the forward task plan.

The one-line shape: `ScanPanel` → `POST /api/scan` → `controllers/scan` → `scanService.processScan` (parse → dedup → rule/guest decision → log every scan) → PostgreSQL (`rules` + `entries`) → `ScanResponse` → `ResultCard`. Two side paths: exceptional approval (`POST /api/scan/exception`) and the rules editor (`/api/rules` CRUD).

---

## 2. How to study it (for Mark)

**Read the current code as the source of truth, bottom-up. Use git history as a targeted teaching aid, not a replay** — the code diverged a lot from the POC plan (exceptional approvals, rules editor, guest policy, `isValidBcbp`, the Zustand rewrite all came after), so a chronological replay teaches versions that no longer exist. The exception: the backend domain/pipeline barely changed since Phase 3–4, so `git show 0303e59` and `git show 00c7e0e` are still a gentle, test-backed intro.

**The path:**
1. **Orient:** `CLAUDE.md`, this file, then the **decision log**, [DECISIONS.md](DECISIONS.md) (the "why"; the POC-era log is in [archive/POC_PHASES.md](archive/POC_PHASES.md)).
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

## 3. The task plan (in order — small first, large last)

**Open tasks (2026-10-22)** — the summary of the `**Status:**` line under each task; keep the two in agreement. Done: 1–14, 19, 20–26, 28, 29, 30, 32. Superseded: 27 (by 30).
- **Next, in this plan:** 31 (length limits on every free-text column).
- **To move to the next plan** (or to continue here, if the next agent finds this plan still a manageable size — Mark decides then): **15** (authentication), **16** (admin panel), **17** (Hebrew and RTL; the redesign absorbs it), **18** (production deployment, after 15). Order: the UI redesign first, then 15 and 16, then 18 (DECISIONS.md, 2026-10-21).

**How every task runs.** One task = one branch off `staging` = one focused commit. **Server first, then client, with a review stop after each:** build the server side (schema → services/controllers/endpoints + tests), stop and hand it to Mark to check; only then build the client side and hand that to Mark to check. Run `/verify` (server tests + both lints + client build), then **stop and hand it to Mark for review. Commit only after Mark says so.** Stage only your own files — Mark keeps WIP in the tree. Never run integration tests against a live DB (`npm test` is unit-only; `npm run test:integration` needs a dedicated `TEST_DATABASE_URL`). For any schema change: edit `schema.ts`, then give Mark the commands — **he runs `npm run db:generate` and `npm run db:migrate` himself; agents never run them**. Review the generated SQL (hand-add any seed/backfill), check row counts before/after his migrate, and keep `seed-data/rules.json` in sync. Log any scope/approach decision with `/decision` (it appends to [DECISIONS.md](DECISIONS.md)). **New features ship with tests that prove them — pure domain logic written test-first, new endpoints/services covered by an integration test, client `lib/` unit-tested** (this is for new work, not a rebuild of what exists). When a change touches the architecture — the module dependency rules, the request lifecycle, the data model or its invariants, the API contract, the client state model, or the extension points — update [docs/ARCHITECTURE.md](ARCHITECTURE.md) in the **same commit** (it is the source of truth; a routine change that only follows the existing patterns does not need an edit there). Update `CLAUDE.md` too when a task changes how the system works.

Tasks 1–9 are small and mechanical; 10–14 are medium features; 15–18 are the large ones and depend on the earlier ones as noted. Task 19 (appended later) is a small safety guard that can land any time — numbered last only to avoid renumbering the rest. **Tasks 20–25 are IsraJet's requests (2026-10-13) and come next, before 15–18** (see DECISIONS.md). With task 26 (every deny reason, combined and stored; Mark, 2026-10-13) the order is: 20 → 26 → 21 → 22 → 23, with 24 → 25 at any point after 20. Task 27 (exceptional approval for a guest) is still to be planned. Each is its own branch and PR, and **each starts with a plan agreed with Mark** (its open questions answered) before any code.

---

### 1. Domain cleanup — resolve the review TODOs (small)
**Status:** Done (before pull requests were used)
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
**Status:** Done (before pull requests were used)
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
**Status:** Done (before pull requests were used)
**Why:** the USB scanner (keyboard wedge) is the only input (decision in force). The camera code is dead weight and ~120 KB of bundle.
**Touch:** delete `client/src/components/CameraScanner.tsx` and `client/src/lib/barcodeCapture.ts`; in `ScanPanel.tsx` remove the `cameraOn`/`readingPhoto` state, the hidden file `<input>`, the `scanPhoto` handler, the camera branch, and the two commented-out buttons; `npm uninstall html5-qrcode` in `client/`; drop `.camera-region` from `styles.css`; update the `ScanPanel` doc-comment (it still describes the photo path).
**Done when:** `grep -rn "html5-qrcode\|CameraScanner\|barcodeCapture" client/` is empty, `client/package.json` no longer lists it, the scan input + Manual-approval button still work (drive it in the browser), bundle size drops, `/verify` green.

### 4. Refresh `.claude/agents/react-frontend-senior.md` (small)
**Status:** Done (before pull requests were used)
**Why:** its ground rules still say "no admin, no router, POC §6 binding, html5-qrcode" — every one of those is now false and would mislead delegated work.
**Steps:** rewrite the *Ground rules* and *The screen* sections to match `CLAUDE.md`: the app has an operator view and a rules-editor view (view switch in the store), Zustand is the one store, the input is the USB scanner only, the component library is whatever task 9 chose (or "TBD, see HANDOFF task 9" until then), admin/RTL work is in scope. Keep the `.claude/feedbacks/` convention and the "stay in `client/`" rule. Check `ts-backend-senior.md` for the same staleness (it references the phase plan).
**Done when:** nothing in either agent file contradicts `CLAUDE.md`.

### 5. Write `docs/ARCHITECTURE.md` from the code (small, high value)
**Status:** Done (before pull requests were used)
**Why:** learning-by-documenting — it validates this handoff against reality and becomes the durable reference once this file's "current state" section is superseded.
**Steps:** read the code (not this file) layer by layer per §2 and write: the request lifecycle of one scan, the module dependency rules (what may import what), the data model with the invariants, the API contract, the client state model, and an "extension points" section (how to add a rule dimension, an endpoint, a store slice). Where it disagrees with this file, **the code wins** — fix this file too.
**Done when:** Mark can answer "where would I add X?" from it alone.

### 6. Upgrade Express 4 → 5 (small)
**Status:** Done (before pull requests were used)
**Why:** Express 4 does not catch rejected Promises from async controllers (`asyncHandler` exists for that). Express 5 does. Node is already `>=20`.
**Touch:** `server/package.json` (+ lockfile), `@types/express` (needs v5 types), optionally drop `asyncHandler` from controllers, `docs/ARCHITECTURE.md`, §6 convention in this file.
**Steps:**
1. Bump `express` to `^5` and matching types.
2. Keep `errorHandler` and `notFound`. `asyncHandler` may be removed after tests pass.
3. Unparsed `req.body` is `undefined` in v5 (was `{}`). Existing `typeof body !== 'object' || body === null` checks already cover that.
4. `/verify` + `npm run test:integration` (dedicated `TEST_DATABASE_URL`). Confirm `/api/rules/:id` and `/api/scan/exception` still match.
**Done when:** `express` is v5, tests green, docs match whether `asyncHandler` was kept or removed.

### 7. Dedup at the database level (small)
**Status:** Done (before pull requests were used)
**Why:** dedup is check-then-insert with no lock — two scanners could both approve the same pass. A partial unique index makes the DB the referee.
**Steps:** migration adding `CREATE UNIQUE INDEX entries_one_approved_per_uniq_key ON entries (uniq_key) WHERE approved = true AND uniq_key IS NOT NULL;`. In `scanService`, wrap the insert so a unique-violation (`pg` error code `23505` on that index) is converted to the existing `ALREADY_ENTERED` denial (log the denied row as usual). Keep the pre-check as a fast path. Before migrating, check the live data for existing duplicates (`select uniq_key, count(*) from entries where approved group by 1 having count(*)>1`) and report them to Mark rather than guessing.
**Done when:** an integration test proves two concurrent approvals of the same pass yield exactly one `approved = true` row; `/verify` green.

### 8. Snapshot the guest policy onto the host entry (small)
**Status:** Done (before pull requests were used)
**Why:** a guest's policy is resolved *live* from the host's `rule_key` (`getActiveRuleByKey`), so editing that rule mid-session changes the outcome for guests already being scanned.
**Steps:** add `entries.guest_policy text` (nullable, additive); when a host is approved, copy the matched rule's `guest_policy` onto its entry; in the guest path read `host.guestPolicy` and fall back to the live lookup only when it is `null` (pre-existing rows). Show it in the details modal.
**Done when:** editing a rule after a host scan does not change that host's guest outcome (unit test on the service with a fake DB, or integration test).

### 9. Client test runner (small)
**Status:** Done (before pull requests were used)
**Why:** `lib/entriesView.ts`, `lib/rulesCsv.ts`, `lib/approvers.ts` are pure and untested.
**Steps:** add Vitest to `client/` (`npm i -D vitest`, a `client/vitest.config.ts` with `environment: 'node'` for `lib/`, `"test": "vitest run"`), write tests for `buildEntriesView` (filter/sort/group incl. the "host kept as context row when only a guest matches" case), `rulesToCsv` (quoting, BOM-less content, column order), and `isApprover`. Add `cd client && npm test` to the `/verify` skill.
**Done when:** `/verify` runs client tests and they pass.

### 10. Continuous integration (medium)
**Status:** Done — PR #8 (and #9)
**Why:** `/verify` is manual; nothing stops a red commit.
**Steps:** `.github/workflows/ci.yml` on push/PR: Node 22, `npm ci` in both packages, server lint + unit tests, client lint + build + tests, **and** the server integration suite against a `postgres:16` service container with `TEST_DATABASE_URL` pointing at it (never at a real DB). Cache `node_modules`. Badge in the README.
**Done when:** a PR shows the gate; a deliberately failing test blocks it.

### 11. Adopt shadcn + Tailwind — the UI foundation (small)
**Status:** Done — PR #10
**Why:** every UI effort ahead (admin panel, the client-requested redesign, Hebrew/RTL) needs one component system in place first. This task **only establishes the foundation** — it is deliberately NOT the redesign. The big visual/flow overhaul is a separate handoff (see "Next handoff" at the bottom). Doing this thin-and-first means all later UI is built once, on the right system, instead of migrated twice. Decision in force: **shadcn + Tailwind, not MUI** (DECISIONS.md).
**Steps:**
1. Install Tailwind + shadcn: Vite plugin, `components.json`, the `@/` path alias. Preflight reset is expected to shift plain-CSS styling — plan for it in step 4.
2. Define the **theme-token layer** (Tailwind config + CSS variables). This is the payoff: "make it look like the legacy desktop app" later becomes largely a token change, not a per-component rewrite.
3. Adopt a **thin app-level wrapper** pattern around shadcn primitives (one touch-point per widget), so a future restyle or version bump has a single place to change.
4. **Prove it on one real component:** a `Button` primitive **plus** `EntryDetailsModal` migrated onto shadcn `Dialog` (Dialog is the hardest primitive — overlay/Esc/focus — so one real migration validates the setup). Keep the store-driven open/close semantics. Regression-check the operator + rules screens against the preflight reset.
5. **Explicitly deferred to the UI-redesign handoff:** the other two modals (`ExceptionForm`, `RuleForm`), the visual redesign to match the legacy app, the changed flows, and Hebrew/RTL (task 17). Do not start them here. The `lib/` (pure) → `hooks/` (wiring) → `components/` (render) split stays intact so presentation swaps never touch logic.
**Done when:** Tailwind + shadcn installed with tokens + the wrapper pattern; `Button` and `EntryDetailsModal` run on shadcn; no visual regressions on the operator + rules screens; `/verify` green.

### 12. Approvers and guest policies as database tables (medium) — prerequisite for the admin panel
**Status:** Done — PR #11 (approvers became a table; guest policies stayed a vocabulary, by decision)
**Why:** both are hardcoded allowlists (`domain/approvers.ts`, `domain/guestPolicy.ts`) with a hand-copied list in the client. The admin panel must manage them.
**Steps:** tables `approvers (id, name, kind: 'internal'|'external', company, active)` and `guest_policies (code, label, active)` with migrations that seed today's four approvers and two policies; `GET /api/approvers` + `GET /api/guest-policies` (+ create/update/deactivate for the admin panel later); `exceptionApprovalService` validates against the table instead of the array; `rulesService` validates `guest_policy` against the table; the client fetches both lists on load into the store and deletes `client/src/lib/approvers.ts`. Keep `guestSatisfiesPolicy` keyed on the two known codes (they carry behavior); unknown codes are rejected at write time. Note the design nuance Mark raised: approvers include *external-company contacts*, hence the `kind` and `company` columns.
**Done when:** adding an approver by SQL makes it appear in the exception form without a deploy; the hardcoded arrays are gone.

### 13. Multi-lounge (medium)
**Status:** Done — PR #14 (and #15)
**Why:** `lounge` is hardcoded `'C'` (`scanService.ts` TODO). IsraJet starts with 2 lounges, later 4.
**Built** — see the 2026-09-30 row in DECISIONS.md for how it landed (one seeded lounge `A`, editable codes, a lounges management page).
**Steps:** `lounges (code, name, active)` table seeded with the real codes (get them from Mark); each station selects its lounge once (persist in the store + `localStorage`) and sends `lounge` with every scan/exception; `entries.lounge` becomes an FK; the entries table gets a lounge column and filter; rules are global for now (per-lounge rules are a later decision — log it if it comes up).
**Done when:** two browser tabs set to different lounges produce entries tagged accordingly and the table filters by lounge.

### 14. Club selection at scan time (medium)
**Status:** Done — PR #16
**Built** — see the 2026-10-05 clubs row in DECISIONS.md for how it landed (global clubs table with images, "ask first, log once", clubs by id, Guest club retired, FF tier dropped).
**Why:** the loyalty *tier* / `club` is not in the barcode, so `club`-keyed rules (e.g. `EY ##LAGold`) can never match from a bare scan.
**Steps:** decide the flow with Mark first: after a scan, when the matched carrier has any active rule with a non-`#` `club`, show a popup listing that carrier's club values (derive them from the rules table — the same value-set logic `ruleKey.ts` uses) plus "none"; the operator's choice is sent as a second call (`POST /api/scan` with `{ rawBarcode, club }`) or as a re-evaluation of the just-created entry — choose the simpler and log it. Store the chosen club on the entry. The `frequent_flyer` *tier* dimension (BA's `1`/`2`) is the same problem and can share the popup. This will require a migration, changes to the scan service, a UI modal, and more.
**Done when:** scanning an EY pass and choosing "Gold" matches `EY ##LAGold`; choosing "none" behaves exactly as today.

### 15. Authentication, roles, and the station model (large) — prerequisite for 16
**Status:** Later — moved to the next plan, after the UI redesign (Mark, 2026-10-21). See BACKLOG.md, "First features of the next plan".
**Why:** everything is public. Production needs operators, managers, and admins, and a per-station login.
**Steps:** decide the identity source with Mark (local users table vs the client's SSO — on-prem suggests local first); `users (id, username, password_hash, role, active)` with bcrypt/argon2; login endpoint issuing an httpOnly-cookie session or JWT; `requireAuth` / `requireRole` middleware; roles `operator` (scan, exceptions), `manager` (+ rules, approvers), `admin` (+ users); record `user_id` on entries (who scanned) and on exceptional approvals (who logged it — distinct from `approver_name`, who authorized it). Client: login screen, role-aware navigation, 401 handling in `api/client.ts`.
**Done when:** an unauthenticated request to any `/api/*` except `/health` and login is 401; an operator cannot reach the rules editor; every new entry records who created it.

### 16. Admin panel (large) — after 11, 12, 15
**Status:** Later — moved to the next plan with task 15 (Mark, 2026-10-21): the redesign builds the admin sections; authentication then gates them.
**Why:** the client asked for a proper admin area: users/roles, approvers, guest policies, lounges, and the existing rules editor.
**Steps:** a routed admin area (this is the point at which adding `react-router` is justified — log the decision; the operator screen stays a single view), sections for users, approvers, guest policies, lounges, and rules (move `RulesPage`/`RuleForm` here), all built on the task-11 component library. Server: the create/update/deactivate endpoints from task 12 plus users CRUD behind `requireRole('admin')`. When `schema.ts` passes ~5 tables, split it into `db/schema/*.ts` with an index re-export (keep `drizzle.config.ts` pointing at the folder) and switch the `entries` self-reference to the table-level `foreignKey()` helper for readability.
**Done when:** an admin can manage every list above without touching SQL; operators never see it.

### 17. Hebrew and RTL (large) — after 11
**Status:** Later — the next plan's UI redesign absorbs it
**Why:** the operators work in Hebrew.
**Steps:** an i18n layer (`i18next` + `react-i18next`, JSON catalogs for `he` and `en`, language in the store + `localStorage`); every user-visible string moved to the catalogs (grep the components — there are ~80); `<html dir="rtl" lang="he">` driven by the language; the component library's RTL mode (shadcn: logical CSS properties + `tailwindcss-rtl` or the `rtl:` variant; MUI: `stylis-plugin-rtl` cache); mirror the layout (tables, the guest indent, chips); keep barcodes, rule keys, flight numbers, and dates LTR inside RTL text (`dir="ltr"` / `unicode-bidi: isolate` on those cells). Get the Hebrew strings from Mark; do not machine-translate operator-facing text.
**Done when:** the full operator flow and the rules editor read correctly in Hebrew RTL, with codes still LTR; English still works.

### 18. Deployment to the on-prem machines (large) — after 10 and 15
**Status:** Later — moved to the next plan, after task 15
**Decided (Mark, 2026-10-21): production deployment comes after authentication** (task 15), so it moves to the next plan with it. A test deployment is already running; DEPLOY.md doesn't describe it yet, and this task should record it.
**Why:** two on-prem machines behind a VPN; the client owns hosting. No Terraform, no cloud.
**Steps:** **one compose file per VM** (task 19 decision). The DB VM's `deploy/db/docker-compose.db.yml` (Postgres only) already exists. This task adds the app VM's `deploy/app/docker-compose.app.yml`: `api` + `web` only, **no `pg`** (the app VM is stateless; club images live in Postgres), `DATABASE_URL` → `192.168.1.1:5432` from an env file **not** in git, pinned image tags, `restart: unless-stopped`, log rotation, nginx serving the client build and proxying `/api`. It **retires the demo `docker-compose.yml` on APP.Layam**: its own `pg` container and its seed on every start must go. Also give the API a non-superuser database role instead of the `POSTGRES_USER` superuser; a `deploy.sh` (or a GH Actions job over the VPN via a self-hosted runner) that builds images, pushes/loads them on the target, runs `db:migrate` **before** switching traffic, and can roll back to the previous tag; backups belong to IsraJet's DBA (`docs/DEPLOY.md` §Backups states what is needed: a nightly `pg_dump` copied off the DB VM and one rehearsed restore); a smoke check after deploy (`/api/health` + one `/scan-fixture`). Document the runbook in `docs/DEPLOY.md`.
**Done when:** a fresh app VM goes from zero to serving with one command; a rollback is one command.

### 19. Guard `db:seed` against production (small — can land any time)
**Status:** Done — PR #18
**Why:** `seedRules` (`server/src/db/seed.ts`) does an **unconditional `delete from rules` + reinsert** in one transaction. Run against a real database it wipes the rules table (and any operator edits). Seeding prod by accident must be impossible — this is exactly the "can't happen in production" class of risk (it's also the mechanism behind the dev-data reset we traced during task 6).
**Touch:** `server/src/db/seed.ts` (a guard, possibly shared with any future destructive script), a unit test; note it in `/db-reset` and `docs/DEPLOY.md` (task 18).
**Steps:** refuse to run when `NODE_ENV === 'production'` — throw a clear error and touch nothing. Optionally also refuse when the `rules` table is already non-empty unless an explicit override (a `--force` flag) is passed, so a mis-pointed dev run can't silently clobber real data either. Keep dev/CI/integration seeding working (they rely on delete-all + reseed against throwaway DBs). Confirm prod deploy (task 18) runs **migrate-only**, never seed.
**Done when:** `NODE_ENV=production npm run db:seed` refuses with a clear message and leaves the table untouched; dev/CI seeding still works; a unit test covers the refusal.
**Built (2026-10-11), extended by Mark's decisions (DECISIONS.md):**
- A pure `decideSeed` in `db/seedGuard.ts`. It runs in the `db:seed` command and again inside `seedRules`' transaction.
- `--force`, and an in-database **go-live lock** (`deployment_state`, migrations `0011` + `0012`, set by `npm run db:lock`). There is no unlock script.
- The production **DB VM** setup: `deploy/db/` and the runbook in [docs/DEPLOY.md](DEPLOY.md).

### 20. Global scan rules: departure airport and a ±2-day window (small–medium) — IsraJet request, next up
**Status:** Done — PR #21
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
- **The flight date is the one the `bcbp` library resolves** from the day-of-year, so the window works across New Year (on 30–31 Dec, a 1 Jan flight is allowed). *Method replaced (2026-10-13, DECISIONS.md):* the goal stands, but the window uses the year nearest today, because `bcbp` only gets New Year right when the pass carries an issuance date.

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
**Status:** Done — PR #23
**Why:** IsraJet (2026-10-13). Each lounge needs its own rules. This **reverses** "rules stay global" (the task-13 row in DECISIONS.md), so it gets a `/decision` when it's built.

**Decided (Mark, 2026-10-13/14):**
- `rules.lounge_id` → `lounges.id` (an FK by id, per DECISIONS.md), **nullable: NULL = the rule applies to every lounge** ("all lounges", `#` in the key).
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
**Status:** Done — PR #24
**Why:** IsraJet (2026-10-13). Rules can be exported but not imported. Copying lounge A's rules to lounge B means exporting from A and importing into B.

**Decided (Mark, 2026-10-13):**
- **The import only adds; it never overwrites.** A row is skipped when an **active** rule with the same `rule_key` exists. That is enough, because the key now includes the club id and lounge id.
- **All or nothing:** every row is validated first. If any row is invalid, nothing is saved, and the admin sees the invalid rows. The save is one transaction.
- **A preview before saving:** N new, M skipped (already exist), K invalid (listed).
- **The CSV carries both the ids and the readable codes** for club and lounge, so a file exported from one lounge can be imported into another.
- Removing rules = **bulk deactivate** (never hard-delete; the DECISIONS.md decision stands), with Gmail-style checkboxes and select-all in the rules list.
- **The admin picks the target lounge at import**, and it overrides the file's lounge columns.
- **Ids are the authority, not codes.** A club id that doesn't exist in the target database, or an id whose code disagrees with the file, is an invalid row: the import aborts and shows it. Before importing rules into another database, copy its clubs and lounges first, exactly as they are. This is worked out in detail when building.
- **If an identical rule exists but is inactive, it is reactivated instead of recreated.** The preview counts it as "reactivated".
- **The dashboard gets bulk reactivate** next to bulk deactivate, using the same checkboxes.

**Decided (Mark, 2026-10-14/15, planning the build):**
- **Target:** one active lounge, or "All lounges (#)". One target per import. The file's `lounge`/`lounge_id` columns never set the lounge. **A file whose `lounge_id` column holds more than one value is refused whole** ("this file mixes rules from several lounges — export one lounge's rules"), because its rows would collide once moved to one target.
- **Columns read:** `carrier`, `compartment`, `frequent_flyer`, `company_var`, `club_id`, `club`, `description`, `allowed_guests`, `guest_policy`, `active` (+ `lounge_id` for the mixed-lounge check only). Ignored: `id`, `rule_key`, `rule_key_readable`, `lounge`. The key is rebuilt from the columns and the target lounge, never taken from the file. `club_id` is required: an export from before this change is refused ("re-export it"). Header names are found in any order; a `;`-separated file is refused with a clear message.
- **Existence is by `rule_key`.** An ACTIVE rule with the same key → skipped (the key alone decides). `allowed_guests`, `guest_policy` and `description` stay out of the key (they say what a rule grants, not which passes it admits); they count only for reactivation.
- **Reactivation:** an INACTIVE rule with the same key **and** the same description, allowed guests and guest policy is reactivated as it is (lowest id if several). Otherwise the row is added. The import never edits an existing rule's fields.
- **Rows with `active=false` are not imported**; the preview lists them by line in a warning section (Mark, 2026-10-15: no toast — the preview already shows it where the admin is looking).
- **Clubs:** `club_id` must exist, be **active**, and its current code must equal the file's `club` (`#`/empty in both = any club). Otherwise the row is invalid, and the message says what this database holds (e.g. "club 7 is 'Silver' here; 'Gold' is 9").
- **Two endpoints, one body `{ csv, loungeId }`:** `POST /api/rules/import/preview` (saves nothing) and `POST /api/rules/import` (re-plans inside one transaction that locks `rules`; any invalid row → nothing saved). The CSV is parsed on the server; the column names are mirrored in the client export and pinned by a test on each side (noted in both senior agents).
- **Limits, enforced on the server and checked first on the client:** an import file ≤ 1 MB and ≤ 2,000 rule rows; a bulk action ≤ 1,000 ids.
- **Bulk activate/deactivate** (`setRulesActive`): all or nothing. A reactivation that would give two active rules one key (inside the selection or against an active rule) → 409 listing every clash, nothing changed; the client shows it in an error toast.
- **"No two ACTIVE rules share a `rule_key`" becomes a database guarantee:** a partial unique index on `rules (rule_key) WHERE active`. Mark checked his dev DB: no active duplicates. Its unique violation becomes the same 409 in the editor, the import and the bulk action.
- **Bulk hard delete of rules** (reverses "rules are never hard-deleted" — see DECISIONS.md): only **inactive** rules can be deleted (deactivate first, in bulk, then delete, in bulk, after a confirmation showing the count); a selection with an active rule is refused whole. Works on a locked database (an admin's choice, not a script). No FK references `rules`, so the log is untouched. Clubs and lounges stay deactivate-only.
- **The import and bulk actions work on a locked database.**
- **Selection:** select-all selects the rows shown; changing a filter or the search clears the selection.
- **Export:** gains `club_id` next to `club` and `lounge_id` next to `lounge` (`#` = none; the import also accepts empty).
- **Toasts:** shadcn Sonner, for what has nowhere else to show: a file refused whole (e.g. the `;` refusal), a failed bulk action (e.g. the 409) and a success. Errors stay up 15 s, the rest Sonner's default. Invalid and inactive rows are shown in the preview, not in toasts.
- **Names:** `parseRulesCsv` (server) / `rulesToCsv` (client), `planRulesImport`, `RulesImportPlan`, `rulesImportService`, `setRulesActive`.

**Touch:**
- `schema.ts` + a migration: the partial unique index.
- `domain/ruleFields.ts` (the rule-field validation `prepare()` and the import share, every error on a row) and `domain/rulesCsv.ts` (`parseRulesCsv`, `planRulesImport`), written test-first.
- `services/rulesImportService.ts`; `rulesService`: `setRulesActive`, `deleteRules`, the 23505 → 409.
- `POST /api/rules/import/preview`, `POST /api/rules/import`, `POST /api/rules/bulk-active`, `POST /api/rules/bulk-delete`.
- Client: the export's id columns, the import dialog, checkboxes, select-all and the bulk actions, toasts.
- Integration tests.

**Still open:** none.

**Done when:**
- Exporting lounge A and importing into lounge B adds exactly the missing rules.
- Re-importing the same file adds nothing.
- One invalid row aborts the whole import and is shown to the admin.
- Bulk deactivate, reactivate and delete work on a selection.

### 23. Modify an existing scan: move lounge, add guests, rescan, exceptional approval (medium–large) — after 21
**Status:** Done — PR #26 (and #27)
**Why:** IsraJet (2026-10-13). A passenger scanned into lounge A may be sent to B because A is full. Staff must be able to change the lounge, add guests if allowed, rescan a crumpled barcode, or turn the entry into an exceptional approval.

**Decided (Mark, 2026-10-13):**
- **Modify the existing entry in place; keep no audit trail for now.** It can be added if IsraJet asks.
  - This changes the task-14 reasoning ("rewriting a logged entry loses the decision"), so it gets a `/decision` when it's built.
- **Moving the host to another lounge revalidates the host against that lounge's rules, and revalidates its admitted guests too.**
- **An exceptional approval** is available as one of the modifications. It skips the rules, as it does today.
- **A rescan replaces the failed or garbage scan of the same person**, instead of creating a duplicate entry.
- **Modifications are allowed only within 48 hours of the entry's creation.** The limit is a new `global_rules` row (`max_hours_to_modify_entry = 48`), added by this task's migration, per task 20's rule.
- **This absorbs the old backlog item "Retry / recovery for already-scanned visitors and guests"** (raised by Mark, 2026-10-06). Today every guest result, approved *or denied*, uses up one of the host's slots (`guest.results.length` counts toward `guest.total`). A denied slot can't be re-scanned, and a visitor scanned again gets `ALREADY_ENTERED` with no way back to their entry. This task fixes both: retry a denied guest slot, and reopen an admitted host to add guests.
- **An in-place exceptional approval keeps the entry's stored deny reasons** (Mark, 2026-10-14; see task 26), as the record of what was overridden.
- **A guest who fails revalidation on a host move:** the host still moves; the guest is left behind or denied, and the operator can admit that guest by exceptional approval.
- **Club on a move: the club picker is asked again**, then every validation runs. If the target lounge's rules don't pass, an exceptional approval is offered.
- **A rescan that turns out to be a different person or flight** (a different dedup key, or one already approved elsewhere) **is refused.** The operator sees the reason and a suggested way out, for example modifying that other entry if it's still inside the 48-hour window.
- **A guest-slot retry overwrites the denied guest's entry** (in place, like every modification).
- **Anyone at a station may modify until auth (task 15)**, then it becomes a role permission.

**Decided (Mark, 2026-10-15, planning the build):**
- **One shared re-evaluation.** A move, a rescan and a guest retry re-run the scan checks on the existing entry with one thing changed (lounge, barcode). Dedup ignores the entry itself.
- **Guest places are enforced by the server.** The host's allowance is snapshotted at admission (`entries.allowed_guests`, like `guest_policy`). Places left = allowance − **approved** guests, so a denied guest no longer uses up a place. A guest beyond the allowance is refused (400, nothing logged). Entries from before the column count as 0. A guest scan also needs its host approved, not voided, and inside the modify window.
- **Move (host only):** the target must be an active lounge; the club picker is asked again (club options for the target), then every check runs.
  - If the host fails the target's checks, **nothing changes**: the operator sees every reason and an **Approve as exception** button that moves and approves in one step.
  - If it passes, the host is updated in place (lounge, rule, club, policy and allowance snapshots).
  - **Its guests move with it** and are re-checked against the new policy and allowance. A guest who now fails stays logged as denied, with reasons. If the new rule allows fewer guests, the most recently admitted extras are denied with a new reason, **`GUEST_LIMIT_REACHED`** ("Guest limit reached").
  - An exception-approved host moves without being re-checked (the exception stands), and its guests move with it.
- **Exceptional approval in place, for hosts and guests.** It works on a denied entry, keeps its stored deny reasons, and keeps the pass's dedup key, so the same pass can't be admitted twice.
  - An exception overrides a guest's policy and the guest limit.
- **Exception guests: the approver sets "Guests allowed"** on every exceptional approval (new or in place), 0–100. It defaults to the matched rule's allowance if the pass matched one, otherwise 0. Mark's example: the president arriving with his guards.
  - **Every guest of an exception-approved host is itself exceptional**, with no guest-policy check, only the count. It **inherits the host's approver**.
  - Such a guest can be added **without a barcode** (guards may have no pass).
  - This absorbs most of task 27; what's left of it is decided when it's planned.
- **Rescan:** only a denied or garbage (invalid) entry, never an approved one. It replaces that entry's scan in place, and is how a denied guest's place is retried.
  - If the original was readable, a pass with a different passenger/flight key is refused. If that pass is already approved elsewhere, the message names the entry ("this pass belongs to entry #N — modify that one").
  - If the original was garbage, there is no key to compare, so any readable pass is accepted.
- **Void an approved entry scanned by mistake.** A **reason** and an **approver** are required, within the modify window. The entry stays in the log with a **VOIDED** mark, the reason, the approver and the time, and is no longer approved, so the pass can be scanned again correctly. **The host's guests are voided too**, with the same reason. A voided entry can't be modified.
- **"Already entered" leads back to the entry.** The scan response carries the id of the approved entry, and the result card offers **Open their entry**, so it can be modified there. When "already entered" is the only reason, the card **no longer offers Approve anyway** (Mark, 2026-10-15): it would log the same person twice.
- **Approve anyway approves the scanned entry itself** (Mark, 2026-10-15): the result card's exception is the in-place one (the entry keeps its deny reasons and its pass key; a pass already admitted elsewhere is refused, naming that entry), never a second entry. **Manual approval** (no barcode at all) still logs a new entry.
- **Exceptional rows in the log show their scan** (Mark, 2026-10-15): since Approve anyway approves a real scanned entry, an exceptional row shows its carrier, flight, class, companyVar and rule like any other row (a manual approval with no barcode shows "—"; an exception on a garbage scan keeps the ⚠ Invalid barcode marker). The **⚡ Exceptional** chip and the approver move to the result column, under the status.
- **The log gets a ⊘ Voided filter**; **✕ Denied** no longer lists voided entries (Mark, 2026-10-15).
- **Exceptional guests stay unchecked** (Mark, 2026-10-15): a guest with a boarding pass scans it, one without is added with **Add guest without barcode**.
- **The modify window is a global rule**, `max_hours_to_modify_entry` (seeded `48` by the migration; 1–720 whole hours). It is counted from the entry's creation; a modification doesn't restart it. Scans never check it: it's an operator rule, shown on the Global rules page under its own heading, **"Modifying entries"**. After it, every modification is refused (409).
- **"Modified" marker:** `entries.modified_at` is set by every modification and shown in the log and the details window ("modified at HH:MM"). It's a timestamp only, not an audit trail.

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
**Status:** Done — PR #28
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

**Decided (Mark, 2026-10-15, planning the build):**
- **The filters drive both the on-screen log and the export.** `GET /api/entries` and `GET /api/entries/export` take the same query parameters, read by one pure module in `domain/`.
- **Guests travel with their host, and the host with its guests.** A filter selects whole parties (a host and its guests): if any member of a party matches every filter, the whole party is shown and exported. So a filter for one airline can export a guest of another airline.
- **An optional strict mode** (Mark, 2026-10-15): `match=entry` judges each row on its own, and the export holds only the rows that match. The default (`match=party`) keeps parties together. The log always returns whole parties and marks each row `matchesFilters`; in strict mode the client hides the guests that don't match and greys out a host shown only as context. The difference is explained in an ⓘ tooltip next to the switch and in the user guide.
- **The on-screen log shows the newest 2,000 hosts** (was 50), with their guests, until pagination (task 25) settles it.
- **Export row cap: 100,000 rows.** If more match, the export is refused (400, "narrow the filters"), never cut short: a silently truncated billing file is worse than a refusal.
- **The filters** (AND between filters; several values within one filter mean any of them):
  - `loungeId` and `clubId`: ids; `clubId` also takes `none` (a club-less entry).
  - `carrier`, `compartment`: codes.
  - `frequentFlyer`: airline designators, plus `none` (no frequent flyer) and `any` (has one).
  - `flightDateFrom` / `flightDateTo` and `scanDateFrom` / `scanDateTo`: `YYYY-MM-DD`, both ends included; scan dates are whole days in Israel time.
  - `status`: `approved`, `denied`, `voided` (voided is its own status, as in the log).
  - `type`: `host`, `guest`.
  - `exceptional`, `modified`: `true` or `false`.
  - `denyReason`: deny-reason codes; an entry matches if it has any of them.
- **Query format:** comma-separated values (`?carrier=EY,LY&status=denied,voided`). An unknown parameter or a bad value is a 400 naming it.
- **CSV columns:** ids with codes next to them (lounge, club), the parsed pass, status, deny reasons, both rule keys, the exceptional fields, `allowed_guests`, `modified_at`, the void fields, `created_at`, and `is_valid_bcbp` (an unreadable scan is marked, not dropped). Times are Israel local time.
- **The export reuses the log's read context** (current codes, `ruleKeyReadable`), so the file and the screen spell things the same way.
- **Indexes:** scan time and lounge are already indexed; add one on flight date if the query plans need it. Checked with EXPLAIN on `jetlog_test` loaded with Mark's real-volume barcode sheet (never committed).

**Still open:** none.

**Done when:**
- Any combination of filters exports exactly the matching rows.
- The file opens correctly in Excel.
- The common filters are index-backed.

### 25. Entries pagination with the export's filters (medium) — after 24
**Status:** Done — PR #29
**Why:** `GET /api/entries` returns only the most recent hosts (2,000 since task 24, 50 before) (`RECENT_LIMIT` in `entriesService.ts`), so older or quieter data can't be browsed. This was the BACKLOG.md "Entries pagination" item.
**Shape:** the on-screen entries table pages through the server. It is already filtered by task 24's filters (same module, same parameters), so this task adds only the paging, and the screen and the export always agree.
**Decided (Mark, 2026-10-18):**
- **Infinite scroll, not page numbers.** The log loads the newest page, then the next page as the user scrolls to the bottom (with a **Load more** button as a fallback). Nobody pages through everything on screen: for whole periods they export to Excel (or, later, Power BI on the database).
- **A page counts hosts (parties), not rows:** 100 hosts per page, each with all its guests, so a party is never split across pages.
- **Cursor (keyset) paging** on the hosts' `(created_at, id)`, newest first: deep pages stay fast, and a scan that arrives while someone is reading doesn't shift the pages under them. The cursor is opaque to the client and carries the exact database timestamp (microseconds), so no row is skipped or repeated.
- **The live operator view stays live:** after a scan the newest page is fetched again and merged on top of what is already loaded, so the user's scroll isn't lost. A filter change starts again from the first page.
- **The first page reports how many hosts match**, so the screen can say "showing 300 of 12,345".
- **The 2,000-host cap goes:** paging replaces it.
- **The export holds up to 500,000 rows** (was 100,000): about two years of data, and one year is under 200,000. It is **counted first** (over the cap is refused before anything else is read) and then **streamed in batches of parties**, so rows never pile up in server memory: only the list of party ids (a few MB at the cap) grows with the export. Above the cap it is still refused, never cut short.
- **Sorting by a column sorts the loaded rows only** (as it always has): a known limitation, noted in the help.
- **Rules get no pagination:** a few hundred rules load and search instantly on screen. Noted in BACKLOG.md: past ~5,000 rules, ask Mark about paging them.

**Still open:** none.
**Done when:** any filter combination can be paged through on screen, with the same rows the export would contain.

### 26. Every deny reason, combined and stored on the entry (small–medium) — right after 20, before 21
**Status:** Done — PR #22
**Why:** Mark (2026-10-13), after task 20. A scan reports only the **first** reason it fails, because the scan pipeline is an if/else chain that stops at the first denial. A JFK pass that is also out of the window shows only `DEPARTURE_AIRPORT_NOT_ALLOWED`. The person at the desk should see every reason at once. The reasons are also lost once the result card closes: they live only in the scan response, so the entry's details, the log and the export (task 24) can't show why a pass was denied. This **reverses** the decision "deny reason lives in the response, not on the row" (DECISIONS.md, and the governing decisions in `CLAUDE.md`), so it gets a `/decision` when it's built.

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
**Status:** Superseded by task 30
**Why:** Mark (2026-10-13). There is no way yet to admit a guest by exceptional approval: today it exists only for a primary passenger. (Task 23 already mentions it for a guest who fails revalidation on a host move.)

**Decided:** not yet. To be planned with Mark.

**Touch:** to be settled in the plan.

**Still open:** the whole task. To settle when it's planned: where it sits in the order, how the guest is linked to the host, and whether the guest uses up one of the host's slots.

**Superseded (Mark, 2026-10-20):** IsraJet decided that guests belong only to hosts approved by the rules (task 30), so there are no exceptional guests to plan. One question about refused guests remains open in task 30.

**Done when:** to be settled in the plan.

### 28. The user guide explains how duplicates are detected (tiny, docs only)
**Status:** Done — PR #35
**Why:** IsraJet (2026-10-20) changed the name in a few barcodes and was surprised that JetLog still reported them as already entered. The guide doesn't say how a duplicate is recognised.

**Decided (Mark, 2026-10-20):**
- **Add it to `docs/USER_GUIDE.md`**, the source of the planned in-app help page, through the `user-guide-writer` agent.
- **What it says:**
  - A pass is a duplicate when five fields match: flight date (day of the year), airline, flight number, check-in sequence number and departure airport. Example: `007-EY-0594-0062-TLV` (7 January, Etihad, flight 594, the 62nd passenger checked in, from TLV).
  - The passenger's name and the rest of the barcode are not compared.
  - **Why:** the sequence number identifies one passenger on one flight. The same pass can come as paper or mobile, or be reprinted, and names are truncated and spelled inconsistently. Comparing the whole barcode would let the same person in twice.
  - **To test a duplicate,** change the sequence number (or the flight, date or airport), not the name.

**Touch:** `docs/USER_GUIDE.md` only.

**Still open:** none.

**Done when:** the guide explains the five fields with the example, and why the name doesn't count.

### 29. The entries export: the raw barcode, and the rule as it was at scan time (small–medium, one migration)
**Status:** Done (PR #31)
**Why:** IsraJet (2026-10-20) needs the raw barcode in the entries export, and the matched rule's description and comments as they were when the entry was made.

**Decided (Mark, 2026-10-20):**
- **The export gains `raw_barcode`.** It contains the passenger's name, so the file is personal data; IsraJet accepts that.
- **Rules gain a `comments` field** (text, optional): a migration, a field in the rules editor, and a column in the rules CSV export and import. The client and server CSV columns are mirrored by hand and pinned by a test on each side.
- **Three new columns on `entries`, written when the entry is scanned and never changed afterwards by rule edits or code renames** (names chosen by Mark):
  - `readable_rule_key_at_scan_time`
  - `rule_description_at_scan_time`
  - `rule_comments_at_scan_time`
  - Only a rescan writes them again.
  - In TypeScript: `readableRuleKeyAtScanTime`, `ruleDescriptionAtScanTime`, `ruleCommentsAtScanTime`.
- **This is a deliberate exception to "store ids, compute what people read":** IsraJet wants the entry to read as it did at the moment of entry. It gets a `/decision` when built.
- **`entries.rule_key` (ids) stays as it is.** It is internal; the at-scan-time readable key is what people read.
- **The export gains the three columns.**
- **The three values are stored in the database** (columns on `entries`), not computed on read (Mark, 2026-10-21).
- **A move to another lounge re-decides the rule, so it rewrites them too**, like a rescan (Mark, 2026-10-21). If the move fails, nothing changes: the passengers stay recorded in their original lounge, with their original values. An exception approval keeps what was captured.
- **Entries logged before the migration are backfilled once** in the migration, from the current rule (by `rule_key`) and the current codes: the best information available. The decision row says these older rows are a later reconstruction (Mark, 2026-10-21).
- **The log and the details window show the at-scan-time readable key**, falling back to the computed one for a row without it; the details window also shows the description and comments (Mark, 2026-10-21).
- **No matched rule, no key** (Mark, 2026-10-21): when no rule matched, `entries.rule_key` and the three at-scan-time columns are **null**, not the key the scan tried. A guest is never matched against a rule, so all four are null on every new guest. When a rule matched and another check failed (e.g. the date window), all four are stored. The scan response's `ruleKey` / `ruleKeyReadable` mirror the row (null). Rows logged before this keep their keys.
- **An "approve anyway" on a refused move** rewrites the three strings together with `rule_key` (the target lounge's key), so the key and its readable form always agree. A plain in-place exception keeps them (Mark, 2026-10-21).
- **The backfill uses only an ACTIVE rule** with the row's `rule_key`. With none (inactive only, deleted, or no key), all three stay null, the readable key included. Comments are always null in the backfill (the column is new). The readable key is spelled in SQL like `readableRuleKey` (a legacy key that isn't six parts stays as it is), checked against the TypeScript on `jetlog_test` (Mark, 2026-10-21).
- **The export keeps `rule_key_readable`** (today's codes) and adds `raw_barcode` and the three at-scan-time columns next to it (Mark, 2026-10-21).
- **Rules CSV import:** `comments` is an optional column, so a file exported before this change still imports (comments null). An inactive rule with the same key is reactivated only if its description, **comments**, allowed guests and guest policy all match the row; any difference adds a new rule (Mark, 2026-10-21).
- **Seed:** `seedRules` accepts an optional `comments`; `rules.json` is unchanged (Mark, 2026-10-21).
- **Rule `description` and `comments` are at most 2,000 characters** (one constant in `domain/ruleFields.ts`, mirrored in the client): checked on create, edit and import (400 / an invalid row), and by the database: both columns become `varchar(2000)`, the pattern the exception fields already use (`EXCEPTION_MAX_CHARS` in `schema.ts`). Trimmed; blank = null. The exception fields already have limits, so nothing goes to the backlog (Mark, 2026-10-21).

**Still open:** none.

**Touch:**
- **Server:**
  - `db/schema.ts`: `rules.comments` and the three `entries` columns. Mark runs `db:generate` and `db:migrate`.
  - `services/scanService.ts` and `services/entryModificationService.ts`: write the snapshot on a scan, a rescan and (if confirmed) a move.
  - `services/entriesService.ts` and `types/dto.ts`.
  - `domain/entriesCsv.ts`: the columns and their pinned test.
  - `domain/rulesCsv.ts`, plus the rule DTO and inputs.
  - Integration tests.
- **Client:**
  - `lib/rulesCsv.ts`, `components/RuleForm.tsx`.
  - The details window.
  - Store changes, if any, go through `store-test-writer`.
- **Docs:** ARCHITECTURE, DEPLOY (migration, row counts), CLAUDE.md, USER_GUIDE.

**Done when:**
- The export has the raw barcode and the three at-scan-time columns.
- Editing a rule or renaming a club or lounge after a scan doesn't change them.
- A rescan does.
- Rules have comments, in the editor and in the rules CSV.

### 30. Exceptional entries carry a quantity; guests only for hosts approved by the rules (medium, one migration)
**Status:** Done — PR #32
**Why:** IsraJet (2026-10-20). A group admitted by exception (e.g. 10 people) should be **one entry with a quantity**, not a host with guests. Guests belong only to a host the rules admitted, up to that rule's allowance.

**Decided (IsraJet via Mark, 2026-10-20):**
- **`entries.quantity`:** whole number, not null, default 1. Its range is checked by the code, from a global rule (below); the database doesn't check it (Mark, 2026-10-22: was 1–200 as a database check).
- **The limit is a global rule the admin edits** (Mark, 2026-10-22): `max_exception_quantity`, inserted as `1000` by this task's migration (`0020`), a whole number from 1 to 10,000 (the ceiling `EXCEPTION_MAX_QUANTITY`, raised from 1,000 by Mark, 2026-10-22). The database has no range check (Mark, 2026-10-22: the limit lives in `global_rules` only); the rule is enforced by the code on all three quantity endpoints (manual approval, Approve anyway, change quantity). Lowering it leaves existing quantities as they are; a later change of quantity is checked against the limit in force then. One value for every lounge for now; a per-lounge limit may come later. On the Global rules page it sits with the operator rules, under a heading reworded to cover both (client half).
- **Only an exceptional host may have a quantity above 1.** Both kinds of exception set it: **Approve anyway** (a scanned pass) and **Manual approval** (no pass).
  - Guests always have quantity 1.
  - A host approved by the rules always has quantity 1.
- **The quantity can be changed later** through "modify entry", inside the modify window.
- **The export gains `quantity`.** IsraJet does the totals in its own system; JetLog's counts and log stay per entry.
- **Guests only for a host approved by the rules, and only up to its rule's allowance.**
  - **An exceptional host has no guests:** **Guests allowed** leaves the exception form, and **Add guest without barcode** is retired.
  - So a host with quantity above 1 never has guests.
  - This reverses task 23's exception-guest decisions ("the approver sets Guests allowed", "every guest of an exception-approved host is itself exceptional", "such a guest can be added without a barcode"), so it gets a `/decision` when built.
- **No raising a host's guest allowance by exception** (Mark, 2026-10-20).
- **Entries logged before this** (exceptional hosts with guests) stay as history, readable and exportable; no new guests can be added to them.

- **A guest the rules refuse can't be approved as an exception** (Mark, 2026-10-21): guests follow the rules only. Such a person can be admitted as their own exceptional entry (a separate party, quantity 1). This closes task 27.

**Decided (Mark, 2026-10-22):**
- **An exception-move of a host who already has guests is allowed.** The host becomes exceptional (quantity from the form, default 1); its existing guests move with it unchanged and stay as history, and no more can be added.
- **No exception-move of a host already approved by exception (409)** (Mark, 2026-10-22, at review): its move is never refused, so the screen never offers it, and the request would reset its quantity and approver. The pure rule is the `EXCEPTION_MOVE` action in `domain/entryModification.ts`, mirrored in `lib/entryActions.ts`.
- **A second database check: `quantity = 1` unless the entry is an exceptional host.** "An exceptional host has no guests" spans two rows, so the server code enforces it.
- **An exceptional host stores `allowed_guests = 0`**, so it has no guest places; the pure rule "guests only for a host approved by the rules" (`modificationProblem`) refuses any guest of it.
- **Changing the quantity later:** `POST /api/entries/:id/quantity` with `{ quantity }`, for an exceptional host that isn't voided, inside the modify window. **No approver:** one would overwrite the original approver, and there is no audit trail; `modified_at` marks the change.
- **An in-place exception on a guest is refused (409)**, saying to admit the person as their own exceptional entry.
- **The export puts `quantity` right after `is_exceptional`.**
- **No backward compatibility in the code:** Mark wipes the dev database, and production holds no entries yet, so no exceptional guest or exceptional host with guests exists anywhere. The task-23 exceptional-guest handling (`recheckGuests`' exceptional branch included) is removed, not kept for old rows, and the exception endpoints simply stop reading `hostEntryId` and `allowedGuests`. The migrations stay append-only: `0020` is a normal additive migration.

**Still open:** none.

**Touch:**
- **Server:**
  - `db/schema.ts`: `entries.quantity` with its check. Mark runs `db:generate` and `db:migrate`.
  - `services/exceptionApprovalService.ts`: a quantity from 1 to the `max_exception_quantity` global rule (starts at 1,000, at most 10,000); drop the guest allowance and the barcode-less guest path.
  - `services/scanService.ts` (guest path): the host must be approved by the rules, not exceptional.
  - `domain/entryModification.ts` and `services/entryModificationService.ts`: a "change quantity" action for exceptional hosts, inside the window, with a route.
  - DTOs, and `domain/entriesCsv.ts` (`quantity`).
  - Integration tests.
- **Client:**
  - `components/ExceptionForm.tsx`: **Quantity** replaces **Guests allowed**.
  - `components/EntryModifyPanel.tsx`: edit the quantity.
  - The guest flow (`GuestPanel`, `ResultCard`): no guests after an exception.
  - The log shows ×N on a host with quantity above 1.
  - Store slices go through `store-test-writer`.
- **Docs:** ARCHITECTURE, DEPLOY (migration), CLAUDE.md, USER_GUIDE.

**Mark's test script** (`test-scan-bodies.sh` + `test-scan-bodies.json` at the repo root, git-ignored, kept on Mark's machine): it creates a `TEST` lounge and sends each pass to `POST /api/scan` as `{ rawBarcode, loungeId }`. Tasks 29 and 30 change what is **stored**, not what that endpoint **receives**, so it should keep working. The agent who lands the last database change of this plan checks it still runs, and updates the two files if any request body changed.

**Done when:**
- An exceptional approval records 1 to `max_exception_quantity` people (starts at 1,000, at most 10,000) as one entry, and it can be changed later inside the window.
- The export has `quantity`.
- No guest can be added to an exceptional host.
- Guests of a host approved by the rules are limited to its rule's allowance.

### 31. Length limits on every free-text column (small–medium, one migration) — after 30
**Status:** Next
**Why:** Mark (2026-10-21), while reviewing task 29's schema. Many `text` columns have no length limit, so one request can store an arbitrarily long string (up to Express's 100 KB body limit; 3 MB on the rules import), bloating the table, the export and the screen. Task 29 already caps a rule's description and comments at 2,000 characters; this task does the rest.

**Decided (Mark, 2026-10-21):**
- **Free-text columns get a maximum length, enforced twice:** by the code first (a 400 with a clear message, or an invalid import row), and by the database as the last guard (`varchar(n)`). The limits are defined once and used by both, like `EXCEPTION_MAX_CHARS` and `RULE_TEXT_MAX_CHARS`.
- **It is about size, not injection:** Drizzle already sends every value as a parameter. In Postgres `varchar(n)` is stored like `text`; only the cap matters.

**Still open (recommendations to confirm with Mark):**
- **Which columns.** *Recommended, by risk:*
  - **`entries.raw_barcode`** — the only column filled straight from an untrusted source (the scanner, or anyone who can post to the API). A real pass is a few hundred characters; *cap around 1,000*.
  - **Admin free text:** `clubs.code` / `description`, `lounges.code` / `description`, `approvers.name` / `company`, `global_rules.value`. `entries.approver_name`, `voided_by` and the task-29 at-scan-time strings are copied from these, so capping the source bounds the copies; cap the copies too, to the same constants.
  - **Columns the code derives** (`carrier`, `flight_number`, `uniq_key`, `rule_key`, `guest_policy`, the `rules` dimensions): already bounded by the BCBP parser or by fixed vocabularies. *Cap them too, generously,* so no `text` column on `entries` or `rules` is left unbounded — or leave them, if Mark prefers the smaller migration.
- **An over-long scan.** Today every scan is logged, garbage included. *Recommended: refuse it with a 400 and log nothing,* like any other bad request (a 1,000-character limit is far above any real pass), rather than storing it cut short.
- **The limits themselves** (characters): *recommended* club/lounge code 50, descriptions 2,000 (as rules), approver name and company 200, global rule value 1,000.

**Touch:**
- **Server:** `db/schema.ts` (the columns, and the limit constants next to `EXCEPTION_MAX_CHARS`, or in `domain/` where the validation is pure). Mark runs `db:generate` and `db:migrate`; before migrating, a query per column confirms no existing value is longer than its new limit. The validation in the controllers/services of clubs, lounges, approvers, global rules and the scan endpoints. Integration tests: one over-long value per endpoint is a 400 and writes nothing.
- **Client:** `maxLength` on the matching form fields, mirroring the constants.
- **Docs:** ARCHITECTURE (the invariant), DEPLOY (the migration and its pre-check), CLAUDE.md, USER_GUIDE (the new messages), a `/decision`.

**Done when:**
- No free-text column chosen above accepts more than its limit, in the code or in the database.
- An over-long value is refused with a clear message, and nothing is written.

### 32. Every scan and every action opens in a modal (medium, client only) — before 31
**Status:** Done — PR #33
**Why:** Mark (2026-10-22), moved here from BACKLOG.md ("First features of the next plan"), because it fixes a visible operator problem now. Today the scan's result, the guest loop and the scan errors are panels fixed at the top of the page, so an operator scrolled down to the log doesn't see them. The worst case: **+ Add guests** in an entry's details window closes the window and switches the scan panel at the top of the page into guest mode, out of sight. Every scan and every action should open in a modal over a dimmed background that takes over the screen until it is closed, so the operator always sees where they are and what comes next. The next plan's UI redesign will restyle these modals, not move them again.

**Where things stand (from the code, 2026-10-22):**
- Already a shadcn `Dialog`: the club question (`ClubPicker`) and the entry details window (`EntryDetailsModal`), which holds the entry changes (`EntryModifyPanel`: move, rescan, approve as exception, void, change quantity, and the change's own club question) as panels inside it.
- A hand-rolled modal (`.modal-overlay`, its own Escape listener, no focus trap): the exception form (`ExceptionForm`).
- On the page: the result card (`ResultCard`), the guest loop (`GuestPanel`), and the flow's error banner (e.g. **Could not decode boarding pass**).
- The scan box (`ScanPanel`) stays on the page: it is the screen at rest.

**Decided (Mark, 2026-10-22, after clicking through the mock — the "JetLog modal flow" artifact):**
- **Where a scan lands.** Every modal that takes a scan focuses its scan field when it opens and after each scan. When a modal closes, focus goes back to the main scan box. With no modal open, a scan typed while focus is on something that isn't a text field (a log row, a button, the page) is sent to the main scan box; the log's search and filter fields keep their own typing.
- **What closes a modal.** A close button (×) and Escape close every modal. Clicking outside closes only the result (and the scan error, the same modal) and the entry details; it does nothing on the club question, the exception form and the guest loop. Halfway closes:
  - Closing the club question cancels the scan; nothing is logged.
  - Closing the guest loop is **End guests**: the guests already scanned stay logged, and the places left can be filled later with **+ Add guests**.
  - Cancelling the exception form returns to the result it came from.
- **How long a result stays open:** until it is closed or until the next scan. The result modal has its own focused **Scan the next passenger** field, so a busy desk never has to close anything. No timer. A scan error opens the same modal, in red.
- **One modal at a time.** A modal opened from another replaces it and returns to it when closed:
  - **+ Add guests** swaps the details window for the guest loop, with no page switch or scroll, and reopens that host's details when the loop ends.
  - **⚡ Approve anyway** swaps the result for the exception form.
  - The entry changes stay panels inside the details window.
- **Store.** `scanSlice`: `mode` drives one flow modal with three steps (club, result, guests); `scanPrimary` from the result starts a new scan; `startGuestsFor` stops switching the view and remembers which host it came from. `exceptionSlice` and `entryEditSlice`: no change expected. No server change expected; if one turns up, stop and say so.
- **A scan while a modal has no scan field** (the club question, the exception form, the details with no Rescan open) is ignored with a short message, so the scanner's closing Enter presses nothing. Raised by the mock and built as recommended; Mark gave no separate answer, so it is confirmed at review.

**Decided (Mark, 2026-10-23, at review):**
- **The modal footer:** secondary buttons in grey on the left (**Close**, **⚡ Approve anyway**, **Open their entry**, **End guests**), the one main action in blue on the right: **Scan**, which submits the modal's scan field (for a pass typed or pasted by hand; the scanner's Enter still works) — named like the main box's button, not "Submit". **End guests** stays grey, not yellow: yellow means ⚡ exceptional in JetLog, and ending early is safe. When every guest place is filled, the field and Scan go and **Done** is the blue button on the right. The result, the failed scan and the guest loop share this footer.
- **Forms that change data submit only from their button**, never from Enter in a text box: the exception form, and the details window's approve-as-exception, change-quantity and void panels. A stray scan in one of their fields leaves visible text and presses nothing. The scan fields (the main box, the modals' fields, **Rescan…**) keep Enter.
- **A scan while the last one is still being checked** is not queued (a pass held back could land in the wrong step, e.g. a guest logged as the next passenger): a message says **Still checking the last scan — scan this pass again.**
- **Opening an entry that fails** (**Open their entry**, or the guest loop's return to its host) shows its error as a toast, not as a failed scan.
- **The change panels in the details window share one shape** (Mark, 2026-10-23: Move and Rescan were unclear): a title (**Move to another lounge**, **Rescan the boarding pass**, **⚡ Approve as exception**, **Change the quantity**, **Void this entry**), labels above full-width fields, the hint, and the modal footer — grey **Cancel** on the left (closes the panel), the blue action on the right. Rescan uses the big scan box.

**Still open:** none.

**Touch:**
- **Client:**
  - A flow modal (e.g. `components/ScanFlowModal.tsx`) on `components/ui/dialog.tsx`, rendering the club question, the result and the guest loop as steps; `ResultCard`, `GuestPanel` and `ClubPicker` become its contents.
  - `ExceptionForm` moves onto the shadcn `Dialog` (its own Escape listener and `.modal-overlay` go).
  - `ScanPanel` (focus handling), `App.tsx` (the operator view: the scan box and the log only; the wedge redirect), `EntryModifyPanel` (**+ Add guests**), `EntryDetailsModal`.
  - `store/slices/{scanSlice,exceptionSlice}.ts` and `store/types.ts`, with their tests through `store-test-writer`; any pure piece (e.g. "is this key a scan for the main box?") in `lib/` with unit tests.
  - shadcn only; never MUI.
- **Docs:** USER_GUIDE (the scanning, guests and manual-approval sections, and the shot list) through `user-guide-writer`, in the same commit; ARCHITECTURE (client state: what `mode` now means on screen, one modal at a time).

**Done when:**
- A scan's club question, result, error and guest loop, the exception form, and every entry change open in a modal over a dimmed background; nothing is a form fixed on the page.
- **+ Add guests** opens the guest loop in front of the operator, wherever the page is scrolled, and returns to the host's details when it ends.
- A USB scan always lands in the field the operator sees: the open modal's scan field, or the main scan box when none is open.
- Checked in Mark's running app (client `localhost:3000`, API `localhost:8000`), and `/verify` is green.

---

## 4. How to work here

- **Dev:** `docker compose -f docker-compose.dev.yml up -d` (Postgres) · `server`: `cp .env.example .env`, `npm run db:migrate && npm run db:seed`, `npm run dev` (8000) · `client`: `npm run dev` (3000, proxies `/api`). Full demo: `docker compose up --build` (or `/demo`).
- **Schema change:** edit `schema.ts` → Mark runs `npm run db:generate` → review the SQL (add backfills by hand) → Mark runs `npm run db:migrate` **with a row-count check before/after** (agents hand him the commands; they never run them). Keep `seed-data/rules.json` in sync if rules gain a column.
- **Tests:** `npm test` (unit, safe) · `npm run test:integration` (needs `TEST_DATABASE_URL` → a throwaway DB, e.g. `jetlog_test`; refuses to run against `DATABASE_URL`).
- **Gate before a PR:** `/verify` (server tests + both lints + client build).
- **Branches:** `main` (docs) · `staging` (demo-safe snapshot) · `feature/*` off `staging`. Small topical commits with descriptive messages.
- **Conventions to keep:** the envelope; `@desc/@route/@access` header on every controller; controllers are plain `async` handlers (Express 5 forwards rejected promises to `errorHandler`); `domain/` stays pure; client `lib/` stays React-free.
- **Never:** run integration tests against a live DB; delete data you didn't create; commit Mark's WIP; introduce a second state store, ORM, or component library.

---

## 5. Next plan — the UI redesign (not started)

**Order (Mark, 2026-10-21): the UI redesign first, then authentication** (tasks 15 and 16 move into that plan). Its first features are listed in BACKLOG.md, "First features of the next plan".

After this plan's tasks are done, the next handoff is a **UI redesign**, driven by IsraJet's requests: make the app resemble their **legacy desktop application** (screenshots on file with Mark), **Hebrew / RTL**, and **changed operator flows**. This is a product redesign, not plumbing — large, design-led, iterative on client feedback — so it gets its own document (a fresh `docs/` handoff; this file may be dated and marked finished/legacy at that point). It **absorbs** the work task 11 deliberately defers: the remaining modal migrations (task 32 moves the operator's scan flow and entry actions into modals now; the redesign restyles them), the visual overhaul, the new flows, and **task 17 (Hebrew/RTL)** — build each redesigned screen RTL-ready from the start rather than mirroring later. It builds entirely on the shadcn + Tailwind foundation from task 11, screen by screen, on bounded PRs (a good fit for `react-frontend-senior` with screenshots in hand). **Not to be started until the current plan is complete and Mark opens that handoff.**

---

*Written 2026-08-31 at the handoff from the POC build agent. When something here stops matching the code, fix this file — it's the contract the next agent trusts.*
