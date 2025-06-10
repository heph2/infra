# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  services.tailscale = { enable = true; };

  networking.hostName = "tyr"; # Define your hostname.
  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCmIz2Selg5eJ77lvpJHgDJiRIOZbucMjDK5zrhTEWK heph@fenrir"
  ];

  environment.systemPackages = with pkgs; [ vim wget ];

  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [
    22
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
    6444
    9000
    2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
    2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
  ];
  networking.firewall.allowedUDPPorts = [
    8472 # k3s, flannel: required if using multi-node for inter-node networking
  ];

  services.k3s = {
    enable = true;
    role = "server";
    token = "uasdfnl8yho";
    clusterInit = true;
  };

  networking.firewall.enable = true;
  system.stateVersion = "22.11"; # Did you read the comment?

}

