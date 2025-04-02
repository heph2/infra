{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
#      ../../modules/compose/firefly/default.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "tyr"; # Define your hostname.
  networking.firewall.checkReversePath = "loose";
  time.timeZone = "Europe/Rome";

  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings.sandbox = false;

  environment.systemPackages = with pkgs; [
     vim mg
     wget
     podman-compose
  ];

  services.caddy = {
    enable = true;
    globalConfig = ''
      auto_https disable_redirects
    '';
    virtualHosts."http://wallet.zaru.cc" = {
      listenAddresses = [ "100.76.226.130" ];
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8080
      '';
    };
    virtualHosts."http://wallet-importer.zaru.cc" = {
      listenAddresses = [ "100.76.226.130" ];
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8081
      '';
    };
  };

  services.netdata = {
    enable = true;
  };

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 
    22 # ssh
    80 443 # http/https
    4648 4647 4646 # nomad
    8600 8500 8300 8301 8302 # consul
  ];
  
  networking.firewall.allowedUDPPorts = [ 
    8600 8301 8302 # consul
  ];

  networking.firewall.enable = true;

  system.stateVersion = "22.11"; # Did you read the comment?

}

