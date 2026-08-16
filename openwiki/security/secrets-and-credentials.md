---
type: security lifecycle
title: Secrets and credential lifecycle
description: The separation between agenix and SOPS, recipient ownership, runtime secret injection, Terraform decryption, and safe rotation practices.
tags: [security, secrets, sops, agenix]
---

# Secrets and credential lifecycle

This repository has two encrypted-secret mechanisms. Secret plaintext is intentionally out of scope; only declarations, recipients, and consumption behavior are documented.

| Mechanism | Canonical control | Consumers | Contract |
|---|---|---|---|
| agenix age files | `secrets/secrets.nix` | NixOS modules through `age.secrets` | Per-file SSH recipients; module materializes a root or service-owned runtime file. |
| SOPS structured files | `.sops.yaml` | Terraform `data.sops_file` and host SOPS use | YAML/JSON/env/ini creation rules encrypt to listed age recipients. |

## agenix lifecycle

`secrets/secrets.nix` is the recipient access matrix. Each `*.age` filename maps to public recipients; changing recipients is an access-control change and requires re-encrypting that file. A host normally sets `age.identityPaths` to an SSH private key it can read, declares `age.secrets.<name>.file`, and passes `config.age.secrets.<name>.path` to a service.

The consuming declaration must specify the runtime principal where the service cannot read a root-only file: `owner`, `group`, and `mode` are part of the service interface. The matrix names user and host SSH recipients (including `heph`, `freya`, `zima`, `sauron`, `tyr`, and `hermes`) per encrypted filename. For example, the Cloudflare Caddy token is authorized to all six host/user entries; the Pocket-ID encryption key is authorized to `heph`, `freya`, and `sauron`; and a new Tyr-only relying-party secret must include a recipient that Tyr can decrypt. These names are access metadata, not secret data.

Three declared consumption patterns must not be conflated: (1) Paperless declares a service-owned file (`paperless:paperless`, mode `640`) as `services.paperless.environmentFile`; (2) Actual disables `DynamicUser`, creates the `actual` system user/home, sets its secret file owner/group/mode, and references its generated path in `openId.client_secret._secret`; (3) Hermes's `mailgun-sasl-passwd` oneshot reads an agenix file to generate `/var/lib/postfix/sasl_passwd`, then Postfix requires that unit. A systemd `EnvironmentFile` or a service-specific `environmentFile(s)` is a dependency edge: the unit must see the path only after agenix has materialized it.

**Known path defect.** `hosts/tyr/homebox.nix` declares `homebox_oidc_secret.path = "/run/agenix/homebox-oidc.env"` but configures Homebox with `/run/agenix/homebox_oidc_secret`. That filename mismatch can make systemd fail to load the OIDC environment and prevent the relying party from starting/authenticating. Align the two paths before assuming the secret is delivered. See [edge and identity](../services/edge-and-identity.md) and [mail and agent](../services/hermes-mail-and-agent.md).

## SOPS and Terraform

`.sops.yaml` applies age key groups to structured secret files. Both Terraform roots declare `data "sops_file" "terraform_secrets"` over `../../secrets/secrets.yaml`; `terraform/hetzner/provider.tf` reads the Hetzner token and `terraform/cloudflare/provider.tf` reads the Cloudflare API token. Their S3 backends are configured externally. The SOPS recipient set must allow the operator running Terraform to decrypt without placing plaintext in source or plans.

## Rotation and safe changes

1. Decide whether the value belongs in a per-file agenix secret or a structured SOPS secret; preserve the existing consumer mechanism unless changing the consumer too.
2. Update recipient access before distributing a changed secret, then encrypt with the intended recipients. Do not copy encrypted contents into documentation or logs.
3. Keep filename, key name, owner/group/mode, and injection path synchronized with consumers. A mismatch is usually a runtime permission or missing-environment failure.
4. For a service credential, build the consuming host, deploy it, and inspect only unit status/log metadata—not secret values. For Terraform, run `terraform fmt -check` and an appropriately authenticated `terraform plan` in the relevant root.

`dev.nix` supplies `sops`, `age`, `ragenix`, and `ssh-to-age`; its shell hook points `SOPS_AGE_KEY_FILE` at a repository-local key path. That path is operationally sensitive and must not be read or documented further.