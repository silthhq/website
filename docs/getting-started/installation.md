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
curl -fsSL https://silth.dev/install.sh | sh
silth version
```

The script downloads the latest release for Linux (`x86_64`, `aarch64`, static binaries) or macOS (`arm64`, `x86_64`), checks it against the release's `SHA256SUMS` and installs it in `~/.silth/bin`. It reads a few variables:

| Variable | Default | |
|---|---|---|
| `SILTH_VERSION` | latest release | a version to install, like `0.1.0` |
| `SILTH_INSTALL_DIR` | `~/.silth/bin` | where to put the binary |
| `SILTH_DOWNLOAD_URL` | GitHub releases | a mirror of the release files |

The archives and `SHA256SUMS` are also on the [releases page](https://github.com/silthhq/framework/releases). To build the CLI from source instead:

```bash
git clone https://github.com/silthhq/framework.git
cd framework
shards build silth --release
sudo cp bin/silth /usr/local/bin/
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

A new app depends on the release line of your CLI (`version: ~> 0.1.0` in `shard.yml`, Docker images tagged `0.1`). `silth new blog --edge` follows the framework's `main` branch instead. See [Releases & upgrading](upgrading.md).

> [!TIP]
> Working on the framework itself? Point the app to your checkout with `silth new blog --path-to-silth=../framework`.

## Editor setup

Install the Crystal extension for your editor (VS Code: *Crystal Language*). Templates use the `.html.ecr` extension — associate it with HTML/ERB highlighting.
