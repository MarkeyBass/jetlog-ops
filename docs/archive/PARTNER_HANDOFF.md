> **HISTORICAL — frozen, kept for the record. Do not follow or edit it.** This is the reviewer guide for the POC's phase PRs. Superseded by the [README](../../../jetlog/README.md) and [PLAN.md](../PLAN.md). Moved to `docs/archive/` on 2026-10-14; links inside may point at old paths.

# Partner Handoff — Reviewing the JetLog POC Phase PRs

**Audience:** the developer reviewing / continuing this work on behalf of Mark.
**Context:** the JetLog POC (IsraJet lounge entry) was built phase-by-phase by Claude Code as a *stack* of pull requests, one per phase. Scope is bound by [POC_Architecture.md](../POC_Architecture.md); the phase plan and decision log live in [POC_PHASES.md](POC_PHASES.md).

---

## 1. The PR stack

Six PRs, each on its own branch, each branched off the previous one:

| # | Branch | Base | Contents |
|---|--------|------|----------|
| 1 | `feat/phase-1-scaffold` | `main` | TS + Express skeleton, error pipeline (`asyncHandler`, `ErrorResponse`, central `errorHandler`), `GET /api/health`, tooling |
| 2 | `feat/phase-2-db-drizzle` | PR 1 | `docker-compose.dev.yml` Postgres, Drizzle `rules` + `entries` schema + migration, 231-rule seed from the Excel |
| 3 | `feat/phase-3-bcbp-domain` | PR 2 | Pure domain: BCBP parse, companyVar, wildcard rule matcher, dedup key + fixture tests |
| 4 | `feat/phase-4-scan-api` | PR 3 | `/api/scan`, `/api/entries`, `/api/rules`, guest flow, integration tests |
| 5 | `feat/phase-5-frontend` | PR 4 | React operator screen: scan → result → guest loop + entries table |
| 6 | `feat/phase-6-demo-polish` | PR 5 | Full `docker-compose.yml` (web + api + pg, seed-on-up), demo README, this doc |

**Why stacked:** each PR's diff shows *only its own phase*. GitHub renders the diff against the base branch, so you never re-review earlier code.

### Review & merge order

Review and merge **bottom-up: 1 → 2 → 3 → 4 → 5 → 6.**

1. Review PR 1. When approved, merge into `main`.
2. PR 2's base retargets to `main` automatically when PR 1's branch is deleted on merge (otherwise edit the base). Repeat down the stack.

### Requesting changes on an earlier PR

Comment as usual. When branch N is fixed, every branch above it must be rebased **in order**:

```bash
git checkout feat/phase-3-bcbp-domain
git rebase feat/phase-2-db-drizzle
git push --force-with-lease
# repeat for each higher branch, in order
```

Always `--force-with-lease`, never `--force`. Claude handles this chain when asked ("I changed PR 2, rebase the stack"). After any force-push, re-check the PR diff shows only that phase.

### Checking out a PR locally

```bash
gh pr checkout <number>
cd server && npm install && npm run build && npm test   # unit tests need no DB
```

Integration tests (Phase 4+) need Postgres — `docker compose -f docker-compose.dev.yml up -d` first, with `DATABASE_URL` set (they self-migrate and self-seed).

---

## 2. What to look for when reviewing

Conventions are ported from the sibling `cicada-vite-green/server` (JS + Mongoose) into TypeScript + Drizzle/Postgres. Deviations are review findings:

- **Layering:** routes wire only → controllers do HTTP (validate, shape the envelope) → services own business rules + DB access → `domain/` is pure (no I/O). No SQL in controllers; no `db/` imports inside `domain/`.
- **Response envelope:** success is `{ success: true, data }`; errors flow through `next(new ErrorResponse(msg, code))` → central `errorHandler` → `{ success: false, error }`. `BoardingPassParseError` maps to 400.
- **Controllers** keep the cicada `@desc / @route / @access` comment block; every async controller is wrapped in `asyncHandler`.
- **Schema** mirrors POC_Architecture.md §3 exactly. `allowed_guests` is an integer (the one deliberate upgrade over the Excel's free text). No columns beyond §3 (e.g. deny reason is in the scan *response*, not on the row).
- **Tests:** unit tests (domain, no DB) must run without Docker; integration tests use supertest against the app + compose Postgres. Fixtures in `server/tests/fixtures/barcodes.json` are real EY barcodes with the outcomes Vlad's Excel computed.
- **`domain/` purity** is the key architectural line — it's what makes the proven Excel logic independently testable.

---

## 3. Key product decisions you need to know

Full reasoning is in the [POC_PHASES.md decision log](POC_PHASES.md#decision-log). The load-bearing ones:

- **companyVar comes straight from the `bcbp` library's `leg.airlineInfo`.** It was verified equal to the Excel `LET` offset-walk on every real fixture (LA on approved, N on denied), so the offset-walk fallback was dropped. If a future EY pass lacks `airlineInfo`, that fallback is the place to add.
- **The full 231-rule Excel sheet is seeded** (all carriers), not just EY + BA. It's all real data, extracted by script and self-verified (every row's columns reconstruct its `rule_key`).
- **Guest rule is same-carrier-as-host** (POC simplification). The host↔guest link (`entries.host_entry_id`) is the demo's money shot — it's the billing-attribution proof Vlad needs.
- **Denied scans are logged** as entries with `approved = false`; the deny reason is returned in the scan response, not stored.
- **Only `compartment` and `companyVar` are derivable from the barcode.** FFP/club tier need an airline loyalty lookup (out of POC scope) and collapse to `#`. This is why EY passes (keyed on companyVar) match and some other carriers' tier rules would not from a bare scan.
- **Two fixture barcodes were re-padded**: manual name-redaction in the source xlsm had shortened them, breaking the BCBP fixed-width layout. The extractor restores the 20-char name field; all other bytes and every expected outcome are untouched.

### Explicitly deferred (POC_Architecture.md §9 — do **not** build)

Auth / roles, rules admin UI, reporting/filters, per-lounge separation (lounge is hardcoded `'C'`), multipass/vouchers/payments, SSE / realtime, same-flight guest validation, offline mode, Hebrew/RTL. The dedup check-then-insert is intentionally not transaction-locked (single-operator POC).

---

## 4. Working with Claude Code on this repo

- **Source of truth:** [POC_Architecture.md](../POC_Architecture.md) (scope) and [POC_PHASES.md](POC_PHASES.md) (plan + decisions). Claude reads [CLAUDE.md](../CLAUDE.md) each session; keep these current when decisions change.
- **Collaboration style Mark has established:** Claude asks clarifying questions before building, works phase-by-phase, verifies each phase (tests + a live run) before opening the PR. Hold it to that.
- **Custom agents** (`.claude/agents/`): `ts-backend-senior` (Express/TS/Drizzle), `react-frontend-senior` (operator UI), `pr-stack-manager` (stacked branches, rebase chains). Each keeps a `.claude/feedbacks/` memory of Mark's corrections.
- **Memory:** Claude keeps persistent project memory outside the repo. Tell it "remember this" for anything that should persist across sessions.
- **Useful commands:** `/code-review` reviews the current diff; `/code-review ultra <PR#>` runs a deep multi-agent cloud review of a PR.

### Typical loop for continuing a phase

1. Open [POC_PHASES.md](POC_PHASES.md), find the phase checklist.
2. Ask Claude to implement it; answer its questions.
3. Let it implement on the stacked branch, run tests + a live check, open the PR.
4. Review against the checklist in section 2 above.

---

*Written 2026-07-17 as part of the phase 1–6 build run.*
