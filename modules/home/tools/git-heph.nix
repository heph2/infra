{ ... }: {
  flake.modules.homeManager.git-heph = { pkgs, ... }: {
    programs.git = {
      enable = true;
      settings = {
        aliases = {
          gp = "add -p";
          co = "checkout";
          s = "switch";
          st = "status";
        };
        extraConfig = {
          pull.ff = "only";
          core.pager = "delta";
          interactive.diffFilter = "delta --color-only";
          delta = {
            navigate = true;
            light = false;
            side-by-side = true;
          };
        };
      };
      userEmail = "srht@mrkeebs.eu";
      userName = "heph";
    };
  };
}
