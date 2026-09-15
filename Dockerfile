# Jellyfin with plugin - expects pre-built plugin in publish/
# Pinned: the plugin ships the EF migrations for the Jellyfin schema it targets
# (Jellyfin.Controller 10.11.11). Floating on :latest lets the server move to a
# schema the plugin has no migrations for, which surfaces as missing columns at
# runtime (e.g. "column u.NormalizedUsername does not exist").
FROM jellyfin/jellyfin:latest

# Install PostgreSQL 17 client tools for backup/restore functionality
RUN apt-get update && \
    apt-get install -y wget ca-certificates gnupg lsb-release && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y postgresql-client-17 xmlstarlet && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the published plugin and config files (built on runner)
COPY publish/ /jellyfin-pgsql/plugin/
COPY Jellyfin.Pgsql/docker/entrypoint.sh /entrypoint.sh
COPY Jellyfin.Pgsql/docker/database.xml /jellyfin-pgsql/database.xml

# Make entrypoint executable
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
