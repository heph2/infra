{ inputs, config, ... }:
let
  nixos = config.flake.modules.nixos;
in
{
  flake.nixosConfigurations.tyr = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      nixos.allow-unfree
      nixos.common-server
      nixos.locale-eu
      inputs.agenix.nixosModules.default
      ({ modulesPath, ... }: {
        imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
      })
      ./hardware-configuration.nix
      ./homebox.nix
      ./vikunja.nix
      ./grafana.nix
      ./vaultwarden.nix
      ./miniflux.nix
      ({ config, pkgs, ... }: {
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        services.tailscale.enable = true;

        networking.interfaces.enp0s31f6 = {
          ipv6.addresses = [{
            address = "2a07:7e81:85f5::babe";
            prefixLength = 64;
          }];
        };
        networking.defaultGateway6 = {
          address = "fe80::6f4:1cff:fe18:162";
          interface = "enp0s31f6";
        };

        networking.hostName = "tyr";

        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCmIz2Selg5eJ77lvpJHgDJiRIOZbucMjDK5zrhTEWK heph@fenrir"
        ];

        services.unifi = {
          enable = false;
          openFirewall = true;
          unifiPackage = pkgs.unifi;
          mongodbPackage = pkgs.mongodb;
        };

        environment.systemPackages = with pkgs; [ vim wget ];

        services.openssh.enable = true;
        networking.firewall.allowedTCPPorts = [
          22 8443 6443 6444 9000 2379 2380
        ];
        networking.firewall.allowedUDPPorts = [ 51820 8472 ];

        services.prometheus.exporters.node = {
          enable = true;
          port = 9000;
          enabledCollectors = [ "ethtool" "softirqs" "systemd" "tcpstat" "wifi" ];
        };

        services.prometheus = {
          enable = true;
          globalConfig.scrape_interval = "10s";
          scrapeConfigs = [
            {
              job_name = "node";
              static_configs = [{
                targets = [
                  "localhost:${toString config.services.prometheus.exporters.node.port}"
                ];
              }];
            }
            {
              job_name = "dovecot";
              static_configs = [{
                targets = [
                  "hermes:${toString config.services.prometheus.exporters.dovecot.port}"
                ];
              }];
            }
            {
              job_name = "rspamd";
              static_configs = [{
                targets = [
                  "hermes:${toString config.services.prometheus.exporters.rspamd.port}"
                ];
              }];
            }
            {
              job_name = "postfix";
              static_configs = [{
                targets = [
                  "hermes:${toString config.services.prometheus.exporters.postfix.port}"
                ];
              }];
            }
            {
              job_name = "esphome";
              scrape_interval = "5s";
              static_configs = [{ targets = [ "192.168.0.167:80" ]; }];
            }
          ];
        };

        services.k3s = {
          enable = true;
          role = "server";
          token = "uasdfnl8yho";
          clusterInit = true;
        };

        networking.firewall.enable = true;
      })
    ];
  };
}
