{ ... }: {
  flake.modules.nixos.niri = { pkgs, ... }: {
    programs.niri = {
      enable = true;
      package = pkgs.niri-stable;
    };

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.greetd}/bin/agreety --cmd niri";
        };
      };
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [ xdg-desktop-portal-gnome ];
    };
  };
}
