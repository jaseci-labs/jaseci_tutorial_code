# Episode 7 — Authentication & Multi-User

Companion code for the Authentication episode of the Jac tutorial series.

## What's in this directory

`main.jac` — Episode 6's LittleX API, made multi-user by **one change: `walker:pub` becomes `walker:priv`**. Every request now must be authenticated, and each user operates on their **own `root`** — the runtime isolates them. `jac start` auto-generates `/user/register` and `/user/login`; a walker call carries the login token in an `Authorization: Bearer <token>` header.

Two small additions make users discoverable across their separate roots:

- **`grant(node, level=...)`** — share a node so *other* users' walkers may read it. `setup_profile` grants its `Profile`, `create_tweet` grants its `Tweet`.
- **`allroots()`** — walk *every* user's root, not just the caller's. `get_all_profiles` uses it to build a global directory.

Everything else — the walkers, the graph model, the view models — is identical to Episode 6.

`requests.sh` — registers two users and demonstrates the whole story: isolation (each feed shows only that user's tweets) and the global directory (`get_all_profiles` sees everyone).

## Prerequisites

```bash
curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash
jac --version
```

## Run it

```bash
jac start main.jac --port 8000
bash requests.sh          # in another terminal
```

## The auth flow

Register and log in return the built-in envelope; login hands back a JWT `token`:

```bash
# register
curl -X POST localhost:8000/user/register -H 'Content-Type: application/json' \
  -d '{"identities":[{"type":"username","value":"alice"}],"credential":{"type":"password","password":"pw123"}}'

# login -> data.token
curl -X POST localhost:8000/user/login -H 'Content-Type: application/json' \
  -d '{"identity":{"type":"username","value":"alice"},"credential":{"type":"password","password":"pw123"}}'

# call a walker as that user
curl -X POST localhost:8000/walker/setup_profile \
  -H "Authorization: Bearer <token>" -H 'Content-Type: application/json' \
  -d '{"username":"alice","bio":"building LittleX"}'
```

A `walker:priv` call **without** a token returns `401 UNAUTHORIZED`.

## What to notice

- The migration from single-user to multi-user is literally `pub` → `priv`. The walker bodies don't change, because they already start at `root`.
- Isolation is at the runtime level — each authenticated user gets a separate `root`. No query filters, no tenant column, no scoping logic.
- `load_feed` for alice returns only alice's tweets; for bob, only bob's. Same walker, different root.
- `get_all_profiles` still sees everyone — because `grant()` shared the profiles and `allroots()` reaches every root. That's how a private-by-default app still offers a public directory.

## The client side

Jac also ships browser-side auth helpers (`jacSignup`, `jacLogin`, `jacLogout`, `jacIsLoggedIn` from `@jac/runtime`) that manage the token for you. Those belong to the frontend and are covered when we build LittleX's UI.
