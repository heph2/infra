---
type: infrastructure estate
title: Host estate and composition
description: Inventory of exported hosts, their composition boundaries, active roles, and the local files that own each system.
tags: [nixos, darwin, hosts]
---

# Host estate and composition

The registry is built by [flake composition](../architecture/flake-composition.md). Host declarations establish the evaluated module list; their `default.nix` files own the durable configuration. Hardware scans and disk layouts are implementation inputs, not reusable service modules.

| Host | Platform | Role and primary owner | Composition notes |
|---|---|---|---|
| `freya` | x86_64-linux | workstation; `hosts/freya/default.nix` | Disko, agenix, Home Manager, ComfyUI, GPU and desktop configuration. |
| `fenrir` | aarch64-linux | Apple Silicon workstation; `hosts/fenrir/default.nix` | Apple Silicon, Niri, agenix and Home Manager. |
| `aron` | aarch64-darwin | macOS client; `hosts/aron/default.nix` | nix-darwin, Home Manager and Spicetify. |
| `timballo` | x86_64-linux | laptop; `hosts/timballo/default.nix` | Home Manager and local encrypted-disk/Hyprland settings. |
| `ushi` | x86_64-linux | WSL experiment; `hosts/ushi/default.nix` | NixOS-WSL and common baseline. |
| `pixie` | aarch64-linux | Android virtualization host; `hosts/pixie/default.nix` | NixOS AVF module. |
| `hermes` | x86_64-linux | VPS, mail and public cross-host proxy; `hosts/hermes/default.nix` | mailserver, agenix, Caddy, Hermes agent, common baseline. |
| `sauron` | x86_64-linux | NAS/media/identity and game host; `hosts/sauron/default.nix` | Disko, agenix, Minecraft integration, ZFS and Caddy. |
| `tyr` | x86_64-linux | K3s server and observability/app host; `hosts/tyr/default.nix` | agenix, Docker, Prometheus, Caddy-backed applications. |
| `zima` | x86_64-linux | K3s agent and budgeting host; `hosts/zima/default.nix` | agenix, Docker, PostgreSQL/Actual. |
| `fafnir` | not exported | router definition; `hosts/fafnir/default.nix` | Its flake import is commented out; see [network topology](../networking/router-and-topology.md). |

## Composition invariant

Ordering matters: imported host `default.nix`, integration modules, shared registry modules, and inline options are all merged by Nix module semantics. A module is active only when it is in that host's list; files with `enable = false` are evaluated but do not create an active service. When changing a host service, trace declaration → `default.nix` imports → dedicated module → generated service option.

Common baseline hosts receive SSH with password authentication disabled, Tailscale, Fail2ban, and Netdata from `modules/common/default.nix`. Freya deliberately force-disables Fail2ban because its firewall is disabled. This means shared defaults are host-specific only where the host includes that module and does not override it.

## Client and server navigation

* [Freya](../workstations/freya.md) owns the ROCm ComfyUI and high-powered desktop path.
* [Fenrir](../workstations/fenrir.md) owns Apple Silicon, Niri, and kernel CI.
* [Other clients](../workstations/other-clients.md) covers Aron, Timballo, Ushi, and Pixie.
* [Hermes mail and agent](../services/hermes-mail-and-agent.md), [Sauron media](../services/sauron-media.md), and [cluster and observability](../services/cluster-and-observability.md) decompose server-owned services.

Validate the host that consumes a change—not merely the shared module—with `just build <host>` after a targeted `nix eval` when possible.