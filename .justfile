deploy HOST:
    sudo nixos-rebuild --no-reexec --impure --flake .#{{HOST}} switch

deploy-remote HOST:
    nixos-rebuild --no-reexec --impure --target-host {{HOST}} --flake .#{{HOST}} switch

deploy-darwin:
    darwin-rebuild switch --flake '.#aron'

deploy-build-remote HOST:
    nixos-rebuild --no-reexec --impure --target-host {{HOST}} --build-host {{HOST}} --flake .#{{HOST}} switch
