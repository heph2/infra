{ ... }: {
  flake.modules.homeManager.zsh-p10k = {
    programs.zsh = {
      enable = true;
      initContent = "source ~/.p10k.zsh";
      shellAliases = {
        ll = "ls -l";
        lz = "lazygit";
      };
      zplug = {
        enable = true;
        plugins = [
          { name = "zsh-users/zsh-autosuggestions"; }
          {
            name = "romkatv/powerlevel10k";
            tags = [ "as:theme" "depth:1" ];
          }
        ];
      };
    };
  };
}
