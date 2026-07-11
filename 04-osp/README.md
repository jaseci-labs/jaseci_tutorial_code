# Episode 4 — Object-Spatial Programming

Companion code for the OSP episode of the Jac tutorial series.

## What's in this directory

`main.jac` — a small program that declares:

- Three **node** types: `Profile`, `Tweet`, `Channel`
- Four **edge** types: `Follow` (with a `since` field), `Post`, `Member`, `ChannelPost`
- Each node's own **`greet`** ability, fired when a `describe_graph` walker arrives
- One **walker**, `describe_graph`, that fans out to tweets, channels, and followed profiles

The graph is built in a `with entry` block — no `root`, no persistence yet. Everything lives for the duration of a single run.

## Prerequisites

Install Jac if you haven't already:

```bash
curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash
jac --version
```

## Run it

From this directory:

```bash
jac main.jac
```

## Expected output

```
=== describe_graph starting at alice ===
[Profile]  alice
  [Tweet]    alice: "Hello, LittleX!"
  [Channel]  #hangout
[Profile]  bob
  [Tweet]    bob: "Learning OSP."
  [Tweet]    bob: "Walkers ftw."
[Profile]  carol
```

## What to notice

- The walker starts at alice. Each `Profile` it lands on fires its own `greet` — that's a **node ability**, not walker code.
- `tour` fires at every `Profile` entry, schedules three visits (tweets, channels, followed profiles), and does no printing itself.
- The traversal is recursive: alice → bob (via `Follow`) → carol. No cycles here, so the walker stops when there's nothing more to visit.
- Re-running the program produces the exact same output. Nothing is stored between runs.
