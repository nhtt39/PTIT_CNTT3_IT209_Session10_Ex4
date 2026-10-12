#!/usr/bin/env bash
set -eu

# 1. Create custom bridge network
docker network inspect app-net >/dev/null 2>&1 ||
  docker network create app-net

# 2. Create named volume (never remove it in this script)
docker volume inspect db-data >/dev/null 2>&1 ||
  docker volume create db-data

# 3. Build backend image
docker build -t hw-db-backend:v1 .

# Remove old containers only; preserve db-data
docker rm -f app-container db-server 2>/dev/null || true

# Function to start PostgreSQL with the same volume
start_db() {
  docker run -d \
    --name db-server \
    --network app-net \
    -e POSTGRES_DB=appdb \
    -e POSTGRES_USER=appuser \
    -e POSTGRES_PASSWORD=app123 \
    -v db-data:/var/lib/postgresql/data \
    postgres:15-alpine
}

# 4. Start database
start_db

# Wait until PostgreSQL is ready
echo "Waiting for PostgreSQL..."
for i in $(seq 1 30); do
  if docker exec db-server pg_isready -U appuser -d appdb >/dev/null 2>&1; then
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "PostgreSQL did not become ready."
    docker logs db-server
    exit 1
  fi
  sleep 2
done

# 5. Start backend on the same network
docker run -d \
  --name app-container \
  --network app-net \
  -p 8081:3000 \
  -e PORT=3000 \
  -e DB_HOST=db-server \
  -e DB_PORT=5432 \
  -e DB_NAME=appdb \
  -e DB_USER=appuser \
  -e DB_PASSWORD=app123 \
  hw-db-backend:v1

# 6. Insert test data
docker exec db-server psql -U appuser -d appdb -c "
CREATE TABLE IF NOT EXISTS persistence_test (
  id INTEGER PRIMARY KEY,
  message TEXT NOT NULL
);
INSERT INTO persistence_test (id, message)
VALUES (1, 'Data survives container deletion')
ON CONFLICT (id) DO NOTHING;
"

echo "Data before deleting DB container:"
docker exec db-server psql -U appuser -d appdb \
  -c "SELECT * FROM persistence_test;"

# 7. Delete DB container, but keep the named volume
docker rm -f db-server

# 8. Recreate DB with the same network and volume
start_db

# Wait for the recreated database
echo "Waiting for recreated PostgreSQL..."
for i in $(seq 1 30); do
  if docker exec db-server pg_isready -U appuser -d appdb >/dev/null 2>&1; then
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "Recreated PostgreSQL did not become ready."
    docker logs db-server
    exit 1
  fi
  sleep 2
done

# 9. Verify persisted data
echo "Data after recreating DB container:"
docker exec db-server psql -U appuser -d appdb \
  -c "SELECT * FROM persistence_test;"

echo "All setup and persistence checks completed."
