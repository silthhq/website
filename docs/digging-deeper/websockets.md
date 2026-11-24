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

Set `realtime.pubsub: redis` (or call `Silth::PubSub.boot_redis(url)`) to fan out across several servers.
