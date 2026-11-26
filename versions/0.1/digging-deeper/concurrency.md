---
title: Concurrency
description: Fibers, parallel maps, timeouts, retries and deferred work.
---
# Concurrency

Crystal runs each request in a lightweight fiber. Silth adds structured helpers:

```crystal
users, posts = Silth::Concurrency.run(-> { User.count }, -> { Post.count })

statuses = Silth::Concurrency.map(urls, workers: 8) { |url| Silth::HTTPClient.get(url).status }

Silth::Concurrency.defer { Analytics.track(event) }          # fire and forget, errors reported

Silth::Concurrency.timeout(2.seconds) { slow_service.call }  # raises Concurrency::Timeout

Silth::Concurrency.retry(times: 3, base_delay: 200.milliseconds) { flaky_api.call }
```

`map` preserves order and raises `Concurrency::Failed` with every error. Database queries inside fibers each check out their own pooled connection (transactions are pinned to the fiber that opened them).

Build with `-Dpreview_mt` to schedule fibers on several threads.
