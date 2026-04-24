{ inputs, config, ... }:
let
  nixos = config.flake.modules.nixos;
  hostname = "zima";
  localDomain = hostname + ".hephnet.lan";
in
{
  flake.nixosConfigurations.zima = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      nixos.allow-unfree
      nixos.common-server
      nixos.nix-settings
      nixos.locale-eu
      inputs.agenix.nixosModules.default
      ({ modulesPath, ... }: {
        imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
      })
      ./hardware-configuration.nix
      ./actual.nix
      ./mosquitto.nix
      ({ config, pkgs, ... }: {
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.initrd.availableKernelModules =
          [ "ahci" "xhci_pci" "sd_mod" "sdhci_pci" ];
        boot.initrd.kernelModules = [ ];
        boot.kernelModules = [ "kvm-intel" ];
        boot.extraModulePackages = [ ];

        virtualisation.docker.enable = true;
        virtualisation.docker.storageDriver = "btrfs";

        networking.interfaces.enp3s0 = {
          ipv6.addresses = [{
            address = "2a07:7e81:85f5::cafe";
            prefixLength = 64;
          }];
        };
        networking.defaultGateway6 = {
          address = "fe80::6f4:1cff:fe18:162";
          interface = "enp3s0";
        };

        programs = {
          direnv.enable = true;
          direnv.nix-direnv.enable = true;
        };

        services.btrfs.autoScrub = {
          enable = true;
          interval = "monthly";
          fileSystems = [ "/" "/data" ];
        };

        services.postgresql = {
          enable = true;
          package = pkgs.postgresql_16;
          ensureDatabases = [ "atuin" ];
          ensureUsers = [{
            name = "atuin";
            ensureDBOwnership = true;
          }];
        };

        services.atuin = {
          enable = true;
          openFirewall = true;
          openRegistration = true;
          host = "0.0.0.0";
          database.createLocally = false;
          database.uri = "postgresql://atuin:atuin@localhost:5432/atuin";
        };

        services.k3s = {
          enable = true;
          role = "agent";
          token = "uasdfnl8yho";
          serverAddr = "https://192.168.0.104:6443";
        };

        services.nginx = {
          enable = true;
          recommendedProxySettings = true;

          virtualHosts."jelly.${localDomain}" = {
            locations."/" = {
              proxyPass = "http://127.0.0.1:8096";
              proxyWebsockets = true;
            };
          };
          virtualHosts."aurora.${localDomain}" = {
            locations."/" = { proxyPass = "http://192.168.1.30:3000"; };
          };
          virtualHosts."torrent.${localDomain}" = {
            locations."/" = {
              proxyPass = "http://127.0.0.1:9091";
              extraConfig = ''
                proxy_pass_header  X-Transmission-Session-Id;
                proxy_set_header   X-Forwarded-Host $host;
                proxy_set_header   X-Forwarded-Server $host;
                proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
              '';
            };
          };
          virtualHosts."rss.${localDomain}" = {
            locations."/" = { proxyPass = "http://127.0.0.1:8080"; };
          };
        };

        services.miniflux = {
          enable = true;
          adminCredentialsFile = "/etc/nixos/miniflux.credentials";
        };

        services.goatcounter = {
          enable = true;
          proxy = true;
          address = "192.168.1.30";
        };

        services.cloudflared = {
          enable = true;
          certificateFile = "/root/.cloudflared/cert.pem";
          tunnels = {
            "bcf94d1a-acfa-4938-99e5-fe9cd8c5e6d8" = {
              credentialsFile = "/etc/nixos/cloudflared.credentials";
              certificateFile = "/root/.cloudflared/cert.pem";
              originRequest.noTLSVerify = true;
              default = "http_status:404";
              ingress = {
                "cup.mbauce.com" = {
                  service = "http://192.168.1.30:7878";
                };
                "stats.mbauce.com" = {
                  service = "http://192.168.1.30:8081";
                };
              };
            };
          };
        };

        networking.firewall = {
          extraCommands = ''
            iptables -I INPUT 1 -i docker0 -p tcp -d 172.17.0.1 -j ACCEPT
            iptables -I INPUT 2 -i docker0 -p udp -d 172.17.0.1 -j ACCEPT
          '';
          allowedTCPPorts = [
            80 8096 9091 6443 6444 2380 2379 5006 1883
          ];
          allowedUDPPorts = [ 8472 ];
        };

        networking.hostName = hostname;

        environment.systemPackages = with pkgs; [
          vim mg wget ncdu git borgbackup bind dnsutils
        ];
      })
    ];
  };
}
