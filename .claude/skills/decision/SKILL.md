---
name: decision
description: Record a scope or approach change in the living decision log — ../jetlog-ops/docs/DECISIONS.md — in the exact table format, with real reasoning. Use whenever a decision is made that changes scope, approach, stack, or conventions — the project workflow rules require logging these. Argument: the decision (and ideally the why).
---

The log is the "Decisions in force" table in **`../jetlog-ops/docs/DECISIONS.md`** — append-only, one row per decision. `../jetlog-ops/docs/archive/POC_PHASES.md`'s decision log is **frozen and historical — never add to it.** The workflow rule in `../jetlog-ops/CLAUDE.md` makes logging mandatory for scope/approach changes. (The session runs in `jetlog/`; the decision docs live in `../jetlog-ops/`.)

## Steps

1. Read the table in `../jetlog-ops/docs/DECISIONS.md` to match voice and check the decision isn't already logged (if a row covers it partially, a **new** row supersedes it — never rewrite history).
2. Compose the row in the table's two-column format, dating the *why*:
   ```markdown
   | <decision, one line, concrete> | **YYYY-MM-DD.** <why — who called it, what it buys or avoids; write for a reader six months out> |
   ```
   - Today's real date.
   - The *why* is the point. "Owner request" alone is acceptable only for cosmetic calls; anything with consequences needs the actual reasoning from $ARGUMENTS or the conversation. If no reasoning was given and it isn't obvious, ask — don't invent one.
   - Escape any `|` inside cell text.
   - A one-off **deferral** (something you're choosing *not* to build now) goes in `../jetlog-ops/docs/BACKLOG.md` instead.
3. Insert the row at the **bottom** of the table. Cite tasks by number only with their plan when it isn't the current one (e.g. "task 21 (post-POC plan)"); outside the plan, decision and backlog files, docs never cite task numbers.
4. **Ripple check** — a decision usually invalidates something else; fix in the same pass whatever applies:
   - in jetlog-ops: `../jetlog-ops/CLAUDE.md` key facts / roster / workflow,
   - `../jetlog-ops/docs/ARCHITECTURE.md` (if it touches the architecture — see its maintenance contract),
   - `../jetlog-ops/docs/PLAN.md` (the task's "Decided" list),
   - agent ground rules in `../jetlog-ops/.claude/agents/` (e.g. the Zustand rule changed when state management did),
   - in jetlog: `docs/DEPLOY.md` (if it changes a runbook command) and `README.md` commands — never with a mention of jetlog-ops, the agents or Mark.
   List what you touched; if a ripple is ambiguous or contradicts a document in `../jetlog-ops/docs/client-israjet/`, flag it for Mark instead of editing. `../jetlog-ops/docs/archive/` is frozen — never edit it.
5. Don't commit. When Mark says to, `/commit` commits it (a paired commit if jetlog files changed too).

For bigger documentation sweeps, hand off to the **docs-scribe** agent — this skill is the quick, single-decision path.
