#!/usr/bin/env bash
# exit on error
set -e
set -x

yarn install --frozen-lockfile
bin/bundle install -j4

echo "Precompiling Assets..."
bin/rails assets:precompile

echo "Cleaning Assets..."
bin/rails assets:clean

if [ "$RUN_DB_MIGRATIONS_DURING_RELEASE" == "true" ]; then
  echo "Running Database Migrations..."
  bin/rails db:migrate VERBOSE=true
fi

if [ "$SEED_DB_DURING_RELEASE" == "true" ]; then
  echo "Seeding Database..."
  bin/rails db:seed
fi

if [ -f tmp/pids/server.pid ]; then
  rm -f tmp/pids/server.pid
fi
