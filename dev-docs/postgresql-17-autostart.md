# EDB PostgreSQL 17 — start, stop, and reboot autostart

This Mac has **EDB PostgreSQL 17** installed at `/Library/PostgreSQL/17`.

It starts at boot because of this LaunchDaemon:

`/Library/LaunchDaemons/postgresql-17.plist`

(`RunAtLoad` is `true`.)

pgAdmin 4 (`/Library/PostgreSQL/17/pgAdmin 4.app`) is only the GUI. Quitting it does not stop the database.

Docker Postgres containers (for example `jetlog-pg`) are separate from this install.

---

## Stop Postgres now

```bash
sudo -u postgres /Library/PostgreSQL/17/bin/pg_ctl -D /Library/PostgreSQL/17/data stop
```

---

## Prevent Postgres from starting at reboot

```bash
sudo launchctl bootout system /Library/LaunchDaemons/postgresql-17.plist
sudo launchctl disable system/postgresql-17
```

If `bootout` says it isn’t loaded, use:

```bash
sudo launchctl unload -w /Library/LaunchDaemons/postgresql-17.plist
```

The `disable` / `-w` step is what stops it from coming back after a restart.

---

## Allow Postgres to start on reboot

```bash
sudo launchctl enable system/postgresql-17
sudo launchctl bootstrap system /Library/LaunchDaemons/postgresql-17.plist
```

That loads the service now **and** leaves it enabled so it starts again after reboot.

Older equivalent:

```bash
sudo launchctl load -w /Library/LaunchDaemons/postgresql-17.plist
```

---

## Start Postgres now (without changing reboot behavior)

```bash
sudo -u postgres /Library/PostgreSQL/17/bin/pg_ctl -D /Library/PostgreSQL/17/data start
```
