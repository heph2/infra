{
  perSystem =
    {
      pkgs,
      self',
      inputs',
      ...
    }:
    {
      formatter = pkgs.nixpkgs-fmt;

      packages = {
        obscura = inputs'.obscura.packages.obscura-browser-bin;

        # Exposed so `nix build .#openwiki` and `pkgs/openwiki/update.sh`
        # (nix-update --flake openwiki) both work.
        openwiki = pkgs.callPackage ./pkgs/openwiki/package.nix { };
      };

      devShells.default =
        with pkgs;
        mkShell {
          buildInputs = [
            sops
            just
            ssh-to-age
            age
            ragenix
            nixos-rebuild
            nixos-rebuild-ng
            fluxcd
          ];
          shellHook = ''
            export SOPS_AGE_KEY_FILE=$(pwd)/secrets/age-privkey.txt
          '';
        };
    };
}
