---
title: Errors & logging
description: Exception handling, debug pages and structured logs.
---
# Errors & logging

## HTTP errors

Raise anywhere during a request:

```crystal
raise Silth::NotFound.new
raise Silth::Forbidden.new("Members only")
raise Silth::UnprocessableEntity.new("Invalid", {"email" => ["is taken"]})
raise Silth::TooManyRequests.new(retry_after: 30)
```

`Silth::ORM::RecordNotFound` becomes a 404 and `RecordInvalid` a 422.

- **Development** (`app.debug: true`): a dark debug page with the source excerpt, backtrace, params, headers and session.
- **Production**: a clean error page.
- **API clients** (`Accept: application/json`): RFC 9457 `application/problem+json`.

Customize rendering:

```crystal
Silth.configure do |app|
  app.error_renderer = ->(ctx : Silth::Context, ex : Exception, status : Int32) do
    return false unless status == 404
    ctx.html(MyNotFoundPage.new.render, 404)
    true
  end
end
```

## Reporting

```crystal
Silth::ErrorReporter.on_report { |ex, ctx| Sentry.capture(ex) }
```

## Logging

Silth uses Crystal's `Log`. Pretty colored lines in development, JSON lines in production (`config/logging.yml`). Every line carries the `request_id` (and `trace_id` when telemetry is on).

```crystal
Log = ::Log.for("billing")
Log.info &.emit("Invoice paid", invoice_id: invoice.id, amount: invoice.total)
```

```yaml
# config/logging.yml
level: debug
format: pretty   # pretty | json
file: log/app.log
postgres:        # also write to the UNLOGGED table silth_logs (batched, background fiber)
  connection: primary
  level: warn
  retention_days: 14
```
