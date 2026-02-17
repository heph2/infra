{ pkgs, inputs, ... }: {
  flake.nixosConfigurations.sauron = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./default.nix
      inputs.agenix.nixosModules.default
      inputs.nix-minecraft.nixosModules.minecraft-servers
      inputs.bo3-server.nixosModules.default
      { nixpkgs.overlays = [ inputs.nix-minecraft.overlay ]; }
      { nixpkgs.config.allowUnfree = true; }
      ../../modules/common/default.nix
      ({ modulesPath, ... }: {
        imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
      })
    ];
  };
}
