{ config, inputs, ... }:
{
  infra.nixos.hosts.hermes = {
    system = "x86_64-linux";
    modules = [
      (
        { ... }:
        {
          nixpkgs.overlays = [ (import ../../pkgs/plakar { inherit inputs; }) ];
        }
      )
      ./default.nix
      inputs.hermes-agent.nixosModules.default
      inputs.sops-nix.nixosModules.sops
      inputs.agenix.nixosModules.default
      { nixpkgs.config.allowUnfree = true; }
      config.infra.modules.nixos.plakar-backup
      inputs.simple-nixos-mailserver.nixosModules.default
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
