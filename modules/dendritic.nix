{ lib, ... }: {
  options.flake.modules = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.deferredModule);
    default = { };
    description = "Dendritic module registry. flake.modules.<class>.<aspect> stores deferred modules.";
  };
}
