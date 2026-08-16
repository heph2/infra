---
type: developer workflow
title: Packages, development shell, and deployment workflow
description: Developer shell tooling, Just build and deployment targets, custom packages, and narrow validation commands for this infrastructure flake.
tags: [nix, packages, deployment, workflow]
---

# Packages, development shell, and deployment workflow

`dev.nix` is imported by the root flake as a `perSystem` module. It provides `nixpkgs-fmt` as the formatter, exposes `packages.openwiki`, and creates the default development shell with SOPS/age tooling, `just`, and NixOS rebuild tooling. Start with `nix develop` (or direnv) before using the repository workflow. Its SOPS key environment references sensitive local material; do not inspect or export it.

## Just targets

| Intent | Narrow command | Notes |
|---|---|---|
| List exported Linux hosts | `just list-nixos-hosts` | Truth comes from evaluated `nixosConfigurations`. |
| List Darwin hosts | `just list-darwin-hosts` | Evaluated `darwinConfigurations`. |
| Build Linux host | `just build <host>` | Builds `config.system.build.toplevel` with `--impure`. |
| Build Darwin host | `just build-darwin aron` | Builds its Darwin system output. |
| Local Linux switch | `just deploy <host>` | Privileged, mutates the running machine. |
| Remote switch | `just deploy-remote <host>` | Targets the named host. |
| Remote build-and-switch | `just deploy-build-remote <host>` | Both build and target host are named host. |
| Darwin switch | `just deploy-darwin aron` | Mutates Aron. |

The generic Nix architecture and registry behavior are in [flake composition](architecture/flake-composition.md). A target can only work if its host is exported by `flake.nix`; Fafnir is deliberately not currently exported.

## Custom package surfaces

`pkgs/openwiki/package.nix` packages OpenWiki 0.3.1 with Node 22. It fetches the npm tarball, substitutes repository-maintained manifests/lockfiles, compiles native `better-sqlite3`, tolerates a peer-dependency conflict, removes build leftovers, and patches bundled-skill staging permissions. Its `update.sh` and `passthru.updateScript` support Nix updates. The Home Manager module `modules/home/openwiki.nix` installs it per user and offers provider/model/telemetry options; its state and credentials are intentionally user-local.

`pkgs/cc/package.nix` packages Claude Code with Node 20, copied lockfile, an authorized build setting, and an auto-updater-disabling wrapper. `pkgs/amused.nix`, `pkgs/mblaze-tui.nix`, Python helpers, and shell converters are standalone custom artifacts; no repository-wide runtime imports make them part of host composition unless a host references them.

## Validation ladder

Format the files changed with `nixfmt --check <paths>` (or the configured formatter). Evaluate the smallest option/output that captures the change, then run `just build <affected-host>`. Treat `just deploy*` as a separate operational step after review. Terraform and secret rotations have their own validation in [Terraform](infrastructure/terraform.md) and [credentials](security/secrets-and-credentials.md). There is no discovered conventional test suite; Nix evaluation/build and service-specific post-deploy checks are the focused evidence.