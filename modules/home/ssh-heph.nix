{
  infra.modules.homeManager.ssh-heph = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        zima = {
          port = 22;
          hostname = "192.168.0.105";
          user = "root";
          identityFile = "/home/heph/.ssh/sekai_ed";
        };
        hermes = {
          port = 22;
          hostname = "135.181.85.238";
          user = "root";
          identityFile = "/home/heph/.ssh/sekai_ed";
        };
        tyr = {
          port = 22;
          hostname = "192.168.0.104";
          user = "root";
          identityFile = "/home/heph/.ssh/sekai_ed";
        };
        sauron = {
          port = 22;
          hostname = "192.168.0.106";
          user = "root";
          identityFile = "/home/heph/.ssh/sekai_ed";
        };
        github = {
          port = 22;
          hostname = "github.com";
          user = "git";
          identityFile = "/home/heph/.ssh/sr-ht_rsa";
        };
      };
    };
  };
}
