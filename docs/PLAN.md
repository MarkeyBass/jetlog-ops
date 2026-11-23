# JetLog — Plan (the UI redesign)

**For:** the agent picking up the next task, and Mark.
**Started:** 2026-10-23. It follows the post-POC plan (tasks 1–32), now [archive/2026-10-post-poc-plan.md](archive/2026-10-post-poc-plan.md), which also holds the study path. Task numbers continue from there, and the unfinished tasks keep their numbers.

How the system is built: [ARCHITECTURE.md](ARCHITECTURE.md). Why it is built that way: [DECISIONS.md](DECISIONS.md). Deliberately unscheduled ideas: [BACKLOG.md](BACKLOG.md). How Mark works and the safety rules: [CLAUDE.md](../CLAUDE.md) and [dev-style/](dev-style/).

---

## 1. Open tasks

The summary of each task's `**Status:**` line; keep the two in agreement.

| Order | Task | Status |
|---|---|---|
| 1 | **33** Role split in today's styling | Done (PR #37) |
| 2 | **34** The look: theme tokens, light/dark, the app frame | Done (PR #38) |
| 3 | **35** Hebrew and RTL foundation (absorbs task 17) | Done (PR #39) |
| 4 | **36** The desk: scan-first page, operator log, scan modals | Done (PR #40) |
| 5 | **44** The database server: use IsraJet's PostgreSQL 16 as it is | Done (PR #1, PR #3) |
| 6 | **15** Login and roles: register, log in, the role decides the pages | Done (PR #5) |
| 7 | **16** What is left of the admin panel: users | Done (PR #7) |
| 8 | **49** Close the API's own port (8000) | Done (PR #8) |
| 9 | **52** Login protection: limit failed logins | Done (PR #8) |
| 10 | **53** Security headers on nginx; no CORS; no version headers; an Origin check | Done (PR #9) |
| 11 | **54** Hardened containers: non-root, production-only images, read-only, health checks | Done (PR #10) |
| 12 | **55** The security audit log | Done (PR #11) |
| 13 | **46** Who did it: the user on every entry and change | Done (PR #12) |
| 14 | **48** A maximum session length, with a warning before the logout | Done (PR #13) |
| 15 | **31** Length limits on every free-text column | Done (PR #14) |
| 16 | **58** Rate limits on nginx, against a flood | Done (PR #15) |
| 17 | **56** Security scans in the pipeline, and the release report | Done (PR #16) |
| 18 | **59** Server errors never show their text; ids checked against the column | In progress |
| 18 | **18** Production deployment (the app server), without an image registry | Next |
| when IT delivers the certificate | **57** TLS: HTTPS, the `Secure` cookie, HSTS | Next |
| — | *IsraJet IT's penetration test* (IT's; not a task of ours) | — |
| 19 | **47** Stations: the admin sets each computer's lounge | Next |
| 20 | **37** Entry details and the change panels | Next |
| 21 | **38** The days-of-entries global rule and the operator's log window | Next |
| 22 | **39** Admin: All entries | Next |
| 23 | **40** Admin: Rules | Next |
| 24 | **41** Admin: Clubs, Lounges, Approvers, Global rules | Next |
| 25 | **43** Hebrew for the admin pages | Next |
| 26 | **42** The full user guide for the redesign | Next |
| — | **50** Fix the npm audit findings | Done (PR #6) |
| — | **51** Containers as non-root; no version headers | Superseded (by 53 and 54) |
| — | **45** Re-entry after a flight delay (already-entered pass) | Done (PR #4) |

**Order (Mark, 2026-10-23):** the role split first, then the redesign in small tasks so each diff can be followed, then authentication, then deployment and the guide. **31 can run at any point**: it is a server safety task that depends on neither the redesign nor login. Task 17 (Hebrew and RTL) is superseded by 35 and by the redesign tasks that build every screen RTL-ready.

**Order changed (Mark, 2026-10-25), after task 36:** the database server first (44, split out of 18), then authentication (15) and users (16), then the app server (18), and only then the rest of the redesign (37–41, 43) and the guide (42). Login replaces the View as switch and keeps the layout, so the screens built after it are not affected, and the days window (38) can be enforced by the server from the start. With the app server deployed by GitHub Actions before the remaining screens, every one of them is shipped through the pipeline, so the deployment is exercised many times before go-live instead of by hand. Why: DECISIONS.md, 2026-10-25.

**Task 15 split (Mark, 2026-10-27):** authentication starts basic — register, log in, the role decides the pages and the admin endpoints (15). Who did each entry (46) and the station token (47) follow users (16), before the app server (18); a maximum session length with its warning (48, Mark, 2026-10-31) comes right after 16. Why: DECISIONS.md, 2026-10-27.

**Security before the pen test (Mark, 2026-11-03):** IsraJet's IT received the security-review doc and will run `npm audit` and a penetration test. Tasks 49–51 close the gaps the doc lists as known, before IT gets the code; they are independent of each other and of the redesign.

**Security first (Mark, 2026-11-17):** every item of IT's security assessment that is ours comes before IT's penetration test, and the UI redesign (37–43, 42) after it, since IsraJet doesn't need its features to go live.

**How every task runs** (the full rules are in CLAUDE.md and the dev-style files): one task = one branch off `staging` = one PR. Plan first and wait for Mark's OK. Server first, then client, with a review stop after each. Store changes go through `store-test-writer`, user-visible changes through `user-guide-writer`, DEPLOY.md changes in the same commit and ARCHITECTURE.md in the paired ops commit (`/commit`) when the task touches them. Mark runs `db:generate` and `db:migrate` himself; the agent runs them only when he explicitly allows it for that task, on the local databases. `/verify` before handing over. Commit only after his go.

---

## 2. Decided for the whole redesign (Mark, 2026-10-23)

These hold for tasks 33–42 unless a task's own "Decided" list says otherwise.

- **The redesign changes the look, not the features.** Every feature built in tasks 1–32 stays and works as it does now. The one functional change is the role split (33), plus the days-of-entries window (38). IsraJet's old desk application (photos with Mark) shows what the desk staff are used to: big clear buttons, a short path, the count always on screen. It is a reference for familiarity only, never a source of features or of a look.
- **The mock is the reference:** https://claude.ai/artifact/Dfu6eF4fPzHEzr59fG8K7U (private to Mark). Switch **View as** to see both roles. Its Hebrew is a draft.
  - **Operator:** the **scan-first** page: one big scan box, ⚡ Manual approval, a strip of the latest scans, and the operator's log on a second tab.
  - **Admin:** **compact tabs** under the header, in this order: Scanning, All entries, Rules, Global rules, Clubs, Lounges, Approvers. Below about 900 px the tabs fold into a **☰ menu** that shows the current page.
  - **The entries toolbar** (lounge, result, search, filters) **stays on screen while scrolling**, on the operator's log and on All entries.
  - **Light and dark**, with a toggle in the header. It follows the system setting until the user picks one, and then remembers the choice on that computer.
- **Screens:** mouse and keyboard; no touch screens. Layouts work from a small laptop (1366×768) to a large desktop monitor. Wide tables scroll inside their card; modals scroll inside themselves. No on-screen keypads.
- **Language:** Hebrew by default, with a switch to English, remembered on each computer. (Task 35: the layout stays as in English; each Hebrew text reads right to left in its place.) Boarding-pass data, rule keys, flight numbers, codes and dates stay left-to-right inside Hebrew text. The Hebrew strings come from Mark or IsraJet; agents may draft them, marked as drafts, and never ship machine Hebrew as final.
- **Kept from task 32:** every scan and every action opens in a modal, one at a time. A USB scan always lands in the scan field the user can see. Forms that change data submit only from their button. The modal footer has the secondary actions (grey) on one side and the one main action (blue) on the other. ~~In Hebrew the footer mirrors, so the main action sits on the left.~~ Superseded in task 35 (Mark, 2026-10-24): nothing mirrors in Hebrew, so the main action stays on the right.
- **Clear status at a glance:** approved and denied as colour-coded badges, ⚡ exceptional in its own purple (never a warning colour: it was approved), every deny reason listed.
- **shadcn + Tailwind only**, never MUI. Colours, fonts and spacing are tokens (34), so later changes to the look stay token changes.
- **The station lounge picker stays as it is** until task 47. Later an admin sets each computer's lounge in a station-setup window, and the operator's badge becomes read-only.

---

## 3. The tasks

### 33. Role split in today's styling (medium, client only)
**Status:** Done (PR #37)
**Why:** the redesign is built role by role. Splitting the pages first, in today's styling, means the redesign's diffs show only styling and stateless components, never behaviour, so Mark can check that nothing else changed.

**Decided (Mark, 2026-10-23):**
- **Two roles, `operator` and `admin`.** There is no login yet. A temporary **View as: Operator / Admin** switch in the header chooses the role. It is remembered on that computer (localStorage, through a pure helper in `lib/`, like `lib/stationLounge.ts`). The default is **Operator** on a computer that has never chosen. Task 15 replaces the switch and keeps the layout.
- **What each role sees:**

  | Page / action | Operator | Admin |
  |---|---|---|
  | **Scanning:** scan box, club question, result, guest loop, ⚡ Approve anyway, ⚡ Manual approval | ✓ | ✓ |
  | Station lounge picker (as today) | ✓ | ✓ |
  | **Scanning page's log:** lounge switch, result switch, search, sort | ✓ | ✓ |
  | Entry details, and every change inside the modify window (move, rescan, approve as exception, add guests, change quantity, void) | ✓ | ✓ |
  | **All entries:** the filter panel, Whole parties / Single entries, Clear, ⤓ Export CSV | ✗ | ✓ |
  | Rules, Global rules, Clubs, Lounges, Approvers | ✗ | ✓ |

- **Navigation:** the operator has no navigation (Scanning only). The admin has one row of tabs in the order of §2.
- **A role switch to a role that can't see the current page goes to Scanning.** For example, an admin on Rules who switches to Operator lands on Scanning.
- **The two pages share one filter state** (`entryFilters`, `searchQuery`, the sort and the match mode, as today). **Opening Scanning clears the filters it has no controls for** (club, airline, class, frequent flyer, flight and scan dates, status beyond the result switch, host/guest, exceptional, modified, deny reason) and puts the match mode back to whole parties, so nothing invisible narrows that log. The lounge switch, the result switch and search stay shared. An admin who goes to Scanning and back loses those filters, and that is accepted.
- **Out of scope:** any restyling, dark mode, Hebrew/RTL, any server change, and the days window (38). The server doesn't check roles until task 15, so hiding the export is screen-only for now; the guide says so.
- **Reuse, don't copy:** one entries table with props or small wrappers, not two copies of the log.

**Decided in the task's plan (Mark, 2026-10-23):**
- **Names, each defined once in `lib/`:** `Role` = `operator` | `admin` (`lib/role.ts`); the views in `lib/views.ts` (re-exported by `store/types.ts`), with the view `operator` renamed **`scanning`** (so an admin is never "on the operator view") and **`entries`** for All entries.
- **The wedge routing acts on All entries too**, so a scan in a modal opened there (the guest loop, a rescan) lands in its scan field. With no modal open, All entries has no scan box: a scan there is swallowed with a toast pointing to Scanning, so its Enter can't press a focused button. The other admin pages keep no routing, as today.
- **Scanning keeps** the lounges (one or several: the lounge switch shows "Several lounges"), search, and one result status; **it clears** two or more statuses and every filter it has no control for, and puts the match mode back to whole parties.
- **Clear:** no Clear in Scanning's filter bar; the "No entries match… Clear filters" link stays on both pages.
- **Headings:** "Today's entries" on Scanning, "All entries" on the admin page.
- **The admin pages keep their "Back to scanning" buttons** (the redesign may remove them).
- **View as** sits in the header next to the station lounge picker, labelled "temporary, until login", in today's styling.
- **One modal set for both pages:** the scan-flow, entry-details and exception modals are mounted on Scanning and on All entries (entry details opens the guest loop).

**Touch:**
- **Client:** `App.tsx` (the view switch per role), `store/slices/viewSlice.ts` and `store/types.ts` (the role, the views per role; tests through `store-test-writer`), the entries components and hooks (`EntriesTable`, `EntryFiltersPanel`, `useEntriesView`), `hooks/useWedgeRouting.ts` if needed, pure helpers in `lib/` with unit tests.
- **Docs:** USER_GUIDE through `user-guide-writer` ("The screens", the log, filtering and export), ARCHITECTURE §6 (the role, the views per role).

**Done when:**
- With View as = Operator, there is no admin navigation. The Scanning page has the scan box and the log, with no filter panel, no parties switch and no Export CSV, and every scan flow and entry change works as before.
- With View as = Admin, the tabs read Scanning, All entries, Rules, Global rules, Clubs, Lounges, Approvers. All entries is today's full log, with every filter and the export.
- The role survives a reload, and a role switch never leaves the screen on a page that role can't see.
- Checked in both roles in Mark's running app, and `/verify` is green.

### 34. The look: theme tokens, light/dark, the app frame (medium, client only) — after 33
**Status:** Done (PR #38)
**Why:** every redesigned screen builds on the same tokens and frame. Done once and first, the screen tasks only apply them.
**Decided:** §2. The colour tokens for light and dark (the mock's palette as the starting point), the fonts (the mock uses Rubik for text and IBM Plex Mono for codes; both cover Hebrew and Latin where needed), spacing and radius; the theme toggle (system first, then remembered); the header (brand, lounge badge, View as, language switch placeholder, theme toggle), the admin tabs and the ☰ menu below ~900 px. Screens keep their current layout inside the new frame.
**Decided in the task's plan (Mark, 2026-10-24):**
- **Tailwind + shadcn conventions, so later agents grow the app with them.** One token set in `client/src/index.css`, with shadcn's names (`--background`, `--foreground`, `--card`, `--primary`, `--secondary`, `--muted`, `--muted-foreground`, `--accent`, `--destructive`, `--border`, `--input`, `--ring`, each colour with its `-foreground` pair) and new tokens added the shadcn way (`--success`, `--warning`, `--exceptional`, `--header`…, under `:root` and `.dark`, exposed through `@theme inline`). `styles.css` keeps no variables of its own: its clashing names (`--muted` as a text colour, `--accent` as the blue, `--bg`, `--panel`, `--text`, `--ok`, `--no`…) are renamed to the shadcn tokens, and every raw colour in it becomes a token. Fonts are `--font-sans` / `--font-mono`, radius is shadcn's `--radius` scale, spacing is Tailwind's `--spacing` base.
- **Dark mode the shadcn way:** a `light` or `dark` class on `<html>` (the `.dark` custom variant shadcn uses), and `color-scheme` to match. The choice is `system` | `light` | `dark`, `system` by default.
- **The theme choice is in the store** (the view slice, next to the role) **and in `localStorage`** (`jetlog.theme`, through a pure guarded helper in `lib/`, like the role), so a reload keeps it. A hook applies it to the page and follows the system while the choice is `system`; `main.tsx` applies it before the first render (no inline script).
- **Brand:** no logo; a text-only "JetLog" and the mock's neutral blue (`#1f5fbf`, `#4d8ef0` in dark). **The header follows the theme:** white in light, navy in dark (Mark, after the first review).
- **The lounge badge** keeps the station lounge picker's behaviour exactly (a native select, disabled mid-scan, the first-run panel) and takes the mock's pill look. Unset, it stays amber: a "do this first" warning in the header, not an entry's status.
- **Language:** a disabled `עב | EN` placeholder in the header, EN on, until task 35.
- **Status colours:** ⚡ Exceptional stays **purple** (it was approved, so it gets its own colour, not a warning colour). ⚠ Invalid barcode turns **neutral grey** (the row's red ✕ Denied carries the status). Amber is the warning colour (the unset lounge, form warnings, the import preview's inactive rules), never an entry's status. It is the softer amber of the dark look in both themes, used as a fill with dark text, never as text on the page.
- **The rules list's description** takes only the room the other columns leave, cut with "…", with the full text (and the comments) in a tooltip, so Edit and Duplicate stay on screen (Mark, after the first review).
- **The ☰ menu below 900 px** is an inline list under the header, not a Radix dropdown (no typeahead competing with the scanner, no focus trap). It shows the current page, and closes on a pick, on Escape and on a click outside it.
- **Fonts bundled with the client** (`@fontsource-variable/rubik`, `@fontsource/ibm-plex-mono`, both SIL OFL 1.1): no Google Fonts link, no internet needed on the on-prem machines.
- **Spacing:** the new frame uses the spacing tokens now; each screen moves onto them in its own restyle task (36–41).
**Done when:** both themes render every existing screen readably, the toggle works and is remembered, and the tabs fold into the menu on a narrow window.

### 35. Hebrew and RTL foundation (large, client only) — after 34; absorbs task 17
**Status:** Done (PR #39)
**Why:** the operators work in Hebrew. Laying the foundation before the screens are restyled means each screen is built RTL-ready once, not mirrored later.
**Decided:** §2, plus task 17's plan: `i18next` + `react-i18next`, JSON catalogs for `he` and `en`, the language in the store and localStorage, `<html dir lang>` driven by the language, logical CSS properties (or Tailwind's `rtl:` variant), and codes kept LTR (`dir="ltr"` / `unicode-bidi: isolate`). Every user-visible string moves to the catalogs. Hebrew strings from Mark or IsraJet; drafts are marked as drafts.
**Decided in the task's plan (Mark, 2026-10-24):**
- **Hebrew only for what the operator sees:** the header, Scanning, every scan modal, the log, entry details and the change panels, and the deny reasons. The admin-only pages (All entries' filter panel and help, Rules and the import, Global rules, Clubs, Lounges, Approvers) still move every string to the catalogs, but into `en.json` only; i18next falls back to English for them. Their Hebrew is task 43.
- **The key test:** `he.json` and `en.json` have exactly the same keys, except the admin keys listed in `i18n/he.pending.json`, which may lack Hebrew. A new string not on that list must have Hebrew.
- **Who writes the Hebrew:** each stop ships English plus draft Hebrew (the mock's draft where it fits, the agent's draft for the rest). Mark or IsraJet review it all in one pass before deployment (18), from a key / English / Hebrew sheet the client generates.
- **Drafts:** every Hebrew string is a draft until its key is listed in `i18n/he.reviewed.json` (empty at first). `npm run i18n:drafts` counts the drafts and writes the review sheet. No marker inside the strings: it would show on screen.
- **Hebrew is the default** on a computer that has never chosen (the test deployment too); the switch to English is remembered on that computer (`jetlog.language`).
- **Nothing mirrors (Mark, after the first look):** the layout stays exactly as in English in both languages: the header, the tabs, the tables' column order, the forms, the windows and their footers (main action on the right). `<html>` is always `dir="ltr"`; only `lang` follows the language. Only the words change, and each Hebrew text reads right to left in its own place (an element that holds only text takes its direction from its first letter). The boarding-pass fields stay left to right. This replaces §2's "in Hebrew the footer mirrors" and this task's "`<html dir lang>` driven by the language".
- **Three stops, one branch and one PR:** (A) the plumbing (i18next, the language in the store and on `<html lang>`, the working switch, the per-text direction, codes kept LTR, the scanner fix below) and the header's strings; (B) the desk: Scanning, the scan modals, the log, entry details and the change panels, the `lib/` texts; (C) the admin pages, English only.
- **`lib/` stays pure:** it returns message keys with their values, never text, and components translate them. The store's error fields hold either one of the client's message keys or the server's own text.
- **The scanner and a Hebrew keyboard layout:** a USB scanner types through the computer's layout, so with Hebrew on, `/` arrives as `.` and a lowercase letter as a Hebrew one. The scan fields read the physical key (`KeyboardEvent.code`) and type what a US layout gives (a pure function in `lib/`, test-first). Pasting is unaffected. Mark checks it with the real scanner on a desk computer with the Hebrew layout on.
- **Server error messages stay English** (plain sentences, no codes); error codes from the server go to the backlog.
- **Dates** use one format in both languages, `dd/MM/yyyy HH:mm` (24-hour), shown LTR, instead of each computer's locale.
- **The CSV exports and the rules import stay English:** their columns are what Excel, billing and the import expect.
- **Text people typed** (descriptions, approver names, notes) reads in its own direction, Hebrew or English, through the same per-text rule as the catalogs' strings; codes always LTR.
**Done when:** every operator screen reads correctly in Hebrew, each Hebrew text right to left in a layout that stays as in English, with codes still LTR; the admin pages keep their English text; and English still works.

### 36. The desk: scan-first page, operator log, scan modals (medium, client only) — after 35
**Status:** Done (PR #40)
**Decided:** §2 and the mock. The scan-first page with ⚡ Manual approval and the latest-scans strip; the log on its own tab, grouped by day, with its toolbar staying on screen; the club question with large club tiles; the result, failed-scan and guest-loop modals; the exception form. Behaviour unchanged (task 32).
**Decided in the task's plan (Mark, 2026-10-25):**
- **Two stops, one branch and one PR:** (A) the page and the log; (B) the scan windows (club question, result, failed scan, guest loop, exception form). Entry details and the change panels stay task 37.
- **The Scanning page has two tabs, Scanning | Entries.** The Entries tab is labelled "Entries" for now; task 38 adds the number of days.
- **The log is grouped by scan day**, newest day first, and the sort orders the rows inside each day. A day's header reads "Today · Sun 25/10/2026", "Yesterday · …", or the weekday and the date (one date format; the weekday names in the catalogs).
- **The Recent strip has its own small request:** the station's lounge, no other filters, the 6 latest hosts, refreshed after every scan or change (the existing `GET /api/entries`; one store field, with its tests). The log's filters never narrow it.
- **The guest loop lists every guest of the session**, kept in the scan slice (with its tests), not only the last one.
- **The operator's lounge control is two buttons, as in the mock: "Lounge <station> | All lounges".** Any other lounge choice (one or several, picked on All entries) becomes the station's lounge when Scanning opens. All entries keeps its select (task 39).
- **The entries table moves to shadcn's `Table`**, added with the shadcn CLI, with Tailwind classes on the tokens; the toolbar stays on screen while scrolling. All entries uses the same table; its own admin tools wait for task 39. The other new building blocks (tabs, badge, input) come from the CLI too.
- **A club with no image** shows a circle with the first two letters of its code.
- **The header stays as task 34 left it.**
**Done when:** the whole operator flow matches the mock in both languages and both themes, on a 1366 px laptop and a large monitor, with every task-32 behaviour intact.

### 37. Entry details and the change panels (small–medium, client only) — after 47
**Status:** Next
**Decided:** §2 and the mock. The details window and its change panels (move, rescan, approve as exception, void, add guests, change quantity), one shared panel shape. Behaviour unchanged.
**Done when:** every change works as before, restyled, in both languages and themes.

### 38. The days-of-entries global rule and the operator's log window (small–medium, one migration) — after 37
**Status:** Next
**Why:** operators see only recent entries (BACKLOG.md, 2026-10-21; Mark, 2026-10-23).
**Decided:**
- A new **global rule** for how many past days of entries the operator's log shows: default **5**, editable **1–365** days on the Global rules page.
- Like every global rule (DECISIONS.md, 2026-10-13), its row is inserted by a migration, and a missing or invalid row **fails closed**: an error, never a value quietly taken from the code.
- **Its name** (key, screen label, name in the code) is Mark's to pick before the migration is written. One suggestion: `max_days_of_entries_at_desk`, **Days of entries shown at the desk**.
- The Scanning page's log applies the window; All entries does not. Task 15 now comes first, so the window is enforced by the server for the operator's role, not only on the screen.
- **This task adds the number of days to the Scanning page's Entries tab label** (task 36 leaves it "Entries"), e.g. "Entries · 5 days", the number read from the rule's row in `global_rules`, never from the code (Mark, 2026-10-25).
**Touch:** server first (schema, migration with its row, the global-rule validation, tests), then the client (the Global rules page, the log's window, the guide), plus DEPLOY.md (the migration and row counts).
**Done when:** the operator's log shows exactly the last N days of the rule's value, the admin can change N, and a missing row stops the log with a clear error.

### 39. Admin: All entries (medium, client only) — after 38
**Status:** Next
**Decided:** §2 and the mock. The full log with a date column, the lounge select, the result switch, search, the filter panel, Whole parties / Single entries, Clear, and ⤓ Export CSV as the main action. The toolbar stays on screen. Paging as today.
**Done when:** every filter and the export work as before, restyled.

### 40. Admin: Rules (medium, client only) — after 39
**Status:** Next
**Decided:** §2 and the mock. The rules list with search, the lounge and active switches, selection with the bulk bar, import and export, and the rule form, which shows the key the rule will have.
**Done when:** every rules action works as before, restyled.

### 41. Admin: Clubs, Lounges, Approvers, Global rules (medium, client only) — after 40
**Status:** Next
**Decided:** §2 and the mock. Clubs as cards with their images; Lounges and Approvers as today's lists; Global rules grouped as today (with 38's rule in its own group).
**Done when:** every admin page works as before, restyled. This completes the redesign.

### 43. Hebrew for the admin pages (small–medium, client only) — after 41
**Status:** Next
**Why:** task 35 gives the operator's screens Hebrew and moves the admin pages' strings into `en.json` only, since 39–41 restyle those pages and may change their wording. Once they are restyled, they get their Hebrew.
**Decided:** §2 and task 35's decisions. Fill in the Hebrew of every key in `i18n/he.pending.json` (drafts, marked as task 35 marks them), then delete that list, so the key test becomes strict parity between `he.json` and `en.json`.
**Done when:** every admin page reads correctly in Hebrew, `he.pending.json` is gone, and the key test checks strict parity.

### 44. The database server: use IsraJet's PostgreSQL 16 as it is (small, deployment) — after 36
**Status:** Done (PR #1, PR #3)
**Why:** Mark (2026-10-25). The database runs on its own server (the DB VM) and the app on the other. The database comes first, before authentication and the rest of the work; the full app deployment stays task 18.
**Since 2026-11-02 the DB VM runs PostgreSQL 18.6** (Mark upgraded it; DECISIONS.md, 2026-11-01 and 2026-11-02). The rest of this task is kept as it was.
**Found on the DB VM (2026-10-26):** IsraJet's own native PostgreSQL **16.15** (Ubuntu, pgdg; cluster `16/main`) listens on `127.0.0.1`, `192.168.1.1` and `[::1]` port 5432, with TLS on. It has a login `appuser` (not a superuser, no Create DB) that owns an **empty** database `appdb` (no tables), and the superuser `postgres`. Docker is not installed there. The DB VM is reached through the app VM: SSH to `192.168.0.1`, then `ssh root@192.168.1.1` or `psql -h 192.168.1.1` from there; SSH from the laptop straight to `192.168.1.1` is refused.
**Decided:**
- **We don't touch IsraJet's database server** (Mark, 2026-10-26): no Docker, no upgrade, no new roles or passwords, no TLS, firewall or `pg_hba.conf` changes. Their DBA owns it (Mark doesn't talk to the DBA; his client does).
- **JetLog uses `appdb` as `appuser`** with the password IsraJet gave. `appuser` can't create a database, and doesn't need to: it owns `appdb`, so the migrations can create the tables there.
- **PostgreSQL 16 is fine for now**; upgrading to 17 is the DBA's call. JetLog's SQL uses nothing that needs 17.
- **No `jetlog-db` repository for now** (Mark, 2026-10-26): the Postgres-17 compose planned there isn't needed while IsraJet's server is used. Nothing moves out of `jetlog`; `deploy/db/` stays, unused.
- **The app VM runs `docker-compose.yml` with its `pg` service and volume commented out** (Mark, 2026-10-26; no separate prod compose): `DATABASE_URL` from `.env.prod`, migrate on start, the one-time seed and `db:lock` by hand with `docker compose run --rm api …`. The code reaches the app VM by `git archive` over SSH. A plain connection (no TLS): IsraJet's server accepts it. Docs kept short.
- **The new jetlog replaces the old demo on the app VM, and the old one is removed** (Mark, 2026-10-26): its containers, images, volume and folder, once the new app runs.
- Separate owner and runtime roles, password rotation, TLS certificates and the firewall are the DBA's and IT's, or a later task.
- Mark runs every command on the servers himself (CLAUDE.md, production rules).
**Done when:** the app VM runs this jetlog from `docker-compose.yml`, connected to `appdb`; `db:migrate` and the one-time seed have run there (DEPLOY.md, rewritten for IsraJet's server); the old demo stack and its traces are gone from the app VM.

### 15. Login and roles: register, log in, the role decides the pages (medium) — after 44
**Status:** Done (PR #5)
**Why:** everything is public. Production needs users and roles. Mark (2026-10-27): **start basic.** A register page and a login page; everyone who registers is an operator; Mark makes one of them admin in the database by hand. The admin sees the admin pages, the operator the operator's. The rest of the old task 15 (who did each entry, the station token) moves to tasks 46 and 47; managing users from the screen stays task 16.
**Decided (Mark, 2026-10-27):**
- **Local users** in a `users` table (`id`, `username` unique, `password_hash`, `role`, `active`, `created_at`). No SSO: the machines are on-prem.
- **Usernames, not emails** (no mail on-prem): trimmed and lower-cased, 3–50 characters of `a-z 0-9 . _ -`. **Passwords** 8–72 characters (bcrypt reads at most 72 bytes; a longer one is refused, never cut short).
- **Two roles, `operator` and `admin`**, one vocabulary in `domain/auth.ts`, the same names as the client's `lib/role.ts`; the database checks the column holds one of them, so a typo in a hand-written `UPDATE` fails instead of locking someone out. No third role for now.
- **Register is open and always creates an operator**; it logs the new user in. **An admin is made by hand in the database** (`UPDATE users SET role = 'admin' WHERE username = '…'`), until task 16 gives the admin a Users page. Open registration means anyone who can reach the app can make an operator account; task 16 closes it.
- **Passwords hashed with bcrypt** (`bcryptjs`, pure JavaScript: no native build in the Docker image), cost 12. A login with an unknown username costs the same time as a wrong password, and both get the same message.
- **Sessions in the database** (`sessions`: `user_id`, the SHA-256 of a random token, `expires_at`), the token in an **httpOnly, `SameSite=Lax` cookie**. Logout deletes the row; the user and role are read on every request, so a role changed in the database applies on the next request and a deactivated user is out at once. No secret to add to `.env.prod`. ~~A session lasts 12 hours from login (a desk shift).~~ **A session ends after a day without use** (Mark, 2026-10-31): every use renews it (at most once an hour), so a desk in use is never logged out in the middle of a scan; the cookie lasts a year and the database decides. No `Secure` flag while the app is served over plain HTTP inside the VPN; it comes with TLS (IT's).
- **API:** `POST /api/auth/register`, `POST /api/auth/login`, `POST /api/auth/logout`, `GET /api/auth/me`. **Every other `/api/*` route except `/api/health` needs a session (401).**
- **The server checks the role now (Mark, 2026-10-27):** an operator gets **403** on what only the admin's pages use: every `/api/rules` route, the writes of lounges, clubs (and the club image), approvers and global rules, and `GET /api/entries/export`. The operator keeps everything the desk uses: scanning, exceptions, re-entry, the log, an entry's details and changes, and the reads of lounges, clubs, approvers and global rules.
- **The client:** a login page and a register page before anything else; the role comes from `GET /api/auth/me` and **replaces the View as switch**, keeping today's layout per role; the header shows the user and a Log out button; a 401 from any call goes back to the login page. The station's lounge picker stays as it is (task 47).
**Touch:** server: `db/schema.ts` (`users`, `sessions`), one migration (Mark runs `db:generate` / `db:migrate`), `domain/auth.ts` (test-first), `services/authService.ts`, `middleware/auth.ts` (`requireAuth`, `requireRole`), `routes/auth.ts` + `controllers/auth.ts`, the admin-only routes, integration tests (every suite logs in). Client: login and register pages, the role from `/me`, 401 handling, store changes through `store-test-writer`, the guide through `user-guide-writer`. Docs: ARCHITECTURE, CLAUDE.md, DEPLOY.md (the migration, making the first admin), a `/decision`.
**Done when:** an unauthenticated request to any `/api/*` except `/health` and the auth routes is a 401; anyone can register and log in as an operator; a user Mark makes admin sees the admin pages; an operator can't reach an admin page and gets 403 from the admin endpoints.

### 48. A maximum session length, with a warning before the logout (small–medium, one migration) — after 46
**Status:** Done (PR #13)
**Why:** Mark (2026-10-31). Task 15 ends a session only after a day without use, so a working desk is never logged out, but a session in daily use never ends either, and its cookie lasts a year. A fixed maximum (a forced re-login every few days) limits how long a copied cookie works. It must never break a scan, so the desk is warned ahead and re-logs in at a moment it chooses.
**Decided (Mark, 2026-10-31):**
- **Two limits:** the day-without-use limit stays as it is, and every session also ends a fixed time after login, used or not (`sessions.max_expires_at`, set at login and never renewed). The cookie lasts as long as that maximum, not a year.
- **A warning before the fixed end:** `GET /api/auth/me` (and login) returns when the session ends; the client keeps a timer and, shortly before, opens a pop-up ("You'll be logged out at 14:00") with **Log in again now**, which asks for the password in the pop-up itself and keeps the screen and any scan in progress.
**Decided (Mark, 2026-11-23):**
- **The maximum is 12 hours (one shift)**, a constant in the code next to the day-without-use limit, not an admin setting, until IsraJet asks.
- **The warning opens 30 minutes before the end, and again at 5.** Its **Log in again now** asks only for the password and lets only the same user continue; someone else logs out and in the normal way, so nobody takes over another person's screen.
- **If the warning is ignored,** the logout happens at the end time, and the login page keeps the station's lounge.
- **Sessions open at the deploy** get the maximum counted from their login (the migration fills `max_expires_at` from `created_at`), so a session older than 12 hours ends at once.
- **Built straight through** while Mark is away: the server, then the client, in one PR, reviewed later. Mark allowed the agent to run this task's migration on the local database.
**Done when:** a session ends at its maximum even while in use, the desk is warned before it, and re-logging in from the warning loses nothing on screen.

### 46. Who did it: the user on every entry and change (small–medium, one migration) — after 55
**Status:** Done (PR #12)
**Why:** carried from the old task 15: once people log in, each entry should say who logged it.
**With the audit log (55):** the audit log already records who changed each entry. Planning settles what each one holds: the log is the record of events for IT, and this task puts the user on the entry itself, for the screen and the export.
**Decided (from the post-POC plan):** `entries.created_by_user_id` (→ `users.id`, who scanned), set by the server from the session on every scan, guest, exception and re-entry; the user on an exceptional approval is who logged it, distinct from `approver_name` (who authorised it). Shown in the entry details and the export.
**Decided (Mark, 2026-11-23):**
- **Who modified it too:** `entries.modified_by_user_id` (→ `users.id`), set with `modified_at` by every change in place (move, rescan, exception, void, quantity, and the guests a change touches): the last person who changed it. The full history is the audit log (55).
- **Ids stored, names read:** both columns hold the user's id and the username is read on every read, so a rename shows on old entries. Users are never deleted, so the id always resolves.
- **The export** gets `created_by_user_id`, `created_by`, `modified_by_user_id` and `modified_by`, like the lounge and club columns.
- **On screen, only who created it**, in the entry details window (both roles). Who modified it is in the export only. No column in the entries table and no filter by user.
- **Entries from before logins** have neither: empty in the export, a dash in the window.
- **Built straight through** while Mark is away: the server, then the client, as two commits in one PR, reviewed later. The agent runs the migration on the local database.
**Done when:** every new entry records who created it and every change in place who made it; the details window shows the creator and the export shows both.

### 47. Stations: the admin sets each computer's lounge (medium) — after the pen test
**Status:** Next
**After the pen test (Mark, 2026-11-17):** it closes a gap of our own, which IT's security assessment doesn't list.
**Why:** the lounge a scan is logged in comes from the browser today (`loungeId` in every request), so any computer can claim any lounge. The server should trust a station, not the browser.
**Decided (Mark, 2026-10-23, 2026-10-27):** an admin opens a station-setup window on the computer and picks its lounge; the server issues a **station token** stored on that computer (`localStorage`), checked on every scan and exception; the server takes the lounge from the token, not from the request, and the operator's lounge badge becomes read-only.
**Still open:** a `stations` table (name, lounge, token hash, active, last seen) so the admin can list and revoke them, or a signed token with no table; whether an operator can log in on a computer that has no station yet (recommended: yes, scanning refused until an admin sets it up).
**Done when:** a station's lounge comes from its token; a computer without one can't log scans; an admin can revoke a station.

### 16. What is left of the admin panel: users (medium) — after 15
**Status:** Done (PR #7)
**Why:** the redesign builds the admin pages (39–41), so what remains of the old admin-panel task is managing users and their roles. Task 15 makes the first admin by hand in the database; this task makes that unnecessary.
**Decided:** a Users page (list, create, edit role, deactivate, reset a password) behind the admin role. **Open registration closes** (Mark, 2026-10-27: it is open only in task 15's basic start): an admin creates the accounts, or approves the registered ones (to settle when planned). `react-router` was the old plan's idea for the admin area; the tabs work without it, so adding it needs a reason and a `/decision`.
**Decided (Mark, 2026-11-07):**
- **The admin creates every account**, choosing its role (admin or operator), and can change any other user's role, deactivate and reactivate them, and reset their password. **Registration closes:** the Create an account page and `POST /api/auth/register` go.
- **The first admin comes from a server script** Mark runs once on the app VM: `npm run user:create-admin -- --username <name>`, which asks for the password twice without showing it (never on the command line, so it stays out of the shell history). It creates a new active admin and refuses a username that exists, so it never changes an account; after a lost admin password, it makes another admin, who resets the first one on the Users page. Not "the first account registered becomes admin": whoever reached the page first would get admin.
- **Everyone changes their own password** (both roles), giving the current one first; a wrong current password is a 400 (not a 401, which would log the desk out). It ends the user's other sessions and keeps the one in use.
- **An admin never changes their own account from the Users page:** not their role, not deactivated, not a password reset (they use Change password, which asks for the current one). So the admin doing the work stays an active admin, and there is always at least one.
- **A reset password or a deactivation logs that user out at once** (their sessions are deleted). A role change keeps the sessions: the role is read on every request.
- **No forced change after a reset** (backlog): the admin sets a password and tells the user, who may change it. **An admin renames another user** (Mark, 2026-11-16, moved in from the backlog; first "usernames are not editable"): `username` in `PATCH /api/users/:id`, with the rules of a new username and a 409 when another user has it, active or not. Never their own, like every other change on the Users page; nobody renames themselves. The renamed user stays logged in (a session points at the id) and logs in with the new name from then on. **Users are never deleted**, only deactivated (task 46 will link entries to users). A username that exists, active or not, can't be created again (409); a deactivated one is reactivated instead.
- **API:** `POST /api/auth/password` (logged in) · `GET /api/users` · `POST /api/users` · `PATCH /api/users/:id` (`role`, `active`) · `POST /api/users/:id/password` — the `/api/users` routes admin only (403). No migration: `users` already has every column.
**Done when:** an admin manages users without touching SQL, and operators never see the page.

### 18. Production deployment to the on-prem machines: the app server (large) — after 48
**Status:** Next
**No image registry for now (Mark, 2026-11-23; a private `ghcr.io` registry was decided on 2026-11-17):** the app VM keeps building the images from the code, as today, and a rollback rebuilds the previous release. The registry is in the backlog (why: DECISIONS.md, 2026-11-23).
**Decided (carried over):** one compose file per VM. The DB VM is task 44 (its own repository, its roles and secure access); this task is the app VM, connecting with the runtime role task 44 creates. This task adds the app VM's `deploy/app/docker-compose.app.yml` (`api` + `web`, no `pg`, `DATABASE_URL` to `192.168.1.1:5432` from an env file not in git, pinned image tags, `restart: unless-stopped`, log rotation, nginx serving the client and proxying `/api`), retires the demo compose and its seed-on-start on APP.Layam, adds a GitHub Actions job over the VPN (Mark, 2026-10-25: the remaining screens, 37 on, are shipped through it, so it is tested many times before go-live) that runs `db:migrate` before switching traffic and can roll back to the previous tag, and a smoke check after deploy. A test deployment already runs; DEPLOY.md should record it. Backups are the DBA's (DEPLOY.md §Backups).
**Done when:** a fresh app VM goes from zero to serving with one command, and a rollback is one command.

### 42. The full user guide for the redesign (medium, docs) — after 41 (and 15, if the guide should cover login)
**Status:** Next
**Why:** the guide is kept current by every task, but the redesign changes every screen. This task brings it together: the screenshots from the shot list on the new screens, the Hebrew version of the guide, and possibly the planned in-app help page.
**Still open:** whether the in-app help page is part of this task or its own; who translates the guide into Hebrew.
**Done when:** the guide and its screenshots match the redesigned app, in English and Hebrew.

### 49. Close the API's own port (8000) (small, deployment) — first of the security tasks
**Status:** Done (PR #8)
**Why:** `docker-compose.yml` publishes the API on port 8000 of the app server, beside nginx on 3000. nginx reaches the API over Docker's internal network, so the published port only adds a second way in, past nginx. A host firewall rule would not close it: Docker writes its own iptables rules for published ports, which bypass `ufw`.
**Decided (Mark, 2026-11-03):** remove the API's `ports` from `docker-compose.yml`; nginx stays the only entry point. The security-review doc says it "will be closed".
**Touch:** `docker-compose.yml`; `docs/DEPLOY.md` (every health check already goes through `:3000/api/health`; check nothing calls `:8000`); the review doc's diagram, ports table and known-limits row once done. A redeploy on the app server (Mark).
**Done when:** `curl http://192.168.0.1:8000/api/health` from the VPN fails, and the app on `:3000` works.

### 50. Fix the npm audit findings (small) — before the pen test
**Status:** Done (PR #6)
**Why:** on 2026-11-03, `npm audit --omit=dev` reported 4 in `server/` (critical `proxy-addr`, high `body-parser` and `multer`, moderate `qs`; all through Express and multer) and 2 high in `client/` build tools (`vite`, `source-map-js`). IT's first audit should come back clean. Mark started on it (2026-11-03).
**Decided:** `npm audit fix` in both projects (no `--force`: no major-version jumps without a look); the full gate after; anything left is listed with why.
**Touch:** `server/package-lock.json`, `client/package-lock.json` (and `package.json` only if a range must move). Optional in the same task: the export's `drain`/`close` waits leave a listener behind on each wait (`controllers/entries.ts`; the `MaxListenersExceededWarning` in the 500,000-row test).
**Done when:** `npm audit --omit=dev` reports 0 in both projects (or each remaining finding is explained), and `/verify` passes.

### 51. Containers as non-root; no version headers (small) — before the pen test
**Status:** Superseded (by 53 and 54; Mark, 2026-11-17): the version headers go to 53, the non-root user to 54.
**Why:** two findings a pen test reports, both listed as known in the security-review doc: the API container runs as root (`server/Dockerfile` has no `USER`), and the responses name their software (Express's `X-Powered-By`, nginx's version in `Server`).
**Decided (Mark, 2026-11-03):** one task for both. The API image runs as the image's `node` user; Express's `x-powered-by` is turned off; nginx gets `server_tokens off`.
**Touch:** `server/Dockerfile`, `server/src/app.ts`, `client/nginx.conf`; a test that the header is gone; DEPLOY.md if a rebuild step changes.
**Done when:** `docker compose exec api whoami` is not root, and no response carries `X-Powered-By` or an nginx version.

### 52. Login protection: limit failed logins (small–medium, server then client) — after 49
**Status:** Done (PR #8)
**Why:** IT's security assessment, a High item. Nothing limits failed logins today, so anyone on the VPN can try passwords against any username, the admin's included, for as long as they like.
**Decided (Mark, 2026-11-17):**
- **After 49:** the limit per address trusts the client address nginx passes on (Express's `trust proxy`, one hop), which is only safe once the API's own port is closed; while it is open, anyone can call the API directly with a made-up address.
- **Failed logins are limited, and the lock is temporary**, never permanent: a permanent lock would let anyone lock an operator out at the desk by typing their username wrongly.
- **The answer stays the same for an unknown username and a wrong password** (task 15), and the lock doesn't reveal whether a username exists.
- **A clear message on the login page** when a lock applies, saying when to try again.
**Decided (Mark, 2026-11-18):**
- **The limits, constants in the code** (never global rules: security limits aren't edited from a page): 5 failures of one username within 15 minutes lock it for 15 minutes, the same length every time; 30 failures from one address within 15 minutes refuse that address until its window ends. The failure that reaches a limit already answers the lock.
- **A lock answers 429 with `Retry-After`** (seconds), one message for both limits, refused before the password is checked, so a lock never confirms a right password. The login page says how many minutes to wait.
- **The username counts live in a `login_failures` table keyed by the username text** (not columns on `users`), so an unknown username is counted and locked exactly like a real one, by one mechanism. A username that breaks the username rules can't be an account and counts only toward its address. A successful login and an admin's password reset delete the row; every attempt deletes the rows that no longer matter, so the table holds only the last 15–30 minutes (at most about addresses × 30 × 2 rows, since only the VPN reaches the login).
- **The address counts live in memory** (one API container; a restart only resets a 15-minute window), cleaned on every failure, with a hard cap of 10,000 addresses: when full, a new address is refused rather than the map growing. A test proves the map empties once the window passes.
- **The Users page doesn't show locks** (not now).
**Touch:** server: the pure rules in `domain/auth.ts` (test-first), `services/authService.ts`, the login controller, `app.ts` (`trust proxy`), maybe `db/schema.ts` and a migration (Mark runs it), integration tests. Client: the login page's message (the store through `store-test-writer`), both languages. Docs: USER_GUIDE (`user-guide-writer`), ARCHITECTURE, DEPLOY.md if a migration, a `/decision`.
**Done when:** repeated wrong passwords lock that username for a while and slow down an address; the lock ends on its own (or with a password reset); the right password works again after it; the message is clear in both languages.

### 53. Security headers on nginx; no CORS; no version headers; an Origin check (small) — after 52
**Status:** Done (PR #9)
**Why:** IT's security assessment: HTTP security headers (High) and restricting CORS (Medium), plus the version headers from 51 (Express's `X-Powered-By`, nginx's version in `Server`).
**Decided (Mark, 2026-11-17):**
- **CORS is removed from the API, not restricted:** `app.use(cors())` in `server/src/app.ts` today allows any origin. The browser always calls the API from the page's own address, through nginx in production and through Vite's proxy in development, so the API never needs a cross-origin request. Monitoring that calls `/api/health` and a log collector that reads Docker's logs aren't browsers, so CORS never applies to them. If a browser page on another address ever needs the API, that one origin is allowed then. This doesn't wait for IT's host name.
- **The headers go on nginx:** a Content Security Policy, `X-Content-Type-Options: nosniff`, `Referrer-Policy`, and framing refused (`frame-ancestors` in the CSP, plus `X-Frame-Options`). HSTS waits for TLS (57).
- **No version anywhere:** `server_tokens off` in nginx, Express's `x-powered-by` off.
- **An Origin check on nginx (Mark, 2026-11-18):** a `POST`, `PATCH`, `PUT` or `DELETE` to `/api/` whose `Origin` names another address than the request's own `Host` gets a 403. A request without `Origin` (`curl`, monitoring) passes and still needs a session. It defends the desk's browser against another site (CSRF), beside `SameSite=Lax` and no CORS; it can't keep out a non-browser client, which writes any `Origin` it likes: the VPN, login, roles and 52 do that. Comparing with `Host` means nothing changes when the address does (IT's host name, 57).
**Decided (Mark, 2026-11-18):**
- **The CSP:** `default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self'; font-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'`. Scripts only from JetLog's own files; inline styles allowed, because the dialogs' scroll lock and the toasts add `<style>` elements while the app runs, and a nonce would need nginx to rewrite the page on every request. A style runs no code. Checked on every screen, in both languages and themes.
- **Also `Permissions-Policy: camera=(), microphone=(), geolocation=()`** (camera scanning was removed); no cross-origin isolation headers. **`Referrer-Policy: same-origin`.**
- **The Origin check's 403 is the API's JSON envelope** (`{"success":false,"error":"Forbidden"}`), not nginx's HTML page.
- **One stop** for the server and nginx together (the server part is a few lines).
**Touch:** `client/nginx.conf`, `server/src/app.ts`, `server/package.json` (drop `cors`), a test that no response carries `X-Powered-By` or `Access-Control-Allow-Origin`, the Origin check tried through nginx (a foreign `Origin`, the app's own, none); ARCHITECTURE if it names CORS; DEPLOY.md if a check changes. A redeploy (Mark).
**Done when:** every response through nginx carries the headers and names no software version, the API sends no CORS header, a write to `/api/` with a foreign `Origin` gets a 403 while the app's own pages and a request without `Origin` work, and every screen works with the CSP on.

### 54. Hardened containers: non-root, production-only images, read-only, health checks (medium, deployment) — after 53
**Status:** Done (PR #10)
**Why:** IT's security assessment: hardening the containers (High; the part inside the containers, while the app server itself is IT's), production-only images (Medium), and the health checks IT's monitoring will watch. It takes over 51's non-root user.
**Decided (Mark, 2026-11-17):**
- **Multi-stage builds:** the API's final image holds only the compiled code and the production packages, with no dev dependencies, tests or `tsx`. The web image already works this way.
- **The API runs as the image's `node` user**, not root.
- **In the compose file:** a read-only filesystem where possible (with small writable temporary folders where a process needs one), every Linux capability dropped unless one is needed, `no-new-privileges`, and a Docker health check for each service.
- **No registry here:** the images are still built on the app VM (the registry is 18's).
**The hard part:** the migrations run at container start through `tsx` (a dev tool), and so do the scripts DEPLOY.md runs by hand (the one-time seed, `db:lock`, `user:create-admin`). Without `tsx` they must run from the compiled code.
**Decided (Mark, 2026-11-21):**
- **The scripts run from the compiled code.** They already compile with the server (they are under `src/`); the build copies in the SQL migrations and `rules.json`. The image has no npm (it can't write its logs on a read-only filesystem, and its scripts call `tsx`), so DEPLOY.md and the README run `node dist/…`; development keeps `npm run …`.
- **nginx: the unprivileged image**, listening on 8080 inside the container (still 3000 outside), with no capability at all.
- **Docker's log size limit here:** 10 MB × 5 files per container.
- **IsraJet collects the logs with Sophos MDR**, an agent IT installs on the app VM, outside the containers. Nothing here stands in its way: it reads Docker's log files on the VM, and if IT prefers syslog or journald, that is one line in the compose file.
- **One stop** (no screen changes).
**Touch:** `server/Dockerfile`, `client/Dockerfile`, `client/nginx.conf` (if the port changes), `docker-compose.yml`, the server's build and scripts, DEPLOY.md (every command checked against the new images). A redeploy (Mark).
**Done when:** `docker compose exec api whoami` is not root; the API image has no dev dependencies; the containers run read-only with no extra privileges; both report healthy; the migrations still run on start; and every DEPLOY.md command works with the new images.

### 55. The security audit log (medium) — after 54
**Status:** Done (PR #11)
**Why:** IT's security assessment: security audit logging (High), and recording each CSV export (part of export governance, Medium).
**Decided (Mark, 2026-11-17):**
- **Structured log lines (JSON) on the API's output**, which Docker keeps and IT can collect into their own log system. Each line holds the time, the event, the user, the client address and the outcome.
- **The events:** login success and failure (and a lock, from 52), logout, every change on the Users page (create, rename, role, deactivate, reactivate, password reset) and a user's own password change, each CSV export (its filters and row count), and the entry changes (move, rescan, exception, void, quantity).
- **Never in the log:** passwords, session tokens, or the raw barcode (personal data).
**Decided (Mark, 2026-11-22):**
- **The admin's changes to rules, lounges, clubs, approvers and global rules are logged too**, the same way: they decide who gets in.
- **No database table and no screen for now:** the lines go to IsraJet's log system; a screen if IsraJet asks.
- **Log rotation is 54's** (10 MB × 5 per container). IsraJet collects the logs with Sophos MDR on the app VM (Mark, 2026-11-21); how its agent reads them (Docker's files or syslog) is IT's answer.
- **Server only, one stop** (nothing on screen changes).
**Touch:** server: one small logging module used by the services, integration tests that each event writes its line and nothing secret; DEPLOY.md (where the logs are and how IT collects them); ARCHITECTURE.
**Done when:** every listed event writes one line saying who did what, when and from where; nothing secret or personal is logged; tests prove each event.

### 56. Security scans in the pipeline, and the release report (medium, CI) — after 58, before 18 (moved ahead of 18: Mark, 2026-11-23)
**Status:** Done (PR #16)
**Why:** IT's security assessment: the dependency review and the container vulnerability assessment (both High). The response to IT proposed a report with every release, instead of one check by hand.
**Decided (Mark, 2026-11-17):**
- **In GitHub Actions, on every release:** `npm audit --omit=dev` for the server and the client; a Trivy scan of the two images, built by the pipeline from the release's commit (no registry: Mark, 2026-11-23); an SBOM (the list of components and versions) for each image; the test results.
- **The report is kept with each release**, as the workflow's artifact, ready to hand to IT.
- **A High or Critical finding stops the release** unless IT accepts it formally.
**Decided (Mark, 2026-11-23, from his reference workflow; details may change later):**
- **The fast gates run on every PR, like the tests:** Semgrep (named rule sets, not `--config auto`; only `ERROR` fails), `npm audit --omit=dev --audit-level=high` for the server and the client (the dev packages reported, not failing), gitleaks (secrets in the code and its history), zizmor (unsafe patterns in the workflows).
- **The release is a push to `main`:** the tests and the same gates again on that exact commit, then both images built, Trivy on each (High and Critical fail, unfixed ignored), an SBOM of each (CycloneDX, from Trivy), and a ZAP baseline scan of the running stack (report-only at first). The release is tagged `vYYYY.MM.DD` (Israel's date; `.2`, `.3` for more that day) by the release job, only when everything passed; the deploy (18) will start only from a tagged commit.
- **The report, kept as the run's artifact for 400 days** (the most a private repo allows), also on a failed release (marked FAILED, untagged), so the reason is there: a summary (on the run's page and as a file) with the verdict, the tag, commit and date, each check with pass or fail and its findings per severity, every failing finding (what, where, severity, the fixed version), the findings IT accepted, the ZAP alerts, and the release notes (the commits since the previous tag); then each scanner's own output and the SBOMs, for IT.
- **A weekly scheduled scan** of the current images (and on demand), so a new CVE is seen before a release meets it.
- **A finding IT accepts** goes into `.trivyignore.yaml` with its reason and an end date.
- **Pinned supply chain:** every action and the scanners' images by full commit SHA or digest (the March 2026 attack rewrote trivy-action's tags); the base images in both Dockerfiles by digest, so the scanned image is the one the app VM builds from that commit; Dependabot (alerts, security updates, and version updates for npm, Docker and the actions, waiting a few days after each release of a package) keeps the pins current. Workflows get a read-only token by default; only the release job writes (its tag).
- **The scan jobs install nothing** (`npm audit` reads the lockfile; the scanners run from pinned images), so no package's install script runs there (the 2025 npm worms spread through them).
- **Not taken from the reference:** the registry push and the GitOps update (no registry, no Argo), and the conventional-commit version bump (our messages are sentences).
- **Enforcing the gate on GitHub:** GitHub Pro on Mark's account, so the PR checks can be required (Mark sets it up); the release gate holds either way.
**Decided (Mark, 2026-11-23, after the first ZAP run):**
- **The cross-origin isolation headers are added** on nginx (`Cross-Origin-Opener-Policy: same-origin`, `Cross-Origin-Embedder-Policy: require-corp`, `Cross-Origin-Resource-Policy: same-origin`), which 53 had left out; ZAP flagged them, and JetLog loads nothing from another address, so they cost nothing.
- **ZAP's app waits for its database through compose** (the API `depends_on` the database being healthy, in a small file of the ZAP job's own), not through the order of the start commands.
**Still open:** IT's answer: is this report enough, or will they run their own tools as well, and which severity blocks a release.
**Touch:** `.github/workflows/` (the PR gates, the release, the schedule), `.github/dependabot.yml`, `.trivyignore.yaml`, the Dockerfiles (digests), the Semgrep config, DEPLOY.md (where the report is and how to read it), README (the checks).
**Done when:** every PR runs the fast gates; every push to `main` produces the report or fails on a High or Critical finding; the weekly scan runs; every action and image is pinned.

### 57. TLS: HTTPS, the `Secure` cookie, HSTS (small, deployment) — when IT delivers the certificate
**Status:** Next (waiting for IT's host name and certificate)
**Why:** IT's security assessment: HTTPS/TLS (High), and the `Secure` session cookie its assessment result names.
**Decided (Mark, 2026-11-17):** IT provides the host name in IsraJet's domain, its internal DNS record, and the certificate with its renewal (public, or from IsraJet's own CA trusted on every desk computer), and decides where TLS ends. Ours: HTTPS on JetLog's nginx (443, with 80 redirecting) if TLS ends there, the `Secure` flag on the session cookie, and HSTS.
**Still open:** IT's choices: the host name, the kind of certificate, and whether TLS ends on JetLog's nginx or on IT's own reverse proxy.
**Touch:** `client/nginx.conf`, `docker-compose.yml` (port 443, the certificate files mounted, not in git), the cookie options in `server/src/controllers/auth.ts`, DEPLOY.md (installing and renewing the certificate). A redeploy (Mark).
**Done when:** JetLog is served over HTTPS at its host name, plain HTTP redirects to it, the session cookie carries `Secure`, and HSTS is sent.

### 31. Length limits on every free-text column (small–medium, one migration) — after 48, before the pen test (moved ahead of 56: Mark, 2026-11-23)
**Status:** Done (PR #14)
**Before the pen test (Mark, 2026-11-17):** not in IT's assessment, but pen testers send oversized values.
**Why:** Mark (2026-10-21). Many `text` columns have no length limit, so one request can store an arbitrarily long string (up to Express's 100 KB body limit; 3 MB on the rules import), bloating the table, the export and the screen. Task 29 already caps a rule's description and comments at 2,000 characters.
**Decided (Mark, 2026-10-21):** free-text columns get a maximum length, enforced twice: by the code first (a 400 with a clear message, or an invalid import row), and by the database as the last guard (`varchar(n)`). The limits are defined once and used by both, like `EXCEPTION_MAX_CHARS` and `RULE_TEXT_MAX_CHARS`. It is about size, not injection: Drizzle already sends every value as a parameter.
**Decided (Mark, 2026-11-23):**
- **The scanned barcode:** at most 1,000 characters, on the scan, the club question, the rescan and the re-entry (a real pass is a few hundred at most). A longer one is refused with a 400 and nothing is logged. The desk checks it before sending, so the operator reads the message in their language.
- **A rule's carrier, class, frequent flyer and company field:** at most 10 characters each, in the editor and the CSV import (an invalid row), far above any real code.
- **The limits the code already has are kept** (club code 50, lounge code 10, club and lounge descriptions 500, approver name and company 100, username 50) instead of the draft numbers; the global-rule value gets 1,000. Each limit is defined once, in one module, shared by the check and the column.
- **The database guard:** `varchar(n)` on those columns, plus `entries.approver_name` and `voided_by` (the approver name's 100) and `login_failures.username` (the username's 50). The columns the server fills itself (hashes, rule keys, the fields parsed from the barcode, `locked_by`) stay `text`: the barcode cap bounds them.
- **Counted in characters, as Postgres counts a varchar,** so the check and the column always agree, Hebrew included.
- **No length limit on the scan box itself,** so a scan is never cut short silently; the other fields get the matching `maxLength`.
- **Production:** DEPLOY.md gets a check query per column, run before migrating; a too-long value stops the migration with nothing changed.
- **Migration:** the agent runs `db:generate` and `db:migrate` on the dev database for this task (Mark, 2026-11-23), reporting the row counts.
**Touch:** server (`db/schema.ts`, the limits module, the clubs, lounges, approvers, global-rules, rules and scan validation, integration tests). Client: `maxLength` on the matching fields, the scan length check. Docs: ARCHITECTURE, DEPLOY, CLAUDE.md, USER_GUIDE.
**Done when:** no chosen column accepts more than its limit, in the code or in the database, and an over-long value is refused with a clear message, writing nothing.

### 58. Rate limits on nginx, against a flood (small, nginx only) — after 31, before the pen test
**Status:** Done (PR #15)
**Why:** Mark (2026-11-23). Pen testers send floods of requests from one address; nothing limited the rate except the API's failed-login count. nginx is the only way in and refuses cheaply, before the Node server or the database does any work.
**Decided (Mark, 2026-11-23):**
- **At nginx, per address and for everyone together**, plus a tighter count on the login on top of the API's failed-login limit (which stays: only the API knows usernames).
- **Generous: only an attack meets them.** The desks and the admins send a few requests a second at their busiest, even if they all reach nginx from one address. 50 a second per address with a burst of 200; 200 a second for everyone with a burst of 400; the login 2 a second per address with a burst of 20; 100 open connections per address. A slow sender is cut off after 10 seconds of silence.
- **A refusal is a 429 in the API's JSON envelope**, logged as a warning in nginx's error log (on Docker's output, so IT's collector reads it). No `Retry-After`: adding a header there would drop the security headers, and the wait is a second.
- **The client is not changed:** it shows the server's words, "Too many requests", which normal work never sees.
**Touch:** `client/nginx.conf`, DEPLOY.md (a check after a deploy), USER_GUIDE, ARCHITECTURE.
**Done when:** a flood from one address, from many, and on the login is refused with a 429 while normal use is never refused, checked in the running app.

### 59. Server errors never show their text; ids checked against the column (small, server only) — after 56, before the pen test
**Status:** In progress (`feature/task-59-server-errors`)
**Why:** A review before the pen test: an unexpected error answered 500 with its own text, in production too, and left no trace in the log. An id too large for the database's `integer` column (e.g. `/api/entries/99999999999`) made the database refuse the query, and Drizzle's error text carries the query and its values: the answer showed the SQL with every column of the table. Reproduced on the entries log, an entry, a club image and a lounge update (any logged-in user; the pen testers get accounts).
**Decided (Mark, 2026-11-23):**
- **An unexpected error answers only `Server Error`** (500); the errors the code raises on purpose (`ErrorResponse`, a bad barcode, a bad body or upload) keep their messages.
- **Every unexpected error writes one line on the API's output** (`"type":"error"`, beside the audit lines, so IsraJet's log collector sees it): when, the request (method, path), the user, the error's kind, and for a database error its code and the table, column or constraint, with where in the code it happened. **Never its message or the query's values**, which can hold a barcode or a search; the same rule as the audit log. Development also prints the full error, as before. The export's failure in the middle of a download writes the same line.
- **An id above the column's maximum (2,147,483,647) is refused with a 400**, defined once and used by every id the API reads: path ids, ids in a body, the entries filters, the log's cursor.
- **Tests:** the id check test-first (unit), the line's fields (unit, nothing secret), and integration: a huge id is a 400, an unexpected error is `Server Error` with its line written.
**Touch:** server only: a pure `domain/` module for ids and one for the error line, `middleware/errorHandler.ts`, the controllers' id parsers, `domain/entryFilters.ts`, `domain/entriesPaging.ts`, the export's catch; ARCHITECTURE (the error path); DEPLOY.md if it names the log lines.
**Done when:** no response carries an unexpected error's text, every unexpected error leaves one safe line in the log, and a huge id gets a 400 everywhere.

### 45. Re-entry after a flight delay: a pass that already entered (small, one migration) — Mark to place in the order
**Status:** Done (PR #4)
**Why:** Mark (2026-10-26). A flight can be delayed after the passenger has already been admitted and left the lounge; they then need to come back in, sometimes more than once. Today an approved pass is blocked on re-scan (`ALREADY_ENTERED`), with no way to let it back in. This adds a **re-entry**: a special exceptional approval for a pass that has already entered, usable as many times as needed. Keep it small — don't over-build it.

**The rule it must not break:** dedup is "one APPROVED entry per pass" — `uniq_key` behind the partial unique index `entries_one_approved_per_uniq_key` (`where approved = true and uniq_key is not null`). A re-entry must not collide with the original approved entry, nor with earlier re-entries, nor let a plain second scan sneak an entry in.

**Decided (Mark, 2026-10-26):**
- **A re-entry is an exceptional approval that keeps the pass's real `uniq_key`.** It is logged as: `approved = true`, `is_exceptional = true`, `is_reentry = true`, the real `uniq_key` (not null), quantity 1, no guests. Keeping the key ties every re-entry to the original admission, so "every admission of this pass" is one query by `uniq_key` — no separate pointer (`reentry_of_entry_id`) needed.
- **The dedup index is narrowed by one predicate so re-entries don't collide.** `entries_one_approved_per_uniq_key` becomes `where approved = true and uniq_key is not null and is_reentry = false`. The original approved entry stays the one deduped admission; re-entries (and earlier re-entries) fall outside the index, so any number coexist, while a plain second scan — `is_reentry = false` — is still blocked exactly as today. `approvedEntryWithKey` is ordered to prefer the original (non-re-entry) row.
- **One new flag, `entries.is_reentry` (boolean, NOT NULL default false).** It marks the row as a second/third admission, keeps it out of the dedup index, drives its badge in the log, and lets the export and reports tell re-entries apart from ordinary manual approvals.
- **Triggered from the scan result when the pass is already entered.** The operator re-scans the pass; the result shows `ALREADY_ENTERED`; a **Re-enter (flight delay)** action opens the exception form (approver required, notes optional), carrying the raw barcode so the row records the same flight and passenger. The server guards it: the pass must parse and an approved entry with its `uniq_key` must already exist, else 400 — a re-entry is only ever for a pass that already entered.
- **Unlimited.** Each re-entry is a fresh row; nothing caps how many times an approved pass re-enters.

**Still open (recommendation to confirm):**
- **Ordering.** Independent of login (15) and the redesign (37–43): it needs only today's scan and exception code. Recommended: schedulable any time, like task 31; listed here as "Next" for Mark to slot.

**Touch:**
- **Server first:** `db/schema.ts` (`is_reentry`, and the narrowed `entries_one_approved_per_uniq_key` predicate), a migration adding the column and recreating the index (Mark runs `db:generate` / `db:migrate`; the index change drops and recreates it — check row counts before/after), a re-entry path in `exceptionApprovalService.ts` (keeps the real `uniq_key`, sets `is_reentry`) + its controller/route and the already-entered guard, the `approvedEntryWithKey` ordering, integration tests.
- **Client:** the Re-enter action on the already-entered scan result, and its badge in the log.
- **Docs:** USER_GUIDE (`user-guide-writer`), ARCHITECTURE (the data-model note: dedup is one approved *non-re-entry* per pass; re-entries are exceptional and keep the pass's `uniq_key`), DEPLOY.md (the migration + row counts), and a `/decision` (this extends "one approved entry per pass" to allow approver-authorised re-entries, excluded from dedup by `is_reentry`).

**Done when:** an already-entered pass can be approved for re-entry by an approver, as many times as needed; each re-entry is logged, badged, distinguishable from a manual approval, and tied to the original by `uniq_key`; and a plain second scan (not a re-entry) is still blocked by the dedup index.

---

*Written 2026-10-23, when the post-POC plan was archived. When something here stops matching the code, fix this file: it is the contract the next agent trusts.*
