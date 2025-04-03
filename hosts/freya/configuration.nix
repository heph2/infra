{ pkgs, inputs, ... }:
{
  flake.nixosConfigurations.freya = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      inputs.spicetify-nix.nixosModules.default
      {
        nixpkgs.overlays = [ inputs.emacs-overlay.overlay ];
      }      
	    ./default.nix
      {nixpkgs.config.allowUnfree = true;}
      ../../modules/common/default.nix
      ({ modulesPath, ... }: { imports = [(modulesPath + "/installer/scan/not-detected.nix")]; })
    ];
  };
}
