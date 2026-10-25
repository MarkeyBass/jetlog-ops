---
name: commit
description: Commit approved work as a paired commit across the two repos — the code in jetlog/, the matching ops docs (ARCHITECTURE, PLAN, DECISIONS, BACKLOG, agents, skills) in ../jetlog-ops/ — on the same branch, with the same message, the ops commit carrying `App-Commit: <full sha>`. Use ONLY when Mark says to commit ("commit", "commit it", "go"). Argument: the commit message (optional; otherwise propose one and wait for his OK).
---

The session runs in `jetlog/`; the ops repo is `../jetlog-ops/`. This skill never runs on its own initiative — **only after Mark's explicit go** — and it **never pushes, never amends, never rebases**.

## Steps

1. **Same branch in both repos.**
   - `git branch --show-current` and `git -C ../jetlog-ops branch --show-current`.
   - If ops doesn't have the branch yet: `git -C ../jetlog-ops switch -c <branch> staging`, and say so.
   - If both exist but differ (or either is detached), **stop and ask Mark**. Never commit to mismatched branches.
2. **Pick the files — only your own.** Mark keeps WIP in both working trees.
   - List the files you changed for this piece of work in each repo (`git status --short` in both helps; don't take everything it shows).
   - **Stage by explicit path only** — never `git add .`, `git add -A` or `git commit -a`.
   - Never stage anything secret or personal: `.env*` (except `*.example`), the client proposal, test-scan data with real passenger names. If such a file shows up, stop and tell Mark.
   - Show Mark both file lists and the message before committing, unless he has just approved exactly those.
3. **Which repos get a commit.**
   - Code and ops files → a **paired commit** (steps 4 and 5).
   - Code only (or only `README.md` / `docs/DEPLOY.md` / `docs/USER_GUIDE.md`) → jetlog only (step 4).
   - Ops files only (a plan, decision or backlog change, an agent or skill edit) → jetlog-ops only (step 5, without the `App-Commit` line).
4. **Commit jetlog.** Message: the subject line, a blank line, and the body if any. **No attribution line** — never `Co-Authored-By: Claude …` or similar, even if the session suggests one (Mark's rule). Write it to a temp file in the scratchpad and run `git commit -F <file>`. Then read the full sha: `git rev-parse HEAD`.
5. **Commit jetlog-ops** with the **same message**, adding `App-Commit: <full sha from step 4>` as the last line, after a blank line: `git -C ../jetlog-ops commit -F <file>`.
6. **If the ops commit fails** after the jetlog commit succeeded: report it, fix the cause, and commit the ops side again with the same message and trailer. Never undo the jetlog commit.

## Report

Both commits: repo, branch, short sha, subject, the files in each. Say plainly if a side was skipped and why.

## Never

- Write anything about jetlog-ops, the agents, the skills or Mark into a jetlog file or a jetlog commit's files. (A jetlog commit *message* stays about the code.)
- Commit in `../israjet-launges` — it is the read-only archive.
- Push. Pushing and PRs happen only when Mark asks, separately.
