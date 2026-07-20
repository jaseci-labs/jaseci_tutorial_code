# Episode 7 deliverable — LittleX goes multi-user.
#
# Same walkers as Episode 6, with one change: `walker:pub` becomes
# `walker:priv`. Now each request must be authenticated, and every user
# operates on their OWN `root` — the runtime isolates them. `jac start`
# auto-generates `/user/register` and `/user/login`; a walker call carries
# the login token in an `Authorization: Bearer <token>` header.
#
# Two small additions make users discoverable across their separate roots:
#   grant(...)   — share a node so other users may read it
#   allroots()   — walk every user's root, not just the caller's
#
# Run it:
#   jac start main.jac
#   bash requests.sh          # registers alice + bob, shows isolation

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

# --- Edges ---
edge Follow {}
edge Post {}

# --- Nodes ---
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

# --- Profile walkers: spawn at the caller's OWN root ---
walker:priv setup_profile {
    has username: str = "",
        bio: str = "";

    can run with Root entry {
        visit [-->[?:Profile]] else {
            fresh = Profile(created_at=_now());
            here ++> fresh;
            # Share the profile so other users' walkers may read it.
            grant(fresh, level=ConnectPerm);
            visit fresh;
        }
    }

    can apply with Profile entry {
        if self.username { here.username = self.username; }
        if self.bio { here.bio = self.bio; }
        report here.to_profile_view();
    }
}

walker:priv get_profile {
    can run with Root entry {
        visit [-->[?:Profile]];
    }

    can give with Profile entry {
        report here.to_profile_view();
    }
}

# --- Global directory: allroots() reaches every user's root ---
walker:priv get_all_profiles {
    has results: list[UserView] = [],
        seen: dict[str, bool] = {};

    can run with Root entry {
        for r in allroots() {
            visit [r-->[?:Profile]];
        }
    }

    can gather with Profile entry {
        pid = jid(here);
        if pid in self.seen {
            return;
        }
        self.seen[pid] = True;
        self.results.append(here.to_user_view());
    }

    can deliver with Root exit {
        report self.results;
    }
}

# --- Create a tweet under the caller's profile ---
walker:priv create_tweet {
    has content: str;

    can run with Root entry {
        visit [-->[?:Profile]];
    }

    can make with Profile entry {
        new = Tweet(content=self.content, author_username=here.username, created_at=_now());
        here +>:Post():+> new;
        # Share the tweet so it can appear in other users' feeds.
        grant(new, level=WritePerm);
        report new.to_view();
    }
}

walker:priv load_feed {
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
