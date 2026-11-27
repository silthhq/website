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

## Files and binary bodies

`multipart:` sends `multipart/form-data`: fields and files, a name may repeat. `body:` takes a `String` or `Bytes`, and `response.bytes` returns a binary response:

```crystal
pdf = Silth::HTTPClient.new
  .base_url("http://gotenberg:3000")
  .post("/forms/chromium/convert/html", multipart: [
    {"files", Silth::HTTPClient::File.new("index.html", html, "text/html")},
    {"files", Silth::HTTPClient::File.new("logo.png", logo_bytes, "image/png")},
    {"paperWidth", "8.27"},
  ])
  .raise_for_status!
  .bytes

Silth::HTTPClient.new.post(url, body: xml.to_slice)   # raw body, set Content-Type with .header
```

A `Hash(String, String | HTTPClient::File)` works too when no name repeats.

## Faking in tests

```crystal
Silth::HTTPClient.fake({"api.github.com/*" => {200, %({"stargazers_count": 20000})}})
Silth::HTTPClient.fake("*/charges") { |req| Silth::HTTPClient::Response.new(402, "{}", HTTP::Headers.new, req.resource) }
Silth::HTTPClient.recorded.size.should eq(1)
```
