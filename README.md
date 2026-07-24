# Jac Tutorial — Code Deliverables

Runnable code for each episode of the [Jac tutorial series](https://github.com/Gorgeous-Patrick/jaseci_tutorial). One directory per episode; each contains a self-contained `main.jac` and its own `README.md` with detailed instructions.

## Install Jac

```bash
curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash
jac --version
```

## Episodes

| # | Directory | Topic |
|---|-----------|-------|
| 4 | [`04-osp/`](04-osp/README.md)                | Object-Spatial Programming basics |
| 5 | [`05-data-model/`](05-data-model/README.md)  | Persistence via `root` |
| 6 | [`06-auto-generated-api/`](06-auto-generated-api/README.md) | REST API from `pub` functions and walkers |
| 7 | [`07-authentication/`](07-authentication/README.md) | Auth & multi-user: `pub` → `priv`, per-user `root` |
| 8 | [`08-agentic-ai/`](08-agentic-ai/README.md) | Agentic AI: the seven `by llm()` + OSP patterns |
| 9 | [`09-frontend/`](09-frontend/README.md) | The complete LittleX — full backend + `cl` frontend |
| 10 | [`10-scaling-to-k8s/`](10-scaling-to-k8s/README.md) | Same app, `[scale.*]` config → `jac start --scale` to Kubernetes |

Each episode's `README.md` covers what the code does, how to run it, and what to notice. `cd` into one and follow along.
