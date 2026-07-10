{
  infra.modules.homeManager.terminal =
    { pkgs, ... }:
    {
      programs = {
        ghostty = {
          enable = true;
          enableZshIntegration = true;
          settings.window-decoration = "none";
        };
        tmux = {
          enable = true;
          terminal = "tmux-256color";
          mouse = true;
          shell = "${pkgs.zsh}/bin/zsh";
          extraConfig = ''
            set-option -g mouse on
            set -g extended-keys on
            set -g extended-keys-format csi-u
            bind-key h split-window -v
            bind-key v split-window -h
          '';
        };
      };
    };
}
