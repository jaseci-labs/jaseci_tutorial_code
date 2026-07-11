# Jac Tutorial — Code Deliverables

Runnable code for each episode of the [Jac tutorial series](https://github.com/Gorgeous-Patrick/jaseci_tutorial). One directory per episode; each holds a self-contained `main.jac` you can run with the `jac` CLI.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash
```

Verify:

```bash
jac --version
```

## Episodes

| # | Directory | What it does |
|---|-----------|--------------|
| 4 | `04-osp/`         | Three node types, four edge types, one dummy walker on a small in-memory graph. Introduces Object-Spatial Programming. |
| 5 | `05-data-model/`  | Same graph shapes as L4, plus `root` and an idempotent `bootstrap` walker. Runs twice: seeds the graph, then finds it already there. |

More coming as the series continues.

## Run an episode

```bash
cd 04-osp
jac main.jac
```

For episodes with persistence (L5+), running twice shows the graph surviving across runs. The runtime writes to `.jac/data/` under the episode directory.
