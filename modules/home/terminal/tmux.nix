{ ... }: {
  flake.modules.homeManager.tmux = { pkgs, ... }: {
    programs.tmux = {
      enable = true;
      terminal = "tmux-256color";
      mouse = true;
      shell = "${pkgs.zsh}/bin/zsh";
      extraConfig = ''
        set-option -g mouse on
        bind-key h split-window -v
        bind-key v split-window -h
      '';
    };
  };
}
