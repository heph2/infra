{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable latest compatible zfs kernel
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  networking.hostName = "freya";
  time.timeZone = "Europe/Rome";

  i18n.defaultLocale = "en_US.UTF-8";
  environment.systemPackages = with pkgs; [
    vim mg
    wget curl
  ];

  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.enable = true;

  # ZFS Stuff
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  system.stateVersion = "23.11";
}
