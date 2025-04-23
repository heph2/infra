{ config, lib, pkgs, ... }:

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

  networking.hostName = "sauron"; # Define your hostname.
  boot.loader.grub.enable = true; # Enables wireless support via wpa_suppli
  boot.loader.grub.efiInstallAsRemovable = true; # Easiest to use and most
  boot.loader.grub.device = "nodev";
  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";
  networking.hostId = "a854bd58";

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCmIz2Selg5eJ77lvpJHgDJiRIOZbucMjDK5zrhTEWK"
  ];

  environment.systemPackages = with pkgs; [ vim mg wget ];

  services.openssh.enable = true;

  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.enable = true;

  system.stateVersion = "24.11"; # Did you read the comment?

}

