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
          ];
          shellHook = ''
            export SOPS_AGE_KEY_FILE=$(pwd)/secrets/age-privkey.txt
          '';
        };
    };
}
