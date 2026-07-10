{ config, inputs, ... }:
let
  hm = config.infra.modules.homeManager;
in
{
  infra.nixos.hosts.fenrir = {
    system = "aarch64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      {
        nixpkgs.overlays = [
          inputs.apple-silicon.overlays.default
          inputs.niri.overlays.niri
          inputs.emacs-overlay.overlay
          (final: prev: {
            stable = import inputs.stable-nixpkgs {
              system = prev.stdenv.hostPlatform.system;
              config.allowUnfree = true;
            };
          })
        ];
      }
      ./default.nix
      inputs.apple-silicon.nixosModules.default
      inputs.niri.nixosModules.niri
      inputs.agenix.nixosModules.default
      config.infra.modules.nixos.home-manager
      {
        home-manager.backupFileExtension = "backup";
        home-manager.users.heph.imports = [
          hm.heph
          hm.user-tools
          hm.terminal
          hm.helix
          hm.git-heph
          hm.zsh-p10k
          hm.ssh-heph
          hm.firefox-heph
          hm.mail-heph
          ./home.nix
        ];
        home-manager.extraSpecialArgs = {
          inherit inputs;
          agenix = inputs.agenix;
          firefox-addons = inputs.firefox-addons;
        };
      }
      { nixpkgs.config.allowUnfree = true; }
      (
        { modulesPath, ... }:
        {
          imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
        }
      )
    ];
  };
}
