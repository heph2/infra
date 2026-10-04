{ inputs, ... }:
{
  infra.nixos.hosts.gengar = {
    system = "aarch64-linux";
    modules = [
      ./default.nix
      inputs.disko.nixosModules.disko
      { nixpkgs.hostPlatform = "aarch64-linux"; }
      (
        { modulesPath, ... }:
        {
          imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
        }
      )
    ];
  };
}
