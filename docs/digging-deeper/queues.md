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

## Unique jobs

```crystal
class SyncStockJob < Silth::Job
  unique for: 10.minutes
  getter sku : String
  def initialize(@sku); end

  # Optional: what makes two jobs duplicates (default: class + arguments)
  def unique_key : String
    sku
  end
end

SyncStockJob.new("A1").dispatch   # => "01a2…" (job id)
SyncStockJob.new("A1").dispatch   # => nil, the first one is still waiting or running
```

The lock lives in the cache store (`config/cache.yml`), so use a shared store (Redis, database) when several workers run. It is released when the job succeeds or fails for good, and expires after `for:` in any case (a worker that crashed). `dispatch` returns `String?` for that reason.

## Rate limits

```crystal
class CallPartnerApiJob < Silth::Job
  rate_limit 30, per: 1.minute    # every job of this class, across workers
end
```

```yaml
# config/queue.yml: a whole queue
rate_limits:
  mail: 10/1s
  partner: 1000/1h
```

A job over the limit goes back to its queue until the next window, without using one of its retries. Counters live in the cache store like `Silth::RateLimit`. The `sync` driver ignores rate limits (jobs run inline).

## Batches

```crystal
batch = Silth::Batch.dispatch(rows.map { |row| ImportRowJob.new(row.id) },
  name: "Import #{import.id}",
  on_success: ImportDoneJob.new(import.id),     # every job succeeded
  on_failure: ImportFailedJob.new(import.id),   # first job that failed for good
  on_complete: CleanupJob.new(import.id))       # everything processed

Silth::Batch.find(batch.id).try(&.progress)     # => 0..100
batch.cancel                                    # jobs that did not start are skipped
```

Inside a job, `batch` returns the `Silth::Batch` (`batch.try(&.cancelled?)` to stop a long job early); callbacks get it the same way. The first job that fails for good cancels the batch, unless `allow_failures: true`. Callbacks are jobs rather than blocks so that any worker can run them.

| `Silth::Batch` | |
|---|---|
| `total_jobs`, `pending_jobs`, `processed_jobs`, `failed_jobs`, `failed_job_ids` | counters |
| `progress` | percent processed |
| `finished?`, `cancelled?`, `failed?` | state |

Batches are stored in `silth_job_batches` (created on first use) and counted under a row lock, so a batch finishes exactly once with any number of workers. Without a database they stay in memory (`batches: memory` in config/queue.yml).

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
