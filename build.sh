#!/usr/bin/env bash
# exit on error
set -e
set -x

yarn install --frozen-lockfile

if [[ $RAILS_ENV == "production" ]]; then
  bin/bundle config set --local without "development test"
  bin/bundle config set --local deployment true
  bin/bundle install -j4

  echo "Precompiling Assets..."
  bin/rails assets:precompile

  # echo "Uploading Assets to S3..."
  # bin/rails assets:s3_sync

  echo "Cleaning Assets..."
  bin/rails assets:clean

  bash ./release-tasks.sh
else
  bin/bundle install
fi

if [ -f tmp/pids/server.pid ]; then
  rm -f tmp/pids/server.pid
fi
