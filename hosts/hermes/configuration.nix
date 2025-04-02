{ pkgs, inputs, ... }:
{
  flake.nixosConfigurations.hermes = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
	    ./default.nix
      inputs.sops-nix.nixosModules.sops
      {nixpkgs.config.allowUnfree = true;}
      inputs.simple-nixos-mailserver.nixosModule
      ../../modules/common/default.nix
      ({ modulesPath, ... }: { imports = [(modulesPath + "/installer/scan/not-detected.nix")]; })
    ];
  };
}
