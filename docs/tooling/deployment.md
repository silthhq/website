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

Every app ships a multi-stage `Dockerfile` built on the official images: `ghcr.io/killidia/silth-builder` (Crystal on Alpine with the static libraries and the `silth` CLI) compiles static binaries, `ghcr.io/killidia/silth-runtime` (Alpine, CA certificates, time zones, an unprivileged `app` user, a `HEALTHCHECK` on `/up`) runs them. The result is a small image with `/app/bin/<app>` (web) and `/app/bin/cli` (migrations, workers, scheduler).

```bash
docker build -t blog .
docker run -p 3000:3000 -e APP_KEY=… -e DATABASE_URL=… blog
docker run blog /app/bin/cli queue:work
```

Use other base images with `--build-arg SILTH_BUILDER=… --build-arg SILTH_RUNTIME=…` (for instance `crystallang/crystal:1.22-alpine` with `sqlite-static`). The images are built from `docker/` in the Silth repository for amd64 and arm64.

## silth deploy

A ready-made deployment for servers that only run Docker and accept SSH: no agent, no orchestrator.

```bash
silth deploy:init          # writes config/deploy.yml
silth deploy               # build, push, roll out on every server
silth deploy --dry-run     # print the commands and the server scripts
silth deploy:status        # current version and containers per server
silth deploy:rollback 3f2a9c1e04bd
```

```yaml
# config/deploy.yml
image: ghcr.io/acme/blog
servers: [deploy@203.0.113.10, deploy@203.0.113.11]
domain: blog.example.com          # Caddy fronts the app with a Let's Encrypt certificate
env_file: .env.production         # uploaded to each server; keep it out of git
registry:
  server: ghcr.io
  username: ${REGISTRY_USERNAME:-}
  password: ${REGISTRY_PASSWORD:-}
workers: 2                        # queue:work containers
scheduler: true                   # one schedule:work container
volumes: [storage:/app/storage]
keep: 3                           # versions kept for rollbacks
```

What `silth deploy` does:

1. Builds the image tagged with the git commit (it refuses uncommitted changes unless `--allow-dirty`), logs into the registry (password on stdin) and pushes it.
2. On each server, over SSH: uploads the env file, pulls the image and, on the first server only, runs `bin/cli db:migrate`.
3. Starts the new web container next to the running one and waits for `GET /up` (`health_timeout`, 60 s). If it never answers, the new container is removed and the running version stays.
4. Points the shared Caddy container (`silth-proxy`, ports 80/443, one per server for every Silth app) to the new container and reloads it, then stops the old one with a 30 s grace period.
5. Replaces the worker and scheduler containers with the new image, and keeps the last `keep` versions for `deploy:rollback`.

Everything lives under `~/.silth/<app>` on the server (env file, Caddyfile, version history) and the containers carry `silth.app`, `silth.role` and `silth.version` labels. Rollbacks run a previous image again without migrations: keep migrations backward compatible (add columns first, remove them in a later deploy).

## Static sites

`silth export -o dist` renders every parameterless GET route (plus `export.paths`) to HTML and copies `public/` — the Silth website itself is built this way.

## Maintenance mode

`silth down --secret=letmein` returns 503 except for visitors who opened `?secret=letmein`; `silth up` brings the app back.
