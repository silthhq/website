---
title: Installation
description: Install Crystal and the silth CLI, then create an application.
---
# Installation

## Requirements

- **Crystal 1.22+** (`brew install crystal` on macOS, see [crystal-lang.org/install](https://crystal-lang.org/install) elsewhere)
- **libsqlite3** (preinstalled on macOS and most Linux distributions)
- Optional: PostgreSQL 14+ (with `pgvector` for vector search), MariaDB 10.6+/MySQL 8, Redis

## Install the CLI

```bash
git clone https://github.com/silthhq/framework.git
cd framework
shards build silth --release
sudo cp bin/silth /usr/local/bin/
silth version
```

## Create an application

```bash
silth new blog                 # SQLite by default
silth new shop --db=postgres   # or --db=mysql
cd blog
shards install
silth db:migrate
silth serve
```

Open `http://localhost:3000`. The development profiler lives at `/_silth/profiler` and the API reference at `/docs/api`.

> [!TIP]
> Working on the framework itself? Point the app to your checkout with `silth new blog --path-to-silth=../framework`.

## Editor setup

Install the Crystal extension for your editor (VS Code: *Crystal Language*). Templates use the `.html.ecr` extension — associate it with HTML/ERB highlighting.
