---
name: nixos-host-workflow
description: Use when editing NixOS or nix-darwin host configurations in this infra repo, including host modules, service files, Home Manager snippets, secrets wiring, build checks, or deploy commands.
---

# NixOS host workflow

Use this skill for changes under `hosts/`, `modules/`, `pkgs/`, `secrets/`, and related Home Manager configuration.

## Repo model

- `flake.nix` is the entry point for NixOS, nix-darwin, Home Manager, inputs, and deploy targets.
- Host-specific configuration lives under `hosts/<host>/`; shared code belongs in `modules/` or `pkgs/`.
- Secrets are declared in `secrets/` and wired through agenix/sops-style modules; encrypted payloads stay encrypted.

## Before editing

- Inspect the target host entry point and any imported modules before changing options.
- Check for existing patterns in neighboring hosts/modules and reuse them where possible.
- Keep host-local choices in the host file; move reusable behavior to shared modules only when it is clearly shared.

## Editing conventions

- Make small, explicit Nix changes and preserve existing option style.
- Prefer package references from `pkgs` or flake `inputs` already in scope.
- Format touched Nix files with the repo formatter (`nixfmt`, `nix fmt`, or the configured formatter).

## Secrets safety

- Do not print, decrypt, copy, or commit secret plaintext.
- Only edit encrypted secret files or secret wiring when explicitly requested.
- Never add private keys, tokens, `.env` values, or host-only credentials to Nix files.

## Validation

- For syntax/format checks, run `nixfmt --check <file>` or `nix fmt -- --check <file>` when available.
- For host changes, prefer targeted builds/checks such as `nix flake check`, `nixos-rebuild build --flake .#<host>`, or the host's documented build command.
- Report exactly which validation commands ran and any skipped checks.

## Deployment safety

- Do not deploy, switch, reboot, or run destructive commands unless the user explicitly asks.
- For deploy requests, show the target host and command first, then verify the command matches the requested host.
