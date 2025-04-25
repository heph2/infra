{ config, lib, pkgs, ... }:

let
  hostname = "sauron";
  localDomain = hostname + ".hephnet.lan";
in

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./disk-config.nix
    "${
      builtins.fetchTarball
      "https://github.com/nix-community/disko/archive/master.tar.gz"
    }/module.nix"
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.grub.efiSupport = true;

  networking.hostName = hostname; # Define your hostname.
  boot.loader.grub.enable = true; # Enables wireless support via wpa_suppli
  boot.loader.grub.efiInstallAsRemovable = true; # Easiest to use and most
  boot.loader.grub.device = "nodev";
  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";
  networking.hostId = "a854bd58";

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      vpl-gpu-rt
    ];
  };

  services.zfs.autoScrub.enable = true;
  services.jellyfin = {
    enable = true;
    dataDir = "/media";
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts."jelly.${localDomain}" = {
      proxyPass = "http://127.0.0.1:8096";
      proxyWebSockets = true;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCmIz2Selg5eJ77lvpJHgDJiRIOZbucMjDK5zrhTEWK"
  ];

  environment.systemPackages = with pkgs; [ vim mg wget borgbackup ];

  services.openssh.enable = true;

  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.enable = true;

}
