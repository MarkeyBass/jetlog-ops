---
name: why-rule
description: Explain why a scan was approved or denied — walk the ruleKey wildcard-collapse step by step against the seeded rules and show which rule matched (or which near-miss rules exist). Use for "why was this denied", "why did this get in", "which rule fired", or rule-tuning questions. Argument: a ruleKey, parsed scan fields, an entry id, or a fixture index.
---

The matching logic is `buildRuleKey` + `matchRule` in `server/src/domain/ruleKey.ts`; the rules are the 231 rows in `server/src/db/seed-data/rules.json` (source of truth: the Excel `Rules` sheet). Key construction: `carrier-compartment-frequentFlyer-companyVar-<club id|#>-<lounge id|#>`, where each scanned value survives only if some **active rule of that carrier** (in the rule set being tried) uses it — otherwise it collapses to `#`. Keys spell club and lounge **ids**; always show people the `ruleKeyReadable` form, with codes (e.g. `EY-#-#-LA-Gold-#`). Matching runs in two steps: the station lounge's own rules first, then the all-lounges rules (lounge `#`).

## Steps

1. **Get the scan's dimensions and its lounge** from $ARGUMENTS: a fixture index → parse via the domain code (see `/decode-barcode`), and ask which lounge (default: lounge `A`); an entry id → `GET /api/entries` if the server is up (it carries `loungeId`), else query pg; explicit fields → use as given.
2. **Load the carrier's rules** from the seed JSON (prefer `GET /api/rules` when the server is running — live DB wins if they've diverged; say which source you used). Split them: the station lounge's own rules, and the all-lounges rules (`loungeId` null / `lounge` `#`).
3. **Walk the collapse, one dimension at a time** — this is the part the user actually wants. Do it over the lounge's own rules first; if no own rule matches, again over the all-lounges rules:
   > compartment `J` — carrier EY has rules using `J`? → kept / collapsed to `#`
   > frequentFlyer `EY` (the FF designator) — no rule uses this dimension → `#`
   > companyVar `LA` — EY rules use `LA` → kept
   > club — the operator's pick (an entry's `club`), or `''` for None → `#`; a picked club (e.g. `Gold`) is kept when the carrier's rules use it
   > ⇒ built key: `EY-#-#-LA-#-#` (or `EY-#-#-LA-Gold-#` with Gold picked; `…-A` when lounge A has its own matching rule)
4. **Verdict:** the active rule whose `rule_key` equals the built key (show its description and `allowed_guests`), or — on a miss — the built key plus the carrier's *nearest* existing keys (same carrier, differing dimensions highlighted), so the user sees what rule *would* have caught it.
5. Remember the second deny path: an approved entry with the same `uniqKey` today → `ALREADY_ENTERED`. If the question is about a real scan that "should have passed", check entries for a dedup hit before blaming the rules.

Read-only: this skill explains matching; it never edits rules, seed data, or code. Rule changes are a scope question for Mark (and a decision-log entry via `/decision`).
