{ inputs, ... }:
{
  infra.nixos.hosts.ushi = {
    system = "x86_64-linux";
    modules = [
      ./default.nix
      { nixpkgs.config.allowUnfree = true; }
      inputs.nixos-wsl.nixosModules.wsl
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
