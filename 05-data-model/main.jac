# Episode 5 deliverable — LittleX's graph, now persistent.
#
# Same node/edge shapes as Lesson 4, plus one new idea: connect the
# graph to `root`. Anything reachable from root survives a restart.
# The `bootstrap` walker seeds the graph only if it's empty, so
# repeated runs stay idempotent.
#
# Run twice:
#   jac main.jac   # Run 1 — seeds and describes
#   jac main.jac   # Run 2 — same graph, no reseed

# --- Edges --------------------------------------------------------------
edge Follow { has since: str = ""; }
edge Post {}
edge Member {}
edge ChannelPost {}

# --- Nodes: each carries a `greet` ability the describe walker triggers ---
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

# --- Walker 1: bootstrap. Idempotent seed of the LittleX graph. --------
walker bootstrap {
    can seed with Root entry {
        if [-->[?:Profile]] {
            print("Graph already seeded — skipping.");
            return;
        }
        print("Empty graph — seeding.");
        alice = Profile(username="alice");
        bob   = Profile(username="bob");
        carol = Profile(username="carol");

        # Only alice sits directly under root. bob and carol are still
        # persisted because they're reachable via alice's Follow edges.
        here ++> alice;

        alice +>: Follow(since="2026-01-01") :+> bob;
        bob   +>: Follow(since="2026-02-14") :+> carol;

        alice +>: Post() :+> Tweet(author="alice", content="Hello, LittleX!");
        bob   +>: Post() :+> Tweet(author="bob",   content="Learning OSP.");
        bob   +>: Post() :+> Tweet(author="bob",   content="Walkers ftw.");

        alice +>: Member() :+> Channel(name="hangout");
    }
}

# --- Walker 2: describe_graph. Starts at root, tours reachable graph. --
walker describe_graph {
    can from_root with Root entry {
        visit [-->[?:Profile]];
    }
    can tour with Profile entry {
        visit [-->[?:Tweet]];
        visit [-->[?:Channel]];
        visit [->:Follow:->[?:Profile]];
    }
}

with entry {
    root spawn bootstrap();
    print("=== describe_graph starting at root ===");
    root spawn describe_graph();
}
