#!/usr/bin/env bash
# exit on error
set -o errexit

yarn install --frozen-lockfile
BUNDLE_WITHOUT='development:test' BUNDLE_DEPLOYMENT=1 bundle install -j4
bundle exec rake assets:precompile
bundle exec rake assets:clean
./release-tasks.sh
