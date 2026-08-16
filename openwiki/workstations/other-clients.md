---
type: host configuration
title: Other client and virtualization hosts
description: Aron nix-darwin, Timballo laptop, Ushi NixOS-WSL, and Pixie Android virtualization host ownership and platform boundaries.
tags: [workstations, darwin, wsl, virtualization]
---

# Other client and virtualization hosts

These hosts are registered in the same [dendritic registry](../architecture/flake-composition.md) but have distinct operating-system boundaries.

## Aron: nix-darwin

`hosts/aron/configuration.nix` registers `aarch64-darwin`, imports its local `default.nix`, the Darwin Home Manager bridge, Spicetify, and a small Home Manager set for user `marco`. The system enables distributed builds but sets `nix.enable = false` for the Determinate installer boundary; treat Nix daemon behavior as installer-owned. `default.nix` manages system packages, PostgreSQL/Emacs, dnsmasq, Touch ID sudo, and a post-activation `networksetup` command that assigns IPv6 to Wi-Fi. Build with `just build-darwin aron`; switch only with `just deploy-darwin aron`. Networking activation scripts are host-state changes and need a local recovery route.

## Timballo: laptop

Timballo is x86_64 NixOS with Home Manager and the common baseline. Its local system config uses GRUB with LUKS, wireless, greetd launching Hyprland, PipeWire, and an enabled firewall allowing SSH. The stored wireless configuration is sensitive; do not reproduce or rotate it through this documentation. Validate with `just build timballo`; disk/boot changes must be tested with physical-console recovery available.

## Ushi: NixOS-WSL

Ushi imports `inputs.nixos-wsl.nixosModules.wsl`, enables WSL, sets default user `nixos`, and configures SSH on port 2222. It also takes the common baseline. It is an experimental environment, so Linux host/network assumptions do not automatically apply; use `just build ushi` before a WSL-specific switch.

## Pixie: Android Virtualization Framework

Pixie is aarch64 NixOS and imports `inputs.avf.nixosModules.avf` in an inline module. Its local `default.nix` sets AVF user `droid`, enables SSH and Tailscale SSH, and provides basic troubleshooting tools. Its registration applies a `ttyd` overlay. Evaluate/build it as `pixie`; platform availability and guest runtime behavior are external to normal Nix configuration evaluation.

All client user configuration is sourced through `modules/home` only where that host imports the Home Manager bridge. See [Freya](freya.md) and [Fenrir](fenrir.md) for fuller Linux Home Manager composition.