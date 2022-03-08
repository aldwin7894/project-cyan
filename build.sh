#!/usr/bin/env bash
# exit on error
set -e

yarn install --silent --frozen-lockfile

if [[ $RAILS_ENV == "production" ]]; then
  BUNDLE_WITHOUT='development:test' BUNDLE_DEPLOYMENT=1 bin/bundle install -j4 --quiet
  bin/rails assets:precompile
  bin/rails assets:clean
  bash -v ./release-tasks.sh
else
  bin/bundle install --quiet
fi

if [ -f tmp/pids/server.pid ]; then
  rm -f tmp/pids/server.pid
fi
