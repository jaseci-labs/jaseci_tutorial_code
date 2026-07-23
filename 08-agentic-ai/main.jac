"""LittleX's AI layer — the seven agentic patterns as LittleX features.

Same graph shapes as Ep5: Profile / Tweet / Channel nodes wired by
Follow / Post / Member / ChannelPost edges. Each section below is one
pattern from the video, applied to a real feature. Run with `jac main.jac`.
"""

# --- The LittleX graph from Ep5, miniaturized ---
node Profile {
    has username: str = "";
}

node Tweet {
    has content: str = "",
        author_username: str = "";
}

node Channel {
    has name: str = "",
        description: str = "";
}

edge Follow {}
edge Post {}
edge Member {}
edge ChannelPost {}

# === The Mind: three patterns inside a single model call ===

# --- byLLM: the signature is the prompt (the composer's reply button) ---
def suggest_reply(tweet: str) -> str by llm();
sem suggest_reply = "Suggest a short, friendly reply to this tweet.";

# --- Generate: channels describe themselves from what gets posted ---
def describe_channel(name: str, posts: list[str]) -> str by llm();
sem describe_channel =
    "An inviting one-line description from this channel's posts.";

walker refresh_description {
    can run with Root entry {
        visit [-->[?:Profile]->:Member:->[?:Channel]];
    }

    can write with Channel entry {
        posts = [t.content for t in [here-->[?:Tweet]]];
        here.description = describe_channel(here.name, posts);
        report here.description;
    }
}

# --- Extract: typed insights that power trending ---
enum Sentiment { POSITIVE, NEUTRAL, NEGATIVE }

obj TweetInsights {
    has topics: list[str];
    has sentiment: Sentiment;
}
sem TweetInsights.topics =
    "1-3 lowercase single-word topic tags, no '#' prefix.";

def analyze_tweet(content: str) -> TweetInsights by llm();
sem analyze_tweet = "Analyze a social post for its topics and tone.";

walker smart_trending {
    has counts: dict[str, int] = {};

    can run with Root entry {
        visit [-->[?:Profile]-->[?:Tweet]];
        visit [-->[?:Profile]-->[?:Channel]-->[?:Tweet]];
    }

    can tally with Tweet entry {
        for topic in analyze_tweet(here.content).topics {
            self.counts[topic] = self.counts.get(topic, 0) + 1;
        }
    }

    can deliver with Root exit {
        report self.counts;
    }
}

# --- Invoke: an assistant whose tools walk the LittleX graph ---
def search_tweets(query: str) -> list[str] {
    tweets = [root-->[?:Profile]-->[?:Tweet]]
        + [root-->[?:Profile]-->[?:Channel]-->[?:Tweet]];
    return [t.content for t in tweets
            if query.lower() in t.content.lower()];
}
sem search_tweets = "Find tweets containing the query text.";
sem search_tweets.query = "A single lowercase keyword.";

def list_channels -> list[str] {
    return [
        f"{c.name}: {c.description}"
        for c in [root-->[?:Profile]-->[?:Channel]]
    ];
}
sem list_channels = "Every channel's name and description.";

def assistant(question: str) -> str by llm(
    tools=[search_tweets, list_channels]
);
sem assistant =
    "Answer questions about what's happening on LittleX.";

# === The Flow: four patterns for how model calls connect ===

# --- Pipe: the AI composer — each stage is a node, the walker carries the text ---
node DraftPost {
    def run(topic: str) -> str by llm();
}
node AddTags {
    def run(text: str) -> str by llm();
}
node Trim {
    # A stage doesn't have to be a model call — this one is plain code.
    def run(text: str) -> str {
        return text[:280];
    }
}
sem DraftPost.run = "Draft a short social post about the topic.";
sem AddTags.run =
    "Return the post text with 2-3 fitting hashtags appended.";

walker compose_tweet {
    has text: str;

    can start with Root entry {
        visit [-->[?:DraftPost]];
    }
    can draft with DraftPost entry {
        self.text = here.run(self.text);
        visit [-->];
    }
    can tag with AddTags entry {
        self.text = here.run(self.text);
        visit [-->];
    }
    can trim with Trim entry {
        self.text = here.run(self.text);
    }
    can deliver with Root exit {
        report self.text;
    }
}

# --- Route: post without picking a channel — the model reads descriptions and files it ---
walker auto_file {
    has content: str;
    has author: str = "";

    can run with Root entry {
        me = [-->[?:Profile]][0];
        self.author = me.username;
        visit [me->:Member:->[?:Channel]] by llm(
            select=1,
            intent="Pick the channel where this tweet belongs.",
            incl_info={"tweet": self.content}
        );
    }

    can post with Channel entry {
        here +>:ChannelPost():+> Tweet(
            content=self.content, author_username=self.author
        );
        report here.name;
        disengage;
    }
}

# --- Loop: critique-and-revise until the description passes review ---
enum Verdict { APPROVE, REVISE }

obj Review {
    has verdict: Verdict;
    has feedback: str;
}
sem Review.feedback = "What to fix, when the verdict is REVISE.";

node Evaluate {
    def run(desc: str, posts: list[str]) -> Review by llm();
}
node Revise {
    def run(desc: str, feedback: str) -> str by llm();
}
edge Retry {}

sem Evaluate.run =
    "Review the description against what the channel discusses.";
sem Revise.run = "Rewrite the description, applying the feedback.";

walker refine_description {
    has desc: str = "",
        posts: list[str] = [],
        feedback: str = "",
        rounds: int = 0,
        max_rounds: int = 3;

    can start with Channel entry {
        self.posts = [t.content for t in [here-->[?:Tweet]]];
        self.desc = describe_channel(here.name, self.posts);
        visit [-->[?:Evaluate]];
    }

    can judge with Evaluate entry {
        review = here.run(self.desc, self.posts);
        if review.verdict == Verdict.APPROVE {
            return;
        }
        if self.rounds < self.max_rounds {
            self.rounds += 1;
            self.feedback = review.feedback;
            visit [here->:Retry:->[?:Revise]];
        }
    }

    can fix with Revise entry {
        self.desc = here.run(self.desc, self.feedback);
        visit [-->[?:Evaluate]];
    }

    can publish with Channel exit {
        here.description = self.desc;
        report self.desc;
    }
}

# --- Spawn: the "What's happening?" brief — one reporter per channel, in parallel ---
def summarize_posts(channel: str, posts: list[str]) -> str by llm();
sem summarize_posts =
    "One sentence on what this channel discusses right now.";

def merge_briefs(briefs: list[str]) -> str by llm();
sem merge_briefs =
    "Merge per-channel briefs into one 'What's happening' update.";

walker channel_reporter {
    has brief: str = "";

    can run with Channel entry {
        posts = [t.content for t in [here-->[?:Tweet]]];
        self.brief = summarize_posts(here.name, posts);
    }
}

walker whats_happening {
    can run with Root entry {
        channels = [-->[?:Profile]->:Member:->[?:Channel]];
        futures = [flow (c spawn channel_reporter())
                   for c in channels];
        briefs = [((wait f) as channel_reporter).brief
                  for f in futures];
        report merge_briefs(briefs);
    }
}

# --- A tiny LittleX world to run everything against ---
with entry {
    # Everything reachable from root persists between runs (Ep5!) — so build
    # the world and the flow scaffolding only when they don't exist yet.
    if not [root-->[?:Profile]] {
        alice = root ++> Profile(username="alice");
        bob = root ++> Profile(username="bob");
        alice +>:Follow():+> bob;

        gpu = alice +>:Member():+> Channel(name="gpu-talk");
        cook = alice +>:Member():+> Channel(name="home-cooking");

        gpu +>:ChannelPost():+> Tweet(content="New GPU day — finally got its tensor cores humming at 90% utilization", author_username="alice");
        gpu +>:ChannelPost():+> Tweet(content="Has anyone benchmarked the new HBM4 cards yet?", author_username="bob");
        cook +>:ChannelPost():+> Tweet(content="Sourdough starter, day 5: it's alive", author_username="bob");
        bob +>:Post():+> Tweet(content="Shipping my first Jac app today!", author_username="bob");

        # The Pipe and Loop stages live in the graph too.
        d = root ++> DraftPost();
        a = d ++> AddTags();
        a ++> Trim();

        ev = gpu ++> Evaluate();
        rv = ev +>:Retry():+> Revise();
        rv ++> ev;
    }
    gpu_talk = [root-->[?:Profile]->:Member:->[?:Channel, name == "gpu-talk"]][0];

    # The Mind
    print("reply:      ", suggest_reply("Shipping my first Jac app today!"));
    print("described:  ", (root spawn refresh_description()).reports);
    print("trending:   ", (root spawn smart_trending()).reports);
    print("assistant:  ", assistant("What are people saying about GPUs?"));

    # The Flow
    print("composed:   ", (root spawn compose_tweet(text="the Jac tutorial series launch")).reports);
    print("auto-filed: ", (root spawn auto_file(content="Best oven temperature for focaccia?")).reports);
    print("refined:    ", (gpu_talk spawn refine_description()).reports);
    print("brief:      ", (root spawn whats_happening()).reports);
}
