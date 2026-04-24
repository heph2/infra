{ inputs, config, ... }:
let
  nixos = config.flake.modules.nixos;
in
{
  flake.nixosConfigurations.timballo = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      nixos.allow-unfree
      nixos.common-server
      nixos.locale-eu
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.heph = import ./home.nix;
      }
      ({ modulesPath, ... }: {
        imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
      })
      ./hardware-configuration.nix
      ({ pkgs, ... }: {
        boot.kernelPackages = pkgs.linuxPackages_latest;
        boot.supportedFilesystems = [ "btrfs" ];
        hardware.enableAllFirmware = true;
        boot.loader.systemd-boot.enable = false;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.loader.grub = {
          enable = true;
          device = "nodev";
          efiSupport = true;
          enableCryptodisk = true;
        };

        boot.initrd.luks.devices = {
          root = {
            device = "/dev/disk/by-uuid/eff08293-9601-478f-bc54-6dd5160a3a3e";
            preLVM = true;
          };
        };

        networking.hostName = "timballo";
        networking.wireless.enable = true;
        networking.wireless.networks = {
          Monolith = { psk = "cipotleTheRebels1818&"; };
        };

        fonts.packages = with pkgs; [ nerdfonts ];

        services.greetd = {
          enable = true;
          settings = {
            default_session = {
              command = "${pkgs.greetd.greetd}/bin/agreety --cmd Hyprland";
            };
          };
        };

        sound.enable = true;
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };

        users.users.heph = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
        };

        environment.systemPackages = with pkgs; [ vim mg wget lshw pciutils ];

        hardware.opengl.enable = true;

        networking.firewall.allowedTCPPorts = [ 22 ];
        networking.firewall.enable = true;

        system.stateVersion = "23.05";
      })
    ];
  };
}
