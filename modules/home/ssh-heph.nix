{
  infra.modules.homeManager.ssh-heph = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        mikrotik = {
          Port = 22;
          HostName = "192.168.0.1";
          User = "admin";
          IdentityFile = "/home/heph/.ssh/plakar";
        };
        zima = {
          Port = 22;
          HostName = "192.168.0.105";
          User = "root";
          IdentityFile = "/home/heph/.ssh/sekai_ed";
        };
        hermes = {
          Port = 22;
          HostName = "135.181.85.238";
          User = "root";
          IdentityFile = "/home/heph/.ssh/sekai_ed";
        };
        tyr = {
          Port = 22;
          HostName = "192.168.0.104";
          User = "root";
          IdentityFile = "/home/heph/.ssh/sekai_ed";
        };
        sauron = {
          Port = 22;
          HostName = "192.168.0.106";
          User = "root";
          IdentityFile = "/home/heph/.ssh/sekai_ed";
        };
        github = {
          Port = 22;
          HostName = "github.com";
          User = "git";
          IdentityFile = "/home/heph/.ssh/sr-ht_rsa";
        };
      };
    };
  };
}
