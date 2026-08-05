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

      # Exposed so `nix build .#openwiki` and `pkgs/openwiki/update.sh`
      # (nix-update --flake openwiki) both work.
      packages.openwiki = pkgs.callPackage ./pkgs/openwiki/package.nix { };

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
          ];
          shellHook = ''
            export SOPS_AGE_KEY_FILE=$(pwd)/secrets/age-privkey.txt
          '';
        };
    };
}
