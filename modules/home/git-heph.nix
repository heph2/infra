{
  infra.modules.homeManager.git-heph = {
    programs.git = {
      enable = true;
      settings = {
        user = {
          email = "srht@mrkeebs.eu";
          name = "heph";
        };
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
    };
  };
}
