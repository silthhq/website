---
title: Configuration
description: YAML configuration, environment variables and per-environment overrides.
---
# Configuration

Every file in `config/*.yml` becomes a top-level key named after the file: `config/mail.yml` is read with `Silth.config.string("mail.host")`.

```yaml
# config/app.yml
name: Blog
url: ${APP_URL:-http://localhost:3000}
debug: false
json_time_precision: 3          # fractional digits of times in JSON: 0, 3, 6, 9 or auto

when@development:
  debug: true
```

Other files of a new app: `server.yml` (`host`, `port`, `workers`), `database.yml`, `auth.yml` (password hashing, JWT, login throttling), `cache.yml`, `queue.yml`, `mail.yml`, `storage.yml`, `session.yml`, `security.yml`, `logging.yml`, `profiler.yml`, `telemetry.yml`. Every key has a default.

## Environment variables

| Syntax | Meaning |
|---|---|
| `${VAR}` | value of `VAR` (empty when missing) |
| `${VAR:-default}` | value or default |
| `${VAR:?message}` | fail at boot when missing |

`.env`, `.env.local`, `.env.<env>` and `.env.<env>.local` are loaded automatically (real environment variables always win). The environment comes from `SILTH_ENV` (or `APP_ENV`), default `development`.

## `when@<env>` blocks

Blocks named `when@production`, `when@test`… are deep-merged when the environment matches. Several environments: `when@staging,production:`.

## Reading values

```crystal
config = Silth.config
config.string("app.name")               # raises when missing
config.string?("app.tagline")           # String?
config.string("app.locale", "en")       # with default
config.int("server.port", 3000)
config.bool("app.debug")
config.array("cors.origins")            # YAML list or comma separated string
config.hash("i18n.fallbacks")

struct MailSettings
  include YAML::Serializable
  getter host : String
  getter port : Int32
end
settings = config.bind("mail", MailSettings)
```

In tests, override values with `Silth.config.set("app.debug", true)`.

## The application key

`APP_KEY` (base64, 32 bytes) encrypts sessions and cookies and signs URLs. Generate one with `silth key:generate`. Silth refuses to boot in production without it.
