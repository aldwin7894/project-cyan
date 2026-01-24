#!/usr/bin/env bash
# exit on error
set -e
set -x

TZ=$(cat /run/secrets/TZ)
RAILS_ENV=$(cat /run/secrets/RAILS_ENV)
NODE_ENV=$(cat /run/secrets/NODE_ENV)
RAILS_MASTER_KEY=$(cat /run/secrets/RAILS_MASTER_KEY)
RAILS_ASSET_HOST=$(cat /run/secrets/RAILS_ASSET_HOST)
BUNDLER_VERSION=$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1 | xargs)
export TZ
export RAILS_ENV
export NODE_ENV
export RAILS_MASTER_KEY
export RAILS_ASSET_HOST
export BUNDLER_VERSION

gem install bundler

if [[ ${RAILS_ENV} == "production" ]]; then
	bin/bundle config set without "development test"
	bin/bundle config set frozen "true"
fi

yarn install --immutable
bin/bundle install -j4

echo "Precompiling Assets..."
bin/rails assets:precompile

echo "Cleaning Assets..."
bin/rails assets:clean

if [[ -f tmp/pids/server.pid ]]; then
	rm -f tmp/pids/server.pid
fi
