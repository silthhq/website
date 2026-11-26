---
title: OpenTelemetry
description: Traces and metrics exported with OTLP/HTTP.
---
# OpenTelemetry

Set `OTEL_EXPORTER_OTLP_ENDPOINT` (or `config/telemetry.yml`) and Silth exports **traces** and **metrics** with OTLP/HTTP JSON to any collector: Jaeger, Grafana Tempo, Honeycomb, Datadog, SigNoz…

```yaml
# config/telemetry.yml
enabled: true
service_name: blog
endpoint: http://localhost:4318
sample_rate: 0.25
headers:
  x-honeycomb-team: ${HONEYCOMB_KEY}
```

## Automatic instrumentation

- A **server span** per request named after the route (`GET /posts/:id`) with HTTP semantic conventions; incoming `traceparent` headers are honored.
- **Client spans** for SQL queries (`db.system.name`, `db.query.text`).
- `traceparent` propagation on `Silth::HTTPClient` calls.
- **Consumer spans** for jobs.
- Logs carry `trace_id` / `span_id`.
- Metrics: `http.server.request.duration`, `db.client.operation.duration`, `http.client.request.duration` (histograms) and `silth.jobs` (counter).

## Custom spans and metrics

```crystal
Silth::Telemetry.trace("checkout.charge", attributes: {"order.id" => order.id.to_s}) do |span|
  span.add_event("payment.authorized")
  charge!
end

Silth::Telemetry.counter("orders.created").add(1, {"plan" => "pro"})
Silth::Telemetry.histogram("pdf.render.duration").record(0.42)
```

Try it locally: `docker run -p 16686:16686 -p 4318:4318 jaegertracing/all-in-one` then open `http://localhost:16686`.
