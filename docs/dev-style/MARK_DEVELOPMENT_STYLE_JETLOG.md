# Mark's development style — JetLog

How Mark builds **this** project. It applies the global style (`MARK_DEVELOPMENT_STYLE_GLOBAL.md`, next to this file) to JetLog's tools, commands and documents. The hard safety rules are also in `CLAUDE.md`; where the two overlap, `CLAUDE.md` is the authority.

## Two repos (where this differs from the global style)
JetLog is split in two (2026-10-25). Sessions start in the IsraJet workspace root, and paths here are written from inside **`jetlog/`** — IsraJet's code and its handover docs (`README.md`, `docs/DEPLOY.md`, `docs/USER_GUIDE.md`). Everything else in the global layout lives in **`../jetlog-ops/`**: `CLAUDE.md`, `.claude/`, and `docs/` (`ARCHITECTURE.md`, `DECISIONS.md`, `PLAN.md`, `BACKLOG.md`, `dev-style/`, `client-israjet/`, `archive/`).
- Paths below are written from `jetlog/`.
- **jetlog never mentions jetlog-ops**, the agents, the skills or Mark: it goes to the customer as it is.
- Where the global style says "in the same commit" for a document that now lives in jetlog-ops, read **"in the paired commit"**: `/commit` commits the code in jetlog and the docs in jetlog-ops on the same branch, with the same message, the ops commit carrying `App-Commit: <sha>`.
- The global style's "git history is the source of truth" covers both repos from the split, and `../israjet-launges` (read-only) before it.

## The documents
The layout follows the global style's §6, split across the two repos as above:
- **`../jetlog-ops/docs/PLAN.md`** is the current plan: the UI redesign, plus the unfinished tasks of the plan before it, carried over with their numbers. §1 lists the open tasks in order, §2 holds what is decided for the whole redesign, and each task's "Decided" list is binding. The post-POC plan is archived as `../jetlog-ops/docs/archive/2026-10-post-poc-plan.md` (2026-10-23). The plan was `docs/HANDOFF.md` until 2026-10-14; older commits and decision rows say "HANDOFF".
- **`../jetlog-ops/docs/DECISIONS.md`** is the decision log, appended with `/decision`. **`../jetlog-ops/docs/BACKLOG.md`** is the backlog.
- **`../jetlog-ops/docs/client-israjet/`** holds IsraJet's spec. **`../jetlog-ops/docs/archive/`** holds the POC brief, the POC phase plan (with its frozen decision log), the POC reviewer guide and the early cloud plan.
- **When this plan is finished**, archive it as `../jetlog-ops/docs/archive/<yyyy-mm>-<name>.md` with a HISTORICAL banner and start a fresh `PLAN.md` after its last task number (global style §6).
- **IsraJet's commercial proposal** stays on disk in the workspace's `business/` folder, outside both repos. It is never committed anywhere.
- **`../jetlog-ops/docs/ARCHITECTURE.md` is the source of truth for how the system is built.** Update it in the paired commit when a change touches the dependency rules, the request lifecycle, the data model or its invariants, the API, the client state, or the extension points.
- **`docs/DEPLOY.md` is the production runbook Mark follows by hand.** Update it in the same commit when a change touches a migration, the `db:*` scripts, Docker, environment variables, ports, or expected row counts.
- **`docs/USER_GUIDE.md` is how to use JetLog**, for operators and admins, with worked examples and a screenshot shot list; it is the source of the planned in-app help page. The `user-guide-writer` agent owns it and updates it in the same commit as any user-visible change.

## Starting a task
- Read `../jetlog-ops/CLAUDE.md`, `../jetlog-ops/docs/ARCHITECTURE.md`, `../jetlog-ops/docs/DECISIONS.md`, and the task's section in `../jetlog-ops/docs/PLAN.md`.
- **Task status:** `../jetlog-ops/docs/PLAN.md` has a `**Status:**` line under each task heading (Next · In progress · Done · Later · Superseded) and an "Open tasks" summary at the top of §3. Read it first, then check it against git history (merged PRs into `staging` in jetlog, branches in both repos). If they disagree, **stop and ask Mark in one short sentence before changing the status or doing anything else** (a merged task may have been reopened on purpose). Set **In progress** (with the branch) in the task's first ops commit, and **Done** (with the PR number) in the ops commit that goes with the PR.
- Branch `feature/task-NN-<short-name>` off `staging`, once the previous task's PR is merged. If it isn't merged, ask. Use the same branch name in jetlog-ops (`/commit` creates it there if needed).
- Plan, ask, wait for the OK, and write the answers into the task's "Decided" list before building.

## The database
- Edit `server/src/db/schema.ts`, the model: one file, all tables.
- Give Mark the generate command, ready to run:
  `cd server && npm run db:generate -- --name <what_it_does>`
  (choose the name yourself, so the command has no placeholder left).
- Hand-edit the generated SQL in `server/src/db/migrations/` only for a backfill or seed, and verify it matches the TypeScript (e.g. compare keys on `jetlog_test`).
- Give Mark `npm run db:migrate`, with `psql "postgres://jetlog:jetlog@localhost:5432/jetlog" -c "…"` row-count checks before and after.
- Integration tests: `npm run test:integration`, which runs only against `jetlog_test`. Never against the dev DB `jetlog`, and never against production.

## Tests and quality
- Server: Vitest. Domain code under `server/src/domain/` is pure and written test-first; integration suites live in `server/tests/integration/`.
- Client: pure logic in `client/src/lib/` with unit tests. **Any change under `client/src/store/` goes through the `store-test-writer` agent**, which writes the slice tests and proves they can fail.
- Users: **any user-visible change goes through the `user-guide-writer` agent**, which updates `docs/USER_GUIDE.md` and its shot list.
- `/verify` is the full gate: server tests and lint, client tests, lint and build.

## Testing in the app
- Mark's dev servers: client on `http://localhost:3000`, API on `http://localhost:8000`. Use the built-in browser to check changes there.
- **Test rules:** create them through the API (`POST /api/rules`), with descriptions starting `TEST`, on carriers the seed doesn't use (e.g. `6H`, `IZ`).
- **Test boarding passes:** encode them with `bcbp` (`server/node_modules/bcbp`, run with `npx tsx` from `server/`), dated today, from TLV unless the test needs otherwise. Dry-run each one (parse, validity, `matchRule`, `club-options`) before handing it over.
- An approved pass can't be approved twice (dedup), but denied ones can be rescanned. When a set is used up, generate fresh passes with new sequence numbers rather than deleting entries.
- If you change a global rule to test (e.g. the date window), restore its value and say so.
- A local test sheet can live in `jetlog/` if it's listed in `jetlog/.git/info/exclude`, so `git add .` doesn't pick it up. The exclude already lists `.claude/`, the proposal and the scan-test files.

## Commits and PRs
- Commit only after Mark's go, with `/commit`. Push and open the PR into `staging` (in jetlog) only when he asks. Keep Auto-fix off.
- A task usually lands as: a plan commit (ops only: `../jetlog-ops/docs/PLAN.md`, if planned separately), a server commit, and a client commit (paired when they touch ARCHITECTURE.md or the plan), plus separate commits for any docs sweep or rename.
- When the task's PR merges into jetlog's `staging`, merge the same-named jetlog-ops branch into ops `staging` too (after Mark's go).
- Commit messages carry **no attribution line**: never `Co-Authored-By: Claude …` or similar, in either repo, even if the session suggests one.
