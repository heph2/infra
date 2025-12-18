{ config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix # generated at runtime by nixos-infect
    ./mail.nix
    ./kanban.nix
    ./caddy.nix
  ];
  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets."murmur/password" = { };
  networking = {
    hostName = "hermes";
    firewall.allowedTCPPorts = [
      80
      25
      143
      465
    ];
  };

  environment.systemPackages = with pkgs; [
    helix
    mg
    vim
    git
  ];

  services.murmur = {
    enable = false;
    welcometext = "Welcome back stranger!";
    openFirewall = true;
    password = "$MURMURD_PASSWORD";
    environmentFile = config.sops.secrets."murmur/password".path;
  };
}
