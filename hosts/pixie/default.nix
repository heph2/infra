{ inputs, config, ... }:
let
  nixos = config.flake.modules.nixos;
in
{
  flake.nixosConfigurations.pixie = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      nixos.allow-unfree
      ({ modulesPath, ... }: {
        imports = [
          (modulesPath + "/installer/scan/not-detected.nix")
          inputs.avf.nixosModules.avf
        ];
      })
      ({ pkgs, ... }: {
        nixpkgs.overlays = [
          (final: prev: {
            ttyd = prev.ttyd.overrideAttrs (old: { patches = [ ]; });
          })
        ];
      })
      ({ pkgs, ... }: {
        avf.defaultUser = "droid";
        services.openssh.enable = true;
        services.tailscale = {
          enable = true;
          extraSetFlags = [ "--ssh" ];
        };

        environment.systemPackages = with pkgs; [
          mg vim htop ncdu helix
        ];

        system.stateVersion = "25.11";
      })
    ];
  };
}
