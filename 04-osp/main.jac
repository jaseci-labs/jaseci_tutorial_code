# Episode 4 deliverable — LittleX in miniature.
#
# Three node types, four edge types, one dummy walker. Everything the
# Object-Spatial Programming lesson introduces, in one runnable file
# so viewers can code along and see the concepts move.
#
# Run:  jac main.jac

# --- Edges: typed relationships between nodes. ------------------------
# `Follow` carries its own data (a `since` timestamp) to show that
# edges can hold state; the others are markers with no fields.

edge Follow { has since: str = ""; }
edge Post {}
edge Member {}
edge ChannelPost {}

# --- Nodes: the data plus each node's own ability to describe itself
#     when a `describe_graph` walker arrives. -------------------------

node Profile {
    has username: str = "";

    can greet with describe_graph entry {
        print(f"[Profile]  {self.username}");
    }
}

node Tweet {
    has author: str = "",
        content: str = "";

    can greet with describe_graph entry {
        print(f'  [Tweet]    {self.author}: "{self.content}"');
    }
}

node Channel {
    has name: str = "";

    can greet with describe_graph entry {
        print(f"  [Channel]  #{self.name}");
    }
}

# --- Walker: a tour that fans out at every Profile it visits.
#     Each destination node's `greet` ability does the printing. ------

walker describe_graph {
    can tour with Profile entry {
        visit [-->[?:Tweet]];
        visit [-->[?:Channel]];
        visit [->:Follow:->[?:Profile]];
    }
}

# --- Build a small graph in the entry block, then spawn the walker.
#     No `root` here — persistence comes in the next episode. Nodes
#     live only for this run. -----------------------------------------

with entry {
    alice = Profile(username="alice");
    bob   = Profile(username="bob");
    carol = Profile(username="carol");

    # Alice follows Bob; Bob follows Carol.
    alice +>:Follow(since="2026-01-01"):+> bob;
    bob   +>:Follow(since="2026-02-14"):+> carol;

    # Alice posts once; Bob posts twice; Carol is quiet.
    alice +>:Post():+> Tweet(author="alice", content="Hello, LittleX!");
    bob   +>:Post():+> Tweet(author="bob",   content="Learning OSP.");
    bob   +>:Post():+> Tweet(author="bob",   content="Walkers ftw.");

    # Alice creates and joins a channel.
    alice +>:Member():+> Channel(name="hangout");

    # Spawn the walker at alice. Watch it tour the reachable graph.
    print("=== describe_graph starting at alice ===");
    alice spawn describe_graph();
}
