{ pkgs, inputs, ... }: {
  flake.nixosConfigurations.pixie = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      ./default.nix
      {
        nixpkgs.config.allowUnfree = true;
      }
      ({ modulesPath, ... }: {
        imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
      })
    ];
  };
}
