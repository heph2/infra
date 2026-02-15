{ pkgs, inputs, ... }:
{
  flake.nixosConfigurations.freya = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      {
        nixpkgs.overlays = [
          inputs.emacs-overlay.overlay
          (final: prev: {
            stable = import inputs.stable-nixpkgs {
              system = prev.system;
              config.allowUnfree = true;
            };
          })
        ];
      }
      ./default.nix
      inputs.agenix.nixosModules.default
      inputs.spicetify-nix.nixosModules.default
      inputs.trcc_gif.nixosModules.trcc-gif
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.heph = import ./home.nix;
        home-manager.backupFileExtension = "backup";
        home-manager.extraSpecialArgs = {
          agenix = inputs.agenix;
          stardew-modding = inputs.stardew-modding;
        };

      }
      { nixpkgs.config.allowUnfree = true; }
      ../../modules/common/default.nix
      (
        { modulesPath, ... }:
        {
          imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
        }
      )
    ];
  };
}
