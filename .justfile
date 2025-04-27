deploy HOST:
    sudo nixos-rebuild --fast --impure --flake .#{{HOST}} switch

deploy-remote HOST:
    nixos-rebuild --fast --impure --target-host {{HOST}} --flake .#{{HOST}} switch

deploy-darwin:
    darwin-rebuild switch --flake '.#aron'

deploy-build-remote HOST:
    nixos-rebuild --fast --impure --target-host {{HOST}} --build-host {{HOST}} --flake .#{{HOST}} switch
