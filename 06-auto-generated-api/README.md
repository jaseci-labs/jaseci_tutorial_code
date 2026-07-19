# Episode 6 — Auto-Generated API

Companion code for the Auto-Generated API episode of the Jac tutorial series.

## What's in this directory

`main.jac` — takes the LittleX graph and exposes it as an HTTP service. Marking code `pub` is the only step: `jac start` reads the signatures and generates documented REST endpoints.

- **`def:pub health()`** — a public function. Becomes `POST /function/health`; the return value lands in `data.result`.
- **`walker:pub add_profile` / `post_tweet` / `feed`** — public walkers. Each becomes `POST /walker/<name>`; the walker's `has` fields are the request body, and its `report` values land in `data.reports`.
- **`obj UserView` / `obj TweetView`** — typed view models, the contract the client receives.
- **`Profile.to_view()` / `Tweet.to_view()`** — each node builds its own view; walkers report the result.

The walkers use a plain `with entry` ability and reach the graph through the built-in `root` node, so every request reads and writes the same persistent graph.

## Prerequisites

Install Jac if you haven't already:

```bash
curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash
jac --version
```

## Run it

From this directory:

```bash
jac start main.jac --port 8000
```

Then open the auto-generated Swagger UI at **http://localhost:8000/docs** — every public function and walker is listed with its request and response schema, and you can call them from the browser.

## Try the endpoints

```bash
# def:pub function
curl -X POST localhost:8000/function/health

# create two profiles (idempotent — adding an existing one just returns it)
curl -X POST localhost:8000/walker/add_profile -H 'Content-Type: application/json' -d '{"username":"alice"}'
curl -X POST localhost:8000/walker/add_profile -H 'Content-Type: application/json' -d '{"username":"bob"}'

# post tweets
curl -X POST localhost:8000/walker/post_tweet -H 'Content-Type: application/json' -d '{"username":"alice","content":"Hello, LittleX!"}'
curl -X POST localhost:8000/walker/post_tweet -H 'Content-Type: application/json' -d '{"username":"bob","content":"Walkers ftw."}'

# read the feed
curl -X POST localhost:8000/walker/feed
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

- Function return values arrive in `data.result`.
- Walker `report` values arrive in `data.reports`.
- A view model serializes to its fields plus `_jac_type` / `_jac_id` metadata, e.g. `{"_jac_type": "TweetView", "author": "alice", "content": "Hello, LittleX!"}`.

## Reset it

The graph persists in `.jac/data/` between restarts. To start from an empty graph:

```bash
rm -rf .jac
```

## What to notice

- One keyword (`pub`) is the whole step from internal code to a live HTTP endpoint — the function/walker signature *is* the API contract.
- Swagger at `/docs` is generated from your type annotations, so it's always in sync with the code.
- View models keep the internal node shape separate from what the client sees.
- The graph is durable: stop the server, start it again, and `feed` still returns the tweets you posted.
