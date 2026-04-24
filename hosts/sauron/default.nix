{ inputs, config, ... }:
let
  nixos = config.flake.modules.nixos;

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
  flake.nixosConfigurations.sauron = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      nixos.allow-unfree
      nixos.common-server
      nixos.locale-eu
      inputs.agenix.nixosModules.default
      inputs.nix-minecraft.nixosModules.minecraft-servers
      inputs.bo3-server.nixosModules.default
      { nixpkgs.overlays = [ inputs.nix-minecraft.overlay ]; }
      ({ modulesPath, ... }: {
        imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
      })
      ./hardware-configuration.nix
      ./disk-config.nix
      ./pocked-id.nix
      ./caddy.nix
      ./paperless.nix
      ./minecraft.nix
      "${
        builtins.fetchTarball {
          url = "https://github.com/nix-community/disko/archive/master.tar.gz";
          sha256 = "sha256:035nyq47jvhxf2d00frd983h5rn56zs84bk41fax88sjq2gb02iw";
        }
      }/module.nix"
      ({ config, pkgs, ... }: {
        boot.loader.grub.efiSupport = true;
        boot.zfs.extraPools = [ "data" ];

        networking.hostName = hostname;

        networking.interfaces.enp1s0 = {
          ipv6.addresses = [{
            address = "2a07:7e81:85f5::beef";
            prefixLength = 64;
          }];
        };
        networking.defaultGateway6 = {
          address = "fe80::6f4:1cff:fe18:162";
          interface = "enp1s0";
        };

        boot.loader.grub.enable = true;
        boot.loader.grub.efiInstallAsRemovable = true;
        boot.loader.grub.device = "nodev";
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
          "Z ${usenetBase}/complete 2775 sabnzbd media - -"
          "d /media/jelly 2775 root media - -"
          "d /media/jelly/shows 2775 jellyfin media - -"
          "d /media/jelly/movies 2775 jellyfin media - -"
        ];

        services.sabnzbd = {
          enable = true;
          openFirewall = false;
          group = mediaGroup;
        };

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

        age.secrets.netdata_token = {
          file = ../../secrets/netdata_token.age;
          mode = "640";
        };
        services.netdata = {
          enable = true;
          package = pkgs.netdata.override { withCloudUi = true; };
          claimTokenFile = config.age.secrets.netdata_token.path;
        };

        environment.systemPackages = with pkgs; [
          vim mg wget borgbackup git
        ];

        services.openssh.enable = true;

        networking.firewall.allowedTCPPorts = [
          22 80 443 1411 8096 9091 27017 19999
        ];
        networking.firewall.allowedUDPPorts = [ 27017 ];
        networking.firewall.enable = true;

        services.bo3-server = {
          enable = true;
          steamUser = "olympiczeus";
          client = "boiii";
          port = 27017;
          gameMode = "zm";
          serverName = "^5Sauron ^7Zombies";
          description = "NixOS powered BO3 Zombies server";
          maxClients = 4;
          lobbyMinPlayers = 1;
          rconPassword = "banana";
          modId = "2661297173";
          openFirewall = false;
          mapRotation = [
            { gametype = "zclassic"; map = "zm_town"; }
            { gametype = "zclassic"; map = "zm_tomb"; }
            { gametype = "zclassic"; map = "zm_factory"; }
            { gametype = "zclassic"; map = "zm_theater"; }
            { gametype = "zclassic"; map = "zm_cosmodrome"; }
            { gametype = "zclassic"; map = "zm_temple"; }
            { gametype = "zclassic"; map = "zm_moon"; }
            { gametype = "zclassic"; map = "zm_castle"; }
          ];
        };

        age.secrets.ups_password = {
          file = ../../secrets/ups-admin.age;
          mode = "640";
        };

        power.ups = {
          enable = true;
          mode = "standalone";
          ups."UPS-1" = {
            description = "Eaton ECO 650 5E";
            driver = "usbhid-ups";
            port = "auto";
          };
          users."nut-admin" = {
            passwordFile = config.age.secrets.ups_password.path;
            upsmon = "primary";
          };
          upsmon.monitor."UPS-1" = {
            system = "UPS-1@localhost";
            powerValue = 1;
            user = "nut-admin";
            passwordFile = config.age.secrets.ups_password.path;
            type = "primary";
          };
          upsmon.settings = {
            NOTIFYMSG = [
              [ "ONLINE" ''"UPS %s: On line power."'' ]
              [ "ONBATT" ''"UPS %s: On battery."'' ]
              [ "LOWBATT" ''"UPS %s: Battery is low."'' ]
              [ "REPLBATT" ''"UPS %s: Battery needs to be replaced."'' ]
              [ "FSD" ''"UPS %s: Forced shutdown in progress."'' ]
              [ "SHUTDOWN" ''"Auto logout and shutdown proceeding."'' ]
              [ "COMMOK" ''"UPS %s: Communications (re-)established."'' ]
              [ "COMMBAD" ''"UPS %s: Communications lost."'' ]
              [ "NOCOMM" ''"UPS %s: Not available."'' ]
              [ "NOPARENT" ''"upsmon parent dead, shutdown impossible."'' ]
            ];
            NOTIFYFLAG = [
              [ "ONLINE" "SYSLOG+WALL" ]
              [ "ONBATT" "SYSLOG+WALL" ]
              [ "LOWBATT" "SYSLOG+WALL" ]
              [ "REPLBATT" "SYSLOG+WALL" ]
              [ "FSD" "SYSLOG+WALL" ]
              [ "SHUTDOWN" "SYSLOG+WALL" ]
              [ "COMMOK" "SYSLOG+WALL" ]
              [ "COMMBAD" "SYSLOG+WALL" ]
              [ "NOCOMM" "SYSLOG+WALL" ]
              [ "NOPARENT" "SYSLOG+WALL" ]
            ];
            RBWARNTIME = 216000;
            NOCOMMWARNTIME = 300;
            FINALDELAY = 0;
          };
        };
      })
    ];
  };
}
