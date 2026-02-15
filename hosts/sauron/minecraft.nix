{
  config,
  pkgs,
  ...
}:
let
  # Cobblemon mod and dependencies
  cobblemon = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/MdwFAVRL/versions/kF7CvxTo/Cobblemon-fabric-1.7.3%2B1.21.1.jar";
    sha256 = "sha256-98JZVRdrrcRErWIR/FVlFP7b26d2In8QX+iZ+IGddOM=";
    name = "cobblemon.jar";
  };
  fabricApi = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/3wZtvzew/fabric-api-0.116.8%2B1.21.1.jar";
    sha256 = "sha256-eLrjGef9xTHpStPYhfLzVhP8EmZFocu0noRWuQg1SRs=";
    name = "fabric-api.jar";
  };
  kotlin = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/Ha28R6CL/versions/ViT4gucI/fabric-language-kotlin-1.13.9%2Bkotlin.2.3.10.jar";
    sha256 = "sha256-/s1ebdaudoFLqSE2tBeRLBmxnsdupFHO3kcs0pzez5E=";
    name = "fabric-language-kotlin.jar";
  };
in
{
  services.minecraft-servers = {
    enable = true;
    eula = true;
    dataDir = "/var/lib/minecraft";
    # Don't open firewall - only accessible via Tailscale
    openFirewall = false;

    servers.fabric = {
      enable = true;
      package = pkgs.fabricServers.fabric-1_21_1;

      serverProperties = {
        server-port = 25565;
        difficulty = "normal";
        gamemode = "survival";
        max-players = 10;
        motd = "Cobblemon Server";
        white-list = false;
        enable-command-block = true;
        spawn-protection = 0;
        online-mode = false;
      };

      jvmOpts = "-Xmx4G -Xms3G";

      symlinks = {
        "mods/cobblemon.jar" = cobblemon;
        "mods/fabric-api.jar" = fabricApi;
        "mods/fabric-language-kotlin.jar" = kotlin;
      };
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
