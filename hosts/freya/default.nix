{ inputs, config, ... }:
let
  nixos = config.flake.modules.nixos;
  hm = config.flake.modules.homeManager;

  user = "heph";
  platform = "amd";
  home = "/home/${user}";
in
{
  flake.nixosConfigurations.freya = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      # Dendritic foundation
      nixos.allow-unfree
      nixos.common-server
      nixos.nix-settings
      nixos.locale-eu
      nixos.user-heph
      nixos.resolved-dns

      # Desktop
      nixos.pipewire
      nixos.fonts
      nixos.polkit
      nixos.documentation
      nixos.cosmic

      # Security
      nixos.yubikey

      # Home-manager
      nixos.hm-nixos-wiring

      # External input modules
      inputs.agenix.nixosModules.default
      inputs.spicetify-nix.nixosModules.default
      inputs.trcc_gif.nixosModules.trcc-gif

      # Overlays
      {
        nixpkgs.overlays = [
          inputs.emacs-overlay.overlay
          (final: prev: {
            stable = import inputs.stable-nixpkgs {
              system = prev.system;
              config.allowUnfree = true;
            };
          })
        ];
      }

      # Home-manager user
      {
        home-manager.extraSpecialArgs = {
          agenix = inputs.agenix;
          stardew-modding = inputs.stardew-modding;
          firefox-addons = inputs.firefox-addons;
        };
        home-manager.users.heph = import ./home.nix;
      }

      ({ modulesPath, ... }: {
        imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
      })

      # Hardware
      ./hardware-configuration.nix
      ./disk-config.nix
      "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix"

      # Host-specific config
      ({ config, lib, pkgs, ... }: {
        age.identityPaths = [ "/home/heph/.ssh/sekai_ed" ];
        age.secrets.wg = {
          file = ../../secrets/wg-key-freya.age;
          mode = "640";
          owner = "systemd-network";
          group = "systemd-network";
        };

        boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

        hardware.opentabletdriver.enable = false;
        services.libinput.enable = true;
        services.xserver.wacom.enable = true;
        services.avahi = {
          enable = true;
          openFirewall = true;
          publish = { enable = true; addresses = true; workstation = true; userServices = true; };
        };
        services.flatpak.enable = true;
        services.udev.extraHwdb = ''
          evdev:input:b0003v056Ap033C*
            ID_INPUT_TABLET_PAD=1
            ID_INPUT_TABLET=0
        '';

        nixpkgs.config.permittedInsecurePackages = [ "libsoup-2.74.3" "openssl-1.1.1w" ];
        environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;
        environment.extraInit = "xset s off -dpms";

        systemd.targets.sleep.enable = false;
        systemd.targets.suspend.enable = false;
        systemd.targets.hibernate.enable = false;
        systemd.targets.hybrid-sleep.enable = false;
        services.blueman.enable = true;
        services.zfs.autoScrub.enable = true;

        services.trcc-gif = {
          enable = true;
          binDirectory = "/var/lib/trcc-gif/frames";
        };

        services.borgbackup.jobs =
          let
            common-excludes = [
              ".cache" "*/cache2" "*/Cache" ".mozilla" "*/.cargo"
              ".compose-cache" ".npm" ".local/share" ".ollama"
              "*/.terraform.d" ".rustup" ".config/Slack/logs"
              ".config/Code/CachedData" ".container-diff"
              ".npm/_cacache" "*/node_modules" "*/_build" "*/.tox"
              "*/venv" "*/.venv"
            ];
            basicBorgJob = name: {
              encryption.mode = "none";
              environment.BORG_RSH = "ssh -o 'StrictHostKeyChecking=no' -i /home/heph/.ssh/sekai_ed";
              environment.BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK = "yes";
              extraCreateArgs = "--verbose --stats --checkpoint-interval 600";
              repo = "ssh://sauron//data/backup/${name}";
              compression = "zstd,1";
              startAt = "hourly";
              persistentTimer = true;
              user = "heph";
            };
          in
          {
            home-heph = basicBorgJob "freya/home-heph" // rec {
              paths = "/home/heph";
              exclude = map (x: paths + "/" + x) (
                common-excludes ++ [ "Downloads" "Videos" ".models" "Games" ]
              );
            };
          };

        services.samba = {
          enable = false;
          openFirewall = true;
          settings = {
            global = {
              "workgroup" = "WORKGROUP"; "server string" = "smbnix"; "netbios name" = "smbnix";
              "security" = "user"; "hosts allow" = "192.168.1. 192.168.122. 127.0.0.1 localhost";
              "hosts deny" = "0.0.0.0/0"; "guest account" = "nobody"; "map to guest" = "bad user";
            };
            "public" = {
              "path" = "/home/heph/Public"; "browseable" = "yes"; "read only" = "no";
              "guest ok" = "yes"; "create mask" = "0644"; "directory mask" = "0755";
              "force user" = "username"; "force group" = "groupname";
            };
          };
        };
        services.samba-wsdd = { enable = false; openFirewall = true; };

        programs.steam.enable = true;

        services.transmission = {
          enable = false;
          user = "heph"; group = "users"; home = "/home/heph/";
          settings.download-dir = "/home/heph/Videos";
          settings.incomplete-dir = "/home/heph/Videos/.incomplete";
          settings.downloadDirPermissions = "0770";
        };

        services.syncthing = {
          enable = true;
          openDefaultPorts = true;
          user = "heph";
          configDir = "${home}/.config/syncthing";
          settings.gui = { user = "freya"; password = "mypassword"; };
          devices = {
            "aron" = { id = "AJ5RD3I-H6AKBMI-J7MP7LC-METYTUB-YEQNZTQ-FJUUTPA-REJTL7O-BKPH5QD"; };
            "zarel" = { id = "TQR3SDR-KFWUNRW-MLVQFCG-TJN2O72-I36HOMF-JHWHONU-IGDPFDA-3Z3ARAW"; };
            "timballo" = { id = ""; };
          };
          folders = {
            "Age" = { path = "${home}/.age"; devices = [ "aron" "timballo" ]; };
            "Emacs" = { path = "${home}/.emacs.d"; devices = [ "aron" "timballo" ]; };
            "Gnupg" = { path = "${home}/.gnupg"; devices = [ "aron" "timballo" ]; };
            "Ledger" = { path = "${home}/Documents/finance"; devices = [ "aron" "timballo" ]; };
          };
        };

        services.fstrim.enable = true;

        networking.wireguard.interfaces = {
          wg0 = {
            ips = [ "10.1.1.6/32" "2a0f:85c1:c4d:1234::6/128" ];
            listenPort = 51820;
            privateKeyFile = config.age.secrets.wg.path;
            peers = [{
              publicKey = "VaCUhE4J7m4uP+3aKPf0PBeRCnS4Wy1rFX0aZ0imYgU=";
              allowedIPs = [ "2000::/3" "10.1.1.0/24" "1.1.1.1/32" ];
              endpoint = "193.57.159.213:51820";
              persistentKeepalive = 25;
            }];
          };
        };

        nix.settings.trusted-substituters = [
          "https://ai.cachix.org" "https://heph2.cachix.org"
          "https://nixos-apple-silicon.cachix.org"
        ];
        nix.settings.trusted-public-keys = [
          "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="
          "heph2.cachix.org-1:aVuYQpvc6De8i9qWwP2V0ErH4VqSpOCWjv116AR1mYc="
          "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
        ];

        boot.extraModprobeConfig = "blacklist nouveau\noptions nouveau modeset=0\n";
        boot.kernelModules = [
          "kvm-${platform}" "vfio_virqfd" "vfio_pci" "vfio_iommu_type1"
          "vfio" "wacom" "amdgpu" "usbmon"
        ];
        boot.kernelParams = [
          "radeon.si_support=0" "amdgpu.si_support=1"
          "radeon.cik_support=0" "amdgpu.cik_support=1"
        ];
        boot.loader.efi.canTouchEfiVariables = true;
        boot.loader.systemd-boot.enable = true;

        programs.wireshark = { enable = true; usbmon.enable = true; };

        services.udev.extraRules = ''
          SUBSYSTEM=="usb", ATTR{idVendor}=="87ad", ATTR{idProduct}=="70db", MODE="0666"
          SUBSYSTEM=="usbmon", GROUP="wireshark", MODE="0640"
        '';
        services.udev.packages = [
          pkgs.libfido2 pkgs.yubikey-personalization pkgs.wooting-udev-rules
        ];
        security.pam.services = { login.u2fAuth = true; sudo.u2fAuth = true; };

        boot.blacklistedKernelModules = [ "nouveau" ];

        systemd.tmpfiles.rules = [
          "f /dev/shm/looking-glass 0660 ${user} kvm -"
          "d /var/lib/trcc-gif/frames 0755 root root -"
        ];

        hardware.enableAllFirmware = true;
        hardware.steam-hardware.enable = true;
        hardware.xpadneo.enable = true;
        hardware.graphics.enable = true;
        hardware.rtl-sdr.enable = true;
        hardware.cpu.amd.updateMicrocode = true;
        hardware.graphics.enable32Bit = true;
        hardware.bluetooth.enable = true;

        networking.hostName = "freya";
        networking.hostId = "d81f3ea4";

        # Extra user groups beyond dendritic user-heph
        users.users.heph.extraGroups = [ "wireshark" "qemu-libvirtd" "libvirtd" "disk" "kvm" ];

        services.xserver.enable = true;
        services.xserver.xrandrHeads = [
          { output = "HDMI-A-0"; primary = true; }
          { output = "DisplayPort-1"; }
        ];
        services.xserver.videoDrivers = [ "amdgpu" ];
        services.displayManager.ly.enable = false;
        services.xserver.xkb.layout = "us";
        services.printing.enable = true;

        programs.spicetify =
          let spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
          in {
            enable = true;
            enabledExtensions = with spicePkgs.extensions; [ adblock hidePodcasts shuffle ];
            theme = spicePkgs.themes.catppuccin;
            colorScheme = "mocha";
          };

        programs.streamdeck-ui = { enable = true; autoStart = true; };

        services.synergy.server = {
          enable = false; autoStart = false; screenName = "freya";
          address = "0.0.0.0:24800"; tls.enable = false;
        };

        virtualisation.docker.enable = true;

        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCmIz2Selg5eJ77lvpJHgDJiRIOZbucMjDK5zrhTEWK heph@fenrir"
        ];

        nixpkgs.overlays = [
          (self: super: {
            lutris = inputs.stable-nixpkgs.legacyPackages.${super.system}.lutris.override {
              extraLibraries = pkgs: with pkgs; [ libadwaita gtk4 ];
            };
          })
          (self: super: {
            heroic = super.heroic.override { extraPkgs = pkgs: [ pkgs.gamescope ]; };
          })
        ];

        programs.gamemode.enable = true;
        programs.gamescope.enable = true;
        services.open-webui = { enable = true; port = 11111; };

        environment.systemPackages = with pkgs; [
          inputs.nix-ai-tools.packages.${pkgs.system}.claude-code
          inputs.nix-ai-tools.packages.${pkgs.system}.opencode
          steamcmd uxplay llama-cpp-rocm libinput libwacom vim wireshark
          heroic stable.lutris protonup-qt wineWowPackages.stable winetricks
          hidapi wget quickemu python3 aider-chat man-pages man-pages-posix
          ffmpeg kubectl bind fd smartmontools nvme-cli nh nixfmt-classic
          inetutils openssl virt-manager looking-glass-client pciutils usbutils
          mg git docker-compose podman-tui remmina lm_sensors rofi scrcpy dive
          dmenu sxhkd bspwm btrfs-assistant thunderbird xorg.libXxf86vm glib
          openjdk21 obsidian
          (aspellWithDicts (dicts: with dicts; [ en en-computers en-science es it ]))
        ];

        virtualisation = {
          spiceUSBRedirection.enable = true;
          libvirtd = { enable = true; onBoot = "start"; onShutdown = "shutdown"; };
        };

        programs.mtr.enable = true;

        services.openssh.enable = true;
        networking.firewall.allowedTCPPorts = [ 22 24800 57621 8000 8443 ];
        networking.firewall.allowedUDPPorts = [ 24800 5353 ];
        networking.firewall.enable = false;
        networking.firewall.extraCommands = ''
          iptables -I INPUT 1 -i docker0 -p tcp -d 172.17.0.1 -j ACCEPT
          iptables -I INPUT 2 -i docker0 -p udp -d 172.17.0.1 -j ACCEPT
        '';
        networking.firewall.trustedInterfaces = [ "virbr0" ];

        system.stateVersion = "23.11";
      })
    ];
  };
}
