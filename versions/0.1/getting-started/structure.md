---
title: Directory structure
description: Where things live in a Silth application.
---
# Directory structure

```
blog/
├── AGENTS.md              # instructions for AI coding agents (also CLAUDE.md)
├── .claude/skills/silth/  # Claude skill for this framework
├── assets/                # CSS, JS, images (served as-is in dev, fingerprinted in prod)
├── config/
│   ├── app.yml            # one YAML file per concern
│   ├── database.yml
│   ├── locales/           # i18n catalogs (en.yml, fr.yml…)
│   └── routes.cr          # routes (Crystal, type-checked)
├── db/
│   ├── migrations/        # versioned schema changes
│   ├── seeders/
│   └── seeds.cr           # DatabaseSeeder
├── public/                # static files
├── spec/                  # specs, factories
├── src/
│   ├── app.cr             # loads the application (order matters)
│   ├── server.cr          # HTTP entry point
│   ├── cli.cr             # CLI entry point (`silth <command>`)
│   ├── controllers/  models/  views/  components/
│   ├── jobs/  mails/  notifications/  events/  listeners/
│   ├── policies/  requests/  channels/  commands/  middleware/
└── shard.yml
```

## Entry points

- `src/server.cr` → `require "./app"` then `Silth.serve`.
- `src/cli.cr` → loads the app, migrations and seeders, then `Silth::CLI.run(ARGV)`. The global `silth` binary compiles it on demand into `bin/cli` (and rebuilds it when sources change).

## Load order

Crystal requires a superclass to be defined before its subclasses, so `src/app.cr` requires base classes (`ApplicationModel`, `ApplicationController`, `ApiController`) first and then every directory with `require "./models/**"`.
