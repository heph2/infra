---
type: host configuration
title: Fenrir Apple Silicon workstation
description: Fenrir's Apple Silicon, Niri, Home Manager, networking, hardware security, and kernel build CI composition.
tags: [fenrir, apple-silicon, niri, nixos]
---

# Fenrir Apple Silicon workstation

`hosts/fenrir/configuration.nix` registers the aarch64 Linux host and adds Apple Silicon, Niri, Emacs, stable package overlays, agenix, and Home Manager. Its `default.nix` owns the machine runtime: Apple peripheral firmware extraction, NetworkManager/iwd, Niri and greetd, PipeWire, hardware-security services, Docker, and a firewall with SSH only.

## Runtime and Home Manager

Fenrir enables Niri from `pkgs.niri-stable`; greetd launches `agreety --cmd niri`. It uses NetworkManager with iwd, a static IPv6 address/gateway on `wlan0`, resolved with DNS-over-TLS, and configured substitutes for Apple Silicon-related binaries. Hardware features include Bluetooth, smartcard/GPG/YubiKey agent support, USB muxing, and Apple peripheral firmware extraction. Home Manager composes the shared user, tools, terminal, editor, Git, shell, SSH, Firefox, and mail modules alongside host-specific `home.nix`.

Do not transplant x86 GPU or desktop assumptions from Freya: this host imports Apple Silicon support and uses aarch64 dependencies. Nix garbage collection is weekly and deletes paths older than seven days, so cache/substituter changes affect rebuild viability.

## Kernel CI

`.github/workflows/build-fenrir-kernel.yml` runs on ARM Ubuntu for manual dispatch and relevant `main` changes to flake files, Fenrir files, or itself. It evaluates the Fenrir kernel derivation, builds only `config.boot.kernelPackages.kernel`, reports closure metadata, and—when the GitHub secret is available—configures and checks the `heph2` Cachix cache. Concurrency cancels an older job on the same ref.

The workflow proves kernel derivation buildability, not full Fenrir system activation. Its cache authentication is CI secret material and is not part of repository documentation.

## Validation

For Fenrir kernel/platform work, first evaluate `.#nixosConfigurations.fenrir.config.boot.kernelPackages.kernel.drvPath`, then run the kernel build expression or `just build fenrir` for a broader system build. Hardware, wireless, graphics, and login changes require post-deploy device testing. Keep Apple-Silicon modules, flake locks, and CI path triggers aligned when changing kernel inputs.