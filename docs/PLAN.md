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
| 5 | **44** The database server: use IsraJet's PostgreSQL 16 as it is | In progress |
| 6 | **15** Authentication, roles and stations | Next |
| 7 | **16** What is left of the admin panel: users | Next |
| 8 | **18** Production deployment (the app server) | Next |
| 9 | **37** Entry details and the change panels | Next |
| 10 | **38** The days-of-entries global rule and the operator's log window | Next |
| 11 | **39** Admin: All entries | Next |
| 12 | **40** Admin: Rules | Next |
| 13 | **41** Admin: Clubs, Lounges, Approvers, Global rules | Next |
| 14 | **43** Hebrew for the admin pages | Next |
| 15 | **42** The full user guide for the redesign | Next |
| any time | **31** Length limits on every free-text column | Next |

**Order (Mark, 2026-10-23):** the role split first, then the redesign in small tasks so each diff can be followed, then authentication, then deployment and the guide. **31 can run at any point**: it is a server safety task that depends on neither the redesign nor login. Task 17 (Hebrew and RTL) is superseded by 35 and by the redesign tasks that build every screen RTL-ready.

**Order changed (Mark, 2026-10-25), after task 36:** the database server first (44, split out of 18), then authentication (15) and users (16), then the app server (18), and only then the rest of the redesign (37–41, 43) and the guide (42). Login replaces the View as switch and keeps the layout, so the screens built after it are not affected, and the days window (38) can be enforced by the server from the start. With the app server deployed by GitHub Actions before the remaining screens, every one of them is shipped through the pipeline, so the deployment is exercised many times before go-live instead of by hand. Why: DECISIONS.md, 2026-10-25.

**How every task runs** (the full rules are in CLAUDE.md and the dev-style files): one task = one branch off `staging` = one PR. Plan first and wait for Mark's OK. Server first, then client, with a review stop after each. Store changes go through `store-test-writer`, user-visible changes through `user-guide-writer`, DEPLOY.md changes in the same commit and ARCHITECTURE.md in the paired ops commit (`/commit`) when the task touches them. Mark runs `db:generate` and `db:migrate` himself. `/verify` before handing over. Commit only after his go.

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
- **The station lounge picker stays as it is** until task 15. Later an admin sets each computer's lounge in a station-setup window, and the operator's badge becomes read-only.

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

### 37. Entry details and the change panels (small–medium, client only) — after 18
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
**Status:** In progress (`feature/task-44-israjet-postgres`)
**Why:** Mark (2026-10-25). The database runs on its own server (the DB VM) and the app on the other. The database comes first, before authentication and the rest of the work; the full app deployment stays task 18.
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

### 15. Authentication, roles and stations (large) — after 44
**Status:** Next
**Why:** everything is public. Production needs users, roles, and a lounge per computer that the server can trust.
**Decided:**
- Login replaces 33's **View as** switch and keeps the layout. The server enforces the roles: an operator can't export or open admin endpoints, and the days window (38) is applied by the server, not only the screen (BACKLOG.md, 2026-10-21).
- **The station model** (Mark, 2026-10-23): an admin sets each computer's lounge in a station-setup window. It is stored on that computer as a token the server checks, and the operator's lounge badge becomes read-only.
- From the post-POC plan: `users (id, username, password_hash, role, active)` with bcrypt or argon2; a login endpoint issuing an httpOnly-cookie session or a JWT; `requireAuth` / `requireRole` middleware; `user_id` recorded on entries (who scanned) and on exceptional approvals (who logged it, distinct from `approver_name`, who authorised it); a login screen and 401 handling in `api/client.ts`.
**Still open:** the identity source (a local users table vs IsraJet's SSO; on-prem suggests local first); whether a third role (the old plan's `manager`, for rules and approvers) is needed; how the station token is issued and revoked.
**Done when:** an unauthenticated request to any `/api/*` except `/health` and login is a 401; an operator can't reach an admin page or endpoint; every new entry records who created it; a station's lounge comes from its token.

### 16. What is left of the admin panel: users (medium) — after 15
**Status:** Next
**Why:** the redesign builds the admin pages (39–41), so what remains of the old admin-panel task is managing users and their roles.
**Decided:** a Users page (list, create, edit role, deactivate) behind the admin role. `react-router` was the old plan's idea for the admin area; the tabs work without it, so adding it needs a reason and a `/decision`.
**Done when:** an admin manages users without touching SQL, and operators never see the page.

### 18. Production deployment to the on-prem machines: the app server (large) — after 16
**Status:** Next
**Decided (carried over):** one compose file per VM. The DB VM is task 44 (its own repository, its roles and secure access); this task is the app VM, connecting with the runtime role task 44 creates. This task adds the app VM's `deploy/app/docker-compose.app.yml` (`api` + `web`, no `pg`, `DATABASE_URL` to `192.168.1.1:5432` from an env file not in git, pinned image tags, `restart: unless-stopped`, log rotation, nginx serving the client and proxying `/api`), retires the demo compose and its seed-on-start on APP.Layam, adds a GitHub Actions job over the VPN (Mark, 2026-10-25: the remaining screens, 37 on, are shipped through it, so it is tested many times before go-live) that runs `db:migrate` before switching traffic and can roll back to the previous tag, and a smoke check after deploy. A test deployment already runs; DEPLOY.md should record it. Backups are the DBA's (DEPLOY.md §Backups).
**Done when:** a fresh app VM goes from zero to serving with one command, and a rollback is one command.

### 42. The full user guide for the redesign (medium, docs) — after 41 (and 15, if the guide should cover login)
**Status:** Next
**Why:** the guide is kept current by every task, but the redesign changes every screen. This task brings it together: the screenshots from the shot list on the new screens, the Hebrew version of the guide, and possibly the planned in-app help page.
**Still open:** whether the in-app help page is part of this task or its own; who translates the guide into Hebrew.
**Done when:** the guide and its screenshots match the redesigned app, in English and Hebrew.

### 31. Length limits on every free-text column (small–medium, one migration) — any time
**Status:** Next
**Why:** Mark (2026-10-21). Many `text` columns have no length limit, so one request can store an arbitrarily long string (up to Express's 100 KB body limit; 3 MB on the rules import), bloating the table, the export and the screen. Task 29 already caps a rule's description and comments at 2,000 characters.
**Decided (Mark, 2026-10-21):** free-text columns get a maximum length, enforced twice: by the code first (a 400 with a clear message, or an invalid import row), and by the database as the last guard (`varchar(n)`). The limits are defined once and used by both, like `EXCEPTION_MAX_CHARS` and `RULE_TEXT_MAX_CHARS`. It is about size, not injection: Drizzle already sends every value as a parameter.
**Still open (recommendations to confirm with Mark):**
- **Which columns**, by risk: `entries.raw_barcode` (the only column filled from an untrusted source; cap around 1,000); the admin free text (`clubs.code`/`description`, `lounges.code`/`description`, `approvers.name`/`company`, `global_rules.value`) and their copies on `entries`; the columns the code derives (generously, or left out for a smaller migration).
- **An over-long scan:** refused with a 400 and nothing logged, rather than stored cut short.
- **The limits:** club and lounge code 50, descriptions 2,000, approver name and company 200, global-rule value 1,000.
**Touch:** server (`db/schema.ts`, the constants, validation in the clubs, lounges, approvers, global-rules and scan endpoints, integration tests); before migrating, a query per column confirms no existing value is longer than its limit. Client: `maxLength` on the matching fields. Docs: ARCHITECTURE, DEPLOY, CLAUDE.md, USER_GUIDE, a `/decision`.
**Done when:** no chosen column accepts more than its limit, in the code or in the database, and an over-long value is refused with a clear message, writing nothing.

---

*Written 2026-10-23, when the post-POC plan was archived. When something here stops matching the code, fix this file: it is the contract the next agent trusts.*
