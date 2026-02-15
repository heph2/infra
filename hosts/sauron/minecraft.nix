{
  config,
  pkgs,
  ...
}:
{
  services.minecraft-servers = {
    enable = true;
    eula = true;
    dataDir = "/var/lib/minecraft";
    # Don't open firewall - only accessible via Tailscale
    openFirewall = false;

    servers.fabric = {
      enable = true;
      package = pkgs.fabricServers.fabric-1_21_4;

      serverProperties = {
        server-port = 25565;
        difficulty = "normal";
        gamemode = "survival";
        max-players = 10;
        motd = "Sauron Minecraft Server";
        white-list = false;
        enable-command-block = true;
        spawn-protection = 0;
      };

      jvmOpts = "-Xmx4G -Xms2G";
    };
  };
}
