#!/usr/bin/env bash
# exit on error
set -e

yarn install --silent --frozen-lockfile

if [[ $RAILS_ENV == "production" ]]; then
  BUNDLE_WITHOUT='development:test' BUNDLE_DEPLOYMENT=1 bin/bundle install -j4 --quiet

  echo "Precompiling Assets..."
  bin/rails assets:precompile --trace

  echo "Cleaning Assets..."
  bin/rails assets:clean --trace

  bash -v ./release-tasks.sh
else
  bin/bundle install --quiet
fi

if [ -f tmp/pids/server.pid ]; then
  rm -f tmp/pids/server.pid
fi
