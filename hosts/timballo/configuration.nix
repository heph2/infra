{ config, ... }:
{
  infra.nixos.hosts.timballo = {
    system = "x86_64-linux";
    modules = [
      ./default.nix
      { nixpkgs.config.allowUnfree = true; }
      config.infra.modules.nixos.home-manager
      { home-manager.users.heph = import ./home.nix; }
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
