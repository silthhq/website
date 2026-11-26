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
| `silth test` | `crystal spec` in the test environment |
| `silth g <generator> <Name> [fields]` | code generators |
| `silth routes [--json]` | list routes |
| `silth db:*` | create, drop, migrate, rollback, status, seed, reset, fresh, console |
| `silth queue:work`, `schedule:run`, `schedule:work` | workers |
| `silth assets:build`, `api:docs`, `workflow:dump`, `export` | build tasks |
| `silth key:generate`, `down`, `up`, `about` | operations |

## Generators

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
