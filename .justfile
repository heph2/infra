list-nixos-hosts:
    nix eval .#nixosConfigurations --apply builtins.attrNames --json

list-darwin-hosts:
    nix eval .#darwinConfigurations --apply builtins.attrNames --json

build HOST:
    nix build --impure .#nixosConfigurations.{{HOST}}.config.system.build.toplevel

build-darwin HOST='aron':
    nix build --impure .#darwinConfigurations.{{HOST}}.system

deploy HOST:
    sudo nixos-rebuild --no-reexec --impure --flake .#{{HOST}} switch

deploy-remote HOST:
    nixos-rebuild --no-reexec --impure --target-host {{HOST}} --flake .#{{HOST}} switch

deploy-darwin HOST='aron':
    darwin-rebuild switch --flake '.#{{HOST}}'

deploy-build-remote HOST:
    nixos-rebuild --no-reexec --impure --target-host {{HOST}} --build-host {{HOST}} --flake .#{{HOST}} switch
