{ ... }: {
  flake.modules.homeManager.dev-tools = {
    programs.yazi.enable = true;
    programs.zellij.enable = true;
    programs.fzf.enable = true;
    programs.htop.enable = true;
    programs.zathura.enable = true;
    programs.k9s.enable = true;
  };
}
