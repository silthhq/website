---
title: AI-assisted development
description: AGENTS.md, Claude skills, llms.txt and machine-readable tooling.
---
# AI-assisted development

Crystal is a great language for working with coding agents: the compiler catches mistakes immediately and the code stays readable for human review. Silth goes further.

## Every app is agent-ready

`silth new` generates:

- **`AGENTS.md`** — commands, layout, conventions and testing patterns for any agent (Codex, Cursor, Copilot…).
- **`CLAUDE.md`** — imports `AGENTS.md` for Claude Code.
- **`.claude/skills/silth/`** — a Claude skill with the Silth cheat sheet.

## Machine-readable output

- `silth routes --json` — every route, name, handler and middleware.
- Errors print the exact file and line; the dev error page includes the source excerpt.
- `/docs/api/openapi.json` — the API contract.

## Documentation for LLMs

- [`/llms.txt`](/llms.txt) — an index of every documentation page with a one-line description.
- [`/llms-full.txt`](/llms-full.txt) — the full documentation in one Markdown file.
- Every page is available as raw Markdown: append `.md` to its URL.

## Tips for prompting

- Ask the agent to run `crystal tool format` and `silth test` before finishing.
- Prefer generators (`silth g scaffold …`) and let the agent refine the generated code.
- Point it to the relevant docs page (`/docs/database/models.md`) for focused context.
