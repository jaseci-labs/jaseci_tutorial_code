# Episode 9 — Frontend (the complete LittleX)

Companion code for the Frontend episode — and the **finished LittleX app**. This is the production build the whole series has been leading up to: a full backend *and* a React-style UI, in one Jac project.

## What's in this directory

**Backend**
- `social_graph.jac` — the complete social graph: `Profile` / `Tweet` / `Channel` nodes, the full set of walkers (profiles, tweets, feed, follows, likes, comments, channels, trending), view models, and multi-user auth via `grant()` / `allroots()`.

**Frontend** (the `cl` codespace — React-style JSX written in Jac)
- `frontend.cl.jac` / `frontend.impl.jac` — the app shell and its logic (calls the backend walkers with `root spawn`).
- `components/` — the UI: `FeedTab`, `ExploreTab`, `ProfileTab`, `ChannelsTab`, `Composer`, `TweetCard`, `Sidebar`, `AuthForm`, … plus a `ui/` primitives library (button, card, dialog, tabs, …).
- `lib/`, `assets/`, `global.css` — helpers, the logo, and styles.

`main.jac` — the entry point that mounts the client app.

## Prerequisites

```bash
curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash
jac --version
```

## Run it

```bash
jac start main.jac
```

`jac start` serves the backend endpoints **and** builds and serves the client bundle. Open the app in your browser, register a user, and you're on LittleX.

## What to notice

- One project, one language: the backend walkers and the frontend components live side by side. The client calls a walker as if it were a local function.
- Everything you've learned across the series is here in production form — the graph model (Ep4–5), the auto-generated API (Ep6), auth and multi-user (Ep7), and now the UI.
