{ config, inputs, ... }:
let
  hm = config.infra.modules.homeManager;
in
{
  infra.nixos.hosts.freya = {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      {
        nixpkgs.overlays = [
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
      inputs.agenix.nixosModules.default
      inputs.disko.nixosModules.disko
      inputs.spicetify-nix.nixosModules.default
      inputs.trcc_gif.nixosModules.trcc-gif
      inputs.handy.nixosModules.default
      config.infra.modules.nixos.home-manager
      config.infra.modules.nixos.comfyui
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
          stardew-modding = inputs.stardew-modding;
        };
      }
      { nixpkgs.config.allowUnfree = true; }
      ../../modules/common/default.nix
      (
        { modulesPath, ... }:
        {
          imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
        }
      )
    ];
  };
}
