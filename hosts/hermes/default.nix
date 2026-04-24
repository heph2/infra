{ inputs, config, ... }:
let
  nixos = config.flake.modules.nixos;
in
{
  flake.nixosConfigurations.hermes = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      nixos.allow-unfree
      nixos.common-server
      inputs.hermes-agent.nixosModules.default
      inputs.sops-nix.nixosModules.sops
      inputs.agenix.nixosModules.default
      inputs.simple-nixos-mailserver.nixosModule
      ({ modulesPath, ... }: {
        imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
      })
      ./hardware-configuration.nix
      ./networking.nix
      ./mail.nix
      ./kanban.nix
      ./caddy.nix
      ./hermes-agent.nix
      ({ config, pkgs, ... }: {
        boot.tmp.cleanOnBoot = true;
        zramSwap.enable = true;

        sops.defaultSopsFile = ./secrets.yaml;
        sops.secrets."murmur/password" = { };
        networking = {
          hostName = "hermes";
          defaultGateway = "172.31.1.1";
          firewall.allowedTCPPorts = [ 80 25 143 465 7980 9160 9117 ];
          firewall.extraCommands = ''
            iptables -A INPUT -s 192.253.248.30 -j DROP
            iptables -A OUTPUT -d 192.253.248.30 -j DROP
            iptables -A INPUT -s 80.94.95.216 -j DROP
            iptables -A OUTPUT -d 80.94.95.216 -j DROP
          '';
        };

        environment.systemPackages = with pkgs; [
          helix openssl openssh ncdu mg vim git
        ];

        services.murmur = {
          enable = false;
          welcometext = "Welcome back stranger!";
          openFirewall = true;
          password = "$MURMURD_PASSWORD";
          environmentFile = config.sops.secrets."murmur/password".path;
        };
      })
    ];
  };
}
