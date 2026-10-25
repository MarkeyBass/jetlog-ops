---
name: new-fixture
description: Turn a raw scanned boarding pass into a proper test fixture in server/tests/fixtures/barcodes.json — redacted, width-preserved, with a domain-computed expected block — and prove the suite stays green. Use for "add this barcode as a fixture", "make a test from this scan", or when a bug report comes with a raw pass. Argument: the raw BCBP string (+ optionally the known correct outcome).
---

Fixtures are ground truth: real scans with known outcomes (originally from the xlsm `Checkup` sheet). A new fixture must meet the same bar — this skill is exacting on purpose. Input: $ARGUMENTS.

## Steps

1. **Decode first** (offline, via the domain code — see `/decode-barcode`). If the string doesn't parse, stop and hand the bytes to the **bcbp-domain-expert** agent; never add an unparseable fixture.
2. **Redact the passenger name — mandatory** (real passenger data must not enter the repo): replace the name characters with `******` while **preserving the exact 20-char field width** (offsets 2–21). Verify after redaction that leg-1 origin still reads at offset 30 — a shortened name field shifts every later offset and breaks standards parsers (see the 2026-07-17 re-padding decision).
3. **Build the `expected` block by running the real domain functions**, matching the existing fixtures' shape exactly: `carrier`, `compartment`, `frequentFlyer`, `companyVar`, `club`, `ruleKey`, `description`, `approved`, `flightNumber`, `julian`, `uniqbcbp` (note: `uniqbcbp` keeps the Excel-style space padding — copy the format of existing entries, e.g. `"007-EY -0594 -0062 -TLV"`).
4. **Cross-check:** if the user supplied a known outcome, the computed block must agree with it. Disagreement = a finding about the code (or the claim), not a value to fudge — investigate with bcbp-domain-expert before committing anything.
5. **Append** to `server/tests/fixtures/barcodes.json` (keep JSON formatting consistent) and run `cd server && npm test`. The fixture-driven tests (`tests/unit/fixtures.test.ts`, `tests/unit/parse.test.ts`) pick fixtures up from the file; confirm the new one is actually exercised — if a test hardcodes a fixture count, update it.
6. Report: the redacted barcode, the expected block, which tests cover it, and the green test run. If this fixture exists to reproduce a bug, say so and note that the *expected* values encode the **correct** behavior, not the buggy one.
