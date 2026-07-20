#!/usr/bin/env bash
# Send a request to every endpoint in main.jac.
#
# Start the server first, in another terminal:
#   jac start main.jac --port 8000
# Then run this:
#   bash requests.sh
#
# Override the base URL with:  BASE=localhost:3000 bash requests.sh
set -euo pipefail
BASE="${BASE:-localhost:8000}"

# POST helper: path + optional JSON body (defaults to {}), pretty-print.
post() {
    local path="$1" body="${2:-{\}}"
    echo "> POST /$path  $body"
    curl -s -X POST "$BASE/$path" -H 'Content-Type: application/json' -d "$body" | python3 -m json.tool
    echo
}

echo "=== setup_profile: create/update the profile under root ==="
post "walker/setup_profile" '{"username":"alice","bio":"building LittleX"}'

echo "=== create_tweet: navigate to the profile, attach a tweet ==="
post "walker/create_tweet" '{"content":"Hello, LittleX!"}'
post "walker/create_tweet" '{"content":"learning walkers #jac"}'

echo "=== load_feed: gather the profile's tweets, newest first ==="
post "walker/load_feed"

echo "=== load_feed with a search query ==="
post "walker/load_feed" '{"search_query":"jac"}'

echo "=== get_profile: the full profile view, with its tweets ==="
post "walker/get_profile"

echo "=== get_all_profiles: every profile as a UserView ==="
post "walker/get_all_profiles"

# Spawn a walker on a specific node: setup_profile's response includes the
# profile's `id`; put it in the path to run profile_feed on that node.
PROFILE_ID=$(curl -s -X POST "$BASE/walker/get_all_profiles" -H 'Content-Type: application/json' -d '{}' \
    | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['reports'][0][0]['id'])")
echo "=== profile_feed spawned on the profile node ($PROFILE_ID) ==="
post "walker/profile_feed/$PROFILE_ID"
