---
title: Profiler
description: Debug toolbar, request timeline and dashboard for development.
---
# Profiler

In development every HTML page gets a **toolbar** at the bottom: status and handler, total time, SQL queries, logs, translations, events, exceptions and the current user. Items turn amber or red when something deserves a look (duplicated or slow queries, warnings, missing translations).

- **Hover** an item (or focus it with Tab) to see the details without leaving the page: time breakdown, slowest queries, possible N+1, last warnings, missing translation keys…
- **Click** it to open the matching panel of the profile in a new tab, so the page you are testing stays as it is.
- **Fold** the bar with the chevron on the right: it becomes an icon in the bottom right corner (with a status dot) until you click it again. The choice is remembered per browser.

## Dashboard

The dashboard lives at **`/_silth/profiler`**: a sidebar with the sections and the last requests, and the content on the right.

| Section | Content |
|---|---|
| Requests | last requests (filter by URL, handler or status), median and slowest time, server errors |
| Activity | jobs, mails, warnings and exceptions happening outside requests (workers, scheduler, fibers) plus failed jobs |
| Mails | mail previews, captured and file-transport mails |
| Routes | every route with its middleware |
| Schedule | scheduled tasks, next and last runs |
| Workflows | SVG diagrams of every workflow |

Each request has these panels (`?panel=` in the URL):

| Panel | Content |
|---|---|
| Timeline | the path of the request on a time axis: before the action (middleware, session, CSRF, auth), the action, templates and components, every query, HTTP call, job, cache access, log line and exception, nested by containment |
| Queries | statements with their arguments, offsets and timings; slow ones and duplicates (possible N+1) flagged |
| Logs | every log line written during the request, filterable by level |
| Translations | every key looked up, with its locale and status: found, fallback (another locale answered) or missing |
| Events | events, cache operations, mails, jobs, notifications, outgoing HTTP calls |
| Request | params, session, request and response headers |
| Exceptions | reported exceptions with their backtrace |

```yaml
# config/profiler.yml
enabled: false
toolbar: true
keep: 200            # profiles kept in memory
slow_query_ms: 100
when@development:
  enabled: true
```

Each response carries an `X-Silth-Profile` header with the profile token, handy when debugging APIs: open `/_silth/profiler/<token>`.

## Your own events

The profiler subscribes to `Silth::Instrument`. Anything you publish shows up in the Events panel and on the timeline:

```crystal
Silth::Instrument.measure("pdf.render") { Pdf.render(invoice) }
Silth::Instrument.publish(Silth::Instrument::Custom.new("import.done", {"rows" => "1200"}))
```

Template and component renders, controller actions and translation lookups are instrumented by the framework (`Instrument::Render`, `Instrument::Action`, `Instrument::Translation`); they cost nothing when nobody listens.
