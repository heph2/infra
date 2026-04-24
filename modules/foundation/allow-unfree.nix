{ ... }: {
  flake.modules.nixos.allow-unfree = {
    nixpkgs.config.allowUnfree = true;
  };

  flake.modules.darwin.allow-unfree = {
    nixpkgs.config.allowUnfree = true;
  };
}
