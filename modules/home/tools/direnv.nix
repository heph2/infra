{ ... }: {
  flake.modules.homeManager.direnv = {
    programs = {
      direnv = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };
      bash.enable = true;
    };
  };
}
