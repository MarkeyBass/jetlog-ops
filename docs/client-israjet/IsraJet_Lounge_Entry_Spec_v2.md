# IsraJet — Lounge Entry & Entitlement System
### Functional Specification (English) — Draft v2

**Status:** Draft for review
**Date:** July 2026
**Sources:** Original Hebrew characterization document (אפיון כניסה לטרקלין, 10‑06‑26) + two requirements meetings with Vlad + follow-up conversations + **analysis of the working Excel prototype (`JetLog_v11_DEMO.xlsm`)**.
**Changes from v1:** guest flow fully specified (§7.1.1); rules-engine algorithm, BCBP parsing detail, and dedup logic extracted from the Excel prototype (Appendix A); technology stack confirmed (§3); Multipass partner list updated (§6 Phase 3); open items updated (§11).
**Note on open questions:** Items the client has not yet decided are collected in **Section 11 — Open Items**. They are intentionally *not* guessed at in the body.

---

## 1. Overview

IsraJet operates **two airport lounges** ("טרקלין") at Ben Gurion Airport. Each lounge hosts travelers who are, in almost all cases, **not paying directly** — instead the lounge is paid by whoever the traveler "belongs to": an airline, a credit‑card/benefits network, a membership organization, or via a pre‑issued voucher. A small minority of visitors pay on the spot.

The system to be built is an **entry‑validation and entitlement‑capture engine**. Its job is to prove who entered, establish which paying party is responsible for them, log the entry as billing evidence, and report on it per lounge so IsraJet can invoice its B2B partners at month‑end.

It is therefore better understood as an **entitlement-and-billing-evidence system** than as a payment terminal, even though one of its flows does take payment.

A **working Excel prototype** built by the client (Vlad) already implements the airline flow manually: BCBP parsing, a 234-row rules table, duplicate-entry checking, and an entry log. Its logic has been analyzed and is preserved in **Appendix A** — the application ports this proven logic rather than inventing it.

---

## 2. The Core Engine

Underneath every customer type is a single loop:

> **Scan an identifier → evaluate it against configurable entry rules → approve/deny entry (and any eligible guests) → log the full transaction → report per lounge.**

The original spec defines six customer types. They are not six systems — they are **six ways of entering the same engine**, each differing only in how identity and entitlement are established:

1. **Airline passengers** — boarding-pass barcode.
2. **Multipass customers** — credit-card/benefits network (Amex, Histadrut Refuit, etc.).
3. **Named-list / handling organizations** — pre-loaded list lookup (e.g. AEROHANDLING).
4. **Voucher / coupon holders** — pre-issued single-use or time-limited codes.
5. **Exceptional approvals** — manual VIP entry pre-authorized by an admin.
6. **Paying walk-ins** — on-the-spot payment.

All six converge on the same logging and reporting layer.

---

## 3. Architecture & Deployment

- **Application type:** Web application, running in **Chrome or Edge**. No native desktop or mobile app.
- **Technology stack (confirmed):**
  - **Frontend:** React + Vite + TypeScript.
  - **Backend:** Node.js + Express + TypeScript. BCBP parsing performed **on the backend** (source of truth, validation, sanitization) using the open-source `bcbp` npm package, supplemented by custom conditional-field extraction (Appendix A §A.2).
  - **Database:** PostgreSQL. (The client's BI team will connect to it directly — see Section 9.)
  - **Real-time layer:** none required for the desk flow — one operator, one PC, one browser tab; scan results render synchronously in the same client.
- **Operator hardware:** **Windows 11** PC at the desk, with a **USB-connected 2D barcode scanner** acting as a **keyboard wedge** (emulated keyboard input into a focused field in the web app). Barcodes may be **PDF417** (printed passes) or **QR/Aztec** (mobile wallet passes); the input path is identical since the scanner delivers a decoded text string.
- **Number of stations:** **Two** — one per lounge (see Section 5). Two physical computers.
- **Back office / admin:** An administrative interface for configuration, rules, coupons, lists, and users.
- **Hosting & ownership:** **The client owns hosting and backups.** Deployment target is **most likely on-premises**; the client is still pricing cloud and will confirm. The contractor ships the application (containerized — Docker Compose — for portability to the client's infrastructure); the client operates the infrastructure.
- **Network:** Internal network, ~99% reliability expected, **no VPN required**. (Offline resilience is a separately-priced option — see Sections 6 and 11.)

---

## 4. Users, Roles & Access

- **Roles:** Two — **Admin** and **Cashier/Operator**.
- **Authentication:** **Username + password** is sufficient for launch and may remain the permanent approach. No SSO/Google requirement at this stage.
- **User count:** Approximately **5 operators** (up to ~10); not a scaling concern.
- **Admin access:** Admins can log in from **many locations**, not only the desk PCs.
- **Operator access:** Operators work from the lounge desk PCs and **can move between stations**.

### 4.1 The double-login model

Configuration is bound to the physical station:

1. **Admin login (setup):** An admin configures the PC — assigns it to a specific lounge, and sets the rules/contracts/parameters that apply at that station.
2. **Operator login (use):** The operator then logs in on that already-configured station to process entries.

This produces an intentional **two-step / double login**: station setup by admin, then operational use by the cashier.

---

## 5. Lounge / Station Model

**Important clarification from the meetings:** *lounge = desk = station = PC.* These terms are interchangeable here. There are **two** of them.

This is **not** full multi-tenancy. It is a **single organization** with a **"lounge" dimension** running through the data:

- A `lounge_id` (station identifier) tags every transaction, rule set, contract, and report.
- Each lounge may have **different airline/club contracts and billing terms**, so entries and revenue must be attributable to the correct lounge.
- Reporting must be separable per lounge.

The "lounge" is therefore a scoping dimension across **rules, billing, and reporting** — not merely a report filter.

---

## 6. Phased Delivery Plan

Vlad's explicit instruction is to work **agile, in phases**, prioritizing fastest time-to-value. Timeline target: **as fast as possible.** The phases below are the primary delivery and billing structure.

### Phase 1 — Airline passenger entry (barcode)
The foundational phase. Includes the shared engine, logging, and basic reporting.

- Parse the **boarding-pass barcode** (IATA **BCBP** format). A barcode may encode **multiple flight legs** (`M2...` = two legs); the system parses **leg 1 only** (the flight departing TLV), with a soft warning if leg 1's origin is not TLV. See Appendix A §A.1.
- Extract and evaluate: **airline (operating carrier)**, **cabin/class (compartment)**, **frequent-flyer (FFP) airline + number**, and the **airline "user field"** (`CompanyVar` — e.g. Etihad's lounge-access codes LA/LB/LF/LC). Conditional-section extraction per Appendix A §A.2.
- Present the operator with an **entry decision** based on rules (approve / deny + reason).
- **Duplicate-entry check:** the same boarding pass may not be admitted twice (uniqueness key per Appendix A §A.4).
- **Guest handling is in Phase 1** — see §7.1.1 for the confirmed flow.
- **Rules engine:** the wildcard-matching algorithm proven in the Excel prototype (Appendix A §A.3), with rules stored in the **database** and admin-editable. Implementation approach: **start with seeded rules, land the admin-editable DB rules UI by the end of Phase 1.** `AllowedQty` becomes a **numeric guest allowance** (the prototype stored it as descriptive text; the application enforces the number).
- Full transaction logging (Section 8) and basic per-lounge reporting (Section 9).
- **Exceptional approvals (אישור חריג):** simple manual VIP entry, admin pre-authorizes via dashboard, passenger + guests enter (see 7.6).

### Phase 2 — Voucher & named-list redemption (מימוש שוברים — מספרי או שמי)
Redemption by **numeric code** or by **named list**.

- **Coupon admin panel** for the admin to manage codes. Organizations include e.g. **Hever**, **Histadrut**.
- **Two coupon types:**
  - **Single-use** coupon.
  - **Time-limited** coupon — may be used to enter **unlimited times within a defined time window**.
- **Admin can cancel a coupon.**
- **Named-list flow:** for organizations supplying a roster (e.g. handling companies); operator looks the person up and marks redemption.
- **Coupon origination:** Vlad mints coupons → the company generates the QR code → the resulting data lands in the system. (Confirm exact handoff/format — see Open Items.)

### Phase 3 — Multipass integration
- Integration is via **a separate API per Multipass partner/club** — the design must be **modular so new partners can be added easily**.
- **Current partners (confirmed):**
  - **Amex** — via Multipass.
  - **Histadrut Refuit (Israeli Medical Association)** — via Multipass.
- **Scale consideration:** 2 partners today; could grow to ~10, and potentially up to ~100 clubs, **each potentially with a different API**. Additional partners beyond the first two are incremental work items.
- **Amex flow (example):** swipe the credit card → send card details to Multipass → Multipass/Amex returns the **available benefit options** → options are presented → operator selects and confirms.
- Do **not** store credit-card details (Section 10).

### Phase 4 — Payments / clearing (סליקה)
- On-the-spot payment for paying walk-ins.
- **Payment provider is not yet decided** (Tranzila is referenced for receipt generation but is not confirmed as the chosen gateway).
- **Hard requirement:** card data **never touches the contractor's server** — hosted/tokenized integration only (keeps the system out of PCI scope).
- Receipt generation handled by the payment provider (e.g. Tranzila generates the receipt).
- Multi-currency support (per original spec; confirm).

### Later / Bonus (priced separately)
- **Capacity / waitlist tracking** — *possible future requirement.* Per agreement, a stay is ~**2 hours**; staying longer could generate a **double charge.** Marked **Phase 2 / bonus**.
- **Offline mode** — keep working if the network drops mid-scan. Marked as a **separately-priced option**.
- **MALAM attendance report** — employee attendance hours export in **Malam payroll's** required format. Spec to be supplied by client. Marked **Phase 2 / bonus**, priced separately.
- **ERP receipt push** — a **custom script** to send receipts into the client's ERP. Marked **Phase 3**.

---

## 7. Detailed Functional Requirements (per flow)

### 7.1 Airline passengers
- **Identification by barcode stream (BCBP / IATA):** key fields at known fixed positions — operating carrier, flight number, Julian flight date, compartment, sequence number — plus a variable-length conditional section carrying FFP data and the airline user field. Full field map in Appendix A §A.1–A.2.
- **FFP club not in the barcode:** where the frequent-flyer *club/tier* is not derivable from the scan, it is resolved via a **selection list / pop-up showing membership-card images**, filtered to the airline identified by the scan.
- **Decision display:** approve/deny with the matched rule description (e.g. *"Approved — Rule: EY ##LA# LOUNGE ACCESS, Passenger + Guest"*) or a denial reason (rule not matched / already entered).

#### 7.1.1 Guest flow (confirmed with client)
The host↔guest link is **billing evidence** — it proves to the paying airline which admissions belong to which entitled passenger.

- **Current manual process (being replaced):** receptionist scans a guest's barcode, then separately scans/enters the host to attach them — inefficient and error-prone.
- **Target flow (to build):**
  1. Operator scans the **primary passenger** → rule evaluation returns the decision **and the allowed guest count**.
  2. UI asks: **"How many guests?"** (0 up to the rule's allowance) → operator selects.
  3. UI enters **guest mode**: the operator scans each guest's **boarding-pass barcode** sequentially, with per-guest validation and result.
  4. Each guest entry is stored linked to the primary passenger's entry (`host_entry_id`).
- **Guest validation rules** (admin-configurable per airline): guest on the **same airline / same flight** as the host, evaluated from the guest's own parsed barcode fields.
- The number of admitted guests must **not exceed** the rule's numeric allowance.

### 7.2 Rules generator (מחולל כללי כניסה)
- An admin-editable table of entry conditions, evaluated at scan time via the **wildcard-matching algorithm** (Appendix A §A.3): dimensions are *carrier, compartment, frequent-flyer, company-var (airline user field), club*; `#` means "don't care," and a specific value beats a wildcard.
- Supports **per-row date limits** (e.g. for end of a contract/engagement) and an **active** flag.
- Each rule carries: rule key, description, **numeric allowed-guest quantity**, active flag, date limits, lounge scope.
- The Excel prototype's 234-row rules table (BA + EY policies) is the **seed data source** for initial rules.

### 7.3 Multipass customers (credit-card / benefits networks)
- Identified via the Multipass partner API. The passenger does not pay IsraJet; settlement is with the organization at month-end via a consolidated invoice.
- Flow: Multipass menu → select club → enter voucher / swipe card / manual entry where permitted → choose guest/benefit options (e.g. Amex) → confirm.
- **Do not store credit-card details.**
- Customer-type label: `Multipass-[org]` (e.g. `Multipass-Amex`, `Multipass-Histadrut-Refuit`).

### 7.4 Named-list / handling organizations (non-Multipass)
- A named roster of permitted entrants with varying conditions: single entry on a specific date, or entry permitted until a given date.
- Requires a table to load entry data with date limits, plus customer-type/club.
- Flow: customer presents ID → operator locates them in the table and marks redemption.
- Customer-type label: `[org name]`, e.g. `AEROHANDLING`.

### 7.5 Voucher / coupon holders
- Codes issued by IsraJet's POS/logistics system, loaded into the registers and **"burned" on use**; all burned codes are retained.
- Customer-type label: `Vouchers-[org]` (e.g. `Vouchers-Direct-Finance`).

### 7.6 Exceptional approvals (occasional, אישור חריג) — *Phase 1*
- Simple manual-entry flow (no barcode parsing, rules, or integrations), so it ships in **Phase 1**.
- Primary workflow: an **admin pre-authorizes** a named VIP via the dashboard (e.g. celebrity, politician); the passenger and any guests then enter the lounge. (Desk-side entry by the operator is a possible variant.)
- Fields: **Name**, **ID**, **Barcode**, **approving authority**, optional field.
- Customer-type label: `Exceptional approvals`.

### 7.7 Paying walk-ins (occasional, payment)
- Standard paying entry. Support **multiple currencies**.
- Customer-type label: `Occasional customers`.

---

## 8. Data & Logging Requirements

For each entry, store:

- The **full barcode** as scanned (raw string).
- **Fields extracted** from it (carrier, flight number, flight date, compartment, FFP airline/number, company-var).
- **Club / membership** selected.
- **Scan date/time** (timestamp of redemption).
- The **entry decision** (approved/denied) and, for denials, the **reason** (no matching rule / duplicate entry).
- The **rule** that produced the decision (rule key + description).
- The **customer type** (taxonomy in Section 7).
- The **lounge / station** (`lounge_id`).
- The **duplicate-check uniqueness key** (Appendix A §A.4).
- **Guest records:** stored per guest as full entries, each linked to its host via `host_entry_id`.
- For Multipass and named-list/voucher flows: redemption confirmation / voucher reference and date.

**Prohibited:** storing credit-card numbers.

**Cross-cutting capture:** for every customer type, allow scanning the ticket barcode (even when not strictly required) to support **future analytics** of entries by airline / class / etc.

---

## 9. Reporting

- **Transaction-level detail report** — one row per entry, including **customer type** and **redemption date**; guests attributable to their host.
- **Per-lounge:** all reports must be produceable **separately per lounge** (terms and agreements may differ).
- **Filters:** by **date**, **airline**, **club**, **customer type** (per flow).
- **BI access:** the client's BI tooling will **connect directly to the SQL database** to view all data. The contractor delivers the **table structure and connection details**; the contractor does **not** build dashboards.

---

## 10. Non-Functional & Compliance

- **PCI scope:** payments must use a **hosted/tokenized** provider; card data must **never reach the contractor's server**. This keeps the system out of PCI scope and satisfies the "do not store card numbers" requirement.
- **Privacy (Israeli law):** the system stores personal data (names, ID numbers, boarding passes, frequent-flyer data). Israel's **Privacy Protection Law, as amended by Amendment 13 (in force August 2025)**, applies, with significantly strengthened enforcement. The **client is the data controller/owner** and owns the resulting obligations (database documentation, any DPO appointment, and the determination of whether periodic penetration testing applies). The contractor builds to the Data Security Regulations (access control, logging, etc.). *(Orientation only — the client's legal counsel makes binding determinations.)*
- **Hosting:** client-owned; on-prem likely. Backups owned by the client.
- **Offline option:** available as a separately-priced capability if required.

---

## 11. Open Items (decisions pending)

| # | Item | Status / needed from |
|---|------|----------------------|
| 1 | **Payment provider** | Undecided. Tranzila referenced for receipts only. Must be hosted/tokenized. |
| 2 | **Hosting: on-prem vs cloud** | Client pricing it; on-prem most likely. Client to confirm. |
| 3 | **Support model** | Not finalized. Hourly maintenance discussed; commercial terms open. |
| 4 | **Multipass docs + sandbox/test env** | Pending. Both contractor and Vlad to chase. Per-partner APIs (Amex, Histadrut Refuit first). |
| 5 | **MALAM attendance report spec** | Client to send file format. |
| 6 | **Coupon handoff/format** | Confirm exact data/format flow: Vlad mints → company generates QR → into system. |
| 7 | **Admin pre-auth vs desk entry** (exceptional approvals) | In Phase 1. Confirm: admin pre-authorizes VIP via dashboard (primary) vs operator records at desk (variant). |
| 8 | **Capacity/waitlist** | Possible future (Phase 2/bonus); 2-hour stay → potential double charge. |
| 9 | **Multi-currency (paying walk-ins)** | Confirm scope/currencies. |
| 10 | **FFP club-image popup** | Confirm which airlines require the manual club-selection popup vs full derivation from the barcode. |

---

## 12. Dependencies

- **Field staff & client IT** — for deployment, on-prem environment, and operational rollout.
- **Multipass** — API documentation and test environment (blocking Phase 3).
- **Payment provider decision** (blocking Phase 4).
- **MALAM format** (blocking the attendance-report bonus).
- **Coupon-generation handoff** from Vlad / partner company (affecting Phase 2).

---

## Appendix A — Extracted Logic from the Excel Prototype (`JetLog_v11_DEMO.xlsm`)

The client's macro-enabled Excel is a working manual implementation of the airline flow. Its logic was reverse-engineered and is preserved here as the authoritative reference for Phase 1. The prototype's flow: scan into a *Template* row → formulas parse and decide → a VBA macro copies the row into a *Movements* log table and clears for the next scan (prompting "Enter Host Id / Scan Barcode").

### A.1 BCBP fixed-field positions (mandatory block, 1-indexed)

| Field | Position | Length | Notes |
|---|---|---|---|
| Format code | 1 | 1 | `M` |
| Number of legs encoded | 2 | 1 | `M2...` = two legs; **parse leg 1 only** |
| Passenger name | 3 | 20 | |
| Operating carrier PNR | 24 | 7 | |
| From airport | 31 | 3 | Expect `TLV`; warn if not |
| To airport | 34 | 3 | |
| **Operating carrier** | **37** | **3** | → `carrier` |
| **Flight number** | **40** | **5** | |
| **Date of flight (Julian)** | **45** | **3** | Day-of-year; convert with current year |
| **Compartment code** | **48** | **1** | → cabin/class |
| Seat number | 49 | 4 | |
| **Check-in sequence number** | **53** | **5** | Used in dedup key |
| Passenger status | 58 | 1 | |
| **Size of variable field (hex)** | **59** | **2** | Gates the conditional section |

The recommended implementation uses the open-source `bcbp` npm package for the standard fields, with the positions above as the verification reference; multi-leg barcodes concatenate additional leg blocks after the first.

### A.2 Conditional-section walk (FFP + airline user field)

The variable-length conditional section begins at position 61 when the hex size at position 59 is > 0. The prototype's decoding (ported from its `LET` formulas):

```
s          = barcode with CR/LF stripped
varSize    = hex2dec(s[59..60]);  hasCond = varSize > 0
condStart  = 61
uniqLen    = hasCond ? hex2dec(s[63..64]) : 0        // size of unique structured block
uniqStart  = condStart + 6                            // = 67
repStart   = uniqStart + uniqLen                      // repeated (per-leg) block start
repLen     = hex2dec(s[repStart-2 .. repStart-1])

issuer     = trim(s[uniqStart+8 .. +3])               // boarding-pass issuer airline
marketing  = trim(s[repStart+15 .. +3])               // marketing carrier
ffAirline  = trim(s[repStart+18 .. +3])               // frequent-flyer airline → FrequentFlyer
companyVarStart = 61 + uniqLen + repLen + 6
CompanyVar = trim(s[companyVarStart .. (61 + varSize − companyVarStart)])
                                                      // airline "user field" — e.g. EY lounge codes
```

**Known `CompanyVar` values (Etihad):** `LA` / `LB` / `LC` = lounge access variants, `LF` = lounge premium. These drive EY's entry rules.

### A.3 Rules engine — wildcard matching algorithm

Rule dimensions: `Carrier, Compartment, FrequentFlyer, CompanyVar, Club`. `#` = "don't care."

**Key construction for a scan:** for each dimension (Compartment, FrequentFlyer, CompanyVar, Club):
- If any rule row exists for this **carrier** with the scanned **specific value** in that dimension → use the specific value;
- otherwise → use `#`.

Concatenate `carrier + compartment + ffp + companyVar + club` → **RuleKey** (e.g. `EY ##LA#`) → look up the rule row (must be `Active`) → obtain `RuleDescription` and **allowed guest quantity**. By construction, a specific rule always beats a wildcard rule for the same carrier.

**Approval:** `approved = ruleMatched(Active) AND notDuplicate`.

**Seed data:** the prototype's 234-row Rules table (British Airways + Etihad policies, including per-tier guest allowances and dedicated `Guest` rule rows) seeds the initial database. **Upgrade required:** the prototype's `AllowedQty` is descriptive text ("Passenger + 2Guest"); the application stores a **numeric allowance and enforces it**.

### A.4 Duplicate-entry key

```
uniqKey = julianDate + "-" + carrier + "-" + flightNumber + "-" + sequenceNumber + "-" + originAirport
```

A scan is a duplicate (deny, reason `ALREADY_ENTERED`) if an **approved** entry with the same key already exists.

### A.5 Test fixtures

The prototype's *Checkup* sheet contains **real scanned EY boarding passes** (flight EY 594 TLV→AUH) with known expected outcomes (e.g. `CompanyVar=LA` → rule `EY ##LA#` → approved, "LOUNGE ACCESS, Passenger + Guest"; no lounge code → `EY ####` → denied). These serve as the **unit-test fixture set** for the parser, key builder, rule matcher, and dedup logic.

### A.6 Prototype → application mapping

| Prototype artifact | Application equivalent |
|---|---|
| Template row (formulas) | Backend scan-evaluation service |
| Movements table | `entries` table |
| Rules sheet | `rules` table + admin UI |
| VBA macro (copy row, clear, host prompt) | POST /scan endpoint + guest-session UI state |
| Host column (manual ID entry) | `host_entry_id` foreign key, set by the guest flow (§7.1.1) |
| Encoding-FFP sheet (853 rows) | FFP club reference table (seed data) |

---

*End of Draft v2. Section 11 lists what to close with the client; Appendix A is the authoritative Phase-1 logic reference.*
