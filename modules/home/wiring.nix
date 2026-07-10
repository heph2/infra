{ inputs, ... }:
{
  infra.modules.nixos.home-manager = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };

  infra.modules.darwin.home-manager = {
    imports = [ inputs.home-manager.darwinModules.home-manager ];
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };
}
