> **HISTORICAL — frozen, kept for the record. Do not follow or edit it.** This is the POC's architecture & scope brief. Superseded by [ARCHITECTURE.md](../ARCHITECTURE.md) (how the system is built) and [PLAN.md](../PLAN.md) (where it's going); its §9 "deferred" list is no longer binding. Moved to `docs/archive/` on 2026-10-14; links inside may point at old paths.

# JetLog POC — Architecture & Scope Brief

> **SUPERSEDED — historical document.** This was the POC scope brief. The POC is complete and the codebase has moved beyond it (exceptional approvals, rules editor, guest policies, and more are built). **§9's "deferred" list is no longer binding.** For the current architecture and direction see [`docs/HANDOFF.md`](docs/HANDOFF.md) and [`CLAUDE.md`](CLAUDE.md). Kept for the record of why the POC was shaped the way it was.

**Goal:** prove the end-to-end Phase-1 loop — *scan boarding pass → parse BCBP → evaluate entry rule → handle guests → log entry → show result* — on localhost, demoable to the client.
**Non-goal:** production hardening. This is a de-risking demo, not Phase 1 itself (POC ≈ 15% of Phase 1).

---

## 1. Stack

| Layer | Choice | Notes |
|---|---|---|
| Frontend | React + Vite + TypeScript | Single-page operator screen |
| Barcode input (dev) | `html5-qrcode` (ZXing) | Phone/laptop camera → raw string, client-side decode. PDF417 **and** QR/Aztec (mobile wallet passes) |
| Barcode input (prod-like) | Focused `<input>` field | USB scanner = keyboard wedge; same code path as manual paste |
| Backend | Node.js + Express + TypeScript | Structure modeled on the Cicada backend, upgraded to TS |
| BCBP parsing | `bcbp` npm package | Parse on the **backend** (source of truth, validation, sanitization) |
| DB | PostgreSQL in Docker | via docker-compose |
| Real-time | **None** (no SSE/WebSockets) | One operator, one PC, one tab — scan result renders in the same client that sent it. SSE deferred until a real two-device flow exists |

---

## 2. Architecture

```
[React operator screen]
   │  raw barcode string (camera decode OR scanner/paste into input)
   ▼  POST /api/scan
[Express + TS]
   ├─ parse: bcbp.decode(raw) → use legs[0] only
   ├─ sanity: leg1.origin === "TLV" ? ok : warn flag
   ├─ dedup: uniq key lookup in entries
   ├─ rules: wildcard match → decision + allowedGuests
   ▼
[PostgreSQL]  ← entries, rules
   ▼
JSON response → UI renders decision + starts guest session (client state)
```

Everything synchronous request/response. No queues, no events, no auth.

---

## 3. Data model (minimal — 2 tables)

```sql
-- rules: seeded from Vlad's Excel Rules sheet (subset is fine)
CREATE TABLE rules (
  id            SERIAL PRIMARY KEY,
  carrier       TEXT NOT NULL,        -- 'EY', 'BA'
  compartment   TEXT NOT NULL DEFAULT '#',   -- '#' = wildcard
  frequent_flyer TEXT NOT NULL DEFAULT '#',
  company_var   TEXT NOT NULL DEFAULT '#',   -- airline user field (EY: LA/LB/LF/LC)
  club          TEXT NOT NULL DEFAULT '#',
  rule_key      TEXT NOT NULL,        -- e.g. 'EY ##LA#'
  description   TEXT,
  allowed_guests INT NOT NULL DEFAULT 0,  -- numeric! (Excel had text — this is the upgrade)
  active        BOOLEAN NOT NULL DEFAULT TRUE
);

-- entries: the Movements log
CREATE TABLE entries (
  id            SERIAL PRIMARY KEY,
  raw_barcode   TEXT NOT NULL,
  carrier       TEXT, flight_number TEXT, flight_date DATE,
  compartment   TEXT, frequent_flyer TEXT, company_var TEXT,
  uniq_key      TEXT NOT NULL,        -- julianDate-carrier-flight-seq-origin
  approved      BOOLEAN NOT NULL,
  rule_key      TEXT,
  is_guest      BOOLEAN NOT NULL DEFAULT FALSE,
  host_entry_id INT REFERENCES entries(id),  -- guest → primaryPassenger link
  lounge        TEXT NOT NULL DEFAULT 'C',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

`host_entry_id` is the **proof of host↔guest connection** Vlad needs for billing. That link is the POC's money shot.

---

## 4. Core backend logic (ported from Vlad's Excel — already proven)

**4.1 Parse** — `bcbp.decode(raw)`, take `legs[0]` (Israel = first leg; `M2...` barcodes carry 2 legs, ignore leg 2). If `legs[0].origin !== 'TLV'` → include `warning: "first leg does not depart TLV"` in response, don't block.

**4.2 CompanyVar** — the airline "user field" (EY lounge codes LA/LB/LF/LC) lives in the conditional section. If the `bcbp` lib exposes airline-use data, use it; otherwise port the offset walk from the Excel `LET` formula (hex size at pos 59 → walk conditional block). Acceptable POC fallback: extract for EY samples only.

**4.3 Rule matching (wildcard)** — for each dimension (compartment, FFP, companyVar, club): if a rule row exists for this carrier with the scanned value → use the value, else `#`. Concatenate → ruleKey → lookup active rule. Specific beats wildcard by construction.

**4.4 Dedup** — `uniqKey = julianDate-carrier-flightNumber-seqNumber-origin`; if an approved entry with same key exists → deny with reason `ALREADY_ENTERED`.

**4.5 Guest flow (session = client state, not DB)**
1. Scan primary → approved → response includes `allowedGuests` from rule.
2. UI: "How many guests? (0–N)" → operator picks count.
3. UI enters guest mode: scan each guest → `POST /api/scan { hostEntryId }` → same parse/dedup, `is_guest=true`, linked.
4. POC guest rule: same carrier as host = approve (same-flight check: nice-to-have).

---

## 5. API (3 endpoints)

```
POST /api/scan        { rawBarcode, hostEntryId? }
  → { approved, reason?, warning?, ruleKey, description,
      allowedGuests, entryId, parsed: {carrier, flight, date, compartment, ffp, companyVar} }

GET  /api/entries     → last 50, guests nested under hosts
GET  /api/rules       → active rules (read-only display)
```

---

## 6. UI (one screen, three states)

- **Scan state:** big focused input (wedge/paste) + "use camera" toggle (html5-qrcode).
- **Result state:** APPROVED (green) / DENIED (red + reason) card — rule description, parsed fields, guest-count prompt when `allowedGuests > 0`.
- **Guest state:** "Scanning guest 2 of 3" progress, per-guest result, Done → back to scan.
- Below: table of today's entries (from `GET /api/entries`), guests indented under host.

RTL not required for POC. English UI is fine.

---

## 7. Test fixtures

Seed `rules` with the EY rows from the Excel (`EY ##LA#`, `EY ##LB#`, `EY ##LF#` + Gold/Platinum variants, guest rows) and 2–3 BA rows. Use the **real scanned EY barcodes from the Checkup sheet** as test inputs — expected outputs are already known (e.g. `EY ##LA#` → LOUNGE ACCESS, approved). Write 5–8 unit tests on parse + ruleKey + dedup from these.

---

## 8. Deployment

**Step 1 (the actual POC): docker-compose on localhost.** Three services: `web` (Vite build served by nginx or Express static), `api`, `pg` (+ volume). Seed script runs migrations + rules on `docker-compose up`.

**Step 2 (optional, demo-hosting only): Terraform → 1 EC2 running the same compose.** Time-boxed to half a day; if it fights you, demo from a laptop — the client outcome is identical. **Do not over-invest:** production target is *their* infra (on-prem likely, they own hosting) — compose portability is the point, the EC2 is disposable.

---

## 9. Explicitly deferred (not in POC — do not build)

- Auth / roles / double-login station model
- Rules admin UI (rules are seeded; DB-editable is enough)
- Reporting, filters, per-lounge separation (hardcode `lounge='C'`)
- Multipass, vouchers, named lists, payments, exceptional approvals
- SSE / any real-time channel
- Same-flight guest validation (same-carrier only)
- Offline mode, capacity, MALAM, ERP, BI
- Hebrew/RTL, styling polish beyond readable

---

## 10. Honest time budget

| Chunk | Est. |
|---|---|
| Backend: scaffold + bcbp + rules + dedup + endpoints + tests | 2.5–4 h |
| Frontend: scan screen + states + guest loop + entries table | 2–3 h |
| docker-compose + seed | 1 h |
| Buffer (CompanyVar offsets, camera quirks) | 1–2 h |
| **Localhost POC total** | **~6.5–10 h (1–1.5 days)** |
| Optional EC2 via Terraform | +0.5 day, time-boxed |

*Never quote build-time to the client. The POC de-risks parsing and demos the flow — it is not Phase 1 and must not re-anchor its price.*
