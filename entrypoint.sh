#!/bin/sh
set -e

echo "Waiting for database to be ready..."
# Wait until Postgres is ready
until pg_isready -h "$DB_HOST" -U "$DB_USER"; do
  sleep 1
done

echo "Database ready, creating database if it doesn't exist..."
# Create the DB if needed
bin/comet eval "Comet.Release.migrate"

echo "Starting the app..."
exec bin/comet start
