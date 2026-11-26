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
| Queries | statements with their arguments, offsets, timings and the line of your code that ran them; slow ones and repeats (possible N+1) flagged |
| Logs | every log line written during the request, filterable by level |
| Translations | every key looked up, with its locale and status: found, fallback (another locale answered) or missing |
| Events | events, cache operations, mails, jobs, notifications, outgoing HTTP calls |
| Request | params, session, request and response headers |
| Exceptions | reported exceptions with their backtrace |

```yaml
# config/profiler.yml
enabled: false
toolbar: true
keep: 200                          # profiles kept in memory
slow_query_ms: 100
query_sources: true                # the line of your code behind each query
editor: ${SILTH_EDITOR:-vscode}    # file:line links open in your editor
when@development:
  enabled: true
```

Each response carries an `X-Silth-Profile` header with the profile token, handy when debugging APIs: open `/_silth/profiler/<token>`.

## Hunting N+1 queries

Every query is traced back to the first line of **your** code that ran it (a controller, a model method, a template line), skipping the framework, shards and the standard library. The Queries panel shows it next to each statement, the timeline next to each query bar.

When the same statement runs several times from the same line, that line is a loop doing one query per item: the panel lists it first, with the count and the line, and the toolbar's database item turns amber.

```text
×12  SELECT * FROM authors WHERE id = ? LIMIT 1
     from src/views/posts/index.html.ecr:8 · to_s
```

Preload the association (`Post.includes(:author)`), load the rows in one query, or cache the result. The trace comes from the backtrace, so it needs debug information, which `silth serve` builds have. It costs a few microseconds per query; `query_sources: false` turns it off.

## Editor links

File and line references (queries, timeline, exceptions, the debug page) open in your editor:

| `editor:` | Opens |
|---|---|
| `vscode` (default), `vscode-insiders`, `vscodium`, `cursor`, `windsurf` | `vscode://file/…:line` and friends |
| `zed` | `zed://file/…:line` |
| `idea` (any JetBrains IDE with the Toolbox) | `idea://open?file=…&line=…` |
| `sublime`, `textmate`, `emacs`, `macvim`, `nova` | their URL schemes |
| `"myeditor://open?path={file}&line={line}"` | any template with `{file}` and `{line}` |
| `none` | plain text |

`SILTH_EDITOR=zed silth serve` picks one without touching the config. When the app runs in a container, set `editor_root` to its path on your machine so the links point there.

## Your own events

The profiler subscribes to `Silth::Instrument`. Anything you publish shows up in the Events panel and on the timeline:

```crystal
Silth::Instrument.measure("pdf.render") { Pdf.render(invoice) }
Silth::Instrument.publish(Silth::Instrument::Custom.new("import.done", {"rows" => "1200"}))
```

Template and component renders, controller actions and translation lookups are instrumented by the framework (`Instrument::Render`, `Instrument::Action`, `Instrument::Translation`); they cost nothing when nobody listens.
