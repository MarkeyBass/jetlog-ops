# JetLog local DB connection (Docker Compose)

This project uses Docker Postgres from:

- `jetlog/docker-compose.dev.yml`
- service: `pg`
- container: `jetlog-pg`
- host port mapping: `5432:5432`
- db credentials: `jetlog / jetlog`
- database: `jetlog`

## 1) Start the DB container

From project root:

```bash
cd jetlog
docker compose -f docker-compose.dev.yml up -d pg
docker ps --filter name=jetlog-pg
```

Optional health check:

```bash
docker inspect -f '{{.State.Health.Status}}' jetlog-pg
```

## 2) Connect with psql (recommended commands)

Use an explicit URL (works even if `DATABASE_URL` is not exported in shell):

```bash
psql "postgres://jetlog:jetlog@localhost:5432/jetlog"
```

Or run inside container:

```bash
docker exec -it jetlog-pg psql -U jetlog -d jetlog
```

Quick validation:

```bash
psql "postgres://jetlog:jetlog@localhost:5432/jetlog" -c "select count(*) from entries; select count(*) from rules;"
```

Check the new column:

```bash
psql "postgres://jetlog:jetlog@localhost:5432/jetlog" -c "select column_name from information_schema.columns where table_name='entries' and column_name='frequent_flyer_number';"
```

## 3) Why `psql "$DATABASE_URL"` may fail

`server/.env` is read by Node apps (dotenv), not automatically by your shell.
If `DATABASE_URL` is empty in terminal, this command:

```bash
psql "$DATABASE_URL"
```

becomes just `psql`, which tries local socket defaults like `/tmp/.s.PGSQL.5432`.

If you want to use shell env var style:

```bash
cd jetlog/server
export DATABASE_URL="postgres://jetlog:jetlog@localhost:5432/jetlog"
psql "$DATABASE_URL"
```

## 4) If connection still fails

- Ensure container is up: `docker ps --filter name=jetlog-pg`
- Ensure port is listening: `lsof -nP -iTCP:5432 -sTCP:LISTEN`
- If local Postgres is conflicting on 5432, stop it (see `dev-docs/postgresql-17-autostart.md`) or remap compose port.
