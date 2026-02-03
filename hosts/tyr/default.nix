# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./homebox.nix
    ./vikunja.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  services.tailscale = {
    enable = true;
  };

  # IPV6 Configuration
  networking.interfaces.enp0s31f6 = {
    ipv6.addresses = [
      {
        address = "2a07:7e81:85f5::babe";
        prefixLength = 64;
      }
    ];
  };
  networking.defaultGateway6 = {
    address = "fe80::6f4:1cff:fe18:162";
    interface = "enp0s31f6";
  };

  networking.hostName = "tyr"; # Define your hostname.
  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCmIz2Selg5eJ77lvpJHgDJiRIOZbucMjDK5zrhTEWK heph@fenrir"
  ];

  services.unifi = {
    enable = true;
    openFirewall = true;
    unifiPackage = pkgs.unifi;
    mongodbPackage = pkgs.mongodb;
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
  ];

  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [
    22
    8443
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
    6444
    9000
    2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
    2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
  ];
  networking.firewall.allowedUDPPorts = [
    51820
    8472 # k3s, flannel: required if using multi-node for inter-node networking
  ];
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [
        "10.1.1.5/32"
        "2a0f:85c1:c4d:1234::5/128"
      ];
      listenPort = 51820;
      privateKeyFile = "/root/vellutata.wg0.priv";

      peers = [
        {
          publicKey = "JE3KvXkupkYkM3eJ2mSmSeBCAZvHBqv7k4XZ/WSUc1w=";
          allowedIPs = [
            "0.0.0.0/0"
            "::/0"
          ];
          endpoint = "193.57.159.213:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };
  services.k3s = {
    enable = true;
    role = "server";
    token = "uasdfnl8yho";
    clusterInit = true;
  };

  networking.firewall.enable = true;

}
