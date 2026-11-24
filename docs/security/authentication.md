---
title: Authentication
description: Sessions, remember me, API tokens, JWT, password resets and two-factor.
---
# Authentication

```bash
silth g auth && silth db:migrate
```

The generator creates a `User` model, login/registration/password-reset controllers and views, a password reset mail and the routes.

## The user model

```crystal
class User < ApplicationModel
  include Silth::Auth::Authenticatable
  primary_key
  column email : String
  column password_digest : String, hidden: true
end

user.password = "correct horse battery staple"   # bcrypt
user.authenticate?("guess")                       # false
```

## Session guard

```crystal
auth.attempt(params["email"]?, params["password"]?, remember: true)  # rate limited: 5 tries/minute
auth.login(user)          # regenerates the session id and the CSRF token
auth.logout
auth.user                 # Silth::Auth::Authenticatable?
ctx.auth_user.as?(User)
```

Changing a password invalidates other sessions and remember-me cookies (they carry a password fingerprint).

## Protecting routes

```crystal
scope middleware: [:auth] do … end            # redirect to /login (401 for JSON)
scope middleware: [:guest] do … end           # login/register pages
scope middleware: [:auth, :verified] do … end # requires email_verified_at
```

In controllers: `before_action :authenticate!`.

## API tokens

```crystal
token = user.create_token("cli", abilities: ["posts:read", "posts:write"], expires_in: 30.days)
# => "12|Zl9…" — shown once, only a SHA-256 hash is stored
```

Clients send `Authorization: Bearer <token>`. In the `api` group the user is resolved automatically; check abilities with `ctx.auth_token.try(&.can?("posts:write"))`. Wildcards like `posts:*` are supported.

## JWT

```crystal
token = Silth::JWT.encode({"sub" => user.auth_id, "typ" => "User"}, secret, expires_in: 15.minutes)
claims = Silth::JWT.decode(token, secret)    # verifies signature, exp and nbf
```

Set `auth.jwt_secret` to let the token middleware accept JWTs.

## Password resets & email verification

Stateless and signed — no tables needed:

```crystal
token = Silth::Auth.password_reset_token(user)          # expires in 1 hour, single use
user = Silth::Auth.verify_password_reset(token)
url = Silth::Auth.verification_url(user)                # signed, expiring link
```

## Two-factor authentication (TOTP)

```crystal
secret = Silth::Auth::TOTP.generate_secret
uri = Silth::Auth::TOTP.provisioning_uri(secret, user.email, "Blog")   # render as a QR code
Silth::Auth::TOTP.verify(secret, params["code"])
```

## Events

`Silth::Auth::LoggedIn`, `LoggedOut` and `LoginFailed` are dispatched on the event bus.
