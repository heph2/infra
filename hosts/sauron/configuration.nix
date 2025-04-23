{ pkgs, inputs, ... }: {
  flake.nixosConfigurations.sauron = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./default.nix
      { nixpkgs.config.allowUnfree = true; }
      ../../modules/common/default.nix
      ({ modulesPath, ... }: {
        imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
      })
    ];
  };
}
