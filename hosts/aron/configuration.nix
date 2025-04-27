{ pkgs, inputs, ... }: {
  flake.darwinConfigurations.aron = inputs.darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = { inherit inputs; };
    modules = [
      ./default.nix
      {
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [ inputs.emacs-overlay.overlay ];
      }
      #inputs.nur.nixosModules.nur
      inputs.home-manager.darwinModules.home-manager
      #inputs.spicetify-nix.nixosModules.default      
      {
        home-manager.backupFileExtension = "backup";
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.marco = import ./home.nix;
        home-manager.extraSpecialArgs = { inherit inputs; };
        home-manager.sharedModules = [
          #inputs.spicetify-nix.homeManagerModules.default
          #inputs.ghostty.homeModules.default
        ];
      }
    ];
  };
}
