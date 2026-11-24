---
title: Deployment
description: Build a release binary, configure production and ship with Docker.
---
# Deployment

```bash
silth build                       # shards build --release + assets:build
SILTH_ENV=production bin/cli db:migrate
SILTH_ENV=production bin/<app>    # listens on $PORT (0.0.0.0 in production)
```

Checklist:

- `APP_KEY` set (`silth key:generate --show`), `APP_URL` correct.
- `SILTH_ENV=production`: JSON logs, HSTS, secure cookies, profiler off.
- Database migrated; queue workers (`bin/cli queue:work`) and scheduler (`bin/cli schedule:work`) running.
- A reverse proxy (Caddy, nginx) terminating TLS and forwarding `X-Forwarded-Proto`/`X-Forwarded-For`.
- Health check: `GET /up` (add checks with `Silth.health_check("redis") { Silth::Redis.new.ping }`).
- Zero-downtime restarts: `server.reuse_port: true` lets a new process bind before the old one exits.

## Docker

Every app ships a multi-stage `Dockerfile` producing a small Alpine image with static binaries:

```bash
docker build -t blog .
docker run -p 3000:3000 -e APP_KEY=… -e DATABASE_URL=… blog
```

## Static sites

`silth export -o dist` renders every parameterless GET route (plus `export.paths`) to HTML and copies `public/` — the Silth website itself is built this way.

## Maintenance mode

`silth down --secret=letmein` returns 503 except for visitors who opened `?secret=letmein`; `silth up` brings the app back.
