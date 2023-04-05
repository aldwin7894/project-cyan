#!/usr/bin/env bash
# exit on error
set -e
set -x

TZ=$(cat /run/secrets/TZ)
RAILS_ENV=$(cat /run/secrets/RAILS_ENV)
NODE_ENV=$(cat /run/secrets/NODE_ENV)
OCCSON_ACCESS_TOKEN=$(cat /run/secrets/OCCSON_ACCESS_TOKEN)
OCCSON_PASSPHRASE=$(cat /run/secrets/OCCSON_PASSPHRASE)
RAILS_MASTER_KEY=$(cat /run/secrets/RAILS_MASTER_KEY)
RAILS_ASSET_HOST=$(cat /run/secrets/RAILS_ASSET_HOST)
export TZ
export RAILS_ENV
export NODE_ENV
export OCCSON_ACCESS_TOKEN
export OCCSON_PASSPHRASE
export RAILS_MASTER_KEY
export RAILS_ASSET_HOST

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
