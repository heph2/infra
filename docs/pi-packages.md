# Pi packages configured by this flake

`hosts/freya/home.nix` configures Pi through `programs.pi.coding-agent.settings.packages`.

## Enabled packages

- `pi-landstrip` — OS-level sandboxing for Pi shell/read/write/edit tools. Project defaults live in `.pi/sandbox.json`.
- `pi-web-access` — web search, URL fetching, PDFs, GitHub repo cloning, YouTube/video helpers.
- `pi-skillful` — skill invocation/visibility improvements.
- `@eko24ive/pi-ask` — `ask_user` clarification tool.
- `pi-subagents` and `@narumitw/pi-goal` were already enabled for delegation and goal tracking.

## Notes

Pi packages run with user permissions. Keep the sandbox default-deny-ish, audit package updates, and prefer temporary/session approvals over writing broad global allows.
