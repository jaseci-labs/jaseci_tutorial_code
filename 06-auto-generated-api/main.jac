# Episode 6 deliverable — LittleX's API, the public (pre-auth) slice.
#
# These are LittleX's real walkers and views (see the full app in
# examples/littleX/social_graph.jac), marked `pub` so `jac start` serves
# them without auth on one shared `root`. Each walker declares where it
# starts (`with Root entry`) and what to do at the nodes it lands on
# (`with Profile entry`, `with Tweet entry`). Traversal is `visit`.
#
# Two things are deferred to the auth episode, where the same walkers turn
# private: `grant(...)` permission calls, and `allroots()` cross-user
# aggregation. The walker names and structure stay the same — the change
# there is dropping `:pub`, not a rewrite.
#
# Run it:
#   jac start main.jac
#   open http://localhost:8000/docs
#   bash requests.sh          # in another terminal

import datetime;

def _now -> str {
    return datetime.datetime.now(datetime.UTC).replace(tzinfo=None).isoformat() + "Z";
}

# --- View models: the typed contract returned to the client ---
obj UserView {
    has id: str,
        username: str,
        bio: str = "";
}

obj TweetView {
    has id: str,
        content: str,
        author_username: str,
        created_at: str;
}

obj ProfileView {
    has id: str,
        username: str,
        bio: str,
        tweets: list[TweetView];
}

# --- Edges: relationships in the social graph ---
edge Follow {}
edge Post {}

# --- Nodes: data, plus the methods that present it as a view ---
node Profile {
    has username: str = "",
        bio: str = "",
        created_at: str = "";

    def to_user_view -> UserView {
        return UserView(id=jid(self), username=self.username, bio=self.bio);
    }

    def to_profile_view -> ProfileView {
        tweets = [t.to_view() for t in [self-->[?:Tweet]]];
        tweets.sort(key=lambda t: TweetView : t.created_at, reverse=True);
        return ProfileView(
            id=jid(self),
            username=self.username,
            bio=self.bio,
            tweets=tweets
        );
    }
}

node Tweet {
    has content: str = "",
        author_username: str = "",
        created_at: str = "";

    def to_view -> TweetView {
        return TweetView(
            id=jid(self),
            content=self.content,
            author_username=self.author_username,
            created_at=self.created_at
        );
    }
}

# --- Profile walkers: spawn at root, act on the profile ---
walker:pub setup_profile {
    has username: str = "",
        bio: str = "";

    can run with Root entry {
        # `else` fires when `visit` enqueues nothing — no profile yet — so
        # we create one and walk into it instead.
        visit [-->[?:Profile]] else {
            fresh = here ++> Profile(created_at=_now());
            visit fresh;
        }
    }

    can apply with Profile entry {
        if self.username { here.username = self.username; }
        if self.bio { here.bio = self.bio; }
        report here.to_profile_view();
    }
}

walker:pub get_profile {
    can run with Root entry {
        visit [-->[?:Profile]];
    }

    can give with Profile entry {
        report here.to_profile_view();
    }
}

# --- Accumulator walker: fan out, gather at each node, report once at exit ---
walker:pub get_all_profiles {
    has results: list[UserView] = [];

    can run with Root entry {
        visit [-->[?:Profile]];
    }

    can gather with Profile entry {
        self.results.append(here.to_user_view());
    }

    can deliver with Root exit {
        report self.results;
    }
}

# --- Create walker: navigate to the profile, then attach a tweet ---
walker:pub create_tweet {
    has content: str;

    can run with Root entry {
        visit [-->[?:Profile]];
    }

    can make with Profile entry {
        new = Tweet(content=self.content, author_username=here.username, created_at=_now());
        here +>:Post():+> new;
        report new.to_view();
    }
}

walker:pub load_feed {
    has search_query: str = "",
        feed: list[TweetView] = [];

    can run with Root entry {
        mine = [-->[?:Profile]];
        if mine {
            me = mine[0];
            visit [me-->[?:Tweet]];
            visit [me->:Follow:->[?:Profile]-->[?:Tweet]];
        }
    }

    can gather with Tweet entry {
        self.feed.append(here.to_view());
    }

    can deliver with Root exit {
        result = self.feed;
        if self.search_query {
            q = self.search_query.lower().strip();
            result = [t for t in result if q in t.content.lower()];
        }
        result.sort(key=lambda t: TweetView : t.created_at, reverse=True);
        report result;
    }
}

# --- Spawn on a specific node --------------------------------------------
# The walkers above start at `root` (the default). A walker can also be
# spawned on a specific node by putting the node's id in the path:
#     POST /walker/profile_feed/<node_id>
# Then `here` is that node, not root. Node ids come back in the views as
# `id` (from `jid`), so a client reads one and targets it here.
walker:pub profile_feed {
    can run with entry {
        report [t.to_view() for t in [here-->[?:Tweet]]];
    }
}
