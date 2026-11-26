# silth.dev

The Silth website (landing page in English and French) and the **documentation** (`docs/`), built with Silth itself. The framework lives in [silthhq/framework](https://github.com/silthhq/framework).

```bash
shards install
silth serve                       # http://localhost:3000, live reload on docs/ and src/
bin/cli export -o dist            # static site (what silth.dev serves)
```

| Path | Content |
|---|---|
| [`docs/`](docs) | Markdown documentation of the framework's `main` branch, `_nav.yml` for the order (served at `/docs/edge`, and at `/docs` before the first frozen release) |
| `versions/X.Y/` | frozen documentation of each release: the newest one is served at `/docs` (also `/llms.txt`), the others at `/docs/X.Y` |
| `src/`, `config/`, `assets/` | the Silth app rendering the site |

When the framework tags a release `vX.Y.0`, freeze its documentation:

```bash
bin/cli docs:release X.Y          # copies docs/ to versions/X.Y/
```

A fix to a released page goes to both `docs/` and `versions/X.Y/`. `/install.sh` serves the framework's `scripts/install.sh` (read from the `silth` shard at compile time).

To work on the framework and the docs together, point the shard at a local checkout with a `shard.override.yml` (git-ignored):

```yaml
dependencies:
  silth:
    path: ../framework
```

## License

MIT
