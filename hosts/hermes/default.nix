{ config, pkgs, ... }: {
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
    firewall.allowedTCPPorts = [ 80 25 143 465 7980 9160 9117 ];
    firewall.extraCommands = ''
      iptables -A INPUT -s 192.253.248.30 -j DROP
      iptables -A OUTPUT -d 192.253.248.30 -j DROP
      iptables -A INPUT -s 80.94.95.216 -j DROP
      iptables -A OUTPUT -d 80.94.95.216 -j DROP
    '';
  };

  environment.systemPackages = with pkgs; [
    helix
    openssl
    openssh
    ncdu
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
