# NixOs Configuration

This repository contains NixOS configurations for my machines, managed using Nix Flakes.
It is structured to manage multiple machines and user configurations.

## Structure

- `flake.nix`: Flake entrypoint
- `hosts`: NixOs configurations for each machine
- `modules`: Reausable specific modules
- `terraform`: Terraform code for cloud based machine setup
- `secrets`: Sops-nix and age directory
- `pkgs`: Custom packages and scripts

## Hosts

- `Fafnir`: Router
- `Freya`: Desktop
- `Hermes`: Hetzner VPS (Currently used as a mail server)
- `Timballo`: Thinkpad t480
- `Tyr`: Intel Nuc (Currently not used)
- `Ushi`: WSL Experiment (Currently not used)
- `Zima`: Zimaboard
- `Sauron`: NAS
- `Aron`: Macbook Pro

## Usage

You can easily drop inside a shell with all the stuff needed using `nix develop` or `direnv allow` if using `direnv`. From there you just need the `age` private key and `ssh` keys, and you can deploy directly using:

```
just deploy <name_of_host`
```

Or using:

```
just deploy-remote <name_of_host`
```

For Darwin:

```
just deploy-darwin
```

This will build the closure using `--build-host` and `--target-host` for avoiding cross-compiling issues.
