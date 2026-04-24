{ inputs, config, ... }:
let
  darwin = config.flake.modules.darwin;
in
{
  flake.darwinConfigurations.aron = inputs.darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = { inherit inputs; };
    modules = [
      # Dendritic foundation
      darwin.allow-unfree
      darwin.nix-settings
      darwin.user-marco
      darwin.hm-darwin-wiring

      {
        nixpkgs.config.allowBroken = true;
        nixpkgs.overlays = [ inputs.emacs-overlay.overlay ];
      }
      inputs.spicetify-nix.darwinModules.spicetify

      # Home-manager user
      {
        home-manager.extraSpecialArgs = { inherit inputs; };
        home-manager.users.marco = import ./home.nix;
        home-manager.sharedModules = [ ];
      }

      ./brew.nix
      ./wm.nix

      ({ pkgs, lib, ... }: {
        nix.distributedBuilds = true;
        nix.enable = false;
        ids.uids.nixbld = 350;
        nix.settings = {
          trusted-users = [ "marco" "root" ];
          substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
            "https://devenv.cachix.org"
            "https://numtide.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
            "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
          ];
        };

        nix.linux-builder = {
          enable = false;
          ephemeral = true;
          systems = [ "aarch64-linux" ];
        };

        services.postgresql.enable = true;
        services.emacs.enable = true;
        programs.nix-index.enable = true;

        services.dnsmasq = {
          enable = true;
          addresses = { localhost = "127.0.0.1"; };
        };
        services.synapse-bt.enable = false;
        services.tailscale.enable = false;

        environment.systemPackages = with pkgs; [
          inputs.nix-ai-tools.packages.${pkgs.system}.claude-code
          inputs.nix-ai-tools.packages.${pkgs.system}.opencode
          cachix granted nixfmt pass gnupg pinentry_mac pinentry-curses
          isync mutt mu notmuch terminal-notifier go llama-cpp gradle jdk
        ];

        environment.variables = { };

        system.keyboard.enableKeyMapping = true;
        system.keyboard.remapCapsLockToEscape = true;
        system.defaults.trackpad.TrackpadRightClick = true;

        security.pam.services.sudo_local.touchIdAuth = true;
        system.stateVersion = 4;
      })
    ];
  };
}
