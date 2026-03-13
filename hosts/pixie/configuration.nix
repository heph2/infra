{ pkgs, inputs, ... }: {
  flake.nixosConfigurations.pixie = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      ./default.nix
      { nixpkgs.config.allowUnfree = true; }
      ({ pkgs, ... }: {
        nixpkgs.overlays = [
          (final: prev: {
            ttyd = prev.ttyd.overrideAttrs (old: { patches = [ ]; });
          })
        ];
      })
      ({ modulesPath, ... }: {
        imports = [
          (modulesPath + "/installer/scan/not-detected.nix")
          inputs.avf.nixosModules.avf
        ];
      })
    ];
  };
}
