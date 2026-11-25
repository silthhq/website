---
title: Cache
description: Memory, file, database, PostgreSQL UNLOGGED and Redis stores with one API.
---
# Cache

```yaml
# config/cache.yml
default: redis          # memory | file | database | postgres | redis | null
stores:
  redis: { url: "${REDIS_URL:-redis://localhost:6379/1}" }
```

`postgres` keeps entries in an UNLOGGED PostgreSQL table, with atomic `add` and `increment` ([details](/docs/database/postgres#unlogged-tables-cache-sessions-logs)).

```crystal
cache = Silth.cache
cache.set("greeting", "hi", 10.minutes)
cache.get("greeting")                                  # String?
cache.fetch("stats", 5.minutes) { compute.to_json }     # read-through
cache.fetch_json("top", Array(Int64), 1.hour) { Post.popular(100).pluck(:id).map(&.as(Int64)) }
cache.increment("visits")
cache.add("once", "1", 1.day)                          # only if absent
cache.lock("report", 30.seconds) { build_report }      # nil when already locked
cache.delete("greeting")
Silth.cache("file").clear                              # another store
```

The Redis store uses Silth's own RESP client (`Silth::Redis`), also available directly. Cache hits and misses appear in the profiler.
