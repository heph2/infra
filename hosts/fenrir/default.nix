{ inputs, config, ... }:
let
  nixos = config.flake.modules.nixos;
  hm = config.flake.modules.homeManager;
in
{
  flake.nixosConfigurations.fenrir = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      # Dendritic foundation
      nixos.allow-unfree
      nixos.nix-settings
      nixos.locale-eu
      nixos.user-heph
      nixos.resolved-dns

      # Desktop
      nixos.pipewire
      nixos.fonts
      nixos.polkit
      nixos.documentation
      nixos.niri

      # Security
      nixos.yubikey

      # Home-manager
      nixos.hm-nixos-wiring

      # External input modules
      inputs.apple-silicon.nixosModules.default
      inputs.niri.nixosModules.niri
      inputs.agenix.nixosModules.default

      # Overlays
      {
        nixpkgs.overlays = [
          inputs.apple-silicon.overlays.default
          inputs.niri.overlays.niri
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
          inherit inputs;
          agenix = inputs.agenix;
          firefox-addons = inputs.firefox-addons;
        };
        home-manager.users.heph = { config, pkgs, lib, ... }: {
          imports = [
            hm.helix
            hm.ghostty
            hm.firefox
            hm.zsh-p10k
            hm.git-heph
            hm.dev-tools
            hm.tmux
            hm.direnv
            hm.gpg-agent
            hm.ssh-hosts
            inputs.agenix.homeManagerModules.default
            inputs.noctalia.homeModules.default
          ];

          home.username = "heph";
          home.homeDirectory = "/home/heph";
          home.stateVersion = "25.05";
          home.enableNixpkgsReleaseCheck = false;
          programs.home-manager.enable = true;

          home.sessionVariables = { EDITOR = "hx"; };

          # Fenrir-specific packages
          home.packages = with pkgs; [
            mpv thunar w3m kdePackages.okular hledger jujutsu arcanechat-tui
            bind feishin lazygit vesktop brave speedtest-cli ranger gnumake jq
            jless feh playerctl nautilus ncdu unzip telegram-desktop pwvucontrol
            wireplumber gh delta nix-output-monitor rclone imagemagick python3
            nodejs pnpm_10 devenv ffmpeg nmap psmisc xclip alsa-utils rclone
          ];

          # Fenrir-specific SSH hosts
          programs.ssh.matchBlocks.freya = {
            port = 22;
            hostname = "192.168.0.102";
            user = "heph";
            identityFile = "/home/heph/.ssh/sekai_ed";
          };

          # Fenrir-specific ghostty overrides
          programs.ghostty.settings = {
            font-size = 13;
            font-family = "Hack Nerd Font";
            unfocused-split-opacity = 0.96;
            font-feature = [ "-liga" "-dlig" "-calt" ];
          };

          # Fenrir-specific yazi override
          programs.yazi.shellWrapperName = "y";

          # Noctalia shell
          programs.noctalia-shell = {
            enable = true;
            package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
              calendarSupport = true;
            };
            settings = {
              bar = {
                density = "compact";
                position = "top";
                widgets = {
                  left = [
                    { id = "ControlCenter"; useDistroLogo = true; }
                    { id = "ActiveWindow"; }
                  ];
                  center = [
                    { id = "Workspace"; hideUnoccupied = false; labelMode = "none"; }
                  ];
                  right = [
                    { id = "Battery"; alwaysShowPercentage = false; warningThreshold = 30; }
                    { id = "Volume"; }
                    { id = "Brightness"; }
                    { id = "Clock"; formatHorizontal = "HH:mm"; useMonospacedFont = true; usePrimaryColor = true; }
                  ];
                };
              };
              colorSchemes = { predefinedScheme = "Noctalia (default)"; darkMode = true; };
              general = { avatarImage = "${config.home.homeDirectory}/.face"; radiusRatio = 0.2; };
              location = { monthBeforeDay = true; name = "Nova Milanese, Italy"; };
            };
          };

          # Niri config
          programs.niri = {
            settings = {
              input = {
                keyboard.xkb.layout = "us";
                touchpad = { tap = true; natural-scroll = true; click-method = "clickfinger"; };
                mouse.natural-scroll = true;
              };
              spawn-at-startup = [{ command = [ "noctalia-shell" ]; }];
              binds =
                with config.lib.niri.actions;
                let
                  mod = "Super";
                  noctalia = cmd:
                    [ "noctalia-shell" "ipc" "call" ] ++ (pkgs.lib.splitString " " cmd);
                in
                {
                  "${mod}+Return".action.spawn = [ "ghostty" ];
                  "${mod}+Space".action.spawn = noctalia "launcher toggle";
                  "${mod}+Shift+Q".action = close-window;
                  "${mod}+Shift+Escape".action.spawn = noctalia "lockScreen lock";
                  "${mod}+Question".action = show-hotkey-overlay;
                  "${mod}+H".action = focus-column-left;
                  "${mod}+J".action = focus-window-down;
                  "${mod}+K".action = focus-window-up;
                  "${mod}+L".action = focus-column-right;
                  "${mod}+Shift+H".action = move-column-left;
                  "${mod}+Shift+J".action = move-window-down;
                  "${mod}+Shift+K".action = move-window-up;
                  "${mod}+Shift+L".action = move-column-right;
                  "${mod}+F".action = fullscreen-window;
                  "${mod}+V".action = toggle-window-floating;
                  "${mod}+1".action = focus-workspace 1;
                  "${mod}+2".action = focus-workspace 2;
                  "${mod}+3".action = focus-workspace 3;
                  "${mod}+4".action = focus-workspace 4;
                  "${mod}+5".action = focus-workspace 5;
                  "${mod}+6".action = focus-workspace 6;
                  "${mod}+7".action = focus-workspace 7;
                  "${mod}+8".action = focus-workspace 8;
                  "${mod}+9".action = focus-workspace 9;
                  "${mod}+Shift+1".action.move-column-to-workspace = 1;
                  "${mod}+Shift+2".action.move-column-to-workspace = 2;
                  "${mod}+Shift+3".action.move-column-to-workspace = 3;
                  "${mod}+Shift+4".action.move-column-to-workspace = 4;
                  "${mod}+Shift+5".action.move-column-to-workspace = 5;
                  "${mod}+Shift+6".action.move-column-to-workspace = 6;
                  "${mod}+Shift+7".action.move-column-to-workspace = 7;
                  "${mod}+Shift+8".action.move-column-to-workspace = 8;
                  "${mod}+Shift+9".action.move-column-to-workspace = 9;
                  "${mod}+Comma".action = consume-window-into-column;
                  "${mod}+Period".action = expel-window-from-column;
                  "${mod}+R".action = switch-preset-column-width;
                  "${mod}+Shift+R".action = reset-window-height;
                  "${mod}+Minus".action = set-column-width "-10%";
                  "${mod}+Equal".action = set-column-width "+10%";
                  "${mod}+Shift+E".action = quit;
                  "XF86AudioRaiseVolume".action.spawn = noctalia "volume increase";
                  "XF86AudioLowerVolume".action.spawn = noctalia "volume decrease";
                  "XF86AudioMute".action.spawn = noctalia "volume muteOutput";
                  "XF86AudioPlay".action.spawn = [ "playerctl" "play" ];
                  "XF86AudioPause".action.spawn = [ "playerctl" "pause" ];
                  "XF86AudioNext".action.spawn = [ "playerctl" "next" ];
                  "XF86AudioPrev".action.spawn = [ "playerctl" "prev" ];
                  "XF86MonBrightnessUp".action.spawn = noctalia "brightness increase";
                  "XF86MonBrightnessDown".action.spawn = noctalia "brightness decrease";
                };
              environment = { DISPLAY = ":0"; XDG_SESSION_TYPE = "wayland"; };
              layout = {
                gaps = 8;
                preset-column-widths = [
                  { proportion = 0.333333; }
                  { proportion = 0.5; }
                  { proportion = 0.666667; }
                ];
                default-column-width = { proportion = 0.5; };
                center-focused-column = "never";
                focus-ring.enable = false;
                border = {
                  enable = true;
                  width = 1;
                  active.color = "#7c3aed";
                  inactive.color = "#333333";
                };
              };
              prefer-no-csd = true;
              screenshot-path = "~/Pictures/Screenshots/%Y-%m-%d %H-%M-%S.png";
              animations = { enable = true; slowdown = 1.0; };
            };
          };

          # Fenrir-specific zsh aliases
          programs.zsh.shellAliases = {
            update = "sudo nixos-rebuild switch --flake .#fenrir";
          };

          programs.firefox.profiles.default.extensions.packages =
            with inputs.firefox-addons.packages.${pkgs.system}; [ ipvfoo ];
        };
      }

      ({ modulesPath, ... }: {
        imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
      })

      # Hardware
      ./hardware-configuration.nix

      # Host-specific NixOS config
      ({ config, pkgs, ... }: {
        hardware.bluetooth.enable = true;
        hardware.pulseaudio.enable = false;
        hardware.asahi.extractPeripheralFirmware = true;

        services.power-profiles-daemon.enable = true;
        services.upower.enable = true;

        networking.hostName = "fenrir";

        networking.networkmanager.enable = true;
        networking.networkmanager.wifi.backend = "iwd";
        networking.wireless.iwd = {
          enable = true;
          settings.General.AddressRandomization = "disabled";
          settings.General.EnableNetworkConfiguration = true;
        };

        networking.interfaces.wlan0 = {
          ipv6.addresses = [{
            address = "2a07:7e81:85f5::dead";
            prefixLength = 64;
          }];
        };
        networking.defaultGateway6 = {
          address = "fe80::6f4:1cff:fe18:162";
          interface = "wlan0";
        };

        services.usbmuxd = {
          enable = true;
          package = pkgs.usbmuxd2;
        };

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = false;

        nix.settings = {
          extra-substituters = [
            "https://noctalia.cachix.org"
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
            "https://nixos-apple-silicon.cachix.org"
          ];
          extra-trusted-public-keys = [
            "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
          ];
        };

        services.gnome.evolution-data-server.enable = true;

        # Extra user groups beyond dendritic user-heph
        users.users.heph.extraGroups = [ "networkmanager" ];

        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCmIz2Selg5eJ77lvpJHgDJiRIOZbucMjDK5zrhTEWK heph@fenrir"
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIM2sRl50sDPAoWbFXglFFsWzgC1Ejo02iL+WRWGOBdiJAAAAC3NzaDp5dWJpa2V5 heph@freya"
        ];

        virtualisation.docker.enable = true;

        environment.systemPackages = with pkgs; [
          inputs.nix-ai-tools.packages.${pkgs.system}.opencode
          vim wget curl git fd nh nixfmt-rfc-style lm_sensors pciutils usbutils
          brightnessctl cliphist man-pages man-pages-posix smartmontools nvme-cli
          inetutils openssl age age-plugin-yubikey passage yubikey-manager
          yubikey-touch-detector libfido2 yubikey-personalization libimobiledevice
          ifuse
        ];

        services.openssh = {
          enable = true;
          settings.PasswordAuthentication = false;
          ports = [ 22 ];
        };
        networking.firewall.allowedTCPPorts = [ 22 ];
        networking.firewall.enable = true;

        system.stateVersion = "25.05";
      })
    ];
  };
}
