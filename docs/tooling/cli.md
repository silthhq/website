---
title: CLI & generators
description: The silth command, generators and custom commands.
---
# CLI & generators

The global `silth` binary handles framework tasks and forwards everything else to your application CLI (`src/cli.cr`, compiled on demand into `bin/cli`).

| Command | Purpose |
|---|---|
| `silth new <name> [--db=postgres]` | create an application |
| `silth serve` | dev server: rebuild on change, restart, live reload |
| `silth build` | release binaries + fingerprinted assets |
| `silth check [--spec]` | type-check the app without building it (a few seconds) |
| `silth test` | `crystal spec` in the test environment |
| `silth g <generator> <Name> [fields]` | code generators |
| `silth routes [--json]` | list routes |
| `silth db:*` | create, drop, migrate, rollback, status, seed, reset, fresh, console |
| `silth queue:work`, `schedule:run`, `schedule:work` | workers |
| `silth assets:build`, `api:docs`, `workflow:dump`, `export` | build tasks |
| `silth key:generate`, `down`, `up`, `about` | operations |

## Type checking

```bash
silth check              # every target of shard.yml (server and src/cli.cr), as one program
silth check --spec       # the specs too
silth check src/app.cr   # given files
```

`silth check` runs the compiler's semantic analysis without generating code: type errors, wrong arguments and template mistakes show up in about half the time of a build. Run it after each change; it is what agents should use between edits.

## Generators

Field types: `string`, `text`, `citext`, `email`, `url`, `uuid`, `integer` (`int`, `int32`), `bigint` (`int64`), `smallint`, `float` (`float64`), `decimal` (`numeric`, `money`; `price:decimal:12,4` sets precision and scale) → `Decimal`, `boolean`, `timestamp` (`datetime`) → `Time`, `date` → `Date`, `time`, `json`, `vector:1536`, `references`. Append `?` for a nullable column (quote it in shells: `'body:text?'`). An unknown type stops the generator.

`scaffold` (model, migration, controller, views, policy, factory, spec, route), `api` (model + JSON controller + form request + OpenAPI annotations), `model`, `migration` (`create_x`, `add_y_to_x`), `controller`, `component`, `live`, `job`, `mail`, `notification`, `event`, `listener`, `policy`, `factory`, `request`, `command`, `middleware`, `channel`, `seeder`, `auth`, `billing`, `notifications`, `workflow`.

Field syntax: `name:type`, nullable with `?` (`'body:text?'`), `user:references`, `embedding:vector:1536`. Types: `string text integer bigint float decimal bool datetime date json uuid email url references vector`.

## Custom commands

```crystal
class ReportCommand < Silth::Command
  command "report:send", "Email the weekly report"
  argument recipient : String, "Email address"
  option weeks : Int32 = 1, "Number of weeks", short: "w"
  option dry_run : Bool = false, "Print instead of sending"

  def run : Nil
    info "Building #{weeks} week(s) report for #{recipient}"
    table(["Metric", "Value"], [["Signups", "42"]])
    success "Sent" unless dry_run
  end
end
```

```bash
silth report:send ada@example.com -w 4 --dry-run
silth help report:send
```

Helpers: `info`, `success`, `warn`, `error`, `comment`, `table`, `ask`, `confirm?`, `choose`, `progress`.

## Configuration

```yaml
# config/cli.yml
aliases:
  m: db:migrate
  deploy-check: about
```

Unknown commands get a "did you mean…" suggestion. Errors print cleanly; `SILTH_TRACE=1` shows the backtrace.
