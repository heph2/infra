{ ... }: {
  flake.modules.homeManager.emacs = { pkgs, ... }: {
    programs.emacs = {
      enable = true;
      package = pkgs.emacs;
      extraPackages = epkgs: [
        epkgs.nix-mode
        epkgs.nixfmt
        epkgs.vterm
        (epkgs.treesit-grammars.with-all-grammars)
      ];
    };
    services.emacs.enable = true;
  };
}
