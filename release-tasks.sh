#!/bin/bash
# This file is created by executing 'touch release-tasks.sh && chmod 0777 release-tasks.sh'.

echo "Running Release Tasks..."

if [ "$RUN_DB_MIGRATIONS_DURING_RELEASE" == "true" ]; then 
  echo "Running Database Migrations..."
  bundle exec rails db:migrate VERBOSE=true
fi

if [ "$SEED_DB_DURING_RELEASE" == "true" ]; then 
  echo "Seeding Database..."
  bundle exec rails db:seed
fi

if [ "$PRECOMPILE_ASSETS_DURING_RELEASE" == "true" ]; then 
  echo "Precompiling Assets..."
  bundle exec rails assets:precompile --trace
  
  echo "Cleaning Assets..."
  bundle exec rails assets:clean --trace
fi

echo "Done running release-tasks.sh"
