{
  perSystem = { pkgs, self', inputs', ... }: {
    formatter = pkgs.nixpkgs-fmt;
    devShells.default = with pkgs;
      mkShell {
        buildInputs = [
          sops
          ssh-to-age
          age
          nixos-rebuild
        ];
        shellHook = ''
          export SOPS_AGE_KEY_FILE=$(pwd)/secrets/age-privkey.txt
        '';
      };
  };
}
