# Episode 6 deliverable — LittleX's graph, now a web API.
#
# In Episode 5 the graph lived behind a CLI walker. Here the same graph
# becomes an HTTP service: mark code `pub` and `jac start` turns it into
# a documented REST endpoint. Two forms:
#
#   def:pub     -> POST /function/<name>   body = params,     data.result  = return
#   walker:pub  -> POST /walker/<name>     body = has-fields, data.reports = reports
#
# Run it:
#   jac start main.jac
#   open http://localhost:8000/docs        # auto-generated Swagger UI
#
# Every walker below uses a plain `with entry` ability and reaches the
# persistent graph through the built-in `root` node, so each call reads
# and writes the same graph across requests.

# --- Edges --------------------------------------------------------------
edge Follow {}
edge Post {}

# --- View models: the typed contract the client receives ----------------
obj UserView {
    has username: str;
    has tweet_count: int;
}

obj TweetView {
    has author: str;
    has content: str;
}

# --- Nodes: each knows how to present itself as a view ------------------
node Profile {
    has username: str = "";
    def to_view -> UserView {
        return UserView(username=self.username, tweet_count=len([self -->[?:Tweet]]));
    }
}

node Tweet {
    has author: str = "",
        content: str = "";
    def to_view -> TweetView {
        return TweetView(author=self.author, content=self.content);
    }
}

# --- def:pub function -> HTTP endpoint ----------------------------------
# The whole API contract is the signature: a string in, a string out.
def:pub health() -> str {
    return "littleX api ok";
}

# --- walker:pub write endpoints -----------------------------------------
# Idempotent: adding a profile that already exists just returns it.
walker:pub add_profile {
    has username: str = "";
    can run with entry {
        existing = [p for p in [root -->[?:Profile]] if p.username == self.username];
        if existing {
            report existing[0].to_view();
            return;
        }
        p = Profile(username=self.username);
        root ++> p;
        report p.to_view();
    }
}

walker:pub post_tweet {
    has username: str = "",
        content: str = "";
    can run with entry {
        owner = [p for p in [root -->[?:Profile]] if p.username == self.username];
        if not owner {
            report {"error": f"no such profile: {self.username}"};
            return;
        }
        author = owner[0];
        t = Tweet(author=author.username, content=self.content);
        author +>: Post() :+> t;
        report t.to_view();
    }
}

# --- walker:pub read endpoint -------------------------------------------
walker:pub feed {
    can run with entry {
        tweets = [];
        for p in [root -->[?:Profile]] {
            for t in [p -->[?:Tweet]] {
                tweets.append(t.to_view());
            }
        }
        report {"tweets": tweets};
    }
}
