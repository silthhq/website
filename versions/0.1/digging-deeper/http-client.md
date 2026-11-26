---
title: HTTP client
description: Fluent outgoing requests with retries, tracing and fakes.
---
# HTTP client

```crystal
response = Silth::HTTPClient.new
  .base_url("https://api.github.com")
  .bearer(ENV["GITHUB_TOKEN"])
  .accept_json
  .timeout(5.seconds)
  .retry(3)
  .get("/repos/crystal-lang/crystal")

response.ok?                       # 2xx
response.json["stargazers_count"]
response.parse(Repo)               # JSON::Serializable
response.raise_for_status!

Silth::HTTPClient.post("https://hooks.example.com", json: {event: "deploy"})
```

Outgoing calls carry the `traceparent` header when telemetry is enabled and appear in the profiler.

## Faking in tests

```crystal
Silth::HTTPClient.fake({"api.github.com/*" => {200, %({"stargazers_count": 20000})}})
Silth::HTTPClient.fake("*/charges") { |req| Silth::HTTPClient::Response.new(402, "{}", HTTP::Headers.new, req.resource) }
Silth::HTTPClient.recorded.size.should eq(1)
```
