{ ... }: {
  flake.modules.nixos.documentation = {
    documentation.dev.enable = true;
    documentation.man = {
      man-db.enable = false;
      mandoc.enable = true;
    };
  };
}
