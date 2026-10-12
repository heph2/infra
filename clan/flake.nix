{
  description = "Opt-in Clan 26.05 experiment for Tyr; not a deployment entrypoint";

  inputs = {
    infra.url = "path:..";
    nixpkgs.follows = "infra/nixpkgs";
    clan-core = {
      # Immutable revision from the 26.05 branch, not main/unstable.
      url = "https://git.clan.lol/clan/clan-core/archive/88d23f9e80115919d2b661e670ef5a24e6eb1442.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "infra/flake-parts";
      inputs.disko.follows = "infra/disko";
      inputs.sops-nix.follows = "infra/sops-nix";
    };
  };

  outputs =
    {
      self,
      infra,
      nixpkgs,
      clan-core,
      ...
    }:
    let
      # Host entrypoints are flake-parts declarations, not NixOS modules.
      # Evaluate the existing registry instead of duplicating Tyr's module list.
      registry =
        infra.inputs.flake-parts.lib.evalFlakeModule
          {
            inputs = infra.inputs // {
              self = infra;
            };
          }
          {
            systems = [ ];
            imports = [
              (infra + "/modules/dendritic")
              (infra + "/hosts/tyr/configuration.nix")
            ];
          };
      host = registry.config.infra.nixos.hosts.tyr;
      clan = clan-core.lib.clan {
        inherit self;
        meta = {
          name = "heph2-infra-prototype";
          domain = "infra.invalid";
          description = "Evaluation-only adapter; production infrastructure is unchanged";
        };
        specialArgs = {
          inputs = infra.inputs;
        }
        // host.specialArgs;
        inventory.machines.tyr = {
          tags = [ "prototype" ];
          # A null target permits local updates. Use a reserved, unreachable name instead.
          deploy.targetHost = "root@tyr.invalid";
        };
        machines.tyr =
          { config, ... }:
          {
            imports = host.modules;
            nixpkgs.hostPlatform = host.system;
            clan.core.enableRecommendedDefaults = false;
            # Clan's ZFS defaults are not gated by enableRecommendedDefaults.
            networking.hostId = infra.nixosConfigurations.tyr.config.networking.hostId;
            boot.zfs.forceImportRoot = infra.nixosConfigurations.tyr.config.boot.zfs.forceImportRoot;
            clan.core.networking.targetHost = config.clanConfig.inventory.machines.tyr.deploy.targetHost;
            clan.core.deployment.requireExplicitUpdate = true;
          };
      };
      regression = import (infra + "/tests/clan-prototype.nix") {
        prototype = self;
        baseline = infra;
      };
    in
    {
      inherit (clan.config)
        nixosConfigurations
        nixosModules
        darwinConfigurations
        clanInternals
        ;
      checks.x86_64-linux.tyr-parity =
        assert regression;
        nixpkgs.legacyPackages.x86_64-linux.runCommand "clan-tyr-parity" { } "touch $out";
      lib.parity = regression;
      packages.x86_64-linux.clan-cli = clan-core.packages.x86_64-linux.clan-cli;
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
    };
}
