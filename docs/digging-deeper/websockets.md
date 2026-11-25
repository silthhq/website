---
title: WebSockets & channels
description: Real-time channels, presence and server broadcasts.
---
# WebSockets & channels

```crystal
class ChatChannel < Silth::Channel
  topic "chat:*"

  def join(payload : JSON::Any) : Bool
    track_presence({"name" => socket.user.try(&.as?(User).try(&.name)) || "guest"})
    !socket.user.nil?                          # authorize
  end

  def handle_in(event : String, payload : JSON::Any) : Nil
    case event
    when "message" then broadcast("message", {body: payload["body"].as_s, at: Time.utc})
    end
  end
end
```

```js
import { silth } from "silth";
const room = silth.socket().channel("chat:lobby");
room.on("message", (m) => append(m.body));
room.on("presence_diff", (diff) => updateRoster(diff));
await room.join();
room.push("message", { body: "Hello!" });
```

The socket lives at `/_silth/socket` and is authenticated with the regular session cookie.

## Broadcasting from the server

```crystal
Silth::Broadcast.to("orders:#{order.id}", "status", {status: "shipped"})
Silth::Presence.list("chat:lobby")
```

## Several server nodes

Channels, `Broadcast` and live component refreshes go through `Silth::PubSub`. In one process it is in memory; with several nodes behind a load balancer, pick an adapter in `config/realtime.yml` so every node receives every message:

```yaml
pubsub: postgres               # memory | redis | postgres
redis_url: ${REDIS_URL:-redis://localhost:6379/0}
connection: primary            # postgres: connection from config/database.yml
channel: silth_pubsub
```

| Adapter | Transport | Notes |
|---|---|---|
| `memory` | none | single process (default) |
| `redis` | `PUBLISH`/`SUBSCRIBE` on `channel` | `rediss://` for TLS |
| `postgres` | `LISTEN`/`NOTIFY` on a dedicated connection | no extra service; messages over 8000 bytes go through an `UNLOGGED` table (`silth_pubsub_messages`); a message published inside a transaction is sent at commit |

Listeners reconnect on their own (with a growing pause) when the connection drops; a failed publish is logged, never raised into the request. The PostgreSQL listener shows up as `silth-pubsub` in `pg_stat_activity`. In code: `Silth::PubSub.adapter = Silth::PubSub::RedisAdapter.new(url)`, or implement `Silth::PubSub::Adapter` (`publish`, `start`, `stop`) for another transport.
