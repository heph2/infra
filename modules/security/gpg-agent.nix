{ ... }: {
  flake.modules.homeManager.gpg-agent = { pkgs, ... }: {
    programs.gpg.enable = true;
    services.gpg-agent = {
      enable = true;
      defaultCacheTtl = 36000;
      maxCacheTtl = 36000;
      defaultCacheTtlSsh = 36000;
      maxCacheTtlSsh = 36000;
      extraConfig = ''
        pinentry-program ${pkgs.pinentry-qt}/bin/pinentry
      '';
    };
  };
}
