# silth.dev

The Silth website (landing page in English and French) and the **documentation** (`docs/`), built with Silth itself. The framework lives in [silthhq/framework](https://github.com/silthhq/framework).

```bash
shards install
silth serve                       # http://localhost:3000, live reload on docs/ and src/
bin/cli export -o dist            # static site (what silth.dev serves)
```

| Path | Content |
|---|---|
| [`docs/`](docs) | Markdown documentation, `_nav.yml` for the order (also served as `/llms.txt` and `/llms-full.txt`) |
| `src/`, `config/`, `assets/` | the Silth app rendering the site |

To work on the framework and the docs together, point the shard at a local checkout with a `shard.override.yml` (git-ignored):

```yaml
dependencies:
  silth:
    path: ../framework
```

## License

MIT
