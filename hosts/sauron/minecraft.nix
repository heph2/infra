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
        online-mode = false;
      };

      jvmOpts = "-Xmx4G -Xms2G";
    };

    # Factory in the Sky 4 - NeoForge modpack
    # FIXME: Enable once network issues with libraries.minecraft.net are resolved
    servers.fits4 = {
      enable = false;
      package = pkgs.neoforgeServers.neoforge-1_21_1;

      serverProperties = {
        server-port = 25566;
        difficulty = "normal";
        gamemode = "survival";
        max-players = 10;
        motd = "Factory in the Sky 4";
        white-list = false;
        enable-command-block = true;
        spawn-protection = 0;
        online-mode = false;
        level-type = "skyblockbuilder:skyblock";
      };

      jvmOpts = "-Xmx6G -Xms4G";

      # Symlink mods from manually downloaded modpack
      # Download server files from: https://www.curseforge.com/minecraft/modpacks/factory-in-the-sky-4/files
      # Extract to /var/lib/minecraft/fits4-modpack/
      symlinks = {
        "mods" = "/var/lib/minecraft/fits4-modpack/mods";
        "config" = "/var/lib/minecraft/fits4-modpack/config";
        "defaultconfigs" = "/var/lib/minecraft/fits4-modpack/defaultconfigs";
        "kubejs" = "/var/lib/minecraft/fits4-modpack/kubejs";
      };
    };
  };
}
