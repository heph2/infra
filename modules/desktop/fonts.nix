{ ... }: {
  flake.modules.nixos.fonts = { pkgs, ... }: {
    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        nerd-fonts.hack
        fantasque-sans-mono
        hack-font
        fira-code
        font-awesome
      ];
    };
  };
}
