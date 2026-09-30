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
