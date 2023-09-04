#!/usr/bin/env bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
if [[ -f tmp/pids/server.pid ]]; then
	rm -f tmp/pids/server.pid
fi

echo "Start seeding db..."
bin/rails db:seed_game_ids
bin/rails db:seed_spotify_artist_whitelists

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
