{
  config,
  inputs,
  lib,
  ...
}:
let
  hostModule =
    { name, ... }:
    {
      options = {
        system = lib.mkOption {
          type = lib.types.str;
          description = "System identifier for host ${name}.";
        };

        specialArgs = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = "Extra specialArgs passed to the host module system.";
        };

        modules = lib.mkOption {
          type = lib.types.listOf lib.types.deferredModule;
          default = [ ];
          description = "Modules composing host ${name}.";
        };
      };
    };

  mkSpecialArgs = host: { inherit inputs; } // host.specialArgs;
in
{
  options.infra = {
    modules = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.deferredModule);
      default = { };
      description = "Dendritic module registry grouped by module class.";
    };

    nixos.hosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule hostModule);
      default = { };
      description = "Dendritic NixOS host declarations.";
    };

    darwin.hosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule hostModule);
      default = { };
      description = "Dendritic nix-darwin host declarations.";
    };
  };

  config.flake = {
    nixosConfigurations = lib.mapAttrs (
      _name: host:
      inputs.nixpkgs.lib.nixosSystem {
        inherit (host) system modules;
        specialArgs = mkSpecialArgs host;
      }
    ) config.infra.nixos.hosts;

    darwinConfigurations = lib.mapAttrs (
      _name: host:
      inputs.darwin.lib.darwinSystem {
        inherit (host) system modules;
        specialArgs = mkSpecialArgs host;
      }
    ) config.infra.darwin.hosts;
  };
}
