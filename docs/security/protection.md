---
title: Security features
description: CSRF, CSP, headers, rate limiting, encryption and signed URLs.
---
# Security features

## CSRF

Enabled for the `web` group. Two layers:

1. **Fetch metadata / Origin check** — cross-site unsafe requests are rejected.
2. **Synchronizer token** — forms include `csrf_field` (automatic with `form_with` and `button_to`); JavaScript sends the `X-CSRF-Token` header (`csrf_meta_tags`). Tokens are masked per render (BREACH mitigation).

Requests with `Authorization: Bearer` are exempt. Exclude webhooks in `config/security.yml` (`csrf_except: ["/webhooks/*"]`). An invalid token returns **419**.

## Headers & CSP

`X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Cross-Origin-Opener-Policy`, `Permissions-Policy` and HSTS (production) are set by default. The Content-Security-Policy in `config/security.yml` can use `{nonce}`; use `csp_nonce` for inline scripts (framework scripts already carry it).

## Rate limiting

```crystal
scope "/api/v1", middleware: [Silth::RateLimit::Middleware.new("api-v1", 60, 1.minute)] do … end

result = Silth::RateLimit.hit("export:#{user.id}", limit: 3, period: 1.hour)
raise Silth::TooManyRequests.new(result.retry_after) unless result.allowed?
```

Responses include `RateLimit-Limit`, `RateLimit-Remaining` and `RateLimit-Reset`. Counters live in the cache (use Redis when you run several servers).

## Encryption & signing

```crystal
Silth.encrypt("secret")  /  Silth.decrypt(token)          # AES-256-CBC + HMAC-SHA256
Silth.verifier("invites").generate(email, expires_in: 2.days)
Silth::SignedURL.sign("/downloads/42", expires_in: 10.minutes)   # verify with middleware [:signed]
Silth::Crypto.token / uuid7 / secure_compare / hash_password
```

## Other protections

- SQL is always parameterized; identifiers are quoted per dialect.
- Mass assignment requires `params.permit`.
- Templates escape output by default.
- Sessions are encrypted, `HttpOnly`, `SameSite=Lax` and `Secure` in production.
- Uploaded file paths are sanitized by the storage layer.
