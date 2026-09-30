{
  perSystem =
    { pkgs
    , self'
    , inputs'
    , terraform
    , ...
    }:
    {
      terranix.terranixConfigurations = {
        hetzner = {
          modules = [ ./terraform/hetzner.nix ];
          terraformWrapper.package = terraform;
          workdir = "terraform/hetzner";
        };
        cloudflare = {
          modules = [ ./terraform/cloudflare.nix ];
          terraformWrapper.package = terraform;
          workdir = "terraform/cloudflare";
        };
      };

      formatter = pkgs.nixpkgs-fmt;

      packages = {
        alfred = pkgs.callPackage ./pkgs/alfred.nix { };
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
            babashka
            hledger
            vja
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
