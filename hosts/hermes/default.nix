{ config, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix # generated at runtime by nixos-infect
    ./mail.nix
    ./kanban.nix
  ];
  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets."murmur/password" = {};
  networking = {
    hostName = "hermes";
    firewall.allowedTCPPorts = [ 80 25 143 465 ];
  };
  services.murmur = {
    enable = true;
    welcometext = "Welcome back stranger!";
    openFirewall = true;
    password = "$MURMURD_PASSWORD";
    environmentFile = config.sops.secrets."murmur/password".path;
  };
}
