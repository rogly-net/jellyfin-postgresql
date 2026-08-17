# Jellyfin PostgreSQL Plugin - Docker Distribution

A pre-built Docker image with Jellyfin and the PostgreSQL plugin integrated, providing PostgreSQL database support as an alternative to the default SQLite backend.

> **⚠️ EXPERIMENTAL:** This plugin is highly experimental and should be used with caution in production environments. Always maintain backups of your data.

## Quick Start

### Using Docker Compose (Recommended)

1. Create a `docker-compose.yml` file:

```yaml
services:
  jellyfin:
    image: ghcr.io/rogly-net/jellyfin-postgresql:latest
    depends_on:
      postgres:
        condition: service_healthy
        restart: true
    environment:
      JELLYFIN_CACHE_DIR: /cache
      POSTGRES_HOST: postgres
      POSTGRES_PORT: 5432
      POSTGRES_DB: jellyfin
      POSTGRES_USER: jellyfin
      POSTGRES_PASSWORD: your_secure_password_here
    ports:
      - "8096:8096"
    volumes:
      - ./jellyfin-config:/config
      - ./jellyfin-cache:/cache
      - /path/to/your/media:/media:ro
    restart: unless-stopped

  postgres:
    image: postgres:17
    environment:
      PGDATA: /var/lib/postgresql/17/docker
      POSTGRES_DB: jellyfin
      POSTGRES_USER: jellyfin
      POSTGRES_PASSWORD: your_secure_password_here
      # Optional: separate WAL directory for better performance
      # POSTGRES_INITDB_WALDIR: /var/lib/postgresql-wal/17/docker
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U jellyfin -d jellyfin"]
      interval: 10s
      timeout: 10s
      retries: 5
      start_period: 30s
    volumes:
      - ./postgres-data:/var/lib/postgresql
      # Optional: separate volume for WAL
      # - ./postgres-wal:/var/lib/postgresql-wal
    restart: unless-stopped
```

2. Update the paths and credentials in the compose file

3. Start the services:

```bash
docker compose up -d
```

4. Access Jellyfin at `http://localhost:8096`

### Using Docker Run

```bash
# Start PostgreSQL
docker run -d \
  --name jellyfin-postgres \
  -e POSTGRES_DB=jellyfin \
  -e POSTGRES_USER=jellyfin \
  -e POSTGRES_PASSWORD=your_secure_password \
  -v ./postgres-data:/var/lib/postgresql/data \
  postgres:17

# Start Jellyfin with PostgreSQL plugin
docker run -d \
  --name jellyfin \
  --link jellyfin-postgres:postgres \
  -e POSTGRES_HOST=postgres \
  -e POSTGRES_PORT=5432 \
  -e POSTGRES_DB=jellyfin \
  -e POSTGRES_USER=jellyfin \
  -e POSTGRES_PASSWORD=your_secure_password \
  -p 8096:8096 \
  -v ./jellyfin-config:/config \
  -v ./jellyfin-cache:/cache \
  -v /path/to/media:/media:ro \
  ghcr.io/rogly-net/jellyfin-postgresql:latest
```

## Configuration

### Environment Variables

The following environment variables configure the PostgreSQL connection:

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `POSTGRES_HOST` | PostgreSQL server hostname | - | Yes |
| `POSTGRES_PORT` | PostgreSQL server port | `5432` | No |
| `POSTGRES_DB` | Database name | `jellyfin` | Yes |
| `POSTGRES_USER` | Database user | `jellyfin` | Yes |
| `POSTGRES_PASSWORD` | Database password | - | Yes |
| `POSTGRES_COMMAND_TIMEOUT` | Npgsql command timeout in seconds (`0` = no limit) | `30` | No |

## Jellyfin Version

The image is pinned to a specific Jellyfin release (currently **10.11.11**) rather than
`jellyfin/jellyfin:latest`. The plugin carries its own set of EF Core migrations for the
PostgreSQL schema, so it only matches the Jellyfin version it was built against — running a
newer server against an older plugin leaves the database missing columns the server expects.

## Troubleshooting

### `column u.NormalizedUsername does not exist`

Jellyfin 10.11.10 added a `NormalizedUsername` column to the `Users` table. Images built
before that change shipped a plugin without the matching migration, so the column was never
created. Pull the current image and restart — the plugin's migrations add the column, backfill
it, and create the unique index on startup.

If you already worked around it by adding the column by hand, drop it first, otherwise the
migration fails with `column "NormalizedUsername" of relation "Users" already exists`:

```sql
ALTER TABLE public."Users" DROP COLUMN "NormalizedUsername";
```

Then start the new image and let the migrations run. Take a backup before doing this.

## Known Limitations

- This is an **experimental** plugin and may have stability issues
- Direct migration from SQLite to PostgreSQL is not automated
- Some Jellyfin features may not work as expected with PostgreSQL
- Plugin updates may require database migrations

## Credits

- **Original Plugin**: [JPVenson/Jellyfin.Pgsql](https://github.com/JPVenson/Jellyfin.Pgsql)
- **Jellyfin**: [Jellyfin Project](https://jellyfin.org/)
- **PostgreSQL**: [PostgreSQL Global Development Group](https://www.postgresql.org/)