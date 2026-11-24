---
title: Introduction
description: What Silth is, what it ships with, and why it exists.
---
# Introduction

**Silth** is a batteries-included MVC web framework for [Crystal](https://crystal-lang.org). It brings the productivity of Laravel and Ruby on Rails, the rigour of Symfony and the speed of a compiled language — without a single third-party shard.

```crystal
Silth.routes do
  get "/", HomeController, :index
  resources "posts", PostsController
end

class PostsController < ApplicationController
  def index
    render "posts/index", posts: Post.published.latest.paginate(params.int("page", 1))
  end
end
```

## Why Silth?

- **Readable code, compiled speed.** Crystal reads like Ruby and runs like C. Code written by you — or by an AI agent — stays easy to review.
- **Zero dependencies.** Every piece (HTTP stack, PostgreSQL/MariaDB/SQLite drivers, Redis client, SMTP, S3 signing, OpenTelemetry exporter, Markdown, WebSockets runtime) is maintained in the framework, on top of Crystal's standard library. No fragile dependency tree.
- **Type safety everywhere.** Routes, templates, model attributes and form requests are checked at compile time. Typos become compiler errors, not production incidents.
- **AI-native.** Every generated app ships with an `AGENTS.md`, a Claude skill and JSON output for tooling (`silth routes --json`). The docs you are reading are available as [`llms.txt`](/llms.txt).

## What's in the box

| Area | Features |
|---|---|
| HTTP | Radix router, middleware groups, controllers & filters, CSRF, CSP nonces, CORS, sessions, flash, signed URLs, SSE |
| Views | ECR templates with auto-escaping, layouts, partials, form builder, components, **live components** over WebSocket |
| Data | ORM, query builder, migrations, seeders, factories, pagination, PostgreSQL vectors & full-text search |
| Security | Authentication (sessions, API tokens, JWT, TOTP), policies & gates, rate limiting, encryption |
| Services | Cache, events, queues, scheduler, mail, notifications, storage (local & S3), i18n, HTTP client, workflows, Stripe billing |
| Observability | Profiler & debug toolbar, structured logs, OpenTelemetry traces and metrics |
| Tooling | `silth` CLI, generators, dev server with live reload, testing helpers, browser tests, OpenAPI docs |

## Philosophy

1. **Convention, then configuration.** Sensible defaults; YAML configuration with `when@env` overrides when you need control.
2. **Explicit beats magic.** Templates are rendered explicitly, mass assignment goes through `permit`, callbacks are plain methods you override.
3. **The compiler is your first reviewer.** Silth leans on macros to generate fast, type-checked code from small declarations.

Ready? [Install Silth](/docs/getting-started/installation) and build your first app in five minutes.
