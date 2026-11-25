# silth.dev: guide for AI coding agents

This repository is the Silth website and documentation, a Silth application. The framework is [silthhq/framework](https://github.com/silthhq/framework); its agent skills (`skills/silth`) describe the API.

- Documentation pages are Markdown files in `docs/`, ordered by `docs/_nav.yml`. Every page starts with front matter (`title`, `description`).
- Keep `docs/` in sync with the framework: a public API change there comes with a pull request here.
- `silth serve` renders the site with live reload; `bin/cli export -o dist` must keep working (CI builds it).
- Write docs in English, short and concrete: an example first, then the details.
