{ pkgs, inputs, ... }: {
  flake.nixosConfigurations.fenrir = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      {
        nixpkgs.overlays = [
          inputs.apple-silicon.overlays.default
          inputs.niri.overlays.niri
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
      inputs.apple-silicon.nixosModules.default
      inputs.niri.nixosModules.niri
      inputs.agenix.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.heph = import ./home.nix;
        home-manager.backupFileExtension = "backup";
        home-manager.extraSpecialArgs = {
          agenix = inputs.agenix;
          firefox-addons = inputs.firefox-addons;
        };
      }
      { nixpkgs.config.allowUnfree = true; }
      ../../modules/common/default.nix
      ({ modulesPath, ... }: {
        imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
      })
    ];
  };
}
