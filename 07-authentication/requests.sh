#!/usr/bin/env bash
# Register two users, then show that each has their own isolated graph —
# but a global directory can still see everyone (grant + allroots).
#
# Start the server first, in another terminal:
#   jac start main.jac --port 8000
# Then run this:
#   bash requests.sh
#
# Override the base URL with:  BASE=localhost:3000 bash requests.sh
set -euo pipefail
BASE="${BASE:-localhost:8000}"

# --- Auth helpers ---------------------------------------------------------
# register <user> <pass>
register() {
    curl -s -X POST "$BASE/user/register" -H 'Content-Type: application/json' \
        -d "{\"identities\":[{\"type\":\"username\",\"value\":\"$1\"}],\"credential\":{\"type\":\"password\",\"password\":\"$2\"}}" \
        >/dev/null
}
# login <user> <pass>  ->  prints the JWT token
login() {
    curl -s -X POST "$BASE/user/login" -H 'Content-Type: application/json' \
        -d "{\"identity\":{\"type\":\"username\",\"value\":\"$1\"},\"credential\":{\"type\":\"password\",\"password\":\"$2\"}}" \
        | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])"
}

# --- Readable summary of a walker response --------------------------------
FILTER='
import sys, json
d = json.load(sys.stdin)
def show(x, pad="  "):
    if isinstance(x, list):
        for i in x: show(i, pad)
    elif isinstance(x, dict):
        if "content" in x and "author_username" in x:
            print(pad + x["author_username"] + ": " + x["content"])
        elif "username" in x:
            line = pad + "@" + x["username"]
            if x.get("bio"): line += " - " + x["bio"]
            print(line)
            show(x.get("tweets") or [], pad + "  ")
if not d.get("ok"):
    print("  error:", (d.get("error") or {}).get("message"))
else:
    r = d.get("data", {}).get("reports")
    print("  (nothing)" if r in (None, [], [[]]) else "", end="")
    show(r or [])
'

# call <walker> <token> [json-body]  ->  prints a readable summary
call() {
    echo "> POST /walker/$1  (as authenticated user)"
    curl -s -X POST "$BASE/walker/$1" \
        -H "Authorization: Bearer $2" -H 'Content-Type: application/json' \
        -d "${3:-{\}}" | python3 -c "$FILTER"
    echo
}

echo "=== Register + log in two users ==="
register alice pw123; ALICE=$(login alice pw123)
register bob   pw123; BOB=$(login bob pw123)
echo "  alice and bob are registered and logged in."
echo

echo "=== alice sets up her profile and posts two tweets ==="
call setup_profile "$ALICE" '{"username":"alice","bio":"building LittleX"}'
call create_tweet  "$ALICE" '{"content":"Hello from alice"}'
call create_tweet  "$ALICE" '{"content":"alice again #jac"}'

echo "=== bob sets up his profile and posts one tweet ==="
call setup_profile "$BOB" '{"username":"bob","bio":"just bob"}'
call create_tweet  "$BOB" '{"content":"bob was here"}'

echo "=== ISOLATION: each feed shows only that user's own tweets ==="
echo "alice's feed:"; call load_feed "$ALICE"
echo "bob's feed:";   call load_feed "$BOB"

echo "=== GLOBAL DIRECTORY: get_all_profiles sees across every user's root ==="
echo "as alice:"; call get_all_profiles "$ALICE"
echo "as bob:";   call get_all_profiles "$BOB"
