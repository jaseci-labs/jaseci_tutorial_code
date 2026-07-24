# Episode 10 — Scaling to Kubernetes

Companion code for the final episode. This is the **same LittleX app** as Episode 9 — every `.jac` file is byte-for-byte identical. The only difference is the `[scale.*]` configuration added to `jac.toml`. That's the whole point: **scaling is a deployment concern, not a rewrite.**

## What's in this directory

- The complete LittleX app (backend `social_graph.jac` + the `cl` frontend), unchanged from Episode 9.
- `jac.toml` — now with `[scale.*]` blocks describing the production deployment (see below).

## The `scale` subsystem

Scaling ships **inside** jac — there is no `jac-scale` package to install. The heavier deps (pymongo, redis, kubernetes, docker, prometheus-client, …) are optional; declaring the `[scale.*]` config below and running `jac install` resolves just those into `.jac/venv`.

```bash
jac install          # resolve the scale deps declared in jac.toml
```

## Local dev (unchanged)

```bash
jac start main.jac   # SQLite at .jac/data/, one process — zero setup
```

## Deploy to Kubernetes

Set the secrets in your environment first (they're injected as a k8s Secret at deploy time):

```bash
export MONGODB_URI=...        # shared graph + user store (required for >1 replica)
export REDIS_URL=...          # cache + coordination tier
export JWT_SECRET=...         # auth signing key — change the default
export OPENAI_API_KEY=...     # model key for the AI layer
```

Then:

```bash
jac start main.jac --scale --dry-run    # lint config + print the plan; nothing applied
jac start main.jac --scale              # deploy (no image build)
jac start main.jac --scale --build      # build + push a Docker image, then deploy
```

MongoDB and Redis are auto-provisioned as StatefulSets alongside your pods. HTTPS is a two-step: deploy plain, point your domain's CNAME at the printed load-balancer host, then `jac start main.jac --scale --enable-tls`.

## Operate it

```bash
jac scale status main.jac               # component health (app, Mongo, Redis, Grafana)
jac scale logs application              # stream logs
jac scale restart application           # restart a component
jac scale destroy main.jac              # ⚠️  DELETES the namespace + persistent volumes — data is lost
```

Built-in probes: `/health` (liveness), `/ready` (readiness). With `[scale.monitoring]` on, `/metrics` feeds Prometheus and a Grafana dashboard.

## What to notice

- Not one line of application code changed from Episode 9. The `walker:priv` code from the auth episode, the `by llm` calls from the AI episode, and the `cl` frontend all run in the cluster exactly as written.
- The deployment — replicas, autoscaling, the shared database, secrets, TLS — is described in `jac.toml`, not in Dockerfiles or Helm charts.
- Multi-replica needs a shared store: `MONGODB_URI` (+ Redis). SQLite is single-process only.
