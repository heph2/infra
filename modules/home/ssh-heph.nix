{ lib, ... }:
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
        gengar = {
          Port = 22;
          HostName = "92.4.163.95";
          User = "root";
          IdentityFile = "/home/heph/.ssh/id_rsa";
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

    # OpenSSH rejects read-only config files in the Nix store when that store
    # is owned by an unmapped uid (e.g. rootless/containerized Nix).
    home.file.".ssh/config".force = true;
    home.activation.materializeSshConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      config="$HOME/.ssh/config"
      if [ -L "$config" ]; then
        $DRY_RUN_CMD cp -- "$config" "$config.tmp"
        $DRY_RUN_CMD chmod 600 "$config.tmp"
        $DRY_RUN_CMD mv -- "$config.tmp" "$config"
      fi
    '';
  };
}
