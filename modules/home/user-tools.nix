{
  infra.modules.homeManager.user-tools =
    { pkgs, ... }:
    {
      programs = {
        bash.enable = true;
        direnv = {
          enable = true;
          enableBashIntegration = true;
          enableZshIntegration = true;
          nix-direnv.enable = true;
        };
        fzf.enable = true;
        gpg.enable = true;
        htop.enable = true;
        k9s.enable = true;
        yazi.enable = true;
        zathura.enable = true;
        zellij.enable = true;
      };

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
