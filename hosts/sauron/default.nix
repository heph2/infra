{
  config,
  lib,
  pkgs,
  ...
}:

let
  hostname = "sauron";
  localDomain = hostname + ".hephnet.lan";
  pochiDomain = "pochi.casa";

  mediaGroup = "media";
  dataRoot = "/media";
  torrentsDir = "${dataRoot}/torrent";
  mediaDir = "${dataRoot}/jelly";

  usenetBase = "${dataRoot}/usenet";
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./disk-config.nix
    ./pocked-id.nix
    ./caddy.nix
    ./paperless.nix
    ./minecraft.nix
    "${
      builtins.fetchTarball {
        url = "https://github.com/nix-community/disko/archive/master.tar.gz";
        sha256 = "14nq552mbbmdd3is3zy4ml56dlzh3m768iimhr17wmxgrfqgczan";
      }
    }/module.nix"
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.grub.efiSupport = true;
  boot.zfs.extraPools = [ "data" ];

  networking.hostName = hostname; # Define your hostname.

  # IPV6 Configuration
  networking.interfaces.enp1s0 = {
    ipv6.addresses = [
      {
        address = "2a07:7e81:85f5::beef";
        prefixLength = 64;
      }
    ];
  };
  networking.defaultGateway6 = {
    address = "fe80::6f4:1cff:fe18:162";
    interface = "enp1s0";
  };

  boot.loader.grub.enable = true; # Enables wireless support via wpa_suppli
  boot.loader.grub.efiInstallAsRemovable = true; # Easiest to use and most
  boot.loader.grub.device = "nodev";
  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";
  networking.hostId = "a854bd58";

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ vpl-gpu-rt ];
  };

  services.zfs.autoScrub.enable = true;
  services.jellyfin = {
    enable = true;
    dataDir = "/media";
  };
  services.transmission = {
    enable = false;
    settings = {
      download-dir = "/media/torrent/downloads";
      incomplete-dir-enabled = false;
      rpc-bind-address = "127.0.0.1";
      downloadDirPermissions = "770";
      rpc-whitelist = "192.168.1.* 127.0.0.1";
      rpc-whitelist-enabled = false;
      rpc-host-whitelist-enabled = false;
    };
    openRPCPort = true;
    openFirewall = true;
  };

  users.groups.${mediaGroup} = { };

  services.qbittorrent = {
    enable = true;
    group = mediaGroup;
    profileDir = "/var/lib/qbittorrent";
    webuiPort = 8088;
    serverConfig = {
      Preferences = {
        "Downloads\\SavePath" = "${torrentsDir}/download";
        "Downloads\\TempPath" = "${torrentsDir}/.incomplete";
        "Downloads\\TempPathEnabled" = true;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /media 0755 root root - -"
    "d ${usenetBase} 2775 root media - -"
    "d ${usenetBase}/incomplete 2775 sabnzbd media - -"
    "d ${usenetBase}/complete 2775 sabnzbd media - -"
    # Recursively fix permissions on completed downloads so Sonarr/Radarr can access them
    "Z ${usenetBase}/complete 2775 sabnzbd media - -"

    # Jellyfin TV library (Sonarr writes, Jellyfin reads)
    "d /media/jelly 2775 root media - -"
    "d /media/jelly/shows 2775 jellyfin media - -"
    "d /media/jelly/movies 2775 jellyfin media - -"
  ];

  services.sabnzbd = {
    enable = true;
    openFirewall = false;
    group = mediaGroup;
  };

  # Set proper umask for sabnzbd so files are readable by media group
  systemd.services.sabnzbd.serviceConfig.UMask = "0002";

  services.prowlarr = {
    enable = true;
    openFirewall = false;
  };

  services.sonarr = {
    enable = true;
    openFirewall = false;
    group = mediaGroup;
  };

  services.radarr = {
    enable = true;
    openFirewall = false;
    group = mediaGroup;
  };

  services.jellyseerr = {
    enable = true;
    openFirewall = false;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCmIz2Selg5eJ77lvpJHgDJiRIOZbucMjDK5zrhTEWK"
  ];

  environment.systemPackages = with pkgs; [
    vim
    mg
    wget
    borgbackup
    git
  ];

  services.openssh.enable = true;

  networking.firewall.allowedTCPPorts = [
    22
    80
    443
    1411
    8096
    9091
    27017
  ];
  networking.firewall.allowedUDPPorts = [ 27017 ];
  networking.firewall.enable = true;

  # Black Ops 3 Dedicated Server
  services.bo3-server = {
    enable = true;
    steamUser = "olympiczeus";
    client = "boiii";
    port = 27017;
    gameMode = "zm";
    serverName = "^5Sauron ^7Zombies";
    description = "NixOS powered BO3 Zombies server";
    maxClients = 4;
    rconPassword = "banana";
    modId = "1638465081"; # Kermit Mod
    openFirewall = false;
    mapRotation = [
      { gametype = "zclassic"; map = "zm_prison"; }     # Mob of the Dead (custom)
      { gametype = "zclassic"; map = "zm_tomb"; }       # Origins
      { gametype = "zclassic"; map = "zm_factory"; }    # The Giant
      { gametype = "zclassic"; map = "zm_theater"; }    # Kino der Toten
      { gametype = "zclassic"; map = "zm_cosmodrome"; } # Ascension
      { gametype = "zclassic"; map = "zm_temple"; }     # Shangri-La
      { gametype = "zclassic"; map = "zm_moon"; }       # Moon
      { gametype = "zclassic"; map = "zm_castle"; }     # Der Eisendrache
    ];
    # mapRotation = [
    #   {
    #     gametype = "tdm";
    #     map = "mp_biodome";
    #   }
    #   {
    #     gametype = "dom";
    #     map = "mp_sector";
    #   }
    #   {
    #     gametype = "tdm";
    #     map = "mp_spire";
    #   }
    #   {
    #     gametype = "dom";
    #     map = "mp_apartments";
    #   }
    # ];
  };

}
