---
name: stack-status
description: Report the health of the JetLog stacked-PR chain — each phase branch's base, ahead/behind counts, open PR state, and exactly which branches need a rebase in what order. Use for "stack status", "do I need to rebase", or after changing an earlier phase branch.
---

The canonical stack table lives in `../jetlog-ops/docs/archive/POC_PHASES.md` (§ "The PR stack"): six branches, phase 1 based on `main`, each later phase based on the previous one. Extra topic branches (e.g. `feat/entries-table-zustand`) stack on top of the highest phase branch they were cut from — detect them with `git branch --list` and `git merge-base`.

## Steps

1. `git fetch --all --prune`, and note the current branch + whether the working tree is dirty (a dirty tree blocks any rebase).
2. For every branch in the chain, bottom-up, against its base:
   - `git rev-list --left-right --count <base>...<branch>` → behind/ahead.
   - **behind > 0 means the branch needs a rebase onto its base** — and every branch above it in the chain will need one too, in order.
3. PRs: `gh pr list --state open --json number,title,baseRefName,headRefName,mergeable` — flag any PR whose `baseRefName` is not its stack-table base (mis-based PR), and any already-merged phase whose successor still targets the deleted branch.
4. Compare local vs `origin/` for each branch (`git rev-list --count origin/<b>..<b>`) — unpushed work on a lower branch means the chain on GitHub is stale.

## Report

One table, bottom-up: branch | base | ahead/behind base | PR # + state | verdict (✅ in sync / ⚠️ needs rebase / ⚠️ unpushed / ❌ mis-based). Then, if anything needs fixing, the exact ordered rebase sequence — and hand execution to the **pr-stack-manager** agent; this skill is read-only and never rebases, pushes, or edits PRs itself.
