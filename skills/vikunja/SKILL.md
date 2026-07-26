---
name: vikunja
description: Interact with the Vikunja task server at vikunja.pochi.casa using vja. Use for listing, creating, updating, completing, organizing, or inspecting Vikunja tasks, projects, labels, and kanban buckets.
---

# Vikunja

Use the installed `vja` CLI. It is configured for `https://vikunja.pochi.casa`.

## Authentication

`vja` does not support the server's browser/OIDC login. It needs a Vikunja API token at `~/.config/vja/token.json`; never ask the user to paste the token into chat, print it, or put it in the repository/Nix configuration.

If authentication is missing, tell the user to create an API token in Vikunja's **Settings → API Tokens**, grant the permissions needed for tasks, projects, labels, users, and relations, then save it locally as:

```json
{"token":"..."}
```

## Read operations

Start with the smallest relevant query:

```bash
vja ls
vja show <task-id>
vja project ls
vja label ls
vja bucket ls --project-id=<project-id>
```

Use `--json` when structured output will make the answer more reliable.

## Changes

Only create, edit, complete, defer, or otherwise modify tasks when the user explicitly asks for that change. Inspect a task with `vja show <task-id>` before modifying an existing task. Confirm the target IDs and summarize what changed afterward.

Common commands:

```bash
vja add "Task title" --project=<project-id>
vja edit <task-id> --title="New title"
vja check <task-id>
vja defer <task-id> 1d
```

Do not use `vja logout` or delete data unless the user explicitly requests it.
