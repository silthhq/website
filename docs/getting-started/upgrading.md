---
title: Releases & upgrading
description: Versions, the compatibility policy, deprecations and how to move an app to a new release.
---
# Releases & upgrading

```yaml
# shard.yml of an app
dependencies:
  silth:
    github: silthhq/framework
    version: ~> 0.1.0     # any 0.1.x release, never 0.2
```

```bash
shards update silth
SILTH_DEPRECATIONS=raise silth test
```

## Versions

Silth follows [semantic versioning](https://semver.org): `MAJOR.MINOR.PATCH`.

- Until 1.0, a **minor** release (`0.1` → `0.2`) may change public APIs. Its changelog says what to change in your app.
- A **patch** release (`0.1.0` → `0.1.1`) only fixes bugs: `~> 0.1.0` picks it up with `shards update`.
- From 1.0, breaking changes wait for the next major release.

The public API is what this documentation describes: classes, methods, macros, configuration keys, CLI commands and the files generators write. Anything marked `:nodoc:` can change in any release.

Supported versions: Crystal 1.22 and later, PostgreSQL 13+, MariaDB 10.6+, MySQL 8.0+, SQLite 3.35+. The latest minor version gets bug fixes, the previous one gets security fixes.

## Deprecations

A deprecated API keeps working for one minor version: deprecated in `0.2`, removed in `0.3`. Until then it warns:

- methods carry Crystal's `@[Deprecated]` annotation, so the compiler prints a warning where you call them;
- configuration keys and behaviors log a `silth.deprecation` warning, once per process.

`SILTH_DEPRECATIONS=raise` turns the runtime warnings into errors. Run your test suite with it before upgrading to the next minor version. Your own code can use the same helper:

```crystal
Silth.deprecated("billing.plans", instead: "config/plans.yml", removed_in: "2.0")
```

## What a release ships

Every `vX.Y.Z` tag of [silthhq/framework](https://github.com/silthhq/framework/releases) publishes:

| | |
|---|---|
| The `silth` CLI | Linux `x86_64` and `aarch64` (static), macOS `arm64` and `x86_64`, with `SHA256SUMS`; [installed](installation.md) by `silth.dev/install.sh` |
| Docker images | `ghcr.io/silthhq/builder` and `ghcr.io/silthhq/runtime`, tagged `X.Y.Z`, `X.Y` and `latest` (`edge` follows `main`) |
| Release notes | the matching section of [`CHANGELOG.md`](https://github.com/silthhq/framework/blob/main/CHANGELOG.md) |
| Documentation | frozen at `silth.dev/docs/X.Y/`; `/docs` shows the latest release and `/docs/edge` the `main` branch |

## Upgrading an app

1. Read the changelog of the new version, its "Upgrading" notes first.
2. Run your suite with `SILTH_DEPRECATIONS=raise` on the current version and fix the warnings.
3. Change the constraint in `shard.yml` (`~> 0.2.0`) and the image tags in the `Dockerfile` (`builder:0.2`, `runtime:0.2`).
4. `shards update silth`, install the matching CLI (`curl -fsSL https://silth.dev/install.sh | sh`), then `silth db:migrate` and `silth test`.

## Upgrading to 0.2

- `NUMERIC`/`DECIMAL` columns are read as `Decimal` and `DATE` columns as `Date`. Model columns typed `Float64` or `Time` keep working (values are converted); raw rows from `Silth::DB.query` hold the new types. Move money columns to `Decimal` ([Decimals & dates](../database/decimals-dates.md)).
- `JSON::Serializable` structs and hashes now write times with milliseconds, like models: `json_time_precision: 0` in `config/app.yml` keeps the previous format.
- Generators stop on an unknown field type: check scripts that call `silth g` with custom types.
- Optional: `workers:` in `config/server.yml`, `config/auth.yml` for Argon2id, `silth check` in your workflow.

## Following main

`silth new blog --edge` (or `branch: main` in `shard.yml`) tracks the development branch and the `edge` images. Its documentation is at [/docs/edge](/docs/edge/getting-started/introduction).
