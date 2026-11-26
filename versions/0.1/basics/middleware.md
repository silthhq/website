---
title: Middleware
description: Global middleware, groups, aliases and writing your own.
---
# Middleware

A middleware receives the request context and a `chain`. Call `chain.next(ctx)` to continue, or respond to stop.

```crystal
class RequireAdmin < Silth::Middleware
  def call(ctx, chain)
    raise Silth::Forbidden.new unless ctx.auth_user.as?(User).try(&.admin?)
    chain.next(ctx)
  end
end
```

Middleware instances are shared between requests — keep them stateless.

## The stack

Global (every request): request id → telemetry → request logger → error handler → profiler → health check (`/up`) → maintenance → framework assets → live reload (dev) → live components & sockets → API docs → static files → method override → security headers → CORS.

Groups (after routing):

| Group | Middleware |
|---|---|
| `web` | session, CSRF, locale, session authentication |
| `api` | locale, bearer token authentication, rate limiting |

## Configuring

```crystal
Silth.configure do |app|
  app.middleware.use TimingHeader.new                       # global, at the end
  app.middleware.insert_before(Silth::StaticMiddleware, Maintenance.new)
  app.middleware_groups["web"] << TrackVisits.new
  app.alias_middleware("admin") { RequireAdmin.new }        # usable as :admin in routes
end
```

## Hooks on the response

Headers and cookies must be set before the body is written. Use `ctx.before_send { … }` for late headers and `ctx.filter_body { |body, type| … }` to transform buffered bodies (the profiler injects its toolbar this way).
