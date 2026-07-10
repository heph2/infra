{ config, inputs, ... }:
{
  infra.darwin.hosts.aron = {
    system = "aarch64-darwin";
    specialArgs = { inherit inputs; };
    modules = [
      ./default.nix
      {
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [ inputs.emacs-overlay.overlay ];
      }
      #inputs.nur.nixosModules.nur
      config.infra.modules.darwin.home-manager
      inputs.spicetify-nix.darwinModules.spicetify
      {
        home-manager.backupFileExtension = "backup";
        home-manager.users.marco = import ./home.nix;
        home-manager.extraSpecialArgs = {
          inherit inputs;
        };
        home-manager.sharedModules = [
          #inputs.spicetify-nix.homeManagerModules.default
          #inputs.ghostty.homeModules.default
        ];
      }
    ];
  };
}
