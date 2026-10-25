# Mark's development style — global

How Mark builds software, for any project. It is project-agnostic on purpose: copy this file into another repo and import it from that repo's `CLAUDE.md` (`@path/to/this-file.md`), or from `~/.claude/CLAUDE.md` to apply it everywhere. Project-specific rules live in a separate file next to it.

When this file and a project's own rules disagree, the project's rules win, and say so.

## 1. Plan before code
- **Every task starts with a short plan, and waits for Mark's OK.** The plan covers what changes, in which order, and the open questions, each with a recommendation. No code before the OK.
- **Ask, don't guess.** When a requirement is open or ambiguous, ask. Offer a recommendation and the trade-off, and let Mark decide.
- **Every task in the plan says its status, right under its heading**: a quick map of where things stand, and the only place that records what git can't show (planned, moved, superseded, and why). **Git history stays the source of truth.** One line, one of:
  - **Next:** planned and decided, waiting to start.
  - **In progress:** being built (name the branch).
  - **Done:** merged (name the PR).
  - **Later:** not in this plan's work (e.g. moved to the next plan).
  - **Superseded:** replaced by another task (name it).

  Read the status first, then check it against git (merged PRs, branches, recent commits). **If they disagree, stop and ask Mark in one short sentence** (e.g. "Task 24 says In progress but its PR is merged — is it done?") **before changing the status or doing anything else.** A merged task may have been reopened on purpose. Update the status whenever it changes, in the same work: the plan commit sets **Next**, the first commit of the work sets **In progress**, and the task's PR sets **Done**, since merging it makes that true. The plan keeps a short summary of open tasks at the top of its task list, and it must agree with the status lines.
- **Record every decision where it lives.** The plan document holds each task's decided list. A change to a standing decision gets a dated entry in the decision log that says *why*, written for a reader six months out. Old decisions are superseded by new entries, never rewritten.
- **Ideas that are not for now go to the backlog**, with whatever was already decided about them.

## 2. Build in reviewed stops
- **Back end first, then front end, with a review stop after each.** Build the server side (schema, domain, services, endpoints, tests), stop, and hand it to Mark. Start the client only after he has reviewed the server, then stop again.
- **Nothing is committed until Mark says so.** He reviews the working tree first, sometimes with `git add .`, so expect staged changes that are his, not yours.

## 3. Databases
- **Mark runs every migration command himself.** Edit the schema file; give him the exact command to generate the migration. Review the generated SQL, hand-edit it only to add a data backfill or seed, and show him what you added. Then give him the command that applies it, with ready-to-run row-count checks to run before and after.
- **Never point tests at a live database.** Destructive or integration tests run only against a dedicated, throwaway test database.
- **Never delete data you did not create.** If test data is used up, make fresh data.
- **Store the minimum; compute what people read.** Store ids and codes, and derive the readable form (labels, codes, lists) on every read, so a rename never leaves stale text. Foreign keys reference ids, never editable codes.

## 4. Tests
- **Pure logic is written test-first.** New services and endpoints get integration tests; front-end logic gets unit tests.
- **Prove a new test can fail:** break the code it covers, see it fail, and restore the code exactly.
- **Run the full quality gate** (tests, lint, type-check, build) before handing anything over, and report the actual results.

## 5. Code
- **One source of truth.** Constants, codes and vocabularies are defined once and imported everywhere. Never repeat a string literal that stands for a code.
- **Names say what a thing is.** If a name is unclear, propose a better one. Prefer names that pair with their counterpart (`ruleKey` / `ruleKeyReadable`).
- **Respect the layering rules.** If you must bend one, say so, explain why, and show that nothing breaks: run the real entry points, not just the tests.
- **Keep pure logic separate from I/O and from the UI**, so it can be tested on its own.

## 6. Documentation
Each kind of document lives where its lifetime says, and every role has a **stable path**, so links never break when a plan ends:

```text
README.md            what it is, how to run it, the doc map
CLAUDE.md            instructions for Claude; imports the dev-style files
docs/
  ARCHITECTURE.md    LIVING  how the system is built — the source of truth
  DEPLOY.md          LIVING  the production runbook
  DECISIONS.md       LIVING  the decision log — append-only, outlives every plan
  BACKLOG.md         LIVING  deliberately unscheduled ideas, with what's decided about them
  PLAN.md            LIVING  the CURRENT plan — always at this path
  dev-style/         LIVING  how Mark works (global + project)
  client-<name>/     INPUTS  the client's own documents, kept as received
  archive/           HISTORY frozen documents, each with a HISTORICAL banner
```

- **The root of `docs/` holds only living documents.** They must be current, and they change in the same commit as the code they describe. A stale runbook command is a production incident waiting to happen.
- **The current plan always lives at `docs/PLAN.md`.** When a plan is finished, move it to `docs/archive/<yyyy-mm>-<name>.md`, mark it HISTORICAL, and start a fresh `PLAN.md`. Unfinished tasks are carried over.
- **Decisions and the backlog outlive plans**, so they never live inside one. A decision is a new dated row in `DECISIONS.md` that says *why*; an idea for later goes in `BACKLOG.md`, and moves into the plan when it's scheduled.
- **Task numbers continue across plans** (a new plan starts after the last number, not at 1), so a number means one task forever. **Only `PLAN.md`, `DECISIONS.md`, `BACKLOG.md` and the archive cite task numbers.** A decision names the plan when it isn't the current one ("task 21 (post-POC plan)"). Everywhere else (other docs, code comments, test names) name the feature, call future work "planned", or point at the file.
- **Retiring a document** = move it to `archive/` (never delete it), add a one-line banner at the top ("HISTORICAL — frozen, kept for the record; superseded by …"), and fix every link to it in the same commit. Nothing in `archive/` is edited after that, and it is history, never instructions.
- **The client's documents are inputs, not ours.** Keep them as received in `docs/client-<name>/`, write our docs from them, and record any deliberate difference in `DECISIONS.md`.
- **No commercial documents in git** (proposals, pricing, contracts). They stay on disk, listed in `.gitignore`.

## 7. Git
- **Small, topical commits with descriptive messages** that explain the *why*. Mark studies the history.
- **Stage only your own files.** Separate unrelated changes (a docs sweep, a rename) into their own commits.
- **Push and open a PR only when asked.** Never turn on auto-merge or auto-fix unless asked.

## 8. Verify for real
- **Check user-visible changes in the running app**, against Mark's own dev servers, and report what you saw, with a screenshot or the page text.
- **Make realistic test data** (real-format inputs, generated with the project's own libraries), label it clearly as test data (e.g. a `TEST` prefix), and dry-run it before relying on it.
- **If you change a setting to test something, put it back** and tell Mark.

## 9. Communication
- **Plain language.** Explain what happened and why, without jargon.
- **Answer Mark's questions before doing more work.**
- **Ready-to-run commands only**, with no placeholders to fill in.
- **Say whether something is expected behaviour or a bug**, and when a limitation is known (e.g. "the client isn't updated yet"), say so up front.
- **Report honestly**: what was verified, what wasn't, and what was skipped.

## 10. UI taste
- **Show the operator everything they need at once**: every reason a check failed, not just the first.
- **Clear status at a glance**: approved and denied as distinct, colour-coded badges; what passed in green, what failed in red.
- **Readable labels for people**; internal ids only in tooltips or exports.
