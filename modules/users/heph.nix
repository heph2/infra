{ ... }: {
  flake.modules.nixos.user-heph = { pkgs, ... }: {
    users.users.heph = {
      isNormalUser = true;
      shell = pkgs.zsh;
      extraGroups = [ "wheel" "docker" "plugdev" "dialout" ];
    };
    programs.zsh.enable = true;
    environment.variables = { EDITOR = "hx"; };
    environment.localBinInPath = true;
  };
}
