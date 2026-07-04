{ inputs, ... }:
{
  infra.nixos.hosts.hermes = {
    system = "x86_64-linux";
    modules = [
      ./default.nix
      inputs.hermes-agent.nixosModules.default
      inputs.sops-nix.nixosModules.sops
      inputs.agenix.nixosModules.default
      { nixpkgs.config.allowUnfree = true; }
      inputs.simple-nixos-mailserver.nixosModule
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
