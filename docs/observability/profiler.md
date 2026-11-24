---
title: Profiler
description: Debug toolbar and Telescope-style dashboard for development.
---
# Profiler

In development every HTML page gets a **debug toolbar**: status, handler, total time, number and time of SQL queries (warnings for duplicates and slow queries), logs, events, memory and current user.

Click it to open **`/_silth/profiler`**:

| Tab | Content |
|---|---|
| Requests | last requests with filter; each profile shows queries (highlighted, duplicates flagged), logs, events, cache operations, mails, jobs, outgoing HTTP calls, exceptions, params, session and headers |
| Activity | jobs, mails, warnings and exceptions happening outside requests (workers, scheduler, fibers) plus failed jobs |
| Mails | captured and file-transport mails |
| Routes | every route with its middleware |
| Schedule | scheduled tasks, next and last runs |
| Workflows | SVG diagrams of every workflow |

```yaml
# config/profiler.yml
enabled: false
toolbar: true
keep: 200            # profiles kept in memory
slow_query_ms: 100
when@development:
  enabled: true
```

Each response carries an `X-Silth-Profile` header with the profile token — handy when debugging APIs. The profiler subscribes to `Silth::Instrument`; publish your own events with `Silth::Instrument.measure("pdf.render") { … }`.
