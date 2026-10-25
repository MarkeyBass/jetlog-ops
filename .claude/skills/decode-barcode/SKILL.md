---
name: decode-barcode
description: Decode a raw BCBP boarding-pass string offline — no server, no DB — field by field with offsets, plus the rule outcome the scan pipeline would produce. Use for "what's in this barcode", "why did this parse weird", or checking a pass before scanning it. Argument: the raw barcode string (or a fixture index from barcodes.json).
---

Decode **offline** through the real domain code — `server/src/domain/` is pure (zero I/O), so a scratch script gives the exact production parse without Postgres or the API. The argument: $ARGUMENTS (a raw string, or an index into `server/tests/fixtures/barcodes.json`).

## Steps

1. Write a throwaway script `server/scratch-decode.ts` (delete it when done):
   ```ts
   import { parseBoardingPass } from './src/domain/parseBoardingPass.js';
   import { matchRule } from './src/domain/ruleKey.js';
   import { buildUniqKey } from './src/domain/uniqKey.js';
   import rules from './src/db/seed-data/rules.json' with { type: 'json' };
   ```
   Parse the raw string, then run `matchRule` over the seed rules (map JSON rows to the `RuleLike` shape — read `src/domain/types.ts` for the exact fields). Run with `npx tsx scratch-decode.ts` from `server/`.
2. Pass the barcode **byte-for-byte** — BCBP is offset-sensitive; no trimming, no re-wrapping. In PowerShell prefer writing the string into the script file over shell-quoting it.
3. Report, in order:
   - **Fixed fields** with their offsets: legs, name (redacted?), PNR, origin/destination, carrier, flight, julian date, compartment, seat, sequence. Flag an origin outside the `departure_airports` global rule (seeded `TLV`) as a `DEPARTURE_AIRPORT_NOT_ALLOWED` denial, and a flight date outside today ±2 days (Israel) as `FLIGHT_TOO_FAR_AHEAD` / `FLIGHT_TOO_LONG_AGO`.
   - **companyVar** from the conditional section (`leg.airlineInfo`; EY: LA/LB/LF/LC or N).
   - **Derived values:** `uniqKey`, built `ruleKey` (show the per-dimension wildcard-collapse — which scanned values survived, which fell to `#`), matched rule + description or "no matching rule → denied".
4. If the parse itself fails or contradicts expectations byte-wise, hand off to the **bcbp-domain-expert** agent for a manual offset decode — that's its specialty. A shortened name field (offsets shifted, origin not at 30) is the classic culprit.

This skill never writes fixtures and never touches the DB — read-only analysis plus one temp script.
