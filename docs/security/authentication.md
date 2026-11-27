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

user.password = "correct horse battery staple"   # bcrypt or Argon2id, see below
user.authenticate?("guess")                       # false
```

## Password hashing

New passwords are hashed with bcrypt by default, or with Argon2id, the algorithm OWASP recommends:

```yaml
# config/auth.yml
password_algorithm: argon2id    # or bcrypt
bcrypt_cost: 12
argon2:
  memory: 19456                 # KiB: OWASP's 19 MiB, 2 iterations, 1 lane
  iterations: 2
  parallelism: 1
rehash_on_login: true
```

Both algorithms are always verified, whatever the setting: `$2a$`/`$2b$`/`$2y$` hashes as bcrypt, `$argon2id$v=19$…` (the PHC string format every implementation writes: Rust's `argon2`, PHP's `password_hash`, libsodium, Django) as Argon2. After a successful `auth.attempt`, a password stored with another algorithm or other settings is hashed again with the current ones. So an application can raise its cost, switch algorithms, or take over the users of another application without asking anyone to reset a password.

Argon2id is implemented in Crystal (with BLAKE2b), checked against RFC 9106 and OpenSSL: about 25 ms per hash with the default settings in a release build. Tests use the cheapest settings automatically.

```crystal
digest = Silth::Password.hash("secret")        # with the configured algorithm
Silth::Password.verify("secret", digest)       # bcrypt or Argon2
Silth::Password.needs_rehash?(digest)
Silth::Argon2.hash("secret", memory: 65536, iterations: 3, parallelism: 4)
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

Tokens are signed with HMAC: HS256 by default, HS384 or HS512 with `algorithm:` (or `jwt_algorithm: HS512` in `config/auth.yml`). `decode` accepts the three unless you narrow it, and never `none`:

```crystal
token = Silth::JWT.encode(claims, secret, algorithm: "HS512")
Silth::JWT.decode(token, secret, algorithms: ["HS512"])
```

Set `auth.jwt_secret` to let the token middleware accept JWTs: their `sub` claim names the user (`typ` the model, when there are several).

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
