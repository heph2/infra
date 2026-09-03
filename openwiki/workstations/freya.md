---
type: host configuration
title: Freya workstation and GPU services
description: Freya's desktop, GPU, virtualization, backup, synchronization, Home Manager, and localhost-only ComfyUI composition.
tags: [freya, workstation, comfyui, nixos]
---

# Freya workstation and GPU services

`hosts/freya/configuration.nix` registers Freya as x86_64 Linux and composes its local system, Disko, agenix, Spicetify, trcc-gif, Handy, Home Manager, the `infra.modules.nixos.comfyui` shared module, and the common baseline. It imports Home Manager modules for the `heph` user plus `hosts/freya/home.nix`. The shared module registration and imports are described in [flake composition](../architecture/flake-composition.md).

## ComfyUI boundary

`modules/nixos/comfyui.nix` imports the external ComfyUI NixOS module, adds ROCm graphics support and Cachix configuration, enables ComfyUI Manager, selects `gpuSupport = "rocm"`, binds only `127.0.0.1:8188`, and keeps the firewall closed. It passes flags disabling xFormers and selecting PyTorch cross attention. This is a local GPU service: remote access should use the SSH tunnel documented in `docs/repository-usage.md`, not a firewall opening.

Runtime model/output/input/custom-node data lives below `/var/lib/comfyui`; that mutable state is separate from the Nix-built package. Manager-driven node or Python changes occur in that data directory and are not reproducible Nix inputs. When making package-level changes, update the module/flake input and build Freya. When changing state, plan backup and compatibility separately.

## Local system concerns

Freya configures COSMIC desktop, AMD graphics, Docker/libvirt, WireGuard key use, Borg backups to Sauron, Syncthing, DNS-over-TLS, YubiKey services, Bluetooth, and a substantial workstation package set. It also backs up the RB5009 through `services.plakar-routeros-backup`: the shared `infra.modules.nixos.plakar-routeros-backup` module is imported by `hosts/freya/configuration.nix`, while its Freya consumer selects both `export` and `backup` modes for a persistent weekly timer. The [RB5009 IPv6-only WireGuard runbook](../networking/rb5009-wireguard-ipv6.md) explains the separate router operation and tunnel checks. Treat the Plakar repository, SSH key path, and agenix-supplied passphrase as a host-side backup boundary, not RouterOS configuration.

It disables sleep targets and system firewall/Fail2ban despite importing the common module. The optional VFIO specialization is commented out; `hosts/freya/vfio.nix` must not be treated as active without restoring that specialization and confirming GPU PCI IDs.

Borg's enabled `home-heph` job runs hourly and excludes caches, build products, large media/model/game directories, and other transient data. Syncthing synchronizes named sensitive user folders across declared devices. These are stateful operations: changing a path or peer can cause replication/backup consequences beyond a Nix build.

## Validation

Run `nixfmt --check modules/nixos/comfyui.nix hosts/freya/configuration.nix hosts/freya/default.nix` for touched files, evaluate a specific service option, and run `just build freya`. For `plakar-routeros-backup` changes, include `modules/nixos/plakar-routeros-backup.nix` in the formatter check and consult `tests/plakar-routeros-backup.nix` for the service/timer contract. For ComfyUI, check `systemctl status comfyui` locally and use the documented SSH tunnel. Test GPU, virtualization, networking, or backup changes on the affected runtime surface after deployment; evaluation cannot prove hardware availability.