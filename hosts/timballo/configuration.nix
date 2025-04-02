{ pkgs, inputs, ... }:
{
  flake.nixosConfigurations.timballo = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ 
	    ./default.nix
      {nixpkgs.config.allowUnfree = true;}
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.heph = import ./home.nix;
      }
      ../../modules/common/default.nix
      ({ modulesPath, ... }: { imports = [(modulesPath + "/installer/scan/not-detected.nix")]; })
    ];
  };
}
