deploy HOST:
    sudo nixos-rebuild --fast --impure --flake .#{{HOST}} switch

deploy-remote HOST:
    nixos-rebuild --fast --impure --target-host {{HOST}} --flake .#{{HOST}} switch
