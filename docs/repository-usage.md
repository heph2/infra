# Repository usage

This repo is a flake-parts based infra flake. The root `flake.nix` only wires inputs and imports; host and shared behavior should live in smaller modules.

## Layout

- `hosts/<name>/configuration.nix`: declares the dendritic host (`infra.nixos.hosts.*` or `infra.darwin.hosts.*`) and composes modules.
- `hosts/<name>/default.nix`: host-local NixOS/nix-darwin settings.
- `modules/dendritic/`: builds `nixosConfigurations` and `darwinConfigurations` from the `infra.*.hosts` registry.
- `modules/nixos/`: shared NixOS modules registered as `infra.modules.nixos.<name>`.
- `modules/home/`: shared Home Manager modules registered as `infra.modules.homeManager.<name>`.
- `docs/`: operational notes like this file.

## Adding a NixOS service module

1. Add any required flake input in `flake.nix`.
2. Create a shared module in `modules/nixos/<name>.nix` that registers `infra.modules.nixos.<name>`.
3. Import it from `modules/nixos/default.nix`.
4. Add `config.infra.modules.nixos.<name>` to the target host's `modules` list.
5. Run the smallest checks first:

```bash
nixfmt --check flake.nix modules/nixos/<name>.nix hosts/<host>/configuration.nix
nix eval .#nixosConfigurations.<host>.config.systemd.services.<service>.description
```

For full validation before deployment:

```bash
nixos-rebuild build --flake .#<host>
```

## ComfyUI on Freya

Freya uses `modules/nixos/comfyui.nix`, which imports `utensils/comfyui-nix` and enables the NixOS service with ROCm for the AMD GPU.

Service basics:

```bash
sudo systemctl status comfyui
sudo systemctl restart comfyui
journalctl -u comfyui -f
```

ComfyUI listens on localhost only:

```text
http://127.0.0.1:8188
```

From another machine, tunnel it instead of opening the firewall:

```bash
ssh -L 8188:127.0.0.1:8188 freya
```

Data lives under `/var/lib/comfyui` by default:

```text
/var/lib/comfyui/models
/var/lib/comfyui/output
/var/lib/comfyui/input
/var/lib/comfyui/custom_nodes
```

The module enables ComfyUI Manager. Runtime custom node/python installs go into the service data directory, while the ComfyUI package itself remains in the Nix store.
