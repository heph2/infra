{
  config,
  lib,
  pkgs,
  ...
}:

let
  hostname = "sauron";
  localDomain = hostname + ".hephnet.lan";

in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./disk-config.nix
    ./pocked-id.nix
    "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix"
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

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts."jelly.${localDomain}" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:8096";
        proxyWebsockets = true;
      };
    };
    virtualHosts."torrent.${localDomain}" = {
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
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCmIz2Selg5eJ77lvpJHgDJiRIOZbucMjDK5zrhTEWK"
  ];

  environment.systemPackages = with pkgs; [
    vim
    mg
    wget
    borgbackup
  ];

  services.openssh.enable = true;

  networking.firewall.allowedTCPPorts = [
    22
    80
    443
    1414
    8096
    9091
  ];
  networking.firewall.enable = true;

}
