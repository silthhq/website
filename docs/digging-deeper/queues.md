---
title: Queues
description: Background jobs with retries, delays and several drivers.
---
# Queues

```crystal
class ResizeImageJob < Silth::Job
  queue "media"
  retries 5
  timeout 2.minutes

  getter upload_id : Int64
  def initialize(@upload_id); end

  def perform : Nil
    Upload.find(upload_id).resize!
  end

  def failed(error : Exception) : Nil
    Log.error { "Resize failed: #{error.message}" }
  end
end

ResizeImageJob.new(upload.id).dispatch
ResizeImageJob.new(upload.id).dispatch(delay: 10.minutes)
ResizeImageJob.new(upload.id).dispatch_after_commit
ResizeImageJob.new(upload.id).dispatch_now
```

Jobs are serialized with `JSON::Serializable` — keep ivars JSON friendly (ids, not models).

## Drivers

```yaml
# config/queue.yml
driver: database      # sync | memory | database | redis
```

| Driver | Use |
|---|---|
| `sync` | run immediately (tests) |
| `memory` | in-process fibers (development) |
| `database` | durable, uses `FOR UPDATE SKIP LOCKED` on PostgreSQL/MySQL, atomic claims on SQLite |
| `redis` | lists + sorted set for delayed jobs |

## Workers

```bash
silth queue:work --queues=media,default --concurrency=8
silth queue:work --once        # drain and exit
silth queue:failed
```

Failed attempts are retried with exponential backoff (override `backoff(attempt)`); exhausted jobs land in `silth_failed_jobs` and the profiler's *Activity* tab. Tests: `Silth::Queue.fake` and `Silth::Queue.pushed?(ResizeImageJob)`.
