# Episode 8 — Agentic AI

Companion code for the Agentic AI episode of the Jac tutorial series.

## What's in this directory

`main.jac` — LittleX's AI layer: the **seven agentic patterns** from the video, each applied to a real LittleX feature on the Ep5 graph (Profile / Tweet / Channel).

**The Mind — three patterns inside a single model call:**
- **byLLM** — `suggest_reply(tweet)` — the signature is the prompt.
- **Generate** — `describe_channel` + the `refresh_description` walker: a channel describes itself from what's posted in it.
- **Extract** — `analyze_tweet -> TweetInsights` (typed `enum` + `obj`) powering `smart_trending`.
- **Invoke** — `assistant(question)` with `tools=[search_tweets, list_channels]` — the tools walk the graph.

**The Flow — four patterns for how model calls connect:**
- **Pipe** — `compose_tweet` walks `DraftPost → AddTags → Trim` nodes, carrying the text.
- **Route** — `auto_file` uses `visit [...] by llm(...)` to file a tweet into the right channel by reading descriptions.
- **Loop** — `refine_description` critiques and revises via an `Evaluate`/`Revise` pair joined by a `Retry` edge, until a typed `Verdict` approves.
- **Spawn** — `whats_happening` spawns one `channel_reporter` per channel in parallel, then merges the briefs.

## Prerequisites

```bash
curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash
jac --version
```

`by llm()` calls a model. `jac.toml` sets `default_model = "gpt-4o"`, so export an OpenAI key first:

```bash
export OPENAI_API_KEY=sk-...
```

## Run it

```bash
jac run main.jac
```

The `with entry` block seeds a tiny LittleX world (persisted via `root`, so it's built only once) and then runs every pattern in turn, printing each result.

## What to notice

- Every AI feature is **OSP + `by llm()`**: the walker gathers context by traversing the graph, and the model supplies the meaning.
- `sem` annotations attach extra intent when the signature alone isn't enough.
- The graph *is* the workflow — Pipe stages, the Loop's `Retry` edge, and the parallel Spawn are all just nodes and edges.
