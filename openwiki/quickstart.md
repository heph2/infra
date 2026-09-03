---
type: wiki entrypoint
title: Infrastructure flake quickstart
description: Navigate and safely change the NixOS, nix-darwin, Home Manager, Terraform, and operational services managed by this repository.
tags: [nix, infrastructure, quickstart]
---

# Infrastructure flake quickstart

This repository is a `flake-parts` infrastructure flake for NixOS, nix-darwin, Home Manager, cloud provisioning, and self-hosted services. The root flake wires inputs and imports; the effective machine configuration is built from the dendritic registry. Start from [flake composition](architecture/flake-composition.md), then route to the owning runtime domain rather than editing by directory name alone.

## Map

- [Host estate](hosts/estate.md): all registered machines and composition conventions.
- Networking: [Fafnir router topology](networking/router-and-topology.md) and the operational [RB5009 IPv6-only WireGuard runbook](networking/rb5009-wireguard-ipv6.md).
- [Credentials](security/secrets-and-credentials.md): agenix/SOPS selection, recipients, runtime file injection, and Terraform decryption.
- Services: [edge and identity](services/edge-and-identity.md), [Hermes mail and agent](services/hermes-mail-and-agent.md), [Sauron media](services/sauron-media.md), [Tyr/Zima cluster and observability](services/cluster-and-observability.md).
- Workstations: [Freya](workstations/freya.md), [Fenrir](workstations/fenrir.md), [other clients](workstations/other-clients.md).
- [Terraform](infrastructure/terraform.md) and [packages/developer workflow](packages-and-developer-workflow.md).

## Task routing

| Change intent | Owning page | Primary source surfaces | Focused validation |
|---|---|---|---|
| Add/change an exported host or shared module | [Flake composition](architecture/flake-composition.md) | `flake.nix`, `modules/dendritic/default.nix`, host `configuration.nix` | `just list-nixos-hosts` or `just list-darwin-hosts`, then `just build <host>` |
| Change a service route, TLS, or OIDC hostname | [Edge and identity](services/edge-and-identity.md) | host `caddy.nix`, application module, Pocket-ID | affected host build, Caddy status, controlled request |
| Change mail or Hermes agent | [Hermes](services/hermes-mail-and-agent.md) | `hosts/hermes/mail.nix`, `hermes-agent.nix` | `just build hermes`, unit status |
| Change NAS/media/games/document service | [Sauron](services/sauron-media.md) | `hosts/sauron/default.nix`, `hosts/sauron/caddy.nix`; `systemd.tmpfiles.rules`, `services.sabnzbd` | `just build sauron`, then a controlled media-group path check |
| Change K3s, metrics, Actual, Signal/TURN exposure, or Tyr app | [Cluster and observability](services/cluster-and-observability.md) | `hosts/tyr/default.nix`, `hosts/zima/default.nix`; `services.k3s`, Tyr firewall rules | `just build tyr` or `just build zima`, then target/unit health |
| Change the reMarkable USB backup or shared USB Plakar behavior | [Freya](workstations/freya.md) | `hosts/freya/default.nix`, `modules/nixos/plakar-usb-backup.nix`; `services.plakar-usb-backup` | `just build freya`; inspect `plakar-remarkable-backup` and USB-trigger behavior |
| Change a secret or recipient | [Credentials](security/secrets-and-credentials.md) | `secrets/secrets.nix`, `.sops.yaml`, consumer declaration | build consumer and verify non-sensitive unit metadata |
| Change the Fafnir NixOS router design | [Fafnir router topology](networking/router-and-topology.md) | `hosts/fafnir/default.nix`, `flake.nix` | evaluate only after restoring export; console-backed network test |
| Change RB5009 WireGuard, IPv6 WAN filtering, peer routes, or endpoint DNS | [RB5009 IPv6-only WireGuard](networking/rb5009-wireguard-ipv6.md) | `docs/rb5009-wireguard-ipv6.md`; RouterOS `wg-road` and IPv6 firewall state | external IPv6 client handshake plus RouterOS peer/rule-counter inspection |
| Change cloud server/DNS | [Terraform](infrastructure/terraform.md) | `terraform/hetzner`, `terraform/cloudflare` | `terraform fmt -check`, reviewed plan |
| Change OpenWiki/package/dev tooling | [Packages and workflow](packages-and-developer-workflow.md) | `dev.nix`, `.justfile`, `pkgs/`, `modules/home/openwiki.nix` | formatter and narrow package/host build |

## Safe operating model

Use `nix develop` for the declared toolchain. Format only changed Nix files, evaluate/build the smallest affected host, and treat `just deploy*` as a privileged state transition—not validation. Secrets and local keys are deliberately not documentation inputs. Stateful services, storage layouts, network rules, cloud resources, and external identity registrations require a rollback/recovery plan beyond Nix evaluation.

## Backlog

- Fafnir is described but not exported: its flake import is commented out in `flake.nix`, so deployment validation is evidence-blocked until it is intentionally restored.
- Some legacy literal credentials and keys are present in source. This wiki does not reproduce them; migrating them to declared secret files is a security-hardening task anchored by the relevant host modules and [credentials](security/secrets-and-credentials.md).