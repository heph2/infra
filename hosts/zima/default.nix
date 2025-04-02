
{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];  

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "btrfs";

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" "/data" ];
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
  };
  

  services.nginx = {
      enable = true;
      recommendedProxySettings = true;

      virtualHosts."netflics.zima.lan" =  {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8096";
          proxyWebsockets = true; # needed if you need to use WebSocket
        };
      };
      # virtualHosts."goat.zima.lan" = {
      #   locations."/" = {
      #     proxyPass = "http://127.0.0.1:8081";
      #   };
      # };
      virtualHosts."torrent.zima.lan" =  {
        locations."/" = {
          proxyPass = "http://127.0.0.1:9091";
          extraConfig = ''
        proxy_pass_header  X-Transmission-Session-Id;
        proxy_set_header   X-Forwarded-Host $host;
        proxy_set_header   X-Forwarded-Server $host;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
          '';
        };
      };
      virtualHosts."rss.zima.lan" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
        };
      };
  };

  services.dokuwiki.sites."wiki.zima.lan" = {
    enable = true;
    settings = {
      title = "My Wiki";
      userewrite = 1;
      useacl = true;
      superuser = "root";
    };
  };  

  services.miniflux = {
    enable = true;
    adminCredentialsFile = "/etc/nixos/miniflux.credentials";
  };

  services.goatcounter = {
    enable = true;
    proxy = true;
    address = "192.168.1.30";
  };

  services.cloudflared = {
    enable = true;
    certificateFile = "/root/.cloudflared/cert.pem";
    tunnels = {
      "bcf94d1a-acfa-4938-99e5-fe9cd8c5e6d8" = {
        credentialsFile = "/etc/nixos/cloudflared.credentials";
        certificateFile = "/root/.cloudflared/cert.pem";
        originRequest.noTLSVerify = true;
        default = "http_status:404";
        ingress = {
          "cup.mbauce.com" = {
            service = "http://192.168.1.30:7878"; # Cuppy
          };
          "stats.mbauce.com" = {
            service = "http://192.168.1.30:8081"; # Goatcounter
          };
        };
      };
    };
  };
  
  services.transmission = {
    enable = true;
    settings = {
      download-dir = "/data/torrent/downloads";
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

  networking.firewall = {
    allowedTCPPorts = [
      80 # Nginx reverse proxy
      8096 # Jellyfin
      9091 # Transmission
    ];
  };

  services.jellyfin.enable = true;

  networking.hostName = "zima"; # Define your hostname.

  # Set your time zone.
  time.timeZone = "Europe/Rome";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    vim mg
    wget ncdu
    git
  ];
}
