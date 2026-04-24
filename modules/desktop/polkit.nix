{ ... }: {
  flake.modules.nixos.polkit = {
    security.polkit.enable = true;
    security.rtkit.enable = true;
  };
}
