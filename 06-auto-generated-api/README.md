# Episode 6 — Auto-Generated API

Companion code for the Auto-Generated API episode of the Jac tutorial series.

## What's in this directory

`main.jac` — LittleX's social-graph API, the **public (pre-auth) slice**. These are LittleX's real walkers and view models (see the full app in [`examples/littleX/social_graph.jac`](https://github.com/Gorgeous-Patrick/jaseci_tutorial)), marked `pub` so `jac start` serves them without auth on one shared `root`.

- **`walker:pub setup_profile`** — creates the profile under `root` if there isn't one, then applies the username/bio. `run with Root entry` navigates to the profile; `apply with Profile entry` does the work.
- **`walker:pub get_profile`** — returns the full `ProfileView` (profile + its tweets).
- **`walker:pub get_all_profiles`** — an accumulator: fans out over profiles, gathers each as a `UserView`, reports once at `Root exit`.
- **`walker:pub create_tweet`** — navigates to the profile, then attaches a `Tweet` with a `Post` edge.
- **`walker:pub load_feed`** — gathers the profile's tweets (and any followed profiles' tweets), optionally filtered by `search_query`, newest first.
- **`walker:pub profile_feed`** — spawned on a specific node: `POST /walker/profile_feed/<node_id>` starts the walker on that node, so `here` is that node (a profile whose tweets it returns) instead of `root`.
- **`obj UserView` / `TweetView` / `ProfileView`** — the typed contract returned to the client. Each carries an `id` (from `jid`), so a client can target a node.

Every walker declares where it starts (`with Root entry`) and what to do at each node type it lands on (`with Profile entry`, `with Tweet entry`). Traversal is `visit`, never a hand-rolled loop.

`requests.sh` — a client script that sends a request to every endpoint and pretty-prints the responses.

### From here to the full LittleX

Two things are deferred to the **auth episode**, where these same walkers turn private:

- `grant(...)` permission calls (who may read/write each new node)
- `allroots()` cross-user aggregation (gathering across every user's graph)

The walker names and structure stay identical — going multi-user is dropping `:pub` and adding those two, not a rewrite. Later episodes also grow the views (likes, comments, followers) and add the follow / like / channel walkers.

## Prerequisites

```bash
curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash
jac --version
```

## Run it

```bash
jac start main.jac --port 8000
```

Open the auto-generated Swagger UI at **http://localhost:8000/docs**, or send requests:

```bash
bash requests.sh
# or point it elsewhere:  BASE=localhost:3000 bash requests.sh
```

Or with `curl` directly:

```bash
# create/update the shared profile
curl -X POST localhost:8000/walker/setup_profile -H 'Content-Type: application/json' \
     -d '{"username":"alice","bio":"building LittleX"}'

# post tweets, then read the feed
curl -X POST localhost:8000/walker/create_tweet -H 'Content-Type: application/json' \
     -d '{"content":"Hello, LittleX!"}'
curl -X POST localhost:8000/walker/load_feed

# spawn a walker on a specific node (id comes back in any view)
curl -X POST localhost:8000/walker/profile_feed/<node_id>
```

## The response envelope

Every endpoint returns the same shape:

```json
{
  "ok": true,
  "type": "response",
  "data": { "result": ..., "reports": [ ... ] },
  "error": null,
  "meta": { "extra": { "http_status": 200 } }
}
```

Walker `report` values arrive in `data.reports`. A view serializes to its fields plus `_jac_type` / `_jac_id` metadata.

## Reset it

The graph persists in `.jac/data/` between restarts. To start from an empty graph:

```bash
rm -rf .jac
```

## What to notice

- Marking a walker `pub` is the whole step from internal code to a live HTTP endpoint.
- Each walker is a small traversal: start at `root`, `visit` into the graph, act on entry at each node type.
- View models keep the internal node shape separate from what the client sees.
- These are the real LittleX walkers — the auth episode makes them private by dropping `:pub`.
