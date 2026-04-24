{ inputs, ... }: {
  flake.modules.nixos.nix-settings = {
    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
        auto-optimise-store = true;
      };
    };
  };

  flake.modules.darwin.nix-settings = { lib, pkgs, ... }: {
    nix.extraOptions = ''
      auto-optimise-store = true
      experimental-features = nix-command flakes
    '' + lib.optionalString (pkgs.system == "aarch64-darwin") ''
      extra-platforms = x86_64-darwin aarch64-darwin
    '';
    nix.optimise.automatic = false;
  };
}
