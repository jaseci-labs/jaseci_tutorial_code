# Episode 5 — Data Model and Database

Companion code for the Data Model episode of the Jac tutorial series.

## What's in this directory

`main.jac` — takes the graph from Episode 4 and makes it persistent by connecting it to `root`.

- Same node and edge types as L4 (`Profile`, `Tweet`, `Channel`; `Follow`, `Post`, `Member`, `ChannelPost`)
- A new **`bootstrap`** walker — idempotent seed on `Root entry`. Guards on `[-->[?:Profile]]`, then wires alice → bob → carol with the same tweets/channel/follows as L4.
- The **`describe_graph`** walker gains a `from_root` ability on `Root entry` that hops to profiles under root; the existing `tour` ability from L4 handles the rest.

Only alice is attached directly to `root`. bob and carol persist because they're reachable through alice's `Follow` edges.

## Prerequisites

Install Jac if you haven't already:

```bash
curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash
jac --version
```

## Run it (twice)

From this directory:

```bash
jac main.jac    # Run 1 — seeds the graph, then tours it
jac main.jac    # Run 2 — finds the graph already there, tours it again
```

## Expected output

Run 1:

```
Empty graph — seeding.
=== describe_graph starting at root ===
[Profile]  alice
  [Tweet]    alice: "Hello, LittleX!"
  [Channel]  #hangout
[Profile]  bob
  [Tweet]    bob: "Learning OSP."
  [Tweet]    bob: "Walkers ftw."
[Profile]  carol
```

Run 2:

```
Graph already seeded — skipping.
=== describe_graph starting at root ===
[Profile]  alice
  [Tweet]    alice: "Hello, LittleX!"
  [Channel]  #hangout
[Profile]  bob
  [Tweet]    bob: "Learning OSP."
  [Tweet]    bob: "Walkers ftw."
[Profile]  carol
```

## Where the data lives

After the first run, look in `.jac/data/`:

```bash
ls .jac/data/
# main.db
```

That SQLite file is the whole "database." The runtime writes to it whenever a walker returns.

## Reset it

To start over (empty graph, `bootstrap` will reseed):

```bash
rm -rf .jac
```

## What to notice

- Only alice is attached to `root` via `++>`. bob and carol persist because they're reachable via `Follow` edges — reachability is transitive.
- `bootstrap` is idempotent: the guard on `[-->[?:Profile]]` skips the seed after the first run.
- Same walker code as L4 for the `tour` ability. The only new piece is `from_root`.
- Persistence works out of the box — the runtime opens the SQLite file, and your graph declarations *are* the schema.
